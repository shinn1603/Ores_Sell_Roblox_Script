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
    local lastMoneyWarnTime = {}
    local lastTriggerRollTime = 0

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

    -- 2. Tự bấm nút Prompt hiển thị trên màn hình trong ExpressivePromptsGui
    function AutoRoll.clickExpressivePromptForLever()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local ep = pg and pg:FindFirstChild("ExpressivePromptsGui")
        if not ep then return false end

        for _, desc in ipairs(ep:GetDescendants()) do
            local isMatch = false
            if desc:IsA("TextLabel") and desc.Text:upper():find("AUTO ROLL") then
                isMatch = true
            elseif desc.Name:find("AutoRoller") or desc.Name:find("Lever") then
                isMatch = true
            end

            if isMatch then
                local target = desc:FindFirstAncestorWhichIsA("CanvasGroup") 
                            or desc:FindFirstAncestorWhichIsA("GuiButton") 
                            or desc:FindFirstAncestorWhichIsA("Frame") 
                            or desc

                if target then
                    pcall(function()
                        if firesignal then
                            if target:IsA("GuiButton") then
                                if target.Activated then firesignal(target.Activated) end
                                if target.MouseButton1Click then firesignal(target.MouseButton1Click) end
                            end
                            for _, btn in ipairs(target:GetDescendants()) do
                                if btn:IsA("GuiButton") then
                                    if btn.Activated then firesignal(btn.Activated) end
                                    if btn.MouseButton1Click then firesignal(btn.MouseButton1Click) end
                                end
                            end
                        end
                    end)

                    pcall(function()
                        local vim = VirtualInputManager or game:GetService("VirtualInputManager")
                        if vim and target.AbsolutePosition and target.AbsoluteSize and target.AbsoluteSize.X > 0 then
                            local pos = target.AbsolutePosition
                            local size = target.AbsoluteSize
                            local cx = pos.X + size.X / 2
                            local cy = pos.Y + size.Y / 2
                            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                            task.wait(0.06)
                            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                        end
                    end)
                    return true
                end
            end
        end
        return false
    end

    -- 3. Tự động bấm START và đóng bảng AutoRollerPanel khi xuất hiện
    function AutoRoll.handleAutoRollerPanel(maxWait)
        maxWait = maxWait or 3.0
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if not pg then return false end

        local t0 = tick()
        local panel = nil
        while tick() - t0 <= maxWait do
            local mainFrames = pg:FindFirstChild("MainFrames")
            panel = mainFrames and (mainFrames:FindFirstChild("AutoRollerPanel", true) or (mainFrames:FindFirstChild("Frames") and mainFrames.Frames:FindFirstChild("AutoRollerPanel")))
            if panel and panel.Visible then
                break
            end
            task.wait(0.1)
        end

        if not panel or not panel.Visible then return false end

        -- A. Tìm nút START trong panel (TextLabel hoặc TextButton hoặc nút màu xanh lá)
        local startBtn = nil
        for _, desc in ipairs(panel:GetDescendants()) do
            local txt = ""
            if desc:IsA("TextLabel") or desc:IsA("TextButton") then
                txt = desc.Text:upper()
            end
            if txt:find("START") and not txt:find("RESTART") and not txt:find("STOP") then
                startBtn = desc:FindFirstAncestorWhichIsA("GuiButton") 
                        or (desc:IsA("GuiButton") and desc)
                        or desc.Parent
                if startBtn then break end
            end
        end

        if not startBtn then
            for _, desc in ipairs(panel:GetDescendants()) do
                if (desc:IsA("GuiButton") or desc:IsA("Frame")) and desc.Visible then
                    local n = desc.Name:lower()
                    local t = (desc:IsA("TextButton") and desc.Text or ""):lower()
                    if (n:find("start") or t:find("start")) and not n:find("restart") and not n:find("stop") then
                        startBtn = desc
                        break
                    end
                    local col = desc.BackgroundColor3
                    if col and col.G > 0.5 and col.R < 0.4 and col.B < 0.4 then
                        startBtn = desc
                        break
                    end
                end
            end
        end

        -- Bấm START bằng cả 2 phương thức: firesignal & VirtualInputManager (đúng 1 lần)
        if startBtn then
            pcall(function()
                if firesignal then
                    if startBtn.Activated then firesignal(startBtn.Activated) end
                    if startBtn.MouseButton1Click then firesignal(startBtn.MouseButton1Click) end
                elseif startBtn.MouseButton1Click then
                    startBtn.MouseButton1Click:Fire()
                end
            end)
            pcall(function()
                local vim = VirtualInputManager or game:GetService("VirtualInputManager")
                if vim and startBtn.AbsolutePosition and startBtn.AbsoluteSize and startBtn.AbsoluteSize.X > 0 then
                    local pos = startBtn.AbsolutePosition
                    local size = startBtn.AbsoluteSize
                    local cx = pos.X + size.X / 2
                    local cy = pos.Y + size.Y / 2
                    vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                    task.wait(0.06)
                    vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                end
            end)
        end

        -- Đợi 0.6s để game xử lý lệnh Start Roll và bắt đầu quay quặng
        task.wait(0.6)

        -- B. Tìm nút ĐÓNG [X] (nút đỏ góc trên hoặc chữ X)
        local closeBtn = nil
        local top = panel:FindFirstChild("Top", true)
        if top then
            for _, desc in ipairs(top:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local n = desc.Name:lower()
                    local t = (desc:IsA("TextButton") and desc.Text or ""):lower()
                    if n:find("close") or n:find("exit") or n:find("x") or t == "x" or t:find("close") or t:find("✕") or t:find("✖") then
                        closeBtn = desc
                        break
                    end
                end
            end
            if not closeBtn then
                for _, desc in ipairs(top:GetDescendants()) do
                    if desc:IsA("GuiButton") and desc.Visible then
                        closeBtn = desc
                        break
                    end
                end
            end
        end

        if not closeBtn then
            for _, desc in ipairs(panel:GetDescendants()) do
                if desc:IsA("GuiButton") and desc.Visible then
                    local n = desc.Name:lower()
                    local t = (desc:IsA("TextButton") and desc.Text or ""):lower()
                    local col = desc.BackgroundColor3
                    if n:find("close") or n:find("exit") or t == "x" or t:find("close") or t:find("✕") or t:find("✖") or (col.R > 0.6 and col.G < 0.3 and col.B < 0.3) then
                        closeBtn = desc
                        break
                    end
                end
            end
        end

        -- Bấm nút Đóng
        if closeBtn then
            pcall(function()
                if firesignal then
                    if closeBtn.Activated then firesignal(closeBtn.Activated) end
                    if closeBtn.MouseButton1Click then firesignal(closeBtn.MouseButton1Click) end
                elseif closeBtn.MouseButton1Click then
                    closeBtn.MouseButton1Click:Fire()
                end
            end)
            pcall(function()
                local vim = VirtualInputManager or game:GetService("VirtualInputManager")
                if vim and closeBtn.AbsolutePosition and closeBtn.AbsoluteSize and closeBtn.AbsoluteSize.X > 0 then
                    local pos = closeBtn.AbsolutePosition
                    local size = closeBtn.AbsoluteSize
                    local cx = pos.X + size.X / 2
                    local cy = pos.Y + size.Y / 2
                    vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                    task.wait(0.06)
                    vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                end
            end)
        end

        task.wait(0.4)

        -- C. Dọn sạch lớp màn hình mờ xám (Dimmer / Blur Effect / Overlay) của game
        Utils.clearBlurAndDimmer()

        if panel.Visible then
            pcall(function() panel.Visible = false end)
        end

        return true
    end

    -- 4. Kích hoạt Auto Roll của game (Thao tác gạt cần Auto Roller thực tế trong Base)
    function AutoRoll.triggerGameAutoRoll(force)
        local now = tick()
        if not force and (now - lastTriggerRollTime < 3.5) then
            return false, "Thao tác gạt cần quá nhanh, đang chờ cooldown"
        end

        -- RÀNG BUỘC: Nếu trên bục đang có quặng trúng mục tiêu nhưng chưa mua được (ví dụ do đang tích lũy tiền),
        -- TUYỆT ĐỐI KHÔNG GẠT CẦN ROLL LẠI vì sẽ làm mất quặng quý!
        if not force then
            local hasPending, pendingOre, pedIdx = AutoRoll.hasPendingWantedOreOnPedestals()
            if hasPending then
                return false, string.format("Bục %d đang có %s chờ mua, tạm dừng roll để bảo vệ quặng!", pedIdx, pendingOre)
            end
        end
        lastTriggerRollTime = now

        local leverPrompt = AutoRoll.getAutoRollerPrompt()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local prevCF = hrp and hrp.CFrame

        -- Bước 1: Tìm tọa độ Cần Gạt
        local leverCF = nil
        if leverPrompt and leverPrompt.Parent then
            if leverPrompt.Parent:IsA("BasePart") then
                leverCF = leverPrompt.Parent.CFrame
            elseif leverPrompt.Parent:IsA("Model") then
                leverCF = leverPrompt.Parent:GetPivot()
            end
        end

        if not leverCF then
            local base = Utils.getMyBase()
            local roller = base and base:FindFirstChild("Roller")
            local autoRoller = roller and roller:FindFirstChild("AutoRoller")
            if autoRoller then
                leverCF = autoRoller:GetPivot()
            end
        end

        -- Bước 2: Teleport đến đứng an toàn ngay trên sàn cạnh cần gạt (1.5 studs trên part, KHÔNG dùng LookVector đâm xuyên tường hay kẹt mesh!)
        if leverCF and hrp then
            local standCF = leverCF + Vector3.new(0, 1.5, 0)
            Utils.teleportTo(standCF)
            task.wait(0.2)
        end

        -- Bước 3: Kích hoạt Cần Gạt vật lý qua ProximityPrompt
        if leverPrompt then
            Utils.firePrompt(leverPrompt)
            task.wait(0.2)
        end

        -- Bước 4: Kích hoạt nút Prompt trên màn hình nếu có (ExpressivePromptsGui)
        AutoRoll.clickExpressivePromptForLever()
        task.wait(0.2)

        -- Bước 5: Chờ bảng AutoRollerPanel bung ra -> bấm START -> đóng bảng
        local panelHandled = AutoRoll.handleAutoRollerPanel(2.5)

        -- Bước 6: Dọn sạch mọi hiệu ứng xám/mờ màn hình còn sót lại
        Utils.clearBlurAndDimmer()

        -- Bước 7: Cất hết tool/vật phẩm vào túi, không cầm trên tay
        Utils.unequipAllTools()

        -- Bước 8: Trả nhân vật về vị trí ban đầu
        if prevCF then
            Utils.teleportTo(prevCF)
        end

        return panelHandled, "Auto Roller"
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

    -- Lấy giá mua của quặng trên bục quay
    function AutoRoll.getPedestalPrice(pedestal, buyPrompt)
        if not pedestal then return nil end

        -- 1. Kiểm tra text trên buyPrompt (ActionText: "Buy ($50,000)", ObjectText, v.v.)
        if buyPrompt then
            if buyPrompt.ActionText and buyPrompt.ActionText ~= "" then
                local p = Utils.parseMoneyString(buyPrompt.ActionText)
                if p and p > 0 then return p end
            end
            if buyPrompt.ObjectText and buyPrompt.ObjectText ~= "" then
                local p = Utils.parseMoneyString(buyPrompt.ObjectText)
                if p and p > 0 then return p end
            end
        end

        -- 2. Kiểm tra Attributes trên bục hoặc prompt
        for _, obj in ipairs({pedestal, buyPrompt, pedestal:FindFirstChild("LocalRollingOreDisplay")}) do
            if obj then
                for _, attr in ipairs({"Price", "Cost", "PriceNumber", "OrePrice", "Value", "Amount"}) do
                    local val = obj:GetAttribute(attr)
                    if type(val) == "number" and val > 0 then
                        return val
                    elseif type(val) == "string" then
                        local p = Utils.parseMoneyString(val)
                        if p and p > 0 then return p end
                    end
                end
            end
        end

        -- 3. Kiểm tra ValueObject con
        for _, name in ipairs({"Price", "Cost", "PriceValue", "Value"}) do
            local vo = pedestal:FindFirstChild(name)
            if vo and vo:IsA("ValueBase") then
                if type(vo.Value) == "number" and vo.Value > 0 then
                    return vo.Value
                elseif type(vo.Value) == "string" then
                    local p = Utils.parseMoneyString(vo.Value)
                    if p and p > 0 then return p end
                end
            end
        end

        -- 4. Kiểm tra TextLabel con (BillboardGui chứa ký tự $ hoặc chữ Cost/Price)
        for _, desc in ipairs(pedestal:GetDescendants()) do
            if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
                local txt = desc.Text
                if txt:find("%$") or txt:lower():find("cost") or txt:lower():find("price") then
                    local p = Utils.parseMoneyString(txt)
                    if p and p > 0 then return p end
                end
            end
        end

        return nil
    end

    -- Kiểm tra xem hiện có quặng mục tiêu nào trên 6 bục đang chờ mua (chưa mua được vì thiếu tiền)
    function AutoRoll.hasPendingWantedOreOnPedestals()
        local base = Utils.getMyBase()
        if not base or not base:FindFirstChild("OrePedestals") then return false end

        local playerMoney = Utils.getPlayerMoney()
        if not playerMoney then return false end -- Nếu không xác định được tiền thì không chặn roll

        for i = 1, 6 do
            local pedestal = base.OrePedestals:FindFirstChild("RolledOrePedestal" .. i)
            if pedestal then
                local oreName = AutoRoll.getOreNameFromPedestal(pedestal)
                if AutoRoll.isOreWanted(oreName) then
                    for _, p in ipairs(pedestal:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.Enabled then
                            local act = p.ActionText:lower()
                            if (act:find("buy") or act:find("claim") or act:find("take") or act == "") and not act:find("place") then
                                local orePrice = AutoRoll.getPedestalPrice(pedestal, p)
                                -- Chỉ trả về true khi thực sự thiếu tiền mua quặng này
                                if orePrice and playerMoney < orePrice then
                                    return true, oreName, i
                                end
                            end
                        end
                    end
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
        local hasWaitingForMoney = false
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
                            -- RÀNG BUỘC: Kiểm tra số tiền hiện tại trước khi bay tới mua
                            local orePrice = AutoRoll.getPedestalPrice(pedestal, buyPrompt)
                            local playerMoney = Utils.getPlayerMoney()

                            if playerMoney and orePrice and playerMoney < orePrice then
                                -- Chưa đủ tiền: KHÔNG bay tới, KHÔNG bấm prompt, đợi đủ hẳn mua!
                                hasWaitingForMoney = true
                                if not lastMoneyWarnTime[i] or (now - lastMoneyWarnTime[i] > 10) then
                                    lastMoneyWarnTime[i] = now
                                    Fluent:Notify({
                                        Title = "⏳ CHƯA ĐỦ TIỀN MUA",
                                        Content = string.format("Bục %d: %s (Cần: $%s | Có: $%s). Đang đợi tích lũy đủ tiền...", i, oreName, Utils.formatNumber(orePrice), Utils.formatNumber(playerMoney)),
                                        Duration = 4
                                    })
                                end
                            else
                                -- Đủ tiền (hoặc không giới hạn): Tiến hành mua ngay
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
                                    Content = string.format("Bục %d: %s%s", i, oreName, orePrice and (" ($" .. Utils.formatNumber(orePrice) .. ")") or ""),
                                    Duration = 3
                                })
                            end
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
            -- Chỉ kích hoạt Roll lại khi KHÔNG còn bục nào đang giữ quặng quý chờ đủ tiền
            if State.AutoReRollAfterBuy and not hasWaitingForMoney then
                task.wait(0.4)
                local ok, msg = AutoRoll.triggerGameAutoRoll(false)
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
