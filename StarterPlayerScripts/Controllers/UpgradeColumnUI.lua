--!strict
-- LOCATION: src/StarterPlayerScripts/Controllers/UpgradeColumnUI.lua
-- TYPE: ModuleScript
-- PURPOSE: Renders the list of Shop Upgrades (Tonic, Weights, etc.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local UpgradeColumnUI = {}

-- Mock data matching screenshot
local UPGRADES = {
	{ name = "Vitality Tonic", level = "1/25", desc = "+6% Max HP per level", price = "Buy - 440 Beli", canBuy = true },
	{ name = "Training Weights", level = "1/20", desc = "+8% Training Speed per level", price = "1.8K Beli (need more)", canBuy = false },
	{ name = "Dojo Pass", level = "0/10", desc = "+4 flat XP per second", price = "5.0K Beli (need more)", canBuy = false },
	{ name = "Port Job License", level = "0/15", desc = "+15% Beli from all sources", price = "15.0K Beli (need more)", canBuy = false },
	{ name = "Combat Manual", level = "0/20", desc = "+10% Damage per level", price = "50.0K Beli (need more)", canBuy = false },
}

function UpgradeColumnUI:Init(container: Frame)
	self.Container = container
	
	local scroller = UIBuilder.scrollingList({
		Name = "upgradePanel",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 1, -10)
	})
	scroller.Parent = self.Container
	
	for i, upgrade in ipairs(UPGRADES) do
		self:createUpgradeEntry(scroller, upgrade, i)
	end
end

function UpgradeColumnUI:createUpgradeEntry(parent: Instance, upgradeData: any, index: number)
	local frame = UIBuilder.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 0, 50),
		LayoutOrder = index
	})
	
	-- Title & Level
	UIBuilder.infoText("<b>" .. upgradeData.name .. "</b> Lv." .. upgradeData.level, {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 5, 0, 0),
		TextColor3 = Color3.fromRGB(240, 200, 150)
	}).Parent = frame
	
	-- Description
	UIBuilder.infoText("<font color='#AAAAAA'>" .. upgradeData.desc .. "</font>", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 5, 0, 16),
		TextSize = 12
	}).Parent = frame
	
	-- Buy Button
	local btnColor = upgradeData.canBuy and {Color3.fromRGB(40, 100, 80), Color3.fromRGB(30, 80, 60)} or {Color3.fromRGB(50, 50, 50), Color3.fromRGB(40, 40, 40)}
	local btn = UIBuilder.primaryButton(upgradeData.price, function()
		if upgradeData.canBuy then
			-- Invoke purchase remote
			print("Buying " .. upgradeData.name)
		end
	end, btnColor, {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 32),
		TextSize = 12,
		Active = upgradeData.canBuy,
	})
	btn.Parent = frame
	
	-- Divider
	UIBuilder.create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, 5)
	}).Parent = frame
	
	frame.Parent = parent
end

return UpgradeColumnUI
