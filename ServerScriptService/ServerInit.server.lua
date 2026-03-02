--[[
	ServerInit.lua
	Main server entry point. Wires up all services, handlers, and remotes.
	This script runs once when the server starts.
]]

-- Services (Roblox)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")

-- Shared modules
local RemoteNames = require(ReplicatedStorage.Shared.NetSchema.RemoteNames)
local ItemsConfig = require(ReplicatedStorage.Shared.Configs.ItemsConfig)

-- Server services
local PlayerDataService = require(script.Parent.Services.PlayerDataService)
local PlayerStateMachine = require(script.Parent.Services.PlayerStateMachine)
local AntiCheatService = require(script.Parent.Services.AntiCheatService)
local EconomyService = require(script.Parent.Services.EconomyService)
local CombatService = require(script.Parent.Services.CombatService)
local UpgradeService = require(script.Parent.Services.UpgradeService)
local JobService = require(script.Parent.Services.JobService)
local TutorialService = require(script.Parent.Services.TutorialService)
local RankService = require(script.Parent.Services.RankService)
local DailyQuestService = require(script.Parent.Services.DailyQuestService)
local LoginStreakService = require(script.Parent.Services.LoginStreakService)
local NotificationService = require(script.Parent.Services.NotificationService)

-- Remote handlers
local CombatHandler = require(script.Parent.RemoteHandlers.CombatHandler)
local EconomyHandler = require(script.Parent.RemoteHandlers.EconomyHandler)
local JobHandler = require(script.Parent.RemoteHandlers.JobHandler)
local RankHandler = require(script.Parent.RemoteHandlers.RankHandler)
local DailyQuestHandler = require(script.Parent.RemoteHandlers.DailyQuestHandler)

------------------------------------------------------------------------
-- 1. Instantiate services with dependency injection
------------------------------------------------------------------------
local playerData = PlayerDataService.new(DataStoreService, MemoryStoreService)
local stateMachine = PlayerStateMachine.new()
local antiCheat = AntiCheatService.new()
local economy = EconomyService.new(playerData, antiCheat)
local combat = CombatService.new(playerData, economy, stateMachine)
local upgrade = UpgradeService.new(playerData, economy)
local job = JobService.new(playerData, economy, stateMachine)
local tutorial = TutorialService.new(playerData, stateMachine)
local rank = RankService.new(playerData, economy, combat, stateMachine)
local dailyQuest = DailyQuestService.new(playerData, economy)
local loginStreak = LoginStreakService.new(playerData, economy)

-- Instantiate handlers
local combatHandler = CombatHandler.new(combat, antiCheat, tutorial)
local economyHandler = EconomyHandler.new(upgrade, economy, playerData, antiCheat, tutorial)
local jobHandler = JobHandler.new(job, antiCheat, tutorial)
local rankHandler = RankHandler.new(rank, antiCheat)
local dailyQuestHandler = DailyQuestHandler.new(dailyQuest, loginStreak, antiCheat)

------------------------------------------------------------------------
-- 2. Create RemoteEvents and RemoteFunctions
------------------------------------------------------------------------
local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "AnimeSimRemotes"
remoteFolder.Parent = ReplicatedStorage

local function createRemoteFunction(name)
	local rf = Instance.new("RemoteFunction")
	rf.Name = name
	rf.Parent = remoteFolder
	return rf
end

local function createRemoteEvent(name)
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = remoteFolder
	return re
end

-- Create all remotes
local fightRemote = createRemoteFunction(RemoteNames.Fight)
local buyUpgradeRemote = createRemoteFunction(RemoteNames.BuyUpgrade)
local sellItemRemote = createRemoteFunction(RemoteNames.SellItem)
local equipItemRemote = createRemoteFunction(RemoteNames.EquipItem)
local unequipItemRemote = createRemoteFunction(RemoteNames.UnequipItem)
local startJobRemote = createRemoteFunction(RemoteNames.StartJob)
local claimJobRemote = createRemoteFunction(RemoteNames.ClaimJob)
local cancelJobRemote = createRemoteFunction(RemoteNames.CancelJob)
local enterRankedRemote = createRemoteFunction(RemoteNames.EnterRanked)
local claimSeasonRewardRemote = createRemoteFunction(RemoteNames.ClaimSeasonReward)
local requestStateRemote = createRemoteFunction(RemoteNames.RequestState)
local tutorialAdvanceRemote = createRemoteFunction(RemoteNames.TutorialAdvance)
local tutorialSkipRemote = createRemoteFunction(RemoteNames.TutorialSkip)
local updateSettingsRemote = createRemoteFunction(RemoteNames.UpdateSettings)
local getDailyQuestsRemote = createRemoteFunction(RemoteNames.GetDailyQuests)
local claimDailyQuestRemote = createRemoteFunction(RemoteNames.ClaimDailyQuest)
local getLoginStatusRemote = createRemoteFunction(RemoteNames.GetLoginStatus)

