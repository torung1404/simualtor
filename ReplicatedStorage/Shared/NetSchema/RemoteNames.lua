--[[
	RemoteNames.lua
	Single source of truth for all remote event/function names.
	Both server and client reference this module to avoid string typos.
]]

local RemoteNames = {
	-- Combat
	Fight = "AnimeSimFight",
	FightResult = "AnimeSimFightResult",

	-- Upgrades / Economy
	BuyUpgrade = "AnimeSimBuyUpgrade",
	SellItem = "AnimeSimSellItem",
	EquipItem = "AnimeSimEquipItem",
	UnequipItem = "AnimeSimUnequipItem",

	-- Jobs
	StartJob = "AnimeSimStartJob",
	ClaimJob = "AnimeSimClaimJob",
	CancelJob = "AnimeSimCancelJob",

	-- Ranked
	EnterRanked = "AnimeSimEnterRanked",
	RankedResult = "AnimeSimRankedResult",

	-- Tutorial
	TutorialAdvance = "AnimeSimTutorialAdvance",
	TutorialSkip = "AnimeSimTutorialSkip",

	-- Player Data
	RequestState = "AnimeSimRequestState",
	StateUpdate = "AnimeSimStateUpdate",

	-- Daily / Season
	ClaimDailyReward = "AnimeSimClaimDailyReward",
	ClaimLoginStreak = "AnimeSimClaimLoginStreak",
	ClaimSeasonReward = "AnimeSimClaimSeasonReward",

	-- Social
	SetReferralCode = "AnimeSimSetReferralCode",
	ApplyReferral = "AnimeSimApplyReferral",

	-- Settings
	UpdateSettings = "AnimeSimUpdateSettings",

	-- Notifications (server -> client)
	Notification = "AnimeSimNotification",
	AchievementUnlock = "AnimeSimAchievementUnlock",
	RareDropAnnounce = "AnimeSimRareDropAnnounce",
}

return RemoteNames
