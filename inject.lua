--!strict
-- Plugin Studio Lite (Delta Executor Edition) by Ikyy
-- Alur: Input GUI -> Validasi -> Kirim Permintaan -> Output Hasil

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
	SpoofFilter = "Auto", -- Auto, Suara, Stiker, Model, Anim
	SpoofSourceMode = "ID", -- "ID" atau "TXT"
	SessionId = "YGF_0000",
	UserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
}

local MEMORY_FILES: {[string]: string} = {}

export type SpoofEntry = {
	kind: "audio" | "rbxm",
	name: string,
	id: string,
	playbackSpeed: number?,
	imageId: string?,
	statusType: string?, -- "Dance" / "Emote" (untuk rbxm)
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

local function sanitizeFileName(name: string): string
	local cleaned = trim(name):gsub('[\\/:*?"<>|]+', "_"):gsub("%s+", " ")
	cleaned = trim(cleaned)
	if cleaned == "" then
		return "UnnamedAsset"
	end
	return cleaned:sub(1, 80)
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

local function copyToClipboard(text: string): boolean
	local env = {}
	pcall(function()
		if type(getgenv) == "function" and type(getgenv()) == "table" then
			for k, v in pairs(getgenv()) do env[k] = v end
		end
	end)
	pcall(function()
		for k, v in pairs(getfenv(0)) do
			if env[k] == nil then env[k] = v end
		end
	end)
	local clipFn = env.setclipboard or env.toclipboard or (type(env.syn) == "table" and env.syn.write_clipboard)
	if type(clipFn) == "function" then
		local ok = pcall(clipFn, text)
		if ok then return true end
	end
	return false
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
local fnListFiles = type(ENV.listfiles) == "function" and ENV.listfiles or nil

local function ensureFolders()
	if not fnMakeFolder then return end
	local folders = {
		CONFIG.WorkspaceRoot,
		CONFIG.WorkspaceRoot .. "/TXT",
		CONFIG.WorkspaceRoot .. "/SPOOF",
		CONFIG.WorkspaceRoot .. "/SPOOF/info",
		CONFIG.WorkspaceRoot .. "/SPOOF/music",
		CONFIG.WorkspaceRoot .. "/SPOOF/animasi",
		CONFIG.WorkspaceRoot .. "/Uploads",
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

local function scanFilesByPrefix(prefixes: {string}, extFilter: string?): {string}
	ensureFolders()
	local seen: {[string]: boolean} = {}
	local results: {string} = {}

	local function matchesAnyPrefix(normPath: string): boolean
		for _, pref in ipairs(prefixes) do
			if normPath:sub(1, #pref) == pref and not normPath:match("/$") then
				if not extFilter or normPath:lower():sub(-#extFilter) == extFilter:lower() then
					return true
				end
			end
		end
		return false
	end

	local function addCandidate(raw: string)
		local norm = normalizeWorkspaceRelPath(raw)
		if matchesAnyPrefix(norm) and not seen[norm] then
			seen[norm] = true
			table.insert(results, norm)
		end
	end

	if fnListFiles then
		local scanDirs: {string} = {}
		local dirSeen: {[string]: boolean} = {}
		for _, pref in ipairs(prefixes) do
			local baseDir = CONFIG.WorkspaceRoot .. "/" .. pref:gsub("/+$", "")
			if not dirSeen[baseDir] then
				dirSeen[baseDir] = true
				table.insert(scanDirs, baseDir)
			end
		end
		table.insert(scanDirs, CONFIG.WorkspaceRoot .. "/SPOOF/music")
		table.insert(scanDirs, CONFIG.WorkspaceRoot .. "/SPOOF/animasi")
		table.insert(scanDirs, CONFIG.WorkspaceRoot .. "/SPOOF/info")

		for _, dir in ipairs(scanDirs) do
			local okList, listRes = pcall(fnListFiles, dir)
			if okList and type(listRes) == "table" then
				for _, entry in ipairs(listRes) do
					if type(entry) == "string" then
						local isDir = false
						if fnIsFolder then
							local okD, resD = pcall(fnIsFolder, entry)
							isDir = okD and (resD == true)
						end
						if not isDir then
							addCandidate(entry)
						end
					end
				end
			end
		end
	end

	for key, _ in pairs(MEMORY_FILES) do
		addCandidate(key)
	end

	table.sort(results)
	return results
end

-- ==========================================
-- PARSER FILE TXT (AUDIO & RBXM)
-- ==========================================
local function parseTxtEntries(content: string, forceKind: "auto" | "audio" | "rbxm"): {SpoofEntry}
	local entries: {SpoofEntry} = {}
	local seenKey: {[string]: boolean} = {}

	local function pushEntry(e: SpoofEntry)
		if e.id == "" or not e.id:match("^%d+$") or #e.id < 4 then return end
		local key = e.kind .. ":" .. e.id .. ":" .. e.name
		if not seenKey[key] then
			seenKey[key] = true
			table.insert(entries, e)
		end
	end

	-- 1. Parse blok RBXM: ["Dances"] / ["Emotes"] = { { "Nama", 12345, "Dance" }, ... }
	if forceKind ~= "audio" then
		for section, blockBody in content:gmatch('%["([Dd]ances|[Ee]motes)"%]%s*=%s*{(.-)}') do
			local defaultStatus = (section:lower():sub(1, 5) == "dance") and "Dance" or "Emote"
			for tupleBody in blockBody:gmatch("{(.-)}") do
				local itemName = tupleBody:match('^%s*"(.-)"%s*,') or tupleBody:match("^%s*'(.-)'%s*,")
				local idStr = tupleBody:match(",%s*(%d+)")
				local explicitStatus = tupleBody:match(',%s*"([^"]+)"%s*$') or tupleBody:match(",%s*'([^']+)'%s*$")
				if itemName and idStr then
					local st = defaultStatus
					if explicitStatus then
						if explicitStatus:lower():find("dance") then
							st = "Dance"
						elseif explicitStatus:lower():find("emote") then
							st = "Emote"
						else
							st = explicitStatus
						end
					end
					pushEntry({
						kind = "rbxm",
						name = trim(itemName),
						id = idStr,
						statusType = st,
					})
				end
			end
		end
	end

	-- 2. Parse blok Audio tabel Luau: ["SongName"], ["SoundIds"], ["PlaybackSpeed"], ["ImageId"]
	if forceKind ~= "rbxm" then
		for block in content:gmatch("{(.-)}%s*,?") do
			local songName = block:match('%["SongName"%]%s*=%s*"(.-)"') or block:match("%[%\"SongName\"%]%s*=%s*'(.-)'")
			local playbackStr = block:match('%["PlaybackSpeed"%]%s*=%s*([%d%.]+)')
			local imageId = block:match('%["ImageId"%]%s*=%s*"(.-)"')

			local soundIdsBlock = block:match('%["SoundIds"%]%s*=%s*{(.-)}')
			local foundAnySound = false
			if soundIdsBlock then
				for sid in soundIdsBlock:gmatch("(%d+)") do
					if #sid >= 4 then
						foundAnySound = true
						pushEntry({
							kind = "audio",
							name = trim(songName or ("Song_" .. sid)),
							id = sid,
							playbackSpeed = tonumber(playbackStr) or 1.0,
							imageId = imageId,
						})
					end
				end
			end

			if not foundAnySound and songName then
				local fallbackId = block:match('rbxassetid://(%d+)')
				if fallbackId and #fallbackId >= 4 then
					pushEntry({
						kind = "audio",
						name = trim(songName),
						id = fallbackId,
						playbackSpeed = tonumber(playbackStr) or 1.0,
						imageId = imageId,
					})
				end
			end
		end

		-- 3. Parse format teks baris: NAMA: ... / SONG ID: ... / PLAYBACK: ...
		local curName: string? = nil
		local curId: string? = nil
		local curPlayback: number? = nil

		local function flushTextRecord()
			if curId and curId ~= "" then
				pushEntry({
					kind = "audio",
					name = trim(curName or ("Song_" .. curId)),
					id = curId,
					playbackSpeed = curPlayback or 1.0,
				})
			end
			curName = nil
			curId = nil
			curPlayback = nil
		end

		for rawLine in (content .. "\n"):gmatch("(.-)\r?\n") do
			local line = trim(rawLine)
			if line == "" then
				flushTextRecord()
			else
				local nVal = line:match("^[Nn][Aa][Mm][Aa]%s*:%s*(.+)$") or line:match("^[Ss][Oo][Nn][Gg]%s*[Nn][Aa][Mm][Ee]%s*:%s*(.+)$")
				local iVal = line:match("^[Ss][Oo][Nn][Gg]%s*[Ii][Dd]%s*:%s*(%d+)") or line:match("^[Ii][Dd]%s*:%s*(%d+)")
				local pVal = line:match("^[Pp][Ll][Aa][Yy][Bb][Aa][Cc][Kk][Ss][Pp][Ee][Ee][Dd]%s*:%s*([%d%.]+)") or line:match("^[Pp][Ll][Aa][Yy][Bb][Aa][Cc][Kk]%s*:%s*([%d%.]+)")

				if nVal then
					if curId then flushTextRecord() end
					curName = trim(nVal)
				elseif iVal then
					if curId then flushTextRecord() end
					curId = iVal
				elseif pVal then
					curPlayback = tonumber(pVal)
				end
			end
		end
		flushTextRecord()
	end

	return entries
end

-- Format JSON bertumpuk (pretty-printed) per item agar mudah dibaca & disalin
local function formatStackedJson(rows: {{[string]: any}}): string
	if #rows == 0 then
		return "[]"
	end
	local blocks: {string} = {}
	for _, row in ipairs(rows) do
		local ok, singleEncoded = pcall(function()
			return HttpService:JSONEncode(row)
		end)
		if ok and type(singleEncoded) == "string" then
			-- Pecah field utama agar bertumpuk ke bawah
			local pretty = singleEncoded
				:gsub("^%{", "{\n  ")
				:gsub('%,"', ',\n  "')
				:gsub("%}$", "\n}")
			table.insert(blocks, pretty)
		end
	end
	return "[\n" .. table.concat(blocks, ",\n") .. "\n]"
end

local savedCookie = loadTextFile("cookie.txt")
local savedApiKey = loadTextFile("apikey.txt")
if savedCookie and trim(savedCookie) ~= "" then CONFIG.Cookie = normalizeCookie(savedCookie) end
if savedApiKey and trim(savedApiKey) ~= "" then CONFIG.ApiKey = trim(savedApiKey) end

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

-- Helper Komponen Output Hasil Standar (Progress Bar + Console)
local function createOutcomePanel(parent: GuiObject, yPos: number, boxHeight: number, editableConsole: boolean)
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 5)
	bar.Position = UDim2.new(0, 12, 0, yPos)
	bar.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
	bar.BorderSizePixel = 0
	bar.Parent = parent
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local consoleScroll = Instance.new("ScrollingFrame")
	consoleScroll.Size = UDim2.new(1, -24, 0, boxHeight)
	consoleScroll.Position = UDim2.new(0, 12, 0, yPos + 8)
	consoleScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
	consoleScroll.BorderSizePixel = 0
	consoleScroll.ScrollBarThickness = 3
	consoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	consoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	consoleScroll.Parent = parent
	Instance.new("UICorner", consoleScroll).CornerRadius = UDim.new(0, 6)
	local csStroke = Instance.new("UIStroke", consoleScroll)
	csStroke.Color = Color3.fromRGB(48, 44, 74)
	csStroke.Thickness = 1

	local consoleBox = Instance.new("TextBox")
	consoleBox.Size = UDim2.new(1, -12, 0, boxHeight)
	consoleBox.AutomaticSize = Enum.AutomaticSize.Y
	consoleBox.Position = UDim2.new(0, 6, 0, 4)
	consoleBox.BackgroundTransparency = 1
	consoleBox.Text = ""
	consoleBox.PlaceholderText = "Hasil akan muncul di sini..."
	consoleBox.PlaceholderColor3 = Color3.fromRGB(95, 92, 118)
	consoleBox.TextColor3 = Color3.fromRGB(210, 240, 220)
	consoleBox.TextSize = 9
	consoleBox.Font = Enum.Font.Code
	consoleBox.TextXAlignment = Enum.TextXAlignment.Left
	consoleBox.TextYAlignment = Enum.TextYAlignment.Top
	consoleBox.ClearTextOnFocus = false
	consoleBox.TextEditable = editableConsole
	consoleBox.MultiLine = true
	consoleBox.TextWrapped = true
	consoleBox.Parent = consoleScroll

	return function(state: "idle" | "working" | "ok" | "err", ratio: number, outputText: string?)
		local clamped = math.clamp(ratio, 0, 1)
		if state == "idle" then
			fill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
		elseif state == "working" then
			fill.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
		elseif state == "ok" then
			fill.BackgroundColor3 = Color3.fromRGB(56, 239, 125)
		else
			fill.BackgroundColor3 = Color3.fromRGB(255, 86, 102)
		end

		TweenService:Create(fill, TweenInfo.new(0.15), {
			Size = UDim2.new(clamped, 0, 1, 0),
		}):Play()

		if outputText ~= nil then
			consoleBox.Text = outputText
			consoleBox.TextColor3 = (state == "err") and Color3.fromRGB(255, 145, 155) or Color3.fromRGB(205, 242, 218)
		end
	end, consoleBox
end

-- ==========================================
-- HALAMAN 1: SPOOF (CONSOLE PROSES & CONSOLE JSON HASIL TERPISAH)
-- ==========================================
local SpoofPage = Instance.new("Frame")
SpoofPage.Size = UDim2.fromScale(1, 1)
SpoofPage.BackgroundTransparency = 1
SpoofPage.Visible = true
SpoofPage.Parent = ContentArea
tabPages["Spoof"] = SpoofPage

local SpoofTitle = Instance.new("TextLabel")
SpoofTitle.Size = UDim2.new(0.45, -12, 0, 15)
SpoofTitle.Position = UDim2.new(0, 12, 0, 3)
SpoofTitle.BackgroundTransparency = 1
SpoofTitle.Text = "Spoof Asset"
SpoofTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SpoofTitle.TextSize = 12
SpoofTitle.Font = Enum.Font.GothamBold
SpoofTitle.TextXAlignment = Enum.TextXAlignment.Left
SpoofTitle.Parent = SpoofPage

local SourceIdBtn = Instance.new("TextButton")
SourceIdBtn.Size = UDim2.new(0.24, -4, 0, 16)
SourceIdBtn.Position = UDim2.new(0.46, 0, 0, 3)
SourceIdBtn.BackgroundColor3 = Color3.fromRGB(48, 45, 74)
SourceIdBtn.Text = "Input ID"
SourceIdBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SourceIdBtn.TextSize = 8
SourceIdBtn.Font = Enum.Font.GothamBold
SourceIdBtn.Parent = SpoofPage
Instance.new("UICorner", SourceIdBtn).CornerRadius = UDim.new(0, 5)

local SourceTxtBtn = Instance.new("TextButton")
SourceTxtBtn.Size = UDim2.new(0.29, -12, 0, 16)
SourceTxtBtn.Position = UDim2.new(0.71, 0, 0, 3)
SourceTxtBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
SourceTxtBtn.Text = "File TXT"
SourceTxtBtn.TextColor3 = Color3.fromRGB(175, 172, 200)
SourceTxtBtn.TextSize = 8
SourceTxtBtn.Font = Enum.Font.GothamBold
SourceTxtBtn.Parent = SpoofPage
Instance.new("UICorner", SourceTxtBtn).CornerRadius = UDim.new(0, 5)

-- Mode 1: Input Asset ID Manual/Massal
local AssetIdBox = Instance.new("TextBox")
AssetIdBox.Size = UDim2.new(1, -24, 0, 38)
AssetIdBox.Position = UDim2.new(0, 12, 0, 21)
AssetIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetIdBox.Text = ""
AssetIdBox.PlaceholderText = "Input Asset ID (pisah spasi, koma, atau baris baru)"
AssetIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetIdBox.TextSize = 10
AssetIdBox.Font = Enum.Font.Gotham
AssetIdBox.TextXAlignment = Enum.TextXAlignment.Left
AssetIdBox.TextYAlignment = Enum.TextYAlignment.Top
AssetIdBox.ClearTextOnFocus = false
AssetIdBox.MultiLine = true
AssetIdBox.TextWrapped = true
AssetIdBox.Visible = true
AssetIdBox.Parent = SpoofPage
Instance.new("UICorner", AssetIdBox).CornerRadius = UDim.new(0, 7)
local AssetStroke = Instance.new("UIStroke", AssetIdBox)
AssetStroke.Color = Color3.fromRGB(65, 60, 102)
AssetStroke.Thickness = 1

-- Mode 2: Scan & Select File TXT Massal
local TxtSelectorPanel = Instance.new("Frame")
TxtSelectorPanel.Size = UDim2.new(1, -24, 0, 38)
TxtSelectorPanel.Position = UDim2.new(0, 12, 0, 21)
TxtSelectorPanel.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
TxtSelectorPanel.Visible = false
TxtSelectorPanel.Parent = SpoofPage
Instance.new("UICorner", TxtSelectorPanel).CornerRadius = UDim.new(0, 7)
local TxtPanelStroke = Instance.new("UIStroke", TxtSelectorPanel)
TxtPanelStroke.Color = Color3.fromRGB(65, 60, 102)
TxtPanelStroke.Thickness = 1

local ScanTxtBtn = Instance.new("TextButton")
ScanTxtBtn.Size = UDim2.new(0, 62, 1, -6)
ScanTxtBtn.Position = UDim2.new(0, 3, 0, 3)
ScanTxtBtn.BackgroundColor3 = Color3.fromRGB(64, 118, 240)
ScanTxtBtn.Text = "Scan TXT"
ScanTxtBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanTxtBtn.TextSize = 8
ScanTxtBtn.Font = Enum.Font.GothamBold
ScanTxtBtn.Parent = TxtSelectorPanel
Instance.new("UICorner", ScanTxtBtn).CornerRadius = UDim.new(0, 5)

local TxtFileList = Instance.new("ScrollingFrame")
TxtFileList.Size = UDim2.new(1, -70, 1, -4)
TxtFileList.Position = UDim2.new(0, 68, 0, 2)
TxtFileList.BackgroundTransparency = 1
TxtFileList.BorderSizePixel = 0
TxtFileList.ScrollBarThickness = 2
TxtFileList.CanvasSize = UDim2.new(0, 0, 0, 0)
TxtFileList.AutomaticCanvasSize = Enum.AutomaticSize.Y
TxtFileList.Parent = TxtSelectorPanel

local TxtListLayout = Instance.new("UIListLayout")
TxtListLayout.Padding = UDim.new(0, 2)
TxtListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TxtListLayout.Parent = TxtFileList

local TxtEmptyLabel = Instance.new("TextLabel")
TxtEmptyLabel.Size = UDim2.new(1, -4, 0, 18)
TxtEmptyLabel.BackgroundTransparency = 1
TxtEmptyLabel.Text = "Klik Scan TXT untuk pilih file .txt..."
TxtEmptyLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
TxtEmptyLabel.TextSize = 8
TxtEmptyLabel.Font = Enum.Font.Gotham
TxtEmptyLabel.TextXAlignment = Enum.TextXAlignment.Left
TxtEmptyLabel.Parent = TxtFileList

local selectedSpoofTxtPath: string? = nil

local function renderSpoofTxtList(files: {string})
	for _, child in ipairs(TxtFileList:GetChildren()) do
		if child:IsA("Frame") or (child:IsA("TextLabel") and child ~= TxtEmptyLabel) then
			child:Destroy()
		end
	end

	if #files == 0 then
		TxtEmptyLabel.Text = "Tidak ada file .txt di TXT/ atau SPOOF/."
		TxtEmptyLabel.Visible = true
		return
	end

	TxtEmptyLabel.Visible = false
	for idx, relFile in ipairs(files) do
		local isSel = (selectedSpoofTxtPath == relFile)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -2, 0, 17)
		row.BackgroundColor3 = isSel and Color3.fromRGB(45, 42, 72) or Color3.fromRGB(22, 21, 34)
		row.BorderSizePixel = 0
		row.LayoutOrder = idx
		row.Parent = TxtFileList
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -44, 1, 0)
		lbl.Position = UDim2.new(0, 4, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = relFile
		lbl.TextColor3 = Color3.fromRGB(225, 222, 245)
		lbl.TextSize = 8
		lbl.Font = Enum.Font.Code
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Parent = row

		local selBtn = Instance.new("TextButton")
		selBtn.Size = UDim2.new(0, 38, 1, -3)
		selBtn.Position = UDim2.new(1, -40, 0, 1.5)
		selBtn.BackgroundColor3 = isSel and Color3.fromRGB(56, 185, 115) or Color3.fromRGB(108, 86, 245)
		selBtn.Text = isSel and "Selected" or "Select"
		selBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selBtn.TextSize = 7
		selBtn.Font = Enum.Font.GothamBold
		selBtn.Parent = row
		Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0, 3)

		selBtn.MouseButton1Click:Connect(function()
			selectedSpoofTxtPath = relFile
			renderSpoofTxtList(files)
		end)
	end
end

local function setSpoofSourceMode(mode: "ID" | "TXT")
	CONFIG.SpoofSourceMode = mode
	local isTxt = (mode == "TXT")
	AssetIdBox.Visible = not isTxt
	TxtSelectorPanel.Visible = isTxt
	SourceIdBtn.BackgroundColor3 = (not isTxt) and Color3.fromRGB(48, 45, 74) or Color3.fromRGB(26, 25, 39)
	SourceIdBtn.TextColor3 = (not isTxt) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(175, 172, 200)
	SourceTxtBtn.BackgroundColor3 = isTxt and Color3.fromRGB(48, 45, 74) or Color3.fromRGB(26, 25, 39)
	SourceTxtBtn.TextColor3 = isTxt and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(175, 172, 200)
	if isTxt then
		renderSpoofTxtList(scanFilesByPrefix({ "TXT/", "SPOOF/" }, ".txt"))
	end
end

SourceIdBtn.MouseButton1Click:Connect(function() setSpoofSourceMode("ID") end)
SourceTxtBtn.MouseButton1Click:Connect(function() setSpoofSourceMode("TXT") end)

ScanTxtBtn.MouseButton1Click:Connect(function()
	local txtFiles = scanFilesByPrefix({ "TXT/", "SPOOF/" }, ".txt")
	renderSpoofTxtList(txtFiles)
	notify("Scan TXT", tostring(#txtFiles) .. " file .txt ditemukan.")
end)

local FilterRow = Instance.new("Frame")
FilterRow.Size = UDim2.new(1, -24, 0, 19)
FilterRow.Position = UDim2.new(0, 12, 0, 62)
FilterRow.BackgroundTransparency = 1
FilterRow.Parent = SpoofPage

local FilterLayout = Instance.new("UIListLayout")
FilterLayout.FillDirection = Enum.FillDirection.Horizontal
FilterLayout.Padding = UDim.new(0, 5)
FilterLayout.Parent = FilterRow

local filterButtons: {[string]: TextButton} = {}
local filters = {"Auto", "Suara", "Stiker", "Model", "Anim"}

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
	fBtn.Size = UDim2.new(0.2, -4, 1, 0)
	fBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
	fBtn.Text = fName
	fBtn.TextColor3 = Color3.fromRGB(165, 162, 190)
	fBtn.TextSize = 9
	fBtn.Font = Enum.Font.GothamMedium
	fBtn.AutoButtonColor = false
	fBtn.Parent = FilterRow
	Instance.new("UICorner", fBtn).CornerRadius = UDim.new(0, 6)
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
SpoofNowBtn.Size = UDim2.new(0.62, -14, 0, 24)
SpoofNowBtn.Position = UDim2.new(0, 12, 0, 84)
SpoofNowBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SpoofNowBtn.Text = "⇄  SPOOF SEKARANG"
SpoofNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SpoofNowBtn.TextSize = 10
SpoofNowBtn.Font = Enum.Font.GothamBold
SpoofNowBtn.Parent = SpoofPage
Instance.new("UICorner", SpoofNowBtn).CornerRadius = UDim.new(0, 7)

local BersihkanBtn = Instance.new("TextButton")
BersihkanBtn.Size = UDim2.new(0.38, -14, 0, 24)
BersihkanBtn.Position = UDim2.new(0.62, 2, 0, 84)
BersihkanBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 39)
BersihkanBtn.Text = "BERSIHKAN"
BersihkanBtn.TextColor3 = Color3.fromRGB(210, 208, 232)
BersihkanBtn.TextSize = 9
BersihkanBtn.Font = Enum.Font.GothamBold
BersihkanBtn.Parent = SpoofPage
Instance.new("UICorner", BersihkanBtn).CornerRadius = UDim.new(0, 7)
local BersStroke = Instance.new("UIStroke", BersihkanBtn)
BersStroke.Color = Color3.fromRGB(68, 64, 100)
BersStroke.Thickness = 1

-- Progress bar
local spoofBar = Instance.new("Frame")
spoofBar.Size = UDim2.new(1, -24, 0, 4)
spoofBar.Position = UDim2.new(0, 12, 0, 111)
spoofBar.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
spoofBar.BorderSizePixel = 0
spoofBar.Parent = SpoofPage
Instance.new("UICorner", spoofBar).CornerRadius = UDim.new(1, 0)

local spoofFill = Instance.new("Frame")
spoofFill.Size = UDim2.new(0, 0, 1, 0)
spoofFill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
spoofFill.BorderSizePixel = 0
spoofFill.Parent = spoofBar
Instance.new("UICorner", spoofFill).CornerRadius = UDim.new(1, 0)

-- 1) Console Proses (atas)
local procScroll = Instance.new("ScrollingFrame")
procScroll.Name = "ProcessConsole"
procScroll.Size = UDim2.new(1, -24, 0, 44)
procScroll.Position = UDim2.new(0, 12, 0, 118)
procScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
procScroll.BorderSizePixel = 0
procScroll.ScrollBarThickness = 2
procScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
procScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
procScroll.Parent = SpoofPage
Instance.new("UICorner", procScroll).CornerRadius = UDim.new(0, 6)
local procStroke = Instance.new("UIStroke", procScroll)
procStroke.Color = Color3.fromRGB(48, 44, 74)
procStroke.Thickness = 1

local procBox = Instance.new("TextBox")
procBox.Size = UDim2.new(1, -10, 0, 40)
procBox.AutomaticSize = Enum.AutomaticSize.Y
procBox.Position = UDim2.new(0, 5, 0, 2)
procBox.BackgroundTransparency = 1
procBox.Text = ""
procBox.PlaceholderText = "Console Proses..."
procBox.PlaceholderColor3 = Color3.fromRGB(95, 92, 118)
procBox.TextColor3 = Color3.fromRGB(185, 205, 255)
procBox.TextSize = 8
procBox.Font = Enum.Font.Code
procBox.TextXAlignment = Enum.TextXAlignment.Left
procBox.TextYAlignment = Enum.TextYAlignment.Top
procBox.ClearTextOnFocus = false
procBox.TextEditable = false
procBox.MultiLine = true
procBox.TextWrapped = true
procBox.Parent = procScroll

-- 2) Console JSON Hasil Bertumpuk (bawah, bisa diedit & dicopy)
local jsonScroll = Instance.new("ScrollingFrame")
jsonScroll.Name = "JsonResultConsole"
jsonScroll.Size = UDim2.new(1, -24, 0, 82)
jsonScroll.Position = UDim2.new(0, 12, 0, 165)
jsonScroll.BackgroundColor3 = Color3.fromRGB(11, 10, 17)
jsonScroll.BorderSizePixel = 0
jsonScroll.ScrollBarThickness = 3
jsonScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
jsonScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
jsonScroll.Parent = SpoofPage
Instance.new("UICorner", jsonScroll).CornerRadius = UDim.new(0, 6)
local jsonStroke = Instance.new("UIStroke", jsonScroll)
jsonStroke.Color = Color3.fromRGB(64, 56, 102)
jsonStroke.Thickness = 1

