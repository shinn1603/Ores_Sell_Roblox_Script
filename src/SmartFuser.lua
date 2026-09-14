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
                    Utils.teleportTo(prompt.Parent.CFrame + Vector3.new(0, 0.5, 0))
                    task.wait(0.25)
                end
                Utils.firePrompt(prompt)
                task.wait(0.35)
                if originCF then Utils.teleportTo(originCF) end
                return true, "Đã nhận thành phẩm Mega Ore!"
            end
        end

        -- 2. Kiểm tra xem người chơi có quặng nào trong danh sách cho phép nung ở túi đồ không
        local hasAnyAllowedOre = Utils.equipToolFromWhitelist(State.AllowedFuseOres)
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

        -- 4. Nạp quặng vào từng node trống (CẦM QUẶNG TRÊN TAY RỒI MỚI BẤM PLACE)
        local placedCount = 0
        for _, prompt in ipairs(emptyNodes) do
            local tool = Utils.equipToolFromWhitelist(State.AllowedFuseOres)
            if not tool then
                -- Không còn quặng nào trong danh sách cho phép ở túi đồ -> Dừng, bảo vệ quặng xịn!
                break
            end

            local okEquip = Utils.equipToolToHand(tool)
            if not okEquip then break end

            -- Đứng sát trước mặt node trên sàn
            if prompt.Parent and prompt.Parent:IsA("BasePart") then
                Utils.teleportTo(prompt.Parent.CFrame + Vector3.new(0, 0.5, 0))
                task.wait(0.3)
            end

            if tool.Parent ~= char then
                Utils.equipToolToHand(tool)
                task.wait(0.15)
            end

            Utils.firePrompt(prompt)
            task.wait(0.35)

            -- Kiểm tra nếu tool vẫn còn trên tay (chưa ăn prompt) -> thử kích hoạt lại 1 lần nữa
            if tool.Parent == char and prompt.Enabled then
                Utils.firePrompt(prompt)
                task.wait(0.25)
            end

            placedCount = placedCount + 1
        end

        -- QUAY LẠI VỊ TRÍ ĐỨNG BAN ĐẦU (Không đứng ngơ ngác ở Fuser!)
        if originCF then
            Utils.teleportTo(originCF)
        end

        return true, string.format("Đã nạp thành công %d quặng cho Fuser!", placedCount)
    end
end

return SmartFuser
