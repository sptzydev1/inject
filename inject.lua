--!strict
-- Plugin Studio Lite (Delta Executor Edition) by Ikyy
-- Mendukung: Spoof (Audio/RBXM), Upload Asset, Place Maker, Asset Permissions, Setting, serta Minimize ke Ikon Lingkaran Profile User

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Hapus GUI lama jika execute ulang
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
}

local function hasFileIO(): boolean
	return type(writefile) == "function" and type(readfile) == "function" and type(isfolder) == "function" and type(makefolder) == "function"
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

local function saveTextFile(relPath: string, content: string)
	if not hasFileIO() then return end
	ensureFolders()
	pcall(writefile, CONFIG.WorkspaceRoot .. "/" .. relPath, content)
end

local function loadTextFile(relPath: string): string?
	if not hasFileIO() then return nil end
	local fullPath = CONFIG.WorkspaceRoot .. "/" .. relPath
	local ok, res = pcall(function()
		if isfile and isfile(fullPath) then
			return readfile(fullPath)
		end
		return nil
	end)
	if ok and type(res) == "string" then
		return res
	end
	return nil
end

-- Muat cookie & api key tersimpan jika ada
local savedCookie = loadTextFile("cookie.txt")
local savedApiKey = loadTextFile("apikey.txt")
if savedCookie and savedCookie ~= "" then CONFIG.Cookie = savedCookie end
if savedApiKey and savedApiKey ~= "" then CONFIG.ApiKey = savedApiKey end

local function getHttpFunc()
	if type(request) == "function" then return request end
	if type(http_request) == "function" then return http_request end
	if syn and type(syn.request) == "function" then return syn.request end
	if http and type(http.request) == "function" then return http.request end
	return nil
end

local function httpRequest(options: {Url: string, Method: string?, Headers: {[string]: string}?, Body: string?})
	local reqFn = getHttpFunc()
	if not reqFn then
		return nil, "HTTP Executor function tidak tersedia."
	end
	local ok, res = pcall(reqFn, {
		Url = options.Url,
		Method = options.Method or "GET",
		Headers = options.Headers or {},
		Body = options.Body,
	})
	if not ok then
		return nil, tostring(res)
	end
	return res, nil
end

-- Ambil Avatar Thumbnail User untuk Ikon Lingkaran saat Close/Minimize
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
-- PEMBUATAN UI (GAYA PLUGIN STUDIO LITE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IkyyPluginStudioLite_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- 1. IKON LINGKARAN PROFILE USER (MUNCUL SAAT GUI DI-CLOSE / MINIMIZE)
local FloatingProfileBtn = Instance.new("ImageButton")
FloatingProfileBtn.Name = "FloatingProfileToggle"
FloatingProfileBtn.Size = UDim2.fromOffset(58, 58)
FloatingProfileBtn.Position = UDim2.new(0.5, -29, 0.08, 0)
FloatingProfileBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
FloatingProfileBtn.BorderSizePixel = 0
FloatingProfileBtn.Visible = false
FloatingProfileBtn.ZIndex = 50
FloatingProfileBtn.Image = getUserAvatarAsync(LocalPlayer.UserId)
FloatingProfileBtn.Parent = ScreenGui

local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatingProfileBtn

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Color = Color3.fromRGB(130, 92, 255)
FloatStroke.Thickness = 2.5
FloatStroke.Parent = FloatingProfileBtn

-- Badge kecil status execute di pojok lingkaran
local BadgeDot = Instance.new("Frame")
BadgeDot.Size = UDim2.fromOffset(14, 14)
BadgeDot.Position = UDim2.new(1, -15, 1, -15)
BadgeDot.BackgroundColor3 = Color3.fromRGB(56, 239, 125)
BadgeDot.BorderSizePixel = 0
BadgeDot.ZIndex = 52
BadgeDot.Parent = FloatingProfileBtn

local BadgeCorner = Instance.new("UICorner")
BadgeCorner.CornerRadius = UDim.new(1, 0)
BadgeCorner.Parent = BadgeDot

local BadgeStroke = Instance.new("UIStroke")
BadgeStroke.Color = Color3.fromRGB(18, 16, 28)
BadgeStroke.Thickness = 2
BadgeStroke.Parent = BadgeDot

-- 2. WINDOW UTAMA
local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = UDim2.fromOffset(660, 385)
MainWindow.Position = UDim2.new(0.5, -330, 0.5, -192)
MainWindow.BackgroundColor3 = Color3.fromRGB(16, 15, 24)
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainWindow

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(92, 72, 168)
MainStroke.Thickness = 1.6
MainStroke.Transparency = 0.25
MainStroke.Parent = MainWindow

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 20, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 12, 20)),
})
MainGradient.Rotation = 135
MainGradient.Parent = MainWindow

-- Helper Dragging untuk Frame
local function makeDraggable(dragHandle: GuiObject, targetFrame: GuiObject)
	local dragging = false
	local dragInput: InputObject? = nil
	local dragStart = Vector2.zero
	local startPos = UDim2.new()

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

-- ==========================================
-- HEADER BAR (KIRI: ICON + JUDUL, KANAN: TOMBOL X)
-- ==========================================
local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 58)
HeaderBar.BackgroundColor3 = Color3.fromRGB(20, 19, 30)
HeaderBar.BackgroundTransparency = 0.25
HeaderBar.BorderSizePixel = 0
HeaderBar.Parent = MainWindow

local HeaderLogoBox = Instance.new("Frame")
HeaderLogoBox.Size = UDim2.fromOffset(36, 36)
HeaderLogoBox.Position = UDim2.new(0, 16, 0.5, -18)
HeaderLogoBox.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
HeaderLogoBox.BorderSizePixel = 0
HeaderLogoBox.Parent = HeaderBar

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 10)
LogoCorner.Parent = HeaderLogoBox

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Color3.fromRGB(95, 85, 145)
LogoStroke.Thickness = 1
LogoStroke.Parent = HeaderLogoBox

