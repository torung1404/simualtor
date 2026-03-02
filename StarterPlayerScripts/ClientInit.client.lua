--[[
	ClientInit.lua
	Main client entry point. Initializes all controllers and view models.
]]

local Controllers = script.Parent.Controllers
local ViewModels = script.Parent.ViewModels

-- Controllers
local UIController = require(Controllers.UIController)
local CombatViewController = require(Controllers.CombatViewController)
local JobViewController = require(Controllers.JobViewController)
local UpgradeViewController = require(Controllers.UpgradeViewController)
local TutorialController = require(Controllers.TutorialController)
local SoundController = require(Controllers.SoundController)

-- View Models
local PlayerViewModel = require(ViewModels.PlayerViewModel)
local EnemyViewModel = require(ViewModels.EnemyViewModel)

------------------------------------------------------------------------
-- Initialize in correct order
------------------------------------------------------------------------

-- 1. Core UI controller first
local ui = UIController.new()
ui:init()

-- 2. View controllers (depend on UI controller)
local combatView = CombatViewController.new(ui)
combatView:init()

local jobView = JobViewController.new(ui)
jobView:init()

local upgradeView = UpgradeViewController.new(ui)
upgradeView:init()

-- 3. Tutorial controller
local tutorialCtrl = TutorialController.new(ui)
tutorialCtrl:init()

-- 4. Sound controller
local soundCtrl = SoundController.new(ui)
soundCtrl:init()

-- 5. View models
local playerVM = PlayerViewModel.new(ui)
local enemyVM = EnemyViewModel.new()

------------------------------------------------------------------------
-- Log initialization
------------------------------------------------------------------------
print("[AnimeSimulator] Client initialized successfully.")
print("[AnimeSimulator] Layout mode: " .. ui:getLayoutMode())
print("[AnimeSimulator] Tutorial active: " .. tostring(tutorialCtrl:isActive()))

------------------------------------------------------------------------
-- Expose for other client scripts if needed
------------------------------------------------------------------------
local ClientAPI = {
	UI = ui,
	CombatView = combatView,
	JobView = jobView,
	UpgradeView = upgradeView,
	Tutorial = tutorialCtrl,
	Sound = soundCtrl,
	PlayerVM = playerVM,
	EnemyVM = enemyVM,
}

return ClientAPI
