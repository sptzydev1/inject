--!strict
-- Plugin Studio Lite (Delta Executor Edition) by Ikyy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

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
export type ToolModeTab = "CopyMap" | "ImportMap" | "Music" | "Settings"

local GUI_THEMES: {GuiTheme} = {
	{
		name = "Amber Studio",
		accent = Color3.fromRGB(245, 178, 36),
		accentSoft = Color3.fromRGB(255, 244, 214),
		stroke = Color3.fromRGB(226, 186, 96),
		gradStart = Color3.fromRGB(255, 252, 245),
		gradEnd = Color3.fromRGB(248, 243, 230),
		eqEven = Color3.fromRGB(245, 178, 36),
		eqOdd = Color3.fromRGB(217, 119, 6),
	},
	{
		name = "Violet Neon",
		accent = Color3.fromRGB(108, 86, 245),
		accentSoft = Color3.fromRGB(236, 233, 255),
		stroke = Color3.fromRGB(138, 122, 224),
		gradStart = Color3.fromRGB(250, 249, 255),
		gradEnd = Color3.fromRGB(242, 240, 252),
		eqEven = Color3.fromRGB(108, 86, 245),
		eqOdd = Color3.fromRGB(56, 189, 248),
	},
	{
		name = "Cyan Cyber",
		accent = Color3.fromRGB(14, 165, 233),
		accentSoft = Color3.fromRGB(224, 246, 255),
		stroke = Color3.fromRGB(92, 186, 226),
		gradStart = Color3.fromRGB(246, 252, 255),
		gradEnd = Color3.fromRGB(236, 247, 253),
		eqEven = Color3.fromRGB(14, 165, 233),
		eqOdd = Color3.fromRGB(37, 99, 235),
	},
	{
		name = "Rose Clean",
		accent = Color3.fromRGB(225, 29, 72),
		accentSoft = Color3.fromRGB(255, 228, 234),
		stroke = Color3.fromRGB(224, 128, 150),
		gradStart = Color3.fromRGB(255, 250, 252),
		gradEnd = Color3.fromRGB(252, 242, 245),
		eqEven = Color3.fromRGB(225, 29, 72),
		eqOdd = Color3.fromRGB(249, 115, 22),
	},
}

local FONT_PRESETS: {FontPreset} = {
	{ name = "Gotham", font = Enum.Font.GothamMedium, boldFont = Enum.Font.GothamBold },
	{ name = "FredokaOne", font = Enum.Font.FredokaOne, boldFont = Enum.Font.FredokaOne },
	{ name = "RobotoMono", font = Enum.Font.RobotoMono, boldFont = Enum.Font.RobotoMono },
	{ name = "Arcade", font = Enum.Font.Arcade, boldFont = Enum.Font.Arcade },
}

local SERVICE_LIST: {string} = {
	"Workspace",
	"StarterPack",
	"Lighting",
	"MaterialService",
	"ReplicatedFirst",
	"ReplicatedStorage",
	"SoundService",
}

local CONFIG = {
	WorkspaceRoot = "IkyyStudioLite",
	IsMinimized = false,
	ActiveTab = "CopyMap" :: ToolModeTab,
	ThemeIndex = 1,
	FontIndex = 1,
	SelectedFileName = "",
	MapPosMode = "OriginalCF" :: ImportPosMode,
	MapAutoAnchor = true,
	MapBusy = false,
	CopyProgress = 0,
	SelectedServices = {
		Workspace = true,
		StarterPack = true,
		Lighting = true,
		MaterialService = true,
		ReplicatedFirst = true,
		ReplicatedStorage = true,
		SoundService = true,
	} :: {[string]: boolean},
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

local WINDOW_SIZE = UDim2.fromOffset(620, 340)
local WINDOW_POS = UDim2.new(0.5, -310, 0.5, -170)
local ICON_SIZE = UDim2.fromOffset(44, 44)
local ICON_DEFAULT_POS = UDim2.new(0.5, -22, 0.08, 0)
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

-- 1. IKON LINGKARAN PROFILE USER (DRAGGABLE)
local FloatingProfileBtn = Instance.new("ImageButton")
FloatingProfileBtn.Name = "FloatingProfileToggle"
FloatingProfileBtn.Size = ICON_SIZE
FloatingProfileBtn.Position = ICON_DEFAULT_POS
FloatingProfileBtn.BackgroundColor3 = Color3.fromRGB(255, 250, 235)
FloatingProfileBtn.BorderSizePixel = 0
FloatingProfileBtn.Visible = false
FloatingProfileBtn.AutoButtonColor = false
FloatingProfileBtn.ZIndex = 60
FloatingProfileBtn.Image = getUserAvatarAsync(LocalPlayer.UserId)
FloatingProfileBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingProfileBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingProfileBtn)
FloatStroke.Color = Color3.fromRGB(245, 178, 36)
FloatStroke.Thickness = 2.4

-- 2. WINDOW UTAMA (620x340)
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = WINDOW_SIZE
MainWindow.Position = WINDOW_POS
MainWindow.BackgroundColor3 = Color3.fromRGB(255, 252, 245)
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainWindow)
MainStroke.Color = Color3.fromRGB(226, 186, 96)
MainStroke.Thickness = 1.6

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 252, 245)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(248, 243, 230)),
})
MainGradient.Rotation = 90
MainGradient.Parent = MainWindow

-- ==========================================
-- TOP BAR (BRANDING + TAB ATAS + KONTROL KANAN)
-- ==========================================
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(255, 250, 238)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainWindow

local BrandTitleLabel = Instance.new("TextLabel")
BrandTitleLabel.Size = UDim2.new(0, 175, 1, 0)
BrandTitleLabel.Position = UDim2.new(0, 12, 0, 0)
BrandTitleLabel.BackgroundTransparency = 1
BrandTitleLabel.Text = "COPY MAP BY IKYY X STUDIO"
BrandTitleLabel.TextColor3 = Color3.fromRGB(35, 32, 26)
BrandTitleLabel.TextSize = 10
BrandTitleLabel.Font = Enum.Font.GothamBold
BrandTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
BrandTitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
BrandTitleLabel.Parent = TopBar

local TopTabContainer = Instance.new("Frame")
TopTabContainer.Size = UDim2.new(0, 336, 0, 24)
TopTabContainer.Position = UDim2.new(0.5, -152, 0.5, -12)
TopTabContainer.BackgroundTransparency = 1
TopTabContainer.Parent = TopBar

local TopTabLayout = Instance.new("UIListLayout")
TopTabLayout.FillDirection = Enum.FillDirection.Horizontal
TopTabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TopTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TopTabLayout.Padding = UDim.new(0, 6)
TopTabLayout.Parent = TopTabContainer

local tabButtons: {[string]: TextButton} = {}
local pageFrames: {[string]: Frame} = {}
local applyThemeAndFont: () -> () = function() end
local refreshImportFileList: () -> () = function() end

local function makeTopTab(tabKey: ToolModeTab, labelText: string)
	local btn = Instance.new("TextButton")
	btn.Name = "Tab_" .. tabKey
	btn.Size = UDim2.fromOffset(78, 22)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = labelText
	btn.TextColor3 = Color3.fromRGB(45, 42, 35)
	btn.TextSize = 8
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.Parent = TopTabContainer
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
	local st = Instance.new("UIStroke", btn)
	st.Color = Color3.fromRGB(228, 200, 132)
	st.Thickness = 1
	tabButtons[tabKey] = btn
	return btn
end

local function switchTab(tabKey: ToolModeTab)
	CONFIG.ActiveTab = tabKey
	for k, frame in pairs(pageFrames) do
		frame.Visible = (k == tabKey)
	end
	if tabKey == "ImportMap" then
		refreshImportFileList()
	end
	applyThemeAndFont()
end

makeTopTab("CopyMap", "COPY MAP")
makeTopTab("ImportMap", "IMPORT MAP")
makeTopTab("Music", "MUSIC")
makeTopTab("Settings", "SETTINGS")

for k, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		switchTab(k :: ToolModeTab)
	end)
end

local QuickSettingsBtn = Instance.new("TextButton")
QuickSettingsBtn.Size = UDim2.fromOffset(22, 22)
QuickSettingsBtn.Position = UDim2.new(1, -80, 0.5, -11)
QuickSettingsBtn.BackgroundColor3 = Color3.fromRGB(252, 246, 228)
QuickSettingsBtn.Text = "⚙"
QuickSettingsBtn.TextColor3 = Color3.fromRGB(40, 36, 28)
QuickSettingsBtn.TextSize = 11
QuickSettingsBtn.Font = Enum.Font.GothamBold
QuickSettingsBtn.Parent = TopBar
Instance.new("UICorner", QuickSettingsBtn).CornerRadius = UDim.new(0, 5)

local DragHandleBtn = Instance.new("TextButton")
DragHandleBtn.Size = UDim2.fromOffset(22, 22)
DragHandleBtn.Position = UDim2.new(1, -54, 0.5, -11)
DragHandleBtn.BackgroundColor3 = Color3.fromRGB(252, 246, 228)
DragHandleBtn.Text = "✥"
DragHandleBtn.TextColor3 = Color3.fromRGB(40, 36, 28)
DragHandleBtn.TextSize = 11
DragHandleBtn.Font = Enum.Font.GothamBold
DragHandleBtn.Parent = TopBar
Instance.new("UICorner", DragHandleBtn).CornerRadius = UDim.new(0, 5)

