--[[
	AntiCheatService.lua
	Rate limiting, flags, bans, and audit logging.
	Implements all 5 defense layers from the blueprint.
]]

local AntiCheatService = {}
AntiCheatService.__index = AntiCheatService

-- Rate limit definitions per remote name
local RATE_LIMITS = {
	Fight         = { maxPerSecond = 3,  penalty = "kick" },
	BuyUpgrade    = { maxPerSecond = 2,  penalty = "kick" },
	ClaimJob      = { maxPerSecond = 1,  penalty = "kick" },
	EquipItem     = { maxPerSecond = 2,  penalty = "throttle" },
	UnequipItem   = { maxPerSecond = 2,  penalty = "throttle" },
	SellItem      = { maxPerSecond = 2,  penalty = "throttle" },
	EnterRanked   = { maxPerSecond = 0.1, penalty = "throttle" }, -- 1 per 10 seconds
	StartJob      = { maxPerSecond = 1,  penalty = "throttle" },
	CancelJob     = { maxPerSecond = 1,  penalty = "throttle" },
}

-- Punishment thresholds
local WARNING_THRESHOLD = 3     -- violations in 1 minute -> throttle 30s
local KICK_THRESHOLD = 10       -- violations in 5 minutes -> kick
local TEMP_BAN_THRESHOLD = 3    -- repeated kicks across sessions -> 24h ban

function AntiCheatService.new()
	local self = setmetatable({}, AntiCheatService)
	self._timestamps = {}   -- userId -> { remoteName -> { timestamps } }
	self._violations = {}   -- userId -> { count, firstViolationAt }
	self._throttled = {}    -- userId -> throttleEndTime
	self._kickCounts = {}   -- userId -> session kick count
	self._auditLog = {}     -- array of audit entries (in-memory buffer)
	return self
end

--- Initialize tracking for a player.
--- @param userId number
function AntiCheatService:initPlayer(userId)
	self._timestamps[userId] = {}
	self._violations[userId] = { count = 0, firstViolationAt = 0 }
	self._throttled[userId] = 0
	self._kickCounts[userId] = 0
end

--- Clean up when player leaves.
--- @param userId number
function AntiCheatService:removePlayer(userId)
	self._timestamps[userId] = nil
	self._violations[userId] = nil
	self._throttled[userId] = nil
	self._kickCounts[userId] = nil
end

--- Check rate limit for a remote call. Returns true if allowed.
--- @param userId number
--- @param remoteName string
--- @return boolean allowed, string? reason
function AntiCheatService:checkRateLimit(userId, remoteName)
	local now = os.clock()

	-- Check if player is throttled
	if self._throttled[userId] and now < self._throttled[userId] then
		return false, "Throttled"
	end

	local limit = RATE_LIMITS[remoteName]
	if not limit then
		return true, nil -- no rate limit defined
	end

	-- Initialize timestamp tracking
	if not self._timestamps[userId] then
		self._timestamps[userId] = {}
	end
	if not self._timestamps[userId][remoteName] then
		self._timestamps[userId][remoteName] = {}
	end

	local timestamps = self._timestamps[userId][remoteName]

	-- Remove timestamps older than 1 second
	local cutoff = now - 1.0
	local newTimestamps = {}
	for _, ts in ipairs(timestamps) do
		if ts > cutoff then
			newTimestamps[#newTimestamps + 1] = ts
		end
	end

	-- Check if over limit
	if #newTimestamps >= limit.maxPerSecond then
		self:_recordViolation(userId, remoteName)
		return false, "Rate limited"
	end

	-- Record this call
	newTimestamps[#newTimestamps + 1] = now
	self._timestamps[userId][remoteName] = newTimestamps

	return true, nil
end

--- Record a violation and apply punishment if thresholds met.
--- @param userId number
--- @param remoteName string
function AntiCheatService:_recordViolation(userId, remoteName)
	local now = os.clock()
	local v = self._violations[userId]
	if not v then return end

	-- Reset counter if first violation was more than 5 minutes ago
	if v.firstViolationAt > 0 and (now - v.firstViolationAt) > 300 then
		v.count = 0
		v.firstViolationAt = now
	end

	if v.count == 0 then
		v.firstViolationAt = now
	end
	v.count = v.count + 1

	-- Log the violation
	self:_addAuditEntry(userId, remoteName, "violation", "Rate limit exceeded")

	-- Check punishment tiers
	if v.count >= KICK_THRESHOLD then
		self._kickCounts[userId] = (self._kickCounts[userId] or 0) + 1
		self:_addAuditEntry(userId, remoteName, "kick", "Exceeded " .. KICK_THRESHOLD .. " violations")
		-- The caller should handle the actual kick
		v.count = 0
	elseif v.count >= WARNING_THRESHOLD then
		-- Throttle for 30 seconds
		self._throttled[userId] = now + 30
		self:_addAuditEntry(userId, remoteName, "throttle", "30 second throttle applied")
	end
end

--- Check if a player should be kicked (call after checkRateLimit returns false).
--- @param userId number
--- @return boolean shouldKick
function AntiCheatService:shouldKick(userId)
	local v = self._violations[userId]
	return v and v.count >= KICK_THRESHOLD
end

--- Check if a player should be temp banned.
--- @param userId number
--- @return boolean shouldBan
function AntiCheatService:shouldTempBan(userId)
	return (self._kickCounts[userId] or 0) >= TEMP_BAN_THRESHOLD
end

--- Validate that a coin change is sane (economic sanity check).
--- @param userId number
--- @param coinBefore number
--- @param coinAfter number
--- @param maxExpectedGain number
--- @return boolean valid, string? reason
function AntiCheatService:validateCoinChange(userId, coinBefore, coinAfter, maxExpectedGain)
	local gain = coinAfter - coinBefore
	if gain < 0 then return true end -- spending is fine
	if gain > maxExpectedGain * 3 then
		self:_addAuditEntry(userId, "economy", "flag", "Coin gain " .. gain .. " exceeds max " .. maxExpectedGain * 3)
		return false, "Abnormal coin gain detected"
	end
	return true, nil
end

--- Validate that a value is not negative (negative balance protection).
--- @param value number
--- @return boolean valid
function AntiCheatService:validateNotNegative(value)
	return value >= 0
end

--- Add an audit log entry.
--- @param userId number
--- @param remoteName string
--- @param action string
--- @param detail string
function AntiCheatService:_addAuditEntry(userId, remoteName, action, detail)
	local entry = {
		userId = userId,
		remoteName = remoteName,
		action = action,
		detail = detail,
		timestamp = os.time(),
	}
	self._auditLog[#self._auditLog + 1] = entry

	-- Keep audit log from growing unbounded (keep last 1000 entries)
	if #self._auditLog > 1000 then
		local trimmed = {}
		for i = #self._auditLog - 999, #self._auditLog do
			trimmed[#trimmed + 1] = self._auditLog[i]
		end
		self._auditLog = trimmed
	end
end

--- Get recent audit entries for a player.
--- @param userId number
--- @param limit number?
--- @return table entries
function AntiCheatService:getAuditLog(userId, limit)
	limit = limit or 50
	local result = {}
	for i = #self._auditLog, 1, -1 do
		if self._auditLog[i].userId == userId then
			result[#result + 1] = self._auditLog[i]
			if #result >= limit then break end
		end
	end
	return result
end

return AntiCheatService
