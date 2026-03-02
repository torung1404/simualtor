--[[
	RankService.lua
	Leaderboards, season management, and ranked battles.
]]

local SeasonConfig = require(game.ReplicatedStorage.Shared.Configs.SeasonConfig)

local RankService = {}
RankService.__index = RankService

--- Create a new RankService.
--- @param playerDataService PlayerDataService
--- @param economyService EconomyService
--- @param combatService CombatService
--- @param stateMachine PlayerStateMachine
--- @return RankService
function RankService.new(playerDataService, economyService, combatService, stateMachine)
	local self = setmetatable({}, RankService)
	self._playerData = playerDataService
	self._economy = economyService
	self._combat = combatService
	self._stateMachine = stateMachine
	return self
end

--- Enter a ranked battle. Deducts entry cost and resolves fight.
--- @param userId number
--- @return table { ok, data?, error? }
function RankService:enterRanked(userId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	-- State check
	local allowed, reason = self._stateMachine:isActionAllowed(userId, "EnterRanked")
	if not allowed then
		return { ok = false, error = reason }
	end

	-- Deduct entry cost
	local cost = SeasonConfig.entryTicketCost
	local spendOk, spendErr = self._economy:spendCoin(userId, cost, "ranked_entry")
	if not spendOk then
		return { ok = false, error = spendErr }
	end

	-- Transition to ranked state
	self._stateMachine:transition(userId, "InRanked")

	-- Simulate ranked encounter using a server seed for fairness
	local seed = os.time() + userId
	math.randomseed(seed)

	-- Generate a ranked challenge based on player power
	local playerPower = self._combat:getPlayerPower(userId)
	local challengePower = math.floor(playerPower * (0.8 + math.random() * 0.5)) -- 80% to 130% of player power

	local won = playerPower >= challengePower
	local clearTimeSeconds = won and math.random(15, 90) or 0
	local hitsTaken = won and math.random(0, 10) or 0

	-- Calculate score
	local score = 0
	if won then
		local scoring = SeasonConfig.scoring
		score = scoring.baseClearPoints

		-- Time bonus
		if clearTimeSeconds < scoring.parTimeSeconds then
			score = score + (scoring.parTimeSeconds - clearTimeSeconds) * scoring.timeBonusPerSecondUnder
		end

		-- Damage bonus
		score = score + math.floor(playerPower * scoring.damageBonusMultiplier)

		-- Hits taken penalty
		score = score - (hitsTaken * scoring.hitsTakenPenalty)
		score = math.max(score, 1)

		-- Add season points
		data.season.points = data.season.points + score

		-- Update tier
		data.season.tier = self:_calculateTier(data.season.points)
	end

	-- Return to menu
	self._stateMachine:transition(userId, "InMenu")
	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = {
			won = won,
			score = score,
			totalPoints = data.season.points,
			tier = data.season.tier,
			challengePower = challengePower,
			playerPower = playerPower,
			clearTime = clearTimeSeconds,
			hitsTaken = hitsTaken,
		},
	}
end

--- Calculate the tier based on points.
--- @param points number
--- @return string tierId
function RankService:_calculateTier(points)
	local currentTier = "bronze"
	for _, tier in ipairs(SeasonConfig.tiers) do
		if points >= tier.minPoints then
			currentTier = tier.tierId
		end
	end
	return currentTier
end

--- Get ranked status for UI.
--- @param userId number
--- @return table? { points, tier, tierName, nextTier, pointsToNext }
function RankService:getRankedStatus(userId)
	local data = self._playerData:getData(userId)
	if not data then return nil end

	local currentTier = data.season.tier
	local nextTier = nil
	local pointsToNext = nil

	for i, tier in ipairs(SeasonConfig.tiers) do
		if tier.tierId == currentTier and i < #SeasonConfig.tiers then
			nextTier = SeasonConfig.tiers[i + 1]
			pointsToNext = nextTier.minPoints - data.season.points
			break
		end
	end

	local tierConfig = SeasonConfig.TierById[currentTier]

	return {
		points = data.season.points,
		tier = currentTier,
		tierName = tierConfig and tierConfig.name or "Unknown",
		nextTier = nextTier and nextTier.name or nil,
		pointsToNext = pointsToNext,
		seasonName = SeasonConfig.seasonName,
	}
end

--- Claim season reward for reaching a tier.
--- @param userId number
--- @param tierId string
--- @return table { ok, data?, error? }
function RankService:claimSeasonReward(userId, tierId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	-- Check if tier reward exists
	local reward = SeasonConfig.rewards[tierId]
	if not reward then
		return { ok = false, error = "Invalid tier" }
	end

	-- Check if already claimed
	for _, claimed in ipairs(data.season.claimedRewards) do
		if claimed == tierId then
			return { ok = false, error = "Already claimed" }
		end
	end

	-- Check if player has reached this tier
	local tierConfig = SeasonConfig.TierById[tierId]
	if not tierConfig or data.season.points < tierConfig.minPoints then
		return { ok = false, error = "Tier not reached yet" }
	end

	-- Grant rewards
	if reward.gems then
		self._economy:addGems(userId, reward.gems)
	end

	data.season.claimedRewards[#data.season.claimedRewards + 1] = tierId
	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = {
			tierId = tierId,
			reward = reward,
		},
	}
end

return RankService
