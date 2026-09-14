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

    local function findPipelineTool()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local containers = {char, backpack}
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        local n = item.Name:lower()
                        if not n:find("pickaxe") and not n:find("sword") and not n:find("weapon") and not n:find("gun") and not n:find("rod") and not n:find("potion") then
                            -- Chỉ match thùng quặng (Crate / Box) hoặc kim loại nung (Metal / Bar / Ingot / Refined)
                            -- Tuyệt đối không match quặng thông thường (ví dụ: Gold Ore, Stone Ore)
                            if n:find("crate") or n:find("box") or n:find("metal") or n:find("bar") or n:find("ingot") or n:find("refined") then
                                return item
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    local function isRefinedTool(tool)
        if not tool then return false end
        local n = tool.Name:lower()
        return n:find("metal") or n:find("bar") or n:find("refined") or n:find("ingot")
    end

    local function isRawCrateTool(tool)
        if not tool then return false end
        local n = tool.Name:lower()
        return (n:find("crate") or n:find("box")) and not isRefinedTool(tool)
    end

    function MoneyPipeline.run()
        local base = Utils.getMyBase()
        if not base then return false, "Không tìm thấy căn cứ" end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return false, "Chưa tải nhân vật" end

        local cm = base:FindFirstChild("CrateMaker")
        local furnace = base:FindFirstChild("Furnace")
        local st = base:FindFirstChild("SellerTable")

        local stepDelay = math.clamp(State.MoneyStepDelay or 0.4, 0.25, 1.0)
        local prevCF = root.CFrame

        -- Hàm phụ trợ bán hàng tại SellerTable
        local function sellAtSellerTable()
            local metalTool = findPipelineTool()
            if metalTool then Utils.equipToolToHand(metalTool) end
            task.wait(0.15)

            local sellPrompt = nil
            if st then
                for _, p in ipairs(st:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.Enabled then
                        local act = p.ActionText:lower()
                        if act:find("sell") or act:find("bán") or act == "" then
                            sellPrompt = p
                            break
                        end
                    end
                end
            end

            if sellPrompt and sellPrompt.Parent and sellPrompt.Parent:IsA("BasePart") then
                Utils.teleportTo(sellPrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
                task.wait(stepDelay)
                if metalTool and metalTool.Parent ~= char then Utils.equipToolToHand(metalTool) end
                task.wait(0.1)
                Utils.firePrompt(sellPrompt)
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
        if furnace and furnace:FindFirstChild("MetalCratePlacementPart") then
            for _, p in ipairs(furnace.MetalCratePlacementPart:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.ActionText:find("Pick up") and p.Enabled then
                    readyMetalPrompt = p
                    break
                end
            end
        end

        if readyMetalPrompt then
            Utils.teleportTo(furnace.MetalCratePlacementPart.CFrame + Vector3.new(0, 1.5, 0))
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
            if cm and cm:FindFirstChild("CrateSpawnPoint") then
                for _, p in ipairs(cm.CrateSpawnPoint:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.ActionText:find("Pick up") and p.Enabled then
                        pickOrePrompt = p
                        break
                    end
                end
            end

            -- RÀNG BUỘC 3: Nếu mỏ chưa ra thùng mới và lò cũng chưa có kim loại
            -- -> KHÔNG bay đi đâu cả, giữ nguyên vị trí, tránh làm việc thừa thãi!
            if not pickOrePrompt then
                return false, "Mỏ đang đào quặng, chưa có thùng mới"
            end

            -- Có thùng: Bay lại nhặt
            Utils.teleportTo(cm.CrateSpawnPoint.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(pickOrePrompt)
            task.wait(stepDelay + 0.15)
        end

        -- BƯỚC 2: Bỏ vào lò nung Furnace ('Place ORES')
        local placePrompt = nil
        if furnace and furnace:FindFirstChild("PlaceCratesPromptPart") then
            for _, p in ipairs(furnace.PlaceCratesPromptPart:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.ActionText:find("Place") and p.Enabled then
                    placePrompt = p
                    break
                end
            end
        end

        if placePrompt then
            Utils.teleportTo(furnace.PlaceCratesPromptPart.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)

            local crateTool = findPipelineTool()
            if crateTool then Utils.equipToolToHand(crateTool) end
            task.wait(0.12)

            Utils.firePrompt(placePrompt)
            task.wait(stepDelay + 0.2)
        end

        -- BƯỚC 3: Chờ lò nung luyện quặng xong
        local metalPrompt = nil
        local waitSmeltStart = tick()
        while tick() - waitSmeltStart < 6.5 do
            if furnace and furnace:FindFirstChild("MetalCratePlacementPart") then
                for _, p in ipairs(furnace.MetalCratePlacementPart:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.ActionText:find("Pick up") and p.Enabled then
                        metalPrompt = p
                        break
                    end
                end
            end
            if metalPrompt then break end
            task.wait(0.3)
        end

        if metalPrompt then
            Utils.teleportTo(furnace.MetalCratePlacementPart.CFrame + Vector3.new(0, 1.5, 0))
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
