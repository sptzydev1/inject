--!strict
-- Plugin Studio Lite (Delta Executor Edition) by Ikyy
-- Fitur: Spoof (Audio/RBXM), Upload Asset, Place Maker, Asset Permissions, Setting, Close -> Ikon Lingkaran Profile (Draggable)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OLD_GUI = PlayerGui:FindFirstChild("IkyyPluginStudioLite_GUI")
if OLD_GUI then
	OLD_GUI:Destroy()
end

-- ==========================================
-- KONFIGURASI & STATE
-- ==========================================
local CONFIG = {
	BaseUrl = "https://ygfstudio.my.id",
	WorkspaceRoot = "IkyyStudioLite",
	Cookie = "",
	ApiKey = "",
	DefaultUniverseId = "10516113765",
	IsMinimized = false,
	ActiveTab = "Spoof",
	SpoofFilter = "Auto", -- Auto, Audio, Decal, Model, Anim
	SessionId = "YGF_0000",
	UserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
}

local WINDOW_SIZE = UDim2.fromOffset(540, 320)
local WINDOW_POS = UDim2.new(0.5, -270, 0.5, -160)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS

local function trim(s: string?): string
	if type(s) ~= "string" then return "" end
	return s:match("^%s*(.-)%s*$") or ""
end

local function normalizeCookie(rawCookie: string): string
	local c = trim(rawCookie)
	if c == "" then return "" end
	c = c:gsub("^%.ROBLOSECURITY=", "")
	c = c:gsub("[\r\n]+", "")
	c = trim(c)
	if c ~= "" and c:sub(-1) ~= ";" then
		c = c .. ";"
	end
	return c
end

local function notify(title: string, text: string)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 2.5,
		})
	end)
end

local function hasFileIO(): boolean
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
end

local function ensureFolders()
	if not hasFileIO() then return end
	local folders = {
		CONFIG.WorkspaceRoot,
		CONFIG.WorkspaceRoot .. "/SPOOF",
		CONFIG.WorkspaceRoot .. "/SPOOF/info",
		CONFIG.WorkspaceRoot .. "/SPOOF/music",
		CONFIG.WorkspaceRoot .. "/SPOOF/animasi",
		CONFIG.WorkspaceRoot .. "/Uploads",
		CONFIG.WorkspaceRoot .. "/Logs",
	}
	for _, folder in ipairs(folders) do
		if not isfolder(folder) then
			pcall(makefolder, folder)
		end
	end
end

local function saveTextFile(relPath: string, content: string): boolean
	if not hasFileIO() then return false end
	ensureFolders()
	local ok = pcall(writefile, CONFIG.WorkspaceRoot .. "/" .. relPath, content)
	return ok
end

local function loadTextFile(relPath: string): string?
	if not hasFileIO() then return nil end
	local cleanRel = relPath:gsub("^/+", "")
	local candidates = {
		CONFIG.WorkspaceRoot .. "/" .. cleanRel,
		cleanRel,
	}
	for _, fullPath in ipairs(candidates) do
		local ok, res = pcall(function()
			if type(isfile) == "function" and isfile(fullPath) then
				return readfile(fullPath)
			end
			return nil
		end)
		if ok and type(res) == "string" then
			return res
		end
	end
	return nil
end

local savedCookie = loadTextFile("cookie.txt")
local savedApiKey = loadTextFile("apikey.txt")
if savedCookie and trim(savedCookie) ~= "" then CONFIG.Cookie = normalizeCookie(savedCookie) end
if savedApiKey and trim(savedApiKey) ~= "" then CONFIG.ApiKey = trim(savedApiKey) end

local function getHttpFunc()
	if type(request) == "function" then return request end
	if type(http_request) == "function" then return http_request end
	if syn and type(syn.request) == "function" then return syn.request end
	if http and type(http.request) == "function" then return http.request end
	return nil
end

-- Wrapper request ala requests.Session di Python
local function apiRequest(options: {
	Url: string,
	Method: string?,
	Headers: {[string]: string}?,
	Body: string?,
	Retries: number?,
})
	local reqFn = getHttpFunc()
	if not reqFn then
		return nil, false
	end

	local maxAttempts = math.max(1, options.Retries or 1)
	local baseHeaders: {[string]: string} = {
		["User-Agent"] = CONFIG.UserAgent,
	}
	if options.Headers then
		for k, v in pairs(options.Headers) do
			baseHeaders[k] = v
		end
	end

	local lastRes = nil
	local lastOk = false

	for attempt = 1, maxAttempts do
		local ok, res = pcall(reqFn, {
			Url = options.Url,
			Method = options.Method or "GET",
			Headers = baseHeaders,
			Body = options.Body,
		})
		if ok and type(res) == "table" then
			lastRes = res
			local code = tonumber(res.StatusCode) or 0
			lastOk = (code >= 200 and code < 300)
			if lastOk or code == 400 or code == 401 or code == 403 or code == 404 then
				return res, lastOk
			end
		end
		if attempt < maxAttempts then
			task.wait(0.6)
		end
	end

	return lastRes, lastOk
end

local function getHeaderCaseInsensitive(headers: any, targetKey: string): string?
	if type(headers) ~= "table" then return nil end
	local lowerTarget = targetKey:lower()
	for k, v in pairs(headers) do
		if type(k) == "string" and k:lower() == lowerTarget then
			return tostring(v)
		end
	end
	return nil
end

local function buildMultipartAssetBody(requestJson: string, payloadContent: string, filename: string)
	local boundary = "----IkyyStudioBoundary" .. tostring(os.time()) .. tostring(math.random(1000, 9999))
	local parts = {
		"--" .. boundary .. "\r\n",
		'Content-Disposition: form-data; name="request"\r\n',
		"Content-Type: application/json\r\n\r\n",
		requestJson .. "\r\n",
		"--" .. boundary .. "\r\n",
		'Content-Disposition: form-data; name="fileContent"; filename="' .. filename .. '"\r\n',
		"Content-Type: application/octet-stream\r\n\r\n",
		payloadContent .. "\r\n",
		"--" .. boundary .. "--\r\n",
	}
	return table.concat(parts), "multipart/form-data; boundary=" .. boundary