local CloseToCircleBtn = Instance.new("TextButton")
CloseToCircleBtn.Size = UDim2.fromOffset(22, 22)
CloseToCircleBtn.Position = UDim2.new(1, -28, 0.5, -11)
CloseToCircleBtn.BackgroundColor3 = Color3.fromRGB(255, 236, 236)
CloseToCircleBtn.Text = "✕"
CloseToCircleBtn.TextColor3 = Color3.fromRGB(185, 38, 52)
CloseToCircleBtn.TextSize = 10
CloseToCircleBtn.Font = Enum.Font.GothamBold
CloseToCircleBtn.Parent = TopBar
Instance.new("UICorner", CloseToCircleBtn).CornerRadius = UDim.new(0, 5)

QuickSettingsBtn.MouseButton1Click:Connect(function()
	switchTab("Settings")
end)

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

CloseToCircleBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

-- Drag MainWindow
do
	local draggingWin = false
	local dragStart = Vector3.zero
	local startPos = UDim2.new()
	local activeInput: InputObject? = nil

	local function beginDrag(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingWin = true
			activeInput = input
			dragStart = input.Position
			startPos = MainWindow.Position
		end
	end

	TopBar.InputBegan:Connect(beginDrag)
	DragHandleBtn.InputBegan:Connect(beginDrag)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if not draggingWin or input ~= activeInput then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			MainWindow.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == activeInput then
			draggingWin = false
			activeInput = nil
		end
	end)
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

-- ==========================================
-- BODY AREA (DUA KOLOM RAPI)
-- ==========================================
local BodyArea = Instance.new("Frame")
BodyArea.Name = "BodyArea"
BodyArea.Size = UDim2.new(1, -20, 1, -46)
BodyArea.Position = UDim2.new(0, 10, 0, 40)
BodyArea.BackgroundTransparency = 1
BodyArea.Parent = MainWindow

-- PAGE 1: COPY MAP (KOLOM KIRI: SERVICE STUDIO | KOLOM KANAN: AUTO FILE & LOG)
local CopyPage = Instance.new("Frame")
CopyPage.Size = UDim2.fromScale(1, 1)
CopyPage.BackgroundTransparency = 1
CopyPage.Visible = true
CopyPage.Parent = BodyArea
pageFrames["CopyMap"] = CopyPage

local LeftServiceCard = Instance.new("Frame")
LeftServiceCard.Size = UDim2.new(0.42, -5, 1, 0)
LeftServiceCard.Position = UDim2.new(0, 0, 0, 0)
LeftServiceCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
LeftServiceCard.BorderSizePixel = 0
LeftServiceCard.Parent = CopyPage
Instance.new("UICorner", LeftServiceCard).CornerRadius = UDim.new(0, 8)
local LeftStroke = Instance.new("UIStroke", LeftServiceCard)
LeftStroke.Color = Color3.fromRGB(235, 212, 152)
LeftStroke.Thickness = 1

local ServiceHeaderLbl = Instance.new("TextLabel")
ServiceHeaderLbl.Size = UDim2.new(1, -16, 0, 16)
ServiceHeaderLbl.Position = UDim2.new(0, 8, 0, 5)
ServiceHeaderLbl.BackgroundTransparency = 1
ServiceHeaderLbl.Text = "SERVICE STUDIO"
ServiceHeaderLbl.TextColor3 = Color3.fromRGB(45, 42, 35)
ServiceHeaderLbl.TextSize = 8
ServiceHeaderLbl.Font = Enum.Font.GothamBold
ServiceHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
ServiceHeaderLbl.Parent = LeftServiceCard

local FilterChipRow = Instance.new("Frame")
FilterChipRow.Size = UDim2.new(1, -16, 0, 18)
FilterChipRow.Position = UDim2.new(0, 8, 0, 21)
FilterChipRow.BackgroundTransparency = 1
FilterChipRow.Parent = LeftServiceCard

local FilterAllBtn = Instance.new("TextButton")
FilterAllBtn.Size = UDim2.new(0.33, -2, 1, 0)
FilterAllBtn.Position = UDim2.new(0, 0, 0, 0)
FilterAllBtn.BackgroundColor3 = Color3.fromRGB(255, 245, 214)
FilterAllBtn.Text = "Semua"
FilterAllBtn.TextColor3 = Color3.fromRGB(50, 44, 30)
FilterAllBtn.TextSize = 7
FilterAllBtn.Font = Enum.Font.GothamBold
FilterAllBtn.Parent = FilterChipRow
Instance.new("UICorner", FilterAllBtn).CornerRadius = UDim.new(0, 4)

local FilterMapBtn = Instance.new("TextButton")
FilterMapBtn.Size = UDim2.new(0.33, -2, 1, 0)
FilterMapBtn.Position = UDim2.new(0.33, 1, 0, 0)
FilterMapBtn.BackgroundColor3 = Color3.fromRGB(250, 248, 242)
FilterMapBtn.Text = "Map"
FilterMapBtn.TextColor3 = Color3.fromRGB(70, 66, 56)
FilterMapBtn.TextSize = 7
FilterMapBtn.Font = Enum.Font.GothamBold
FilterMapBtn.Parent = FilterChipRow
Instance.new("UICorner", FilterMapBtn).CornerRadius = UDim.new(0, 4)

local FilterPackBtn = Instance.new("TextButton")
FilterPackBtn.Size = UDim2.new(0.34, -2, 1, 0)
FilterPackBtn.Position = UDim2.new(0.66, 2, 0, 0)
FilterPackBtn.BackgroundColor3 = Color3.fromRGB(250, 248, 242)
FilterPackBtn.Text = "Pack"
FilterPackBtn.TextColor3 = Color3.fromRGB(70, 66, 56)
FilterPackBtn.TextSize = 7
FilterPackBtn.Font = Enum.Font.GothamBold
FilterPackBtn.Parent = FilterChipRow
Instance.new("UICorner", FilterPackBtn).CornerRadius = UDim.new(0, 4)

local ServiceListScroll = Instance.new("ScrollingFrame")
ServiceListScroll.Size = UDim2.new(1, -12, 1, -46)
ServiceListScroll.Position = UDim2.new(0, 6, 0, 42)
ServiceListScroll.BackgroundTransparency = 1
ServiceListScroll.BorderSizePixel = 0
ServiceListScroll.ScrollBarThickness = 2
ServiceListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ServiceListScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ServiceListScroll.Parent = LeftServiceCard

local ServiceListLayout = Instance.new("UIListLayout")
ServiceListLayout.Padding = UDim.new(0, 5)
ServiceListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ServiceListLayout.Parent = ServiceListScroll

local serviceRowToggles: {[string]: {row: Frame, radioBtn: TextButton, subLbl: TextLabel, titleLbl: TextLabel}} = {}

local function updateServiceCardVisuals()
	for _, sName in ipairs(SERVICE_LIST) do
		local item = serviceRowToggles[sName]
		if item then
			local enabled = CONFIG.SelectedServices[sName] == true
			local okS, srv = pcall(game.GetService, game, sName)
			local childCount = (okS and srv) and #srv:GetChildren() or 0
			item.subLbl.Text = tostring(childCount) .. " item" .. (sName == "StarterPack" and " • Decompile" or " • NoScript")
			item.radioBtn.BackgroundColor3 = enabled and Color3.fromRGB(245, 178, 36) or Color3.fromRGB(235, 232, 224)
			item.radioBtn.Text = enabled and "●" or ""
		end
	end
end

for idx, sName in ipairs(SERVICE_LIST) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, 36)
	row.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
	row.BorderSizePixel = 0
	row.LayoutOrder = idx
	row.Parent = ServiceListScroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	local rStroke = Instance.new("UIStroke", row)
	rStroke.Color = Color3.fromRGB(236, 216, 166)
	rStroke.Thickness = 1

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -36, 0, 14)
	titleLbl.Position = UDim2.new(0, 8, 0, 4)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = sName
	titleLbl.TextColor3 = Color3.fromRGB(35, 32, 26)
	titleLbl.TextSize = 9
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = row

	local subLbl = Instance.new("TextLabel")
	subLbl.Size = UDim2.new(1, -36, 0, 11)
	subLbl.Position = UDim2.new(0, 8, 0, 19)
	subLbl.BackgroundTransparency = 1
	subLbl.Text = "0 item"
	subLbl.TextColor3 = Color3.fromRGB(130, 122, 102)
	subLbl.TextSize = 7
	subLbl.Font = Enum.Font.GothamMedium
	subLbl.TextXAlignment = Enum.TextXAlignment.Left
	subLbl.Parent = row

	local radioBtn = Instance.new("TextButton")
	radioBtn.Size = UDim2.fromOffset(16, 16)
	radioBtn.Position = UDim2.new(1, -24, 0.5, -8)
	radioBtn.BackgroundColor3 = Color3.fromRGB(245, 178, 36)
	radioBtn.Text = "●"
	radioBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	radioBtn.TextSize = 9
	radioBtn.Font = Enum.Font.GothamBold
	radioBtn.Parent = row
	Instance.new("UICorner", radioBtn).CornerRadius = UDim.new(1, 0)

	local function toggleService()
		CONFIG.SelectedServices[sName] = not (CONFIG.SelectedServices[sName] == true)
		updateServiceCardVisuals()
	end

	radioBtn.MouseButton1Click:Connect(toggleService)
	serviceRowToggles[sName] = { row = row, radioBtn = radioBtn, subLbl = subLbl, titleLbl = titleLbl }
end

