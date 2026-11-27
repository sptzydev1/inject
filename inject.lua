--!strict
-- Plugin Studio Lite (Delta Executor Edition) by Ikyy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OLD_GUI = PlayerGui:FindFirstChild("IkyyPluginStudioLite_GUI")
if OLD_GUI then
	OLD_GUI:Destroy()
end

local OLD_SOUND_GROUP = SoundService:FindFirstChild("IkyyStudioLite_MusicGroup")
if OLD_SOUND_GROUP then
	OLD_SOUND_GROUP:Destroy()
end

-- ==========================================
-- KONFIGURASI, TEMA & STATE
-- ==========================================
export type GuiTheme = {
	name: string,
	accent: Color3,
	accentSoft: Color3,
	stroke: Color3,
	gradStart: Color3,
	gradEnd: Color3,
	eqEven: Color3,
	eqOdd: Color3,
}

export type FontPreset = {
	name: string,
	font: Enum.Font,
	boldFont: Enum.Font,
}

export type SearchMatch = {
	sourceType: string,
	fullName: string,
	detail: string,
}

local GUI_THEMES: {GuiTheme} = {
	{
		name = "Violet Neon",
		accent = Color3.fromRGB(108, 86, 245),
		accentSoft = Color3.fromRGB(52, 46, 86),
		stroke = Color3.fromRGB(92, 72, 168),
		gradStart = Color3.fromRGB(22, 20, 34),
		gradEnd = Color3.fromRGB(13, 12, 20),
		eqEven = Color3.fromRGB(122, 98, 255),
		eqOdd = Color3.fromRGB(80, 210, 255),
	},
	{
		name = "Cyan Cyber",
		accent = Color3.fromRGB(14, 165, 233),
		accentSoft = Color3.fromRGB(22, 62, 86),
		stroke = Color3.fromRGB(34, 150, 210),
		gradStart = Color3.fromRGB(14, 24, 34),
		gradEnd = Color3.fromRGB(10, 15, 22),
		eqEven = Color3.fromRGB(34, 211, 238),
		eqOdd = Color3.fromRGB(59, 130, 246),
	},
	{
		name = "Magenta Glow",
		accent = Color3.fromRGB(217, 70, 239),
		accentSoft = Color3.fromRGB(82, 34, 92),
		stroke = Color3.fromRGB(185, 68, 205),
		gradStart = Color3.fromRGB(28, 16, 34),
		gradEnd = Color3.fromRGB(16, 10, 22),
		eqEven = Color3.fromRGB(232, 121, 249),
		eqOdd = Color3.fromRGB(251, 113, 133),
	},
	{
		name = "Crimson Dark",
		accent = Color3.fromRGB(225, 29, 72),
		accentSoft = Color3.fromRGB(84, 26, 40),
		stroke = Color3.fromRGB(180, 48, 76),
		gradStart = Color3.fromRGB(30, 15, 20),
		gradEnd = Color3.fromRGB(16, 10, 14),
		eqEven = Color3.fromRGB(244, 63, 94),
		eqOdd = Color3.fromRGB(251, 146, 60),
	},
}

local FONT_PRESETS: {FontPreset} = {
	{ name = "Gotham", font = Enum.Font.GothamMedium, boldFont = Enum.Font.GothamBold },
	{ name = "FredokaOne", font = Enum.Font.FredokaOne, boldFont = Enum.Font.FredokaOne },
	{ name = "RobotoMono", font = Enum.Font.RobotoMono, boldFont = Enum.Font.RobotoMono },
	{ name = "Arcade", font = Enum.Font.Arcade, boldFont = Enum.Font.Arcade },
}

local CONFIG = {
	WorkspaceRoot = "IkyyStudioLite",
	IsMinimized = false,
	ActiveTab = "Music",
	ThemeIndex = 1,
	FontIndex = 1,
}

export type MusicTrack = {
	name: string,
	songId: string,
	playbackSpeed: number,
}

local DEFAULT_MUSIC_PLAYLIST: {MusicTrack} = {
	{ name = "ONE NIGHT MORE", songId = "132909271866353", playbackSpeed = 1.0 },
	{ name = "ALAMAK", songId = "135551858111362", playbackSpeed = 1.0 },
	{ name = "TANTAE", songId = "116647235474599", playbackSpeed = 1.0 },
	{ name = "INDO REMIX", songId = "16662832435", playbackSpeed = 1.0 },
	{ name = "CHICA LOCA", songId = "127933835766961", playbackSpeed = 1.0 },
	{ name = "BREAKBEAT 1", songId = "115259177751410", playbackSpeed = 1.0 },
	{ name = "CINTAKU ISTIMEWAH", songId = "77152319144498", playbackSpeed = 1.0 },
	{ name = "BLOODLINE MENGKANE", songId = "87291197916136", playbackSpeed = 1.0 },
}

local WINDOW_SIZE = UDim2.fromOffset(540, 320)
local WINDOW_POS = UDim2.new(0.5, -270, 0.5, -160)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS

local function getUserAvatarAsync(userId: number): string
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and type(content) == "string" and content ~= "" then
		return content
	end
	return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function copyTextToClipboard(text: string): boolean
	local fn = (getgenv and getgenv().setclipboard) or (setclipboard :: any)
	if type(fn) == "function" then
		local ok = pcall(function()
			fn(text)
		end)
		return ok
	end
	return false
end

-- ==========================================
-- UI UTAMA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IkyyPluginStudioLite_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- 1. IKON LINGKARAN PROFILE USER (42x42, DRAGGABLE)
local FloatingProfileBtn = Instance.new("ImageButton")
FloatingProfileBtn.Name = "FloatingProfileToggle"
FloatingProfileBtn.Size = ICON_SIZE
FloatingProfileBtn.Position = ICON_DEFAULT_POS
FloatingProfileBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
FloatingProfileBtn.BorderSizePixel = 0
FloatingProfileBtn.Visible = false
FloatingProfileBtn.AutoButtonColor = false
FloatingProfileBtn.ZIndex = 50
FloatingProfileBtn.Image = getUserAvatarAsync(LocalPlayer.UserId)
FloatingProfileBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingProfileBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingProfileBtn)
FloatStroke.Color = Color3.fromRGB(130, 92, 255)
FloatStroke.Thickness = 2

-- 2. WINDOW UTAMA (540x320)
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = WINDOW_SIZE
MainWindow.Position = WINDOW_POS
MainWindow.BackgroundColor3 = Color3.fromRGB(16, 15, 24)
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 14)
local MainStroke = Instance.new("UIStroke", MainWindow)
MainStroke.Color = Color3.fromRGB(92, 72, 168)
MainStroke.Thickness = 1.4
MainStroke.Transparency = 0.25

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 20, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 12, 20)),
})
MainGradient.Rotation = 135
MainGradient.Parent = MainWindow

-- ==========================================
-- HEADER BAR
-- ==========================================
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 44)
HeaderBar.BackgroundColor3 = Color3.fromRGB(20, 19, 30)
HeaderBar.BackgroundTransparency = 0.25
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainWindow

local HeaderLogoBox = Instance.new("Frame")
HeaderLogoBox.Size = UDim2.fromOffset(28, 28)
HeaderLogoBox.Position = UDim2.new(0, 12, 0.5, -14)
HeaderLogoBox.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
HeaderLogoBox.BorderSizePixel = 0
HeaderLogoBox.Parent = HeaderBar
Instance.new("UICorner", HeaderLogoBox).CornerRadius = UDim.new(0, 8)
local LogoStroke = Instance.new("UIStroke", HeaderLogoBox)
LogoStroke.Color = Color3.fromRGB(95, 85, 145)
LogoStroke.Thickness = 1

local LogoIcon = Instance.new("TextLabel")
LogoIcon.Size = UDim2.fromScale(1, 1)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Text = "🎵"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 14
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 230, 0, 11)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 5)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • DELTA EDITION"
SubTitleLabel.TextColor3 = Color3.fromRGB(130, 126, 155)
SubTitleLabel.TextSize = 8
SubTitleLabel.Font = Enum.Font.GothamBold
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 240, 0, 16)
TitleLabel.Position = UDim2.new(0, 48, 0, 15)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Plugin Studio Lite"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(0, 240, 0, 11)
MetaLabel.Position = UDim2.new(0, 48, 0, 31)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "by Ikyy • v1.5.0 • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
MetaLabel.TextSize = 8
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.Parent = HeaderBar

local CloseCircleBtn = Instance.new("TextButton")
CloseCircleBtn.Name = "CloseToCircleBtn"
CloseCircleBtn.Size = UDim2.fromOffset(28, 28)
CloseCircleBtn.Position = UDim2.new(1, -40, 0.5, -14)
CloseCircleBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 50)
CloseCircleBtn.Text = "❌"
CloseCircleBtn.TextColor3 = Color3.fromRGB(255, 110, 125)
CloseCircleBtn.TextSize = 12
CloseCircleBtn.Font = Enum.Font.GothamBold
CloseCircleBtn.Parent = HeaderBar
Instance.new("UICorner", CloseCircleBtn).CornerRadius = UDim.new(1, 0)
local CloseStroke = Instance.new("UIStroke", CloseCircleBtn)
CloseStroke.Color = Color3.fromRGB(115, 65, 95)
CloseStroke.Thickness = 1

local function setMinimized(minimized: boolean)
	CONFIG.IsMinimized = minimized
	if minimized then
		local tw = TweenService:Create(MainWindow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = ICON_SIZE,
			Position = currentIconPos,
		})
		tw:Play()
		tw.Completed:Connect(function()
			if CONFIG.IsMinimized then
				MainWindow.Visible = false
				FloatingProfileBtn.Position = currentIconPos
				FloatingProfileBtn.Size = ICON_SIZE
				FloatingProfileBtn.Visible = true
			end
		end)
	else
		FloatingProfileBtn.Visible = false
		MainWindow.Position = currentIconPos
		MainWindow.Size = ICON_SIZE
		MainWindow.Visible = true
		TweenService:Create(MainWindow, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = WINDOW_SIZE,
			Position = WINDOW_POS,
		}):Play()
	end
end

-- Geser luas ikon profil
do
	local dragging = false
	local movedSignificantly = false
	local dragStart = Vector3.zero
	local startPos = UDim2.new()
	local activeInput: InputObject? = nil
	local DRAG_THRESHOLD = 6

	local function clampToViewport(pos: UDim2): UDim2
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local iconW = ICON_SIZE.X.Offset
		local iconH = ICON_SIZE.Y.Offset
		local pad = 6
		local maxX = math.max(pad, viewport.X - iconW - pad)
		local maxY = math.max(pad, viewport.Y - iconH - pad)
		return UDim2.fromOffset(math.clamp(pos.X.Offset, pad, maxX), math.clamp(pos.Y.Offset, pad, maxY))
	end

	local function getCurrentOffsetPos(): UDim2
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local absX = (FloatingProfileBtn.Position.X.Scale * viewport.X) + FloatingProfileBtn.Position.X.Offset
		local absY = (FloatingProfileBtn.Position.Y.Scale * viewport.Y) + FloatingProfileBtn.Position.Y.Offset
		return UDim2.fromOffset(absX, absY)
	end

	FloatingProfileBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			movedSignificantly = false
			activeInput = input
			dragStart = input.Position
			startPos = getCurrentOffsetPos()
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging or input ~= activeInput then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			if delta.Magnitude > DRAG_THRESHOLD then
				movedSignificantly = true
			end
			local nextPos = clampToViewport(UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y))
			currentIconPos = nextPos
			FloatingProfileBtn.Position = nextPos
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == activeInput then
			local wasClick = dragging and not movedSignificantly
			dragging = false
			activeInput = nil
			if wasClick and CONFIG.IsMinimized then
				setMinimized(false)
			end
		end
	end)
end

CloseCircleBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

-- ==========================================
-- SIDEBAR KIRI
-- ==========================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 126, 1, -54)
Sidebar.Position = UDim2.new(0, 10, 0, 48)
Sidebar.BackgroundColor3 = Color3.fromRGB(21, 20, 32)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
local SideStroke = Instance.new("UIStroke", Sidebar)
SideStroke.Color = Color3.fromRGB(52, 48, 82)
SideStroke.Thickness = 1

local NavScroll = Instance.new("ScrollingFrame")
NavScroll.Size = UDim2.new(1, -10, 1, -10)
NavScroll.Position = UDim2.new(0, 5, 0, 5)
NavScroll.BackgroundTransparency = 1
NavScroll.BorderSizePixel = 0
NavScroll.ScrollBarThickness = 2
NavScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
NavScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavScroll.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavScroll

local tabPages: {[string]: Frame} = {}
local tabButtons: {[string]: TextButton} = {}
local applyThemeAndFont: () -> () = function() end

local function createNavButton(name: string, label: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = "Nav_" .. name
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
	btn.Text = "  " .. label
	btn.TextColor3 = Color3.fromRGB(185, 182, 210)
	btn.TextSize = 10
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Parent = NavScroll
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
	tabButtons[name] = btn
	return btn
end

-- ==========================================
-- AREA KONTEN KANAN
-- ==========================================
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -152, 1, -54)
ContentArea.Position = UDim2.new(0, 142, 0, 48)
ContentArea.BackgroundColor3 = Color3.fromRGB(20, 19, 30)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWindow
Instance.new("UICorner", ContentArea).CornerRadius = UDim.new(0, 10)
local ContStroke = Instance.new("UIStroke", ContentArea)
ContStroke.Color = Color3.fromRGB(52, 48, 82)
ContStroke.Thickness = 1

local function switchTab(tabName: string)
	CONFIG.ActiveTab = tabName
	for name, page in pairs(tabPages) do
		page.Visible = (name == tabName)
	end
	applyThemeAndFont()
end

