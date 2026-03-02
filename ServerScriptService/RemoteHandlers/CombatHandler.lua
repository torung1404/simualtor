--[[
	CombatHandler.lua
	Routes combat remote events to CombatService.
	Handles payload validation, rate limiting, and response formatting.
]]

local PayloadTypes = require(game.ReplicatedStorage.Shared.NetSchema.PayloadTypes)

local CombatHandler = {}
CombatHandler.__index = CombatHandler

--- Create a new CombatHandler.
--- @param combatService CombatService
--- @param antiCheatService AntiCheatService
--- @param tutorialService TutorialService
--- @return CombatHandler
function CombatHandler.new(combatService, antiCheatService, tutorialService)
	local self = setmetatable({}, CombatHandler)
	self._combat = combatService
	self._antiCheat = antiCheatService
	self._tutorial = tutorialService
	return self
end

--- Handle a fight request from a client.
--- @param userId number
--- @param payload table { enemyId: string }
--- @return table Response { ok, data?, error? }
function CombatHandler:handleFight(userId, payload)
	-- Rate limit check
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "Fight")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	-- Payload validation
	local valid, err = PayloadTypes.validateFight(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end

	-- Delegate to service
	local result = self._combat:resolveFight(userId, payload.enemyId)

	-- Track tutorial progress
	if result.ok and result.data.won then
		self._tutorial:recordAction(userId, "fight")
		-- Check if it was a boss kill
		local EnemiesConfig = require(game.ReplicatedStorage.Shared.Configs.EnemiesConfig)
		local enemy = EnemiesConfig.ById[payload.enemyId]
		if enemy and enemy.isBoss then
			self._tutorial:recordAction(userId, "bossKill")
		end
	end

	return result
end

return CombatHandler