local jsonResultBox = Instance.new("TextBox")
jsonResultBox.Size = UDim2.new(1, -54, 0, 78)
jsonResultBox.AutomaticSize = Enum.AutomaticSize.Y
jsonResultBox.Position = UDim2.new(0, 6, 0, 4)
jsonResultBox.BackgroundTransparency = 1
jsonResultBox.Text = ""
jsonResultBox.PlaceholderText = "Console JSON Hasil (bertumpuk, bisa diedit & dicopy)..."
jsonResultBox.PlaceholderColor3 = Color3.fromRGB(95, 92, 118)
jsonResultBox.TextColor3 = Color3.fromRGB(205, 242, 218)
jsonResultBox.TextSize = 8
jsonResultBox.Font = Enum.Font.Code
jsonResultBox.TextXAlignment = Enum.TextXAlignment.Left
jsonResultBox.TextYAlignment = Enum.TextYAlignment.Top
jsonResultBox.ClearTextOnFocus = false
jsonResultBox.TextEditable = true
jsonResultBox.MultiLine = true
jsonResultBox.TextWrapped = true
jsonResultBox.Parent = jsonScroll

local copyJsonBtn = Instance.new("TextButton")
copyJsonBtn.Size = UDim2.fromOffset(44, 17)
copyJsonBtn.Position = UDim2.new(1, -48, 0, 4)
copyJsonBtn.BackgroundColor3 = Color3.fromRGB(38, 35, 60)
copyJsonBtn.Text = "Copy"
copyJsonBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
copyJsonBtn.TextSize = 8
copyJsonBtn.Font = Enum.Font.GothamBold
copyJsonBtn.ZIndex = 5
copyJsonBtn.Parent = jsonScroll
Instance.new("UICorner", copyJsonBtn).CornerRadius = UDim.new(0, 4)

