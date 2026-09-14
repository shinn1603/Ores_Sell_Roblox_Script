--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                 SELL ORES - DIAGNOSTIC SPY V1.0                  ║
    ║   Tự động quét toàn bộ trạng thái runtime của game Sell Ores:     ║
    ║   • Tiền & Gems (leaderstats, Attributes, PlayerGui)             ║
    ║   • Căn cứ (CrateMaker, Furnace, SellerTable, Roller, Fuser)     ║
    ║   • 6 Bục quặng (Tên, Giá, Prompts, Attributes)                  ║
    ║   • Túi đồ & Túi tool (Tools trong Character & Backpack)         ║
    ║   • Nút ApplyGemsButton & Showcase Remotes                       ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local report = {}
local function log(txt)
    table.insert(report, tostring(txt))
    print("[DIAGNOSE] " .. tostring(txt))
end

log("================================================================================")
log("             BÁO CÁO CHẨN ĐOÁN RUNTIME GAME SELL ORES (" .. os.date("%X") .. ")")
log("================================================================================")

-- 1. THÔNG TIN NGƯỜI CHƠI & TIỀN TỆ
log("\n--- [1] NGƯỜI CHƠI & DỮ LIỆU TIỀN TỆ ---")
log("Player: " .. LocalPlayer.Name .. " (UserId: " .. LocalPlayer.UserId .. ")")

local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
if leaderstats then
    log("leaderstats tìm thấy:")
    for _, child in ipairs(leaderstats:GetChildren()) do
        log(string.format("  • %s (%s): %s", child.Name, child.ClassName, tostring(child.Value)))
    end
else
    log("leaderstats: KHÔNG CÓ")
end

local attrs = LocalPlayer:GetAttributes()
local attrCount = 0
for k, v in pairs(attrs) do
    local kLow = tostring(k):lower()
    -- Bỏ qua các attribute tầng/tunnel/drill rác để tránh tràn tin nhắn
    if not kLow:find("tunnel") and not kLow:find("floor") and not kLow:find("drill") and not kLow:find("petability") and not kLow:find("regen") then
        attrCount = attrCount + 1
        log(string.format("  • Attribute: %s = %s (%s)", tostring(k), tostring(v), type(v)))
    end
end
if attrCount == 0 then log("Attributes trên LocalPlayer: Không có (đã lọc bớt thuộc tính tầng đào)") end

for _, fName in ipairs({"PlayerData", "Data", "Stats", "Currencies"}) do
    local f = LocalPlayer:FindFirstChild(fName)
    if f then
        log("Folder " .. fName .. " tìm thấy:")
        for _, c in ipairs(f:GetChildren()) do
            local val = c:IsA("ValueBase") and tostring(c.Value) or c.ClassName
            log(string.format("  • %s: %s", c.Name, val))
        end
    end
end

-- 2. QUÉT TEXTLABEL TIỀN TỆ TRONG PLAYERGUI
log("\n--- [2] PLAYERGUI - TEXTLABEL CHỨA KÝ TỰ $ HOẶC TIỀN TỆ ---")
local pg = LocalPlayer:FindFirstChild("PlayerGui")
if pg then
    local foundLabels = 0
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Visible and desc.Text ~= "" then
            local t = desc.Text
            if t:find("%$") or t:lower():find("cash") or t:lower():find("money") or t:lower():find("coins") or t:lower():find("gems") then
                foundLabels = foundLabels + 1
                local parentBtn = desc:FindFirstAncestorWhichIsA("GuiButton")
                log(string.format("  [%d] '%s' | Path: %s | Trong Button: %s", foundLabels, t, desc:GetFullName(), tostring(parentBtn ~= nil)))
            end
        end
    end
    if foundLabels == 0 then log("Không tìm thấy TextLabel nào chứa $ hoặc chữ tiền tệ") end
else
    log("PlayerGui: Không tìm thấy")
end

