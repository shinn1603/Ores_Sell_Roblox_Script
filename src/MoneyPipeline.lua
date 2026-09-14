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

    function MoneyPipeline.run()
        local base = Utils.getMyBase()
        if not base then return false, "Không tìm thấy căn cứ" end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false, "Chưa tải nhân vật" end

        local cm = base:FindFirstChild("CrateMaker")
        local furnace = base:FindFirstChild("Furnace")
        local st = base:FindFirstChild("SellerTable")

        local stepDelay = math.clamp(State.MoneyStepDelay or 0.4, 0.25, 1.0)
        local prevCF = char.HumanoidRootPart.CFrame

        -- BƯỚC 0: KIỂM TRA XEM LÒ NUNG ĐÃ CÓ SẴN THÙNG KIM LOẠI NUNG XONG CHƯA
        local readyMetalPrompt = nil
        if furnace and furnace:FindFirstChild("MetalCratePlacementPart") then
            for _, p in ipairs(furnace.MetalCratePlacementPart:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.ActionText == "Pick up" and p.Enabled then
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
        else
            -- BƯỚC 1: Thu hoạch thùng quặng thô từ CrateMaker
            local pickOrePrompt = nil
            if cm and cm:FindFirstChild("CrateSpawnPoint") then
                for _, p in ipairs(cm.CrateSpawnPoint:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.ActionText:find("Pick up") and p.Enabled then
                        pickOrePrompt = p
                        break
                    end
                end
            end

            if not pickOrePrompt then
                return false, "Mỏ đang đào quặng, chưa có thùng mới"
            end

            Utils.teleportTo(cm.CrateSpawnPoint.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(pickOrePrompt)
            task.wait(stepDelay + 0.15)

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

                local crateTool = char:FindFirstChildOfClass("Tool") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
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
                        if p:IsA("ProximityPrompt") and p.ActionText == "Pick up" and p.Enabled then
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
            else
                return false, "Lò nung đang nung, chưa xong thùng thành phẩm"
            end
        end

        -- BƯỚC 4: Cầm chắc thùng trên tay và đem bán tại SellerTable
        local metalTool = char:FindFirstChildOfClass("Tool") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChildOfClass("Tool"))
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

        -- Quay lại vị trí đứng cũ
        Utils.teleportTo(prevCF)
        return true, "Đã hoàn thành một chu kỳ bán quặng kiếm tiền!"
    end
end

return MoneyPipeline