end

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
-- UI UTAMA (WINDOW TERKUNCI DI TENGAH, IKON BISA DIGESER LUAS)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IkyyPluginStudioLite_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- 1. IKON LINGKARAN PROFILE USER (UKURAN KECIL 42x42, BISA DIGESER KE SELURUH LAYAR)
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

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingProfileBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(130, 92, 255)
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatingProfileBtn

-- 2. WINDOW UTAMA (UKURAN LEBIH KECIL 540x320)
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = WINDOW_SIZE
MainWindow.Position = WINDOW_POS
MainWindow.BackgroundColor3 = Color3.fromRGB(16, 15, 24)
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainWindow

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(92, 72, 168)
MainStroke.Thickness = 1.4
MainStroke.Transparency = 0.25
MainStroke.Parent = MainWindow

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
HeaderBar.Size = UDim2.new(1, 0, 0, 48)
HeaderBar.BackgroundColor3 = Color3.fromRGB(20, 19, 30)
HeaderBar.BackgroundTransparency = 0.25
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainWindow

local HeaderLogoBox = Instance.new("Frame")
HeaderLogoBox.Size = UDim2.fromOffset(30, 30)
HeaderLogoBox.Position = UDim2.new(0, 12, 0.5, -15)
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
LogoIcon.Text = "⇄"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 15
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 220, 0, 12)
SubTitleLabel.Position = UDim2.new(0, 50, 0, 7)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • DELTA EDITION"
SubTitleLabel.TextColor3 = Color3.fromRGB(130, 126, 155)
SubTitleLabel.TextSize = 8
SubTitleLabel.Font = Enum.Font.GothamBold
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 240, 0, 17)
TitleLabel.Position = UDim2.new(0, 50, 0, 17)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Plugin Studio Lite"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(0, 240, 0, 12)
MetaLabel.Position = UDim2.new(0, 50, 0, 34)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "by Ikyy • v1.0 • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
MetaLabel.TextSize = 9
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.Parent = HeaderBar

-- Tombol Close (X) -> Mengecil menjadi Ikon Lingkaran Profile User (42x42)
local CloseCircleBtn = Instance.new("TextButton")
CloseCircleBtn.Name = "CloseToCircleBtn"
CloseCircleBtn.Size = UDim2.fromOffset(28, 28)
CloseCircleBtn.Position = UDim2.new(1, -40, 0.5, -14)
CloseCircleBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 50)
CloseCircleBtn.Text = "✕"
CloseCircleBtn.TextColor3 = Color3.fromRGB(220, 218, 238)
CloseCircleBtn.TextSize = 12
CloseCircleBtn.Font = Enum.Font.GothamBold
CloseCircleBtn.Parent = HeaderBar

Instance.new("UICorner", CloseCircleBtn).CornerRadius = UDim.new(1, 0)
local CloseStroke = Instance.new("UIStroke", CloseCircleBtn)
CloseStroke.Color = Color3.fromRGB(85, 80, 120)
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

-- Logika Geser Luas (Drag) & Klik pada Ikon Profil
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
		local clampedX = math.clamp(pos.X.Offset, pad, maxX)
		local clampedY = math.clamp(pos.Y.Offset, pad, maxY)
		return UDim2.fromOffset(clampedX, clampedY)
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
Sidebar.Size = UDim2.new(0, 126, 1, -58)
Sidebar.Position = UDim2.new(0, 10, 0, 52)
Sidebar.BackgroundColor3 = Color3.fromRGB(21, 20, 32)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
local SideStroke = Instance.new("UIStroke", Sidebar)
SideStroke.Color = Color3.fromRGB(52, 48, 82)
SideStroke.Thickness = 1

local NavList = Instance.new("Frame")
NavList.Size = UDim2.new(1, -10, 0, 148)
NavList.Position = UDim2.new(0, 5, 0, 6)
NavList.BackgroundTransparency = 1
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavList

local tabPages: {[string]: Frame} = {}
local tabButtons: {[string]: TextButton} = {}

local function createNavButton(name: string, label: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = "Nav_" .. name
	btn.Size = UDim2.new(1, 0, 0, 33)
	btn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
	btn.Text = "  " .. label
	btn.TextColor3 = Color3.fromRGB(185, 182, 210)
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Parent = NavList

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
	tabButtons[name] = btn
	return btn
end

local QuickTitle = Instance.new("TextLabel")
QuickTitle.Size = UDim2.new(1, -12, 0, 14)
QuickTitle.Position = UDim2.new(0, 8, 1, -60)
QuickTitle.BackgroundTransparency = 1
QuickTitle.Text = "Aksi Cepat"
QuickTitle.TextColor3 = Color3.fromRGB(140, 136, 168)
QuickTitle.TextSize = 9
QuickTitle.Font = Enum.Font.GothamMedium
QuickTitle.TextXAlignment = Enum.TextXAlignment.Left
QuickTitle.Parent = Sidebar

local CekKoneksiBtn = Instance.new("TextButton")
CekKoneksiBtn.Size = UDim2.new(0, 54, 0, 30)
CekKoneksiBtn.Position = UDim2.new(0, 6, 1, -40)
CekKoneksiBtn.BackgroundColor3 = Color3.fromRGB(64, 118, 240)
CekKoneksiBtn.Text = "Cek"
CekKoneksiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CekKoneksiBtn.TextSize = 10
CekKoneksiBtn.Font = Enum.Font.GothamBold
CekKoneksiBtn.Parent = Sidebar
Instance.new("UICorner", CekKoneksiBtn).CornerRadius = UDim.new(0, 7)

local SembunyiBtn = Instance.new("TextButton")
SembunyiBtn.Size = UDim2.new(0, 54, 0, 30)
SembunyiBtn.Position = UDim2.new(1, -60, 1, -40)
SembunyiBtn.BackgroundColor3 = Color3.fromRGB(32, 31, 48)
SembunyiBtn.Text = "Sembunyi"
SembunyiBtn.TextColor3 = Color3.fromRGB(215, 212, 235)
SembunyiBtn.TextSize = 9
SembunyiBtn.Font = Enum.Font.GothamBold
SembunyiBtn.Parent = Sidebar
Instance.new("UICorner", SembunyiBtn).CornerRadius = UDim.new(0, 7)
local SembStroke = Instance.new("UIStroke", SembunyiBtn)
SembStroke.Color = Color3.fromRGB(70, 66, 102)
SembStroke.Thickness = 1

SembunyiBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

-- ==========================================
-- AREA KONTEN KANAN
-- ==========================================
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -152, 1, -58)
ContentArea.Position = UDim2.new(0, 142, 0, 52)
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

