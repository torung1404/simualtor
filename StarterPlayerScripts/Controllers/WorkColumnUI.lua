--!strict
-- LOCATION: src/StarterPlayerScripts/Controllers/WorkColumnUI.lua
-- TYPE: ModuleScript
-- PURPOSE: Renders the list of Jobs (Odd Jobs, Fishing, etc.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIBuilder = require(script.Parent:WaitForChild("UIBuilder"))

local WorkColumnUI = {}

-- Mock data matching screenshot
local JOBS: { { name: string, reward: string, req: string?, active: boolean } } = {
	{ name = "Odd Jobs", reward = "+14 Beli", req = nil, active = true },
	{ name = "Fishing", reward = "+36 Beli", req = nil, active = false },
	{ name = "Bounty Hunting", reward = "+72 Beli", req = "Arc 2 Required", active = false },
	{ name = "Treasure Maps", reward = "+164 Beli", req = "Arc 4 Required", active = false },
	{ name = "Pirate Raids", reward = "+412 Beli", req = "Arc 6 Required", active = false },
	{ name = "Grand Heists", reward = "+1.1K Beli", req = "Arc 9 Required", active = false },
}

function WorkColumnUI:Init(container: Frame)
	self.Container = container
	
	UIBuilder.infoText("Select a job below", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 20),
	}).Parent = self.Container
	
	local scroller = UIBuilder.scrollingList({
		LayoutOrder = 2
	})
	scroller.Parent = self.Container
	
	for i, job in ipairs(JOBS) do
		self:createJobEntry(scroller, job, i)
	end
end

function WorkColumnUI:createJobEntry(parent: Instance, jobData: any, index: number)
	local frame = UIBuilder.create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 0, 60), -- Adjust height to fit texts + button
		LayoutOrder = index
	})
	
	-- Name & Reward
	UIBuilder.infoText("<b>" .. jobData.name .. "</b>\n<font color='#F0C850'>" .. jobData.reward .. "</font>", {
		Size = UDim2.new(0.6, 0, 0, 30),
		Position = UDim2.new(0, 5, 0, 0)
	}).Parent = frame
	
	-- Status Text (Working/Idle)
	local statusText = UIBuilder.infoText(jobData.active and "Working..." or "Idle", {
		Size = UDim2.new(0.4, 0, 0, 30),
		Position = UDim2.new(0.6, -5, 0, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = jobData.active and Color3.fromRGB(240, 200, 80) or Color3.fromRGB(150, 150, 150)
	})
	statusText.Parent = frame
	
	-- Button logic
	if jobData.req then
		UIBuilder.primaryButton(jobData.req, function() end, {Color3.fromRGB(80, 80, 80), Color3.fromRGB(50, 50, 50)}, {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 32),
			TextSize = 12,
			Active = false,
		}).Parent = frame
	elseif jobData.active then
		UIBuilder.primaryButton("STOP WORKING", function() end, {Color3.fromRGB(200, 60, 60), Color3.fromRGB(150, 40, 40)}, {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 32),
			TextSize = 12,
		}).Parent = frame
	else
		UIBuilder.primaryButton("START WORKING", function() end, {Color3.fromRGB(40, 140, 100), Color3.fromRGB(30, 100, 70)}, {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 32),
			TextSize = 12,
		}).Parent = frame
	end
	
	-- Divider
	UIBuilder.create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, 5)
	}).Parent = frame
	
	frame.Parent = parent
end

return WorkColumnUI
