--!strict
-- LOCATION: src/StarterPlayerScripts/Controllers/MainScreenController.lua
-- TYPE: ModuleScript
-- PURPOSE: Framework for the top navigation bar and the 3-column flex layout container

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))
local ActionsColumnUI = require(script.Parent:WaitForChild("ActionsColumnUI"))
local WorkColumnUI = require(script.Parent:WaitForChild("WorkColumnUI"))
local UpgradeColumnUI = require(script.Parent:WaitForChild("UpgradeColumnUI"))

local MainScreenController = {}
MainScreenController.Containers = {}

function MainScreenController:Init()
	-- Create the core ScreenGui container
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")
	
	local screenGui = UIBuilder.create("ScreenGui", {
		Name = "MainScreenGui",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets, -- Avoid mobile notches
	})
	screenGui.Parent = playerGui
	
	-- Add a solid full screen background to hide the 3D world
	local backgroundApp = UIBuilder.create("Frame", {
		Name = "AppBackground",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(24, 28, 38), -- Base dark blue/grey
		BorderSizePixel = 0,
		ZIndex = -1, -- Keep it behind everything else
		Active = true, -- Block 3D world clicks
	})
	
	-- Add a premium gradient to the background
	UIBuilder.create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 36, 48)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 16, 22))
		})
	}, {backgroundApp})
	
	backgroundApp.Parent = screenGui
	
	-- Apply auto-scaling relative to Viewport size
	UIBuilder.attachResponsiveScale(screenGui)
	
	-- Create Top Navigation Bar
	self:buildTopNav(screenGui)
	
	-- Create The 3 Columns
	self:buildColumns(screenGui)
end

function MainScreenController:buildTopNav(screenGui: ScreenGui)
	local topBar = UIBuilder.panel({
		Name = "TopNav",
		Size = UDim2.new(1, -20, 0, 40),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundColor3 = Color3.fromRGB(15, 15, 18),
		BackgroundTransparency = 0.05,
	})
	
	-- Add an inner padding
	UIBuilder.create("UIPadding", {
		PaddingLeft = UDim.new(0, 20),
		PaddingRight = UDim.new(0, 20),
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
	}, {topBar})
	
	-- Beli display
	self.BeliDisplay = UIBuilder.headerText("Beli: 0", Color3.fromRGB(240, 200, 80), {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	
	-- Bounty display
	self.BountyDisplay = UIBuilder.headerText("Bounty: 0", Color3.fromRGB(255, 100, 100), {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.35, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	
	-- Training Level display
	self.TrainingDisplay = UIBuilder.headerText("Training: Level 0", Color3.fromRGB(120, 255, 200), {
		Size = UDim2.new(0.3, 0, 1, 0),
		Position = UDim2.new(0.7, 0, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	
	self.BeliDisplay.Parent = topBar
	self.BountyDisplay.Parent = topBar
	self.TrainingDisplay.Parent = topBar
	
	-- Next step indicator
	self.NextStepIndicator = UIBuilder.infoText("Tip: Fight enemies to earn Beli", {
		Name = "nextStepIndicator",
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(200, 255, 100),
	})
	self.NextStepIndicator.Parent = topBar
	
	topBar.Parent = screenGui

	-- Create Top Tabs Bar
	local tabsBar = UIBuilder.panel({
		Name = "TopTabs",
		Size = UDim2.new(1, -20, 0, 50),
		Position = UDim2.new(0, 10, 0, 60),
		BackgroundColor3 = Color3.fromRGB(20, 25, 30),
		BackgroundTransparency = 0.1,
	})
	
	UIBuilder.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, {tabsBar})
	
	-- Top bar tabs: Combat, Items, Jobs, Home, Train, Fish, Ranked
	local tabs = {"Combat", "Items", "Jobs", "Home", "Train", "Fish", "Ranked"}
	for i, tabName in ipairs(tabs) do
		local btn = UIBuilder.primaryButton(tabName, function() end, {Color3.fromRGB(60, 60, 80), Color3.fromRGB(40, 40, 60)}, {
			Name = string.lower(tabName) .. "Tab",
			Size = UDim2.new(0, 80, 1, -10),
			LayoutOrder = i,
		})
		btn.Parent = tabsBar
	end
	tabsBar.Parent = screenGui
end

function MainScreenController:buildColumns(screenGui: ScreenGui)
	-- The layout frame holds 3 side-by-side grids
	local container = UIBuilder.create("Frame", {
		Name = "ColumnsContainer",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 1, -130), -- Offset for the top bar + tabs + margins
		Position = UDim2.new(0, 10, 0, 120),
	})
	container.Parent = screenGui
	
	-- Force columns side by side via UIListLayout
	UIBuilder.create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, {container})
	
	-- 3 columns, each 1/3 of the screen width
	local columnWidth = UDim2.new(1/3, -10, 1, 0)
	
	self.Containers.Actions = self:createColumn(container, "Actions", columnWidth, 1)
	self.Containers.Work = self:createColumn(container, "Work", columnWidth, 2)
	self.Containers.Upgrade = self:createColumn(container, "Upgrade", columnWidth, 3)
	
	-- Populate Content
	ActionsColumnUI:Init(self.Containers.Actions)
	WorkColumnUI:Init(self.Containers.Work)
	UpgradeColumnUI:Init(self.Containers.Upgrade)
end

function MainScreenController:createColumn(parent: Instance, title: string, size: UDim2, layoutOrder: number)
	local column = UIBuilder.panel({
		Name = title .. "Column",
		Size = size,
		LayoutOrder = layoutOrder,
	})
	column.Parent = parent
	
	-- Ensure a top-to-bottom layout inside the column
	UIBuilder.create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, {column})
	
	-- Title of the column
	local titleLabel = UIBuilder.headerText(title, Color3.fromRGB(240, 200, 80))
	titleLabel.LayoutOrder = 1
	titleLabel.Parent = column
	
	-- Return the column frame for other scripts to inject content into
	return column
end

-- Update Top Bar values remotely
function MainScreenController:updateTopNav(beli: number, bounty: number, trainingLvl: string)
	if self.BeliDisplay then
		self.BeliDisplay.Text = "Beli: " .. require(Shared.Utils.NumberFormat).commaFormat(beli)
	end
	if self.BountyDisplay then
		self.BountyDisplay.Text = "Bounty: " .. require(Shared.Utils.NumberFormat).commaFormat(bounty)
	end
	if self.TrainingDisplay then
		self.TrainingDisplay.Text = "Training: " .. trainingLvl
	end
end

return MainScreenController