copyJsonBtn.MouseButton1Click:Connect(function()
	local okCopy = copyToClipboard(jsonResultBox.Text)
	copyJsonBtn.Text = okCopy and "Copied!" or "Selected"
	notify("Console JSON", okCopy and "JSON disalin ke clipboard." or "Teks siap disalin manual.")
	task.delay(1.2, function()
		if copyJsonBtn and copyJsonBtn.Parent then
			copyJsonBtn.Text = "Copy"
		end
	end)
end)

local function setSpoofBar(state: "idle" | "working" | "ok" | "err", ratio: number)
	local clamped = math.clamp(ratio, 0, 1)
	if state == "idle" then
		spoofFill.BackgroundColor3 = Color3.fromRGB(122, 98, 255)
	elseif state == "working" then
		spoofFill.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
	elseif state == "ok" then
		spoofFill.BackgroundColor3 = Color3.fromRGB(56, 239, 125)
	else
		spoofFill.BackgroundColor3 = Color3.fromRGB(255, 86, 102)
	end
	TweenService:Create(spoofFill, TweenInfo.new(0.15), {
		Size = UDim2.new(clamped, 0, 1, 0),
	}):Play()
end

local function setProcessLog(state: "idle" | "working" | "ok" | "err", text: string)
	procBox.Text = text
	procBox.TextColor3 = (state == "err") and Color3.fromRGB(255, 145, 155) or Color3.fromRGB(185, 205, 255)