-- ==========================================
-- HALAMAN 1: MUSIC PLAYER (EQUALIZER + LOOP LOADING + VOLUME + << / ▶⏸ / >>)
-- ==========================================
local MusicPage = Instance.new("Frame")
MusicPage.Size = UDim2.fromScale(1, 1)
MusicPage.BackgroundTransparency = 1
MusicPage.Visible = true
MusicPage.Parent = ContentArea
tabPages["Music"] = MusicPage

local MusicTrackLabel = Instance.new("TextLabel")
MusicTrackLabel.Size = UDim2.new(1, -24, 0, 15)
MusicTrackLabel.Position = UDim2.new(0, 12, 0, 4)
MusicTrackLabel.BackgroundTransparency = 1
MusicTrackLabel.Text = "♪ " .. DEFAULT_MUSIC_PLAYLIST[1].name .. " (" .. DEFAULT_MUSIC_PLAYLIST[1].songId .. ")"
MusicTrackLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
MusicTrackLabel.TextSize = 11
MusicTrackLabel.Font = Enum.Font.GothamBold
MusicTrackLabel.TextTruncate = Enum.TextTruncate.AtEnd
MusicTrackLabel.Parent = MusicPage

local MusicStatusLabel = Instance.new("TextLabel")
MusicStatusLabel.Size = UDim2.new(1, -24, 0, 12)
MusicStatusLabel.Position = UDim2.new(0, 12, 0, 19)
MusicStatusLabel.BackgroundTransparency = 1
MusicStatusLabel.Text = "Siap diputar • Vol: 50%"
MusicStatusLabel.TextColor3 = Color3.fromRGB(150, 146, 182)
MusicStatusLabel.TextSize = 8
MusicStatusLabel.Font = Enum.Font.GothamMedium
MusicStatusLabel.Parent = MusicPage

-- Equalizer di tengah sesuai beat musik
local EqFrame = Instance.new("Frame")
EqFrame.Name = "EqualizerFrame"
EqFrame.Size = UDim2.new(1, -24, 0, 44)
EqFrame.Position = UDim2.new(0, 12, 0, 34)
EqFrame.BackgroundColor3 = Color3.fromRGB(13, 12, 21)
EqFrame.BorderSizePixel = 0
EqFrame.Parent = MusicPage
Instance.new("UICorner", EqFrame).CornerRadius = UDim.new(0, 8)
local EqStroke = Instance.new("UIStroke", EqFrame)
EqStroke.Color = Color3.fromRGB(64, 56, 108)
EqStroke.Thickness = 1

local EqBarsContainer = Instance.new("Frame")
EqBarsContainer.Size = UDim2.new(0, 220, 0, 32)
EqBarsContainer.Position = UDim2.new(0.5, -110, 0.5, -16)
EqBarsContainer.BackgroundTransparency = 1
EqBarsContainer.Parent = EqFrame

local eqBars: {Frame} = {}
local eqBarCount = 14
local eqGap = 4
local eqBarW = math.floor((220 - (eqGap * (eqBarCount - 1))) / eqBarCount)

for i = 1, eqBarCount do
	local bar = Instance.new("Frame")
	bar.Size = UDim2.fromOffset(eqBarW, 6)
	bar.Position = UDim2.fromOffset((i - 1) * (eqBarW + eqGap), 26)
	bar.BackgroundColor3 = (i % 2 == 0) and Color3.fromRGB(122, 98, 255) or Color3.fromRGB(80, 210, 255)
	bar.BorderSizePixel = 0
	bar.Parent = EqBarsContainer
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	table.insert(eqBars, bar)
end

-- Loop loading bar
local MusicLoadTrack = Instance.new("Frame")
MusicLoadTrack.Size = UDim2.new(1, -24, 0, 5)
MusicLoadTrack.Position = UDim2.new(0, 12, 0, 82)
MusicLoadTrack.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
MusicLoadTrack.BorderSizePixel = 0
MusicLoadTrack.Parent = MusicPage
Instance.new("UICorner", MusicLoadTrack).CornerRadius = UDim.new(1, 0)

local MusicLoadFill = Instance.new("Frame")
MusicLoadFill.Size = UDim2.new(0.25, 0, 1, 0)
MusicLoadFill.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
MusicLoadFill.BorderSizePixel = 0
MusicLoadFill.Parent = MusicLoadTrack
Instance.new("UICorner", MusicLoadFill).CornerRadius = UDim.new(1, 0)

-- Slider volume kanan-kiri
local VolumeRow = Instance.new("Frame")
VolumeRow.Size = UDim2.new(1, -24, 0, 20)
VolumeRow.Position = UDim2.new(0, 12, 0, 91)
VolumeRow.BackgroundTransparency = 1
VolumeRow.Parent = MusicPage

local VolLabel = Instance.new("TextLabel")
VolLabel.Size = UDim2.new(0, 74, 1, 0)
VolLabel.BackgroundTransparency = 1
VolLabel.Text = "🔊 Vol: 50%"
VolLabel.TextColor3 = Color3.fromRGB(205, 202, 230)
VolLabel.TextSize = 9
VolLabel.Font = Enum.Font.GothamBold
VolLabel.TextXAlignment = Enum.TextXAlignment.Left
VolLabel.Parent = VolumeRow

local VolSliderBg = Instance.new("Frame")
VolSliderBg.Size = UDim2.new(1, -80, 0, 8)
VolSliderBg.Position = UDim2.new(0, 78, 0.5, -4)
VolSliderBg.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
VolSliderBg.BorderSizePixel = 0
VolSliderBg.Parent = VolumeRow
Instance.new("UICorner", VolSliderBg).CornerRadius = UDim.new(1, 0)

local VolSliderFill = Instance.new("Frame")
VolSliderFill.Size = UDim2.new(0.5, 0, 1, 0)
VolSliderFill.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
VolSliderFill.BorderSizePixel = 0
VolSliderFill.Parent = VolSliderBg
Instance.new("UICorner", VolSliderFill).CornerRadius = UDim.new(1, 0)

local VolKnob = Instance.new("TextButton")
VolKnob.Size = UDim2.fromOffset(14, 14)
VolKnob.Position = UDim2.new(0.5, -7, 0.5, -7)
VolKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
VolKnob.Text = ""
VolKnob.AutoButtonColor = false
VolKnob.Parent = VolSliderBg
Instance.new("UICorner", VolKnob).CornerRadius = UDim.new(1, 0)

-- Tombol kontrol: kiri (<<), tengah (Play/Jeda), kanan (>>)
local ControlsRow = Instance.new("Frame")
ControlsRow.Size = UDim2.new(1, -24, 0, 26)
ControlsRow.Position = UDim2.new(0, 12, 0, 114)
ControlsRow.BackgroundTransparency = 1
ControlsRow.Parent = MusicPage

local PrevTrackBtn = Instance.new("TextButton")
PrevTrackBtn.Size = UDim2.new(0.28, -4, 1, 0)
PrevTrackBtn.Position = UDim2.new(0, 0, 0, 0)
PrevTrackBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
PrevTrackBtn.Text = "<<"
PrevTrackBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
PrevTrackBtn.TextSize = 11
PrevTrackBtn.Font = Enum.Font.GothamBold
PrevTrackBtn.Parent = ControlsRow
Instance.new("UICorner", PrevTrackBtn).CornerRadius = UDim.new(0, 7)

