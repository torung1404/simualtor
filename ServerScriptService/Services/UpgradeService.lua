--[[
	UpgradeService.lua
	Handles buying and leveling upgrades, calculating effects.
]]

local MathUtils = require(game.ReplicatedStorage.Shared.Utils.MathUtils)
local UpgradesConfig = require(game.ReplicatedStorage.Shared.Configs.UpgradesConfig)

local UpgradeService = {}
UpgradeService.__index = UpgradeService

--- Create a new UpgradeService.
--- @param playerDataService PlayerDataService
--- @param economyService EconomyService
--- @return UpgradeService
function UpgradeService.new(playerDataService, economyService)
	local self = setmetatable({}, UpgradeService)
	self._playerData = playerDataService
	self._economy = economyService
	return self
end

--- Get the cost for the next level of an upgrade.
--- @param upgradeId string
--- @param currentLevel number
--- @return number? cost, string? error
function UpgradeService:getUpgradeCost(upgradeId, currentLevel)
	local config = UpgradesConfig.ById[upgradeId]
	if not config then
		return nil, "Unknown upgrade: " .. tostring(upgradeId)
	end
	return MathUtils.upgradeCost(config.baseCost, config.costGrowth, currentLevel), nil
end

--- Buy one level of an upgrade.
--- @param userId number
--- @param upgradeId string
--- @return table { ok, data?, error? }
function UpgradeService:buyUpgrade(userId, upgradeId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	-- Validate upgrade exists
	local config = UpgradesConfig.ById[upgradeId]
	if not config then
		return { ok = false, error = "Unknown upgrade: " .. tostring(upgradeId) }
	end

	-- Get current level
	local currentLevel = data.upgrades[upgradeId] or 0

	-- Check max level
	if currentLevel >= config.maxLevel then
		return { ok = false, error = "Upgrade already at max level" }
	end

	-- Calculate cost
	local cost = MathUtils.upgradeCost(config.baseCost, config.costGrowth, currentLevel)

	-- Attempt to spend
	local spendOk, spendErr = self._economy:spendCoin(userId, cost, "upgrade:" .. upgradeId)
	if not spendOk then
		return { ok = false, error = spendErr }
	end

	-- Apply upgrade
	data.upgrades[upgradeId] = currentLevel + 1
	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = {
			upgradeId = upgradeId,
			newLevel = data.upgrades[upgradeId],
			cost = cost,
			effect = config.effectPerLevel * data.upgrades[upgradeId],
			nextCost = data.upgrades[upgradeId] < config.maxLevel
				and MathUtils.upgradeCost(config.baseCost, config.costGrowth, data.upgrades[upgradeId])
				or nil,
		},
	}
end

--- Get all upgrade states for a player (for UI display).
--- @param userId number
--- @return table[] Array of { upgradeId, name, category, currentLevel, maxLevel, currentEffect, nextCost, description }
function UpgradeService:getUpgradeStates(userId)
	local data = self._playerData:getData(userId)
	if not data then return {} end

	local states = {}
	for _, config in ipairs(UpgradesConfig.List) do
		local level = data.upgrades[config.upgradeId] or 0
		local nextCost = nil
		if level < config.maxLevel then
			nextCost = MathUtils.upgradeCost(config.baseCost, config.costGrowth, level)
		end

		states[#states + 1] = {
			upgradeId = config.upgradeId,
			name = config.name,
			category = config.category,
			currentLevel = level,
			maxLevel = config.maxLevel,
			currentEffect = config.effectPerLevel * level,
			nextCost = nextCost,
			description = config.description,
		}
	end

	return states
end

--- Get total effect for a specific upgrade category.
--- @param userId number
--- @param category string
--- @return number totalEffect
function UpgradeService:getCategoryTotal(userId, category)
	local data = self._playerData:getData(userId)
	if not data then return 0 end

	local total = 0
	for upgradeId, level in pairs(data.upgrades) do
		local config = UpgradesConfig.ById[upgradeId]
		if config and config.category == category then
			total = total + (config.effectPerLevel * level)
		end
	end
	return total
end

return UpgradeService
