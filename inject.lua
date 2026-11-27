--!strict
-- ID Search Studio Lite (Delta Executor Edition) by Ikyy

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

local WINDOW_SIZE = UDim2.fromOffset(500, 300)
local WINDOW_POS = UDim2.new(0.5, -250, 0.5, -150)
local ICON_SIZE = UDim2.fromOffset(42, 42)
local ICON_DEFAULT_POS = UDim2.new(0.5, -21, 0.08, 0)
local currentIconPos = ICON_DEFAULT_POS

local function getUserAvatarAsync(userId: number): string
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	if ok and type(content) == "string" and content ~= "" then
		return content
	end
	return "rbxasset://textures/ui/GuiImagePlaceholder.png"
end

local function copyTextToClipboard(text: string): boolean
	local fn = (getgenv and getgenv().setclipboard) or (setclipboard :: any)
	if type(fn) == "function" then
		local ok = pcall(function()
			fn(text)
		end)
		return ok
	end
	return false
end

-- ==========================================
-- UI UTAMA (KHUSUS ID SEARCH)
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
HeaderBar.Parent = MainWindow

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 0, 18)
TitleLabel.Position = UDim2.new(0, 14, 0, 6)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🔎 ID & Object Search • Studio Lite"
TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = HeaderBar

local MetaLabel = Instance.new("TextLabel")
MetaLabel.Size = UDim2.new(1, -90, 0, 12)
MetaLabel.Position = UDim2.new(0, 14, 0, 24)
MetaLabel.BackgroundTransparency = 1
MetaLabel.Text = "by Ikyy • @" .. LocalPlayer.Name
MetaLabel.TextColor3 = Color3.fromRGB(120, 116, 148)
MetaLabel.TextSize = 8
MetaLabel.Font = Enum.Font.GothamMedium
MetaLabel.TextXAlignment = Enum.TextXAlignment.Left
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
-- AREA PENCARIAN & DETAIL ITEM TERPILIH
-- ==========================================
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -50)
ContentFrame.Position = UDim2.new(0, 10, 0, 44)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainWindow

local InputRow = Instance.new("Frame")
InputRow.Size = UDim2.new(1, 0, 0, 28)
InputRow.Position = UDim2.new(0, 0, 0, 0)
InputRow.BackgroundTransparency = 1
InputRow.Parent = ContentFrame

local SearchBox = Instance.new("TextBox")
SearchBox.Name = "SearchIdInput"
SearchBox.Size = UDim2.new(0.66, -4, 1, 0)
SearchBox.Position = UDim2.new(0, 0, 0, 0)
SearchBox.BackgroundColor3 = Color3.fromRGB(13, 12, 21)
SearchBox.Text = ""
SearchBox.PlaceholderText = "Masukkan ID musik / nama part / module / teks..."
SearchBox.PlaceholderColor3 = Color3.fromRGB(115, 112, 142)
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 9
SearchBox.Font = Enum.Font.GothamMedium
SearchBox.ClearTextOnFocus = false
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.Parent = InputRow
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SearchBoxStroke = Instance.new("UIStroke", SearchBox)
SearchBoxStroke.Color = Color3.fromRGB(75, 62, 130)
SearchBoxStroke.Thickness = 1

local BoxPad = Instance.new("UIPadding")
BoxPad.PaddingLeft = UDim.new(0, 8)
BoxPad.PaddingRight = UDim.new(0, 8)
BoxPad.Parent = SearchBox

local ScanBtn = Instance.new("TextButton")
ScanBtn.Name = "ScanBtn"
ScanBtn.Size = UDim2.new(0.18, -4, 1, 0)
ScanBtn.Position = UDim2.new(0.66, 2, 0, 0)
ScanBtn.BackgroundColor3 = Color3.fromRGB(108, 86, 245)
ScanBtn.Text = "Cari"
ScanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ScanBtn.TextSize = 9
ScanBtn.Font = Enum.Font.GothamBold
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
ClearBtn.Parent = InputRow
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 14)
StatusLabel.Position = UDim2.new(0, 0, 0, 31)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ketik ID musik / nama objek lalu tekan Cari. Klik hasil untuk memilih."
StatusLabel.TextColor3 = Color3.fromRGB(155, 152, 188)
StatusLabel.TextSize = 8
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextTruncate = Enum.TextTruncate.AtEnd
StatusLabel.Parent = ContentFrame

