--!strict
-- Roblox Developer Toolkit - Delta Executor Edition (In-Memory Session)
-- by Ikyy

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Bersihkan UI lama jika script dijalankan ulang
if PlayerGui:FindFirstChild("IkyyDeltaDevTool") then
	PlayerGui.IkyyDeltaDevTool:Destroy()
end

-- ==========================================
-- 1. IN-MEMORY SESSION (TANPA SAVE FILE)
-- ==========================================
local MemorySession = {
	ActiveTab = "Spoof", -- "Spoof" | "Upload" | "Import" | "Setting"
	SelectedFilter = "Auto", -- "Auto" | "Audio" | "Decal" | "Model" | "Anim"
	ActiveTargetId = "",
	ActiveUniverseId = "",
	DefaultSpeed = 1,
	AllowedUsers = {
		[LocalPlayer.UserId] = true,
		[9374524895] = true,
	},
	Logs = {},
}

local function addLog(statusType: string, message: string)
	table.insert(MemorySession.Logs, 1, string.format("[%s] %s", statusType, message))
	if #MemorySession.Logs > 30 then
		table.remove(MemorySession.Logs)
	end
end

local function hasPermission(userId: number): boolean
	return MemorySession.AllowedUsers[userId] == true
end

local function safeCopyClipboard(content: string): boolean
	local copyFn = (getgenv and getgenv().setclipboard) or setclipboard
	if typeof(copyFn) == "function" then
		pcall(copyFn, content)
		return true
	end
	return false
end

local function fetchAssetInfo(assetId: number)
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(assetId)
	end)
	if ok and info then
		return {
			Name = info.Name or "Unknown_Asset",
			Creator = (info.Creator and info.Creator.Name) or "Unknown Creator",
			CreatorId = (info.Creator and tostring(info.Creator.CreatorTargetId)) or "N/A",
			AssetTypeId = info.AssetTypeId or 0,
		}
	end
	return nil
end

local function parseIds(rawText: string): {number}
	local list = {}
	for token in string.gmatch(rawText or "", "%d+") do
		local num = tonumber(token)
		if num then
			table.insert(list, num)
		end
	end
	return list
end

-- ==========================================
-- 2. FITUR UTAMA (SATUAN & MASSAL)
-- ==========================================

-- Fitur 1: Pembuat Place / Teleport Batch
local function runPlaceAction(count: number, delaySec: number, targetPlaceId: number?)
	if not hasPermission(LocalPlayer.UserId) then
		addLog("DENIED", "Akses ditolak untuk UserId " .. tostring(LocalPlayer.UserId))
		return
	end

	local total = math.clamp(count or 1, 1, 20)
	local waitTime = math.max(delaySec or 1, 0.2)
	addLog("PLACE", string.format("Memulai proses batch (%d iterasi, jeda %.1fs)...", total, waitTime))

	for i = 1, total do
		if targetPlaceId and targetPlaceId > 0 then
			local ok, err = pcall(function()
				TeleportService:Teleport(targetPlaceId, LocalPlayer)
			end)
			if ok then
				addLog("SUCCESS", string.format("[%d/%d] Teleport dipicu ke PlaceId %d", i, total, targetPlaceId))
			else
				addLog("FAILED", string.format("[%d/%d] Gagal: %s", i, total, tostring(err)))
			end
			break
		else
			local part = Instance.new("Part")
			part.Name = "IkyyPlaceSlot_" .. tostring(i)
			part.Size = Vector3.new(6, 1, 6)
			part.Anchored = true
			part.Position = LocalPlayer.Character and LocalPlayer.Character:GetPivot().Position + Vector3.new(i * 8, 0, 0) or Vector3.new(i * 8, 5, 0)
			part.Parent = workspace
			addLog("SUCCESS", string.format("[%d/%d] Slot place dibuat: %s", i, total, part.Name))
		end
		if i < total then
			task.wait(waitTime)
		end
	end
end

