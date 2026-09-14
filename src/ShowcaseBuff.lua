--[[
    MODULE: ShowcaseBuff.lua
    Mô tả: Tự động kích hoạt Buff x2.75 từ Showcase Pedestal & Tự động Apply Gems
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

    -- 1. Tự động Apply Gems
    function ShowcaseBuff.applyGems(silent)
        local success = false

        -- A. Tìm nút ApplyGemsButton trong PlayerGui
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local gemBtn = nil
        if pg then
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
        end

        -- B. Kích hoạt nút bằng cả firesignal, getconnections & VirtualInputManager
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
                    task.wait(0.05)
                    vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                end
            end)
            success = true
        end

        -- C. Đồng thời gọi các Remotes liên quan tới Gems nếu có
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, rName in ipairs({"UseLuckySpinRemote", "ApplyGemsRemote", "UseGemsRemote", "ApplyGemRemote", "ApplyGems"}) do
                local rem = remotes:FindFirstChild(rName)
                if rem and rem:IsA("RemoteEvent") then
                    pcall(function() rem:FireServer() end)
                    success = true
                elseif rem and rem:IsA("RemoteFunction") then
                    pcall(function() rem:InvokeServer() end)
                    success = true
                end
            end
        end

        if success then
            return true, "Đã thực hiện Apply Gems thành công!"
        else
            return false, "Không tìm thấy nút ApplyGemsButton trong giao diện"
        end
    end

    -- 2. Tự động kích hoạt Buff x2.75 Showcase Pedestal
    function ShowcaseBuff.activateBuff(forceReset)
        local base = Utils.getMyBase()
        local myBaseName = base and base.Name or "Base4"

        local rem = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ShowcasePedestalAction")
        if not rem then return false, "Không tìm thấy ShowcasePedestalAction Remote" end

        local results = {}
        for i = 1, 2 do
            local stateRes = nil
            pcall(function()
                stateRes = rem:InvokeServer(myBaseName, i, "GetState")
            end)

            local timeLeft = 0
            if stateRes and stateRes.state and stateRes.state.BuffExpiresAt then
                timeLeft = math.max(0, stateRes.state.BuffExpiresAt - os.time())
            end

            if forceReset then
                pcall(function() rem:InvokeServer(myBaseName, i, "Unequip") end)
                task.wait(0.2)
                timeLeft = 0
            end

            if timeLeft <= 10 then
                pcall(function()
                    local res = rem:InvokeServer(myBaseName, i, "ActivateBuff")
                    if res and res.success then
                        local mult = (res.state and res.state.Multiplier) or "2.75"
                        table.insert(results, string.format("Bục %d: Đã kích hoạt Buff x%s!", i, tostring(mult)))
                    else
                        table.insert(results, string.format("Bục %d: Hãy đặt quặng lên bục trước", i))
                    end
                end)
            else
                local mins = math.floor(timeLeft / 60)
                local secs = timeLeft % 60
                table.insert(results, string.format("Bục %d: Buff đang chạy (%dp %ds)", i, mins, secs))
            end
        end


        return true, table.concat(results, " | ")
    end
end

return ShowcaseBuff
