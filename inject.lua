--!strict
-- Lite & Anti-Crash ID & Playtest Scanner (Delta Mobile Edition) by Ikyy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local OLD_GUI = PlayerGui:FindFirstChild("IkyyPluginStudioLite_GUI")
if OLD_GUI then
	OLD_GUI:Destroy()
end

export type SearchMatch = {
	objectName: string,
	className: string,
	sourceType: string,
	fullName: string,
	detail: string,
}

local WINDOW_SIZE = UDim2.fromOffset(480, 290)
local WINDOW_POS = UDim2.new(0.5, -240, 0.5, -145)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS
local SCAN_FOLDER = "IkyyStudioLite"
local SCAN_TXT_FILE = SCAN_FOLDER .. "/playtest_scan_log.txt"

local function getExecutorFunc(name: string): any
	local env = (getgenv and getgenv()) or _G
	if env and type((env :: any)[name]) == "function" then
		return (env :: any)[name]
	end
	if type((_G :: any)[name]) == "function" then
		return (_G :: any)[name]
	end
	return nil
end

local function copyTextToClipboard(text: string): boolean
	local fn = getExecutorFunc("setclipboard")
	if type(fn) == "function" then
		local ok = pcall(function()
			fn(text)
		end)
		return ok
	end
	return false
end

local function writeScanTxt(content: string): boolean
	local makeFolderFn = getExecutorFunc("makefolder")
	local isFolderFn = getExecutorFunc("isfolder")
	local writeFileFn = getExecutorFunc("writefile")

	if type(writeFileFn) ~= "function" then
		return false
	end

	local ok = pcall(function()
		if type(makeFolderFn) == "function" then
			local exists = false
			if type(isFolderFn) == "function" then
				local okCheck, resCheck = pcall(function()
					return isFolderFn(SCAN_FOLDER)
				end)
				exists = (okCheck and resCheck == true)
			end
			if not exists then
				pcall(function()
					makeFolderFn(SCAN_FOLDER)
				end)
			end
		end
		writeFileFn(SCAN_TXT_FILE, content)
	end)
	return ok
end

local function safeArgSummary(args: {any}): string
	if #args == 0 then
		return "()"
	end
	local parts: {string} = {}
	local limit = math.min(#args, 3)
	for i = 1, limit do
		local v = args[i]
		local t = typeof(v)
		if t == "Instance" then
			table.insert(parts, "Instance(" .. tostring(v.Name) .. ")")
		elseif t == "string" then
			local s = tostring(v)
			if #s > 32 then
				s = string.sub(s, 1, 32) .. "..."
			end
			table.insert(parts, string.format("%q", s))
		else
			table.insert(parts, tostring(v))
		end
	end
	if #args > limit then
		table.insert(parts, "...")
	end
	return "(" .. table.concat(parts, ", ") .. ")"
end

-- ==========================================
-- UI UTAMA (RINGAN & ANTI-CRASH)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IkyyPluginStudioLite_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local FloatingProfileBtn = Instance.new("TextButton")
FloatingProfileBtn.Name = "FloatingProfileToggle"
FloatingProfileBtn.Size = ICON_SIZE
FloatingProfileBtn.Position = ICON_DEFAULT_POS
FloatingProfileBtn.BackgroundColor3 = Color3.fromRGB(28, 24, 48)
FloatingProfileBtn.Text = "🔎"
FloatingProfileBtn.TextColor3 = Color3.fromRGB(245, 245, 255)
FloatingProfileBtn.TextSize = 18
FloatingProfileBtn.Font = Enum.Font.GothamBold
FloatingProfileBtn.BorderSizePixel = 0
FloatingProfileBtn.Visible = false
FloatingProfileBtn.AutoButtonColor = false
FloatingProfileBtn.ZIndex = 50
FloatingProfileBtn.Parent = ScreenGui

Instance.new("UICorner", FloatingProfileBtn).CornerRadius = UDim.new(1, 0)
local FloatStroke = Instance.new("UIStroke", FloatingProfileBtn)
FloatStroke.Color = Color3.fromRGB(108, 86, 245)
FloatStroke.Thickness = 2

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainWindow"
MainWindow.Size = WINDOW_SIZE
MainWindow.Position = WINDOW_POS
MainWindow.BackgroundColor3 = Color3.fromRGB(16, 15, 24)
MainWindow.BorderSizePixel = 0
MainWindow.ClipsDescendants = true
MainWindow.Parent = ScreenGui

Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainWindow)
MainStroke.Color = Color3.fromRGB(92, 72, 168)
MainStroke.Thickness = 1.2

