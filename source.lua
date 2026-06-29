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

----------------------------------------------------------------
-- BẢNG PHỐI MÀU THEME (>= 10 lựa chọn) — dùng cho panel Settings
----------------------------------------------------------------
local ThemePresets = {
	{ Name = "Garnet (mặc định)", Color = Color3.fromRGB(145, 60, 50) },
	{ Name = "Cam",               Color = Color3.fromRGB(200, 110, 40) },
	{ Name = "Hổ Phách",          Color = Color3.fromRGB(200, 150, 40) },
	{ Name = "Vàng Chanh",        Color = Color3.fromRGB(170, 180, 50) },
	{ Name = "Xanh Lá",           Color = Color3.fromRGB(70, 150, 80) },
	{ Name = "Ngọc Lục Bảo",      Color = Color3.fromRGB(40, 150, 110) },
	{ Name = "Lam Ngọc",          Color = Color3.fromRGB(40, 150, 150) },
	{ Name = "Xanh Dương",        Color = Color3.fromRGB(50, 110, 190) },
	{ Name = "Chàm",              Color = Color3.fromRGB(90, 90, 200) },
	{ Name = "Tím",               Color = Color3.fromRGB(130, 70, 190) },
	{ Name = "Hồng",              Color = Color3.fromRGB(190, 60, 140) },
	{ Name = "Xám Bạc",           Color = Color3.fromRGB(110, 110, 120) },
}


local function Create(class, props, children)
	local inst = Instance.new(class)
	for prop, value in pairs(props or {}) do inst[prop] = value end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	return inst
end

----------------------------------------------------------------
-- CORNER ĐA GÓC (bản hoạt động đúng)
-- LƯU Ý KỸ THUẬT: UICorner của Roblox chỉ có DUY NHẤT property
-- `CornerRadius`, áp dụng đều cho cả 4 góc — KHÔNG có TopLeftRadius/
-- TopRightRadius/... (gán mấy property đó sẽ làm script lỗi ngay).
-- Để giả lập bo lệch từng góc, mình lấy bán kính lớn nhất làm UICorner
-- chung, rồi "vá vuông" lại các góc có bán kính nhỏ hơn bằng 1 ô vuông
-- cùng màu nền — góc đó sẽ thành vuông hẳn (giới hạn kỹ thuật, không phải
-- lỗi). Ô vá tự bám màu/độ trong suốt của frame cha theo thời gian thực.
----------------------------------------------------------------
local function Corner(radius, tl, tr, bl, br)
	radius = radius or 8
	tl = tl or radius
	tr = tr or radius
	bl = bl or radius
	br = br or radius

	local maxR = math.max(tl, tr, bl, br, 0)
	local corner = Create("UICorner", { CornerRadius = UDim.new(0, maxR) })

	if tl == maxR and tr == maxR and bl == maxR and br == maxR then
		return corner
	end

	local patchSpecs = {
		{ r = tl, anchor = Vector2.new(0, 0), pos = UDim2.new(0, 0, 0, 0) },
		{ r = tr, anchor = Vector2.new(1, 0), pos = UDim2.new(1, 0, 0, 0) },
		{ r = bl, anchor = Vector2.new(0, 1), pos = UDim2.new(0, 0, 1, 0) },
		{ r = br, anchor = Vector2.new(1, 1), pos = UDim2.new(1, 0, 1, 0) },
	}

	corner.AncestryChanged:Connect(function(_, parent)
		if not parent or not parent:IsA("GuiObject") then return end
		for _, spec in ipairs(patchSpecs) do
			if spec.r < maxR then
				local patch = Create("Frame", {
					Name = "CornerPatch",
					BackgroundColor3 = parent.BackgroundColor3,
					BackgroundTransparency = parent.BackgroundTransparency,
					BorderSizePixel = 0,
					AnchorPoint = spec.anchor,
					Position = spec.pos,
					Size = UDim2.new(0, maxR, 0, maxR),
					ZIndex = 5,
					Parent = parent,
				})
				parent:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
					patch.BackgroundColor3 = parent.BackgroundColor3
				end)
				parent:GetPropertyChangedSignal("BackgroundTransparency"):Connect(function()
					patch.BackgroundTransparency = parent.BackgroundTransparency
				end)
			end
		end
	end)

	return corner