FilterAllBtn.MouseButton1Click:Connect(function()
	for _, sName in ipairs(SERVICE_LIST) do CONFIG.SelectedServices[sName] = true end
	updateServiceCardVisuals()
end)
FilterMapBtn.MouseButton1Click:Connect(function()
	for _, sName in ipairs(SERVICE_LIST) do
		CONFIG.SelectedServices[sName] = (sName == "Workspace" or sName == "Lighting" or sName == "MaterialService")
	end
	updateServiceCardVisuals()
end)
FilterPackBtn.MouseButton1Click:Connect(function()
	for _, sName in ipairs(SERVICE_LIST) do CONFIG.SelectedServices[sName] = (sName == "StarterPack") end
	updateServiceCardVisuals()
end)

-- Kolom Kanan Copy Map
local RightControlCard = Instance.new("Frame")
RightControlCard.Size = UDim2.new(0.58, -5, 1, 0)
RightControlCard.Position = UDim2.new(0.42, 5, 0, 0)
RightControlCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
RightControlCard.BorderSizePixel = 0
RightControlCard.Parent = CopyPage
Instance.new("UICorner", RightControlCard).CornerRadius = UDim.new(0, 8)
local RightStroke = Instance.new("UIStroke", RightControlCard)
RightStroke.Color = Color3.fromRGB(235, 212, 152)
RightStroke.Thickness = 1

local RightHeaderLbl = Instance.new("TextLabel")
RightHeaderLbl.Size = UDim2.new(1, -16, 0, 15)
RightHeaderLbl.Position = UDim2.new(0, 8, 0, 4)
RightHeaderLbl.BackgroundTransparency = 1
RightHeaderLbl.Text = "COPY MAP • SIMPAN KE FILE INTERNAL"
RightHeaderLbl.TextColor3 = Color3.fromRGB(45, 42, 35)
RightHeaderLbl.TextSize = 8
RightHeaderLbl.Font = Enum.Font.GothamBold
RightHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
RightHeaderLbl.Parent = RightControlCard

local InfoGrid = Instance.new("Frame")
InfoGrid.Size = UDim2.new(1, -16, 0, 62)
InfoGrid.Position = UDim2.new(0, 8, 0, 20)
InfoGrid.BackgroundTransparency = 1
InfoGrid.Parent = RightControlCard

local function makeInfoTile(col: number, rowIdx: number, tagTxt: string, valTxt: string): TextLabel
	local tile = Instance.new("Frame")
	tile.Size = UDim2.new(0.5, -3, 0.5, -2)
	tile.Position = UDim2.new(col * 0.5, (col == 1 and 3 or 0), rowIdx * 0.5, (rowIdx == 1 and 2 or 0))
	tile.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
	tile.BorderSizePixel = 0
	tile.Parent = InfoGrid
	Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 5)
	local st = Instance.new("UIStroke", tile)
	st.Color = Color3.fromRGB(238, 220, 174)
	st.Thickness = 1

	local tLbl = Instance.new("TextLabel")
	tLbl.Size = UDim2.new(1, -8, 0, 10)
	tLbl.Position = UDim2.new(0, 4, 0, 2)
	tLbl.BackgroundTransparency = 1
	tLbl.Text = tagTxt
	tLbl.TextColor3 = Color3.fromRGB(130, 122, 102)
	tLbl.TextSize = 6
	tLbl.Font = Enum.Font.GothamBold
	tLbl.TextXAlignment = Enum.TextXAlignment.Left
	tLbl.Parent = tile

	local vLbl = Instance.new("TextLabel")
	vLbl.Size = UDim2.new(1, -8, 0, 13)
	vLbl.Position = UDim2.new(0, 4, 0, 12)
	vLbl.BackgroundTransparency = 1
	vLbl.Text = valTxt
	vLbl.TextColor3 = Color3.fromRGB(35, 32, 26)
	vLbl.TextSize = 8
	vLbl.Font = Enum.Font.GothamBold
	vLbl.TextXAlignment = Enum.TextXAlignment.Left
	vLbl.TextTruncate = Enum.TextTruncate.AtEnd
	vLbl.Parent = tile
	return vLbl
end

makeInfoTile(0, 0, "BAYANGAN", "OFF (Ringan)")
makeInfoTile(1, 0, "MAP SCRIPT", "Skip Script/Local")
makeInfoTile(0, 1, "STARTERPACK", "Script + Decompile")
makeInfoTile(1, 1, "PENYIMPANAN", "Internal File JSON")

local AutoFileBanner = Instance.new("Frame")
AutoFileBanner.Size = UDim2.new(1, -16, 0, 24)
AutoFileBanner.Position = UDim2.new(0, 8, 0, 87)
AutoFileBanner.BackgroundColor3 = Color3.fromRGB(252, 249, 242)
AutoFileBanner.BorderSizePixel = 0
AutoFileBanner.Parent = RightControlCard
Instance.new("UICorner", AutoFileBanner).CornerRadius = UDim.new(0, 6)
local AutoBannerStroke = Instance.new("UIStroke", AutoFileBanner)
AutoBannerStroke.Color = Color3.fromRGB(232, 208, 148)
AutoBannerStroke.Thickness = 1

local AutoFilePreviewLbl = Instance.new("TextLabel")
AutoFilePreviewLbl.Size = UDim2.new(1, -12, 1, 0)
AutoFilePreviewLbl.Position = UDim2.new(0, 6, 0, 0)
AutoFilePreviewLbl.BackgroundTransparency = 1
AutoFilePreviewLbl.Text = "File: otomatis mengikuti nama game saat COPY MAP"
AutoFilePreviewLbl.TextColor3 = Color3.fromRGB(45, 42, 35)
AutoFilePreviewLbl.TextSize = 8
AutoFilePreviewLbl.Font = Enum.Font.Code
AutoFilePreviewLbl.TextXAlignment = Enum.TextXAlignment.Left
AutoFilePreviewLbl.TextTruncate = Enum.TextTruncate.AtEnd
AutoFilePreviewLbl.Parent = AutoFileBanner

local StatusLogBox = Instance.new("Frame")
StatusLogBox.Size = UDim2.new(1, -16, 1, -154)
StatusLogBox.Position = UDim2.new(0, 8, 0, 115)
StatusLogBox.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
StatusLogBox.BorderSizePixel = 0
StatusLogBox.Parent = RightControlCard
Instance.new("UICorner", StatusLogBox).CornerRadius = UDim.new(0, 6)
local LogStroke = Instance.new("UIStroke", StatusLogBox)
LogStroke.Color = Color3.fromRGB(238, 222, 178)
LogStroke.Thickness = 1

local StatusHeadlineLbl = Instance.new("TextLabel")
StatusHeadlineLbl.Size = UDim2.new(1, -12, 0, 13)
StatusHeadlineLbl.Position = UDim2.new(0, 6, 0, 3)
StatusHeadlineLbl.BackgroundTransparency = 1
StatusHeadlineLbl.Text = "Siap simpan hasil copy ke file internal"
StatusHeadlineLbl.TextColor3 = Color3.fromRGB(35, 32, 26)
StatusHeadlineLbl.TextSize = 8
StatusHeadlineLbl.Font = Enum.Font.GothamBold
StatusHeadlineLbl.TextXAlignment = Enum.TextXAlignment.Left
StatusHeadlineLbl.Parent = StatusLogBox

local ProgTrack = Instance.new("Frame")
ProgTrack.Size = UDim2.new(1, -12, 0, 5)
ProgTrack.Position = UDim2.new(0, 6, 0, 19)
ProgTrack.BackgroundColor3 = Color3.fromRGB(240, 232, 210)
ProgTrack.BorderSizePixel = 0
ProgTrack.Parent = StatusLogBox
Instance.new("UICorner", ProgTrack).CornerRadius = UDim.new(1, 0)

local ProgFill = Instance.new("Frame")
ProgFill.Size = UDim2.new(0, 0, 1, 0)
ProgFill.BackgroundColor3 = Color3.fromRGB(245, 178, 36)
ProgFill.BorderSizePixel = 0
ProgFill.Parent = ProgTrack
Instance.new("UICorner", ProgFill).CornerRadius = UDim.new(1, 0)

local LogScroll = Instance.new("ScrollingFrame")
LogScroll.Size = UDim2.new(1, -12, 1, -28)
LogScroll.Position = UDim2.new(0, 6, 0, 26)
LogScroll.BackgroundTransparency = 1
LogScroll.BorderSizePixel = 0
LogScroll.ScrollBarThickness = 2
LogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
LogScroll.Parent = StatusLogBox

local LogTextLbl = Instance.new("TextLabel")
LogTextLbl.Size = UDim2.new(1, -4, 0, 16)
LogTextLbl.AutomaticSize = Enum.AutomaticSize.Y
LogTextLbl.BackgroundTransparency = 1
LogTextLbl.Text = "[Ready] Menyimpan ke folder internal: " .. CONFIG.WorkspaceRoot .. "/\n[Ready] Buka tab IMPORT MAP di game lain untuk memilih file."
LogTextLbl.TextColor3 = Color3.fromRGB(95, 88, 72)
LogTextLbl.TextSize = 7
LogTextLbl.Font = Enum.Font.Code
LogTextLbl.TextXAlignment = Enum.TextXAlignment.Left
LogTextLbl.TextYAlignment = Enum.TextYAlignment.Top
LogTextLbl.TextWrapped = true
LogTextLbl.Parent = LogScroll

