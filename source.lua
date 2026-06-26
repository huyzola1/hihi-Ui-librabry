local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local UILib = {}
UILib.__index = UILib


UILib.LucideIcons = {

}

local function ResolveIcon(icon)
	if icon == nil or icon == "" then
		return nil
	end

	if typeof(icon) == "number" then
		return { Image = "rbxassetid://" .. icon }
	end

	if typeof(icon) == "string" then
		if icon:match("^%d+$") then
			return { Image = "rbxassetid://" .. icon }
		end
		if icon:find("rbxassetid://") then
			return { Image = icon }
		end

		local data = UILib.LucideIcons[icon]
		if data then
			return { Image = "rbxassetid://" .. data.Id, Offset = data.Offset, Size = data.Size }
		else
			warn(("[UILib] icon \"%s\" trong UILib.LucideIcons — bỏ qua icon."):format(icon))
			return nil
		end
	end

	return nil
end

local ActiveWindow = nil

local DefaultTheme = {
	Background = Color3.fromRGB(18, 18, 20),
	Surface = Color3.fromRGB(28, 28, 32),
	SurfaceLight = Color3.fromRGB(42, 42, 48),
	Accent = Color3.fromRGB(145, 60, 50),
	AccentDark = Color3.fromRGB(120, 48, 40),
	Text = Color3.fromRGB(225, 220, 215),
	SubText = Color3.fromRGB(130, 125, 120),
	Border = Color3.fromRGB(50, 50, 55),
	Success = Color3.fromRGB(80, 160, 90),
	Error = Color3.fromRGB(210, 80, 70),
	Warning = Color3.fromRGB(225, 175, 60),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
}




local function Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do inst[prop] = value end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

