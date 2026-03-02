--[[
	RankHandler.lua
	Routes ranked remotes to RankService.
]]

local PayloadTypes = require(game.ReplicatedStorage.Shared.NetSchema.PayloadTypes)

local RankHandler = {}
RankHandler.__index = RankHandler

--- Create a new RankHandler.
--- @param rankService RankService
--- @param antiCheatService AntiCheatService
--- @return RankHandler
function RankHandler.new(rankService, antiCheatService)
	local self = setmetatable({}, RankHandler)
	self._rank = rankService
	self._antiCheat = antiCheatService
	return self
end

--- Handle an enter ranked request.
--- @param userId number
--- @return table Response
function RankHandler:handleEnterRanked(userId)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "EnterRanked")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	return self._rank:enterRanked(userId)
end

--- Handle a claim season reward request.
--- @param userId number
--- @param payload table { tierId: string }
--- @return table Response
function RankHandler:handleClaimSeasonReward(userId, payload)
	if type(payload) ~= "table" or type(payload.tierId) ~= "string" then
		return PayloadTypes.response(false, nil, "Invalid payload")
	end

	return self._rank:claimSeasonReward(userId, payload.tierId)
end

return RankHandler