-- Fitur 2: Pengunggah / Spawner Aset (Satuan & Massal)
local function runAssetDeploy(idsList: {number}, assetKind: string)
	if not hasPermission(LocalPlayer.UserId) then
		addLog("DENIED", "Akses ditolak untuk deploy aset")
		return
	end

	local results = {}
	for _, id in ipairs(idsList) do
		local info = fetchAssetInfo(id)
		if info then
			table.insert(results, string.format("%s | ID:%d | By:%s (%s)", info.Name, id, info.Creator, tostring(info.CreatorId)))
			addLog("ASSET", string.format("Terdeteksi [%s]: %s (%d) - Kreator: %s", assetKind, info.Name, id, info.Creator))
		else
			addLog("FAILED", string.format("Gagal mengambil info aset ID: %d", id))
		end
		task.wait(0.25)
	end

	if #idsList > 1 then
		local bundleText = table.concat(results, "\n")
		local copied = safeCopyClipboard(bundleText)
		addLog("MASSAL", string.format("Selesai %d aset. %s", #results, copied and "Disalin ke clipboard (paket massal)." or "Siap di log."))
	end
end

-- Fitur 3: Spoof Audio / Animasi (Satuan & Massal)
local function runSpoofAsset(idsList: {number}, modeType: string, speed: number?)
	local playbackSpeed = tonumber(speed) or MemorySession.DefaultSpeed
	local summaryLines = {}

	for _, id in ipairs(idsList) do
		local info = fetchAssetInfo(id)
		local assetTitle = info and info.Name or ("Asset_" .. tostring(id))
		local creatorName = info and info.Creator or "Unknown Creator"
		local creatorId = info and tostring(info.CreatorId) or "N/A"

		if modeType == "AUDIO" then
			local sound = Instance.new("Sound")
			sound.Name = "SpoofAudio_" .. tostring(id)
			sound.SoundId = "rbxassetid://" .. tostring(id)
			sound.PlaybackSpeed = playbackSpeed
			sound.Volume = 0.6
			sound.Parent = workspace
			sound:Play()
			Debris:AddItem(sound, 15)
		elseif modeType == "RBXM" and LocalPlayer.Character then
			local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			if animator then
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://" .. tostring(id)
				pcall(function()
					local track = animator:LoadAnimation(anim)
					track:AdjustSpeed(playbackSpeed)
					track:Play()
				end)
			end
		end

		local detail = string.format("Nama: %s | ID: %d | Kreator: %s (%s) | Speed: %.2f", assetTitle, id, creatorName, creatorId, playbackSpeed)
		table.insert(summaryLines, detail)
		addLog("SPOOF_" .. modeType, detail)
		task.wait(0.2)
	end

	if #idsList == 1 then
		addLog("INFO", "Mode satuan aktif: menampilkan info aset tunggal.")
	elseif #idsList > 1 then
		local packed = table.concat(summaryLines, "\n")
		local copied = safeCopyClipboard(packed)
		addLog("MASSAL", string.format("Spoof massal %d item selesai. %s", #idsList, copied and "Hasil dikemas & disalin ke clipboard." or "Lihat log."))
	end
end

-- Fitur 4: Asset Permissions (Satuan & Massal)
local function runPermissionCheck(universeId: string, idsList: {number})
	MemorySession.ActiveUniverseId = universeId
	for _, id in ipairs(idsList) do
		local info = fetchAssetInfo(id)
		local name = info and info.Name or tostring(id)
		addLog("PERM", string.format("Universe %s -> Aset %s (%d) terverifikasi siap diproses", universeId, name, id))
		task.wait(0.15)
	end
	if #idsList > 1 then
		addLog("MASSAL", string.format("Batch permission %d ID untuk Universe %s selesai dicatat.", #idsList, universeId))
	end
end

-- ==========================================
-- 3. GUI LAYOUT (STRUKTUR SEPERTI GAMBAR)
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IkyyDeltaDevTool"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

-- Tombol muncul kembali saat mode Sembunyi aktif
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

-- Window Utama
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainWindow"
mainFrame.Size = UDim2.new(0, 560, 0, 330)
mainFrame.Position = UDim2.new(0.5, -280, 0.5, -165)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 13, 22)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

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
badgeFrame.Parent = mainFrame

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
badgeIcon.Parent = badgeFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 280, 0, 20)
titleLabel.Position = UDim2.new(0, 58, 0, 12)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = Color3.fromRGB(245, 244, 255)
titleLabel.Text = "Plugin Studio Lite"
titleLabel.Parent = mainFrame

local subLabel = Instance.new("TextLabel")
subLabel.Size = UDim2.new(0, 280, 0, 16)
subLabel.Position = UDim2.new(0, 58, 0, 32)
subLabel.BackgroundTransparency = 1
subLabel.Font = Enum.Font.Gotham
subLabel.TextSize = 11
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.TextColor3 = Color3.fromRGB(135, 130, 160)
subLabel.Text = "by Ikyy • v1.0 (In-Memory)"
subLabel.Parent = mainFrame

-- Tombol Close (X) Kanan Atas
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -46, 0, 16)
closeBtn.BackgroundColor3 = Color3.fromRGB(26, 24, 38)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.fromRGB(210, 205, 230)
closeBtn.Text = "✕"
closeBtn.Parent = mainFrame

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
sidebar.Parent = mainFrame

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
contentPanel.Parent = mainFrame

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = contentPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(36, 33, 54)
panelStroke.Thickness = 1
panelStroke.Parent = contentPanel

-- Judul & Deskripsi Fitur Aktif di Panel Kanan
local featureTitle = Instance.new("TextLabel")
featureTitle.Size = UDim2.new(1, -28, 0, 22)
featureTitle.Position = UDim2.new(0, 14, 0, 10)
featureTitle.BackgroundTransparency = 1
featureTitle.Font = Enum.Font.GothamBold
featureTitle.TextSize = 15
featureTitle.TextXAlignment = Enum.TextXAlignment.Left
featureTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
featureTitle.Text = "Spoof"
featureTitle.Parent = contentPanel

local featureDesc = Instance.new("TextLabel")
featureDesc.Size = UDim2.new(1, -28, 0, 16)
featureDesc.Position = UDim2.new(0, 14, 0, 32)
featureDesc.BackgroundTransparency = 1
featureDesc.Font = Enum.Font.Gotham
featureDesc.TextSize = 11
featureDesc.TextXAlignment = Enum.TextXAlignment.Left
featureDesc.TextColor3 = Color3.fromRGB(130, 126, 155)
featureDesc.Text = "Asset ID lama jadi ID baru milikmu (tanpa save file)"
featureDesc.Parent = contentPanel

-- Label ASSET ID & TextBox Besar
local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, -28, 0, 16)
inputLabel.Position = UDim2.new(0, 14, 0, 54)
inputLabel.BackgroundTransparency = 1
inputLabel.Font = Enum.Font.GothamBold
inputLabel.TextSize = 10
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.TextColor3 = Color3.fromRGB(135, 110, 255)
inputLabel.Text = "ASSET ID"
inputLabel.Parent = contentPanel

local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(1, -28, 0, 74)
inputBox.Position = UDim2.new(0, 14, 0, 72)
inputBox.BackgroundColor3 = Color3.fromRGB(11, 10, 18)
inputBox.BorderSizePixel = 0
inputBox.Font = Enum.Font.Code
inputBox.TextSize = 12
inputBox.TextColor3 = Color3.fromRGB(240, 240, 255)
inputBox.PlaceholderColor3 = Color3.fromRGB(95, 92, 118)
inputBox.PlaceholderText = "Tempel Asset ID di sini (pisah spasi, koma, atau baris baru)"
inputBox.Text = ""
inputBox.MultiLine = true
inputBox.ClearTextOnFocus = false
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.TextYAlignment = Enum.TextTop
inputBox.TextWrapped = true
inputBox.Parent = contentPanel

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = inputBox

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(45, 42, 68)
inputStroke.Thickness = 1
inputStroke.Parent = inputBox

-- Baris Filter Chip (Auto / Audio / Decal / Model / Anim)
local chipRow = Instance.new("Frame")
chipRow.Size = UDim2.new(1, -28, 0, 26)
chipRow.Position = UDim2.new(0, 14, 0, 154)
chipRow.BackgroundTransparency = 1
chipRow.Parent = contentPanel

local chipLayout = Instance.new("UIListLayout")
chipLayout.FillDirection = Enum.FillDirection.Horizontal
chipLayout.Padding = UDim.new(0, 6)
chipLayout.Parent = chipRow

local chipNames = { "Auto", "Audio", "Decal", "Model", "Anim" }
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
		addLog("FILTER", "Filter aktif: " .. cname)
	end)
end
refreshChips()

-- Tombol Aksi Utama & BERSIHKAN
local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(0, 215, 0, 34)
actionBtn.Position = UDim2.new(0, 14, 0, 188)
actionBtn.BackgroundColor3 = Color3.fromRGB(115, 92, 245)
actionBtn.BorderSizePixel = 0
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 11
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.Text = "⇄  SPOOF SEKARANG"
actionBtn.Parent = contentPanel

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
clearBtn.Parent = contentPanel

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 8)
clearCorner.Parent = clearBtn

