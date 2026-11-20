--!strict
-- Plugin Studio Lite (Delta Executor Edition - Create Place & Setting) by Ikyy
-- Alur: Input GUI -> Validasi -> Kirim Permintaan -> Output Realtime (Icon Game, Name Game, Status)

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
	WorkspaceRoot = "IkyyStudioLite",
	Cookie = "",
	IsMinimized = false,
	ActiveTab = "CreatePlace",
	UserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
}

local MEMORY_FILES: {[string]: string} = {}

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

local function getDeltaHttpFunc()
	local candidates = {
		ENV.request,
		ENV.http_request,
		type(ENV.syn) == "table" and ENV.syn.request or nil,
		type(ENV.http) == "table" and ENV.http.request or nil,
		type(ENV.fluxus) == "table" and ENV.fluxus.request or nil,
		type(ENV.delta) == "table" and ENV.delta.request or nil,
	}
	for _, fn in ipairs(candidates) do
		if type(fn) == "function" then
			return fn
		end
	end
	return nil
end

local fnWriteFile = type(ENV.writefile) == "function" and ENV.writefile or nil
local fnReadFile = type(ENV.readfile) == "function" and ENV.readfile or nil
local fnIsFile = type(ENV.isfile) == "function" and ENV.isfile or nil
local fnIsFolder = type(ENV.isfolder) == "function" and ENV.isfolder or nil
local fnMakeFolder = type(ENV.makefolder) == "function" and ENV.makefolder or nil

local function ensureFolders()
	if not fnMakeFolder then return end
	local folders = {
		CONFIG.WorkspaceRoot,
		CONFIG.WorkspaceRoot .. "/Logs",
	}
	for _, folder in ipairs(folders) do
		local exists = false
		if fnIsFolder then
			local okChk, resChk = pcall(fnIsFolder, folder)
			exists = okChk and (resChk == true)
		end
		if not exists then
			pcall(fnMakeFolder, folder)
		end
	end
end

