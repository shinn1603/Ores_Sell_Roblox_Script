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
        if not base or not base:FindFirstChild("Fuser") then return false, "Không tìm thấy Fuser trong căn cứ" end
        local fuser = base.Fuser
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false, "Chưa tải nhân vật" end

        -- Lưu vị trí đứng ban đầu để quay về
        local originCF = char.HumanoidRootPart.CFrame

        -- 1. Nếu có prompt 'Claim Fused Ore' -> Bay tới nhận ngay!
        for _, prompt in ipairs(fuser:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.ActionText:lower():find("claim") then
                if prompt.Parent and prompt.Parent:IsA("BasePart") then
                    Utils.teleportTo(prompt.Parent.CFrame + Vector3.new(0, 2.0, 0))
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
            -- Nếu đã hết quặng cho phép nung thì dừng ngay, không bay tới node tiếp theo để tránh việc thừa thãi!
            if not Utils.hasToolInWhitelist(State.AllowedFuseOres) then
                break
            end

            -- Bước A: Teleport đến node TRƯỚC (chưa cầm gì cả!)
            if prompt.Parent and prompt.Parent:IsA("BasePart") then
                Utils.unequipAllTools()
                task.wait(0.1)
                Utils.teleportTo(prompt.Parent.CFrame + Vector3.new(0, 2.0, 0))
                task.wait(0.35)
            end

            -- Bước B: SAU KHI ĐÃ ĐỨNG YÊN, mới cầm quặng lên tay
            local tool = Utils.equipToolFromWhitelist(State.AllowedFuseOres)
            if not tool then
                -- Không còn quặng nào trong danh sách cho phép ở túi đồ -> Dừng, bảo vệ quặng xịn!
                break
            end

            local okEquip = Utils.equipToolToHand(tool)
            if not okEquip then break end
            task.wait(0.25) -- Đợi game server xác nhận tool đã trên tay

            -- Bước C: Kích hoạt prompt để đặt quặng vào Fuser
            Utils.firePrompt(prompt)
            task.wait(0.4)

            -- Bước D: Nếu tool vẫn còn trên tay (game chưa nhận) -> thử lại 2 lần nữa
            for retry = 1, 2 do
                if tool.Parent == char and prompt.Enabled then
                    -- Equip lại tool (đề phòng bị drop)
                    Utils.equipToolToHand(tool)
                    task.wait(0.2)
                    Utils.firePrompt(prompt)
                    task.wait(0.35)
                else
                    break
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
