--[[
    MODULE: Utils.lua
    Mô tả: Các hàm tiện ích cốt lõi (Định vị Base, Teleport, Kích hoạt Prompt, Trang bị Tool)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local Utils = {}
local cachedMyBase = nil

function Utils.getMyBase()
    if cachedMyBase and cachedMyBase.Parent then
        return cachedMyBase
    end

    local bases = Workspace:FindFirstChild("Bases")
    if not bases then return nil end

    -- 1. Ưu tiên số 1: Nhận diện trực tiếp qua Prompt hiển thị trên màn hình người chơi (ExpressivePromptsGui)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local ep = pg and pg:FindFirstChild("ExpressivePromptsGui")
    if ep then
        for _, child in ipairs(ep:GetChildren()) do
            local baseName = child.Name:match("Bases%.(Base%d+)")
            if baseName and bases:FindFirstChild(baseName) then
                cachedMyBase = bases[baseName]
                return cachedMyBase
            end
        end
    end

    -- 2. Kiểm tra thuộc tính của người chơi (Attribute)
    for _, attr in ipairs({"AssignedBaseName", "Base", "BaseName", "CurrentBase", "MyBase"}) do
        local bName = LocalPlayer:GetAttribute(attr)
        if bName and bases:FindFirstChild(tostring(bName)) then
            cachedMyBase = bases[tostring(bName)]
            return cachedMyBase
        end
    end

    -- 3. Kiểm tra Owner hoặc Tên Base
    for _, base in ipairs(bases:GetChildren()) do
        local owner = base:FindFirstChild("Owner") or base:FindFirstChild("Player")
        if (owner and tostring(owner.Value) == LocalPlayer.Name) or base.Name:find(LocalPlayer.Name) then
            cachedMyBase = base
            return base
        end
        for _, val in pairs(base:GetAttributes()) do
            if tostring(val) == LocalPlayer.Name or tostring(val) == tostring(LocalPlayer.UserId) then
                cachedMyBase = base
                return base
            end
        end
    end

    -- 4. Kiểm tra khoảng cách nhân vật tới base gần nhất
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local closest = nil
        local minDist = math.huge
        for _, b in ipairs(bases:GetChildren()) do
            local p = b:FindFirstChildWhichIsA("BasePart", true)
            if p then
                local d = (hrp.Position - p.Position).Magnitude
                if d < minDist and d < 120 then
                    minDist = d
                    closest = b
                end
            end
        end
        if closest then
            cachedMyBase = closest
            return closest
        end
    end

    -- 5. Quét bục có prompt Buy
    for _, base in ipairs(bases:GetChildren()) do
        local pedestals = base:FindFirstChild("OrePedestals")
        if pedestals then
            for _, p in ipairs(pedestals:GetDescendants()) do
                if p:IsA("ProximityPrompt") and (p.ActionText == "Buy" or p.ActionText:lower():find("buy")) then
                    cachedMyBase = base
                    return base
                end
            end
        end
    end

    local fallback = bases:FindFirstChild("Base4") or bases:FindFirstChild("Base3") or bases:FindFirstChild("Base1")
    if fallback then
        cachedMyBase = fallback
        return fallback
    end

    return nil
end

function Utils.teleportTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.CFrame = cf + Vector3.new(0, 1.2, 0)
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end
end

function Utils.firePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        pcall(function()
            prompt.MaxActivationDistance = 9999
            prompt.RequiresLineOfSight = false
            prompt.Enabled = true

            local holdTime = prompt.HoldDuration
            if not holdTime or holdTime <= 0 then
                holdTime = 0.1
            end

            -- 1. Gọi trực tiếp API native của Roblox Engine
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(holdTime + 0.05)
                prompt:InputHoldEnd()
            end)

            -- 2. Hỗ trợ executor C-level
            if fireproximityprompt then
                pcall(function() fireproximityprompt(prompt, 0, true) end)
                pcall(function() fireproximityprompt(prompt) end)
            end

            -- 3. VirtualInputManager (luôn đảm bảo nhả phím đúng thời gian)
            local vim = VirtualInputManager or game:GetService("VirtualInputManager")
            if vim then
                local keyCode = prompt.KeyboardKeyCode or Enum.KeyCode.E
                pcall(function()
                    vim:SendKeyEvent(true, keyCode, false, game)
                    task.wait(holdTime)
                    vim:SendKeyEvent(false, keyCode, false, game)
                end)
            end
        end)
    end
end

function Utils.isOreMatchingWhitelist(toolName, whitelistMap)
    if not whitelistMap then return true end
    if not toolName or toolName == "" then return false end

    local cleanTool = toolName:lower():gsub("%s+", "")

    for oreName, active in pairs(whitelistMap) do
        if active then
            local cleanOre = oreName:lower():gsub("%s+", "")
            -- 1. Trùng khớp 100%
            if cleanTool == cleanOre then
                return true
            end
            -- 2. Trùng khớp khi bỏ chữ 'ore' ở cuối
            local baseTool = cleanTool:gsub("ore$", "")
            local baseOre = cleanOre:gsub("ore$", "")
            if baseTool ~= "" and baseTool == baseOre then
                return true
            end
        end
    end
    return false
end

function Utils.equipToolToHand(tool)
    if not tool then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    if tool.Parent == char then
        return true
    end

    if humanoid then
        humanoid:UnequipTools()
        task.wait(0.08)
    end

    if humanoid and backpack and tool.Parent == backpack then
        humanoid:EquipTool(tool)
    else
        pcall(function() tool.Parent = backpack end)
        task.wait(0.08)
        if humanoid then humanoid:EquipTool(tool) end
    end

    local t0 = tick()
    while tick() - t0 < 0.6 do
        if tool.Parent == char then
            return true
        end
        task.wait(0.05)
    end

    return tool.Parent == char
end

function Utils.equipToolFromWhitelist(whitelistMap)
    local char = LocalPlayer.Character
    if not char then return nil end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and Utils.isOreMatchingWhitelist(currentTool.Name, whitelistMap) then
        return currentTool
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and Utils.isOreMatchingWhitelist(item.Name, whitelistMap) then
                local success = Utils.equipToolToHand(item)
                if success then
                    return item
                end
            end
        end
    end

    return nil
end

function Utils.hasToolInWhitelist(whitelistMap)
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Tool") then
        local t = char:FindFirstChildOfClass("Tool")
        if Utils.isOreMatchingWhitelist(t.Name, whitelistMap) then
            return true
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and Utils.isOreMatchingWhitelist(item.Name, whitelistMap) then
                return true
            end
        end
    end

    return false
end

function Utils.unequipAllTools()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:UnequipTools() end)
    end