local function normalizeWorkspaceRelPath(rawPath: string): string
	local p = rawPath:gsub("\\", "/"):gsub("^%./", "")
	local rootPrefix = CONFIG.WorkspaceRoot .. "/"
	if p:sub(1, #rootPrefix) == rootPrefix then
		p = p:sub(#rootPrefix + 1)
	end
	return p:gsub("^/+", "")
end

local function saveTextFile(relPath: string, content: string): boolean
	local cleanRel = normalizeWorkspaceRelPath(relPath)
	local fullPath = CONFIG.WorkspaceRoot .. "/" .. cleanRel
	MEMORY_FILES[cleanRel] = content
	MEMORY_FILES[fullPath] = content

	if not fnWriteFile then
		return true
	end

	ensureFolders()
	local ok = pcall(fnWriteFile, fullPath, content)
	return ok
end

local function loadTextFile(relPath: string): string?
	local cleanRel = normalizeWorkspaceRelPath(relPath)
	local candidates = {
		CONFIG.WorkspaceRoot .. "/" .. cleanRel,
		cleanRel,
	}

	if fnReadFile then
		for _, fullPath in ipairs(candidates) do
			local canRead = true
			if fnIsFile then
				local okChk, exists = pcall(fnIsFile, fullPath)
				canRead = okChk and (exists == true)
			end
			if canRead then
				local okRead, res = pcall(fnReadFile, fullPath)
				if okRead and type(res) == "string" then
					return res
				end
			end
		end
	end

	for _, key in ipairs(candidates) do
		if type(MEMORY_FILES[key]) == "string" then
			return MEMORY_FILES[key]
		end
	end
	if type(MEMORY_FILES[cleanRel]) == "string" then
		return MEMORY_FILES[cleanRel]
	end
	return nil
end

local savedCookie = loadTextFile("cookie.txt")
if savedCookie and trim(savedCookie) ~= "" then
	CONFIG.Cookie = normalizeCookie(savedCookie)
end

local function apiRequest(options: {
	Url: string,
	Method: string?,
	Headers: {[string]: string}?,
	Body: string?,
	Retries: number?,
})
	local reqFn = getDeltaHttpFunc()
	if not reqFn then
		return nil, false, "HTTP function tidak tersedia di executor"
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
	local lastErr = "Tidak ada respons"

	for attempt = 1, maxAttempts do
		local ok, res = pcall(reqFn, {
			Url = options.Url,
			Method = options.Method or "GET",
			Headers = baseHeaders,
			Body = options.Body,
		})
		if ok and type(res) == "table" then
			lastRes = res
			local code = tonumber(res.StatusCode or res.Status or res.status_code) or 0
			lastOk = (code >= 200 and code < 300)
			if lastOk then
				return res, true, "HTTP " .. tostring(code)
			end
			lastErr = "HTTP " .. tostring(code)
			if code == 400 or code == 401 or code == 403 or code == 404 then
				return res, false, lastErr
			end
		else
			lastErr = tostring(res)
		end
		if attempt < maxAttempts then
			task.wait(0.6)
		end
	end

	return lastRes, lastOk, lastErr
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

-- ==========================================
-- HELPER REALTIME: ICON GAME, NAME GAME & STATUS
-- ==========================================
export type GameResultCardData = {
	universeId: string,
	rootPlaceId: string?,
	iconImage: string,
	gameName: string,
	status: "publik" | "private" | "tidak diketahui",
	metaInfo: string,
	isError: boolean?,
}

local function resolveRealtimeGameIcon(universeId: string, rootPlaceId: string?, cookieVal: string): string
	local cleanUniv = trim(universeId):match("%d+") or ""
	local cleanPlace = (rootPlaceId and trim(rootPlaceId):match("%d+")) or ""

	local authHeaders: {[string]: string} = {}
	if trim(cookieVal) ~= "" then
		authHeaders["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal)
	end

	-- 1. Cek status GameIcon dari Thumbnails API terlebih dahulu (dengan Cookie agar game private juga terbaca)
	if cleanUniv ~= "" then
		local uRes, uOk = apiRequest({
			Url = string.format("https://thumbnails.roblox.com/v1/games/icons?universeIds=%s&size=150x150&format=Png&isCircular=false", cleanUniv),
			Method = "GET",
			Headers = authHeaders,
			Retries = 1,
		})
		if uOk and uRes and uRes.Body then
			local okDec, decoded = pcall(function()
				return HttpService:JSONDecode(tostring(uRes.Body))
			end)
			if okDec and type(decoded) == "table" and type(decoded.data) == "table" and type(decoded.data[1]) == "table" then
				local entry = decoded.data[1]
				if entry.state == "Completed" and type(entry.imageUrl) == "string" and entry.imageUrl ~= "" then
					-- Di Roblox Client, rbxthumb:// adalah URI resmi yang bisa dirender oleh ImageLabel
					return "rbxthumb://type=GameIcon&id=" .. cleanUniv .. "&w=150&h=150"
				end
			end
		end
	end

	-- 2. Fallback cek thumbnail Place / Asset jika GameIcon universe belum tersedia
	if cleanPlace ~= "" then
		local pRes, pOk = apiRequest({
			Url = string.format("https://thumbnails.roblox.com/v1/places/gameicons?placeIds=%s&size=150x150&format=Png&isCircular=false", cleanPlace),
			Method = "GET",
			Headers = authHeaders,
			Retries = 1,
		})
		if pOk and pRes and pRes.Body then
			local okDec, decoded = pcall(function()
				return HttpService:JSONDecode(tostring(pRes.Body))
			end)
			if okDec and type(decoded) == "table" and type(decoded.data) == "table" and type(decoded.data[1]) == "table" then
				local entry = decoded.data[1]
				if entry.state == "Completed" and type(entry.imageUrl) == "string" and entry.imageUrl ~= "" then
					return "rbxthumb://type=Asset&id=" .. cleanPlace .. "&w=150&h=150"
				end
			end
		end
		return "rbxthumb://type=Asset&id=" .. cleanPlace .. "&w=150&h=150"
	end

	if cleanUniv ~= "" then
		return "rbxthumb://type=GameIcon&id=" .. cleanUniv .. "&w=150&h=150"
	end

	return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function fetchRealtimeGameData(universeId: string, cookieVal: string, fallbackPlaceId: string?): GameResultCardData
	local cleanUniv = trim(universeId):match("%d+") or ""
	local nameVal: string? = nil
	local statusVal: "publik" | "private" | "tidak diketahui" = "tidak diketahui"
	local rootPlaceId: string? = fallbackPlaceId

	local devHeaders: {[string]: string} = {}
	if trim(cookieVal) ~= "" then
		devHeaders["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal)
	end

	-- 1. Sumber utama & realtime untuk status privasi (develop API terautentikasi)
	local devRes, devOk = apiRequest({
		Url = "https://develop.roblox.com/v1/universes/" .. cleanUniv,
		Method = "GET",
		Headers = devHeaders,
		Retries = 2,
	})

	if devOk and devRes and devRes.Body then
		local okDec, decoded = pcall(function()
			return HttpService:JSONDecode(tostring(devRes.Body))
		end)
		if okDec and type(decoded) == "table" then
			if type(decoded.name) == "string" and trim(decoded.name) ~= "" then
				nameVal = trim(decoded.name)
			end
			if decoded.rootPlaceId ~= nil and tostring(decoded.rootPlaceId):match("%d+") then
				rootPlaceId = tostring(decoded.rootPlaceId):match("%d+")
			end
			if type(decoded.isActive) == "boolean" then
				statusVal = decoded.isActive and "publik" or "private"
			elseif type(decoded.privacyType) == "string" then
				local pLow = decoded.privacyType:lower()
				if pLow == "public" or pLow:find("public") or pLow:find("open") then
					statusVal = "publik"
				elseif pLow == "private" or pLow:find("private") or pLow:find("closed") then
					statusVal = "private"
				end
			end
		end
	end

	-- 2. Cek games.roblox.com hanya untuk melengkapi nama/rootPlaceId jika belum didapat (TIDAK memaksa status jadi publik)
	if not nameVal or not rootPlaceId then
		local gameRes, gameOk = apiRequest({
			Url = "https://games.roblox.com/v1/games?universeIds=" .. cleanUniv,
			Method = "GET",
			Headers = devHeaders,
			Retries = 1,
		})
		if gameOk and gameRes and gameRes.Body then
			local okDec, decoded = pcall(function()
				return HttpService:JSONDecode(tostring(gameRes.Body))
			end)
			if okDec and type(decoded) == "table" and type(decoded.data) == "table" and type(decoded.data[1]) == "table" then
				local g = decoded.data[1]
				if not nameVal and type(g.name) == "string" and trim(g.name) ~= "" then
					nameVal = trim(g.name)
				end
				if not rootPlaceId and g.rootPlaceId ~= nil and tostring(g.rootPlaceId):match("%d+") then
					rootPlaceId = tostring(g.rootPlaceId):match("%d+")
				end
			end
		end
	end

	-- 3. Jika develop API tidak mengembalikan isActive/privacyType, cek endpoint konfigurasi universe sebagai verifikasi cadangan
	if statusVal == "tidak diketahui" and trim(cookieVal) ~= "" then
		local cfgRes, cfgOk = apiRequest({
			Url = "https://develop.roblox.com/v2/universes/" .. cleanUniv .. "/configuration",
			Method = "GET",
			Headers = devHeaders,
			Retries = 1,
		})
		if cfgOk and cfgRes and cfgRes.Body then
			local okDec, decoded = pcall(function()
				return HttpService:JSONDecode(tostring(cfgRes.Body))
			end)
			if okDec and type(decoded) == "table" then
				if not nameVal and type(decoded.name) == "string" and trim(decoded.name) ~= "" then
					nameVal = trim(decoded.name)
				end
				if type(decoded.isActive) == "boolean" then
					statusVal = decoded.isActive and "publik" or "private"
				elseif type(decoded.privacyType) == "string" then
					local pLow = decoded.privacyType:lower()
					statusVal = (pLow == "public" or pLow:find("public")) and "publik" or "private"
				end
			end
		end
	end

	local finalName = nameVal or ("Place #" .. cleanUniv)
	local iconUri = resolveRealtimeGameIcon(cleanUniv, rootPlaceId, cookieVal)
	local metaStr = "Universe: " .. cleanUniv .. (rootPlaceId and (" • Place: " .. rootPlaceId) or "")

	return {
		universeId = cleanUniv,
		rootPlaceId = rootPlaceId,
		iconImage = iconUri,
		gameName = finalName,
		status = statusVal,
		metaInfo = metaStr,
		isError = false,
	}
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
LogoIcon.Text = "🏗"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 14
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 230, 0, 11)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 5)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • CREATE PLACE"
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
MetaLabel.Text = "by Ikyy • Create Place • @" .. LocalPlayer.Name
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
-- SIDEBAR KIRI (HANYA CREATE PLACE & SETTING)
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
NavLayout.Padding = UDim.new(0, 6)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavListFrame

local tabPages: {[string]: Frame} = {}
local tabButtons: {[string]: TextButton} = {}

local function createNavButton(name: string, label: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = "Nav_" .. name
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(28, 27, 42)
	btn.Text = "  " .. label
	btn.TextColor3 = Color3.fromRGB(185, 182, 210)
	btn.TextSize = 10
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
-- HALAMAN 1: CREATE PLACE
-- ==========================================
local CreatePlacePage = Instance.new("Frame")
CreatePlacePage.Size = UDim2.fromScale(1, 1)
CreatePlacePage.BackgroundTransparency = 1
CreatePlacePage.Visible = true
CreatePlacePage.Parent = ContentArea
tabPages["CreatePlace"] = CreatePlacePage

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, -24, 0, 16)
PageTitle.Position = UDim2.new(0, 12, 0, 4)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "Create Place"
PageTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
PageTitle.TextSize = 12
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Parent = CreatePlacePage

local TemplateIdBox = Instance.new("TextBox")
TemplateIdBox.Size = UDim2.new(0.38, -12, 0, 22)
TemplateIdBox.Position = UDim2.new(0, 12, 0, 23)
TemplateIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TemplateIdBox.Text = "95206881"
TemplateIdBox.PlaceholderText = "Template ID"
TemplateIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TemplateIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TemplateIdBox.TextSize = 10
TemplateIdBox.Font = Enum.Font.Gotham
TemplateIdBox.ClearTextOnFocus = false
TemplateIdBox.Parent = CreatePlacePage
Instance.new("UICorner", TemplateIdBox).CornerRadius = UDim.new(0, 6)

local GroupIdBox = Instance.new("TextBox")
GroupIdBox.Size = UDim2.new(0.34, -8, 0, 22)
GroupIdBox.Position = UDim2.new(0.38, 2, 0, 23)
GroupIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
GroupIdBox.Text = ""
GroupIdBox.PlaceholderText = "Group ID (opsional)"
GroupIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
GroupIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
GroupIdBox.TextSize = 10
GroupIdBox.Font = Enum.Font.Gotham
GroupIdBox.ClearTextOnFocus = false
GroupIdBox.Parent = CreatePlacePage
Instance.new("UICorner", GroupIdBox).CornerRadius = UDim.new(0, 6)

local PlaceCountBox = Instance.new("TextBox")
PlaceCountBox.Size = UDim2.new(0.28, -10, 0, 22)
PlaceCountBox.Position = UDim2.new(0.72, 0, 0, 23)
PlaceCountBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PlaceCountBox.Text = "1"
PlaceCountBox.PlaceholderText = "Jumlah"
PlaceCountBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PlaceCountBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PlaceCountBox.TextSize = 10
PlaceCountBox.Font = Enum.Font.Gotham
PlaceCountBox.ClearTextOnFocus = false
PlaceCountBox.Parent = CreatePlacePage
Instance.new("UICorner", PlaceCountBox).CornerRadius = UDim.new(0, 6)

local CreatePlaceBtn = Instance.new("TextButton")
CreatePlaceBtn.Size = UDim2.new(1, -24, 0, 25)
CreatePlaceBtn.Position = UDim2.new(0, 12, 0, 49)
CreatePlaceBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
CreatePlaceBtn.Text = "🏗  CREATE PLACE"
CreatePlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreatePlaceBtn.TextSize = 10
CreatePlaceBtn.Font = Enum.Font.GothamBold
CreatePlaceBtn.Parent = CreatePlacePage
Instance.new("UICorner", CreatePlaceBtn).CornerRadius = UDim.new(0, 7)

-- Progress Bar
local ProgressTrack = Instance.new("Frame")
ProgressTrack.Size = UDim2.new(1, -24, 0, 4)
ProgressTrack.Position = UDim2.new(0, 12, 0, 78)
ProgressTrack.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
ProgressTrack.BorderSizePixel = 0
ProgressTrack.Parent = CreatePlacePage
Instance.new("UICorner", ProgressTrack).CornerRadius = UDim.new(1, 0)

local ProgressFill = Instance.new("Frame")
ProgressFill.Size = UDim2.new(0, 0, 1, 0)
ProgressFill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
ProgressFill.BorderSizePixel = 0
ProgressFill.Parent = ProgressTrack
Instance.new("UICorner", ProgressFill).CornerRadius = UDim.new(1, 0)

local StatusBanner = Instance.new("TextLabel")
StatusBanner.Size = UDim2.new(1, -24, 0, 14)
StatusBanner.Position = UDim2.new(0, 12, 0, 84)
StatusBanner.BackgroundTransparency = 1
StatusBanner.Text = "Siap membuat place."
StatusBanner.TextColor3 = Color3.fromRGB(165, 162, 192)
StatusBanner.TextSize = 9
StatusBanner.Font = Enum.Font.GothamMedium
StatusBanner.TextXAlignment = Enum.TextXAlignment.Left
StatusBanner.TextTruncate = Enum.TextTruncate.AtEnd
StatusBanner.Parent = CreatePlacePage

-- Area Hasil Realtime: [Icon Game (ukuran sedang)] | [Name Game] | [Status: private / publik]
local ResultsScroll = Instance.new("ScrollingFrame")
ResultsScroll.Name = "CreatedGamesResults"
ResultsScroll.Size = UDim2.new(1, -24, 1, -106)
ResultsScroll.Position = UDim2.new(0, 12, 0, 100)
ResultsScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
ResultsScroll.BorderSizePixel = 0
ResultsScroll.ScrollBarThickness = 3
ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ResultsScroll.Parent = CreatePlacePage
Instance.new("UICorner", ResultsScroll).CornerRadius = UDim.new(0, 8)
local ResStroke = Instance.new("UIStroke", ResultsScroll)
ResStroke.Color = Color3.fromRGB(52, 48, 82)
ResStroke.Thickness = 1

local ResultsLayout = Instance.new("UIListLayout")
ResultsLayout.Padding = UDim.new(0, 6)
ResultsLayout.SortOrder = Enum.SortOrder.LayoutOrder
ResultsLayout.Parent = ResultsScroll

local ResultsPad = Instance.new("UIPadding")
ResultsPad.PaddingTop = UDim.new(0, 6)
ResultsPad.PaddingBottom = UDim.new(0, 6)
ResultsPad.PaddingLeft = UDim.new(0, 6)
ResultsPad.PaddingRight = UDim.new(0, 6)
ResultsPad.Parent = ResultsScroll

local EmptyResultHint = Instance.new("TextLabel")
EmptyResultHint.Size = UDim2.new(1, 0, 0, 36)
EmptyResultHint.BackgroundTransparency = 1
EmptyResultHint.Text = "Hasil place akan tampil realtime di sini:\nicon game • name game • status (private / publik)"
EmptyResultHint.TextColor3 = Color3.fromRGB(105, 102, 130)
EmptyResultHint.TextSize = 9
EmptyResultHint.Font = Enum.Font.Gotham
EmptyResultHint.Parent = ResultsScroll

local resultCardOrder = 0

local function clearResultCards()
	resultCardOrder = 0
	for _, child in ipairs(ResultsScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	EmptyResultHint.Visible = true
end

local function styleStatusBadge(badge: TextLabel, status: "publik" | "private" | "tidak diketahui", isError: boolean?)
	if isError then
		badge.BackgroundColor3 = Color3.fromRGB(115, 32, 45)
		badge.Text = "gagal"
		badge.TextColor3 = Color3.fromRGB(255, 200, 208)
	elseif status == "publik" then
		badge.BackgroundColor3 = Color3.fromRGB(24, 92, 56)
		badge.Text = "publik"
		badge.TextColor3 = Color3.fromRGB(145, 255, 190)
	elseif status == "private" then
		badge.BackgroundColor3 = Color3.fromRGB(88, 62, 24)
		badge.Text = "private"
		badge.TextColor3 = Color3.fromRGB(255, 222, 145)
	else
		badge.BackgroundColor3 = Color3.fromRGB(48, 46, 68)
		badge.Text = "cek status..."
		badge.TextColor3 = Color3.fromRGB(205, 202, 230)
	end
end

local function appendResultCard(data: GameResultCardData)
	EmptyResultHint.Visible = false
	resultCardOrder += 1

	local card = Instance.new("Frame")
	card.Name = "GameCard_" .. tostring(resultCardOrder)
	card.Size = UDim2.new(1, -2, 0, 68)
	card.BackgroundColor3 = data.isError and Color3.fromRGB(34, 18, 24) or Color3.fromRGB(21, 20, 33)
	card.BorderSizePixel = 0
	card.LayoutOrder = resultCardOrder
	card.Parent = ResultsScroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
	local cardStroke = Instance.new("UIStroke", card)
	cardStroke.Color = data.isError and Color3.fromRGB(165, 65, 85) or Color3.fromRGB(64, 58, 104)
	cardStroke.Thickness = 1

	-- 1. Icon Game (ukuran sedang: 54x54 px menggunakan rbxthumb:// realtime)
	local iconFrame = Instance.new("Frame")
	iconFrame.Size = UDim2.fromOffset(54, 54)
	iconFrame.Position = UDim2.new(0, 7, 0.5, -27)
	iconFrame.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = card
	Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(0, 8)
	local iconStroke = Instance.new("UIStroke", iconFrame)
	iconStroke.Color = Color3.fromRGB(92, 82, 148)
	iconStroke.Thickness = 1

	local gameIconImg = Instance.new("ImageLabel")
	gameIconImg.Size = UDim2.fromScale(1, 1)
	gameIconImg.BackgroundTransparency = 1
	gameIconImg.Image = data.iconImage
	gameIconImg.ScaleType = Enum.ScaleType.Crop
	gameIconImg.Parent = iconFrame
	Instance.new("UICorner", gameIconImg).CornerRadius = UDim.new(0, 8)

	-- 2. Name Game
	local gameNameLabel = Instance.new("TextLabel")
	gameNameLabel.Size = UDim2.new(1, -124, 0, 18)
	gameNameLabel.Position = UDim2.new(0, 68, 0, 7)
	gameNameLabel.BackgroundTransparency = 1
	gameNameLabel.Text = data.gameName
	gameNameLabel.TextColor3 = data.isError and Color3.fromRGB(255, 160, 170) or Color3.fromRGB(248, 248, 255)
	gameNameLabel.TextSize = 11
	gameNameLabel.Font = Enum.Font.GothamBold
	gameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	gameNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	gameNameLabel.Parent = card

	-- 3. Status Realtime (private / publik)
	local statusBadge = Instance.new("TextLabel")
	statusBadge.Size = UDim2.fromOffset(74, 17)
	statusBadge.Position = UDim2.new(0, 68, 0, 27)
	statusBadge.TextSize = 9
	statusBadge.Font = Enum.Font.GothamBold
	statusBadge.Parent = card
	Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 5)
	styleStatusBadge(statusBadge, data.status, data.isError)

	local metaLabel = Instance.new("TextLabel")
	metaLabel.Size = UDim2.new(1, -76, 0, 14)
	metaLabel.Position = UDim2.new(0, 68, 0, 47)
	metaLabel.BackgroundTransparency = 1
	metaLabel.Text = data.metaInfo
	metaLabel.TextColor3 = Color3.fromRGB(150, 146, 178)
	metaLabel.TextSize = 8
	metaLabel.Font = Enum.Font.Code
	metaLabel.TextXAlignment = Enum.TextXAlignment.Left
	metaLabel.TextTruncate = Enum.TextTruncate.AtEnd
	metaLabel.Parent = card

	-- Tombol Refresh Realtime per card (cek ulang icon & status publik/private langsung ke API)
	if not data.isError and data.universeId ~= "" then
		local refreshBtn = Instance.new("TextButton")
		refreshBtn.Size = UDim2.fromOffset(44, 18)
		refreshBtn.Position = UDim2.new(1, -50, 0, 7)
		refreshBtn.BackgroundColor3 = Color3.fromRGB(36, 34, 56)
		refreshBtn.Text = "↻ Cek"
		refreshBtn.TextColor3 = Color3.fromRGB(215, 212, 245)
		refreshBtn.TextSize = 8
		refreshBtn.Font = Enum.Font.GothamBold
		refreshBtn.Parent = card
		Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 5)

		local isRefreshing = false
		refreshBtn.MouseButton1Click:Connect(function()
			if isRefreshing then return end
			isRefreshing = true
			refreshBtn.Text = "..."
			task.spawn(function()
				local latest = fetchRealtimeGameData(data.universeId, CONFIG.Cookie, data.rootPlaceId)
				gameIconImg.Image = latest.iconImage
				gameNameLabel.Text = latest.gameName
				metaLabel.Text = latest.metaInfo
				styleStatusBadge(statusBadge, latest.status, false)
				refreshBtn.Text = "↻ Cek"
				isRefreshing = false
			end)
		end)
	end
end

local function setCreateProgress(state: "idle" | "working" | "ok" | "err", ratio: number, msg: string)
	local clamped = math.clamp(ratio, 0, 1)
	if state == "idle" then
		ProgressFill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
		StatusBanner.TextColor3 = Color3.fromRGB(165, 162, 192)
	elseif state == "working" then
		ProgressFill.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
		StatusBanner.TextColor3 = Color3.fromRGB(175, 205, 255)
	elseif state == "ok" then
		ProgressFill.BackgroundColor3 = Color3.fromRGB(56, 239, 125)
		StatusBanner.TextColor3 = Color3.fromRGB(145, 255, 190)
	else
		ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 86, 102)
		StatusBanner.TextColor3 = Color3.fromRGB(255, 155, 165)
	end
	TweenService:Create(ProgressFill, TweenInfo.new(0.15), {
		Size = UDim2.new(clamped, 0, 1, 0),
	}):Play()
	StatusBanner.Text = msg
end

-- ==========================================
-- HALAMAN 2: SETTING (HANYA COOKIE)
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
SettingTitle.Text = "Pengaturan Cookie"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 13
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local CookieBox = Instance.new("TextBox")
CookieBox.Size = UDim2.new(1, -24, 0, 96)
CookieBox.Position = UDim2.new(0, 12, 0, 32)
CookieBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
CookieBox.Text = CONFIG.Cookie
CookieBox.PlaceholderText = "Tempel .ROBLOSECURITY Cookie di sini..."
CookieBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
CookieBox.TextColor3 = Color3.fromRGB(235, 235, 250)
CookieBox.TextSize = 10
CookieBox.Font = Enum.Font.Gotham
CookieBox.ClearTextOnFocus = false
CookieBox.MultiLine = true
CookieBox.TextWrapped = true
CookieBox.TextXAlignment = Enum.TextXAlignment.Left
CookieBox.TextYAlignment = Enum.TextYAlignment.Top
CookieBox.Parent = SettingPage
Instance.new("UICorner", CookieBox).CornerRadius = UDim.new(0, 7)

local SaveSettingBtn = Instance.new("TextButton")
SaveSettingBtn.Size = UDim2.new(1, -24, 0, 32)
SaveSettingBtn.Position = UDim2.new(0, 12, 0, 136)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN COOKIE"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 11
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 8)

