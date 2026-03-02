--[[
	CombatViewController.lua
	Formats combat data for display. Handles fight requests and result rendering.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)
local NumberFormat = require(ReplicatedStorage.Shared.Utils.NumberFormat)
local EnemiesConfig = require(ReplicatedStorage.Shared.Configs.EnemiesConfig)
local ArcsConfig = require(ReplicatedStorage.Shared.Configs.ArcsConfig)

local CombatViewController = {}
CombatViewController.__index = CombatViewController

--- Create a new CombatViewController.
--- @param uiController UIController
--- @return CombatViewController
function CombatViewController.new(uiController)
	local self = setmetatable({}, CombatViewController)
	self._ui = uiController
	self._lastFightResult = nil
	self._remoteFolder = nil
	return self
end

--- Initialize. Call after UIController:init().
function CombatViewController:init()
	self._remoteFolder = ReplicatedStorage:WaitForChild("AnimeSimRemotes")
end

--- Get the list of enemies for the current arc, formatted for UI display.
--- @return table[] Array of { enemyId, name, hp, power, rewards, isDefeatable }
function CombatViewController:getEnemyList()
	local state = self._ui:getPlayerState()
	if not state then return {} end

	local currentArcId = state.progress.currentArcId
	local arc = ArcsConfig.ById[currentArcId]
	if not arc then return {} end

	local playerPower = state.stats and state.stats.highestPower or 0
	local enemies = {}

	-- Regular enemies
	for _, enemyId in ipairs(arc.enemies) do
		local enemy = EnemiesConfig.ById[enemyId]
		if enemy then
			enemies[#enemies + 1] = {
				enemyId = enemy.enemyId,
				name = enemy.name,
				hp = NumberFormat.abbreviate(enemy.hp),
				power = NumberFormat.abbreviate(enemy.power),
				coinReward = NumberFormat.abbreviate(enemy.rewards.coin),
				xpReward = NumberFormat.abbreviate(enemy.rewards.xp),
				isDefeatable = playerPower >= enemy.power,
				isBoss = false,
			}
		end
	end

	-- Boss
	local boss = EnemiesConfig.ById[arc.bossId]
	if boss then
		enemies[#enemies + 1] = {
			enemyId = boss.enemyId,
			name = boss.name,
			hp = NumberFormat.abbreviate(boss.hp),
			power = NumberFormat.abbreviate(boss.power),
			coinReward = NumberFormat.abbreviate(boss.rewards.coin),
			xpReward = NumberFormat.abbreviate(boss.rewards.xp),
			isDefeatable = playerPower >= boss.power,
			isBoss = true,
			mechanics = boss.mechanics,
		}
	end

	return enemies
end

--- Request a fight with an enemy.
--- @param enemyId string
--- @return table? result { won, rewards, drops, ... }
function CombatViewController:requestFight(enemyId)
	if not self._remoteFolder then return nil end

	local fightRemote = self._remoteFolder:FindFirstChild(RemoteNames.Fight)
	if not fightRemote then return nil end

	local response = fightRemote:InvokeServer({ enemyId = enemyId })
	self._lastFightResult = response

	if response and response.ok then
		-- Notify UI controller of state change
		self._ui:_fireEvent("fightResult", response.data)
	else
		self._ui:_fireEvent("fightError", response and response.error or "Unknown error")
	end

	return response
end

--- Get the last fight result formatted for display.
--- @return table? { won, enemyName, playerPower, coinGained, xpGained, drops }
function CombatViewController:getLastFightResult()
	if not self._lastFightResult or not self._lastFightResult.ok then
		return nil
	end

	local data = self._lastFightResult.data
	local formattedDrops = {}
	if data.drops then
		local ItemsConfig = require(ReplicatedStorage.Shared.Configs.ItemsConfig)
		for _, itemId in ipairs(data.drops) do
			local item = ItemsConfig.ById[itemId]
			if item then
				formattedDrops[#formattedDrops + 1] = {
					itemId = itemId,
					name = item.name,
					rarity = item.rarity,
				}
			end
		end
	end

	return {
		won = data.won,
		enemyName = data.enemyName,
		playerPower = NumberFormat.abbreviate(data.playerPower),
		enemyPower = NumberFormat.abbreviate(data.enemyPower),
		coinGained = data.rewards and NumberFormat.abbreviate(data.rewards.coin) or "0",
		xpGained = data.rewards and NumberFormat.abbreviate(data.rewards.xp) or "0",
		gemsGained = data.rewards and data.rewards.gems or 0,
		drops = formattedDrops,
		bossDefeated = data.bossDefeated or false,
	}
end

--- Get available arcs for display.
--- @return table[] Array of { arcId, name, recommendedPower, unlocked, isCurrent }
function CombatViewController:getArcList()
	local state = self._ui:getPlayerState()
	if not state then return {} end

	local unlockedArcs = state.progress.unlockedArcs or {}
	local currentArcId = state.progress.currentArcId

	local arcs = {}
	for _, arc in ipairs(ArcsConfig.List) do
		local unlocked = false
		for _, uArc in ipairs(unlockedArcs) do
			if uArc == arc.arcId then
				unlocked = true
				break
			end
		end

		arcs[#arcs + 1] = {
			arcId = arc.arcId,
			name = arc.name,
			recommendedPower = NumberFormat.abbreviate(arc.recommendedPower),
			unlocked = unlocked,
			isCurrent = arc.arcId == currentArcId,
		}
	end

	return arcs
end

return CombatViewController