local PlayPauseBtn = Instance.new("TextButton")
PlayPauseBtn.Size = UDim2.new(0.44, -4, 1, 0)
PlayPauseBtn.Position = UDim2.new(0.28, 2, 0, 0)
PlayPauseBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
PlayPauseBtn.Text = "▶ PLAY"
PlayPauseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayPauseBtn.TextSize = 10
PlayPauseBtn.Font = Enum.Font.GothamBold
PlayPauseBtn.Parent = ControlsRow
Instance.new("UICorner", PlayPauseBtn).CornerRadius = UDim.new(0, 7)

local NextTrackBtn = Instance.new("TextButton")
NextTrackBtn.Size = UDim2.new(0.28, -4, 1, 0)
NextTrackBtn.Position = UDim2.new(0.72, 2, 0, 0)
NextTrackBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
NextTrackBtn.Text = ">>"
NextTrackBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
NextTrackBtn.TextSize = 11
NextTrackBtn.Font = Enum.Font.GothamBold
NextTrackBtn.Parent = ControlsRow
Instance.new("UICorner", NextTrackBtn).CornerRadius = UDim.new(0, 7)

-- List Musik
local PlaylistScroll = Instance.new("ScrollingFrame")
PlaylistScroll.Size = UDim2.new(1, -24, 0, 108)
PlaylistScroll.Position = UDim2.new(0, 12, 0, 144)
PlaylistScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
PlaylistScroll.BorderSizePixel = 0
PlaylistScroll.ScrollBarThickness = 3
PlaylistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlaylistScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlaylistScroll.Parent = MusicPage
Instance.new("UICorner", PlaylistScroll).CornerRadius = UDim.new(0, 7)
local PlStroke = Instance.new("UIStroke", PlaylistScroll)
PlStroke.Color = Color3.fromRGB(48, 44, 74)
PlStroke.Thickness = 1

local PlLayout = Instance.new("UIListLayout")
PlLayout.Padding = UDim.new(0, 3)
PlLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlLayout.Parent = PlaylistScroll

local PlPad = Instance.new("UIPadding")
PlPad.PaddingTop = UDim.new(0, 4)
PlPad.PaddingBottom = UDim.new(0, 4)
PlPad.PaddingLeft = UDim.new(0, 4)
PlPad.PaddingRight = UDim.new(0, 4)
PlPad.Parent = PlaylistScroll

local MusicGroup = Instance.new("SoundGroup")
MusicGroup.Name = "IkyyStudioLite_MusicGroup"
MusicGroup.Volume = 0.5
MusicGroup.Parent = SoundService

local MusicSound = Instance.new("Sound")
MusicSound.Name = "IkyyStudioLite_TrackSound"
MusicSound.SoundGroup = MusicGroup
MusicSound.Looped = true
MusicSound.Parent = MusicGroup

local currentTrackIndex = 1
local isPlayingMusic = false
local isLoadingTrack = false
local currentVolumeRatio = 0.5

local function applyVolume(ratio: number)
	currentVolumeRatio = math.clamp(ratio, 0, 1)
	MusicGroup.Volume = currentVolumeRatio
	MusicSound.Volume = currentVolumeRatio
	VolSliderFill.Size = UDim2.new(currentVolumeRatio, 0, 1, 0)
	VolKnob.Position = UDim2.new(currentVolumeRatio, -7, 0.5, -7)
	local pct = math.floor(currentVolumeRatio * 100 + 0.5)
	VolLabel.Text = "🔊 Vol: " .. tostring(pct) .. "%"
	if not isLoadingTrack then
		MusicStatusLabel.Text = (isPlayingMusic and "Memutar" or "Dijeda") .. " • Vol: " .. tostring(pct) .. "%"
	end
end

local function renderMusicPlaylist()
	local theme = GUI_THEMES[CONFIG.ThemeIndex]
	local fontPreset = FONT_PRESETS[CONFIG.FontIndex]

	for _, child in ipairs(PlaylistScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for idx, tr in ipairs(DEFAULT_MUSIC_PLAYLIST) do
		local active = (idx == currentTrackIndex)
		local itemBtn = Instance.new("TextButton")
		itemBtn.Size = UDim2.new(1, -4, 0, 22)
		itemBtn.BackgroundColor3 = active and theme.accentSoft or Color3.fromRGB(22, 21, 34)
		itemBtn.Text = string.format("  %d. %s  [%s]", idx, tr.name, tr.songId)
		itemBtn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 188, 215)
		itemBtn.TextSize = 9
		itemBtn.Font = active and fontPreset.boldFont or fontPreset.font
		itemBtn.TextXAlignment = Enum.TextXAlignment.Left
		itemBtn.TextTruncate = Enum.TextTruncate.AtEnd
		itemBtn.LayoutOrder = idx
		itemBtn.Parent = PlaylistScroll
		Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 5)

		itemBtn.MouseButton1Click:Connect(function()
			currentTrackIndex = idx
			isPlayingMusic = true
			PlayPauseBtn.Text = "⏸ JEDA"
			renderMusicPlaylist()
			local chosen = DEFAULT_MUSIC_PLAYLIST[currentTrackIndex]
			MusicTrackLabel.Text = "♪ " .. chosen.name .. " (" .. chosen.songId .. ")"
			isLoadingTrack = true
			MusicStatusLabel.Text = "Memuat audio " .. chosen.songId .. "..."
			MusicSound.SoundId = "rbxassetid://" .. chosen.songId
			MusicSound.PlaybackSpeed = chosen.playbackSpeed
			MusicSound.Volume = currentVolumeRatio
			pcall(function()
				MusicSound:Play()
			end)
			task.delay(0.8, function()
				if currentTrackIndex == idx then
					isLoadingTrack = false
					local pct = math.floor(currentVolumeRatio * 100 + 0.5)
					MusicStatusLabel.Text = (isPlayingMusic and "Memutar" or "Dijeda") .. " • Vol: " .. tostring(pct) .. "%"
				end
			end)
		end)
	end
end

local function loadAndPlayTrack(index: number, shouldPlay: boolean)
	if index < 1 then
		index = #DEFAULT_MUSIC_PLAYLIST
	elseif index > #DEFAULT_MUSIC_PLAYLIST then
		index = 1
	end
	currentTrackIndex = index
	local tr = DEFAULT_MUSIC_PLAYLIST[currentTrackIndex]
	MusicTrackLabel.Text = "♪ " .. tr.name .. " (" .. tr.songId .. ")"
	isPlayingMusic = shouldPlay
	PlayPauseBtn.Text = shouldPlay and "⏸ JEDA" or "▶ PLAY"
	renderMusicPlaylist()

	isLoadingTrack = true
	MusicStatusLabel.Text = "Memuat lagu: " .. tr.name .. "..."
	MusicSound.SoundId = "rbxassetid://" .. tr.songId
	MusicSound.PlaybackSpeed = tr.playbackSpeed
	MusicSound.Volume = currentVolumeRatio

	if shouldPlay then
		pcall(function()
			MusicSound:Play()
		end)
	else
		pcall(function()
			MusicSound:Pause()
		end)
	end

	task.delay(0.8, function()
		if currentTrackIndex == index then
			isLoadingTrack = false
			local pct = math.floor(currentVolumeRatio * 100 + 0.5)
			MusicStatusLabel.Text = (isPlayingMusic and "Memutar" or "Dijeda") .. " • Vol: " .. tostring(pct) .. "%"
		end
	end)
