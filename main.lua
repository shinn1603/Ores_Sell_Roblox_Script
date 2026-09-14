--[[
    ========================================================================
    SELL ORES HUB - MODULAR LOADER
    Phiên bản: v7.8 Ultimate PRO (Clean Modular Architecture)
    GitHub Repo: https://github.com/shinn1603/Ores_Sell_Roblox_Script
    ========================================================================
]]

local REPO_URL = "https://raw.githubusercontent.com/shinn1603/Ores_Sell_Roblox_Script/main/src/"

-- Hàm nạp module thông minh: Hỗ trợ nạp trực tiếp từ Local Workspace (Dev) hoặc GitHub (Live)
local function loadModule(moduleName)
    local sourceCode = nil

    -- 1. Ưu tiên nạp từ file local nếu có (dành cho người dùng lưu script trong thư mục executor)
    local localPaths = {
        "ORES_Script/src/" .. moduleName .. ".lua",
        "src/" .. moduleName .. ".lua"
    }
    if isfile and readfile then
        for _, path in ipairs(localPaths) do
            if isfile(path) then
                local success, fileData = pcall(readfile, path)
                if success and fileData and fileData ~= "" then
                    sourceCode = fileData
                    break
                end
            end
        end
    end

    -- 2. Tải trực tiếp từ GitHub Raw nếu không có file local
    if not sourceCode then
        local url = REPO_URL .. moduleName .. ".lua"
        local success, response = pcall(game.HttpGet, game, url)
        if not success or not response or response == "" then
            error("[Sell Ores] Lỗi tải module '" .. moduleName .. "' từ GitHub: " .. tostring(response))
        end
        sourceCode = response
    end

    -- 3. Biên dịch và thực thi module
    local compiledFn, compileErr = loadstring(sourceCode)
    if not compiledFn then
        error("[Sell Ores] Lỗi cú pháp trong module '" .. moduleName .. "': " .. tostring(compileErr))
    end

    return compiledFn()
end

-- Tải thư viện Fluent UI & Addons
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- Nạp các module theo thứ tự phụ thuộc (Dependency Injection)
local OresData = loadModule("OresData")

local StateModule = loadModule("State")
local State = StateModule.State
local defaultBuy = StateModule.defaultBuy
local defaultFuse = StateModule.defaultFuse

local Utils = loadModule("Utils")

local ShowcaseBuff = loadModule("ShowcaseBuff")
ShowcaseBuff.init({
    Utils = Utils
})

local MoneyPipeline = loadModule("MoneyPipeline")
MoneyPipeline.init({
    Utils = Utils,
    State = State
})

local SmartFuser = loadModule("SmartFuser")
SmartFuser.init({
    Utils = Utils,
    State = State
})

local AutoRoll = loadModule("AutoRoll")
AutoRoll.init({
    Utils = Utils,
    State = State,
    OresData = OresData,
    Fluent = Fluent
})

local ConfigManager = loadModule("ConfigManager")
ConfigManager.init({
    State = State,
    defaultBuy = defaultBuy,
    defaultFuse = defaultFuse,
    Fluent = Fluent
})

local UI = loadModule("UI")
UI.init({
    Fluent = Fluent,
    SaveManager = SaveManager,
    InterfaceManager = InterfaceManager,
    State = State,
    OresData = OresData,
    Utils = Utils,
    AutoRoll = AutoRoll,
    SmartFuser = SmartFuser,
    MoneyPipeline = MoneyPipeline,
    ShowcaseBuff = ShowcaseBuff,
    ConfigManager = ConfigManager
})