local LogoIcon = Instance.new("TextLabel")
LogoIcon.Size = UDim2.fromScale(1, 1)
LogoIcon.BackgroundTransparency = 1
LogoIcon.Text = "⇄"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 18
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 260, 0, 14)
SubTitleLabel.Position = UDim2.new(0, 62, 0, 9)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • DELTA EDITION"
SubTitleLabel.TextColor3 = Color3.fromRGB(130, 126, 155)
SubTitleLabel.TextSize = 9
SubTitleLabel.Font = Enum.Font.GothamBold
SubTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubTitleLabel.Parent = HeaderBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 300, 0, 20)
TitleLabel.Position = UDim2.new(0, 62, 0, 21)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Plugin Studio Lite"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(0, 300, 0, 14)
MetaLabel.Position = UDim2.new(0, 62, 0, 40)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "by Ikyy  •  v1.0  •  @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
MetaLabel.TextSize = 10
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.Parent = HeaderBar

-- Tombol Close (X) -> Mengecil menjadi Ikon Lingkaran Profile User
local CloseCircleBtn = Instance.new("TextButton")
CloseCircleBtn.Name = "CloseToCircleBtn"
CloseCircleBtn.Size = UDim2.fromOffset(34, 34)
CloseCircleBtn.Position = UDim2.new(1, -50, 0.5, -17)
CloseCircleBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 50)
CloseCircleBtn.Text = "✕"
CloseCircleBtn.TextColor3 = Color3.fromRGB(220, 218, 238)
CloseCircleBtn.TextSize = 14
CloseCircleBtn.Font = Enum.Font.GothamBold
CloseCircleBtn.AutoButtonColor = true
CloseCircleBtn.Parent = HeaderBar

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(1, 0)
CloseBtnCorner.Parent = CloseCircleBtn

local CloseBtnStroke = Instance.new("UIStroke")
CloseBtnStroke.Color = Color3.fromRGB(85, 80, 120)
CloseBtnStroke.Thickness = 1
CloseBtnStroke.Parent = CloseCircleBtn

local function setMinimized(minimized: boolean)
	CONFIG.IsMinimized = minimized
	if minimized then
		local tween = TweenService:Create(MainWindow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(58, 58),
		})
		tween:Play()
		tween.Completed:Connect(function()
			if CONFIG.IsMinimized then
				MainWindow.Visible = false
				FloatingProfileBtn.Position = MainWindow.Position
				FloatingProfileBtn.Visible = true
			end
		end)
	else
		FloatingProfileBtn.Visible = false
		MainWindow.Position = FloatingProfileBtn.Position
		MainWindow.Size = UDim2.fromOffset(58, 58)
		MainWindow.Visible = true
		TweenService:Create(MainWindow, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(660, 385),
		}):Play()
	end
end

CloseCircleBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

FloatingProfileBtn.MouseButton1Click:Connect(function()
	setMinimized(false)
end)

makeDraggable(HeaderBar, MainWindow)
makeDraggable(FloatingProfileBtn, FloatingProfileBtn)

-- ==========================================
-- SIDEBAR KIRI (SPOOF, UPLOAD, PLACE, PERM, SETTING + AKSI CEPAT)
-- ==========================================
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 152, 1, -68)
Sidebar.Position = UDim2.new(0, 12, 0, 62)
Sidebar.BackgroundColor3 = Color3.fromRGB(21, 20, 32)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

local SidebarStroke = Instance.new("UIStroke")
SidebarStroke.Color = Color3.fromRGB(52, 48, 82)
SidebarStroke.Thickness = 1
SidebarStroke.Parent = Sidebar

local NavList = Instance.new("Frame")
NavList.Size = UDim2.new(1, -12, 0, 218)
NavList.Position = UDim2.new(0, 6, 0, 8)
NavList.BackgroundTransparency = 1
NavList.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 5)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavList

local tabPages: {[string]: Frame} = {}
local tabButtons: {[string]: TextButton} = {}

local function createNavButton(name: string, label: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = "Nav_" .. name
	btn.Size = UDim2.new(1, 0, 0, 38)
	btn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
	btn.Text = "  " .. label
	btn.TextColor3 = Color3.fromRGB(185, 182, 210)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Parent = NavList

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	tabButtons[name] = btn
	return btn
end

-- Aksi Cepat di bagian bawah Sidebar (seperti pada gambar: Cek Koneksi & Sembunyi)
local QuickTitle = Instance.new("TextLabel")
QuickTitle.Size = UDim2.new(1, -16, 0, 16)
QuickTitle.Position = UDim2.new(0, 10, 1, -72)
QuickTitle.BackgroundTransparency = 1
QuickTitle.Text = "Aksi Cepat"
QuickTitle.TextColor3 = Color3.fromRGB(140, 136, 168)
QuickTitle.TextSize = 10
QuickTitle.Font = Enum.Font.GothamMedium
QuickTitle.TextXAlignment = Enum.TextXAlignment.Left
QuickTitle.Parent = Sidebar

local CekKoneksiBtn = Instance.new("TextButton")
CekKoneksiBtn.Size = UDim2.new(0, 66, 0, 34)
CekKoneksiBtn.Position = UDim2.new(0, 8, 1, -46)
CekKoneksiBtn.BackgroundColor3 = Color3.fromRGB(64, 118, 240)
CekKoneksiBtn.Text = "Cek Koneksi"
CekKoneksiBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CekKoneksiBtn.TextSize = 10
CekKoneksiBtn.Font = Enum.Font.GothamBold
CekKoneksiBtn.Parent = Sidebar

local CekCorner = Instance.new("UICorner")
CekCorner.CornerRadius = UDim.new(0, 8)
CekCorner.Parent = CekKoneksiBtn

local SembunyiBtn = Instance.new("TextButton")
SembunyiBtn.Size = UDim2.new(0, 64, 0, 34)
SembunyiBtn.Position = UDim2.new(1, -72, 1, -46)
SembunyiBtn.BackgroundColor3 = Color3.fromRGB(32, 31, 48)
SembunyiBtn.Text = "Sembunyi"
SembunyiBtn.TextColor3 = Color3.fromRGB(215, 212, 235)
SembunyiBtn.TextSize = 10
SembunyiBtn.Font = Enum.Font.GothamBold
SembunyiBtn.Parent = Sidebar

local SembunyiCorner = Instance.new("UICorner")
SembunyiCorner.CornerRadius = UDim.new(0, 8)
SembunyiCorner.Parent = SembunyiBtn

local SembunyiStroke = Instance.new("UIStroke")
SembunyiStroke.Color = Color3.fromRGB(70, 66, 102)
SembunyiStroke.Thickness = 1
SembunyiStroke.Parent = SembunyiBtn

SembunyiBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

-- ==========================================
-- AREA KONTEN KANAN
-- ==========================================
local ContentArea = Instance.new("Frame")
ContentArea.Name = "ContentArea"
ContentArea.Size = UDim2.new(1, -182, 1, -68)
ContentArea.Position = UDim2.new(0, 172, 0, 62)
ContentArea.BackgroundColor3 = Color3.fromRGB(20, 19, 30)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainWindow

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 12)
ContentCorner.Parent = ContentArea

