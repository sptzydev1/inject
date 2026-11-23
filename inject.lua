-- SCRIPT PREMIUM BY IKYY
-- AUTO ANIMATION ID SCANNER + COPY ID (DELTA EXECUTOR)

--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GUI_NAME = "IkyyAnimScanner_GUI"
local OLD_GUI = PlayerGui:FindFirstChild(GUI_NAME)
if OLD_GUI then
	OLD_GUI:Destroy()
end

-- ==========================================
-- KONFIGURASI & STATE
-- ==========================================
local CONFIG = {
	WorkspaceRoot = "IkyyStudioLite",
	IsMinimized = false,
	ActiveTab = "Scanner",
	AutoScan = true,
	TargetFilter = "ALL", -- "ALL" atau nama player spesifik
}

type AnimEntry = {
	key: string,
	animId: string,
	rawUri: string,
	animName: string,
	playerName: string,
	displayName: string,
	userId: number,
	count: number,
	lastSeen: string,
	orderScore: number,
}

local SCANNED_LIST: {AnimEntry} = {}
local SCANNED_MAP: {[string]: AnimEntry} = {}
local CARD_FRAMES: {[string]: Frame} = {}
local CONSOLE_LINES: {string} = {}
local HOOKED_ANIMATORS: {[Instance]: boolean} = {}
local PLAYER_CONNECTIONS: {[Player]: {RBXScriptConnection}} = {}

local latestOrderCounter = 0
local refreshScannerViewFn: (() -> ())? = nil
local rebuildFilterDropdownFn: (() -> ())? = nil
local appendConsoleLineFn: ((level: string, formattedLine: string) -> ())? = nil

local WINDOW_SIZE = UDim2.fromOffset(540, 320)
local WINDOW_POS = UDim2.new(0.5, -270, 0.5, -160)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS

local function trim(s: string?): string
	if type(s) ~= "string" then return "" end
	return s:match("^%s*(.-)%s*$") or ""
end

local function notify(title: string, text: string)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 3,
		})
	end)
end

-- ==========================================
-- DELTA EXECUTOR ENVIRONMENT BRIDGE
-- ==========================================
local function getEnvTable(): {[string]: any}
	local env: {[string]: any} = {}
	pcall(function()
		if type(getgenv) == "function" then
			local g = getgenv()
			if type(g) == "table" then
				for k, v in pairs(g) do
					env[k] = v
				end
			end
		end
	end)
	pcall(function()
		local f = getfenv(0)
		if type(f) == "table" then
			for k, v in pairs(f) do
				if env[k] == nil then
					env[k] = v
				end
			end
		end
	end)
	return env
end

local ENV = getEnvTable()

local function setClipboardText(text: string): boolean
	local clipFns = { ENV.setclipboard, ENV.toclipboard, ENV.set_clipboard }
	for _, fn in ipairs(clipFns) do
		if type(fn) == "function" then
			local ok = pcall(fn, text)
			if ok then return true end
		end
	end
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Animation ID",
			Text = text,
			Duration = 4,
		})
	end)
	return false
end

local fnWriteFile = type(ENV.writefile) == "function" and ENV.writefile or nil
local fnMakeFolder = type(ENV.makefolder) == "function" and ENV.makefolder or nil

local function exportAnimIdsToFile(): (boolean, string)
	if #SCANNED_LIST == 0 then
		return false, "Belum ada ID animasi untuk diexport."
	end
	local lines: {string} = {}
	for _, item in ipairs(SCANNED_LIST) do
		if CONFIG.TargetFilter == "ALL" or item.playerName == CONFIG.TargetFilter then
			table.insert(lines, string.format("%s | %s (%s) | x%d | %s", item.animId, item.playerName, item.animName, item.count, item.rawUri))
		end
	end
	if #lines == 0 then
		return false, "Tidak ada data sesuai filter aktif."
	end
	local content = table.concat(lines, "\n")
	if fnWriteFile then
		pcall(function()
			if fnMakeFolder then
				fnMakeFolder(CONFIG.WorkspaceRoot)
				fnMakeFolder(CONFIG.WorkspaceRoot .. "/Animations")
			end
		end)
		local path = CONFIG.WorkspaceRoot .. "/Animations/anim_scan_" .. tostring(os.time()) .. ".txt"
		local ok = pcall(fnWriteFile, path, content)
		if ok then
			return true, "Tersimpan ke " .. path
		end
	end
	local copied = setClipboardText(content)
	return copied, copied and "Disalin semua ID ke clipboard" or "Gagal export file"
end

-- ==========================================
-- CONSOLE LOGGER
-- ==========================================
local function pushConsole(level: string, message: string)
	local stamp = os.date("%H:%M:%S")
	local line = string.format("[%s] [%s] %s", tostring(stamp), level, message)
	table.insert(CONSOLE_LINES, line)
	if #CONSOLE_LINES > 200 then
		table.remove(CONSOLE_LINES, 1)
	end
	if appendConsoleLineFn then
		appendConsoleLineFn(level, line)
	end