local PrimaryCopyBtn = Instance.new("TextButton")
PrimaryCopyBtn.Size = UDim2.new(1, -16, 0, 28)
PrimaryCopyBtn.Position = UDim2.new(0, 8, 1, -34)
PrimaryCopyBtn.BackgroundColor3 = Color3.fromRGB(245, 178, 36)
PrimaryCopyBtn.Text = "COPY MAP"
PrimaryCopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PrimaryCopyBtn.TextSize = 9
PrimaryCopyBtn.Font = Enum.Font.GothamBold
PrimaryCopyBtn.Parent = RightControlCard
Instance.new("UICorner", PrimaryCopyBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- PAGE 2: IMPORT MAP (LIST FILE OTOMATIS + TARGET SERVICE)
-- ==========================================
local ImportPage = Instance.new("Frame")
ImportPage.Size = UDim2.fromScale(1, 1)
ImportPage.BackgroundTransparency = 1
ImportPage.Visible = false
ImportPage.Parent = BodyArea
pageFrames["ImportMap"] = ImportPage

-- Kolom Kiri Import: Daftar File Hasil Copy
local ImportFileCard = Instance.new("Frame")
ImportFileCard.Size = UDim2.new(0.45, -5, 1, 0)
ImportFileCard.Position = UDim2.new(0, 0, 0, 0)
ImportFileCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImportFileCard.BorderSizePixel = 0
ImportFileCard.Parent = ImportPage
Instance.new("UICorner", ImportFileCard).CornerRadius = UDim.new(0, 8)
local ImpLeftStroke = Instance.new("UIStroke", ImportFileCard)
ImpLeftStroke.Color = Color3.fromRGB(235, 212, 152)
ImpLeftStroke.Thickness = 1

local FileListTitleLbl = Instance.new("TextLabel")
FileListTitleLbl.Size = UDim2.new(1, -68, 0, 18)
FileListTitleLbl.Position = UDim2.new(0, 8, 0, 5)
FileListTitleLbl.BackgroundTransparency = 1
FileListTitleLbl.Text = "LIST FILE TERSIMPAN"
FileListTitleLbl.TextColor3 = Color3.fromRGB(45, 42, 35)
FileListTitleLbl.TextSize = 8
FileListTitleLbl.Font = Enum.Font.GothamBold
FileListTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
FileListTitleLbl.Parent = ImportFileCard

local RefreshFilesBtn = Instance.new("TextButton")
RefreshFilesBtn.Size = UDim2.fromOffset(54, 18)
RefreshFilesBtn.Position = UDim2.new(1, -62, 0, 5)
RefreshFilesBtn.BackgroundColor3 = Color3.fromRGB(255, 245, 214)
RefreshFilesBtn.Text = "↻ Refresh"
RefreshFilesBtn.TextColor3 = Color3.fromRGB(50, 44, 30)
RefreshFilesBtn.TextSize = 7
RefreshFilesBtn.Font = Enum.Font.GothamBold
RefreshFilesBtn.Parent = ImportFileCard
Instance.new("UICorner", RefreshFilesBtn).CornerRadius = UDim.new(0, 4)

local SavedFilesScroll = Instance.new("ScrollingFrame")
SavedFilesScroll.Size = UDim2.new(1, -12, 1, -30)
SavedFilesScroll.Position = UDim2.new(0, 6, 0, 26)
SavedFilesScroll.BackgroundTransparency = 1
SavedFilesScroll.BorderSizePixel = 0
SavedFilesScroll.ScrollBarThickness = 2
SavedFilesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SavedFilesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SavedFilesScroll.Parent = ImportFileCard

local SavedFilesLayout = Instance.new("UIListLayout")
SavedFilesLayout.Padding = UDim.new(0, 5)
SavedFilesLayout.SortOrder = Enum.SortOrder.LayoutOrder
SavedFilesLayout.Parent = SavedFilesScroll

-- Kolom Kanan Import: Target Service + Opsi + Tombol IMPORT MAP
local ImportRightCard = Instance.new("Frame")
ImportRightCard.Size = UDim2.new(0.55, -5, 1, 0)
ImportRightCard.Position = UDim2.new(0.45, 5, 0, 0)
ImportRightCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImportRightCard.BorderSizePixel = 0
ImportRightCard.Parent = ImportPage
Instance.new("UICorner", ImportRightCard).CornerRadius = UDim.new(0, 8)
local ImpRightStroke = Instance.new("UIStroke", ImportRightCard)
ImpRightStroke.Color = Color3.fromRGB(235, 212, 152)
ImpRightStroke.Thickness = 1

local ImpRightTitle = Instance.new("TextLabel")
ImpRightTitle.Size = UDim2.new(1, -16, 0, 15)
ImpRightTitle.Position = UDim2.new(0, 8, 0, 5)
ImpRightTitle.BackgroundTransparency = 1
ImpRightTitle.Text = "IMPORT KE GAME INI"
ImpRightTitle.TextColor3 = Color3.fromRGB(45, 42, 35)
ImpRightTitle.TextSize = 8
ImpRightTitle.Font = Enum.Font.GothamBold
ImpRightTitle.TextXAlignment = Enum.TextXAlignment.Left
ImpRightTitle.Parent = ImportRightCard

local selectedImportTarget = "Workspace"
local importTargetBtns: {[string]: TextButton} = {}

local function refreshImportTargetBtns()
	for sName, btn in pairs(importTargetBtns) do
		local active = (sName == selectedImportTarget)
		btn.BackgroundColor3 = active and Color3.fromRGB(255, 245, 214) or Color3.fromRGB(255, 253, 248)
		btn.Text = (active and "● " or "○ ") .. sName
	end
end

local targetList = { "Workspace", "StarterPack", "Lighting", "ReplicatedStorage" }
for i, sName in ipairs(targetList) do
	local col = (i - 1) % 2
	local rowIdx = math.floor((i - 1) / 2)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.5, -10, 0, 22)
	b.Position = UDim2.new(col * 0.5, (col == 0 and 8 or 2), 0, 22 + rowIdx * 25)
	b.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
	b.Text = "○ " .. sName
	b.TextColor3 = Color3.fromRGB(35, 32, 26)
	b.TextSize = 7
	b.Font = Enum.Font.GothamBold
	b.Parent = ImportRightCard
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	local st = Instance.new("UIStroke", b)
	st.Color = Color3.fromRGB(236, 216, 166)
	st.Thickness = 1
	importTargetBtns[sName] = b
	b.MouseButton1Click:Connect(function()
		selectedImportTarget = sName
		refreshImportTargetBtns()
	end)
end
refreshImportTargetBtns()

local PosToggleBtn = Instance.new("TextButton")
PosToggleBtn.Size = UDim2.new(0.5, -10, 0, 22)
PosToggleBtn.Position = UDim2.new(0, 8, 0, 74)
PosToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
PosToggleBtn.Text = "Posisi: Original CF"
PosToggleBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
PosToggleBtn.TextSize = 7
PosToggleBtn.Font = Enum.Font.GothamBold
PosToggleBtn.Parent = ImportRightCard
Instance.new("UICorner", PosToggleBtn).CornerRadius = UDim.new(0, 5)

local AnchorToggleBtn = Instance.new("TextButton")
AnchorToggleBtn.Size = UDim2.new(0.5, -10, 0, 22)
AnchorToggleBtn.Position = UDim2.new(0.5, 2, 0, 74)
AnchorToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 245, 214)
AnchorToggleBtn.Text = "Anchor: ON"
AnchorToggleBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
AnchorToggleBtn.TextSize = 7
AnchorToggleBtn.Font = Enum.Font.GothamBold
AnchorToggleBtn.Parent = ImportRightCard
Instance.new("UICorner", AnchorToggleBtn).CornerRadius = UDim.new(0, 5)

PosToggleBtn.MouseButton1Click:Connect(function()
	if CONFIG.MapPosMode == "OriginalCF" then
		CONFIG.MapPosMode = "InFrontOfChar"
		PosToggleBtn.Text = "Posisi: Depan Char"
	else
		CONFIG.MapPosMode = "OriginalCF"
		PosToggleBtn.Text = "Posisi: Original CF"
	end
end)

AnchorToggleBtn.MouseButton1Click:Connect(function()
	CONFIG.MapAutoAnchor = not CONFIG.MapAutoAnchor
	AnchorToggleBtn.Text = CONFIG.MapAutoAnchor and "Anchor: ON" or "Anchor: OFF"
end)

local SelectedFileBanner = Instance.new("TextLabel")
SelectedFileBanner.Size = UDim2.new(1, -16, 0, 20)
SelectedFileBanner.Position = UDim2.new(0, 8, 0, 100)
SelectedFileBanner.BackgroundColor3 = Color3.fromRGB(252, 249, 242)
SelectedFileBanner.Text = "File terpilih: (klik file di list kiri)"
SelectedFileBanner.TextColor3 = Color3.fromRGB(45, 42, 35)
SelectedFileBanner.TextSize = 7
SelectedFileBanner.Font = Enum.Font.Code
SelectedFileBanner.TextXAlignment = Enum.TextXAlignment.Left
SelectedFileBanner.TextTruncate = Enum.TextTruncate.AtEnd
SelectedFileBanner.Parent = ImportRightCard
Instance.new("UICorner", SelectedFileBanner).CornerRadius = UDim.new(0, 5)