local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = Color3.fromRGB(52, 48, 82)
ContentStroke.Thickness = 1
ContentStroke.Parent = ContentArea

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
-- HALAMAN 1: SPOOF (SUSUNAN PERSIS SEPERTI GAMBAR)
-- ==========================================
local SpoofPage = Instance.new("Frame")
SpoofPage.Size = UDim2.fromScale(1, 1)
SpoofPage.BackgroundTransparency = 1
SpoofPage.Visible = true
SpoofPage.Parent = ContentArea
tabPages["Spoof"] = SpoofPage

local SpoofTitle = Instance.new("TextLabel")
SpoofTitle.Size = UDim2.new(1, -24, 0, 22)
SpoofTitle.Position = UDim2.new(0, 14, 0, 10)
SpoofTitle.BackgroundTransparency = 1
SpoofTitle.Text = "Spoof"
SpoofTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SpoofTitle.TextSize = 16
SpoofTitle.Font = Enum.Font.GothamBold
SpoofTitle.TextXAlignment = Enum.TextXAlignment.Left
SpoofTitle.Parent = SpoofPage

local SpoofDesc = Instance.new("TextLabel")
SpoofDesc.Size = UDim2.new(1, -24, 0, 16)
SpoofDesc.Position = UDim2.new(0, 14, 0, 31)
SpoofDesc.BackgroundTransparency = 1
SpoofDesc.Text = "Asset ID lama jadi ID baru milikmu"
SpoofDesc.TextColor3 = Color3.fromRGB(145, 142, 170)
SpoofDesc.TextSize = 11
SpoofDesc.Font = Enum.Font.Gotham
SpoofDesc.TextXAlignment = Enum.TextXAlignment.Left
SpoofDesc.Parent = SpoofPage

local AssetIdHeader = Instance.new("TextLabel")
AssetIdHeader.Size = UDim2.new(1, -24, 0, 16)
AssetIdHeader.Position = UDim2.new(0, 14, 0, 54)
AssetIdHeader.BackgroundTransparency = 1
AssetIdHeader.Text = "｜ ASSET ID"
AssetIdHeader.TextColor3 = Color3.fromRGB(175, 172, 205)
AssetIdHeader.TextSize = 11
AssetIdHeader.Font = Enum.Font.GothamBold
AssetIdHeader.TextXAlignment = Enum.TextXAlignment.Left
AssetIdHeader.Parent = SpoofPage

local AssetIdBox = Instance.new("TextBox")
AssetIdBox.Size = UDim2.new(1, -28, 0, 82)
AssetIdBox.Position = UDim2.new(0, 14, 0, 74)
AssetIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetIdBox.Text = ""
AssetIdBox.PlaceholderText = "Tempel Asset ID di sini (pisah spasi, koma, atau baris baru)"
AssetIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetIdBox.TextSize = 12
AssetIdBox.Font = Enum.Font.Gotham
AssetIdBox.TextXAlignment = Enum.TextXAlignment.Left
AssetIdBox.TextYAlignment = Enum.TextYAlignment.Top
AssetIdBox.ClearTextOnFocus = false
AssetIdBox.MultiLine = true
AssetIdBox.TextWrapped = true
AssetIdBox.Parent = SpoofPage

local AssetIdCorner = Instance.new("UICorner")
AssetIdCorner.CornerRadius = UDim.new(0, 10)
AssetIdCorner.Parent = AssetIdBox

local AssetIdStroke = Instance.new("UIStroke")
AssetIdStroke.Color = Color3.fromRGB(65, 60, 102)
AssetIdStroke.Thickness = 1
AssetIdStroke.Parent = AssetIdBox

-- Baris Filter Tipe: Auto | Audio | Decal | Model | Anim
local FilterRow = Instance.new("Frame")
FilterRow.Size = UDim2.new(1, -28, 0, 30)
FilterRow.Position = UDim2.new(0, 14, 0, 164)
FilterRow.BackgroundTransparency = 1
FilterRow.Parent = SpoofPage

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 8)
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
	fBtn.Size = UDim2.new(0.2, -7, 1, 0)
	fBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
	fBtn.Text = fName
	fBtn.TextColor3 = Color3.fromRGB(165, 162, 190)
	fBtn.TextSize = 11
	fBtn.Font = Enum.Font.GothamMedium
	fBtn.AutoButtonColor = false
	fBtn.Parent = FilterRow

	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 8)
	fc.Parent = fBtn

	local fs = Instance.new("UIStroke")
	fs.Color = Color3.fromRGB(62, 58, 92)
	fs.Thickness = 1
	fs.Parent = fBtn

	filterButtons[fName] = fBtn
	fBtn.MouseButton1Click:Connect(function()
		setFilter(fName)
	end)
