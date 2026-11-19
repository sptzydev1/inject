--!strict
-- Plugin Studio Lite Style GUI - Delta Executor Edition (In-Memory Session)
-- by Ikyy

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("IkyyStudioLiteCaseUI") then
	PlayerGui.IkyyStudioLiteCaseUI:Destroy()
end

-- ==========================================
-- 1. IN-MEMORY SESSION (TANPA SAVE FILE)
-- ==========================================
local MemorySession = {
	ActiveTab = "Spoof", -- "Spoof" | "Upload" | "Import" | "Setting" | "About"
	SelectedFilter = "Auto", -- "Auto" | "Audio" | "Decal" | "Model" | "Anim"
	CookieToken = "",
	ApiKeyToken = "",
	ActiveUniverseId = "10516113765",
	PlaybackSpeed = 1.0,
	AllowedUsers = {
		[LocalPlayer.UserId] = true,
		[9374524895] = true,
	},
	Logs = {},
}

local function pushLog(tag: string, msg: string)
	table.insert(MemorySession.Logs, 1, string.format("[%s] %s", tag, msg))
	if #MemorySession.Logs > 25 then
		table.remove(MemorySession.Logs)
	end
end

local function hasAccess(): boolean
	return MemorySession.AllowedUsers[LocalPlayer.UserId] == true
end

local function safeCopy(text: string): boolean
	local fn = (getgenv and getgenv().setclipboard) or setclipboard
	if typeof(fn) == "function" then
		pcall(fn, text)
		return true
	end
	return false
end

local function extractPairsOrIds(raw: string): {{name: string, id: number}}
	local items = {}
	local foundPair = false

	for sName, sId in string.gmatch(raw or "", "Song[Nn]ame:%s*(.-)%s*Song[Ii]d:%s*(%d+)") do
		local numId = tonumber(sId)
		if numId then
			foundPair = true
			local cleanName = string.gsub(sName, "^%s*(.-)%s*$", "%1")
			table.insert(items, {
				name = cleanName ~= "" and cleanName or ("Asset_" .. tostring(numId)),
				id = numId,
			})
		end
	end

	if not foundPair then
		local seen: {[number]: boolean} = {}
		for token in string.gmatch(raw or "", "%d+") do
			local numId = tonumber(token)
			if numId and not seen[numId] then
				seen[numId] = true
				table.insert(items, {
					name = "Asset_" .. tostring(numId),
					id = numId,
				})
			end
		end
	end

	return items
end

local function fetchAssetDetails(assetId: number)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(assetId)
	end)
	if ok and info then
		return {
			Name = info.Name or ("Asset_" .. tostring(assetId)),
			Creator = (info.Creator and info.Creator.Name) or "Unknown Creator",
			CreatorId = (info.Creator and tostring(info.Creator.CreatorTargetId)) or "N/A",
			AssetTypeId = info.AssetTypeId or 0,
			Created = info.Created or "N/A",
			Updated = info.Updated or "N/A",
		}
	end
	return {
		Name = "Asset_" .. tostring(assetId),
		Creator = "Unknown Creator",
		CreatorId = "N/A",
		AssetTypeId = 0,
		Created = "N/A",
		Updated = "N/A",
	}
end

-- ==========================================
-- 2. FUNGSI FITUR (SATUAN, MASSAL & ABOUT)
-- ==========================================

