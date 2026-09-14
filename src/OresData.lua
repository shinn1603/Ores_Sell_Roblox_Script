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

return OresData
