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

-- Chuyển đổi chuỗi tiền ($1,500, 50k, 2.5M, 10B, 1.2T, etc.) sang số thực
function Utils.parseMoneyString(str)
    if not str then return nil end
    local clean = tostring(str):gsub(",", ""):gsub("%$", ""):gsub("%s+", ""):lower()
    local numStr, suffix = clean:match("^([%d%.]+)([kmbtq]?)$")
    if not numStr then
        numStr = clean:match("([%d%.]+)")
    end
    local num = tonumber(numStr)
    if not num then return nil end

    if suffix == "k" then
        num = num * 1e3
    elseif suffix == "m" then
        num = num * 1e6
    elseif suffix == "b" then
        num = num * 1e9
    elseif suffix == "t" then
        num = num * 1e12
    elseif suffix == "q" then
        num = num * 1e15
    end

    return num
end

-- Lấy số tiền hiện tại của người chơi từ leaderstats, Attributes hoặc PlayerGui
function Utils.getPlayerMoney()
    local lp = LocalPlayer or game:GetService("Players").LocalPlayer
    if not lp then return nil end

    -- 1. leaderstats
    local leaderstats = lp:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs({"Cash", "Money", "Coins", "Gold", "Balance", "Dollar", "OreCoins"}) do
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
            end
        end
    end

    -- 2. Attributes
    for _, attr in ipairs({"Cash", "Money", "Coins", "Balance", "Gold"}) do
        local val = lp:GetAttribute(attr)
        if type(val) == "number" then
            return val
        elseif type(val) == "string" then
            local parsed = Utils.parseMoneyString(val)
            if parsed then return parsed end
        end
    end

    -- 3. PlayerData / Stats folder
    for _, folderName in ipairs({"PlayerData", "Data", "Stats", "Currencies"}) do
        local folder = lp:FindFirstChild(folderName)
        if folder then
            for _, name in ipairs({"Cash", "Money", "Coins", "Balance"}) do
                local v = folder:FindFirstChild(name)
                if v and v:IsA("ValueBase") and type(v.Value) == "number" then
                    return v.Value
                end
            end
        end
    end

    -- 4. PlayerGui (HUD Labels có ký tự $)
    local pg = lp:FindFirstChild("PlayerGui")
    if pg then
        for _, label in ipairs(pg:GetDescendants()) do
            if label:IsA("TextLabel") and label.Visible and label.Text:find("%$") then
                local parsed = Utils.parseMoneyString(label.Text)
                if parsed and parsed > 0 then
                    return parsed
                end
            end
        end
    end

    return nil
end

-- Định dạng số hiển thị rút gọn ($1.5M, $50K, v.v.)
function Utils.formatNumber(num)
    if not num then return "0" end
    num = tonumber(num) or 0
    if num >= 1e15 then
        return string.format("%.2fQ", num / 1e15)
    elseif num >= 1e12 then
        return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.2fK", num / 1e3)
    else
        return tostring(math.floor(num))
    end
end

-- Lấy số Gems hiện tại của người chơi
function Utils.getPlayerGems()
    local lp = LocalPlayer or game:GetService("Players").LocalPlayer
    if not lp then return nil end

    -- 1. leaderstats
    local leaderstats = lp:FindFirstChild("leaderstats")
    if leaderstats then
        for _, name in ipairs({"Gems", "Gem", "Diamonds", "Diamond"}) do
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

    -- 2. Attributes
    for _, attr in ipairs({"Gems", "Gem", "Diamonds", "Diamond"}) do
        local val = lp:GetAttribute(attr)
        if type(val) == "number" then
            return val
        elseif type(val) == "string" then
            local parsed = Utils.parseMoneyString(val)
            if parsed then return parsed end
        end
    end

    -- 3. PlayerData / Stats folder
    for _, folderName in ipairs({"PlayerData", "Data", "Stats", "Currencies"}) do
        local folder = lp:FindFirstChild(folderName)
        if folder then
            for _, name in ipairs({"Gems", "Gem", "Diamonds"}) do
                local v = folder:FindFirstChild(name)
                if v and v:IsA("ValueBase") and type(v.Value) == "number" then
                    return v.Value
                end
            end
        end
    end

    return nil
end

return Utils