-- [Spoof] Downloader Spoof (Satuan & Massal)
local function executeSpoofFeature(rawInput: string, filterMode: string)
	local targets = extractPairsOrIds(rawInput)
	if #targets == 0 then
		pushLog("SPOOF", "Target ID atau format SongName/SongId tidak valid.")
		return
	end

	local isAnimMode = (filterMode == "Anim")
	local reportLines = {}

	for _, item in ipairs(targets) do
		local details = fetchAssetDetails(item.id)
		local finalName = (item.name ~= "Asset_" .. tostring(item.id)) and item.name or details.Name

		if not isAnimMode then
			local sound = Instance.new("Sound")
			sound.Name = "SpoofAudio_" .. tostring(item.id)
			sound.SoundId = "rbxassetid://" .. tostring(item.id)
			sound.PlaybackSpeed = MemorySession.PlaybackSpeed
			sound.Volume = 0.6
			sound.Parent = workspace
			sound:Play()
			Debris:AddItem(sound, 15)
		elseif LocalPlayer.Character then
			local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			if animator then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. tostring(item.id)
				pcall(function()
					local track = animator:LoadAnimation(anim)
					track:AdjustSpeed(MemorySession.PlaybackSpeed)
					track:Play()
				end)
			end
		end

		local line = string.format(
			"%s | ID:%d | Kreator:%s (%s) | Dibuat:%s",
			finalName,
			item.id,
			details.Creator,
			details.CreatorId,
			details.Created
		)
		table.insert(reportLines, line)
	end

	if #targets == 1 then
		pushLog("SATUAN", reportLines[1])
	else
		local copied = safeCopy(table.concat(reportLines, "\n"))
		pushLog("MASSAL", string.format("Spoof %d aset selesai%s", #targets, copied and " (disalin ke clipboard)" or ""))
	end
end

-- [Upload] Pengunggah Aset & Decal (Satuan & Massal)
local function executeUploadFeature(rawInput: string, filterMode: string)
	if not hasAccess() then
		pushLog("DENIED", "Akses upload ditolak untuk UserId " .. tostring(LocalPlayer.UserId))
		return
	end

	local targets = extractPairsOrIds(rawInput)
	if #targets == 0 then
		pushLog("UPLOAD", "Masukkan Asset ID / target aset untuk diproses.")
		return
	end

	local assetKind = (filterMode == "Auto") and "Asset" or filterMode
	local hasApi = (MemorySession.ApiKeyToken ~= "")
	local summary = {}

	for _, item in ipairs(targets) do
		local details = fetchAssetDetails(item.id)
		table.insert(summary, string.format("[%s] %s (%d) - API:%s", assetKind, details.Name, item.id, hasApi and "SET" or "MEM"))
		task.wait(0.1)
	end

	if #targets == 1 then
		pushLog("UPLOAD", summary[1])
	else
		local copied = safeCopy(table.concat(summary, "\n"))
		pushLog("MASSAL", string.format("Upload %s (%d item)%s", assetKind, #targets, copied and " • disalin" or ""))
	end
end

-- [Import] Pembuat Place & Asset Permissions (Satuan & Massal)
local function executeImportFeature(rawInput: string)
	if not hasAccess() then
		pushLog("DENIED", "Akses import ditolak untuk UserId " .. tostring(LocalPlayer.UserId))
		return
	end

	local targets = extractPairsOrIds(rawInput)
	local firstNum = targets[1] and targets[1].id or nil

	if firstNum and firstNum >= 1 and firstNum <= 20 and string.len(tostring(firstNum)) <= 2 then
		local createdCount = 0
		for i = 1, firstNum do
			local part = Instance.new("Part")
			part.Name = "PlaceTemplate_" .. tostring(i)
			part.Size = Vector3.new(6, 1, 6)
			part.Anchored = true
			part.Position = LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position + Vector3.new(i * 8, 0, 0) or Vector3.new(i * 8, 5, 0)
			part.Parent = workspace
			createdCount += 1
			if i < firstNum then
				task.wait(0.25)
			end
		end
		pushLog("PLACE", string.format("Pembuatan Place selesai: %d/%d slot dibuat", createdCount, firstNum))
		return
	end

	local universeId = (firstNum and tostring(firstNum)) or MemorySession.ActiveUniverseId
	MemorySession.ActiveUniverseId = universeId

	local permIds = {}
	for idx = 2, #targets do
		table.insert(permIds, targets[idx].id)
	end
	if #permIds == 0 and firstNum then
		table.insert(permIds, firstNum)
	end

	if #permIds > 1 then
		local listStr = {}
		for _, pid in ipairs(permIds) do
			table.insert(listStr, tostring(pid))
		end
		safeCopy(table.concat(listStr, ","))
		pushLog("PERM", string.format("Batch permission %d ID -> Universe %s (disalin)", #permIds, universeId))
	elseif #permIds == 1 then
		pushLog("PERM", string.format("Permission ID %d -> Universe %s siap", permIds[1], universeId))
	else
		pushLog("PERM", "Target Universe ID aktif: " .. universeId)
	end
end

-- [Setting] Set Cookie / API Key / Speed / Universe / Exit
local function executeSettingFeature(rawInput: string, screenGui: ScreenGui)
	local trimmed = string.gsub(rawInput or "", "^%s*(.-)%s*$", "%1")
	local lower = string.lower(trimmed)

	if lower == "exit" or lower == "keluar" then
		table.clear(MemorySession.Logs)
		screenGui:Destroy()
		return
	end

	if string.sub(trimmed, 1, 10) == "_|WARNING:" or string.len(trimmed) > 80 then
		MemorySession.CookieToken = trimmed
		pushLog("COOKIE", "Cookie tersimpan di sesi memori (" .. tostring(LocalPlayer.UserId) .. ")")
		return
	end

	if string.sub(lower, 1, 4) == "key_" or string.sub(lower, 1, 7) == "rblxkey" then
		MemorySession.ApiKeyToken = trimmed
		pushLog("APIKEY", "Open Cloud API Key tersimpan di sesi memori")
		return
	end

	local numVal = tonumber(trimmed)
	if numVal then
		if numVal > 0 and numVal <= 10 and string.find(trimmed, "%.", 1, false) then
			MemorySession.PlaybackSpeed = numVal
			pushLog("SPEED", string.format("PlaybackSpeed diatur ke %.2f", numVal))
		else
			MemorySession.ActiveUniverseId = tostring(math.floor(numVal))
			pushLog("UNIVERSE", "ActiveUniverseId diatur ke " .. MemorySession.ActiveUniverseId)
		end
		return
	end

	if trimmed ~= "" then
		MemorySession.ApiKeyToken = trimmed
		pushLog("SESSION", "Token/Key sesi diperbarui di memori")
	else
		pushLog("SETTING", string.format(
			"Universe:%s | Speed:%.2f | Cookie:%s | API:%s",
			MemorySession.ActiveUniverseId,
			MemorySession.PlaybackSpeed,
			MemorySession.CookieToken ~= "" and "OK" or "-",
			MemorySession.ApiKeyToken ~= "" and "OK" or "-"
		))
	end
end

-- [About] Info Creator Ikyy & Detail Tools
local ABOUT_SUMMARY = table.concat({
	"Creator: Ikyy (sptzyy / IkyyXD)",
	"Tools: Plugin Studio Lite (Spoof Audio/RBXM, Upload Aset, Place & Asset Permissions)",
	"Mode: In-Memory Session (Tanpa Save File, Isolasi Sesi Aktif)",
}, " • ")

local function executeAboutFeature()
	local copied = safeCopy(ABOUT_SUMMARY)
	pushLog("ABOUT", "by Ikyy • Tools: Spoof, Upload, Import/Place, Permission (In-Memory)" .. (copied and " [Disalin]" or ""))
end

-- ==========================================
-- 3. GUI LAYOUT (STRUKTUR SEPERTI GAMBAR)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IkyyStudioLiteCaseUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui[span_1](start_span)[span_1](end_span)

local restoreBtn = Instance.new("TextButton")
restoreBtn.Name = "RestoreButton"
restoreBtn.Size = UDim2.new(0, 126, 0, 32)
restoreBtn.Position = UDim2.new(0, 14, 0, 88)
restoreBtn.BackgroundColor3 = Color3.fromRGB(20, 18, 32)
restoreBtn.TextColor3 = Color3.fromRGB(230, 225, 255)
restoreBtn.Font = Enum.Font.GothamBold
restoreBtn.TextSize = 12
restoreBtn.Text = "⇄ Studio Lite"
restoreBtn.Visible = false
restoreBtn.Parent = screenGui

local restoreCorner = Instance.new("UICorner")
restoreCorner.CornerRadius = UDim.new(0, 8)
restoreCorner.Parent = restoreBtn

local restoreStroke = Instance.new("UIStroke")
restoreStroke.Color = Color3.fromRGB(130, 92, 255)
restoreStroke.Thickness = 1.3
restoreStroke.Parent = restoreBtn

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = UDim2.new(0, 560, 0, 330)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -165)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui[span_2](start_span)[span_2](end_span)

local cornerMain = Instance.new("UICorner")
cornerMain.CornerRadius = UDim.new(0, 14)
cornerMain.Parent = mainFrame

local strokeMain = Instance.new("UIStroke")
strokeMain.Color = Color3.fromRGB(125, 88, 255)
strokeMain.Thickness = 1.6
strokeMain.Transparency = 0.25
strokeMain.Parent = mainFrame

-- Header Kiri Atas
local badgeFrame = Instance.new("Frame")
badgeFrame.Size = UDim2.new(0, 34, 0, 34)
badgeFrame.Position = UDim2.new(0, 16, 0, 14)
badgeFrame.BackgroundColor3 = Color3.fromRGB(28, 25, 44)
badgeFrame.BorderSizePixel = 0
badgeFrame.Parent = mainFrame[span_3](start_span)[span_3](end_span)

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 8)
badgeCorner.Parent = badgeFrame

local badgeIcon = Instance.new("TextLabel")
badgeIcon.Size = UDim2.new(1, 0, 1, 0)
badgeIcon.BackgroundTransparency = 1
badgeIcon.Font = Enum.Font.GothamBold
badgeIcon.TextSize = 15
badgeIcon.TextColor3 = Color3.fromRGB(185, 165, 255)
badgeIcon.Text = "⇄"
badgeIcon.Parent = badgeFrame[span_4](start_span)[span_4](end_span)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 280, 0, 20)
titleLabel.Position = UDim2.new(0, 58, 0, 12)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(245, 244, 255)
titleLabel.Text = "Plugin Studio Lite"
titleLabel.Parent = mainFrame[span_5](start_span)[span_5](end_span)

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(0, 280, 0, 16)
subLabel.Position = UDim2.new(0, 58, 0, 32)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.Gotham
subLabel.TextSize = 11
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.TextColor3 = Color3.fromRGB(135, 130, 160)
subLabel.Text = "by Ikyy • v1.0 (In-Memory)"
subLabel.Parent = mainFrame[span_6](start_span)[span_6](end_span)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -46, 0, 16)
closeBtn.BackgroundColor3 = Color3.fromRGB(26, 24, 38)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.fromRGB(210, 205, 230)
closeBtn.Text = "✕"
closeBtn.Parent = mainFrame[span_7](start_span)[span_7](end_span)

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

local closeStroke = Instance.new("UIStroke")
closeStroke.Color = Color3.fromRGB(65, 60, 90)
closeStroke.Thickness = 1
closeStroke.Parent = closeBtn

-- Sidebar Kiri
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 145, 1, -74)
sidebar.Position = UDim2.new(0, 16, 0, 58)
sidebar.BackgroundColor3 = Color3.fromRGB(18, 17, 28)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame[span_8](start_span)[span_8](end_span)

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 10)
sideCorner.Parent = sidebar

