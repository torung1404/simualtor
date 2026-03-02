--[[
	UIController.lua
	Manages all UI state and transitions on the client.
	Event-driven: UI subscribes to state changes, never polls.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)

local UIController = {}
UIController.__index = UIController

-- Tab definitions with unlock requirements
local TAB_DEFINITIONS = {
	{ id = "combat",  name = "Combat",  icon = "rbxassetid://0", defaultUnlocked = true },
	{ id = "items",   name = "Items",   icon = "rbxassetid://0", defaultUnlocked = false },
	{ id = "jobs",    name = "Jobs",    icon = "rbxassetid://0", defaultUnlocked = false },
	{ id = "home",    name = "Home",    icon = "rbxassetid://0", defaultUnlocked = true },
	{ id = "train",   name = "Train",   icon = "rbxassetid://0", defaultUnlocked = false },
	{ id = "fish",    name = "Fish",    icon = "rbxassetid://0", defaultUnlocked = false },
	{ id = "ranked",  name = "Ranked",  icon = "rbxassetid://0", defaultUnlocked = false },
}

-- Color palette (dark theme)
UIController.Colors = {
	Background   = Color3.fromHex("#0B0F14"),
	Surface      = Color3.fromHex("#141A22"),
	SurfaceAlt   = Color3.fromHex("#1A2230"),
	TextPrimary  = Color3.fromHex("#E7EDF5"),
	TextSecondary= Color3.fromHex("#AAB4C0"),
	Accent       = Color3.fromHex("#F0B45A"),
	CTADanger    = Color3.fromHex("#E16B6B"),
	Success      = Color3.fromHex("#5FD28C"),
	Info         = Color3.fromHex("#6EA0FF"),
}

function UIController.new()
	local self = setmetatable({}, UIController)
	self._currentTab = "combat"
	self._unlockedTabs = { combat = true }
	self._listeners = {} -- event -> { callbacks }
	self._playerState = nil
	self._isMobile = false
	return self
end

--- Initialize the UI controller. Call once from client init.
function UIController:init()
	-- Detect platform
	local UserInputService = game:GetService("UserInputService")
	self._isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

	-- Request initial state from server
	local remoteFolder = ReplicatedStorage:WaitForChild("AnimeSimRemotes")
	local requestState = remoteFolder:WaitForChild(RemoteNames.RequestState)

	local response = requestState:InvokeServer()
	if response and response.ok then
		self._playerState = response.data
		-- Set up unlocked tabs
		if response.data.progress and response.data.progress.unlockedTabs then
			for _, tabId in ipairs(response.data.progress.unlockedTabs) do
				self._unlockedTabs[tabId] = true
			end
		end
		self:_fireEvent("stateLoaded", self._playerState)
	end

	-- Listen for state updates from server
	local stateUpdateEvent = remoteFolder:WaitForChild(RemoteNames.StateUpdate)
	stateUpdateEvent.OnClientEvent:Connect(function(update)
		self:_handleStateUpdate(update)
	end)

	-- Listen for notifications
	local notificationEvent = remoteFolder:WaitForChild(RemoteNames.Notification)
	notificationEvent.OnClientEvent:Connect(function(notification)
		self:_fireEvent("notification", notification)
	end)
end

--- Switch to a tab.
--- @param tabId string
--- @return boolean success
function UIController:switchTab(tabId)
	if not self._unlockedTabs[tabId] then
		return false
	end
	local previousTab = self._currentTab
	self._currentTab = tabId
	self:_fireEvent("tabChanged", { from = previousTab, to = tabId })
	return true
end

--- Get the current active tab.
--- @return string tabId
function UIController:getCurrentTab()
	return self._currentTab
end

--- Get all tab definitions with unlock state.
--- @return table[] tabs
function UIController:getTabs()
	local result = {}
	for _, tab in ipairs(TAB_DEFINITIONS) do
		result[#result + 1] = {
			id = tab.id,
			name = tab.name,
			icon = tab.icon,
			unlocked = self._unlockedTabs[tab.id] or false,
		}
	end
	return result
end

--- Unlock a tab (called when tutorial or milestone unlocks it).
--- @param tabId string
function UIController:unlockTab(tabId)
	if not self._unlockedTabs[tabId] then
		self._unlockedTabs[tabId] = true
		self:_fireEvent("tabUnlocked", { tabId = tabId })
	end
end

--- Check if running on mobile.
--- @return boolean
function UIController:isMobile()
	return self._isMobile
end

--- Get the current player state.
--- @return table?
function UIController:getPlayerState()
	return self._playerState
end

--- Subscribe to a UI event.
--- @param event string
--- @param callback function
function UIController:on(event, callback)
	if not self._listeners[event] then
		self._listeners[event] = {}
	end
	self._listeners[event][#self._listeners[event] + 1] = callback
end

--- Fire a UI event to all listeners.
--- @param event string
--- @param data any
function UIController:_fireEvent(event, data)
	local listeners = self._listeners[event]
	if listeners then
		for _, callback in ipairs(listeners) do
			task.spawn(callback, data)
		end
	end
end

--- Handle state update from server.
--- @param update table
function UIController:_handleStateUpdate(update)
	if not self._playerState then
		self._playerState = update
	else
		-- Merge updated fields
		for key, value in pairs(update) do
			self._playerState[key] = value
		end
	end
	self:_fireEvent("stateUpdated", update)
end

--- Get the layout mode based on platform.
--- @return string "pc" or "mobile"
function UIController:getLayoutMode()
	if self._isMobile then
		return "mobile"
	end
	return "pc"
end

--- Get the recommended next action for the "Next Step" indicator.
--- @return table? { text, action, tabId }
function UIController:getNextStepHint()
	if not self._playerState then return nil end

	local progress = self._playerState.progress
	local tutorial = self._playerState.tutorial

	-- If in tutorial, show tutorial step
	if tutorial and not tutorial.isComplete then
		return {
			text = tutorial.description,
			action = "tutorial",
			tabId = "combat",
		}
	end

	-- Simple heuristic for next step
	local wallet = self._playerState.wallet
	if wallet and wallet.coin > 0 then
		-- Suggest buying cheapest available upgrade
		return {
			text = "Buy your next upgrade",
			action = "buyUpgrade",
			tabId = "combat",
		}
	end

	return {
		text = "Fight enemies to earn coins",
		action = "fight",
		tabId = "combat",
	}
end

return UIController
