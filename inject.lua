--!strict
-- Plugin Studio Lite (Delta Executor Edition - Permission Place, Setting & Console) by Ikyy
-- Alur: Input GUI -> Validasi -> Kirim Permintaan -> Output Realtime (Icon Game, Name Game, Status + Console)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

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
	ActiveTab = "PermissionPlace",
	DefaultUniverseId = "10516113765",
	UserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
}

type GenreEntry = {
	label: string,
	apiValue: string,
	genreType: string,
}

local ROBLOX_GENRES: {GenreEntry} = {
	{ label = "All (Semua)", apiValue = "All", genreType = "All" },
	{ label = "Town and City (Sosial/Kota)", apiValue = "Town and City", genreType = "TownAndCity" },
	{ label = "Adventure (Petualangan)", apiValue = "Adventure", genreType = "Adventure" },
	{ label = "Fantasy (Fantasi)", apiValue = "Fantasy", genreType = "Fantasy" },
	{ label = "Sci-Fi", apiValue = "Sci-Fi", genreType = "SciFi" },
	{ label = "Horror / Scary", apiValue = "Scary", genreType = "Scary" },
	{ label = "Fighting (Pertarungan)", apiValue = "Fighting", genreType = "Fighting" },
	{ label = "FPS", apiValue = "FPS", genreType = "FPS" },
	{ label = "RPG", apiValue = "RPG", genreType = "RPG" },
	{ label = "Sports (Olahraga)", apiValue = "Sports", genreType = "Sports" },
	{ label = "Comedy / Funny", apiValue = "Comedy", genreType = "Comedy" },
	{ label = "Building", apiValue = "Building", genreType = "Building" },
	{ label = "Military", apiValue = "Military", genreType = "Military" },
	{ label = "Medieval", apiValue = "Medieval", genreType = "Medieval" },
	{ label = "Ninja", apiValue = "Ninja", genreType = "Ninja" },
	{ label = "Pirate", apiValue = "Pirate", genreType = "Pirate" },
	{ label = "Naval", apiValue = "Naval", genreType = "Naval" },
	{ label = "Western / Wild West", apiValue = "Wild West", genreType = "WildWest" },
	{ label = "War", apiValue = "War", genreType = "War" },
	{ label = "Skate Park", apiValue = "Skate Park", genreType = "SkatePark" },
	{ label = "Tutorial", apiValue = "Tutorial", genreType = "Tutorial" },
}

local MEMORY_FILES: {[string]: string} = {}
local CONSOLE_LINES: {string} = {}

local WINDOW_SIZE = UDim2.fromOffset(540, 320)
local WINDOW_POS = UDim2.new(0.5, -270, 0.5, -160)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS

local function trim(s: string?): string
	if type(s) ~= "string" then
		return ""
	end
	return (s:match("^%s*(.-)%s*$") or "") :: string
end

local function normalizeCookie(rawCookie: string): string
	local c = trim(rawCookie)
	if c == "" then
		return ""
	end
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
		if StarterGui and type(StarterGui.SetCore) == "function" then
			StarterGui:SetCore("SendNotification", {
				Title = tostring(title),
				Text = tostring(text),
				Duration = 3,
			})
		end
	end)
end

local function safeClockString(): string
	local ok, res = pcall(function()
		local osLib = os :: any
		if type(osLib) == "table" and type(osLib.date) == "function" then
			return osLib.date("%H:%M:%S")
		end
		return nil
	end)
	if ok and type(res) == "string" and res ~= "" then
		return res
	end
	local okClk, clk = pcall(function()
		return os.clock()
	end)
	local t = math.floor((okClk and type(clk) == "number") and clk or 0)
	local h = math.floor(t / 3600) % 24
	local m = math.floor(t / 60) % 60
	local s = t % 60
	return string.format("%02d:%02d:%02d", h, m, s)
end

local function safeTimestamp(): number
	local ok, res = pcall(function()
		local osLib = os :: any
		if type(osLib) == "table" and type(osLib.time) == "function" then
			return osLib.time()
		end
		return nil
	end)
	if ok and type(res) == "number" then
		return res
	end
	local okClk, clk = pcall(function()
		return os.clock()
	end)
	return math.floor((okClk and type(clk) == "number") and clk or 0)
end

-- ==========================================
-- DELTA EXECUTOR ENVIRONMENT BRIDGE (SAFE)
-- ==========================================
local function getEnvTable(): {[string]: any}
	local env: {[string]: any} = {}

	local function copyFromTable(tbl: any)
		if type(tbl) ~= "table" then
			return
		end
		pcall(function()
			for k, v in pairs(tbl) do
				if type(k) == "string" and env[k] == nil then
					env[k] = v
				end
			end
		end)
	end

	pcall(function()
		local gf = getfenv :: any
		if type(gf) == "function" then
			local ok0, fenv0 = pcall(gf, 0)
			if ok0 and type(fenv0) == "table" then
				copyFromTable(fenv0)
				local rawGetGenv = rawget(fenv0, "getgenv")
				if type(rawGetGenv) == "function" then
					local okG, g = pcall(rawGetGenv)
					if okG then
						copyFromTable(g)
					end
				end
				local rawShared = rawget(fenv0, "shared")
				if type(rawShared) == "table" then
					copyFromTable(rawShared)
				end
			end
		end
	end)

	copyFromTable(_G :: any)

	return env
end

local ENV = getEnvTable()

local function getCallable(fnVal: any): ((...any) -> ...any)?
	if type(fnVal) == "function" then
		return fnVal :: (...any) -> ...any
	end
	return nil
end

local function getDeltaHttpFunc(): ((any) -> any)?
	local candidates: {any} = {
		ENV.request,
		ENV.http_request,
		type(ENV.syn) == "table" and ENV.syn.request or nil,
		type(ENV.http) == "table" and ENV.http.request or nil,
		type(ENV.fluxus) == "table" and ENV.fluxus.request or nil,
		type(ENV.delta) == "table" and ENV.delta.request or nil,
	}
	for _, fn in ipairs(candidates) do
		local c = getCallable(fn)
		if c then
			return c :: (any) -> any
		end
	end
	return nil
end

local function setClipboardText(text: string): boolean
	local clipFns: {any} = { ENV.setclipboard, ENV.toclipboard, ENV.set_clipboard }
	for _, fn in ipairs(clipFns) do
		local c = getCallable(fn)
		if c then
			local ok = pcall(c, text)
			if ok then
				return true
			end
		end
	end
	notify("Universe ID", text)
	return false
end

local fnWriteFile = getCallable(ENV.writefile)
local fnReadFile = getCallable(ENV.readfile)
local fnIsFile = getCallable(ENV.isfile)
local fnIsFolder = getCallable(ENV.isfolder)
local fnMakeFolder = getCallable(ENV.makefolder)

local function ensureFolders()
	local makeFn = fnMakeFolder
	if not makeFn then
		return
	end
	local folders = {
		CONFIG.WorkspaceRoot,
		CONFIG.WorkspaceRoot .. "/Logs",
	}
	for _, folder in ipairs(folders) do
		local exists = false
		local isFldFn = fnIsFolder
		if isFldFn then
			local okChk, resChk = pcall(isFldFn, folder)
			exists = okChk and (resChk == true)
		end
		if not exists then
			pcall(makeFn, folder)
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

	local writeFn = fnWriteFile
	if not writeFn then
		return true
	end

	ensureFolders()
	local ok = pcall(writeFn, fullPath, content)
	return ok
end

local function loadTextFile(relPath: string): string?
	local cleanRel = normalizeWorkspaceRelPath(relPath)
	local candidates = {
		CONFIG.WorkspaceRoot .. "/" .. cleanRel,
		cleanRel,
	}

	local readFn = fnReadFile
	if readFn then
		for _, fullPath in ipairs(candidates) do
			local canRead = true
			local isFileFn = fnIsFile
			if isFileFn then
				local okChk, exists = pcall(isFileFn, fullPath)
				canRead = okChk and (exists == true)
			end
			if canRead then
				local okRead, res = pcall(readFn, fullPath)
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
	local stamp = safeClockString()
	local line = string.format("[%s] [%s] %s", stamp, level, message)
	table.insert(CONSOLE_LINES, line)
	if #CONSOLE_LINES > 250 then
		table.remove(CONSOLE_LINES, 1)
	end
	local fn = appendConsoleLineFn
	if type(fn) == "function" then
		pcall(fn, level, line)
	end
end