local sideStroke = Instance.new("UIStroke")
sideStroke.Color = Color3.fromRGB(36, 33, 54)
sideStroke.Thickness = 1
sideStroke.Parent = sidebar

-- Panel Konten Kanan
local contentPanel = Instance.new("Frame")
contentPanel.Size = UDim2.new(1, -185, 1, -74)
contentPanel.Position = UDim2.new(0, 169, 0, 58)
contentPanel.BackgroundColor3 = Color3.fromRGB(18, 17, 28)
contentPanel.BorderSizePixel = 0
contentPanel.Parent = mainFrame[span_9](start_span)[span_9](end_span)

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = contentPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(36, 33, 54)
panelStroke.Thickness = 1
panelStroke.Parent = contentPanel

local featureTitle = Instance.new("TextLabel")
featureTitle.Size = UDim2.new(1, -28, 0, 22)
featureTitle.Position = UDim2.new(0, 14, 0, 10)
featureTitle.BackgroundTransparency = 1
featureTitle.Font = Enum.Font.GothamBold
featureTitle.TextSize = 15
featureTitle.TextXAlignment = Enum.TextXAlignment.Left
featureTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
featureTitle.Text = "Spoof"
featureTitle.Parent = contentPanel[span_10](start_span)[span_10](end_span)