local HeaderBar = Instance.new("Frame")
HeaderBar.Name = "HeaderBar"
HeaderBar.Size = UDim2.new(1, 0, 0, 38)
HeaderBar.BackgroundColor3 = Color3.fromRGB(22, 20, 34)
HeaderBar.BorderSizePixel = 0
HeaderBar.ClipsDescendants = true
HeaderBar.Parent = MainWindow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 0, 16)
TitleLabel.Position = UDim2.new(0, 12, 0, 4)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔎 Lite ID & Playtest Scanner"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(1, -80, 0, 12)
MetaLabel.Position = UDim2.new(0, 12, 0, 21)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "Anti-Crash Mode • Auto-Save TXT • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(130, 126, 160)
MetaLabel.TextSize = 8
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.TextTruncate = Enum.TextTruncate.AtEnd
MetaLabel.Parent = HeaderBar

local CloseCircleBtn = Instance.new("TextButton")
CloseCircleBtn.Name = "CloseToCircleBtn"
CloseCircleBtn.Size = UDim2.fromOffset(24, 24)
CloseCircleBtn.Position = UDim2.new(1, -34, 0.5, -12)
CloseCircleBtn.BackgroundColor3 = Color3.fromRGB(36, 33, 54)
CloseCircleBtn.Text = "✕"
CloseCircleBtn.TextColor3 = Color3.fromRGB(255, 110, 125)
CloseCircleBtn.TextSize = 11
CloseCircleBtn.Font = Enum.Font.GothamBold
CloseCircleBtn.Parent = HeaderBar
Instance.new("UICorner", CloseCircleBtn).CornerRadius = UDim.new(1, 0)

local function setMinimized(minimized: boolean)
	if minimized then
		MainWindow.Visible = false
		FloatingProfileBtn.Position = currentIconPos
		FloatingProfileBtn.Visible = true
	else
		FloatingProfileBtn.Visible = false
		MainWindow.Position = WINDOW_POS
		MainWindow.Size = WINDOW_SIZE
		MainWindow.Visible = true
	end
end

do
	local dragging = false
	local movedSignificantly = false
	local dragStart = Vector3.zero
	local startPos = UDim2.new()
	local activeInput: InputObject? = nil

	local function clampToViewport(pos: UDim2): UDim2
		local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local maxX = math.max(6, viewport.X - 48)
		local maxY = math.max(6, viewport.Y - 48)
		return UDim2.fromOffset(math.clamp(pos.X.Offset, 6, maxX), math.clamp(pos.Y.Offset, 6, maxY))
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
			if delta.Magnitude > 6 then
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
			if wasClick then
				setMinimized(false)
			end
		end
	end)
end

CloseCircleBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)

-- ==========================================
-- KONTEN UTAMA
-- ==========================================
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -18, 1, -44)
ContentFrame.Position = UDim2.new(0, 9, 0, 40)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true
ContentFrame.Parent = MainWindow

