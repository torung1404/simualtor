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

	-- Boss mechanics: calculate effective enemy power with shield/enrage
	local effectiveEnemyPower = enemy.power
	local bossInfo = nil
	if enemy.isBoss then
		bossInfo = self:_resolveBossMechanics(enemy, playerPower)
		effectiveEnemyPower = bossInfo.effectivePower
	end

	-- Crit calculation: chance to deal bonus damage
	local critChance = self:_getCritChance(data)
	local isCrit = MathUtils.rollChance(critChance)
	local effectivePlayerPower = playerPower
	if isCrit then
		effectivePlayerPower = math.floor(playerPower * 1.5) -- 50% crit damage bonus
	end

	-- Resolve fight: compare power vs enemy power
	local won = effectivePlayerPower >= effectiveEnemyPower
	local result = {
		won = won,
		playerPower = playerPower,
		effectivePlayerPower = effectivePlayerPower,
		enemyPower = enemy.power,
		effectiveEnemyPower = effectiveEnemyPower,
		enemyName = enemy.name,
		isCrit = isCrit,
		bossInfo = bossInfo,
		rewards = nil,
		drops = nil,
		arcUnlocked = nil,
	}

	if won then
		-- Get arc multiplier
		local arcMultiplier = 1.0
		local currentArcId = nil
		for _, arc in ipairs(ArcsConfig.List) do
			for _, eid in ipairs(arc.enemies) do
				if eid == enemyId then
					arcMultiplier = arc.rewardMultiplier
					currentArcId = arc.arcId
					break
				end
			end
			if arc.bossId == enemyId then
				arcMultiplier = arc.rewardMultiplier
				currentArcId = arc.arcId
			end
		end

		-- Calculate bonuses
		local incomeBonus = self._economy:getIncomeBonus(userId, UpgradesConfig.ById)
		local dropRateBonus = self._economy:getDropRateBonus(userId, UpgradesConfig.ById)

		-- Calculate rewards (crit gives bonus coin)
		local critCoinMultiplier = isCrit and 1.25 or 1.0
		local rewards = self._economy:calculateCombatRewards(
			enemy.rewards, arcMultiplier * critCoinMultiplier, incomeBonus, dropRateBonus
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
				local itemConfig = ItemsConfig.ById[dropEntry.itemId]
				drops[#drops + 1] = {
					itemId = dropEntry.itemId,
					name = itemConfig and itemConfig.name or dropEntry.itemId,
					rarity = itemConfig and itemConfig.rarity or "common",
				}
				self:_addItemToInventory(data, dropEntry.itemId)
			end
		end
		result.drops = drops

		-- Check arc progression: unlock next arc if boss defeated
		if enemy.isBoss and currentArcId then
			local unlocked = self:_checkArcProgression(data, currentArcId, playerPower)
			if unlocked then
				result.arcUnlocked = unlocked
			end
		end

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

--- Resolve boss mechanics: shield phase and enrage modify effective power.
--- @param enemy table Enemy config
--- @param playerPower number
--- @return table { effectivePower, shieldActive, enraged, mechanics }
function CombatService:_resolveBossMechanics(enemy, playerPower)
	local info = {
		effectivePower = enemy.power,
		shieldActive = false,
		enraged = false,
		mechanics = enemy.mechanics or {},
	}

	-- Shield phase: boss gets a defense multiplier
	-- Simulated as: if player power is within shield range, boss power increases
	if enemy.shieldPhaseAt then
		local powerRatio = playerPower / math.max(enemy.power, 1)
		-- Shield activates when the fight is close (ratio near 1.0-1.5)
		if powerRatio < 2.0 then
			info.shieldActive = true
			info.effectivePower = math.floor(enemy.power * 1.3) -- 30% shield boost
		end
	end

	-- Enrage timer: if fight would be long (player barely stronger), boss gets stronger
	if enemy.enrageTimerSeconds then
		local powerRatio = playerPower / math.max(enemy.power, 1)
		-- Enrage triggers when fight is very close
		if powerRatio < 1.2 and powerRatio >= 1.0 then
			info.enraged = true
			info.effectivePower = math.floor(info.effectivePower * 1.25) -- 25% enrage boost
		end
	end

	-- Dodge phase (Arc 2 boss): chance to completely avoid hit
	if enemy.dodgePhaseInterval then
		-- Simulate dodge: 20% chance the boss dodges and gets effective power boost
		if MathUtils.rollChance(0.20) then
			info.effectivePower = math.floor(info.effectivePower * 1.15)
		end
	end

	return info
end

--- Get total crit chance from upgrades and equipment.
--- @param data table Player data
--- @return number critChance (0.0 to 1.0)
function CombatService:_getCritChance(data)
	local critTotal = 0
	for upgradeId, level in pairs(data.upgrades) do
		local config = UpgradesConfig.ById[upgradeId]
		if config and config.category == "crit" then
			critTotal = critTotal + (config.effectPerLevel * level)
		end
	end

	-- Add equipment crit bonuses
	local equipBonuses = self:_getEquipmentBonuses(data)
	critTotal = critTotal + (equipBonuses.crit or 0)

	-- Cap at 80%
	return math.min(critTotal, 0.80)
end

--- Check if defeating a boss unlocks the next arc.
--- @param data table Player data (mutated)
--- @param currentArcId string
--- @param playerPower number
--- @return table? { arcId, arcName } if a new arc was unlocked, nil otherwise
function CombatService:_checkArcProgression(data, currentArcId, playerPower)
	-- Find the next arc in sequence
	local foundCurrent = false
	for _, arc in ipairs(ArcsConfig.List) do
		if foundCurrent then
			-- Check if already unlocked
			local alreadyUnlocked = false
			for _, unlockedId in ipairs(data.progress.unlockedArcs) do
				if unlockedId == arc.arcId then
					alreadyUnlocked = true
					break
				end
			end

			-- Check unlock requirement
			if not alreadyUnlocked then
				local canUnlock = false
				local req = arc.unlockRequirement
				if req.type == "none" then
					canUnlock = true
				elseif req.type == "power" then
					canUnlock = playerPower >= req.value
				end

				if canUnlock then
					data.progress.unlockedArcs[#data.progress.unlockedArcs + 1] = arc.arcId
					data.progress.currentArcId = arc.arcId

					-- Unlock the ranked tab once player reaches arc 2
					if arc.arcId == "arc_2" then
						local hasRanked = false
						for _, tab in ipairs(data.progress.unlockedTabs) do
							if tab == "ranked" then
								hasRanked = true
								break
							end
						end
						if not hasRanked then
							data.progress.unlockedTabs[#data.progress.unlockedTabs + 1] = "ranked"
						end
					end

					return { arcId = arc.arcId, arcName = arc.name }
				end
			end
			break -- only check the immediately next arc
		end
		if arc.arcId == currentArcId then
			foundCurrent = true
		end
	end

	return nil
end

return CombatService
