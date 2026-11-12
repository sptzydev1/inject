-- ======================================================
-- IKYYXD DEX1.0 - STARTERGUI COPIER & DECOMPILER EDITION
-- COPYRIGHT (C) IkyyXD - ALL RIGHTS RESERVED
-- ======================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

-- Hapus GUI lama jika ada
local oldGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("IKYYXDGuiCopier")
if oldGui then oldGui:Destroy() end

--------------------------------------------------
-- 1. UTAMA: SCREEN GUI & FLOATING ICON (Cyan Accent)
--------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IKYYXDGuiCopier"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Floating Icon Kecil
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 32, 0, 32)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -16)
ToggleButton.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
ToggleButton.Text = "IK"
ToggleButton.TextSize = 12
ToggleButton.TextColor3 = Color3.fromRGB(0, 229, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

local UICornerIcon = Instance.new("UICorner")
UICornerIcon.CornerRadius = UDim.new(0, 6)
UICornerIcon.Parent = ToggleButton

local UIStrokeIcon = Instance.new("UIStroke")
UIStrokeIcon.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStrokeIcon.Color = Color3.fromRGB(0, 229, 255)
UIStrokeIcon.Thickness = 1.5
UIStrokeIcon.Parent = ToggleButton

-- Main Frame (Lebar: 460px, Tinggi: 220px)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 460, 0, 220)
MainFrame.Position = UDim2.new(0.5, -230, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner")
UICornerMain.CornerRadius = UDim.new(0, 8)
UICornerMain.Parent = MainFrame

local UIStrokeMain = Instance.new("UIStroke")
UIStrokeMain.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStrokeMain.Color = Color3.fromRGB(0, 229, 255)
UIStrokeMain.Thickness = 1.5
UIStrokeMain.Parent = MainFrame

ToggleButton.MouseButton1Click:Connect(function()
	MainFrame.Visible = not MainFrame.Visible
end)

--------------------------------------------------
-- 2. WATERMARK PALING BAWAH (@IkyyXD)
--------------------------------------------------
local BottomWatermark = Instance.new("TextLabel")
BottomWatermark.Size = UDim2.new(1, 0, 0, 16)
BottomWatermark.Position = UDim2.new(0, 0, 1, -16)
BottomWatermark.BackgroundTransparency = 1
BottomWatermark.Text = "IKYYXD DEX1.0 // @IkyyXD"
BottomWatermark.TextColor3 = Color3.fromRGB(150, 150, 150)
BottomWatermark.TextSize = 9
BottomWatermark.Font = Enum.Font.SourceSansBold
BottomWatermark.Parent = MainFrame

--------------------------------------------------
-- 3. PAGE KIRI: LIST FITUR MINI
--------------------------------------------------
local PageKiri = Instance.new("Frame")
PageKiri.Name = "PageKiri"
PageKiri.Size = UDim2.new(0, 142, 1, -22)
PageKiri.Position = UDim2.new(0, 6, 0, 6)
PageKiri.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PageKiri.Parent = MainFrame

local UICornerKiri = Instance.new("UICorner")
UICornerKiri.CornerRadius = UDim.new(0, 6)
UICornerKiri.Parent = PageKiri

local TitleKiri = Instance.new("TextLabel")
TitleKiri.Size = UDim2.new(1, 0, 0, 18)
TitleKiri.Position = UDim2.new(0, 0, 0, 2)
TitleKiri.BackgroundTransparency = 1
TitleKiri.Text = "GUI FEATURES"
TitleKiri.TextColor3 = Color3.fromRGB(0, 229, 255)
TitleKiri.TextSize = 10
TitleKiri.Font = Enum.Font.SourceSansBold
TitleKiri.Parent = PageKiri

local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(1, -12, 1, -26)
ListContainer.Position = UDim2.new(0, 6, 0, 22)
ListContainer.BackgroundTransparency = 1
ListContainer.Parent = PageKiri

local UIListKiri = Instance.new("UIListLayout")
UIListKiri.SortOrder = Enum.SortOrder.LayoutOrder
UIListKiri.Padding = UDim.new(0, 3)
UIListKiri.Parent = ListContainer

local function createFeatureLabel(text, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.LayoutOrder = order
	lbl.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.TextSize = 9
	lbl.Font = Enum.Font.SourceSans
	lbl.Parent = ListContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = lbl
	return lbl
end

createFeatureLabel("• StarterGui Only", 1)
createFeatureLabel("• All Properties Sync", 2)
createFeatureLabel("• Script Decompiler", 3)
createFeatureLabel("• Auto Storage Backup", 4)
createFeatureLabel("• Direct Inject/Paste", 5)

--------------------------------------------------
-- 4. PAGE TENGAH: PROFILE MINI
--------------------------------------------------
local PageTengah = Instance.new("Frame")
PageTengah.Name = "PageTengah"
PageTengah.Size = UDim2.new(0, 142, 1, -22)
PageTengah.Position = UDim2.new(0, 154, 0, 6)
PageTengah.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PageTengah.Parent = MainFrame

local UICornerTengah = Instance.new("UICorner")
UICornerTengah.CornerRadius = UDim.new(0, 6)
UICornerTengah.Parent = PageTengah

local TitleTengah = Instance.new("TextLabel")
TitleTengah.Size = UDim2.new(1, 0, 0, 18)
TitleTengah.Position = UDim2.new(0, 0, 0, 2)
TitleTengah.BackgroundTransparency = 1
TitleTengah.Text = "PROFILE AKUN"
TitleTengah.TextColor3 = Color3.fromRGB(0, 229, 255)
TitleTengah.TextSize = 10
TitleTengah.Font = Enum.Font.SourceSansBold
TitleTengah.Parent = PageTengah

local AvatarImg = Instance.new("ImageLabel")
AvatarImg.Size = UDim2.new(0, 32, 0, 32)
AvatarImg.Position = UDim2.new(0, 6, 0, 22)
AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
AvatarImg.Parent = PageTengah

local UICornerAvatar = Instance.new("UICorner")
UICornerAvatar.CornerRadius = UDim.new(1, 0)
UICornerAvatar.Parent = AvatarImg

local ProfileDetails = Instance.new("TextLabel")
ProfileDetails.Size = UDim2.new(1, -44, 0, 32)
ProfileDetails.Position = UDim2.new(0, 42, 0, 22)
ProfileDetails.BackgroundTransparency = 1
ProfileDetails.TextXAlignment = Enum.TextXAlignment.Left
ProfileDetails.TextYAlignment = Enum.TextYAlignment.Center
ProfileDetails.Text = "👤 " .. LocalPlayer.DisplayName .. "\n🗓️ " .. LocalPlayer.AccountAge .. " Hari"
ProfileDetails.TextColor3 = Color3.fromRGB(220, 220, 220)
ProfileDetails.TextSize = 9
ProfileDetails.Font = Enum.Font.SourceSans
ProfileDetails.Parent = PageTengah

local InfoList = Instance.new("TextLabel")
InfoList.Size = UDim2.new(1, -12, 0, 115)
InfoList.Position = UDim2.new(0, 6, 0, 60)
InfoList.BackgroundTransparency = 1
InfoList.TextXAlignment = Enum.TextXAlignment.Left
InfoList.TextYAlignment = Enum.TextYAlignment.Top
InfoList.TextColor3 = Color3.fromRGB(180, 180, 180)
InfoList.TextSize = 9
InfoList.Font = Enum.Font.SourceSans
InfoList.Text = "👥 Friends: Loading...\n⭐ Followers: Loading...\n📌 Following: Loading..."
InfoList.Parent = PageTengah

task.spawn(function()
	local friendsCount, followersCount, followingCount = "0", "0", "0"
	pcall(function() friendsCount = tostring(#Players:GetFriendsAsync(LocalPlayer.UserId):GetCurrentPage()) end)
	pcall(function() followersCount = tostring(HttpService:JSONDecode(game:HttpGet("https://friends.roblox.com/v1/users/" .. LocalPlayer.UserId .. "/followers/count")).count) end)
	pcall(function() followingCount = tostring(HttpService:JSONDecode(game:HttpGet("https://friends.roblox.com/v1/users/" .. LocalPlayer.UserId .. "/followings/count")).count) end)
	InfoList.Text = "👥 Friends: " .. friendsCount .. "\n⭐ Followers: " .. followersCount .. "\n📌 Following: " .. followingCount
end)

--------------------------------------------------
-- 5. PAGE KANAN: KONTROL, LIST & CONSOLE LOG
--------------------------------------------------
local PageKanan = Instance.new("Frame")
PageKanan.Name = "PageKanan"
PageKanan.Size = UDim2.new(0, 150, 1, -22)
PageKanan.Position = UDim2.new(0, 302, 0, 6)
PageKanan.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PageKanan.Parent = MainFrame

local UICornerKanan = Instance.new("UICorner")
UICornerKanan.CornerRadius = UDim.new(0, 6)
UICornerKanan.Parent = PageKanan

local TitleKanan = Instance.new("TextLabel")
TitleKanan.Size = UDim2.new(1, -24, 0, 18)
TitleKanan.Position = UDim2.new(0, 0, 0, 2)
TitleKanan.BackgroundTransparency = 1
TitleKanan.Text = "GUI SAVED"
TitleKanan.TextColor3 = Color3.fromRGB(0, 229, 255)
TitleKanan.TextSize = 10
TitleKanan.Font = Enum.Font.SourceSansBold
TitleKanan.Parent = PageKanan

local BtnContainer = Instance.new("Frame")
BtnContainer.Size = UDim2.new(1, -12, 0, 50)
BtnContainer.Position = UDim2.new(0, 6, 0, 20)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Parent = PageKanan

local UIListKanan = Instance.new("UIListLayout")
UIListKanan.SortOrder = Enum.SortOrder.LayoutOrder
UIListKanan.Padding = UDim.new(0, 3)
UIListKanan.Parent = BtnContainer

local function createActionButton(name, text, order)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 20)
	btn.LayoutOrder = order
	btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(240, 240, 240)
	btn.TextSize = 9
	btn.Font = Enum.Font.SourceSansBold
	btn.Parent = BtnContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 3)
	corner.Parent = btn
	return btn
end

local CopyGuiBtn = createActionButton("CopyGuiBtn", "Copy StarterGui", 1)
local SaveBtn     = createActionButton("SaveBtn", "Save to File", 2)

-- Scroll Container List Hasil
local ResultFrame = Instance.new("ScrollingFrame")
ResultFrame.Name = "ResultFrame"
ResultFrame.Size = UDim2.new(1, -12, 0, 75)
ResultFrame.Position = UDim2.new(0, 6, 0, 74)
ResultFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
ResultFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ResultFrame.ScrollBarThickness = 2
ResultFrame.Parent = PageKanan

local UICornerResult = Instance.new("UICorner")
UICornerResult.CornerRadius = UDim.new(0, 4)
UICornerResult.Parent = ResultFrame

local ResultListLayout = Instance.new("UIListLayout")
ResultListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ResultListLayout.Padding = UDim.new(0, 2)
ResultListLayout.Parent = ResultFrame

-- Console Log Box
local ConsoleLog = Instance.new("TextLabel")
ConsoleLog.Name = "ConsoleLog"
ConsoleLog.Size = UDim2.new(1, -12, 0, 32)
ConsoleLog.Position = UDim2.new(0, 6, 0, 154)
ConsoleLog.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
ConsoleLog.Text = "> System Ready..."
ConsoleLog.TextColor3 = Color3.fromRGB(0, 229, 255)
ConsoleLog.TextSize = 8
ConsoleLog.Font = Enum.Font.Code
ConsoleLog.TextXAlignment = Enum.TextXAlignment.Left
ConsoleLog.TextYAlignment = Enum.TextYAlignment.Top
ConsoleLog.TextWrapped = true
ConsoleLog.Parent = PageKanan

local UICornerConsole = Instance.new("UICorner")
UICornerConsole.CornerRadius = UDim.new(0, 4)
UICornerConsole.Parent = ConsoleLog

--------------------------------------------------
-- 6. LOGIKA DECOMPILER & SERIALIZER STARTERGUI
--------------------------------------------------
local savedGuiStorage = {}
local listButtons = {}

local function setConsoleMessage(text, color)
	ConsoleLog.Text = "> " .. text
	ConsoleLog.TextColor3 = color or Color3.fromRGB(0, 229, 255)
end

-- Fungsi Decompile Script layaknya Delta / DEX Executor
local function getScriptSource(scriptObj)
	local success, source = pcall(function()
		if decompile then
			return decompile(scriptObj)
		elseif scriptObj.Source and scriptObj.Source ~= "" then
			return scriptObj.Source
		end
		return ""
	end)
	if success and source then
		return source
	end
	return "-- [Decompile Failed / Locked]"
end

-- Rekursif Menyalin Properti GUI & Script secara Akurat
local function serializeInstance(obj)
	local data = {
		Name = obj.Name,
		ClassName = obj.ClassName,
		Properties = {},
		Source = "",
		Children = {}
	}

	-- Salin properti umum GUI secara akurat
	pcall(function()
		if obj:IsA("GuiObject") or obj:IsA("LayerCollector") then
			data.Properties.Size = {obj.Size.X.Scale, obj.Size.X.Offset, obj.Size.Y.Scale, obj.Size.Y.Offset}
			data.Properties.Position = {obj.Position.X.Scale, obj.Position.X.Offset, obj.Position.Y.Scale, obj.Position.Y.Offset}
			data.Properties.BackgroundColor3 = {obj.BackgroundColor3.R, obj.BackgroundColor3.G, obj.BackgroundColor3.B}
			data.Properties.BackgroundTransparency = obj.BackgroundTransparency
			data.Properties.Visible = obj.Visible
			data.Properties.ZIndex = obj.ZIndex
		end
		if obj:IsA("TextButton") or obj:IsA("TextLabel") or obj:IsA("TextBox") then
			data.Properties.Text = obj.Text
			data.Properties.TextSize = obj.TextSize
			data.Properties.TextColor3 = {obj.TextColor3.R, obj.TextColor3.G, obj.TextColor3.B}
			data.Properties.Font = obj.Font.Name
		end
		if obj:IsA("ImageButton") or obj:IsA("ImageLabel") then
			data.Properties.Image = obj.Image
		end
	end)

	-- Ambil isi script menggunakan logika decompiler jika berupa Script/LocalScript
	if obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script") then
		data.Source = getScriptSource(obj)
	end

	-- Rekursif ke anak objek (Children)
	for _, child in ipairs(obj:GetChildren()) do
		table.insert(data.Children, serializeInstance(child))
	end

	return data
end

-- Rekursif Membangun Kembali (Paste) Objek GUI ke dalam Game
local function deserializeInstance(data, parent)
	local success, newObj = pcall(function()
		local instance = Instance.new(data.ClassName)
		instance.Name = data.Name

		-- Terapkan kembali properti
		local p = data.Properties
		if p.Size then instance.Size = UDim2.new(unpack(p.Size)) end
		if p.Position then instance.Position = UDim2.new(unpack(p.Position)) end
		if p.BackgroundColor3 then instance.BackgroundColor3 = Color3.new(unpack(p.BackgroundColor3)) end
		if p.BackgroundTransparency then instance.BackgroundTransparency = p.BackgroundTransparency end
		if p.Visible ~= nil then instance.Visible = p.Visible end
		if p.ZIndex then instance.ZIndex = p.ZIndex end

		if instance:IsA("TextButton") or instance:IsA("TextLabel") or instance:IsA("TextBox") then
			if p.Text then instance.Text = p.Text end
			if p.TextSize then instance.TextSize = p.TextSize end
			if p.TextColor3 then instance.TextColor3 = Color3.new(unpack(p.TextColor3)) end
			if p.Font and Enum.Font[p.Font] then instance.Font = Enum.Font[p.Font] end
		end

		if instance:IsA("ImageButton") or instance:IsA("ImageLabel") then
			if p.Image then instance.Image = p.Image end
		end

		-- Jika memiliki source code (Script/LocalScript), masukkan kembali kodenya
		if (instance:IsA("LocalScript") or instance:IsA("ModuleScript") or instance:IsA("Script")) and data.Source ~= "" then
			pcall(function()
				instance.Source = data.Source
			end)
		end

		instance.Parent = parent

		-- Proses rekursif anak objek
		for _, childData in ipairs(data.Children) do
			deserializeInstance(childData, instance)
		end

		return instance
	end)

	if not success then
		warn("Failed to create instance: " .. tostring(newObj))
	end
end

-- Refresh UI List Hasil
local function refreshResultList()
	for _, btn in ipairs(listButtons) do
		btn:Destroy()
	end
	listButtons = {}

	for idx, guiData in ipairs(savedGuiStorage) do
		local itemBtn = Instance.new("TextButton")
		itemBtn.Size = UDim2.new(1, -4, 0, 18)
		itemBtn.LayoutOrder = idx
		itemBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
		itemBtn.Text = idx .. ". " .. guiData.Title
		itemBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
		itemBtn.TextXAlignment = Enum.TextXAlignment.Left
		itemBtn.TextSize = 8
		itemBtn.Font = Enum.Font.SourceSans
		itemBtn.Parent = ResultFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 3)
		corner.Parent = itemBtn

		-- Klik item untuk langsung Paste ke PlayerGui
		itemBtn.MouseButton1Click:Connect(function()
			local targetParent = LocalPlayer:WaitForChild("PlayerGui")
			for _, childData in ipairs(guiData.Items) do
				deserializeInstance(childData, targetParent)
			end
			setConsoleMessage("Successfully Pasted GUI to PlayerGui!", Color3.fromRGB(0, 255, 180))
		end)

		table.insert(listButtons, itemBtn)
	end

	ResultFrame.CanvasSize = UDim2.new(0, 0, 0, ResultListLayout.AbsoluteContentSize.Y)
end

-- Tombol COPY STARTERGUI
CopyGuiBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		setConsoleMessage("Copying StarterGui...", Color3.fromRGB(255, 220, 100))
		local guiItems = {}

		-- Hanya menyalin isi StarterGui
		for _, child in ipairs(StarterGui:GetChildren()) do
			table.insert(guiItems, serializeInstance(child))
		end

		local payload = {
			Title = "StarterGui_Backup_" .. math.random(10, 99),
			Items = guiItems
		}

		table.insert(savedGuiStorage, payload)
		refreshResultList()
		setConsoleMessage("StarterGui Copied Successfully!", Color3.fromRGB(0, 255, 180))
	end)
end)

-- Tombol SAVE ke File (.dat)
SaveBtn.MouseButton1Click:Connect(function()
	if writefile then
		pcall(function()
			writefile("ikyyxd_startergui_data.dat", HttpService:JSONEncode(savedGuiStorage))
			setConsoleMessage("Saved to workspace file!", Color3.fromRGB(0, 255, 180))
		end)
	else
		setConsoleMessage("writefile not supported!", Color3.fromRGB(255, 100, 100))
	end
end)

-- Auto Load Storage
if readfile and isfile and isfile("ikyyxd_startergui_data.dat") then
	pcall(function()
		local content = readfile("ikyyxd_startergui_data.dat")
		local decoded = HttpService:JSONDecode(content)
		if type(decoded) == "table" then
			savedGuiStorage = decoded
			refreshResultList()
			setConsoleMessage("Loaded saved GUI data")
		end
	end)
end
