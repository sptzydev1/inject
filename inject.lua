--!strict
-- Plugin Studio Lite (Upload Only Edition) by Ikyy
-- Fitur: Upload Asset (List SPOOF/music, Select 1 / Select All, 2 Console + Copy Hasil), Setting (API Key), Close -> Ikon Lingkaran Profile

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
	MusicFolder = "IkyyStudioLite/SPOOF/music",
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

local function copyToClipboard(text: string): boolean
	if type(setclipboard) == "function" then
		local ok = pcall(setclipboard, text)
		if ok then return true end
	end
	if type(toclipboard) == "function" then
		local ok = pcall(toclipboard, text)
		if ok then return true end
	end
	if set_clipboard and type(set_clipboard) == "function" then
		local ok = pcall(set_clipboard, text)
		if ok then return true end
	end
	return false
end

local function hasFileIO(): boolean
	return type(writefile) == "function"
		and type(readfile) == "function"
		and type(isfolder) == "function"
		and type(makefolder) == "function"
		and type(listfiles) == "function"
end

local function ensureFolders()
	if not hasFileIO() then return end
	local folders = {
		CONFIG.WorkspaceRoot,
		CONFIG.WorkspaceRoot .. "/SPOOF",
		CONFIG.MusicFolder,
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

local function readRawFile(fullPath: string): string?
	if type(readfile) ~= "function" then return nil end
	local ok, res = pcall(readfile, fullPath)
	if ok and type(res) == "string" then
		return res
	end
	return nil
end

local function basenameNoExt(pathOrName: string): string
	local fileOnly = pathOrName:match("[^/\\]+$") or pathOrName
	local clean = fileOnly:gsub("%.%w+$", "")
	return clean ~= "" and clean or fileOnly
end

local function getMusicFiles(): {{path: string, name: string}}
	ensureFolders()
	local result: {{path: string, name: string}} = {}
	if type(listfiles) ~= "function" then return result end

	local ok, files = pcall(listfiles, CONFIG.MusicFolder)
	if not ok or type(files) ~= "table" then return result end

	for _, entry in ipairs(files) do
		local raw = tostring(entry)
		local isDir = false
		if type(isfolder) == "function" then
			local dOk, dRes = pcall(isfolder, raw)
			if dOk and dRes then isDir = true end
		end
		if not isDir then
			local display = raw:match("[^/\\]+$") or raw
			table.insert(result, {
				path = raw,
				name = display,
			})
		end
	end

	table.sort(result, function(a, b)
		return a.name:lower() < b.name:lower()
	end)
	return result
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
LogoIcon.Text = "⬆"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 14
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 240, 0, 16)
TitleLabel.Position = UDim2.new(0, 48, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Plugin Studio Lite"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(0, 260, 0, 12)
MetaLabel.Position = UDim2.new(0, 48, 0, 23)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "SPOOF/music Uploader • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
MetaLabel.TextSize = 9
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.Parent = HeaderBar

local CloseCircleBtn = Instance.new("TextButton")
CloseCircleBtn.Name = "CloseToCircleBtn"
CloseCircleBtn.Size = UDim2.fromOffset(26, 26)
CloseCircleBtn.Position = UDim2.new(1, -38, 0.5, -13)
CloseCircleBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 50)
CloseCircleBtn.Text = "✕"
CloseCircleBtn.TextColor3 = Color3.fromRGB(220, 218, 238)
CloseCircleBtn.TextSize = 11
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
Sidebar.Size = UDim2.new(0, 116, 1, -52)
Sidebar.Position = UDim2.new(0, 8, 0, 46)
Sidebar.BackgroundColor3 = Color3.fromRGB(21, 20, 32)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainWindow

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)
local SideStroke = Instance.new("UIStroke", Sidebar)
SideStroke.Color = Color3.fromRGB(52, 48, 82)
SideStroke.Thickness = 1

local NavList = Instance.new("Frame")
NavList.Size = UDim2.new(1, -10, 0, 76)
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
	btn.Size = UDim2.new(1, 0, 0, 32)
	btn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
	btn.Text = "  " .. label
	btn.TextColor3 = Color3.fromRGB(185, 182, 210)
	btn.TextSize = 10
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
SembunyiBtn.Size = UDim2.new(1, -10, 0, 28)
SembunyiBtn.Position = UDim2.new(0, 5, 1, -34)
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
ContentArea.Size = UDim2.new(1, -138, 1, -52)
ContentArea.Position = UDim2.new(0, 130, 0, 46)
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
-- HALAMAN 1: UPLOAD ASSET (SPOOF/music + 2 CONSOLE)
-- ==========================================
local UploadPage = Instance.new("Frame")
UploadPage.Size = UDim2.fromScale(1, 1)
UploadPage.BackgroundTransparency = 1
UploadPage.Visible = true
UploadPage.Parent = ContentArea
tabPages["Upload"] = UploadPage

