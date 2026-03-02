--[[
	SeasonConfig.lua
	Current season parameters for ranked play and seasonal content.
]]

local SeasonConfig = {
	currentSeasonId = "s1",
	seasonName = "Atlas Tournament: Season 1",
	startDate = "2026-03-01",
	endDate = "2026-03-31",
	durationWeeks = 4,

	-- Ranked tiers
	tiers = {
		{ tierId = "bronze",  name = "Bronze",  minPoints = 0,    icon = "rbxassetid://0" },
		{ tierId = "silver",  name = "Silver",  minPoints = 100,  icon = "rbxassetid://0" },
		{ tierId = "gold",    name = "Gold",    minPoints = 300,  icon = "rbxassetid://0" },
		{ tierId = "diamond", name = "Diamond", minPoints = 700,  icon = "rbxassetid://0" },
		{ tierId = "mythic",  name = "Mythic",  minPoints = 1500, icon = "rbxassetid://0" },
	},

	-- Ranked entry cost
	entryTicketCost = 50, -- coin cost per ranked attempt

	-- Ranked scoring
	scoring = {
		baseClearPoints = 10,
		timeBonusPerSecondUnder = 2, -- bonus points for each second under par
		parTimeSeconds = 60,
		damageBonusMultiplier = 0.01,
		hitsTakenPenalty = 1, -- points lost per hit taken
	},

	-- Season rewards at tier thresholds
	rewards = {
		bronze  = { gems = 10, title = "Bronze Walker" },
		silver  = { gems = 25, title = "Silver Walker",  aura = "silver_glow" },
		gold    = { gems = 50, title = "Gold Walker",    aura = "gold_glow" },
		diamond = { gems = 100, title = "Diamond Walker", aura = "diamond_glow", nameColor = { r = 100, g = 200, b = 255 } },
		mythic  = { gems = 250, title = "Mythic Walker",  aura = "mythic_glow",  nameColor = { r = 255, g = 180, b = 40 } },
	},

	-- Daily quests for season progression
	dailyQuestPool = {
		{ questId = "dq_kill_10",      description = "Defeat 10 enemies",   requirement = { type = "kills", count = 10 },     rewardPoints = 5,  rewardCoin = 50 },
		{ questId = "dq_kill_boss",    description = "Defeat any Boss",     requirement = { type = "bossKill", count = 1 },    rewardPoints = 15, rewardCoin = 200 },
		{ questId = "dq_earn_500",     description = "Earn 500 coins",      requirement = { type = "coinEarned", count = 500 },rewardPoints = 8,  rewardCoin = 100 },
		{ questId = "dq_upgrade_3",    description = "Buy 3 upgrades",      requirement = { type = "upgrades", count = 3 },    rewardPoints = 6,  rewardCoin = 75 },
		{ questId = "dq_job_5",        description = "Claim 5 job rewards", requirement = { type = "jobClaims", count = 5 },   rewardPoints = 5,  rewardCoin = 60 },
		{ questId = "dq_ranked_1",     description = "Complete 1 ranked battle", requirement = { type = "ranked", count = 1 },  rewardPoints = 10, rewardCoin = 150 },
	},
	dailyQuestCount = 3, -- number of quests assigned per day

	-- Login streak rewards
	loginStreakRewards = {
		[1]  = { coin = 100 },
		[2]  = { coin = 150 },
		[3]  = { coin = 200, gems = 5 },
		[5]  = { coin = 500, gems = 10 },
		[7]  = { coin = 1000, gems = 25, title = "Dedicated Walker" },
		[14] = { coin = 2500, gems = 50 },
		[30] = { coin = 5000, gems = 100, aura = "streak_glow" },
	},

	-- Welcome back bonus (3+ days away)
	welcomeBackBonus = {
		coin = 500,
		offlineJobCapHours = 8, -- max offline accumulation
	},
}

-- Build tier lookup
local TierById = {}
for _, tier in ipairs(SeasonConfig.tiers) do
	TierById[tier.tierId] = tier
end
SeasonConfig.TierById = TierById

return SeasonConfig
