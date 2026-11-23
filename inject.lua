--!strict
-- Plugin Studio Lite (Delta Executor Edition) by Ikyy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

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

export type ImportPosMode = "OriginalCF" | "InFrontOfChar"

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
	MapTargetService = "Workspace",
	MapFileName = "map_export.json",
	MapPosMode = "OriginalCF" :: ImportPosMode,
	MapAutoAnchor = true,
	MapBusy = false,
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
MetaLabel.Text = "by Ikyy • v1.7.0 • @" .. LocalPlayer.Name
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
-- HALAMAN 2: MAP TOOL (NO SCRIPT/LOCAL SCRIPT IN MAP + STARTERPACK DECOMPILE + NO SHADOW)
-- ==========================================
local MapPage = Instance.new("Frame")
MapPage.Size = UDim2.fromScale(1, 1)
MapPage.BackgroundTransparency = 1
MapPage.Visible = false
MapPage.Parent = ContentArea
tabPages["MapTool"] = MapPage

local MapTitleLabel = Instance.new("TextLabel")
MapTitleLabel.Size = UDim2.new(1, -24, 0, 16)
MapTitleLabel.Position = UDim2.new(0, 12, 0, 5)
MapTitleLabel.BackgroundTransparency = 1
MapTitleLabel.Text = "🗺 Copy Map & Import (+StarterPack Decompile)"
MapTitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
MapTitleLabel.TextSize = 10
MapTitleLabel.Font = Enum.Font.GothamBold
MapTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
MapTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
MapTitleLabel.Parent = MapPage

local MapStatusLabel = Instance.new("TextLabel")
MapStatusLabel.Size = UDim2.new(1, -24, 0, 12)
MapStatusLabel.Position = UDim2.new(0, 12, 0, 21)
MapStatusLabel.BackgroundTransparency = 1
MapStatusLabel.Text = "Map skips Script/LocalScript • StarterPack decompile ON • NoShadow"
MapStatusLabel.TextColor3 = Color3.fromRGB(150, 146, 182)
MapStatusLabel.TextSize = 8
MapStatusLabel.Font = Enum.Font.GothamMedium
MapStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
MapStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
MapStatusLabel.Parent = MapPage

local ServiceSelectRow = Instance.new("Frame")
ServiceSelectRow.Size = UDim2.new(1, -24, 0, 21)
ServiceSelectRow.Position = UDim2.new(0, 12, 0, 36)
ServiceSelectRow.BackgroundTransparency = 1
ServiceSelectRow.Parent = MapPage

local TARGET_SERVICES: {string} = { "Workspace", "StarterPack", "ReplicatedStorage", "Lighting" }
local serviceButtons: {[string]: TextButton} = {}

for idx, sName in ipairs(TARGET_SERVICES) do
	local sBtn = Instance.new("TextButton")
	local wScale = 1 / #TARGET_SERVICES
	sBtn.Size = UDim2.new(wScale, -3, 1, 0)
	sBtn.Position = UDim2.new((idx - 1) * wScale, (idx > 1 and 2 or 0), 0, 0)
	sBtn.BackgroundColor3 = Color3.fromRGB(24, 23, 36)
	sBtn.Text = (sName == "ReplicatedStorage") and "RepStorage" or sName
	sBtn.TextColor3 = Color3.fromRGB(220, 218, 245)
	sBtn.TextSize = 8
	sBtn.Font = Enum.Font.GothamBold
	sBtn.Parent = ServiceSelectRow
	Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 6)
	serviceButtons[sName] = sBtn

	sBtn.MouseButton1Click:Connect(function()
		CONFIG.MapTargetService = sName
		applyThemeAndFont()
	end)
end

local FileNameBox = Instance.new("TextBox")
FileNameBox.Size = UDim2.new(0.46, -4, 0, 23)
FileNameBox.Position = UDim2.new(0, 12, 0, 61)
FileNameBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
FileNameBox.Text = CONFIG.MapFileName
FileNameBox.PlaceholderText = "map_export.json"
FileNameBox.TextColor3 = Color3.fromRGB(240, 238, 255)
FileNameBox.PlaceholderColor3 = Color3.fromRGB(120, 116, 148)
FileNameBox.TextSize = 8
FileNameBox.Font = Enum.Font.Code
FileNameBox.ClearTextOnFocus = false
FileNameBox.Parent = MapPage
Instance.new("UICorner", FileNameBox).CornerRadius = UDim.new(0, 6)
local FileBoxStroke = Instance.new("UIStroke", FileNameBox)
FileBoxStroke.Color = Color3.fromRGB(58, 52, 92)
FileBoxStroke.Thickness = 1

