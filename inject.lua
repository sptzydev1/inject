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

export type JailMode = "OrbitHead" | "ShakePart" | "GravityThrow" | "PullToTarget" | "RopeBreak" | "AttackFall" | "CarryPart"

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
	JailEnabled = false,
	JailMode = "OrbitHead" :: JailMode,
	JailSpeed = 2.5,
	JailTargetUserId = 0,
	JailAnchorLocked = false,
	PlayerSearchQuery = "",
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
MetaLabel.Text = "by Ikyy • v1.4.0 • @" .. LocalPlayer.Name
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
-- HALAMAN 1: MUSIC PLAYER
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
-- HALAMAN 2: JAIL (ANTI-STUCK + SWING + TARGET CARRY + LASER BEAM)
-- ==========================================
local JailPage = Instance.new("Frame")
JailPage.Size = UDim2.fromScale(1, 1)
JailPage.BackgroundTransparency = 1
JailPage.Visible = false
JailPage.Parent = ContentArea
tabPages["Jail"] = JailPage

local JailTopRow = Instance.new("Frame")
JailTopRow.Size = UDim2.new(1, -24, 0, 22)
JailTopRow.Position = UDim2.new(0, 12, 0, 5)
JailTopRow.BackgroundTransparency = 1
JailTopRow.Parent = JailPage

local JailSwitchBtn = Instance.new("TextButton")
JailSwitchBtn.Size = UDim2.new(0.5, -3, 1, 0)
JailSwitchBtn.Position = UDim2.new(0, 0, 0, 0)
JailSwitchBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 50)
JailSwitchBtn.Text = "⚡ JAIL: OFF"
JailSwitchBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
JailSwitchBtn.TextSize = 8
JailSwitchBtn.Font = Enum.Font.GothamBold
JailSwitchBtn.Parent = JailTopRow
Instance.new("UICorner", JailSwitchBtn).CornerRadius = UDim.new(0, 6)

local JailAnchorLockBtn = Instance.new("TextButton")
JailAnchorLockBtn.Size = UDim2.new(0.5, -3, 1, 0)
JailAnchorLockBtn.Position = UDim2.new(0.5, 3, 0, 0)
JailAnchorLockBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
JailAnchorLockBtn.Text = "🔒 Anchor: OFF"
JailAnchorLockBtn.TextColor3 = Color3.fromRGB(220, 218, 245)
JailAnchorLockBtn.TextSize = 8
JailAnchorLockBtn.Font = Enum.Font.GothamBold
JailAnchorLockBtn.Parent = JailTopRow
Instance.new("UICorner", JailAnchorLockBtn).CornerRadius = UDim.new(0, 6)

local JailStatusLabel = Instance.new("TextLabel")
JailStatusLabel.Size = UDim2.new(1, -24, 0, 11)
JailStatusLabel.Position = UDim2.new(0, 12, 0, 29)
JailStatusLabel.BackgroundTransparency = 1
JailStatusLabel.Text = "OFF • Mode: OrbitHead"
JailStatusLabel.TextColor3 = Color3.fromRGB(150, 146, 182)
JailStatusLabel.TextSize = 8
JailStatusLabel.Font = Enum.Font.GothamMedium
JailStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
JailStatusLabel.Parent = JailPage

local JailSpeedRow = Instance.new("Frame")
JailSpeedRow.Size = UDim2.new(1, -24, 0, 16)
JailSpeedRow.Position = UDim2.new(0, 12, 0, 41)
JailSpeedRow.BackgroundTransparency = 1
JailSpeedRow.Parent = JailPage

local JailSpeedLabel = Instance.new("TextLabel")
JailSpeedLabel.Size = UDim2.new(0, 84, 1, 0)
JailSpeedLabel.BackgroundTransparency = 1
JailSpeedLabel.Text = "🚀 Speed: 2.5x"
JailSpeedLabel.TextColor3 = Color3.fromRGB(205, 202, 230)
JailSpeedLabel.TextSize = 8
JailSpeedLabel.Font = Enum.Font.GothamBold
JailSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
JailSpeedLabel.Parent = JailSpeedRow

local JailSpeedBg = Instance.new("Frame")
JailSpeedBg.Size = UDim2.new(1, -90, 0, 7)
JailSpeedBg.Position = UDim2.new(0, 88, 0.5, -3)
JailSpeedBg.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
JailSpeedBg.BorderSizePixel = 0
JailSpeedBg.Parent = JailSpeedRow
Instance.new("UICorner", JailSpeedBg).CornerRadius = UDim.new(1, 0)

