--[[
	TutorialService.lua
	Tracks and validates tutorial progress.
	The tutorial is a 6-step guided experience completable in under 10 minutes.
]]

local TutorialService = {}
TutorialService.__index = TutorialService

-- Tutorial step definitions
local TUTORIAL_STEPS = {
	{
		step = 1,
		action = "fight_3_times",
		description = "Fight an enemy 3 times",
		teaches = "Core combat loop",
		requirement = { type = "fights", count = 3 },
	},
	{
		step = 2,
		action = "buy_damage_upgrade",
		description = "Buy 1 Damage upgrade",
		teaches = "Upgrade system, seeing DPS increase",
		requirement = { type = "upgrade", category = "damage", count = 1 },
	},
	{
		step = 3,
		action = "open_jobs_claim",
		description = "Open Jobs tab and claim first reward",
		teaches = "Passive income",
		requirement = { type = "jobClaim", count = 1 },
		unlocks = { tab = "jobs" },
	},
	{
		step = 4,
		action = "defeat_boss",
		description = "Defeat the first Boss",
		teaches = "Boss mechanic, loot drops",
		requirement = { type = "bossKill", count = 1 },
	},
	{
		step = 5,
		action = "equip_item",
		description = "Open Items tab and equip a Shard",
		teaches = "Inventory and equipment",
		requirement = { type = "equip", count = 1 },
		unlocks = { tab = "items" },
	},
	{
		step = 6,
		action = "show_next_step",
		description = "See the Next Step indicator pointing to Arc 2",
		teaches = "Long-term goal",
		requirement = { type = "acknowledge" },
	},
}

--- Create a new TutorialService.
--- @param playerDataService PlayerDataService
--- @param stateMachine PlayerStateMachine
--- @return TutorialService
function TutorialService.new(playerDataService, stateMachine)
	local self = setmetatable({}, TutorialService)
	self._playerData = playerDataService
	self._stateMachine = stateMachine
	self._stepProgress = {} -- userId -> { stepActionCounts }
	return self
end

--- Initialize tutorial tracking for a player.
--- @param userId number
function TutorialService:initPlayer(userId)
	local data = self._playerData:getData(userId)
	if not data then return end

	self._stepProgress[userId] = {
		fights = 0,
		upgrades = 0,
		jobClaims = 0,
		bossKills = 0,
		equips = 0,
	}

	-- If tutorial is already complete, do nothing
	if data.progress.tutorialComplete then
		return
	end

	-- Set state machine to tutorial if needed
	if data.progress.tutorialStep <= #TUTORIAL_STEPS then
		self._stateMachine:transition(userId, "InTutorial")
	end
end

--- Record a player action that may advance the tutorial.
--- @param userId number
--- @param actionType string ("fight", "upgrade", "jobClaim", "bossKill", "equip", "acknowledge")
--- @param details table? Optional details (e.g., { category = "damage" })
--- @return table? { advanced = bool, newStep = number?, unlocks = table?, completed = bool? }
function TutorialService:recordAction(userId, actionType, details)
	local data = self._playerData:getData(userId)
	if not data or data.progress.tutorialComplete then
		return nil
	end

	local currentStep = data.progress.tutorialStep
	if currentStep > #TUTORIAL_STEPS then
		return nil
	end

	local stepDef = TUTORIAL_STEPS[currentStep]
	local progress = self._stepProgress[userId]
	if not progress then return nil end

	-- Track the action
	if actionType == "fight" then
		progress.fights = progress.fights + 1
	elseif actionType == "upgrade" then
		progress.upgrades = progress.upgrades + 1
	elseif actionType == "jobClaim" then
		progress.jobClaims = progress.jobClaims + 1
	elseif actionType == "bossKill" then
		progress.bossKills = progress.bossKills + 1
	elseif actionType == "equip" then
		progress.equips = progress.equips + 1
	end

	-- Check if current step requirement is met
	local met = false
	local req = stepDef.requirement

	if req.type == "fights" and progress.fights >= req.count then
		met = true
	elseif req.type == "upgrade" and progress.upgrades >= req.count then
		if details and details.category then
			met = details.category == req.category
		else
			met = true
		end
	elseif req.type == "jobClaim" and progress.jobClaims >= req.count then
		met = true
	elseif req.type == "bossKill" and progress.bossKills >= req.count then
		met = true
	elseif req.type == "equip" and progress.equips >= req.count then
		met = true
	elseif req.type == "acknowledge" and actionType == "acknowledge" then
		met = true
	end

	if not met then
		return { advanced = false }
	end

	-- Advance to next step
	data.progress.tutorialStep = currentStep + 1

	-- Apply unlocks
	local unlocks = stepDef.unlocks
	if unlocks and unlocks.tab then
		local tabs = data.progress.unlockedTabs
		local found = false
		for _, t in ipairs(tabs) do
			if t == unlocks.tab then
				found = true
				break
			end
		end
		if not found then
			tabs[#tabs + 1] = unlocks.tab
		end
	end

	-- Reset step-specific counters for new step
	progress.fights = 0
	progress.upgrades = 0
	progress.jobClaims = 0
	progress.bossKills = 0
	progress.equips = 0

	-- Check if tutorial is now complete
	local completed = data.progress.tutorialStep > #TUTORIAL_STEPS
	if completed then
		data.progress.tutorialComplete = true
		self._stateMachine:transition(userId, "InMenu")
	end

	self._playerData:markDirty(userId)

	return {
		advanced = true,
		newStep = data.progress.tutorialStep,
		unlocks = unlocks,
		completed = completed,
	}
end

--- Skip the tutorial entirely.
--- @param userId number
--- @return table { ok, data? }
function TutorialService:skipTutorial(userId)
	local data = self._playerData:getData(userId)
	if not data then
		return { ok = false, error = "Player data not found" }
	end

	data.progress.tutorialComplete = true
	data.progress.tutorialStep = #TUTORIAL_STEPS + 1

	-- Unlock all tutorial-gated tabs
	local allTabs = { "combat", "jobs", "items" }
	data.progress.unlockedTabs = allTabs

	self._stateMachine:transition(userId, "InMenu")
	self._playerData:markDirty(userId)

	return {
		ok = true,
		data = { skipped = true, unlockedTabs = allTabs },
	}
end

--- Get current tutorial state for UI display.
--- @param userId number
--- @return table? { step, description, teaches, isComplete }
function TutorialService:getTutorialState(userId)
	local data = self._playerData:getData(userId)
	if not data then return nil end

	if data.progress.tutorialComplete then
		return { isComplete = true }
	end

	local currentStep = data.progress.tutorialStep
	if currentStep > #TUTORIAL_STEPS then
		return { isComplete = true }
	end

	local stepDef = TUTORIAL_STEPS[currentStep]
	return {
		step = currentStep,
		totalSteps = #TUTORIAL_STEPS,
		description = stepDef.description,
		teaches = stepDef.teaches,
		isComplete = false,
	}
end

--- Clean up.
--- @param userId number
function TutorialService:removePlayer(userId)
	self._stepProgress[userId] = nil
end

-- Expose steps for reference
TutorialService.STEPS = TUTORIAL_STEPS

return TutorialService
