--[[
	PlayerDataService.lua
	Handles loading, saving, caching, migrating, and session locking of player data.
	All player data lives in a server-side Lua table while the player is online.
	Saves are batched every SAVE_INTERVAL seconds, plus on leave and shutdown.
]]

local TableUtils = require(game.ReplicatedStorage.Shared.Utils.TableUtils)

local PlayerDataService = {}
PlayerDataService.__index = PlayerDataService

local CURRENT_SCHEMA_VERSION = 3
local SAVE_INTERVAL = 75 -- seconds between auto-saves
local MAX_RETRIES = 3
local RETRY_BASE_DELAY = 1 -- seconds, exponential backoff

-- Default data template for new players
local DEFAULT_DATA = {
	schemaVersion = CURRENT_SCHEMA_VERSION,

	wallet = {
		coin = 0,
		gems = 0,
		seasonTickets = 0,
	},

	progress = {
		currentArcId = "arc_1",
		unlockedArcs = { "arc_1" },
		unlockedTabs = { "combat" },
		tutorialStep = 1,
		tutorialComplete = false,
	},

	upgrades = {},

	inventory = {
		items = {},
		equippedSlots = {},
	},

	jobs = {
		activeJobId = nil,
		jobStartedAt = 0,
		lastClaimAt = 0,
	},

	stats = {
		totalKills = 0,
		bossesDefeated = 0,
		totalPlaytime = 0,
		highestPower = 0,
		totalCoinEarned = 0,
	},

	season = {
		seasonId = "s1",
		points = 0,
		tier = "bronze",
		claimedRewards = {},
	},

	social = {
		referralCode = "",
		referredBy = "",
		referralCount = 0,
	},

	daily = {
		loginStreak = 0,
		lastLoginDate = "",
		dailyQuestsCompleted = {},
		lastDailyReset = "",
	},

	settings = {
		sfxEnabled = true,
		musicEnabled = true,
		uiScale = 1,
	},
}

--- Create a new PlayerDataService instance.
--- @param dataStoreService any Roblox DataStoreService (injected for testability)
--- @param memoryStoreService any Roblox MemoryStoreService (injected)
--- @return PlayerDataService
function PlayerDataService.new(dataStoreService, memoryStoreService)
	local self = setmetatable({}, PlayerDataService)
	self._cache = {} -- userId -> playerData
	self._dirty = {} -- userId -> boolean (whether data needs saving)
	self._sessionLocks = {} -- userId -> boolean (whether we hold the lock)
	self._dataStore = dataStoreService and dataStoreService:GetDataStore("AnimeSimPlayerData_v1") or nil
	self._memoryStore = memoryStoreService and memoryStoreService:GetSortedMap("AnimeSimSessionLocks") or nil
	self._saveLoopRunning = false
	return self
end

--- Get default data template (deep copy).
--- @return table
function PlayerDataService.getDefaultData()
	return TableUtils.deepCopy(DEFAULT_DATA)
end

--- Run schema migrations sequentially.
--- @param data table Player data that may be outdated
--- @return table Migrated data
function PlayerDataService._migrate(data)
	if not data.schemaVersion then
		data.schemaVersion = 1
	end

	-- Migration v1 -> v2: added season and social tables
	if data.schemaVersion < 2 then
		data.season = data.season or TableUtils.deepCopy(DEFAULT_DATA.season)
		data.social = data.social or TableUtils.deepCopy(DEFAULT_DATA.social)
		data.schemaVersion = 2
	end

	-- Migration v2 -> v3: added daily and settings tables
	if data.schemaVersion < 3 then
		data.daily = data.daily or TableUtils.deepCopy(DEFAULT_DATA.daily)
		data.settings = data.settings or TableUtils.deepCopy(DEFAULT_DATA.settings)
		data.schemaVersion = 3
	end

	return data
end

--- Acquire a session lock for a player. Returns true if lock acquired.
--- @param userId number
--- @return boolean
function PlayerDataService:_acquireSessionLock(userId)
	if not self._memoryStore then
		-- No MemoryStore available (testing), always succeed
		self._sessionLocks[userId] = true
		return true
	end

	local key = "session_" .. tostring(userId)
	local success, _ = pcall(function()
		-- Try to set with expiry; if key exists, another server holds the lock
		self._memoryStore:SetIfNotExists(key, true, 300) -- 5 minute expiry
	end)

	if success then
		self._sessionLocks[userId] = true
		return true
	end

	-- Lock exists, wait briefly and retry once
	task.wait(2)
	success, _ = pcall(function()
		self._memoryStore:SetIfNotExists(key, true, 300)
	end)

	if success then
		self._sessionLocks[userId] = true
		return true
	end

	return false