-- Baris kontrol Select All & Refresh
local ControlBar = Instance.new("Frame")
ControlBar.Size = UDim2.new(1, -16, 0, 24)
ControlBar.Position = UDim2.new(0, 8, 0, 6)
ControlBar.BackgroundTransparency = 1
ControlBar.Parent = UploadPage

local SelectAllBtn = Instance.new("TextButton")
SelectAllBtn.Size = UDim2.new(0, 76, 1, 0)
SelectAllBtn.Position = UDim2.new(0, 0, 0, 0)
SelectAllBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
SelectAllBtn.Text = "Select All"
SelectAllBtn.TextColor3 = Color3.fromRGB(220, 218, 242)
SelectAllBtn.TextSize = 9
SelectAllBtn.Font = Enum.Font.GothamBold
SelectAllBtn.Parent = ControlBar
Instance.new("UICorner", SelectAllBtn).CornerRadius = UDim.new(0, 6)
local SelAllStroke = Instance.new("UIStroke", SelectAllBtn)
SelAllStroke.Color = Color3.fromRGB(72, 68, 108)
SelAllStroke.Thickness = 1

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0, 64, 1, 0)
RefreshBtn.Position = UDim2.new(0, 80, 0, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
RefreshBtn.Text = "Refresh"
RefreshBtn.TextColor3 = Color3.fromRGB(190, 188, 215)
RefreshBtn.TextSize = 9
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Parent = ControlBar
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

local UploadBtn = Instance.new("TextButton")
UploadBtn.Size = UDim2.new(0, 82, 1, 0)
UploadBtn.Position = UDim2.new(1, -82, 0, 0)
UploadBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
UploadBtn.Text = "⬆ Upload"
UploadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UploadBtn.TextSize = 9
UploadBtn.Font = Enum.Font.GothamBold
UploadBtn.Parent = ControlBar
Instance.new("UICorner", UploadBtn).CornerRadius = UDim.new(0, 6)

-- List file dari IkyyStudioLite/SPOOF/music (Select Satu / Select All)
local FileScroll = Instance.new("ScrollingFrame")
FileScroll.Size = UDim2.new(1, -16, 0, 86)
FileScroll.Position = UDim2.new(0, 8, 0, 34)
FileScroll.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
FileScroll.BorderSizePixel = 0
FileScroll.ScrollBarThickness = 3
FileScroll.CanvasSize = UDim2.fromOffset(0, 0)
FileScroll.Parent = UploadPage
Instance.new("UICorner", FileScroll).CornerRadius = UDim.new(0, 7)
local FileStroke = Instance.new("UIStroke", FileScroll)
FileStroke.Color = Color3.fromRGB(58, 54, 88)
FileStroke.Thickness = 1

local FileLayout = Instance.new("UIListLayout")
FileLayout.Padding = UDim.new(0, 3)
FileLayout.SortOrder = Enum.SortOrder.LayoutOrder
FileLayout.Parent = FileScroll

local FilePad = Instance.new("UIPadding")
FilePad.PaddingTop = UDim.new(0, 4)
FilePad.PaddingBottom = UDim.new(0, 4)
FilePad.PaddingLeft = UDim.new(0, 4)
FilePad.PaddingRight = UDim.new(0, 4)
FilePad.Parent = FileScroll

-- CONSOLE 1: PROSES
local ProcessHeader = Instance.new("TextLabel")
ProcessHeader.Size = UDim2.new(1, -16, 0, 12)
ProcessHeader.Position = UDim2.new(0, 8, 0, 124)
ProcessHeader.BackgroundTransparency = 1
ProcessHeader.Text = "Console Proses"
ProcessHeader.TextColor3 = Color3.fromRGB(155, 152, 184)
ProcessHeader.TextSize = 9
ProcessHeader.Font = Enum.Font.GothamBold
ProcessHeader.TextXAlignment = Enum.TextXAlignment.Left
ProcessHeader.Parent = UploadPage

local ProcessConsoleScroll = Instance.new("ScrollingFrame")
ProcessConsoleScroll.Size = UDim2.new(1, -16, 0, 34)
ProcessConsoleScroll.Position = UDim2.new(0, 8, 0, 137)
ProcessConsoleScroll.BackgroundColor3 = Color3.fromRGB(11, 10, 18)
ProcessConsoleScroll.BorderSizePixel = 0
ProcessConsoleScroll.ScrollBarThickness = 2
ProcessConsoleScroll.CanvasSize = UDim2.fromOffset(0, 0)
ProcessConsoleScroll.Parent = UploadPage
Instance.new("UICorner", ProcessConsoleScroll).CornerRadius = UDim.new(0, 6)
local ProcStroke = Instance.new("UIStroke", ProcessConsoleScroll)
ProcStroke.Color = Color3.fromRGB(52, 48, 82)
ProcStroke.Thickness = 1

local ProcessConsoleText = Instance.new("TextLabel")
ProcessConsoleText.Size = UDim2.new(1, -10, 0, 0)
ProcessConsoleText.Position = UDim2.new(0, 5, 0, 4)
ProcessConsoleText.BackgroundTransparency = 1
ProcessConsoleText.Text = "Menunggu file dipilih..."
ProcessConsoleText.TextColor3 = Color3.fromRGB(175, 195, 255)
ProcessConsoleText.TextSize = 9
ProcessConsoleText.Font = Enum.Font.Code
ProcessConsoleText.TextXAlignment = Enum.TextXAlignment.Left
ProcessConsoleText.TextYAlignment = Enum.TextYAlignment.Top
ProcessConsoleText.TextWrapped = true
ProcessConsoleText.AutomaticSize = Enum.AutomaticSize.Y
ProcessConsoleText.Parent = ProcessConsoleScroll

-- CONSOLE 2: HASIL (BERTUMPUK FORMAT nama : / id : + TOMBOL COPY)
local ResultHeaderBar = Instance.new("Frame")
ResultHeaderBar.Size = UDim2.new(1, -16, 0, 15)
ResultHeaderBar.Position = UDim2.new(0, 8, 0, 174)
ResultHeaderBar.BackgroundTransparency = 1
ResultHeaderBar.Parent = UploadPage

local ResultHeader = Instance.new("TextLabel")
ResultHeader.Size = UDim2.new(1, -54, 1, 0)
ResultHeader.Position = UDim2.new(0, 0, 0, 0)
ResultHeader.BackgroundTransparency = 1
ResultHeader.Text = "Console Hasil"
ResultHeader.TextColor3 = Color3.fromRGB(155, 152, 184)
ResultHeader.TextSize = 9
ResultHeader.Font = Enum.Font.GothamBold
ResultHeader.TextXAlignment = Enum.TextXAlignment.Left
ResultHeader.Parent = ResultHeaderBar

local CopyResultBtn = Instance.new("TextButton")
CopyResultBtn.Name = "CopyResultBtn"
CopyResultBtn.Size = UDim2.new(0, 50, 1, 0)
CopyResultBtn.Position = UDim2.new(1, -50, 0, 0)
CopyResultBtn.BackgroundColor3 = Color3.fromRGB(48, 44, 76)
CopyResultBtn.Text = "Copy"
CopyResultBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
CopyResultBtn.TextSize = 8
CopyResultBtn.Font = Enum.Font.GothamBold
CopyResultBtn.Parent = ResultHeaderBar
Instance.new("UICorner", CopyResultBtn).CornerRadius = UDim.new(0, 4)

local ResultConsoleScroll = Instance.new("ScrollingFrame")
ResultConsoleScroll.Size = UDim2.new(1, -16, 0, 69)
ResultConsoleScroll.Position = UDim2.new(0, 8, 0, 191)
ResultConsoleScroll.BackgroundColor3 = Color3.fromRGB(11, 10, 18)
ResultConsoleScroll.BorderSizePixel = 0
ResultConsoleScroll.ScrollBarThickness = 3
ResultConsoleScroll.CanvasSize = UDim2.fromOffset(0, 0)
ResultConsoleScroll.Parent = UploadPage
Instance.new("UICorner", ResultConsoleScroll).CornerRadius = UDim.new(0, 6)
local ResStroke = Instance.new("UIStroke", ResultConsoleScroll)
ResStroke.Color = Color3.fromRGB(52, 48, 82)
ResStroke.Thickness = 1

local ResultConsoleText = Instance.new("TextLabel")
ResultConsoleText.Size = UDim2.new(1, -10, 0, 0)
ResultConsoleText.Position = UDim2.new(0, 5, 0, 4)
ResultConsoleText.BackgroundTransparency = 1
ResultConsoleText.Text = ""
ResultConsoleText.TextColor3 = Color3.fromRGB(220, 245, 225)
ResultConsoleText.TextSize = 9
ResultConsoleText.Font = Enum.Font.Code
ResultConsoleText.TextXAlignment = Enum.TextXAlignment.Left
ResultConsoleText.TextYAlignment = Enum.TextYAlignment.Top
ResultConsoleText.TextWrapped = true
ResultConsoleText.AutomaticSize = Enum.AutomaticSize.Y
ResultConsoleText.Parent = ResultConsoleScroll

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
SettingTitle.Size = UDim2.new(1, -20, 0, 18)
SettingTitle.Position = UDim2.new(0, 10, 0, 8)
SettingTitle.BackgroundTransparency = 1
SettingTitle.Text = "Pengaturan API Key"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 13
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local ApiKeyBox = Instance.new("TextBox")
ApiKeyBox.Size = UDim2.new(1, -20, 0, 150)
ApiKeyBox.Position = UDim2.new(0, 10, 0, 32)
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
SaveSettingBtn.Size = UDim2.new(1, -20, 0, 34)
SaveSettingBtn.Position = UDim2.new(0, 10, 0, 192)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 11
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 8)

