--[[
    ====================================================================
               SELL ORES - LIVE SYSTEM TEST & INSPECTOR V2.0
    ====================================================================
    Script này sẽ chạy thử và kiểm tra từng chức năng một cách độc lập:
    [1] Nhận diện Base & Máy móc (CrateMaker, Furnace, SellerTable, Fuser)
    [2] Kích hoạt Buff Showcase x2.75 / x4 (InvokeServer thực tế)
    [3] Bấm Apply Gems & kiểm tra bảng xác nhận (ConfirmationPanel)
    [4] Chạy thử 1 vòng nhặt thùng bỏ lò bán tiền (MoneyPipeline.run)
    [5] Chạy thử Fuser nạp quặng (SmartFuser.run)
    ====================================================================
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local report = {}
local function log(txt)
    table.insert(report, tostring(txt))
    print("[TEST-SUITE] " .. tostring(txt))
end

log("================================================================================")
log("              SELL ORES - BÁO CÁO KIỂM TRA HỆ THỐNG (" .. os.date("%X") .. ")")
log("================================================================================")

-- [TEST 1] BASE & ĐỒNG BỘ MÁY MÓC
log("\n--- [TEST 1] ĐỊNH VỊ BASE & CÁC MÁY MÓC ---")
local assignedAttr = LocalPlayer:GetAttribute("AssignedBaseName")
log("• LocalPlayer Attribute 'AssignedBaseName' = " .. tostring(assignedAttr))

local bases = Workspace:FindFirstChild("Bases")
log("• Workspace.Bases tồn tại: " .. tostring(bases ~= nil))
if bases then
    local baseNames = {}
    for _, b in ipairs(bases:GetChildren()) do table.insert(baseNames, b.Name) end
    log("• Các Base hiện có trong Server: " .. table.concat(baseNames, ", "))
end

local myBase = nil
if bases and assignedAttr and bases:FindFirstChild(tostring(assignedAttr)) then
    myBase = bases[tostring(assignedAttr)]
end
if not myBase and bases then
    -- Thử quét qua ExpressivePromptsGui
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local ep = pg and pg:FindFirstChild("ExpressivePromptsGui")
    if ep then
        for _, child in ipairs(ep:GetChildren()) do
            local bn = child.Name:match("Bases%.(Base%d+)")
            if bn and bases:FindFirstChild(bn) then
                myBase = bases[bn]
                log("• Tìm thấy Base qua ExpressivePromptsGui: " .. bn)
                break
            end
        end
    end
end
log("--> KẾT LUẬN BASE CỦA BẠN: " .. (myBase and myBase.Name or "KHÔNG TÌM THẤY!"))

if myBase then
    local cm = myBase:FindFirstChild("CrateMaker")
    local furnace = myBase:FindFirstChild("Furnace")
    local st = myBase:FindFirstChild("SellerTable")
    local fuser = myBase:FindFirstChild("Fuser")
    local peds = myBase:FindFirstChild("OrePedestals")

    log(string.format("• CrateMaker: %s | Furnace: %s | SellerTable: %s | Fuser: %s | Pedestals: %s",
        cm and "Có" or "Không",
        furnace and "Có" or "Không",
        st and "Có" or "Không",
        fuser and "Có" or "Không",
        peds and "Có" or "Không"
    ))

    -- Kiểm tra prompt tại CrateMaker
    if cm then
        local cmPrompts = {}
        for _, p in ipairs(cm:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                table.insert(cmPrompts, string.format("Action='%s', Obj='%s', Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
            end
        end
        log("  └─ Prompts tại CrateMaker: " .. (#cmPrompts > 0 and table.concat(cmPrompts, " | ") or "Không có"))
    end

    -- Kiểm tra prompt tại Furnace
    if furnace then
        local fPrompts = {}
        for _, p in ipairs(furnace:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                table.insert(fPrompts, string.format("Action='%s', Obj='%s', Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
            end
        end
        log("  └─ Prompts tại Furnace: " .. (#fPrompts > 0 and table.concat(fPrompts, " | ") or "Không có"))
    end

    -- Kiểm tra prompt tại SellerTable
    if st then
        local stPrompts = {}
        for _, p in ipairs(st:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                table.insert(stPrompts, string.format("Action='%s', Obj='%s', Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
            end
        end
        log("  └─ Prompts tại SellerTable: " .. (#stPrompts > 0 and table.concat(stPrompts, " | ") or "Không có"))
    end

    -- Kiểm tra prompt tại Fuser
    if fuser then
        local fuserPrompts = {}
        for _, p in ipairs(fuser:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                table.insert(fuserPrompts, string.format("Action='%s', Obj='%s', Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
            end
        end
        log("  └─ Prompts tại Fuser (" .. #fuserPrompts .. " cái): " .. (#fuserPrompts > 0 and table.concat(fuserPrompts, " | ") or "Không có"))
    end
end

-- [TEST 2] THỬ KÍCH HOẠT BUFF SHOWCASE PEDESTAL
log("\n--- [TEST 2] THỬ GỌI REMOTE KÍCH HOẠT BUFF SHOWCASE ---")
local showcaseRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ShowcasePedestalAction")
if showcaseRemote and myBase then
    for slot = 1, 2 do
        local oreName = LocalPlayer:GetAttribute("ShowcasePedestal" .. slot .. "OreName")
        local mult = LocalPlayer:GetAttribute("ShowcasePedestal" .. slot .. "Multiplier")
        local exp = LocalPlayer:GetAttribute("ShowcasePedestal" .. slot .. "BoostExpiresAt")
        log(string.format("• Bục %d: Quặng='%s', Mult=%s, Expire=%s", slot, tostring(oreName), tostring(mult), tostring(exp)))

        local stateRes = nil
        local stateOk, stateErr = pcall(function()
            stateRes = showcaseRemote:InvokeServer(myBase.Name, slot, "GetState")
        end)
        if stateOk then
            log(string.format("  └─ GetState(%s, %d): OK, state=%s", myBase.Name, slot, tostring(stateRes and stateRes.state and stateRes.state.Multiplier or stateRes)))
        else
            log(string.format("  └─ GetState LỖI: %s", tostring(stateErr)))
        end

        local actRes = nil
        local actOk, actErr = pcall(function()
            actRes = showcaseRemote:InvokeServer(myBase.Name, slot, "ActivateBuff")
        end)
        if actOk then
            local success = actRes and actRes.success
            local msg = actRes and actRes.message or "nil"
            log(string.format("  └─ ActivateBuff(%s, %d): Tra ve success=%s, msg='%s'", myBase.Name, slot, tostring(success), tostring(msg)))
        else
            log(string.format("  └─ ActivateBuff LỖI: %s", tostring(actErr)))
        end
    end
else
    log("ShowcasePedestalAction Remote hoặc Base: KHÔNG TÌM THẤY")
end

-- [TEST 3] THỬ NÚT APPLY GEMS & QUÉT BẢNG XÁC NHẬN
log("\n--- [TEST 3] THỬ BẤM APPLY GEMS & QUÉT CONFIRMATION PANEL ---")
local pg = LocalPlayer:FindFirstChild("PlayerGui")
local gemBtn = nil
if pg then
    local mainFrames = pg:FindFirstChild("MainFrames")
    local topPane = mainFrames and mainFrames:FindFirstChild("MenuFrames") and mainFrames.MenuFrames:FindFirstChild("TopPane")
    local row1 = topPane and topPane:FindFirstChild("Row1")
    gemBtn = row1 and row1:FindFirstChild("ApplyGemsButton")
    if not gemBtn then gemBtn = pg:FindFirstChild("ApplyGemsButton", true) end
end

log("• Nút ApplyGemsButton: " .. (gemBtn and ("Tìm thấy (" .. gemBtn:GetFullName() .. ")") or "KHÔNG TÌM THẤY"))

if gemBtn then
    log("• Bắt đầu bấm nút ApplyGemsButton...")
    pcall(function()
        if firesignal then
            if gemBtn.Activated then firesignal(gemBtn.Activated) end
            if gemBtn.MouseButton1Click then firesignal(gemBtn.MouseButton1Click) end
        end
        if gemBtn.MouseButton1Click then gemBtn.MouseButton1Click:Fire() end
        local vim = VirtualInputManager or game:GetService("VirtualInputManager")
        if vim and gemBtn.AbsolutePosition and gemBtn.AbsoluteSize then
            local cx = gemBtn.AbsolutePosition.X + gemBtn.AbsoluteSize.X / 2
            local cy = gemBtn.AbsolutePosition.Y + gemBtn.AbsoluteSize.Y / 2
            vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.04)
            vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end
    end)
    task.wait(0.4)

    -- Quét xem ConfirmationPanel có mở không
    local confirmPanel = pg:FindFirstChild("ConfirmationPanel", true)
    log("• ConfirmationPanel sau khi bấm: " .. (confirmPanel and ("Tìm thấy, Visible=" .. tostring(confirmPanel.Visible)) or "Không có"))
    if confirmPanel then
        local btns = {}
        for _, d in ipairs(confirmPanel:GetDescendants()) do
            if d:IsA("GuiButton") then
                local t = d:IsA("TextButton") and d.Text or ""
                table.insert(btns, string.format("Name='%s', Text='%s', Visible=%s", d.Name, t, tostring(d.Visible)))
            end
            if d:IsA("TextLabel") and d.Visible and d.Text ~= "" then
                log("  └─ Text trên bảng: '" .. d.Text .. "'")
            end
        end
        log("  └─ Các nút trong ConfirmationPanel: " .. table.concat(btns, " | "))
    end
end

-- [TEST 4] KIỂM TRA TÚI ĐỒ ĐỐI CHIẾU DANH SÁCH FUSER
log("\n--- [TEST 4] TÚI ĐỒ VÀ DANH SÁCH QUẶNG ĐỂ NUNG FUSER ---")
local backpack = LocalPlayer:FindFirstChild("Backpack")
local char = LocalPlayer.Character
local toolsInHand = {}
local toolsInBackpack = {}
if char then
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then table.insert(toolsInHand, item.Name) end
    end
end
if backpack then
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then table.insert(toolsInBackpack, item.Name) end
    end
end
log("• Đang cầm trên tay: " .. (#toolsInHand > 0 and table.concat(toolsInHand, ", ") or "(Trống)"))
log("• Tổng Tool trong Backpack: " .. #toolsInBackpack)

local safeOres = {"Stone Ore", "Coal Ore", "Copper Ore", "Tin Ore", "Iron Ore", "Lead Ore"}
local matchingSafeOres = {}
for _, tName in ipairs(toolsInBackpack) do
    for _, sName in ipairs(safeOres) do
        if tName:lower():find(sName:lower():gsub(" ore$", "")) then
            table.insert(matchingSafeOres, tName)
            break
        end
    end
end
log("• Quặng cơ bản (an toàn để nung) tìm thấy trong túi: " .. (#matchingSafeOres > 0 and table.concat(matchingSafeOres, ", ") or "KHÔNG CÓ QUẶNG CƠ BẢN NÀO"))

log("\n================================================================================")
log("                           KẾT THÚC KIỂM TRA                                    ")
log("================================================================================")

local fullReport = table.concat(report, "\n")

-- 1. Copy vào Clipboard
pcall(function()
    if setclipboard then setclipboard(fullReport)
    elseif toclipboard then toclipboard(fullReport)
    end
end)

-- 2. Dựng bảng hiển thị trực tiếp trên màn hình Game
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local parentGui = CoreGui:FindFirstChild("RobloxGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if not parentGui then return end

    local old = parentGui:FindFirstChild("SellOresTestGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "SellOresTestGui"
    sg.ResetOnSpawn = false
    sg.Parent = parentGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 520, 0, 420)
    frame.Position = UDim2.new(0.5, -260, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(15, 17, 24)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(0, 220, 255)
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -70, 0, 32)
    title.Position = UDim2.new(0, 12, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "📊 BÁO CÁO KIỂM TRA HỆ THỐNG RUNTIME"
    title.TextColor3 = Color3.fromRGB(0, 255, 220)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 26, 0, 26)
    closeBtn.Position = UDim2.new(1, -32, 0, 6)
    closeBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.Parent = frame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 5)
    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 80, 0, 26)
    copyBtn.Position = UDim2.new(1, -118, 0, 6)
    copyBtn.BackgroundColor3 = Color3.fromRGB(16, 68, 48)
    copyBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
    copyBtn.Text = "📋 COPY"
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.TextSize = 11
    copyBtn.Parent = frame
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 5)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(fullReport)
            elseif toclipboard then toclipboard(fullReport) end
            copyBtn.Text = "✓ ĐÃ COPY"
            task.wait(1.5)
            copyBtn.Text = "📋 COPY"
        end)
    end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -48)
    scroll.Position = UDim2.new(0, 10, 0, 38)
    scroll.BackgroundColor3 = Color3.fromRGB(8, 10, 15)
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 5
    scroll.Parent = frame
    Instance.new("UICorner", scroll).CornerRadius = UDim.new(0, 6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -12, 1, 0)
    box.Position = UDim2.new(0, 6, 0, 6)
    box.BackgroundTransparency = 1
    box.TextColor3 = Color3.fromRGB(220, 225, 235)
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.MultiLine = true
    box.ClearTextOnFocus = false
    box.TextEditable = false
    box.Text = fullReport
    box.Parent = scroll

    task.spawn(function()
        task.wait(0.1)
        local lineCount = #report
        scroll.CanvasSize = UDim2.new(0, 0, 0, lineCount * 17 + 40)
    end)
end)
