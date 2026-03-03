--!strict
-- LOCATION: src/StarterPlayerScripts/Controllers/UIBuilder.lua
-- TYPE: ModuleScript
-- PURPOSE: Fluent builder utility for Cartoon Mobile UI (Bubble Buttons, Panels)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local UIBuilder = {}

-- Generic Instance Creator
function UIBuilder.create(className: string, properties: { [string]: any }?, children: { any }?): Instance
	local inst = Instance.new(className)
	if properties then
		for k, v in pairs(properties) do
			(inst :: any)[k] = v
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	return inst
end

-----------------------------------------
-- CARTOON BUBBLE / PANEL STYLES
-----------------------------------------

-- Base background panel (e.g. Columns)
-- Dark brown/black with subtle transparency
function UIBuilder.panel(props: { [string]: any }?, children: { any }?): Frame
	local defaults = {
		BackgroundColor3 = Color3.fromRGB(24, 20, 20),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}
	
	if props then
		for k, v in pairs(props) do defaults[k] = v end
	end
	
	local kids = children or {}
	table.insert(kids, UIBuilder.create("UICorner", { CornerRadius = UDim.new(0, 8) }))
	table.insert(kids, UIBuilder.create("UIStroke", { 
		Color = Color3.fromRGB(80, 60, 40), 
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border 
	}))

	-- Provide padding so contents aren't glued to perfectly the edge
	table.insert(kids, UIBuilder.create("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}))

	return UIBuilder.create("Frame", defaults, kids) :: Frame
end

-- Primary Bubble Button (e.g. Fight Enemy - Red)
function UIBuilder.primaryButton(text: string, onClick: () -> (), colorConfig: {Color3}?, props: { [string]: any }?): Frame
	local mainColor = colorConfig and colorConfig[1] or Color3.fromRGB(220, 80, 80)
	local shadowColor = colorConfig and colorConfig[2] or Color3.fromRGB(150, 40, 40)
	
	local defaults = {
		Text = text,
		Font = Enum.Font.FredokaOne,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 20,
		BackgroundColor3 = mainColor,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 46),
		AutoButtonColor = false,
	}
	if props then
		for k, v in pairs(props) do defaults[k] = v end
	end
	
	local btn = UIBuilder.create("TextButton", defaults) :: TextButton
	
	-- Style
	UIBuilder.create("UICorner", { CornerRadius = UDim.new(0, 12) }, {btn})
	UIBuilder.create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 2,
		Transparency = 0.2,
	}, {btn})
	
	-- Drop shadow (Fake 3D bottom) via nested frame
	local shadow = UIBuilder.create("Frame", {
		BackgroundColor3 = shadowColor,
		Size = UDim2.new(1, 0, 1, 4),
		Position = UDim2.new(0, 0, 0, 0),
		ZIndex = btn.ZIndex - 1,
	})
	UIBuilder.create("UICorner", { CornerRadius = UDim.new(0, 12) }, {shadow})
	btn.Parent = shadow -- Button sits inside shadow
	
	-- Effects
	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = mainColor:Lerp(Color3.new(1,1,1), 0.2)
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = mainColor
		btn.Position = UDim2.new(0, 0, 0, 0)
	end)
	btn.MouseButton1Down:Connect(function()
		btn.Position = UDim2.new(0, 0, 0, 4) -- Press down logic
	end)
	btn.MouseButton1Up:Connect(function()
		btn.Position = UDim2.new(0, 0, 0, 0)
		onClick()
	end)

	-- Return the shadow frame because it is the actual root container now
	return shadow :: Frame
end

-- Top/Header Title text
function UIBuilder.headerText(text: string, color: Color3?, props: { [string]: any }?): TextLabel
	local defaults = {
		Text = text,
		Font = Enum.Font.FredokaOne,
		TextColor3 = color or Color3.fromRGB(255, 200, 50),
		TextSize = 24,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Center,
	}
	if props then
		for k, v in pairs(props) do defaults[k] = v end
	end
	
	local lbl = UIBuilder.create("TextLabel", defaults) :: TextLabel
	UIBuilder.create("UIStroke", { Color = Color3.fromRGB(20, 20, 20), Thickness = 2 }, {lbl})
	
	return lbl
end

-- Normal Label Info
function UIBuilder.infoText(text: string, props: { [string]: any }?): TextLabel
	local defaults = {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(220, 220, 220),
		TextSize = 14,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		RichText = true,
	}
	if props then
		for k, v in pairs(props) do defaults[k] = v end
	end
	return UIBuilder.create("TextLabel", defaults) :: TextLabel
end

-- A scrolling list for Job or Upgrade panels
function UIBuilder.scrollingList(props: { [string]: any }?): ScrollingFrame
	local defaults = {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -40),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 4,
	}
	if props then
		for k, v in pairs(props) do defaults[k] = v end
	end
	
	local scroller = UIBuilder.create("ScrollingFrame", defaults) :: ScrollingFrame
	UIBuilder.create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center
	}, {scroller})
	
	return scroller
end

-----------------------------------------
-- AUTO RESPONSIVE LOGIC
-----------------------------------------

-- Automatically scales a ScreenGui using UIScale and the ViewportSize
function UIBuilder.attachResponsiveScale(screenGui: ScreenGui)
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = screenGui
	
	local camera = Workspace.CurrentCamera
	if not camera then return end
	
	local function updateScale()
		local viewport = camera.ViewportSize
		local baseSize = math.min(viewport.X, viewport.Y)
		-- Formula provided by promptui.txt
		local scale = math.clamp(baseSize / 1080, 0.85, 1.25)
		uiScale.Scale = scale
	end
	
	updateScale()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

return UIBuilder