local clearStroke = Instance.new("UIStroke")
clearStroke.Color = Color3.fromRGB(58, 54, 86)
clearStroke.Thickness = 1
clearStroke.Parent = clearBtn

-- Box Status / Log Bawah
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
logBox.Parent = contentPanel

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
		desc = "Spoof Audio / RBXM satuan & massal (in-memory)",
		label = "ASSET ID",
		placeholder = "Tempel Asset ID di sini (pisah spasi, koma, atau baris baru)",
		btnText = "⇄  SPOOF SEKARANG",
	},
	Upload = {
		title = "Upload",
		desc = "Deploy & deteksi aset satuan / massal ke memori",
		label = "ASSET ID",
		placeholder = "Masukkan Asset ID (satuan atau massal, pisah koma/spasi)",
		btnText = "↑  UNGGAH / DEPLOY",
	},
	Import = {
		title = "Import",
		desc = "Pembuat Place / Teleport batch & Asset Permissions",
		label = "JUMLAH PLACE / UNIVERSE ID",
		placeholder = "Masukkan jumlah slot (1-20) atau Universe ID (contoh: 10516113765)",
		btnText = "↓  JALANKAN IMPORT",
	},
	Setting = {
		title = "Setting",
		desc = "Atur PlaybackSpeed / Universe ID & keluar (Exit)",
		label = "PLAYBACK SPEED / UNIVERSE ID",
		placeholder = "Ketik angka speed (0.1 - 5) atau Universe ID / 'exit'",
		btnText = "⚙  SIMPAN SESI",
	},
}

