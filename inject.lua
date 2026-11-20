--!strict
-- Plugin Studio Lite (Delta Executor Edition - Create Place, Voice Chat, Setting & Console) by Ikyy
-- Alur: Input GUI -> Validasi -> Kirim Permintaan -> Output Realtime (Icon Game, Name Game, Status + Console)

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
	DefaultUniverseId = "10516113765",
	UserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
}

local MEMORY_FILES: {[string]: string} = {}
local CONSOLE_LINES: {string} = {}

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

local function setClipboardText(text: string): boolean
	local clipFns = { ENV.setclipboard, ENV.toclipboard, ENV.set_clipboard }
	for _, fn in ipairs(clipFns) do
		if type(fn) == "function" then
			local ok = pcall(fn, text)
			if ok then return true end
		end
	end
	return false
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

-- ==========================================
-- CONSOLE LOGGER BRIDGE
-- ==========================================
local appendConsoleLineFn: ((level: string, message: string) -> ())? = nil

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

local function apiRequest(options: {
	Url: string,
	Method: string?,
	Headers: {[string]: string}?,
	Body: string?,
	Retries: number?,
})
	local reqFn = getDeltaHttpFunc()
	if not reqFn then
		pushConsole("ERR", "HTTP function tidak tersedia di executor")
		return nil, false, "HTTP function tidak tersedia di executor"
	end

	local methodStr = options.Method or "GET"
	pushConsole("REQ", methodStr .. " " .. options.Url)

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
			Method = methodStr,
			Headers = baseHeaders,
			Body = options.Body,
		})
		if ok and type(res) == "table" then
			lastRes = res
			local code = tonumber(res.StatusCode or res.Status or res.status_code) or 0
			local rawBody = tostring(res.Body or "")
			local snippet = rawBody:gsub("[\r\n]+", " ")
			if #snippet > 160 then
				snippet = snippet:sub(1, 160) .. "..."
			end

			lastOk = (code >= 200 and code < 300)
			if lastOk then
				pushConsole("OK", string.format("HTTP %d %s | %s", code, methodStr, snippet ~= "" and snippet or "(empty body)"))
				return res, true, "HTTP " .. tostring(code)
			end
			lastErr = "HTTP " .. tostring(code)
			pushConsole("WARN", string.format("HTTP %d %s | %s", code, methodStr, snippet ~= "" and snippet or "(no body)"))
			if code == 400 or code == 401 or code == 403 or code == 404 then
				return res, false, lastErr
			end
		else
			lastErr = tostring(res)
			pushConsole("ERR", methodStr .. " gagal: " .. lastErr)
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
					return "rbxthumb://type=GameIcon&id=" .. cleanUniv .. "&w=150&h=150"
				end
			end
		end
	end

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

