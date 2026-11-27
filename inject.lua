--!strict
-- ID, Feature Request & Playtest Scanner Studio Lite (Delta Executor Edition) by Ikyy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")

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

local WINDOW_SIZE = UDim2.fromOffset(500, 304)
local WINDOW_POS = UDim2.new(0.5, -250, 0.5, -152)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS
local SCAN_FOLDER = "IkyyStudioLite"
local SCAN_TXT_FILE = SCAN_FOLDER .. "/playtest_scan_log.txt"

local function getUserAvatarAsync(userId: number): string
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and type(content) == "string" and content ~= "" then
		return content
	end
	return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

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
	local limit = math.min(#args, 4)
	for i = 1, limit do
		local v = args[i]
		local t = typeof(v)
		if t == "Instance" then
			local n = v.Name
			pcall(function()
				n = v:GetFullName()
			end)
			table.insert(parts, string.format("Instance(%s)", n))
		elseif t == "string" then
			local s = tostring(v)
			if #s > 40 then
				s = string.sub(s, 1, 40) .. "..."
			end
			table.insert(parts, string.format("%q", s))
		elseif t == "table" then
			table.insert(parts, "table")
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
FloatingProfileBtn.Image = getUserAvatarAsync(LocalPlayer.UserId)
FloatingProfileBtn.Parent = ScreenGui

Instance.new("UICner", FloatingProfileBtn).CornerRadius = UDim.new(1, 0)
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
HeaderBar.Size = UDim2.new(1, 0, 0, 42)
HeaderBar.BackgroundColor3 = Color3.fromRGB(20, 19, 30)
HeaderBar.BackgroundTransparency = 0.25
HeaderBar.BorderSizePixel = 0
HeaderBar.ClipsDescendants = true
HeaderBar.Parent = MainWindow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 0, 18)
TitleLabel.Position = UDim2.new(0, 14, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔎 ID, Feature & Playtest Scanner"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(1, -90, 0, 12)
MetaLabel.Position = UDim2.new(0, 14, 0, 24)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "by Ikyy • Auto-Save TXT + Req Hook • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(120, 116, 148)
MetaLabel.TextSize = 8
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
MetaLabel.TextTruncate = Enum.TextTruncate.AtEnd
MetaLabel.Parent = HeaderBar

local CloseCircleBtn = Instance.new("TextButton")
CloseCircleBtn.Name = "CloseToCircleBtn"
CloseCircleBtn.Size = UDim2.fromOffset(26, 26)
CloseCircleBtn.Position = UDim2.new(1, -38, 0.5, -13)
CloseCircleBtn.BackgroundColor3 = Color3.fromRGB(34, 32, 50)
CloseCircleBtn.Text = "✕"
CloseCircleBtn.TextColor3 = Color3.fromRGB(255, 110, 125)
CloseCircleBtn.TextSize = 11
CloseCircleBtn.Font = Enum.Font.GothamBold
CloseCircleBtn.Parent = HeaderBar
Instance.new("UICorner", CloseCircleBtn).CornerRadius = UDim.new(1, 0)

local function setMinimized(minimized: boolean)
	if minimized then
		local tw = TweenService:Create(MainWindow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = ICON_SIZE,
			Position = currentIconPos,
		})
		tw:Play()
		tw.Completed:Connect(function()
			if MainWindow.Size == ICON_SIZE then
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
-- KONTEN UTAMA (ANTI-OVERFLOW TEKS)
-- ==========================================
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 44)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = true
ContentFrame.Parent = MainWindow