end

--- Release the session lock for a player.
--- @param userId number
function PlayerDataService:_releaseSessionLock(userId)
	self._sessionLocks[userId] = nil
	if not self._memoryStore then return end

	local key = "session_" .. tostring(userId)
	pcall(function()
		self._memoryStore:RemoveAsync(key)
	end)
end

--- Load player data from DataStore with retry logic.
--- @param userId number
--- @return table playerData
function PlayerDataService:loadData(userId)
	-- Acquire session lock first
	if not self:_acquireSessionLock(userId) then
		warn("[PlayerDataService] Could not acquire session lock for " .. userId)
		return nil
	end

	local data = nil

	if self._dataStore then
		local key = "player_" .. tostring(userId)
		for attempt = 1, MAX_RETRIES do
			local success, result = pcall(function()
				return self._dataStore:GetAsync(key)
			end)
			if success then
				data = result
				break
			else
				warn("[PlayerDataService] Load attempt " .. attempt .. " failed for " .. userId .. ": " .. tostring(result))
				if attempt < MAX_RETRIES then
					task.wait(RETRY_BASE_DELAY * (2 ^ (attempt - 1)))
				end
			end
		end
	end

	-- Use default data if no saved data or DataStore unavailable
	if data == nil then
		data = PlayerDataService.getDefaultData()
	else
		-- Run migrations if needed
		if data.schemaVersion < CURRENT_SCHEMA_VERSION then
			data = PlayerDataService._migrate(data)
			self._dirty[userId] = true -- save migrated data
		end
	end

	self._cache[userId] = data
	return data
end

--- Save player data to DataStore with retry logic.
--- @param userId number
--- @return boolean success
function PlayerDataService:saveData(userId)
	local data = self._cache[userId]
	if not data then return false end
	if not self._dataStore then
		self._dirty[userId] = false
		return true
	end

	local key = "player_" .. tostring(userId)
	for attempt = 1, MAX_RETRIES do
		local success, err = pcall(function()
			self._dataStore:SetAsync(key, data)
		end)
		if success then
			self._dirty[userId] = false
			return true
		else
			warn("[PlayerDataService] Save attempt " .. attempt .. " failed for " .. userId .. ": " .. tostring(err))
			if attempt < MAX_RETRIES then
				task.wait(RETRY_BASE_DELAY * (2 ^ (attempt - 1)))
			end
		end
	end
	return false
end

--- Get cached data for an online player.
--- @param userId number
--- @return table? playerData
function PlayerDataService:getData(userId)
	return self._cache[userId]
end

--- Mark a player's data as dirty (needs saving).
--- @param userId number
function PlayerDataService:markDirty(userId)
	self._dirty[userId] = true
end

--- Called when a player leaves. Saves and releases lock.
--- @param userId number
function PlayerDataService:onPlayerLeave(userId)
	if self._cache[userId] then
		self:saveData(userId)
		self._cache[userId] = nil
		self._dirty[userId] = nil
	end
	self:_releaseSessionLock(userId)
end

--- Save all dirty player data. Called periodically and on shutdown.
function PlayerDataService:saveAllDirty()
	for userId, isDirty in pairs(self._dirty) do
		if isDirty and self._cache[userId] then
			self:saveData(userId)
		end
	end
end

--- Start the auto-save loop. Call once on server init.
function PlayerDataService:startSaveLoop()
	if self._saveLoopRunning then return end
	self._saveLoopRunning = true

	task.spawn(function()
		while self._saveLoopRunning do
			task.wait(SAVE_INTERVAL)
			self:saveAllDirty()
		end
	end)
end

--- Stop the auto-save loop.
function PlayerDataService:stopSaveLoop()
	self._saveLoopRunning = false
end

--- Bind to close: save all players on server shutdown.
--- Call this during server initialization.
function PlayerDataService:bindToClose()
	game:BindToClose(function()
		self:stopSaveLoop()
		self:saveAllDirty()
		-- Release all session locks
		for userId in pairs(self._sessionLocks) do
			self:_releaseSessionLock(userId)
		end
	end)
end

return PlayerDataService
