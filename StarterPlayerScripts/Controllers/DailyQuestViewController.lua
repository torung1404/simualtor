--[[
	DailyQuestViewController.lua
	Formats daily quest and login streak data for UI display.
	Provides methods to invoke claim remotes from the client.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)

local DailyQuestViewController = {}
DailyQuestViewController.__index = DailyQuestViewController

--- Create a new DailyQuestViewController.
--- @param uiController UIController
--- @return DailyQuestViewController
function DailyQuestViewController.new(uiController)
	local self = setmetatable({}, DailyQuestViewController)
	self._ui = uiController
	self._remoteFolder = nil
	return self
end

--- Initialize the controller. Call once from client init.
function DailyQuestViewController:init()
	self._remoteFolder = ReplicatedStorage:WaitForChild("AnimeSimRemotes")

	-- Listen for state updates to refresh quest data
	self._ui:on("stateUpdated", function(update)
		if update.dailyQuests then
			self._ui:_fireEvent("dailyQuestsUpdated", update.dailyQuests)
		end
		if update.loginStatus then
			self._ui:_fireEvent("loginStatusUpdated", update.loginStatus)
		end
	end)

	-- Listen for notifications
	self._ui:on("notification", function(notif)
		if notif.type == "reward" then
			self._ui:_fireEvent("rewardReceived", notif)
		end
	end)
end

--- Get formatted daily quest display data.
--- @return table[] Array of formatted quest entries
function DailyQuestViewController:getQuestDisplay()
	local quests = self._ui:getDailyQuests()
	if not quests or not quests.quests then
		return {}
	end

	local display = {}
	for _, quest in ipairs(quests.quests) do
		local progressText = quest.current .. "/" .. quest.required
		local rewardText = NumberFormat.abbreviate(quest.rewardCoin) .. " coins"
		if quest.rewardPoints and quest.rewardPoints > 0 then
			rewardText = rewardText .. " + " .. quest.rewardPoints .. " pts"
		end

		display[#display + 1] = {
			questId = quest.questId,
			description = quest.description,
			progressText = progressText,
			progressPercent = quest.current / math.max(quest.required, 1),
			rewardText = rewardText,
			isCompleted = quest.completed,
			isClaimed = quest.claimed,
			canClaim = quest.completed and not quest.claimed,
		}
	end

	return display
end

--- Get formatted login streak display data.
--- @return table
function DailyQuestViewController:getLoginStreakDisplay()
	local status = self._ui:getLoginStatus()
	if not status then
		return {
			streakDay = 0,
			streakText = "Day 0",
			nextRewardText = "Log in to start!",
		}
	end

	local streakText = "Day " .. status.streakDay
	local nextRewardText = nil
	if status.nextRewardDay then
		local daysLeft = status.nextRewardDay - status.streakDay
		nextRewardText = "Next reward in " .. daysLeft .. " day" .. (daysLeft > 1 and "s" or "")
		if status.nextReward then
			local parts = {}
			if status.nextReward.coin then
				parts[#parts + 1] = NumberFormat.abbreviate(status.nextReward.coin) .. " coins"
			end
			if status.nextReward.gems then
				parts[#parts + 1] = status.nextReward.gems .. " gems"
			end
			if #parts > 0 then
				nextRewardText = nextRewardText .. " (" .. table.concat(parts, ", ") .. ")"
			end
		end
	else
		nextRewardText = "All streak rewards claimed!"
	end

	return {
		streakDay = status.streakDay,
		streakText = streakText,
		nextRewardText = nextRewardText,
		lastResult = status.lastResult,
	}
end

--- Claim a completed daily quest reward.
--- @param questId string
--- @return table Response from server
function DailyQuestViewController:claimQuest(questId)
	if not self._remoteFolder then return { ok = false, error = "Not initialized" } end

	local remote = self._remoteFolder:FindFirstChild(RemoteNames.ClaimDailyQuest)
	if not remote then return { ok = false, error = "Remote not found" } end

	return remote:InvokeServer({ questId = questId })
end

--- Refresh daily quest data from server.
--- @return table Response from server
function DailyQuestViewController:refreshQuests()
	if not self._remoteFolder then return { ok = false, error = "Not initialized" } end

	local remote = self._remoteFolder:FindFirstChild(RemoteNames.GetDailyQuests)
	if not remote then return { ok = false, error = "Remote not found" } end

	local response = remote:InvokeServer()
	if response and response.ok and response.data then
		-- Update the cached state
		local state = self._ui:getPlayerState()
		if state then
			state.dailyQuests = response.data
		end
		self._ui:_fireEvent("dailyQuestsUpdated", response.data)
	end
	return response
end

return DailyQuestViewController