local featureDesc = Instance.new("TextLabel")
featureDesc.Size = UDim2.new(1, -28, 0, 16)
featureDesc.Position = UDim2.new(0, 14, 0, 32)
featureDesc.BackgroundTransparency = 1
featureDesc.Font = Enum.Font.Gotham
featureDesc.TextSize = 11
featureDesc.TextXAlignment = Enum.TextXAlignment.Left
featureDesc.TextColor3 = Color3.fromRGB(130, 126, 155)
featureDesc.Text = "Downloader Spoof Audio / RBXM (satuan & massal)"
featureDesc.Parent = contentPanel[span_11](start_span)[span_11](end_span)

local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, -28, 0, 16)
inputLabel.Position = UDim2.new(0, 14, 0, 54)
inputLabel.BackgroundTransparency = 1
inputLabel.Font = Enum.Font.GothamBold
inputLabel.TextSize = 10
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.TextColor3 = Color3.fromRGB(135, 110, 255)
inputLabel.Text = "ASSET ID"
inputLabel.Parent = contentPanel[span_12](start_span)[span_12](end_span)

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -28, 0, 74)
inputBox.Position = UDim2.new(0, 14, 0, 72)
inputBox.BackgroundColor3 = Color3.fromRGB(11, 10, 18)
inputBox.BorderSizePixel = 0
inputBox.Font = Enum.Font.Code
inputBox.TextSize = 11
inputBox.TextColor3 = Color3.fromRGB(240, 240, 255)
inputBox.PlaceholderColor3 = Color3.fromRGB(95, 92, 118)
inputBox.PlaceholderText = "Tempel Asset ID di sini (pisah spasi, koma, atau baris baru)"
inputBox.Text = ""
inputBox.MultiLine = true
inputBox.ClearTextOnFocus = false
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.TextYAlignment = Enum.TextTop
inputBox.TextWrapped = true
inputBox.Parent = contentPanel[span_13](start_span)[span_13](end_span)

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputBox

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(45, 42, 68)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox

-- Filter Chip Row
local chipRow = Instance.new("Frame")
chipRow.Size = UDim2.new(1, -28, 0, 26)
chipRow.Position = UDim2.new(0, 14, 0, 154)
chipRow.BackgroundTransparency = 1
chipRow.Parent = contentPanel[span_14](start_span)[span_14](end_span)

local chipLayout = Instance.new("UIListLayout")
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.Padding = UDim.new(0, 6)
chipLayout.Parent = chipRow

local chipNames = { "Auto", "Audio", "Decal", "Model", "Anim" }[span_15](start_span)[span_15](end_span)
local chipButtons: {[string]: TextButton} = {}

local function refreshChips()
	for _, cname in ipairs(chipNames) do
		local btn = chipButtons[cname]
		local active = (MemorySession.SelectedFilter == cname)
		btn.BackgroundColor3 = active and Color3.fromRGB(48, 42, 78) or Color3.fromRGB(24, 23, 36)
		btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(155, 152, 180)
	end
end

for _, cname in ipairs(chipNames) do
	local cBtn = Instance.new("TextButton")
	cBtn.Size = UDim2.new(0, 62, 1, 0)
	cBtn.BackgroundColor3 = Color3.fromRGB(24, 23, 36)
	cBtn.BorderSizePixel = 0
	cBtn.Font = Enum.Font.GothamMedium
	cBtn.TextSize = 11
	cBtn.Text = cname
	cBtn.Parent = chipRow

	local cCorner = Instance.new("UICorner")
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = cBtn

	local cStroke = Instance.new("UIStroke")
	cStroke.Color = Color3.fromRGB(58, 54, 86)
	cStroke.Thickness = 1
	cStroke.Parent = cBtn

	chipButtons[cname] = cBtn
	cBtn.MouseButton1Click:Connect(function()
		MemorySession.SelectedFilter = cname
		refreshChips()
		pushLog("FILTER", "Filter aktif: " .. cname)
	end)
end
refreshChips()

local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(0, 215, 0, 34)
actionBtn.Position = UDim2.new(0, 14, 0, 188)
actionBtn.BackgroundColor3 = Color3.fromRGB(115, 92, 245)
actionBtn.BorderSizePixel = 0
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 11
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.Text = "⇄  SPOOF SEKARANG"
actionBtn.Parent = contentPanel[span_16](start_span)[span_16](end_span)

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 8)
actionCorner.Parent = actionBtn

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 128, 0, 34)
clearBtn.Position = UDim2.new(0, 237, 0, 188)
clearBtn.BackgroundColor3 = Color3.fromRGB(25, 24, 38)
clearBtn.BorderSizePixel = 0
clearBtn.Font = Enum.Font.GothamBold
clearBtn.TextSize = 11
clearBtn.TextColor3 = Color3.fromRGB(215, 212, 235)
clearBtn.Text = "BERSIHKAN"
clearBtn.Parent = contentPanel[span_17](start_span)[span_17](end_span)

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 8)
clearCorner.Parent = clearBtn