-- Helper indikator hasil (tanpa menampilkan teks nama status)
local function createResultBar(parent: GuiObject, yPos: number)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 10)
	bar.Position = UDim2.new(0, 12, 0, yPos)
	bar.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
	bar.BorderSizePixel = 0
	bar.Parent = parent
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local stroke = Instance.new("UIStroke", bar)
	stroke.Color = Color3.fromRGB(58, 54, 88)
	stroke.Thickness = 1

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local statusTextHidden = Instance.new("TextLabel")
	statusTextHidden.Visible = false
	statusTextHidden.Parent = bar

	return function(success: boolean, ratio: number)
		local clamped = math.clamp(ratio, 0, 1)
		fill.BackgroundColor3 = success and Color3.fromRGB(56, 239, 125) or Color3.fromRGB(255, 86, 102)
		TweenService:Create(fill, TweenInfo.new(0.18), {
			Size = UDim2.new(clamped, 0, 1, 0),
		}):Play()
	end
end

-- ==========================================
-- HALAMAN 1: SPOOF (SUSUNAN PERSIS SEPERTI GAMBAR)
-- ==========================================
local SpoofPage = Instance.new("Frame")
SpoofPage.Size = UDim2.fromScale(1, 1)
SpoofPage.BackgroundTransparency = 1
SpoofPage.Visible = true
SpoofPage.Parent = ContentArea
tabPages["Spoof"] = SpoofPage

local SpoofTitle = Instance.new("TextLabel")
SpoofTitle.Size = UDim2.new(1, -24, 0, 18)
SpoofTitle.Position = UDim2.new(0, 12, 0, 8)
SpoofTitle.BackgroundTransparency = 1
SpoofTitle.Text = "Spoof"
SpoofTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SpoofTitle.TextSize = 14
SpoofTitle.Font = Enum.Font.GothamBold
SpoofTitle.TextXAlignment = Enum.TextXAlignment.Left
SpoofTitle.Parent = SpoofPage

local SpoofDesc = Instance.new("TextLabel")
SpoofDesc.Size = UDim2.new(1, -24, 0, 14)
SpoofDesc.Position = UDim2.new(0, 12, 0, 25)
SpoofDesc.BackgroundTransparency = 1
SpoofDesc.Text = "Asset ID lama jadi ID baru milikmu"
SpoofDesc.TextColor3 = Color3.fromRGB(145, 142, 170)
SpoofDesc.TextSize = 10
SpoofDesc.Font = Enum.Font.Gotham
SpoofDesc.TextXAlignment = Enum.TextXAlignment.Left
SpoofDesc.Parent = SpoofPage

local AssetIdHeader = Instance.new("TextLabel")
AssetIdHeader.Size = UDim2.new(1, -24, 0, 14)
AssetIdHeader.Position = UDim2.new(0, 12, 0, 43)
AssetIdHeader.BackgroundTransparency = 1
AssetIdHeader.Text = "｜ ASSET ID"
AssetIdHeader.TextColor3 = Color3.fromRGB(175, 172, 205)
AssetIdHeader.TextSize = 10
AssetIdHeader.Font = Enum.Font.GothamBold
AssetIdHeader.TextXAlignment = Enum.TextXAlignment.Left
AssetIdHeader.Parent = SpoofPage

local AssetIdBox = Instance.new("TextBox")
AssetIdBox.Size = UDim2.new(1, -24, 0, 68)
AssetIdBox.Position = UDim2.new(0, 12, 0, 59)
AssetIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetIdBox.Text = ""
AssetIdBox.PlaceholderText = "Tempel Asset ID di sini (pisah spasi, koma, atau baris baru)"
AssetIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetIdBox.TextSize = 11
AssetIdBox.Font = Enum.Font.Gotham
AssetIdBox.TextXAlignment = Enum.TextXAlignment.Left
AssetIdBox.TextYAlignment = Enum.TextYAlignment.Top
AssetIdBox.ClearTextOnFocus = false
AssetIdBox.MultiLine = true
AssetIdBox.TextWrapped = true
AssetIdBox.Parent = SpoofPage
Instance.new("UICorner", AssetIdBox).CornerRadius = UDim.new(0, 8)
local AssetStroke = Instance.new("UIStroke", AssetIdBox)
AssetStroke.Color = Color3.fromRGB(65, 60, 102)
AssetStroke.Thickness = 1

local FilterRow = Instance.new("Frame")
FilterRow.Size = UDim2.new(1, -24, 0, 26)
FilterRow.Position = UDim2.new(0, 12, 0, 134)
FilterRow.BackgroundTransparency = 1
FilterRow.Parent = SpoofPage

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 6)
FilterLayout.Parent = FilterRow

local filterButtons: {[string]: TextButton} = {}
local filters = {"Auto", "Audio", "Decal", "Model", "Anim"}

local function setFilter(name: string)
	CONFIG.SpoofFilter = name
	for fName, btn in pairs(filterButtons) do
		local selected = (fName == name)
		btn.BackgroundColor3 = selected and Color3.fromRGB(48, 45, 74) or Color3.fromRGB(26, 25, 39)
		btn.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(165, 162, 190)
	end
end

for _, fName in ipairs(filters) do
	local fBtn = Instance.new("TextButton")
	fBtn.Size = UDim2.new(0.2, -5, 1, 0)
	fBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
	fBtn.Text = fName
	fBtn.TextColor3 = Color3.fromRGB(165, 162, 190)
	fBtn.TextSize = 10
	fBtn.Font = Enum.Font.GothamMedium
	fBtn.AutoButtonColor = false
	fBtn.Parent = FilterRow
	Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 7)
	local fs = Instance.new("UIStroke", fBtn)
	fs.Color = Color3.fromRGB(62, 58, 92)
	fs.Thickness = 1
	filterButtons[fName] = fBtn
	fBtn.MouseButton1Click:Connect(function()
		setFilter(fName)
	end)
end
setFilter("Auto")

