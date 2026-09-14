--[[
    MODULE: AutoRoll.lua
    Mô tả: Hệ thống Auto Roll (Tự mở bảng, bấm START, đóng bảng) & Soi quét mua quặng 6 bục
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

local AutoRoll = {}

function AutoRoll.init(deps)
    local Utils = deps.Utils
    local State = deps.State
    local OresData = deps.OresData
    local Fluent = deps.Fluent

    local recentlyBought = {}

    -- 1. Tìm ProximityPrompt của cần gạt Auto Roller trong Base
    function AutoRoll.getAutoRollerPrompt()
        local base = Utils.getMyBase()
        if not base then return nil end

        local roller = base:FindFirstChild("Roller")
        if not roller then return nil end

        local autoRoller = roller:FindFirstChild("AutoRoller")
        if autoRoller then
            local lever = autoRoller:FindFirstChild("Lever") or autoRoller:FindFirstChildWhichIsA("BasePart", true)
            if lever then
                for _, p in ipairs(lever:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        return p
                    end
                end
            end
        end

        for _, desc in ipairs(roller:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local act = (desc.ActionText or ""):lower()
                if act:find("auto") or act:find("roll") or (desc.Parent and desc.Parent.Name:lower():find("lever")) then
                    return desc
                end
            end
        end

        return nil
    end

    -- 2. Tự bấm nút Prompt hiển thị trên màn hình trong ExpressivePromptsGui (đặc biệt hữu ích trên Mobile/Giả lập)
    function AutoRoll.clickExpressivePromptForLever()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local ep = pg and pg:FindFirstChild("ExpressivePromptsGui")
        if ep then
            for _, desc in ipairs(ep:GetDescendants()) do
                local pName = desc.Parent and desc.Parent.Name:lower() or ""
                local dName = desc.Name:lower()
                if dName:find("roller") or dName:find("lever") or pName:find("roller") or pName:find("lever") then
                    local btn = desc:IsA("GuiButton") and desc or desc:FindFirstChildWhichIsA("GuiButton", true)
                    if btn then
                        pcall(function()
                            if firesignal then
                                firesignal(btn.Activated)
                                firesignal(btn.MouseButton1Click)
                            else
                                btn.MouseButton1Click:Fire()
                            end
                        end)
                        return true
                    end
                end
            end
        end
        return false
    end

    -- 3. Tự động bấm START và đóng bảng AutoRollerPanel khi xuất hiện
    function AutoRoll.handleAutoRollerPanel(maxWait)
        maxWait = maxWait or 1.5
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return false end

        local t0 = tick()
        local panel = nil
        while tick() - t0 <= maxWait do
            local mainFrames = pg:FindFirstChild("MainFrames")
            panel = mainFrames and mainFrames:FindFirstChild("AutoRollerPanel", true)
            if panel and panel.Visible then
                break
            end
            task.wait(0.1)
        end

        if not panel or not panel.Visible then return false end

        -- A. Tìm và bấm nút START trong panel
        local startBtn = nil
        for _, desc in ipairs(panel:GetDescendants()) do
            if desc:IsA("GuiButton") and desc.Visible then
                local n = desc.Name:lower()
                local t = (desc:IsA("TextButton") and desc.Text or ""):lower()
                if (n:find("start") or t:find("start")) and not n:find("restart") then
                    startBtn = desc
                    break
                end
                for _, lbl in ipairs(desc:GetDescendants()) do
                    if lbl:IsA("TextLabel") and lbl.Text:lower():find("start") then
                        startBtn = desc
                        break
                    end
                end
                if startBtn then break end
                local col = desc.BackgroundColor3
                if col.G > 0.5 and col.R < 0.4 and col.B < 0.4 then
                    startBtn = desc
                    break
                end
            end
        end

        if startBtn then
            pcall(function()
                local vim = VirtualInputManager or game:GetService("VirtualInputManager")
                local guiService = GuiService or game:GetService("GuiService")
                if vim and startBtn.AbsolutePosition and startBtn.AbsoluteSize then
                    local pos = startBtn.AbsolutePosition
                    local size = startBtn.AbsoluteSize
                    local inset = guiService and guiService:GetGuiInset() or Vector2.new(0, 0)
                    local cx = pos.X + size.X / 2 + inset.X
                    local cy = pos.Y + size.Y / 2 + inset.Y
                    vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                    task.wait(0.05)
                    vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                end

                if firesignal then
                    firesignal(startBtn.Activated)
                    firesignal(startBtn.MouseButton1Click)
                else
                    startBtn.MouseButton1Click:Fire()
                end
            end)
        end

        task.wait(0.25)

        -- B. Tìm và bấm nút ĐÓNG [X]
        local closeBtn = nil
        local top = panel:FindFirstChild("Top", true)
        if top then
            for _, desc in ipairs(top:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    closeBtn = desc
                    break
                end
            end
        end

        if not closeBtn then
            for _, desc in ipairs(panel:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local n = desc.Name:lower()
                    local t = (desc:IsA("TextButton") and desc.Text or ""):lower()
                    if n:find("close") or n:find("exit") or n:find("cancel") or t == "x" or t:find("close") or t:find("✕") or t:find("✖") then
                        closeBtn = desc
                        break
                    end
                end
            end
        end

        if closeBtn then
            pcall(function()
                if firesignal then
                    firesignal(closeBtn.Activated)
                    firesignal(closeBtn.MouseButton1Click)
                else
                    closeBtn.MouseButton1Click:Fire()
                end
            end)
        end

        task.wait(0.1)
        if panel.Visible then
            pcall(function() panel.Visible = false end)
        end

        return true
    end

    -- 4. Kích hoạt Auto Roll của game (Kết hợp cả 3 phương thức: Lever 3D, Expressive Prompt UI & Direct Panel Open)
    function AutoRoll.triggerGameAutoRoll(force)
        local leverPrompt = AutoRoll.getAutoRollerPrompt()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local prevCF = hrp and hrp.CFrame

        -- Phương thức A: Teleport sát cần gạt vật lý để tương tác
        if leverPrompt and leverPrompt.Parent and leverPrompt.Parent:IsA("BasePart") then
            Utils.teleportTo(leverPrompt.Parent.CFrame + Vector3.new(0, 0.5, 0))
            task.wait(0.25)
            Utils.firePrompt(leverPrompt)
            task.wait(0.15)
        end

        -- Phương thức B: Bấm nút trên ExpressivePromptsGui nếu có
        AutoRoll.clickExpressivePromptForLever()

        -- Phương thức C: Trực tiếp mở AutoRollerPanel nếu chưa mở
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local mainFrames = pg and pg:FindFirstChild("MainFrames")
        local panel = mainFrames and mainFrames:FindFirstChild("AutoRollerPanel", true)
        if panel and not panel.Visible then
            pcall(function() panel.Visible = true end)
        end

        -- Tự động chờ bảng xuất hiện, bấm START và đóng lại ngay lập tức
        AutoRoll.handleAutoRollerPanel(1.5)

        if prevCF then
            Utils.teleportTo(prevCF)
        end

        return true, "Auto Roller"
    end

    -- 5. Nhận diện tên quặng trên bục quay
    function AutoRoll.getOreNameFromPedestal(pedestal)
        if not pedestal then return "Unknown" end

        for _, desc in ipairs(pedestal:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local obj = (desc.ObjectText or ""):lower():gsub("%s+", "")
                if obj ~= "" then
                    if OresData.OreAliases[obj] then return OresData.OreAliases[obj] end
                    for _, ore in ipairs(OresData.SortedOresByLen) do
                        if obj:find(ore:lower():gsub("%s+", "")) then return ore end
                    end
                end
            end
        end

        for _, obj in ipairs({pedestal, pedestal:FindFirstChild("LocalRollingOreDisplay")}) do
            if obj then
                for _, attrVal in pairs(obj:GetAttributes()) do
                    if type(attrVal) == "string" and attrVal ~= "" then
                        local clean = attrVal:lower():gsub("%s+", "")
                        if OresData.OreAliases[clean] then return OresData.OreAliases[clean] end
                        for _, ore in ipairs(OresData.SortedOresByLen) do
                            if clean == ore:lower():gsub("%s+", "") or clean:find(ore:lower():gsub("%s+", "")) then
                                return ore
                            end
                        end
                    end
                end
            end
        end

        for _, desc in ipairs(pedestal:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Text ~= "" then
                local txt = desc.Text:lower():gsub("%s+", "")
                if not txt:find("buy") and not txt:find("press") and not txt:find("cost") and not txt:find("%$") and not txt:find("pedestal") then
                    for _, ore in ipairs(OresData.SortedOresByLen) do
                        if txt:find(ore:lower():gsub("%s+", "")) then return ore end
                    end
                end
            end
        end

        for _, desc in ipairs(pedestal:GetDescendants()) do
            local dName = desc.Name:lower():gsub("%s+", "")
            if OresData.OreAliases[dName] then return OresData.OreAliases[dName] end
            for _, ore in ipairs(OresData.SortedOresByLen) do
                local oClean = ore:lower():gsub("%s+", "")
                if dName == oClean or (dName:find(oClean) and not dName:find("pedestal") and not dName:find("display") and not dName:find("prompt")) then
                    return ore
                end
            end
        end

        return "Unknown"
    end

    function AutoRoll.isOreWanted(oreName)
        if State.BuyAllPedestals then return true end
        if not oreName or oreName == "Unknown" then return false end

        local oClean = oreName:lower():gsub("%s+", "")
        for wanted, active in pairs(State.WantedBuyOres) do
            if active then
                local wClean = wanted:lower():gsub("%s+", "")
                if oClean == wClean or oClean:find(wClean) or wClean:find(oClean) then
                    return true
                end
            end
        end
        return false
    end

    -- 6. Quét & Mua quặng trên 6 bục (và tự động bật lại Auto Roll sau khi mua xong)
    function AutoRoll.checkAndBuyMatchingPedestals()
        local base = Utils.getMyBase()
        if not base or not base:FindFirstChild("OrePedestals") then return 0 end

        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local originCF = root and root.CFrame

        local boughtCount = 0
        local now = tick()

        for i = 1, 6 do
            local pedestal = base.OrePedestals:FindFirstChild("RolledOrePedestal" .. i)
            if pedestal then
                local buyPrompt = nil
                for _, p in ipairs(pedestal:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.Enabled then
                        local act = p.ActionText:lower()
                        if (act:find("buy") or act:find("claim") or act:find("take") or act == "") and not act:find("place") then
                            buyPrompt = p
                            break
                        end
                    end
                end

                if buyPrompt then
                    if not recentlyBought[i] or (now - recentlyBought[i] > 1.5) then
                        local oreName = AutoRoll.getOreNameFromPedestal(pedestal)
                        if AutoRoll.isOreWanted(oreName) then
                            recentlyBought[i] = now
                            if buyPrompt.Parent and buyPrompt.Parent:IsA("BasePart") then
                                Utils.teleportTo(buyPrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
                                task.wait(0.08)
                            end
                            Utils.firePrompt(buyPrompt)
                            task.wait(0.12)
                            boughtCount = boughtCount + 1
                            Fluent:Notify({
                                Title = "💎 ĐÃ MUA QUẶNG!",
                                Content = string.format("Bục %d: %s", i, oreName),
                                Duration = 3
                            })
                        end
                    end
                end
            end
        end

        -- Quay lại vị trí đứng ban đầu sau khi mua xong & TỰ ĐỘNG BẬT LẠI AUTOROLL
        if boughtCount > 0 then
            if originCF then
                Utils.teleportTo(originCF)
            end
            if State.AutoReRollAfterBuy then
                task.wait(0.4)
                local ok = AutoRoll.triggerGameAutoRoll(false)
                if ok then
                    Fluent:Notify({
                        Title = "🔄 TIẾP TỤC AUTO ROLL",
                        Content = "Đã tự động kích hoạt lại Auto Roll sau khi mua quặng!",
                        Duration = 2.5
                    })
                end
            end
        end

        return boughtCount
    end
end

return AutoRoll
