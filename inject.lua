--!strict
-- Plugin Studio Lite (Upload Only Edition) by Ikyy
-- Fitur: Upload Asset, Setting (API Key), Close -> Ikon Lingkaran Profile

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

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
	WorkspaceRoot = "IkyyStudioLite",
	ApiKey = "",
	IsMinimized = false,
	ActiveTab = "Upload",
}

local WINDOW_SIZE = UDim2.fromOffset(540, 320)
local WINDOW_POS = UDim2.new(0.5, -270, 0.5, -160)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_POS = UDim2.new(0.5, -21, 0.08, 0)

local function trim(s: string?): string
	if type(s) ~= "string" then return "" end
	return s:match("^%s*(.-)%s*$") or ""
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
		CONFIG.WorkspaceRoot .. "/Uploads",
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
	return pcall(writefile, CONFIG.WorkspaceRoot .. "/" .. relPath, content)
end

local function loadTextFile(relPath: string): string?
	if not hasFileIO() then return nil end
	local fullPath = CONFIG.WorkspaceRoot .. "/" .. relPath
	local ok, res = pcall(function()
		if type(isfile) == "function" and isfile(fullPath) then
			return readfile(fullPath)
		end
		return nil
	end)
	if ok and type(res) == "string" then
		return res
	end
	return nil
end

local savedApiKey = loadTextFile("apikey.txt")
if savedApiKey and trim(savedApiKey) ~= "" then
	CONFIG.ApiKey = trim(savedApiKey)
end

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
		return nil, false
	end
	local ok, res = pcall(reqFn, {
		Url = options.Url,
		Method = options.Method or "GET",
		Headers = options.Headers or {},
		Body = options.Body,
	})
	if not ok or type(res) ~= "table" then
		return nil, false
	end
	local code = tonumber(res.StatusCode) or 0
	return res, (code >= 200 and code < 300)
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
-- UI UTAMA (TERKUNCI DI TENGAH, TANPA DRAG)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IkyyPluginStudioLite_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- 1. IKON LINGKARAN PROFILE USER (42x42)
local FloatingProfileBtn = Instance.new("ImageButton")
FloatingProfileBtn.Name = "FloatingProfileToggle"
FloatingProfileBtn.Size = ICON_SIZE
FloatingProfileBtn.Position = ICON_POS
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
FloatStroke.Thickness = 2
FloatStroke.Parent = FloatingProfileBtn

-- 2. WINDOW UTAMA (540x320)
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
LogoIcon.Text = "⬆"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 15
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 220, 0, 12)
SubTitleLabel.Position = UDim2.new(0, 50, 0, 7)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • UPLOAD EDITION"
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
MetaLabel.Text = "by Ikyy • Upload Only • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
MetaLabel.TextSize = 9
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.Parent = HeaderBar

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
			Position = ICON_POS,
		})
		tw:Play()
		tw.Completed:Connect(function()
			if CONFIG.IsMinimized then
				MainWindow.Visible = false
				FloatingProfileBtn.Position = ICON_POS
				FloatingProfileBtn.Size = ICON_SIZE
				FloatingProfileBtn.Visible = true
			end
		end)
	else
		FloatingProfileBtn.Visible = false
		MainWindow.Position = ICON_POS
		MainWindow.Size = ICON_SIZE
		MainWindow.Visible = true
		TweenService:Create(MainWindow, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = WINDOW_SIZE,
			Position = WINDOW_POS,
		}):Play()
	end
end

CloseCircleBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

FloatingProfileBtn.MouseButton1Click:Connect(function()
	setMinimized(false)
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
NavList.Size = UDim2.new(1, -10, 0, 80)
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
	btn.Size = UDim2.new(1, 0, 0, 34)
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

local SembunyiBtn = Instance.new("TextButton")
SembunyiBtn.Size = UDim2.new(1, -12, 0, 32)
SembunyiBtn.Position = UDim2.new(0, 6, 1, -40)
SembunyiBtn.BackgroundColor3 = Color3.fromRGB(32, 31, 48)
SembunyiBtn.Text = "SEMBUNYIKAN"
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

	return function(success: boolean, ratio: number)
		local clamped = math.clamp(ratio, 0, 1)
		fill.BackgroundColor3 = success and Color3.fromRGB(56, 239, 125) or Color3.fromRGB(255, 86, 102)
		TweenService:Create(fill, TweenInfo.new(0.18), {
			Size = UDim2.new(clamped, 0, 1, 0),
		}):Play()
	end
end

-- ==========================================
-- HALAMAN 1: UPLOAD ASSET
-- ==========================================
local UploadPage = Instance.new("Frame")
UploadPage.Size = UDim2.fromScale(1, 1)
UploadPage.BackgroundTransparency = 1
UploadPage.Visible = true
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
-- HALAMAN 2: SETTING (API KEY)
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
SettingTitle.Text = "Pengaturan API Key"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 14
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local ApiKeyBox = Instance.new("TextBox")
ApiKeyBox.Size = UDim2.new(1, -24, 0, 118)
ApiKeyBox.Position = UDim2.new(0, 12, 0, 34)
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
SaveSettingBtn.Position = UDim2.new(0, 12, 0, 160)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 11
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 8)

local setSettingOutcome = createResultBar(SettingPage, 204)

SaveSettingBtn.MouseButton1Click:Connect(function()
	local k = trim(ApiKeyBox.Text)
	CONFIG.ApiKey = k
	local ok = (k == "") or saveTextFile("apikey.txt", k)
	setSettingOutcome(ok, ok and 1 or 0)
	notify("Plugin Studio Lite", ok and "Berhasil disimpan." or "Gagal menyimpan.")
end)

-- Navigasi Sidebar
createNavButton("Upload", "⬆  Upload", 1).MouseButton1Click:Connect(function() switchTab("Upload") end)
createNavButton("Setting", "⚙  Setting", 2).MouseButton1Click:Connect(function() switchTab("Setting") end)
switchTab("Upload")

-- ==========================================
-- LOGIKA UPLOAD ASSET
-- ==========================================
UploadActionBtn.MouseButton1Click:Connect(function()
	if trim(CONFIG.ApiKey) == "" then
		setUploadOutcome(false, 0)
		notify("Upload", "Gagal.")
		return
	end

	local assetName = trim(UploadNameBox.Text)
	if assetName == "" then
		assetName = "IkyyAsset_" .. tostring(os.time())
	end
	local assetType = trim(UploadTypeBox.Text)
	if assetType == "" then
		assetType = "Model"
	end
	local creatorId = trim(UploadCreatorBox.Text)
	if creatorId == "" then
		creatorId = tostring(LocalPlayer.UserId)
	end
	local isGroup = (trim(UploadOwnerModeBox.Text):lower() == "group")

	local rawPayload = trim(UploadPayloadBox.Text)
	if rawPayload ~= "" then
		local loaded = loadTextFile(rawPayload)
		if loaded then
			rawPayload = loaded
		end
	else
		rawPayload = "-- Exported via Ikyy Plugin Studio Lite"
	end

	task.spawn(function()
		local creatorTable = isGroup and { groupId = tostring(creatorId) } or { userId = tostring(creatorId) }
		local res, ok = httpRequest({
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
				creationContext = { creator = creatorTable },
				payload = rawPayload,
			}),
		})

		if ok and res then
			saveTextFile("Uploads/upload_" .. tostring(os.time()) .. ".json", tostring(res.Body or ""))
			setUploadOutcome(true, 1)
			notify("Upload", "Berhasil.")
		else
			setUploadOutcome(false, 0)
			notify("Upload", "Gagal.")
		end
	end)
end)
