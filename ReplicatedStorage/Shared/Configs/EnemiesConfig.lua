--[[
	EnemiesConfig.lua
	All enemy stat tables for the Anime Simulator.
	Each enemy is referenced by enemyId from ArcsConfig.
]]

local EnemiesConfig = {
	-- Arc 1: Shattered Gate
	{
		enemyId = "arc1_e1",
		name = "Shadow Wisp",
		hp = 50,
		power = 10,
		rewards = { coin = 5, xp = 2 },
		dropTable = {
			{ itemId = "shard_common", chance = 0.15 },
		},
	},
	{
		enemyId = "arc1_e2",
		name = "Void Hound",
		hp = 120,
		power = 25,
		rewards = { coin = 12, xp = 5 },
		dropTable = {
			{ itemId = "shard_common", chance = 0.20 },
			{ itemId = "fang_fragment", chance = 0.08 },
		},
	},
	{
		enemyId = "arc1_e3",
		name = "Rift Crawler",
		hp = 250,
		power = 55,
		rewards = { coin = 28, xp = 10 },
		dropTable = {
			{ itemId = "shard_common", chance = 0.25 },
			{ itemId = "fang_fragment", chance = 0.12 },
			{ itemId = "relic_arc1_shard", chance = 0.03 },
		},
	},
	{
		enemyId = "arc1_e4",
		name = "Gate Sentinel",
		hp = 500,
		power = 100,
		rewards = { coin = 55, xp = 20 },
		dropTable = {
			{ itemId = "shard_uncommon", chance = 0.15 },
			{ itemId = "relic_arc1_ember", chance = 0.04 },
		},
	},
	{
		enemyId = "arc1_e5",
		name = "Dusk Phantom",
		hp = 900,
		power = 180,
		rewards = { coin = 100, xp = 35 },
		dropTable = {
			{ itemId = "shard_uncommon", chance = 0.20 },
			{ itemId = "shard_rare", chance = 0.05 },
			{ itemId = "relic_arc1_crest", chance = 0.03 },
		},
	},
	-- Arc 1 Boss
	{
		enemyId = "arc1_boss",
		name = "Shadow Warden",
		hp = 3000,
		power = 350,
		isBoss = true,
		mechanics = { "shield_phase", "enrage_timer" },
		shieldPhaseAt = 0.5, -- triggers at 50% HP
		enrageTimerSeconds = 120,
		rewards = { coin = 500, xp = 150, gems = 5 },
		dropTable = {
			{ itemId = "shard_rare", chance = 0.30 },
			{ itemId = "shard_epic", chance = 0.08 },
			{ itemId = "relic_arc1_shard", chance = 0.15 },
			{ itemId = "relic_arc1_ember", chance = 0.10 },
			{ itemId = "relic_arc1_crest", chance = 0.10 },
		},
	},

	-- Arc 2: Sky Realm
	{
		enemyId = "arc2_e1",
		name = "Cloud Sprite",
		hp = 800,
		power = 200,
		rewards = { coin = 90, xp = 30 },
		dropTable = {
			{ itemId = "shard_uncommon", chance = 0.20 },
		},
	},
	{
		enemyId = "arc2_e2",
		name = "Storm Hawk",
		hp = 1500,
		power = 350,
		rewards = { coin = 170, xp = 55 },
		dropTable = {
			{ itemId = "shard_uncommon", chance = 0.25 },
			{ itemId = "feather_shard", chance = 0.10 },
		},
	},
	{
		enemyId = "arc2_e3",
		name = "Gale Knight",
		hp = 2800,
		power = 600,
		rewards = { coin = 320, xp = 100 },
		dropTable = {
			{ itemId = "shard_rare", chance = 0.15 },
			{ itemId = "relic_arc2_feather", chance = 0.04 },
		},
	},
	{
		enemyId = "arc2_e4",
		name = "Thunder Djinn",
		hp = 5000,
		power = 1000,
		rewards = { coin = 580, xp = 180 },
		dropTable = {
			{ itemId = "shard_rare", chance = 0.20 },
			{ itemId = "relic_arc2_prism", chance = 0.04 },
		},
	},
	{
		enemyId = "arc2_e5",
		name = "Skyshatter Golem",
		hp = 9000,
		power = 1800,
		rewards = { coin = 1050, xp = 300 },
		dropTable = {
			{ itemId = "shard_rare", chance = 0.25 },
			{ itemId = "shard_epic", chance = 0.08 },
			{ itemId = "relic_arc2_wing", chance = 0.03 },
		},
	},
	-- Arc 2 Boss
	{
		enemyId = "arc2_boss",
		name = "Tempest Sovereign",
		hp = 30000,
		power = 3500,
		isBoss = true,
		mechanics = { "dodge_phase", "enrage_timer" },
		dodgePhaseInterval = 15, -- dodges every 15 seconds
		enrageTimerSeconds = 150,
		rewards = { coin = 5000, xp = 1200, gems = 10 },
		dropTable = {
			{ itemId = "shard_epic", chance = 0.25 },
			{ itemId = "shard_legendary", chance = 0.05 },
			{ itemId = "relic_arc2_feather", chance = 0.15 },
			{ itemId = "relic_arc2_prism", chance = 0.12 },
			{ itemId = "relic_arc2_wing", chance = 0.10 },
		},
	},

	-- Arc 3: Steampunk Forge
	{
		enemyId = "arc3_e1",
		name = "Rust Automaton",
		hp = 8000,
		power = 2000,
		rewards = { coin = 900, xp = 250 },
		dropTable = {
			{ itemId = "shard_rare", chance = 0.20 },
		},
	},
	{
		enemyId = "arc3_e2",
		name = "Boiler Wraith",
		hp = 15000,
		power = 3500,
		rewards = { coin = 1700, xp = 450 },
		dropTable = {
			{ itemId = "shard_rare", chance = 0.25 },
			{ itemId = "gear_fragment", chance = 0.10 },
		},
	},
	{
		enemyId = "arc3_e3",
		name = "Cog Berserker",
		hp = 28000,
		power = 6000,
		rewards = { coin = 3200, xp = 800 },
		dropTable = {
			{ itemId = "shard_epic", chance = 0.12 },
			{ itemId = "relic_arc3_gear", chance = 0.04 },
		},
	},
	{
		enemyId = "arc3_e4",
		name = "Furnace Titan",
		hp = 50000,
		power = 10000,
		rewards = { coin = 5800, xp = 1400 },
		dropTable = {
			{ itemId = "shard_epic", chance = 0.18 },
			{ itemId = "relic_arc3_piston", chance = 0.04 },
		},
	},
	{
		enemyId = "arc3_e5",
		name = "Iron Leviathan",
		hp = 90000,
		power = 18000,
		rewards = { coin = 10500, xp = 2500 },
		dropTable = {
			{ itemId = "shard_epic", chance = 0.22 },
			{ itemId = "shard_legendary", chance = 0.06 },
			{ itemId = "relic_arc3_core", chance = 0.03 },
		},
	},
	-- Arc 3 Boss
	{
		enemyId = "arc3_boss",
		name = "The Grand Machinist",
		hp = 300000,
		power = 35000,
		isBoss = true,
		mechanics = { "shield_phase", "dodge_phase", "enrage_timer" },
		shieldPhaseAt = 0.6,
		dodgePhaseInterval = 12,
		enrageTimerSeconds = 180,
		rewards = { coin = 50000, xp = 10000, gems = 20 },
		dropTable = {
			{ itemId = "shard_legendary", chance = 0.15 },
			{ itemId = "relic_arc3_gear", chance = 0.15 },
			{ itemId = "relic_arc3_piston", chance = 0.12 },
			{ itemId = "relic_arc3_core", chance = 0.10 },
		},
	},
}

-- Build lookup table by enemyId
local EnemyById = {}
for _, enemy in ipairs(EnemiesConfig) do
	EnemyById[enemy.enemyId] = enemy
end

return {
	List = EnemiesConfig,
	ById = EnemyById,
}
