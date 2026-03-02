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
local DailyQuestViewController = require(Controllers.DailyQuestViewController)

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

-- 3. Daily quest view controller
local dailyQuestView = DailyQuestViewController.new(ui)
dailyQuestView:init()

-- 4. Tutorial controller
local tutorialCtrl = TutorialController.new(ui)
tutorialCtrl:init()

-- 5. Sound controller
local soundCtrl = SoundController.new(ui)
soundCtrl:init()

-- 6. View models
local playerVM = PlayerViewModel.new(ui)
local enemyVM = EnemyViewModel.new()

------------------------------------------------------------------------
-- Set up notification display handlers
------------------------------------------------------------------------
ui:on("notification", function(notif)
	if notif.type == "info" then
		print("[Notification] " .. (notif.title or "") .. ": " .. (notif.message or ""))
	elseif notif.type == "reward" then
		print("[Reward] " .. (notif.title or "") .. ": " .. (notif.message or ""))
		soundCtrl:playSound("reward")
	elseif notif.type == "achievement" then
		print("[Achievement] " .. (notif.title or "") .. ": " .. (notif.message or ""))
		soundCtrl:playSound("achievement")
	elseif notif.type == "success" then
		print("[Success] " .. (notif.title or "") .. ": " .. (notif.message or ""))
	end
end)

ui:on("rareDrop", function(dropInfo)
	print("[RARE DROP] " .. dropInfo.playerName .. " found " .. dropInfo.itemName
		.. " (" .. dropInfo.rarity .. ") from " .. dropInfo.enemyName .. "!")
	soundCtrl:playSound("rareDrop")
end)

ui:on("fightResult", function(data)
	if data.isCrit then
		print("[Combat] CRITICAL HIT!")
		soundCtrl:playSound("crit")
	end
	if data.arcUnlocked then
		print("[Progress] New arc unlocked: " .. data.arcUnlocked.arcName)
		soundCtrl:playSound("arcUnlock")
	end
end)

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
	DailyQuestView = dailyQuestView,
	Tutorial = tutorialCtrl,
	Sound = soundCtrl,
	PlayerVM = playerVM,
	EnemyVM = enemyVM,
}

return ClientAPI