local SpoofNowBtn = Instance.new("TextButton")
SpoofNowBtn.Size = UDim2.new(0.62, -14, 0, 36)
SpoofNowBtn.Position = UDim2.new(0, 12, 0, 168)
SpoofNowBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SpoofNowBtn.Text = "⇄  SPOOF SEKARANG"
SpoofNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpoofNowBtn.TextSize = 11
SpoofNowBtn.Font = Enum.Font.GothamBold
SpoofNowBtn.Parent = SpoofPage
Instance.new("UICorner", SpoofNowBtn).CornerRadius = UDim.new(0, 8)

local BersihkanBtn = Instance.new("TextButton")
BersihkanBtn.Size = UDim2.new(0.38, -14, 0, 36)
BersihkanBtn.Position = UDim2.new(0.62, 2, 0, 168)
BersihkanBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
BersihkanBtn.Text = "BERSIHKAN"
BersihkanBtn.TextColor3 = Color3.fromRGB(210, 208, 232)
BersihkanBtn.TextSize = 10
BersihkanBtn.Font = Enum.Font.GothamBold
BersihkanBtn.Parent = SpoofPage
Instance.new("UICorner", BersihkanBtn).CornerRadius = UDim.new(0, 8)
local BersStroke = Instance.new("UIStroke", BersihkanBtn)
BersStroke.Color = Color3.fromRGB(68, 64, 100)
BersStroke.Thickness = 1

local setSpoofOutcome = createResultBar(SpoofPage, 214)

BersihkanBtn.MouseButton1Click:Connect(function()
	AssetIdBox.Text = ""
	setSpoofOutcome(true, 0)
end)

-- ==========================================
-- HALAMAN 2: UPLOAD ASSET
-- ==========================================
local UploadPage = Instance.new("Frame")
UploadPage.Size = UDim2.fromScale(1, 1)
UploadPage.BackgroundTransparency = 1
UploadPage.Visible = false
UploadPage.Parent = ContentArea
tabPages["Upload"] = UploadPage

local UploadTitle = Instance.new("TextLabel")
UploadTitle.Size = UDim2.new(1, -24, 0, 18)
UploadTitle.Position = UDim2.new(0, 12, 0, 8)
UploadTitle.BackgroundTransparency = 1
UploadTitle.Text = "Upload Asset"
UploadTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
UploadTitle.TextSize = 14
UploadTitle.Font = Enum.Font.GothamBold
UploadTitle.TextXAlignment = Enum.TextXAlignment.Left
UploadTitle.Parent = UploadPage

local UploadNameBox = Instance.new("TextBox")
UploadNameBox.Size = UDim2.new(0.5, -15, 0, 30)
UploadNameBox.Position = UDim2.new(0, 12, 0, 32)
UploadNameBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadNameBox.PlaceholderText = "Nama Asset"
UploadNameBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadNameBox.Text = ""
UploadNameBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadNameBox.TextSize = 10
UploadNameBox.Font = Enum.Font.Gotham
UploadNameBox.Parent = UploadPage
Instance.new("UICorner", UploadNameBox).CornerRadius = UDim.new(0, 7)

local UploadTypeBox = Instance.new("TextBox")
UploadTypeBox.Size = UDim2.new(0.5, -15, 0, 30)
UploadTypeBox.Position = UDim2.new(0.5, 3, 0, 32)
UploadTypeBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadTypeBox.PlaceholderText = "Model / Audio / Animation / Decal"
UploadTypeBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadTypeBox.Text = "Model"
UploadTypeBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadTypeBox.TextSize = 10
UploadTypeBox.Font = Enum.Font.Gotham
UploadTypeBox.Parent = UploadPage
Instance.new("UICorner", UploadTypeBox).CornerRadius = UDim.new(0, 7)

local UploadCreatorBox = Instance.new("TextBox")
UploadCreatorBox.Size = UDim2.new(0.5, -15, 0, 30)
UploadCreatorBox.Position = UDim2.new(0, 12, 0, 68)
UploadCreatorBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadCreatorBox.PlaceholderText = "Creator ID"
UploadCreatorBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadCreatorBox.Text = tostring(LocalPlayer.UserId)
UploadCreatorBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadCreatorBox.TextSize = 10
UploadCreatorBox.Font = Enum.Font.Gotham
UploadCreatorBox.Parent = UploadPage
Instance.new("UICorner", UploadCreatorBox).CornerRadius = UDim.new(0, 7)

local UploadOwnerModeBox = Instance.new("TextBox")
UploadOwnerModeBox.Size = UDim2.new(0.5, -15, 0, 30)
UploadOwnerModeBox.Position = UDim2.new(0.5, 3, 0, 68)
UploadOwnerModeBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadOwnerModeBox.PlaceholderText = "user atau group"
UploadOwnerModeBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadOwnerModeBox.Text = "user"
UploadOwnerModeBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadOwnerModeBox.TextSize = 10
UploadOwnerModeBox.Font = Enum.Font.Gotham
UploadOwnerModeBox.Parent = UploadPage
Instance.new("UICorner", UploadOwnerModeBox).CornerRadius = UDim.new(0, 7)

local UploadPayloadBox = Instance.new("TextBox")
UploadPayloadBox.Size = UDim2.new(1, -24, 0, 66)
UploadPayloadBox.Position = UDim2.new(0, 12, 0, 104)
UploadPayloadBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadPayloadBox.PlaceholderText = "Path file di workspace atau isi payload"
UploadPayloadBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadPayloadBox.Text = ""
UploadPayloadBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadPayloadBox.TextSize = 10
UploadPayloadBox.Font = Enum.Font.Gotham
UploadPayloadBox.MultiLine = true
UploadPayloadBox.TextWrapped = true
UploadPayloadBox.TextXAlignment = Enum.TextXAlignment.Left
UploadPayloadBox.TextYAlignment = Enum.TextYAlignment.Top
UploadPayloadBox.Parent = UploadPage
Instance.new("UICorner", UploadPayloadBox).CornerRadius = UDim.new(0, 7)