local function Corner(radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end



local function Tween(obj, props, time, style, dir)
	local tween = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function MakeDraggable(dragHandle, target)
	local dragging, dragStart, startPos = false, nil, nil
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = target.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	dragHandle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local function GetScreenGui()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("UILib_ScreenGui")
	if existing then existing:Destroy() end
	return Create("ScreenGui", { Name = "UILib_ScreenGui", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = playerGui })
end

local function CreateNotificationHolder(screenGui)
	return Create("Frame", {
		Name = "NotificationHolder", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, 300, 1, -32), Parent = screenGui,
	}, { Create("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
end


local function PlayGreeting(screenGui, theme, onDone)
	local playerName = LocalPlayer.DisplayName ~= "" and LocalPlayer.DisplayName or LocalPlayer.Name
	local greetText = "Hello " .. playerName .. "!"

	local GreetingLabel = Create("TextLabel", {
		Name = "GreetingLabel",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 700, 0, 60),
		Font = theme.FontBold,
		Text = "",
		TextColor3 = theme.Text,
		TextSize = 30,
		TextTransparency = 1,
		Parent = screenGui,
	})

	local Cursor = Create("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.5, 4, 0.5, 0),
		Size = UDim2.new(0, 16, 0, 34),
		Font = theme.FontBold,
		Text = "|",
		TextColor3 = theme.Accent,
		TextSize = 28,
		TextTransparency = 1,
		Parent = screenGui,
	})

	task.spawn(function()
		Tween(GreetingLabel, { TextTransparency = 0 }, 0.25)
		Tween(Cursor, { TextTransparency = 0 }, 0.25)
		task.wait(0.2)

		for i = 1, #greetText do
			GreetingLabel.Text = greetText:sub(1, i)
			local textWidth = game:GetService("TextService"):GetTextSize(
				GreetingLabel.Text, GreetingLabel.TextSize, GreetingLabel.Font, Vector2.new(1000, 60)
			).X
			Cursor.Position = UDim2.new(0.5, (textWidth / 2) + 4, 0.5, 0)
			task.wait(0.045)
		end

		for _ = 1, 3 do
			Tween(Cursor, { TextTransparency = 1 }, 0.18)
			task.wait(0.18)
			Tween(Cursor, { TextTransparency = 0 }, 0.18)
			task.wait(0.18)
		end

		task.wait(0.3)
		Tween(GreetingLabel, { TextTransparency = 1 }, 0.35)
		Tween(Cursor, { TextTransparency = 1 }, 0.35)
		task.wait(0.4)
		GreetingLabel:Destroy()
		Cursor:Destroy()

		if onDone then onDone() end
	end)
end

function UILib:CreateWindow(config)
	config = config or {}
	local windowName, subTitle, toggleKey = config.Name or "Window", config.SubTitle or "", config.Keybind or nil
	if ActiveWindow then ActiveWindow:Destroy() end

	local Theme = table.clone(DefaultTheme)
	if config.Theme then for k, v in pairs(config.Theme) do if Theme[k] then Theme[k] = v end end end

	local screenGui = GetScreenGui()
	local notifHolder = CreateNotificationHolder(screenGui)
	local fullSize = UDim2.new(0, 520, 0, 380)

	local Main = Create("Frame", {
		Name = "Main", BackgroundColor3 = Theme.Background, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true, BackgroundTransparency = 1, Visible = false, Parent = screenGui,
	})
	local Shadow = Instance.new("UIShadow",Main)
	Shadow.BlurRadius = UDim.new(0,10)

	local TopBar = Create("Frame", { Name = "TopBar", BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 48), Parent = Main })
	Create("Frame", { BackgroundColor3 = Theme.Surface, Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12), BorderSizePixel = 0, Parent = TopBar })
	Create("TextLabel", { Name = "Title", BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 6), Size = UDim2.new(1, -100, 0, 22), Font = Theme.FontBold, Text = windowName, TextColor3 = Theme.Text, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
	Create("TextLabel", { Name = "SubTitle", BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 26), Size = UDim2.new(1, -100, 0, 16), Font = Theme.Font, Text = subTitle, TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })

	local CloseBtn = Create("TextButton", { Name = "CloseBtn", BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -40, 0, 10), Size = UDim2.new(0, 28, 0, 28), Font = Theme.FontBold, Text = "×", TextColor3 = Theme.Text, TextSize = 18, AutoButtonColor = false, Parent = TopBar })
	local MinimizeBtn = Create("TextButton", { Name = "MinimizeBtn", BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -74, 0, 10), Size = UDim2.new(0, 28, 0, 28), Font = Theme.FontBold, Text = "—", TextColor3 = Theme.Text, TextSize = 14, AutoButtonColor = false, Parent = TopBar })

	MakeDraggable(TopBar, Main)

	local TabList = Create("Frame", { Name = "TabList", BackgroundColor3 = Theme.Surface, Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(0, 130, 1, -48), Parent = Main }, {
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})

	local Container = Create("Frame", { Name = "Container", BackgroundTransparency = 1, Position = UDim2.new(0, 130, 0, 48), Size = UDim2.new(1, -130, 1, -48), Parent = Main })

	local Window = { ScreenGui = screenGui, Main = Main, Tabs = {}, Connections = {}, _firstTab = nil }
	ActiveWindow = Window

	local ToggleButton = Create("ImageButton", { Name = "ToggleButton", BackgroundColor3 = Theme.Accent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 45, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), Visible = false, AutoButtonColor = false, Parent = screenGui }, {Corner(50)})
	Create("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.new(0.5, -12, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), Image = "rbxassetid://7488932274" , ImageColor3 = Color3.fromRGB(255, 255, 255), Parent = ToggleButton })
	
	local Shadow = Instance.new("UIShadow",ToggleButton)
	Shadow.BlurRadius = UDim.new(0,10)
		
	MakeDraggable(ToggleButton, ToggleButton)
	local isDraggingBtn, dragStartPos = false, nil
	ToggleButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStartPos = input.Position; isDraggingBtn = false end
	end)
	
	ToggleButton.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragStartPos and (input.Position - dragStartPos).Magnitude > 5 then isDraggingBtn = true end
		end
	end)
	ToggleButton.MouseEnter:Connect(function() if ToggleButton.Visible then Tween(ToggleButton, { Size = UDim2.new(0, 56, 0, 56) }, 0.2, Enum.EasingStyle.Back) end end)
	ToggleButton.MouseLeave:Connect(function() if ToggleButton.Visible then Tween(ToggleButton, { Size = UDim2.new(0, 50, 0, 50) }, 0.2, Enum.EasingStyle.Back) end end)

	local isAnimating = false

	local function closeWindow()
		if isAnimating or not Main.Visible then return end
		isAnimating = true
		Main.ClipsDescendants = true
		Tween(Main, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.25)
		task.delay(0.25, function()
			Main.Visible = false; ToggleButton.Visible = true
			Tween(ToggleButton, { Size = UDim2.new(0, 50, 0, 50) }, 0.3, Enum.EasingStyle.Back)
			isAnimating = false
		end)
	end

	local function openWindow()
		if isAnimating or Main.Visible then return end
		isAnimating = true
		Tween(ToggleButton, { Size = UDim2.new(0, 0, 0, 0) }, 0.2)
		task.delay(0.2, function()
			ToggleButton.Visible = false; Main.Visible = true; Main.ClipsDescendants = true
			Main.Size = UDim2.new(0, 0, 0, 0); Main.BackgroundTransparency = 1
			Tween(Main, { Size = fullSize, BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back)
			task.delay(0.4, function() Main.ClipsDescendants = false; isAnimating = false end)
		end)
	end

	CloseBtn.MouseButton1Click:Connect(closeWindow)
	ToggleButton.MouseButton1Click:Connect(function() if not isDraggingBtn then openWindow() end end)

	if toggleKey then
		table.insert(Window.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if not gameProcessed and input.KeyCode == toggleKey then
				if Main.Visible then closeWindow() else openWindow() end
			end
		end))
	end

	local minimized = false
	MinimizeBtn.MouseButton1Click:Connect(function()
		if isAnimating then return end
		minimized = not minimized
		if minimized then
			Tween(Main, { Size = UDim2.new(0, fullSize.X.Offset, 0, 48) }, 0.25, Enum.EasingStyle.Quad)
			TabList.Visible = false; Container.Visible = false
		else
			TabList.Visible = true; Container.Visible = true
			Tween(Main, { Size = fullSize }, 0.25, Enum.EasingStyle.Back)
		end
	end)

	PlayGreeting(screenGui, Theme, function()
		isAnimating = true
		Main.Visible = true
		Main.ClipsDescendants = true
		Main.Size = UDim2.new(0, 0, 0, 0); Main.BackgroundTransparency = 1
		Tween(Main, { Size = fullSize, BackgroundTransparency = 0 }, 0.5, Enum.EasingStyle.Back)
		task.delay(0.5, function() Main.ClipsDescendants = false; isAnimating = false end)
	end)

	function Window:CreateTab(tabName, icon)
		local iconData = ResolveIcon(icon)

		local TabButton = Create("TextButton", { Name = tabName .. "Btn", BackgroundColor3 = Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 34), Text = "", AutoButtonColor = false, Parent = TabList }, {Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })

		local TabIcon = nil
		if iconData then
			TabIcon = Create("ImageLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0.5, -8), Size = UDim2.new(0, 16, 0, 16), Image = iconData.Image, ImageColor3 = Theme.SubText, Parent = TabButton })
			if iconData.Offset and iconData.Size then
				TabIcon.ImageRectOffset = iconData.Offset
				TabIcon.ImageRectSize = iconData.Size
			end
		end

		local textOffsetX = TabIcon and 24 or 8
		local TabText = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffsetX, 0, 0), Size = UDim2.new(1, -(textOffsetX + 10), 1, 0), Font = Theme.Font, Text = tabName, TextColor3 = Theme.SubText, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = TabButton })

		local TabPage = Create("ScrollingFrame", { Name = tabName .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Accent, Visible = false, Parent = Container }, {
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12) }),
		})

		local function selectTab()
			for _, t in pairs(Window.Tabs) do
				t.Page.Visible = false
				Tween(t.Button, { BackgroundColor3 = Theme.SurfaceLight }, 0.2)
				if t.Icon then Tween(t.Icon, { ImageColor3 = Theme.SubText }, 0.2) end
				Tween(t.Text, { TextColor3 = Theme.SubText }, 0.2)
			end
			TabPage.Visible = true
			Tween(TabButton, { BackgroundColor3 = Theme.Accent }, 0.2)
			if TabIcon then Tween(TabIcon, { ImageColor3 = Color3.fromRGB(255,255,255) }, 0.2) end
			Tween(TabText, { TextColor3 = Color3.fromRGB(255,255,255) }, 0.2)
		end

		TabButton.MouseButton1Click:Connect(selectTab)
		local Tab = { Button = TabButton, Page = TabPage, Icon = TabIcon, Text = TabText }
		table.insert(Window.Tabs, Tab)
		if not Window._firstTab then Window._firstTab = Tab; selectTab() end

		function Tab:CreateSection(name)
			Create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Font = Theme.FontBold, Text = name, TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabPage })
		end

		function Tab:CreateLabel(text)
			Create("TextLabel", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Theme.Font, Text = text, TextColor3 = Theme.Text, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabPage }, {
			 Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
			})
		end

		function Tab:CreateButton(opts)
			opts = opts or {}
			local Btn = Create("TextButton", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Font = Theme.Font, Text = opts.Name or "Button", TextColor3 = Theme.Text, TextSize = 13, AutoButtonColor = false, Parent = TabPage })
			Btn.MouseEnter:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.SurfaceLight }, 0.15) end)
			Btn.MouseLeave:Connect(function() Tween(Btn, { BackgroundColor3 = Theme.Surface }, 0.15) end)
			Btn.MouseButton1Click:Connect(function()
				Tween(Btn, { Size = UDim2.new(1, -6, 0, 34), BackgroundColor3 = Theme.Accent }, 0.1)
				task.delay(0.1, function() Tween(Btn, { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = Theme.Surface }, 0.2, Enum.EasingStyle.Quad) end)
				if opts.Callback then task.spawn(opts.Callback) end
			end)
		end

		function Tab:CreateToggle(opts)
			opts = opts or {}
			local state = opts.CurrentValue or false
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Parent = TabPage })
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -70, 1, 0), Font = Theme.Font, Text = opts.Name or "Toggle", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local Switch = Create("TextButton", { BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight, Position = UDim2.new(1, -50, 0.5, -10), Size = UDim2.new(0, 40, 0, 20), Text = "", AutoButtonColor = false, Parent = Holder })
			local Dot = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7), Size = UDim2.new(0, 14, 0, 14), Parent = Switch })
			Switch.MouseButton1Click:Connect(function()
				state = not state
				Tween(Switch, { BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight }, 0.2, Enum.EasingStyle.Quad)
				Tween(Dot, { Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) }, 0.2, Enum.EasingStyle.Quad)
				if opts.Callback then task.spawn(opts.Callback, state) end
			end)
			return { Set = function(_, v) state = v; Switch.BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight; Dot.Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7) end }
		end

		function Tab:CreateSlider(opts)
			opts = opts or {}
			local min, max = (opts.Range and opts.Range[1]) or 0, (opts.Range and opts.Range[2]) or 100
			local increment, value = opts.Increment or 1, opts.CurrentValue or min
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 50), Parent = TabPage })
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -80, 0, 18), Font = Theme.Font, Text = opts.Name or "Slider", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local ValueLabel = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 6), Size = UDim2.new(0, 48, 0, 18), Font = Theme.FontBold, Text = tostring(value), TextColor3 = Theme.Accent, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder })
			local Track = Create("Frame", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 12, 0, 32), Size = UDim2.new(1, -24, 0, 8), Parent = Holder })
			local function ratio(v) return math.clamp((v - min) / (max - min), 0, 1) end
			local Fill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(ratio(value), 0, 1, 0), Parent = Track })
			local Knob = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ratio(value), 0, 0.5, 0), Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Track })
			local dragging = false
			local function updateFromX(xPos)
				local relative = math.clamp((xPos - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
				value = math.clamp(math.floor((min + relative * (max - min)) / increment + 0.5) * increment, min, max)
				local r = ratio(value)
				Fill.Size = UDim2.new(r, 0, 1, 0); Knob.Position = UDim2.new(r, 0, 0.5, 0); ValueLabel.Text = tostring(value)
				if opts.Callback then task.spawn(opts.Callback, value) end
			end
			Track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; updateFromX(input.Position.X) end end)
			table.insert(Window.Connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
			table.insert(Window.Connections, UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateFromX(input.Position.X) end end))
			return { Set = function(_, v) value = math.clamp(v, min, max); local r = ratio(value); Fill.Size = UDim2.new(r, 0, 1, 0); Knob.Position = UDim2.new(r, 0, 0.5, 0); ValueLabel.Text = tostring(value) end }
		end

		function Tab:CreateDropdown(opts)
			opts = opts or {}
			local options, current, open = opts.Options or {}, opts.CurrentOption or opts.Options[1] or "—", false
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Parent = TabPage })
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -120, 0, 38), Font = Theme.Font, Text = opts.Name or "Dropdown", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local SelectedBtn = Create("TextButton", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -110, 0, 6), Size = UDim2.new(0, 98, 0, 26), Font = Theme.Font, Text = current .. "  ▾", TextColor3 = Theme.Text, TextSize = 12, AutoButtonColor = false, Parent = Holder })
			local OptionList = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, #options * 30), Parent = Holder }, { Create("UIListLayout", { Padding = UDim.new(0, 4) }), Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
			for _, optionName in ipairs(options) do
				local OptBtn = Create("TextButton", { BackgroundColor3 = Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 26), Font = Theme.Font, Text = optionName, TextColor3 = Theme.SubText, TextSize = 12, AutoButtonColor = false, Parent = OptionList })
				OptBtn.MouseButton1Click:Connect(function() current = optionName; SelectedBtn.Text = current .. "  ▾"; open = false; Tween(Holder, { Size = UDim2.new(1, 0, 0, 38) }, 0.2, Enum.EasingStyle.Quad); if opts.Callback then task.spawn(opts.Callback, current) end end)
			end
			SelectedBtn.MouseButton1Click:Connect(function() open = not open; Tween(Holder, { Size = UDim2.new(1, 0, 0, open and (40 + #options * 30 + 8) or 38) }, 0.25, Enum.EasingStyle.Quad) end)
			return { Set = function(_, v) current = v; SelectedBtn.Text = current .. "  ▾" end }
		end

		function Tab:CreateInput(opts)
			opts = opts or {}
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Parent = TabPage })
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(0, 110, 1, 0), Font = Theme.Font, Text = opts.Name or "Input", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local TextBox = Create("TextBox", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 126, 0, 6), Size = UDim2.new(1, -138, 0, 26), Font = Theme.Font, PlaceholderText = opts.PlaceholderText or "", Text = "", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText, TextSize = 13, ClearTextOnFocus = false, Parent = Holder }, {Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
			TextBox.FocusLost:Connect(function(enterPressed) if opts.Callback then task.spawn(opts.Callback, TextBox.Text, enterPressed) end end)
			return TextBox
		end

		function Tab:CreateKeybind(opts)
			opts = opts or {}
			local currentKey, isListening = opts.CurrentKey or Enum.KeyCode.E, false
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Parent = TabPage })
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 1, 0), Font = Theme.Font, Text = opts.Name or "Keybind", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local KeyBtn = Create("TextButton", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -82, 0.5, -12), Size = UDim2.new(0, 70, 0, 24), Font = Theme.FontBold, Text = currentKey.Name, TextColor3 = Theme.Text, TextSize = 12, AutoButtonColor = false, Parent = Holder })
			KeyBtn.MouseButton1Click:Connect(function() isListening = true; KeyBtn.Text = "..."; Tween(KeyBtn, { BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255,255,255) }, 0.15) end)
			table.insert(Window.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if isListening and input.UserInputType == Enum.UserInputType.Keyboard then
					isListening = false; currentKey = input.KeyCode; KeyBtn.Text = currentKey.Name
					Tween(KeyBtn, { BackgroundColor3 = Theme.SurfaceLight, TextColor3 = Theme.Text }, 0.15)
				elseif not isListening and not gameProcessed then
					if input.KeyCode == currentKey and opts.Callback then task.spawn(opts.Callback, currentKey) end
				end
			end))
			return { Set = function(_, newKey) currentKey = newKey; KeyBtn.Text = currentKey.Name end, GetKey = function() return currentKey end }
		end

		function Tab:CreateColorPicker(opts)
			opts = opts or {}
			local defaultColor = opts.DefaultColor or Color3.fromRGB(255, 255, 255)
			local r, g, b, open = math.floor(defaultColor.R * 255), math.floor(defaultColor.G * 255), math.floor(defaultColor.B * 255), false
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Parent = TabPage })
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -100, 0, 38), Font = Theme.Font, Text = opts.Name or "Color Picker", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local ColorPreview = Create("TextButton", { BackgroundColor3 = defaultColor, Position = UDim2.new(1, -48, 0, 7), Size = UDim2.new(0, 36, 0, 24), Text = "", Parent = Holder })
			local ContentFrame = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 0, 90), Parent = Holder })

			local function createColorSlider(name, defaultVal, yPos, callback)
				local SliderTrack = Create("Frame", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 12, 0, yPos), Size = UDim2.new(1, -24, 0, 18), Parent = ContentFrame })
				Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 30, 1, 0), Font = Theme.FontBold, Text = name, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderTrack })
				local SliderFill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(defaultVal / 255, 0, 1, 0), BackgroundTransparency = 0.4, Parent = SliderTrack })
				local drag = false
				local function update(x) local rel = math.clamp((x - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1); SliderFill.Size = UDim2.new(rel, 0, 1, 0); callback(math.floor(rel * 255)) end
				SliderTrack.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drag = true; update(input.Position.X) end end)
				table.insert(Window.Connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then drag = false end end))
				table.insert(Window.Connections, UserInputService.InputChanged:Connect(function(input) if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end end))
			end

			local function updateColor() local nColor = Color3.fromRGB(r, g, b); ColorPreview.BackgroundColor3 = nColor; if opts.Callback then task.spawn(opts.Callback, nColor) end end
			createColorSlider("R", r, 5, function(v) r = v updateColor() end)
			createColorSlider("G", g, 30, function(v) g = v updateColor() end)
			createColorSlider("B", b, 55, function(v) b = v updateColor() end)

			ColorPreview.MouseButton1Click:Connect(function() open = not open; Tween(Holder, { Size = open and UDim2.new(1, 0, 0, 134) or UDim2.new(1, 0, 0, 38) }, 0.25, Enum.EasingStyle.Quad) end)
			return { Set = function(_, nColor) r, g, b = math.floor(nColor.R * 255), math.floor(nColor.G * 255), math.floor(nColor.B * 255); ColorPreview.BackgroundColor3 = nColor; updateColor() end }
		end

		return Tab
	end

	function Window:Notify(opts)
		opts = opts or {}
		local duration = opts.Duration or 4
		local notifType = opts.Type or "Info"
		local typeColor = ({
			Success = Theme.Success,
			Error = Theme.Error,
			Warning = Theme.Warning,
			Info = Theme.Accent,
		})[notifType] or Theme.Accent

		local Notif = Create("Frame", {
			BackgroundColor3 = Theme.Surface,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Position = UDim2.new(1, 340, 0, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			Parent = notifHolder,
		})

		local Scale = Create("UIScale", { Scale = 0.7, Parent = Notif })

		Create("Frame", { BackgroundColor3 = typeColor, Size = UDim2.new(0, 4, 1, -8), Position = UDim2.new(0, 0, 0, 4), Parent = Notif })

		Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 8), Size = UDim2.new(1, -28, 0, 18), Font = Theme.FontBold, Text = opts.Title or "Notification", TextColor3 = Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = Notif })
		Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 16, 0, 28), Size = UDim2.new(1, -28, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Theme.Font, Text = opts.Content or "", TextColor3 = Theme.SubText, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = Notif })


		local ProgressTrack = Create("Frame", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 16, 2, -6), Size = UDim2.new(1, -32, 0, 3), Parent = Notif })
		local ProgressFill = Create("Frame", { BackgroundColor3 = typeColor, Size = UDim2.new(1, 0,2, 0), Parent = ProgressTrack })

		Create("UIPadding", { PaddingBottom = UDim.new(0, 16) }).Parent = Notif

		Tween(Notif, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back)
		Tween(Scale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)

		task.delay(0.1, function()
			Tween(ProgressFill, { Size = UDim2.new(0, 0, 2, 0) }, duration, Enum.EasingStyle.Linear)
		end)

		task.delay(duration, function()
			if Notif and Notif.Parent then
				Tween(Scale, { Scale = 0.7 }, 0.3, Enum.EasingStyle.Quad)
				Tween(Notif, { Position = UDim2.new(1, 340, 0, 0), BackgroundTransparency = 1 }, 0.3, Enum.EasingStyle.Quad)
				task.delay(0.3, function() Notif:Destroy() end)
			end
		end)
	end

	function Window:Destroy()
		for _, conn in ipairs(Window.Connections) do if conn.Connected then conn:Disconnect() end end
		table.clear(Window.Connections)
		screenGui:Destroy()
	end

	return Window
end

return UILib

