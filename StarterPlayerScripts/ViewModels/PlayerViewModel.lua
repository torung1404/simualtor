--[[
	PlayerViewModel.lua
	Formats player stats for UI display.
]]

local NumberFormat = require(game.ReplicatedStorage.Shared.Utils.NumberFormat)

local PlayerViewModel = {}
PlayerViewModel.__index = PlayerViewModel

--- Create a new PlayerViewModel.
--- @param uiController UIController
--- @return PlayerViewModel
function PlayerViewModel.new(uiController)
	local self = setmetatable({}, PlayerViewModel)
	self._ui = uiController
	return self
end

--- Get formatted wallet display.
--- @return table { coin, gems, seasonTickets }
function PlayerViewModel:getWalletDisplay()
	local state = self._ui:getPlayerState()
	if not state or not state.wallet then
		return { coin = "0", gems = "0", seasonTickets = "0" }
	end

	return {
		coin = NumberFormat.abbreviate(state.wallet.coin),
		gems = NumberFormat.commaFormat(state.wallet.gems),
		seasonTickets = tostring(state.wallet.seasonTickets),
	}
end

--- Get formatted stats display.
--- @return table
function PlayerViewModel:getStatsDisplay()
	local state = self._ui:getPlayerState()
	if not state or not state.stats then
		return {
			totalKills = "0",
			bossesDefeated = "0",
			highestPower = "0",
			totalCoinEarned = "0",
		}
	end

	return {
		totalKills = NumberFormat.commaFormat(state.stats.totalKills),
		bossesDefeated = NumberFormat.commaFormat(state.stats.bossesDefeated),
		highestPower = NumberFormat.abbreviate(state.stats.highestPower),
		totalCoinEarned = NumberFormat.abbreviate(state.stats.totalCoinEarned),
	}
end

--- Get formatted progress display.
--- @return table
function PlayerViewModel:getProgressDisplay()
	local state = self._ui:getPlayerState()
	if not state or not state.progress then
		return { currentArc = "Unknown", tutorialStep = "0" }
	end

	local ArcsConfig = require(game.ReplicatedStorage.Shared.Configs.ArcsConfig)
	local arc = ArcsConfig.ById[state.progress.currentArcId]

	return {
		currentArc = arc and arc.name or "Unknown",
		currentArcId = state.progress.currentArcId,
		tutorialComplete = state.progress.tutorialComplete,
		tutorialStep = state.progress.tutorialStep,
		unlockedArcs = #state.progress.unlockedArcs,
	}
end

--- Get formatted ranked display.
--- @return table
function PlayerViewModel:getRankedDisplay()
	local state = self._ui:getPlayerState()
	if not state or not state.ranked then
		return { tier = "Bronze", points = "0", tierName = "Bronze" }
	end

	local ranked = state.ranked
	return {
		tier = ranked.tier,
		tierName = ranked.tierName,
		points = NumberFormat.commaFormat(ranked.points),
		nextTier = ranked.nextTier,
		pointsToNext = ranked.pointsToNext and NumberFormat.commaFormat(ranked.pointsToNext) or nil,
		seasonName = ranked.seasonName,
	}
end

--- Get the bottom bar data (coin, power, next step).
--- @return table
function PlayerViewModel:getBottomBarData()
	local wallet = self:getWalletDisplay()
	local stats = self:getStatsDisplay()
	local nextStep = self._ui:getNextStepHint()

	return {
		coin = wallet.coin,
		gems = wallet.gems,
		power = stats.highestPower,
		nextStep = nextStep,
	}
end

return PlayerViewModel
