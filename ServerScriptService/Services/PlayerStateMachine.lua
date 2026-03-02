--[[
	PlayerStateMachine.lua
	Manages player states: InMenu, InCombat, InJob, InRanked, InTutorial.
	Server only accepts requests valid for the current state.
]]

local PlayerStateMachine = {}
PlayerStateMachine.__index = PlayerStateMachine

-- Valid states
local States = {
	InMenu = "InMenu",
	InCombat = "InCombat",
	InJob = "InJob",
	InRanked = "InRanked",
	InTutorial = "InTutorial",
}

-- Valid transitions: from -> { allowed targets }
local TRANSITIONS = {
	[States.InMenu] = {
		States.InCombat,
		States.InJob,
		States.InRanked,
		States.InTutorial,
	},
	[States.InCombat] = {
		States.InMenu,
	},
	[States.InJob] = {
		States.InMenu,
	},
	[States.InRanked] = {
		States.InMenu,
	},
	[States.InTutorial] = {
		States.InMenu,
	},
}

-- What actions are blocked per state
local BLOCKED_ACTIONS = {
	[States.InCombat] = { "StartJob", "EnterRanked", "StartFight" },
	[States.InJob] = { "StartFight", "EnterRanked" },
	[States.InRanked] = { "StartJob", "StartFight" },
	[States.InTutorial] = { "EnterRanked" },
}

function PlayerStateMachine.new()
	local self = setmetatable({}, PlayerStateMachine)
	self._states = {} -- userId -> current state string
	return self
end

--- Initialize a player's state (call on join).
--- @param userId number
--- @param hasTutorial boolean Whether the player is in tutorial
function PlayerStateMachine:initPlayer(userId, hasTutorial)
	if hasTutorial then
		self._states[userId] = States.InTutorial
	else
		self._states[userId] = States.InMenu
	end
end

--- Get the current state for a player.
--- @param userId number
--- @return string state
function PlayerStateMachine:getState(userId)
	return self._states[userId] or States.InMenu
end

--- Check if a transition is valid.
--- @param userId number
--- @param targetState string
--- @return boolean
function PlayerStateMachine:canTransition(userId, targetState)
	local currentState = self:getState(userId)
	local allowed = TRANSITIONS[currentState]
	if not allowed then return false end

	for _, state in ipairs(allowed) do
		if state == targetState then return true end
	end
	return false
end

--- Attempt to transition to a new state. Returns true on success.
--- @param userId number
--- @param targetState string
--- @return boolean success, string? errorMessage
function PlayerStateMachine:transition(userId, targetState)
	if not self:canTransition(userId, targetState) then
		local current = self:getState(userId)
		return false, "Cannot transition from " .. current .. " to " .. targetState
	end
	self._states[userId] = targetState
	return true, nil
end

--- Check if a specific action is allowed in the current state.
--- @param userId number
--- @param actionName string (e.g., "StartFight", "StartJob", "EnterRanked")
--- @return boolean allowed, string? reason
function PlayerStateMachine:isActionAllowed(userId, actionName)
	local currentState = self:getState(userId)
	local blocked = BLOCKED_ACTIONS[currentState]
	if blocked then
		for _, blockedAction in ipairs(blocked) do
			if blockedAction == actionName then
				return false, actionName .. " is blocked while in " .. currentState
			end
		end
	end
	return true, nil
end

--- Remove a player (call on leave).
--- @param userId number
function PlayerStateMachine:removePlayer(userId)
	self._states[userId] = nil
end

-- Expose States enum
PlayerStateMachine.States = States

return PlayerStateMachine