local JailSpeedFill = Instance.new("Frame")
JailSpeedFill.Size = UDim2.new(0.36, 0, 1, 0)
JailSpeedFill.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
JailSpeedFill.BorderSizePixel = 0
JailSpeedFill.Parent = JailSpeedBg
Instance.new("UICorner", JailSpeedFill).CornerRadius = UDim.new(1, 0)

local JailSpeedKnob = Instance.new("TextButton")
JailSpeedKnob.Size = UDim2.fromOffset(12, 12)
JailSpeedKnob.Position = UDim2.new(0.36, -6, 0.5, -6)
JailSpeedKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
JailSpeedKnob.Text = ""
JailSpeedKnob.AutoButtonColor = false
JailSpeedKnob.Parent = JailSpeedBg
Instance.new("UICorner", JailSpeedKnob).CornerRadius = UDim.new(1, 0)

local JailModeGrid = Instance.new("Frame")
JailModeGrid.Size = UDim2.new(1, -24, 0, 44)
JailModeGrid.Position = UDim2.new(0, 12, 0, 59)
JailModeGrid.BackgroundTransparency = 1
JailModeGrid.Parent = JailPage

local JailModeLayout = Instance.new("UIGridLayout")
JailModeLayout.CellSize = UDim2.new(0.25, -4, 0, 20)
JailModeLayout.CellPadding = UDim2.fromOffset(4, 3)
JailModeLayout.SortOrder = Enum.SortOrder.LayoutOrder
JailModeLayout.Parent = JailModeGrid

local JAIL_MODES: {{id: JailMode, label: string}} = {
	{ id = "OrbitHead", label = "🌀 Orbit" },
	{ id = "ShakePart", label = "💥 Shake" },
	{ id = "GravityThrow", label = "🎯 Throw" },
	{ id = "PullToTarget", label = "🧲 Pull" },
	{ id = "RopeBreak", label = "⛓ Rope" },
	{ id = "AttackFall", label = "⬇ Fall" },
	{ id = "CarryPart", label = "🧳 Carry" },
}

local modeButtons: {[JailMode]: TextButton} = {}
for idx, m in ipairs(JAIL_MODES) do
	local btn = Instance.new("TextButton")
	btn.Text = m.label
	btn.TextColor3 = Color3.fromRGB(220, 218, 245)
	btn.TextSize = 8
	btn.BackgroundColor3 = Color3.fromRGB(24, 23, 36)
	btn.LayoutOrder = idx
	btn.Parent = JailModeGrid
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	modeButtons[m.id] = btn

	btn.MouseButton1Click:Connect(function()
		CONFIG.JailMode = m.id
		applyThemeAndFont()
	end)
end

local JailTargetHeader = Instance.new("Frame")
JailTargetHeader.Size = UDim2.new(1, -24, 0, 15)
JailTargetHeader.Position = UDim2.new(0, 12, 0, 106)
JailTargetHeader.BackgroundTransparency = 1
JailTargetHeader.Parent = JailPage

local JailTargetTitle = Instance.new("TextLabel")
JailTargetTitle.Size = UDim2.new(0.75, 0, 1, 0)
JailTargetTitle.BackgroundTransparency = 1
JailTargetTitle.Text = "👤 Target User (Carry / Throw / Pull)"
JailTargetTitle.TextColor3 = Color3.fromRGB(205, 202, 230)
JailTargetTitle.TextSize = 8
JailTargetTitle.Font = Enum.Font.GothamBold
JailTargetTitle.TextXAlignment = Enum.TextXAlignment.Left
JailTargetTitle.Parent = JailTargetHeader

local RefreshUsersBtn = Instance.new("TextButton")
RefreshUsersBtn.Size = UDim2.new(0.24, 0, 1, 0)
RefreshUsersBtn.Position = UDim2.new(0.76, 0, 0, 0)
RefreshUsersBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
RefreshUsersBtn.Text = "↻ List"
RefreshUsersBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
RefreshUsersBtn.TextSize = 8
RefreshUsersBtn.Font = Enum.Font.GothamBold
RefreshUsersBtn.Parent = JailTargetHeader
Instance.new("UICorner", RefreshUsersBtn).CornerRadius = UDim.new(0, 5)