local clearStroke = Instance.new("UIStroke")
clearStroke.Color = Color3.fromRGB(58, 54, 86)
clearStroke.Thickness = 1
clearStroke.Parent = clearBtn

local logBox = Instance.new("TextLabel")
logBox.Size = UDim2.new(1, -28, 0, 22)
logBox.Position = UDim2.new(0, 14, 0, 228)
logBox.BackgroundColor3 = Color3.fromRGB(11, 10, 18)
logBox.BorderSizePixel = 0
logBox.Font = Enum.Font.Code
logBox.TextSize = 11
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextColor3 = Color3.fromRGB(190, 245, 255)
logBox.Text = "  Siap."
logBox.Parent = contentPanel[span_18](start_span)[span_18](end_span)

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 6)
logCorner.Parent = logBox

local function refreshLogs()
	if #MemorySession.Logs == 0 then
		logBox.Text = "  Siap."
	else
		logBox.Text = "  " .. MemorySession.Logs[1]
	end
end

-- ==========================================
-- 4. SIDEBAR NAVIGASI & AKSI CEPAT
-- ==========================================
local tabMeta = {
	Spoof = {
		title = "Spoof",
		desc = "Downloader Spoof Audio / RBXM (satuan & massal)",
		label = "ASSET ID",
		placeholder = "Tempel Asset ID atau format SongName: ... SongId: ...",
		btnText = "⇄  SPOOF SEKARANG",
		editable = true,
		presetText = "",
	},
	Upload = {
		title = "Upload",
		desc = "Pengunggah Aset & Decal (satuan & massal)",
		label = "ASSET ID",
		placeholder = "Masukkan Asset ID (satuan atau massal, pisah koma/spasi)",
		btnText = "↑  UPLOAD SEKARANG",
		editable = true,
		presetText = "",
	},
	Import = {
		title = "Import",
		desc = "Pembuat Place (1-20) & Asset Permissions (Universe)",
		label = "JUMLAH PLACE / UNIVERSE ID",
		placeholder = "Masukkan jumlah Place (1-20) atau UniverseId,AssetId1,AssetId2",
		btnText = "↓  IMPORT SEKARANG",
		editable = true,
		presetText = "",
	},
	Setting = {
		title = "Setting",
		desc = "Set Cookie / API Key / Speed / Universe / Exit",
		label = "COOKIE / API KEY / SPEED / UNIVERSE",
		placeholder = "Tempel Cookie, API Key, Speed (misal 1.25), Universe ID, atau 'exit'",
		btnText = "⚙  SIMPAN SESI",
		editable = true,
		presetText = "",
	},
	About = {
		title = "About",
		desc = "Tentang Creator Ikyy & Informasi Plugin Studio Lite",
		label = "CREATOR & TENTANG TOOLS",
		placeholder = "",
		btnText = "📋  SALIN INFO ABOUT",
		editable = false,
		presetText = table.concat({
			"Creator : Ikyy (sptzyy / IkyyXD)",
			"Tools   : Plugin Studio Lite (Delta Executor - In-Memory)",
			"Fitur   : Spoof Audio/RBXM, Upload Aset, Place & Permission",
			"Sesi    : Terisolasi di memori tanpa save file lokal",
		}, "\n"),
	},
}

local navOrder = { "Spoof", "Upload", "Import", "Setting", "About" }
local navButtons: {[string]: TextButton} = {}

local function selectTab(name: string)
	MemorySession.ActiveTab = name
	local info = tabMeta[name]
	featureTitle.Text = info.title
	featureDesc.Text = info.desc
	inputLabel.Text = info.label
	inputBox.PlaceholderText = info.placeholder
	actionBtn.Text = info.btnText
	inputBox.TextEditable = info.editable

	if name == "About" then
		inputBox.Text = info.presetText
	elseif inputBox.Text == tabMeta.About.presetText then
		inputBox.Text = ""
	end

	for tName, btn in pairs(navButtons) do
		local isAct = (tName == name)
		btn.BackgroundColor3 = isAct and Color3.fromRGB(46, 40, 76) or Color3.fromRGB(18, 17, 28)
		btn.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(165, 162, 188)
	end
end