local InputRow = Instance.new("Frame")
InputRow.Size = UDim2.new(1, 0, 0, 26)
InputRow.BackgroundTransparency = 1
InputRow.ClipsDescendants = true
InputRow.Parent = ContentFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchIdInput"
SearchBox.Size = UDim2.new(0.66, -4, 1, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(13, 12, 21)
SearchBox.Text = ""
SearchBox.PlaceholderText = "Ketik ID musik / nama part / module..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 142)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 9
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.TextTruncate = Enum.TextTruncate.AtEnd
SearchBox.ClipsDescendants = true
SearchBox.Parent = InputRow
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SearchBoxStroke = Instance.new("UIStroke", SearchBox)
SearchBoxStroke.Color = Color3.fromRGB(75, 62, 130)
SearchBoxStroke.Thickness = 1

local BoxPad = Instance.new("UIPadding")
BoxPad.PaddingLeft = UDim.new(0, 7)
BoxPad.PaddingRight = UDim.new(0, 7)
BoxPad.Parent = SearchBox

local ScanBtn = Instance.new("TextButton")
ScanBtn.Name = "ScanBtn"
ScanBtn.Size = UDim2.new(0.18, -3, 1, 0)
ScanBtn.Position = UDim2.new(0.66, 2, 0, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ScanBtn.Text = "Cari"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.TextSize = 9
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.ClipsDescendants = true
ScanBtn.Parent = InputRow
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Name = "ClearBtn"
ClearBtn.Size = UDim2.new(0.16, 0, 1, 0)
ClearBtn.Position = UDim2.new(0.84, 2, 0, 0)
ClearBtn.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
ClearBtn.Text = "Hapus"
ClearBtn.TextColor3 = Color3.fromRGB(235, 232, 255)
ClearBtn.TextSize = 8
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.ClipsDescendants = true
ClearBtn.Parent = InputRow
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 14)
StatusLabel.Position = UDim2.new(0, 0, 0, 29)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Auto-Log Aktif -> " .. SCAN_TXT_FILE
StatusLabel.TextColor3 = Color3.fromRGB(155, 152, 188)
StatusLabel.TextSize = 8
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.ClipsDescendants = true
StatusLabel.Parent = ContentFrame

local SelectedBox = Instance.new("ScrollingFrame")
SelectedBox.Name = "SelectedDetailBox"
SelectedBox.Size = UDim2.new(1, 0, 0, 58)
SelectedBox.Position = UDim2.new(0, 0, 0, 45)
SelectedBox.BackgroundColor3 = Color3.fromRGB(21, 19, 34)
SelectedBox.BorderSizePixel = 0
SelectedBox.ScrollBarThickness = 2
SelectedBox.CanvasSize = UDim2.new(0, 0, 0, 0)
SelectedBox.AutomaticCanvasSize = Enum.AutomaticSize.Y
SelectedBox.ClipsDescendants = true
SelectedBox.Parent = ContentFrame
Instance.new("UICorner", SelectedBox).CornerRadius = UDim.new(0, 7)
local SelStroke = Instance.new("UIStroke", SelectedBox)
SelStroke.Color = Color3.fromRGB(92, 72, 168)
SelStroke.Thickness = 1

local SelLayout = Instance.new("UIListLayout")
SelLayout.Padding = UDim.new(0, 2)
SelLayout.SortOrder = Enum.SortOrder.LayoutOrder
SelLayout.Parent = SelectedBox

local SelPad = Instance.new("UIPadding")
SelPad.PaddingTop = UDim.new(0, 4)
SelPad.PaddingBottom = UDim.new(0, 4)
SelPad.PaddingLeft = UDim.new(0, 7)
SelPad.PaddingRight = UDim.new(0, 7)
SelPad.Parent = SelectedBox

local function makeWrappedDetailLabel(order: number, color: Color3, font: Enum.Font, textSize: number): TextLabel
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -4, 0, 14)
	lbl.AutomaticSize = Enum.AutomaticSize.Y
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color
	lbl.TextSize = textSize
	lbl.Font = font
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.ClipsDescendants = true
	lbl.LayoutOrder = order
	lbl.Parent = SelectedBox
	return lbl
end

local SelectedNameLabel = makeWrappedDetailLabel(1, Color3.fromRGB(255, 255, 255), Enum.Font.GothamBold, 9)
SelectedNameLabel.Text = "Terpilih: - (Klik hasil di bawah)"

local SelectedMetaLabel = makeWrappedDetailLabel(2, Color3.fromRGB(165, 195, 255), Enum.Font.GothamMedium, 8)
SelectedMetaLabel.Text = "Tipe / Info: -"

local SelectedPathLabel = makeWrappedDetailLabel(3, Color3.fromRGB(185, 182, 212), Enum.Font.RobotoMono, 8)
SelectedPathLabel.Text = "Path: -"

local ResultsScroll = Instance.new("ScrollingFrame")
ResultsScroll.Size = UDim2.new(1, 0, 1, -108)
ResultsScroll.Position = UDim2.new(0, 0, 0, 107)
ResultsScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
ResultsScroll.BorderSizePixel = 0
ResultsScroll.ScrollBarThickness = 3
ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ResultsScroll.ClipsDescendants = true
ResultsScroll.Parent = ContentFrame
Instance.new("UICorner", ResultsScroll).CornerRadius = UDim.new(0, 7)
local ResStroke = Instance.new("UIStroke", ResultsScroll)
ResStroke.Color = Color3.fromRGB(48, 44, 74)
ResStroke.Thickness = 1

local ResLayout = Instance.new("UIListLayout")
ResLayout.Padding = UDim.new(0, 4)
ResLayout.SortOrder = Enum.SortOrder.LayoutOrder
ResLayout.Parent = ResultsScroll

