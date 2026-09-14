--[[
    MODULE: State.lua
    Mô tả: Quản lý biến trạng thái toàn hệ thống & danh sách mặc định
]]

local State = {
    -- 1. Auto Farm Tiền (Money Pipeline: CrateMaker -> Furnace -> Seller)
    AutoFarmMoney = false,
    MoneyPipelineInterval = 12,
    MoneyStepDelay = 0.4,
    LastMoneyPipelineTime = 0,

    -- 2. Auto Roll & Mua Quặng (Auto Roller + Pedestals Scan)
    AutoRollBuyEnabled = false,
    RollScanDelay = 0.5,
    AutoBuyTargetOres = true,
    BuyAllPedestals = false,
    AutoReRollAfterBuy = true,
    WantedBuyOres = {}, -- { ["Tên Quặng"] = true }

    -- 3. Smart Fuser (Tự Động Nạp Quặng & Nhận Mega Ore)
    AutoFuserLoop = false,
    FuserInterval = 8,
    LastFuserRun = 0,
    AllowedFuseOres = {}, -- { ["Tên Quặng"] = true }

    -- 4. Buffs & Gems (Apply Gems & Showcase Buff x2.75)
    AutoApplyGems = false,
    AutoActivateBuff = false,
    LastBuffActivated = 0,
    LastGemsApplied = 0,

    -- Khóa điều phối (tránh xung đột khi bật nhiều tính năng cùng lúc)
    isBusy = false,

    -- 5. Movement & AFK
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