end

-- ==========================================
-- LOGIKA AUTO SCAN ANIMASI PLAYER
-- ==========================================
local function extractNumericAnimId(rawId: string): string?
	local s = trim(rawId)
	if s == "" then return nil end
	local queryId = s:match("[?&]id=(%d+)")
	if queryId then return queryId end
	local assetId = s:match("rbxassetid://(%d+)")
	if assetId then return assetId end
	local anyNum = s:match("(%d+)")
	return anyNum
end

local function recordAnimationPlay(plr: Player, track: AnimationTrack)
	if not CONFIG.AutoScan then return end
	local anim: Animation? = nil
	pcall(function()
		anim = track.Animation
	end)
	if not anim then return end

	local rawUri = ""
	local animTitle = "Animation"
	pcall(function()
		rawUri = tostring(anim.AnimationId or "")
		if anim.Name ~= "" and anim.Name ~= "Animation" then
			animTitle = anim.Name
		end
	end)

	local numericId = extractNumericAnimId(rawUri)
	if not numericId or numericId == "" then return end

	latestOrderCounter += 1
	local stamp = tostring(os.date("%H:%M:%S"))
	local key = tostring(plr.UserId) .. "_" .. numericId
	local existing = SCANNED_MAP[key]

	if existing then
		existing.count += 1
		existing.lastSeen = stamp
		existing.orderScore = latestOrderCounter
		if animTitle ~= "Animation" then
			existing.animName = animTitle
		end
	else
		local entry: AnimEntry = {
			key = key,
			animId = numericId,
			rawUri = rawUri ~= "" and rawUri or ("rbxassetid://" .. numericId),
			animName = animTitle,
			playerName = plr.Name,
			displayName = plr.DisplayName,
			userId = plr.UserId,
			count = 1,
			lastSeen = stamp,
			orderScore = latestOrderCounter,
		}
		SCANNED_MAP[key] = entry
		table.insert(SCANNED_LIST, entry)
		pushConsole("SCAN", string.format("%s memutar ID %s (%s)", plr.Name, numericId, animTitle))
	end

	table.sort(SCANNED_LIST, function(a: AnimEntry, b: AnimEntry): boolean
		return a.orderScore > b.orderScore
	end)

	if refreshScannerViewFn then
		refreshScannerViewFn()
	end
end

local function bindAnimator(plr: Player, animator: Animator)
	if HOOKED_ANIMATORS[animator] then return end
	HOOKED_ANIMATORS[animator] = true

	-- Tangkap animation track yang sedang berjalan saat animator terdeteksi
	pcall(function()
		for _, playingTrack in ipairs(animator:GetPlayingAnimationTracks()) do
			task.defer(recordAnimationPlay, plr, playingTrack)
		end
	end)

	local conn = animator.AnimationPlayed:Connect(function(track: AnimationTrack)
		recordAnimationPlay(plr, track)
	end)

	if not PLAYER_CONNECTIONS[plr] then
		PLAYER_CONNECTIONS[plr] = {}
	end
	table.insert(PLAYER_CONNECTIONS[plr], conn)
end

local function scanCharacterForAnimators(plr: Player, char: Model)
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Animator") then
			bindAnimator(plr, desc)
		end
	end

	local descConn = char.DescendantAdded:Connect(function(desc: Instance)
		if desc:IsA("Animator") then
			bindAnimator(plr, desc)
		elseif desc:IsA("Humanoid") then
			local anim = desc:FindFirstChildOfClass("Animator")
			if anim then
				bindAnimator(plr, anim)
			end
		end
	end)

	if not PLAYER_CONNECTIONS[plr] then
		PLAYER_CONNECTIONS[plr] = {}
	end
	table.insert(PLAYER_CONNECTIONS[plr], descConn)
end

local function disconnectPlayer(plr: Player)
	local list = PLAYER_CONNECTIONS[plr]
	if list then
		for _, c in ipairs(list) do
			pcall(function()
				c:Disconnect()
			end)
		end
		PLAYER_CONNECTIONS[plr] = nil
	end
	if CONFIG.TargetFilter == plr.Name then
		CONFIG.TargetFilter = "ALL"
	end
end

local function hookPlayer(plr: Player)
	disconnectPlayer(plr)
	if plr.Character then
		scanCharacterForAnimators(plr, plr.Character)
	end
	local charConn = plr.CharacterAdded:Connect(function(char: Model)
		scanCharacterForAnimators(plr, char)
	end)
	PLAYER_CONNECTIONS[plr] = PLAYER_CONNECTIONS[plr] or {}
	table.insert(PLAYER_CONNECTIONS[plr], charConn)

	if rebuildFilterDropdownFn then
		rebuildFilterDropdownFn()
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	hookPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr: Player)
	hookPlayer(plr)
	pushConsole("INFO", "Player join: " .. plr.Name .. " (auto-hook aktif)")
