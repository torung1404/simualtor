--[[
	CombatService.lua
	Resolves fights, boss mechanics, reward calculation, and loot drops.
	All combat is menu-driven: server resolves based on player power vs enemy stats.
]]

local MathUtils = require(game.ReplicatedStorage.Shared.Utils.MathUtils)
local EnemiesConfig = require(game.ReplicatedStorage.Shared.Configs.EnemiesConfig)
local ArcsConfig = require(game.ReplicatedStorage.Shared.Configs.ArcsConfig)
local UpgradesConfig = require(game.ReplicatedStorage.Shared.Configs.UpgradesConfig)
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local CombatService = {}
CombatService.__index = CombatService

--- Create a new CombatService.
--- @param playerDataService PlayerDataService
--- @param economyService EconomyService
--- @param stateMachine PlayerStateMachine
--- @return CombatService
function CombatService.new(playerDataService, economyService, stateMachine)
	local self = setmetatable({}, CombatService)
	self._playerData = playerDataService
	self._economy = economyService
	self._stateMachine = stateMachine
	return self
end

--- Calculate the player's total combat power.
--- @param userId number
--- @return number power
function CombatService:getPlayerPower(userId)
	local data = self._playerData:getData(userId)
	if not data then return 0 end

	local equipBonuses = self:_getEquipmentBonuses(data)
	return MathUtils.calculatePower(data.upgrades, UpgradesConfig.ById, equipBonuses)
end

--- Get total stat bonuses from equipped items and completed collection sets.
--- @param data table Player data
--- @return table { damage, crit, speed, ... }
function CombatService:_getEquipmentBonuses(data)
	local bonuses = { damage = 0, crit = 0, speed = 0, income = 0, dropRate = 0 }

	-- Equipment bonuses
	for _, itemId in pairs(data.inventory.equippedSlots) do
		local config = ItemsConfig.ById[itemId]
		if config and config.statBonus then
			for stat, value in pairs(config.statBonus) do
				bonuses[stat] = (bonuses[stat] or 0) + value
			end
		end
	end

	-- Collection set bonuses
	for setId, setConfig in pairs(ItemsConfig.CollectionSets) do
		local hasAll = true
		for _, requiredItemId in ipairs(setConfig.requiredItems) do
			local found = false
			for _, invItem in ipairs(data.inventory.items) do
				if invItem.itemId == requiredItemId then
					found = true
					break
				end
			end
			if not found then
				hasAll = false
				break
			end
		end
		if hasAll then
			for stat, value in pairs(setConfig.bonus) do
				bonuses[stat] = (bonuses[stat] or 0) + value
			end
		end
	end

	return bonuses
end

--- Resolve a fight between the player and an enemy.
--- @param userId number
--- @param enemyId string
--- @return table { ok, data?, error? }
function CombatService:resolveFight(userId, enemyId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	-- Validate enemy exists
	local enemy = EnemiesConfig.ById[enemyId]
	if not enemy then
		return { ok = false, error = "Unknown enemy: " .. tostring(enemyId) }
	end

	-- State machine check
	local allowed, reason = self._stateMachine:isActionAllowed(userId, "StartFight")
	if not allowed then
		return { ok = false, error = reason }
	end

	-- Transition to combat state
	local transOk, transErr = self._stateMachine:transition(userId, "InCombat")
	if not transOk then
		return { ok = false, error = transErr }
	end

	-- Calculate player power
	local playerPower = self:getPlayerPower(userId)

	-- Resolve fight: compare power vs enemy power
	local won = playerPower >= enemy.power
	local result = {
		won = won,
		playerPower = playerPower,
		enemyPower = enemy.power,
		enemyName = enemy.name,
		rewards = nil,
		drops = nil,
	}

	if won then
		-- Get arc multiplier
		local arcMultiplier = 1.0
		for _, arc in ipairs(ArcsConfig.List) do
			for _, eid in ipairs(arc.enemies) do
				if eid == enemyId then
					arcMultiplier = arc.rewardMultiplier
					break
				end
			end
			if arc.bossId == enemyId then
				arcMultiplier = arc.rewardMultiplier
			end
		end

		-- Calculate bonuses
		local incomeBonus = self._economy:getIncomeBonus(userId, UpgradesConfig.ById)
		local dropRateBonus = self._economy:getDropRateBonus(userId, UpgradesConfig.ById)

		-- Calculate rewards
		local rewards = self._economy:calculateCombatRewards(
			enemy.rewards, arcMultiplier, incomeBonus, dropRateBonus
		)
		result.rewards = rewards

		-- Apply rewards
		self._economy:addCoin(userId, rewards.coin, "combat:" .. enemyId)
		if rewards.gems > 0 then
			self._economy:addGems(userId, rewards.gems)
		end

		-- Update stats
		data.stats.totalKills = data.stats.totalKills + 1
		if enemy.isBoss then
			data.stats.bossesDefeated = data.stats.bossesDefeated + 1
		end
		if playerPower > data.stats.highestPower then
			data.stats.highestPower = playerPower
		end

		-- Roll for drops
		local drops = {}
		for _, dropEntry in ipairs(enemy.dropTable) do
			local adjustedChance = dropEntry.chance + dropRateBonus
			if MathUtils.rollChance(adjustedChance) then
				drops[#drops + 1] = dropEntry.itemId
				self:_addItemToInventory(data, dropEntry.itemId)
			end
		end
		result.drops = drops

		self._playerData:markDirty(userId)
	end

	-- Return to menu state
	self._stateMachine:transition(userId, "InMenu")

	return { ok = true, data = result }
end

--- Add an item to the player's inventory.
--- @param data table Player data (mutated)
--- @param itemId string
function CombatService:_addItemToInventory(data, itemId)
	local config = ItemsConfig.ById[itemId]
	if not config then return end

	if config.stackable then
		-- Find existing stack
		for _, invItem in ipairs(data.inventory.items) do
			if invItem.itemId == itemId then
				if invItem.quantity < config.maxStack then
					invItem.quantity = invItem.quantity + 1
					return
				end
			end
		end
	end

	-- Add new entry
	data.inventory.items[#data.inventory.items + 1] = {
		itemId = itemId,
		quantity = 1,
		equipped = false,
	}
end

--- Resolve a boss fight with special mechanics.
--- Boss fights are essentially the same as regular fights but with extra rules.
--- @param userId number
--- @param bossId string
--- @return table { ok, data?, error? }
function CombatService:resolveBossFight(userId, bossId)
	local enemy = EnemiesConfig.ById[bossId]
	if not enemy or not enemy.isBoss then
		return { ok = false, error = "Not a valid boss: " .. tostring(bossId) }
	end

	-- Boss fights use the same core logic
	local result = self:resolveFight(userId, bossId)

	-- Add boss-specific info to the result
	if result.ok and result.data.won then
		result.data.bossDefeated = true
		result.data.mechanics = enemy.mechanics
	end

	return result
end

return CombatService