local SettingStatusLabel = Instance.new("TextLabel")
SettingStatusLabel.Size = UDim2.new(1, -24, 0, 56)
SettingStatusLabel.Position = UDim2.new(0, 12, 0, 176)
SettingStatusLabel.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
SettingStatusLabel.Text = CONFIG.Cookie ~= ""
	and ("Status Cookie: Terisi (" .. tostring(#CONFIG.Cookie) .. " karakter)")
	or ("Status Cookie: Kosong • Simpan ke " .. CONFIG.WorkspaceRoot .. "/cookie.txt")
SettingStatusLabel.TextColor3 = Color3.fromRGB(185, 205, 255)
SettingStatusLabel.TextSize = 9
SettingStatusLabel.Font = Enum.Font.Code
SettingStatusLabel.TextWrapped = true
SettingStatusLabel.Parent = SettingPage
Instance.new("UICorner", SettingStatusLabel).CornerRadius = UDim.new(0, 7)

local function syncCookieFromInput(): string
	local boxCookie = normalizeCookie(CookieBox.Text)
	if boxCookie ~= "" then
		CONFIG.Cookie = boxCookie
	end
	return CONFIG.Cookie
end

CookieBox:GetPropertyChangedSignal("Text"):Connect(function()
	CONFIG.Cookie = normalizeCookie(CookieBox.Text)
end)

SaveSettingBtn.MouseButton1Click:Connect(function()
	local c = normalizeCookie(CookieBox.Text)
	CONFIG.Cookie = c
	CookieBox.Text = c

	local okC = saveTextFile("cookie.txt", c)
	SettingStatusLabel.Text = c ~= ""
		and ("Status Cookie: Tersimpan (" .. tostring(#c) .. " karakter)")
		or "Status Cookie: Kosong"
	SettingStatusLabel.TextColor3 = okC and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
	notify("Setting", okC and "Cookie tersimpan." or "Gagal menyimpan cookie.")
end)

-- Navigasi Sidebar
createNavButton("CreatePlace", "🏗  Create Place", 1).MouseButton1Click:Connect(function()
	switchTab("CreatePlace")
end)
createNavButton("Setting", "⚙  Setting", 2).MouseButton1Click:Connect(function()
	switchTab("Setting")
end)
switchTab("CreatePlace")

-- ==========================================
-- LOGIKA CREATE PLACE
-- ==========================================
local isCreatingPlace = false
CreatePlaceBtn.MouseButton1Click:Connect(function()
	if isCreatingPlace then return end
	local cookieVal = syncCookieFromInput()
	if cookieVal == "" then
		setCreateProgress("err", 0, "Cookie .ROBLOSECURITY belum diisi di tab Setting.")
		notify("Create Place", "Cookie kosong.")
		return
	end

	local tplId = tonumber(trim(TemplateIdBox.Text):match("%d+")) or 95206881
	local grpId = tonumber(trim(GroupIdBox.Text):match("%d+"))
	local count = math.clamp(tonumber(trim(PlaceCountBox.Text):match("%d+")) or 1, 1, 50)

	isCreatingPlace = true
	clearResultCards()
	setCreateProgress("working", 0.1, "Membuat " .. tostring(count) .. " place...")

	task.spawn(function()
		local csrf = ""
		local sukses, gagal = 0, 0

		for i = 1, count do
			setCreateProgress("working", (i - 0.5) / count, string.format("Membuat place %d dari %d...", i, count))

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

			local res, ok, info = sendCreateRequest(csrf)
			if not ok and res and tonumber(res.StatusCode or res.Status or res.status_code) == 403 then
				local newCsrf = getHeaderCaseInsensitive(res.Headers, "x-csrf-token")
				if newCsrf and newCsrf ~= "" then
					csrf = newCsrf
					res, ok, info = sendCreateRequest(csrf)
				end
			end

			local bodyStr = res and tostring(res.Body or "") or ""
			if ok and res then
				sukses += 1
				saveTextFile("Logs/place_" .. tostring(os.time()) .. "_" .. tostring(i) .. ".json", bodyStr)

				local createdUnivId: string? = nil
				local createdRootPlaceId: string? = nil
				local okDec, decoded = pcall(function()
					return HttpService:JSONDecode(bodyStr)
				end)
				if okDec and type(decoded) == "table" then
					if decoded.universeId ~= nil then
						createdUnivId = tostring(decoded.universeId):match("%d+")
					elseif decoded.id ~= nil then
						createdUnivId = tostring(decoded.id):match("%d+")
					end
					if decoded.rootPlaceId ~= nil then
						createdRootPlaceId = tostring(decoded.rootPlaceId):match("%d+")
					end
				end
				if not createdUnivId then
					createdUnivId = bodyStr:match('"universeId"%s*:%s*(%d+)')
				end
				if not createdRootPlaceId then
					createdRootPlaceId = bodyStr:match('"rootPlaceId"%s*:%s*(%d+)')
				end

				if createdUnivId and createdUnivId ~= "" then
					local cardData = fetchRealtimeGameData(createdUnivId, cookieVal, createdRootPlaceId)
					appendResultCard(cardData)
				else
					appendResultCard({
						universeId = "",
						rootPlaceId = createdRootPlaceId,
						iconImage = "rbxasset://textures/ui/GuiImagePlaceholder.png",
						gameName = "Place Baru #" .. tostring(i),
						status = "tidak diketahui",
						metaInfo = "Universe ID tidak terbaca dari respons",
						isError = false,
					})
				end
			else
				gagal += 1
				appendResultCard({
					universeId = "",
					rootPlaceId = nil,
					iconImage = "rbxasset://textures/ui/GuiImagePlaceholder.png",
					gameName = "Place #" .. tostring(i) .. " (" .. info .. ")",
					status = "private",
					metaInfo = bodyStr ~= "" and bodyStr:sub(1, 90) or "Gagal membuat place",
					isError = true,
				})
			end

			setCreateProgress((gagal == 0) and "working" or "err", i / count, string.format("Progress %d/%d • OK: %d | Gagal: %d", i, count, sukses, gagal))
			if i < count then
				task.wait(1)
			end
		end

		local allOk = (sukses > 0 and gagal == 0)
		setCreateProgress(allOk and "ok" or "err", 1, string.format("Selesai: %d berhasil, %d gagal.", sukses, gagal))
		notify("Create Place", string.format("Selesai: %d berhasil, %d gagal.", sukses, gagal))
		isCreatingPlace = false
	end)
end)
