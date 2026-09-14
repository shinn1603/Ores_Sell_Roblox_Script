--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                 SELL ORES HUB - V7.8 ULTIMATE PRO                ║
    ║   • MODULAR ARCHITECTURE: CHIA TÁCH MODULE RÕ RÀNG & MƯỢT MÀ     ║
    ║   • FULL AUTO ROLL: TỰ MỞ BẢNG, BẤM START & TỰ ĐÓNG BẢNG 100%    ║
    ║   • SMART FUSER: NẠP QUẶNG AN TOÀN & BẢO VỆ TUYỆT ĐỐI QUẶNG XỊN  ║
    ║   • ORE BUFF SHOWCASE: DUY TRÌ TỰ ĐỘNG X2.75 BUFF 24/7           ║
    ║   • MONEY PIPELINE: ĐÀO MỎ -> NUNG LÒ -> BÁN TIỀN KHÉP KÍN       ║
    ║   • FLOATING TOGGLE BUTTON TRÒN NỔI MỞ LẠI MENU MỌI LÚC          ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()


--------------------------------------------------------------------------------
-- MODULE: OresData.lua
--------------------------------------------------------------------------------
--[[
    MODULE: OresData.lua
    Mô tả: Danh sách 81 loại quặng chuẩn xác 100% trích xuất từ game Sell Ores
]]

local OresData = {}

OresData.AllGameOres = {
    -- Bậc Tối Thượng / Thần Thoại / Cosmic
    "The First Star", "WorldBreaker Ore", "Worldroot Ore", "Omnipotence Ore", "Reality Ore",
    "Singularity Ore", "Starforge Ore", "Supernova Ore", "Event Horizon Ore", "Zeus Core",
    "Devils Core", "Creators Core Ore", "Nova Core Ore", "Antimatter Crystal", "Astral Heart Ore",
    "Godcube Ore", "Godstone Ore", "Infinity Ore", "Divine Crystal", "Galaxy Crystal",
    "Genesis Crystal", "Solaris Crystal", "Lunar Crystal", "Eclipse Crystal", "Chrono Crystal",
    "Sulfur Crystal", "Devil Crystal", "Cotton Candy Crystal", "Gummy Crystal",

    -- Bậc Huyền Thoại / Đặc Biệt / Anime / Event
    "Dragon Ore", "DragonBall Ore", "DevilFruit Ore", "Nichirin Ore", "PalBall Ore",
    "Eternium Ore", "Empyrean Ore", "Celestium Ore", "Chaos Ore", "Primordial Ore",
    "Prism Ore", "Quantumite Ore", "Nebula Ore", "Nebulite Ore", "Dark Matter Ore",
    "Cryocube Ore", "Embercube Ore", "Crystalite Ore", "Verdantite Ore", "Voidstone Ore",
    "Adminite Ore", "Aether Ore", "Origin Ore", "Seraphite Ore", "Titan Ore", "Igros Ore",

    -- Bậc Đá Quý & Kim Loại Hiếm (Gems & High Tier)
    "Emerald Ore", "Ruby Ore", "Sapphire Ore", "Amethyst Ore", "Amber Ore",
    "Jade Ore", "Sunstone Ore", "Runestone Ore", "Seastone Ore", "Titanium Ore",
    "Platinum Ore", "Gold Ore", "Mythril Ore", "Obsidian Ore",

    -- Bậc Cơ Bản / Thường (Starter & Common)
    "Silver Ore", "Copper Ore", "Iron Ore", "Lead Ore", "Tin Ore",
    "Zinc Ore", "Quartzite Ore", "Coal Ore", "Stone Ore", "Bubblegum Ore",
    "Chocolate Ore", "Lollipop Ore"
}

table.sort(OresData.AllGameOres)