end
setFilter("Auto")

-- Tombol Utama: SPOOF SEKARANG (Ungu) & BERSIHKAN
local SpoofNowBtn = Instance.new("TextButton")
SpoofNowBtn.Size = UDim2.new(0.62, -18, 0, 42)
SpoofNowBtn.Position = UDim2.new(0, 14, 0, 204)
SpoofNowBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SpoofNowBtn.Text = "⇄  SPOOF SEKARANG"
SpoofNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpoofNowBtn.TextSize = 12
SpoofNowBtn.Font = Enum.Font.GothamBold
SpoofNowBtn.Parent = SpoofPage

local SpoofNowCorner = Instance.new("UICorner")
SpoofNowCorner.CornerRadius = UDim.new(0, 10)
SpoofNowCorner.Parent = SpoofNowBtn

local BersihkanBtn = Instance.new("TextButton")
BersihkanBtn.Size = UDim2.new(0.38, -14, 0, 42)
BersihkanBtn.Position = UDim2.new(0.62, 4, 0, 204)
BersihkanBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
BersihkanBtn.Text = "BERSIHKAN"
BersihkanBtn.TextColor3 = Color3.fromRGB(210, 208, 232)
BersihkanBtn.TextSize = 11
BersihkanBtn.Font = Enum.Font.GothamBold
BersihkanBtn.Parent = SpoofPage

local BersihkanCorner = Instance.new("UICorner")
BersihkanCorner.CornerRadius = UDim.new(0, 10)
BersihkanCorner.Parent = BersihkanBtn

local BersihkanStroke = Instance.new("UIStroke")
BersihkanStroke.Color = Color3.fromRGB(68, 64, 100)
BersihkanStroke.Thickness = 1
BersihkanStroke.Parent = BersihkanBtn

-- Panel Status "Siap." di bagian bawah
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -28, 0, 52)
StatusBox.Position = UDim2.new(0, 14, 0, 255)
StatusBox.BackgroundColor3 = Color3.fromRGB(15, 14, 23)
StatusBox.BorderSizePixel = 0
StatusBox.Parent = SpoofPage

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 10)
StatusCorner.Parent = StatusBox

local StatusStroke = Instance.new("UIStroke")
StatusStroke.Color = Color3.fromRGB(58, 54, 88)
StatusStroke.Thickness = 1
StatusStroke.Parent = StatusBox

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 24)
StatusLabel.Position = UDim2.new(0, 10, 0, 4)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Siap."
StatusLabel.TextColor3 = Color3.fromRGB(175, 172, 200)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = StatusBox

local ProgressTrack = Instance.new("Frame")
ProgressTrack.Size = UDim2.new(1, -20, 0, 4)
ProgressTrack.Position = UDim2.new(0, 10, 1, -12)
ProgressTrack.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
ProgressTrack.BorderSizePixel = 0
ProgressTrack.Parent = StatusBox

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressTrack

local function setStatus(msg: string, ratio: number)
	StatusLabel.Text = msg
	local clamped = math.clamp(ratio, 0, 1)
	TweenService:Create(ProgressFill, TweenInfo.new(0.2), {
		Size = UDim2.new(clamped, 0, 1, 0),
	}):Play()
end

BersihkanBtn.MouseButton1Click:Connect(function()
	AssetIdBox.Text = ""
	setStatus("Siap.", 0)
end)

-- ==========================================
-- HALAMAN 2: UPLOAD ASSET (OPEN CLOUD API)
-- ==========================================
local UploadPage = Instance.new("Frame")
UploadPage.Size = UDim2.fromScale(1, 1)
UploadPage.BackgroundTransparency = 1
UploadPage.Visible = false
UploadPage.Parent = ContentArea
tabPages["Upload"] = UploadPage

local UploadTitle = Instance.new("TextLabel")
UploadTitle.Size = UDim2.new(1, -24, 0, 22)
UploadTitle.Position = UDim2.new(0, 14, 0, 10)
UploadTitle.BackgroundTransparency = 1
UploadTitle.Text = "Upload Asset"
UploadTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
UploadTitle.TextSize = 16
UploadTitle.Font = Enum.Font.GothamBold
UploadTitle.TextXAlignment = Enum.TextXAlignment.Left
UploadTitle.Parent = UploadPage

local UploadNameBox = Instance.new("TextBox")
UploadNameBox.Size = UDim2.new(0.48, -16, 0, 34)
UploadNameBox.Position = UDim2.new(0, 14, 0, 42)
UploadNameBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadNameBox.PlaceholderText = "Nama Asset (contoh: IkyyAsset)"
UploadNameBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadNameBox.Text = ""
UploadNameBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadNameBox.TextSize = 11
UploadNameBox.Font = Enum.Font.Gotham
UploadNameBox.Parent = UploadPage
Instance.new("UICorner", UploadNameBox).CornerRadius = UDim.new(0, 8)

local UploadTypeBox = Instance.new("TextBox")
UploadTypeBox.Size = UDim2.new(0.48, -16, 0, 34)
UploadTypeBox.Position = UDim2.new(0.52, 2, 0, 42)
UploadTypeBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadTypeBox.PlaceholderText = "Tipe: Audio / Model / Animation / Decal"
UploadTypeBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadTypeBox.Text = "Model"
UploadTypeBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadTypeBox.TextSize = 11
UploadTypeBox.Font = Enum.Font.Gotham
UploadTypeBox.Parent = UploadPage
Instance.new("UICorner", UploadTypeBox).CornerRadius = UDim.new(0, 8)

