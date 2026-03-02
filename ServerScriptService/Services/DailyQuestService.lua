--[[
	DailyQuestService.lua
	Assigns daily quests from the pool, tracks progress, and grants rewards.
	Quests reset at midnight UTC each day. Players get dailyQuestCount quests per day.
]]

local SeasonConfig = require(game.ReplicatedStorage.Shared.Configs.SeasonConfig)
local TableUtils = require(game.ReplicatedStorage.Shared.Utils.TableUtils)

local DailyQuestService = {}
DailyQuestService.__index = DailyQuestService

--- Create a new DailyQuestService.
--- @param playerDataService PlayerDataService
--- @param economyService EconomyService
--- @return DailyQuestService
function DailyQuestService.new(playerDataService, economyService)
	local self = setmetatable({}, DailyQuestService)
	self._playerData = playerDataService
	self._economy = economyService
	self._questProgress = {} -- userId -> { questId -> { current = N } }
	return self
end

--- Get the current UTC date string (YYYY-MM-DD).
--- @return string
function DailyQuestService._getDateString()
	return os.date("!%Y-%m-%d")
end

--- Initialize daily quests for a player on join.
--- Assigns new quests if the day has changed since last login.
--- @param userId number
function DailyQuestService:initPlayer(userId)
	local data = self._playerData:getData(userId)
	if not data then return end

	local today = DailyQuestService._getDateString()

	-- Initialize daily table if missing (migration safety)
	if not data.daily then
		data.daily = {
			loginStreak = 0,
			lastLoginDate = "",
			dailyQuestsCompleted = {},
			lastDailyReset = "",
			activeQuests = {},
			questProgress = {},
		}
	end

	-- Ensure new fields exist
	if not data.daily.activeQuests then
		data.daily.activeQuests = {}
	end
	if not data.daily.questProgress then
		data.daily.questProgress = {}
	end

	-- Check if daily reset is needed
	if data.daily.lastDailyReset ~= today then
		self:_assignDailyQuests(data, today)
		self._playerData:markDirty(userId)
	end

	-- Init in-memory progress tracking
	self._questProgress[userId] = {}
	for _, questId in ipairs(data.daily.activeQuests) do
		local saved = data.daily.questProgress[questId]
		self._questProgress[userId][questId] = {
			current = saved and saved.current or 0,
			completed = saved and saved.completed or false,
			claimed = saved and saved.claimed or false,
		}
	end
end

--- Assign random daily quests from the pool.
--- @param data table Player data (mutated)
--- @param today string Date string
function DailyQuestService:_assignDailyQuests(data, today)
	local pool = TableUtils.shallowCopy(SeasonConfig.dailyQuestPool)
	local count = math.min(SeasonConfig.dailyQuestCount, #pool)
	local assigned = {}
	local progress = {}

	-- Shuffle and pick
	for i = 1, count do
		local idx = math.random(i, #pool)
		pool[i], pool[idx] = pool[idx], pool[i]
		assigned[#assigned + 1] = pool[i].questId
		progress[pool[i].questId] = { current = 0, completed = false, claimed = false }
	end

	data.daily.activeQuests = assigned
	data.daily.questProgress = progress
	data.daily.lastDailyReset = today
	data.daily.dailyQuestsCompleted = {}
end

--- Record a player action that may progress daily quests.
--- @param userId number
--- @param actionType string ("kills", "bossKill", "coinEarned", "upgrades", "jobClaims", "ranked")
--- @param amount number How much to increment (default 1)
function DailyQuestService:recordAction(userId, actionType, amount)
	amount = amount or 1
	local progress = self._questProgress[userId]
	if not progress then return end

	local data = self._playerData:getData(userId)
	if not data then return end

	local dirty = false

	for _, questId in ipairs(data.daily.activeQuests) do
		local qProgress = progress[questId]
		if qProgress and not qProgress.completed then
			local questConfig = self:_getQuestConfig(questId)
			if questConfig and questConfig.requirement.type == actionType then
				qProgress.current = qProgress.current + amount
				if qProgress.current >= questConfig.requirement.count then
					qProgress.current = questConfig.requirement.count
					qProgress.completed = true
				end
				-- Sync to persistent data
				if data.daily.questProgress[questId] then
					data.daily.questProgress[questId].current = qProgress.current
					data.daily.questProgress[questId].completed = qProgress.completed
				end
				dirty = true
			end
		end
	end

	if dirty then
		self._playerData:markDirty(userId)
	end
end

--- Claim reward for a completed daily quest.
--- @param userId number
--- @param questId string
--- @return table { ok, data?, error? }
function DailyQuestService:claimQuest(userId, questId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	local progress = self._questProgress[userId]
	if not progress or not progress[questId] then
		return { ok = false, error = "Quest not active" }
	end

	local qProgress = progress[questId]
	if not qProgress.completed then
		return { ok = false, error = "Quest not completed yet" }
	end

	if qProgress.claimed then
		return { ok = false, error = "Quest reward already claimed" }
	end

	local questConfig = self:_getQuestConfig(questId)
	if not questConfig then
		return { ok = false, error = "Unknown quest" }
	end

	-- Grant rewards
	if questConfig.rewardCoin and questConfig.rewardCoin > 0 then
		self._economy:addCoin(userId, questConfig.rewardCoin, "dailyQuest:" .. questId)
	end

	-- Add season points
	if questConfig.rewardPoints and questConfig.rewardPoints > 0 then
		data.season.points = data.season.points + questConfig.rewardPoints
	end

	-- Mark as claimed
	qProgress.claimed = true
	if data.daily.questProgress[questId] then
		data.daily.questProgress[questId].claimed = true
	end
	data.daily.dailyQuestsCompleted[#data.daily.dailyQuestsCompleted + 1] = questId

	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = {
			questId = questId,
			rewardCoin = questConfig.rewardCoin,
			rewardPoints = questConfig.rewardPoints,
			seasonPoints = data.season.points,
		},
	}
end

--- Get the daily quest status for a player (for UI display).
--- @param userId number
--- @return table { quests = { questId, description, current, required, completed, claimed }[] }
function DailyQuestService:getQuestStatus(userId)
	local data = self._playerData:getData(userId)
	if not data then return { quests = {} } end

	local progress = self._questProgress[userId] or {}
	local quests = {}

	for _, questId in ipairs(data.daily.activeQuests or {}) do
		local questConfig = self:_getQuestConfig(questId)
		local qProgress = progress[questId]
		if questConfig then
			quests[#quests + 1] = {
				questId = questId,
				description = questConfig.description,
				current = qProgress and qProgress.current or 0,
				required = questConfig.requirement.count,
				completed = qProgress and qProgress.completed or false,
				claimed = qProgress and qProgress.claimed or false,
				rewardCoin = questConfig.rewardCoin,
				rewardPoints = questConfig.rewardPoints,
			}
		end
	end

	return { quests = quests }
end

--- Look up a quest config by ID.
--- @param questId string
--- @return table?
function DailyQuestService:_getQuestConfig(questId)
	for _, quest in ipairs(SeasonConfig.dailyQuestPool) do
		if quest.questId == questId then
			return quest
		end
	end
	return nil
end

--- Clean up when player leaves.
--- @param userId number
function DailyQuestService:removePlayer(userId)
	self._questProgress[userId] = nil
end

return DailyQuestService