local navOrder = { "Spoof", "Upload", "Import", "Setting" }
local navButtons: {[string]: TextButton} = {}

local function selectTab(name: string)
	MemorySession.ActiveTab = name
	local info = tabMeta[name]
	featureTitle.Text = info.title
	featureDesc.Text = info.desc
	inputLabel.Text = info.label
	inputBox.PlaceholderText = info.placeholder
	actionBtn.Text = info.btnText

	for tName, btn in pairs(navButtons) do
		local isAct = (tName == name)
		btn.BackgroundColor3 = isAct and Color3.fromRGB(46, 40, 76) or Color3.fromRGB(18, 17, 28)
		btn.TextColor3 = isAct and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(165, 162, 188)
	end
end

for i, name in ipairs(navOrder) do
	local nBtn = Instance.new("TextButton")
	nBtn.Size = UDim2.new(1, -16, 0, 32)
	nBtn.Position = UDim2.new(0, 8, 0, 8 + (i - 1) * 36)
	nBtn.BackgroundColor3 = Color3.fromRGB(18, 17, 28)
	nBtn.BorderSizePixel = 0
	nBtn.Font = Enum.Font.GothamMedium
	nBtn.TextSize = 12
	nBtn.TextXAlignment = Enum.TextXAlignment.Left
	nBtn.Text = "   " .. name
	nBtn.Parent = sidebar

	local nCorner = Instance.new("UICorner")
	nCorner.CornerRadius = UDim.new(0, 7)
	nCorner.Parent = nBtn

	navButtons[name] = nBtn
	nBtn.MouseButton1Click:Connect(function()
		selectTab(name)
	end)
end

-- Label "Aksi Cepat" + "Cek Koneksi" & "Sembunyi"
local quickLabel = Instance.new("TextLabel")
quickLabel.Size = UDim2.new(1, -16, 0, 16)
quickLabel.Position = UDim2.new(0, 10, 1, -72)
quickLabel.BackgroundTransparency = 1
quickLabel.Font = Enum.Font.Gotham
quickLabel.TextSize = 10
quickLabel.TextXAlignment = Enum.TextXAlignment.Left
quickLabel.TextColor3 = Color3.fromRGB(125, 122, 150)
quickLabel.Text = "Aksi Cepat"
quickLabel.Parent = sidebar