SaveSettingBtn.MouseButton1Click:Connect(function()
	local k = trim(ApiKeyBox.Text)
	CONFIG.ApiKey = k
	local ok = (k == "") or saveTextFile("apikey.txt", k)
	notify("Plugin Studio Lite", ok and "Berhasil disimpan." or "Gagal menyimpan.")
end)

-- Navigasi Sidebar
createNavButton("Upload", "⬆  Upload", 1).MouseButton1Click:Connect(function() switchTab("Upload") end)
createNavButton("Setting", "⚙  Setting", 2).MouseButton1Click:Connect(function() switchTab("Setting") end)
switchTab("Upload")

-- ==========================================
-- LOGIKA LIST FILE, SELECT SATU / ALL & 2 CONSOLE
-- ==========================================
local currentFiles: {{path: string, name: string}} = {}
local selectedPaths: {[string]: boolean} = {}
local rowButtons: {[string]: TextButton} = {}
local resultBlocks: {string} = {}

local function setProcessLog(msg: string)
	ProcessConsoleText.Text = msg
	ProcessConsoleScroll.CanvasSize = UDim2.fromOffset(0, ProcessConsoleText.TextBounds.Y + 8)
	ProcessConsoleScroll.CanvasPosition = Vector2.new(0, math.max(0, ProcessConsoleText.TextBounds.Y - 24))
