--!strict
-- LOCATION: src/StarterPlayerScripts/Controllers/ActionsColumnUI.lua
-- TYPE: ModuleScript
-- PURPOSE: Renders Enemy stats and manages the "Fight Enemy" button flow

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))
local EnemyViewModel = require(script.Parent.Parent:WaitForChild("ViewModels"):WaitForChild("EnemyViewModel"))

local ActionsColumnUI = {}

function ActionsColumnUI:Init(container: Frame)
	self.Container = container
	
	-- Back button (Arrow)
	local topBar = UIBuilder.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 2
	}, {
		UIBuilder.primaryButton("<", function()
			-- Go back an arc
		end, {Color3.fromRGB(40, 100, 200), Color3.fromRGB(20, 60, 150)}, {
			Size = UDim2.new(0, 40, 1, 0),
		}),
		UIBuilder.infoText("Arc 1: Captain Morgan Arc", {
			Size = UDim2.new(1, -50, 1, 0),
			Position = UDim2.new(0, 50, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = Color3.fromRGB(255, 200, 50),
			Font = Enum.Font.FredokaOne
		})
	})
	topBar.Parent = self.Container
	
	-- Enemy Info
	self.EnemyInfo = UIBuilder.infoText("Next: Marine Recruit\nHP: 177 | ATK: 52 | DEF: 4", {
		Name = "enemyList",
		Size = UDim2.new(1, 0, 0, 40),
		LayoutOrder = 3
	})
	self.EnemyInfo.Parent = self.Container
	
	-- Fight Button
	self.FightButtonWrapper = UIBuilder.primaryButton("Fight Enemy", function()
		self:requestFight()
	end, {Color3.fromRGB(220, 80, 80), Color3.fromRGB(150, 40, 40)}, {
		LayoutOrder = 4
	})
	self.FightButtonWrapper.Parent = self.Container
	
	-- Boss Info (red)
	self.BossInfo = UIBuilder.infoText("Boss: Captain Axe-Hand Morgan\nHP: 825 | ATK: 140 | DEF: 18", {
		Name = "bossButton",
		Size = UDim2.new(1, 0, 0, 40),
		TextColor3 = Color3.fromRGB(200, 60, 60),
		LayoutOrder = 5
	})
	self.BossInfo.Parent = self.Container
	
	-- Drops Info
	self.DropsInfo = UIBuilder.infoText("🎁 Morgan's Axe-Hand (100%)\n🍎 Mystery Devil Fruit (100%)", {
		Size = UDim2.new(1, 0, 0, 40),
		TextColor3 = Color3.fromRGB(200, 255, 100),
		LayoutOrder = 6
	})
	self.DropsInfo.Parent = self.Container
	
	-- Player Power
	local fill = UIBuilder.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -260), -- Take up remaining space
		LayoutOrder = 7
	})
	fill.Parent = self.Container
	
	self.PlayerPower = UIBuilder.infoText("Your Power: ATK 163 | HP 1.7K", {
		Size = UDim2.new(1, 0, 0, 20),
		TextColor3 = Color3.fromRGB(240, 200, 80),
		Position = UDim2.new(0, 0, 1, -20),
	})
	self.PlayerPower.Parent = fill
end

function ActionsColumnUI:requestFight()
	-- Call remote to fight current enemy (implemented in RemoteHandlers)
	local isSuccess = Shared.Remotes.Combat.FightEnemy:InvokeServer()
	if not isSuccess then
		-- Flash button red or show error
		print("Fight failed! Too weak or cooldown.")
	end
end

return ActionsColumnUI