local PosModeBtn = Instance.new("TextButton")
PosModeBtn.Size = UDim2.new(0.27, -4, 0, 23)
PosModeBtn.Position = UDim2.new(0.46, 2, 0, 61)
PosModeBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
PosModeBtn.Text = "📍 Ori CF"
PosModeBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
PosModeBtn.TextSize = 8
PosModeBtn.Font = Enum.Font.GothamBold
PosModeBtn.Parent = MapPage
Instance.new("UICorner", PosModeBtn).CornerRadius = UDim.new(0, 6)

local AutoAnchorBtn = Instance.new("TextButton")
AutoAnchorBtn.Size = UDim2.new(0.27, -12, 0, 23)
AutoAnchorBtn.Position = UDim2.new(0.73, 2, 0, 61)
AutoAnchorBtn.BackgroundColor3 = Color3.fromRGB(52, 46, 86)
AutoAnchorBtn.Text = "🔒 Anchor: ON"
AutoAnchorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoAnchorBtn.TextSize = 8
AutoAnchorBtn.Font = Enum.Font.GothamBold
AutoAnchorBtn.Parent = MapPage
Instance.new("UICorner", AutoAnchorBtn).CornerRadius = UDim.new(0, 6)

PosModeBtn.MouseButton1Click:Connect(function()
	if CONFIG.MapPosMode == "OriginalCF" then
		CONFIG.MapPosMode = "InFrontOfChar"
		PosModeBtn.Text = "🧍 Depan"
	else
		CONFIG.MapPosMode = "OriginalCF"
		PosModeBtn.Text = "📍 Ori CF"
	end
end)

AutoAnchorBtn.MouseButton1Click:Connect(function()
	CONFIG.MapAutoAnchor = not CONFIG.MapAutoAnchor
	applyThemeAndFont()
end)

local ActionRow = Instance.new("Frame")
ActionRow.Size = UDim2.new(1, -24, 0, 26)
ActionRow.Position = UDim2.new(0, 12, 0, 89)
ActionRow.BackgroundTransparency = 1
ActionRow.Parent = MapPage

local CopyMapBtn = Instance.new("TextButton")
CopyMapBtn.Size = UDim2.new(0.5, -4, 1, 0)
CopyMapBtn.Position = UDim2.new(0, 0, 0, 0)
CopyMapBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
CopyMapBtn.Text = "📦 COPY ALL MAP"
CopyMapBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyMapBtn.TextSize = 9
CopyMapBtn.Font = Enum.Font.GothamBold
CopyMapBtn.Parent = ActionRow
Instance.new("UICorner", CopyMapBtn).CornerRadius = UDim.new(0, 7)

local ImportMapBtn = Instance.new("TextButton")
ImportMapBtn.Size = UDim2.new(0.5, -4, 1, 0)
ImportMapBtn.Position = UDim2.new(0.5, 4, 0, 0)
ImportMapBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
ImportMapBtn.Text = "📥 IMPORT FILE"
ImportMapBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
ImportMapBtn.TextSize = 9
ImportMapBtn.Font = Enum.Font.GothamBold
ImportMapBtn.Parent = ActionRow
Instance.new("UICorner", ImportMapBtn).CornerRadius = UDim.new(0, 7)

local MapLogScroll = Instance.new("ScrollingFrame")
MapLogScroll.Size = UDim2.new(1, -24, 0, 136)
MapLogScroll.Position = UDim2.new(0, 12, 0, 120)
MapLogScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
MapLogScroll.BorderSizePixel = 0
MapLogScroll.ScrollBarThickness = 3
MapLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MapLogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MapLogScroll.Parent = MapPage
Instance.new("UICorner", MapLogScroll).CornerRadius = UDim.new(0, 7)
local MapLogStroke = Instance.new("UIStroke", MapLogScroll)
MapLogStroke.Color = Color3.fromRGB(48, 44, 74)
MapLogStroke.Thickness = 1

local MapLogLabel = Instance.new("TextLabel")
MapLogLabel.Size = UDim2.new(1, -12, 0, 20)
MapLogLabel.AutomaticSize = Enum.AutomaticSize.Y
MapLogLabel.Position = UDim2.new(0, 6, 0, 4)
MapLogLabel.BackgroundTransparency = 1
MapLogLabel.Text = table.concat({
	"[Ready] Script & LocalScript di luar StarterPack tidak disalin.",
	"[Ready] StarterPack menyalin Script & LocalScript dengan decompile Delta Executor + fallback memori sesi.",
}, "\n")
MapLogLabel.TextColor3 = Color3.fromRGB(195, 192, 222)
MapLogLabel.TextSize = 8
MapLogLabel.Font = Enum.Font.Code
MapLogLabel.TextXAlignment = Enum.TextXAlignment.Left
MapLogLabel.TextYAlignment = Enum.TextYAlignment.Top
MapLogLabel.TextWrapped = true
MapLogLabel.Parent = MapLogScroll