-- Events (server -> client)
local stateUpdateEvent = createRemoteEvent(RemoteNames.StateUpdate)
local notificationEvent = createRemoteEvent(RemoteNames.Notification)
local rareDropEvent = createRemoteEvent(RemoteNames.RareDropAnnounce)

-- Initialize notification service with remote references
local notification = NotificationService.new(remoteFolder)
notification:init(stateUpdateEvent, notificationEvent, rareDropEvent)

------------------------------------------------------------------------
-- 3. Wire up RemoteFunction callbacks
------------------------------------------------------------------------
fightRemote.OnServerInvoke = function(player, payload)
	local result = combatHandler:handleFight(player.UserId, payload)

	-- Fire notifications for combat results
	if result.ok and result.data then
		local fightData = result.data

		-- Track daily quest progress
		if fightData.won then
			dailyQuest:recordAction(player.UserId, "kills", 1)
			dailyQuest:recordAction(player.UserId, "coinEarned", fightData.rewards and fightData.rewards.coin or 0)

			-- Announce rare drops
			if fightData.drops then
				for _, drop in ipairs(fightData.drops) do
					if drop.rarity == "epic" or drop.rarity == "legendary" then
						notification:announceRareDrop(
							player.UserId,
							player.Name,
							drop.name or drop.itemId,
							drop.rarity,
							fightData.enemyName
						)
					end
				end
			end

			-- Boss kill daily quest tracking
			if fightData.bossInfo then
				dailyQuest:recordAction(player.UserId, "bossKill", 1)
			end

			-- Arc unlock notification
			if fightData.arcUnlocked then
				notification:sendArcUnlock(player.UserId, fightData.arcUnlocked.arcName)
				notification:sendStateUpdate(player.UserId, {
					progress = playerData:getData(player.UserId).progress,
				})
			end
		end
	end

	return result
end

buyUpgradeRemote.OnServerInvoke = function(player, payload)
	local result = economyHandler:handleBuyUpgrade(player.UserId, payload)

	-- Track daily quest progress
	if result.ok then
		dailyQuest:recordAction(player.UserId, "upgrades", 1)
	end

	return result
end

sellItemRemote.OnServerInvoke = function(player, payload)
	return economyHandler:handleSellItem(player.UserId, payload)
end

equipItemRemote.OnServerInvoke = function(player, payload)
	return economyHandler:handleEquipItem(player.UserId, payload)
end

unequipItemRemote.OnServerInvoke = function(player, payload)
	return economyHandler:handleUnequipItem(player.UserId, payload)
end

startJobRemote.OnServerInvoke = function(player, payload)
	return jobHandler:handleStartJob(player.UserId, payload)
end

claimJobRemote.OnServerInvoke = function(player)
	local result = jobHandler:handleClaimJob(player.UserId)

	-- Track daily quest progress
	if result.ok then
		dailyQuest:recordAction(player.UserId, "jobClaims", 1)
		if result.data and result.data.reward then
			dailyQuest:recordAction(player.UserId, "coinEarned", result.data.reward)
		end
	end

	return result
end

cancelJobRemote.OnServerInvoke = function(player)
	return jobHandler:handleCancelJob(player.UserId)
end

enterRankedRemote.OnServerInvoke = function(player)
	local result = rankHandler:handleEnterRanked(player.UserId)

	-- Track daily quest progress
	if result.ok then
		dailyQuest:recordAction(player.UserId, "ranked", 1)
	end

	return result
end

claimSeasonRewardRemote.OnServerInvoke = function(player, payload)
	return rankHandler:handleClaimSeasonReward(player.UserId, payload)
end