-- Panel Detail Item Terpilih (Nama Objek, Kelas, Tipe, Path Lengkap)
local SelectedBox = Instance.new("Frame")
SelectedBox.Name = "SelectedDetailBox"
SelectedBox.Size = UDim2.new(1, 0, 0, 56)
SelectedBox.Position = UDim2.new(0, 0, 0, 47)
SelectedBox.BackgroundColor3 = Color3.fromRGB(21, 19, 34)
SelectedBox.BorderSizePixel = 0
SelectedBox.Parent = ContentFrame
Instance.new("UICorner", SelectedBox).CornerRadius = UDim.new(0, 7)
local SelStroke = Instance.new("UIStroke", SelectedBox)
SelStroke.Color = Color3.fromRGB(92, 72, 168)
SelStroke.Thickness = 1

local SelectedNameLabel = Instance.new("TextLabel")
SelectedNameLabel.Size = UDim2.new(1, -14, 0, 16)
SelectedNameLabel.Position = UDim2.new(0, 7, 0, 4)
SelectedNameLabel.BackgroundTransparency = 1
SelectedNameLabel.Text = "Terpilih: - (Belum ada item dipilih)"
SelectedNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectedNameLabel.TextSize = 9
SelectedNameLabel.Font = Enum.Font.GothamBold
SelectedNameLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedNameLabel.Parent = SelectedBox

local SelectedMetaLabel = Instance.new("TextLabel")
SelectedMetaLabel.Size = UDim2.new(1, -14, 0, 13)
SelectedMetaLabel.Position = UDim2.new(0, 7, 0, 20)
SelectedMetaLabel.BackgroundTransparency = 1
SelectedMetaLabel.Text = "Tipe / Info: -"
SelectedMetaLabel.TextColor3 = Color3.fromRGB(165, 195, 255)
SelectedMetaLabel.TextSize = 8
SelectedMetaLabel.Font = Enum.Font.GothamMedium
SelectedMetaLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedMetaLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedMetaLabel.Parent = SelectedBox

local SelectedPathLabel = Instance.new("TextLabel")
SelectedPathLabel.Size = UDim2.new(1, -14, 0, 14)
SelectedPathLabel.Position = UDim2.new(0, 7, 0, 36)
SelectedPathLabel.BackgroundTransparency = 1
SelectedPathLabel.Text = "Path: -"
SelectedPathLabel.TextColor3 = Color3.fromRGB(185, 182, 212)
SelectedPathLabel.TextSize = 8
SelectedPathLabel.Font = Enum.Font.RobotoMono
SelectedPathLabel.TextXAlignment = Enum.TextXAlignment.Left
SelectedPathLabel.TextTruncate = Enum.TextTruncate.AtEnd
SelectedPathLabel.Parent = SelectedBox

-- Daftar Hasil Pencarian
local ResultsScroll = Instance.new("ScrollingFrame")
ResultsScroll.Size = UDim2.new(1, 0, 1, -110)
ResultsScroll.Position = UDim2.new(0, 0, 0, 109)
ResultsScroll.BackgroundColor3 = Color3.fromRGB(12, 11, 18)
ResultsScroll.BorderSizePixel = 0
ResultsScroll.ScrollBarThickness = 3
ResultsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
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

local lastMatches: {SearchMatch} = {}
local selectedIndex: number? = nil

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

local function selectMatch(idx: number)
	local item = lastMatches[idx]
	if not item then return end
	selectedIndex = idx

	SelectedNameLabel.Text = string.format("Nama: %s  [%s]", item.objectName, item.className)
	SelectedMetaLabel.Text = string.format("Sumber: %s • %s", item.sourceType, item.detail)
	SelectedPathLabel.Text = "Path: " .. item.fullName

	local copied = copyTextToClipboard(item.fullName)
	if copied then
		StatusLabel.Text = "Dipilih #" .. tostring(idx) .. " (" .. item.objectName .. ") • Path disalin"
	else
		StatusLabel.Text = "Dipilih #" .. tostring(idx) .. " (" .. item.objectName .. ")"
	end

	print(string.format("[IDSearch][SELECT #%d] Nama=%s | Class=%s | Tipe=%s | Path=%s | Detail=%s",
		idx, item.objectName, item.className, item.sourceType, item.fullName, item.detail))
