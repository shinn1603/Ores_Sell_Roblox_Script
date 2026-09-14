--[[
    MODULE: UI.lua
    Mô tả: Toàn bộ giao diện Fluent UI, Floating Button tròn & Hệ thống chọn 81 loại quặng
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

local UI = {}

function UI.init(deps)
    local Fluent = deps.Fluent
    local SaveManager = deps.SaveManager
    local InterfaceManager = deps.InterfaceManager
    local State = deps.State
    local OresData = deps.OresData
    local Utils = deps.Utils
    local AutoRoll = deps.AutoRoll
    local SmartFuser = deps.SmartFuser
    local MoneyPipeline = deps.MoneyPipeline
    local ShowcaseBuff = deps.ShowcaseBuff
    local ConfigManager = deps.ConfigManager

    -- 1. KHỞI TẠO CỬA SỔ FLUENT UI
    local Window = Fluent:CreateWindow({
        Title = "Sell Ores Hub",
        SubTitle = "v7.8 Ultimate PRO (Modular & AutoRoll Base4)",
        TabWidth = 150,
        Size = UDim2.fromOffset(620, 500),
        Acrylic = false,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.RightControl
    })

    -- 2. NÚT NỔI TRÒN (FLOATING TOGGLE BUTTON)
    if CoreGui:FindFirstChild("SellOresFloatingToggleGui") then
        CoreGui.SellOresFloatingToggleGui:Destroy()
    end

    local floatGui = Instance.new("ScreenGui")
    floatGui.Name = "SellOresFloatingToggleGui"
    floatGui.ResetOnSpawn = false
    floatGui.Parent = (gethui and gethui()) or CoreGui

    local floatBtn = Instance.new("TextButton")
    floatBtn.Name = "FloatingButton"
    floatBtn.Size = UDim2.fromOffset(50, 50)
    floatBtn.Position = UDim2.new(0.02, 0, 0.45, 0)
    floatBtn.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
    floatBtn.BorderSizePixel = 0
    floatBtn.AutoButtonColor = true
    floatBtn.Visible = false
    floatBtn.Active = true
    floatBtn.Text = "💎"
    floatBtn.TextSize = 24
    floatBtn.Font = Enum.Font.GothamBold
    floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    floatBtn.Parent = floatGui

    local floatCorner = Instance.new("UICorner")
    floatCorner.CornerRadius = UDim.new(1, 0)
    floatCorner.Parent = floatBtn

    local floatStroke = Instance.new("UIStroke")
    floatStroke.Color = Color3.fromRGB(0, 220, 255)
    floatStroke.Thickness = 2
    floatStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    floatStroke.Parent = floatBtn

    local restoringDebounce = false
    local function restoreFluentWindow()
        if restoringDebounce then return end
        restoringDebounce = true
        pcall(function()
            if Window then
                if Window.Minimized then
                    Window:Minimize()
                end
                Window.Minimized = false
                if Window.Root then
                    Window.Root.Visible = true
                end
            end
            floatBtn.Visible = false
        end)
        task.wait(0.3)
        restoringDebounce = false
    end

    local isDragging = false
    local dragStart = nil
    local startPos = nil
    local totalDragDist = 0

    floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = floatBtn.Position
            totalDragDist = 0

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    floatBtn.InputChanged:Connect(function(input)
        if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            totalDragDist = delta.Magnitude
            floatBtn.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    floatBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if totalDragDist < 8 then
                restoreFluentWindow()
            end
            isDragging = false
        end
    end)

    task.spawn(function()
        while true do
            pcall(function()
                if Window and Window.Root then
                    local isHidden = (Window.Minimized == true) or (Window.Root.Visible == false)
                    if isHidden then
                        if not floatBtn.Visible then floatBtn.Visible = true end
                    else
                        if floatBtn.Visible then floatBtn.Visible = false end
                    end
                end
            end)
            task.wait(0.3)
        end
    end)

    -- 3. BỘ CHỌN 81 QUẶNG TÍCH HỢP TRỰC TIẾP
    local function buildIntegratedOreSelector(parentTab, titleText, descText, targetStateTable, quickSelectPreset)
        parentTab:AddParagraph({
            Title = titleText,
            Content = descText
        })

        local container = parentTab:AddParagraph({
            Title = "DANH SÁCH 81 LOẠI QUẶNG",
            Content = "Đang dựng danh sách chọn quặng trực quan..."
        })

        local card = nil
        pcall(function()
            if container and container.Frame then
                card = container.Frame
            end
        end)

        if not card then
            for oreName, isSelected in pairs(targetStateTable) do
                parentTab:AddToggle("OreToggle_" .. oreName:gsub("%s+", ""), {
                    Title = oreName,
                    Default = isSelected
                }):OnChanged(function(val) targetStateTable[oreName] = val end)
            end
            return function() end
        end

        for _, child in ipairs(card:GetChildren()) do
            if not child:IsA("UIStroke") and not child:IsA("UICorner") then
                child.Visible = false
            end
        end

        card.Size = UDim2.new(1, 0, 0, 310)
        card.BackgroundTransparency = 0.05
        card.BackgroundColor3 = Color3.fromRGB(18, 20, 28)

        local searchFrame = Instance.new("Frame")
        searchFrame.Size = UDim2.new(1, -16, 0, 28)
        searchFrame.Position = UDim2.new(0, 8, 0, 8)
        searchFrame.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
        searchFrame.BorderSizePixel = 0
        searchFrame.Parent = card
        Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 5)

        local searchBox = Instance.new("TextBox")
        searchBox.Size = UDim2.new(1, -34, 1, 0)
        searchBox.Position = UDim2.new(0, 8, 0, 0)
        searchBox.BackgroundTransparency = 1
        searchBox.PlaceholderText = "🔍 Gõ tên quặng để tìm nhanh..."
        searchBox.PlaceholderColor3 = Color3.fromRGB(130, 135, 150)
        searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextSize = 12
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.ClearTextOnFocus = false
        searchBox.Text = ""
        searchBox.Parent = searchFrame

        local clearSearchBtn = Instance.new("TextButton")
        clearSearchBtn.Size = UDim2.new(0, 26, 0, 26)
        clearSearchBtn.Position = UDim2.new(1, -27, 0, 1)
        clearSearchBtn.BackgroundTransparency = 1
        clearSearchBtn.Text = "✕"
        clearSearchBtn.TextColor3 = Color3.fromRGB(160, 165, 175)
        clearSearchBtn.Font = Enum.Font.GothamBold
        clearSearchBtn.TextSize = 12
        clearSearchBtn.Parent = searchFrame

        local oreScroll = Instance.new("ScrollingFrame")
        oreScroll.Size = UDim2.new(1, -16, 0, 160)
        oreScroll.Position = UDim2.new(0, 8, 0, 40)
        oreScroll.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
        oreScroll.BorderSizePixel = 0
        oreScroll.ScrollBarThickness = 5
        oreScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 220, 255)
        oreScroll.Parent = card
        Instance.new("UICorner", oreScroll).CornerRadius = UDim.new(0, 6)

        local grid = Instance.new("UIGridLayout")
        grid.CellSize = UDim2.new(0.485, 0, 0, 30)
        grid.CellPadding = UDim2.new(0.02, 0, 0, 6)
        grid.SortOrder = Enum.SortOrder.Name
        grid.Parent = oreScroll

        local oreButtons = {}

        local displayBox = Instance.new("Frame")
        displayBox.Size = UDim2.new(1, -16, 0, 60)
        displayBox.Position = UDim2.new(0, 8, 0, 202)
        displayBox.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
        displayBox.BorderSizePixel = 0
        displayBox.Parent = card
        Instance.new("UICorner", displayBox).CornerRadius = UDim.new(0, 6)

        local dispTitle = Instance.new("TextLabel")
        dispTitle.Size = UDim2.new(1, -12, 0, 18)
        dispTitle.Position = UDim2.new(0, 6, 0, 4)
        dispTitle.BackgroundTransparency = 1
        dispTitle.TextColor3 = Color3.fromRGB(0, 220, 255)
        dispTitle.Font = Enum.Font.GothamBold
        dispTitle.TextSize = 12
        dispTitle.TextXAlignment = Enum.TextXAlignment.Left
        dispTitle.Text = "📋 Quặng Đang Chọn:"
        dispTitle.Parent = displayBox

        local dispScroll = Instance.new("ScrollingFrame")
        dispScroll.Size = UDim2.new(1, -12, 0, 34)
        dispScroll.Position = UDim2.new(0, 6, 0, 22)
        dispScroll.BackgroundTransparency = 1
        dispScroll.BorderSizePixel = 0
        dispScroll.ScrollBarThickness = 4
        dispScroll.Parent = displayBox

        local dispContent = Instance.new("TextLabel")
        dispContent.Size = UDim2.new(1, 0, 1, 0)
        dispContent.BackgroundTransparency = 1
        dispContent.TextColor3 = Color3.fromRGB(220, 225, 235)
        dispContent.Font = Enum.Font.Gotham
        dispContent.TextSize = 11
        dispContent.TextXAlignment = Enum.TextXAlignment.Left
        dispContent.TextYAlignment = Enum.TextYAlignment.Top
        dispContent.TextWrapped = true
        dispContent.Parent = dispScroll

        local function updateSummaryDisplay()
            local selectedList = {}
            for oreName, isSelected in pairs(targetStateTable) do
                if isSelected then table.insert(selectedList, oreName) end
            end
            table.sort(selectedList)

            dispTitle.Text = string.format("📋 Quặng Đã Chọn (%d loại):", #selectedList)
            dispContent.Text = (#selectedList > 0) and table.concat(selectedList, ", ") or "(Chưa chọn quặng nào)"
            dispScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(34, math.ceil(#selectedList / 4) * 16))
        end

        local function refreshButtonVisual(btn, oreName)
            local isSelected = targetStateTable[oreName] == true
            if isSelected then
                btn.Text = "[✓] " .. oreName
                btn.Font = Enum.Font.GothamBold
                btn.TextColor3 = Color3.fromRGB(0, 255, 230)
                btn.BackgroundColor3 = Color3.fromRGB(16, 48, 68)
                if btn:FindFirstChild("Stroke") then
                    btn.Stroke.Color = Color3.fromRGB(0, 220, 255)
                end
            else
                btn.Text = "[  ] " .. oreName
                btn.Font = Enum.Font.Gotham
                btn.TextColor3 = Color3.fromRGB(160, 165, 175)
                btn.BackgroundColor3 = Color3.fromRGB(22, 25, 34)
                if btn:FindFirstChild("Stroke") then
                    btn.Stroke.Color = Color3.fromRGB(36, 40, 52)
                end
            end
        end

        local function refreshAllVisuals()
            for _, item in ipairs(oreButtons) do
                refreshButtonVisual(item.Button, item.Name)
            end
            updateSummaryDisplay()
        end

        for _, ore in ipairs(OresData.AllGameOres) do
            local btn = Instance.new("TextButton")
            btn.Name = ore
            btn.TextSize = 11
            btn.AutoButtonColor = true
            btn.BorderSizePixel = 0
            btn.Parent = oreScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

            local bStroke = Instance.new("UIStroke")
            bStroke.Name = "Stroke"
            bStroke.Thickness = 1
            bStroke.Parent = btn

            refreshButtonVisual(btn, ore)

            btn.MouseButton1Click:Connect(function()
                targetStateTable[ore] = not targetStateTable[ore]
                refreshButtonVisual(btn, ore)
                updateSummaryDisplay()
            end)

            table.insert(oreButtons, { Name = ore, Button = btn })
        end

        local function filterOres(query)
            query = query:lower():gsub("%s+", "")
            local visibleCount = 0
            for _, item in ipairs(oreButtons) do
                local cleanName = item.Name:lower():gsub("%s+", "")
                if query == "" or cleanName:find(query) then
                    item.Button.Visible = true
                    visibleCount = visibleCount + 1
                else
                    item.Button.Visible = false
                end
            end
            oreScroll.CanvasSize = UDim2.new(0, 0, 0, math.ceil(visibleCount / 2) * 36 + 10)
        end

        searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterOres(searchBox.Text) end)
        clearSearchBtn.MouseButton1Click:Connect(function() searchBox.Text = ""; filterOres("") end)

        filterOres("")
        updateSummaryDisplay()

        local actionsFrame = Instance.new("Frame")
        actionsFrame.Size = UDim2.new(1, -16, 0, 32)
        actionsFrame.Position = UDim2.new(0, 8, 0, 268)
        actionsFrame.BackgroundTransparency = 1
        actionsFrame.Parent = card

        local aLayout = Instance.new("UIListLayout")
        aLayout.FillDirection = Enum.FillDirection.Horizontal
        aLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        aLayout.Padding = UDim.new(0, 8)
        aLayout.Parent = actionsFrame

        local btnPreset = Instance.new("TextButton")
        btnPreset.Size = UDim2.new(0.38, 0, 1, 0)
        btnPreset.BackgroundColor3 = Color3.fromRGB(26, 60, 90)
        btnPreset.TextColor3 = Color3.fromRGB(0, 240, 255)
        btnPreset.Font = Enum.Font.GothamBold
        btnPreset.TextSize = 11
        btnPreset.Text = (quickSelectPreset == "buy") and "⭐ Chọn Toàn Bộ Quặng Xịn" or "🪵 Chọn Quặng Rác Nung"
        btnPreset.Parent = actionsFrame
        Instance.new("UICorner", btnPreset).CornerRadius = UDim.new(0, 5)

        local btnSelectAllFiltered = Instance.new("TextButton")
        btnSelectAllFiltered.Size = UDim2.new(0.32, 0, 1, 0)
        btnSelectAllFiltered.BackgroundColor3 = Color3.fromRGB(30, 80, 50)
        btnSelectAllFiltered.TextColor3 = Color3.fromRGB(0, 255, 150)
        btnSelectAllFiltered.Font = Enum.Font.GothamBold
        btnSelectAllFiltered.TextSize = 11
        btnSelectAllFiltered.Text = "✨ Chọn Hết Đang Lọc"
        btnSelectAllFiltered.Parent = actionsFrame
        Instance.new("UICorner", btnSelectAllFiltered).CornerRadius = UDim.new(0, 5)

        local btnClear = Instance.new("TextButton")
        btnClear.Size = UDim2.new(0.26, 0, 1, 0)
        btnClear.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
        btnClear.TextColor3 = Color3.fromRGB(255, 120, 120)
        btnClear.Font = Enum.Font.GothamBold
        btnClear.TextSize = 11
        btnClear.Text = "🗑️ Bỏ Chọn Hết"
        btnClear.Parent = actionsFrame
        Instance.new("UICorner", btnClear).CornerRadius = UDim.new(0, 5)

        btnPreset.MouseButton1Click:Connect(function()
            if quickSelectPreset == "buy" then
                for _, ore in ipairs(OresData.AllGameOres) do
                    local l = ore:lower()
                    if l:find("star") or l:find("god") or l:find("divine") or l:find("infinity") or l:find("dragon") or l:find("core") or l:find("world") or l:find("reality") or l:find("singularity") then
                        targetStateTable[ore] = true
                    end
                end
            else
                for _, o in ipairs(deps.defaultFuse) do targetStateTable[o] = true end
            end
            refreshAllVisuals()
            Fluent:Notify({ Title = titleText, Content = "Đã chọn nhóm quặng nhanh!", Duration = 2 })
        end)

        btnSelectAllFiltered.MouseButton1Click:Connect(function()
            local cnt = 0
            for _, item in ipairs(oreButtons) do
                if item.Button.Visible then
                    targetStateTable[item.Name] = true
                    cnt = cnt + 1
                end
            end
            refreshAllVisuals()
            Fluent:Notify({ Title = titleText, Content = "Đã chọn " .. cnt .. " quặng đang lọc!", Duration = 2 })
        end)

        btnClear.MouseButton1Click:Connect(function()
            for k in pairs(targetStateTable) do targetStateTable[k] = nil end
            refreshAllVisuals()
            Fluent:Notify({ Title = titleText, Content = "Đã bỏ chọn tất cả quặng!", Duration = 2 })
        end)

        return refreshAllVisuals
    end

    -- 4. KHỞI TẠO CÁC TAB ĐỘC LẬP TỪNG CHỨC NĂNG
    local Tabs = {
        Farm = Window:AddTab({ Title = "💰 Auto Farm Tiền", Icon = "coins" }),
        RollBuy = Window:AddTab({ Title = "🎲 Auto Roll & Mua", Icon = "gem" }),
        Fuser = Window:AddTab({ Title = "🔥 Smart Fuser", Icon = "flame" }),
        Buffs = Window:AddTab({ Title = "⭐ Buff & Gems", Icon = "sparkles" }),
        Teleport = Window:AddTab({ Title = "📍 Dịch Chuyển", Icon = "map-pin" }),
        Player = Window:AddTab({ Title = "🏃 Nhân Vật", Icon = "user" }),
        Settings = Window:AddTab({ Title = "⚙️ Cài Đặt", Icon = "settings" })
    }

    local Options = Fluent.Options

    ----------------------------------------------------------------------------
    -- TAB 1: 💰 AUTO FARM TIỀN (MONEY PIPELINE)
    ----------------------------------------------------------------------------
    Tabs.Farm:AddParagraph({
        Title = "💰 QUY TRÌNH KIẾM TIỀN TỰ ĐỘNG (ĐỘC LẬP)",
        Content = "Tự động lấy thùng quặng từ CrateMaker -> Mang vào lò nung Furnace -> Đem thanh kim loại lên bàn Seller bán kiếm tiền liên tục!"
    })

    local ToggleAutoFarmMoney = Tabs.Farm:AddToggle("ToggleAutoFarmMoney", {
        Title = "🚀 BẬT TỰ ĐỘNG BÁN TIỀN (AUTO MONEY PIPELINE)",
        Default = false
    })

    ToggleAutoFarmMoney:OnChanged(function()
        State.AutoFarmMoney = Options.ToggleAutoFarmMoney.Value
        if State.AutoFarmMoney then
            Fluent:Notify({ Title = "💰 Auto Farm Tiền", Content = "Đã BẬT quy trình bán tiền tự động!", Duration = 3 })
            task.spawn(function()
                while State.AutoFarmMoney do
                    pcall(MoneyPipeline.run)
                    task.wait(State.MoneyPipelineInterval or 12)
                end
            end)
        else
            Fluent:Notify({ Title = "💰 Auto Farm Tiền", Content = "Đã TẮT quy trình bán tiền.", Duration = 3 })
        end
    end)

    Tabs.Farm:AddParagraph({
        Title = "⏱️ CÀI ĐẶT TỐC ĐỘ BÁN TIỀN:",
        Content = "Tùy chỉnh khoảng cách giữa các lần bán và độ trễ từng bước để không bị vấp."
    })

    Tabs.Farm:AddSlider("SliderMoneyInterval", {
        Title = "⏱️ Giãn Cách Chu Kỳ Bán (Giây)",
        Default = State.MoneyPipelineInterval or 12,
        Min = 5,
        Max = 60,
        Rounding = 0,
        Callback = function(val) State.MoneyPipelineInterval = val end
    })

    Tabs.Farm:AddSlider("SliderMoneyStepDelay", {
        Title = "⏳ Độ Trễ Từng Bước Bán (Giây)",
        Default = State.MoneyStepDelay or 0.4,
        Min = 0.25,
        Max = 1.0,
        Rounding = 2,
        Callback = function(val) State.MoneyStepDelay = val end
    })

    Tabs.Farm:AddButton({
        Title = "💰 Chạy Thử 1 Vòng Bán Tiền Ngay (Manual Run)",
        Callback = function()
            local ok, msg = MoneyPipeline.run()
            Fluent:Notify({ Title = "Quy Trình Tiền", Content = msg or "Đã thực hiện xong một vòng kiếm tiền!", Duration = 4 })
        end
    })

    ----------------------------------------------------------------------------
    -- TAB 2: 🎲 AUTO ROLL & MUA QUẶNG
    ----------------------------------------------------------------------------
    Tabs.RollBuy:AddParagraph({
        Title = "🎲 CƠ CHẾ AUTO ROLL & QUÉT MUA QUẶNG TỰ ĐỘNG (ĐỘC LẬP)",
        Content = "• Tự động kích hoạt cần gạt Auto Roll của game và soi liên tục 6 bục.\n• Khi thấy đúng quặng bạn chọn (hoặc bật Mua Tất Cả) -> bay tới mua ngay.\n• Sau khi mua, tự động bật lại cần gạt Auto Roll của game để tiếp tục AFK 24/7!"
    })

    local ToggleAutoRollBuy = Tabs.RollBuy:AddToggle("ToggleAutoRollBuy", {
        Title = "🚀 BẬT AUTO ROLL & TỰ ĐỘNG MUA QUẶNG",
        Default = false
    })

    ToggleAutoRollBuy:OnChanged(function()
        State.AutoRollBuyEnabled = Options.ToggleAutoRollBuy.Value
        if State.AutoRollBuyEnabled then
            Fluent:Notify({ Title = "🎲 Auto Roll & Mua", Content = "Đã BẬT tự động Roll & Mua quặng!", Duration = 3 })
            task.spawn(function()
                task.wait(0.2)
                if State.AutoReRollAfterBuy then
                    pcall(AutoRoll.triggerGameAutoRoll, false)
                end

                while State.AutoRollBuyEnabled do
                    pcall(AutoRoll.checkAndBuyMatchingPedestals)
                    task.wait(State.RollScanDelay or 0.5)
                end
            end)
        else
            Fluent:Notify({ Title = "🎲 Auto Roll & Mua", Content = "Đã TẮT tự động Roll & Mua quặng.", Duration = 3 })
        end
    end)

    Tabs.RollBuy:AddToggle("ToggleAutoReRoll", {
        Title = "🔄 Tự Động Kích Hoạt Lại Auto Roll Sau Khi Mua",
        Default = true
    }):OnChanged(function() State.AutoReRollAfterBuy = Options.ToggleAutoReRoll.Value end)

    Tabs.RollBuy:AddToggle("ToggleBuyAll", {
        Title = "Mua Tất Cả Quặng (Không Cần Chọn Lọc)",
        Default = false
    }):OnChanged(function() State.BuyAllPedestals = Options.ToggleBuyAll.Value end)

    Tabs.RollBuy:AddSlider("SliderRollScanDelay", {
        Title = "⏱️ Tần Suất Quét Bục Roll (Giây)",
        Default = State.RollScanDelay or 0.5,
        Min = 0.2,
        Max = 3.0,
        Rounding = 1,
        Callback = function(val) State.RollScanDelay = val end
    })

    Tabs.RollBuy:AddButton({
        Title = "🎲 Gạt Cần Bật / Tắt Auto Roll Của Game (1-Click)",
        Callback = function()
            local ok, name = AutoRoll.triggerGameAutoRoll(true)
            if ok then
                Fluent:Notify({ Title = "🎲 Auto Roll Game", Content = "Đã kích hoạt Auto Roll thành công!", Duration = 3 })
            else
                Fluent:Notify({ Title = "⚠️ Thông Báo", Content = "Không tìm thấy cần gạt Auto Roller!", Duration = 4 })
            end
        end
    })

    Tabs.RollBuy:AddButton({
        Title = "⚡ Quét & Mua Ngay Trên 6 Bục Hiện Tại",
        Callback = function()
            local count = AutoRoll.checkAndBuyMatchingPedestals()
            Fluent:Notify({ Title = "Mua Quặng", Content = string.format("Đã quét và mua %d quặng phù hợp!", count), Duration = 3 })
        end
    })

    local refreshBuySelectorVisuals = buildIntegratedOreSelector(
        Tabs.RollBuy,
        "🎯 Bảng Chọn Quặng Muốn Mua",
        "Gõ tên để tìm kiếm, bấm chọn để đánh dấu [✓]. Script chỉ bay tới mua khi đúng quặng bạn chọn xuất hiện trên 6 bục!",
        State.WantedBuyOres,
        "buy"
    )

    ----------------------------------------------------------------------------
    -- TAB 3: 🔥 SMART FUSER
    ----------------------------------------------------------------------------
    Tabs.Fuser:AddParagraph({
        Title = "🔥 TỰ ĐỘNG NẠP & NHẬN THÀNH PHẨM FUSER (ĐỘC LẬP)",
        Content = "• Tự động thu hoạch thành phẩm Mega Ore khi hoàn thành.\n• Tự động kiểm tra các node trống, cầm quặng trong danh sách cho phép và nạp vào.\n• Bảo vệ 100% quặng xịn trong túi đồ không bao giờ bị nung nhầm!"
    })

    local ToggleAutoFuser = Tabs.Fuser:AddToggle("ToggleAutoFuser", {
        Title = "🚀 BẬT TỰ ĐỘNG SMART FUSER (AUTO FUSER)",
        Default = false
    })

    ToggleAutoFuser:OnChanged(function()
        State.AutoFuserLoop = Options.ToggleAutoFuser.Value
        if State.AutoFuserLoop then
            Fluent:Notify({ Title = "🔥 Smart Fuser", Content = "Đã BẬT tự động nạp & nhận quặng Fuser!", Duration = 3 })
            task.spawn(function()
                while State.AutoFuserLoop do
                    pcall(SmartFuser.run)
                    task.wait(State.FuserInterval or 8)
                end
            end)
        else
            Fluent:Notify({ Title = "🔥 Smart Fuser", Content = "Đã TẮT tự động Smart Fuser.", Duration = 3 })
        end
    end)

    Tabs.Fuser:AddSlider("SliderFuserInterval", {
        Title = "⏱️ Giãn Cách Kiểm Tra Fuser (Giây)",
        Default = State.FuserInterval or 8,
        Min = 4,
        Max = 30,
        Rounding = 0,
        Callback = function(val) State.FuserInterval = val end
    })

    Tabs.Fuser:AddButton({
        Title = "🔥 Cầm Quặng & Nạp Ngay Vào Các Node Trống (1 Lần)",
        Callback = function()
            local ok, msg = SmartFuser.run()
            Fluent:Notify({ Title = "Smart Fuser", Content = msg or "Đã nạp quặng vào Fuser!", Duration = 4 })
        end
    })

    local refreshFuseSelectorVisuals = buildIntegratedOreSelector(
        Tabs.Fuser,
        "🔥 Bảng Chọn Quặng Cho Phép Nung Trong Fuser",
        "Gõ tên để tìm kiếm, bấm chọn để đánh dấu [✓]. Chỉ những quặng có dấu [✓] mới bị đem nung. Quặng xịn của bạn được bảo vệ 100%!",
        State.AllowedFuseOres,
        "fuse"
    )

    ----------------------------------------------------------------------------
    -- TAB 4: ⭐ BUFF & GEMS
    ----------------------------------------------------------------------------
    Tabs.Buffs:AddParagraph({
        Title = "⭐ TỰ ĐỘNG DUY TRÌ ORE BUFF SHOWCASE & APPLY GEMS",
        Content = "• Showcase Buff: Tự động đặt quặng lên bục để duy trì hiệu ứng nhân x2.75 giá trị quặng 24/7.\n• Apply Gems: Tự động áp dụng ngọc tăng cường giá trị để tối đa hóa thu nhập."
    })

    local ToggleAutoApplyGems = Tabs.Buffs:AddToggle("ToggleAutoApplyGems", {
        Title = "💎 Tự Động Sử Dụng Apply Gems (Mỗi 15 Giây)",
        Default = false
    })

    ToggleAutoApplyGems:OnChanged(function()
        State.AutoApplyGems = Options.ToggleAutoApplyGems.Value
        if State.AutoApplyGems then
            Fluent:Notify({ Title = "💎 Apply Gems", Content = "Đã BẬT tự động Apply Gems!", Duration = 3 })
            task.spawn(function()
                while State.AutoApplyGems do
                    pcall(ShowcaseBuff.applyGems, true)
                    task.wait(15)
                end
            end)
        else
            Fluent:Notify({ Title = "💎 Apply Gems", Content = "Đã TẮT tự động Apply Gems.", Duration = 3 })
        end
    end)

    local ToggleAutoBuff1H = Tabs.Buffs:AddToggle("ToggleAutoBuff1H", {
        Title = "⭐ Tự Động Duy Trì Buff Showcase x2.75 / x4",
        Default = false
    })

    ToggleAutoBuff1H:OnChanged(function()
        State.AutoActivateBuff = Options.ToggleAutoBuff1H.Value
        if State.AutoActivateBuff then
            Fluent:Notify({ Title = "⭐ Buff Showcase", Content = "Đã BẬT tự động duy trì Buff Showcase!", Duration = 3 })
            task.spawn(function()
                while State.AutoActivateBuff do
                    pcall(ShowcaseBuff.activateBuff, false)
                    task.wait(30) -- Kiểm tra mỗi 30s, khi sắp hết hạn sẽ tự động kích hoạt lại
                end
            end)
        else
            Fluent:Notify({ Title = "⭐ Buff Showcase", Content = "Đã TẮT tự động duy trì Buff Showcase.", Duration = 3 })
        end
    end)

    Tabs.Buffs:AddButton({
        Title = "💎 Sử Dụng Apply Gems Ngay Lập Tức",
        Callback = function()
            local ok, msg = ShowcaseBuff.applyGems(false)
            Fluent:Notify({ Title = "Apply Gems", Content = msg or "Đã thực hiện Apply Gems!", Duration = 4 })
        end
    })

    Tabs.Buffs:AddButton({
        Title = "⭐ Kiểm Tra / Kích Hoạt Buff Showcase Ngay",
        Callback = function()
            local ok, msg = ShowcaseBuff.activateBuff(false)
            Fluent:Notify({ Title = "Buff Showcase", Content = msg or "Đã kích hoạt Buff Showcase!", Duration = 4 })
        end
    })

    ----------------------------------------------------------------------------
    -- TAB 5: 📍 DỊCH CHUYỂN
    ----------------------------------------------------------------------------
    Tabs.Teleport:AddParagraph({ Title = "📍 DỊCH CHUYỂN TRONG CĂN CỨ", Content = "Dịch chuyển tức thì đến các máy móc quan trọng." })

    Tabs.Teleport:AddButton({
        Title = "⚡ Đến Cần Gạt Auto Roller",
        Callback = function()
            local prompt = AutoRoll.getAutoRollerPrompt()
            if prompt and prompt.Parent and prompt.Parent:IsA("BasePart") then
                Utils.teleportTo(prompt.Parent.CFrame)
                Fluent:Notify({ Title = "Teleport", Content = "Đã đến cần gạt Auto Roller!", Duration = 3 })
            else
                Fluent:Notify({ Title = "Lỗi", Content = "Không tìm thấy vị trí Auto Roller!", Duration = 3 })
            end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "⚡ Đến 6 Bục Quay Quặng (OrePedestals)",
        Callback = function()
            local base = Utils.getMyBase()
            if base and base:FindFirstChild("OrePedestals") then
                local ped = base.OrePedestals:FindFirstChild("RolledOrePedestal1") or base.OrePedestals:FindFirstChildWhichIsA("BasePart", true)
                if ped then
                    local cf = ped:IsA("BasePart") and ped.CFrame or ped:GetPivot()
                    Utils.teleportTo(cf)
                    Fluent:Notify({ Title = "Teleport", Content = "Đã đến bục quay quặng!", Duration = 3 })
                end
            end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "⚡ Đến Trạm Ghép Quặng (Fuser)",
        Callback = function()
            local base = Utils.getMyBase()
            if base and base:FindFirstChild("Fuser") then
                local p = base.Fuser:FindFirstChildWhichIsA("BasePart", true)
                if p then
                    Utils.teleportTo(p.CFrame)
                    Fluent:Notify({ Title = "Teleport", Content = "Đã đến trạm Fuser!", Duration = 3 })
                end
            end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "⚡ Đến Lò Nung (Furnace)",
        Callback = function()
            local base = Utils.getMyBase()
            if base and base:FindFirstChild("Furnace") then
                local p = base.Furnace:FindFirstChildWhichIsA("BasePart", true)
                if p then
                    Utils.teleportTo(p.CFrame)
                    Fluent:Notify({ Title = "Teleport", Content = "Đã đến Lò Nung!", Duration = 3 })
                end
            end
        end
    })

    Tabs.Teleport:AddButton({
        Title = "⚡ Đến Bàn Bán Quặng (SellerTable)",
        Callback = function()
            local base = Utils.getMyBase()
            if base and base:FindFirstChild("SellerTable") then
                local p = base.SellerTable:FindFirstChildWhichIsA("BasePart", true)
                if p then
                    Utils.teleportTo(p.CFrame)
                    Fluent:Notify({ Title = "Teleport", Content = "Đã đến bàn Bán Quặng!", Duration = 3 })
                end
            end
        end
    })

    -- TAB 5: NHÂN VẬT
    Tabs.Player:AddToggle("ToggleWalkSpeed", {
        Title = "Tăng Tốc Chạy (WalkSpeed)",
        Default = false
    }):OnChanged(function()
        State.WalkSpeedEnabled = Options.ToggleWalkSpeed.Value
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = State.WalkSpeedEnabled and State.WalkSpeedValue or 16 end
    end)

    Tabs.Player:AddSlider("SliderWalkSpeed", {
        Title = "Tốc Độ Chạy",
        Default = 16,
        Min = 16,
        Max = 150,
        Rounding = 0,
        Callback = function(val)
            State.WalkSpeedValue = val
            if State.WalkSpeedEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end
    })

    Tabs.Player:AddToggle("ToggleJumpPower", {
        Title = "Tăng Nhảy Cao (JumpPower)",
        Default = false
    }):OnChanged(function()
        State.JumpPowerEnabled = Options.ToggleJumpPower.Value
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = State.JumpPowerEnabled and State.JumpPowerValue or 50
        end
    end)

    Tabs.Player:AddSlider("SliderJumpPower", {
        Title = "Lực Nhảy",
        Default = 50,
        Min = 50,
        Max = 250,
        Rounding = 0,
        Callback = function(val)
            State.JumpPowerValue = val
            if State.JumpPowerEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.UseJumpPower = true; hum.JumpPower = val end
            end
        end
    })

    Tabs.Player:AddToggle("ToggleInfiniteJump", {
        Title = "Nhảy Vô Hạn (Infinite Jump)",
        Default = false
    }):OnChanged(function() State.InfiniteJump = Options.ToggleInfiniteJump.Value end)

    UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJump and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    Tabs.Player:AddToggle("ToggleNoclip", {
        Title = "Đi Xuyên Tường (Noclip)",
        Default = false
    }):OnChanged(function() State.Noclip = Options.ToggleNoclip.Value end)

    RunService.Stepped:Connect(function()
        if State.Noclip and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end
    end)

    Tabs.Player:AddToggle("ToggleAntiAFK", {
        Title = "Chống Văng Treo Máy 24/7 (Anti-AFK)",
        Default = true
    }):OnChanged(function() State.AntiAFK = Options.ToggleAntiAFK.Value end)

    LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            end)
        end
    end)

    ----------------------------------------------------------------------------
    -- TAB 7: ⚙️ CẤU HÌNH & CÀI ĐẶT (CONFIG MANAGER & SETTINGS)
    ----------------------------------------------------------------------------
    Tabs.Settings:AddParagraph({
        Title = "💾 QUẢN LÝ CẤU HÌNH TOÀN HỆ THỐNG (USER CONFIG)",
        Content = "Tập trung toàn bộ việc Lưu & Nạp cấu hình độc lập tại đây.\nFile SellOres_UserConfig.json lưu giữ vĩnh viễn:\n• Danh sách 81 loại quặng đã chọn mua [✓]\n• Danh sách quặng cho phép nung Fuser [✓]\n• Mọi công tắc bật/tắt (Farm Tiền, Roll & Mua, Fuser, Buffs, v.v.) và các thanh trượt delay."
    })

    Tabs.Settings:AddButton({
        Title = "💾 LƯU TOÀN BỘ CẤU HÌNH HIỆN TẠI (SAVE CONFIG)",
        Callback = function() ConfigManager.save(false) end
    })

    Tabs.Settings:AddButton({
        Title = "📂 TẢI LẠI CẤU HÌNH ĐÃ LƯU (LOAD CONFIG)",
        Callback = function() ConfigManager.load(false) end
    })

    Tabs.Settings:AddToggle("ToggleAutoLoadConfig", {
        Title = "⚡ Tự Động Nạp Cấu Hình Khi Khởi Chạy Script",
        Default = State.AutoLoadConfig ~= false
    }):OnChanged(function()
        State.AutoLoadConfig = Options.ToggleAutoLoadConfig.Value
    end)

    Tabs.Settings:AddButton({
        Title = "🔄 KHÔI PHỤC DANH SÁCH MẶC ĐỊNH (RESET CONFIG)",
        Callback = function() ConfigManager.reset() end
    })

    Tabs.Settings:AddButton({
        Title = "🗑️ XÓA FILE CẤU HÌNH (DELETE CONFIG FILE)",
        Callback = function() ConfigManager.deleteFile() end
    })

    Tabs.Settings:AddParagraph({
        Title = "🎨 TÙY BIẾN GIAO DIỆN & PHÍM TẮT (THEMES & KEYBINDS)",
        Content = "Tùy chỉnh màu sắc chủ đề Fluent Design, hiệu ứng trong suốt Acrylic và phím tắt mở lại menu."
    })

    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    InterfaceManager:SetFolder("SellOresHub")
    SaveManager:SetFolder("SellOresHub/config")

    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)

    ConfigManager.setVisualCallbacks(refreshBuySelectorVisuals, refreshFuseSelectorVisuals)

    Window:SelectTab(1)

    Fluent:Notify({
        Title = "Sell Ores Hub v7.8 Ultimate PRO",
        Content = "Đã khởi tạo xong! Từng chức năng và phần Cấu hình được tách biệt hoàn toàn.",
        Duration = 5
    })

    task.spawn(function()
        task.wait(0.6)
        if State.AutoLoadConfig and isfile and isfile("SellOres_UserConfig.json") then
            local success = ConfigManager.load(true)
            if success then
                Fluent:Notify({
                    Title = "⚡ Tự Động Nạp Cấu Hình",
                    Content = "Đã nạp lại toàn bộ quặng mua, quặng nung & cài đặt của bạn!",
                    Duration = 3
                })
            end
        end
    end)
end

return UI