local InputRow = Instance.new("Frame")
InputRow.Size = UDim2.new(1, 0, 0, 26)
InputRow.Position = UDim2.new(0, 0, 0, 0)
InputRow.BackgroundTransparency = 1
InputRow.ClipsDescendants = true
InputRow.Parent = ContentFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchIdInput"
SearchBox.Size = UDim2.new(0.56, -4, 1, 0)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(13, 12, 21)
SearchBox.Text = ""
SearchBox.PlaceholderText = "ID musik / nama objek / teks..."
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
ScanBtn.Size = UDim2.new(0.14, -3, 1, 0)
ScanBtn.Position = UDim2.new(0.56, 2, 0, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ScanBtn.Text = "Cari"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.TextSize = 8
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.ClipsDescendants = true
ScanBtn.Parent = InputRow
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 6)

local PlayScanBtn = Instance.new("TextButton")
PlayScanBtn.Name = "PlayScanBtn"
PlayScanBtn.Size = UDim2.new(0.17, -3, 1, 0)
PlayScanBtn.Position = UDim2.new(0.70, 2, 0, 0)
PlayScanBtn.BackgroundColor3 = Color3.fromRGB(34, 92, 68)
PlayScanBtn.Text = "▶ Scan"
PlayScanBtn.TextColor3 = Color3.fromRGB(220, 255, 235)
PlayScanBtn.TextSize = 8
PlayScanBtn.Font = Enum.Font.GothamBold
PlayScanBtn.ClipsDescendants = true
PlayScanBtn.Parent = InputRow
Instance.new("UICorner", PlayScanBtn).CornerRadius = UDim.new(0, 6)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Name = "ClearBtn"
ClearBtn.Size = UDim2.new(0.13, 0, 1, 0)
ClearBtn.Position = UDim2.new(0.87, 2, 0, 0)
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
StatusLabel.Text = "File TXT: " .. SCAN_TXT_FILE .. " • Tekan ▶ Scan untuk hook aman"
StatusLabel.TextColor3 = Color3.fromRGB(155, 152, 188)
StatusLabel.TextSize = 8
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.ClipsDescendants = true
StatusLabel.Parent = ContentFrame

local SelectedBox = Instance.new("ScrollingFrame")
SelectedBox.Name = "SelectedDetailBox"
SelectedBox.Size = UDim2.new(1, 0, 0, 62)
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
ResultsScroll.Size = UDim2.new(1, 0, 1, -113)
ResultsScroll.Position = UDim2.new(0, 0, 0, 112)
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
-- LOGIKA SCAN, FEATURE REQUEST HOOK & AUTO-SAVE TXT
-- ==========================================
local lastMatches: {SearchMatch} = {}
local selectedIndex: number? = nil
local playScanActive = false
local namecallHookInstalled = false
local capturedRuntimeLogs: {string} = {}
local capturedNewInstances: {string} = {}
local capturedFeatureRequests: {string} = {}
local hookedRemotes: {[Instance]: boolean} = {}
local lastSavedSnapshot = ""

local function appendCaptureList(list: {string}, line: string, maxItems: number)
	table.insert(list, line)
	if #list > maxItems then
		table.remove(list, 1)
	end
end

local function isIgnoredStudioOrPluginInstance(inst: Instance): boolean
	if inst == ScreenGui or inst:IsDescendantOf(ScreenGui) then
		return true
	end
	local full = ""
	local ok, res = pcall(function()
		return inst:GetFullName()
	end)
	if ok and type(res) == "string" then
		full = res
	end
	if string.find(full, "StudioGui", 1, true) then
		return true
	end
	return false
end

local function formatInstanceSummary(inst: Instance, tag: string): string
	local objName = inst.Name
	local className = inst.ClassName
	local fullName = objName
	local okFull, fullRes = pcall(function()
		return inst:GetFullName()
	end)
	if okFull and type(fullRes) == "string" then
		fullName = fullRes
	end

	local extra = ""
	if inst:IsA("Sound") then
		local okId, sid = pcall(function()
			return tostring(inst.SoundId)
		end)
		if okId then
			extra = " | SoundId=" .. sid
		end
	elseif inst:IsA("StringValue") or inst:IsA("NumberValue") or inst:IsA("IntValue") then
		local okVal, val = pcall(function()
			return tostring((inst :: any).Value)
		end)
		if okVal then
			extra = " | Value=" .. val
		end
	end

	return string.format("[%s] Name=%s | Class=%s | Path=%s%s", tag, objName, className, fullName, extra)