end

local function renderResults(matches: {SearchMatch})
	for _, child in ipairs(ResultsScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	if #matches == 0 then
		local emptyBtn = Instance.new("TextButton")
		emptyBtn.Size = UDim2.new(1, -4, 0, 24)
		emptyBtn.BackgroundColor3 = Color3.fromRGB(22, 21, 34)
		emptyBtn.Text = "  Tidak ada objek / part / module / sound yang cocok"
		emptyBtn.TextColor3 = Color3.fromRGB(165, 162, 190)
		emptyBtn.TextSize = 8
		emptyBtn.Font = Enum.Font.GothamMedium
		emptyBtn.TextXAlignment = Enum.TextXAlignment.Left
		emptyBtn.LayoutOrder = 1
		emptyBtn.Parent = ResultsScroll
		Instance.new("UICorner", emptyBtn).CornerRadius = UDim.new(0, 5)
		return
	end

	for idx, item in ipairs(matches) do
		local isSelected = (idx == selectedIndex)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -4, 0, 30)
		btn.BackgroundColor3 = isSelected and Color3.fromRGB(52, 46, 86) or Color3.fromRGB(22, 21, 34)
		btn.Text = string.format("  #%d  %s [%s]\n      %s • %s", idx, item.objectName, item.className, item.sourceType, item.detail)
		btn.TextColor3 = Color3.fromRGB(240, 238, 255)
		btn.TextSize = 8
		btn.Font = isSelected and Enum.Font.GothamBold or Enum.Font.GothamMedium
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.LayoutOrder = idx
		btn.Parent = ResultsScroll
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

		btn.MouseButton1Click:Connect(function()
			selectMatch(idx)
			renderResults(matches)
		end)
	end
end

local function runSearch(rawQuery: string)
	local trimmed = string.match(rawQuery, "^%s*(.-)%s*$") or ""
	selectedIndex = nil
	SelectedNameLabel.Text = "Terpilih: - (Klik salah satu hasil di bawah)"
	SelectedMetaLabel.Text = "Tipe / Info: -"
	SelectedPathLabel.Text = "Path: -"

	if trimmed == "" then
		table.clear(lastMatches)
		renderResults(lastMatches)
		StatusLabel.Text = "Masukkan kata kunci atau ID musik terlebih dahulu"
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

				-- 1. Cek nama Part / Folder / ModuleScript / Script / Model / dll.
				if string.find(nameLower, needleLower, 1, true) then
					matched = true
					sourceType = "Nama (" .. className .. ")"
					detail = "Nama objek cocok"
				end

				-- 2. Cek Sound.SoundId
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

				-- 3. Cek ValueObject (StringValue / NumberValue / IntValue / ObjectValue)
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

				-- 4. Cek Attributes pada objek
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

				-- 5. Cek TextBox / TextLabel non-UI editor
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
	StatusLabel.Text = string.format("'%s' • %d cocok (%d objek dicek)", trimmed, #matches, checkedCount)
	renderResults(matches)
	if #matches > 0 then
		selectMatch(1)
		renderResults(matches)
	end
end

ScanBtn.MouseButton1Click:Connect(function()
	runSearch(SearchBox.Text)
end)

SearchBox.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed then
		runSearch(SearchBox.Text)
	end
end)

ClearBtn.MouseButton1Click:Connect(function()
	SearchBox.Text = ""
	selectedIndex = nil
	table.clear(lastMatches)
	SelectedNameLabel.Text = "Terpilih: - (Belum ada item dipilih)"
	SelectedMetaLabel.Text = "Tipe / Info: -"
	SelectedPathLabel.Text = "Path: -"
	StatusLabel.Text = "Hasil dibersihkan • Masukkan kata kunci lalu tekan Cari"
	renderResults(lastMatches)
end)

renderResults(lastMatches)
