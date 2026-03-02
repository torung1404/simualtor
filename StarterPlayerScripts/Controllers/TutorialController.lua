--[[
	TutorialController.lua
	Drives the tutorial overlay on the client.
	Overlay-style tutorial highlighting exactly one button at a time.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)

local TutorialController = {}
TutorialController.__index = TutorialController

--- Create a new TutorialController.
--- @param uiController UIController
--- @return TutorialController
function TutorialController.new(uiController)
	local self = setmetatable({}, TutorialController)
	self._ui = uiController
	self._isActive = false
	self._currentStep = nil
	self._remoteFolder = nil
	return self
end

--- Initialize the tutorial controller.
function TutorialController:init()
	self._remoteFolder = ReplicatedStorage:WaitForChild("AnimeSimRemotes")

	local state = self._ui:getPlayerState()
	if state and state.tutorial and not state.tutorial.isComplete then
		self._isActive = true
		self._currentStep = state.tutorial
		self._ui:_fireEvent("tutorialStepChanged", self._currentStep)
	end

	-- Listen for state updates that may include tutorial changes
	self._ui:on("stateUpdated", function(update)
		if update.tutorial then
			if update.tutorial.isComplete then
				self._isActive = false
				self._ui:_fireEvent("tutorialComplete", {})
			else
				self._currentStep = update.tutorial
				self._ui:_fireEvent("tutorialStepChanged", self._currentStep)
			end
		end
	end)
end

--- Check if the tutorial is currently active.
--- @return boolean
function TutorialController:isActive()
	return self._isActive
end

--- Get the current tutorial step data for the overlay.
--- @return table? { step, totalSteps, description, teaches, highlightTarget }
function TutorialController:getCurrentStep()
	if not self._isActive or not self._currentStep then
		return nil
	end

	-- Map step numbers to UI highlight targets
	local highlightTargets = {
		[1] = { target = "enemyList", buttonText = "Fight!" },
		[2] = { target = "upgradePanel", buttonText = "Buy Upgrade" },
		[3] = { target = "jobsTab", buttonText = "Open Jobs" },
		[4] = { target = "bossButton", buttonText = "Fight Boss!" },
		[5] = { target = "itemsTab", buttonText = "Equip Item" },
		[6] = { target = "nextStepIndicator", buttonText = "Got it!" },
	}

	local step = self._currentStep.step
	local highlight = highlightTargets[step] or {}

	return {
		step = step,
		totalSteps = self._currentStep.totalSteps,
		description = self._currentStep.description,
		teaches = self._currentStep.teaches,
		highlightTarget = highlight.target,
		buttonText = highlight.buttonText,
	}
end

--- Acknowledge the current tutorial step (for step 6 / "acknowledge" type).
--- @return table? response
function TutorialController:acknowledgeStep()
	if not self._remoteFolder then return nil end
	local remote = self._remoteFolder:FindFirstChild(RemoteNames.TutorialAdvance)
	if not remote then return nil end

	return remote:InvokeServer({ actionType = "acknowledge" })
end

--- Skip the tutorial entirely.
--- @return table? response
function TutorialController:skipTutorial()
	if not self._remoteFolder then return nil end
	local remote = self._remoteFolder:FindFirstChild(RemoteNames.TutorialSkip)
	if not remote then return nil end

	local response = remote:InvokeServer()
	if response and response.ok then
		self._isActive = false
		self._ui:_fireEvent("tutorialComplete", { skipped = true })
	end
	return response
end

return TutorialController
