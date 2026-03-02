--[[
	JobHandler.lua
	Routes job remotes to JobService.
]]

local PayloadTypes = require(game.ReplicatedStorage.Shared.NetSchema.PayloadTypes)

local JobHandler = {}
JobHandler.__index = JobHandler

--- Create a new JobHandler.
--- @param jobService JobService
--- @param antiCheatService AntiCheatService
--- @param tutorialService TutorialService
--- @return JobHandler
function JobHandler.new(jobService, antiCheatService, tutorialService)
	local self = setmetatable({}, JobHandler)
	self._job = jobService
	self._antiCheat = antiCheatService
	self._tutorial = tutorialService
	return self
end

--- Handle a start job request.
--- @param userId number
--- @param payload table { jobId: string }
--- @return table Response
function JobHandler:handleStartJob(userId, payload)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "StartJob")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	local valid, err = PayloadTypes.validateJob(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end

	return self._job:startJob(userId, payload.jobId)
end

--- Handle a claim job reward request.
--- @param userId number
--- @return table Response
function JobHandler:handleClaimJob(userId)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "ClaimJob")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	local result = self._job:claimReward(userId)

	-- Track tutorial progress
	if result.ok then
		self._tutorial:recordAction(userId, "jobClaim")
	end

	return result
end

--- Handle a cancel job request.
--- @param userId number
--- @return table Response
function JobHandler:handleCancelJob(userId)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "CancelJob")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	return self._job:cancelJob(userId)
end

return JobHandler