end

function Utils.clearBlurAndDimmer()
    pcall(function()
        local lighting = game:GetService("Lighting")
        for _, obj in ipairs(lighting:GetChildren()) do
            if obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") then
                obj.Enabled = false
            end
        end
        local cam = Workspace.CurrentCamera
        if cam then
            for _, obj in ipairs(cam:GetChildren()) do
                if obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect") then
                    obj.Enabled = false
                end
            end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local mf = pg and pg:FindFirstChild("MainFrames")
        if mf then
            for _, child in ipairs(mf:GetChildren()) do
                local cName = child.Name:lower()
                if (cName:find("dim") or cName:find("blur") or cName:find("overlay") or cName:find("shade") or cName:find("dark")) and child:IsA("GuiObject") then
                    child.Visible = false
                end
            end
        end
    end)
end

-- Bảng tỷ lệ quy đổi số tiền cho toàn bộ hệ thống (Hỗ trợ từ K, M, B, T, Qa, Qi đến Vigintillion)
local MONEY_SUFFIXES = {
    -- 4+ ký tự
    ["qavg"] = 1e75, ["qivg"] = 1e78, ["sxvg"] = 1e81, ["spvg"] = 1e84, ["ocvg"] = 1e87, ["novg"] = 1e90,
    ["cent"] = 1e303,
    
    -- 3 ký tự
    ["tvg"] = 1e72, ["dvg"] = 1e69, ["uvg"] = 1e66, ["vig"] = 1e63,
    ["utg"] = 1e96,
    ["nod"] = 1e60, ["nond"] = 1e60,
    ["ocd"] = 1e57, ["octd"] = 1e57,
    ["spd"] = 1e54, ["septd"] = 1e54,
    ["sxd"] = 1e51, ["sexd"] = 1e51,
    ["qid"] = 1e48, ["qind"] = 1e48,
    ["qad"] = 1e45, ["quad"] = 1e45,
    ["td"]  = 1e42, ["tred"] = 1e42,
    ["dd"]  = 1e39, ["duod"] = 1e39,
    ["ud"]  = 1e36, ["und"] = 1e36,
    ["dec"] = 1e33,
    ["non"] = 1e30,
    ["oct"] = 1e27,
    ["sep"] = 1e24, ["spt"] = 1e24,
    ["sex"] = 1e21, ["sxt"] = 1e21,
    ["qui"] = 1e18, ["qin"] = 1e18,
    ["qua"] = 1e15, ["qdr"] = 1e15,
    
    -- 2 ký tự (Phổ biến nhất trong game Sell Ores & Roblox Incremental Games)
    ["tg"]  = 1e93,
    ["vg"]  = 1e63,
    ["dc"]  = 1e33,
    ["no"]  = 1e30,
    ["oc"]  = 1e27,
    ["sp"]  = 1e24,
    ["sx"]  = 1e21,
    ["qi"]  = 1e18, -- Quintillion
    ["qn"]  = 1e18,
    ["qa"]  = 1e15, -- Quadrillion
    ["qd"]  = 1e15,
    
    -- 1 ký tự
    ["t"]   = 1e12,
    ["b"]   = 1e9,
    ["m"]   = 1e6,
    ["k"]   = 1e3,
    ["q"]   = 1e15, -- Fallback nếu chỉ ghi 'q'
    ["s"]   = 1e21, -- Fallback nếu chỉ ghi 's'
}