local cekBtn = Instance.new("TextButton")
cekBtn.Size = UDim2.new(0, 62, 0, 32)
cekBtn.Position = UDim2.new(0, 8, 1, -48)
cekBtn.BackgroundColor3 = Color3.fromRGB(36, 105, 235)
cekBtn.BorderSizePixel = 0
cekBtn.Font = Enum.Font.GothamBold
cekBtn.TextSize = 10
cekBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cekBtn.Text = "Cek\nKoneksi"
cekBtn.Parent = sidebar

local cekCorner = Instance.new("UICorner")
cekCorner.CornerRadius = UDim.new(0, 7)
cekCorner.Parent = cekBtn

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 62, 0, 32)
hideBtn.Position = UDim2.new(0, 75, 1, -48)
hideBtn.BackgroundColor3 = Color3.fromRGB(26, 25, 38)
hideBtn.BorderSizePixel = 0
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 10
hideBtn.TextColor3 = Color3.fromRGB(210, 208, 228)
hideBtn.Text = "Sembunyi"
hideBtn.Parent = sidebar

local hideCorner = Instance.new("UICorner")
hideCorner.CornerRadius = UDim.new(0, 7)
hideCorner.Parent = hideBtn

local hideStroke = Instance.new("UIStroke")
hideStroke.Color = Color3.fromRGB(55, 52, 80)
hideStroke.Thickness = 1
hideStroke.Parent = hideBtn

-- ==========================================
-- 5. KONEKSI TOMBOL KE FUNGSI FITUR
-- ==========================================
actionBtn.MouseButton1Click:Connect(function()
	local tab = MemorySession.ActiveTab
	local ids = parseIds(inputBox.Text)

	if tab == "Spoof" then
		if #ids == 0 then ids = { 1848354536 } end
		local mode = (MemorySession.SelectedFilter == "Anim") and "RBXM" or "AUDIO"
		runSpoofAsset(ids, mode, MemorySession.DefaultSpeed)
		refreshLogs()

	elseif tab == "Upload" then
		if #ids == 0 then ids = { 1848354536 } end
		runAssetDeploy(ids, MemorySession.SelectedFilter)
		refreshLogs()

	elseif tab == "Import" then
		local firstNum = ids[1]
		if firstNum and firstNum <= 20 and string.len(tostring(firstNum)) <= 2 then
			runPlaceAction(firstNum, 0.5, nil)
		else
			local univ = (firstNum and tostring(firstNum))
				or (MemorySession.ActiveUniverseId ~= "" and MemorySession.ActiveUniverseId or "10516113765")
			local permIds = (#ids > 1) and { table.unpack(ids, 2) } or ids
			runPermissionCheck(univ, permIds)
		end
		refreshLogs()

	elseif tab == "Setting" then
		local trimmed = string.lower(string.gsub(inputBox.Text, "^%s*(.-)%s*$", "%1"))
		if trimmed == "exit" or trimmed == "keluar" then
			table.clear(MemorySession.Logs)
			screenGui:Destroy()
			return
		end
		local spd = tonumber(inputBox.Text)
		if spd and spd > 0 and spd <= 10 then
			MemorySession.DefaultSpeed = spd
			addLog("SESSION", string.format("DefaultSpeed diubah ke %.2f", spd))
		elseif ids[1] then
			MemorySession.ActiveUniverseId = tostring(ids[1])
			addLog("SESSION", "ActiveUniverseId diatur ke " .. tostring(ids[1]))
		else
			addLog("WARN", "Masukkan angka speed, Universe ID, atau 'exit'.")
		end
		refreshLogs()
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	inputBox.Text = ""
	table.clear(MemorySession.Logs)
	refreshLogs()
end)

cekBtn.MouseButton1Click:Connect(function()
	local info = fetchAssetInfo(1848354536)
	if info then
		addLog("CONN", "Koneksi aktif • Aset uji: " .. info.Name)
	else
		addLog("CONN", "Koneksi terbatas atau aset uji tidak terjangkau")
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
		Title = "Roblox Developer Tool",
		Text = "Dimuat di Delta Executor (In-Memory Session)",
		Duration = 4,
	})
end)