end

local function appendResultEntry(nama: string, assetId: string)
	local entry = "nama : " .. nama .. "\nid : " .. assetId
	table.insert(resultBlocks, entry)
	ResultConsoleText.Text = table.concat(resultBlocks, "\n\n")
	task.defer(function()
		ResultConsoleScroll.CanvasSize = UDim2.fromOffset(0, ResultConsoleText.TextBounds.Y + 10)
		ResultConsoleScroll.CanvasPosition = Vector2.new(0, math.max(0, ResultConsoleText.TextBounds.Y - 56))
	end)
end

CopyResultBtn.MouseButton1Click:Connect(function()
	local rawResult = ResultConsoleText.Text
	if trim(rawResult) == "" then
		setProcessLog("Tidak ada hasil untuk di-copy")
		return
	end
	local ok = copyToClipboard(rawResult)
	if ok then
		CopyResultBtn.Text = "Copied!"
		setProcessLog("Hasil berhasil di-copy ke clipboard")
		notify("Console Hasil", "Berhasil di-copy.")
		task.delay(1.2, function()
			CopyResultBtn.Text = "Copy"
		end)
	else
		setProcessLog("Gagal copy: executor tidak mendukung clipboard")
		notify("Console Hasil", "Gagal copy.")
	end
end)

local function refreshRowVisuals()
	for path, btn in pairs(rowButtons) do
		local isSel = selectedPaths[path] == true
		btn.BackgroundColor3 = isSel and Color3.fromRGB(64, 52, 120) or Color3.fromRGB(22, 21, 34)
		btn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(190, 188, 215)
	end
end

