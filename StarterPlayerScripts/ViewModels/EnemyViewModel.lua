--[[
	EnemyViewModel.lua
	Formats enemy info for UI display.
]]

local NumberFormat = require(game.ReplicatedStorage.Shared.Utils.NumberFormat)
local EnemiesConfig = require(game.ReplicatedStorage.Shared.Configs.EnemiesConfig)
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local EnemyViewModel = {}
EnemyViewModel.__index = EnemyViewModel

function EnemyViewModel.new()
	local self = setmetatable({}, EnemyViewModel)
	return self
end

--- Format a single enemy for detailed display (tooltip/detail panel).
--- @param enemyId string
--- @param playerPower number?
--- @return table? formatted enemy data
function EnemyViewModel:getEnemyDetail(enemyId, playerPower)
	local enemy = EnemiesConfig.ById[enemyId]
	if not enemy then return nil end

	playerPower = playerPower or 0

	-- Format drop table for display
	local drops = {}
	for _, drop in ipairs(enemy.dropTable) do
		local item = ItemsConfig.ById[drop.itemId]
		if item then
			drops[#drops + 1] = {
				name = item.name,
				rarity = item.rarity,
				chance = NumberFormat.formatPercent(drop.chance),
				rarityColor = ItemsConfig.RarityColors[item.rarity],
			}
		end
	end

	local powerDiff = playerPower - enemy.power
	local difficulty = "Easy"
	if powerDiff < 0 then
		difficulty = "Too Strong"
	elseif powerDiff < enemy.power * 0.2 then
		difficulty = "Hard"
	elseif powerDiff < enemy.power then
		difficulty = "Medium"
	end

	return {
		enemyId = enemy.enemyId,
		name = enemy.name,
		hp = NumberFormat.abbreviate(enemy.hp),
		hpRaw = enemy.hp,
		power = NumberFormat.abbreviate(enemy.power),
		powerRaw = enemy.power,
		coinReward = NumberFormat.abbreviate(enemy.rewards.coin),
		xpReward = NumberFormat.abbreviate(enemy.rewards.xp),
		gemsReward = enemy.rewards.gems or 0,
		isBoss = enemy.isBoss or false,
		mechanics = enemy.mechanics,
		drops = drops,
		difficulty = difficulty,
		canDefeat = playerPower >= enemy.power,
	}
end

--- Get a short summary for list display.
--- @param enemyId string
--- @return table? { name, power, coinReward }
function EnemyViewModel:getEnemySummary(enemyId)
	local enemy = EnemiesConfig.ById[enemyId]
	if not enemy then return nil end

	return {
		enemyId = enemy.enemyId,
		name = enemy.name,
		power = NumberFormat.abbreviate(enemy.power),
		coinReward = NumberFormat.abbreviate(enemy.rewards.coin),
		isBoss = enemy.isBoss or false,
	}
end

return EnemyViewModel
