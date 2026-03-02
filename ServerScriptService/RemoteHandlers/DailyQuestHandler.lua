--[[
	DailyQuestHandler.lua
	Routes daily quest and login streak remotes to services.
]]

local PayloadTypes = require(game.ReplicatedStorage.Shared.NetSchema.PayloadTypes)

local DailyQuestHandler = {}
DailyQuestHandler.__index = DailyQuestHandler

--- Create a new DailyQuestHandler.
--- @param dailyQuestService DailyQuestService
--- @param loginStreakService LoginStreakService
--- @param antiCheatService AntiCheatService
--- @return DailyQuestHandler
function DailyQuestHandler.new(dailyQuestService, loginStreakService, antiCheatService)
	local self = setmetatable({}, DailyQuestHandler)
	self._dailyQuest = dailyQuestService
	self._loginStreak = loginStreakService
	self._antiCheat = antiCheatService
	return self
end

--- Handle get daily quests request.
--- @param userId number
--- @return table Response
function DailyQuestHandler:handleGetDailyQuests(userId)
	local status = self._dailyQuest:getQuestStatus(userId)
	return PayloadTypes.response(true, status)
end

--- Handle claim daily quest reward request.
--- @param userId number
--- @param payload table { questId: string }
--- @return table Response
function DailyQuestHandler:handleClaimDailyQuest(userId, payload)
	local valid, err = PayloadTypes.validateClaimDailyQuest(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end

	return self._dailyQuest:claimQuest(userId, payload.questId)
end

--- Handle get login status request.
--- @param userId number
--- @return table Response
function DailyQuestHandler:handleGetLoginStatus(userId)
	local status = self._loginStreak:getLoginStatus(userId)
	return PayloadTypes.response(true, status)
end

return DailyQuestHandler