local UploadCreatorBox = Instance.new("TextBox")
UploadCreatorBox.Size = UDim2.new(1, -28, 0, 34)
UploadCreatorBox.Position = UDim2.new(0, 14, 0, 84)
UploadCreatorBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadCreatorBox.PlaceholderText = "Creator ID (User ID atau Group ID)"
UploadCreatorBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadCreatorBox.Text = tostring(LocalPlayer.UserId)
UploadCreatorBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadCreatorBox.TextSize = 11
UploadCreatorBox.Font = Enum.Font.Gotham
UploadCreatorBox.Parent = UploadPage
Instance.new("UICorner", UploadCreatorBox).CornerRadius = UDim.new(0, 8)

local UploadPayloadBox = Instance.new("TextBox")
UploadPayloadBox.Size = UDim2.new(1, -28, 0, 96)
UploadPayloadBox.Position = UDim2.new(0, 14, 0, 126)
UploadPayloadBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadPayloadBox.PlaceholderText = "Tempel path file workspace atau isi RBXM/JSON/URL..."
UploadPayloadBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadPayloadBox.Text = ""
UploadPayloadBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadPayloadBox.TextSize = 11
UploadPayloadBox.Font = Enum.Font.Gotham
UploadPayloadBox.MultiLine = true
UploadPayloadBox.TextWrapped = true
UploadPayloadBox.TextXAlignment = Enum.TextXAlignment.Left
UploadPayloadBox.TextYAlignment = Enum.TextYAlignment.Top
UploadPayloadBox.Parent = UploadPage
Instance.new("UICorner", UploadPayloadBox).CornerRadius = UDim.new(0, 8)

local UploadActionBtn = Instance.new("TextButton")
UploadActionBtn.Size = UDim2.new(1, -28, 0, 38)
UploadActionBtn.Position = UDim2.new(0, 14, 0, 232)
UploadActionBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
UploadActionBtn.Text = "⬆  UPLOAD KE OPEN CLOUD"
UploadActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UploadActionBtn.TextSize = 12
UploadActionBtn.Font = Enum.Font.GothamBold
UploadActionBtn.Parent = UploadPage
Instance.new("UICorner", UploadActionBtn).CornerRadius = UDim.new(0, 10)

local UploadLogLabel = Instance.new("TextLabel")
UploadLogLabel.Size = UDim2.new(1, -28, 0, 32)
UploadLogLabel.Position = UDim2.new(0, 14, 0, 276)
UploadLogLabel.BackgroundColor3 = Color3.fromRGB(15, 14, 23)
UploadLogLabel.Text = "Status Upload: Menunggu input & API Key."
UploadLogLabel.TextColor3 = Color3.fromRGB(175, 172, 200)
UploadLogLabel.TextSize = 10
UploadLogLabel.Font = Enum.Font.Gotham
UploadLogLabel.TextXAlignment = Enum.TextXAlignment.Left
UploadLogLabel.TextWrapped = true
UploadLogLabel.Parent = UploadPage
Instance.new("UICorner", UploadLogLabel).CornerRadius = UDim.new(0, 8)

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
ToolsTitle.Size = UDim2.new(1, -24, 0, 22)
ToolsTitle.Position = UDim2.new(0, 14, 0, 10)
ToolsTitle.BackgroundTransparency = 1
ToolsTitle.Text = "Place Maker & Permissions"
ToolsTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ToolsTitle.TextSize = 15
ToolsTitle.Font = Enum.Font.GothamBold
ToolsTitle.TextXAlignment = Enum.TextXAlignment.Left
ToolsTitle.Parent = ToolsPage

local TemplateIdBox = Instance.new("TextBox")
TemplateIdBox.Size = UDim2.new(0.48, -16, 0, 34)
TemplateIdBox.Position = UDim2.new(0, 14, 0, 42)
TemplateIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TemplateIdBox.Text = "95206881" -- Baseplate
TemplateIdBox.PlaceholderText = "Template Place ID"
TemplateIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TemplateIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TemplateIdBox.TextSize = 11
TemplateIdBox.Font = Enum.Font.Gotham
TemplateIdBox.Parent = ToolsPage
Instance.new("UICorner", TemplateIdBox).CornerRadius = UDim.new(0, 8)

local GroupIdBox = Instance.new("TextBox")
GroupIdBox.Size = UDim2.new(0.48, -16, 0, 34)
GroupIdBox.Position = UDim2.new(0.52, 2, 0, 42)
GroupIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
GroupIdBox.Text = ""
GroupIdBox.PlaceholderText = "Group ID (Opsional)"
GroupIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
GroupIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
GroupIdBox.TextSize = 11
GroupIdBox.Font = Enum.Font.Gotham
GroupIdBox.Parent = ToolsPage
Instance.new("UICorner", GroupIdBox).CornerRadius = UDim.new(0, 8)

local CreatePlaceBtn = Instance.new("TextButton")
CreatePlaceBtn.Size = UDim2.new(1, -28, 0, 36)
CreatePlaceBtn.Position = UDim2.new(0, 14, 0, 84)
CreatePlaceBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
CreatePlaceBtn.Text = "🏗  BUAT UNIVERSE / PLACE (BUTUH COOKIE)"
CreatePlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreatePlaceBtn.TextSize = 11
CreatePlaceBtn.Font = Enum.Font.GothamBold
CreatePlaceBtn.Parent = ToolsPage
Instance.new("UICorner", CreatePlaceBtn).CornerRadius = UDim.new(0, 9)

local TargetUniverseBox = Instance.new("TextBox")
TargetUniverseBox.Size = UDim2.new(1, -28, 0, 34)
TargetUniverseBox.Position = UDim2.new(0, 14, 0, 130)
TargetUniverseBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TargetUniverseBox.Text = CONFIG.DefaultUniverseId
TargetUniverseBox.PlaceholderText = "Target Universe ID untuk Permission"
TargetUniverseBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TargetUniverseBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TargetUniverseBox.TextSize = 11
TargetUniverseBox.Font = Enum.Font.Gotham
TargetUniverseBox.Parent = ToolsPage
Instance.new("UICorner", TargetUniverseBox).CornerRadius = UDim.new(0, 8)

