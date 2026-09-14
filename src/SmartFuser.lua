--[[
    MODULE: SmartFuser.lua
    Mô tả: Tự động nạp quặng vào 5 node của Fuser và nhận thành phẩm Mega Ore (Bảo vệ quặng xịn 100%)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SmartFuser = {}

function SmartFuser.init(deps)
    local Utils = deps.Utils
    local State = deps.State

    function SmartFuser.run()
        local base = Utils.getMyBase()
        if not base then
            for _ = 1, 3 do
                task.wait(0.5)
                base = Utils.getMyBase()
                if base then break end
            end
        end
        if not base or not base:FindFirstChild("Fuser") then
            return false, "Chưa tìm thấy Fuser trong căn cứ của bạn. Đang chờ đồng bộ..."
        end
        local fuser = base.Fuser
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false, "Chưa tải nhân vật" end

        -- Lưu vị trí đứng ban đầu để quay về
        local originCF = char.HumanoidRootPart.CFrame

        -- 1. Nếu có prompt 'Claim Fused Ore' -> Bay tới nhận ngay!
        for _, prompt in ipairs(fuser:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.ActionText:lower():find("claim") then
                local claimPart = (prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent) or prompt:FindFirstAncestorWhichIsA("BasePart")
                if claimPart then
                    Utils.teleportTo(claimPart.CFrame + Vector3.new(0, 2.0, 0))
                    task.wait(0.25)
                end
                Utils.firePrompt(prompt)
                task.wait(0.35)
                if originCF then Utils.teleportTo(originCF) end
                return true, "Đã nhận thành phẩm Mega Ore!"
            end
        end

        -- 2. Kiểm tra xem người chơi có quặng nào trong danh sách cho phép nung ở túi đồ không
        local hasAnyAllowedOre = Utils.hasToolInWhitelist(State.AllowedFuseOres)
        if not hasAnyAllowedOre then
            return false, "Không có quặng nào trong danh sách cho phép nung ở túi đồ"
        end

        -- 3. Tìm tất cả các node đang TRỐNG (Place Ore / Place / Add / Fuse)
        local emptyNodes = {}
        for _, prompt in ipairs(fuser:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local act = (prompt.ActionText or ""):lower()
                if not act:find("claim") and not act:find("remove") then
                    if act:find("place") or act:find("deposit") or act:find("insert") or act:find("add") or act:find("fuse") or act == "" then
                        table.insert(emptyNodes, prompt)
                    end
                end
            end
        end

        if #emptyNodes == 0 then
            return true, "Fuser đã đầy hoặc đang nung quặng"
        end

        -- 4. Nạp quặng vào từng node trống (TELEPORT TRƯỚC → CẦM QUẶNG → BẤM PLACE)
        local placedCount = 0
        for _, prompt in ipairs(emptyNodes) do
            -- RÀNG BUỘC: Kiểm tra túi đồ TRƯỚC KHI bay tới node!
            if not Utils.hasToolInWhitelist(State.AllowedFuseOres) then
                break
            end

            -- Bước A: Teleport đến node TRƯỚC (chưa cầm gì cả!)
            local nodePart = (prompt.Parent and prompt.Parent:IsA("BasePart") and prompt.Parent) or prompt:FindFirstAncestorWhichIsA("BasePart")
            if nodePart then
                Utils.unequipAllTools()
                task.wait(0.08)
                Utils.teleportTo(nodePart.CFrame + Vector3.new(0, 1.8, 0))
                task.wait(0.35)
            end

            -- Bước B: SAU KHI ĐÃ ĐỨNG YÊN, mới cầm quặng lên tay
            local tool = Utils.equipToolFromWhitelist(State.AllowedFuseOres)
            if not tool then
                -- Không còn quặng nào trong danh sách cho phép ở túi đồ -> Dừng, bảo vệ quặng xịn!
                break
            end

            task.wait(0.25) -- Đợi game server xác nhận tool đã trên tay

            -- Bước C: Kích hoạt prompt để đặt quặng vào Fuser (chỉ khi action là Place)
            local actText = (prompt.ActionText or ""):lower()
            if actText:find("place") or actText:find("bỏ") or actText:find("đặt") or actText == "" then
                Utils.firePrompt(prompt)

                -- Đợi tối đa 0.8s kiểm tra xem quặng đã nạp vào node thành công chưa (tool rời tay)
                local startWait = tick()
                while tick() - startWait < 0.8 do
                    if not tool or tool.Parent ~= char then
                        break
                    end
                    task.wait(0.08)
                end

                -- Bước D: Nếu tool vẫn còn trên tay VÀ prompt vẫn là "Place" thì thử lại duy nhất 1 lần
                if tool and tool.Parent == char and prompt.Enabled then
                    local actNow = (prompt.ActionText or ""):lower()
                    if actNow:find("place") or actNow:find("bỏ") or actNow:find("đặt") or actNow == "" then
                        Utils.firePrompt(prompt)
                        task.wait(0.4)
                    end
                end
            end

            placedCount = placedCount + 1
        end

        -- Cất toàn bộ tool vào túi, không cầm trên tay
        Utils.unequipAllTools()

        -- QUAY LẠI VỊ TRÍ ĐỨNG BAN ĐẦU (Nếu đã di chuyển nạp quặng)
        if placedCount > 0 and originCF then
            Utils.teleportTo(originCF)
        end

        return true, string.format("Đã nạp thành công %d quặng cho Fuser!", placedCount)
    end
end

return SmartFuser