end)

Players.PlayerRemoving:Connect(function(plr: Player)
	disconnectPlayer(plr)
	if rebuildFilterDropdownFn then
		rebuildFilterDropdownFn()
	end
	if refreshScannerViewFn then
		refreshScannerViewFn()
	end
end)

-- ==========================================
-- UI UTAMA
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- 1. IKON LINGKARAN FLOATING (42x42, DRAGGABLE)
local FloatingBtn = Instance.new("ImageButton")
FloatingBtn.Name = "FloatingScannerToggle"
FloatingBtn.Size = ICON_SIZE
FloatingBtn.Position = ICON_DEFAULT_POS
FloatingBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
FloatingBtn.BorderSizePixel = 0
FloatingBtn.Visible = false
FloatingBtn.AutoButtonColor = false
FloatingBtn.ZIndex = 50
FloatingBtn.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150"
FloatingBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingBtn)
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
LogoIcon.Text = "🎬"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 14
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 340, 0, 11)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 5)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "SCRIPT PREMIUM BY IKYY • AUTO SCAN ANIMATION ID & COPY"
SubTitleLabel.TextColor3 = Color3.fromRGB(130, 126, 155)
SubTitleLabel.TextSize = 8
SubTitleLabel.Font = Enum.Font.GothamBold
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 260, 0, 16)
TitleLabel.Position = UDim2.new(0, 48, 0, 15)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Animation ID Scanner"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(0, 280, 0, 11)
MetaLabel.Position = UDim2.new(0, 48, 0, 31)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "REALTIME PLAYER TRACKER • @" .. LocalPlayer.Name
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
				FloatingBtn.Position = currentIconPos
				FloatingBtn.Size = ICON_SIZE
				FloatingBtn.Visible = true
			end
		end)
	else
		FloatingBtn.Visible = false
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
		local absX = (FloatingBtn.Position.X.Scale * viewport.X) + FloatingBtn.Position.X.Offset
		local absY = (FloatingBtn.Position.Y.Scale * viewport.Y) + FloatingBtn.Position.Y.Offset
		return UDim2.fromOffset(absX, absY)
	end

	FloatingBtn.InputBegan:Connect(function(input: InputObject)
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
			FloatingBtn.Position = nextPos
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

local NavListFrame = Instance.new("Frame")
NavListFrame.Size = UDim2.new(1, -10, 1, -10)
NavListFrame.Position = UDim2.new(0, 5, 0, 5)
NavListFrame.BackgroundTransparency = 1
NavListFrame.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavListFrame

local tabPages: {[string]: Frame} = {}
local tabButtons: {[string]: TextButton} = {}

local function createNavButton(name: string, label: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = "Nav_" .. name
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
	btn.Text = "  " .. label
	btn.TextColor3 = Color3.fromRGB(185, 182, 210)
	btn.TextSize = 9
	btn.Font = Enum.Font.GothamBold
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Parent = NavListFrame
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
	for name, btn in pairs(tabButtons) do
		local active = (name == tabName)
		btn.BackgroundColor3 = active and Color3.fromRGB(45, 42, 68) or Color3.fromRGB(28, 27, 42)
		btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 182, 210)
	end
end

-- ==========================================
-- HALAMAN 1: AUTO SCAN ANIMATION ID
-- ==========================================
local ScannerPage = Instance.new("Frame")
ScannerPage.Size = UDim2.fromScale(1, 1)
ScannerPage.BackgroundTransparency = 1
ScannerPage.Visible = true
ScannerPage.Parent = ContentArea
tabPages["Scanner"] = ScannerPage

local ScannerHeaderLabel = Instance.new("TextLabel")
ScannerHeaderLabel.Size = UDim2.new(1, -170, 0, 16)
ScannerHeaderLabel.Position = UDim2.new(0, 12, 0, 5)
ScannerHeaderLabel.BackgroundTransparency = 1
ScannerHeaderLabel.Text = "Auto Scan Animation ID"
ScannerHeaderLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
ScannerHeaderLabel.TextSize = 12
ScannerHeaderLabel.Font = Enum.Font.GothamBold
ScannerHeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
ScannerHeaderLabel.Parent = ScannerPage

local ToggleScanBtn = Instance.new("TextButton")
ToggleScanBtn.Size = UDim2.fromOffset(86, 20)
ToggleScanBtn.Position = UDim2.new(1, -162, 0, 4)
ToggleScanBtn.BackgroundColor3 = Color3.fromRGB(26, 98, 58)
ToggleScanBtn.Text = "● SCAN: ON"
ToggleScanBtn.TextColor3 = Color3.fromRGB(150, 255, 195)
ToggleScanBtn.TextSize = 8
ToggleScanBtn.Font = Enum.Font.GothamBold
ToggleScanBtn.Parent = ScannerPage
Instance.new("UICorner", ToggleScanBtn).CornerRadius = UDim.new(0, 6)

local ClearAnimBtn = Instance.new("TextButton")
ClearAnimBtn.Size = UDim2.fromOffset(64, 20)
ClearAnimBtn.Position = UDim2.new(1, -72, 0, 4)
ClearAnimBtn.BackgroundColor3 = Color3.fromRGB(58, 26, 36)
ClearAnimBtn.Text = "🗑 Clear"
ClearAnimBtn.TextColor3 = Color3.fromRGB(255, 185, 195)
ClearAnimBtn.TextSize = 8
ClearAnimBtn.Font = Enum.Font.GothamBold
ClearAnimBtn.Parent = ScannerPage
Instance.new("UICorner", ClearAnimBtn).CornerRadius = UDim.new(0, 6)

-- Bar Filter Player + Search ID
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(0.54, -14, 0, 22)
SearchBox.Position = UDim2.new(0, 12, 0, 28)
SearchBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
SearchBox.Text = ""
SearchBox.PlaceholderText = "Cari ID / Nama Animasi / Player..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
SearchBox.TextColor3 = Color3.fromRGB(235, 235, 250)
SearchBox.TextSize = 9
SearchBox.Font = Enum.Font.Gotham
SearchBox.ClearTextOnFocus = false
SearchBox.Parent = ScannerPage
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)