local PermIdsBox = Instance.new("TextBox")
PermIdsBox.Size = UDim2.new(1, -28, 0, 56)
PermIdsBox.Position = UDim2.new(0, 14, 0, 170)
PermIdsBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PermIdsBox.Text = ""
PermIdsBox.PlaceholderText = "Asset IDs untuk Grant Permission (pisah koma/spasi/baris)"
PermIdsBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PermIdsBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PermIdsBox.TextSize = 11
PermIdsBox.Font = Enum.Font.Gotham
PermIdsBox.MultiLine = true
PermIdsBox.TextWrapped = true
PermIdsBox.TextXAlignment = Enum.TextXAlignment.Left
PermIdsBox.TextYAlignment = Enum.TextYAlignment.Top
PermIdsBox.Parent = ToolsPage
Instance.new("UICorner", PermIdsBox).CornerRadius = UDim.new(0, 8)

local GrantPermBtn = Instance.new("TextButton")
GrantPermBtn.Size = UDim2.new(1, -28, 0, 36)
GrantPermBtn.Position = UDim2.new(0, 14, 0, 234)
GrantPermBtn.BackgroundColor3 = Color3.fromRGB(48, 45, 74)
GrantPermBtn.Text = "🔑  GRANT ASSET PERMISSIONS KE UNIVERSE"
GrantPermBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
GrantPermBtn.TextSize = 11
GrantPermBtn.Font = Enum.Font.GothamBold
GrantPermBtn.Parent = ToolsPage
Instance.new("UICorner", GrantPermBtn).CornerRadius = UDim.new(0, 9)

local ToolsStatusLabel = Instance.new("TextLabel")
ToolsStatusLabel.Size = UDim2.new(1, -28, 0, 28)
ToolsStatusLabel.Position = UDim2.new(0, 14, 0, 276)
ToolsStatusLabel.BackgroundColor3 = Color3.fromRGB(15, 14, 23)
ToolsStatusLabel.Text = "Status Tools: Siap."
ToolsStatusLabel.TextColor3 = Color3.fromRGB(175, 172, 200)
ToolsStatusLabel.TextSize = 10
ToolsStatusLabel.Font = Enum.Font.Gotham
ToolsStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
ToolsStatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
ToolsStatusLabel.Parent = ToolsPage
Instance.new("UICorner", ToolsStatusLabel).CornerRadius = UDim.new(0, 8)

-- ==========================================
-- HALAMAN 4: SETTING (COOKIE, API KEY, FOLDER)
-- ==========================================
local SettingPage = Instance.new("Frame")
SettingPage.Size = UDim2.fromScale(1, 1)
SettingPage.BackgroundTransparency = 1
SettingPage.Visible = false
SettingPage.Parent = ContentArea
tabPages["Setting"] = SettingPage

local SettingTitle = Instance.new("TextLabel")
SettingTitle.Size = UDim2.new(1, -24, 0, 22)
SettingTitle.Position = UDim2.new(0, 14, 0, 10)
SettingTitle.BackgroundTransparency = 1
SettingTitle.Text = "Pengaturan Kredensial"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 15
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local CookieBox = Instance.new("TextBox")
CookieBox.Size = UDim2.new(1, -28, 0, 62)
CookieBox.Position = UDim2.new(0, 14, 0, 42)
CookieBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
CookieBox.Text = CONFIG.Cookie
CookieBox.PlaceholderText = "Tempel .ROBLOSECURITY Cookie di sini (untuk Place Maker)..."
CookieBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
CookieBox.TextColor3 = Color3.fromRGB(235, 235, 250)
CookieBox.TextSize = 11
CookieBox.Font = Enum.Font.Gotham
CookieBox.MultiLine = true
CookieBox.TextWrapped = true
CookieBox.TextXAlignment = Enum.TextXAlignment.Left
CookieBox.TextYAlignment = Enum.TextYAlignment.Top
CookieBox.Parent = SettingPage
Instance.new("UICorner", CookieBox).CornerRadius = UDim.new(0, 8)

local ApiKeyBox = Instance.new("TextBox")
ApiKeyBox.Size = UDim2.new(1, -28, 0, 62)
ApiKeyBox.Position = UDim2.new(0, 14, 0, 114)
ApiKeyBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
ApiKeyBox.Text = CONFIG.ApiKey
ApiKeyBox.PlaceholderText = "Tempel Roblox Open Cloud API Key (x-api-key)..."
ApiKeyBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
ApiKeyBox.TextColor3 = Color3.fromRGB(235, 235, 250)
ApiKeyBox.TextSize = 11
ApiKeyBox.Font = Enum.Font.Gotham
ApiKeyBox.MultiLine = true
ApiKeyBox.TextWrapped = true
ApiKeyBox.TextXAlignment = Enum.TextXAlignment.Left
ApiKeyBox.TextYAlignment = Enum.TextYAlignment.Top
ApiKeyBox.Parent = SettingPage
Instance.new("UICorner", ApiKeyBox).CornerRadius = UDim.new(0, 8)

local SaveSettingBtn = Instance.new("TextButton")
SaveSettingBtn.Size = UDim2.new(1, -28, 0, 38)
SaveSettingBtn.Position = UDim2.new(0, 14, 0, 188)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN COOKIE & API KEY"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 12
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 10)

local SettingInfoLabel = Instance.new("TextLabel")
SettingInfoLabel.Size = UDim2.new(1, -28, 0, 56)
SettingInfoLabel.Position = UDim2.new(0, 14, 0, 236)
SettingInfoLabel.BackgroundColor3 = Color3.fromRGB(15, 14, 23)
SettingInfoLabel.Text = "Workspace: " .. CONFIG.WorkspaceRoot .. "/SPOOF\nUser: " .. LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")"
SettingInfoLabel.TextColor3 = Color3.fromRGB(165, 162, 192)
SettingInfoLabel.TextSize = 10
SettingInfoLabel.Font = Enum.Font.Gotham
SettingInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
SettingInfoLabel.TextYAlignment = Enum.TextYAlignment.Top
SettingInfoLabel.Parent = SettingPage
Instance.new("UICorner", SettingInfoLabel).CornerRadius = UDim.new(0, 8)