local SessionMapCache: {[string]: string} = {}

local function appendMapLog(msg: string)
	local current = MapLogLabel.Text
	if current == "" then
		MapLogLabel.Text = msg
	else
		MapLogLabel.Text = current .. "\n" .. msg
	end
end

local function sanitizeFileName(rawName: string): string
	local trimmed = string.gsub(rawName, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")
	trimmed = string.gsub(trimmed, "[\\/:*?\"<>|]", "_")
	if trimmed == "" then
		return "map_export.json"
	end
	return trimmed
end

local function getExecutorEnv(): {[string]: any}
	local env: {[string]: any} = {}

	local okFenv, fenvTbl = pcall(function()
		return getfenv(1)
	end)
	if okFenv and type(fenvTbl) == "table" then
		for k, v in pairs(fenvTbl) do
			env[tostring(k)] = v
		end
	end

	local okRootFenv, rootFenv = pcall(function()
		return getfenv(0)
	end)
	if okRootFenv and type(rootFenv) == "table" then
		for k, v in pairs(rootFenv) do
			if env[tostring(k)] == nil then
				env[tostring(k)] = v
			end
		end
	end

	if type(shared) == "table" then
		for k, v in pairs(shared :: any) do
			if env[tostring(k)] == nil then
				env[tostring(k)] = v
			end
		end
	end

	if type(_G) == "table" then
		for k, v in pairs(_G :: any) do
			if env[tostring(k)] == nil then
				env[tostring(k)] = v
			end
		end
	end

	return env
end

local function ensureWorkspaceFolder()
	local env = getExecutorEnv()
	local isfolderFn = env["isfolder"]
	local makefolderFn = env["makefolder"]
	if type(isfolderFn) == "function" and type(makefolderFn) == "function" then
		local okExists, exists = pcall(isfolderFn, CONFIG.WorkspaceRoot)
		if not okExists or not exists then
			pcall(makefolderFn, CONFIG.WorkspaceRoot)
		end
	end
end

local function readExecutorFile(relPath: string): (boolean, string)
	local env = getExecutorEnv()
	local isfileFn = env["isfile"]
	local readfileFn = env["readfile"]

	if type(isfileFn) == "function" and type(readfileFn) == "function" then
		local fullPath = CONFIG.WorkspaceRoot .. "/" .. relPath
		local okEx, exists = pcall(isfileFn, fullPath)
		if okEx and exists then
			local okRead, content = pcall(readfileFn, fullPath)
			if okRead and type(content) == "string" then
				return true, content
			end
		end
	end

	local cached = SessionMapCache[relPath]
	if type(cached) == "string" and cached ~= "" then
		return true, cached
	end

	return false, "File tidak ditemukan (lokal/sesi): " .. CONFIG.WorkspaceRoot .. "/" .. relPath
end

local function writeExecutorFile(relPath: string, content: string): (boolean, string)
	SessionMapCache[relPath] = content
	local env = getExecutorEnv()
	local writefileFn = env["writefile"]
	if type(writefileFn) ~= "function" then
		return true, "MEMORI_SESI://" .. CONFIG.WorkspaceRoot .. "/" .. relPath
	end
	ensureWorkspaceFolder()
	local fullPath = CONFIG.WorkspaceRoot .. "/" .. relPath
	local okW, errW = pcall(writefileFn, fullPath, content)
	if not okW then
		return true, "MEMORI_SESI://" .. fullPath .. " (" .. tostring(errW) .. ")"
	end
	return true, fullPath
end

local function decompileDeltaScript(scr: LuaSourceContainer): string?
	local env = getExecutorEnv()
	local decompileFn = env["decompile"]
	if type(decompileFn) == "function" then
		local okD, resD = pcall(decompileFn, scr)
		if okD and type(resD) == "string" and resD ~= "" then
			return resD
		end
	end

	local getBytecodeFn = env["getscriptbytecode"]
	if type(getBytecodeFn) == "function" then
		local okB, bc = pcall(getBytecodeFn, scr)
		if okB and type(bc) == "string" and bc ~= "" then
			if type(decompileFn) == "function" then
				local okD2, resD2 = pcall(decompileFn, bc)
				if okD2 and type(resD2) == "string" and resD2 ~= "" then
					return resD2
				end
			end
		end
	end

	local okSrc, directSrc = pcall(function()
		return (scr :: any).Source
	end)
	if okSrc and type(directSrc) == "string" and directSrc ~= "" then
		return directSrc
	end

	return nil
end

local PROP_WHITELIST: {string} = {
	"Anchored",
	"CanCollide",
	"CanTouch",
	"CanQuery",
	"Massless",
	"EnableFluidForces",
	"CollisionGroup",
	"CustomPhysicalProperties",
	"RootPriority",
	"CFrame",
	"Size",
	"Color",
	"BrickColor",
	"Material",
	"MaterialVariant",
	"Transparency",
	"Reflectance",
	"Shape",
	"TopSurface",
	"BottomSurface",
	"FrontSurface",
	"BackSurface",
	"LeftSurface",
	"RightSurface",
	"MeshId",
	"TextureID",
	"RenderFidelity",
	"CollisionFidelity",
	"DoubleSided",
	"UsePartColor",
	"MeshType",
	"Scale",
	"Offset",
	"VertexColor",
	"Texture",
	"Face",
	"Color3",
	"StudsPerTileU",
	"StudsPerTileV",
	"OffsetStudsU",
	"OffsetStudsV",
	"ZIndex",
	"ColorMap",
	"MetalnessMap",
	"NormalMap",
	"RoughnessMap",
	"AlphaMode",
	"Enabled",
	"Brightness",
	"Range",
	"Angle",
	"Rate",
	"Lifetime",
	"Speed",
	"SpreadAngle",
	"Acceleration",
	"Drag",
	"LightEmission",
	"LightInfluence",
	"Orientation",
	"RotSpeed",
	"Rotation",
	"Squash",
	"LockedToPart",
	"Width0",
	"Width1",
	"CurveSize0",
	"CurveSize1",
	"Segments",
	"TextureLength",
	"TextureMode",
	"TextureSpeed",
	"MinLength",
	"MaxLength",
	"SoundId",
	"Volume",
	"PlaybackSpeed",
	"Looped",
	"RollOffMaxDistance",
	"RollOffMinDistance",
	"RollOffMode",
	"TimePosition",
	"Value",
	"Text",
	"Image",
	"ImageColor3",
	"ImageTransparency",
	"BackgroundColor3",
	"BackgroundTransparency",
	"StudsOffset",
	"AlwaysOnTop",
	"MaxDistance",
	"Adornee",
	"WorldPivot",
	"LevelOfDetail",
	-- Tool / StarterPack props
	"ToolTip",
	"Grip",
	"GripPos",
	"GripForward",
	"GripRight",
	"GripUp",
	"RequiresHandle",
	"CanBeDropped",
	"ManualActivationOnly",
}

local function serializePropertyValue(val: any): any
	local t = typeof(val)
	if t == "Vector3" then
		return { __type = "Vector3", x = val.X, y = val.Y, z = val.Z }
	elseif t == "Vector2" then
		return { __type = "Vector2", x = val.X, y = val.Y }
	elseif t == "CFrame" then
		local comps = { val:GetComponents() }
		return { __type = "CFrame", c = comps }
	elseif t == "Color3" then
		return { __type = "Color3", r = val.R, g = val.G, b = val.B }
	elseif t == "BrickColor" then
		return { __type = "BrickColor", name = val.Name }
	elseif t == "UDim2" then
		return {
			__type = "UDim2",
			xs = val.X.Scale,
			xo = val.X.Offset,
			ys = val.Y.Scale,
			yo = val.Y.Offset,
		}
	elseif t == "NumberRange" then
		return { __type = "NumberRange", min = val.Min, max = val.Max }
	elseif t == "NumberSequence" then
		local kps: {any} = {}
		for _, kp in ipairs(val.Keypoints) do
			table.insert(kps, { t = kp.Time, v = kp.Value, e = kp.Envelope })
		end
		return { __type = "NumberSequence", kps = kps }
	elseif t == "ColorSequence" then
		local kps: {any} = {}
		for _, kp in ipairs(val.Keypoints) do
			table.insert(kps, { t = kp.Time, r = kp.Value.R, g = kp.Value.G, b = kp.Value.B })
		end
		return { __type = "ColorSequence", kps = kps }
	elseif t == "EnumItem" then
		return { __type = "EnumItem", enumType = tostring(val.EnumType), name = val.Name }
	elseif t == "number" or t == "boolean" or t == "string" then
		return val
	end
	return nil
end

local function deserializePropertyValue(raw: any): any
	if type(raw) == "table" and type(raw.__type) == "string" then
		local tp = raw.__type
		if tp == "Vector3" then
			return Vector3.new(tonumber(raw.x) or 0, tonumber(raw.y) or 0, tonumber(raw.z) or 0)
		elseif tp == "Vector2" then
			return Vector2.new(tonumber(raw.x) or 0, tonumber(raw.y) or 0)
		elseif tp == "CFrame" and type(raw.c) == "table" and #raw.c >= 12 then
			return CFrame.new(
				tonumber(raw.c[1]) or 0, tonumber(raw.c[2]) or 0, tonumber(raw.c[3]) or 0,
				tonumber(raw.c[4]) or 1, tonumber(raw.c[5]) or 0, tonumber(raw.c[6]) or 0,
				tonumber(raw.c[7]) or 0, tonumber(raw.c[8]) or 1, tonumber(raw.c[9]) or 0,
				tonumber(raw.c[10]) or 0, tonumber(raw.c[11]) or 0, tonumber(raw.c[12]) or 1
			)
		elseif tp == "Color3" then
			return Color3.new(tonumber(raw.r) or 1, tonumber(raw.g) or 1, tonumber(raw.b) or 1)
		elseif tp == "BrickColor" and type(raw.name) == "string" then
			return BrickColor.new(raw.name)
		elseif tp == "UDim2" then
			return UDim2.new(
				tonumber(raw.xs) or 0,
				tonumber(raw.xo) or 0,
				tonumber(raw.ys) or 0,
				tonumber(raw.yo) or 0
			)
		elseif tp == "NumberRange" then
			return NumberRange.new(tonumber(raw.min) or 0, tonumber(raw.max) or 0)
		elseif tp == "NumberSequence" and type(raw.kps) == "table" then
			local seqKps: {NumberSequenceKeypoint} = {}
			for _, kp in ipairs(raw.kps) do
				if type(kp) == "table" then
					table.insert(seqKps, NumberSequenceKeypoint.new(tonumber(kp.t) or 0, tonumber(kp.v) or 0, tonumber(kp.e) or 0))
				end
			end
			if #seqKps >= 2 then
				return NumberSequence.new(seqKps)
			end
		elseif tp == "ColorSequence" and type(raw.kps) == "table" then
			local colKps: {ColorSequenceKeypoint} = {}
			for _, kp in ipairs(raw.kps) do
				if type(kp) == "table" then
					table.insert(colKps, ColorSequenceKeypoint.new(
						tonumber(kp.t) or 0,
						Color3.new(tonumber(kp.r) or 1, tonumber(kp.g) or 1, tonumber(kp.b) or 1)
					))
				end
			end
			if #colKps >= 2 then
				return ColorSequence.new(colKps)
			end
		elseif tp == "EnumItem" and type(raw.enumType) == "string" and type(raw.name) == "string" then
			local enumGroup = (Enum :: any)[raw.enumType]
			if enumGroup then
				return enumGroup[raw.name]
			end
		end
		return nil
	end
	return raw
end

local function isPlayerCharacterDescendant(inst: Instance): boolean
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and inst:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

local function serializeInstanceTree(inst: Instance, countRef: {n: number}, allowScripts: boolean): any?
	if isPlayerCharacterDescendant(inst) then
		return nil
	end
	if inst == ScreenGui or inst == MusicGroup then
		return nil
	end

	local isScriptInst = inst:IsA("Script") or inst:IsA("LocalScript")
	if isScriptInst and not allowScripts then
		return nil
	end

	local props: {[string]: any} = {}
	for _, propName in ipairs(PROP_WHITELIST) do
		local okGet, val = pcall(function()
			return (inst :: any)[propName]
		end)
		if okGet and val ~= nil then
			local encoded = serializePropertyValue(val)
			if encoded ~= nil then
				props[propName] = encoded
			end
		end
	end

	local decompiledCode: string? = nil
	if isScriptInst and allowScripts then
		decompiledCode = decompileDeltaScript(inst :: LuaSourceContainer)
	end

	local primaryPartName: string? = nil
	if inst:IsA("Model") and inst.PrimaryPart then
		primaryPartName = inst.PrimaryPart.Name
	end

	local attrs: {[string]: any} = {}
	local okAttr, rawAttrs = pcall(function()
		return inst:GetAttributes()
	end)
	if okAttr and type(rawAttrs) == "table" then
		for k, v in pairs(rawAttrs) do
			local encAttr = serializePropertyValue(v)
			if encAttr ~= nil then
				attrs[tostring(k)] = encAttr
			end
		end
	end

	countRef.n += 1
	local childrenSerialized: {any} = {}
	for _, ch in ipairs(inst:GetChildren()) do
		local childNode = serializeInstanceTree(ch, countRef, allowScripts)
		if childNode ~= nil then
			table.insert(childrenSerialized, childNode)
		end
	end

	return {
		Name = inst.Name,
		ClassName = inst.ClassName,
		PrimaryPartName = primaryPartName,
		DecompiledSource = decompiledCode,
		Properties = props,
		Attributes = attrs,
		Children = childrenSerialized,
	}
end

local function getFrontAnchorCFrame(): CFrame?
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then
		return hrp.CFrame * CFrame.new(0, 0, -14)
	end
	return nil
end

local function applyImportedProps(inst: Instance, propsTable: any, refOrigin: CFrame?, frontAnchor: CFrame?, isStarterPackTarget: boolean)
	if type(propsTable) ~= "table" then return end

	if propsTable.Size ~= nil then
		local sz = deserializePropertyValue(propsTable.Size)
		if sz ~= nil then
			pcall(function()
				(inst :: any).Size = sz
			end)
		end
	end

	for propName, rawVal in pairs(propsTable) do
		if propName ~= "Size" and propName ~= "CastShadow" and propName ~= "Shadows" then
			local decoded = deserializePropertyValue(rawVal)
			if decoded ~= nil then
				if propName == "CFrame" and typeof(decoded) == "CFrame" and CONFIG.MapPosMode == "InFrontOfChar" and refOrigin and frontAnchor and not isStarterPackTarget then
					local rel = refOrigin:ToObjectSpace(decoded)
					decoded = frontAnchor * rel
				end
				pcall(function()
					(inst :: any)[propName] = decoded
				end)
			end
		end
	end

	if inst:IsA("BasePart") then
		pcall(function()
			inst.CastShadow = false
			if CONFIG.MapAutoAnchor and not isStarterPackTarget then
				inst.Anchored = true
			end
		end)
	elseif inst:IsA("Light") then
		pcall(function()
			inst.Shadows = false
		end)
	end
end

local function injectDecompiledSource(inst: Instance, sourceCode: any)
	if type(sourceCode) ~= "string" or sourceCode == "" then
		return
	end
	local okSet = pcall(function()
		(inst :: any).Source = sourceCode
	end)
	if not okSet then
		-- Simpan juga di Attribute sebagai cadangan dekompilasi jika property Source read-only di runtime
		pcall(function()
			inst:SetAttribute("DecompiledSource", sourceCode)
		end)
	end
end

local function buildNodesIntoParent(nodes: any, parentTarget: Instance, importedCounter: {n: number}, refOrigin: CFrame?, frontAnchor: CFrame?, isStarterPackTarget: boolean)
	if type(nodes) ~= "table" then return end
	for i, node in ipairs(nodes) do
		if type(node) == "table" and type(node.ClassName) == "string" then
			local okNew, newInst = pcall(Instance.new, node.ClassName)
			if okNew and newInst then
				if type(node.Name) == "string" then
					newInst.Name = node.Name
				end

				if type(node.Attributes) == "table" then
					for aName, aRaw in pairs(node.Attributes) do
						local aVal = deserializePropertyValue(aRaw)
						if aVal ~= nil then
							pcall(function()
								newInst:SetAttribute(aName, aVal)
							end)
						end
					end
				end

				applyImportedProps(newInst, node.Properties, refOrigin, frontAnchor, isStarterPackTarget)

				if (newInst:IsA("Script") or newInst:IsA("LocalScript")) and isStarterPackTarget then
					injectDecompiledSource(newInst, node.DecompiledSource)
				end

				newInst.Parent = parentTarget
				importedCounter.n += 1

				if type(node.Children) == "table" and #node.Children > 0 then
					buildNodesIntoParent(node.Children, newInst, importedCounter, refOrigin, frontAnchor, isStarterPackTarget)
				end

				if newInst:IsA("Model") and type(node.PrimaryPartName) == "string" then
					local foundPP = newInst:FindFirstChild(node.PrimaryPartName, true)
					if foundPP and foundPP:IsA("BasePart") then
						newInst.PrimaryPart = foundPP
					end
				end

				if importedCounter.n % 90 == 0 then
					task.wait()
				end
			end
		end
		if i % 40 == 0 then
			task.wait()
		end
	end
end

local function parseSimpleRbxml(xmlText: string): {any}
	local roots: {any} = {}

	for tagOpen, body in string.gmatch(xmlText, "<Item%s+class=\"([^\"]+)\"[^>]*>(.-)</Item>") do
		local itemName = string.match(body, "<string%s+name=\"Name\">([^<]*)</string>") or tagOpen
		local props: {[string]: any} = {}

		local anchoredStr = string.match(body, "<bool%s+name=\"Anchored\">([^<]+)</bool>")
		if anchoredStr then
			props.Anchored = (string.lower(anchoredStr) == "true")
		end
		local canCollideStr = string.match(body, "<bool%s+name=\"CanCollide\">([^<]+)</bool>")
		if canCollideStr then
			props.CanCollide = (string.lower(canCollideStr) == "true")
		end
		local transpStr = string.match(body, "<float%s+name=\"Transparency\">([^<]+)</float>")
		if transpStr and tonumber(transpStr) then
			props.Transparency = tonumber(transpStr)
		end

		local sx, sy, sz = string.match(body, "<Vector3%s+name=\"Size\"><X>([^<]+)</X><Y>([^<]+)</Y><Z>([^<]+)</Z></Vector3>")
		if sx and sy and sz then
			props.Size = {
				__type = "Vector3",
				x = tonumber(sx) or 4,
				y = tonumber(sy) or 1,
				z = tonumber(sz) or 2,
			}
		end

		local px, py, pz = string.match(body, "<CoordinateFrame%s+name=\"CFrame\"><X>([^<]+)</X><Y>([^<]+)</Y><Z>([^<]+)</Z>")
		if px and py and pz then
			props.CFrame = {
				__type = "CFrame",
				c = {
					tonumber(px) or 0, tonumber(py) or 0, tonumber(pz) or 0,
					1, 0, 0,
					0, 1, 0,
					0, 0, 1,
				},
			}
		end

		table.insert(roots, {
			Name = itemName,
			ClassName = tagOpen,
			Properties = props,
			Attributes = {},
			Children = {},
		})
	end

	return roots
end

local function performCopyAllMap()
	if CONFIG.MapBusy then return end
	CONFIG.MapBusy = true
	CONFIG.MapFileName = sanitizeFileName(FileNameBox.Text)
	FileNameBox.Text = CONFIG.MapFileName

	MapStatusLabel.Text = "Scanning Map (skip Script/LocalScript) + StarterPack..."
	appendMapLog("[Copy] Map skip Script/LocalScript | StarterPack include Script/LocalScript (decompile)...")

	task.spawn(function()
		local servicesToDump = {
			"Workspace",
			"StarterPack",
			"Lighting",
			"ReplicatedFirst",
			"ReplicatedStorage",
			"SoundService",
			"MaterialService",
		}
		local dumpPayload: {[string]: any} = {
			_meta = {
				exportedBy = LocalPlayer.Name,
				placeId = game.PlaceId,
				universeId = game.GameId,
				skipMapScripts = true,
				starterPackDecompile = true,
				noShadow = true,
				exportedAt = os.date("%Y-%m-%d %H:%M:%S"),
			},
		}

		local totalCount = { n = 0 }
		for _, sName in ipairs(servicesToDump) do
			local okS, srv = pcall(game.GetService, game, sName)
			if okS and srv then
				local allowScriptsHere = (sName == "StarterPack")
				local listNodes: {any} = {}
				for _, child in ipairs(srv:GetChildren()) do
					local node = serializeInstanceTree(child, totalCount, allowScriptsHere)
					if node ~= nil then
						table.insert(listNodes, node)
					end
				end
				dumpPayload[sName] = listNodes
				appendMapLog(string.format("[Scan] %s -> %d root node", sName, #listNodes))
				task.wait()
			end
		end

		local okEncode, jsonStr = pcall(HttpService.JSONEncode, HttpService, dumpPayload)
		if not okEncode or type(jsonStr) ~= "string" then
			CONFIG.MapBusy = false
			MapStatusLabel.Text = "Gagal encode JSON snapshot"
			appendMapLog("[Error] Gagal serialize data map.")
			return
		end

		local targetFile = CONFIG.MapFileName
		if not string.match(string.lower(targetFile), "%.json$") then
			targetFile = targetFile .. ".json"
		end

		local okSave, savedPathOrErr = writeExecutorFile(targetFile, jsonStr)
		CONFIG.MapBusy = false

		if okSave then
			MapStatusLabel.Text = string.format("Selesai Copy: %d instance -> %s", totalCount.n, targetFile)
			appendMapLog(string.format("[Success] Tersimpan (%d instance) di %s", totalCount.n, savedPathOrErr))
		else
			MapStatusLabel.Text = "Gagal simpan file: " .. savedPathOrErr
			appendMapLog("[Error] " .. savedPathOrErr)
		end
	end)
end

local function performImportMap()
	if CONFIG.MapBusy then return end
	CONFIG.MapBusy = true
	CONFIG.MapFileName = sanitizeFileName(FileNameBox.Text)
	FileNameBox.Text = CONFIG.MapFileName

	MapStatusLabel.Text = "Membaca file " .. CONFIG.MapFileName .. "..."
	appendMapLog("[Import] Membaca '" .. CONFIG.WorkspaceRoot .. "/" .. CONFIG.MapFileName .. "'...")

	task.spawn(function()
		local okRead, rawData = readExecutorFile(CONFIG.MapFileName)
		if not okRead then
			CONFIG.MapBusy = false
			MapStatusLabel.Text = rawData
			appendMapLog("[Error] " .. rawData)
			return
		end

		local okTarget, targetService = pcall(game.GetService, game, CONFIG.MapTargetService)
		if not okTarget or not targetService then
			CONFIG.MapBusy = false
			MapStatusLabel.Text = "Target service tidak valid"
			return
		end

		local isStarterPackTarget = (CONFIG.MapTargetService == "StarterPack")
		local nodesToBuild: {any} = {}
		local refOrigin: CFrame? = nil

		local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, rawData)
		if okDecode and type(decoded) == "table" then
			local svcNodes = decoded[CONFIG.MapTargetService] or decoded["Workspace"] or decoded
			if type(svcNodes) == "table" then
				nodesToBuild = svcNodes
			end
			for _, n in ipairs(nodesToBuild) do
				if type(n) == "table" and type(n.Properties) == "table" and type(n.Properties.CFrame) == "table" then
					local cfVal = deserializePropertyValue(n.Properties.CFrame)
					if typeof(cfVal) == "CFrame" then
						refOrigin = cfVal
						break
					end
				end
			end
		elseif string.find(rawData, "<roblox", 1, true) or string.find(rawData, "<Item", 1, true) then
			nodesToBuild = parseSimpleRbxml(rawData)
		else
			CONFIG.MapBusy = false
			MapStatusLabel.Text = "Format file tidak dikenali (.json / .rbxmx)"
			appendMapLog("[Error] Format file harus JSON snapshot atau XML (.rbxmx).")
			return
		end

		local frontAnchor = getFrontAnchorCFrame()
		local importedCounter = { n = 0 }
		buildNodesIntoParent(nodesToBuild, targetService, importedCounter, refOrigin, frontAnchor, isStarterPackTarget)

		CONFIG.MapBusy = false
		MapStatusLabel.Text = string.format("Import selesai: %d instance -> %s", importedCounter.n, CONFIG.MapTargetService)
		appendMapLog(string.format(
			"[Success] %d instance di-import ke %s (%s)",
			importedCounter.n,
			CONFIG.MapTargetService,
			isStarterPackTarget and "StarterPack+Decompile" or (CONFIG.MapPosMode .. " | NoShadow")
		))
	end)
end

CopyMapBtn.MouseButton1Click:Connect(function()
	performCopyAllMap()
end)

ImportMapBtn.MouseButton1Click:Connect(function()
	performImportMap()
end)

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
	"Versi         : v1.7.0",
	"",
	"Fitur Aktif:",
	"• Music Player: Pemutar musik default dengan equalizer beat, loop loading, volume slider, dan tombol << / ▶⏸ / >>.",
	"• Map Tool    : Copy map tanpa Script/LocalScript (NoShadow), + StarterPack Script/LocalScript decompile Delta.",
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
	CopyMapBtn.BackgroundColor3 = theme.accent

	AutoAnchorBtn.BackgroundColor3 = CONFIG.MapAutoAnchor and theme.accentSoft or Color3.fromRGB(32, 30, 48)
	AutoAnchorBtn.Text = CONFIG.MapAutoAnchor and "🔒 Anchor: ON" or "🔓 Anchor: OFF"

	for sName, sBtn in pairs(serviceButtons) do
		local active = (sName == CONFIG.MapTargetService)
		sBtn.BackgroundColor3 = active and theme.accentSoft or Color3.fromRGB(24, 23, 36)
		sBtn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 218, 245)
		sBtn.Font = active and fontPreset.boldFont or fontPreset.font
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
	MapTitleLabel.Font = fontPreset.boldFont
	MapStatusLabel.Font = fontPreset.font
	FileNameBox.Font = fontPreset.font
	PosModeBtn.Font = fontPreset.boldFont
	AutoAnchorBtn.Font = fontPreset.boldFont
	CopyMapBtn.Font = fontPreset.boldFont
	ImportMapBtn.Font = fontPreset.boldFont
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
end

-- Navigasi Sidebar
createNavButton("Music", "Music", 1).MouseButton1Click:Connect(function() switchTab("Music") end)
createNavButton("MapTool", "Map Tool", 2).MouseButton1Click:Connect(function() switchTab("MapTool") end)
createNavButton("Settings", "Settings", 3).MouseButton1Click:Connect(function() switchTab("Settings") end)
createNavButton("About", "About", 4).MouseButton1Click:Connect(function() switchTab("About") end)

switchTab("Music")
applyThemeAndFont()
