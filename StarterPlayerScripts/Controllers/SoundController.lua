--[[
	SoundController.lua
	Handles SFX triggers based on game events.
	Respects player settings for sfx/music enabled.
]]

local SoundController = {}
SoundController.__index = SoundController

-- Sound definitions mapped to game events
local SOUNDS = {
	fightWin     = { id = "rbxassetid://0", volume = 0.5 },
	fightLose    = { id = "rbxassetid://0", volume = 0.5 },
	upgradeBuy   = { id = "rbxassetid://0", volume = 0.4 },
	bossDefeated = { id = "rbxassetid://0", volume = 0.7 },
	arcUnlocked  = { id = "rbxassetid://0", volume = 0.6 },
	itemDrop     = { id = "rbxassetid://0", volume = 0.5 },
	jobClaim     = { id = "rbxassetid://0", volume = 0.4 },
	tierUp       = { id = "rbxassetid://0", volume = 0.7 },
	tabUnlock    = { id = "rbxassetid://0", volume = 0.5 },
}

--- Create a new SoundController.
--- @param uiController UIController
--- @return SoundController
function SoundController.new(uiController)
	local self = setmetatable({}, SoundController)
	self._ui = uiController
	self._sfxEnabled = true
	self._soundInstances = {}
	return self
end

--- Initialize: wire up event listeners.
function SoundController:init()
	-- Read settings
	local state = self._ui:getPlayerState()
	if state and state.settings then
		self._sfxEnabled = state.settings.sfxEnabled ~= false
	end

	-- Wire up game events
	self._ui:on("fightResult", function(data)
		if data.won then
			if data.bossDefeated then
				self:play("bossDefeated")
			else
				self:play("fightWin")
			end
		else
			self:play("fightLose")
		end
	end)

	self._ui:on("upgradeBought", function()
		self:play("upgradeBuy")
	end)

	self._ui:on("jobClaimed", function()
		self:play("jobClaim")
	end)

	self._ui:on("tabUnlocked", function()
		self:play("tabUnlock")
	end)

	self._ui:on("stateUpdated", function(update)
		if update.settings then
			self._sfxEnabled = update.settings.sfxEnabled ~= false
		end
	end)
end

--- Play a sound by name.
--- @param soundName string
function SoundController:play(soundName)
	if not self._sfxEnabled then return end

	local soundDef = SOUNDS[soundName]
	if not soundDef then return end

	-- Create or reuse sound instance
	local sound = self._soundInstances[soundName]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = soundDef.id
		sound.Volume = soundDef.volume
		sound.Parent = game:GetService("SoundService")
		self._soundInstances[soundName] = sound
	end

	sound:Play()
end

--- Toggle SFX on/off.
--- @param enabled boolean
function SoundController:setSFXEnabled(enabled)
	self._sfxEnabled = enabled
end

return SoundController