local function sanitizeHeaders(rawHeaders: {[string]: string}?, hasBody: boolean): {[string]: string}
	local clean: {[string]: string} = {
		["User-Agent"] = CONFIG.UserAgent,
	}
	local seenLower: {[string]: boolean} = {
		["user-agent"] = true,
	}
	if rawHeaders then
		for k, v in pairs(rawHeaders) do
			if type(k) == "string" and type(v) == "string" then
				local lowK = k:lower()
				if lowK == "content-type" and hasBody then
					-- Biarkan executor menyetel Content-Type tunggal dari Body JSON
				elseif not seenLower[lowK] then
					seenLower[lowK] = true
					local cleanVal = v:match("^%s*([^,]+)") or v
					clean[k] = cleanVal:match("^%s*(.-)%s*$") or cleanVal
				end
			end
		end
	end
	return clean
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
	local hasBody = (options.Body ~= nil and options.Body ~= "")
	pushConsole("REQ", methodStr .. " " .. options.Url)

	local maxAttempts = math.max(1, options.Retries or 1)
	local baseHeaders = sanitizeHeaders(options.Headers, hasBody)

	local lastRes: any = nil
	local lastOk = false
	local lastErr = "Tidak ada respons"

	for attempt = 1, maxAttempts do
		local reqPayload: {[string]: any} = {
			Url = options.Url,
			Method = methodStr,
			Headers = baseHeaders,
		}
		if options.Body ~= nil then
			reqPayload.Body = options.Body
		end

		local ok, res = pcall(reqFn, reqPayload)
		if ok and type(res) == "table" then
			lastRes = res
			local code = tonumber(res.StatusCode or res.Status or res.status_code) or 0
			local rawBody = tostring(res.Body or "")
			local snippet = rawBody:gsub("[\r\n]+", " ")
			if #snippet > 180 then
				snippet = snippet:sub(1, 180) .. "..."
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
	if type(headers) ~= "table" then
		return nil
	end
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
type GameStatus = "publik" | "private" | "tidak diketahui"

