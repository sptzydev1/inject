--!strict
-- Plugin Studio Lite (Delta Executor Edition - Create Place, My Places from Profile, Upload Asset ID, Voice Chat, 3rd Party Sales, Setting & Console) by Ikyy
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
	ApiKey = "",
	IsMinimized = false,
	ActiveTab = "CreatePlace",
	DefaultUniverseId = "10516113765",
	UserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36",
}

local MEMORY_FILES: {[string]: string} = {}
local CONSOLE_LINES: {string} = {}
local LAST_KNOWN_THIRD_PARTY: {[string]: boolean} = {}

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
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Copied Value",
			Text = text,
			Duration = 4,
		})
	end)
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
		CONFIG.WorkspaceRoot .. "/Assets",
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

local savedApiKey = loadTextFile("apikey.txt")
if savedApiKey and trim(savedApiKey) ~= "" then
	CONFIG.ApiKey = trim(savedApiKey)
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
-- API CEK PLACE SAYA (DARI HALAMAN PROFILE USER)
-- ==========================================
local function getAuthenticatedUserFromCookie(cookieVal: string): (number?, string?)
	local hdrs: {[string]: string} = {
		["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
	}
	local res, ok = apiRequest({
		Url = "https://users.roblox.com/v1/users/authenticated",
		Method = "GET",
		Headers = hdrs,
		Retries = 1,
	})
	if ok and res and res.Body then
		local okDec, decoded = pcall(function()
			return HttpService:JSONDecode(tostring(res.Body))
		end)
		if okDec and type(decoded) == "table" and decoded.id ~= nil then
			local uidNum = tonumber(tostring(decoded.id):match("%d+"))
			local uname = type(decoded.name) == "string" and decoded.name or nil
			return uidNum, uname
		end
	end
	return nil, nil
end

local function placeIdToUniverseId(placeId: string, hdrs: {[string]: string}): string?
	local res, ok = apiRequest({
		Url = "https://apis.roblox.com/universes/v1/places/" .. placeId .. "/universe",
		Method = "GET",
		Headers = hdrs,
		Retries = 1,
	})
	if ok and res and res.Body then
		local okDec, decoded = pcall(function()
			return HttpService:JSONDecode(tostring(res.Body))
		end)
		if okDec and type(decoded) == "table" and decoded.universeId ~= nil then
			return tostring(decoded.universeId):match("%d+")
		end
	end
	return nil
end

local function fetchMyPlacesList(cookieVal: string): (boolean, {GameResultCardData}, string)
	local hdrs: {[string]: string} = {
		["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
	}

	local uid, uname = getAuthenticatedUserFromCookie(cookieVal)
	if not uid then
		return false, {}, "Cookie tidak valid atau sesi expired"
	end

	type RawPlaceEntry = {
		univId: string,
		rootPlaceId: string?,
		name: string?,
		status: "publik" | "private" | "tidak diketahui",
	}

	local rawItems: {RawPlaceEntry} = {}
	local seenUniv: {[string]: boolean} = {}

	local function addItem(univId: string?, rootPlaceId: string?, name: string?, status: "publik" | "private" | "tidak diketahui")
		local cleanU = univId and trim(univId):match("%d+") or ""
		if cleanU == "" then return end
		if seenUniv[cleanU] then
			for _, existing in ipairs(rawItems) do
				if existing.univId == cleanU then
					if (not existing.rootPlaceId or existing.rootPlaceId == "") and rootPlaceId and rootPlaceId ~= "" then
						existing.rootPlaceId = rootPlaceId
					end
					if (not existing.name or existing.name == "") and name and name ~= "" then
						existing.name = name
					end
					if existing.status == "tidak diketahui" and status ~= "tidak diketahui" then
						existing.status = status
					end
					break
				end
			end
			return
		end
		seenUniv[cleanU] = true
		table.insert(rawItems, {
			univId = cleanU,
			rootPlaceId = rootPlaceId,
			name = name,
			status = status,
		})
	end

	local profileApiUrls = {
		string.format("https://games.roblox.com/v2/users/%d/games?accessFilter=All&limit=50&sortOrder=Desc", uid),
		string.format("https://games.roblox.com/v2/users/%d/games?accessFilter=2&limit=50&sortOrder=Desc", uid),
		string.format("https://games.roblox.com/v2/users/%d/games?accessFilter=4&limit=50&sortOrder=Desc", uid),
	}

	for _, pApiUrl in ipairs(profileApiUrls) do
		local gRes, gOk = apiRequest({
			Url = pApiUrl,
			Method = "GET",
			Headers = {
				["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
				["Referer"] = string.format("https://www.roblox.com/users/%d/profile", uid),
				["Origin"] = "https://www.roblox.com",
			},
			Retries = 1,
		})
		if gOk and gRes and gRes.Body then
			local okG, gDec = pcall(function()
				return HttpService:JSONDecode(tostring(gRes.Body))
			end)
			if okG and type(gDec) == "table" and type(gDec.data) == "table" then
				for _, entry in ipairs(gDec.data) do
					if type(entry) == "table" then
						local univStr = entry.id ~= nil and tostring(entry.id):match("%d+") or nil
						local rpStr = (type(entry.rootPlace) == "table" and entry.rootPlace.id ~= nil)
							and tostring(entry.rootPlace.id):match("%d+")
							or (entry.rootPlaceId ~= nil and tostring(entry.rootPlaceId):match("%d+") or nil)
						local gName = type(entry.name) == "string" and trim(entry.name) or nil
						local st: "publik" | "private" | "tidak diketahui" = "tidak diketahui"
						if pApiUrl:find("accessFilter=2") then
							st = "publik"
						elseif pApiUrl:find("accessFilter=4") then
							st = "private"
						end
						addItem(univStr, rpStr, gName, st)
					end
				end
			end
		end
	end

	local profilePageUrl = string.format("https://www.roblox.com/users/%d/profile", uid)
	local htmlRes, htmlOk = apiRequest({
		Url = profilePageUrl,
		Method = "GET",
		Headers = {
			["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
			["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
			["Referer"] = "https://www.roblox.com/home",
		},
		Retries = 1,
	})

	if htmlOk and htmlRes and htmlRes.Body then
		local htmlBody = tostring(htmlRes.Body)
		local discoveredPlaceIds: {string} = {}
		local seenPlace: {[string]: boolean} = {}

		local function collectPlaceId(pid: string?)
			local cleanP = pid and trim(pid):match("%d+") or ""
			if cleanP == "" or seenPlace[cleanP] then return end
			seenPlace[cleanP] = true
			table.insert(discoveredPlaceIds, cleanP)
		end

		for pid in htmlBody:gmatch("/games/(%d+)/") do
			collectPlaceId(pid)
		end
		for pid in htmlBody:gmatch('"placeId"%s*:%s*(%d+)') do
			collectPlaceId(pid)
		end
		for pid in htmlBody:gmatch('data%-place%-id=["\'](%d+)["\']') do
			collectPlaceId(pid)
		end
		for univStr in htmlBody:gmatch('"universeId"%s*:%s*(%d+)') do
			addItem(univStr, nil, nil, "tidak diketahui")
		end

		for _, pid in ipairs(discoveredPlaceIds) do
			local alreadyHasPlace = false
			for _, existing in ipairs(rawItems) do
				if existing.rootPlaceId == pid then
					alreadyHasPlace = true
					break
				end
			end
			if not alreadyHasPlace then
				local resolvedUniv = placeIdToUniverseId(pid, hdrs)
				if resolvedUniv then
					addItem(resolvedUniv, pid, nil, "tidak diketahui")
				end
			end
		end
	end

	for _, it in ipairs(rawItems) do
		local dRes, dOk = apiRequest({
			Url = "https://develop.roblox.com/v1/universes/" .. it.univId,
			Method = "GET",
			Headers = hdrs,
			Retries = 1,
		})
		if dOk and dRes and dRes.Body then
			local okD, dDec = pcall(function()
				return HttpService:JSONDecode(tostring(dRes.Body))
			end)
			if okD and type(dDec) == "table" then
				if type(dDec.name) == "string" and trim(dDec.name) ~= "" then
					it.name = trim(dDec.name)
				end
				if not it.rootPlaceId and dDec.rootPlaceId ~= nil and tostring(dDec.rootPlaceId):match("%d+") then
					it.rootPlaceId = tostring(dDec.rootPlaceId):match("%d+")
				end
				if type(dDec.isActive) == "boolean" then
					it.status = dDec.isActive and "publik" or "private"
				elseif type(dDec.privacyType) == "string" then
					local pLow = dDec.privacyType:lower()
					if pLow:find("public") or pLow:find("open") then
						it.status = "publik"
					elseif pLow:find("private") or pLow:find("closed") then
						it.status = "private"
					end
				end
			end
		end
	end

	local gamesInfoMap: {[string]: {name: string?, rootPlaceId: string?}} = {}
	if #rawItems > 0 then
		local idsArr: {string} = {}
		for _, it in ipairs(rawItems) do
			table.insert(idsArr, it.univId)
		end
		local gRes, gOk = apiRequest({
			Url = "https://games.roblox.com/v1/games?universeIds=" .. table.concat(idsArr, ","),
			Method = "GET",
			Headers = hdrs,
			Retries = 1,
		})
		if gOk and gRes and gRes.Body then
			local okG, gDec = pcall(function()
				return HttpService:JSONDecode(tostring(gRes.Body))
			end)
			if okG and type(gDec) == "table" and type(gDec.data) == "table" then
				for _, gEntry in ipairs(gDec.data) do
					if type(gEntry) == "table" and gEntry.id ~= nil then
						local gid = tostring(gEntry.id):match("%d+") or ""
						if gid ~= "" then
							gamesInfoMap[gid] = {
								name = type(gEntry.name) == "string" and trim(gEntry.name) or nil,
								rootPlaceId = gEntry.rootPlaceId ~= nil and tostring(gEntry.rootPlaceId):match("%d+") or nil,
							}
						end
					end
				end
			end
		end
	end

	local iconMap: {[string]: string} = {}
	if #rawItems > 0 then
		local idsArr: {string} = {}
		for _, it in ipairs(rawItems) do
			table.insert(idsArr, it.univId)
		end
		local tRes, tOk = apiRequest({
			Url = "https://thumbnails.roblox.com/v1/games/icons?universeIds=" .. table.concat(idsArr, ",") .. "&size=150x150&format=Png&isCircular=false",
			Method = "GET",
			Headers = hdrs,
			Retries = 1,
		})
		if tOk and tRes and tRes.Body then
			local okT, tDec = pcall(function()
				return HttpService:JSONDecode(tostring(tRes.Body))
			end)
			if okT and type(tDec) == "table" and type(tDec.data) == "table" then
				for _, tEntry in ipairs(tDec.data) do
					if type(tEntry) == "table" and tEntry.targetId ~= nil then
						local tid = tostring(tEntry.targetId):match("%d+") or ""
						if tid ~= "" and tEntry.state == "Completed" and type(tEntry.imageUrl) == "string" and tEntry.imageUrl ~= "" then
							iconMap[tid] = "rbxthumb://type=GameIcon&id=" .. tid .. "&w=150&h=150"
						end
					end
				end
			end
		end
	end

	local cards: {GameResultCardData} = {}
	for _, it in ipairs(rawItems) do
		local gInfo = gamesInfoMap[it.univId]
		local finalName = (it.name and it.name ~= "") and it.name
			or ((gInfo and gInfo.name and gInfo.name ~= "") and gInfo.name or ("Place #" .. it.univId))
		local finalPlace = it.rootPlaceId or (gInfo and gInfo.rootPlaceId)
		local finalStatus = it.status

		local iconUri = iconMap[it.univId]
			or (finalPlace and ("rbxthumb://type=Asset&id=" .. finalPlace .. "&w=150&h=150"))
			or ("rbxthumb://type=GameIcon&id=" .. it.univId .. "&w=150&h=150")

		local metaStr = "Universe: " .. it.univId .. (finalPlace and (" • Place: " .. finalPlace) or "")

		table.insert(cards, {
			universeId = it.univId,
			rootPlaceId = finalPlace,
			iconImage = iconUri,
			gameName = finalName,
			status = finalStatus,
			metaInfo = metaStr,
			isError = false,
		})
	end

	local acctLabel = uname and ("@" .. uname) or ("ID:" .. tostring(uid))
	return true, cards, acctLabel
end

-- ==========================================
-- API UPLOAD ASSET -> DAPAT ASSET ID & CEK STATUS
-- ==========================================
local function buildMultipartAssetBody(boundary: string, requestJson: string, fileContent: string, fileName: string): string
	local parts = {
		"--" .. boundary .. "\r\n",
		'Content-Disposition: form-data; name="request"\r\n',
		"Content-Type: application/json\r\n\r\n",
		requestJson .. "\r\n",
		"--" .. boundary .. "\r\n",
		string.format('Content-Disposition: form-data; name="fileContent"; filename="%s"\r\n', fileName),
		"Content-Type: application/octet-stream\r\n\r\n",
		fileContent .. "\r\n",
		"--" .. boundary .. "--\r\n",
	}
	return table.concat(parts)
end

local function uploadAssetAndGetId(params: {
	apiKey: string,
	cookieVal: string,
	assetType: string,
	displayName: string,
	description: string,
	groupId: string?,
	filePathOrContent: string,
	requestPublicCatalog: boolean,
}): (boolean, string?, string, string)
	local cleanKey = trim(params.apiKey)
	local cleanCookie = normalizeCookie(params.cookieVal)
	if cleanKey == "" then
		return false, nil, "API_KEY_MISSING", "Open Cloud API Key kosong. Isi di tab Setting."
	end

	local filePayload = params.filePathOrContent
	local loadedFile = loadTextFile(filePayload)
	if loadedFile then
		filePayload = loadedFile
		pushConsole("INFO", "Membaca file aset dari workspace: " .. filePayload:sub(1, 0) .. params.filePathOrContent)
	end

	if trim(filePayload) == "" then
		return false, nil, "EMPTY_PAYLOAD", "Konten/path file aset kosong."
	end

	local creatorTbl: {[string]: any}
	local cleanGroup = params.groupId and (trim(params.groupId):match("%d+") or "") or ""
	if cleanGroup ~= "" then
		creatorTbl = { groupId = tonumber(cleanGroup) }
	else
		local uid = getAuthenticatedUserFromCookie(cleanCookie)
		if not uid then
			return false, nil, "NO_CREATOR", "Isi Group ID atau pastikan Cookie valid untuk mendeteksi User ID."
		end
		creatorTbl = { userId = uid }
	end

	local reqObj = {
		assetType = params.assetType,
		displayName = trim(params.displayName) ~= "" and trim(params.displayName) or "UploadedAsset",
		description = trim(params.description) ~= "" and trim(params.description) or "Uploaded via Plugin Studio Lite",
		creationContext = {
			creator = creatorTbl,
		},
	}

	local boundary = "----IkyyStudioLiteBoundary" .. tostring(os.time())
	local multipartBody = buildMultipartAssetBody(boundary, HttpService:JSONEncode(reqObj), filePayload, "asset_payload.rbxm")

	local hdrs: {[string]: string} = {
		["x-api-key"] = cleanKey,
		["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
	}

	local res, ok, info = apiRequest({
		Url = "https://apis.roblox.com/assets/v1/assets",
		Method = "POST",
		Headers = hdrs,
		Body = multipartBody,
		Retries = 1,
	})

	if not ok or not res then
		return false, nil, "UPLOAD_FAILED", info
	end

	local bodyStr = tostring(res.Body or "")
	saveTextFile("Logs/asset_upload_" .. tostring(os.time()) .. ".json", bodyStr)

	local okDec, decoded = pcall(function()
		return HttpService:JSONDecode(bodyStr)
	end)

	local assetId: string? = nil
	local modState = "MODERATION_PENDING"
	local opPath: string? = nil

	if okDec and type(decoded) == "table" then
		if type(decoded.path) == "string" then
			opPath = decoded.path
		end
		if decoded.assetId ~= nil then
			assetId = tostring(decoded.assetId):match("%d+")
		end
		if type(decoded.response) == "table" and decoded.response.assetId ~= nil then
			assetId = tostring(decoded.response.assetId):match("%d+")
		end
	end

	if not assetId then
		assetId = bodyStr:match('"assetId"%s*:%s*"?(%d+)"?')
	end

	if opPath and opPath ~= "" and not assetId then
		for _ = 1, 5 do
			task.wait(1)
			local opRes, opOk = apiRequest({
				Url = "https://apis.roblox.com/assets/v1/" .. opPath:gsub("^/", ""),
				Method = "GET",
				Headers = { ["x-api-key"] = cleanKey },
				Retries = 1,
			})
			if opOk and opRes and opRes.Body then
				local opStr = tostring(opRes.Body)
				local okOp, opDec = pcall(function()
					return HttpService:JSONDecode(opStr)
				end)
				if okOp and type(opDec) == "table" then
					if type(opDec.response) == "table" and opDec.response.assetId ~= nil then
						assetId = tostring(opDec.response.assetId):match("%d+")
					end
					if type(opDec.response) == "table" and type(opDec.response.moderationResult) == "table" and type(opDec.response.moderationResult.moderationState) == "string" then
						modState = opDec.response.moderationResult.moderationState
					end
					if opDec.done == true then
						break
					end
				end
			end
		end
	end

	if not assetId or assetId == "" then
		return false, nil, "NO_ASSET_ID", "Upload terkirim tapi Asset ID belum terbaca (cek Console)."
	end

	local statusTag = params.requestPublicCatalog
		and ("ID Ready • " .. modState .. " (Publik: cek/set di Creator Dashboard)")
		or ("ID Ready • " .. modState .. " (Privat/Terbatas)")

	return true, assetId, statusTag, "Asset ID berhasil dibuat: " .. assetId
end

-- ==========================================
-- API VOICE CHAT UNIVERSE
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
		return false, nil, {}, "Gagal decode JSON respons voice"
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

-- ==========================================
-- API ALLOW THIRD PARTY SALES (DEVELOP V2 + 403 FALLBACK)
-- ==========================================
local function getUniverseThirdPartySales(universeId: string, cookieVal: string): (boolean, boolean?, {[string]: any}, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	if cleanUniv == "" then
		return false, nil, {}, "Universe ID tidak valid"
	end

	local hdrs: {[string]: string} = {}
	if trim(cookieVal) ~= "" then
		hdrs["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal)
	end

	local res, ok, info = apiRequest({
		Url = "https://develop.roblox.com/v2/universes/" .. cleanUniv .. "/configuration",
		Method = "GET",
		Headers = hdrs,
		Retries = 1,
	})

	if ok and res then
		local bodyStr = tostring(res.Body or "")
		local okDec, decoded = pcall(function()
			return HttpService:JSONDecode(bodyStr)
		end)
		if okDec and type(decoded) == "table" and type(decoded.allowThirdPartySales) == "boolean" then
			LAST_KNOWN_THIRD_PARTY[cleanUniv] = decoded.allowThirdPartySales
			return true, decoded.allowThirdPartySales, decoded, "OK"
		end
	end

	local code = res and (tonumber(res.StatusCode or res.Status or res.status_code) or 0) or 0
	if code == 403 then
		local v1Res, v1Ok = apiRequest({
			Url = "https://develop.roblox.com/v1/universes/" .. cleanUniv,
			Method = "GET",
			Headers = hdrs,
			Retries = 1,
		})
		local v1Decoded: {[string]: any} = {}
		if v1Ok and v1Res and v1Res.Body then
			pcall(function()
				local d = HttpService:JSONDecode(tostring(v1Res.Body))
				if type(d) == "table" then
					v1Decoded = d
					if type(d.allowThirdPartySales) == "boolean" then
						LAST_KNOWN_THIRD_PARTY[cleanUniv] = d.allowThirdPartySales
					end
				end
			end)
		end

		if LAST_KNOWN_THIRD_PARTY[cleanUniv] ~= nil then
			return true, LAST_KNOWN_THIRD_PARTY[cleanUniv], v1Decoded, "SYNC_LOCAL_STATE"
		end
		return true, nil, v1Decoded, "GET_403_PATCH_SUPPORTED"
	end

	return false, nil, {}, info
end

local function setUniverseThirdPartySales(universeId: string, cookieVal: string, enabled: boolean, csrfSeed: string): (boolean, string, string)
	local cleanUniv = trim(universeId):match("%d+") or ""
	if cleanUniv == "" then
		return false, "Universe ID tidak valid", csrfSeed
	end

	local jsonBody = HttpService:JSONEncode({
		allowThirdPartySales = enabled,
	})
	local currentCsrf = csrfSeed

	local function sendPatch(token: string)
		local hdrs: {[string]: string} = {
			["Cookie"] = ".ROBLOSECURITY=" .. normalizeCookie(cookieVal),
			["Content-Type"] = "application/json",
			["Origin"] = "https://create.roblox.com",
			["Referer"] = "https://create.roblox.com/",
		}
		if token ~= "" then
			hdrs["x-csrf-token"] = token
		end
		return apiRequest({
			Url = "https://develop.roblox.com/v2/universes/" .. cleanUniv .. "/configuration",
			Method = "PATCH",
			Headers = hdrs,
			Body = jsonBody,
			Retries = 1,
		})
	end

	local res, ok, info = sendPatch(currentCsrf)
	if not ok and res and tonumber(res.StatusCode or res.Status or res.status_code) == 403 then
		local newToken = getHeaderCaseInsensitive(res.Headers, "x-csrf-token")
		if newToken and newToken ~= "" then
			pushConsole("INFO", "Refresh x-csrf-token otomatis untuk develop.roblox.com")
			currentCsrf = newToken
			res, ok, info = sendPatch(currentCsrf)
		end
	end

	local bodyStr = res and tostring(res.Body or "") or ""
	if ok then
		LAST_KNOWN_THIRD_PARTY[cleanUniv] = enabled
		saveTextFile("Logs/thirdparty_" .. cleanUniv .. "_" .. tostring(os.time()) .. ".json", bodyStr)
		return true, "Allow Third Party Sales berhasil " .. (enabled and "DIAKTIFKAN" or "DINONAKTIFKAN"), currentCsrf
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
SubTitleLabel.Size = UDim2.new(0, 320, 0, 11)
SubTitleLabel.Position = UDim2.new(0, 48, 0, 5)
SubTitleLabel.BackgroundTransparency = 1
SubTitleLabel.Text = "IKYYSTUDIO • PLACE, ASSET ID, VOICE & 3RD PARTY"
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

local NavListFrame = Instance.new("ScrollingFrame")
NavListFrame.Size = UDim2.new(1, -10, 1, -10)
NavListFrame.Position = UDim2.new(0, 5, 0, 5)
NavListFrame.BackgroundTransparency = 1
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
-- REUSABLE GAME CARD BUILDER (SUPPORT COPY UNIVERSE ID)
-- ==========================================
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
			if isRefreshing then return end
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
-- HALAMAN 1: CREATE PLACE
-- ==========================================
local CreatePlacePage = Instance.new("Frame")
CreatePlacePage.Size = UDim2.fromScale(1, 1)
CreatePlacePage.BackgroundTransparency = 1
CreatePlacePage.Visible = true
CreatePlacePage.Parent = ContentArea
tabPages["CreatePlace"] = CreatePlacePage

local PageTitle = Instance.new("TextLabel")
PageTitle.Size = UDim2.new(1, -24, 0, 15)
PageTitle.Position = UDim2.new(0, 12, 0, 3)
PageTitle.BackgroundTransparency = 1
PageTitle.Text = "Create Place"
PageTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
PageTitle.TextSize = 12
PageTitle.Font = Enum.Font.GothamBold
PageTitle.TextXAlignment = Enum.TextXAlignment.Left
PageTitle.Parent = CreatePlacePage

local TemplateIdBox = Instance.new("TextBox")
TemplateIdBox.Size = UDim2.new(0.38, -12, 0, 21)
TemplateIdBox.Position = UDim2.new(0, 12, 0, 20)
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
GroupIdBox.Size = UDim2.new(0.34, -8, 0, 21)
GroupIdBox.Position = UDim2.new(0.38, 2, 0, 20)
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
PlaceCountBox.Size = UDim2.new(0.28, -10, 0, 21)
PlaceCountBox.Position = UDim2.new(0.72, 0, 0, 20)
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

local AutoThirdPartyRow = Instance.new("Frame")
AutoThirdPartyRow.Size = UDim2.new(1, -24, 0, 22)
AutoThirdPartyRow.Position = UDim2.new(0, 12, 0, 44)
AutoThirdPartyRow.BackgroundColor3 = Color3.fromRGB(17, 16, 26)
AutoThirdPartyRow.BorderSizePixel = 0
AutoThirdPartyRow.Parent = CreatePlacePage
Instance.new("UICorner", AutoThirdPartyRow).CornerRadius = UDim.new(0, 6)

local AutoThirdPartyLbl = Instance.new("TextLabel")
AutoThirdPartyLbl.Size = UDim2.new(1, -76, 1, 0)
AutoThirdPartyLbl.Position = UDim2.new(0, 8, 0, 0)
AutoThirdPartyLbl.BackgroundTransparency = 1
AutoThirdPartyLbl.Text = "Auto Third Party Sales saat buat place"
AutoThirdPartyLbl.TextColor3 = Color3.fromRGB(190, 187, 218)
AutoThirdPartyLbl.TextSize = 9
AutoThirdPartyLbl.Font = Enum.Font.GothamMedium
AutoThirdPartyLbl.TextXAlignment = Enum.TextXAlignment.Left
AutoThirdPartyLbl.Parent = AutoThirdPartyRow

local AutoThirdPartySwitch = createModernToggleSwitch(AutoThirdPartyRow, false, nil)
AutoThirdPartySwitch.Button.Size = UDim2.fromOffset(58, 18)
AutoThirdPartySwitch.Button.Position = UDim2.new(1, -64, 0.5, -9)

local CreatePlaceBtn = Instance.new("TextButton")
CreatePlaceBtn.Size = UDim2.new(1, -24, 0, 23)
CreatePlaceBtn.Position = UDim2.new(0, 12, 0, 69)
CreatePlaceBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
CreatePlaceBtn.Text = "🏗  CREATE PLACE"
CreatePlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreatePlaceBtn.TextSize = 10
CreatePlaceBtn.Font = Enum.Font.GothamBold
CreatePlaceBtn.Parent = CreatePlacePage
Instance.new("UICorner", CreatePlaceBtn).CornerRadius = UDim.new(0, 7)

local ProgressTrack = Instance.new("Frame")
ProgressTrack.Size = UDim2.new(1, -24, 0, 4)
ProgressTrack.Position = UDim2.new(0, 12, 0, 95)
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
StatusBanner.Size = UDim2.new(1, -24, 0, 13)
StatusBanner.Position = UDim2.new(0, 12, 0, 100)
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
ResultsScroll.Size = UDim2.new(1, -24, 1, -121)
ResultsScroll.Position = UDim2.new(0, 12, 0, 115)
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

local function appendResultCard(data: GameResultCardData)
	EmptyResultHint.Visible = false
	resultCardOrder += 1
	createGameCard(ResultsScroll, resultCardOrder, data, function()
		return CONFIG.Cookie
	end)
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
-- HALAMAN 2: CEK PLACE SAYA (DARI HALAMAN PROFILE)
-- ==========================================
local MyPlacesPage = Instance.new("Frame")
MyPlacesPage.Size = UDim2.fromScale(1, 1)
MyPlacesPage.BackgroundTransparency = 1
MyPlacesPage.Visible = false
MyPlacesPage.Parent = ContentArea
tabPages["MyPlaces"] = MyPlacesPage

local MyPlacesTitle = Instance.new("TextLabel")
MyPlacesTitle.Size = UDim2.new(1, -24, 0, 15)
MyPlacesTitle.Position = UDim2.new(0, 12, 0, 3)
MyPlacesTitle.BackgroundTransparency = 1
MyPlacesTitle.Text = "Cek Place Saya (Dari Halaman Profile)"
MyPlacesTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
MyPlacesTitle.TextSize = 11
MyPlacesTitle.Font = Enum.Font.GothamBold
MyPlacesTitle.TextXAlignment = Enum.TextXAlignment.Left
MyPlacesTitle.TextTruncate = Enum.TextTruncate.AtEnd
MyPlacesTitle.Parent = MyPlacesPage

local LoadMyPlacesBtn = Instance.new("TextButton")
LoadMyPlacesBtn.Size = UDim2.new(1, -24, 0, 24)
LoadMyPlacesBtn.Position = UDim2.new(0, 12, 0, 21)
LoadMyPlacesBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
LoadMyPlacesBtn.Text = "🔎  CEK PLACE DARI HALAMAN PROFILE"
LoadMyPlacesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadMyPlacesBtn.TextSize = 9
LoadMyPlacesBtn.Font = Enum.Font.GothamBold
LoadMyPlacesBtn.Parent = MyPlacesPage
Instance.new("UICorner", LoadMyPlacesBtn).CornerRadius = UDim.new(0, 6)

local MyPlacesStatusLbl = Instance.new("TextLabel")
MyPlacesStatusLbl.Size = UDim2.new(1, -24, 0, 14)
MyPlacesStatusLbl.Position = UDim2.new(0, 12, 0, 48)
MyPlacesStatusLbl.BackgroundTransparency = 1
MyPlacesStatusLbl.Text = "Mengambil daftar Creations dari profil akun cookie (private & publik)."
MyPlacesStatusLbl.TextColor3 = Color3.fromRGB(165, 162, 192)
MyPlacesStatusLbl.TextSize = 9
MyPlacesStatusLbl.Font = Enum.Font.GothamMedium
MyPlacesStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
MyPlacesStatusLbl.TextTruncate = Enum.TextTruncate.AtEnd
MyPlacesStatusLbl.Parent = MyPlacesPage

local MyPlacesScroll = Instance.new("ScrollingFrame")
MyPlacesScroll.Name = "MyPlacesListScroll"
MyPlacesScroll.Size = UDim2.new(1, -24, 1, -70)
MyPlacesScroll.Position = UDim2.new(0, 12, 0, 64)
MyPlacesScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
MyPlacesScroll.BorderSizePixel = 0
MyPlacesScroll.ScrollBarThickness = 3
MyPlacesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MyPlacesScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MyPlacesScroll.Parent = MyPlacesPage
Instance.new("UICorner", MyPlacesScroll).CornerRadius = UDim.new(0, 8)
local MyPlacesStroke = Instance.new("UIStroke", MyPlacesScroll)
MyPlacesStroke.Color = Color3.fromRGB(52, 48, 82)
MyPlacesStroke.Thickness = 1

local MyPlacesLayout = Instance.new("UIListLayout")
MyPlacesLayout.Padding = UDim.new(0, 6)
MyPlacesLayout.SortOrder = Enum.SortOrder.LayoutOrder
MyPlacesLayout.Parent = MyPlacesScroll

local MyPlacesPad = Instance.new("UIPadding")
MyPlacesPad.PaddingTop = UDim.new(0, 6)
MyPlacesPad.PaddingBottom = UDim.new(0, 6)
MyPlacesPad.PaddingLeft = UDim.new(0, 6)
MyPlacesPad.PaddingRight = UDim.new(0, 6)
MyPlacesPad.Parent = MyPlacesScroll

local MyPlacesEmptyHint = Instance.new("TextLabel")
MyPlacesEmptyHint.Size = UDim2.new(1, 0, 0, 36)
MyPlacesEmptyHint.BackgroundTransparency = 1
MyPlacesEmptyHint.Text = "Klik tombol di atas untuk memuat place dari halaman profile.\nTiap card mendukung 📋 Copy ID untuk menyalin Universe ID."
MyPlacesEmptyHint.TextColor3 = Color3.fromRGB(105, 102, 130)
MyPlacesEmptyHint.TextSize = 9
MyPlacesEmptyHint.Font = Enum.Font.Gotham
MyPlacesEmptyHint.Parent = MyPlacesScroll

-- ==========================================
-- HALAMAN 3: UPLOAD ASSET -> DAPAT ASSET ID + TOGGLE PUBLIK
-- ==========================================
local UploadAssetPage = Instance.new("Frame")
UploadAssetPage.Size = UDim2.fromScale(1, 1)
UploadAssetPage.BackgroundTransparency = 1
UploadAssetPage.Visible = false
UploadAssetPage.Parent = ContentArea
tabPages["UploadAsset"] = UploadAssetPage

local AssetPageTitle = Instance.new("TextLabel")
AssetPageTitle.Size = UDim2.new(1, -24, 0, 15)
AssetPageTitle.Position = UDim2.new(0, 12, 0, 3)
AssetPageTitle.BackgroundTransparency = 1
AssetPageTitle.Text = "Upload Asset -> Dapat Asset ID"
AssetPageTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
AssetPageTitle.TextSize = 11
AssetPageTitle.Font = Enum.Font.GothamBold
AssetPageTitle.TextXAlignment = Enum.TextXAlignment.Left
AssetPageTitle.Parent = UploadAssetPage

local AssetNameBox = Instance.new("TextBox")
AssetNameBox.Size = UDim2.new(0.56, -10, 0, 21)
AssetNameBox.Position = UDim2.new(0, 12, 0, 20)
AssetNameBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetNameBox.Text = "StudioLite_Model"
AssetNameBox.PlaceholderText = "Nama Aset"
AssetNameBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetNameBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetNameBox.TextSize = 9
AssetNameBox.Font = Enum.Font.Gotham
AssetNameBox.ClearTextOnFocus = false
AssetNameBox.Parent = UploadAssetPage
Instance.new("UICorner", AssetNameBox).CornerRadius = UDim.new(0, 6)

local AssetTypeBox = Instance.new("TextBox")
AssetTypeBox.Size = UDim2.new(0.44, -12, 0, 21)
AssetTypeBox.Position = UDim2.new(0.56, 0, 0, 20)
AssetTypeBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetTypeBox.Text = "Model"
AssetTypeBox.PlaceholderText = "Model / Audio / Decal"
AssetTypeBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetTypeBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetTypeBox.TextSize = 9
AssetTypeBox.Font = Enum.Font.Gotham
AssetTypeBox.ClearTextOnFocus = false
AssetTypeBox.Parent = UploadAssetPage
Instance.new("UICorner", AssetTypeBox).CornerRadius = UDim.new(0, 6)

local AssetGroupBox = Instance.new("TextBox")
AssetGroupBox.Size = UDim2.new(0.36, -10, 0, 21)
AssetGroupBox.Position = UDim2.new(0, 12, 0, 44)
AssetGroupBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetGroupBox.Text = ""
AssetGroupBox.PlaceholderText = "Group ID (opsional)"
AssetGroupBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetGroupBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetGroupBox.TextSize = 9
AssetGroupBox.Font = Enum.Font.Gotham
AssetGroupBox.ClearTextOnFocus = false
AssetGroupBox.Parent = UploadAssetPage
Instance.new("UICorner", AssetGroupBox).CornerRadius = UDim.new(0, 6)

local AssetFileBox = Instance.new("TextBox")
AssetFileBox.Size = UDim2.new(0.64, -12, 0, 21)
AssetFileBox.Position = UDim2.new(0.36, 0, 0, 44)
AssetFileBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
AssetFileBox.Text = ""
AssetFileBox.PlaceholderText = "Path file workspace (misal Assets/test.rbxm) atau isi"
AssetFileBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
AssetFileBox.TextColor3 = Color3.fromRGB(235, 235, 250)
AssetFileBox.TextSize = 9
AssetFileBox.Font = Enum.Font.Gotham
AssetFileBox.ClearTextOnFocus = false
AssetFileBox.Parent = UploadAssetPage
Instance.new("UICorner", AssetFileBox).CornerRadius = UDim.new(0, 6)

local AssetPublicRow = Instance.new("Frame")
AssetPublicRow.Size = UDim2.new(1, -24, 0, 22)
AssetPublicRow.Position = UDim2.new(0, 12, 0, 68)
AssetPublicRow.BackgroundColor3 = Color3.fromRGB(17, 16, 26)
AssetPublicRow.BorderSizePixel = 0
AssetPublicRow.Parent = UploadAssetPage
Instance.new("UICorner", AssetPublicRow).CornerRadius = UDim.new(0, 6)

local AssetPublicLbl = Instance.new("TextLabel")
AssetPublicLbl.Size = UDim2.new(1, -76, 1, 0)
AssetPublicLbl.Position = UDim2.new(0, 8, 0, 0)
AssetPublicLbl.BackgroundTransparency = 1
AssetPublicLbl.Text = "Mode Target Publik (OFF = Privat | ON = Publik)"
AssetPublicLbl.TextColor3 = Color3.fromRGB(190, 187, 218)
AssetPublicLbl.TextSize = 9
AssetPublicLbl.Font = Enum.Font.GothamMedium
AssetPublicLbl.TextXAlignment = Enum.TextXAlignment.Left
AssetPublicLbl.Parent = AssetPublicRow

local AssetPublicSwitch = createModernToggleSwitch(AssetPublicRow, false, function(state: boolean)
	AssetPublicLbl.Text = state
		and "Mode Publik: ON (set distribusi di Creator Dashboard)"
		or "Mode Publik: OFF (tetap privat / terbatas)"
end)
AssetPublicSwitch.Button.Size = UDim2.fromOffset(58, 18)
AssetPublicSwitch.Button.Position = UDim2.new(1, -64, 0.5, -9)

local UploadAssetBtn = Instance.new("TextButton")
UploadAssetBtn.Size = UDim2.new(1, -24, 0, 24)
UploadAssetBtn.Position = UDim2.new(0, 12, 0, 93)
UploadAssetBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
UploadAssetBtn.Text = "📦  UPLOAD & GENERATE ASSET ID"
UploadAssetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UploadAssetBtn.TextSize = 10
UploadAssetBtn.Font = Enum.Font.GothamBold
UploadAssetBtn.Parent = UploadAssetPage
Instance.new("UICorner", UploadAssetBtn).CornerRadius = UDim.new(0, 7)

local AssetResultCard = Instance.new("Frame")
AssetResultCard.Size = UDim2.new(1, -24, 1, -125)
AssetResultCard.Position = UDim2.new(0, 12, 0, 121)
AssetResultCard.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
AssetResultCard.BorderSizePixel = 0
AssetResultCard.Parent = UploadAssetPage
Instance.new("UICorner", AssetResultCard).CornerRadius = UDim.new(0, 8)
local AssetCardStroke = Instance.new("UIStroke", AssetResultCard)
AssetCardStroke.Color = Color3.fromRGB(52, 48, 82)
AssetCardStroke.Thickness = 1

local AssetIdDisplay = Instance.new("TextLabel")
AssetIdDisplay.Size = UDim2.new(1, -86, 0, 20)
AssetIdDisplay.Position = UDim2.new(0, 10, 0, 8)
AssetIdDisplay.BackgroundTransparency = 1
AssetIdDisplay.Text = "Asset ID: -"
AssetIdDisplay.TextColor3 = Color3.fromRGB(248, 248, 255)
AssetIdDisplay.TextSize = 12
AssetIdDisplay.Font = Enum.Font.GothamBold
AssetIdDisplay.TextXAlignment = Enum.TextXAlignment.Left
AssetIdDisplay.Parent = AssetResultCard

local CopyAssetIdBtn = Instance.new("TextButton")
CopyAssetIdBtn.Size = UDim2.fromOffset(66, 20)
CopyAssetIdBtn.Position = UDim2.new(1, -74, 0, 8)
CopyAssetIdBtn.BackgroundColor3 = Color3.fromRGB(42, 38, 72)
CopyAssetIdBtn.Text = "📋 Copy ID"
CopyAssetIdBtn.TextColor3 = Color3.fromRGB(220, 215, 255)
CopyAssetIdBtn.TextSize = 8
CopyAssetIdBtn.Font = Enum.Font.GothamBold
CopyAssetIdBtn.Parent = AssetResultCard
Instance.new("UICorner", CopyAssetIdBtn).CornerRadius = UDim.new(0, 5)

local AssetStatusDetail = Instance.new("TextLabel")
AssetStatusDetail.Size = UDim2.new(1, -20, 1, -34)
AssetStatusDetail.Position = UDim2.new(0, 10, 0, 30)
AssetStatusDetail.BackgroundTransparency = 1
AssetStatusDetail.Text = "Butuh Open Cloud API Key (tab Setting). API membuat aset & mengembalikan Asset ID; publikasi penuh ke katalog/Creator Store tetap melewati moderasi & pengaturan distribusi."
AssetStatusDetail.TextColor3 = Color3.fromRGB(165, 162, 194)
AssetStatusDetail.TextSize = 9
AssetStatusDetail.Font = Enum.Font.GothamMedium
AssetStatusDetail.TextXAlignment = Enum.TextXAlignment.Left
AssetStatusDetail.TextYAlignment = Enum.TextYAlignment.Top
AssetStatusDetail.TextWrapped = true
AssetStatusDetail.Parent = AssetResultCard

local lastGeneratedAssetId: string? = nil

CopyAssetIdBtn.MouseButton1Click:Connect(function()
	if not lastGeneratedAssetId or lastGeneratedAssetId == "" then
		notify("Asset ID", "Belum ada Asset ID.")
		return
	end
	local okCopy = setClipboardText(lastGeneratedAssetId)
	pushConsole("INFO", "Asset ID " .. lastGeneratedAssetId .. (okCopy and " disalin ke clipboard" or " ditampilkan"))
	notify("Asset ID", (okCopy and "Disalin: " or "ID: ") .. lastGeneratedAssetId)
end)

-- ==========================================
-- HALAMAN 4: VOICE CHAT UNIVERSE
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
VoiceTitle.Text = "Voice Chat Universe"
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
-- HALAMAN 5: ALLOW THIRD PARTY SALES
-- ==========================================
local ThirdPartyPage = Instance.new("Frame")
ThirdPartyPage.Size = UDim2.fromScale(1, 1)
ThirdPartyPage.BackgroundTransparency = 1
ThirdPartyPage.Visible = false
ThirdPartyPage.Parent = ContentArea
tabPages["ThirdPartySales"] = ThirdPartyPage

local ThirdPartyTitle = Instance.new("TextLabel")
ThirdPartyTitle.Size = UDim2.new(1, -24, 0, 16)
ThirdPartyTitle.Position = UDim2.new(0, 12, 0, 6)
ThirdPartyTitle.BackgroundTransparency = 1
ThirdPartyTitle.Text = "Allow Third Party Sales"
ThirdPartyTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
ThirdPartyTitle.TextSize = 12
ThirdPartyTitle.Font = Enum.Font.GothamBold
ThirdPartyTitle.TextXAlignment = Enum.TextXAlignment.Left
ThirdPartyTitle.Parent = ThirdPartyPage

local SalesUniverseBox = Instance.new("TextBox")
SalesUniverseBox.Size = UDim2.new(1, -108, 0, 26)
SalesUniverseBox.Position = UDim2.new(0, 12, 0, 26)
SalesUniverseBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
SalesUniverseBox.Text = CONFIG.DefaultUniverseId
SalesUniverseBox.PlaceholderText = "Masukkan Universe ID..."
SalesUniverseBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
SalesUniverseBox.TextColor3 = Color3.fromRGB(235, 235, 250)
SalesUniverseBox.TextSize = 10
SalesUniverseBox.Font = Enum.Font.Gotham
SalesUniverseBox.ClearTextOnFocus = false
SalesUniverseBox.Parent = ThirdPartyPage
Instance.new("UICorner", SalesUniverseBox).CornerRadius = UDim.new(0, 7)

local SyncSalesBtn = Instance.new("TextButton")
SyncSalesBtn.Size = UDim2.fromOffset(78, 26)
SyncSalesBtn.Position = UDim2.new(1, -90, 0, 26)
SyncSalesBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 52)
SyncSalesBtn.Text = "↻ Cek Status"
SyncSalesBtn.TextColor3 = Color3.fromRGB(215, 212, 248)
SyncSalesBtn.TextSize = 9
SyncSalesBtn.Font = Enum.Font.GothamBold
SyncSalesBtn.Parent = ThirdPartyPage
Instance.new("UICorner", SyncSalesBtn).CornerRadius = UDim.new(0, 7)
local SyncSalesStroke = Instance.new("UIStroke", SyncSalesBtn)
SyncSalesStroke.Color = Color3.fromRGB(82, 76, 124)
SyncSalesStroke.Thickness = 1

local SalesSwitchCard = Instance.new("Frame")
SalesSwitchCard.Size = UDim2.new(1, -24, 0, 52)
SalesSwitchCard.Position = UDim2.new(0, 12, 0, 60)
SalesSwitchCard.BackgroundColor3 = Color3.fromRGB(24, 23, 38)
SalesSwitchCard.BorderSizePixel = 0
SalesSwitchCard.Parent = ThirdPartyPage
Instance.new("UICorner", SalesSwitchCard).CornerRadius = UDim.new(0, 9)
local SalesSwitchStroke = Instance.new("UIStroke", SalesSwitchCard)
SalesSwitchStroke.Color = Color3.fromRGB(68, 62, 112)
SalesSwitchStroke.Thickness = 1

local SalesSwitchTitle = Instance.new("TextLabel")
SalesSwitchTitle.Size = UDim2.new(1, -104, 0, 16)
SalesSwitchTitle.Position = UDim2.new(0, 12, 0, 9)
SalesSwitchTitle.BackgroundTransparency = 1
SalesSwitchTitle.Text = "Allow Third Party Sales (Aktif / Nonaktif)"
SalesSwitchTitle.TextColor3 = Color3.fromRGB(248, 248, 255)
SalesSwitchTitle.TextSize = 11
SalesSwitchTitle.Font = Enum.Font.GothamBold
SalesSwitchTitle.TextXAlignment = Enum.TextXAlignment.Left
SalesSwitchTitle.Parent = SalesSwitchCard

local SalesSwitchDesc = Instance.new("TextLabel")
SalesSwitchDesc.Size = UDim2.new(1, -104, 0, 14)
SalesSwitchDesc.Position = UDim2.new(0, 12, 0, 26)
SalesSwitchDesc.BackgroundTransparency = 1
SalesSwitchDesc.Text = "Geser kiri/kanan untuk memilih OFF atau ON"
SalesSwitchDesc.TextColor3 = Color3.fromRGB(150, 146, 182)
SalesSwitchDesc.TextSize = 9
SalesSwitchDesc.Font = Enum.Font.GothamMedium
SalesSwitchDesc.TextXAlignment = Enum.TextXAlignment.Left
SalesSwitchDesc.Parent = SalesSwitchCard

local SalesSwitch = createModernToggleSwitch(SalesSwitchCard, false, function(state: boolean)
	SalesSwitchDesc.Text = state
		and "Target: Third Party Sales DIAKTIFKAN (true)"
		or "Target: Third Party Sales DINONAKTIFKAN (false)"
end)
SalesSwitch.Button.Position = UDim2.new(1, -86, 0.5, -14)

local ApplySalesBtn = Instance.new("TextButton")
ApplySalesBtn.Size = UDim2.new(1, -24, 0, 28)
ApplySalesBtn.Position = UDim2.new(0, 12, 0, 120)
ApplySalesBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ApplySalesBtn.Text = "⚡  TERAPKAN THIRD PARTY SALES"
ApplySalesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplySalesBtn.TextSize = 10
ApplySalesBtn.Font = Enum.Font.GothamBold
ApplySalesBtn.Parent = ThirdPartyPage
Instance.new("UICorner", ApplySalesBtn).CornerRadius = UDim.new(0, 7)

local SalesPreviewCard = Instance.new("Frame")
SalesPreviewCard.Size = UDim2.new(1, -24, 1, -162)
SalesPreviewCard.Position = UDim2.new(0, 12, 0, 155)
SalesPreviewCard.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
SalesPreviewCard.BorderSizePixel = 0
SalesPreviewCard.Parent = ThirdPartyPage
Instance.new("UICorner", SalesPreviewCard).CornerRadius = UDim.new(0, 8)
local SalesPrevStroke = Instance.new("UIStroke", SalesPreviewCard)
SalesPrevStroke.Color = Color3.fromRGB(52, 48, 82)
SalesPrevStroke.Thickness = 1

local SalesIconImg = Instance.new("ImageLabel")
SalesIconImg.Size = UDim2.fromOffset(52, 52)
SalesIconImg.Position = UDim2.new(0, 8, 0.5, -26)
SalesIconImg.BackgroundColor3 = Color3.fromRGB(20, 19, 32)
SalesIconImg.Image = resolveRealtimeGameIcon(CONFIG.DefaultUniverseId, nil, CONFIG.Cookie)
SalesIconImg.ScaleType = Enum.ScaleType.Crop
SalesIconImg.Parent = SalesPreviewCard
Instance.new("UICorner", SalesIconImg).CornerRadius = UDim.new(0, 8)

local SalesGameName = Instance.new("TextLabel")
SalesGameName.Size = UDim2.new(1, -74, 0, 16)
SalesGameName.Position = UDim2.new(0, 68, 0, 8)
SalesGameName.BackgroundTransparency = 1
SalesGameName.Text = "Universe #" .. CONFIG.DefaultUniverseId
SalesGameName.TextColor3 = Color3.fromRGB(245, 245, 255)
SalesGameName.TextSize = 11
SalesGameName.Font = Enum.Font.GothamBold
SalesGameName.TextXAlignment = Enum.TextXAlignment.Left
SalesGameName.TextTruncate = Enum.TextTruncate.AtEnd
SalesGameName.Parent = SalesPreviewCard

local SalesStatusText = Instance.new("TextLabel")
SalesStatusText.Size = UDim2.new(1, -74, 0, 26)
SalesStatusText.Position = UDim2.new(0, 68, 0, 26)
SalesStatusText.BackgroundTransparency = 1
SalesStatusText.Text = "Siap sinkronisasi status Allow Third Party Sales."
SalesStatusText.TextColor3 = Color3.fromRGB(165, 162, 194)
SalesStatusText.TextSize = 9
SalesStatusText.Font = Enum.Font.GothamMedium
SalesStatusText.TextXAlignment = Enum.TextXAlignment.Left
SalesStatusText.TextWrapped = true
SalesStatusText.Parent = SalesPreviewCard

-- ==========================================
-- HALAMAN 6: SETTING (COOKIE & OPEN CLOUD API KEY)
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
SettingTitle.Text = "Pengaturan Cookie & Open Cloud Key"
SettingTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
SettingTitle.TextSize = 12
SettingTitle.Font = Enum.Font.GothamBold
SettingTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingTitle.Parent = SettingPage

local CookieBox = Instance.new("TextBox")
CookieBox.Size = UDim2.new(1, -24, 0, 64)
CookieBox.Position = UDim2.new(0, 12, 0, 26)
CookieBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
CookieBox.Text = CONFIG.Cookie
CookieBox.PlaceholderText = "Tempel .ROBLOSECURITY Cookie di sini..."
CookieBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
CookieBox.TextColor3 = Color3.fromRGB(235, 235, 250)
CookieBox.TextSize = 9
CookieBox.Font = Enum.Font.Gotham
CookieBox.ClearTextOnFocus = false
CookieBox.MultiLine = true
CookieBox.TextWrapped = true
CookieBox.TextXAlignment = Enum.TextXAlignment.Left
CookieBox.TextYAlignment = Enum.TextYAlignment.Top
CookieBox.Parent = SettingPage
Instance.new("UICorner", CookieBox).CornerRadius = UDim.new(0, 7)

local ApiKeyBox = Instance.new("TextBox")
ApiKeyBox.Size = UDim2.new(1, -24, 0, 26)
ApiKeyBox.Position = UDim2.new(0, 12, 0, 96)
ApiKeyBox.BackgroundColor3 = Color3.fromRGB(13, 12, 20)
ApiKeyBox.Text = CONFIG.ApiKey
ApiKeyBox.PlaceholderText = "Open Cloud API Key (untuk Upload Asset ID)..."
ApiKeyBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 138)
ApiKeyBox.TextColor3 = Color3.fromRGB(235, 235, 250)
ApiKeyBox.TextSize = 9
ApiKeyBox.Font = Enum.Font.Gotham
ApiKeyBox.ClearTextOnFocus = false
ApiKeyBox.Parent = SettingPage
Instance.new("UICorner", ApiKeyBox).CornerRadius = UDim.new(0, 7)

local SaveSettingBtn = Instance.new("TextButton")
SaveSettingBtn.Size = UDim2.new(1, -24, 0, 28)
SaveSettingBtn.Position = UDim2.new(0, 12, 0, 128)
SaveSettingBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
SaveSettingBtn.Text = "💾  SIMPAN COOKIE & API KEY"
SaveSettingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveSettingBtn.TextSize = 10
SaveSettingBtn.Font = Enum.Font.GothamBold
SaveSettingBtn.Parent = SettingPage
Instance.new("UICorner", SaveSettingBtn).CornerRadius = UDim.new(0, 8)

local SettingStatusLabel = Instance.new("TextLabel")
SettingStatusLabel.Size = UDim2.new(1, -24, 0, 48)
SettingStatusLabel.Position = UDim2.new(0, 12, 0, 162)
SettingStatusLabel.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
SettingStatusLabel.Text = string.format(
	"Cookie: %s | API Key: %s",
	CONFIG.Cookie ~= "" and (tostring(#CONFIG.Cookie) .. " chars") or "Kosong",
	CONFIG.ApiKey ~= "" and (tostring(#CONFIG.ApiKey) .. " chars") or "Kosong"
)
SettingStatusLabel.TextColor3 = Color3.fromRGB(185, 205, 255)
SettingStatusLabel.TextSize = 9
SettingStatusLabel.Font = Enum.Font.Code
SettingStatusLabel.TextWrapped = true
SettingStatusLabel.Parent = SettingPage
Instance.new("UICorner", SettingStatusLabel).CornerRadius = UDim.new(0, 7)

-- ==========================================
-- HALAMAN 7: CONSOLE OUTPUT SERVER / PERMINTAAN
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
-- LOGIKA COOKIE, API KEY & NAVIGASI
-- ==========================================
local function syncCookieFromInput(): string
	local boxCookie = normalizeCookie(CookieBox.Text)
	if boxCookie ~= "" then
		CONFIG.Cookie = boxCookie
	end
	return CONFIG.Cookie
end

local function syncApiKeyFromInput(): string
	local boxKey = trim(ApiKeyBox.Text)
	if boxKey ~= "" then
		CONFIG.ApiKey = boxKey
	end
	return CONFIG.ApiKey
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
	SettingStatusLabel.Text = string.format(
		"Cookie: %s | API Key: %s",
		c ~= "" and (tostring(#c) .. " chars") or "Kosong",
		k ~= "" and (tostring(#k) .. " chars") or "Kosong"
	)
	SettingStatusLabel.TextColor3 = (okC and okK) and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 155, 165)
	pushConsole((okC and okK) and "OK" or "ERR", "Menyimpan cookie.txt & apikey.txt")
	notify("Setting", (okC and okK) and "Cookie & API Key tersimpan." or "Gagal menyimpan.")
end)

createNavButton("CreatePlace", "🏗  Create Place", 1).MouseButton1Click:Connect(function()
	switchTab("CreatePlace")
end)
createNavButton("MyPlaces", "🎮  Place Saya", 2).MouseButton1Click:Connect(function()
	switchTab("MyPlaces")
end)
createNavButton("UploadAsset", "📦  Asset ID", 3).MouseButton1Click:Connect(function()
	switchTab("UploadAsset")
end)
createNavButton("VoiceChat", "🎙  Voice Chat", 4).MouseButton1Click:Connect(function()
	switchTab("VoiceChat")
end)
createNavButton("ThirdPartySales", "🛒  3rd Party", 5).MouseButton1Click:Connect(function()
	switchTab("ThirdPartySales")
end)
createNavButton("Setting", "⚙  Setting", 6).MouseButton1Click:Connect(function()
	switchTab("Setting")
end)
createNavButton("Console", "🖥  Console", 7).MouseButton1Click:Connect(function()
	switchTab("Console")
end)
switchTab("CreatePlace")

pushConsole("INFO", "Plugin Studio Lite siap (Create Place, Place Saya, Asset ID, Voice & 3rd Party Sales aktif).")

-- ==========================================
-- LOGIKA UPLOAD ASSET -> DAPAT ASSET ID
-- ==========================================
local isUploadingAsset = false

UploadAssetBtn.MouseButton1Click:Connect(function()
	if isUploadingAsset then return end
	local apiKeyVal = syncApiKeyFromInput()
	local cookieVal = syncCookieFromInput()
	local wantPublic = AssetPublicSwitch.GetState()

	isUploadingAsset = true
	UploadAssetBtn.Text = "⏳  MENGUPLOAD ASET..."
	AssetStatusDetail.TextColor3 = Color3.fromRGB(175, 205, 255)
	AssetStatusDetail.Text = "Mengirim permintaan upload ke Open Cloud Assets API..."

	task.spawn(function()
		local okUp, assetIdStr, statusTag, msgUp = uploadAssetAndGetId({
			apiKey = apiKeyVal,
			cookieVal = cookieVal,
			assetType = AssetTypeBox.Text,
			displayName = AssetNameBox.Text,
			description = "Uploaded via Ikyy Plugin Studio Lite",
			groupId = AssetGroupBox.Text,
			filePathOrContent = AssetFileBox.Text,
			requestPublicCatalog = wantPublic,
		})

		if okUp and assetIdStr then
			lastGeneratedAssetId = assetIdStr
			AssetIdDisplay.Text = "Asset ID: " .. assetIdStr
			AssetStatusDetail.TextColor3 = Color3.fromRGB(145, 255, 190)
			AssetStatusDetail.Text = statusTag .. "\n" .. msgUp
			pushConsole("OK", msgUp .. " [" .. statusTag .. "]")
			notify("Asset ID", "ID: " .. assetIdStr)
		else
			AssetStatusDetail.TextColor3 = Color3.fromRGB(255, 155, 165)
			AssetStatusDetail.Text = "Gagal: " .. msgUp
			pushConsole("ERR", "Upload Asset gagal: " .. msgUp)
			notify("Asset ID", "Gagal upload aset.")
		end

		UploadAssetBtn.Text = "📦  UPLOAD & GENERATE ASSET ID"
		isUploadingAsset = false
	end)
end)

-- ==========================================
-- LOGIKA CEK PLACE SAYA (DARI HALAMAN PROFILE)
-- ==========================================
local isLoadingMyPlaces = false

local function clearMyPlacesCards()
	for _, child in ipairs(MyPlacesScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	MyPlacesEmptyHint.Visible = true
end

LoadMyPlacesBtn.MouseButton1Click:Connect(function()
	if isLoadingMyPlaces then return end
	local cookieVal = syncCookieFromInput()
	if cookieVal == "" then
		MyPlacesStatusLbl.TextColor3 = Color3.fromRGB(255, 155, 165)
		MyPlacesStatusLbl.Text = "Cookie .ROBLOSECURITY kosong. Isi di tab Setting."
		pushConsole("ERR", "Cek Place Saya gagal: Cookie kosong.")
		notify("Place Saya", "Cookie belum diisi.")
		return
	end

	isLoadingMyPlaces = true
	LoadMyPlacesBtn.Text = "⏳  MEMUAT DARI HALAMAN PROFILE..."
	MyPlacesStatusLbl.TextColor3 = Color3.fromRGB(175, 205, 255)
	MyPlacesStatusLbl.Text = "Membaca Creations dari halaman profile akun..."
	clearMyPlacesCards()

	task.spawn(function()
		local okList, cards, infoOrAcct = fetchMyPlacesList(cookieVal)
		if okList then
			local pubCount, privCount = 0, 0
			for _, cData in ipairs(cards) do
				if cData.status == "publik" then
					pubCount += 1
				elseif cData.status == "private" then
					privCount += 1
				end
			end

			if #cards == 0 then
				MyPlacesStatusLbl.TextColor3 = Color3.fromRGB(255, 215, 130)
				MyPlacesStatusLbl.Text = string.format("Profile %s: tidak ada place ditemukan.", infoOrAcct)
				pushConsole("WARN", "Daftar place di halaman profile kosong untuk " .. infoOrAcct)
			else
				MyPlacesEmptyHint.Visible = false
				for idx, cardData in ipairs(cards) do
					createGameCard(MyPlacesScroll, idx, cardData, function()
						return CONFIG.Cookie
					end)
				end
				MyPlacesStatusLbl.TextColor3 = Color3.fromRGB(145, 255, 190)
				MyPlacesStatusLbl.Text = string.format("%s • Total %d place (Publik: %d | Private: %d)", infoOrAcct, #cards, pubCount, privCount)
				pushConsole("OK", string.format("Memuat %d place dari profile %s (Publik: %d, Private: %d).", #cards, infoOrAcct, pubCount, privCount))
			end
		else
			MyPlacesStatusLbl.TextColor3 = Color3.fromRGB(255, 155, 165)
			MyPlacesStatusLbl.Text = "Gagal memuat place: " .. infoOrAcct
			pushConsole("ERR", "Cek Place Saya gagal: " .. infoOrAcct)
			notify("Place Saya", "Gagal memuat daftar place.")
		end

		LoadMyPlacesBtn.Text = "🔎  CEK PLACE DARI HALAMAN PROFILE"
		isLoadingMyPlaces = false
	end)
end)

-- ==========================================
-- LOGIKA VOICE CHAT UNIVERSE
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
		VoiceStatusText.Text = "Respons pengaturan voice terbaca (cek Console)"
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
	VoiceStatusText.Text = "Mengirim pengaturan optIn = " .. tostring(targetState) .. "..."

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
-- LOGIKA ALLOW THIRD PARTY SALES
-- ==========================================
local isSyncingSales = false
local isApplyingSales = false
local cachedSalesCsrf = ""

local function refreshSalesUniversePreview(univId: string, cookieVal: string, overrideState: boolean?)
	local cardInfo = fetchRealtimeGameData(univId, cookieVal, nil)
	SalesIconImg.Image = cardInfo.iconImage
	SalesGameName.Text = cardInfo.gameName .. " (" .. cardInfo.status .. ")"

	if type(overrideState) == "boolean" then
		LAST_KNOWN_THIRD_PARTY[univId] = overrideState
	end

	local okSales, salesOn, rawSalesData, errSales = getUniverseThirdPartySales(univId, cookieVal)
	if okSales and type(salesOn) == "boolean" then
		SalesSwitch.SetState(salesOn, true)
		SalesStatusText.TextColor3 = salesOn and Color3.fromRGB(145, 255, 190) or Color3.fromRGB(255, 210, 140)
		local suffix = (errSales == "SYNC_LOCAL_STATE") and " (tersinkron dari PATCH)" or ""
		SalesStatusText.Text = "Third Party Sales: " .. (salesOn and "AKTIF (ON)" or "NONAKTIF (OFF)") .. suffix
		pushConsole("OK", string.format("Universe #%s allowThirdPartySales = %s%s", univId, tostring(salesOn), suffix))
	elseif okSales then
		SalesStatusText.TextColor3 = Color3.fromRGB(185, 205, 255)
		SalesStatusText.Text = "GET konfigurasi dibatasi (403), namun PATCH aktif. Geser ON/OFF lalu Terapkan."
		pushConsole("INFO", string.format("Universe #%s GET configuration 403; gunakan toggle + Terapkan untuk mengubah. JSON: %s", univId, HttpService:JSONEncode(rawSalesData)))
	else
		SalesStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		SalesStatusText.Text = "Gagal cek Third Party Sales: " .. errSales
		pushConsole("ERR", string.format("Universe #%s gagal cek Third Party Sales: %s", univId, errSales))
	end
end

SyncSalesBtn.MouseButton1Click:Connect(function()
	if isSyncingSales or isApplyingSales then return end
	local cookieVal = syncCookieFromInput()
	local univId = trim(SalesUniverseBox.Text):match("%d+") or ""
	if univId == "" then
		SalesStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		SalesStatusText.Text = "Masukkan Universe ID yang valid."
		pushConsole("WARN", "Cek Status Third Party Sales dibatalkan: Universe ID kosong/tidak valid.")
		return
	end

	isSyncingSales = true
	SyncSalesBtn.Text = "..."
	task.spawn(function()
		refreshSalesUniversePreview(univId, cookieVal, nil)
		SyncSalesBtn.Text = "↻ Cek Status"
		isSyncingSales = false
	end)
end)

ApplySalesBtn.MouseButton1Click:Connect(function()
	if isApplyingSales or isSyncingSales then return end
	local cookieVal = syncCookieFromInput()
	if cookieVal == "" then
		SalesStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		SalesStatusText.Text = "Cookie .ROBLOSECURITY kosong. Isi di tab Setting."
		pushConsole("ERR", "Apply Third Party Sales gagal: Cookie kosong.")
		notify("3rd Party Sales", "Cookie belum diisi.")
		return
	end

	local univId = trim(SalesUniverseBox.Text):match("%d+") or ""
	if univId == "" then
		SalesStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
		SalesStatusText.Text = "Universe ID tidak valid."
		pushConsole("ERR", "Apply Third Party Sales gagal: Universe ID tidak valid.")
		return
	end

	local targetState = SalesSwitch.GetState()
	isApplyingSales = true
	ApplySalesBtn.Text = "⏳  MENGIRIM..."
	SalesStatusText.TextColor3 = Color3.fromRGB(175, 205, 255)
	SalesStatusText.Text = "Mengirim allowThirdPartySales = " .. tostring(targetState) .. "..."

	task.spawn(function()
		local okPatch, msgPatch, nextCsrf = setUniverseThirdPartySales(univId, cookieVal, targetState, cachedSalesCsrf)
		cachedSalesCsrf = nextCsrf

		if okPatch then
			SalesStatusText.TextColor3 = Color3.fromRGB(145, 255, 190)
			SalesStatusText.Text = msgPatch
			pushConsole("OK", msgPatch .. " (Universe #" .. univId .. ")")
			notify("3rd Party Sales", msgPatch)
			refreshSalesUniversePreview(univId, cookieVal, targetState)
		else
			SalesStatusText.TextColor3 = Color3.fromRGB(255, 155, 165)
			SalesStatusText.Text = "Gagal: " .. msgPatch
			pushConsole("ERR", "Apply Third Party Sales gagal (#" .. univId .. "): " .. msgPatch)
			notify("3rd Party Sales", "Gagal mengubah status Third Party Sales.")
		end

		ApplySalesBtn.Text = "⚡  TERAPKAN THIRD PARTY SALES"
		isApplyingSales = false
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
	local autoThirdParty = AutoThirdPartySwitch.GetState()

	isCreatingPlace = true
	clearResultCards()
	setCreateProgress("working", 0.1, "Membuat " .. tostring(count) .. " place...")
	pushConsole("INFO", string.format("Mulai Create Place: count=%d, template=%d, group=%s, auto3rdParty=%s", count, tplId, grpId and tostring(grpId) or "none", tostring(autoThirdParty)))

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

					if autoThirdParty then
						local okSalesAuto, msgSalesAuto, nextSalesCsrf = setUniverseThirdPartySales(createdUnivId, cookieVal, true, cachedSalesCsrf)
						cachedSalesCsrf = nextSalesCsrf
						pushConsole(okSalesAuto and "OK" or "WARN", string.format("Auto 3rd Party Sales #%s: %s", createdUnivId, msgSalesAuto))
					end

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