-- ==========================================
-- API VOICE CHAT UNIVERSE (voice.roblox.com)
-- ==========================================
local function getUniverseVoiceSettings(universeId: string, cookieVal: string): (boolean, boolean?, {[string]: any}, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	if cleanUniv == "" then
		return false, nil, {}, "Universe ID tidak valid"
	end

	local hdrs: {[string]: string} = {}
	if trim(cookieVal) ~= "" then
		hdrs["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal)
	end

	local res, ok, info = apiRequest({
		Url = "https://voice.roblox.com/v1/settings/universe/" .. cleanUniv,
		Method = "GET",
		Headers = hdrs,
		Retries = 1,
	})

	if not ok or not res then
		return false, nil, {}, info
	end

	local bodyStr = tostring(res.Body or "")
	local okDec, decoded = pcall(function()
		return HttpService:JSONDecode(bodyStr)
	end)
	if not okDec or type(decoded) ~= "table" then
		return false, nil, {}, "Gagal decode JSON voice.roblox.com"
	end

	local voiceState: boolean? = nil
	if type(decoded.isUniverseEnabledForVoice) == "boolean" then
		voiceState = decoded.isUniverseEnabledForVoice
	elseif type(decoded.isVoiceEnabled) == "boolean" then
		voiceState = decoded.isVoiceEnabled
	elseif type(decoded.optIn) == "boolean" then
		voiceState = decoded.optIn
	end

	return true, voiceState, decoded, "OK"
end

local function setUniverseVoiceSettings(universeId: string, cookieVal: string, enabled: boolean, csrfSeed: string): (boolean, string, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	if cleanUniv == "" then
		return false, "Universe ID tidak valid", csrfSeed
	end

	local jsonBody = HttpService:JSONEncode({
		optIn = enabled,
	})
	local currentCsrf = csrfSeed

	local function sendVoicePost(token: string)
		local hdrs: {[string]: string} = {
			["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
			["Content-Type"] = "application/json",
			["Origin"] = "https://create.roblox.com",
			["Referer"] = "https://create.roblox.com/",
		}
		if token ~= "" then
			hdrs["X-CSRF-TOKEN"] = token
		end
		return apiRequest({
			Url = "https://voice.roblox.com/v1/settings/universe/" .. cleanUniv,
			Method = "POST",
			Headers = hdrs,
			Body = jsonBody,
			Retries = 1,
		})
	end

	local res, ok, info = sendVoicePost(currentCsrf)
	if not ok and res and tonumber(res.StatusCode or res.Status or res.status_code) == 403 then
		local newToken = getHeaderCaseInsensitive(res.Headers, "x-csrf-token")
		if newToken and newToken ~= "" then
			pushConsole("INFO", "Refresh X-CSRF-TOKEN otomatis untuk voice.roblox.com")
			currentCsrf = newToken
			res, ok, info = sendVoicePost(currentCsrf)
		end
	end

	local bodyStr = res and tostring(res.Body or "") or ""
	if ok then
		saveTextFile("Logs/voice_" .. cleanUniv .. "_" .. tostring(os.time()) .. ".json", bodyStr)
		return true, "Voice Chat Universe berhasil " .. (enabled and "DIAKTIFKAN" or "DINONAKTIFKAN"), currentCsrf
	end

	local detail = bodyStr ~= "" and (" (" .. bodyStr:sub(1, 120) .. ")") or ""
	return false, info .. detail, currentCsrf
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
-- KOMPONEN UI MODERN: TOGGLE SWITCH KANAN-KIRI
-- ==========================================
local function createModernToggleSwitch(parent: Instance, initialState: boolean?, onChanged: ((boolean) -> ())?)
	local isOn = initialState == true

	local capsule = Instance.new("TextButton")
	capsule.Name = "ModernToggleSwitch"
	capsule.Size = UDim2.fromOffset(74, 28)
	capsule.BackgroundColor3 = isOn and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(42, 40, 62)
	capsule.Text = ""
	capsule.AutoButtonColor = false
	capsule.Parent = parent
	Instance.new("UICorner", capsule).CornerRadius = UDim.new(1, 0)

	local capStroke = Instance.new("UIStroke", capsule)
	capStroke.Color = isOn and Color3.fromRGB(110, 245, 160) or Color3.fromRGB(92, 86, 132)
	capStroke.Thickness = 1.2

	local sideLabel = Instance.new("TextLabel")
	sideLabel.Size = UDim2.new(1, -30, 1, 0)
	sideLabel.Position = isOn and UDim2.new(0, 8, 0, 0) or UDim2.new(0, 22, 0, 0)
	sideLabel.BackgroundTransparency = 1
	sideLabel.Text = isOn and "ON" or "OFF"
	sideLabel.TextColor3 = isOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 182, 212)
	sideLabel.TextSize = 9
	sideLabel.Font = Enum.Font.GothamBold
	sideLabel.TextXAlignment = isOn and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
	sideLabel.Parent = capsule

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(22, 22)
	knob.Position = isOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
	knob.BackgroundColor3 = Color3.fromRGB(250, 250, 255)
	knob.BorderSizePixel = 0
	knob.Parent = capsule
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function applyVisual(state: boolean, animate: boolean)
		isOn = state
		local targetBg = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(42, 40, 62)
		local targetStroke = state and Color3.fromRGB(110, 245, 160) or Color3.fromRGB(92, 86, 132)
		local targetKnobPos = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)

		sideLabel.Text = state and "ON" or "OFF"
		sideLabel.TextColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(185, 182, 212)
		sideLabel.TextXAlignment = state and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
		sideLabel.Position = state and UDim2.new(0, 9, 0, 0) or UDim2.new(0, 21, 0, 0)
		capStroke.Color = targetStroke

		if animate then
			TweenService:Create(capsule, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = targetBg,
			}):Play()
			TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = targetKnobPos,
			}):Play()
		else
			capsule.BackgroundColor3 = targetBg
			knob.Position = targetKnobPos
		end
	end

	capsule.MouseButton1Click:Connect(function()
		applyVisual(not isOn, true)
		if onChanged then
			onChanged(isOn)
		end
	end)

	return {
		Button = capsule,
		GetState = function(): boolean
			return isOn
		end,
		SetState = function(state: boolean, animate: boolean?)
			applyVisual(state, animate ~= false)
		end,
	}
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
SubTitleLabel.Size = UDim2.new(0, 240, 0, 11)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 5)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • CREATE PLACE & VOICE"
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
MetaLabel.Text = "by Ikyy • Studio & Universe • @" .. LocalPlayer.Name
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

