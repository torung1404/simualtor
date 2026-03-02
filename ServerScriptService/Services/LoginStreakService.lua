--[[
	LoginStreakService.lua
	Tracks daily login streaks, grants streak rewards, and handles welcome-back bonuses.
	A streak increments when the player logs in on consecutive days.
	If 3+ days pass, the streak resets and a welcome-back bonus is granted instead.
]]

local SeasonConfig = require(game.ReplicatedStorage.Shared.Configs.SeasonConfig)

local LoginStreakService = {}
LoginStreakService.__index = LoginStreakService

--- Create a new LoginStreakService.
--- @param playerDataService PlayerDataService
--- @param economyService EconomyService
--- @return LoginStreakService
function LoginStreakService.new(playerDataService, economyService)
	local self = setmetatable({}, LoginStreakService)
	self._playerData = playerDataService
	self._economy = economyService
	self._loginResults = {} -- userId -> last login result (cached for UI)
	return self
end

--- Get the current UTC date string (YYYY-MM-DD).
--- @return string
function LoginStreakService._getDateString()
	return os.date("!%Y-%m-%d")
end

--- Calculate the number of days between two YYYY-MM-DD date strings.
--- @param dateA string
--- @param dateB string
--- @return number days (absolute)
function LoginStreakService._daysBetween(dateA, dateB)
	if dateA == "" or dateB == "" then
		return 999 -- treat as very far apart
	end

	local function parseDate(dateStr)
		local y, m, d = dateStr:match("(%d+)-(%d+)-(%d+)")
		if not y then return 0 end
		return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0 })
	end

	local timeA = parseDate(dateA)
	local timeB = parseDate(dateB)
	return math.abs(math.floor((timeB - timeA) / 86400))
end

--- Process a player's login. Call once when they join.
--- Updates streak, grants welcome-back bonus if applicable.
--- @param userId number
--- @return table { streakDay, reward?, welcomeBack?, isNewDay }
function LoginStreakService:processLogin(userId)
	local data = self._playerData:getData(userId)
	if not data then return { streakDay = 0, isNewDay = false } end

	-- Initialize daily table if missing
	if not data.daily then
		data.daily = {
			loginStreak = 0,
			lastLoginDate = "",
			dailyQuestsCompleted = {},
			lastDailyReset = "",
		}
	end

	local today = LoginStreakService._getDateString()
	local lastLogin = data.daily.lastLoginDate or ""

	-- Already logged in today
	if lastLogin == today then
		local result = {
			streakDay = data.daily.loginStreak,
			isNewDay = false,
		}
		self._loginResults[userId] = result
		return result
	end

	local daysSinceLast = LoginStreakService._daysBetween(lastLogin, today)
	local result = { isNewDay = true }

	if daysSinceLast == 1 then
		-- Consecutive day: increment streak
		data.daily.loginStreak = data.daily.loginStreak + 1
	elseif daysSinceLast >= 3 then
		-- Long absence: reset streak, grant welcome-back bonus
		data.daily.loginStreak = 1
		local bonus = SeasonConfig.welcomeBackBonus
		if bonus and bonus.coin and bonus.coin > 0 then
			self._economy:addCoin(userId, bonus.coin, "welcomeBack")
			result.welcomeBack = {
				coin = bonus.coin,
				daysAway = daysSinceLast,
			}
		end
	else
		-- Missed 1 day (daysSinceLast == 2): reset streak but no welcome-back
		data.daily.loginStreak = 1
	end

	data.daily.lastLoginDate = today
	result.streakDay = data.daily.loginStreak

	-- Check for streak reward
	local streakReward = SeasonConfig.loginStreakRewards[data.daily.loginStreak]
	if streakReward then
		result.reward = self:_grantStreakReward(userId, data, streakReward)
	end

	self._playerData:markDirty(userId)
	self._loginResults[userId] = result
	return result
end

--- Grant a streak reward to the player.
--- @param userId number
--- @param data table Player data
--- @param reward table { coin?, gems?, title?, aura? }
--- @return table Applied reward details
function LoginStreakService:_grantStreakReward(userId, data, reward)
	local applied = {}

	if reward.coin and reward.coin > 0 then
		self._economy:addCoin(userId, reward.coin, "loginStreak:" .. data.daily.loginStreak)
		applied.coin = reward.coin
	end

	if reward.gems and reward.gems > 0 then
		self._economy:addGems(userId, reward.gems)
		applied.gems = reward.gems
	end

	if reward.title then
		applied.title = reward.title
	end

	if reward.aura then
		applied.aura = reward.aura
	end

	return applied
end

--- Get the login status for a player (for UI display).
--- @param userId number
--- @return table { streakDay, nextRewardDay, nextReward, lastResult }
function LoginStreakService:getLoginStatus(userId)
	local data = self._playerData:getData(userId)
	if not data or not data.daily then
		return { streakDay = 0, nextRewardDay = 1 }
	end

	local currentStreak = data.daily.loginStreak

	-- Find next reward milestone
	local nextRewardDay = nil
	local nextReward = nil
	local sortedDays = {}
	for day, _ in pairs(SeasonConfig.loginStreakRewards) do
		sortedDays[#sortedDays + 1] = day
	end
	table.sort(sortedDays)

	for _, day in ipairs(sortedDays) do
		if day > currentStreak then
			nextRewardDay = day
			nextReward = SeasonConfig.loginStreakRewards[day]
			break
		end
	end

	return {
		streakDay = currentStreak,
		nextRewardDay = nextRewardDay,
		nextReward = nextReward,
		lastResult = self._loginResults[userId],
	}
end

--- Clean up when player leaves.
--- @param userId number
function LoginStreakService:removePlayer(userId)
	self._loginResults[userId] = nil
end

return LoginStreakService