local PlayerSearchBox = Instance.new("TextBox")
PlayerSearchBox.Name = "PlayerSearchBox"
PlayerSearchBox.Size = UDim2.new(1, -24, 0, 20)
PlayerSearchBox.Position = UDim2.new(0, 12, 0, 123)
PlayerSearchBox.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
PlayerSearchBox.PlaceholderText = "🔍 Cari player (display / @username)..."
PlayerSearchBox.PlaceholderColor3 = Color3.fromRGB(125, 122, 152)
PlayerSearchBox.Text = ""
PlayerSearchBox.TextColor3 = Color3.fromRGB(245, 245, 255)
PlayerSearchBox.TextSize = 8
PlayerSearchBox.Font = Enum.Font.GothamMedium
PlayerSearchBox.ClearTextOnFocus = false
PlayerSearchBox.TextXAlignment = Enum.TextXAlignment.Left
PlayerSearchBox.Parent = JailPage
Instance.new("UICorner", PlayerSearchBox).CornerRadius = UDim.new(0, 6)
local SearchStroke = Instance.new("UIStroke", PlayerSearchBox)
SearchStroke.Color = Color3.fromRGB(56, 52, 86)
SearchStroke.Thickness = 1

local PlayerSearchPad = Instance.new("UIPadding")
PlayerSearchPad.PaddingLeft = UDim.new(0, 6)
PlayerSearchPad.PaddingRight = UDim.new(0, 6)
PlayerSearchPad.Parent = PlayerSearchBox

local UserListScroll = Instance.new("ScrollingFrame")
UserListScroll.Size = UDim2.new(1, -24, 0, 110)
UserListScroll.Position = UDim2.new(0, 12, 0, 146)
UserListScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
UserListScroll.BorderSizePixel = 0
UserListScroll.ScrollBarThickness = 3
UserListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
UserListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
UserListScroll.Parent = JailPage
Instance.new("UICorner", UserListScroll).CornerRadius = UDim.new(0, 7)
local UserListStroke = Instance.new("UIStroke", UserListScroll)
UserListStroke.Color = Color3.fromRGB(48, 44, 74)
UserListStroke.Thickness = 1

local UserListLayout = Instance.new("UIListLayout")
UserListLayout.Padding = UDim.new(0, 3)
UserListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UserListLayout.Parent = UserListScroll

local UserListPad = Instance.new("UIPadding")
UserListPad.PaddingTop = UDim.new(0, 4)
UserListPad.PaddingBottom = UDim.new(0, 4)
UserListPad.PaddingLeft = UDim.new(0, 4)
UserListPad.PaddingRight = UDim.new(0, 4)
UserListPad.Parent = UserListScroll

-- Logika Scan, Swing Release, Anti-Stuck & Laser Beam
local scannedUnanchoredParts: {BasePart} = {}
local trackedPartsSet: {[BasePart]: boolean} = {}
local activeAttackedParts: {[BasePart]: boolean} = {}
local lockedAnchoredParts: {[BasePart]: boolean} = {}
local lastPartPos: {[BasePart]: Vector3} = {}
local stuckTimerByPart: {[BasePart]: number} = {}
local throwCycleClock = 0
local throwPulseIndex = 0
local forceScanNow: () -> () = function() end

type LaserVisual = {
	partAtt: Attachment,
	beam: Beam,
}

local laserVisuals: {[BasePart]: LaserVisual} = {}
local playerLaserAtt: Attachment? = nil