end


local function AddIcon(parent, icon, baseOffset, iconColor, size)
	local iconData = ResolveIcon(icon)
	if not iconData then
		return baseOffset, nil
	end

	size = size or 16
	local IconLabel = Create("ImageLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, baseOffset, 0.5, 0),
		Size = UDim2.new(0, size, 0, size),
		Image = iconData.Image,
		ImageColor3 = iconColor or Color3.fromRGB(225, 220, 215),
		Parent = parent,
	})
	if iconData.Offset and iconData.Size then
		IconLabel.ImageRectOffset = iconData.Offset
		IconLabel.ImageRectSize = iconData.Size
	end

	return baseOffset + size + 8, IconLabel
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
	}, { Corner(14) })
	local Shadow = Instance.new("UIShadow",Main)
	Shadow.BlurRadius = UDim.new(0,10)


	local TopBar = Create("Frame", { Name = "TopBar", BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 48), Parent = Main }, { Corner(14, 14, 14, 0, 0) })

	local titleOffsetX, WindowIcon = AddIcon(TopBar, config.Icon, 16, Theme.Text, 22)

	Create("TextLabel", { Name = "Title", BackgroundTransparency = 1, Position = UDim2.new(0, titleOffsetX, 0, 6), Size = UDim2.new(1, -100 - titleOffsetX, 0, 22), Font = Theme.FontBold, Text = windowName, TextColor3 = Theme.Text, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
	Create("TextLabel", { Name = "SubTitle", BackgroundTransparency = 1, Position = UDim2.new(0, titleOffsetX, 0, 26), Size = UDim2.new(1, -100 - titleOffsetX, 0, 16), Font = Theme.Font, Text = subTitle, TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })

	local CloseBtn = Create("TextButton", { Name = "CloseBtn", BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -40, 0, 10), Size = UDim2.new(0, 28, 0, 28), Font = Theme.FontBold, Text = "×", TextColor3 = Theme.Text, TextSize = 18, AutoButtonColor = false, Parent = TopBar }, { Corner(8) })
	local MinimizeBtn = Create("TextButton", { Name = "MinimizeBtn", BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -74, 0, 10), Size = UDim2.new(0, 28, 0, 28), Font = Theme.FontBold, Text = "—", TextColor3 = Theme.Text, TextSize = 14, AutoButtonColor = false, Parent = TopBar }, { Corner(8) })

	MakeDraggable(TopBar, Main)

	-- TabList: chỉ bo góc dưới-trái (góc ngoài thật của Main), phần tab nằm trong TabsHolder
	-- để dành khoảng trống cố định ở đáy cho nút Settings.
	local TabList = Create("Frame", { Name = "TabList", BackgroundColor3 = Theme.Surface, Position = UDim2.new(0, 0, 0, 48), Size = UDim2.new(0, 130, 1, -48), Parent = Main }, {
		Corner(12, 0, 0, 12, 0),
	})

	local TabsHolder = Create("Frame", { Name = "TabsHolder", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Parent = TabList }, {
		Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
	})

	Create("Frame", { -- đường kẻ phân tách phía trên nút Settings
		Name = "SettingsDivider",
		BackgroundColor3 = Theme.Border,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -50),
		Size = UDim2.new(1, -16, 0, 1),
		BorderSizePixel = 0,
		Parent = TabList,
	})

	local Container = Create("Frame", { Name = "Container", BackgroundTransparency = 1, Position = UDim2.new(0, 130, 0, 48), Size = UDim2.new(1, -130, 1, -48), Parent = Main })

	local Window = { ScreenGui = screenGui, Main = Main, Tabs = {}, Connections = {}, _firstTab = nil, _allPages = {}, _accentListeners = {}, _activeTabButton = nil }
	ActiveWindow = Window

	function Window:SetAccent(newColor)
		Theme.Accent = newColor
		if Window._activeTabButton then
			Window._activeTabButton.BackgroundColor3 = newColor
		end
		for _, fn in ipairs(Window._accentListeners) do
			fn(newColor)
		end
	end

	----------------------------------------------------------------
	-- NÚT "Settings" CỐ ĐỊNH Ở ĐÁY TABLIST
	-- Tên và icon hard-code, KHÔNG đi qua hệ thống Icon tuỳ biến (Icon/opts)
	-- của các component khác — người dùng không chỉnh được tên/icon nút này.
	----------------------------------------------------------------
	local SettingsBtn = Create("TextButton", {
		Name = "SettingsBtn",
		BackgroundColor3 = Theme.SurfaceLight,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -8),
		Size = UDim2.new(1, -16, 0, 34),
		Text = "",
		AutoButtonColor = false,
		Parent = TabList,
	}, { Corner(8) })

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0, 18, 1, 0),
		Font = Theme.FontBold,
		Text = "⚙",
		TextColor3 = Theme.SubText,
		TextSize = 15,
		Parent = SettingsBtn,
	})
	local SettingsLabel = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 30, 0, 0),
		Size = UDim2.new(1, -38, 1, 0),
		Font = Theme.Font,
		Text = "Settings",
		TextColor3 = Theme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = SettingsBtn,
	})

	local SettingsPage = Create("ScrollingFrame", {
		Name = "SettingsPage",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
		ScrollBarImageColor3 = Theme.Accent,
		Visible = false,
		Parent = Container,
	}, {
		Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12) }),
	})
	table.insert(Window._allPages, SettingsPage)
	table.insert(Window._accentListeners, function(c) SettingsPage.ScrollBarImageColor3 = c end)

	Create("TextLabel", {
		Name = "SectionTitle",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Font = Theme.FontBold,
		Text = "MÀU THEME",
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = SettingsPage,
	})

	local SwatchGrid = Create("Frame", {
		Name = "SwatchGrid",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = SettingsPage,
	}, {
		Create("UIGridLayout", {
			CellSize = UDim2.new(0, 76, 0, 86),
			CellPadding = UDim2.new(0, 10, 0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local swatchRefs = {}
	local function refreshSwatchSelection()
		for _, ref in ipairs(swatchRefs) do
			local isActive = ref.color == Theme.Accent
			ref.check.Visible = isActive
			ref.stroke.Transparency = isActive and 0 or 1
		end
	end

	for _, preset in ipairs(ThemePresets) do
		local Cell = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Parent = SwatchGrid })

		local Swatch = Create("TextButton", {
			BackgroundColor3 = preset.Color,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.new(0, 56, 0, 56),
			Text = "",
			AutoButtonColor = false,
			Parent = Cell,
		}, { Corner(10) })

		local SwatchStroke = Create("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
			Transparency = 1,
			Parent = Swatch,
		})

		local Check = Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Font = Theme.FontBold,
			Text = "✓",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 22,
			Visible = false,
			Parent = Swatch,
		})

		Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 60),
			Size = UDim2.new(1, 0, 0, 16),
			Font = Theme.Font,
			Text = preset.Name,
			TextColor3 = Theme.SubText,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = Cell,
		})

		table.insert(swatchRefs, { color = preset.Color, check = Check, stroke = SwatchStroke })

		Swatch.MouseButton1Click:Connect(function()
			Window:SetAccent(preset.Color)
			refreshSwatchSelection()
		end)
	end

	refreshSwatchSelection()

	SettingsBtn.MouseButton1Click:Connect(function()
		for _, p in ipairs(Window._allPages) do p.Visible = false end
		for _, t in ipairs(Window.Tabs) do
			Tween(t.Button, { BackgroundColor3 = Theme.SurfaceLight }, 0.2)
			if t.Icon then Tween(t.Icon, { ImageColor3 = Theme.SubText }, 0.2) end
			Tween(t.Text, { TextColor3 = Theme.SubText }, 0.2)
		end
		SettingsPage.Visible = true
		Tween(SettingsBtn, { BackgroundColor3 = Theme.Accent }, 0.2)
		Tween(SettingsLabel, { TextColor3 = Color3.fromRGB(255,255,255) }, 0.2)
		Window._activeTabButton = SettingsBtn
	end)

	local ToggleButton = Create("ImageButton", { Name = "ToggleButton",Transparency = 1, BackgroundColor3 = Theme.Accent, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 45, 0.5, 0), Size = UDim2.new(0, 0, 0, 0), Visible = false, AutoButtonColor = false, Parent = screenGui }, {Corner(50)})
	local Img = Create("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(.5,.5), Position = UDim2.new(0.5, -12, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), Image = "rbxassetid://7488932274" , ImageColor3 = Color3.fromRGB(255, 255, 255), Parent = ToggleButton} , {Corner(50)})
	
	local Shadow2 = Instance.new("UIShadow",Img)
	Shadow2.BlurRadius = UDim.new(0,10)
		
	MakeDraggable(ToggleButton, ToggleButton)
	local isDraggingBtn, dragStartPos = false, nil
	Img.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragStartPos = input.Position; isDraggingBtn = false end
	end)
	
	Img.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragStartPos and (input.Position - dragStartPos).Magnitude > 5 then isDraggingBtn = true end
		end
	end)
	Img.MouseEnter:Connect(function() if Img.Visible then Tween(Img, { Size = UDim2.new(0, 56, 0, 56) }, 0.2, Enum.EasingStyle.Back) end end)
	Img.MouseLeave:Connect(function() if Img.Visible then Tween(Img, { Size = UDim2.new(0, 24, 0, 24) }, 0.2, Enum.EasingStyle.Back) end end)

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

		local TabButton = Create("TextButton", { Name = tabName .. "Btn", BackgroundColor3 = Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 34), Text = "", AutoButtonColor = false, Parent = TabsHolder }, {Corner(8), Create("UIPadding", { PaddingLeft = UDim.new(0, 10) }) })

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

		local TabPage = Create("ScrollingFrame", { Name = tabName .. "Page", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, ScrollBarImageColor3 = Theme.Accent, Visible = false, Parent = Container}, {
			Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			Create("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingBottom = UDim.new(0, 12) }),
		})
		table.insert(Window._allPages, TabPage)
		table.insert(Window._accentListeners, function(c) TabPage.ScrollBarImageColor3 = c end)

		local function selectTab()
			for _, p in ipairs(Window._allPages) do p.Visible = false end
			for _, t in pairs(Window.Tabs) do
				Tween(t.Button, { BackgroundColor3 = Theme.SurfaceLight }, 0.2)
				if t.Icon then Tween(t.Icon, { ImageColor3 = Theme.SubText }, 0.2) end
				Tween(t.Text, { TextColor3 = Theme.SubText }, 0.2)
			end
			Tween(SettingsBtn, { BackgroundColor3 = Theme.SurfaceLight }, 0.2)
			Tween(SettingsLabel, { TextColor3 = Theme.SubText }, 0.2)
			TabPage.Visible = true
			Tween(TabButton, { BackgroundColor3 = Theme.Accent }, 0.2)
			if TabIcon then Tween(TabIcon, { ImageColor3 = Color3.fromRGB(255,255,255) }, 0.2) end
			Tween(TabText, { TextColor3 = Color3.fromRGB(255,255,255) }, 0.2)
			Window._activeTabButton = TabButton
		end

		TabButton.MouseButton1Click:Connect(selectTab)
		local Tab = { Button = TabButton, Page = TabPage, Icon = TabIcon, Text = TabText }
		table.insert(Window.Tabs, Tab)
		if not Window._firstTab then Window._firstTab = Tab; selectTab() end

		function Tab:CreateSection(name, icon)
			local Holder = Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = TabPage })
			local textOffset, _ = AddIcon(Holder, icon, 0, Theme.SubText, 14)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset, 1, 0), Font = Theme.FontBold, Text = name, TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
		end

		function Tab:CreateLabel(text, icon)
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = TabPage }, {
				Corner(8), Create("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
			})
			local textOffset, _ = AddIcon(Holder, icon, 0, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Font = Theme.Font, Text = text, TextColor3 = Theme.Text, TextSize = 13, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
		end

		function Tab:CreateButton(opts)
			opts = opts or {}
			local Btn = Create("TextButton", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Text = "", AutoButtonColor = false, Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Btn, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset - 8, 1, 0), Font = Theme.Font, Text = opts.Name or "Button", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Btn })
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
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Holder, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset - 60, 1, 0), Font = Theme.Font, Text = opts.Name or "Toggle", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local Switch = Create("TextButton", { BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight, Position = UDim2.new(1, -50, 0.5, -10), Size = UDim2.new(0, 40, 0, 20), Text = "", AutoButtonColor = false, Parent = Holder }, { Corner(10) })
			local Dot = Create("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = state and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7), Size = UDim2.new(0, 14, 0, 14), Parent = Switch }, { Corner(7) })

			table.insert(Window._accentListeners, function(c)
				if state then Switch.BackgroundColor3 = c end
			end)

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
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 50), Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Holder, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 6), Size = UDim2.new(1, -textOffset - 68, 0, 18), Font = Theme.Font, Text = opts.Name or "Slider", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local ValueLabel = Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(1, -60, 0, 6), Size = UDim2.new(0, 48, 0, 18), Font = Theme.FontBold, Text = tostring(value), TextColor3 = Theme.Accent, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Right, Parent = Holder })
			local Track = Create("Frame", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 12, 0, 32), Size = UDim2.new(1, -24, 0, 8), Parent = Holder }, { Corner(4) })
			local function ratio(v) return math.clamp((v - min) / (max - min), 0, 1) end
			local Fill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(ratio(value), 0, 1, 0), Parent = Track }, { Corner(4) })
			local Knob = Create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(ratio(value), 0, 0.5, 0), Size = UDim2.new(0, 16, 0, 16), BackgroundColor3 = Color3.fromRGB(255, 255, 255), Parent = Track }, { Corner(8) })

			table.insert(Window._accentListeners, function(c)
				Fill.BackgroundColor3 = c
				ValueLabel.TextColor3 = c
			end)

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
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Holder, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset - 120, 0, 38), Font = Theme.Font, Text = opts.Name or "Dropdown", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local SelectedBtn = Create("TextButton", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -110, 0, 6), Size = UDim2.new(0, 98, 0, 26), Font = Theme.Font, Text = current, TextColor3 = Theme.Text, TextSize = 12, AutoButtonColor = false, Parent = Holder }, { Corner(6) })
			local OptionList = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 40), Size = UDim2.new(1, 0, 0, #options * 30), Parent = Holder }, { Create("UIListLayout", { Padding = UDim.new(0, 4) }), Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
			for _, optionName in ipairs(options) do
				local OptBtn = Create("TextButton", { BackgroundColor3 = Theme.SurfaceLight, Size = UDim2.new(1, 0, 0, 26), Font = Theme.Font, Text = optionName, TextColor3 = Theme.SubText, TextSize = 12, AutoButtonColor = false, Parent = OptionList }, { Corner(6) })
				OptBtn.MouseButton1Click:Connect(function() current = optionName; SelectedBtn.Text = current; open = false; Tween(Holder, { Size = UDim2.new(1, 0, 0, 38) }, 0.2, Enum.EasingStyle.Quad); if opts.Callback then task.spawn(opts.Callback, current) end end)
			end
			SelectedBtn.MouseButton1Click:Connect(function() open = not open; Tween(Holder, { Size = UDim2.new(1, 0, 0, open and (40 + #options * 30 + 8) or 38) }, 0.25, Enum.EasingStyle.Quad) end)
			return { Set = function(_, v) current = v; SelectedBtn.Text = current end }
		end

		function Tab:CreateInput(opts)
			opts = opts or {}
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Holder, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(0, 110, 1, 0), Font = Theme.Font, Text = opts.Name or "Input", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local TextBox = Create("TextBox", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, textOffset + 116, 0, 6), Size = UDim2.new(1, -(textOffset + 128), 0, 26), Font = Theme.Font, PlaceholderText = opts.PlaceholderText or "", Text = "", TextColor3 = Theme.Text, PlaceholderColor3 = Theme.SubText, TextSize = 13, ClearTextOnFocus = false, Parent = Holder }, {Corner(6), Create("UIPadding", { PaddingLeft = UDim.new(0, 8) }) })
			TextBox.FocusLost:Connect(function(enterPressed) if opts.Callback then task.spawn(opts.Callback, TextBox.Text, enterPressed) end end)
			return TextBox
		end

		function Tab:CreateKeybind(opts)
			opts = opts or {}
			local currentKey, isListening = opts.CurrentKey or Enum.KeyCode.E, false
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Holder, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset - 100, 1, 0), Font = Theme.Font, Text = opts.Name or "Keybind", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local KeyBtn = Create("TextButton", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(1, -82, 0.5, -12), Size = UDim2.new(0, 70, 0, 24), Font = Theme.FontBold, Text = currentKey.Name, TextColor3 = Theme.Text, TextSize = 12, AutoButtonColor = false, Parent = Holder }, { Corner(6) })
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
			local Holder = Create("Frame", { BackgroundColor3 = Theme.Surface, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true, Parent = TabPage }, { Corner(8) })
			local textOffset, _ = AddIcon(Holder, opts.Icon, 12, Theme.Text)
			Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, textOffset, 0, 0), Size = UDim2.new(1, -textOffset - 100, 0, 38), Font = Theme.Font, Text = opts.Name or "Color Picker", TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = Holder })
			local ColorPreview = Create("TextButton", { BackgroundColor3 = defaultColor, Position = UDim2.new(1, -48, 0, 7), Size = UDim2.new(0, 36, 0, 24), Text = "", Parent = Holder }, { Corner(6) })
			local ContentFrame = Create("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 0, 90), Parent = Holder })

			local function createColorSlider(name, defaultVal, yPos, callback)
				local SliderTrack = Create("Frame", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 12, 0, yPos), Size = UDim2.new(1, -24, 0, 18), Parent = ContentFrame }, { Corner(6) })
				Create("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0, 30, 1, 0), Font = Theme.FontBold, Text = name, TextColor3 = Color3.fromRGB(255,255,255), TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = SliderTrack })
				local SliderFill = Create("Frame", { BackgroundColor3 = Theme.Accent, Size = UDim2.new(defaultVal / 255, 0, 1, 0), BackgroundTransparency = 0.4, Parent = SliderTrack }, { Corner(6) })
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


		local ProgressTrack = Create("Frame", { BackgroundColor3 = Theme.SurfaceLight, Position = UDim2.new(0, 16, 1, -6), Size = UDim2.new(1, -32, 0, 3), Parent = Notif })
		local ProgressFill = Create("Frame", { BackgroundColor3 = typeColor, Size = UDim2.new(1, 0, 1, 0), Parent = ProgressTrack })

		Create("UIPadding", { PaddingBottom = UDim.new(0, 16) }).Parent = Notif

		Tween(Notif, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back)
		Tween(Scale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)

		task.delay(0.1, function()
			Tween(ProgressFill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)
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