end

local function setJsonResultText(isErr: boolean, text: string)
	jsonResultBox.Text = text
	jsonResultBox.TextColor3 = isErr and Color3.fromRGB(255, 165, 175) or Color3.fromRGB(205, 242, 218)
end

BersihkanBtn.MouseButton1Click:Connect(function()
	AssetIdBox.Text = ""
	selectedSpoofTxtPath = nil
	setSpoofBar("idle", 0)
	setProcessLog("idle", "")
	setJsonResultText(false, "")
end)

-- ==========================================
-- HALAMAN 2: UPLOAD ASSET (SCAN SPOOF -> SELECT -> UPLOAD -> HASIL)
-- ==========================================
local UploadPage = Instance.new("Frame")
UploadPage.Size = UDim2.fromScale(1, 1)
UploadPage.BackgroundTransparency = 1
UploadPage.Visible = false
UploadPage.Parent = ContentArea
tabPages["Upload"] = UploadPage

local UploadTitle = Instance.new("TextLabel")
UploadTitle.Size = UDim2.new(0.58, -12, 0, 16)
UploadTitle.Position = UDim2.new(0, 12, 0, 4)
UploadTitle.BackgroundTransparency = 1
UploadTitle.Text = "Upload Asset"
UploadTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
UploadTitle.TextSize = 12
UploadTitle.Font = Enum.Font.GothamBold
UploadTitle.TextXAlignment = Enum.TextXAlignment.Left
UploadTitle.Parent = UploadPage

local ScanSpoofBtn = Instance.new("TextButton")
ScanSpoofBtn.Size = UDim2.new(0.42, -12, 0, 18)
ScanSpoofBtn.Position = UDim2.new(0.58, 0, 0, 4)
ScanSpoofBtn.BackgroundColor3 = Color3.fromRGB(64, 118, 240)
ScanSpoofBtn.Text = "🔍 SCAN SPOOF"
ScanSpoofBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanSpoofBtn.TextSize = 9
ScanSpoofBtn.Font = Enum.Font.GothamBold
ScanSpoofBtn.Parent = UploadPage
Instance.new("UICorner", ScanSpoofBtn).CornerRadius = UDim.new(0, 6)