requestStateRemote.OnServerInvoke = function(player)
	local data = playerData:getData(player.UserId)
	if not data then return { ok = false, error = "Data not loaded" } end
	return {
		ok = true,
		data = {
			wallet = data.wallet,
			progress = data.progress,
			upgrades = data.upgrades,
			inventory = data.inventory,
			jobs = data.jobs,
			stats = data.stats,
			season = data.season,
			settings = data.settings,
			tutorial = tutorial:getTutorialState(player.UserId),
			jobStatus = job:getJobStatus(player.UserId),
			ranked = rank:getRankedStatus(player.UserId),
			dailyQuests = dailyQuest:getQuestStatus(player.UserId),
			loginStatus = loginStreak:getLoginStatus(player.UserId),
		},
	}
end

tutorialAdvanceRemote.OnServerInvoke = function(player, payload)
	local actionType = type(payload) == "table" and payload.actionType or "acknowledge"
	local result = tutorial:recordAction(player.UserId, actionType, payload)
	return { ok = true, data = result }
end

tutorialSkipRemote.OnServerInvoke = function(player)
	return tutorial:skipTutorial(player.UserId)
end

updateSettingsRemote.OnServerInvoke = function(player, payload)
	local PayloadTypes = require(ReplicatedStorage.Shared.NetSchema.PayloadTypes)
	local valid, err = PayloadTypes.validateSettings(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end
	local data = playerData:getData(player.UserId)
	if not data then
		return PayloadTypes.response(false, nil, "Data not loaded")
	end
	for k, v in pairs(payload) do
		data.settings[k] = v
	end
	playerData:markDirty(player.UserId)
	return PayloadTypes.response(true, data.settings)
end

getDailyQuestsRemote.OnServerInvoke = function(player)
	return dailyQuestHandler:handleGetDailyQuests(player.UserId)
end

claimDailyQuestRemote.OnServerInvoke = function(player, payload)
	local result = dailyQuestHandler:handleClaimDailyQuest(player.UserId, payload)

	-- Send notification on quest claim
	if result.ok and result.data then
		notification:sendRewardNotification(player.UserId, "Daily Quest Reward", {
			coin = result.data.rewardCoin,
			points = result.data.rewardPoints,
		})
	end

	return result
end

getLoginStatusRemote.OnServerInvoke = function(player)
	return dailyQuestHandler:handleGetLoginStatus(player.UserId)
end

------------------------------------------------------------------------
-- 4. Player lifecycle
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local data = playerData:loadData(player.UserId)
	if not data then
		player:Kick("Failed to load player data. Please try again.")
		return
	end

	antiCheat:initPlayer(player.UserId)
	stateMachine:initPlayer(player.UserId, not data.progress.tutorialComplete)
	tutorial:initPlayer(player.UserId)
	dailyQuest:initPlayer(player.UserId)

	-- Process login streak and send notifications
	local loginResult = loginStreak:processLogin(player.UserId)
	if loginResult.isNewDay then
		-- Send login streak notification
		task.defer(function()
			task.wait(2) -- small delay so client is ready

			if loginResult.welcomeBack then
				notification:sendWelcomeBack(
					player.UserId,
					loginResult.welcomeBack.daysAway,
					loginResult.welcomeBack
				)
			end

			if loginResult.reward then
				notification:sendLoginStreak(player.UserId, loginResult.streakDay, loginResult.reward)
			else
				notification:sendLoginStreak(player.UserId, loginResult.streakDay, nil)
			end

			-- Send initial state update with all data
			notification:sendStateUpdate(player.UserId, {
				wallet = data.wallet,
				dailyQuests = dailyQuest:getQuestStatus(player.UserId),
				loginStatus = loginStreak:getLoginStatus(player.UserId),
			})
		end)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerData:onPlayerLeave(player.UserId)
	antiCheat:removePlayer(player.UserId)
	stateMachine:removePlayer(player.UserId)
	tutorial:removePlayer(player.UserId)
	job:removePlayer(player.UserId)
	dailyQuest:removePlayer(player.UserId)
	loginStreak:removePlayer(player.UserId)
end)

------------------------------------------------------------------------
-- 5. Start background systems
------------------------------------------------------------------------
playerData:startSaveLoop()
playerData:bindToClose()

print("[AnimeSimulator] Server initialized successfully.")
print("[AnimeSimulator] Services: PlayerData, StateMachine, AntiCheat, Economy, Combat, Upgrade, Job, Tutorial, Rank, DailyQuest, LoginStreak, Notification")