SaveSettingBtn.MouseButton1Click:Connect(function()
	CONFIG.Cookie = CookieBox.Text:match("^%s*(.-)%s*$") or ""
	CONFIG.ApiKey = ApiKeyBox.Text:match("^%s*(.-)%s*$") or ""
	if CONFIG.Cookie ~= "" and not CONFIG.Cookie:sub(-1) == ";" then
		CONFIG.Cookie = CONFIG.Cookie .. ";"
	end
	saveTextFile("cookie.txt", CONFIG.Cookie)
	saveTextFile("apikey.txt", CONFIG.ApiKey)
	SettingInfoLabel.Text = "✔ Tersimpan ke workspace/" .. CONFIG.WorkspaceRoot .. "\nCookie: " .. (CONFIG.Cookie ~= "" and "Terisi" or "Kosong") .. " | API Key: " .. (CONFIG.ApiKey ~= "" and "Terisi" or "Kosong")
end)

-- Buat tombol navigasi Sidebar
createNavButton("Spoof", "⇄  Spoof", 1).MouseButton1Click:Connect(function() switchTab("Spoof") end)
createNavButton("Upload", "⬆  Upload", 2).MouseButton1Click:Connect(function() switchTab("Upload") end)
createNavButton("Tools", "🛠  Place & Perm", 3).MouseButton1Click:Connect(function() switchTab("Tools") end)
createNavButton("Setting", "⚙  Setting", 4).MouseButton1Click:Connect(function() switchTab("Setting") end)
switchTab("Spoof")

-- ==========================================
-- LOGIKA EKSEKUSI FITUR
-- ==========================================
local function parseIds(raw: string): {string}
	local seen: {[string]: boolean} = {}
	local out: {string} = {}
	for digits in raw:gmatch("%d{6,}") do
		if not seen[digits] then
			seen[digits] = true
			table.insert(out, digits)
		end
	end
	return out
end

-- Cek Koneksi
CekKoneksiBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		switchTab("Spoof")
		setStatus("Memeriksa koneksi ke ygfstudio.my.id & Roblox API...", 0.25)
		local res, err = httpRequest({
			Url = CONFIG.BaseUrl .. "/tools/spoof-audio",
			Method = "GET",
			Headers = { ["User-Agent"] = "Mozilla/5.0 (Android 13; Mobile) DeltaExecutor/1.0" },
		})
		if res and res.StatusCode == 200 then
			local sessMatch = tostring(res.Body or ""):match("YGF_%d+")
			if sessMatch then
				CONFIG.SessionId = sessMatch
				saveTextFile("SPOOF/info/session.txt", CONFIG.SessionId)
			end
			setStatus("✔ Terhubung! Session: " .. CONFIG.SessionId, 1)
		else
			setStatus("⚠ Koneksi terbatas / Offline (" .. tostring(err or (res and res.StatusCode) or "N/A") .. ")", 0.1)
		end
	end)
end)

