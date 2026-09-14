--[[
    MODULE: MoneyPipeline.lua
    Mô tả: Chu trình kiếm tiền tự động (CrateMaker -> Furnace -> SellerTable)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MoneyPipeline = {}

function MoneyPipeline.init(deps)
    local Utils = deps.Utils
    local State = deps.State

    local function isPipelineTool(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local n = tool.Name:lower()

        -- 1. Tuyệt đối loại trừ tất cả Pet / Động vật / Thú cưng / Vũ khí
        local blacklist = {
            "capybara", "cat", "lizard", "parrot", "turtle", "rabbit", "koala", "goat", "llama",
            "kangaroo", "retriever", "zebra", "pony", "horse", "snake", "cow", "elephant",
            "bear", "gorilla", "triceratops", "brachiosaurus", "spinosaurus", "tiger", "imp",
            "griffin", "hydra", "kraken", "wyvern", "pet", "pickaxe", "sword", "weapon", "gun",
            "rod", "potion", "gem", "coating"
        }
        for _, b in ipairs(blacklist) do
            if n:find(b) then return false end
        end

        -- 2. Match chính xác thùng quặng hoặc kim loại nung:
        -- "Crate", "Ore Crate", "Box", "Metal", "Metal Bar", "Refined Metal", "Ingot", "ORES"
        if n:find("crate") or n == "box" or n:find("%s*box") or n == "ores" or n:find("ore%s*crate") or n:find("crate%s*of%s*ores") then
            return true
        end
        if n:find("metal") or n:find("ingot") or n:find("refined") or n:match("%f[%a]bar%f[%A]") then
            return true
        end
        return false
    end

    local function isRefinedTool(tool)
        if not isPipelineTool(tool) then return false end
        local n = tool.Name:lower()
        return n:find("metal") or n:find("refined") or n:find("ingot") or (n:match("%f[%a]bar%f[%A]") ~= nil)
    end

    local function isRawCrateTool(tool)
        if not isPipelineTool(tool) then return false end
        return not isRefinedTool(tool)
    end

    local function findPipelineTool()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local containers = {char, backpack}
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if isPipelineTool(item) then
                        return item
                    end
                end
            end
        end
        return nil
    end

    function MoneyPipeline.run()
        local base = Utils.getMyBase()
        if not base then
            for _ = 1, 3 do
                task.wait(0.5)
                base = Utils.getMyBase()
                if base then break end
            end
        end
        if not base then return false, "Chưa xác định được căn cứ của bạn. Đang chờ đồng bộ..." end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false, "Chưa tải nhân vật" end

        local cm = base:FindFirstChild("CrateMaker") or base:WaitForChild("CrateMaker", 2)
        local furnace = base:FindFirstChild("Furnace") or base:WaitForChild("Furnace", 2)
        local st = base:FindFirstChild("SellerTable") or base:WaitForChild("SellerTable", 2)

        local stepDelay = math.clamp(State.MoneyStepDelay or 0.4, 0.25, 1.0)
        local prevCF = root.CFrame

        -- Hàm phụ trợ bán hàng tại SellerTable
        local function sellAtSellerTable()
            local metalTool = findPipelineTool()
            if metalTool then Utils.equipToolToHand(metalTool) end
            task.wait(0.12)

            local sellPrompt = nil
            if st then
                for _, p in ipairs(st:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        local act = (p.ActionText or ""):lower()
                        if act:find("sell") or act:find("bán") or act == "" then
                            sellPrompt = p
                            break
                        end
                    end
                end
            end

            local sellTargetPart = (sellPrompt and sellPrompt.Parent and sellPrompt.Parent:IsA("BasePart") and sellPrompt.Parent)
                or (st and st:FindFirstChildWhichIsA("BasePart", true))

            if sellTargetPart then
                Utils.teleportTo(sellTargetPart.CFrame + Vector3.new(0, 1.5, 0))
                task.wait(stepDelay)

                if metalTool and metalTool.Parent ~= char then Utils.equipToolToHand(metalTool) end
                task.wait(0.1)

                if sellPrompt then
                    pcall(function() sellPrompt.Enabled = true end)
                    Utils.firePrompt(sellPrompt)
                end
                task.wait(stepDelay)
            end

            Utils.unequipAllTools()
            if prevCF then Utils.teleportTo(prevCF) end
            return true, "Đã bán thành công kim loại tại SellerTable!"
        end

        -- RÀNG BUỘC 1: Nếu người chơi ĐÃ CÓ SẴN thùng kim loại thành phẩm trên người
        -- -> Bay thẳng tới SellerTable bán luôn, không đi đâu vòng vo!
        local initialTool = findPipelineTool()
        if initialTool and isRefinedTool(initialTool) then
            return sellAtSellerTable()
        end

        -- BƯỚC 0: KIỂM TRA XEM LÒ NUNG ĐÃ CÓ SẴN THÙNG KIM LOẠI NUNG XONG CHƯA
        local readyMetalPrompt = nil
        if furnace then
            for _, p in ipairs(furnace:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.Enabled then
                    local act = (p.ActionText or ""):lower()
                    if (act:find("pick") or act:find("take") or act:find("lấy")) and not act:find("place") and not act:find("purchase") then
                        readyMetalPrompt = p
                        break
                    end
                end
            end
        end

        if readyMetalPrompt and readyMetalPrompt.Parent and readyMetalPrompt.Parent:IsA("BasePart") then
            Utils.teleportTo(readyMetalPrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(readyMetalPrompt)
            task.wait(stepDelay + 0.1)
            return sellAtSellerTable()
        end

        -- RÀNG BUỘC 2: Nếu chưa có kim loại nung sẵn, nhưng người chơi ĐÃ CÓ SẴN thùng quặng thô trên người
        -- -> Bỏ qua CrateMaker, bay thẳng tới Lò Nung bỏ vào!
        local hasRawCrate = initialTool and isRawCrateTool(initialTool)

        if not hasRawCrate then
            -- Kiểm tra CrateMaker xem có thùng mới chưa TRƯỚC KHI bay tới!
            local pickOrePrompt = nil
            if cm then
                for _, p in ipairs(cm:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        local act = (p.ActionText or ""):lower()
                        if act:find("pick") or act:find("take") or act:find("nhặt") or act:find("ore") or act == "" then
                            pickOrePrompt = p
                            break
                        end
                    end
                end
            end

            -- RÀNG BUỘC 3: Nếu mỏ chưa ra thùng mới và lò cũng chưa có kim loại
            -- -> KHÔNG bay đi đâu cả, giữ nguyên vị trí, tránh làm việc thừa thãi!
            if not pickOrePrompt or not pickOrePrompt.Parent or not pickOrePrompt.Parent:IsA("BasePart") then
                return false, "Mỏ đang đào quặng, chưa có thùng mới"
            end

            if not pickOrePrompt.Enabled then
                return false, "Mỏ đang đào quặng, thùng chưa sẵn sàng"
            end

            -- Có thùng: Bay lại nhặt
            Utils.teleportTo(pickOrePrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(pickOrePrompt)
            task.wait(stepDelay + 0.15)
        end

        -- BƯỚC 2: Bỏ vào lò nung Furnace ('Place ORES')
        local placePrompt = nil
        if furnace then
            for _, p in ipairs(furnace:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    local act = (p.ActionText or ""):lower()
                    if (act:find("place") or act:find("bỏ") or act:find("đặt")) and not act:find("purchase") then
                        placePrompt = p
                        break
                    end
                end
            end
        end

        local placeTargetPart = (placePrompt and placePrompt.Parent and placePrompt.Parent:IsA("BasePart") and placePrompt.Parent)
            or (furnace and furnace:FindFirstChild("PlaceCratesPromptPart"))
            or (furnace and furnace:FindFirstChildWhichIsA("BasePart", true))

        if placeTargetPart then
            Utils.teleportTo(placeTargetPart.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)

            local crateTool = findPipelineTool()
            if crateTool then Utils.equipToolToHand(crateTool) end
            task.wait(0.12)

            if placePrompt then
                pcall(function() placePrompt.Enabled = true end)
                Utils.firePrompt(placePrompt)
            end
            task.wait(stepDelay + 0.2)
        end

        -- BƯỚC 3: Chờ lò nung luyện quặng xong
        local metalPrompt = nil
        local waitSmeltStart = tick()
        while tick() - waitSmeltStart < 6.5 do
            if furnace then
                for _, p in ipairs(furnace:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.Enabled then
                        local act = (p.ActionText or ""):lower()
                        if (act:find("pick") or act:find("take") or act:find("lấy")) and not act:find("place") and not act:find("purchase") then
                            metalPrompt = p
                            break
                        end
                    end
                end
            end
            if metalPrompt then break end
            task.wait(0.3)
        end

        if metalPrompt and metalPrompt.Parent and metalPrompt.Parent:IsA("BasePart") then
            Utils.teleportTo(metalPrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(metalPrompt)
            task.wait(stepDelay + 0.15)
            return sellAtSellerTable()
        else
            Utils.unequipAllTools()
            if prevCF then Utils.teleportTo(prevCF) end
            return false, "Lò nung đang nung, chưa xong thùng thành phẩm"
        end
    end
end

return MoneyPipeline