type GameResultCardData = {
	universeId: string,
	rootPlaceId: string?,
	iconImage: string,
	gameName: string,
	status: GameStatus,
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
	local genreVal: string? = nil
	local statusVal: GameStatus = "tidak diketahui"
	local rootPlaceId: string? = fallbackPlaceId

	local devHeaders: {[string]: string} = {}
	if trim(cookieVal) ~= "" then
		devHeaders["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal)
	end

	local devRes, devOk = apiRequest({
		Url = "https://develop.roblox.com/v1/universes/" .. cleanUniv,
		Method = "GET",
		Headers = devHeaders,
		Retries = 1,
	})

	if devOk and devRes and devRes.Body then
		local okDec, decoded = pcall(function()
			return HttpService:JSONDecode(tostring(devRes.Body))
		end)
		if okDec and type(decoded) == "table" then
			if type(decoded.name) == "string" and trim(decoded.name) ~= "" then
				nameVal = trim(decoded.name)
			end
			if type(decoded.genre) == "string" and trim(decoded.genre) ~= "" then
				genreVal = trim(decoded.genre)
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

	if not nameVal or not rootPlaceId or not genreVal then
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
				if not genreVal and type(g.genre) == "string" and trim(g.genre) ~= "" then
					genreVal = trim(g.genre)
				end
				if not rootPlaceId and g.rootPlaceId ~= nil and tostring(g.rootPlaceId):match("%d+") then
					rootPlaceId = tostring(g.rootPlaceId):match("%d+")
				end
			end
		end
	end

	local finalName = nameVal or ("Place #" .. cleanUniv)
	local iconUri = resolveRealtimeGameIcon(cleanUniv, rootPlaceId, cookieVal)
	local metaStr = "Universe: " .. cleanUniv
		.. (rootPlaceId and (" • Place: " .. rootPlaceId) or "")
		.. (genreVal and (" • Genre: " .. genreVal) or "")

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
-- API PERMISSION PLACE
-- ==========================================
local function sendAuthedJsonRequest(
	method: string,
	url: string,
	cookieVal: string,
	csrfSeed: string,
	jsonBody: string?,
	queryParams: {[string]: string}?
): (boolean, number, string, {[string]: any}?, string)
	local fullUrl = url
	if queryParams then
		local parts: {string} = {}
		for k, v in pairs(queryParams) do
			table.insert(parts, HttpService:UrlEncode(k) .. "=" .. HttpService:UrlEncode(v))
		end
		if #parts > 0 then
			fullUrl = fullUrl .. (fullUrl:find("?", 1, true) and "&" or "?") .. table.concat(parts, "&")
		end
	end

	local currentCsrf = csrfSeed
	local function doSend(token: string)
		local hdrs: {[string]: string} = {
			["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
			["Accept"] = "application/json",
			["Origin"] = "https://create.roblox.com",
			["Referer"] = "https://create.roblox.com/",
		}
		if token ~= "" then
			hdrs["X-CSRF-TOKEN"] = token
		end
		return apiRequest({
			Url = fullUrl,
			Method = method,
			Headers = hdrs,
			Body = jsonBody,
			Retries = 1,
		})
	end

	local res, ok, info = doSend(currentCsrf)
	local statusCode = res and (tonumber(res.StatusCode or res.Status or res.status_code) or 0) or 0
	if not ok and res and statusCode == 403 then
		local newToken = getHeaderCaseInsensitive(res.Headers, "x-csrf-token")
		if newToken and newToken ~= "" then
			pushConsole("INFO", "Refresh X-CSRF-TOKEN otomatis untuk " .. url)
			currentCsrf = newToken
			res, ok, info = doSend(currentCsrf)
			statusCode = res and (tonumber(res.StatusCode or res.Status or res.status_code) or 0) or 0
		end
	end

	local bodyStr = res and tostring(res.Body or "") or ""
	local decoded: {[string]: any}? = nil
	if bodyStr ~= "" then
		local okDec, dec = pcall(function()
			return HttpService:JSONDecode(bodyStr)
		end)
		if okDec and type(dec) == "table" then
			decoded = dec
		end
	end

	return ok, statusCode, bodyStr, decoded, currentCsrf
end

local function normalizeGenreSelection(rawGenre: string): (string, string)
	local gTrim = trim(rawGenre)
	if gTrim == "" then
		return "All", "All"
	end
	local low = gTrim:lower()
	for _, entry in ipairs(ROBLOX_GENRES) do
		if entry.apiValue:lower() == low or entry.genreType:lower() == low or entry.label:lower() == low then
			return entry.apiValue, entry.genreType
		end
	end
	if low:find("sosial", 1, true) or low:find("social", 1, true) or low:find("town", 1, true) then
		return "Town and City", "TownAndCity"
	end
	return gTrim, gTrim:gsub("%s+", "")
end

local function updateUniverseDetailStep1(
	universeId: string,
	cookieVal: string,
	inputName: string,
	inputDesc: string,
	selectedGenreApi: string,
	csrfSeed: string
): (boolean, string, {[string]: any}, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	local currentCsrf = csrfSeed
	local nameVal = trim(inputName)
	local descVal = trim(inputDesc)
	local genreApi, genreTypeEnum = normalizeGenreSelection(selectedGenreApi)
	local rootPlaceId: string? = nil

	local okGet, _, _, getDec, nextCsrfGet = sendAuthedJsonRequest(
		"GET",
		"https://develop.roblox.com/v1/universes/" .. cleanUniv,
		cookieVal,
		currentCsrf,
		nil,
		nil
	)
	currentCsrf = nextCsrfGet
	if okGet and type(getDec) == "table" then
		if nameVal == "" and type(getDec.name) == "string" and trim(getDec.name) ~= "" then
			nameVal = trim(getDec.name)
		end
		if descVal == "" and type(getDec.description) == "string" and trim(getDec.description) ~= "" then
			descVal = trim(getDec.description)
		end
		if getDec.rootPlaceId ~= nil then
			rootPlaceId = tostring(getDec.rootPlaceId):match("%d+")
		end
	end

	if nameVal == "" then
		nameVal = "Place #" .. cleanUniv
	end
	if descVal == "" then
		descVal = "Experience #" .. cleanUniv
	end

	local detailSummary: {[string]: any} = {
		universeId = cleanUniv,
		rootPlaceId = rootPlaceId or "-",
		name = nameVal,
		description = descVal,
		genre = genreApi,
	}

	local payloadJson = HttpService:JSONEncode({
		name = nameVal,
		description = descVal,
		genre = genreApi,
		genreType = genreTypeEnum,
	})

	pushConsole("INFO", string.format("[Step 1: Detail Place] Kirim -> Name='%s' | Genre='%s' (%s) | Desc='%s'", nameVal, genreApi, genreTypeEnum, descVal))

	local okV2, codeV2, bodyV2, decV2, csrfV2 = sendAuthedJsonRequest(
		"PATCH",
		"https://develop.roblox.com/v2/universes/" .. cleanUniv .. "/configuration",
		cookieVal,
		currentCsrf,
		payloadJson,
		nil
	)
	currentCsrf = csrfV2

	if okV2 then
		saveTextFile("Logs/perm_step1_detail_" .. cleanUniv .. "_" .. tostring(safeTimestamp()) .. ".json", bodyV2)
		if type(decV2) == "table" then
			detailSummary.name = tostring(decV2.name or nameVal)
			detailSummary.description = tostring(decV2.description or descVal)
			local returnedGenre = tostring(decV2.genreType or decV2.genre or genreApi)
			if returnedGenre ~= "" then
				detailSummary.genre = returnedGenre
			end
		end

		if rootPlaceId and rootPlaceId ~= "" then
			local placePayload = HttpService:JSONEncode({
				name = nameVal,
				description = descVal,
				genre = genreApi,
			})
			local _, _, _, _, csrfPlace = sendAuthedJsonRequest(
				"PATCH",
				"https://develop.roblox.com/v2/places/" .. rootPlaceId,
				cookieVal,
				currentCsrf,
				placePayload,
				nil
			)
			currentCsrf = csrfPlace
		end

		local resultMsg = string.format("Detail Tersimpan: '%s' | Genre: %s", tostring(detailSummary.name), tostring(detailSummary.genre))
		pushConsole("OK", "[Step 1: Detail Place] Sukses (HTTP " .. tostring(codeV2) .. ") -> " .. resultMsg)
		return true, resultMsg, detailSummary, currentCsrf
	end

	pushConsole("WARN", string.format("[Step 1: Detail Place] PATCH v2 HTTP %d, mencoba PATCH v1...", codeV2))
	local okV1, codeV1, bodyV1, decV1, csrfV1 = sendAuthedJsonRequest(
		"PATCH",
		"https://develop.roblox.com/v1/universes/" .. cleanUniv .. "/configuration",
		cookieVal,
		currentCsrf,
		payloadJson,
		nil
	)
	currentCsrf = csrfV1
	if okV1 then
		saveTextFile("Logs/perm_step1_detail_v1_" .. cleanUniv .. "_" .. tostring(safeTimestamp()) .. ".json", bodyV1)
		if type(decV1) == "table" then
			detailSummary.name = tostring(decV1.name or nameVal)
			detailSummary.description = tostring(decV1.description or descVal)
			detailSummary.genre = tostring(decV1.genreType or decV1.genre or genreApi)
		end
		local resultMsg = string.format("Detail Tersimpan: '%s' | Genre: %s", tostring(detailSummary.name), tostring(detailSummary.genre))
		pushConsole("OK", "[Step 1: Detail Place] Sukses v1 (HTTP " .. tostring(codeV1) .. ") -> " .. resultMsg)
		return true, resultMsg, detailSummary, currentCsrf
	end

	local errSnippet = bodyV2 ~= "" and bodyV2:sub(1, 130) or bodyV1:sub(1, 130)
	local errMsg = string.format("Gagal Detail Place (HTTP %d/%d): %s", codeV2, codeV1, errSnippet)
	pushConsole("ERR", "[Step 1: Detail Place] " .. errMsg)
	return false, errMsg, detailSummary, currentCsrf
end

type EvaluatedAnswerItem = {
	questionId: any,
	section: string,
	title: string,
	chosenLabel: string,
	chosenValue: any,
}

local function evaluateQuestionnaireWithCustomLogic(schemaObj: any): ({{[string]: any}}, {EvaluatedAnswerItem}, {[string]: any})
	local payloadAnswers: {{[string]: any}} = {}
	local auditList: {EvaluatedAnswerItem} = {}
	local directMapAnswers: {[string]: any} = {}
	local seenQ: {[string]: boolean} = {}

	local socialHangoutPrimaryAnsweredYes = false

	local function pickOptionValue(optionsList: any, targetWord: string): (any, string)
		local targetLow = targetWord:lower()
		if type(optionsList) == "table" and #optionsList > 0 then
			for _, opt in ipairs(optionsList) do
				if type(opt) == "table" then
					local lbl = tostring(opt.label or opt.text or opt.displayText or opt.value or opt.id or "")
					local val = opt.id ~= nil and opt.id or (opt.value ~= nil and opt.value or lbl)
					local lblLow = lbl:lower()
					local valLow = tostring(val):lower()

					if targetLow == "game" then
						if lblLow == "game" or lblLow:find("game", 1, true) or valLow == "game" then
							return val, lbl ~= "" and lbl or "Game"
						end
					elseif targetLow == "yes" then
						if lblLow == "yes" or lblLow == "ya" or lblLow == "true" or valLow == "yes" or valLow == "true" then
							return val, lbl ~= "" and lbl or "Yes"
						end
					else
						if lblLow == "no" or lblLow == "tidak" or lblLow == "none" or lblLow == "false" or valLow == "no" or valLow == "false" then
							return val, lbl ~= "" and lbl or "No"
						end
					end
				elseif type(opt) == "string" then
					local optLow = opt:lower()
					if targetLow == "game" and optLow:find("game", 1, true) then
						return opt, opt
					elseif targetLow == "yes" and (optLow == "yes" or optLow == "ya" or optLow == "true") then
						return opt, opt
					elseif targetLow == "no" and (optLow == "no" or optLow == "tidak" or optLow == "none" or optLow == "false") then
						return opt, opt
					end
				end
			end

			for _, opt in ipairs(optionsList) do
				if type(opt) == "boolean" then
					if targetLow == "yes" and opt == true then
						return true, "Yes"
					elseif targetLow == "no" and opt == false then
						return false, "No"
					end
				end
			end
		end

		if targetLow == "game" then
			return "Game", "Game"
		elseif targetLow == "yes" then
			return "Yes", "Yes"
		end
		return "No", "No"
	end

	local function detectSectionAndDecision(qNode: {[string]: any}, inheritedSection: string): (string, string)
		local qIdStr = tostring(qNode.questionId or qNode.id or qNode.key or ""):lower()
		local qTitle = tostring(qNode.title or qNode.question or qNode.prompt or qNode.text or qNode.description or qNode.name or ""):lower()
		local qCat = tostring(qNode.category or qNode.section or qNode.group or inheritedSection or ""):lower()
		local combined = qIdStr .. " " .. qTitle .. " " .. qCat

		if combined:find("application", 1, true)
			or combined:find("app type", 1, true)
			or combined:find("describe your", 1, true)
			or combined:find("experience type", 1, true)
			or combined:find("what kind of", 1, true)
		then
			return "Tipe Aplikasi", "Game"
		end

		if combined:find("iarc", 1, true)
			or qIdStr:find("^iarc")
			or qCat:find("iarc", 1, true)
		then
			return "IARC", "No"
		end

		local isSocialHangout = combined:find("social hangout", 1, true)
			or combined:find("social_hangout", 1, true)
			or combined:find("socialhangout", 1, true)
			or (combined:find("social", 1, true) and combined:find("hangout", 1, true))

		if isSocialHangout then
			local isSubFollowUp = (qNode.parentQuestionId ~= nil)
				or (qNode.parentId ~= nil)
				or (qNode.dependsOn ~= nil)
				or (qNode.isFollowUp == true)
				or (qNode.isSubQuestion == true)
				or (qIdStr:find("sub", 1, true) ~= nil)
				or (qIdStr:find("follow", 1, true) ~= nil)
				or (qIdStr:find("detail", 1, true) ~= nil)
				or (qIdStr:find("child", 1, true) ~= nil)

			if not socialHangoutPrimaryAnsweredYes and not isSubFollowUp then
				socialHangoutPrimaryAnsweredYes = true
				return "Roblox (Social Hangout Awal)", "Yes"
			else
				return "Roblox (Social Hangout Lanjutan)", "No"
			end
		end

		return "Roblox (Lainnya)", "No"
	end

	local function traverseSchema(node: any, currentSection: string)
		if type(node) ~= "table" then
			return
		end

		local nextSection = currentSection
		if type(node.section) == "string" and node.section ~= "" then
			nextSection = node.section
		elseif type(node.category) == "string" and node.category ~= "" then
			nextSection = node.category
		elseif type(node.groupName) == "string" and node.groupName ~= "" then
			nextSection = node.groupName
		end

		if #node > 0 then
			for i = 1, #node do
				traverseSchema(node[i], nextSection)
			end
		end

		local qId = node.questionId or node.id or node.key
		local looksLikeQuestion = (
			node.options ~= nil
			or node.choices ~= nil
			or node.answers ~= nil
			or node.possibleAnswers ~= nil
			or node.questionType ~= nil
			or node.prompt ~= nil
			or node.question ~= nil
			or (node.title ~= nil and qId ~= nil and type(node.questions) ~= "table")
		)

		if qId ~= nil and looksLikeQuestion and type(node.data) ~= "table" then
			local qKey = tostring(qId)
			if qKey ~= "" and not seenQ[qKey] then
				seenQ[qKey] = true
				local secLabel, decisionWord = detectSectionAndDecision(node, nextSection)
				local opts = node.options or node.choices or node.answers or node.possibleAnswers
				local chosenVal, chosenLbl = pickOptionValue(opts, decisionWord)
				local rawTitle = tostring(node.title or node.question or node.prompt or node.text or qKey)

				table.insert(payloadAnswers, {
					questionId = qId,
					answer = chosenVal,
					value = chosenVal,
					response = chosenVal,
				})
				directMapAnswers[qKey] = chosenVal

				table.insert(auditList, {
					questionId = qId,
					section = secLabel,
					title = rawTitle,
					chosenLabel = chosenLbl,
					chosenValue = chosenVal,
				})
			end
		end

		local orderedKeys = {
			"applicationTypeQuestion",
			"sections",
			"groups",
			"iarcQuestions",
			"robloxQuestions",
			"questions",
			"subQuestions",
			"followUpQuestions",
			"children",
			"items",
			"data",
			"questionnaire",
		}
		local visitedKeys: {[string]: boolean} = {}
		for _, k in ipairs(orderedKeys) do
			visitedKeys[k] = true
			if type(node[k]) == "table" then
				traverseSchema(node[k], nextSection)
			end
		end

		for k, v in pairs(node) do
			if type(k) == "string" and not visitedKeys[k] and type(v) == "table" then
				traverseSchema(v, nextSection)
			end
		end
	end

	traverseSchema(schemaObj, "")

	if #payloadAnswers == 0 then
		local fallbackItems = {
			{ id = "applicationType", sec = "Tipe Aplikasi", title = "Application Type", word = "Game" },
			{ id = "iarc_violence", sec = "IARC", title = "IARC - Violence", word = "No" },
			{ id = "iarc_fear", sec = "IARC", title = "IARC - Fear / Horror", word = "No" },
			{ id = "iarc_sexuality", sec = "IARC", title = "IARC - Sexuality", word = "No" },
			{ id = "iarc_gambling", sec = "IARC", title = "IARC - Simulated Gambling", word = "No" },
			{ id = "iarc_language", sec = "IARC", title = "IARC - Crude Humor / Language", word = "No" },
			{ id = "iarc_substances", sec = "IARC", title = "IARC - Alcohol / Tobacco / Drugs", word = "No" },
			{ id = "roblox_social_hangout", sec = "Roblox (Social Hangout Awal)", title = "Social Hangout", word = "Yes" },
			{ id = "roblox_social_hangout_followup", sec = "Roblox (Social Hangout Lanjutan)", title = "Social Hangout Follow-up / Unmoderated", word = "No" },
			{ id = "roblox_freeform_user_creation", sec = "Roblox (Lainnya)", title = "Free-form User Creation", word = "No" },
			{ id = "roblox_paid_random_items", sec = "Roblox (Lainnya)", title = "Paid Random Items", word = "No" },
			{ id = "roblox_unrestricted_trading", sec = "Roblox (Lainnya)", title = "Trading / Virtual Economy", word = "No" },
		}
		for _, fb in ipairs(fallbackItems) do
			table.insert(payloadAnswers, {
				questionId = fb.id,
				answer = fb.word,
				value = fb.word,
				response = fb.word,
			})
			directMapAnswers[fb.id] = fb.word
			table.insert(auditList, {
				questionId = fb.id,
				section = fb.sec,
				title = fb.title,
				chosenLabel = fb.word,
				chosenValue = fb.word,
			})
		end
	end

	return payloadAnswers, auditList, directMapAnswers
end

local function submitContentQuestionnaireStep2(
	universeId: string,
	cookieVal: string,
	csrfSeed: string
): (boolean, string, {EvaluatedAnswerItem}, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	local currentCsrf = csrfSeed
	local univNum = tonumber(cleanUniv) or 0

	pushConsole("INFO", string.format("[Step 2: Form Rating] Mengambil kuesioner Universe #%s (v1beta1)...", cleanUniv))

	local fetchTargets = {
		{
			method = "POST",
			url = "https://apis.roblox.com/experience-guidelines-api/experience-guidelines/v1beta1/questionnaire",
			body = HttpService:JSONEncode({ universeId = univNum }) :: string?,
			query = nil :: {[string]: string}?,
		},
		{
			method = "GET",
			url = "https://apis.roblox.com/experience-guidelines-api/experience-guidelines/v1beta1/questionnaire",
			body = nil :: string?,
			query = { universeId = cleanUniv } :: {[string]: string}?,
		},
		{
			method = "POST",
			url = "https://apis.roblox.com/experience-guidelines-api/experience-guidelines/get-age-recommendation",
			body = HttpService:JSONEncode({ universeId = univNum }) :: string?,
			query = nil :: {[string]: string}?,
		},
	}

	local loadedSchema: {[string]: any} = {}
	local schemaLoadedFromServer = false
	for _, tInfo in ipairs(fetchTargets) do
		local okF, codeF, bodyF, decF, csrfF = sendAuthedJsonRequest(
			tInfo.method,
			tInfo.url,
			cookieVal,
			currentCsrf,
			tInfo.body,
			tInfo.query
		)
		currentCsrf = csrfF
		if okF and type(decF) == "table" then
			loadedSchema = decF
			schemaLoadedFromServer = true
			saveTextFile("Logs/perm_step2_schema_" .. cleanUniv .. "_" .. tostring(safeTimestamp()) .. ".json", bodyF)
			pushConsole("OK", string.format("[Step 2: Form Rating] Schema kuesioner terbaca (HTTP %d)", codeF))
			break
		end
	end

	if not schemaLoadedFromServer then
		pushConsole("WARN", "[Step 2: Form Rating] Menggunakan struktur standar (App=Game, IARC=No, Social Hangout=Yes->No)")
	end

	local builtAnswers, auditList, directMap = evaluateQuestionnaireWithCustomLogic(loadedSchema)

	pushConsole("INFO", string.format("[Step 2: Form Rating] Total %d item jawaban disiapkan:", #auditList))
	for idx, item in ipairs(auditList) do
		pushConsole("INFO", string.format("   %d. [%s] %s => %s", idx, item.section, item.title:sub(1, 48), item.chosenLabel))
	end

	local submitPayloads = {
		HttpService:JSONEncode({
			universeId = univNum,
			questionnaireId = loadedSchema.questionnaireId or loadedSchema.id,
			applicationType = "Game",
			responses = builtAnswers,
		}),
		HttpService:JSONEncode({
			universeId = univNum,
			applicationType = "Game",
			answers = directMap,
			responses = builtAnswers,
		}),
	}

	local submitUrls = {
		"https://apis.roblox.com/experience-guidelines-api/experience-guidelines/v1beta1/questionnaire/submit",
		"https://apis.roblox.com/experience-guidelines-api/experience-guidelines/v1beta1/questionnaire",
	}

	local lastErr = "Endpoint submit mengembalikan non-200"
	for _, sUrl in ipairs(submitUrls) do
		for _, sBody in ipairs(submitPayloads) do
			local okS, codeS, bodyS, decS, csrfS = sendAuthedJsonRequest(
				"POST",
				sUrl,
				cookieVal,
				currentCsrf,
				sBody,
				nil
			)
			currentCsrf = csrfS
			if okS then
				saveTextFile("Logs/perm_step2_submit_" .. cleanUniv .. "_" .. tostring(safeTimestamp()) .. ".json", bodyS)
				local ratingBadge = ""
				if type(decS) == "table" then
					local rec = decS.ageRecommendationDetails or decS.ageRecommendation or decS
					if type(rec) == "table" and (rec.minimumAge ~= nil or rec.displayName ~= nil) then
						ratingBadge = " | Rating: " .. tostring(rec.displayName or ("Usia " .. tostring(rec.minimumAge) .. "+"))
					end
				end
				local resMsg = string.format("Form Rating Terkirim (HTTP %d): App=Game, IARC=No, SocialHangout=Yes->No%s", codeS, ratingBadge)
				pushConsole("OK", "[Step 2: Form Rating] " .. resMsg)
				return true, resMsg, auditList, currentCsrf
			else
				lastErr = string.format("HTTP %d (%s)", codeS, bodyS ~= "" and bodyS:sub(1, 100) or "empty")
			end
		end
	end

	local failMsg = "Gagal kirim Form Rating: " .. lastErr
	pushConsole("ERR", "[Step 2: Form Rating] " .. failMsg)
	return false, failMsg, auditList, currentCsrf
end

local function applyPlacePermissionAction(
	universeId: string,
	cookieVal: string,
	makePublic: boolean,
	csrfSeed: string
): (boolean, string, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	local currentCsrf = csrfSeed

	local okU, _, _, decU, csrfU = sendAuthedJsonRequest(
		"GET",
		"https://develop.roblox.com/v1/universes/" .. cleanUniv,
		cookieVal,
		currentCsrf,
		nil,
		nil
	)
	currentCsrf = csrfU

	local rootPlaceId: string? = nil
	if okU and type(decU) == "table" and decU.rootPlaceId ~= nil then
		rootPlaceId = tostring(decU.rootPlaceId):match("%d+")
	end

	if makePublic and rootPlaceId and rootPlaceId ~= "" then
		local _, _, _, _, csrfP = sendAuthedJsonRequest(
			"PATCH",
			"https://develop.roblox.com/v2/places/" .. rootPlaceId,
			cookieVal,
			currentCsrf,
			HttpService:JSONEncode({ maxPlayerCount = 50 }),
			nil
		)
		currentCsrf = csrfP
	end

	local actionSlug = makePublic and "activate" or "deactivate"
	local url = "https://develop.roblox.com/v1/universes/" .. cleanUniv .. "/" .. actionSlug

	pushConsole("INFO", string.format("[Step 3: Akses Place] Kirim status '%s' untuk Universe #%s...", makePublic and "Publik" or "Private", cleanUniv))
	local okA, codeA, bodyA, _, csrfA = sendAuthedJsonRequest(
		"POST",
		url,
		cookieVal,
		currentCsrf,
		"{}",
		nil
	)
	currentCsrf = csrfA

	if okA then
		saveTextFile("Logs/perm_access_" .. cleanUniv .. "_" .. tostring(safeTimestamp()) .. ".json", bodyA)
		local labelOut = makePublic and "PUBLIK" or "PRIVATE"
		pushConsole("OK", string.format("[Step 3: Akses Place] Status akses Universe #%s berhasil diubah ke %s (HTTP %d)", cleanUniv, labelOut, codeA))
		return true, "Status akses berhasil diubah ke " .. labelOut .. " (HTTP " .. tostring(codeA) .. ")", currentCsrf
	end

	local reasonHint = ""
	if codeA == 403 then
		reasonHint = " -> Pastikan akun cookie adalah pemilik Universe ini & Root Place sudah memiliki versi terpublikasi (Published)."
	end
	local snippet = bodyA ~= "" and (" | " .. bodyA:sub(1, 140)) or ""
	pushConsole("ERR", string.format("[Step 3: Akses Place] Gagal ubah status akses ke %s (HTTP %d)%s%s", makePublic and "PUBLIK" or "PRIVATE", codeA, snippet, reasonHint))
	return false, string.format("Gagal ubah status akses (HTTP %d)%s", codeA, reasonHint), currentCsrf
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
		if type(onChanged) == "function" then
			pcall(onChanged, isOn)
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

local FloatingProfileBtn = Instance.new("ImageButton")
FloatingProfileBtn.Name = "FloatingProfileToggle"
FloatingProfileBtn.Size = ICON_SIZE
FloatingProfileBtn.Position = ICON_DEFAULT_POS
FloatingProfileBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
FloatingProfileBtn.BorderSizePixel = 0
FloatingProfileBtn.Visible = false
FloatingProfileBtn.AutoButtonColor = false
FloatingProfileBtn.ZIndex = 50
FloatingProfileBtn.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
FloatingProfileBtn.Parent = ScreenGui

task.spawn(function()
	local avatarUrl = getUserAvatarAsync(LocalPlayer.UserId)
	if FloatingProfileBtn and FloatingProfileBtn.Parent then
		FloatingProfileBtn.Image = avatarUrl
	end
end)

Instance.new("UICorner", FloatingProfileBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingProfileBtn)
FloatStroke.Color = Color3.fromRGB(130, 92, 255)
FloatStroke.Thickness = 2

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
LogoIcon.Text = "🔐"
LogoIcon.TextColor3 = Color3.fromRGB(215, 210, 255)
LogoIcon.TextSize = 14
LogoIcon.Font = Enum.Font.GothamBold
LogoIcon.Parent = HeaderLogoBox

local SubTitleLabel = Instance.new("TextLabel")
SubTitleLabel.Size = UDim2.new(0, 320, 0, 11)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 5)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • PERMISSION PLACE, SETTING & CONSOLE"
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
		local cam = workspace.CurrentCamera
		local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
		local iconW = ICON_SIZE.X.Offset
		local iconH = ICON_SIZE.Y.Offset
		local pad = 6
		local maxX = math.max(pad, viewport.X - iconW - pad)
		local maxY = math.max(pad, viewport.Y - iconH - pad)
		return UDim2.fromOffset(math.clamp(pos.X.Offset, pad, maxX), math.clamp(pos.Y.Offset, pad, maxY))
	end

	local function getCurrentOffsetPos(): UDim2
		local cam = workspace.CurrentCamera
		local viewport = cam and cam.ViewportSize or Vector2.new(1280, 720)
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
		if not dragging or input ~= activeInput then
			return
		end
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

local NavListFrame = Instance.new("ScrollingFrame")
NavListFrame.Size = UDim2.new(1, -8, 1, -8)
NavListFrame.Position = UDim2.new(0, 4, 0, 4)
NavListFrame.BackgroundTransparency = 1
NavListFrame.BorderSizePixel = 0
NavListFrame.ScrollBarThickness = 2
NavListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
NavListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
NavListFrame.Parent = Sidebar

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 3)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavListFrame

local tabPages: {[string]: Frame} = {}
local tabButtons: {[string]: TextButton} = {}

local function createNavButton(name: string, label: string, order: number)
	local btn = Instance.new("TextButton")
	btn.Name = "Nav_" .. name
	btn.Size = UDim2.new(1, 0, 0, 25)
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
-- REUSABLE GAME CARD BUILDER
-- ==========================================
local function styleStatusBadge(badge: TextLabel, status: GameStatus, isError: boolean?)
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

local function createGameCard(parent: Instance, order: number, data: GameResultCardData, getCookieFn: () -> string): Frame
	local card = Instance.new("Frame")
	card.Name = "GameCard_" .. tostring(order)
	card.Size = UDim2.new(1, -2, 0, 68)
	card.BackgroundColor3 = data.isError and Color3.fromRGB(34, 18, 24) or Color3.fromRGB(21, 20, 33)
	card.BorderSizePixel = 0
	card.LayoutOrder = order
	card.Parent = parent
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
	gameNameLabel.Size = UDim2.new(1, -166, 0, 18)
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
		local copyUnivBtn = Instance.new("TextButton")
		copyUnivBtn.Size = UDim2.fromOffset(52, 18)
		copyUnivBtn.Position = UDim2.new(1, -102, 0, 7)
		copyUnivBtn.BackgroundColor3 = Color3.fromRGB(42, 38, 72)
		copyUnivBtn.Text = "📋 Copy ID"
		copyUnivBtn.TextColor3 = Color3.fromRGB(220, 215, 255)
		copyUnivBtn.TextSize = 8
		copyUnivBtn.Font = Enum.Font.GothamBold
		copyUnivBtn.Parent = card
		Instance.new("UICorner", copyUnivBtn).CornerRadius = UDim.new(0, 5)

		copyUnivBtn.MouseButton1Click:Connect(function()
			local okCopy = setClipboardText(data.universeId)
			pushConsole("INFO", string.format("Universe ID %s %s", data.universeId, okCopy and "disalin ke clipboard" or "ditampilkan via notifikasi"))
			notify("Universe ID", (okCopy and "Disalin: " or "ID: ") .. data.universeId)
			copyUnivBtn.Text = "✓ Copied"
			task.delay(1.2, function()
				if copyUnivBtn and copyUnivBtn.Parent then
					copyUnivBtn.Text = "📋 Copy ID"
				end
			end)
		end)

		local refreshBtn = Instance.new("TextButton")
		refreshBtn.Size = UDim2.fromOffset(44, 18)
		refreshBtn.Position = UDim2.new(1, -46, 0, 7)
		refreshBtn.BackgroundColor3 = Color3.fromRGB(36, 34, 56)
		refreshBtn.Text = "↻ Cek"
		refreshBtn.TextColor3 = Color3.fromRGB(215, 212, 245)
		refreshBtn.TextSize = 8
		refreshBtn.Font = Enum.Font.GothamBold
		refreshBtn.Parent = card
		Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 5)

		local isRefreshing = false
		refreshBtn.MouseButton1Click:Connect(function()
			if isRefreshing then
				return
			end
			isRefreshing = true
			refreshBtn.Text = "..."
			task.spawn(function()
				local latest = fetchRealtimeGameData(data.universeId, getCookieFn(), data.rootPlaceId)
				gameIconImg.Image = latest.iconImage
				gameNameLabel.Text = latest.gameName
				metaLabel.Text = latest.metaInfo
				styleStatusBadge(statusBadge, latest.status, false)
				refreshBtn.Text = "↻ Cek"
				isRefreshing = false
			end)
		end)
	end

	return card
end

-- ==========================================
-- HALAMAN 1: PERMISSION PLACE
-- ==========================================
local PermPlacePage = Instance.new("Frame")
PermPlacePage.Size = UDim2.fromScale(1, 1)
PermPlacePage.BackgroundTransparency = 1
PermPlacePage.Visible = true
PermPlacePage.Parent = ContentArea
tabPages["PermissionPlace"] = PermPlacePage

local PermScroll = Instance.new("ScrollingFrame")
PermScroll.Name = "PermissionPlaceScroll"
PermScroll.Size = UDim2.new(1, -16, 1, -8)
PermScroll.Position = UDim2.new(0, 8, 0, 4)
PermScroll.BackgroundTransparency = 1
PermScroll.BorderSizePixel = 0
PermScroll.ScrollBarThickness = 2
PermScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PermScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PermScroll.Parent = PermPlacePage

local PermLayout = Instance.new("UIListLayout")
PermLayout.Padding = UDim.new(0, 5)
PermLayout.SortOrder = Enum.SortOrder.LayoutOrder
PermLayout.Parent = PermScroll

local PermHeaderLbl = Instance.new("TextLabel")
PermHeaderLbl.Size = UDim2.new(1, -4, 0, 15)
PermHeaderLbl.BackgroundTransparency = 1
PermHeaderLbl.Text = "Permission Place"
PermHeaderLbl.TextColor3 = Color3.fromRGB(245, 245, 255)
PermHeaderLbl.TextSize = 12
PermHeaderLbl.Font = Enum.Font.GothamBold
PermHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
PermHeaderLbl.LayoutOrder = 1
PermHeaderLbl.Parent = PermScroll

local PermTopRow = Instance.new("Frame")
PermTopRow.Size = UDim2.new(1, -4, 0, 24)
PermTopRow.BackgroundTransparency = 1
PermTopRow.LayoutOrder = 2
PermTopRow.Parent = PermScroll

local PermUniverseBox = Instance.new("TextBox")
PermUniverseBox.Size = UDim2.new(1, -138, 1, 0)
PermUniverseBox.Position = UDim2.new(0, 0, 0, 0)
PermUniverseBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PermUniverseBox.Text = CONFIG.DefaultUniverseId
PermUniverseBox.PlaceholderText = "Universe ID..."
PermUniverseBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PermUniverseBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PermUniverseBox.TextSize = 10
PermUniverseBox.Font = Enum.Font.Gotham
PermUniverseBox.ClearTextOnFocus = false
PermUniverseBox.Parent = PermTopRow
Instance.new("UICorner", PermUniverseBox).CornerRadius = UDim.new(0, 6)

local PermCheckBtn = Instance.new("TextButton")
PermCheckBtn.Size = UDim2.fromOffset(64, 24)
PermCheckBtn.Position = UDim2.new(1, -132, 0, 0)
PermCheckBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 52)
PermCheckBtn.Text = "↻ Cek"
PermCheckBtn.TextColor3 = Color3.fromRGB(215, 212, 248)
PermCheckBtn.TextSize = 9
PermCheckBtn.Font = Enum.Font.GothamBold
PermCheckBtn.Parent = PermTopRow
Instance.new("UICorner", PermCheckBtn).CornerRadius = UDim.new(0, 6)

local PermAccessSwitch = createModernToggleSwitch(PermTopRow, false, nil)
PermAccessSwitch.Button.Size = UDim2.fromOffset(62, 24)
PermAccessSwitch.Button.Position = UDim2.new(1, -62, 0, 0)

local selectedGenreApiValue = "All"

local PermMetaRow = Instance.new("Frame")
PermMetaRow.Size = UDim2.new(1, -4, 0, 23)
PermMetaRow.BackgroundTransparency = 1
PermMetaRow.LayoutOrder = 3
PermMetaRow.Parent = PermScroll

local PermNameBox = Instance.new("TextBox")
PermNameBox.Size = UDim2.new(0.32, -3, 1, 0)
PermNameBox.Position = UDim2.new(0, 0, 0, 0)
PermNameBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PermNameBox.Text = ""
PermNameBox.PlaceholderText = "Name game..."
PermNameBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PermNameBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PermNameBox.TextSize = 9
PermNameBox.Font = Enum.Font.Gotham
PermNameBox.ClearTextOnFocus = false
PermNameBox.Parent = PermMetaRow
Instance.new("UICorner", PermNameBox).CornerRadius = UDim.new(0, 6)

local PermDescBox = Instance.new("TextBox")
PermDescBox.Size = UDim2.new(0.38, -3, 1, 0)
PermDescBox.Position = UDim2.new(0.32, 2, 0, 0)
PermDescBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
PermDescBox.Text = ""
PermDescBox.PlaceholderText = "Description..."
PermDescBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
PermDescBox.TextColor3 = Color3.fromRGB(235, 235, 250)
PermDescBox.TextSize = 9
PermDescBox.Font = Enum.Font.Gotham
PermDescBox.ClearTextOnFocus = false
PermDescBox.Parent = PermMetaRow
Instance.new("UICorner", PermDescBox).CornerRadius = UDim.new(0, 6)

local PermGenreDropdownBtn = Instance.new("TextButton")
PermGenreDropdownBtn.Size = UDim2.new(0.30, 0, 1, 0)
PermGenreDropdownBtn.Position = UDim2.new(0.70, 0, 0, 0)
PermGenreDropdownBtn.BackgroundColor3 = Color3.fromRGB(28, 26, 46)
PermGenreDropdownBtn.Text = "Genre: All ▾"
PermGenreDropdownBtn.TextColor3 = Color3.fromRGB(230, 226, 255)
PermGenreDropdownBtn.TextSize = 8
PermGenreDropdownBtn.Font = Enum.Font.GothamBold
PermGenreDropdownBtn.TextTruncate = Enum.TextTruncate.AtEnd
PermGenreDropdownBtn.Parent = PermMetaRow
Instance.new("UICorner", PermGenreDropdownBtn).CornerRadius = UDim.new(0, 6)
local GenreBtnStroke = Instance.new("UIStroke", PermGenreDropdownBtn)
GenreBtnStroke.Color = Color3.fromRGB(84, 76, 134)
GenreBtnStroke.Thickness = 1

local GenreDropdownPanel = Instance.new("ScrollingFrame")
GenreDropdownPanel.Name = "GenrePickerList"
GenreDropdownPanel.Size = UDim2.new(1, -4, 0, 96)
GenreDropdownPanel.BackgroundColor3 = Color3.fromRGB(15, 14, 25)
GenreDropdownPanel.BorderSizePixel = 0
GenreDropdownPanel.ScrollBarThickness = 3
GenreDropdownPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
GenreDropdownPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y
GenreDropdownPanel.Visible = false
GenreDropdownPanel.LayoutOrder = 4
GenreDropdownPanel.Parent = PermScroll
Instance.new("UICorner", GenreDropdownPanel).CornerRadius = UDim.new(0, 7)
local GenreDropStroke = Instance.new("UIStroke", GenreDropdownPanel)
GenreDropStroke.Color = Color3.fromRGB(108, 86, 245)
GenreDropStroke.Thickness = 1

local GenreGrid = Instance.new("UIGridLayout")
GenreGrid.CellSize = UDim2.new(0.5, -6, 0, 20)
GenreGrid.CellPadding = UDim2.fromOffset(4, 4)
GenreGrid.SortOrder = Enum.SortOrder.LayoutOrder
GenreGrid.Parent = GenreDropdownPanel

local GenreGridPad = Instance.new("UIPadding")
GenreGridPad.PaddingTop = UDim.new(0, 4)
GenreGridPad.PaddingBottom = UDim.new(0, 4)
GenreGridPad.PaddingLeft = UDim.new(0, 4)
GenreGridPad.PaddingRight = UDim.new(0, 4)
GenreGridPad.Parent = GenreDropdownPanel

for idx, gItem in ipairs(ROBLOX_GENRES) do
	local optBtn = Instance.new("TextButton")
	optBtn.Size = UDim2.fromOffset(100, 20)
	optBtn.BackgroundColor3 = Color3.fromRGB(26, 24, 42)
	optBtn.Text = "  " .. gItem.label
	optBtn.TextColor3 = Color3.fromRGB(225, 222, 250)
	optBtn.TextSize = 8
	optBtn.Font = Enum.Font.GothamMedium
	optBtn.TextXAlignment = Enum.TextXAlignment.Left
	optBtn.TextTruncate = Enum.TextTruncate.AtEnd
	optBtn.LayoutOrder = idx
	optBtn.Parent = GenreDropdownPanel
	Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 5)

	optBtn.MouseButton1Click:Connect(function()
		selectedGenreApiValue = gItem.apiValue
		PermGenreDropdownBtn.Text = "Genre: " .. gItem.apiValue .. " ▾"
		GenreDropdownPanel.Visible = false
	end)
end

PermGenreDropdownBtn.MouseButton1Click:Connect(function()
	GenreDropdownPanel.Visible = not GenreDropdownPanel.Visible
end)

local PermRuleBanner = Instance.new("TextLabel")
PermRuleBanner.Size = UDim2.new(1, -4, 0, 14)
PermRuleBanner.BackgroundTransparency = 1
PermRuleBanner.Text = "Rating: Tipe=Game • IARC=Semua No • Roblox=Social Hangout(Yes) -> Lanjutan(No) -> Sisanya(No)"
PermRuleBanner.TextColor3 = Color3.fromRGB(145, 140, 178)
PermRuleBanner.TextSize = 8
PermRuleBanner.Font = Enum.Font.GothamMedium
PermRuleBanner.TextXAlignment = Enum.TextXAlignment.Left
PermRuleBanner.TextTruncate = Enum.TextTruncate.AtEnd
PermRuleBanner.LayoutOrder = 5
PermRuleBanner.Parent = PermScroll

local PermActionRow = Instance.new("Frame")
PermActionRow.Size = UDim2.new(1, -4, 0, 24)
PermActionRow.BackgroundTransparency = 1
PermActionRow.LayoutOrder = 6
PermActionRow.Parent = PermScroll

local PermStep1Btn = Instance.new("TextButton")
PermStep1Btn.Size = UDim2.new(0.33, -3, 1, 0)
PermStep1Btn.Position = UDim2.new(0, 0, 0, 0)
PermStep1Btn.BackgroundColor3 = Color3.fromRGB(45, 42, 74)
PermStep1Btn.Text = "1. Detail Place"
PermStep1Btn.TextColor3 = Color3.fromRGB(235, 232, 255)
PermStep1Btn.TextSize = 9
PermStep1Btn.Font = Enum.Font.GothamBold
PermStep1Btn.Parent = PermActionRow
Instance.new("UICorner", PermStep1Btn).CornerRadius = UDim.new(0, 6)

local PermStep2Btn = Instance.new("TextButton")
PermStep2Btn.Size = UDim2.new(0.34, -4, 1, 0)
PermStep2Btn.Position = UDim2.new(0.33, 2, 0, 0)
PermStep2Btn.BackgroundColor3 = Color3.fromRGB(45, 42, 74)
PermStep2Btn.Text = "2. Form Rating"
PermStep2Btn.TextColor3 = Color3.fromRGB(235, 232, 255)
PermStep2Btn.TextSize = 9
PermStep2Btn.Font = Enum.Font.GothamBold
PermStep2Btn.Parent = PermActionRow
Instance.new("UICorner", PermStep2Btn).CornerRadius = UDim.new(0, 6)

local PermApplyBtn = Instance.new("TextButton")
PermApplyBtn.Size = UDim2.new(0.33, 0, 1, 0)
PermApplyBtn.Position = UDim2.new(0.67, 0, 0, 0)
PermApplyBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
PermApplyBtn.Text = "⚡ Terapkan"
PermApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PermApplyBtn.TextSize = 9
PermApplyBtn.Font = Enum.Font.GothamBold
PermApplyBtn.Parent = PermActionRow
Instance.new("UICorner", PermApplyBtn).CornerRadius = UDim.new(0, 6)

local PermStatusLbl = Instance.new("TextLabel")
PermStatusLbl.Size = UDim2.new(1, -4, 0, 14)
PermStatusLbl.BackgroundTransparency = 1
PermStatusLbl.Text = "Pilih Genre di atas, lalu tekan '1. Detail Place' atau '2. Form Rating'."
PermStatusLbl.TextColor3 = Color3.fromRGB(165, 162, 194)
PermStatusLbl.TextSize = 9
PermStatusLbl.Font = Enum.Font.GothamMedium
PermStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
PermStatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
PermStatusLbl.LayoutOrder = 7
PermStatusLbl.Parent = PermScroll

local PermOutputBox = Instance.new("Frame")
PermOutputBox.Size = UDim2.new(1, -4, 0, 0)
PermOutputBox.AutomaticSize = Enum.AutomaticSize.Y
PermOutputBox.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
PermOutputBox.BorderSizePixel = 0
PermOutputBox.LayoutOrder = 8
PermOutputBox.Parent = PermScroll
Instance.new("UICorner", PermOutputBox).CornerRadius = UDim.new(0, 7)
local PermOutStroke = Instance.new("UIStroke", PermOutputBox)
PermOutStroke.Color = Color3.fromRGB(58, 53, 94)
PermOutStroke.Thickness = 1

local PermOutPad = Instance.new("UIPadding", PermOutputBox)
PermOutPad.PaddingTop = UDim.new(0, 5)
PermOutPad.PaddingBottom = UDim.new(0, 5)
PermOutPad.PaddingLeft = UDim.new(0, 7)
PermOutPad.PaddingRight = UDim.new(0, 7)

local PermOutputText = Instance.new("TextLabel")
PermOutputText.Size = UDim2.new(1, 0, 0, 0)
PermOutputText.AutomaticSize = Enum.AutomaticSize.Y
PermOutputText.BackgroundTransparency = 1
PermOutputText.Text = "Belum ada permintaan dikirim. Tekan '1. Detail Place' atau '2. Form Rating'."
PermOutputText.TextColor3 = Color3.fromRGB(185, 182, 214)
PermOutputText.TextSize = 8
PermOutputText.Font = Enum.Font.Code
PermOutputText.TextWrapped = true
PermOutputText.TextXAlignment = Enum.TextXAlignment.Left
PermOutputText.Parent = PermOutputBox

local PermCardHost = Instance.new("Frame")
PermCardHost.Size = UDim2.new(1, -4, 0, 72)
PermCardHost.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
PermCardHost.BorderSizePixel = 0
PermCardHost.LayoutOrder = 9
PermCardHost.Parent = PermScroll
Instance.new("UICorner", PermCardHost).CornerRadius = UDim.new(0, 8)
local PermHostStroke = Instance.new("UIStroke", PermCardHost)
PermHostStroke.Color = Color3.fromRGB(52, 48, 82)
PermHostStroke.Thickness = 1

local function renderPermissionPreviewCard(cardData: GameResultCardData)
	for _, ch in ipairs(PermCardHost:GetChildren()) do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	local c = createGameCard(PermCardHost, 1, cardData, function()
		return CONFIG.Cookie
	end)
	c.Size = UDim2.new(1, -4, 1, -4)
	c.Position = UDim2.fromOffset(2, 2)
end

renderPermissionPreviewCard({
	universeId = CONFIG.DefaultUniverseId,
	rootPlaceId = nil,
	iconImage = "rbxthumb://type=GameIcon&id=" .. CONFIG.DefaultUniverseId .. "&w=150&h=150",
	gameName = "Universe #" .. CONFIG.DefaultUniverseId,
	status = "tidak diketahui",
	metaInfo = "Universe: " .. CONFIG.DefaultUniverseId .. " • Siap cek status",
	isError = false,
})

-- ==========================================
-- HALAMAN 2: SETTING (COOKIE)
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
-- HALAMAN 3: CONSOLE OUTPUT SERVER / PERMINTAAN
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
		if ConsoleScroll and ConsoleScroll.Parent then
			ConsoleScroll.CanvasPosition = Vector2.new(0, math.max(0, ConsoleScroll.AbsoluteCanvasSize.Y))
		end
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

createNavButton("PermissionPlace", "🔐  Permission Place", 1).MouseButton1Click:Connect(function()
	switchTab("PermissionPlace")
end)
createNavButton("Setting", "⚙  Setting", 2).MouseButton1Click:Connect(function()
	switchTab("Setting")
end)
createNavButton("Console", "🖥  Console", 3).MouseButton1Click:Connect(function()
	switchTab("Console")
end)
switchTab("PermissionPlace")

pushConsole("INFO", "Plugin Studio Lite siap (Permission Place, Setting & Console aktif).")

-- ==========================================
-- LOGIKA PERMISSION PLACE
-- ==========================================
local isRunningPermPlace = false
local cachedPermCsrf = ""

local function validatePermUniverseAndCookie(requireCookie: boolean): (string?, string?)
	local cookieVal = syncCookieFromInput()
	if requireCookie and cookieVal == "" then
		PermStatusLbl.TextColor3 = Color3.fromRGB(255, 155, 165)
		PermStatusLbl.Text = "Cookie .ROBLOSECURITY kosong. Isi di tab Setting."
		pushConsole("ERR", "[Permission Place] Gagal: Cookie kosong.")
		notify("Permission Place", "Cookie belum diisi.")
		return nil, nil
	end
	local univId = trim(PermUniverseBox.Text):match("%d+") or ""
	if univId == "" then
		PermStatusLbl.TextColor3 = Color3.fromRGB(255, 155, 165)
		PermStatusLbl.Text = "Masukkan Universe ID yang valid."
		pushConsole("WARN", "[Permission Place] Universe ID tidak valid.")
		return nil, nil
	end
	return univId, cookieVal
end

PermCheckBtn.MouseButton1Click:Connect(function()
	if isRunningPermPlace then
		return
	end
	local univId, cookieVal = validatePermUniverseAndCookie(false)
	if not univId or not cookieVal then
		return
	end

	isRunningPermPlace = true
	PermCheckBtn.Text = "..."
	PermStatusLbl.TextColor3 = Color3.fromRGB(175, 205, 255)
	PermStatusLbl.Text = "Memeriksa status place..."

	task.spawn(function()
		local card = fetchRealtimeGameData(univId, cookieVal, nil)
		renderPermissionPreviewCard(card)
		if card.status == "publik" then
			PermAccessSwitch.SetState(true, true)
		elseif card.status == "private" then
			PermAccessSwitch.SetState(false, true)
		end
		PermStatusLbl.TextColor3 = Color3.fromRGB(145, 255, 190)
		PermStatusLbl.Text = "Status terkini: " .. card.gameName .. " (" .. card.status .. ")"
		PermOutputText.TextColor3 = Color3.fromRGB(185, 210, 255)
		PermOutputText.Text = string.format("[Cek Status] Game: %s | Status: %s | %s", card.gameName, card.status, card.metaInfo)
		pushConsole("OK", string.format("[Permission Place] Cek status #%s -> %s (%s)", univId, card.gameName, card.status))
		PermCheckBtn.Text = "↻ Cek"
		isRunningPermPlace = false
	end)
end)

PermStep1Btn.MouseButton1Click:Connect(function()
	if isRunningPermPlace then
		return
	end
	local univId, cookieVal = validatePermUniverseAndCookie(true)
	if not univId or not cookieVal then
		return
	end

	GenreDropdownPanel.Visible = false
	isRunningPermPlace = true
	PermStep1Btn.Text = "⏳..."
	PermStatusLbl.TextColor3 = Color3.fromRGB(175, 205, 255)
	PermStatusLbl.Text = "Mengirim Detail Place (Name, Description, Genre)..."

	task.spawn(function()
		local okDet, msgDet, detSummary, nextCsrf = updateUniverseDetailStep1(
			univId,
			cookieVal,
			PermNameBox.Text,
			PermDescBox.Text,
			selectedGenreApiValue,
			cachedPermCsrf
		)
		cachedPermCsrf = nextCsrf

		local latestCard = fetchRealtimeGameData(univId, cookieVal, nil)
		renderPermissionPreviewCard(latestCard)

		PermStatusLbl.TextColor3 = okDet and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
		PermStatusLbl.Text = msgDet
		PermOutputText.TextColor3 = okDet and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
		PermOutputText.Text = string.format(
			"[Hasil Step 1 - Detail Place]\n• Name: %s\n• Genre: %s\n• Description: %s\n• Status: %s",
			tostring(detSummary.name),
			tostring(detSummary.genre),
			tostring(detSummary.description),
			okDet and "BERHASIL DISIMPAN" or msgDet
		)

		notify("Detail Place", okDet and "Detail place tersimpan." or "Gagal menyimpan detail place.")
		PermStep1Btn.Text = "1. Detail Place"
		isRunningPermPlace = false
	end)
end)

PermStep2Btn.MouseButton1Click:Connect(function()
	if isRunningPermPlace then
		return
	end
	local univId, cookieVal = validatePermUniverseAndCookie(true)
	if not univId or not cookieVal then
		return
	end

	GenreDropdownPanel.Visible = false
	isRunningPermPlace = true
	PermStep2Btn.Text = "⏳..."
	PermStatusLbl.TextColor3 = Color3.fromRGB(175, 205, 255)
	PermStatusLbl.Text = "Mengirim Form Rating (Game, IARC=No, SocialHangout=Yes->No)..."

	task.spawn(function()
		local okQ, msgQ, auditList, nextCsrf = submitContentQuestionnaireStep2(
			univId,
			cookieVal,
			cachedPermCsrf
		)
		cachedPermCsrf = nextCsrf

		local previewLines = {
			okQ and "[Hasil Step 2 - Form Rating TERKIRIM]" or "[Hasil Step 2 - Form Rating GAGAL]",
			"• Tipe Aplikasi: Game | Bagian IARC: Semua No",
			"• Bagian Roblox: Social Hangout Awal = Yes, Lanjutan = No, Sisanya = No",
		}
		for i = 1, math.min(6, #auditList) do
			local it = auditList[i]
			table.insert(previewLines, string.format("  - [%s] %s -> %s", it.section, it.title:sub(1, 34), it.chosenLabel))
		end
		if #auditList > 6 then
			table.insert(previewLines, string.format("  ... (+%d item lainnya di Console)", #auditList - 6))
		end
		table.insert(previewLines, "Status Server: " .. msgQ)

		PermStatusLbl.TextColor3 = okQ and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
		PermStatusLbl.Text = msgQ
		PermOutputText.TextColor3 = okQ and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
		PermOutputText.Text = table.concat(previewLines, "\n")

		notify("Form Rating", okQ and "Form rating terkirim." or "Cek hasil di layar / Console.")
		PermStep2Btn.Text = "2. Form Rating"
		isRunningPermPlace = false
	end)
end)

PermApplyBtn.MouseButton1Click:Connect(function()
	if isRunningPermPlace then
		return
	end
	local univId, cookieVal = validatePermUniverseAndCookie(true)
	if not univId or not cookieVal then
		return
	end

	GenreDropdownPanel.Visible = false
	local targetPublic = PermAccessSwitch.GetState()

	isRunningPermPlace = true
	PermApplyBtn.Text = "⏳..."
	PermStatusLbl.TextColor3 = Color3.fromRGB(175, 205, 255)
	PermStatusLbl.Text = "Menjalankan alur lengkap Permission Place..."

	task.spawn(function()
		local summaryOut: {string} = {}

		if targetPublic then
			local okDet, msgDet, _, csrfAfterDet = updateUniverseDetailStep1(
				univId,
				cookieVal,
				PermNameBox.Text,
				PermDescBox.Text,
				selectedGenreApiValue,
				cachedPermCsrf
			)
			cachedPermCsrf = csrfAfterDet
			table.insert(summaryOut, "1. Detail Place: " .. (okDet and "OK" or msgDet))

			local okQ, msgQ, _, csrfAfterQ = submitContentQuestionnaireStep2(
				univId,
				cookieVal,
				cachedPermCsrf
			)
			cachedPermCsrf = csrfAfterQ
			table.insert(summaryOut, "2. Form Rating: " .. (okQ and "OK" or msgQ))
		end

		local okAct, msgAct, csrfAfterAct = applyPlacePermissionAction(univId, cookieVal, targetPublic, cachedPermCsrf)
		cachedPermCsrf = csrfAfterAct
		table.insert(summaryOut, "3. Status Akses: " .. msgAct)

		local latestCard = fetchRealtimeGameData(univId, cookieVal, nil)
		renderPermissionPreviewCard(latestCard)

		PermStatusLbl.TextColor3 = okAct and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
		PermStatusLbl.Text = msgAct
		PermOutputText.TextColor3 = okAct and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
		PermOutputText.Text = table.concat(summaryOut, "\n")

		notify("Permission Place", okAct and ("Status: " .. latestCard.status) or "Gagal memperbarui akses place.")
		PermApplyBtn.Text = "⚡ Terapkan"
		isRunningPermPlace = false
	end)
end)