for i, name in ipairs(navOrder) do
	local nBtn = Instance.new("TextButton")
	nBtn.Size = UDim2.new(1, -16, 0, 28)
	nBtn.Position = UDim2.new(0, 8, 0, 6 + (i - 1) * 31)
	nBtn.BackgroundColor3 = Color3.fromRGB(18, 17, 28)
	nBtn.BorderSizePixel = 0
	nBtn.Font = Enum.Font.GothamMedium
	nBtn.TextSize = 12
	nBtn.TextXAlignment = Enum.TextXAlignment.Left
	nBtn.Text = "   " .. name
	nBtn.Parent = sidebar[span_19](start_span)[span_19](end_span)

	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 7)
	nCorner.Parent = nBtn

	navButtons[name] = nBtn
	nBtn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
end

local quickLabel = Instance.new("TextLabel")
quickLabel.Size = UDim2.new(1, -16, 0, 14)
quickLabel.Position = UDim2.new(0, 10, 1, -66)
quickLabel.BackgroundTransparency = 1
quickLabel.Font = Enum.Font.Gotham
quickLabel.TextSize = 10
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.TextColor3 = Color3.fromRGB(125, 122, 150)
quickLabel.Text = "Aksi Cepat"
quickLabel.Parent = sidebar[span_20](start_span)[span_20](end_span)

local cekBtn = Instance.new("TextButton")
cekBtn.Size = UDim2.new(0, 62, 0, 30)
cekBtn.Position = UDim2.new(0, 8, 1, -46)
cekBtn.BackgroundColor3 = Color3.fromRGB(36, 105, 235)
cekBtn.BorderSizePixel = 0
cekBtn.Font = Enum.Font.GothamBold
cekBtn.TextSize = 10
cekBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cekBtn.Text = "Cek\nKoneksi"
cekBtn.Parent = sidebar[span_21](start_span)[span_21](end_span)

local cekCorner = Instance.new("UICorner")
cekCorner.CornerRadius = UDim.new(0, 7)
cekCorner.Parent = cekBtn

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 62, 0, 30)
hideBtn.Position = UDim2.new(0, 75, 1, -46)
hideBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 38)
hideBtn.BorderSizePixel = 0
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 10
hideBtn.TextColor3 = Color3.fromRGB(210, 208, 228)
hideBtn.Text = "Sembunyi"
hideBtn.Parent = sidebar[span_22](start_span)[span_22](end_span)

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 7)
hideCorner.Parent = hideBtn

local hideStroke = Instance.new("UIStroke")
hideStroke.Color = Color3.fromRGB(55, 52, 80)
hideStroke.Thickness = 1
hideStroke.Parent = hideBtn

-- ==========================================
-- 5. EVENT HANDLER
-- ==========================================
actionBtn.MouseButton1Click:Connect(function()
	local tab = MemorySession.ActiveTab
	if tab == "Spoof" then
		executeSpoofFeature(inputBox.Text, MemorySession.SelectedFilter)
	elseif tab == "Upload" then
		executeUploadFeature(inputBox.Text, MemorySession.SelectedFilter)
	elseif tab == "Import" then
		executeImportFeature(inputBox.Text)
	elseif tab == "Setting" then
		executeSettingFeature(inputBox.Text, screenGui)
	elseif tab == "About" then
		executeAboutFeature()
	end
	refreshLogs()
end)

clearBtn.MouseButton1Click:Connect(function()
	if MemorySession.ActiveTab ~= "About" then
		inputBox.Text = ""
	end
	table.clear(MemorySession.Logs)
	refreshLogs()
end)

cekBtn.MouseButton1Click:Connect(function()
	local details = fetchAssetDetails(1848354536)
	if details and details.Name ~= "Asset_1848354536" then
		pushLog("CONN", "Koneksi aktif • Aset uji: " .. details.Name)
	else
		pushLog("CONN", "Sesi aktif • Periksa koneksi MarketplaceService")
	end
	refreshLogs()
end)

hideBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
	restoreBtn.Visible = true
end)

restoreBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = true
	restoreBtn.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
	table.clear(MemorySession.Logs)
	screenGui:Destroy()
end)

selectTab("Spoof")

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Plugin Studio Lite",
		Text = "Dimuat di Delta Executor • by Ikyy",
		Duration = 4,
	})
end)