local function getCharacterRoot(player: Player?): BasePart?
	local plr = player or LocalPlayer
	local char = plr.Character
	if not char then return nil end
	return (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")) :: BasePart?
end

local function getOrCreatePlayerLaserAttachment(): Attachment?
	local root = getCharacterRoot(LocalPlayer)
	if not root then
		playerLaserAtt = nil
		return nil
	end

	if playerLaserAtt and playerLaserAtt.Parent == root then
		return playerLaserAtt
	end

	if playerLaserAtt then
		pcall(function()
			playerLaserAtt:Destroy()
		end)
	end

	local att = Instance.new("Attachment")
	att.Name = "IkyyJail_PlayerLaserAtt"
	att.Parent = root
	playerLaserAtt = att
	return att
end

local function setPartLaserEnabled(part: BasePart, enabled: boolean, accentColor: Color3?)
	if not enabled then
		local vis = laserVisuals[part]
		if vis then
			laserVisuals[part] = nil
			pcall(function()
				vis.beam:Destroy()
				vis.partAtt:Destroy()
			end)
		end
		return
	end

	if not part.Parent then return end
	local pAtt = getOrCreatePlayerLaserAttachment()
	if not pAtt then return end

	local vis = laserVisuals[part]
	if not vis or not vis.beam.Parent or not vis.partAtt.Parent then
		if vis then
			pcall(function()
				vis.beam:Destroy()
				vis.partAtt:Destroy()
			end)
		end

		local att = Instance.new("Attachment")
		att.Name = "IkyyJail_PartLaserAtt"
		att.Parent = part

		local beam = Instance.new("Beam")
		beam.Name = "IkyyJail_LaserBeam"
		beam.Attachment0 = att
		beam.Attachment1 = pAtt
		beam.FaceCamera = true
		beam.Width0 = 0.08
		beam.Width1 = 0.08
		beam.LightEmission = 0.85
		beam.LightInfluence = 0
		beam.Transparency = NumberSequence.new(0.15)
		beam.Parent = part

		vis = {
			partAtt = att,
			beam = beam,
		}
		laserVisuals[part] = vis
	end

	vis.beam.Attachment1 = pAtt
	vis.beam.Enabled = true
	if accentColor then
		vis.beam.Color = ColorSequence.new(accentColor)
	end
end

local function clearAllLaserVisuals()
	for part, vis in pairs(laserVisuals) do
		laserVisuals[part] = nil
		pcall(function()
			vis.beam:Destroy()
			vis.partAtt:Destroy()
		end)
	end
	if playerLaserAtt then
		pcall(function()
			playerLaserAtt:Destroy()
		end)
		playerLaserAtt = nil
	end
end

local function disableBindingOnContainer(container: Instance, part: BasePart)
	for _, desc in ipairs(container:GetDescendants()) do
		if desc:IsA("RopeConstraint") or desc:IsA("HingeConstraint") or desc:IsA("SpringConstraint") or desc:IsA("RodConstraint") or desc:IsA("AlignPosition") or desc:IsA("AlignOrientation") or desc:IsA("WeldConstraint") or desc:IsA("BodyMover") then
			local c = desc :: any
			local bindsPart = false
			if c.Part0 == part or c.Part1 == part then
				bindsPart = true
			end
			if c.Attachment0 and (c.Attachment0:IsDescendantOf(part) or c.Attachment0.Parent == part) then
				bindsPart = true
			end
			if c.Attachment1 and (c.Attachment1:IsDescendantOf(part) or c.Attachment1.Parent == part) then
				bindsPart = true
			end
			if desc:IsDescendantOf(part) or desc.Parent == part or bindsPart then
				pcall(function()
					if typeof(c.Enabled) == "boolean" then
						c.Enabled = false
					end
					if desc:IsA("RopeConstraint") then
						desc.Length = 0.01
					elseif desc:IsA("SpringConstraint") then
						desc.Stiffness = 0
					end
				end)
			end
		end
	end
end

-- Mendukung lepas ikatan ayunan / swing (Hinge, Rope, Spring, Weld, dll.) agar part bebas gerak
local function detachPartFromReturnPull(part: BasePart)
	pcall(function()
		disableBindingOnContainer(part, part)
		if part.Parent and part.Parent ~= workspace then
			disableBindingOnContainer(part.Parent, part)
			if part.Parent.Parent and part.Parent.Parent ~= workspace then
				disableBindingOnContainer(part.Parent.Parent, part)
			end
		end
	end)
end

local function applyUnstickImpulse(part: BasePart, idx: number, speed: number)
	pcall(function()
		part.Anchored = false
		part.AssemblyLinearVelocity = Vector3.new(
			math.cos(idx * 1.7) * 28 * speed,
			22 * speed,
			math.sin(idx * 1.7) * 28 * speed
		)
		part.AssemblyAngularVelocity = Vector3.new(18 * speed, 16 * speed, 18 * speed)
	end)
end

local function getSelectedTargetPlayer(): Player?
	if CONFIG.JailTargetUserId == 0 then return nil end
	return Players:GetPlayerByUserId(CONFIG.JailTargetUserId)
end

local function scanUnanchoredParts()
	table.clear(scannedUnanchoredParts)
	table.clear(trackedPartsSet)

	local root = getCharacterRoot(LocalPlayer)
	local targetPlr = getSelectedTargetPlayer()
	local targetRoot = getCharacterRoot(targetPlr)

	local originPos = root and root.Position or Vector3.zero
	local targetPos = targetRoot and targetRoot.Position or originPos

	local maxDist = 160
	local maxParts = 36

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	local ignoreList: {Instance} = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			table.insert(ignoreList, plr.Character)
		end
	end
	overlapParams.FilterDescendantsInstances = ignoreList

	local nearbyParts = workspace:GetPartBoundsInRadius(originPos, maxDist, overlapParams)
	for _, part in ipairs(nearbyParts) do
		if part:IsA("BasePart") and not part.Anchored and not trackedPartsSet[part] then
			trackedPartsSet[part] = true
			table.insert(scannedUnanchoredParts, part)
			if #scannedUnanchoredParts >= maxParts then
				break
			end
		end
	end

	if targetRoot and (targetPos - originPos).Magnitude > 25 and #scannedUnanchoredParts < maxParts then
		local targetParts = workspace:GetPartBoundsInRadius(targetPos, maxDist, overlapParams)
		for _, part in ipairs(targetParts) do
			if part:IsA("BasePart") and not part.Anchored and not trackedPartsSet[part] then
				trackedPartsSet[part] = true
				table.insert(scannedUnanchoredParts, part)
				if #scannedUnanchoredParts >= maxParts then
					break
				end
			end
		end
	end
end

local function releasePartsToFall()
	local dropBoost = 65 * CONFIG.JailSpeed
	for i = #scannedUnanchoredParts, 1, -1 do
		local part = scannedUnanchoredParts[i]
		if part and part.Parent and not part.Anchored then
			part.AssemblyLinearVelocity = Vector3.new(math.random(-20, 20), -dropBoost, math.random(-20, 20))
			part.AssemblyAngularVelocity = Vector3.new(18, 18, 18)
		end
	end
	clearAllLaserVisuals()
	table.clear(activeAttackedParts)
	table.clear(scannedUnanchoredParts)
	table.clear(trackedPartsSet)
	table.clear(lastPartPos)
	table.clear(stuckTimerByPart)
end

local function setAnchorLock(locked: boolean)
	CONFIG.JailAnchorLocked = locked
	if locked then
		scanUnanchoredParts()
		for _, part in ipairs(scannedUnanchoredParts) do
			if part.Parent and not part.Anchored then
				lockedAnchoredParts[part] = true
				pcall(function()
					part.Anchored = true
				end)
			end
		end
	else
		for part, _ in pairs(lockedAnchoredParts) do
			if part.Parent then
				pcall(function()
					part.Anchored = false
				end)
			end
		end
		table.clear(lockedAnchoredParts)
	end
	applyThemeAndFont()
end

local function renderUserList()
	local theme = GUI_THEMES[CONFIG.ThemeIndex]
	local fontPreset = FONT_PRESETS[CONFIG.FontIndex]

	for _, child in ipairs(UserListScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local q = string.lower(string.match(CONFIG.PlayerSearchQuery, "^%s*(.-)%s*$") or "")
	local others: {Player} = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local hayName = string.lower(plr.Name)
			local hayDisp = string.lower(plr.DisplayName)
			if q == "" or string.find(hayName, q, 1, true) ~= nil or string.find(hayDisp, q, 1, true) ~= nil then
				table.insert(others, plr)
			end
		end
	end

	if CONFIG.JailTargetUserId == 0 and #others > 0 then
		CONFIG.JailTargetUserId = others[1].UserId
	end

	if #others == 0 then
		local emptyBtn = Instance.new("TextButton")
		emptyBtn.Size = UDim2.new(1, -4, 0, 22)
		emptyBtn.BackgroundColor3 = Color3.fromRGB(22, 21, 34)
		emptyBtn.Text = q ~= "" and ("  Tidak cocok: \"" .. CONFIG.PlayerSearchQuery .. "\"") or "  Tidak ada player lain di server"
		emptyBtn.TextColor3 = Color3.fromRGB(165, 162, 190)
		emptyBtn.TextSize = 8
		emptyBtn.Font = fontPreset.font
		emptyBtn.TextXAlignment = Enum.TextXAlignment.Left
		emptyBtn.LayoutOrder = 1
		emptyBtn.Parent = UserListScroll
		Instance.new("UICorner", emptyBtn).CornerRadius = UDim.new(0, 5)
		return
	end

	for idx, plr in ipairs(others) do
		local selected = (plr.UserId == CONFIG.JailTargetUserId)
		local uBtn = Instance.new("TextButton")
		uBtn.Size = UDim2.new(1, -4, 0, 22)
		uBtn.BackgroundColor3 = selected and theme.accentSoft or Color3.fromRGB(22, 21, 34)
		uBtn.Text = string.format("  %s (@%s)", plr.DisplayName, plr.Name)
		uBtn.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 188, 215)
		uBtn.TextSize = 9
		uBtn.Font = selected and fontPreset.boldFont or fontPreset.font
		uBtn.TextXAlignment = Enum.TextXAlignment.Left
		uBtn.TextTruncate = Enum.TextTruncate.AtEnd
		uBtn.LayoutOrder = idx
		uBtn.Parent = UserListScroll
		Instance.new("UICorner", uBtn).CornerRadius = UDim.new(0, 5)

		uBtn.MouseButton1Click:Connect(function()
			CONFIG.JailTargetUserId = plr.UserId
			renderUserList()
		end)
	end
end

local function applyJailSpeedFromRatio(ratio: number)
	local clamped = math.clamp(ratio, 0, 1)
	local minSpeed = 0.5
	local maxSpeed = 6.0
	local speedVal = minSpeed + (clamped * (maxSpeed - minSpeed))
	CONFIG.JailSpeed = math.floor(speedVal * 10 + 0.5) / 10
	local displayRatio = (CONFIG.JailSpeed - minSpeed) / (maxSpeed - minSpeed)
	JailSpeedFill.Size = UDim2.new(displayRatio, 0, 1, 0)
	JailSpeedKnob.Position = UDim2.new(displayRatio, -6, 0.5, -6)
	JailSpeedLabel.Text = "🚀 Speed: " .. string.format("%.1f", CONFIG.JailSpeed) .. "x"
end

JailSwitchBtn.MouseButton1Click:Connect(function()
	CONFIG.JailEnabled = not CONFIG.JailEnabled
	if CONFIG.JailEnabled then
		pcall(function()
			LocalPlayer.SimulationRadius = 1000
		end)
		forceScanNow()
	else
		releasePartsToFall()
	end
	applyThemeAndFont()
end)

JailAnchorLockBtn.MouseButton1Click:Connect(function()
	setAnchorLock(not CONFIG.JailAnchorLocked)
end)

RefreshUsersBtn.MouseButton1Click:Connect(function()
	renderUserList()
end)

PlayerSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	CONFIG.PlayerSearchQuery = PlayerSearchBox.Text
	renderUserList()
end)