-- 3. QUÉT NÚT APPLY GEMS
log("\n--- [3] NÚT APPLY GEMS ---")
if pg then
    local mainFrames = pg:FindFirstChild("MainFrames")
    local topPane = mainFrames and mainFrames:FindFirstChild("MenuFrames") and mainFrames.MenuFrames:FindFirstChild("TopPane")
    local row1 = topPane and topPane:FindFirstChild("Row1")
    local directBtn = row1 and row1:FindFirstChild("ApplyGemsButton")
    if directBtn then
        log("  ✓ Tìm thấy theo đường dẫn chính xác: MainFrames.MenuFrames.TopPane.Row1.ApplyGemsButton")
        log("    - Class: " .. directBtn.ClassName .. " | Visible: " .. tostring(directBtn.Visible))
    else
        log("  ✗ Không có ở TopPane.Row1.ApplyGemsButton")
    end

    local fallbackBtns = {}
    for _, desc in ipairs(pg:GetDescendants()) do
        if desc:IsA("GuiButton") then
            local n = desc.Name:lower()
            local t = desc:IsA("TextButton") and desc.Text:lower() or ""
            if n:find("gem") or t:find("gem") then
                table.insert(fallbackBtns, desc:GetFullName() .. " (Text: '" .. t .. "')")
            end
        end
    end
    log("  Các nút có chữ 'gem' trong PlayerGui: " .. (#fallbackBtns > 0 and table.concat(fallbackBtns, " | ") or "Không có"))
end

-- 4. TÌM BASE CỦA NGƯỜI CHƠI
log("\n--- [4] CĂN CỨ (BASE) CỦA NGƯỜI CHƠI ---")
local myBase = nil
local bases = Workspace:FindFirstChild("Bases")
if bases then
    for _, b in ipairs(bases:GetChildren()) do
        local peds = b:FindFirstChild("OrePedestals")
        if peds then
            for _, p in ipairs(peds:GetDescendants()) do
                if p:IsA("ProximityPrompt") and (p.ActionText == "Buy" or p.ActionText:find("Buy")) then
                    myBase = b
                    break
                end
            end
        end
        if myBase then break end
    end
end
if not myBase and bases then
    for _, b in ipairs(bases:GetChildren()) do
        if b.Name:lower():find(LocalPlayer.Name:lower()) then
            myBase = b
            break
        end
    end
end
log("Căn cứ xác định: " .. (myBase and myBase.Name or "KHÔNG TÌM THẤY"))

if myBase then
    -- 5. MÁY MÓC TRONG BASE
    log("\n--- [5] CHI TIẾT MÁY MÓC TRONG BASE ---")
    local cm = myBase:FindFirstChild("CrateMaker")
    log("CrateMaker: " .. (cm and "Có" or "Không"))
    if cm then
        local sp = cm:FindFirstChild("CrateSpawnPoint")
        log("  - CrateSpawnPoint: " .. (sp and "Có" or "Không"))
        if sp then
            for _, p in ipairs(sp:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    log(string.format("    • Prompt: Action='%s' | Obj='%s' | Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
                end
            end
        end
    end

    local furnace = myBase:FindFirstChild("Furnace")
    log("Furnace: " .. (furnace and "Có" or "Không"))
    if furnace then
        local place = furnace:FindFirstChild("PlaceCratesPromptPart")
        log("  - PlaceCratesPromptPart: " .. (place and "Có" or "Không"))
        if place then
            for _, p in ipairs(place:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    log(string.format("    • Prompt: Action='%s' | Obj='%s' | Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
                end
            end
        end

        local metal = furnace:FindFirstChild("MetalCratePlacementPart")
        log("  - MetalCratePlacementPart: " .. (metal and "Có" or "Không"))
        if metal then
            for _, p in ipairs(metal:GetDescendants()) do
                if p:IsA("ProximityPrompt") then
                    log(string.format("    • Prompt: Action='%s' | Obj='%s' | Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
                end
            end
        end
    end

    local st = myBase:FindFirstChild("SellerTable")
    log("SellerTable: " .. (st and "Có" or "Không"))
    if st then
        for _, p in ipairs(st:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                log(string.format("  • Prompt: Action='%s' | Obj='%s' | Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
            end
        end
    end

    -- Roller / Lever
    local roller = myBase:FindFirstChild("Roller")
    log("Roller: " .. (roller and "Có" or "Không"))
    if roller then
        local autoR = roller:FindFirstChild("AutoRoller")
        log("  - AutoRoller: " .. (autoR and "Có" or "Không"))
        for _, p in ipairs(roller:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                log(string.format("    • Prompt Roller: Action='%s' | Obj='%s' | Part='%s' | Enabled=%s", p.ActionText, p.ObjectText, p.Parent and p.Parent.Name or "nil", tostring(p.Enabled)))
            end
        end
    end

    -- 6. 6 BỤC QUẶNG (ORE PEDESTALS)
    log("\n--- [6] 6 BỤC QUẶNG (ORE PEDESTALS) ---")
    local pedsFolder = myBase:FindFirstChild("OrePedestals")
    if pedsFolder then
        for i = 1, 6 do
            local ped = pedsFolder:FindFirstChild("RolledOrePedestal" .. i)
            if ped then
                local promptInfo = {}
                for _, p in ipairs(ped:GetDescendants()) do
                    if p:IsA("ProximityPrompt") then
                        table.insert(promptInfo, string.format("Action='%s' Obj='%s' Enabled=%s", p.ActionText, p.ObjectText, tostring(p.Enabled)))
                    end
                end
                local attrList = {}
                for k, v in pairs(ped:GetAttributes()) do
                    table.insert(attrList, k .. "=" .. tostring(v))
                end
                local texts = {}
                for _, desc in ipairs(ped:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                        table.insert(texts, "'" .. desc.Text .. "'")
                    end
                end
                log(string.format("Bục %d: Prompts=[%s] | Attrs=[%s] | Labels=[%s]", i, table.concat(promptInfo, "; "), table.concat(attrList, ", "), table.concat(texts, ", ")))
            else
                log(string.format("Bục %d: Không tìm thấy Part RolledOrePedestal%d", i, i))
            end
        end
    else
        log("OrePedestals Folder: KHÔNG TÌM THẤY")
    end

    -- 7. FUSER
    log("\n--- [7] FUSER ---")
    local fuser = myBase:FindFirstChild("Fuser")
    log("Fuser: " .. (fuser and "Có" or "Không"))
    if fuser then
        local fuserPrompts = {}
        for _, p in ipairs(fuser:GetDescendants()) do
            if p:IsA("ProximityPrompt") then
                table.insert(fuserPrompts, string.format("Part='%s' | Action='%s' | Obj='%s' | Enabled=%s", p.Parent and p.Parent.Name or "nil", p.ActionText, p.ObjectText, tostring(p.Enabled)))
            end
        end
        log("Prompts trong Fuser:\n  • " .. (#fuserPrompts > 0 and table.concat(fuserPrompts, "\n  • ") or "Không có prompt nào"))
    end
end

-- 8. TÚI ĐỒ VÀ CHARACTER (TOOLS)
log("\n--- [8] CÁC TOOL ĐANG CÓ TRÊN NGƯỜI & TRONG BACKPACK ---")
local char = LocalPlayer.Character
if char then
    local cTools = {}
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(cTools, item.Name)
        end
    end
    log("Đang cầm trên tay: " .. (#cTools > 0 and table.concat(cTools, ", ") or "Không cầm tool nào"))
end

local backpack = LocalPlayer:FindFirstChild("Backpack")
if backpack then
    local bTools = {}
    for _, item in ipairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            table.insert(bTools, item.Name)
        end
    end
    log("Trong Backpack (" .. #bTools .. " items): " .. table.concat(bTools, ", "))
end

-- 9. GIAO DIỆN HIỂN THỊ TRỰC TIẾP TRÊN MÀN HÌNH + NÚT COPY
log("\n================================================================================")
log("                         KẾT THÚC BÁO CÁO CHẨN ĐOÁN                            ")
log("================================================================================")

local fullReport = table.concat(report, "\n")

-- Tự động copy vào Clipboard nếu executor hỗ trợ
pcall(function()
    if setclipboard then
        setclipboard(fullReport)
        log("✓ Đã tự động copy toàn bộ nội dung vào Clipboard!")
    end
end)

-- Tạo GUI hiển thị kết quả
pcall(function()
    if CoreGui:FindFirstChild("DiagnoseSpyGui") then
        CoreGui.DiagnoseSpyGui:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "DiagnoseSpyGui"
    sg.ResetOnSpawn = false
    sg.Parent = (gethui and gethui()) or CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(650, 450)
    frame.Position = UDim2.new(0.5, -325, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
    title.Text = "🔍 BÁO CÁO CHẨN ĐOÁN RUNTIME (SELL ORES)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 15
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title

    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, -20, 1, -100)
    sf.Position = UDim2.fromOffset(10, 45)
    sf.BackgroundTransparency = 1
    sf.CanvasSize = UDim2.new(0, 0, 0, #report * 18 + 50)
    sf.ScrollBarThickness = 6
    sf.Parent = frame

    local tb = Instance.new("TextBox")
    tb.Size = UDim2.new(1, 0, 1, 0)
    tb.BackgroundTransparency = 1
    tb.Text = fullReport
    tb.TextColor3 = Color3.fromRGB(220, 225, 240)
    tb.TextSize = 11
    tb.Font = Enum.Font.Code
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.TextYAlignment = Enum.TextYAlignment.Top
    tb.ClearTextOnFocus = false
    tb.Parent = sf

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0.7, 0, 0, 38)
    copyBtn.Position = UDim2.new(0.05, 0, 1, -48)
    copyBtn.BackgroundColor3 = Color3.fromRGB(46, 180, 110)
    copyBtn.Text = "📋 SAO CHÉP TOÀN BỘ (COPY ALL TO CLIPBOARD)"
    copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    copyBtn.TextSize = 13
    copyBtn.Font = Enum.Font.GothamBold
    copyBtn.Parent = frame

    local copyCorner = Instance.new("UICorner")
    copyCorner.CornerRadius = UDim.new(0, 6)
    copyCorner.Parent = copyBtn

    copyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then
                setclipboard(fullReport)
                copyBtn.Text = "✓ ĐÃ SAO CHÉP THÀNH CÔNG!"
            else
                copyBtn.Text = "Hãy bôi đen trong khung và bấm Ctrl+C"
            end
        end)
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.2, 0, 0, 38)
    closeBtn.Position = UDim2.new(0.76, 0, 1, -48)
    closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    closeBtn.Text = "✕ ĐÓNG"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 13
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = frame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)
end)