local NavListFrame = Instance.new("Frame")
NavListFrame.Size = UDim2.new(1, -10, 1, -10)
NavListFrame.Position = UDim2.new(0, 5, 0, 5)
NavListFrame.BackgroundTransparency = 1
NavListFrame.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 5)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavListFrame

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
-- HALAMAN 2: VOICE CHAT UNIVERSE (voice.roblox.com)
-- ==========================================
local VoicePage = Instance.new("Frame")
VoicePage.Size = UDim2.fromScale(1, 1)
VoicePage.BackgroundTransparency = 1
VoicePage.Visible = false
VoicePage.Parent = ContentArea
tabPages["VoiceChat"] = VoicePage

local VoiceTitle = Instance.new("TextLabel")
VoiceTitle.Size = UDim2.new(1, -24, 0, 16)
VoiceTitle.Position = UDim2.new(0, 12, 0, 6)
VoiceTitle.BackgroundTransparency = 1
VoiceTitle.Text = "Voice Chat Universe (voice.roblox.com)"
VoiceTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
VoiceTitle.TextSize = 12
VoiceTitle.Font = Enum.Font.GothamBold
VoiceTitle.TextXAlignment = Enum.TextXAlignment.Left
VoiceTitle.Parent = VoicePage

local VoiceUniverseBox = Instance.new("TextBox")
VoiceUniverseBox.Size = UDim2.new(1, -108, 0, 26)
VoiceUniverseBox.Position = UDim2.new(0, 12, 0, 26)
VoiceUniverseBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
VoiceUniverseBox.Text = CONFIG.DefaultUniverseId
VoiceUniverseBox.PlaceholderText = "Masukkan Universe ID..."
VoiceUniverseBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
VoiceUniverseBox.TextColor3 = Color3.fromRGB(235, 235, 250)
VoiceUniverseBox.TextSize = 10
VoiceUniverseBox.Font = Enum.Font.Gotham
VoiceUniverseBox.ClearTextOnFocus = false
VoiceUniverseBox.Parent = VoicePage
Instance.new("UICorner", VoiceUniverseBox).CornerRadius = UDim.new(0, 7)

local SyncVoiceBtn = Instance.new("TextButton")
SyncVoiceBtn.Size = UDim2.fromOffset(78, 26)
SyncVoiceBtn.Position = UDim2.new(1, -90, 0, 26)
SyncVoiceBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 52)
SyncVoiceBtn.Text = "↻ Cek Status"
SyncVoiceBtn.TextColor3 = Color3.fromRGB(215, 212, 248)
SyncVoiceBtn.TextSize = 9
SyncVoiceBtn.Font = Enum.Font.GothamBold
SyncVoiceBtn.Parent = VoicePage
Instance.new("UICorner", SyncVoiceBtn).CornerRadius = UDim.new(0, 7)
local SyncStroke = Instance.new("UIStroke", SyncVoiceBtn)
SyncStroke.Color = Color3.fromRGB(82, 76, 124)
SyncStroke.Thickness = 1

local SwitchCard = Instance.new("Frame")
SwitchCard.Size = UDim2.new(1, -24, 0, 52)
SwitchCard.Position = UDim2.new(0, 12, 0, 60)
SwitchCard.BackgroundColor3 = Color3.fromRGB(24, 23, 38)
SwitchCard.BorderSizePixel = 0
SwitchCard.Parent = VoicePage
Instance.new("UICorner", SwitchCard).CornerRadius = UDim.new(0, 9)
local SwitchCardStroke = Instance.new("UIStroke", SwitchCard)
SwitchCardStroke.Color = Color3.fromRGB(68, 62, 112)
SwitchCardStroke.Thickness = 1

local SwitchTitle = Instance.new("TextLabel")
SwitchTitle.Size = UDim2.new(1, -104, 0, 16)
SwitchTitle.Position = UDim2.new(0, 12, 0, 9)
SwitchTitle.BackgroundTransparency = 1
SwitchTitle.Text = "Enable Voice Chat (Universe)"
SwitchTitle.TextColor3 = Color3.fromRGB(248, 248, 255)
SwitchTitle.TextSize = 11
SwitchTitle.Font = Enum.Font.GothamBold
SwitchTitle.TextXAlignment = Enum.TextXAlignment.Left
SwitchTitle.Parent = SwitchCard

