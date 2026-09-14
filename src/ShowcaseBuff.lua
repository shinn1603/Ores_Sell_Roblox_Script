--[[
    MODULE: ShowcaseBuff.lua
    Mô tả: Tự động kích hoạt Buff x2.75 / x4 từ Showcase Pedestal & Tự động Apply Gems
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local ShowcaseBuff = {}

function ShowcaseBuff.init(deps)
    local Utils = deps.Utils
    local Fluent = deps.Fluent

    -- 1. Tự động Apply Gems (Bấm ApplyGemsButton + Xác nhận ConfirmationPanel)
    function ShowcaseBuff.applyGems(silent)
        local success = false
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return false, "Chưa tải PlayerGui" end

        -- A. Tìm nút ApplyGemsButton trong PlayerGui
        local gemBtn = nil
        local mainFrames = pg:FindFirstChild("MainFrames")
        local topPane = mainFrames and mainFrames:FindFirstChild("MenuFrames") and mainFrames.MenuFrames:FindFirstChild("TopPane")
        if topPane then
            local row1 = topPane:FindFirstChild("Row1")
            gemBtn = (row1 and row1:FindFirstChild("ApplyGemsButton")) or topPane:FindFirstChild("ApplyGemsButton", true)
        end
        if not gemBtn then
            gemBtn = pg:FindFirstChild("ApplyGemsButton", true)
        end
        if not gemBtn then
            for _, desc in ipairs(pg:GetDescendants()) do
                if desc:IsA("GuiButton") then
                    local n = desc.Name:lower()
                    local t = desc:IsA("TextButton") and desc.Text:lower() or ""
                    if n:find("applygem") or (n:find("gem") and n:find("apply")) or (t:find("apply") and t:find("gem")) then
                        gemBtn = desc
                        break
                    end
                end
            end
        end

        -- B. Kích hoạt nút ApplyGemsButton
        if gemBtn then
            pcall(function()
                if firesignal then
                    if gemBtn.Activated then firesignal(gemBtn.Activated) end
                    if gemBtn.MouseButton1Click then firesignal(gemBtn.MouseButton1Click) end
                end
                if getconnections then
                    if gemBtn.Activated then
                        for _, c in ipairs(getconnections(gemBtn.Activated)) do c:Fire() end
                    end
                    if gemBtn.MouseButton1Click then
                        for _, c in ipairs(getconnections(gemBtn.MouseButton1Click)) do c:Fire() end
                    end
                end
                if gemBtn.MouseButton1Click then
                    gemBtn.MouseButton1Click:Fire()
                end
            end)

            pcall(function()
                local vim = VirtualInputManager or game:GetService("VirtualInputManager")
                if vim and gemBtn.AbsolutePosition and gemBtn.AbsoluteSize and gemBtn.AbsoluteSize.X > 0 then
                    local pos = gemBtn.AbsolutePosition
                    local size = gemBtn.AbsoluteSize
                    local cx = pos.X + size.X / 2
                    local cy = pos.Y + size.Y / 2
                    vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                    task.wait(0.04)
                    vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                end
            end)
            success = true

            -- C. ĐỢI VÀ TỰ ĐỘNG BẤM XÁC NHẬN YESBUTTON TRONG BẢNG CONFIRMATIONPANEL
            task.wait(0.3)
            local confirmPanel = (mainFrames and mainFrames:FindFirstChild("Frames") and mainFrames.Frames:FindFirstChild("ConfirmationPanel"))
                or pg:FindFirstChild("ConfirmationPanel", true)

            if confirmPanel then
                local yesBtn = confirmPanel:FindFirstChild("YesButton", true)
                if not yesBtn then
                    for _, desc in ipairs(confirmPanel:GetDescendants()) do
                        if desc:IsA("GuiButton") and desc.Name:lower():find("yes") then
                            yesBtn = desc
                            break
                        end
                    end
                end

                if yesBtn then
                    pcall(function()
                        if firesignal then
                            if yesBtn.Activated then firesignal(yesBtn.Activated) end
                            if yesBtn.MouseButton1Click then firesignal(yesBtn.MouseButton1Click) end
                        end
                        if getconnections then
                            if yesBtn.Activated then
                                for _, c in ipairs(getconnections(yesBtn.Activated)) do c:Fire() end
                            end
                            if yesBtn.MouseButton1Click then
                                for _, c in ipairs(getconnections(yesBtn.MouseButton1Click)) do c:Fire() end
                            end
                        end
                        if yesBtn.MouseButton1Click then yesBtn.MouseButton1Click:Fire() end

                        local vim = VirtualInputManager or game:GetService("VirtualInputManager")
                        if vim and yesBtn.AbsolutePosition and yesBtn.AbsoluteSize and yesBtn.AbsoluteSize.X > 0 then
                            local cx = yesBtn.AbsolutePosition.X + yesBtn.AbsoluteSize.X / 2
                            local cy = yesBtn.AbsolutePosition.Y + yesBtn.AbsoluteSize.Y / 2
                            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                            task.wait(0.04)
                            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                        end
                    end)
                end
            end
        end

        if success then
            return true, "Đã thực hiện Apply Gems thành công!"
        else
            return false, "Không tìm thấy nút ApplyGemsButton trong giao diện"
        end
    end

    -- 2. Tự động kích hoạt Buff x2.75 / x4 Showcase Pedestal (Không bao giờ Unequip quặng của người chơi)
    function ShowcaseBuff.activateBuff(forceReset)
        local base = Utils.getMyBase()
        if not base then
            return false, "Chưa xác định được Base của bạn. Hãy đợi server gán Base hoàn tất."
        end
        local myBaseName = base.Name

        local rem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ShowcasePedestalAction")
        if not rem then return false, "Không tìm thấy ShowcasePedestalAction Remote" end

        local results = {}
        for i = 1, 2 do
            -- Đọc trực tiếp thuộc tính tác giả trên LocalPlayer từ game server
            local isUnlocked = LocalPlayer:GetAttribute("ShowcasePedestal" .. i .. "Unlocked")
            local oreName = LocalPlayer:GetAttribute("ShowcasePedestal" .. i .. "OreName")
            local mult = LocalPlayer:GetAttribute("ShowcasePedestal" .. i .. "Multiplier") or 2.75
            local expiresAt = LocalPlayer:GetAttribute("ShowcasePedestal" .. i .. "BoostExpiresAt")

            if isUnlocked == false then
                table.insert(results, string.format("Bục %d: Chưa mở khóa bục", i))
            elseif not oreName or oreName == "" then
                table.insert(results, string.format("Bục %d: Hãy đặt quặng lên bục trước", i))
            else
                local timeLeft = 0
                if expiresAt and tonumber(expiresAt) then
                    timeLeft = math.max(0, tonumber(expiresAt) - os.time())
                end

                -- Nếu không có Attribute thì gọi GetState từ Remote
                if not expiresAt then
                    pcall(function()
                        local stateRes = rem:InvokeServer(myBaseName, i, "GetState")
                        if stateRes and stateRes.state and stateRes.state.BuffExpiresAt then
                            timeLeft = math.max(0, stateRes.state.BuffExpiresAt - os.time())
                        end
                    end)
                end

                if timeLeft <= 10 then
                    pcall(function()
                        -- Chuẩn lệnh InvokeServer: "ActivateBoost", slot, baseName
                        local res = nil
                        pcall(function() res = rem:InvokeServer("ActivateBoost", i, myBaseName) end)
                        if not res or not res.success then
                            pcall(function() res = rem:InvokeServer(myBaseName, i, "ActivateBuff") end)
                        end
                        if res and res.success then
                            local actMult = (res.state and res.state.Multiplier) or res.Multiplier or mult
                            table.insert(results, string.format("Bục %d (%s): Đã kích hoạt Buff x%s!", i, oreName, tostring(actMult)))
                        else
                            table.insert(results, string.format("Bục %d (%s): Đã gửi lệnh kích hoạt", i, oreName))
                        end
                    end)
                else
                    local mins = math.floor(timeLeft / 60)
                    local secs = timeLeft % 60
                    table.insert(results, string.format("Bục %d (%s x%s): Buff còn %dp %ds", i, oreName, tostring(mult), mins, secs))
                end
            end
        end

        return true, table.concat(results, " | ")
    end
end

return ShowcaseBuff