local UploadActionBtn = Instance.new("TextButton")
UploadActionBtn.Size = UDim2.new(1, -24, 0, 34)
UploadActionBtn.Position = UDim2.new(0, 12, 0, 176)
UploadActionBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
UploadActionBtn.Text = "⬆  UPLOAD ASSET"
UploadActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UploadActionBtn.TextSize = 11
UploadActionBtn.Font = Enum.Font.GothamBold
UploadActionBtn.Parent = UploadPage
Instance.new("UICorner", UploadActionBtn).CornerRadius = UDim.new(0, 8)

local setUploadOutcome = createResultBar(UploadPage, 218)

-- ==========================================
-- HALAMAN 3: PLACE MAKER & ASSET PERMISSIONS
-- ==========================================
local ToolsPage = Instance.new("Frame")
ToolsPage.Size = UDim2.fromScale(1, 1)
ToolsPage.BackgroundTransparency = 1
ToolsPage.Visible = false
ToolsPage.Parent = ContentArea
tabPages["Tools"] = ToolsPage

local ToolsTitle = Instance.new("TextLabel")
ToolsTitle.Size = UDim2.new(1, -24, 0, 18)
ToolsTitle.Position = UDim2.new(0, 12, 0, 6)
ToolsTitle.BackgroundTransparency = 1
ToolsTitle.Text = "Place Maker & Permissions"
ToolsTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ToolsTitle.TextSize = 13
ToolsTitle.Font = Enum.Font.GothamBold
ToolsTitle.TextXAlignment = Enum.TextXAlignment.Left
ToolsTitle.Parent = ToolsPage

local TemplateIdBox = Instance.new("TextBox")
TemplateIdBox.Size = UDim2.new(0.36, -12, 0, 28)
TemplateIdBox.Position = UDim2.new(0, 12, 0, 26)
TemplateIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TemplateIdBox.Text = "95206881"
TemplateIdBox.PlaceholderText = "Template ID"
TemplateIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TemplateIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TemplateIdBox.TextSize = 10
TemplateIdBox.Font = Enum.Font.Gotham
TemplateIdBox.Parent = ToolsPage
Instance.new("UICorner", TemplateIdBox).CornerRadius = UDim.new(0, 6)

local GroupIdBox = Instance.new("TextBox")
GroupIdBox.Size = UDim2.new(0.32, -8, 0, 28)
GroupIdBox.Position = UDim2.new(0.36, 2, 0, 26)
GroupIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
GroupIdBox.Text = ""
GroupIdBox.PlaceholderText = "Group ID"
GroupIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
GroupIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
GroupIdBox.TextSize = 10
GroupIdBox.Font = Enum.Font.Gotham
GroupIdBox.Parent = ToolsPage
Instance.new("UICorner", GroupIdBox).CornerRadius = UDim.new(0, 6)

local PlaceCountBox = Instance.new("TextBox")
PlaceCountBox.Size = UDim2.new(0.32, -10, 0, 28)
PlaceCountBox.Position = UDim2.new(0.68, 0, 0, 26)
PlaceCountBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PlaceCountBox.Text = "1"
PlaceCountBox.PlaceholderText = "Jumlah"
PlaceCountBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PlaceCountBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PlaceCountBox.TextSize = 10
PlaceCountBox.Font = Enum.Font.Gotham
PlaceCountBox.Parent = ToolsPage
Instance.new("UICorner", PlaceCountBox).CornerRadius = UDim.new(0, 6)

local CreatePlaceBtn = Instance.new("TextButton")
CreatePlaceBtn.Size = UDim2.new(1, -24, 0, 30)
CreatePlaceBtn.Position = UDim2.new(0, 12, 0, 58)
CreatePlaceBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
CreatePlaceBtn.Text = "🏗  BUAT PLACE"
CreatePlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreatePlaceBtn.TextSize = 10
CreatePlaceBtn.Font = Enum.Font.GothamBold
CreatePlaceBtn.Parent = ToolsPage
Instance.new("UICorner", CreatePlaceBtn).CornerRadius = UDim.new(0, 7)

local TargetUniverseBox = Instance.new("TextBox")
TargetUniverseBox.Size = UDim2.new(1, -24, 0, 28)
TargetUniverseBox.Position = UDim2.new(0, 12, 0, 94)
TargetUniverseBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TargetUniverseBox.Text = CONFIG.DefaultUniverseId
TargetUniverseBox.PlaceholderText = "Target Universe ID"
TargetUniverseBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TargetUniverseBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TargetUniverseBox.TextSize = 10
TargetUniverseBox.Font = Enum.Font.Gotham
TargetUniverseBox.Parent = ToolsPage
Instance.new("UICorner", TargetUniverseBox).CornerRadius = UDim.new(0, 6)

local PermIdsBox = Instance.new("TextBox")
PermIdsBox.Size = UDim2.new(1, -24, 0, 44)
PermIdsBox.Position = UDim2.new(0, 12, 0, 126)
PermIdsBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PermIdsBox.Text = ""
PermIdsBox.PlaceholderText = "Asset IDs Permission (pisah koma/spasi/baris)"
PermIdsBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PermIdsBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PermIdsBox.TextSize = 10
PermIdsBox.Font = Enum.Font.Gotham
PermIdsBox.MultiLine = true
PermIdsBox.TextWrapped = true
PermIdsBox.TextXAlignment = Enum.TextXAlignment.Left
PermIdsBox.TextYAlignment = Enum.TextYAlignment.Top
PermIdsBox.Parent = ToolsPage
Instance.new("UICorner", PermIdsBox).CornerRadius = UDim.new(0, 6)

local GrantPermBtn = Instance.new("TextButton")
GrantPermBtn.Size = UDim2.new(1, -24, 0, 30)
GrantPermBtn.Position = UDim2.new(0, 12, 0, 174)
GrantPermBtn.BackgroundColor3 = Color3.fromRGB(48, 45, 74)
GrantPermBtn.Text = "🔑  GRANT PERMISSIONS"
GrantPermBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
GrantPermBtn.TextSize = 10
GrantPermBtn.Font = Enum.Font.GothamBold
GrantPermBtn.Parent = ToolsPage
Instance.new("UICorner", GrantPermBtn).CornerRadius = UDim.new(0, 7)

local setToolsOutcome = createResultBar(ToolsPage, 212)

-- ==========================================
-- HALAMAN 4: SETTING
-- ==========================================
local SettingPage = Instance.new("Frame")
SettingPage.Size = UDim2.fromScale(1, 1)
SettingPage.BackgroundTransparency = 1
SettingPage.Visible = false
SettingPage.Parent = ContentArea
tabPages["Setting"] = SettingPage