end

local function buildTxtReport(queryText: string): string
	local lines: {string} = {
		"=== IKYY STUDIO LITE • PLAYTEST, REQUEST & ID SCAN LOG ===",
		"Timestamp   : " .. os.date("!%Y-%m-%d %H:%M:%S UTC"),
		"Player      : " .. LocalPlayer.Name .. " (" .. tostring(LocalPlayer.UserId) .. ")",
		"PlaceId     : " .. tostring(game.PlaceId),
		"Query Filter: " .. (queryText ~= "" and queryText or "(Semua / Playtest Monitor)"),
		"PlayScan    : " .. (playScanActive and "ACTIVE" or "IDLE"),
		"",
		"--- PROSES PERMINTAAN FITUR / SISTEM (" .. tostring(#capturedFeatureRequests) .. ") ---",
	}

	if #capturedFeatureRequests == 0 then
		table.insert(lines, "(Belum ada permintaan Remote/Bindable terekam saat playtest)")
	else
		for _, reqLine in ipairs(capturedFeatureRequests) do
			table.insert(lines, reqLine)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "--- HASIL SCAN OBJEK / ID (" .. tostring(#lastMatches) .. ") ---")
	if #lastMatches == 0 then
		table.insert(lines, "(Tidak ada kecocokan objek/ID pada scan terakhir)")
	else
		for i, m in ipairs(lastMatches) do
			table.insert(lines, string.format("#%d | Name=%s | Class=%s | Type=%s | Path=%s | Detail=%s",
				i, m.objectName, m.className, m.sourceType, m.fullName, m.detail))
		end
	end

	table.insert(lines, "")
	table.insert(lines, "--- OBJEK BARU SAAT PLAYTEST (" .. tostring(#capturedNewInstances) .. ") ---")
	if #capturedNewInstances == 0 then
		table.insert(lines, "(Belum ada objek baru terdeteksi saat playtest)")
	else
		for _, entry in ipairs(capturedNewInstances) do
			table.insert(lines, entry)
		end
	end

	table.insert(lines, "")
	table.insert(lines, "--- CONSOLE / KICK / ERROR LOG (" .. tostring(#capturedRuntimeLogs) .. ") ---")
	if #capturedRuntimeLogs == 0 then
		table.insert(lines, "(Belum ada log konsol terekam)")
	else
		for _, logLine in ipairs(capturedRuntimeLogs) do
			table.insert(lines, logLine)
		end
	end

	return table.concat(lines, "\n")
end

local function saveSnapshotToTxt(queryText: string, forceSave: boolean): boolean
	local report = buildTxtReport(queryText)
	if not forceSave and report == lastSavedSnapshot then
		return false
	end
	lastSavedSnapshot = report
	local saved = writeScanTxt(report)
	if saved then
		print("[StudioLiteTXT] Tersimpan otomatis ke -> " .. SCAN_TXT_FILE)
	else
		print("[StudioLiteTXT] Executor tanpa writefile; ringkasan log dicetak ke console:")
		print(report)
	end
	return saved
end

local function wrapRemoteFunctionCallback(rf: RemoteFunction, origFn: ((...any) -> ...any)?): (...any) -> ...any
	local hookFuncFn = getExecutorFunc("hookfunction")
	local wrapped: (...any) -> ...any = function(...: any): ...any
		local args = { ... }
		if playScanActive and not isIgnoredStudioOrPluginInstance(rf) then
			local full = rf.Name
			pcall(function()
				full = rf:GetFullName()
			end)
			local line = string.format("[%s][RemoteFunction:OnClientInvoke] %s args=%s",
				os.date("!%H:%M:%S"), full, safeArgSummary(args))
			appendCaptureList(capturedFeatureRequests, line, 200)
			saveSnapshotToTxt(SearchBox.Text, false)
		end

		if type(origFn) == "function" then
			return (origFn :: any)(table.unpack(args))
		end
		return nil
	end

	if type(hookFuncFn) == "function" and type(origFn) == "function" then
		local okHook, hooked = pcall(function()
			return hookFuncFn(origFn, wrapped)
		end)
		if okHook and type(hooked) == "function" then
			return origFn
		end
	end

	return wrapped
end

local function attachOnClientInvokeHook(rf: RemoteFunction)
	local existingCallback: ((...any) -> ...any)? = nil
	pcall(function()
		existingCallback = rf.OnClientInvoke
	end)

	local hookedHandler = wrapRemoteFunctionCallback(rf, existingCallback)
	pcall(function()
		rf.OnClientInvoke = hookedHandler
	end)
end

local function hookRemoteInstance(inst: Instance)
	if hookedRemotes[inst] or isIgnoredStudioOrPluginInstance(inst) then
		return
	end
	if inst:IsA("RemoteEvent") then
		hookedRemotes[inst] = true
		pcall(function()
			inst.OnClientEvent:Connect(function(...: any)
				if not playScanActive then return end
				local full = inst.Name
				pcall(function()
					full = inst:GetFullName()
				end)
				local line = string.format("[%s][RemoteEvent:OnClientEvent] %s args=%s",
					os.date("!%H:%M:%S"), full, safeArgSummary({ ... }))
				appendCaptureList(capturedFeatureRequests, line, 200)
				saveSnapshotToTxt(SearchBox.Text, false)
			end)
		end)
	elseif inst:IsA("BindableEvent") then
		hookedRemotes[inst] = true
		pcall(function()
			inst.Event:Connect(function(...: any)
				if not playScanActive then return end
				local full = inst.Name
				pcall(function()
					full = inst:GetFullName()
				end)
				local line = string.format("[%s][BindableEvent] %s args=%s",
					os.date("!%H:%M:%S"), full, safeArgSummary({ ... }))
				appendCaptureList(capturedFeatureRequests, line, 200)
				saveSnapshotToTxt(SearchBox.Text, false)
			end)
		end)
	elseif inst:IsA("RemoteFunction") then
		hookedRemotes[inst] = true
		attachOnClientInvokeHook(inst)
		pcall(function()
			inst:GetPropertyChangedSignal("OnClientInvoke"):Connect(function()
				local currentCb: ((...any) -> ...any)? = nil
				pcall(function()
					currentCb = inst.OnClientInvoke
				end)
				if type(currentCb) == "function" then
					local nextCb = wrapRemoteFunctionCallback(inst, currentCb)
					if nextCb ~= currentCb then
						pcall(function()
							inst.OnClientInvoke = nextCb
						end)
					end
				end
			end)
		end)
	end
end

-- Dipasang hanya saat ▶ Scan ditekan agar tidak memancing detektor namecall saat idle
local function ensureNamecallHook()
	if namecallHookInstalled then
		return
	end
	local hookMetaFn = getExecutorFunc("hookmetamethod")
	local getNamecallFn = getExecutorFunc("getnamecallmethod")
	local checkCallerFn = getExecutorFunc("checkcaller")

	if type(hookMetaFn) == "function" and type(getNamecallFn) == "function" then
		local ok = pcall(function()
			local oldNamecall: any
			oldNamecall = hookMetaFn(game, "__namecall", function(self: any, ...: any)
				local args = { ... }
				if playScanActive and typeof(self) == "Instance" and not isIgnoredStudioOrPluginInstance(self) then
					local okM, method = pcall(getNamecallFn)
					if okM and (method == "FireServer" or method == "InvokeServer" or method == "Fire" or method == "Invoke") then
						local isExec = false
						if type(checkCallerFn) == "function" then
							local okC, resC = pcall(checkCallerFn)
							isExec = (okC and resC == true)
						end
						if not isExec then
							local full = tostring(self.Name)
							pcall(function()
								full = self:GetFullName()
							end)
							local line = string.format("[%s][REQ:GAME/%s] %s args=%s",
								os.date("!%H:%M:%S"), tostring(method), full, safeArgSummary(args))
							appendCaptureList(capturedFeatureRequests, line, 200)
						end
					end
				end
				return oldNamecall(self, table.unpack(args))
			end)
		end)
		if ok then
			namecallHookInstalled = true
		end
	end
end

local function attachExistingRemoteListeners()
	local targets: {Instance} = {
		workspace,
		game:GetService("ReplicatedStorage"),
		Players,
	}
	for _, root in ipairs(targets) do
		local okD, desc = pcall(function()
			return root:GetDescendants()
		end)
		if okD and desc then
			for _, inst in ipairs(desc) do
				hookRemoteInstance(inst)
			end
		end
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
	local txtSaved = saveSnapshotToTxt(SearchBox.Text, false)
	local extraMsg = copied and " • Path disalin" or ""
	if txtSaved then
		extraMsg = extraMsg .. " • TXT tersimpan"
	end
	StatusLabel.Text = "Dipilih #" .. tostring(idx) .. " (" .. item.objectName .. ")" .. extraMsg
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
		emptyBtn.Text = "  Belum ada hasil cocok (atau tekan ▶ Scan saat playtest)"
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
		btn.Size = UDim2.new(1, -4, 0, 34)
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

local function runSearch(rawQuery: string, autoSaveTxt: boolean)
	local trimmed = string.match(rawQuery, "^%s*(.-)%s*$") or ""
	selectedIndex = nil
	SelectedNameLabel.Text = "Terpilih: - (Klik salah satu hasil di bawah)"
	SelectedMetaLabel.Text = "Tipe / Info: -"
	SelectedPathLabel.Text = "Path: -"

	if trimmed == "" then
		table.clear(lastMatches)
		renderResults(lastMatches)
		StatusLabel.Text = "Ketik ID musik / nama objek lalu tekan Cari"
		if autoSaveTxt then
			saveSnapshotToTxt("", false)
		end
		return
	end

	local needleLower = string.lower(trimmed)
	local numericPart = string.match(trimmed, "%d+")
	local matches: {SearchMatch} = {}
	local checkedCount = 0

	local okDesc, descendants = pcall(function()
		return game:GetDescendants()
	end)

	if okDesc and descendants then
		for _, inst in ipairs(descendants) do
			if not isIgnoredStudioOrPluginInstance(inst) then
				checkedCount += 1

				local objName = inst.Name
				local className = inst.ClassName
				local fullName = objName
				local okFull, fullRes = pcall(function()
					return inst:GetFullName()
				end)
				if okFull and type(fullRes) == "string" then
					fullName = fullRes
				end

				local nameLower = string.lower(objName)
				local matched = false
				local sourceType = "Nama Objek"
				local detail = "Class: " .. className

				if string.find(nameLower, needleLower, 1, true) then
					matched = true
					sourceType = "Nama (" .. className .. ")"
					detail = "Nama objek cocok"
				end

				if not matched then
					local okSound, isSound = pcall(function()
						return inst:IsA("Sound")
					end)
					if okSound and isSound then
						local okId, sid = pcall(function()
							return tostring(inst.SoundId)
						end)
						if okId then
							if string.find(string.lower(sid), needleLower, 1, true)
								or (numericPart and numericPart ~= "" and string.find(sid, numericPart, 1, true)) then
								matched = true
								sourceType = "SoundId"
								detail = sid
							end
						end
					end
				end

				if not matched then
					if inst:IsA("StringValue") or inst:IsA("NumberValue") or inst:IsA("IntValue") then
						local okVal, valStr = pcall(function()
							return tostring((inst :: any).Value)
						end)
						if okVal and (string.find(string.lower(valStr), needleLower, 1, true)
							or (numericPart and numericPart ~= "" and string.find(valStr, numericPart, 1, true))) then
							matched = true
							sourceType = className .. ".Value"
							detail = "Value: " .. valStr
						end
					end
				end

				if not matched then
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

				if not matched then
					if inst:IsA("TextBox") or inst:IsA("TextLabel") then
						local okTxt, txtVal = pcall(function()
							return tostring(inst.Text)
						end)
						if okTxt and (string.find(string.lower(txtVal), needleLower, 1, true)
							or (numericPart and numericPart ~= "" and string.find(txtVal, numericPart, 1, true))) then
							matched = true
							sourceType = className .. ".Text"
							detail = txtVal
						end
					end
				end

				if matched then
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

	lastMatches = matches
	renderResults(matches)
	if #matches > 0 then
		selectMatch(1)
		renderResults(matches)
	else
		StatusLabel.Text = string.format("'%s' • 0 cocok (%d objek dicek)", trimmed, checkedCount)
		if autoSaveTxt then
			saveSnapshotToTxt(trimmed, false)
		end
	end
end

LogService.MessageOut:Connect(function(message: string, messageType: Enum.MessageType)
	if not playScanActive then return end
	local entry = string.format("[%s][%s] %s", os.date("!%H:%M:%S"), messageType.Name, message)
	appendCaptureList(capturedRuntimeLogs, entry, 200)
	saveSnapshotToTxt(SearchBox.Text, false)
end)

game.DescendantAdded:Connect(function(desc: Instance)
	if not playScanActive then return end
	hookRemoteInstance(desc)
	if isIgnoredStudioOrPluginInstance(desc) then return end
	task.defer(function()
		if not playScanActive then return end
		local summary = formatInstanceSummary(desc, "NEW@" .. os.date("!%H:%M:%S"))
		appendCaptureList(capturedNewInstances, summary, 200)
		saveSnapshotToTxt(SearchBox.Text, false)
	end)
end)

do
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if not playScanActive then return end
		acc += dt
		if acc >= 2.0 then
			acc = 0
			saveSnapshotToTxt(SearchBox.Text, false)
		end
	end)
end

LocalPlayer.OnTeleport:Connect(function()
	appendCaptureList(capturedRuntimeLogs, string.format("[%s][TELEPORT] LocalPlayer.OnTeleport triggered", os.date("!%H:%M:%S")), 200)
	saveSnapshotToTxt(SearchBox.Text, true)
end)

ScanBtn.MouseButton1Click:Connect(function()
	runSearch(SearchBox.Text, true)
end)

SearchBox.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed then
		runSearch(SearchBox.Text, true)
	end
end)

PlayScanBtn.MouseButton1Click:Connect(function()
	playScanActive = not playScanActive
	if playScanActive then
		ensureNamecallHook()
		attachExistingRemoteListeners()
		PlayScanBtn.Text = "⏹ Stop"
		PlayScanBtn.BackgroundColor3 = Color3.fromRGB(165, 45, 65)
		local q = string.match(SearchBox.Text, "^%s*(.-)%s*$") or ""
		if q ~= "" then
			runSearch(q, false)
		end
		saveSnapshotToTxt(SearchBox.Text, true)
		StatusLabel.Text = "PlayScan ON • " .. SCAN_TXT_FILE
	else
		PlayScanBtn.Text = "▶ Scan"
		PlayScanBtn.BackgroundColor3 = Color3.fromRGB(34, 92, 68)
		saveSnapshotToTxt(SearchBox.Text, true)
		StatusLabel.Text = "PlayScan OFF • Tersimpan ke " .. SCAN_TXT_FILE
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
	StatusLabel.Text = "Hasil & log dibersihkan • File: " .. SCAN_TXT_FILE
	renderResults(lastMatches)
end)

renderResults(lastMatches)