local UploadNameBox = Instance.new("TextBox")
UploadNameBox.Size = UDim2.new(0.5, -15, 0, 22)
UploadNameBox.Position = UDim2.new(0, 12, 0, 24)
UploadNameBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadNameBox.PlaceholderText = "Nama Asset"
UploadNameBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadNameBox.Text = ""
UploadNameBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadNameBox.TextSize = 10
UploadNameBox.Font = Enum.Font.Gotham
UploadNameBox.ClearTextOnFocus = false
UploadNameBox.Parent = UploadPage
Instance.new("UICorner", UploadNameBox).CornerRadius = UDim.new(0, 6)

local UploadTypeBox = Instance.new("TextBox")
UploadTypeBox.Size = UDim2.new(0.5, -15, 0, 22)
UploadTypeBox.Position = UDim2.new(0.5, 3, 0, 24)
UploadTypeBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadTypeBox.PlaceholderText = "Model / Audio / Animation / Decal"
UploadTypeBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadTypeBox.Text = "Model"
UploadTypeBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadTypeBox.TextSize = 10
UploadTypeBox.Font = Enum.Font.Gotham
UploadTypeBox.ClearTextOnFocus = false
UploadTypeBox.Parent = UploadPage
Instance.new("UICorner", UploadTypeBox).CornerRadius = UDim.new(0, 6)

local UploadCreatorBox = Instance.new("TextBox")
UploadCreatorBox.Size = UDim2.new(0.5, -15, 0, 22)
UploadCreatorBox.Position = UDim2.new(0, 12, 0, 49)
UploadCreatorBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadCreatorBox.PlaceholderText = "Creator ID"
UploadCreatorBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadCreatorBox.Text = tostring(LocalPlayer.UserId)
UploadCreatorBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadCreatorBox.TextSize = 10
UploadCreatorBox.Font = Enum.Font.Gotham
UploadCreatorBox.ClearTextOnFocus = false
UploadCreatorBox.Parent = UploadPage
Instance.new("UICorner", UploadCreatorBox).CornerRadius = UDim.new(0, 6)

local UploadOwnerModeBox = Instance.new("TextBox")
UploadOwnerModeBox.Size = UDim2.new(0.5, -15, 0, 22)
UploadOwnerModeBox.Position = UDim2.new(0.5, 3, 0, 49)
UploadOwnerModeBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadOwnerModeBox.PlaceholderText = "user atau group"
UploadOwnerModeBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadOwnerModeBox.Text = "user"
UploadOwnerModeBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadOwnerModeBox.TextSize = 10
UploadOwnerModeBox.Font = Enum.Font.Gotham
UploadOwnerModeBox.ClearTextOnFocus = false
UploadOwnerModeBox.Parent = UploadPage
Instance.new("UICorner", UploadOwnerModeBox).CornerRadius = UDim.new(0, 6)

local SpoofFileListFrame = Instance.new("ScrollingFrame")
SpoofFileListFrame.Name = "SpoofFileListFrame"
SpoofFileListFrame.Size = UDim2.new(1, -24, 0, 56)
SpoofFileListFrame.Position = UDim2.new(0, 12, 0, 74)
SpoofFileListFrame.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
SpoofFileListFrame.BorderSizePixel = 0
SpoofFileListFrame.ScrollBarThickness = 3
SpoofFileListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
SpoofFileListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
SpoofFileListFrame.Parent = UploadPage
Instance.new("UICorner", SpoofFileListFrame).CornerRadius = UDim.new(0, 6)
local FileListStroke = Instance.new("UIStroke", SpoofFileListFrame)
FileListStroke.Color = Color3.fromRGB(55, 50, 88)
FileListStroke.Thickness = 1

local FileListLayout = Instance.new("UIListLayout")
FileListLayout.Padding = UDim.new(0, 3)
FileListLayout.SortOrder = Enum.SortOrder.LayoutOrder
FileListLayout.Parent = SpoofFileListFrame

local FileListPad = Instance.new("UIPadding")
FileListPad.PaddingTop = UDim.new(0, 4)
FileListPad.PaddingBottom = UDim.new(0, 4)
FileListPad.PaddingLeft = UDim.new(0, 4)
FileListPad.PaddingRight = UDim.new(0, 4)
FileListPad.Parent = SpoofFileListFrame

local EmptyListLabel = Instance.new("TextLabel")
EmptyListLabel.Size = UDim2.new(1, -8, 0, 20)
EmptyListLabel.BackgroundTransparency = 1
EmptyListLabel.Text = "Klik SCAN SPOOF untuk melihat list file..."
EmptyListLabel.TextColor3 = Color3.fromRGB(115, 112, 138)
EmptyListLabel.TextSize = 9
EmptyListLabel.Font = Enum.Font.Gotham
EmptyListLabel.TextXAlignment = Enum.TextXAlignment.Left
EmptyListLabel.Parent = SpoofFileListFrame

local selectedSpoofRelPath: string? = nil

local UploadPayloadBox = Instance.new("TextBox")
UploadPayloadBox.Size = UDim2.new(1, -24, 0, 22)
UploadPayloadBox.Position = UDim2.new(0, 12, 0, 133)
UploadPayloadBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
UploadPayloadBox.PlaceholderText = "File terpilih dari SPOOF atau path/konten manual"
UploadPayloadBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
UploadPayloadBox.Text = ""
UploadPayloadBox.TextColor3 = Color3.fromRGB(235, 235, 250)
UploadPayloadBox.TextSize = 9
UploadPayloadBox.Font = Enum.Font.Code
UploadPayloadBox.ClearTextOnFocus = false
UploadPayloadBox.Parent = UploadPage
Instance.new("UICorner", UploadPayloadBox).CornerRadius = UDim.new(0, 6)

local UploadActionBtn = Instance.new("TextButton")
UploadActionBtn.Size = UDim2.new(1, -24, 0, 25)
UploadActionBtn.Position = UDim2.new(0, 12, 0, 158)
UploadActionBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
UploadActionBtn.Text = "⬆  UPLOAD ASSET"
UploadActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UploadActionBtn.TextSize = 10
UploadActionBtn.Font = Enum.Font.GothamBold
UploadActionBtn.Parent = UploadPage
Instance.new("UICorner", UploadActionBtn).CornerRadius = UDim.new(0, 7)

local updateUploadOutcome = createOutcomePanel(UploadPage, 186, 56, false)

local function renderSpoofFileList(files: {string})
	for _, child in ipairs(SpoofFileListFrame:GetChildren()) do
		if child:IsA("Frame") or (child:IsA("TextLabel") and child ~= EmptyListLabel) then
			child:Destroy()
		end
	end

	if #files == 0 then
		EmptyListLabel.Text = "Tidak ada file di folder SPOOF."
		EmptyListLabel.Visible = true
		return
	end

	EmptyListLabel.Visible = false
	for idx, relFile in ipairs(files) do
		local row = Instance.new("Frame")
		row.Name = "FileRow_" .. tostring(idx)
		row.Size = UDim2.new(1, -4, 0, 20)
		row.BackgroundColor3 = (selectedSpoofRelPath == relFile) and Color3.fromRGB(45, 42, 72) or Color3.fromRGB(22, 21, 34)
		row.BorderSizePixel = 0
		row.LayoutOrder = idx
		row.Parent = SpoofFileListFrame
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, -54, 1, 0)
		nameLbl.Position = UDim2.new(0, 6, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = relFile
		nameLbl.TextColor3 = Color3.fromRGB(225, 222, 245)
		nameLbl.TextSize = 9
		nameLbl.Font = Enum.Font.Code
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		nameLbl.Parent = row

		local selectBtn = Instance.new("TextButton")
		selectBtn.Size = UDim2.new(0, 44, 1, -4)
		selectBtn.Position = UDim2.new(1, -46, 0, 2)
		selectBtn.BackgroundColor3 = (selectedSpoofRelPath == relFile) and Color3.fromRGB(56, 185, 115) or Color3.fromRGB(108, 86, 245)
		selectBtn.Text = (selectedSpoofRelPath == relFile) and "Selected" or "Select"
		selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectBtn.TextSize = 8
		selectBtn.Font = Enum.Font.GothamBold
		selectBtn.Parent = row
		Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 4)

		selectBtn.MouseButton1Click:Connect(function()
			selectedSpoofRelPath = relFile
			UploadPayloadBox.Text = relFile
			if trim(UploadNameBox.Text) == "" then
				local baseOnly = relFile:match("([^/]+)$") or relFile
				local stemOnly = baseOnly:gsub("%.[^%.]+$", "")
				UploadNameBox.Text = stemOnly
			end
			local lowerFile = relFile:lower()
			if lowerFile:sub(-4) == ".mp3" or lowerFile:sub(-4) == ".ogg" or lowerFile:sub(-4) == ".wav" then
				UploadTypeBox.Text = "Audio"
			elseif lowerFile:sub(-5) == ".rbxm" or lowerFile:sub(-5) == ".rbxmx" then
				UploadTypeBox.Text = "Model"
			end
			renderSpoofFileList(files)
			updateUploadOutcome("ok", 1, "Dipilih: " .. CONFIG.WorkspaceRoot .. "/" .. relFile)
		end)
	end