local SwitchDesc = Instance.new("TextLabel")
SwitchDesc.Size = UDim2.new(1, -104, 0, 14)
SwitchDesc.Position = UDim2.new(0, 12, 0, 26)
SwitchDesc.BackgroundTransparency = 1
SwitchDesc.Text = "Geser kiri/kanan untuk memilih OFF atau ON"
SwitchDesc.TextColor3 = Color3.fromRGB(150, 146, 182)
SwitchDesc.TextSize = 9
SwitchDesc.Font = Enum.Font.GothamMedium
SwitchDesc.TextXAlignment = Enum.TextXAlignment.Left
SwitchDesc.Parent = SwitchCard

local VoiceSwitch = createModernToggleSwitch(SwitchCard, false, function(state: boolean)
	SwitchDesc.Text = state
		and "Target: Voice Chat DIAKTIFKAN (optIn = true)"
		or "Target: Voice Chat DINONAKTIFKAN (optIn = false)"
end)
VoiceSwitch.Button.Position = UDim2.new(1, -86, 0.5, -14)

local ApplyVoiceBtn = Instance.new("TextButton")
ApplyVoiceBtn.Size = UDim2.new(1, -24, 0, 28)
ApplyVoiceBtn.Position = UDim2.new(0, 12, 0, 120)
ApplyVoiceBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ApplyVoiceBtn.Text = "⚡  TERAPKAN PENGATURAN VOICE CHAT"
ApplyVoiceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyVoiceBtn.TextSize = 10
ApplyVoiceBtn.Font = Enum.Font.GothamBold
ApplyVoiceBtn.Parent = VoicePage
Instance.new("UICorner", ApplyVoiceBtn).CornerRadius = UDim.new(0, 7)

local VoicePreviewCard = Instance.new("Frame")
VoicePreviewCard.Size = UDim2.new(1, -24, 1, -162)
VoicePreviewCard.Position = UDim2.new(0, 12, 0, 155)
VoicePreviewCard.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
VoicePreviewCard.BorderSizePixel = 0
VoicePreviewCard.Parent = VoicePage
Instance.new("UICorner", VoicePreviewCard).CornerRadius = UDim.new(0, 8)
local VoicePrevStroke = Instance.new("UIStroke", VoicePreviewCard)
VoicePrevStroke.Color = Color3.fromRGB(52, 48, 82)
VoicePrevStroke.Thickness = 1

local VoiceIconImg = Instance.new("ImageLabel")
VoiceIconImg.Size = UDim2.fromOffset(52, 52)
VoiceIconImg.Position = UDim2.new(0, 8, 0.5, -26)
VoiceIconImg.BackgroundColor3 = Color3.fromRGB(20, 19, 32)
VoiceIconImg.Image = resolveRealtimeGameIcon(CONFIG.DefaultUniverseId, nil, CONFIG.Cookie)
VoiceIconImg.ScaleType = Enum.ScaleType.Crop
VoiceIconImg.Parent = VoicePreviewCard
Instance.new("UICorner", VoiceIconImg).CornerRadius = UDim.new(0, 8)

local VoiceGameName = Instance.new("TextLabel")
VoiceGameName.Size = UDim2.new(1, -74, 0, 16)
VoiceGameName.Position = UDim2.new(0, 68, 0, 8)
VoiceGameName.BackgroundTransparency = 1
VoiceGameName.Text = "Universe #" .. CONFIG.DefaultUniverseId
VoiceGameName.TextColor3 = Color3.fromRGB(245, 245, 255)
VoiceGameName.TextSize = 11
VoiceGameName.Font = Enum.Font.GothamBold
VoiceGameName.TextXAlignment = Enum.TextXAlignment.Left
VoiceGameName.TextTruncate = Enum.TextTruncate.AtEnd
VoiceGameName.Parent = VoicePreviewCard