local FORMAT_SCALES = {
    {1e63, "Vg"},
    {1e60, "Nod"},
    {1e57, "Ocd"},
    {1e54, "Spd"},
    {1e51, "Sxd"},
    {1e48, "Qid"},
    {1e45, "Qad"},
    {1e42, "Td"},
    {1e39, "Dd"},
    {1e36, "Ud"},
    {1e33, "Dc"},
    {1e30, "No"},
    {1e27, "Oc"},
    {1e24, "Sp"},
    {1e21, "Sx"},
    {1e18, "Qi"},
    {1e15, "Qa"},
    {1e12, "T"},
    {1e9,  "B"},
    {1e6,  "M"},
    {1e3,  "K"},
}

-- Chuyển đổi chuỗi tiền ($1,500, 50k, 2.5M, 10B, 1.2T, 5.45Qa, 12.8Qi, etc.) sang số thực
function Utils.parseMoneyString(str)
    if not str then return nil end
    local clean = tostring(str):gsub(",", ""):gsub("%$", ""):gsub("%s+", ""):lower()
    
    -- 1. Nếu là số thuần hoặc dạng ký hiệu khoa học (e.g. "1.5e18", "50000")
    local directNum = tonumber(clean)
    if directNum then return directNum end

    -- 2. Trích xuất phần số và hậu tố (e.g. "5.45qa", "12.8qi", "buy(50.5qi)")
    local numStr, suffix = clean:match("([%d%.]+)(%a*)")
    if not numStr then return nil end
    local num = tonumber(numStr)
    if not num then return nil end

    if suffix and suffix ~= "" then
        if MONEY_SUFFIXES[suffix] then
            num = num * MONEY_SUFFIXES[suffix]
        elseif #suffix >= 2 and MONEY_SUFFIXES[suffix:sub(1, 2)] then
            num = num * MONEY_SUFFIXES[suffix:sub(1, 2)]
        elseif #suffix >= 1 and MONEY_SUFFIXES[suffix:sub(1, 1)] then
            num = num * MONEY_SUFFIXES[suffix:sub(1, 1)]
        end
    end

    return num
end