end

ScanSpoofBtn.MouseButton1Click:Connect(function()
	local foundFiles = scanFilesByPrefix({ "SPOOF/" }, nil)
	renderSpoofFileList(foundFiles)
	if #foundFiles > 0 then
		updateUploadOutcome("ok", 1, "Ditemukan " .. tostring(#foundFiles) .. " file di SPOOF. Klik Select untuk memilih.")
		notify("Scan SPOOF", tostring(#foundFiles) .. " file ditemukan.")
	else
		updateUploadOutcome("err", 0, "Tidak ada file ditemukan di folder SPOOF.")
		notify("Scan SPOOF", "Folder SPOOF kosong.")
	end
end)

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
ToolsTitle.Size = UDim2.new(1, -24, 0, 16)
ToolsTitle.Position = UDim2.new(0, 12, 0, 5)
ToolsTitle.BackgroundTransparency = 1
ToolsTitle.Text = "Place Maker & Permissions"
ToolsTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ToolsTitle.TextSize = 12
ToolsTitle.Font = Enum.Font.GothamBold
ToolsTitle.TextXAlignment = Enum.TextXAlignment.Left
ToolsTitle.Parent = ToolsPage

local TemplateIdBox = Instance.new("TextBox")
TemplateIdBox.Size = UDim2.new(0.36, -12, 0, 24)
TemplateIdBox.Position = UDim2.new(0, 12, 0, 23)
TemplateIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TemplateIdBox.Text = "95206881"
TemplateIdBox.PlaceholderText = "Template ID"
TemplateIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TemplateIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TemplateIdBox.TextSize = 10
TemplateIdBox.Font = Enum.Font.Gotham
TemplateIdBox.ClearTextOnFocus = false
TemplateIdBox.Parent = ToolsPage
Instance.new("UICorner", TemplateIdBox).CornerRadius = UDim.new(0, 6)

local GroupIdBox = Instance.new("TextBox")
GroupIdBox.Size = UDim2.new(0.32, -8, 0, 24)
GroupIdBox.Position = UDim2.new(0.36, 2, 0, 23)
GroupIdBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
GroupIdBox.Text = ""
GroupIdBox.PlaceholderText = "Group ID (opsional)"
GroupIdBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
GroupIdBox.TextColor3 = Color3.fromRGB(235, 235, 250)
GroupIdBox.TextSize = 10
GroupIdBox.Font = Enum.Font.Gotham
GroupIdBox.ClearTextOnFocus = false
GroupIdBox.Parent = ToolsPage
Instance.new("UICorner", GroupIdBox).CornerRadius = UDim.new(0, 6)

local PlaceCountBox = Instance.new("TextBox")
PlaceCountBox.Size = UDim2.new(0.32, -10, 0, 24)
PlaceCountBox.Position = UDim2.new(0.68, 0, 0, 23)
PlaceCountBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PlaceCountBox.Text = "1"
PlaceCountBox.PlaceholderText = "Jumlah"
PlaceCountBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PlaceCountBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PlaceCountBox.TextSize = 10
PlaceCountBox.Font = Enum.Font.Gotham
PlaceCountBox.ClearTextOnFocus = false
PlaceCountBox.Parent = ToolsPage
Instance.new("UICorner", PlaceCountBox).CornerRadius = UDim.new(0, 6)

local CreatePlaceBtn = Instance.new("TextButton")
CreatePlaceBtn.Size = UDim2.new(1, -24, 0, 25)
CreatePlaceBtn.Position = UDim2.new(0, 12, 0, 50)
CreatePlaceBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
CreatePlaceBtn.Text = "🏗  BUAT PLACE"
CreatePlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreatePlaceBtn.TextSize = 10
CreatePlaceBtn.Font = Enum.Font.GothamBold
CreatePlaceBtn.Parent = ToolsPage
Instance.new("UICorner", CreatePlaceBtn).CornerRadius = UDim.new(0, 6)

local TargetUniverseBox = Instance.new("TextBox")
TargetUniverseBox.Size = UDim2.new(1, -24, 0, 24)
TargetUniverseBox.Position = UDim2.new(0, 12, 0, 80)
TargetUniverseBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
TargetUniverseBox.Text = CONFIG.DefaultUniverseId
TargetUniverseBox.PlaceholderText = "Target Universe ID"
TargetUniverseBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
TargetUniverseBox.TextColor3 = Color3.fromRGB(235, 235, 250)
TargetUniverseBox.TextSize = 10
TargetUniverseBox.Font = Enum.Font.Gotham
TargetUniverseBox.ClearTextOnFocus = false
TargetUniverseBox.Parent = ToolsPage
Instance.new("UICorner", TargetUniverseBox).CornerRadius = UDim.new(0, 6)

local PermIdsBox = Instance.new("TextBox")
PermIdsBox.Size = UDim2.new(1, -24, 0, 34)
PermIdsBox.Position = UDim2.new(0, 12, 0, 108)
PermIdsBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PermIdsBox.Text = ""
PermIdsBox.PlaceholderText = "Asset IDs Permission (pisah koma/spasi/baris)"
PermIdsBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PermIdsBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PermIdsBox.TextSize = 10
PermIdsBox.Font = Enum.Font.Gotham
PermIdsBox.ClearTextOnFocus = false
PermIdsBox.MultiLine = true
PermIdsBox.TextWrapped = true
PermIdsBox.TextXAlignment = Enum.TextXAlignment.Left
PermIdsBox.TextYAlignment = Enum.TextYAlignment.Top
PermIdsBox.Parent = ToolsPage
Instance.new("UICorner", PermIdsBox).CornerRadius = UDim.new(0, 6)

local GrantPermBtn = Instance.new("TextButton")
GrantPermBtn.Size = UDim2.new(1, -24, 0, 25)
GrantPermBtn.Position = UDim2.new(0, 12, 0, 146)
GrantPermBtn.BackgroundColor3 = Color3.fromRGB(48, 45, 74)
GrantPermBtn.Text = "🔑  GRANT PERMISSIONS"
GrantPermBtn.TextColor3 = Color3.fromRGB(240, 240, 255)
GrantPermBtn.TextSize = 10
GrantPermBtn.Font = Enum.Font.GothamBold
GrantPermBtn.Parent = ToolsPage
Instance.new("UICorner", GrantPermBtn).CornerRadius = UDim.new(0, 6)

local updateToolsOutcome = createOutcomePanel(ToolsPage, 176, 66, false)

-- ==========================================
-- HALAMAN 4: SETTING (INPUT LANGSUNG SINKRON + SIMPAN)
-- ==========================================
local SettingPage = Instance.new("Frame")
SettingPage.Size = UDim2.fromScale(1, 1)
SettingPage.BackgroundTransparency = 1
SettingPage.Visible = false
SettingPage.Parent = ContentArea
tabPages["Setting"] = SettingPage

local SettingTitle = Instance.new("TextLabel")
SettingTitle.Size = UDim2.new(1, -24, 0, 16)
SettingTitle.Position = UDim2.new(0, 12, 0, 6)
SettingTitle.BackgroundTransparency = 1
SettingTitle.Text = "Pengaturan Kredensial"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 13
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local CookieBox = Instance.new("TextBox")
CookieBox.Size = UDim2.new(1, -24, 0, 46)
CookieBox.Position = UDim2.new(0, 12, 0, 26)
CookieBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
CookieBox.Text = CONFIG.Cookie
CookieBox.PlaceholderText = ".ROBLOSECURITY Cookie..."
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

local ApiKeyBox = Instance.new("TextBox")
ApiKeyBox.Size = UDim2.new(1, -24, 0, 46)
ApiKeyBox.Position = UDim2.new(0, 12, 0, 78)
ApiKeyBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
ApiKeyBox.Text = CONFIG.ApiKey
ApiKeyBox.PlaceholderText = "Roblox Open Cloud API Key (x-api-key)..."
ApiKeyBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
ApiKeyBox.TextColor3 = Color3.fromRGB(235, 235, 250)
ApiKeyBox.TextSize = 10
ApiKeyBox.Font = Enum.Font.Gotham
ApiKeyBox.ClearTextOnFocus = false
ApiKeyBox.MultiLine = true
ApiKeyBox.TextWrapped = true
ApiKeyBox.TextXAlignment = Enum.TextXAlignment.Left
ApiKeyBox.TextYAlignment = Enum.TextYAlignment.Top
ApiKeyBox.Parent = SettingPage
Instance.new("UICorner", ApiKeyBox).CornerRadius = UDim.new(0, 7)

local SaveSettingBtn = Instance.new("TextButton")
SaveSettingBtn.Size = UDim2.new(1, -24, 0, 30)
SaveSettingBtn.Position = UDim2.new(0, 12, 0, 130)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN KREDENSIAL"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 11
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 8)

local updateSettingOutcome = createOutcomePanel(SettingPage, 166, 76, false)

local function syncCredentialsFromInputs(): (string, string)
	local boxCookie = normalizeCookie(CookieBox.Text)
	local boxApiKey = trim(ApiKeyBox.Text)
	if boxCookie ~= "" then
		CONFIG.Cookie = boxCookie
	end
	if boxApiKey ~= "" then
		CONFIG.ApiKey = boxApiKey
	end
	return CONFIG.Cookie, CONFIG.ApiKey
end

CookieBox:GetPropertyChangedSignal("Text"):Connect(function()
	CONFIG.Cookie = normalizeCookie(CookieBox.Text)
end)

ApiKeyBox:GetPropertyChangedSignal("Text"):Connect(function()
	CONFIG.ApiKey = trim(ApiKeyBox.Text)
end)

SaveSettingBtn.MouseButton1Click:Connect(function()
	local c = normalizeCookie(CookieBox.Text)
	local k = trim(ApiKeyBox.Text)
	CONFIG.Cookie = c
	CONFIG.ApiKey = k
	CookieBox.Text = c
	ApiKeyBox.Text = k

	local okC = saveTextFile("cookie.txt", c)
	local okK = saveTextFile("apikey.txt", k)
	local ok = (c == "" or okC) and (k == "" or okK)
	local summary = string.format(
		"Cookie: %s | API Key: %s",
		c ~= "" and ("Terisi (" .. tostring(#c) .. " karakter)") or "Kosong",
		k ~= "" and ("Terisi (" .. tostring(#k) .. " karakter)") or "Kosong"
	)
	updateSettingOutcome(ok and "ok" or "err", ok and 1 or 0, summary)
	notify("Setting", ok and "Tersimpan." or "Gagal menyimpan.")
end)

-- Navigasi Sidebar
createNavButton("Spoof", "⇄  Spoof", 1).MouseButton1Click:Connect(function() switchTab("Spoof") end)
createNavButton("Upload", "⬆  Upload", 2).MouseButton1Click:Connect(function()
	switchTab("Upload")
	renderSpoofFileList(scanFilesByPrefix({ "SPOOF/" }, nil))
end)
createNavButton("Tools", "🛠  Place & Perm", 3).MouseButton1Click:Connect(function() switchTab("Tools") end)
createNavButton("Setting", "⚙  Setting", 4).MouseButton1Click:Connect(function() switchTab("Setting") end)
switchTab("Spoof")

-- ==========================================
-- LOGIKA EKSEKUSI: INPUT -> KIRIM PERMINTAAN -> HASIL
-- ==========================================
local function parseIds(raw: string): {string}
	local seen: {[string]: boolean} = {}
	local out: {string} = {}
	if type(raw) ~= "string" then return out end
	for digits in raw:gmatch("%d+") do
		if #digits >= 4 and not seen[digits] then
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

local function fetchAndStoreSession(): (string, boolean, string)
	local res, ok, info = apiRequest({
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
		end
		return CONFIG.SessionId, true, info
	end
	return CONFIG.SessionId, false, info
end

local function spoofSingleEntry(entry: SpoofEntry, filterMode: string): (boolean, string, {[string]: any})
	local assetId = entry.id
	local isRbxmMode = (entry.kind == "rbxm") or (filterMode == "Model" or filterMode == "Anim")

	local jsonRecord: {[string]: any} = (entry.kind == "rbxm")
		and {
			nama = entry.name,
			id = assetId,
			status = entry.statusType or "Dance",
		}
		or {
			nama_song = entry.name,
			id = assetId,
			playbackspeed = entry.playbackSpeed or 1.0,
		}

	local _, cmdOk, cmdInfo = apiRequest({
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
		return false, assetId .. " -> Gagal kirim perintah (" .. cmdInfo .. ")", jsonRecord
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
					elseif filterMode == "Auto" and entry.kind ~= "rbxm" then
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
		return false, assetId .. " -> File hasil belum muncul di /list-files", jsonRecord
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

	local dlRes, dlOk, dlInfo = apiRequest({
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
		local baseFileName = sanitizeFileName(entry.name)
		local outRel = subDir .. baseFileName .. ext
		local saved = saveTextFile(outRel, tostring(dlRes.Body))
		if saved then
			return true, entry.name .. " (" .. assetId .. ") -> " .. CONFIG.WorkspaceRoot .. "/" .. outRel, jsonRecord
		end
		return false, assetId .. " -> Gagal menyimpan file lokal", jsonRecord
	end

	return false, assetId .. " -> Gagal unduh (" .. dlInfo .. ")", jsonRecord
end

-- Cek Koneksi
local isCheckingConn = false
CekKoneksiBtn.MouseButton1Click:Connect(function()
	if isCheckingConn then return end
	isCheckingConn = true
	switchTab("Spoof")
	setSpoofBar("working", 0.35)
	setProcessLog("working", "Memeriksa koneksi ke " .. CONFIG.BaseUrl .. "...")
	task.spawn(function()
		local sess, sessOk, sessInfo = fetchAndStoreSession()
		local _, listOk, listInfo = apiRequest({
			Url = CONFIG.BaseUrl .. "/list-files",
			Method = "GET",
			Headers = {
				["Referer"] = CONFIG.BaseUrl .. "/tools/spoof-audio",
			},
		})
		local success = sessOk or listOk
		local msg = string.format(
			"Server: %s | Session: %s | List: %s",
			success and "Terhubung" or "Gagal",
			sess,
			listOk and listInfo or sessInfo
		)
		setSpoofBar(success and "ok" or "err", success and 1 or 0)
		setProcessLog(success and "ok" or "err", msg)
		notify("Koneksi", success and "Terhubung." or "Gagal terhubung.")
		isCheckingConn = false
	end)
end)

-- Proses Spoof (ID Massal atau File TXT Massal)
local isSpoofing = false
SpoofNowBtn.MouseButton1Click:Connect(function()
	if isSpoofing then return end

	local entries: {SpoofEntry} = {}
	if CONFIG.SpoofSourceMode == "TXT" then
		if not selectedSpoofTxtPath or selectedSpoofTxtPath == "" then
			setSpoofBar("err", 0)
			setProcessLog("err", "Pilih file .txt terlebih dahulu (klik Scan TXT -> Select).")
			notify("Spoof TXT", "Belum ada file TXT dipilih.")
			return
		end
		local txtContent = loadTextFile(selectedSpoofTxtPath)
		if not txtContent or trim(txtContent) == "" then
			setSpoofBar("err", 0)
			setProcessLog("err", "File TXT kosong atau tidak bisa dibaca: " .. selectedSpoofTxtPath)
			notify("Spoof TXT", "File TXT kosong.")
			return
		end
		local kindHint: "auto" | "audio" | "rbxm" = "auto"
		if CONFIG.SpoofFilter == "Model" or CONFIG.SpoofFilter == "Anim" then
			kindHint = "rbxm"
		elseif CONFIG.SpoofFilter == "Suara" then
			kindHint = "audio"
		end
		entries = parseTxtEntries(txtContent, kindHint)
		if #entries == 0 then
			setSpoofBar("err", 0)
			setProcessLog("err", "Tidak ada data ID valid di dalam " .. selectedSpoofTxtPath)
			notify("Spoof TXT", "Data tidak ditemukan.")
			return
		end
	else
		local ids = parseIds(AssetIdBox.Text)
		if #ids == 0 then
			setSpoofBar("err", 0)
			setProcessLog("err", "Input Asset ID kosong atau tidak valid.")
			notify("Spoof", "Input kosong.")
			return
		end
		for _, idStr in ipairs(ids) do
			local isRbxm = (CONFIG.SpoofFilter == "Model" or CONFIG.SpoofFilter == "Anim")
			table.insert(entries, {
				kind = isRbxm and "rbxm" or "audio",
				name = "Asset_" .. idStr,
				id = idStr,
				playbackSpeed = 1.0,
				statusType = "Dance",
			})
		end
	end

	isSpoofing = true
	setSpoofBar("working", 0.1)
	setProcessLog("working", "Memulai proses " .. tostring(#entries) .. " item...")
	setJsonResultText(false, "")

	task.spawn(function()
		ensureFolders()
		fetchAndStoreSession()

		local berhasil, gagal = 0, 0
		local processLines: {string} = {}
		local jsonRows: {{[string]: any}} = {}

		for i, item in ipairs(entries) do
			table.insert(processLines, string.format("[%d/%d] Memproses %s (%s)...", i, #entries, item.name, item.id))
			setSpoofBar("working", (i - 0.5) / #entries)
			setProcessLog("working", table.concat(processLines, "\n"))

			local okItem, stepMsg, rowJson = spoofSingleEntry(item, CONFIG.SpoofFilter)
			processLines[#processLines] = stepMsg
			if okItem then
				berhasil += 1
			else
				gagal += 1
			end

			table.insert(jsonRows, rowJson)
			setJsonResultText(gagal > 0, formatStackedJson(jsonRows))
			setSpoofBar((gagal == 0) and "working" or "err", i / #entries)
			setProcessLog((gagal == 0) and "working" or "err", table.concat(processLines, "\n"))

			if i < #entries then
				task.wait(0.35)
			end
		end

		local finalJson = formatStackedJson(jsonRows)
		saveTextFile("Logs/spoof_result_" .. tostring(os.time()) .. ".json", finalJson)
		table.insert(processLines, string.format("Selesai: %d berhasil, %d gagal.", berhasil, gagal))

		local allOk = (berhasil > 0 and gagal == 0)
		setSpoofBar(allOk and "ok" or "err", 1)
		setProcessLog(allOk and "ok" or "err", table.concat(processLines, "\n"))
		setJsonResultText(not allOk, finalJson)
		notify("Spoof", string.format("Selesai: %d berhasil, %d gagal.", berhasil, gagal))
		isSpoofing = false
	end)
end)

-- Proses Upload Asset
local isUploading = false
UploadActionBtn.MouseButton1Click:Connect(function()
	if isUploading then return end
	local _, apiKey = syncCredentialsFromInputs()
	if apiKey == "" then
		updateUploadOutcome("err", 0, "API Key (x-api-key) belum diisi di Setting.")
		notify("Upload", "API Key kosong.")
		return
	end

	local assetName = trim(UploadNameBox.Text)
	if assetName == "" then assetName = "IkyyAsset_" .. tostring(os.time()) end
	local assetType = trim(UploadTypeBox.Text)
	if assetType == "" then assetType = "Model" end
	local creatorIdNum = tonumber(trim(UploadCreatorBox.Text):match("%d+")) or LocalPlayer.UserId
	local isGroup = (trim(UploadOwnerModeBox.Text):lower() == "group")

	local rawInput = trim(UploadPayloadBox.Text)
	if rawInput == "" and selectedSpoofRelPath then
		rawInput = selectedSpoofRelPath
	end

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
	updateUploadOutcome("working", 0.35, "Mengirim permintaan upload '" .. assetName .. "' (" .. uploadFilename .. ")...")
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
		local res, ok, info = apiRequest({
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
			res, ok, info = apiRequest({
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

		local bodyStr = res and tostring(res.Body or "") or ""
		if ok and res then
			saveTextFile("Uploads/upload_" .. tostring(os.time()) .. ".json", bodyStr)
			updateUploadOutcome("ok", 1, "Berhasil (" .. info .. "):\n" .. bodyStr:sub(1, 300))
			notify("Upload", "Berhasil.")
		else
			updateUploadOutcome("err", 0, "Gagal (" .. info .. "):\n" .. bodyStr:sub(1, 300))
			notify("Upload", "Gagal.")
		end
		isUploading = false
	end)
end)

-- Proses Place Maker
local isCreatingPlace = false
CreatePlaceBtn.MouseButton1Click:Connect(function()
	if isCreatingPlace then return end
	local cookieVal = syncCredentialsFromInputs()
	if cookieVal == "" then
		updateToolsOutcome("err", 0, "Cookie .ROBLOSECURITY belum diisi di Setting.")
		notify("Place Maker", "Cookie kosong.")
		return
	end

	local tplId = tonumber(trim(TemplateIdBox.Text):match("%d+")) or 95206881
	local grpId = tonumber(trim(GroupIdBox.Text):match("%d+"))
	local count = math.clamp(tonumber(trim(PlaceCountBox.Text):match("%d+")) or 1, 1, 50)

	isCreatingPlace = true
	updateToolsOutcome("working", 0.1, "Mengirim permintaan pembuatan " .. tostring(count) .. " place...")
	task.spawn(function()
		local csrf = ""
		local sukses, gagal = 0, 0
		local lines: {string} = {}

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
				table.insert(lines, "#" .. tostring(i) .. " OK: " .. bodyStr)
			else
				gagal += 1
				table.insert(lines, "#" .. tostring(i) .. " Gagal (" .. info .. "): " .. bodyStr:sub(1, 140))
			end

			updateToolsOutcome((gagal == 0) and "working" or "err", i / count, table.concat(lines, "\n"))
			if i < count then
				task.wait(1)
			end
		end

		local allOk = (sukses > 0 and gagal == 0)
		updateToolsOutcome(allOk and "ok" or "err", 1, table.concat(lines, "\n"))
		notify("Place Maker", string.format("Selesai: %d berhasil, %d gagal.", sukses, gagal))
		isCreatingPlace = false
	end)
end)

-- Proses Asset Permissions
local isGrantingPerm = false
GrantPermBtn.MouseButton1Click:Connect(function()
	if isGrantingPerm then return end
	local _, apiKey = syncCredentialsFromInputs()
	if apiKey == "" then
		updateToolsOutcome("err", 0, "API Key (x-api-key) belum diisi di Setting.")
		notify("Permissions", "API Key kosong.")
		return
	end

	local univId = trim(TargetUniverseBox.Text):match("%d+")
	local ids = parseIds(PermIdsBox.Text)
	if not univId or #ids == 0 then
		updateToolsOutcome("err", 0, "Target Universe ID atau daftar Asset ID masih kosong.")
		notify("Permissions", "Input kosong.")
		return
	end

	isGrantingPerm = true
	updateToolsOutcome("working", 0.1, "Mengirim izin untuk " .. tostring(#ids) .. " aset ke Universe " .. univId .. "...")
	task.spawn(function()
		local batchSize = 50
		local totalBatches = math.ceil(#ids / batchSize)
		local suksesBatch, gagalBatch = 0, 0
		local bIdx = 0
		local lines: {string} = {}

		for i = 1, #ids, batchSize do
			bIdx += 1
			local reqList = {}
			for j = i, math.min(i + batchSize - 1, #ids) do
				local numId = tonumber(ids[j])
				if numId then
					table.insert(reqList, { assetId = numId })
				end
			end

			local res, ok, info = apiRequest({
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

			local bodyStr = res and tostring(res.Body or "") or ""
			if ok and res then
				suksesBatch += 1
				saveTextFile("Logs/perm_" .. tostring(os.time()) .. "_" .. tostring(bIdx) .. ".json", bodyStr)
				table.insert(lines, "Batch " .. tostring(bIdx) .. "/" .. tostring(totalBatches) .. " OK (" .. tostring(#reqList) .. " ID)")
			else
				gagalBatch += 1
				table.insert(lines, "Batch " .. tostring(bIdx) .. " Gagal (" .. info .. "): " .. bodyStr:sub(1, 140))
			end

			updateToolsOutcome((gagalBatch == 0) and "working" or "err", bIdx / totalBatches, table.concat(lines, "\n"))
			if i + batchSize <= #ids then
				task.wait(1)
			end
		end

		local allOk = (suksesBatch > 0 and gagalBatch == 0)
		updateToolsOutcome(allOk and "ok" or "err", 1, table.concat(lines, "\n"))
		notify("Permissions", allOk and "Berhasil." or "Sebagian/semua gagal.")
		isGrantingPerm = false
	end)
end)
