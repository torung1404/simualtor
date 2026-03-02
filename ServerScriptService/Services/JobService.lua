--[[
	JobService.lua
	Handles job ticking, claiming, and cap enforcement.
	A single server loop ticks all active jobs (not per-player timers).
]]

local JobsConfig = require(game.ReplicatedStorage.Shared.Configs.JobsConfig)

local JobService = {}
JobService.__index = JobService

--- Create a new JobService.
--- @param playerDataService PlayerDataService
--- @param economyService EconomyService
--- @param stateMachine PlayerStateMachine
--- @return JobService
function JobService.new(playerDataService, economyService, stateMachine)
	local self = setmetatable({}, JobService)
	self._playerData = playerDataService
	self._economy = economyService
	self._stateMachine = stateMachine
	self._tickLoopRunning = false
	self._claimTimestamps = {} -- userId -> { timestamps for anti-macro }
	return self
end

--- Start a job for a player.
--- @param userId number
--- @param jobId string
--- @return table { ok, data?, error? }
function JobService:startJob(userId, jobId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	-- Validate job exists
	local jobConfig = JobsConfig.ById[jobId]
	if not jobConfig then
		return { ok = false, error = "Unknown job: " .. tostring(jobId) }
	end

	-- Check state
	local allowed, reason = self._stateMachine:isActionAllowed(userId, "StartJob")
	if not allowed then
		return { ok = false, error = reason }
	end

	-- Check if already running a job
	if data.jobs.activeJobId ~= nil then
		return { ok = false, error = "Already running a job. Cancel it first." }
	end

	-- Check unlock requirement
	local req = jobConfig.unlockRequirement
	if req.type == "power" then
		-- Would need combat service for power calc; for now check highest power
		if data.stats.highestPower < req.value then
			return { ok = false, error = "Insufficient power to unlock this job" }
		end
	elseif req.type == "tutorialStep" then
		if data.progress.tutorialStep < req.value and not data.progress.tutorialComplete then
			return { ok = false, error = "Complete more tutorial steps first" }
		end
	end

	-- Start the job
	local now = os.time()
	data.jobs.activeJobId = jobId
	data.jobs.jobStartedAt = now
	data.jobs.lastClaimAt = now

	-- Transition state
	self._stateMachine:transition(userId, "InJob")

	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = {
			jobId = jobId,
			jobName = jobConfig.name,
			tickTimeSeconds = jobConfig.tickTimeSeconds,
			rewardPerTick = jobConfig.rewardPerTick,
			startedAt = now,
		},
	}
end

--- Claim accumulated job rewards.
--- @param userId number
--- @return table { ok, data?, error? }
function JobService:claimReward(userId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	if data.jobs.activeJobId == nil then
		return { ok = false, error = "No active job" }
	end

	local jobConfig = JobsConfig.ById[data.jobs.activeJobId]
	if not jobConfig then
		return { ok = false, error = "Invalid job configuration" }
	end

	local now = os.time()
	local elapsed = now - data.jobs.lastClaimAt
	local ticks = math.floor(elapsed / jobConfig.tickTimeSeconds)

	if ticks <= 0 then
		return { ok = false, error = "No rewards to claim yet" }
	end

	-- Cap enforcement: max ticks per minute
	local minutesElapsed = math.max(elapsed / 60, 1)
	local maxTicks = math.floor(jobConfig.capPerMinute * minutesElapsed)
	ticks = math.min(ticks, maxTicks)

	-- Anti-macro: track claim timestamps
	self:_trackClaimTiming(userId, now)

	-- Calculate reward with income bonus
	local UpgradesConfig = require(game.ReplicatedStorage.Shared.Configs.UpgradesConfig)
	local incomeBonus = self._economy:getIncomeBonus(userId, UpgradesConfig.ById)
	local totalReward = self._economy:calculateJobReward(jobConfig.rewardPerTick, ticks, incomeBonus)

	-- Apply reward
	self._economy:addCoin(userId, totalReward, "job:" .. data.jobs.activeJobId)

	-- Update claim timestamp
	data.jobs.lastClaimAt = now
	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = {
			ticks = ticks,
			reward = totalReward,
			jobName = jobConfig.name,
		},
	}
end

--- Cancel the current job.
--- @param userId number
--- @return table { ok, data?, error? }
function JobService:cancelJob(userId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	if data.jobs.activeJobId == nil then
		return { ok = false, error = "No active job to cancel" }
	end

	local jobName = "Unknown"
	local jobConfig = JobsConfig.ById[data.jobs.activeJobId]
	if jobConfig then
		jobName = jobConfig.name
	end

	data.jobs.activeJobId = nil
	data.jobs.jobStartedAt = 0
	data.jobs.lastClaimAt = 0

	-- Return to menu state
	self._stateMachine:transition(userId, "InMenu")

	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = { cancelled = jobName },
	}
end

--- Get the current job status for a player.
--- @param userId number
--- @return table? { jobId, jobName, ticks, pendingReward, elapsed }
function JobService:getJobStatus(userId)
	local data = self._playerData:getData(userId)
	if not data or data.jobs.activeJobId == nil then
		return nil
	end

	local jobConfig = JobsConfig.ById[data.jobs.activeJobId]
	if not jobConfig then return nil end

	local now = os.time()
	local elapsed = now - data.jobs.lastClaimAt
	local ticks = math.floor(elapsed / jobConfig.tickTimeSeconds)

	return {
		jobId = data.jobs.activeJobId,
		jobName = jobConfig.name,
		ticks = ticks,
		pendingReward = jobConfig.rewardPerTick * ticks,
		elapsed = elapsed,
		tickTimeSeconds = jobConfig.tickTimeSeconds,
	}
end

--- Track claim timing for anti-macro detection.
--- If claim timing is too uniform over 20+ claims, flag the player.
--- @param userId number
--- @param timestamp number
function JobService:_trackClaimTiming(userId, timestamp)
	if not self._claimTimestamps[userId] then
		self._claimTimestamps[userId] = {}
	end

	local timestamps = self._claimTimestamps[userId]
	timestamps[#timestamps + 1] = timestamp

	-- Keep only last 25 timestamps
	if #timestamps > 25 then
		local trimmed = {}
		for i = #timestamps - 24, #timestamps do
			trimmed[#trimmed + 1] = timestamps[i]
		end
		self._claimTimestamps[userId] = trimmed
		timestamps = trimmed
	end

	-- Check for uniformity if we have 20+ timestamps
	if #timestamps >= 20 then
		local intervals = {}
		for i = 2, #timestamps do
			intervals[#intervals + 1] = timestamps[i] - timestamps[i - 1]
		end

		-- Calculate standard deviation of intervals
		local sum = 0
		for _, v in ipairs(intervals) do sum = sum + v end
		local mean = sum / #intervals

		local varianceSum = 0
		for _, v in ipairs(intervals) do
			varianceSum = varianceSum + (v - mean) ^ 2
		end
		local stdDev = math.sqrt(varianceSum / #intervals)

		-- If standard deviation is very low (< 0.5 seconds), flag as suspicious
		if stdDev < 0.5 and mean > 0 then
			warn("[JobService] Anti-macro flag: userId " .. userId .. " has uniform claim timing (stdDev=" .. stdDev .. ")")
		end
	end
end

--- Clean up tracking for a player.
--- @param userId number
function JobService:removePlayer(userId)
	self._claimTimestamps[userId] = nil
end

return JobService