local SettingTitle = Instance.new("TextLabel")
SettingTitle.Size = UDim2.new(1, -24, 0, 18)
SettingTitle.Position = UDim2.new(0, 12, 0, 8)
SettingTitle.BackgroundTransparency = 1
SettingTitle.Text = "Pengaturan Kredensial"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 14
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local CookieBox = Instance.new("TextBox")
CookieBox.Size = UDim2.new(1, -24, 0, 56)
CookieBox.Position = UDim2.new(0, 12, 0, 32)
CookieBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
CookieBox.Text = CONFIG.Cookie
CookieBox.PlaceholderText = ".ROBLOSECURITY Cookie..."
CookieBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
CookieBox.TextColor3 = Color3.fromRGB(235, 235, 250)
CookieBox.TextSize = 10
CookieBox.Font = Enum.Font.Gotham
CookieBox.MultiLine = true
CookieBox.TextWrapped = true
CookieBox.TextXAlignment = Enum.TextXAlignment.Left
CookieBox.TextYAlignment = Enum.TextYAlignment.Top
CookieBox.Parent = SettingPage
Instance.new("UICorner", CookieBox).CornerRadius = UDim.new(0, 7)

local ApiKeyBox = Instance.new("TextBox")
ApiKeyBox.Size = UDim2.new(1, -24, 0, 56)
ApiKeyBox.Position = UDim2.new(0, 12, 0, 94)
ApiKeyBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
ApiKeyBox.Text = CONFIG.ApiKey
ApiKeyBox.PlaceholderText = "Roblox Open Cloud API Key (x-api-key)..."
ApiKeyBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
ApiKeyBox.TextColor3 = Color3.fromRGB(235, 235, 250)
ApiKeyBox.TextSize = 10
ApiKeyBox.Font = Enum.Font.Gotham
ApiKeyBox.MultiLine = true
ApiKeyBox.TextWrapped = true
ApiKeyBox.TextXAlignment = Enum.TextXAlignment.Left
ApiKeyBox.TextYAlignment = Enum.TextYAlignment.Top
ApiKeyBox.Parent = SettingPage
Instance.new("UICorner", ApiKeyBox).CornerRadius = UDim.new(0, 7)

local SaveSettingBtn = Instance.new("TextButton")
SaveSettingBtn.Size = UDim2.new(1, -24, 0, 34)
SaveSettingBtn.Position = UDim2.new(0, 12, 0, 158)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 11
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 8)

local setSettingOutcome = createResultBar(SettingPage, 202)

SaveSettingBtn.MouseButton1Click:Connect(function()
	local c = normalizeCookie(CookieBox.Text)
	local k = trim(ApiKeyBox.Text)
	CONFIG.Cookie = c
	CONFIG.ApiKey = k
	CookieBox.Text = c
	ApiKeyBox.Text = k

	if not hasFileIO() then
		setSettingOutcome(true, 1)
		notify("Plugin Studio Lite", "Berhasil.")
		return
	end

	local okC = saveTextFile("cookie.txt", c)
	local okK = saveTextFile("apikey.txt", k)
	local ok = (c == "" or okC) and (k == "" or okK)
	setSettingOutcome(ok, ok and 1 or 0)
	notify("Plugin Studio Lite", ok and "Berhasil." or "Gagal.")
end)

-- Navigasi Sidebar
createNavButton("Spoof", "⇄  Spoof", 1).MouseButton1Click:Connect(function() switchTab("Spoof") end)
createNavButton("Upload", "⬆  Upload", 2).MouseButton1Click:Connect(function() switchTab("Upload") end)
createNavButton("Tools", "🛠  Place & Perm", 3).MouseButton1Click:Connect(function() switchTab("Tools") end)
createNavButton("Setting", "⚙  Setting", 4).MouseButton1Click:Connect(function() switchTab("Setting") end)
switchTab("Spoof")

-- ==========================================
-- LOGIKA EKSEKUSI FITUR (ALA PYTHON WORKFLOW)
-- ==========================================
local function parseIds(raw: string): {string}
	local seen: {[string]: boolean} = {}
	local out: {string} = {}
	for digits in raw:gmatch("%d{4,}") do
		if not seen[digits] then
			seen[digits] = true
			table.insert(out, digits)
		end
	end
	return out
end

local function extractFileNamesFromList(bodyText: string): {string}
	local names: {string} = {}
	local okJson, decoded = pcall(function()
		return HttpService:JSONDecode(bodyText)
	end)
	if okJson and type(decoded) == "table" then
		local listObj = decoded.files or decoded
		if type(listObj) == "table" then
			for _, item in ipairs(listObj) do
				if type(item) == "string" then
					table.insert(names, item)
				elseif type(item) == "table" then
					local fname = item.name or item.filename or item.file
					if type(fname) == "string" then
						table.insert(names, fname)
					end
				end
			end
		end
	end
	if #names == 0 then
		for quoted in bodyText:gmatch('"([^"]+%.%w+)"') do
			table.insert(names, quoted)
		end
	end
	return names
end

-- Step Python: ambil & simpan session YGF_\d+ dari halaman tools
local function fetchAndStoreSession(): string
	local res, ok = apiRequest({
		Url = CONFIG.BaseUrl .. "/tools/spoof-audio",
		Method = "GET",
		Headers = {
			["Referer"] = CONFIG.BaseUrl .. "/",
		},
		Retries = 2,
	})
	if ok and res then
		local sessMatch = tostring(res.Body or ""):match("YGF_%d+")
		if sessMatch then
			CONFIG.SessionId = sessMatch
			saveTextFile("SPOOF/info/session.txt", CONFIG.SessionId)
			return CONFIG.SessionId
		end
	end
	return CONFIG.SessionId
end