local ImportInfoLbl = Instance.new("TextLabel")
ImportInfoLbl.Size = UDim2.new(1, -16, 1, -160)
ImportInfoLbl.Position = UDim2.new(0, 8, 0, 124)
ImportInfoLbl.BackgroundColor3 = Color3.fromRGB(255, 253, 248)
ImportInfoLbl.Text = "• Pilih file dari list di kiri (hasil copy game sebelumnya).\n• Tanpa bayangan (CastShadow=OFF & Shadows=OFF) agar ringan.\n• Target StarterPack memulihkan item + decompile Script/LocalScript."
ImportInfoLbl.TextColor3 = Color3.fromRGB(80, 74, 60)
ImportInfoLbl.TextSize = 7
ImportInfoLbl.Font = Enum.Font.GothamMedium
ImportInfoLbl.TextXAlignment = Enum.TextXAlignment.Left
ImportInfoLbl.TextYAlignment = Enum.TextYAlignment.Top
ImportInfoLbl.TextWrapped = true
ImportInfoLbl.Parent = ImportRightCard
Instance.new("UICorner", ImportInfoLbl).CornerRadius = UDim.new(0, 6)

local PrimaryImportBtn = Instance.new("TextButton")
PrimaryImportBtn.Size = UDim2.new(1, -16, 0, 28)
PrimaryImportBtn.Position = UDim2.new(0, 8, 1, -34)
PrimaryImportBtn.BackgroundColor3 = Color3.fromRGB(245, 178, 36)
PrimaryImportBtn.Text = "IMPORT MAP"
PrimaryImportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PrimaryImportBtn.TextSize = 9
PrimaryImportBtn.Font = Enum.Font.GothamBold
PrimaryImportBtn.Parent = ImportRightCard
Instance.new("UICorner", PrimaryImportBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- PAGE 3: MUSIC PLAYER
-- ==========================================
local MusicPage = Instance.new("Frame")
MusicPage.Size = UDim2.fromScale(1, 1)
MusicPage.BackgroundTransparency = 1
MusicPage.Visible = false
MusicPage.Parent = BodyArea
pageFrames["Music"] = MusicPage

local MusicLeftCard = Instance.new("Frame")
MusicLeftCard.Size = UDim2.new(0.46, -5, 1, 0)
MusicLeftCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MusicLeftCard.Parent = MusicPage
Instance.new("UICorner", MusicLeftCard).CornerRadius = UDim.new(0, 8)
local MusLeftStroke = Instance.new("UIStroke", MusicLeftCard)
MusLeftStroke.Color = Color3.fromRGB(235, 212, 152)
MusLeftStroke.Thickness = 1

local PlaylistScroll = Instance.new("ScrollingFrame")
PlaylistScroll.Size = UDim2.new(1, -12, 1, -12)
PlaylistScroll.Position = UDim2.new(0, 6, 0, 6)
PlaylistScroll.BackgroundTransparency = 1
PlaylistScroll.BorderSizePixel = 0
PlaylistScroll.ScrollBarThickness = 2
PlaylistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlaylistScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlaylistScroll.Parent = MusicLeftCard

local PlLayout = Instance.new("UIListLayout")
PlLayout.Padding = UDim.new(0, 4)
PlLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlLayout.Parent = PlaylistScroll

local MusicRightCard = Instance.new("Frame")
MusicRightCard.Size = UDim2.new(0.54, -5, 1, 0)
MusicRightCard.Position = UDim2.new(0.46, 5, 0, 0)
MusicRightCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MusicRightCard.Parent = MusicPage
Instance.new("UICorner", MusicRightCard).CornerRadius = UDim.new(0, 8)
local MusRightStroke = Instance.new("UIStroke", MusicRightCard)
MusRightStroke.Color = Color3.fromRGB(235, 212, 152)
MusRightStroke.Thickness = 1

local TrackTitleLbl = Instance.new("TextLabel")
TrackTitleLbl.Size = UDim2.new(1, -16, 0, 16)
TrackTitleLbl.Position = UDim2.new(0, 8, 0, 8)
TrackTitleLbl.BackgroundTransparency = 1
TrackTitleLbl.Text = "♪ " .. DEFAULT_MUSIC_PLAYLIST[1].name
TrackTitleLbl.TextColor3 = Color3.fromRGB(35, 32, 26)
TrackTitleLbl.TextSize = 10
TrackTitleLbl.Font = Enum.Font.GothamBold
TrackTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TrackTitleLbl.Parent = MusicRightCard

local TrackSubLbl = Instance.new("TextLabel")
TrackSubLbl.Size = UDim2.new(1, -16, 0, 12)
TrackSubLbl.Position = UDim2.new(0, 8, 0, 24)
TrackSubLbl.BackgroundTransparency = 1
TrackSubLbl.Text = "ID: " .. DEFAULT_MUSIC_PLAYLIST[1].songId .. " • Vol 50%"
TrackSubLbl.TextColor3 = Color3.fromRGB(120, 112, 95)
TrackSubLbl.TextSize = 8
TrackSubLbl.Font = Enum.Font.GothamMedium
TrackSubLbl.TextXAlignment = Enum.TextXAlignment.Left
TrackSubLbl.Parent = MusicRightCard

local EqBox = Instance.new("Frame")
EqBox.Size = UDim2.new(1, -16, 0, 56)
EqBox.Position = UDim2.new(0, 8, 0, 42)
EqBox.BackgroundColor3 = Color3.fromRGB(255, 250, 236)
EqBox.Parent = MusicRightCard
Instance.new("UICorner", EqBox).CornerRadius = UDim.new(0, 6)

local eqBars: {Frame} = {}
for i = 1, 14 do
	local b = Instance.new("Frame")
	b.Size = UDim2.fromOffset(10, 8)
	b.Position = UDim2.fromOffset(12 + (i - 1) * 16, 42)
	b.BackgroundColor3 = Color3.fromRGB(245, 178, 36)
	b.BorderSizePixel = 0
	b.Parent = EqBox
	Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
	table.insert(eqBars, b)
end

local PrevBtn = Instance.new("TextButton")
PrevBtn.Size = UDim2.new(0.26, -6, 0, 26)
PrevBtn.Position = UDim2.new(0, 8, 0, 108)
PrevBtn.BackgroundColor3 = Color3.fromRGB(252, 246, 228)
PrevBtn.Text = "<<"
PrevBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
PrevBtn.TextSize = 10
PrevBtn.Font = Enum.Font.GothamBold
PrevBtn.Parent = MusicRightCard
Instance.new("UICorner", PrevBtn).CornerRadius = UDim.new(0, 6)

local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0.48, -4, 0, 26)
PlayBtn.Position = UDim2.new(0.26, 2, 0, 108)
PlayBtn.BackgroundColor3 = Color3.fromRGB(245, 178, 36)
PlayBtn.Text = "▶ PLAY"
PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayBtn.TextSize = 9
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.Parent = MusicRightCard
Instance.new("UICorner", PlayBtn).CornerRadius = UDim.new(0, 6)

local NextBtn = Instance.new("TextButton")
NextBtn.Size = UDim2.new(0.26, -6, 0, 26)
NextBtn.Position = UDim2.new(0.74, 0, 0, 108)
NextBtn.BackgroundColor3 = Color3.fromRGB(252, 246, 228)
NextBtn.Text = ">>"
NextBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
NextBtn.TextSize = 10
NextBtn.Font = Enum.Font.GothamBold
NextBtn.Parent = MusicRightCard
Instance.new("UICorner", NextBtn).CornerRadius = UDim.new(0, 6)

local MusicGroup = Instance.new("SoundGroup")
MusicGroup.Name = "IkyyStudioLite_MusicGroup"
MusicGroup.Volume = 0.5
MusicGroup.Parent = SoundService

local MusicSound = Instance.new("Sound")
MusicSound.Name = "IkyyStudioLite_TrackSound"
MusicSound.SoundGroup = MusicGroup
MusicSound.Looped = true
MusicSound.Parent = MusicGroup

local currentTrackIdx = 1
local isPlayingMusic = false

local function selectTrack(idx: number, autoPlay: boolean)
	if idx < 1 then idx = #DEFAULT_MUSIC_PLAYLIST elseif idx > #DEFAULT_MUSIC_PLAYLIST then idx = 1 end
	currentTrackIdx = idx
	local tr = DEFAULT_MUSIC_PLAYLIST[currentTrackIdx]
	TrackTitleLbl.Text = "♪ " .. tr.name
	TrackSubLbl.Text = "ID: " .. tr.songId .. (autoPlay and " • Memutar" or " • Siap")
	MusicSound.SoundId = "rbxassetid://" .. tr.songId
	MusicSound.PlaybackSpeed = tr.playbackSpeed
	isPlayingMusic = autoPlay
	PlayBtn.Text = autoPlay and "⏸ JEDA" or "▶ PLAY"
	if autoPlay then
		pcall(function() MusicSound:Play() end)
	else
		pcall(function() MusicSound:Pause() end)
	end
end

for idx, tr in ipairs(DEFAULT_MUSIC_PLAYLIST) do
	local rowBtn = Instance.new("TextButton")
	rowBtn.Size = UDim2.new(1, -4, 0, 24)
	rowBtn.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
	rowBtn.Text = string.format("  %d. %s", idx, tr.name)
	rowBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
	rowBtn.TextSize = 8
	rowBtn.Font = Enum.Font.GothamBold
	rowBtn.TextXAlignment = Enum.TextXAlignment.Left
	rowBtn.LayoutOrder = idx
	rowBtn.Parent = PlaylistScroll
	Instance.new("UICorner", rowBtn).CornerRadius = UDim.new(0, 5)
	rowBtn.MouseButton1Click:Connect(function()
		selectTrack(idx, true)
	end)
end

PlayBtn.MouseButton1Click:Connect(function()
	selectTrack(currentTrackIdx, not isPlayingMusic)
end)
PrevBtn.MouseButton1Click:Connect(function()
	selectTrack(currentTrackIdx - 1, true)
end)
NextBtn.MouseButton1Click:Connect(function()
	selectTrack(currentTrackIdx + 1, true)
end)