-- Sắp xếp danh sách tên quặng theo độ dài giảm dần để match chính xác nhất
OresData.SortedOresByLen = {}
for _, o in ipairs(OresData.AllGameOres) do table.insert(OresData.SortedOresByLen, o) end
table.sort(OresData.SortedOresByLen, function(a, b) return #a > #b end)

OresData.OreAliases = {
    ["dragonballore"] = "DragonBall Ore",
    ["palballore"] = "PalBall Ore",
    ["nichirinswordore"] = "Nichirin Ore",
}


--------------------------------------------------------------------------------
-- MODULE: State.lua
--------------------------------------------------------------------------------
--[[
    MODULE: State.lua
    Mô tả: Quản lý biến trạng thái toàn hệ thống & danh sách mặc định
]]

local State = {
    -- Pro Farm Loop
    ProFarmLoop = false,
    AutoApplyGems = true,
    AutoActivateBuff = true,
    LastBuffActivated = 0,

    -- Quy trình tiền (đào mỏ -> nung lò -> bán)
    AutoMoneyPipeline = true,
    MoneyPipelineInterval = 12,
    MoneyStepDelay = 0.4,
    LastMoneyPipelineTime = 0,

    -- Roll & Buy Target Ores
    AutoRollBuyEnabled = false,
    RollScanDelay = 0.5,
    AutoBuyTargetOres = true,
    BuyAllPedestals = false,
    AutoReRollAfterBuy = true,
    WantedBuyOres = {}, -- { ["Tên Quặng"] = true }

    -- Smart Fuser
    SmartFuser = true,
    LastFuserRun = 0,
    AllowedFuseOres = {}, -- { ["Tên Quặng"] = true }

    -- Movement & AFK
    WalkSpeedEnabled = false,
    WalkSpeedValue = 16,
    JumpPowerEnabled = false,
    JumpPowerValue = 50,
    InfiniteJump = false,
    Noclip = false,
    AntiAFK = true
}

-- Mặc định danh sách quặng muốn mua: Quặng Thần Thoại / Tối Thượng
local defaultBuy = {
    "The First Star", "WorldBreaker Ore", "Omnipotence Ore", "Singularity Ore", 
    "Starforge Ore", "Supernova Ore", "Zeus Core", "Devils Core", "Infinity Ore",
    "Divine Crystal", "Galaxy Crystal", "Dragon Ore", "DragonBall Ore", "DevilFruit Ore"
}
for _, o in ipairs(defaultBuy) do State.WantedBuyOres[o] = true end

-- Mặc định danh sách quặng cho phép nung Fuser: Chỉ quặng cơ bản an toàn
local defaultFuse = {
    "Stone Ore", "Coal Ore", "Copper Ore", "Tin Ore"
}
for _, o in ipairs(defaultFuse) do State.AllowedFuseOres[o] = true end

-- State, defaultBuy, defaultFuse are now all in local scope for bundler

--------------------------------------------------------------------------------
-- MODULE: Utils.lua
--------------------------------------------------------------------------------
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
            end
        end
    end

    -- 2. Kiểm tra thuộc tính của người chơi (Attribute)
    for _, attr in ipairs({"AssignedBaseName", "Base", "BaseName", "CurrentBase", "MyBase"}) do
        local bName = LocalPlayer:GetAttribute(attr)
        if bName and bases:FindFirstChild(tostring(bName)) then
            cachedMyBase = bases[tostring(bName)]
        end
    end

    -- 3. Kiểm tra Owner hoặc Tên Base
    for _, base in ipairs(bases:GetChildren()) do
        local owner = base:FindFirstChild("Owner") or base:FindFirstChild("Player")
        if (owner and tostring(owner.Value) == LocalPlayer.Name) or base.Name:find(LocalPlayer.Name) then
            cachedMyBase = base
        end
        for _, val in pairs(base:GetAttributes()) do
            if tostring(val) == LocalPlayer.Name or tostring(val) == tostring(LocalPlayer.UserId) then
                cachedMyBase = base
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
        end
    end

    -- 5. Quét bục có prompt Buy
    for _, base in ipairs(bases:GetChildren()) do
        local pedestals = base:FindFirstChild("OrePedestals")
        if pedestals then
            for _, p in ipairs(pedestals:GetDescendants()) do
                if p:IsA("ProximityPrompt") and (p.ActionText == "Buy" or p.ActionText:lower():find("buy")) then
                    cachedMyBase = base
                end
            end
        end
    end

    local fallback = bases:FindFirstChild("Base4") or bases:FindFirstChild("Base3") or bases:FindFirstChild("Base1")
    if fallback then
        cachedMyBase = fallback
    end

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
            end
            -- 2. Trùng khớp khi bỏ chữ 'ore' ở cuối
            local baseTool = cleanTool:gsub("ore$", "")
            local baseOre = cleanOre:gsub("ore$", "")
            if baseTool ~= "" and baseTool == baseOre then
            end
        end
    end
end

function Utils.equipToolToHand(tool)
    if not tool then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    if tool.Parent == char then
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
        end
        task.wait(0.05)
    end

end

function Utils.equipToolFromWhitelist(whitelistMap)
    local char = LocalPlayer.Character
    if not char then return nil end

    local currentTool = char:FindFirstChildOfClass("Tool")
    if currentTool and Utils.isOreMatchingWhitelist(currentTool.Name, whitelistMap) then
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and Utils.isOreMatchingWhitelist(item.Name, whitelistMap) then
                local success = Utils.equipToolToHand(item)
                if success then
                end
            end
        end
    end

end

function Utils.hasToolInWhitelist(whitelistMap)
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Tool") then
        local t = char:FindFirstChildOfClass("Tool")
        if Utils.isOreMatchingWhitelist(t.Name, whitelistMap) then
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and Utils.isOreMatchingWhitelist(item.Name, whitelistMap) then
            end
        end
    end

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


--------------------------------------------------------------------------------
-- MODULE: AutoRoll.lua
--------------------------------------------------------------------------------
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
                    end
                end
            end
        end

        for _, desc in ipairs(roller:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local act = (desc.ActionText or ""):lower()
                if act:find("auto") or act:find("roll") or (desc.Parent and desc.Parent.Name:lower():find("lever")) then
                end
            end
        end

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
                end
            end
        end
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

    end

    -- 4. Kích hoạt Auto Roll của game (Thao tác gạt cần Auto Roller thực tế trong Base)
    function AutoRoll.triggerGameAutoRoll(force)
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
                end
            end
        end

    end

    function AutoRoll.isOreWanted(oreName)
        if State.BuyAllPedestals then return true end
        if not oreName or oreName == "Unknown" then return false end

        local oClean = oreName:lower():gsub("%s+", "")
        for wanted, active in pairs(State.WantedBuyOres) do
            if active then
                local wClean = wanted:lower():gsub("%s+", "")
                if oClean == wClean or oClean:find(wClean) or wClean:find(oClean) then
                end
            end
        end
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

    end
end


--------------------------------------------------------------------------------
-- MODULE: SmartFuser.lua
--------------------------------------------------------------------------------
--[[
    MODULE: SmartFuser.lua
    Mô tả: Tự động nạp quặng vào 5 node của Fuser và nhận thành phẩm Mega Ore (Bảo vệ quặng xịn 100%)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local SmartFuser = {}

function SmartFuser.init(deps)
    local Utils = deps.Utils
    local State = deps.State

    function SmartFuser.run()
        local base = Utils.getMyBase()
        if not base or not base:FindFirstChild("Fuser") then return false, "Không tìm thấy Fuser trong căn cứ" end
        local fuser = base.Fuser
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false, "Chưa tải nhân vật" end

        -- Lưu vị trí đứng ban đầu để quay về
        local originCF = char.HumanoidRootPart.CFrame

        -- 1. Nếu có prompt 'Claim Fused Ore' -> Bay tới nhận ngay!
        for _, prompt in ipairs(fuser:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.ActionText:lower():find("claim") then
                if prompt.Parent and prompt.Parent:IsA("BasePart") then
                    Utils.teleportTo(prompt.Parent.CFrame + Vector3.new(0, 2.0, 0))
                    task.wait(0.25)
                end
                Utils.firePrompt(prompt)
                task.wait(0.35)
                if originCF then Utils.teleportTo(originCF) end
            end
        end

        -- 2. Kiểm tra xem người chơi có quặng nào trong danh sách cho phép nung ở túi đồ không
        local hasAnyAllowedOre = Utils.hasToolInWhitelist(State.AllowedFuseOres)
        if not hasAnyAllowedOre then
        end

        -- 3. Tìm tất cả các node đang TRỐNG (Place Ore / Place / Add / Fuse)
        local emptyNodes = {}
        for _, prompt in ipairs(fuser:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local act = (prompt.ActionText or ""):lower()
                if not act:find("claim") and not act:find("remove") then
                    if act:find("place") or act:find("deposit") or act:find("insert") or act:find("add") or act:find("fuse") or act == "" then
                        table.insert(emptyNodes, prompt)
                    end
                end
            end
        end

        if #emptyNodes == 0 then
        end

        -- 4. Nạp quặng vào từng node trống (TELEPORT TRƯỚC → CẦM QUẶNG → BẤM PLACE)
        local placedCount = 0
        for _, prompt in ipairs(emptyNodes) do
            -- Bước A: Teleport đến node TRƯỚC (chưa cầm gì cả!)
            if prompt.Parent and prompt.Parent:IsA("BasePart") then
                Utils.unequipAllTools()
                task.wait(0.1)
                Utils.teleportTo(prompt.Parent.CFrame + Vector3.new(0, 2.0, 0))
                task.wait(0.35)
            end

            -- Bước B: SAU KHI ĐÃ ĐỨNG YÊN, mới cầm quặng lên tay
            local tool = Utils.equipToolFromWhitelist(State.AllowedFuseOres)
            if not tool then
                -- Không còn quặng nào trong danh sách cho phép ở túi đồ -> Dừng, bảo vệ quặng xịn!
                break
            end

            local okEquip = Utils.equipToolToHand(tool)
            if not okEquip then break end
            task.wait(0.25) -- Đợi game server xác nhận tool đã trên tay

            -- Bước C: Kích hoạt prompt để đặt quặng vào Fuser
            Utils.firePrompt(prompt)
            task.wait(0.4)

            -- Bước D: Nếu tool vẫn còn trên tay (game chưa nhận) -> thử lại 2 lần nữa
            for retry = 1, 2 do
                if tool.Parent == char and prompt.Enabled then
                    -- Equip lại tool (đề phòng bị drop)
                    Utils.equipToolToHand(tool)
                    task.wait(0.2)
                    Utils.firePrompt(prompt)
                    task.wait(0.35)
                else
                    break
                end
            end

            placedCount = placedCount + 1
        end

        -- Cất toàn bộ tool vào túi, không cầm trên tay
        Utils.unequipAllTools()

        -- QUAY LẠI VỊ TRÍ ĐỨNG BAN ĐẦU (Không đứng ngơ ngác ở Fuser!)
        if originCF then
            Utils.teleportTo(originCF)
        end

    end
end


--------------------------------------------------------------------------------
-- MODULE: MoneyPipeline.lua
--------------------------------------------------------------------------------
--[[
    MODULE: MoneyPipeline.lua
    Mô tả: Chu trình kiếm tiền tự động (CrateMaker -> Furnace -> SellerTable)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local MoneyPipeline = {}

function MoneyPipeline.init(deps)
    local Utils = deps.Utils
    local State = deps.State

    local function findPipelineTool()
        local char = LocalPlayer.Character
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        local containers = {char, backpack}
        for _, container in ipairs(containers) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        local n = item.Name:lower()
                        if not n:find("pickaxe") and not n:find("sword") and not n:find("weapon") and not n:find("gun") and not n:find("rod") and not n:find("potion") then
                            if n:find("crate") or n:find("metal") or n:find("bar") or n:find("ore") or n:find("box") then
                            end
                        end
                    end
                end
            end
        end
    end

    function MoneyPipeline.run()
        local base = Utils.getMyBase()
        if not base then return false, "Không tìm thấy căn cứ" end

        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return false, "Chưa tải nhân vật" end

        local cm = base:FindFirstChild("CrateMaker")
        local furnace = base:FindFirstChild("Furnace")
        local st = base:FindFirstChild("SellerTable")

        local stepDelay = math.clamp(State.MoneyStepDelay or 0.4, 0.25, 1.0)
        local prevCF = char.HumanoidRootPart.CFrame

        -- BƯỚC 0: KIỂM TRA XEM LÒ NUNG ĐÃ CÓ SẴN THÙNG KIM LOẠI NUNG XONG CHƯA
        local readyMetalPrompt = nil
        if furnace and furnace:FindFirstChild("MetalCratePlacementPart") then
            for _, p in ipairs(furnace.MetalCratePlacementPart:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.ActionText == "Pick up" and p.Enabled then
                    readyMetalPrompt = p
                    break
                end
            end
        end

        if readyMetalPrompt then
            Utils.teleportTo(furnace.MetalCratePlacementPart.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(readyMetalPrompt)
            task.wait(stepDelay + 0.1)
        else
            -- BƯỚC 1: Thu hoạch thùng quặng thô từ CrateMaker
            local pickOrePrompt = nil
            if cm and cm:FindFirstChild("CrateSpawnPoint") then
                for _, p in ipairs(cm.CrateSpawnPoint:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.ActionText:find("Pick up") and p.Enabled then
                        pickOrePrompt = p
                        break
                    end
                end
            end

            if not pickOrePrompt then
            end

            Utils.teleportTo(cm.CrateSpawnPoint.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            Utils.firePrompt(pickOrePrompt)
            task.wait(stepDelay + 0.15)

            -- BƯỚC 2: Bỏ vào lò nung Furnace ('Place ORES')
            local placePrompt = nil
            if furnace and furnace:FindFirstChild("PlaceCratesPromptPart") then
                for _, p in ipairs(furnace.PlaceCratesPromptPart:GetDescendants()) do
                    if p:IsA("ProximityPrompt") and p.ActionText:find("Place") and p.Enabled then
                        placePrompt = p
                        break
                    end
                end
            end

            if placePrompt then
                Utils.teleportTo(furnace.PlaceCratesPromptPart.CFrame + Vector3.new(0, 1.5, 0))
                task.wait(stepDelay)

                local crateTool = findPipelineTool()
                if crateTool then Utils.equipToolToHand(crateTool) end
                task.wait(0.12)

                Utils.firePrompt(placePrompt)
                task.wait(stepDelay + 0.2)
            end

            -- BƯỚC 3: Chờ lò nung luyện quặng xong
            local metalPrompt = nil
            local waitSmeltStart = tick()
            while tick() - waitSmeltStart < 6.5 do
                if furnace and furnace:FindFirstChild("MetalCratePlacementPart") then
                    for _, p in ipairs(furnace.MetalCratePlacementPart:GetDescendants()) do
                        if p:IsA("ProximityPrompt") and p.ActionText == "Pick up" and p.Enabled then
                            metalPrompt = p
                            break
                        end
                    end
                end
                if metalPrompt then break end
                task.wait(0.3)
            end

            if metalPrompt then
                Utils.teleportTo(furnace.MetalCratePlacementPart.CFrame + Vector3.new(0, 1.5, 0))
                task.wait(stepDelay)
                Utils.firePrompt(metalPrompt)
                task.wait(stepDelay + 0.15)
            else
                Utils.unequipAllTools()
                if prevCF then Utils.teleportTo(prevCF) end
            end
        end

        -- BƯỚC 4: Cầm chắc thùng trên tay và đem bán tại SellerTable
        local metalTool = findPipelineTool()
        if metalTool then Utils.equipToolToHand(metalTool) end
        task.wait(0.15)

        local sellPrompt = nil
        if st then
            for _, p in ipairs(st:GetDescendants()) do
                if p:IsA("ProximityPrompt") and p.Enabled then
                    local act = p.ActionText:lower()
                    if act:find("sell") or act:find("bán") or act == "" then
                        sellPrompt = p
                        break
                    end
                end
            end
        end

        if sellPrompt and sellPrompt.Parent and sellPrompt.Parent:IsA("BasePart") then
            Utils.teleportTo(sellPrompt.Parent.CFrame + Vector3.new(0, 1.5, 0))
            task.wait(stepDelay)
            if metalTool and metalTool.Parent ~= char then Utils.equipToolToHand(metalTool) end
            task.wait(0.1)
            Utils.firePrompt(sellPrompt)
            task.wait(stepDelay)
        end

        -- Cất tool vào túi sau khi bán xong
        Utils.unequipAllTools()

        -- Quay lại vị trí đứng cũ
        Utils.teleportTo(prevCF)
    end
end


--------------------------------------------------------------------------------
-- MODULE: ShowcaseBuff.lua
--------------------------------------------------------------------------------
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


    end
end


--------------------------------------------------------------------------------
-- MODULE: ConfigManager.lua
--------------------------------------------------------------------------------
--[[
    MODULE: ConfigManager.lua
    Mô tả: Hệ thống lưu & tải cấu hình JSON độc lập (81 loại quặng & mọi cài đặt)
]]

local HttpService = game:GetService("HttpService")

local ConfigManager = {}
local CONFIG_FILE = "SellOres_UserConfig.json"

function ConfigManager.init(deps)
    local State = deps.State
    local defaultBuy = deps.defaultBuy
    local defaultFuse = deps.defaultFuse
    local Fluent = deps.Fluent

    local refreshBuyVisuals = nil
    local refreshFuseVisuals = nil

    function ConfigManager.setVisualCallbacks(buyCb, fuseCb)
        refreshBuyVisuals = buyCb
        refreshFuseVisuals = fuseCb
    end

    function ConfigManager.save(silent)
        local configData = {
            WantedBuyOres = State.WantedBuyOres,
            AllowedFuseOres = State.AllowedFuseOres,
            Settings = {
                AutoMoneyPipeline = State.AutoMoneyPipeline,
                MoneyPipelineInterval = State.MoneyPipelineInterval,
                MoneyStepDelay = State.MoneyStepDelay,
                RollScanDelay = State.RollScanDelay,
                AutoApplyGems = State.AutoApplyGems,
                AutoActivateBuff = State.AutoActivateBuff,
                BuyAllPedestals = State.BuyAllPedestals,
                AutoReRollAfterBuy = State.AutoReRollAfterBuy,
                WalkSpeedEnabled = State.WalkSpeedEnabled,
                WalkSpeedValue = State.WalkSpeedValue,
                JumpPowerEnabled = State.JumpPowerEnabled,
                JumpPowerValue = State.JumpPowerValue,
                InfiniteJump = State.InfiniteJump,
                Noclip = State.Noclip,
                AntiAFK = State.AntiAFK
            }
        }

        local ok, encoded = pcall(function() return HttpService:JSONEncode(configData) end)
        if not ok then
            if not silent then Fluent:Notify({ Title = "Lỗi Lưu Cấu Hình", Content = "Không thể mã hóa dữ liệu!", Duration = 3 }) end
        end

        local writeOk = pcall(function()
            if writefile then
                writefile(CONFIG_FILE, encoded)
            end
        end)

        if writeOk and writefile then
            local buyCount = 0
            for _, v in pairs(State.WantedBuyOres) do if v then buyCount = buyCount + 1 end end
            local fuseCount = 0
            for _, v in pairs(State.AllowedFuseOres) do if v then fuseCount = fuseCount + 1 end end

            if not silent then
                Fluent:Notify({
                    Title = "💾 ĐÃ LƯU CẤU HÌNH THÀNH CÔNG!",
                    Content = string.format("Đã lưu %d quặng mua, %d quặng nung & toàn bộ cài đặt vào file %s!", buyCount, fuseCount, CONFIG_FILE),
                    Duration = 4
                })
            end
        else
            if not silent then
                Fluent:Notify({
                    Title = "Lưu Thất Bại",
                    Content = "Executor của bạn không hỗ trợ hàm writefile!",
                    Duration = 3
                })
            end
        end
    end

    function ConfigManager.load(silent)
        if not isfile or not readfile then
            if not silent then
                Fluent:Notify({ Title = "Lỗi Tải Cấu Hình", Content = "Executor không hỗ trợ đọc file!", Duration = 3 })
            end
        end

        if not isfile(CONFIG_FILE) then
            if not silent then
                Fluent:Notify({ Title = "Không Tìm Thấy File", Content = "Chưa có file " .. CONFIG_FILE .. " đã lưu trước đó!", Duration = 3 })
            end
        end

        local content = nil
        local readOk = pcall(function() content = readfile(CONFIG_FILE) end)
        if not readOk or not content or content == "" then
            if not silent then Fluent:Notify({ Title = "Lỗi Đọc File", Content = "Không thể đọc nội dung file config!", Duration = 3 }) end
        end

        local decodeOk, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not decodeOk or type(data) ~= "table" then
            if not silent then Fluent:Notify({ Title = "Lỗi Giải Mã", Content = "File cấu hình bị lỗi định dạng!", Duration = 3 }) end
        end

        if type(data.WantedBuyOres) == "table" then
            table.clear(State.WantedBuyOres)
            for k, v in pairs(data.WantedBuyOres) do State.WantedBuyOres[k] = v end
            if refreshBuyVisuals then refreshBuyVisuals() end
        end

        if type(data.AllowedFuseOres) == "table" then
            table.clear(State.AllowedFuseOres)
            for k, v in pairs(data.AllowedFuseOres) do State.AllowedFuseOres[k] = v end
            if refreshFuseVisuals then refreshFuseVisuals() end
        end

        if type(data.Settings) == "table" then
            local s = data.Settings
            if s.AutoMoneyPipeline ~= nil then State.AutoMoneyPipeline = s.AutoMoneyPipeline end
            if s.MoneyPipelineInterval ~= nil then State.MoneyPipelineInterval = s.MoneyPipelineInterval end
            if s.MoneyStepDelay ~= nil then State.MoneyStepDelay = s.MoneyStepDelay end
            if s.RollScanDelay ~= nil then State.RollScanDelay = s.RollScanDelay end
            if s.AutoApplyGems ~= nil then State.AutoApplyGems = s.AutoApplyGems end
            if s.AutoActivateBuff ~= nil then State.AutoActivateBuff = s.AutoActivateBuff end
            if s.BuyAllPedestals ~= nil then State.BuyAllPedestals = s.BuyAllPedestals end
            if s.AutoReRollAfterBuy ~= nil then State.AutoReRollAfterBuy = s.AutoReRollAfterBuy end
            if s.WalkSpeedEnabled ~= nil then State.WalkSpeedEnabled = s.WalkSpeedEnabled end
            if s.WalkSpeedValue ~= nil then State.WalkSpeedValue = s.WalkSpeedValue end
            if s.JumpPowerEnabled ~= nil then State.JumpPowerEnabled = s.JumpPowerEnabled end
            if s.JumpPowerValue ~= nil then State.JumpPowerValue = s.JumpPowerValue end
            if s.InfiniteJump ~= nil then State.InfiniteJump = s.InfiniteJump end
            if s.Noclip ~= nil then State.Noclip = s.Noclip end
            if s.AntiAFK ~= nil then State.AntiAFK = s.AntiAFK end
        end

        local buyCount = 0
        for _, v in pairs(State.WantedBuyOres) do if v then buyCount = buyCount + 1 end end
        local fuseCount = 0
        for _, v in pairs(State.AllowedFuseOres) do if v then fuseCount = fuseCount + 1 end end

        if not silent then
            Fluent:Notify({
                Title = "📂 ĐÃ TẢI CẤU HÌNH THÀNH CÔNG!",
                Content = string.format("Đã nạp %d quặng mua, %d quặng nung & toàn bộ cài đặt!", buyCount, fuseCount),
                Duration = 4
            })
        end
    end

    function ConfigManager.reset()
        table.clear(State.WantedBuyOres)
        for _, o in ipairs(defaultBuy) do State.WantedBuyOres[o] = true end
        table.clear(State.AllowedFuseOres)
        for _, o in ipairs(defaultFuse) do State.AllowedFuseOres[o] = true end

        if refreshBuyVisuals then refreshBuyVisuals() end
        if refreshFuseVisuals then refreshFuseVisuals() end

        Fluent:Notify({
            Title = "🔄 ĐÃ ĐẶT LẠI MẶC ĐỊNH",
            Content = "Đã khôi phục danh sách quặng về mặc định chuẩn!",
            Duration = 3
        })
    end
end


--------------------------------------------------------------------------------
-- MODULE: UI.lua
--------------------------------------------------------------------------------
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

    end

    -- 4. KHỞI TẠO CÁC TAB
    local Tabs = {
        Farm = Window:AddTab({ Title = "⚡ Pro Farm", Icon = "zap" }),
        RollBuy = Window:AddTab({ Title = "🎲 Roll & Mua Quặng", Icon = "gem" }),
        Fuser = Window:AddTab({ Title = "🔥 Smart Fuser", Icon = "flame" }),
        Teleport = Window:AddTab({ Title = "📍 Teleports", Icon = "map-pin" }),
        Player = Window:AddTab({ Title = "🏃 Nhân Vật", Icon = "user" }),
        Settings = Window:AddTab({ Title = "⚙️ Cài Đặt", Icon = "settings" })
    }

    local Options = Fluent.Options

    -- TAB 1: PRO FARM
    Tabs.Farm:AddParagraph({
        Title = "👑 CHẾ ĐỘ PRO FARM TỰ ĐỘNG KHÉP KÍN",
        Content = "Apply Gems -> Giữ Auto Roll & Mua đúng quặng đã chọn trên 6 bục -> Smart Fuser -> Lò nung & Bán tiền mượt mà!"
    })

    local ToggleProFarm = Tabs.Farm:AddToggle("ToggleProFarm", {
        Title = "🚀 BẬT PRO FARM TOÀN DIỆN (FULL AUTOMATION)",
        Default = false
    })

    ToggleProFarm:OnChanged(function()
        State.ProFarmLoop = Options.ToggleProFarm.Value
        if State.ProFarmLoop then
            task.spawn(function()
                task.wait(0.2)
                AutoRoll.triggerGameAutoRoll(false)
            end)

            task.spawn(function()
                while State.ProFarmLoop do
                    if State.AutoApplyGems and (tick() - (State.LastGemsApplied or 0) >= 15) then
                        State.LastGemsApplied = tick()
                        ShowcaseBuff.applyGems(false)
                    end

                    if State.AutoActivateBuff and (tick() - State.LastBuffActivated > 15) then
                        State.LastBuffActivated = tick()
                        ShowcaseBuff.activateBuff(false)
                    end

                    if State.AutoBuyTargetOres then
                        AutoRoll.checkAndBuyMatchingPedestals()
                    end
                    task.wait(0.2)

                    if State.SmartFuser and (tick() - (State.LastFuserRun or 0) >= 7) then
                        State.LastFuserRun = tick()
                        SmartFuser.run()
                    end
                    task.wait(0.2)

                    if State.AutoMoneyPipeline and (tick() - State.LastMoneyPipelineTime >= State.MoneyPipelineInterval) then
                        State.LastMoneyPipelineTime = tick()
                        MoneyPipeline.run()
                    end

                    task.wait(0.4)
                end
            end)
        end
    end)

    Tabs.Farm:AddParagraph({
        Title = "⏱️ CÀI ĐẶT DELAY BÁN QUẶNG:",
        Content = "Tùy chỉnh khoảng thời gian giữa các chu kỳ bán để nhân vật hoạt động mượt mà."
    })

    Tabs.Farm:AddToggle("ToggleAutoMoney", {
        Title = "Tự Động Bán Kiếm Tiền (CrateMaker -> Furnace -> Sell)",
        Default = true
    }):OnChanged(function() State.AutoMoneyPipeline = Options.ToggleAutoMoney.Value end)

    Tabs.Farm:AddSlider("SliderMoneyInterval", {
        Title = "⏱️ Giãn Cách Chu Kỳ Bán (Giây)",
        Default = 12,
        Min = 5,
        Max = 60,
        Rounding = 0,
        Callback = function(val) State.MoneyPipelineInterval = val end
    })

    Tabs.Farm:AddSlider("SliderMoneyStepDelay", {
        Title = "⏳ Độ Trễ Từng Bước Bán (Giây)",
        Default = 0.4,
        Min = 0.25,
        Max = 1.0,
        Rounding = 2,
        Callback = function(val) State.MoneyStepDelay = val end
    })

    Tabs.Farm:AddToggle("ToggleGems", {
        Title = "Tự Động Sử Dụng Apply Gems",
        Default = true
    }):OnChanged(function() State.AutoApplyGems = Options.ToggleGems.Value end)

    Tabs.Farm:AddToggle("ToggleBuff1H", {
        Title = "Tự Động Duy Trì Activate Ore Buff (Mỗi 1 Tiếng)",
        Default = true
    }):OnChanged(function() State.AutoActivateBuff = Options.ToggleBuff1H.Value end)

    Tabs.Farm:AddButton({
        Title = "💰 Chạy Ngay Quy Trình Tiền (Lấy Mỏ -> Nung Lò -> Bán)",
        Callback = function()
            local ok, msg = MoneyPipeline.run()
            Fluent:Notify({ Title = "Quy Trình Tiền", Content = msg or "Đã thực hiện xong một vòng kiếm tiền!", Duration = 4 })
        end
    })

    Tabs.Farm:AddButton({
        Title = "🔥 Chạy Ngay Smart Fuser (Cầm Quặng & Nạp Node)",
        Callback = function()
            local ok, msg = SmartFuser.run()
            Fluent:Notify({ Title = "Smart Fuser", Content = msg or "Đã nạp quặng cho Fuser!", Duration = 4 })
        end
    })

    Tabs.Farm:AddButton({
        Title = "⭐ Kiểm Tra / Đặt Lại Quặng Buff Showcase",
        Callback = function()
            local ok, msg = ShowcaseBuff.activateBuff(false)
            Fluent:Notify({ Title = "Buff Showcase", Content = msg, Duration = 4 })
        end
    })

    -- TAB 2: ROLL & MUA QUẶNG
    Tabs.RollBuy:AddParagraph({
        Title = "🎲 CƠ CHẾ AUTO ROLL & QUÉT MUA QUẶNG TỰ ĐỘNG 100%",
        Content = "• TỰ ĐỘNG HOÀN TOÀN: Khi bật toggle, script sẽ tự động kích hoạt Auto Roll của game và soi 6 bục.\n• KHÔNG CẦN BẬT TAY SAU KHI MUA: Mua quặng xong, script tự động kích hoạt lại Auto Roll của game ngay lập tức, AFK 24/7 không lo bị ngắt!"
    })

    Tabs.RollBuy:AddToggle("ToggleAutoRollBuy", {
        Title = "🚀 BẬT QUÉT & TỰ ĐỘNG MUA QUẶNG (THEO DANH SÁCH)",
        Default = false
    }):OnChanged(function()
        State.AutoRollBuyEnabled = Options.ToggleAutoRollBuy.Value
        if State.AutoRollBuyEnabled then
            task.spawn(function()
                task.wait(0.2)
                if State.AutoReRollAfterBuy then
                    AutoRoll.triggerGameAutoRoll(false)
                end

                while State.AutoRollBuyEnabled do
                    AutoRoll.checkAndBuyMatchingPedestals()
                    task.wait(State.RollScanDelay or 0.5)
                end
            end)
        end
    end)


    Tabs.RollBuy:AddToggle("ToggleAutoReRoll", {
        Title = "🔄 Tự Động Kích Hoạt Lại Auto Roll Sau Khi Mua",
        Default = true
    }):OnChanged(function() State.AutoReRollAfterBuy = Options.ToggleAutoReRoll.Value end)

    Tabs.RollBuy:AddSlider("SliderRollScanDelay", {
        Title = "⏱️ Tần Suất Quét Bục Roll (Giây)",
        Default = 0.5,
        Min = 0.2,
        Max = 3.0,
        Rounding = 1,
        Callback = function(val) State.RollScanDelay = val end
    })

    Tabs.RollBuy:AddToggle("ToggleBuyAll", {
        Title = "Mua Tất Cả Quặng (Không Cần Chọn Lọc)",
        Default = false
    }):OnChanged(function() State.BuyAllPedestals = Options.ToggleBuyAll.Value end)

    Tabs.RollBuy:AddButton({
        Title = "🎲 Bấm Bật / Tắt Auto Roll Của Game (1-Click)",
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

    Tabs.RollBuy:AddButton({
        Title = "💾 Lưu Danh Sách Quặng Mua & Cài Đặt (Save Config)",
        Callback = function() ConfigManager.save(false) end
    })

    -- TAB 3: SMART FUSER
    local refreshFuseSelectorVisuals = buildIntegratedOreSelector(
        Tabs.Fuser,
        "🔥 Bảng Chọn Quặng Cho Phép Nung Trong Fuser",
        "Gõ tên để tìm kiếm, bấm chọn để đánh dấu [✓]. Chỉ những quặng có dấu [✓] mới bị đem nung. Quặng xịn của bạn được bảo vệ 100%!",
        State.AllowedFuseOres,
        "fuse"
    )

    Tabs.Fuser:AddButton({
        Title = "🔥 Cầm Quặng & Nạp Ngay Vào Các Node Trống",
        Callback = function()
            local ok, msg = SmartFuser.run()
            Fluent:Notify({ Title = "Smart Fuser", Content = msg or "Đã nạp quặng vào Fuser!", Duration = 4 })
        end
    })

    Tabs.Fuser:AddButton({
        Title = "💾 Lưu Danh Sách Quặng Nung & Cài Đặt (Save Config)",
        Callback = function() ConfigManager.save(false) end
    })

    -- TAB 4: TELEPORTS
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

    -- TAB 6: SETTINGS
    Tabs.Settings:AddParagraph({
        Title = "💾 HỆ THỐNG LƯU / TẢI CẤU HÌNH (JSON FILE)",
        Content = "Lưu lại toàn bộ 81 loại quặng bạn đã chọn mua [✓], quặng nung [✓] và mọi thanh trượt/toggle."
    })

    Tabs.Settings:AddButton({
        Title = "💾 LƯU CẤU HÌNH NGAY BÂY GIỜ (QUẶNG & CÀI ĐẶT)",
        Callback = function() ConfigManager.save(false) end
    })

    Tabs.Settings:AddButton({
        Title = "📂 TẢI LẠI CẤU HÌNH ĐÃ LƯU (LOAD CONFIG)",
        Callback = function() ConfigManager.load(false) end
    })

    Tabs.Settings:AddButton({
        Title = "🔄 KHÔI PHỤC CẤU HÌNH MẶC ĐỊNH (RESET)",
        Callback = function() ConfigManager.reset() end
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
        Content = "Đã tối ưu Modular: Tự mở bảng, bấm START & Tự đóng bảng 100% rảnh tay!",
        Duration = 5
    })

    task.spawn(function()
        task.wait(0.6)
        if isfile and isfile("SellOres_UserConfig.json") then
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


--------------------------------------------------------------------------------
-- BOOTSTRAP INITIALIZATION
--------------------------------------------------------------------------------
local deps = {
    Fluent = Fluent,
    SaveManager = SaveManager,
    InterfaceManager = InterfaceManager,
    State = State,
    defaultBuy = defaultBuy,
    defaultFuse = defaultFuse,
    OresData = OresData,
    Utils = Utils,
    AutoRoll = AutoRoll,
    SmartFuser = SmartFuser,
    MoneyPipeline = MoneyPipeline,
    ShowcaseBuff = ShowcaseBuff,
    ConfigManager = ConfigManager
}

AutoRoll.init(deps)
SmartFuser.init(deps)
MoneyPipeline.init(deps)
ShowcaseBuff.init(deps)
ConfigManager.init(deps)
UI.init(deps)
