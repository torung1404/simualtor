--[[
	EconomyService.lua
	Reward calculation, currency sinks, and sanity checks.
	Central authority for all currency operations.
]]

local EconomyService = {}
EconomyService.__index = EconomyService

--- Create a new EconomyService.
--- @param playerDataService PlayerDataService
--- @param antiCheatService AntiCheatService
--- @return EconomyService
function EconomyService.new(playerDataService, antiCheatService)
	local self = setmetatable({}, EconomyService)
	self._playerData = playerDataService
	self._antiCheat = antiCheatService
	return self
end

--- Add coins to a player. Returns false if sanity check fails.
--- @param userId number
--- @param amount number
--- @param source string Description of where the coins came from
--- @return boolean success, string? error
function EconomyService:addCoin(userId, amount, source)
	if amount <= 0 then
		return false, "Amount must be positive"
	end

	local data = self._playerData:getData(userId)
	if not data then return false, "Player data not found" end

	local before = data.wallet.coin
	data.wallet.coin = data.wallet.coin + amount
	data.stats.totalCoinEarned = data.stats.totalCoinEarned + amount

	self._playerData:markDirty(userId)
	return true, nil
end

--- Spend coins. Returns false if insufficient funds.
--- @param userId number
--- @param amount number
--- @param reason string
--- @return boolean success, string? error
function EconomyService:spendCoin(userId, amount, reason)
	if amount <= 0 then
		return false, "Amount must be positive"
	end

	local data = self._playerData:getData(userId)
	if not data then return false, "Player data not found" end

	if data.wallet.coin < amount then
		return false, "Insufficient coins"
	end

	data.wallet.coin = data.wallet.coin - amount
	self._playerData:markDirty(userId)
	return true, nil
end

--- Add gems to a player.
--- @param userId number
--- @param amount number
--- @return boolean success
function EconomyService:addGems(userId, amount)
	if amount <= 0 then return false end

	local data = self._playerData:getData(userId)
	if not data then return false end

	data.wallet.gems = data.wallet.gems + amount
	self._playerData:markDirty(userId)
	return true
end

--- Spend gems.
--- @param userId number
--- @param amount number
--- @return boolean success, string? error
function EconomyService:spendGems(userId, amount)
	if amount <= 0 then return false, "Amount must be positive" end

	local data = self._playerData:getData(userId)
	if not data then return false, "Player data not found" end

	if data.wallet.gems < amount then
		return false, "Insufficient gems"
	end

	data.wallet.gems = data.wallet.gems - amount
	self._playerData:markDirty(userId)
	return true, nil
end

--- Calculate combat rewards with multipliers from arc and upgrades.
--- @param baseRewards table { coin, xp, gems? }
--- @param arcMultiplier number
--- @param incomeBonus number (from upgrades)
--- @param dropRateBonus number (from upgrades)
--- @return table { coin, xp, gems }
function EconomyService:calculateCombatRewards(baseRewards, arcMultiplier, incomeBonus, dropRateBonus)
	local coin = math.floor(baseRewards.coin * arcMultiplier + incomeBonus)
	local xp = math.floor(baseRewards.xp * arcMultiplier)
	local gems = baseRewards.gems or 0

	return {
		coin = coin,
		xp = xp,
		gems = gems,
	}
end

--- Calculate job rewards with income bonus.
--- @param baseReward number
--- @param ticks number
--- @param incomeBonus number
--- @return number totalCoin
function EconomyService:calculateJobReward(baseReward, ticks, incomeBonus)
	return math.floor((baseReward + incomeBonus) * ticks)
end

--- Get the total income bonus from all income upgrades.
--- @param userId number
--- @param upgradeConfigs table UpgradeById lookup
--- @return number totalIncomeBonus
function EconomyService:getIncomeBonus(userId, upgradeConfigs)
	local data = self._playerData:getData(userId)
	if not data then return 0 end

	local bonus = 0
	for upgradeId, level in pairs(data.upgrades) do
		local config = upgradeConfigs[upgradeId]
		if config and config.category == "income" then
			bonus = bonus + (config.effectPerLevel * level)
		end
	end
	return bonus
end

--- Get the total drop rate bonus from all drop rate upgrades.
--- @param userId number
--- @param upgradeConfigs table UpgradeById lookup
--- @return number totalDropRateBonus (0.0 to ~1.0)
function EconomyService:getDropRateBonus(userId, upgradeConfigs)
	local data = self._playerData:getData(userId)
	if not data then return 0 end

	local bonus = 0
	for upgradeId, level in pairs(data.upgrades) do
		local config = upgradeConfigs[upgradeId]
		if config and config.category == "dropRate" then
			bonus = bonus + (config.effectPerLevel * level)
		end
	end
	return bonus
end

--- Get player wallet snapshot.
--- @param userId number
--- @return table? { coin, gems, seasonTickets }
function EconomyService:getWallet(userId)
	local data = self._playerData:getData(userId)
	if not data then return nil end
	return {
		coin = data.wallet.coin,
		gems = data.wallet.gems,
		seasonTickets = data.wallet.seasonTickets,
	}
end

return EconomyService
