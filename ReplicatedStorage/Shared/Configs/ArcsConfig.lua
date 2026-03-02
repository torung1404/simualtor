--[[
	ArcsConfig.lua
	All arc definitions for the Anime Simulator.
	Adding a new Arc means adding a table entry here -- no system changes needed.
]]

local ArcsConfig = {
	{
		arcId = "arc_1",
		name = "Shattered Gate",
		recommendedPower = 0,
		rewardMultiplier = 1.0,
		unlockRequirement = { type = "none" },
		enemies = { "arc1_e1", "arc1_e2", "arc1_e3", "arc1_e4", "arc1_e5" },
		bossId = "arc1_boss",
		upgrades = {
			"dmg_1", "income_1", "crit_1", "drop_1", "speed_1",
			"dmg_2", "income_2", "crit_2", "drop_2", "speed_2",
			"qol_autoclaim_1", "dmg_3", "income_3", "crit_3", "drop_3",
		},
		jobs = { "delivery", "patrol", "scavenge" },
		relics = { "relic_arc1_shard", "relic_arc1_ember", "relic_arc1_crest" },
		storyDialogues = { "d_arc1_intro", "d_arc1_mid", "d_arc1_boss" },
	},
	{
		arcId = "arc_2",
		name = "Sky Realm",
		recommendedPower = 500,
		rewardMultiplier = 2.0,
		unlockRequirement = { type = "power", value = 500 },
		enemies = { "arc2_e1", "arc2_e2", "arc2_e3", "arc2_e4", "arc2_e5" },
		bossId = "arc2_boss",
		upgrades = {
			"dmg_4", "income_4", "crit_4", "drop_4", "speed_3",
			"dmg_5", "income_5", "crit_5", "drop_5", "speed_4",
			"qol_autoclaim_2", "dmg_6", "income_6", "crit_6", "drop_6",
		},
		jobs = { "sky_courier", "cloud_mining", "wind_patrol" },
		relics = { "relic_arc2_feather", "relic_arc2_prism", "relic_arc2_wing" },
		storyDialogues = { "d_arc2_intro", "d_arc2_mid", "d_arc2_boss" },
	},
	{
		arcId = "arc_3",
		name = "Steampunk Forge",
		recommendedPower = 2000,
		rewardMultiplier = 3.5,
		unlockRequirement = { type = "power", value = 2000 },
		enemies = { "arc3_e1", "arc3_e2", "arc3_e3", "arc3_e4", "arc3_e5" },
		bossId = "arc3_boss",
		upgrades = {
			"dmg_7", "income_7", "crit_7", "drop_7", "speed_5",
			"dmg_8", "income_8", "crit_8", "drop_8", "speed_6",
			"qol_autofight_1", "dmg_9", "income_9", "crit_9", "drop_9",
		},
		jobs = { "forge_smith", "gear_salvage", "boiler_watch" },
		relics = { "relic_arc3_gear", "relic_arc3_piston", "relic_arc3_core" },
		storyDialogues = { "d_arc3_intro", "d_arc3_mid", "d_arc3_boss" },
	},
}

-- Build lookup table by arcId for O(1) access
local ArcById = {}
for _, arc in ipairs(ArcsConfig) do
	ArcById[arc.arcId] = arc
end

return {
	List = ArcsConfig,
	ById = ArcById,
}