do
	local tElapsed = 0
	RunService.RenderStepped:Connect(function(dt: number)
		tElapsed += dt
		local theme = GUI_THEMES[CONFIG.ThemeIndex]
		for i, b in ipairs(eqBars) do
			b.BackgroundColor3 = (i % 2 == 0) and theme.eqEven or theme.eqOdd
			local h = isPlayingMusic and math.floor(8 + math.abs(math.sin(tElapsed * 9 + i * 0.6)) * 36) or 7
			b.Size = UDim2.fromOffset(10, h)
			b.Position = UDim2.fromOffset(12 + (i - 1) * 16, 50 - h)
		end
	end)
end

-- PAGE 4: SETTINGS & ABOUT
local SettingsPage = Instance.new("Frame")
SettingsPage.Size = UDim2.fromScale(1, 1)
SettingsPage.BackgroundTransparency = 1
SettingsPage.Visible = false
SettingsPage.Parent = BodyArea
pageFrames["Settings"] = SettingsPage

local SettingsCard = Instance.new("Frame")
SettingsCard.Size = UDim2.fromScale(1, 1)
SettingsCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SettingsCard.Parent = SettingsPage
Instance.new("UICorner", SettingsCard).CornerRadius = UDim.new(0, 8)
local SetStroke = Instance.new("UIStroke", SettingsCard)
SetStroke.Color = Color3.fromRGB(235, 212, 152)
SetStroke.Thickness = 1

local SetTitleLbl = Instance.new("TextLabel")
SetTitleLbl.Size = UDim2.new(1, -16, 0, 18)
SetTitleLbl.Position = UDim2.new(0, 8, 0, 8)
SetTitleLbl.BackgroundTransparency = 1
SetTitleLbl.Text = "TEMA WARNA & FONT • BY IKYY (@" .. LocalPlayer.Name .. ")"
SetTitleLbl.TextColor3 = Color3.fromRGB(35, 32, 26)
SetTitleLbl.TextSize = 9
SetTitleLbl.Font = Enum.Font.GothamBold
SetTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
SetTitleLbl.Parent = SettingsCard

for idx, th in ipairs(GUI_THEMES) do
	local tBtn = Instance.new("TextButton")
	tBtn.Size = UDim2.new(0.25, -8, 0, 26)
	tBtn.Position = UDim2.new((idx - 1) * 0.25, 8, 0, 34)
	tBtn.BackgroundColor3 = th.accentSoft
	tBtn.Text = th.name
	tBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
	tBtn.TextSize = 8
	tBtn.Font = Enum.Font.GothamBold
	tBtn.Parent = SettingsCard
	Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
	tBtn.MouseButton1Click:Connect(function()
		CONFIG.ThemeIndex = idx
		applyThemeAndFont()
	end)
end

for idx, fp in ipairs(FONT_PRESETS) do
	local fBtn = Instance.new("TextButton")
	fBtn.Size = UDim2.new(0.25, -8, 0, 26)
	fBtn.Position = UDim2.new((idx - 1) * 0.25, 8, 0, 68)
	fBtn.BackgroundColor3 = Color3.fromRGB(252, 249, 242)
	fBtn.Text = fp.name
	fBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
	fBtn.TextSize = 9
	fBtn.Font = fp.font
	fBtn.Parent = SettingsCard
	Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 6)
	fBtn.MouseButton1Click:Connect(function()
		CONFIG.FontIndex = idx
		applyThemeAndFont()
	end)
end

local AboutSummaryLbl = Instance.new("TextLabel")
AboutSummaryLbl.Size = UDim2.new(1, -16, 1, -110)
AboutSummaryLbl.Position = UDim2.new(0, 8, 0, 102)
AboutSummaryLbl.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
AboutSummaryLbl.Text = "Plugin Studio Lite (Delta Executor Edition) v2.0.0\n• Menyimpan file internal ke folder: " .. CONFIG.WorkspaceRoot .. "/\n• Tab IMPORT MAP menampilkan list file tersimpan untuk dipilih langsung lintas game\n• Bayangan OFF (CastShadow/Shadows OFF) + Map NoScript + StarterPack Decompile"
AboutSummaryLbl.TextColor3 = Color3.fromRGB(70, 64, 52)
AboutSummaryLbl.TextSize = 8
AboutSummaryLbl.Font = Enum.Font.Code
AboutSummaryLbl.TextXAlignment = Enum.TextXAlignment.Left
AboutSummaryLbl.TextYAlignment = Enum.TextYAlignment.Top
AboutSummaryLbl.TextWrapped = true
AboutSummaryLbl.Parent = SettingsCard
Instance.new("UICorner", AboutSummaryLbl).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- FILE SYSTEM INTERNAL, DECOMPILE & COPY/IMPORT
-- ==========================================
local function appendMapLog(msg: string)
	if LogTextLbl.Text == "" then
		LogTextLbl.Text = msg
	else
		LogTextLbl.Text = LogTextLbl.Text .. "\n" .. msg
	end
end

local function setProgress(ratio: number)
	local c = math.clamp(ratio, 0, 1)
	CONFIG.CopyProgress = c
	ProgFill.Size = UDim2.new(c, 0, 1, 0)
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

local function getCurrentGameTitle(): string
	local title = tostring(game.Name or "RobloxGame")
	local okInfo, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(game.PlaceId)
	end)
	if okInfo and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
		title = info.Name
	end
	local clean = string.gsub(title, "[^%w%s%-_]", "")
	clean = string.gsub(clean, "%s+", "_")
	clean = string.gsub(clean, "_+", "_")
	clean = string.gsub(clean, "^_+", "")
	clean = string.gsub(clean, "_+$", "")
	if clean == "" then
		clean = "RobloxGame"
	end
	if #clean > 44 then
		clean = string.sub(clean, 1, 44)
	end
	return clean
end

local function buildAutoGameFileName(): string
	local gameSlug = getCurrentGameTitle()
	local placePart = tostring(game.PlaceId > 0 and game.PlaceId or game.GameId)
	return sanitizeFileName(gameSlug .. "_" .. placePart .. ".json")
end

local function resolveExecFn(fnName: string): ((...any) -> any)?
	local okG, directFn = pcall(function()
		return (getfenv(0) :: any)[fnName]
	end)
	if okG and type(directFn) == "function" then
		return directFn
	end

	local okL, localFn = pcall(function()
		return (getfenv(1) :: any)[fnName]
	end)
	if okL and type(localFn) == "function" then
		return localFn
	end

	local okR, renv = pcall(function()
		local gRen = (getfenv(0) :: any)["getrenv"]
		if type(gRen) == "function" then
			return gRen()
		end
		return nil
	end)
	if okR and type(renv) == "table" and type(renv[fnName]) == "function" then
		return renv[fnName]
	end

	if type(shared) == "table" and type((shared :: any)[fnName]) == "function" then
		return (shared :: any)[fnName]
	end

	if type(_G) == "table" and type((_G :: any)[fnName]) == "function" then
		return (_G :: any)[fnName]
	end

	return nil
end

local function ensureInternalFolder(): (boolean, string)
	local isfolderFn = resolveExecFn("isfolder")
	local makefolderFn = resolveExecFn("makefolder")
	if type(makefolderFn) ~= "function" then
		return false, "makefolder tidak tersedia di executor"
	end
	if type(isfolderFn) == "function" then
		local okEx, exists = pcall(isfolderFn, CONFIG.WorkspaceRoot)
		if okEx and exists then
			return true, CONFIG.WorkspaceRoot
		end
	end
	local okMk, errMk = pcall(makefolderFn, CONFIG.WorkspaceRoot)
	if not okMk then
		return false, "Gagal membuat folder " .. CONFIG.WorkspaceRoot .. ": " .. tostring(errMk)
	end
	return true, CONFIG.WorkspaceRoot
end

local function saveToInternalStorage(fileName: string, content: string): (boolean, string)
	local writefileFn = resolveExecFn("writefile")
	if type(writefileFn) ~= "function" then
		return false, "Executor tidak mengekspos writefile ke environment script."
	end

	ensureInternalFolder()
	local fullPath = CONFIG.WorkspaceRoot .. "/" .. fileName
	local okW, errW = pcall(writefileFn, fullPath, content)
	if not okW then
		return false, "Gagal menulis ke " .. fullPath .. " (" .. tostring(errW) .. ")"
	end

	local isfileFn = resolveExecFn("isfile")
	if type(isfileFn) == "function" then
		local okCheck, existsAfter = pcall(isfileFn, fullPath)
		if not okCheck or not existsAfter then
			return false, "File tidak terverifikasi ada di " .. fullPath
		end
	end

	return true, fullPath
end

local function readFromInternalStorage(fileName: string): (boolean, string)
	local readfileFn = resolveExecFn("readfile")
	if type(readfileFn) ~= "function" then
		return false, "Executor tidak mengekspos readfile."
	end

	local fullPath = CONFIG.WorkspaceRoot .. "/" .. fileName
	local isfileFn = resolveExecFn("isfile")
	if type(isfileFn) == "function" then
		local okEx, exists = pcall(isfileFn, fullPath)
		if not okEx or not exists then
			return false, "File tidak ditemukan di penyimpanan internal: " .. fullPath
		end
	end

	local okR, raw = pcall(readfileFn, fullPath)
	if not okR or type(raw) ~= "string" or raw == "" then
		return false, "Gagal membaca isi file: " .. fullPath
	end
	return true, raw
end

