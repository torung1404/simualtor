--[[
	JobViewController.lua
	Formats job data for display. Handles job start/claim/cancel requests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local JobsConfig = require(ReplicatedStorage.Shared.Configs.JobsConfig)

local JobViewController = {}
JobViewController.__index = JobViewController

--- Create a new JobViewController.
--- @param uiController UIController
--- @return JobViewController
function JobViewController.new(uiController)
	local self = setmetatable({}, JobViewController)
	self._ui = uiController
	self._remoteFolder = nil
	return self
end

--- Initialize.
function JobViewController:init()
	self._remoteFolder = ReplicatedStorage:WaitForChild("AnimeSimRemotes")
end

--- Get available jobs for the current arc.
--- @return table[] Array of formatted job data
function JobViewController:getJobList()
	local state = self._ui:getPlayerState()
	if not state then return {} end

	local playerPower = state.stats and state.stats.highestPower or 0
	local activeJobId = state.jobs and state.jobs.activeJobId or nil

	local jobs = {}
	for _, jobConfig in ipairs(JobsConfig.List) do
		local unlocked = true
		local req = jobConfig.unlockRequirement
		if req.type == "power" then
			unlocked = playerPower >= req.value
		elseif req.type == "tutorialStep" then
			unlocked = state.progress.tutorialComplete or state.progress.tutorialStep >= req.value
		end

		jobs[#jobs + 1] = {
			jobId = jobConfig.jobId,
			name = jobConfig.name,
			arcId = jobConfig.arcId,
			tickTime = jobConfig.tickTimeSeconds .. "s",
			rewardPerTick = NumberFormat.abbreviate(jobConfig.rewardPerTick),
			unlocked = unlocked,
			isActive = jobConfig.jobId == activeJobId,
		}
	end

	return jobs
end

--- Request to start a job.
--- @param jobId string
--- @return table? response
function JobViewController:requestStartJob(jobId)
	if not self._remoteFolder then return nil end
	local remote = self._remoteFolder:FindFirstChild(RemoteNames.StartJob)
	if not remote then return nil end

	local response = remote:InvokeServer({ jobId = jobId })
	if response and response.ok then
		self._ui:_fireEvent("jobStarted", response.data)
	end
	return response
end

--- Request to claim job rewards.
--- @return table? response
function JobViewController:requestClaimJob()
	if not self._remoteFolder then return nil end
	local remote = self._remoteFolder:FindFirstChild(RemoteNames.ClaimJob)
	if not remote then return nil end

	local response = remote:InvokeServer()
	if response and response.ok then
		self._ui:_fireEvent("jobClaimed", response.data)
	end
	return response
end

--- Request to cancel the current job.
--- @return table? response
function JobViewController:requestCancelJob()
	if not self._remoteFolder then return nil end
	local remote = self._remoteFolder:FindFirstChild(RemoteNames.CancelJob)
	if not remote then return nil end

	local response = remote:InvokeServer()
	if response and response.ok then
		self._ui:_fireEvent("jobCancelled", response.data)
	end
	return response
end

--- Get formatted active job status.
--- @return table? { jobName, ticks, pendingReward, elapsed }
function JobViewController:getActiveJobStatus()
	local state = self._ui:getPlayerState()
	if not state or not state.jobStatus then return nil end

	local status = state.jobStatus
	return {
		jobName = status.jobName,
		ticks = status.ticks,
		pendingReward = NumberFormat.abbreviate(status.pendingReward),
		elapsed = NumberFormat.formatTime(status.elapsed),
		tickTime = status.tickTimeSeconds .. "s",
	}
end

return JobViewController