-- Lấy số tiền hiện tại của người chơi từ leaderstats, Attributes hoặc PlayerGui
function Utils.getPlayerMoney()
    local lp = LocalPlayer or game:GetService("Players").LocalPlayer
    if not lp then return nil end

    -- 1. ƯU TIÊN SỐ 1: Attribute "Money" dạng số nguyên (Game server cập nhật số 64-bit chuẩn xác 100%)
    for _, attr in ipairs({"Money", "Cash", "Coins", "Balance", "Gold"}) do
        local val = lp:GetAttribute(attr)
        if type(val) == "number" and val > 0 then
            return val
        elseif type(val) == "string" then
            local parsed = Utils.parseMoneyString(val)
            if parsed and parsed > 0 then return parsed end
        end
    end

    -- 2. leaderstats (StringValue như "$1.9Qi" hoặc NumberValue)
    local leaderstats = lp:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs({"Money", "Cash", "Coins", "Gold", "Balance", "Dollar", "OreCoins"}) do
            local valObj = leaderstats:FindFirstChild(name)
            if valObj and valObj:IsA("ValueBase") then
                if type(valObj.Value) == "number" then
                    return valObj.Value
                elseif type(valObj.Value) == "string" then
                    local parsed = Utils.parseMoneyString(valObj.Value)
                    if parsed then return parsed end
                end
            end
        end
        for _, child in ipairs(leaderstats:GetChildren()) do
            if (child:IsA("NumberValue") or child:IsA("IntValue")) and child.Name:lower():find("gem") == nil then
                return child.Value
            elseif child:IsA("StringValue") and child.Name:lower():find("gem") == nil then
                local parsed = Utils.parseMoneyString(child.Value)
                if parsed then return parsed end
            end
        end
    end

    -- 3. PlayerData / Stats folder
    for _, folderName in ipairs({"PlayerData", "Data", "Stats", "Currencies"}) do
        local folder = lp:FindFirstChild(folderName)
        if folder then
            for _, name in ipairs({"Money", "Cash", "Coins", "Balance"}) do
                local v = folder:FindFirstChild(name)
                if v and v:IsA("ValueBase") then
                    if type(v.Value) == "number" then
                        return v.Value
                    elseif type(v.Value) == "string" then
                        local parsed = Utils.parseMoneyString(v.Value)
                        if parsed then return parsed end
                    end
                end
            end
        end
    end

    -- 4. PlayerGui (Chỉ quét TextLabel là HUD hiển thị số dư, LOẠI TRỪ các nút Button mua bán)
    local pg = lp:FindFirstChild("PlayerGui")
    if pg then
        -- Ưu tiên 1: TextLabel có tên liên quan đến Cash/Money/Coins/Balance
        for _, label in ipairs(pg:GetDescendants()) do
            if label:IsA("TextLabel") and label.Visible and not label:FindFirstAncestorWhichIsA("GuiButton") then
                local lName = label.Name:lower()
                if lName:find("cash") or lName:find("money") or lName:find("coin") or lName:find("balance") or lName:find("currency") then
                    local parsed = Utils.parseMoneyString(label.Text)
                    if parsed and parsed > 0 then
                        return parsed
                    end
                end
            end
        end

        -- Ưu tiên 2: TextLabel bất kỳ có chứa ký tự $ nhưng không nằm trong Button
        for _, label in ipairs(pg:GetDescendants()) do
            if label:IsA("TextLabel") and label.Visible and not label:FindFirstAncestorWhichIsA("GuiButton") and label.Text:find("%$") then
                local parsed = Utils.parseMoneyString(label.Text)
                if parsed and parsed > 0 then
                    return parsed
                end
            end
        end
    end

    return nil
end

-- Định dạng số hiển thị rút gọn ($1.5M, $50K, $5.45Qa, $12.8Qi, v.v.)
function Utils.formatNumber(num)
    if not num then return "0" end
    num = tonumber(num) or 0
    for _, scale in ipairs(FORMAT_SCALES) do
        if num >= scale[1] then
            return string.format("%.2f%s", num / scale[1], scale[2])
        end
    end
    return tostring(math.floor(num))
end

-- Lấy số Gems hiện tại của người chơi
function Utils.getPlayerGems()
    local lp = LocalPlayer or game:GetService("Players").LocalPlayer
    if not lp then return nil end

    -- 1. ƯU TIÊN SỐ 1: Attribute "GrowthGemInventoryCount" chuẩn của game Sell Ores
    local growthGems = lp:GetAttribute("GrowthGemInventoryCount")
    if type(growthGems) == "number" then
        return growthGems
    end

    -- 2. Attributes khác
    for _, attr in ipairs({"Gems", "Gem", "Diamonds", "Diamond", "GrowthGems"}) do
        local val = lp:GetAttribute(attr)
        if type(val) == "number" then
            return val
        elseif type(val) == "string" then
            local parsed = Utils.parseMoneyString(val)
            if parsed then return parsed end
        end
    end

    -- 3. leaderstats
    local leaderstats = lp:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs({"Gems", "Gem", "Diamonds", "Diamond", "GrowthGems"}) do
            local valObj = leaderstats:FindFirstChild(name)
            if valObj and valObj:IsA("ValueBase") then
                if type(valObj.Value) == "number" then
                    return valObj.Value
                elseif type(valObj.Value) == "string" then
                    local parsed = Utils.parseMoneyString(valObj.Value)
                    if parsed then return parsed end
                end
            end
        end
    end

    return nil
end

return Utils