local function rebuildFileList()
	for _, child in ipairs(FileScroll:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	table.clear(rowButtons)

	currentFiles = getMusicFiles()
	if #currentFiles == 0 then
		local emptyLbl = Instance.new("TextLabel")
		emptyLbl.Size = UDim2.new(1, -8, 0, 24)
		emptyLbl.BackgroundTransparency = 1
		emptyLbl.Text = "Kosong: " .. CONFIG.MusicFolder
		emptyLbl.TextColor3 = Color3.fromRGB(125, 122, 150)
		emptyLbl.TextSize = 9
		emptyLbl.Font = Enum.Font.Gotham
		emptyLbl.TextXAlignment = Enum.TextXAlignment.Left
		emptyLbl.Parent = FileScroll
		FileScroll.CanvasSize = UDim2.fromOffset(0, 28)
		return
	end

	for idx, item in ipairs(currentFiles) do
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -4, 0, 22)
		row.BackgroundColor3 = Color3.fromRGB(22, 21, 34)
		row.Text = "  " .. item.name
		row.TextColor3 = Color3.fromRGB(190, 188, 215)
		row.TextSize = 9
		row.Font = Enum.Font.GothamMedium
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.LayoutOrder = idx
		row.AutoButtonColor = false
		row.Parent = FileScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

		rowButtons[item.path] = row

		-- Select Satu (klik toggle satu file)
		row.MouseButton1Click:Connect(function()
			selectedPaths[item.path] = not (selectedPaths[item.path] == true)
			refreshRowVisuals()
			local count = 0
			for _, v in pairs(selectedPaths) do
				if v then count += 1 end
			end
			setProcessLog("Dipilih: " .. tostring(count) .. " file")
		end)
	end

	refreshRowVisuals()
	local totalH = (#currentFiles * 25) + 8
	FileScroll.CanvasSize = UDim2.fromOffset(0, totalH)
end

-- Select All (toggle pilih semua / batal semua)
SelectAllBtn.MouseButton1Click:Connect(function()
	if #currentFiles == 0 then
		setProcessLog("Tidak ada file di SPOOF/music")
		return
	end
	local allSelected = true
	for _, item in ipairs(currentFiles) do
		if not selectedPaths[item.path] then
			allSelected = false
			break
		end
	end
	for _, item in ipairs(currentFiles) do
		selectedPaths[item.path] = not allSelected
	end
	refreshRowVisuals()
	setProcessLog((not allSelected) and ("Select All (" .. tostring(#currentFiles) .. " file)") or "Batal pilih semua")
end)

RefreshBtn.MouseButton1Click:Connect(function()
	rebuildFileList()
	setProcessLog("List diperbarui (" .. tostring(#currentFiles) .. " file)")
end)

local function extractCreatedId(bodyStr: string): string
	local idMatch = bodyStr:match('"assetId"%s*:%s*"?(%d+)"?')
		or bodyStr:match('"id"%s*:%s*"?(%d+)"?')
		or bodyStr:match('"(%d{6,})"')
	return idMatch or "-"
end

local isUploading = false
UploadBtn.MouseButton1Click:Connect(function()
	if isUploading then return end

	if trim(CONFIG.ApiKey) == "" then
		setProcessLog("Gagal: API Key belum diatur di Setting")
		notify("Upload", "Gagal.")
		return
	end

	local queue: {{path: string, name: string}} = {}
	for _, item in ipairs(currentFiles) do
		if selectedPaths[item.path] then
			table.insert(queue, item)
		end
	end

	if #queue == 0 then
		setProcessLog("Gagal: Pilih minimal 1 file dulu")
		notify("Upload", "Gagal.")
		return
	end

	isUploading = true
	task.spawn(function()
		for i, item in ipairs(queue) do
			local namaAsset = basenameNoExt(item.name)
			setProcessLog("[" .. tostring(i) .. "/" .. tostring(#queue) .. "] Uploading: " .. item.name)

			local content = readRawFile(item.path)
			if not content then
				setProcessLog("[" .. tostring(i) .. "/" .. tostring(#queue) .. "] Gagal baca file: " .. item.name)
				appendResultEntry(namaAsset, "GAGAL")
			else
				local res, ok = httpRequest({
					Url = "https://apis.roblox.com/assets/v1/assets",
					Method = "POST",
					Headers = {
						["x-api-key"] = CONFIG.ApiKey,
						["Content-Type"] = "application/json",
					},
					Body = HttpService:JSONEncode({
						assetType = "Audio",
						displayName = namaAsset,
						description = "Uploaded from SPOOF/music by Ikyy",
						creationContext = {
							creator = { userId = tostring(LocalPlayer.UserId) },
						},
						payload = content,
					}),
				})

				if ok and res then
					local respBody = tostring(res.Body or "")
					local newId = extractCreatedId(respBody)
					saveTextFile("Uploads/upload_" .. namaAsset .. "_" .. tostring(os.time()) .. ".json", respBody)
					appendResultEntry(namaAsset, newId)
				else
					appendResultEntry(namaAsset, "GAGAL")
				end
			end

			if i < #queue then
				task.wait(0.4)
			end
		end

		setProcessLog("Selesai (" .. tostring(#queue) .. " file diproses)")
		notify("Upload", "Selesai.")
		isUploading = false
	end)
end)

ensureFolders()
rebuildFileList()