local FilterPlayerBtn = Instance.new("TextButton")
FilterPlayerBtn.Size = UDim2.new(0.46, -12, 0, 22)
FilterPlayerBtn.Position = UDim2.new(0.54, 0, 0, 28)
FilterPlayerBtn.BackgroundColor3 = Color3.fromRGB(30, 28, 46)
FilterPlayerBtn.Text = "👤 Player: ALL"
FilterPlayerBtn.TextColor3 = Color3.fromRGB(215, 212, 245)
FilterPlayerBtn.TextSize = 9
FilterPlayerBtn.Font = Enum.Font.GothamBold
FilterPlayerBtn.TextTruncate = Enum.TextTruncate.AtEnd
FilterPlayerBtn.Parent = ScannerPage
Instance.new("UICorner", FilterPlayerBtn).CornerRadius = UDim.new(0, 6)
local FilterStroke = Instance.new("UIStroke", FilterPlayerBtn)
FilterStroke.Color = Color3.fromRGB(78, 72, 120)
FilterStroke.Thickness = 1

local ScanStatsLabel = Instance.new("TextLabel")
ScanStatsLabel.Size = UDim2.new(1, -24, 0, 14)
ScanStatsLabel.Position = UDim2.new(0, 12, 0, 53)
ScanStatsLabel.BackgroundTransparency = 1
ScanStatsLabel.Text = "Menunggu player memutar animasi..."
ScanStatsLabel.TextColor3 = Color3.fromRGB(165, 162, 192)
ScanStatsLabel.TextSize = 8
ScanStatsLabel.Font = Enum.Font.GothamMedium
ScanStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
ScanStatsLabel.Parent = ScannerPage

local AnimScroll = Instance.new("ScrollingFrame")
AnimScroll.Name = "ScannedAnimationsList"
AnimScroll.Size = UDim2.new(1, -24, 1, -75)
AnimScroll.Position = UDim2.new(0, 12, 0, 68)
AnimScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
AnimScroll.BorderSizePixel = 0
AnimScroll.ScrollBarThickness = 3
AnimScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
AnimScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
AnimScroll.Parent = ScannerPage
Instance.new("UICorner", AnimScroll).CornerRadius = UDim.new(0, 8)
local AnimScrollStroke = Instance.new("UIStroke", AnimScroll)
AnimScrollStroke.Color = Color3.fromRGB(52, 48, 82)
AnimScrollStroke.Thickness = 1

local AnimListLayout = Instance.new("UIListLayout")
AnimListLayout.Padding = UDim.new(0, 5)
AnimListLayout.SortOrder = Enum.SortOrder.LayoutOrder
AnimListLayout.Parent = AnimScroll

local AnimListPad = Instance.new("UIPadding")
AnimListPad.PaddingTop = UDim.new(0, 6)
AnimListPad.PaddingBottom = UDim.new(0, 6)
AnimListPad.PaddingLeft = UDim.new(0, 6)
AnimListPad.PaddingRight = UDim.new(0, 6)
AnimListPad.Parent = AnimScroll

local EmptyAnimHint = Instance.new("TextLabel")
EmptyAnimHint.Size = UDim2.new(1, 0, 0, 44)
EmptyAnimHint.BackgroundTransparency = 1
EmptyAnimHint.Text = "Saat ada player yang memutar animasi,\nID animasi akan otomatis terdeteksi & siap dicopy."
EmptyAnimHint.TextColor3 = Color3.fromRGB(105, 102, 130)
EmptyAnimHint.TextSize = 9
EmptyAnimHint.Font = Enum.Font.Gotham
EmptyAnimHint.Parent = AnimScroll