local function listInternalExportFiles(): {string}
	local result: {string} = {}
	local seen: {[string]: boolean} = {}

	local function pushIfJson(rawEntry: any)
		if type(rawEntry) ~= "string" then return end
		local base = string.match(rawEntry, "([^/\\]+)$") or rawEntry
		if string.match(string.lower(base), "%.json$") and not seen[base] then
			seen[base] = true
			table.insert(result, base)
		end
	end

	local listfilesFn = resolveExecFn("listfiles")
	if type(listfilesFn) == "function" then
		local okL, listRes = pcall(listfilesFn, CONFIG.WorkspaceRoot)
		if okL and type(listRes) == "table" then
			for _, item in ipairs(listRes) do
				pushIfJson(item)
			end
		end
	end

	if CONFIG.SelectedFileName ~= "" then
		pushIfJson(CONFIG.SelectedFileName)
	end

	table.sort(result)
	return result
end

refreshImportFileList = function()
	for _, child in ipairs(SavedFilesScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local files = listInternalExportFiles()
	if #files == 0 then
		local emptyLbl = Instance.new("TextLabel")
		emptyLbl.Size = UDim2.new(1, -8, 0, 44)
		emptyLbl.BackgroundColor3 = Color3.fromRGB(255, 251, 240)
		emptyLbl.Text = "Belum ada file .json di " .. CONFIG.WorkspaceRoot .. "/.\nCopy map di game asal dulu, lalu klik ↻ Refresh."
		emptyLbl.TextColor3 = Color3.fromRGB(115, 106, 86)
		emptyLbl.TextSize = 7
		emptyLbl.Font = Enum.Font.GothamMedium
		emptyLbl.TextWrapped = true
		emptyLbl.Parent = SavedFilesScroll
		Instance.new("UICorner", emptyLbl).CornerRadius = UDim.new(0, 6)
		return
	end

	if CONFIG.SelectedFileName == "" then
		CONFIG.SelectedFileName = files[1]
	end

	for idx, fName in ipairs(files) do
		local isSel = (fName == CONFIG.SelectedFileName)
		local fBtn = Instance.new("TextButton")
		fBtn.Size = UDim2.new(1, -4, 0, 28)
		fBtn.BackgroundColor3 = isSel and Color3.fromRGB(255, 245, 214) or Color3.fromRGB(255, 253, 248)
		fBtn.Text = (isSel and "▶ " or "  ") .. fName
		fBtn.TextColor3 = Color3.fromRGB(35, 32, 26)
		fBtn.TextSize = 7
		fBtn.Font = Enum.Font.Code
		fBtn.TextXAlignment = Enum.TextXAlignment.Left
		fBtn.TextTruncate = Enum.TextTruncate.AtEnd
		fBtn.LayoutOrder = idx
		fBtn.Parent = SavedFilesScroll
		Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 5)
		local st = Instance.new("UIStroke", fBtn)
		st.Color = isSel and Color3.fromRGB(245, 178, 36) or Color3.fromRGB(236, 216, 166)
		st.Thickness = 1

		fBtn.MouseButton1Click:Connect(function()
			CONFIG.SelectedFileName = fName
			SelectedFileBanner.Text = "File terpilih: " .. fName
			refreshImportFileList()
		end)
	end

	SelectedFileBanner.Text = "File terpilih: " .. tostring(CONFIG.SelectedFileName)
end

RefreshFilesBtn.MouseButton1Click:Connect(function()
	refreshImportFileList()
end)

local function decompileDeltaScript(scr: LuaSourceContainer): string?
	local decompileFn = resolveExecFn("decompile")
	if type(decompileFn) == "function" then
		local okD, resD = pcall(decompileFn, scr)
		if okD and type(resD) == "string" and resD ~= "" then
			return resD
		end
	end

	local getBytecodeFn = resolveExecFn("getscriptbytecode")
	if type(getBytecodeFn) == "function" then
		local okB, bc = pcall(getBytecodeFn, scr)
		if okB and type(bc) == "string" and bc ~= "" and type(decompileFn) == "function" then
			local okD2, resD2 = pcall(decompileFn, bc)
			if okD2 and type(resD2) == "string" and resD2 ~= "" then
				return resD2
			end
		end
	end

	local okSrc, directSrc = pcall(function() return (scr :: any).Source end)
	if okSrc and type(directSrc) == "string" and directSrc ~= "" then
		return directSrc
	end
	return nil
end

local PROP_WHITELIST: {string} = {
	"Anchored", "CanCollide", "CanTouch", "CanQuery", "Massless", "EnableFluidForces",
	"CollisionGroup", "CustomPhysicalProperties", "RootPriority", "CFrame", "Size",
	"Color", "BrickColor", "Material", "MaterialVariant", "Transparency", "Reflectance",
	"Shape", "TopSurface", "BottomSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface",
	"MeshId", "TextureID", "RenderFidelity", "CollisionFidelity", "DoubleSided", "UsePartColor",
	"MeshType", "Scale", "Offset", "VertexColor", "Texture", "Face", "Color3",
	"StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV", "ZIndex",
	"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap", "AlphaMode",
	"Enabled", "Brightness", "Range", "Angle", "Rate", "Lifetime", "Speed", "SpreadAngle",
	"Acceleration", "Drag", "LightEmission", "LightInfluence", "Orientation", "RotSpeed",
	"Rotation", "Squash", "LockedToPart", "Width0", "Width1", "CurveSize0", "CurveSize1",
	"Segments", "TextureLength", "TextureMode", "TextureSpeed", "MinLength", "MaxLength",
	"SoundId", "Volume", "PlaybackSpeed", "Looped", "RollOffMaxDistance", "RollOffMinDistance",
	"RollOffMode", "TimePosition", "Value", "Text", "Image", "ImageColor3", "ImageTransparency",
	"BackgroundColor3", "BackgroundTransparency", "StudsOffset", "AlwaysOnTop", "MaxDistance",
	"Adornee", "WorldPivot", "LevelOfDetail",
	"ToolTip", "Grip", "GripPos", "GripForward", "GripRight", "GripUp",
	"RequiresHandle", "CanBeDropped", "ManualActivationOnly",
}

local function serializePropertyValue(val: any): any
	local t = typeof(val)
	if t == "Vector3" then
		return { __type = "Vector3", x = val.X, y = val.Y, z = val.Z }
	elseif t == "Vector2" then
		return { __type = "Vector2", x = val.X, y = val.Y }
	elseif t == "CFrame" then
		return { __type = "CFrame", c = { val:GetComponents() } }
	elseif t == "Color3" then
		return { __type = "Color3", r = val.R, g = val.G, b = val.B }
	elseif t == "BrickColor" then
		return { __type = "BrickColor", name = val.Name }
	elseif t == "UDim2" then
		return { __type = "UDim2", xs = val.X.Scale, xo = val.X.Offset, ys = val.Y.Scale, yo = val.Y.Offset }
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
			return UDim2.new(tonumber(raw.xs) or 0, tonumber(raw.xo) or 0, tonumber(raw.ys) or 0, tonumber(raw.yo) or 0)
		elseif tp == "NumberRange" then
			return NumberRange.new(tonumber(raw.min) or 0, tonumber(raw.max) or 0)
		elseif tp == "NumberSequence" and type(raw.kps) == "table" then
			local seqKps: {NumberSequenceKeypoint} = {}
			for _, kp in ipairs(raw.kps) do
				if type(kp) == "table" then
					table.insert(seqKps, NumberSequenceKeypoint.new(tonumber(kp.t) or 0, tonumber(kp.v) or 0, tonumber(kp.e) or 0))
				end
			end
			if #seqKps >= 2 then return NumberSequence.new(seqKps) end
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
			if #colKps >= 2 then return ColorSequence.new(colKps) end
		elseif tp == "EnumItem" and type(raw.enumType) == "string" and type(raw.name) == "string" then
			local enumGroup = (Enum :: any)[raw.enumType]
			if enumGroup then return enumGroup[raw.name] end
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
	if isPlayerCharacterDescendant(inst) or inst == ScreenGui or inst == MusicGroup then
		return nil
	end

	local isScriptInst = inst:IsA("Script") or inst:IsA("LocalScript")
	if isScriptInst and not allowScripts then
		return nil
	end

	local props: {[string]: any} = {}
	for _, propName in ipairs(PROP_WHITELIST) do
		local okGet, val = pcall(function() return (inst :: any)[propName] end)
		if okGet and val ~= nil then
			local enc = serializePropertyValue(val)
			if enc ~= nil then props[propName] = enc end
		end
	end

	local decompiledCode: string? = nil
	if isScriptInst and allowScripts then
		decompiledCode = decompileDeltaScript(inst :: LuaSourceContainer)
	end

	local primaryPartName: string? = (inst:IsA("Model") and inst.PrimaryPart) and inst.PrimaryPart.Name or nil
	local attrs: {[string]: any} = {}
	local okAttr, rawAttrs = pcall(function() return inst:GetAttributes() end)
	if okAttr and type(rawAttrs) == "table" then
		for k, v in pairs(rawAttrs) do
			local encAttr = serializePropertyValue(v)
			if encAttr ~= nil then attrs[tostring(k)] = encAttr end
		end
	end

	countRef.n += 1
	local childrenSerialized: {any} = {}
	for _, ch in ipairs(inst:GetChildren()) do
		local childNode = serializeInstanceTree(ch, countRef, allowScripts)
		if childNode ~= nil then table.insert(childrenSerialized, childNode) end
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
			pcall(function() (inst :: any).Size = sz end)
		end
	end

	for propName, rawVal in pairs(propsTable) do
		if propName ~= "Size" and propName ~= "CastShadow" and propName ~= "Shadows" then
			local decoded = deserializePropertyValue(rawVal)
			if decoded ~= nil then
				if propName == "CFrame" and typeof(decoded) == "CFrame" and CONFIG.MapPosMode == "InFrontOfChar" and refOrigin and frontAnchor and not isStarterPackTarget then
					decoded = frontAnchor * refOrigin:ToObjectSpace(decoded)
				end
				pcall(function() (inst :: any)[propName] = decoded end)
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
		pcall(function() inst.Shadows = false end)
	end