Players.PlayerAdded:Connect(function()
	renderUserList()
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	if plr.UserId == CONFIG.JailTargetUserId then
		CONFIG.JailTargetUserId = 0
	end
	renderUserList()
end)

do
	local draggingSpeed = false
	local function updateSpeedFromInput(inputPos: Vector2)
		local absPos = JailSpeedBg.AbsolutePosition.X
		local absW = math.max(1, JailSpeedBg.AbsoluteSize.X)
		local ratio = math.clamp((inputPos.X - absPos) / absW, 0, 1)
		applyJailSpeedFromRatio(ratio)
	end

	JailSpeedBg.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSpeed = true
			updateSpeedFromInput(input.Position)
		end
	end)

	JailSpeedKnob.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSpeed = true
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not draggingSpeed then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateSpeedFromInput(input.Position)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSpeed = false
		end
	end)
end

-- Loop eksekusi fisika JAIL (Anti-Stuck, Swing Release & Target Carry)
do
	local jailClock = 0
	local scanAccum = 0
	local statusAccum = 0
	local lastAppliedMode: JailMode? = nil

	local function refreshAndUnstickParts()
		scanUnanchoredParts()
		for idx, part in ipairs(scannedUnanchoredParts) do
			if part.Parent and not part.Anchored then
				activeAttackedParts[part] = true
				detachPartFromReturnPull(part)
				applyUnstickImpulse(part, idx, CONFIG.JailSpeed)
				lastPartPos[part] = part.Position
				stuckTimerByPart[part] = 0
			end
		end
	end

	forceScanNow = refreshAndUnstickParts

	RunService.Heartbeat:Connect(function(dt: number)
		if not CONFIG.JailEnabled then
			lastAppliedMode = nil
			if next(laserVisuals) ~= nil or playerLaserAtt ~= nil then
				clearAllLaserVisuals()
			end
			return
		end

		jailClock += dt
		scanAccum += dt
		if scanAccum >= 1.5 then
			scanAccum = 0
			scanUnanchoredParts()
		end

		local mode = CONFIG.JailMode
		local speed = CONFIG.JailSpeed
		local modeChanged = (lastAppliedMode ~= mode)
		if modeChanged then
			lastAppliedMode = mode
		end

		local myRoot = getCharacterRoot(LocalPlayer)
		local targetPlr = getSelectedTargetPlayer()
		local targetRoot = getCharacterRoot(targetPlr) or myRoot
		local activeCount = #scannedUnanchoredParts
		local accentColor = GUI_THEMES[CONFIG.ThemeIndex].accent

		local throwInterval = math.max(0.18, 0.45 / math.max(0.5, speed))
		throwCycleClock += dt
		if throwCycleClock >= throwInterval then
			throwCycleClock -= throwInterval
			throwPulseIndex += 1
		end

		local myPos = myRoot and myRoot.Position or Vector3.zero
		local targetPos = targetRoot and targetRoot.Position or myPos
		local carryBaseCf = (targetRoot and targetRoot.CFrame) or (myRoot and myRoot.CFrame) or CFrame.new()

		for i = activeCount, 1, -1 do
			local part = scannedUnanchoredParts[i]
			if not part or not part.Parent or part.Anchored then
				table.remove(scannedUnanchoredParts, i)
				if part then
					trackedPartsSet[part] = nil
					lastPartPos[part] = nil
					stuckTimerByPart[part] = nil
					setPartLaserEnabled(part, false)
				end
			else
				if not activeAttackedParts[part] then
					activeAttackedParts[part] = true
					detachPartFromReturnPull(part)
					applyUnstickImpulse(part, i, speed)
				elseif modeChanged then
					detachPartFromReturnPull(part)
					applyUnstickImpulse(part, i, speed)
				end

				-- Anti-stuck: jika part hampir tidak berpindah posisi selama >0.35s, beri dorongan pelepasan
				local curPos = part.Position
				local prevPos = lastPartPos[part]
				if prevPos and (curPos - prevPos).Magnitude < 0.08 then
					stuckTimerByPart[part] = (stuckTimerByPart[part] or 0) + dt
					if stuckTimerByPart[part] >= 0.35 then
						stuckTimerByPart[part] = 0
						detachPartFromReturnPull(part)
						applyUnstickImpulse(part, i, speed * 1.2)
					end
				else
					stuckTimerByPart[part] = 0
				end
				lastPartPos[part] = curPos

				setPartLaserEnabled(part, true, accentColor)

				if mode == "OrbitHead" then
					local center = myPos + Vector3.new(0, 5.5, 0)
					local angle = jailClock * (3.2 * speed) + (i * ((math.pi * 2) / math.max(1, activeCount)))
					local radius = 3.5 + ((i % 3) * 1.1)
					local desiredPos = center + Vector3.new(math.cos(angle) * radius, math.sin(angle * 1.5) * 0.6, math.sin(angle) * radius)
					part.AssemblyLinearVelocity = (desiredPos - curPos) * (11 * speed)
					part.AssemblyAngularVelocity = Vector3.new(0, 12 * speed, 0)
				elseif mode == "ShakePart" then
					part.AssemblyLinearVelocity = Vector3.new(
						math.sin(jailClock * 30 * speed + i) * 24 * speed,
						math.cos(jailClock * 26 * speed + i * 2) * 24 * speed,
						math.sin(jailClock * 32 * speed + i * 3) * 24 * speed
					)
					part.AssemblyAngularVelocity = Vector3.new(18 * speed, -16 * speed, 18 * speed)
				elseif mode == "GravityThrow" then
					local spreadPhase = (throwPulseIndex + i) * 1.35
					local aimJitter = Vector3.new(
						math.cos(spreadPhase) * 2.4,
						1.5 + ((throwPulseIndex + i) % 3) * 1.4,
						math.sin(spreadPhase) * 2.4
					)
					local toTarget = (targetPos + aimJitter) - curPos
					local dist = toTarget.Magnitude
					local dir = dist > 0.05 and toTarget.Unit or Vector3.new(0, 1, 0)
					local throwSpeed = math.clamp(dist * 3.5 * speed, 50 * speed, 145 * speed)
					part.AssemblyLinearVelocity = (dir * throwSpeed) + Vector3.new(0, 14 * speed, 0)
					part.AssemblyAngularVelocity = Vector3.new(20 * speed, 18 * speed, 20 * speed)
				elseif mode == "PullToTarget" then
					local angle = jailClock * (2.2 * speed) + (i * 0.7)
					local desiredPos = targetPos + Vector3.new(math.cos(angle) * 2.2, 1.5 + (i % 3), math.sin(angle) * 2.2)
					part.AssemblyLinearVelocity = (desiredPos - curPos) * (12 * speed)
				elseif mode == "RopeBreak" then
					local pullDir = myPos - curPos
					local unitDir = pullDir.Magnitude > 0.1 and pullDir.Unit or Vector3.new(0, 1, 0)
					part.AssemblyLinearVelocity = unitDir * (65 * speed) + Vector3.new(
						math.sin(jailClock * 34 * speed + i) * 28 * speed,
						30 * speed,
						math.cos(jailClock * 34 * speed + i) * 28 * speed
					)
					part.AssemblyAngularVelocity = Vector3.new(24 * speed, 24 * speed, 24 * speed)
				elseif mode == "AttackFall" then
					part.AssemblyLinearVelocity = Vector3.new(
						math.sin(jailClock * 30 * speed + i) * 24 * speed,
						-80 * speed,
						math.cos(jailClock * 30 * speed + i) * 24 * speed
					)
					part.AssemblyAngularVelocity = Vector3.new(26 * speed, -22 * speed, 26 * speed)
				elseif mode == "CarryPart" then
					local col = (i - 1) % 3 - 1
					local row = math.floor((i - 1) / 3) % 3
					local carryPos = (carryBaseCf * CFrame.new(col * 2.2, 1.4 + (row * 1.6), -4.2)).Position
					part.AssemblyLinearVelocity = (carryPos - curPos) * (15 * speed)
					part.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end

		statusAccum += dt
		if statusAccum >= 0.3 then
			statusAccum = 0
			local targetName = targetPlr and ("@" .. targetPlr.Name) or "Self"
			JailStatusLabel.Text = string.format("ON • %d part • %s • %s", #scannedUnanchoredParts, mode, targetName)
		end
	end)
end

renderUserList()
applyJailSpeedFromRatio((CONFIG.JailSpeed - 0.5) / (6.0 - 0.5))

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
	"Versi         : v1.4.0",
	"",
	"Fitur Aktif:",
	"• Music Player: Pemutar musik default dengan equalizer beat, loop loading, volume slider, dan tombol << / ▶⏸ / >>.",
	"• JAIL        : Akses fisika unanchored part anti-stuck + laser beam (Orbit, Shake, Throw, Pull, Rope, Fall, Carry Target).",
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
	JailSpeedFill.BackgroundColor3 = theme.accent

	JailSwitchBtn.BackgroundColor3 = CONFIG.JailEnabled and theme.accent or Color3.fromRGB(34, 32, 50)
	JailSwitchBtn.Text = CONFIG.JailEnabled and "⚡ JAIL: ON" or "⚡ JAIL: OFF"

	JailAnchorLockBtn.BackgroundColor3 = CONFIG.JailAnchorLocked and theme.accentSoft or Color3.fromRGB(32, 30, 48)
	JailAnchorLockBtn.Text = CONFIG.JailAnchorLocked and "🔒 Anchor: ON" or "🔒 Anchor: OFF"

	if not CONFIG.JailEnabled then
		JailStatusLabel.Text = string.format("OFF • Mode: %s", CONFIG.JailMode)
	end

	for modeId, mBtn in pairs(modeButtons) do
		local active = (modeId == CONFIG.JailMode)
		mBtn.BackgroundColor3 = active and theme.accentSoft or Color3.fromRGB(24, 23, 36)
		mBtn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 218, 245)
		mBtn.Font = active and fontPreset.boldFont or fontPreset.font
	end

	for name, btn in pairs(tabButtons) do
		local active = (name == CONFIG.ActiveTab)
		btn.BackgroundColor3 = active and theme.accentSoft or Color3.fromRGB(28, 27, 42)
		btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 182, 210)
		btn.Font = active and fontPreset.boldFont or fontPreset.font
	end

	SubTitleLabel.Font = fontPreset.boldFont
	TitleLabel.Font = fontPreset.boldFont
	MetaLabel.Font = fontPreset.font
	MusicTrackLabel.Font = fontPreset.boldFont
	MusicStatusLabel.Font = fontPreset.font
	VolLabel.Font = fontPreset.boldFont
	PrevTrackBtn.Font = fontPreset.boldFont
	PlayPauseBtn.Font = fontPreset.boldFont
	NextTrackBtn.Font = fontPreset.boldFont
	JailSwitchBtn.Font = fontPreset.boldFont
	JailAnchorLockBtn.Font = fontPreset.boldFont
	JailStatusLabel.Font = fontPreset.font
	JailSpeedLabel.Font = fontPreset.boldFont
	JailTargetTitle.Font = fontPreset.boldFont
	RefreshUsersBtn.Font = fontPreset.boldFont
	PlayerSearchBox.Font = fontPreset.font
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
	renderUserList()
end

-- Navigasi Sidebar
createNavButton("Music", "🎵  Music", 1).MouseButton1Click:Connect(function() switchTab("Music") end)
createNavButton("Jail", "⛓  JAIL", 2).MouseButton1Click:Connect(function() switchTab("Jail") end)
createNavButton("Settings", "🎨  Settings", 3).MouseButton1Click:Connect(function() switchTab("Settings") end)
createNavButton("About", "ℹ  About", 4).MouseButton1Click:Connect(function() switchTab("About") end)

switchTab("Music")
applyThemeAndFont()