-- Step Python: kirim command spoof lalu poll /list-files, /is-ready/<file>, dan /files/<file>
local function spoofSingleAssetPythonStyle(assetId: string, filterMode: string): boolean
	local isRbxmMode = (filterMode == "Model" or filterMode == "Anim")

	local _, cmdOk = apiRequest({
		Url = CONFIG.BaseUrl .. "/send-command",
		Method = "POST",
		Headers = {
			["Content-Type"] = "application/json",
			["Origin"] = CONFIG.BaseUrl,
			["Referer"] = CONFIG.BaseUrl .. "/tools/spoof-audio",
		},
		Body = HttpService:JSONEncode({
			id = tostring(assetId),
			session = CONFIG.SessionId,
		}),
		Retries = 2,
	})

	if not cmdOk then
		return false
	end

	local foundFile: string? = nil
	for _ = 1, 20 do
		local listRes, listOk = apiRequest({
			Url = CONFIG.BaseUrl .. "/list-files",
			Method = "GET",
			Headers = {
				["Referer"] = CONFIG.BaseUrl .. "/tools/spoof-audio",
			},
		})
		if listOk and listRes then
			local candidates = extractFileNamesFromList(tostring(listRes.Body or ""))
			for _, sname in ipairs(candidates) do
				if sname:find(assetId, 1, true) then
					local lowerName = sname:lower()
					if isRbxmMode and lowerName:sub(-5) == ".rbxm" then
						foundFile = sname
						break
					elseif not isRbxmMode and lowerName:sub(-4) == ".mp3" then
						foundFile = sname
						break
					elseif filterMode == "Auto" then
						foundFile = sname
						break
					end
				end
			end
		end
		if foundFile then break end
		task.wait(1.5)
	end

	if not foundFile then
		return false
	end

	local encodedName = HttpService:UrlEncode(foundFile)
	for _ = 1, 10 do
		local readyRes, readyOk = apiRequest({
			Url = CONFIG.BaseUrl .. "/is-ready/" .. encodedName,
			Method = "GET",
		})
		if readyOk and readyRes then
			local okJson, decoded = pcall(function()
				return HttpService:JSONDecode(tostring(readyRes.Body or "{}"))
			end)
			if okJson and type(decoded) == "table" and decoded.ready == true then
				break
			end
		end
		task.wait(1.5)
	end

	local dlRes, dlOk = apiRequest({
		Url = CONFIG.BaseUrl .. "/files/" .. encodedName .. "?t=" .. tostring(os.time() * 1000),
		Method = "GET",
		Headers = {
			["Referer"] = CONFIG.BaseUrl .. "/tools/spoof-audio",
		},
		Retries = 2,
	})

	if dlOk and dlRes and dlRes.Body and tostring(dlRes.Body) ~= "" then
		local ext = (foundFile:match("%.[^%.]+$") or (isRbxmMode and ".rbxm" or ".mp3")):lower()
		local subDir = (ext == ".rbxm") and "SPOOF/animasi/" or "SPOOF/music/"
		local saved = saveTextFile(subDir .. assetId .. ext, tostring(dlRes.Body))
		return saved or (not hasFileIO())
	end

	return false
end

-- Cek Koneksi
local isCheckingConn = false
CekKoneksiBtn.MouseButton1Click:Connect(function()
	if isCheckingConn then return end
	isCheckingConn = true
	task.spawn(function()
		switchTab("Spoof")
		local sess = fetchAndStoreSession()
		local res, ok = apiRequest({
			Url = CONFIG.BaseUrl .. "/list-files",
			Method = "GET",
			Headers = {
				["Referer"] = CONFIG.BaseUrl .. "/tools/spoof-audio",
			},
		})
		local success = ok and res ~= nil and sess ~= nil
		setSpoofOutcome(success, success and 1 or 0)
		notify("Koneksi", success and "Berhasil." or "Gagal.")
		isCheckingConn = false
	end)
end)