local function createAnimCard(entry: AnimEntry, layoutOrder: number): Frame
	local card = Instance.new("Frame")
	card.Name = "AnimCard_" .. entry.key
	card.Size = UDim2.new(1, -2, 0, 52)
	card.BackgroundColor3 = Color3.fromRGB(21, 20, 33)
	card.BorderSizePixel = 0
	card.LayoutOrder = layoutOrder
	card.Parent = AnimScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
	local stroke = Instance.new("UIStroke", card)
	stroke.Color = Color3.fromRGB(64, 58, 104)
	stroke.Thickness = 1

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Size = UDim2.fromOffset(38, 38)
	avatarImg.Position = UDim2.new(0, 7, 0.5, -19)
	avatarImg.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
	avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(entry.userId) .. "&w=150&h=150"
	avatarImg.ScaleType = Enum.ScaleType.Crop
	avatarImg.Parent = card
	Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

	local idTitle = Instance.new("TextLabel")
	idTitle.Size = UDim2.new(1, -126, 0, 16)
	idTitle.Position = UDim2.new(0, 52, 0, 5)
	idTitle.BackgroundTransparency = 1
	idTitle.Text = "ID: " .. entry.animId .. "  •  " .. entry.animName
	idTitle.TextColor3 = Color3.fromRGB(248, 248, 255)
	idTitle.TextSize = 10
	idTitle.Font = Enum.Font.GothamBold
	idTitle.TextXAlignment = Enum.TextXAlignment.Left
	idTitle.TextTruncate = Enum.TextTruncate.AtEnd
	idTitle.Parent = card

	local subInfo = Instance.new("TextLabel")
	subInfo.Size = UDim2.new(1, -126, 0, 14)
	subInfo.Position = UDim2.new(0, 52, 0, 21)
	subInfo.BackgroundTransparency = 1
	subInfo.Text = string.format("Player: %s • Diputar %dx • %s", entry.playerName, entry.count, entry.lastSeen)
	subInfo.TextColor3 = Color3.fromRGB(155, 152, 185)
	subInfo.TextSize = 8
	subInfo.Font = Enum.Font.Code
	subInfo.TextXAlignment = Enum.TextXAlignment.Left
	subInfo.TextTruncate = Enum.TextTruncate.AtEnd
	subInfo.Parent = card

	local uriInfo = Instance.new("TextLabel")
	uriInfo.Size = UDim2.new(1, -126, 0, 12)
	uriInfo.Position = UDim2.new(0, 52, 0, 35)
	uriInfo.BackgroundTransparency = 1
	uriInfo.Text = entry.rawUri
	uriInfo.TextColor3 = Color3.fromRGB(125, 185, 255)
	uriInfo.TextSize = 8
	uriInfo.Font = Enum.Font.Code
	uriInfo.TextXAlignment = Enum.TextXAlignment.Left
	uriInfo.TextTruncate = Enum.TextTruncate.AtEnd
	uriInfo.Parent = card

	local copyIdBtn = Instance.new("TextButton")
	copyIdBtn.Size = UDim2.fromOffset(62, 20)
	copyIdBtn.Position = UDim2.new(1, -70, 0, 7)
	copyIdBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
	copyIdBtn.Text = "📋 Copy ID"
	copyIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	copyIdBtn.TextSize = 8
	copyIdBtn.Font = Enum.Font.GothamBold
	copyIdBtn.Parent = card
	Instance.new("UICorner", copyIdBtn).CornerRadius = UDim.new(0, 5)

	copyIdBtn.MouseButton1Click:Connect(function()
		local okCopy = setClipboardText(entry.animId)
		pushConsole("INFO", string.format("Anim ID %s (%s) %s", entry.animId, entry.playerName, okCopy and "disalin" or "ditampilkan"))
		notify("Copy Animation ID", (okCopy and "Disalin: " or "ID: ") .. entry.animId)
		copyIdBtn.Text = "✓ Copied"
		copyIdBtn.BackgroundColor3 = Color3.fromRGB(34, 165, 92)
		task.delay(1.1, function()
			if copyIdBtn and copyIdBtn.Parent then
				copyIdBtn.Text = "📋 Copy ID"
				copyIdBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
			end
		end)
	end)

	local copyUriBtn = Instance.new("TextButton")
	copyUriBtn.Size = UDim2.fromOffset(62, 16)
	copyUriBtn.Position = UDim2.new(1, -70, 0, 30)
	copyUriBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 52)
	copyUriBtn.Text = "Copy URI"
	copyUriBtn.TextColor3 = Color3.fromRGB(205, 202, 235)
	copyUriBtn.TextSize = 7
	copyUriBtn.Font = Enum.Font.GothamBold
	copyUriBtn.Parent = card
	Instance.new("UICorner", copyUriBtn).CornerRadius = UDim.new(0, 5)

	copyUriBtn.MouseButton1Click:Connect(function()
		local okCopy = setClipboardText(entry.rawUri)
		notify("Copy URI", (okCopy and "Disalin: " or "URI: ") .. entry.rawUri)
		copyUriBtn.Text = "✓ URI"
		task.delay(1.1, function()
			if copyUriBtn and copyUriBtn.Parent then
				copyUriBtn.Text = "Copy URI"
			end
		end)
	end)

	return card