end

PlayPauseBtn.MouseButton1Click:Connect(function()
	if not isPlayingMusic then
		if MusicSound.SoundId == "" then
			loadAndPlayTrack(currentTrackIndex, true)
		else
			isPlayingMusic = true
			PlayPauseBtn.Text = "⏸ JEDA"
			MusicSound.Volume = currentVolumeRatio
			pcall(function()
				MusicSound:Play()
			end)
			local pct = math.floor(currentVolumeRatio * 100 + 0.5)
			MusicStatusLabel.Text = "Memutar • Vol: " .. tostring(pct) .. "%"
		end
	else
		isPlayingMusic = false
		PlayPauseBtn.Text = "▶ PLAY"
		pcall(function()
			MusicSound:Pause()
		end)
		local pct = math.floor(currentVolumeRatio * 100 + 0.5)
		MusicStatusLabel.Text = "Dijeda • Vol: " .. tostring(pct) .. "%"
	end
end)

PrevTrackBtn.MouseButton1Click:Connect(function()
	loadAndPlayTrack(currentTrackIndex - 1, true)
end)

NextTrackBtn.MouseButton1Click:Connect(function()
	loadAndPlayTrack(currentTrackIndex + 1, true)
end)

-- Drag slider volume kanan-kiri
do
	local draggingVol = false
	local function updateVolFromInput(inputPos: Vector2)
		local absPos = VolSliderBg.AbsolutePosition.X
		local absW = math.max(1, VolSliderBg.AbsoluteSize.X)
		local ratio = math.clamp((inputPos.X - absPos) / absW, 0, 1)
		applyVolume(ratio)
	end

	VolSliderBg.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingVol = true
			updateVolFromInput(input.Position)
		end
	end)

	VolKnob.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingVol = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not draggingVol then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateVolFromInput(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingVol = false
		end
	end)
end

renderMusicPlaylist()
applyVolume(0.5)

-- Animasi Equalizer & Loop Loading
do
	local elapsed = 0
	RunService.RenderStepped:Connect(function(dt: number)
		elapsed += dt
		local theme = GUI_THEMES[CONFIG.ThemeIndex]
		if isLoadingTrack then
			local pos = (elapsed * 0.65) % 1
			MusicLoadFill.Size = UDim2.new(0.28, 0, 1, 0)
			MusicLoadFill.Position = UDim2.new(pos * 0.72, 0, 0, 0)
			MusicLoadFill.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
		elseif isPlayingMusic then
			MusicLoadFill.Size = UDim2.new(1, 0, 1, 0)
			MusicLoadFill.Position = UDim2.new(0, 0, 0, 0)
			MusicLoadFill.BackgroundColor3 = Color3.fromRGB(56, 239, 125)
		else
			MusicLoadFill.Size = UDim2.new(0, 0, 1, 0)
			MusicLoadFill.Position = UDim2.new(0, 0, 0, 0)
		end

		local activeBeat = isPlayingMusic and (not isLoadingTrack)
		local volBoost = math.max(0.25, currentVolumeRatio * 1.4)
		for i, bar in ipairs(eqBars) do
			bar.BackgroundColor3 = (i % 2 == 0) and theme.eqEven or theme.eqOdd
			local targetH = 5
			if activeBeat then
				local waveA = math.abs(math.sin(elapsed * 9.5 + i * 0.65))
				local waveB = math.abs(math.cos(elapsed * 5.2 - i * 0.4))
				local amp = math.clamp((waveA * 0.7 + waveB * 0.3) * volBoost, 0.18, 1.0)
				targetH = math.floor(5 + amp * 25)
			else
				targetH = 5
			end
			bar.Size = UDim2.fromOffset(eqBarW, targetH)
			bar.Position = UDim2.fromOffset((i - 1) * (eqBarW + eqGap), 32 - targetH)
		end
	end)
end

-- ==========================================
-- HALAMAN 2: ID SEARCH (CARI LETAK ID MUSIK / TEKS DI GAME)
-- ==========================================
local SearchPage = Instance.new("Frame")
SearchPage.Name = "SearchPage"
SearchPage.Size = UDim2.fromScale(1, 1)
SearchPage.BackgroundTransparency = 1
SearchPage.Visible = false
SearchPage.Parent = ContentArea
tabPages["Search"] = SearchPage

local SearchHeaderLabel = Instance.new("TextLabel")
SearchHeaderLabel.Size = UDim2.new(1, -24, 0, 16)
SearchHeaderLabel.Position = UDim2.new(0, 12, 0, 6)
SearchHeaderLabel.BackgroundTransparency = 1
SearchHeaderLabel.Text = "🔎 Pencari ID Musik / Teks di Seluruh Objek"
SearchHeaderLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
SearchHeaderLabel.TextSize = 11
SearchHeaderLabel.Font = Enum.Font.GothamBold
SearchHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
SearchHeaderLabel.Parent = SearchPage

local SearchInputRow = Instance.new("Frame")
SearchInputRow.Size = UDim2.new(1, -24, 0, 26)
SearchInputRow.Position = UDim2.new(0, 12, 0, 25)
SearchInputRow.BackgroundTransparency = 1
SearchInputRow.Parent = SearchPage

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchIdInput"
SearchBox.Size = UDim2.new(0.64, -4, 1, 0)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(13, 12, 21)
SearchBox.Text = ""
SearchBox.PlaceholderText = "Ketik ID musik (cth: 132909271866353)..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 142)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 9
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Parent = SearchInputRow
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SearchBoxStroke = Instance.new("UIStroke", SearchBox)
SearchBoxStroke.Color = Color3.fromRGB(64, 56, 108)
SearchBoxStroke.Thickness = 1

local SearchBoxPad = Instance.new("UIPadding")
SearchBoxPad.PaddingLeft = UDim.new(0, 8)
SearchBoxPad.PaddingRight = UDim.new(0, 8)
SearchBoxPad.Parent = SearchBox

local ScanIdBtn = Instance.new("TextButton")
ScanIdBtn.Name = "ScanIdBtn"
ScanIdBtn.Size = UDim2.new(0.20, -4, 1, 0)
ScanIdBtn.Position = UDim2.new(0.64, 2, 0, 0)
ScanIdBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ScanIdBtn.Text = "🔍 Cari"
ScanIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanIdBtn.TextSize = 9
ScanIdBtn.Font = Enum.Font.GothamBold
ScanIdBtn.Parent = SearchInputRow
Instance.new("UICorner", ScanIdBtn).CornerRadius = UDim.new(0, 6)