-- Spoof
local isSpoofing = false
SpoofNowBtn.MouseButton1Click:Connect(function()
	if isSpoofing then return end
	local ids = parseIds(AssetIdBox.Text)
	if #ids == 0 then
		setSpoofOutcome(false, 0)
		notify("Spoof", "Gagal.")
		return
	end

	isSpoofing = true
	task.spawn(function()
		ensureFolders()
		fetchAndStoreSession()

		local berhasil, gagal = 0, 0
		for i, assetId in ipairs(ids) do
			local okItem = spoofSingleAssetPythonStyle(assetId, CONFIG.SpoofFilter)
			if okItem then
				berhasil += 1
			else
				gagal += 1
			end
			setSpoofOutcome(berhasil > 0 and gagal == 0, i / #ids)
			if i < #ids then
				task.wait(0.35)
			end
		end

		local allOk = (berhasil > 0 and gagal == 0)
		setSpoofOutcome(allOk, 1)
		notify("Spoof", allOk and "Berhasil." or "Gagal.")
		isSpoofing = false
	end)
end)

-- Upload Asset (Multipart ala Python requests files+data, fallback JSON)
local isUploading = false
UploadActionBtn.MouseButton1Click:Connect(function()
	if isUploading then return end
	local apiKey = trim(CONFIG.ApiKey)
	if apiKey == "" then
		setUploadOutcome(false, 0)
		notify("Upload", "Gagal.")
		return
	end

	local assetName = trim(UploadNameBox.Text)
	if assetName == "" then assetName = "IkyyAsset_" .. tostring(os.time()) end
	local assetType = trim(UploadTypeBox.Text)
	if assetType == "" then assetType = "Model" end
	local creatorIdNum = tonumber(trim(UploadCreatorBox.Text):match("%d+")) or LocalPlayer.UserId
	local isGroup = (trim(UploadOwnerModeBox.Text):lower() == "group")

	local rawInput = trim(UploadPayloadBox.Text)
	local payloadData = "-- Exported via Ikyy Plugin Studio Lite"
	local uploadFilename = assetName:gsub("[^%w_%-]", "_") .. ".lua"

	if rawInput ~= "" then
		local loaded = loadTextFile(rawInput)
		if loaded then
			payloadData = loaded
			local baseName = rawInput:match("([^/\\]+)$")
			if baseName and baseName ~= "" then
				uploadFilename = baseName
			end
		else
			payloadData = rawInput
		end
	end

	isUploading = true
	task.spawn(function()
		local creatorObj = isGroup and { groupId = creatorIdNum } or { userId = creatorIdNum }
		local requestPayloadJson = HttpService:JSONEncode({
			assetType = assetType,
			displayName = assetName,
			description = "Uploaded via Plugin Studio Lite by Ikyy",
			creationContext = {
				creator = creatorObj,
			},
		})

		local multipartBody, contentTypeHeader = buildMultipartAssetBody(requestPayloadJson, payloadData, uploadFilename)
		local res, ok = apiRequest({
			Url = "https://apis.roblox.com/assets/v1/assets",
			Method = "POST",
			Headers = {
				["x-api-key"] = apiKey,
				["Content-Type"] = contentTypeHeader,
			},
			Body = multipartBody,
			Retries = 2,
		})

		if not ok then
			res, ok = apiRequest({
				Url = "https://apis.roblox.com/assets/v1/assets",
				Method = "POST",
				Headers = {
					["x-api-key"] = apiKey,
					["Content-Type"] = "application/json",
				},
				Body = HttpService:JSONEncode({
					assetType = assetType,
					displayName = assetName,
					description = "Uploaded via Plugin Studio Lite by Ikyy",
					creationContext = { creator = creatorObj },
					payload = payloadData,
				}),
				Retries = 1,
			})
		end

		if ok and res then
			saveTextFile("Uploads/upload_" .. tostring(os.time()) .. ".json", tostring(res.Body or ""))
			setUploadOutcome(true, 1)
			notify("Upload", "Berhasil.")
		else
			setUploadOutcome(false, 0)
			notify("Upload", "Gagal.")
		end
		isUploading = false
	end)
end)

-- Place Maker (Loop jumlah + X-CSRF-Token retry ala Python)
local isCreatingPlace = false
CreatePlaceBtn.MouseButton1Click:Connect(function()
	if isCreatingPlace then return end
	local cookieVal = normalizeCookie(CONFIG.Cookie)
	if cookieVal == "" then
		setToolsOutcome(false, 0)
		notify("Place Maker", "Gagal.")
		return
	end

	local tplId = tonumber(trim(TemplateIdBox.Text):match("%d+")) or 95206881
	local grpId = tonumber(trim(GroupIdBox.Text):match("%d+"))
	local count = math.clamp(tonumber(trim(PlaceCountBox.Text):match("%d+")) or 1, 1, 50)

	isCreatingPlace = true
	task.spawn(function()
		local csrf = ""
		local sukses, gagal = 0, 0

		for i = 1, count do
			local bodyTbl: {[string]: any} = { templatePlaceId = tplId }
			if grpId and grpId > 0 then
				bodyTbl.groupId = grpId
			end
			local jsonBody = HttpService:JSONEncode(bodyTbl)

			local function sendCreateRequest(token: string)
				local hdrs: {[string]: string} = {
					["Cookie"] = ".ROBLOSECURITY=" .. cookieVal,
					["Content-Type"] = "application/json",
					["Origin"] = "https://create.roblox.com",
					["Referer"] = "https://create.roblox.com/",
				}
				if token ~= "" then
					hdrs["X-CSRF-TOKEN"] = token
				end
				return apiRequest({
					Url = "https://apis.roblox.com/universes/v1/universes/create",
					Method = "POST",
					Headers = hdrs,
					Body = jsonBody,
					Retries = 1,
				})
			end

			local res, ok = sendCreateRequest(csrf)
			if not ok and res and tonumber(res.StatusCode) == 403 then
				local newCsrf = getHeaderCaseInsensitive(res.Headers, "x-csrf-token")
				if newCsrf and newCsrf ~= "" then
					csrf = newCsrf
					res, ok = sendCreateRequest(csrf)
				end
			end

			if ok and res then
				sukses += 1
				saveTextFile("Logs/place_" .. tostring(os.time()) .. "_" .. tostring(i) .. ".json", tostring(res.Body or ""))
			else
				gagal += 1
			end

			setToolsOutcome(sukses > 0 and gagal == 0, i / count)
			if i < count then
				task.wait(1)
			end
		end

		local allOk = (sukses > 0 and gagal == 0)
		setToolsOutcome(allOk, 1)
		notify("Place Maker", allOk and "Berhasil." or "Gagal.")
		isCreatingPlace = false
	end)
end)

-- Asset Permissions (Batch 50 ID per request ala Python)
local isGrantingPerm = false
GrantPermBtn.MouseButton1Click:Connect(function()
	if isGrantingPerm then return end
	local apiKey = trim(CONFIG.ApiKey)
	if apiKey == "" then
		setToolsOutcome(false, 0)
		notify("Permissions", "Gagal.")
		return
	end

	local univId = trim(TargetUniverseBox.Text):match("%d+")
	local ids = parseIds(PermIdsBox.Text)
	if not univId or #ids == 0 then
		setToolsOutcome(false, 0)
		notify("Permissions", "Gagal.")
		return
	end

	isGrantingPerm = true
	task.spawn(function()
		local batchSize = 50
		local totalBatches = math.ceil(#ids / batchSize)
		local suksesBatch, gagalBatch = 0, 0
		local bIdx = 0

		for i = 1, #ids, batchSize do
			bIdx += 1
			local reqList = {}
			for j = i, math.min(i + batchSize - 1, #ids) do
				local numId = tonumber(ids[j])
				if numId then
					table.insert(reqList, { assetId = numId })
				end
			end

			local res, ok = apiRequest({
				Url = "https://apis.roblox.com/asset-permissions-api/v1/assets/permissions",
				Method = "PATCH",
				Headers = {
					["x-api-key"] = apiKey,
					["Content-Type"] = "application/json",
				},
				Body = HttpService:JSONEncode({
					subjectType = "Universe",
					subjectId = tostring(univId),
					action = "Use",
					requests = reqList,
				}),
				Retries = 2,
			})

			if ok and res then
				suksesBatch += 1
				saveTextFile("Logs/perm_" .. tostring(os.time()) .. "_" .. tostring(bIdx) .. ".json", tostring(res.Body or ""))
			else
				gagalBatch += 1
			end

			setToolsOutcome(suksesBatch > 0 and gagalBatch == 0, bIdx / totalBatches)
			if i + batchSize <= #ids then
				task.wait(1)
			end
		end

		local allOk = (suksesBatch > 0 and gagalBatch == 0)
		setToolsOutcome(allOk, 1)
		notify("Permissions", allOk and "Berhasil." or "Gagal.")
		isGrantingPerm = false
	end)
end)
