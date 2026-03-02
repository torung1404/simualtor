--[[
	UpgradesConfig.lua
	All upgrade definitions for the Anime Simulator.
	Cost formula: baseCost * (costGrowth ^ level)
]]

local UpgradesConfig = {
	-- Arc 1: Damage upgrades
	{ upgradeId = "dmg_1", name = "Sharpen Blade",     category = "damage",  maxLevel = 50,  baseCost = 10,    costGrowth = 1.15, effectPerLevel = 2,    description = "Increases base damage by 2 per level" },
	{ upgradeId = "dmg_2", name = "Power Strike",      category = "damage",  maxLevel = 40,  baseCost = 50,    costGrowth = 1.15, effectPerLevel = 5,    description = "Increases base damage by 5 per level" },
	{ upgradeId = "dmg_3", name = "Shadow Edge",       category = "damage",  maxLevel = 30,  baseCost = 200,   costGrowth = 1.16, effectPerLevel = 12,   description = "Increases base damage by 12 per level" },

	-- Arc 1: Income upgrades
	{ upgradeId = "income_1", name = "Better Contract",   category = "income",  maxLevel = 30,  baseCost = 15,    costGrowth = 1.14, effectPerLevel = 1,    description = "Increases job income by 1 per level" },
	{ upgradeId = "income_2", name = "Haggle",            category = "income",  maxLevel = 25,  baseCost = 80,    costGrowth = 1.14, effectPerLevel = 3,    description = "Increases job income by 3 per level" },
	{ upgradeId = "income_3", name = "Trade Mastery",     category = "income",  maxLevel = 20,  baseCost = 300,   costGrowth = 1.15, effectPerLevel = 7,    description = "Increases job income by 7 per level" },

	-- Arc 1: Crit upgrades
	{ upgradeId = "crit_1", name = "Keen Eye",          category = "crit",    maxLevel = 25,  baseCost = 20,    costGrowth = 1.16, effectPerLevel = 0.01, description = "Increases crit chance by 1% per level" },
	{ upgradeId = "crit_2", name = "Precision",         category = "crit",    maxLevel = 20,  baseCost = 100,   costGrowth = 1.16, effectPerLevel = 0.02, description = "Increases crit chance by 2% per level" },
	{ upgradeId = "crit_3", name = "Lethal Focus",      category = "crit",    maxLevel = 15,  baseCost = 400,   costGrowth = 1.17, effectPerLevel = 0.03, description = "Increases crit chance by 3% per level" },

	-- Arc 1: Drop rate upgrades
	{ upgradeId = "drop_1", name = "Lucky Charm",       category = "dropRate", maxLevel = 25, baseCost = 25,    costGrowth = 1.15, effectPerLevel = 0.005, description = "Increases drop rate by 0.5% per level" },
	{ upgradeId = "drop_2", name = "Treasure Sense",    category = "dropRate", maxLevel = 20, baseCost = 120,   costGrowth = 1.15, effectPerLevel = 0.01,  description = "Increases drop rate by 1% per level" },
	{ upgradeId = "drop_3", name = "Relic Magnetism",   category = "dropRate", maxLevel = 15, baseCost = 500,   costGrowth = 1.16, effectPerLevel = 0.015, description = "Increases drop rate by 1.5% per level" },

	-- Arc 1: Speed upgrades
	{ upgradeId = "speed_1", name = "Quick Strike",     category = "speed",   maxLevel = 40,  baseCost = 12,    costGrowth = 1.14, effectPerLevel = 0.02, description = "Reduces fight time by 2% per level" },
	{ upgradeId = "speed_2", name = "Flurry",           category = "speed",   maxLevel = 30,  baseCost = 60,    costGrowth = 1.14, effectPerLevel = 0.03, description = "Reduces fight time by 3% per level" },

	-- Arc 1: QoL upgrades
	{ upgradeId = "qol_autoclaim_1", name = "Auto Collector",  category = "qol", maxLevel = 5,  baseCost = 500,   costGrowth = 1.50, effectPerLevel = 1, description = "Auto-claims job rewards every N ticks" },

	-- Arc 2: Damage upgrades
	{ upgradeId = "dmg_4", name = "Gale Slash",         category = "damage",  maxLevel = 50,  baseCost = 800,   costGrowth = 1.15, effectPerLevel = 20,   description = "Increases base damage by 20 per level" },
	{ upgradeId = "dmg_5", name = "Storm Fury",         category = "damage",  maxLevel = 40,  baseCost = 3000,  costGrowth = 1.15, effectPerLevel = 50,   description = "Increases base damage by 50 per level" },
	{ upgradeId = "dmg_6", name = "Thunder Rend",       category = "damage",  maxLevel = 30,  baseCost = 10000, costGrowth = 1.16, effectPerLevel = 120,  description = "Increases base damage by 120 per level" },

	-- Arc 2: Income upgrades
	{ upgradeId = "income_4", name = "Sky Merchant",      category = "income",  maxLevel = 30,  baseCost = 1000,  costGrowth = 1.14, effectPerLevel = 10,   description = "Increases job income by 10 per level" },
	{ upgradeId = "income_5", name = "Wind Barter",       category = "income",  maxLevel = 25,  baseCost = 4000,  costGrowth = 1.14, effectPerLevel = 25,   description = "Increases job income by 25 per level" },
	{ upgradeId = "income_6", name = "Cloudtop Deals",    category = "income",  maxLevel = 20,  baseCost = 15000, costGrowth = 1.15, effectPerLevel = 60,   description = "Increases job income by 60 per level" },

	-- Arc 2: Crit, Drop, Speed
	{ upgradeId = "crit_4",  name = "Hawk Eye",          category = "crit",    maxLevel = 25,  baseCost = 1200,  costGrowth = 1.16, effectPerLevel = 0.01, description = "Increases crit chance by 1% per level" },
	{ upgradeId = "crit_5",  name = "Storm Precision",   category = "crit",    maxLevel = 20,  baseCost = 5000,  costGrowth = 1.16, effectPerLevel = 0.02, description = "Increases crit chance by 2% per level" },
	{ upgradeId = "crit_6",  name = "Lightning Reflexes",category = "crit",    maxLevel = 15,  baseCost = 20000, costGrowth = 1.17, effectPerLevel = 0.03, description = "Increases crit chance by 3% per level" },
	{ upgradeId = "drop_4",  name = "Skyfall Luck",      category = "dropRate",maxLevel = 25,  baseCost = 1500,  costGrowth = 1.15, effectPerLevel = 0.005,description = "Increases drop rate by 0.5% per level" },
	{ upgradeId = "drop_5",  name = "Cloud Loot",        category = "dropRate",maxLevel = 20,  baseCost = 6000,  costGrowth = 1.15, effectPerLevel = 0.01, description = "Increases drop rate by 1% per level" },
	{ upgradeId = "drop_6",  name = "Tempest Fortune",   category = "dropRate",maxLevel = 15,  baseCost = 25000, costGrowth = 1.16, effectPerLevel = 0.015,description = "Increases drop rate by 1.5% per level" },
	{ upgradeId = "speed_3", name = "Zephyr",            category = "speed",   maxLevel = 40,  baseCost = 900,   costGrowth = 1.14, effectPerLevel = 0.02, description = "Reduces fight time by 2% per level" },
	{ upgradeId = "speed_4", name = "Cyclone Rush",      category = "speed",   maxLevel = 30,  baseCost = 3500,  costGrowth = 1.14, effectPerLevel = 0.03, description = "Reduces fight time by 3% per level" },
	{ upgradeId = "qol_autoclaim_2", name = "Auto Collector II", category = "qol", maxLevel = 5, baseCost = 25000, costGrowth = 1.50, effectPerLevel = 1, description = "Enhanced auto-claim for Sky Realm jobs" },

	-- Arc 3: Damage upgrades
	{ upgradeId = "dmg_7", name = "Piston Punch",       category = "damage",  maxLevel = 50,  baseCost = 50000,  costGrowth = 1.15, effectPerLevel = 200,  description = "Increases base damage by 200 per level" },
	{ upgradeId = "dmg_8", name = "Forge Hammer",       category = "damage",  maxLevel = 40,  baseCost = 200000, costGrowth = 1.15, effectPerLevel = 500,  description = "Increases base damage by 500 per level" },
	{ upgradeId = "dmg_9", name = "Engine Overload",    category = "damage",  maxLevel = 30,  baseCost = 800000, costGrowth = 1.16, effectPerLevel = 1200, description = "Increases base damage by 1200 per level" },

	-- Arc 3: Income upgrades
	{ upgradeId = "income_7", name = "Forge Profits",     category = "income",  maxLevel = 30,  baseCost = 60000,  costGrowth = 1.14, effectPerLevel = 80,   description = "Increases job income by 80 per level" },
	{ upgradeId = "income_8", name = "Cog Commerce",      category = "income",  maxLevel = 25,  baseCost = 250000, costGrowth = 1.14, effectPerLevel = 200,  description = "Increases job income by 200 per level" },
	{ upgradeId = "income_9", name = "Industry Baron",    category = "income",  maxLevel = 20,  baseCost = 900000, costGrowth = 1.15, effectPerLevel = 500,  description = "Increases job income by 500 per level" },

	-- Arc 3: Crit, Drop, Speed
	{ upgradeId = "crit_7",  name = "Gear Sync",         category = "crit",    maxLevel = 25,  baseCost = 70000,  costGrowth = 1.16, effectPerLevel = 0.01, description = "Increases crit chance by 1% per level" },
	{ upgradeId = "crit_8",  name = "Overclock",         category = "crit",    maxLevel = 20,  baseCost = 300000, costGrowth = 1.16, effectPerLevel = 0.02, description = "Increases crit chance by 2% per level" },
	{ upgradeId = "crit_9",  name = "Perfect Calibration",category = "crit",   maxLevel = 15,  baseCost = 1200000,costGrowth = 1.17, effectPerLevel = 0.03, description = "Increases crit chance by 3% per level" },
	{ upgradeId = "drop_7",  name = "Salvage Sense",     category = "dropRate",maxLevel = 25,  baseCost = 80000,  costGrowth = 1.15, effectPerLevel = 0.005,description = "Increases drop rate by 0.5% per level" },
	{ upgradeId = "drop_8",  name = "Scrap Magnet",      category = "dropRate",maxLevel = 20,  baseCost = 350000, costGrowth = 1.15, effectPerLevel = 0.01, description = "Increases drop rate by 1% per level" },
	{ upgradeId = "drop_9",  name = "Core Attractor",    category = "dropRate",maxLevel = 15,  baseCost = 1500000,costGrowth = 1.16, effectPerLevel = 0.015,description = "Increases drop rate by 1.5% per level" },
	{ upgradeId = "speed_5", name = "Turbo",             category = "speed",   maxLevel = 40,  baseCost = 55000,  costGrowth = 1.14, effectPerLevel = 0.02, description = "Reduces fight time by 2% per level" },
	{ upgradeId = "speed_6", name = "Overdrive",         category = "speed",   maxLevel = 30,  baseCost = 220000, costGrowth = 1.14, effectPerLevel = 0.03, description = "Reduces fight time by 3% per level" },
	{ upgradeId = "qol_autofight_1", name = "Auto Fighter",  category = "qol", maxLevel = 5, baseCost = 500000, costGrowth = 1.50, effectPerLevel = 1, description = "Automatically fights current enemy" },
}

-- Build lookup by upgradeId
local UpgradeById = {}
for _, upgrade in ipairs(UpgradesConfig) do
	UpgradeById[upgrade.upgradeId] = upgrade
end

return {
	List = UpgradesConfig,
	ById = UpgradeById,
}