local ClearSearchBtn = Instance.new("TextButton")
ClearSearchBtn.Name = "ClearSearchBtn"
ClearSearchBtn.Size = UDim2.new(0.16, 0, 1, 0)
ClearSearchBtn.Position = UDim2.new(0.84, 2, 0, 0)
ClearSearchBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
ClearSearchBtn.Text = "Hapus"
ClearSearchBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
ClearSearchBtn.TextSize = 8
ClearSearchBtn.Font = Enum.Font.GothamBold
ClearSearchBtn.Parent = SearchInputRow
Instance.new("UICorner", ClearSearchBtn).CornerRadius = UDim.new(0, 6)

local SearchStatusLabel = Instance.new("TextLabel")
SearchStatusLabel.Size = UDim2.new(1, -24, 0, 14)
SearchStatusLabel.Position = UDim2.new(0, 12, 0, 54)
SearchStatusLabel.BackgroundTransparency = 1
SearchStatusLabel.Text = "Masukkan ID musik lalu tekan Cari (tap hasil untuk salin path)"
SearchStatusLabel.TextColor3 = Color3.fromRGB(150, 146, 182)
SearchStatusLabel.TextSize = 8
SearchStatusLabel.Font = Enum.Font.GothamMedium
SearchStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
SearchStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
SearchStatusLabel.Parent = SearchPage

local SearchResultsScroll = Instance.new("ScrollingFrame")
SearchResultsScroll.Size = UDim2.new(1, -24, 1, -78)
SearchResultsScroll.Position = UDim2.new(0, 12, 0, 71)
SearchResultsScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
SearchResultsScroll.BorderSizePixel = 0
SearchResultsScroll.ScrollBarThickness = 3
SearchResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SearchResultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SearchResultsScroll.Parent = SearchPage
Instance.new("UICorner", SearchResultsScroll).CornerRadius = UDim.new(0, 7)
local SearchResStroke = Instance.new("UIStroke", SearchResultsScroll)
SearchResStroke.Color = Color3.fromRGB(48, 44, 74)
SearchResStroke.Thickness = 1

local SearchResLayout = Instance.new("UIListLayout")
SearchResLayout.Padding = UDim.new(0, 4)
SearchResLayout.SortOrder = Enum.SortOrder.LayoutOrder
SearchResLayout.Parent = SearchResultsScroll

local SearchResPad = Instance.new("UIPadding")
SearchResPad.PaddingTop = UDim.new(0, 5)
SearchResPad.PaddingBottom = UDim.new(0, 5)
SearchResPad.PaddingLeft = UDim.new(0, 5)
SearchResPad.PaddingRight = UDim.new(0, 5)
SearchResPad.Parent = SearchResultsScroll

local lastSearchMatches: {SearchMatch} = {}