end

refreshScannerViewFn = function()
	local query = trim(SearchBox.Text):lower()
	local visibleCount = 0

	for _, child in ipairs(AnimScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	table.clear(CARD_FRAMES)

	local orderIdx = 0
	for _, entry in ipairs(SCANNED_LIST) do
		local matchesPlayer = (CONFIG.TargetFilter == "ALL") or (entry.playerName == CONFIG.TargetFilter)
		local matchesSearch = (query == "")
			or entry.animId:lower():find(query, 1, true) ~= nil
			or entry.animName:lower():find(query, 1, true) ~= nil
			or entry.playerName:lower():find(query, 1, true) ~= nil

		if matchesPlayer and matchesSearch then
			orderIdx += 1
			visibleCount += 1
			local f = createAnimCard(entry, orderIdx)
			CARD_FRAMES[entry.key] = f
		end
	end

	EmptyAnimHint.Visible = (visibleCount == 0)
	ScanStatsLabel.Text = string.format(
		"Terdeteksi: %d ID unik (Tampil: %d) • Filter: %s",
		#SCANNED_LIST,
		visibleCount,
		CONFIG.TargetFilter
	)
end

-- Cycle filter player: ALL -> Player 1 -> Player 2 ... -> ALL
local function getPlayerCycleList(): {string}
	local list = { "ALL" }
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(list, plr.Name)
	end
	return list
end

rebuildFilterDropdownFn = function()
	local list = getPlayerCycleList()
	local found = false
	for _, name in ipairs(list) do
		if name == CONFIG.TargetFilter then
			found = true
			break
		end
	end
	if not found then
		CONFIG.TargetFilter = "ALL"
	end
	FilterPlayerBtn.Text = "👤 Player: " .. CONFIG.TargetFilter
end

FilterPlayerBtn.MouseButton1Click:Connect(function()
	local list = getPlayerCycleList()
	local currentIdx = 1
	for i, name in ipairs(list) do
		if name == CONFIG.TargetFilter then
			currentIdx = i
			break
		end
	end
	local nextIdx = (currentIdx % #list) + 1
	CONFIG.TargetFilter = list[nextIdx]
	FilterPlayerBtn.Text = "👤 Player: " .. CONFIG.TargetFilter
	if refreshScannerViewFn then
		refreshScannerViewFn()
	end
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if refreshScannerViewFn then
		refreshScannerViewFn()
	end
end)

ToggleScanBtn.MouseButton1Click:Connect(function()
	CONFIG.AutoScan = not CONFIG.AutoScan
	if CONFIG.AutoScan then
		ToggleScanBtn.BackgroundColor3 = Color3.fromRGB(26, 98, 58)
		ToggleScanBtn.Text = "● SCAN: ON"
		ToggleScanBtn.TextColor3 = Color3.fromRGB(150, 255, 195)
		pushConsole("OK", "Auto Scan Animation ID diaktifkan.")
	else
		ToggleScanBtn.BackgroundColor3 = Color3.fromRGB(88, 62, 24)
		ToggleScanBtn.Text = "❚❚ PAUSED"
		ToggleScanBtn.TextColor3 = Color3.fromRGB(255, 222, 145)
		pushConsole("WARN", "Auto Scan Animation ID dijeda.")
	end
end)

ClearAnimBtn.MouseButton1Click:Connect(function()
	table.clear(SCANNED_LIST)
	table.clear(SCANNED_MAP)
	if refreshScannerViewFn then
		refreshScannerViewFn()
	end
	pushConsole("INFO", "Daftar ID animasi dibersihkan.")
end)

-- ==========================================
-- HALAMAN 2: EXPORT & INFO
-- ==========================================
local ExportPage = Instance.new("Frame")
ExportPage.Size = UDim2.fromScale(1, 1)
ExportPage.BackgroundTransparency = 1
ExportPage.Visible = false
ExportPage.Parent = ContentArea
tabPages["Export"] = ExportPage

local ExportTitle = Instance.new("TextLabel")
ExportTitle.Size = UDim2.new(1, -24, 0, 16)
ExportTitle.Position = UDim2.new(0, 12, 0, 6)
ExportTitle.BackgroundTransparency = 1
ExportTitle.Text = "Export Hasil Scan & About"
ExportTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ExportTitle.TextSize = 12
ExportTitle.Font = Enum.Font.GothamBold
ExportTitle.TextXAlignment = Enum.TextXAlignment.Left
ExportTitle.Parent = ExportPage

local ExportAllIdsBtn = Instance.new("TextButton")
ExportAllIdsBtn.Size = UDim2.new(1, -24, 0, 28)
ExportAllIdsBtn.Position = UDim2.new(0, 12, 0, 28)
ExportAllIdsBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ExportAllIdsBtn.Text = "💾  SIMPAN / COPY SEMUA ANIMATION ID"
ExportAllIdsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ExportAllIdsBtn.TextSize = 10
ExportAllIdsBtn.Font = Enum.Font.GothamBold
ExportAllIdsBtn.Parent = ExportPage
Instance.new("UICorner", ExportAllIdsBtn).CornerRadius = UDim.new(0, 7)

local ExportStatusLabel = Instance.new("TextLabel")
ExportStatusLabel.Size = UDim2.new(1, -24, 0, 36)
ExportStatusLabel.Position = UDim2.new(0, 12, 0, 62)
ExportStatusLabel.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
ExportStatusLabel.Text = "Menyimpan daftar ID animasi yang terdeteksi ke folder " .. CONFIG.WorkspaceRoot .. "/Animations/"
ExportStatusLabel.TextColor3 = Color3.fromRGB(185, 205, 255)
ExportStatusLabel.TextSize = 9
ExportStatusLabel.Font = Enum.Font.Code
ExportStatusLabel.TextWrapped = true
ExportStatusLabel.Parent = ExportPage
Instance.new("UICorner", ExportStatusLabel).CornerRadius = UDim.new(0, 7)

ExportAllIdsBtn.MouseButton1Click:Connect(function()
	local ok, msg = exportAnimIdsToFile()
	ExportStatusLabel.Text = msg
	ExportStatusLabel.TextColor3 = ok and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
	pushConsole(ok and "OK" or "WARN", msg)
	notify("Export Animation ID", msg)
end)

local AboutCard = Instance.new("Frame")
AboutCard.Size = UDim2.new(1, -24, 0, 72)
AboutCard.Position = UDim2.new(0, 12, 0, 108)
AboutCard.BackgroundColor3 = Color3.fromRGB(24, 23, 38)
AboutCard.BorderSizePixel = 0
AboutCard.Parent = ExportPage
Instance.new("UICorner", AboutCard).CornerRadius = UDim.new(0, 8)
local AboutStroke = Instance.new("UIStroke", AboutCard)
AboutStroke.Color = Color3.fromRGB(82, 72, 134)
AboutStroke.Thickness = 1

local AboutHeader = Instance.new("TextLabel")
AboutHeader.Size = UDim2.new(1, -16, 0, 16)
AboutHeader.Position = UDim2.new(0, 10, 0, 8)
AboutHeader.BackgroundTransparency = 1
AboutHeader.Text = "ABOUT"
AboutHeader.TextColor3 = Color3.fromRGB(155, 145, 225)
AboutHeader.TextSize = 9
AboutHeader.Font = Enum.Font.GothamBold
AboutHeader.TextXAlignment = Enum.TextXAlignment.Left
AboutHeader.Parent = AboutCard

local AboutText = Instance.new("TextLabel")
AboutText.Size = UDim2.new(1, -16, 0, 38)
AboutText.Position = UDim2.new(0, 10, 0, 24)
AboutText.BackgroundTransparency = 1
AboutText.Text = "SCRIPT PREMIUM BY IKYY"
AboutText.TextColor3 = Color3.fromRGB(255, 255, 255)
AboutText.TextSize = 13
AboutText.Font = Enum.Font.GothamBold
AboutText.TextXAlignment = Enum.TextXAlignment.Left
AboutText.TextYAlignment = Enum.TextYAlignment.Center
AboutText.Parent = AboutCard

-- ==========================================
-- HALAMAN 3: CONSOLE LOG
-- ==========================================
local ConsolePage = Instance.new("Frame")
ConsolePage.Size = UDim2.fromScale(1, 1)
ConsolePage.BackgroundTransparency = 1
ConsolePage.Visible = false
ConsolePage.Parent = ContentArea
tabPages["Console"] = ConsolePage

local ConsoleTitle = Instance.new("TextLabel")
ConsoleTitle.Size = UDim2.new(1, -138, 0, 18)
ConsoleTitle.Position = UDim2.new(0, 12, 0, 6)
ConsoleTitle.BackgroundTransparency = 1
ConsoleTitle.Text = "Scanner Console"
ConsoleTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ConsoleTitle.TextSize = 12
ConsoleTitle.Font = Enum.Font.GothamBold
ConsoleTitle.TextXAlignment = Enum.TextXAlignment.Left
ConsoleTitle.Parent = ConsolePage

local CopyConsoleBtn = Instance.new("TextButton")
CopyConsoleBtn.Size = UDim2.fromOffset(54, 20)
CopyConsoleBtn.Position = UDim2.new(1, -120, 0, 5)
CopyConsoleBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 52)
CopyConsoleBtn.Text = "📋 Copy"
CopyConsoleBtn.TextColor3 = Color3.fromRGB(215, 212, 248)
CopyConsoleBtn.TextSize = 8
CopyConsoleBtn.Font = Enum.Font.GothamBold
CopyConsoleBtn.Parent = ConsolePage
Instance.new("UICorner", CopyConsoleBtn).CornerRadius = UDim.new(0, 5)

local ClearConsoleBtn = Instance.new("TextButton")
ClearConsoleBtn.Size = UDim2.fromOffset(52, 20)
ClearConsoleBtn.Position = UDim2.new(1, -62, 0, 5)
ClearConsoleBtn.BackgroundColor3 = Color3.fromRGB(58, 26, 36)
ClearConsoleBtn.Text = "🗑 Clear"
ClearConsoleBtn.TextColor3 = Color3.fromRGB(255, 185, 195)
ClearConsoleBtn.TextSize = 8
ClearConsoleBtn.Font = Enum.Font.GothamBold
ClearConsoleBtn.Parent = ConsolePage
Instance.new("UICorner", ClearConsoleBtn).CornerRadius = UDim.new(0, 5)

local ConsoleScroll = Instance.new("ScrollingFrame")
ConsoleScroll.Name = "ConsoleOutputScroll"
ConsoleScroll.Size = UDim2.new(1, -24, 1, -34)
ConsoleScroll.Position = UDim2.new(0, 12, 0, 28)
ConsoleScroll.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
ConsoleScroll.BorderSizePixel = 0
ConsoleScroll.ScrollBarThickness = 3
ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ConsoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ConsoleScroll.Parent = ConsolePage
Instance.new("UICorner", ConsoleScroll).CornerRadius = UDim.new(0, 8)
local ConsoleStroke = Instance.new("UIStroke", ConsoleScroll)
ConsoleStroke.Color = Color3.fromRGB(52, 48, 82)
ConsoleStroke.Thickness = 1

local ConsoleListLayout = Instance.new("UIListLayout")
ConsoleListLayout.Padding = UDim.new(0, 3)
ConsoleListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ConsoleListLayout.Parent = ConsoleScroll

local ConsolePad = Instance.new("UIPadding")
ConsolePad.PaddingTop = UDim.new(0, 6)
ConsolePad.PaddingBottom = UDim.new(0, 6)
ConsolePad.PaddingLeft = UDim.new(0, 7)
ConsolePad.PaddingRight = UDim.new(0, 7)
ConsolePad.Parent = ConsoleScroll

local consoleRowOrder = 0

local function getLevelColor(level: string): Color3
	if level == "SCAN" then
		return Color3.fromRGB(120, 255, 180)
	elseif level == "WARN" then
		return Color3.fromRGB(255, 215, 120)
	end
	return Color3.fromRGB(195, 192, 222)
end

appendConsoleLineFn = function(level: string, formattedLine: string)
	consoleRowOrder += 1
	local row = Instance.new("TextLabel")
	row.Name = "LogRow_" .. tostring(consoleRowOrder)
	row.Size = UDim2.new(1, -4, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.BackgroundTransparency = 1
	row.Text = formattedLine
	row.TextColor3 = getLevelColor(level)
	row.TextSize = 8
	row.Font = Enum.Font.Code
	row.TextWrapped = true
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.LayoutOrder = consoleRowOrder
	row.Parent = ConsoleScroll

	task.defer(function()
		ConsoleScroll.CanvasPosition = Vector2.new(0, math.max(0, ConsoleScroll.AbsoluteCanvasSize.Y))
	end)
end

ClearConsoleBtn.MouseButton1Click:Connect(function()
	table.clear(CONSOLE_LINES)
	consoleRowOrder = 0
	for _, child in ipairs(ConsoleScroll:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	pushConsole("INFO", "Console dibersihkan.")
end)

CopyConsoleBtn.MouseButton1Click:Connect(function()
	local joined = table.concat(CONSOLE_LINES, "\n")
	if joined == "" then
		notify("Console", "Belum ada log untuk disalin.")
		return
	end
	local copied = setClipboardText(joined)
	notify("Console", copied and "Log console disalin ke clipboard." or "Clipboard tidak didukung di executor ini.")
end)

-- ==========================================
-- NAVIGASI TAB
-- ==========================================
createNavButton("Scanner", "🎬  Anim Scanner", 1).MouseButton1Click:Connect(function()
	switchTab("Scanner")
end)
createNavButton("Export", "💾  Export ID", 2).MouseButton1Click:Connect(function()
	switchTab("Export")
end)
createNavButton("Console", "🖥  Console", 3).MouseButton1Click:Connect(function()
	switchTab("Console")
end)
switchTab("Scanner")

pushConsole("INFO", "SCRIPT PREMIUM BY IKYY • Auto Scan Animation ID aktif.")