-- Eksekusi Spoof
local isSpoofing = false
SpoofNowBtn.MouseButton1Click:Connect(function()
	if isSpoofing then return end
	local ids = parseIds(AssetIdBox.Text)
	if #ids == 0 then
		setStatus("❌ Masukkan minimal 1 Asset ID yang valid!", 0)
		return
	end

	isSpoofing = true
	task.spawn(function()
		ensureFolders()
		local berhasil, gagal = 0, 0
		local isRbxmMode = (CONFIG.SpoofFilter == "Model" or CONFIG.SpoofFilter == "Anim")

		for i, assetId in ipairs(ids) do
			setStatus(string.format("[%d/%d] Spoof ID %s (%s)...", i, #ids, assetId, CONFIG.SpoofFilter), (i - 1) / #ids)

			-- Kirim command ke ygfstudio.my.id
			local cmdRes = httpRequest({
				Url = CONFIG.BaseUrl .. "/send-command",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["Origin"] = CONFIG.BaseUrl,
				},
				Body = HttpService:JSONEncode({
					id = assetId,
					session = CONFIG.SessionId,
				}),
			})

			local foundFile: string? = nil
			if cmdRes and (cmdRes.StatusCode == 200 or cmdRes.StatusCode == 201) then
				for _ = 1, 10 do
					local listRes = httpRequest({ Url = CONFIG.BaseUrl .. "/list-files", Method = "GET" })
					if listRes and listRes.StatusCode == 200 then
						local okJson, decoded = pcall(function()
							return HttpService:JSONDecode(tostring(listRes.Body or "{}"))
						end)
						if okJson and type(decoded) == "table" and type(decoded.files) == "table" then
							for _, fname in ipairs(decoded.files) do
								if tostring(fname):find(assetId, 1, true) then
									foundFile = tostring(fname)
									break
								end
							end
						end
					end
					if foundFile then break end
					task.wait(1.5)
				end
			end

			if foundFile then
				local dlRes = httpRequest({
					Url = CONFIG.BaseUrl .. "/files/" .. HttpService:UrlEncode(foundFile) .. "?t=" .. tostring(os.time() * 1000),
					Method = "GET",
				})
				if dlRes and dlRes.StatusCode == 200 and dlRes.Body then
					local subDir = isRbxmMode and "SPOOF/animasi/" or "SPOOF/music/"
					local ext = isRbxmMode and ".rbxm" or ".mp3"
					saveTextFile(subDir .. assetId .. ext, tostring(dlRes.Body))
					berhasil += 1
				else
					gagal += 1
				end
			else
				-- Catat log percobaan ke workspace agar tetap terdokumentasi di executor
				saveTextFile("SPOOF/info/log_" .. assetId .. ".txt", "AssetId: " .. assetId .. " | Filter: " .. CONFIG.SpoofFilter .. " | Session: " .. CONFIG.SessionId)
				gagal += 1
			end

			setStatus(string.format("[%d/%d] Selesai ID %s (✔ %d | ❌ %d)", i, #ids, assetId, berhasil, gagal), i / #ids)
			task.wait(0.35)
		end

		setStatus(string.format("Selesai! Berhasil: %d | Gagal: %d (Folder: %s/SPOOF)", berhasil, gagal, CONFIG.WorkspaceRoot), 1)
		isSpoofing = false
	end)
end)

-- Upload ke Open Cloud API
UploadActionBtn.MouseButton1Click:Connect(function()
	if CONFIG.ApiKey == "" then
		UploadLogLabel.Text = "❌ Isi API Key terlebih dahulu di tab Setting!"
		return
	end
	local assetName = UploadNameBox.Text ~= "" and UploadNameBox.Text or ("IkyyAsset_" .. tostring(os.time()))
	local assetType = UploadTypeBox.Text ~= "" and UploadTypeBox.Text or "Model"
	local creatorId = UploadCreatorBox.Text ~= "" and UploadCreatorBox.Text or tostring(LocalPlayer.UserId)
	local payloadContent = UploadPayloadBox.Text ~= "" and UploadPayloadBox.Text or "-- Exported via Ikyy Plugin Studio Lite"

	task.spawn(function()
		UploadLogLabel.Text = "⏳ Mengirim request ke Roblox Open Cloud Assets API..."
		local res, err = httpRequest({
			Url = "https://apis.roblox.com/assets/v1/assets",
			Method = "POST",
			Headers = {
				["x-api-key"] = CONFIG.ApiKey,
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				assetType = assetType,
				displayName = assetName,
				description = "Uploaded via Plugin Studio Lite by Ikyy",
				creationContext = {
					creator = { userId = tostring(creatorId) },
				},
				payload = payloadContent,
			}),
		})
		if res then
			saveTextFile("Uploads/upload_" .. tostring(os.time()) .. ".json", tostring(res.Body or ""))
			UploadLogLabel.Text = "✔ HTTP " .. tostring(res.StatusCode) .. " — Log disimpan ke " .. CONFIG.WorkspaceRoot .. "/Uploads"
		else
			UploadLogLabel.Text = "❌ Gagal upload: " .. tostring(err)
		end
	end)
end)

-- Buat Universe / Place
CreatePlaceBtn.MouseButton1Click:Connect(function()
	if CONFIG.Cookie == "" then
		ToolsStatusLabel.Text = "❌ Masukkan Cookie (.ROBLOSECURITY) di tab Setting!"
		return
	end
	local tplId = tonumber(TemplateIdBox.Text) or 95206881
	local grpId = tonumber(GroupIdBox.Text)

	task.spawn(function()
		ToolsStatusLabel.Text = "⏳ Membuat Universe dengan Template " .. tostring(tplId) .. "..."
		local bodyTable: {[string]: any} = { templatePlaceId = tplId }
		if grpId and grpId > 0 then
			bodyTable.groupId = grpId
		end
		local jsonBody = HttpService:JSONEncode(bodyTable)

		local res, err = httpRequest({
			Url = "https://apis.roblox.com/universes/v1/universes/create",
			Method = "POST",
			Headers = {
				["Cookie"] = ".ROBLOSECURITY=" .. CONFIG.Cookie,
				["Content-Type"] = "application/json",
			},
			Body = jsonBody,
		})

		if res and res.StatusCode == 403 and res.Headers then
			local csrf = res.Headers["X-CSRF-Token"] or res.Headers["x-csrf-token"]
			if csrf then
				res, err = httpRequest({
					Url = "https://apis.roblox.com/universes/v1/universes/create",
					Method = "POST",
					Headers = {
						["Cookie"] = ".ROBLOSECURITY=" .. CONFIG.Cookie,
						["Content-Type"] = "application/json",
						["X-CSRF-TOKEN"] = csrf,
					},
					Body = jsonBody,
				})
			end
		end

		if res then
			saveTextFile("Logs/place_" .. tostring(os.time()) .. ".json", tostring(res.Body or ""))
			ToolsStatusLabel.Text = "✔ Place response HTTP " .. tostring(res.StatusCode)
		else
			ToolsStatusLabel.Text = "❌ Gagal membuat Place: " .. tostring(err)
		end
	end)
end)

-- Grant Asset Permissions
GrantPermBtn.MouseButton1Click:Connect(function()
	if CONFIG.ApiKey == "" then
		ToolsStatusLabel.Text = "❌ Isi API Key di tab Setting terlebih dahulu!"
		return
	end
	local univId = TargetUniverseBox.Text:match("%d+")
	local ids = parseIds(PermIdsBox.Text)
	if not univId or #ids == 0 then
		ToolsStatusLabel.Text = "❌ Masukkan Universe ID dan minimal 1 Asset ID!"
		return
	end

	task.spawn(function()
		ToolsStatusLabel.Text = "⏳ Mengirim permission untuk " .. tostring(#ids) .. " asset ke Universe " .. univId .. "..."
		local reqList = {}
		for _, aid in ipairs(ids) do
			table.insert(reqList, { assetId = tonumber(aid) })
		end

		local res, err = httpRequest({
			Url = "https://apis.roblox.com/asset-permissions-api/v1/assets/permissions",
			Method = "PATCH",
			Headers = {
				["x-api-key"] = CONFIG.ApiKey,
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode({
				subjectType = "Universe",
				subjectId = tostring(univId),
				action = "Use",
				requests = reqList,
			}),
		})

		if res then
			saveTextFile("Logs/perm_" .. tostring(os.time()) .. ".json", tostring(res.Body or ""))
			ToolsStatusLabel.Text = "✔ Permission HTTP " .. tostring(res.StatusCode) .. " untuk " .. tostring(#ids) .. " ID"
		else
			ToolsStatusLabel.Text = "❌ Gagal permission: " .. tostring(err)
		end
	end)
end)