local function renderSearchResults(matches: {SearchMatch})
	local fontPreset = FONT_PRESETS[CONFIG.FontIndex]

	for _, child in ipairs(SearchResultsScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	if #matches == 0 then
		local emptyItem = Instance.new("TextButton")
		emptyItem.Size = UDim2.new(1, -4, 0, 24)
		emptyItem.BackgroundColor3 = Color3.fromRGB(22, 21, 34)
		emptyItem.Text = "  Tidak ada kecocokan ditemukan di objek yang dapat dipindai"
		emptyItem.TextColor3 = Color3.fromRGB(165, 162, 190)
		emptyItem.TextSize = 8
		emptyItem.Font = fontPreset.font
		emptyItem.TextXAlignment = Enum.TextXAlignment.Left
		emptyItem.LayoutOrder = 1
		emptyItem.Parent = SearchResultsScroll
		Instance.new("UICorner", emptyItem).CornerRadius = UDim.new(0, 5)
		return
	end

	for idx, item in ipairs(matches) do
		local resBtn = Instance.new("TextButton")
		resBtn.Size = UDim2.new(1, -4, 0, 28)
		resBtn.BackgroundColor3 = Color3.fromRGB(22, 21, 34)
		resBtn.Text = string.format("  #%d [%s] %s\n      %s", idx, item.sourceType, item.fullName, item.detail)
		resBtn.TextColor3 = Color3.fromRGB(225, 223, 248)
		resBtn.TextSize = 8
		resBtn.Font = fontPreset.font
		resBtn.TextXAlignment = Enum.TextXAlignment.Left
		resBtn.TextTruncate = Enum.TextTruncate.AtEnd
		resBtn.LayoutOrder = idx
		resBtn.Parent = SearchResultsScroll
		Instance.new("UICorner", resBtn).CornerRadius = UDim.new(0, 5)

		resBtn.MouseButton1Click:Connect(function()
			local copied = copyTextToClipboard(item.fullName)
			if copied then
				SearchStatusLabel.Text = "Disalin ke clipboard: " .. item.fullName
			else
				SearchStatusLabel.Text = "Letak: " .. item.fullName
			end
			print(string.format("[IDSearch][#%d][%s] %s (%s)", idx, item.sourceType, item.fullName, item.detail))
		end)
	end
end

local function runIdSearch(rawQuery: string)
	local trimmed = string.match(rawQuery, "^%s*(.-)%s*$") or ""
	if trimmed == "" then
		SearchStatusLabel.Text = "Masukkan ID musik atau teks terlebih dahulu"
		table.clear(lastSearchMatches)
		renderSearchResults(lastSearchMatches)
		return
	end

	local numericPart = string.match(trimmed, "%d+")
	local needle = (numericPart and numericPart ~= "") and numericPart or trimmed
	local assetNeedle = "rbxassetid://" .. needle
	local matches: {SearchMatch} = {}
	local scannedCount = 0

	local okDesc, descendants = pcall(function()
		return game:GetDescendants()
	end)

	if okDesc and descendants then
		for _, inst in ipairs(descendants) do
			scannedCount += 1

			local fullName = ""
			local okName, nameRes = pcall(function()
				return inst:GetFullName()
			end)
			if okName and type(nameRes) == "string" then
				fullName = nameRes
			else
				fullName = inst.Name
			end

			-- 1. Objek Sound
			local okSound, isSound = pcall(function()
				return inst:IsA("Sound")
			end)
			if okSound and isSound then
				local okId, soundId = pcall(function()
					return tostring(inst.SoundId)
				end)
				if okId and (string.find(soundId, needle, 1, true) or string.find(soundId, assetNeedle, 1, true)) then
					table.insert(matches, {
						sourceType = "Sound.SoundId",
						fullName = fullName,
						detail = soundId,
					})
				end
			end

			-- 2. StringValue
			local okStrVal, isStrVal = pcall(function()
				return inst:IsA("StringValue")
			end)
			if okStrVal and isStrVal then
				local okVal, valStr = pcall(function()
					return tostring(inst.Value)
				end)
				if okVal and string.find(valStr, needle, 1, true) then
					table.insert(matches, {
						sourceType = "StringValue",
						fullName = fullName,
						detail = "Cocok di Value",
					})
				end
			end

			-- 3. Attributes pada objek
			local okAttr, attrs = pcall(function()
				return inst:GetAttributes()
			end)
			if okAttr and type(attrs) == "table" then
				for attrName, attrVal in pairs(attrs) do
					if type(attrVal) == "string" and string.find(attrVal, needle, 1, true) then
						table.insert(matches, {
							sourceType = "Attribute:" .. tostring(attrName),
							fullName = fullName,
							detail = "Cocok di Attribute",
						})
					end
				end
			end

			-- 4. TextBox / TextLabel
			local okUi, isUiText = pcall(function()
				return inst:IsA("TextBox") or inst:IsA("TextLabel")
			end)
			if okUi and isUiText then
				local okTxt, txtVal = pcall(function()
					return tostring(inst.Text)
				end)
				if okTxt and string.find(txtVal, needle, 1, true) then
					table.insert(matches, {
						sourceType = inst.ClassName .. ".Text",
						fullName = fullName,
						detail = "Cocok di Text",
					})
				end
			end
		end
	end

	lastSearchMatches = matches
	SearchStatusLabel.Text = string.format("ID '%s' • %d cocok (%d objek dicek)", needle, #matches, scannedCount)
	renderSearchResults(matches)
	print(string.format("[IDSearch] Query='%s' | Cocok=%d | Dicek=%d", needle, #matches, scannedCount))
	for i, m in ipairs(matches) do
		print(string.format("[IDSearch][#%d][%s] %s -> %s", i, m.sourceType, m.fullName, m.detail))
	end
end

ScanIdBtn.MouseButton1Click:Connect(function()
	runIdSearch(SearchBox.Text)
end)

SearchBox.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed then
		runIdSearch(SearchBox.Text)
	end
end)

ClearSearchBtn.MouseButton1Click:Connect(function()
	SearchBox.Text = ""
	table.clear(lastSearchMatches)
	renderSearchResults(lastSearchMatches)
	SearchStatusLabel.Text = "Hasil dibersihkan • Masukkan ID musik lalu tekan Cari"
end)

renderSearchResults(lastSearchMatches)

-- ==========================================
-- HALAMAN 3: ABOUT CREATOR & TOOLS
-- ==========================================
local AboutPage = Instance.new("Frame")
AboutPage.Size = UDim2.fromScale(1, 1)
AboutPage.BackgroundTransparency = 1
AboutPage.Visible = false
AboutPage.Parent = ContentArea
tabPages["About"] = AboutPage

local AboutTitle = Instance.new("TextLabel")
AboutTitle.Size = UDim2.new(1, -24, 0, 18)
AboutTitle.Position = UDim2.new(0, 12, 0, 8)
AboutTitle.BackgroundTransparency = 1
AboutTitle.Text = "Tentang Plugin Studio Lite"
AboutTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
AboutTitle.TextSize = 13
AboutTitle.Font = Enum.Font.GothamBold
AboutTitle.TextXAlignment = Enum.TextXAlignment.Left
AboutTitle.Parent = AboutPage

local AboutCard = Instance.new("ScrollingFrame")
AboutCard.Size = UDim2.new(1, -24, 1, -36)
AboutCard.Position = UDim2.new(0, 12, 0, 30)
AboutCard.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AboutCard.BorderSizePixel = 0
AboutCard.ScrollBarThickness = 3
AboutCard.CanvasSize = UDim2.new(0, 0, 0, 0)
AboutCard.AutomaticCanvasSize = Enum.AutomaticSize.Y
AboutCard.Parent = AboutPage
Instance.new("UICorner", AboutCard).CornerRadius = UDim.new(0, 8)
local AboutStroke = Instance.new("UIStroke", AboutCard)
AboutStroke.Color = Color3.fromRGB(64, 56, 102)
AboutStroke.Thickness = 1

local AboutText = Instance.new("TextLabel")
AboutText.Size = UDim2.new(1, -16, 0, 160)
AboutText.AutomaticSize = Enum.AutomaticSize.Y
AboutText.Position = UDim2.new(0, 8, 0, 8)
AboutText.BackgroundTransparency = 1
AboutText.Text = table.concat({
	"Creator       : Ikyy (@" .. LocalPlayer.Name .. " | ID: " .. tostring(LocalPlayer.UserId) .. ")",
	"Tools         : Plugin Studio Lite (Delta Executor Edition)",
	"Versi         : v1.5.0",
	"",
	"Fitur Aktif:",
	"• Music Player: Pemutar musik default dengan equalizer beat, loop loading, volume slider, dan tombol << / ▶⏸ / >>.",
	"• ID Search   : Pencarian lokasi ID musik / teks pada Sound, StringValue, Attribute, dan UI di seluruh objek.",
	"• Settings    : Pengaturan warna tema GUI dan pilihan font secara langsung.",
	"• About       : Informasi kreator dan versi tools.",
}, "\n")
AboutText.TextColor3 = Color3.fromRGB(215, 214, 238)
AboutText.TextSize = 9
AboutText.Font = Enum.Font.Code
AboutText.TextXAlignment = Enum.TextXAlignment.Left
AboutText.TextYAlignment = Enum.TextYAlignment.Top
AboutText.TextWrapped = true
AboutText.Parent = AboutCard

-- ==========================================
-- HALAMAN 4: SETTINGS (WARNA GUI & FONT)
-- ==========================================
local SettingsPage = Instance.new("Frame")
SettingsPage.Size = UDim2.fromScale(1, 1)
SettingsPage.BackgroundTransparency = 1
SettingsPage.Visible = false
SettingsPage.Parent = ContentArea
tabPages["Settings"] = SettingsPage

local SettingsTitle = Instance.new("TextLabel")
SettingsTitle.Size = UDim2.new(1, -24, 0, 18)
SettingsTitle.Position = UDim2.new(0, 12, 0, 6)
SettingsTitle.BackgroundTransparency = 1
SettingsTitle.Text = "Pengaturan Tampilan (Warna & Font)"
SettingsTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingsTitle.TextSize = 12
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.Parent = SettingsPage

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, -24, 1, -30)
SettingsScroll.Position = UDim2.new(0, 12, 0, 26)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsScroll.Parent = SettingsPage

local SettingsLayout = Instance.new("UIListLayout")
SettingsLayout.Padding = UDim.new(0, 8)
SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
SettingsLayout.Parent = SettingsScroll

-- Bagian 1: Warna GUI
local ColorSectionLabel = Instance.new("TextLabel")
ColorSectionLabel.Size = UDim2.new(1, 0, 0, 14)
ColorSectionLabel.BackgroundTransparency = 1
ColorSectionLabel.Text = "🎨 Warna Tema GUI"
ColorSectionLabel.TextColor3 = Color3.fromRGB(205, 202, 230)
ColorSectionLabel.TextSize = 10
ColorSectionLabel.Font = Enum.Font.GothamBold
ColorSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
ColorSectionLabel.LayoutOrder = 1
ColorSectionLabel.Parent = SettingsScroll

local ColorGrid = Instance.new("Frame")
ColorGrid.Size = UDim2.new(1, 0, 0, 56)
ColorGrid.BackgroundTransparency = 1
ColorGrid.LayoutOrder = 2
ColorGrid.Parent = SettingsScroll

local ColorGridLayout = Instance.new("UIGridLayout")
ColorGridLayout.CellSize = UDim2.new(0.5, -4, 0, 25)
ColorGridLayout.CellPadding = UDim2.fromOffset(8, 6)
ColorGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
ColorGridLayout.Parent = ColorGrid

local themeButtons: {TextButton} = {}
for idx, theme in ipairs(GUI_THEMES) do
	local tBtn = Instance.new("TextButton")
	tBtn.Text = "● " .. theme.name
	tBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
	tBtn.TextSize = 9
	tBtn.BackgroundColor3 = Color3.fromRGB(24, 23, 36)
	tBtn.LayoutOrder = idx
	tBtn.Parent = ColorGrid
	Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 7)
	local stroke = Instance.new("UIStroke", tBtn)
	stroke.Color = theme.accent
	stroke.Thickness = 1.2

	tBtn.MouseButton1Click:Connect(function()
		CONFIG.ThemeIndex = idx
		applyThemeAndFont()
	end)
	table.insert(themeButtons, tBtn)
end

-- Bagian 2: Pilihan Font
local FontSectionLabel = Instance.new("TextLabel")
FontSectionLabel.Size = UDim2.new(1, 0, 0, 14)
FontSectionLabel.BackgroundTransparency = 1
FontSectionLabel.Text = "🔤 Jenis Font UI"
FontSectionLabel.TextColor3 = Color3.fromRGB(205, 202, 230)
FontSectionLabel.TextSize = 10
FontSectionLabel.Font = Enum.Font.GothamBold
FontSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
FontSectionLabel.LayoutOrder = 3
FontSectionLabel.Parent = SettingsScroll

local FontGrid = Instance.new("Frame")
FontGrid.Size = UDim2.new(1, 0, 0, 56)
FontGrid.BackgroundTransparency = 1
FontGrid.LayoutOrder = 4
FontGrid.Parent = SettingsScroll

local FontGridLayout = Instance.new("UIGridLayout")
FontGridLayout.CellSize = UDim2.new(0.5, -4, 0, 25)
FontGridLayout.CellPadding = UDim2.fromOffset(8, 6)
FontGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
FontGridLayout.Parent = FontGrid

local fontButtons: {TextButton} = {}
for idx, fp in ipairs(FONT_PRESETS) do
	local fBtn = Instance.new("TextButton")
	fBtn.Text = fp.name
	fBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
	fBtn.TextSize = 10
	fBtn.BackgroundColor3 = Color3.fromRGB(24, 23, 36)
	fBtn.LayoutOrder = idx
	fBtn.Parent = FontGrid
	Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 7)

	fBtn.MouseButton1Click:Connect(function()
		CONFIG.FontIndex = idx
		applyThemeAndFont()
	end)
	table.insert(fontButtons, fBtn)
