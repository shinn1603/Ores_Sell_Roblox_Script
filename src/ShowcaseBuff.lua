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

    -- 1. Tự động Apply Gems
    function ShowcaseBuff.applyGems(silent)
        local success = false
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, rName in ipairs({"UseLuckySpinRemote", "ApplyGemsRemote", "UseGemsRemote"}) do
                local rem = remotes:FindFirstChild(rName)
                if rem and rem:IsA("RemoteEvent") then
                    pcall(function() rem:FireServer() end)
                    success = true
                end
            end
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local mainFrames = pg:FindFirstChild("MainFrames")
            local topPane = mainFrames and mainFrames:FindFirstChild("MenuFrames") and mainFrames.MenuFrames:FindFirstChild("TopPane")
            if topPane then
                local row1 = topPane:FindFirstChild("Row1")
                local gemBtn = (row1 and row1:FindFirstChild("ApplyGemsButton")) or topPane:FindFirstChild("ApplyGemsButton", true)
                if gemBtn and gemBtn:IsA("GuiButton") and gemBtn.Visible then
                    pcall(function()
                        if firesignal then
                            firesignal(gemBtn.Activated)
                            firesignal(gemBtn.MouseButton1Click)
                        else
                            gemBtn.MouseButton1Click:Fire()
                        end
                    end)
                    success = true
                end
            end
        end
        return success
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

        -- Nếu có bục đang trống (Place Ore) -> Cầm quặng đặt lên bục
        local bases = Workspace:FindFirstChild("Bases")
        local bObj = bases and (bases:FindFirstChild(myBaseName) or bases:FindFirstChild("Base4"))
        if bObj then
            for _, name in ipairs({"OreShowcasePedestal1", "OreShowcasePedestal2"}) do
                local ped = bObj:FindFirstChild(name)
                if ped then
                    for _, p in ipairs(ped:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.Enabled and p.ActionText == "Place Ore" then
                            local tool = Utils.equipToolFromWhitelist(nil)
                            if tool then
                                if p.Parent and p.Parent:IsA("BasePart") then Utils.teleportTo(p.Parent.CFrame) end
                                task.wait(0.1)
                                Utils.firePrompt(p)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end

        return true, table.concat(results, " | ")
    end
end

return ShowcaseBuff
