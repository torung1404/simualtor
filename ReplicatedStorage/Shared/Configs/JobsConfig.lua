--[[
	JobsConfig.lua
	All job definitions for the Anime Simulator.
	Jobs provide passive income on a server-side tick timer.
]]

local JobsConfig = {
	-- Arc 1 Jobs
	{
		jobId = "delivery",
		name = "Gate Courier",
		arcId = "arc_1",
		tickTimeSeconds = 10,
		rewardPerTick = 3,
		unlockRequirement = { type = "tutorialStep", value = 3 },
		capPerMinute = 18,
	},
	{
		jobId = "patrol",
		name = "Rift Patrol",
		arcId = "arc_1",
		tickTimeSeconds = 15,
		rewardPerTick = 6,
		unlockRequirement = { type = "power", value = 50 },
		capPerMinute = 12,
	},
	{
		jobId = "scavenge",
		name = "Shard Scavenger",
		arcId = "arc_1",
		tickTimeSeconds = 20,
		rewardPerTick = 10,
		unlockRequirement = { type = "power", value = 150 },
		capPerMinute = 9,
	},

	-- Arc 2 Jobs
	{
		jobId = "sky_courier",
		name = "Sky Courier",
		arcId = "arc_2",
		tickTimeSeconds = 10,
		rewardPerTick = 30,
		unlockRequirement = { type = "power", value = 500 },
		capPerMinute = 18,
	},
	{
		jobId = "cloud_mining",
		name = "Cloud Mining",
		arcId = "arc_2",
		tickTimeSeconds = 15,
		rewardPerTick = 55,
		unlockRequirement = { type = "power", value = 800 },
		capPerMinute = 12,
	},
	{
		jobId = "wind_patrol",
		name = "Wind Patrol",
		arcId = "arc_2",
		tickTimeSeconds = 20,
		rewardPerTick = 90,
		unlockRequirement = { type = "power", value = 1200 },
		capPerMinute = 9,
	},

	-- Arc 3 Jobs
	{
		jobId = "forge_smith",
		name = "Forge Smith",
		arcId = "arc_3",
		tickTimeSeconds = 10,
		rewardPerTick = 250,
		unlockRequirement = { type = "power", value = 2000 },
		capPerMinute = 18,
	},
	{
		jobId = "gear_salvage",
		name = "Gear Salvage",
		arcId = "arc_3",
		tickTimeSeconds = 15,
		rewardPerTick = 450,
		unlockRequirement = { type = "power", value = 3500 },
		capPerMinute = 12,
	},
	{
		jobId = "boiler_watch",
		name = "Boiler Watch",
		arcId = "arc_3",
		tickTimeSeconds = 20,
		rewardPerTick = 750,
		unlockRequirement = { type = "power", value = 6000 },
		capPerMinute = 9,
	},
}

-- Build lookup by jobId
local JobById = {}
for _, job in ipairs(JobsConfig) do
	JobById[job.jobId] = job
end

return {
	List = JobsConfig,
	ById = JobById,
}