end

local SettingsPreviewLabel = Instance.new("TextLabel")
SettingsPreviewLabel.Size = UDim2.new(1, 0, 0, 22)
SettingsPreviewLabel.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
SettingsPreviewLabel.Text = "Preview: Plugin Studio Lite • Beat & Vibe"
SettingsPreviewLabel.TextColor3 = Color3.fromRGB(220, 218, 245)
SettingsPreviewLabel.TextSize = 9
SettingsPreviewLabel.LayoutOrder = 5
SettingsPreviewLabel.Parent = SettingsScroll
Instance.new("UICorner", SettingsPreviewLabel).CornerRadius = UDim.new(0, 6)

applyThemeAndFont = function()
	local theme = GUI_THEMES[CONFIG.ThemeIndex]
	local fontPreset = FONT_PRESETS[CONFIG.FontIndex]

	-- Update warna GUI
	FloatStroke.Color = theme.accent
	MainStroke.Color = theme.stroke
	LogoStroke.Color = theme.stroke
	MainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.gradStart),
		ColorSequenceKeypoint.new(1, theme.gradEnd),
	})
	EqStroke.Color = theme.stroke
	VolSliderFill.BackgroundColor3 = theme.accent
	PlayPauseBtn.BackgroundColor3 = theme.accent
	SearchBoxStroke.Color = theme.stroke
	ScanIdBtn.BackgroundColor3 = theme.accent
	SearchResStroke.Color = theme.stroke

	for name, btn in pairs(tabButtons) do
		local active = (name == CONFIG.ActiveTab)
		btn.BackgroundColor3 = active and theme.accentSoft or Color3.fromRGB(28, 27, 42)
		btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 182, 210)
		btn.Font = active and fontPreset.boldFont or fontPreset.font
	end

	-- Update font elemen teks utama
	SubTitleLabel.Font = fontPreset.boldFont
	TitleLabel.Font = fontPreset.boldFont
	MetaLabel.Font = fontPreset.font
	MusicTrackLabel.Font = fontPreset.boldFont
	MusicStatusLabel.Font = fontPreset.font
	VolLabel.Font = fontPreset.boldFont
	PrevTrackBtn.Font = fontPreset.boldFont
	PlayPauseBtn.Font = fontPreset.boldFont
	NextTrackBtn.Font = fontPreset.boldFont
	SearchHeaderLabel.Font = fontPreset.boldFont
	SearchBox.Font = fontPreset.font
	ScanIdBtn.Font = fontPreset.boldFont
	ClearSearchBtn.Font = fontPreset.boldFont
	SearchStatusLabel.Font = fontPreset.font
	AboutTitle.Font = fontPreset.boldFont
	SettingsTitle.Font = fontPreset.boldFont
	ColorSectionLabel.Font = fontPreset.boldFont
	FontSectionLabel.Font = fontPreset.boldFont
	SettingsPreviewLabel.Font = fontPreset.boldFont
	SettingsPreviewLabel.Text = "Tema: " .. theme.name .. " • Font: " .. fontPreset.name

	for idx, tBtn in ipairs(themeButtons) do
		local selected = (idx == CONFIG.ThemeIndex)
		tBtn.BackgroundColor3 = selected and theme.accentSoft or Color3.fromRGB(24, 23, 36)
		tBtn.Font = selected and fontPreset.boldFont or fontPreset.font
	end

	for idx, fBtn in ipairs(fontButtons) do
		local selected = (idx == CONFIG.FontIndex)
		fBtn.BackgroundColor3 = selected and theme.accentSoft or Color3.fromRGB(24, 23, 36)
		local fp = FONT_PRESETS[idx]
		fBtn.Font = fp.font
	end

	renderMusicPlaylist()
	renderSearchResults(lastSearchMatches)
end

-- Navigasi Sidebar
createNavButton("Music", "🎵  Music", 1).MouseButton1Click:Connect(function() switchTab("Music") end)
createNavButton("Search", "🔎  ID Search", 2).MouseButton1Click:Connect(function() switchTab("Search") end)
createNavButton("Settings", "🎨  Settings", 3).MouseButton1Click:Connect(function() switchTab("Settings") end)
createNavButton("About", "ℹ  About", 4).MouseButton1Click:Connect(function() switchTab("About") end)

switchTab("Music")
applyThemeAndFont()
