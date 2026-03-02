--[[
	UpgradeViewController.lua
	Formats upgrade data for display. Handles buy upgrade requests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local UpgradesConfig = require(ReplicatedStorage.Shared.Configs.UpgradesConfig)
local MathUtils = require(ReplicatedStorage.Shared.Utils.MathUtils)

local UpgradeViewController = {}
UpgradeViewController.__index = UpgradeViewController

--- Create a new UpgradeViewController.
--- @param uiController UIController
--- @return UpgradeViewController
function UpgradeViewController.new(uiController)
	local self = setmetatable({}, UpgradeViewController)
	self._ui = uiController
	self._remoteFolder = nil
	return self
end

--- Initialize.
function UpgradeViewController:init()
	self._remoteFolder = ReplicatedStorage:WaitForChild("AnimeSimRemotes")
end

--- Get all upgrades formatted for display, grouped by category.
--- @return table { damage = {...}, income = {...}, ... }
function UpgradeViewController:getUpgradesByCategory()
	local state = self._ui:getPlayerState()
	if not state then return {} end

	local playerUpgrades = state.upgrades or {}
	local playerCoin = state.wallet and state.wallet.coin or 0

	local categories = {}
	for _, config in ipairs(UpgradesConfig.List) do
		local level = playerUpgrades[config.upgradeId] or 0
		local isMaxed = level >= config.maxLevel
		local nextCost = nil
		if not isMaxed then
			nextCost = MathUtils.upgradeCost(config.baseCost, config.costGrowth, level)
		end

		local entry = {
			upgradeId = config.upgradeId,
			name = config.name,
			category = config.category,
			level = level,
			maxLevel = config.maxLevel,
			currentEffect = config.effectPerLevel * level,
			nextEffect = not isMaxed and config.effectPerLevel * (level + 1) or nil,
			nextCost = nextCost,
			nextCostFormatted = nextCost and NumberFormat.abbreviate(nextCost) or "MAX",
			canAfford = nextCost ~= nil and playerCoin >= nextCost,
			isMaxed = isMaxed,
			description = config.description,
		}

		if not categories[config.category] then
			categories[config.category] = {}
		end
		categories[config.category][#categories[config.category] + 1] = entry
	end

	return categories
end

--- Request to buy an upgrade.
--- @param upgradeId string
--- @return table? response
function UpgradeViewController:requestBuyUpgrade(upgradeId)
	if not self._remoteFolder then return nil end
	local remote = self._remoteFolder:FindFirstChild(RemoteNames.BuyUpgrade)
	if not remote then return nil end

	local response = remote:InvokeServer({ upgradeId = upgradeId })
	if response and response.ok then
		self._ui:_fireEvent("upgradeBought", response.data)
	end
	return response
end

--- Get a tooltip for an upgrade.
--- @param upgradeId string
--- @return table? { name, description, currentValue, nextValue, cost }
function UpgradeViewController:getUpgradeTooltip(upgradeId)
	local config = UpgradesConfig.ById[upgradeId]
	if not config then return nil end

	local state = self._ui:getPlayerState()
	local level = 0
	if state and state.upgrades then
		level = state.upgrades[upgradeId] or 0
	end

	local isMaxed = level >= config.maxLevel
	local nextCost = nil
	if not isMaxed then
		nextCost = MathUtils.upgradeCost(config.baseCost, config.costGrowth, level)
	end

	return {
		name = config.name,
		description = config.description,
		category = config.category,
		currentLevel = level,
		maxLevel = config.maxLevel,
		currentValue = NumberFormat.abbreviate(config.effectPerLevel * level),
		nextValue = not isMaxed and NumberFormat.abbreviate(config.effectPerLevel * (level + 1)) or nil,
		cost = nextCost and NumberFormat.abbreviate(nextCost) or "MAX",
	}
end

return UpgradeViewController