end

local function injectDecompiledSource(inst: Instance, sourceCode: any)
	if type(sourceCode) ~= "string" or sourceCode == "" then return end
	local okSet = pcall(function() (inst :: any).Source = sourceCode end)
	if not okSet then
		pcall(function() inst:SetAttribute("DecompiledSource", sourceCode) end)
	end
end

local function buildNodesIntoParent(nodes: any, parentTarget: Instance, importedCounter: {n: number}, refOrigin: CFrame?, frontAnchor: CFrame?, isStarterPackTarget: boolean)
	if type(nodes) ~= "table" then return end
	for i, node in ipairs(nodes) do
		if type(node) == "table" and type(node.ClassName) == "string" then
			local okNew, newInst = pcall(Instance.new, node.ClassName)
			if okNew and newInst then
				if type(node.Name) == "string" then newInst.Name = node.Name end
				if type(node.Attributes) == "table" then
					for aName, aRaw in pairs(node.Attributes) do
						local aVal = deserializePropertyValue(aRaw)
						if aVal ~= nil then pcall(function() newInst:SetAttribute(aName, aVal) end) end
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
					if foundPP and foundPP:IsA("BasePart") then newInst.PrimaryPart = foundPP end
				end
				if importedCounter.n % 90 == 0 then task.wait() end
			end
		end
		if i % 40 == 0 then task.wait() end
	end
end

local function performCopyMap()
	if CONFIG.MapBusy then return end
	CONFIG.MapBusy = true
	setProgress(0.08)

	local autoFile = buildAutoGameFileName()
	CONFIG.SelectedFileName = autoFile
	AutoFilePreviewLbl.Text = "File: " .. CONFIG.WorkspaceRoot .. "/" .. autoFile
	StatusHeadlineLbl.Text = "Menyimpan ke file internal..."
	appendMapLog("[Copy] File internal: " .. CONFIG.WorkspaceRoot .. "/" .. autoFile)

	task.spawn(function()
		local dumpPayload: {[string]: any} = {
			_meta = {
				exportedBy = LocalPlayer.Name,
				gameName = getCurrentGameTitle(),
				placeId = game.PlaceId,
				universeId = game.GameId,
				crossGameCompatible = true,
				skipMapScripts = true,
				starterPackDecompile = true,
				noShadow = true,
				exportedAt = os.date("%Y-%m-%d %H:%M:%S"),
			},
		}

		local totalCount = { n = 0 }
		for idx, sName in ipairs(SERVICE_LIST) do
			setProgress(0.1 + (idx / #SERVICE_LIST) * 0.65)
			if CONFIG.SelectedServices[sName] then
				local okS, srv = pcall(game.GetService, game, sName)
				if okS and srv then
					local allowScriptsHere = (sName == "StarterPack")
					local listNodes: {any} = {}
					for _, child in ipairs(srv:GetChildren()) do
						local node = serializeInstanceTree(child, totalCount, allowScriptsHere)
						if node ~= nil then table.insert(listNodes, node) end
					end
					dumpPayload[sName] = listNodes
					appendMapLog(string.format("[Scan] %s -> %d root", sName, #listNodes))
					task.wait()
				end
			end
		end

		setProgress(0.85)
		local okEncode, jsonStr = pcall(HttpService.JSONEncode, HttpService, dumpPayload)
		if not okEncode or type(jsonStr) ~= "string" then
			CONFIG.MapBusy = false
			setProgress(0)
			StatusHeadlineLbl.Text = "Gagal encode JSON"
			appendMapLog("[Error] Gagal serialize snapshot.")
			return
		end

		local okSave, savedPathOrErr = saveToInternalStorage(autoFile, jsonStr)
		CONFIG.MapBusy = false
		setProgress(okSave and 1 or 0)

		if okSave then
			StatusHeadlineLbl.Text = string.format("Tersimpan: %s (%d inst)", autoFile, totalCount.n)
			appendMapLog(string.format("[Saved] %d inst -> %s", totalCount.n, savedPathOrErr))
			refreshImportFileList()
		else
			StatusHeadlineLbl.Text = "Gagal simpan file internal"
			appendMapLog("[Error] " .. savedPathOrErr)
		end
	end)
end

local function performImportMap()
	if CONFIG.MapBusy then return end
	if CONFIG.SelectedFileName == "" then
		refreshImportFileList()
	end
	if CONFIG.SelectedFileName == "" then
		ImportInfoLbl.Text = "[Error] Belum ada file yang dipilih dari daftar."
		return
	end

	CONFIG.MapBusy = true
	local targetFile = CONFIG.SelectedFileName
	ImportInfoLbl.Text = "Membaca file internal: " .. targetFile .. "..."

	task.spawn(function()
		local okRead, rawData = readFromInternalStorage(targetFile)
		if not okRead then
			CONFIG.MapBusy = false
			ImportInfoLbl.Text = "[Error] " .. rawData
			return
		end

		local okTarget, targetService = pcall(game.GetService, game, selectedImportTarget)
		if not okTarget or not targetService then
			CONFIG.MapBusy = false
			ImportInfoLbl.Text = "[Error] Target service tidak valid."
			return
		end

		local isStarterPackTarget = (selectedImportTarget == "StarterPack")
		local nodesToBuild: {any} = {}
		local refOrigin: CFrame? = nil
		local sourceGame = "Game Asal"

		local okDecode, decoded = pcall(HttpService.JSONDecode, HttpService, rawData)
		if okDecode and type(decoded) == "table" then
			if type(decoded._meta) == "table" then
				sourceGame = tostring(decoded._meta.gameName or "Game Asal") .. " [" .. tostring(decoded._meta.placeId or "?") .. "]"
			end
			local svcNodes = decoded[selectedImportTarget] or decoded["Workspace"] or decoded
			if type(svcNodes) == "table" then nodesToBuild = svcNodes end
			for _, n in ipairs(nodesToBuild) do
				if type(n) == "table" and type(n.Properties) == "table" and type(n.Properties.CFrame) == "table" then
					local cfVal = deserializePropertyValue(n.Properties.CFrame)
					if typeof(cfVal) == "CFrame" then
						refOrigin = cfVal
						break
					end
				end
			end
		else
			CONFIG.MapBusy = false
			ImportInfoLbl.Text = "[Error] File bukan snapshot JSON valid."
			return
		end

		local frontAnchor = getFrontAnchorCFrame()
		local importedCounter = { n = 0 }
		buildNodesIntoParent(nodesToBuild, targetService, importedCounter, refOrigin, frontAnchor, isStarterPackTarget)

		CONFIG.MapBusy = false
		ImportInfoLbl.Text = string.format(
			"[Success] %d instance dari %s di-import ke %s (%s).",
			importedCounter.n,
			sourceGame,
			selectedImportTarget,
			isStarterPackTarget and "StarterPack + Decompile" or "NoShadow Mode"
		)
	end)
end

PrimaryCopyBtn.MouseButton1Click:Connect(function()
	performCopyMap()
end)

PrimaryImportBtn.MouseButton1Click:Connect(function()
	performImportMap()
end)

-- ==========================================
-- APPLY TEMA & FONT
-- ==========================================
applyThemeAndFont = function()
	local theme = GUI_THEMES[CONFIG.ThemeIndex]
	local fp = FONT_PRESETS[CONFIG.FontIndex]

	FloatStroke.Color = theme.accent
	MainStroke.Color = theme.stroke
	LeftStroke.Color = theme.stroke
	RightStroke.Color = theme.stroke
	ImpLeftStroke.Color = theme.stroke
	ImpRightStroke.Color = theme.stroke
	MusLeftStroke.Color = theme.stroke
	MusRightStroke.Color = theme.stroke
	SetStroke.Color = theme.stroke

	MainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, theme.gradStart),
		ColorSequenceKeypoint.new(1, theme.gradEnd),
	})

	PrimaryCopyBtn.BackgroundColor3 = theme.accent
	PrimaryImportBtn.BackgroundColor3 = theme.accent
	PlayBtn.BackgroundColor3 = theme.accent
	ProgFill.BackgroundColor3 = theme.accent

	for k, btn in pairs(tabButtons) do
		local active = (k == CONFIG.ActiveTab)
		btn.BackgroundColor3 = active and theme.accent or Color3.fromRGB(255, 255, 255)
		btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(45, 42, 35)
		btn.Font = active and fp.boldFont or fp.font
	end

	BrandTitleLabel.Font = fp.boldFont
	ServiceHeaderLbl.Font = fp.boldFont
	RightHeaderLbl.Font = fp.boldFont
	StatusHeadlineLbl.Font = fp.boldFont
	PrimaryCopyBtn.Font = fp.boldFont
	PrimaryImportBtn.Font = fp.boldFont
	TrackTitleLbl.Font = fp.boldFont
	SetTitleLbl.Font = fp.boldFont
end

updateServiceCardVisuals()
refreshImportFileList()
switchTab("CopyMap")
applyThemeAndFont()
