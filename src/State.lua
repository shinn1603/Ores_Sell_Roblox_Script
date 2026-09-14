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

State.defaultBuy = defaultBuy
State.defaultFuse = defaultFuse

-- State, defaultBuy, defaultFuse are now all in local scope for bundler
return State