local VoiceStatusText = Instance.new("TextLabel")
VoiceStatusText.Size = UDim2.new(1, -74, 0, 26)
VoiceStatusText.Position = UDim2.new(0, 68, 0, 26)
VoiceStatusText.BackgroundTransparency = 1
VoiceStatusText.Text = "Siap sinkronisasi status Voice Chat universe."
VoiceStatusText.TextColor3 = Color3.fromRGB(165, 162, 194)
VoiceStatusText.TextSize = 9
VoiceStatusText.Font = Enum.Font.GothamMedium
VoiceStatusText.TextXAlignment = Enum.TextXAlignment.Left
VoiceStatusText.TextWrapped = true
VoiceStatusText.Parent = VoicePreviewCard

-- ==========================================
-- HALAMAN 3: SETTING (COOKIE)
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

-- ==========================================
-- HALAMAN 4: CONSOLE OUTPUT SERVER / PERMINTAAN
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
ConsoleTitle.Text = "Server & Request Console"
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
	if level == "OK" then
		return Color3.fromRGB(120, 255, 180)
	elseif level == "WARN" then
		return Color3.fromRGB(255, 215, 120)
	elseif level == "ERR" then
		return Color3.fromRGB(255, 125, 140)
	elseif level == "REQ" then
		return Color3.fromRGB(130, 205, 255)
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
-- LOGIKA COOKIE & NAVIGASI
-- ==========================================
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
	pushConsole(okC and "OK" or "ERR", okC and ("Cookie disimpan (" .. tostring(#c) .. " chars)") or "Gagal menyimpan cookie.txt")
	notify("Setting", okC and "Cookie tersimpan." or "Gagal menyimpan cookie.")
end)

createNavButton("CreatePlace", "🏗  Create Place", 1).MouseButton1Click:Connect(function()
	switchTab("CreatePlace")
end)
createNavButton("VoiceChat", "🎙  Voice Chat", 2).MouseButton1Click:Connect(function()
	switchTab("VoiceChat")
end)
createNavButton("Setting", "⚙  Setting", 3).MouseButton1Click:Connect(function()
	switchTab("Setting")
end)
createNavButton("Console", "🖥  Console", 4).MouseButton1Click:Connect(function()
	switchTab("Console")
end)
switchTab("CreatePlace")

pushConsole("INFO", "Plugin Studio Lite siap (endpoint Voice: voice.roblox.com).")

-- ==========================================
-- LOGIKA VOICE CHAT UNIVERSE (voice.roblox.com)
-- ==========================================
local isSyncingVoice = false
local isApplyingVoice = false
local cachedVoiceCsrf = ""

local function refreshVoiceUniversePreview(univId: string, cookieVal: string)
	local cardInfo = fetchRealtimeGameData(univId, cookieVal, nil)
	VoiceIconImg.Image = cardInfo.iconImage
	VoiceGameName.Text = cardInfo.gameName .. " (" .. cardInfo.status .. ")"

	local okVoice, voiceOn, rawVoiceData, errVoice = getUniverseVoiceSettings(univId, cookieVal)
	if okVoice and type(voiceOn) == "boolean" then
		VoiceSwitch.SetState(voiceOn, true)
		VoiceStatusText.TextColor3 = voiceOn and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 210, 140)
		VoiceStatusText.Text = "Voice Chat saat ini: " .. (voiceOn and "AKTIF (ON)" or "NONAKTIF (OFF)")
		pushConsole("OK", string.format("Universe #%s isUniverseEnabledForVoice = %s", univId, tostring(voiceOn)))
	elseif okVoice then
		VoiceStatusText.TextColor3 = Color3.fromRGB(185, 205, 255)
		VoiceStatusText.Text = "Respons voice.roblox.com terbaca (cek Console)"
		pushConsole("INFO", string.format("Universe #%s voice JSON: %s", univId, HttpService:JSONEncode(rawVoiceData)))
	else
		VoiceStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		VoiceStatusText.Text = "Gagal cek Voice Chat: " .. errVoice
		pushConsole("ERR", string.format("Universe #%s gagal cek voice: %s", univId, errVoice))
	end
end

SyncVoiceBtn.MouseButton1Click:Connect(function()
	if isSyncingVoice or isApplyingVoice then return end
	local cookieVal = syncCookieFromInput()
	local univId = trim(VoiceUniverseBox.Text):match("%d+") or ""
	if univId == "" then
		VoiceStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		VoiceStatusText.Text = "Masukkan Universe ID yang valid."
		pushConsole("WARN", "Cek Status Voice dibatalkan: Universe ID kosong/tidak valid.")
		return
	end

	isSyncingVoice = true
	SyncVoiceBtn.Text = "..."
	task.spawn(function()
		refreshVoiceUniversePreview(univId, cookieVal)
		SyncVoiceBtn.Text = "↻ Cek Status"
		isSyncingVoice = false
	end)
end)

ApplyVoiceBtn.MouseButton1Click:Connect(function()
	if isApplyingVoice or isSyncingVoice then return end
	local cookieVal = syncCookieFromInput()
	if cookieVal == "" then
		VoiceStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		VoiceStatusText.Text = "Cookie .ROBLOSECURITY kosong. Isi di tab Setting."
		pushConsole("ERR", "Apply Voice gagal: Cookie kosong.")
		notify("Voice Chat", "Cookie belum diisi.")
		return
	end

	local univId = trim(VoiceUniverseBox.Text):match("%d+") or ""
	if univId == "" then
		VoiceStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		VoiceStatusText.Text = "Universe ID tidak valid."
		pushConsole("ERR", "Apply Voice gagal: Universe ID tidak valid.")
		return
	end

	local targetState = VoiceSwitch.GetState()
	isApplyingVoice = true
	ApplyVoiceBtn.Text = "⏳  MENGIRIM..."
	VoiceStatusText.TextColor3 = Color3.fromRGB(175, 205, 255)
	VoiceStatusText.Text = "Mengirim optIn = " .. tostring(targetState) .. " ke voice.roblox.com..."

	task.spawn(function()
		local okPost, msgPost, nextCsrf = setUniverseVoiceSettings(univId, cookieVal, targetState, cachedVoiceCsrf)
		cachedVoiceCsrf = nextCsrf

		if okPost then
			VoiceStatusText.TextColor3 = Color3.fromRGB(145, 255, 190)
			VoiceStatusText.Text = msgPost
			pushConsole("OK", msgPost .. " (Universe #" .. univId .. ")")
			notify("Voice Chat", msgPost)
			refreshVoiceUniversePreview(univId, cookieVal)
		else
			VoiceStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
			VoiceStatusText.Text = "Gagal: " .. msgPost
			pushConsole("ERR", "Apply Voice gagal (#" .. univId .. "): " .. msgPost)
			notify("Voice Chat", "Gagal mengubah status Voice Chat.")
		end

		ApplyVoiceBtn.Text = "⚡  TERAPKAN PENGATURAN VOICE CHAT"
		isApplyingVoice = false
	end)
end)

-- ==========================================
-- LOGIKA CREATE PLACE
-- ==========================================
local isCreatingPlace = false
CreatePlaceBtn.MouseButton1Click:Connect(function()
	if isCreatingPlace then return end
	local cookieVal = syncCookieFromInput()
	if cookieVal == "" then
		setCreateProgress("err", 0, "Cookie .ROBLOSECURITY belum diisi di tab Setting.")
		pushConsole("ERR", "Create Place gagal: Cookie kosong.")
		notify("Create Place", "Cookie kosong.")
		return
	end

	local tplId = tonumber(trim(TemplateIdBox.Text):match("%d+")) or 95206881
	local grpId = tonumber(trim(GroupIdBox.Text):match("%d+"))
	local count = math.clamp(tonumber(trim(PlaceCountBox.Text):match("%d+")) or 1, 1, 50)

	isCreatingPlace = true
	clearResultCards()
	setCreateProgress("working", 0.1, "Membuat " .. tostring(count) .. " place...")
	pushConsole("INFO", string.format("Mulai Create Place: count=%d, template=%d, group=%s", count, tplId, grpId and tostring(grpId) or "none"))

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
					pushConsole("INFO", "Refresh X-CSRF-TOKEN otomatis untuk Create Place #" .. tostring(i))
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
					pushConsole("OK", string.format("Place #%d dibuat -> UniverseId: %s | RootPlaceId: %s", i, createdUnivId, tostring(createdRootPlaceId or "-")))
					local cardData = fetchRealtimeGameData(createdUnivId, cookieVal, createdRootPlaceId)
					appendResultCard(cardData)
				else
					pushConsole("WARN", string.format("Place #%d sukses (%s), namun UniverseId tidak terbaca", i, info))
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
				pushConsole("ERR", string.format("Place #%d gagal (%s): %s", i, info, bodyStr:sub(1, 100)))
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
		pushConsole("INFO", string.format("Create Place selesai: %d berhasil, %d gagal.", sukses, gagal))
		notify("Create Place", string.format("Selesai: %d berhasil, %d gagal.", sukses, gagal))
		isCreatingPlace = false
	end)
end)