local ResPad = Instance.new("UIPadding")
ResPad.PaddingTop = UDim.new(0, 5)
ResPad.PaddingBottom = UDim.new(0, 5)
ResPad.PaddingLeft = UDim.new(0, 5)
ResPad.PaddingRight = UDim.new(0, 5)
ResPad.Parent = ResultsScroll

-- ==========================================
-- LOGIKA SCAN RINGAN (BATCHED YIELD AGAR TIDAK CRASH)
-- ==========================================
local lastMatches: {SearchMatch} = {}
local selectedIndex: number? = nil
local capturedRuntimeLogs: {string} = {}
local capturedNewInstances: {string} = {}
local capturedFeatureRequests: {string} = {}
local hookedRemotes: {[Instance]: boolean} = {}
local isScanningNow = false
local saveQueued = false

local function appendCaptureList(list: {string}, line: string, maxItems: number)
	table.insert(list, line)
	if #list > maxItems then
		table.remove(list, 1)
	end
end

local function isIgnoredInstance(inst: Instance): boolean
	if inst == ScreenGui or inst:IsDescendantOf(ScreenGui) then
		return true
	end
	local p = inst.Parent
	while p do
		if p.Name == "StudioGui" then
			return true
		end
		p = p.Parent
	end
	return false
end

local function buildTxtReport(queryText: string): string
	local lines: {string} = {
		"=== IKYY STUDIO LITE • PLAYTEST & ID LOG ===",
		"Timestamp   : " .. os.date("!%Y-%m-%d %H:%M:%S UTC"),
		"Player      : " .. LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")",
		"PlaceId     : " .. tostring(game.PlaceId),
		"Query       : " .. (queryText ~= "" and queryText or "(Auto-Monitor)"),
		"",
		"--- REMOTE / REQUEST FITUR (" .. tostring(#capturedFeatureRequests) .. ") ---",
	}

	if #capturedFeatureRequests == 0 then
		table.insert(lines, "(Belum ada aktivitas RemoteEvent/BindableEvent)")
	else
		for _, reqLine in ipairs(capturedFeatureRequests) do
			table.insert(lines, reqLine)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "--- HASIL SCAN OBJEK / ID (" .. tostring(#lastMatches) .. ") ---")
	if #lastMatches == 0 then
		table.insert(lines, "(Belum ada hasil scan)")
	else
		for i, m in ipairs(lastMatches) do
			table.insert(lines, string.format("#%d | Name=%s | Class=%s | Type=%s | Path=%s | Detail=%s",
				i, m.objectName, m.className, m.sourceType, m.fullName, m.detail))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "--- OBJEK BARU SAAT PLAYTEST (" .. tostring(#capturedNewInstances) .. ") ---")
	if #capturedNewInstances == 0 then
		table.insert(lines, "(Belum ada objek baru)")
	else
		for _, entry in ipairs(capturedNewInstances) do
			table.insert(lines, entry)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "--- CONSOLE / ERROR / KICK LOG (" .. tostring(#capturedRuntimeLogs) .. ") ---")
	if #capturedRuntimeLogs == 0 then
		table.insert(lines, "(Belum ada log konsol)")
	else
		for _, logLine in ipairs(capturedRuntimeLogs) do
			table.insert(lines, logLine)
		end
	end

	return table.concat(lines, "\n")
end

local function queueSaveTxt()
	if saveQueued then return end
	saveQueued = true
	task.delay(0.8, function()
		saveQueued = false
		local report = buildTxtReport(SearchBox.Text)
		writeScanTxt(report)
	end)
end

local function hookRemoteInstance(inst: Instance)
	if hookedRemotes[inst] or isIgnoredInstance(inst) then
		return
	end
	if inst:IsA("RemoteEvent") then
		hookedRemotes[inst] = true
		pcall(function()
			inst.OnClientEvent:Connect(function(...: any)
				local line = string.format("[%s][OnClientEvent] %s args=%s",
					os.date("!%H:%M:%S"), inst:GetFullName(), safeArgSummary({ ... }))
				appendCaptureList(capturedFeatureRequests, line, 120)
				queueSaveTxt()
			end)
		end)
	elseif inst:IsA("BindableEvent") then
		hookedRemotes[inst] = true
		pcall(function()
			inst.Event:Connect(function(...: any)
				local line = string.format("[%s][BindableEvent] %s args=%s",
					os.date("!%H:%M:%S"), inst:GetFullName(), safeArgSummary({ ... }))
				appendCaptureList(capturedFeatureRequests, line, 120)
				queueSaveTxt()
			end)
		end)
	end
end

local function selectMatch(idx: number)
	local item = lastMatches[idx]
	if not item then return end
	selectedIndex = idx

	SelectedNameLabel.Text = string.format("Nama: %s  [%s]", item.objectName, item.className)
	SelectedMetaLabel.Text = string.format("Tipe: %s • %s", item.sourceType, item.detail)
	SelectedPathLabel.Text = "Path: " .. item.fullName

	local copied = copyTextToClipboard(item.fullName)
	StatusLabel.Text = "Dipilih #" .. tostring(idx) .. " (" .. item.objectName .. ")" .. (copied and " • Path disalin" or "")
	queueSaveTxt()
end

local function renderResults(matches: {SearchMatch})
	for _, child in ipairs(ResultsScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	if #matches == 0 then
		local emptyBtn = Instance.new("TextButton")
		emptyBtn.Size = UDim2.new(1, -4, 0, 26)
		emptyBtn.BackgroundColor3 = Color3.fromRGB(22, 21, 34)
		emptyBtn.Text = "  Ketik ID musik / nama objek lalu tekan Cari (Log & Request tetap tersimpan otomatis)"
		emptyBtn.TextColor3 = Color3.fromRGB(165, 162, 190)
		emptyBtn.TextSize = 8
		emptyBtn.Font = Enum.Font.GothamMedium
		emptyBtn.TextXAlignment = Enum.TextXAlignment.Left
		emptyBtn.TextWrapped = true
		emptyBtn.ClipsDescendants = true
		emptyBtn.LayoutOrder = 1
		emptyBtn.Parent = ResultsScroll
		Instance.new("UICorner", emptyBtn).CornerRadius = UDim.new(0, 5)
		return
	end

	for idx, item in ipairs(matches) do
		local isSelected = (idx == selectedIndex)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 32)
		btn.AutomaticSize = Enum.AutomaticSize.Y
		btn.BackgroundColor3 = isSelected and Color3.fromRGB(52, 46, 86) or Color3.fromRGB(22, 21, 34)
		btn.Text = string.format("#%d %s [%s]\n%s • %s", idx, item.objectName, item.className, item.sourceType, item.detail)
		btn.TextColor3 = Color3.fromRGB(240, 238, 255)
		btn.TextSize = 8
		btn.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextYAlignment = Enum.TextYAlignment.Top
		btn.TextWrapped = true
		btn.ClipsDescendants = true
		btn.LayoutOrder = idx
		btn.Parent = ResultsScroll
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

		local btnPad = Instance.new("UIPadding")
		btnPad.PaddingTop = UDim.new(0, 4)
		btnPad.PaddingBottom = UDim.new(0, 4)
		btnPad.PaddingLeft = UDim.new(0, 6)
		btnPad.PaddingRight = UDim.new(0, 6)
		btnPad.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectMatch(idx)
			renderResults(matches)
		end)
	end
end

-- Pemindaian bertahap (yield setiap 400 objek) agar HP tidak hang/mental
local function runAsyncSearch(rawQuery: string)
	if isScanningNow then
		return
	end
	local trimmed = string.match(rawQuery, "^%s*(.-)%s*$") or ""
	if trimmed == "" then
		selectedIndex = nil
		table.clear(lastMatches)
		renderResults(lastMatches)
		StatusLabel.Text = "Masukkan ID musik / nama objek lalu tekan Cari"
		return
	end

	isScanningNow = true
	StatusLabel.Text = "Memindai '" .. trimmed .. "'..."

	task.spawn(function()
		local needleLower = string.lower(trimmed)
		local numericPart = string.match(trimmed, "%d+")
		local matches: {SearchMatch} = {}
		local checkedCount = 0

		local targets: {Instance} = { workspace, ReplicatedStorage, game:GetService("SoundService"), game:GetService("StarterGui"), game:GetService("StarterPack"), PlayerGui }
		for _, root in ipairs(targets) do
			local okDesc, descendants = pcall(function()
				return root:GetDescendants()
			end)
			if okDesc and descendants then
				for _, inst in ipairs(descendants) do
					checkedCount += 1
					if checkedCount % 400 == 0 then
						task.wait() -- Beri jeda 1 frame agar Delta mobile tidak force close
					end

					if not isIgnoredInstance(inst) and #matches < 100 then
						local objName = inst.Name
						local className = inst.ClassName
						local matched = false
						local sourceType = ""
						local detail = ""

						if string.find(string.lower(objName), needleLower, 1, true) then
							matched = true
							sourceType = "Nama (" .. className .. ")"
							detail = "Cocok pada nama"
						elseif inst:IsA("Sound") then
							local sid = tostring(inst.SoundId)
							if string.find(string.lower(sid), needleLower, 1, true)
								or (numericPart and numericPart ~= "" and string.find(sid, numericPart, 1, true)) then
								matched = true
								sourceType = "SoundId"
								detail = sid
							end
						elseif inst:IsA("StringValue") or inst:IsA("NumberValue") or inst:IsA("IntValue") then
							local valStr = tostring((inst :: any).Value)
							if string.find(string.lower(valStr), needleLower, 1, true)
								or (numericPart and numericPart ~= "" and string.find(valStr, numericPart, 1, true)) then
								matched = true
								sourceType = className .. ".Value"
								detail = valStr
							end
						else
							local okAttr, attrs = pcall(function()
								return inst:GetAttributes()
							end)
							if okAttr and type(attrs) == "table" then
								for attrName, attrVal in pairs(attrs) do
									local valStr = tostring(attrVal)
									if string.find(string.lower(valStr), needleLower, 1, true)
										or (numericPart and numericPart ~= "" and string.find(valStr, numericPart, 1, true)) then
										matched = true
										sourceType = "Attr:" .. tostring(attrName)
										detail = valStr
										break
									end
								end
							end
						end

						if matched then
							local fullName = objName
							pcall(function()
								fullName = inst:GetFullName()
							end)
							table.insert(matches, {
								objectName = objName,
								className = className,
								sourceType = sourceType,
								fullName = fullName,
								detail = detail,
							})
						end
					end
				end
			end
		end

		isScanningNow = false
		lastMatches = matches
		selectedIndex = (#matches > 0) and 1 or nil
		renderResults(matches)
		if #matches > 0 then
			selectMatch(1)
		else
			SelectedNameLabel.Text = "Terpilih: - (Tidak ada kecocokan)"
			SelectedMetaLabel.Text = "Tipe / Info: -"
			SelectedPathLabel.Text = "Path: -"
			StatusLabel.Text = string.format("'%s' • 0 cocok (%d objek dicek)", trimmed, checkedCount)
		end
		queueSaveTxt()
	end)
end

-- Monitor otomatis Console / Kick / Error (Ringan, event-based)
LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
	local entry = string.format("[%s][%s] %s", os.date("!%H:%M:%S"), messageType.Name, message)
	appendCaptureList(capturedRuntimeLogs, entry, 150)
	queueSaveTxt()
end)

-- Monitor otomatis RemoteEvent & objek baru di Workspace & ReplicatedStorage saja (tanpa scan seluruh game)
local function watchContainer(container: Instance)
	task.spawn(function()
		local okD, desc = pcall(function()
			return container:GetDescendants()
		end)
		if okD and desc then
			for i, inst in ipairs(desc) do
				if i % 500 == 0 then
					task.wait()
				end
				hookRemoteInstance(inst)
			end
		end
	end)

	container.DescendantAdded:Connect(function(desc: Instance)
		if isIgnoredInstance(desc) then return end
		hookRemoteInstance(desc)
		local summary = string.format("[NEW@%s] Name=%s | Class=%s | Path=%s",
			os.date("!%H:%M:%S"), desc.Name, desc.ClassName, desc:GetFullName())
		appendCaptureList(capturedNewInstances, summary, 150)
		queueSaveTxt()
	end)
end

watchContainer(workspace)
watchContainer(ReplicatedStorage)

ScanBtn.MouseButton1Click:Connect(function()
	runAsyncSearch(SearchBox.Text)
end)

SearchBox.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed then
		runAsyncSearch(SearchBox.Text)
	end
end)

ClearBtn.MouseButton1Click:Connect(function()
	SearchBox.Text = ""
	selectedIndex = nil
	table.clear(lastMatches)
	table.clear(capturedRuntimeLogs)
	table.clear(capturedNewInstances)
	table.clear(capturedFeatureRequests)
	SelectedNameLabel.Text = "Terpilih: - (Klik hasil di bawah)"
	SelectedMetaLabel.Text = "Tipe / Info: -"
	SelectedPathLabel.Text = "Path: -"
	StatusLabel.Text = "Riwayat dibersihkan • File: " .. SCAN_TXT_FILE
	renderResults(lastMatches)
	queueSaveTxt()
end)

renderResults(lastMatches)
queueSaveTxt()
