--[[
	NotificationService.lua
	Centralized notification dispatcher for server-to-client communication.
	Manages StateUpdate, Notification, and RareDropAnnounce events.
]]

local Players = game:GetService("Players")

local NotificationService = {}
NotificationService.__index = NotificationService

-- Notification types
NotificationService.Types = {
	Info = "info",
	Success = "success",
	Warning = "warning",
	Error = "error",
	Reward = "reward",
	Achievement = "achievement",
	RareDrop = "rareDrop",
}

--- Create a new NotificationService.
--- @param remoteFolder Folder containing remote events
--- @return NotificationService
function NotificationService.new(remoteFolder)
	local self = setmetatable({}, NotificationService)
	self._remoteFolder = remoteFolder
	self._stateUpdateEvent = nil
	self._notificationEvent = nil
	self._rareDropEvent = nil
	self._achievementEvent = nil
	return self
end

--- Initialize remote event references. Call after remotes are created.
--- @param stateUpdateEvent RemoteEvent
--- @param notificationEvent RemoteEvent
--- @param rareDropEvent RemoteEvent
function NotificationService:init(stateUpdateEvent, notificationEvent, rareDropEvent)
	self._stateUpdateEvent = stateUpdateEvent
	self._notificationEvent = notificationEvent
	self._rareDropEvent = rareDropEvent
end

--- Send a state update to a specific player.
--- @param userId number
--- @param stateData table Partial state to merge on client
function NotificationService:sendStateUpdate(userId, stateData)
	if not self._stateUpdateEvent then return end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		self._stateUpdateEvent:FireClient(player, stateData)
	end
end

--- Send a notification to a specific player.
--- @param userId number
--- @param notifType string One of NotificationService.Types
--- @param title string
--- @param message string
--- @param data table? Optional extra data (icon, duration, etc.)
function NotificationService:sendNotification(userId, notifType, title, message, data)
	if not self._notificationEvent then return end

	local player = Players:GetPlayerByUserId(userId)
	if player then
		self._notificationEvent:FireClient(player, {
			type = notifType,
			title = title,
			message = message,
			data = data,
			timestamp = os.time(),
		})
	end
end

--- Announce a rare drop to all players in the server.
--- @param userId number The player who got the drop
--- @param playerName string
--- @param itemName string
--- @param rarity string
--- @param enemyName string
function NotificationService:announceRareDrop(userId, playerName, itemName, rarity, enemyName)
	if not self._rareDropEvent then return end

	self._rareDropEvent:FireAllClients({
		playerId = userId,
		playerName = playerName,
		itemName = itemName,
		rarity = rarity,
		enemyName = enemyName,
		timestamp = os.time(),
	})
end

--- Send a reward notification to a player.
--- @param userId number
--- @param title string
--- @param rewards table { coin?, gems?, points?, items? }
function NotificationService:sendRewardNotification(userId, title, rewards)
	self:sendNotification(userId, NotificationService.Types.Reward, title, "", {
		rewards = rewards,
	})
end

--- Send a welcome-back notification.
--- @param userId number
--- @param daysAway number
--- @param bonus table { coin }
function NotificationService:sendWelcomeBack(userId, daysAway, bonus)
	self:sendNotification(
		userId,
		NotificationService.Types.Info,
		"Welcome Back!",
		"You were away for " .. daysAway .. " days. Here is a bonus!",
		{ rewards = bonus }
	)
end

--- Send a login streak notification.
--- @param userId number
--- @param streakDay number
--- @param reward table?
function NotificationService:sendLoginStreak(userId, streakDay, reward)
	local message = "Day " .. streakDay .. " login streak!"
	if reward then
		self:sendNotification(
			userId,
			NotificationService.Types.Reward,
			"Login Streak Reward",
			message,
			{ rewards = reward, streakDay = streakDay }
		)
	else
		self:sendNotification(
			userId,
			NotificationService.Types.Info,
			"Login Streak",
			message,
			{ streakDay = streakDay }
		)
	end
end

--- Send a daily quest completion notification.
--- @param userId number
--- @param questDescription string
function NotificationService:sendQuestComplete(userId, questDescription)
	self:sendNotification(
		userId,
		NotificationService.Types.Success,
		"Quest Complete!",
		questDescription,
		nil
	)
end

--- Send an arc unlock notification.
--- @param userId number
--- @param arcName string
function NotificationService:sendArcUnlock(userId, arcName)
	self:sendNotification(
		userId,
		NotificationService.Types.Achievement,
		"New Arc Unlocked!",
		arcName .. " is now available!",
		{ arcName = arcName }
	)
end

return NotificationService
