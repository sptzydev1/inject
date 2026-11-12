--[[\
    Project: IKYYXD DEX1.0 Donate Effect Folder Injector & Runner
    Author: sptzyy / IkyyXD
]]--

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

if CoreGui:FindFirstChild("IKYYXDDEX") then
    CoreGui.IKYYXDDEX:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IKYYXDDEX"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Main Frame (Kompak untuk HP - 540 x 340)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 340)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Garis pinggir Neon Cyan terang
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 229, 255)
UIStroke.Transparency = 0.2
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Top Bar (Dragging Handler)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -90, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "IKYYXD DEX1.0 // Donate Injector"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 11
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 35, 0, 20)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -8, 0.5, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
CloseBtn.TextSize = 10
CloseBtn.Parent = TopBar
local CloseCorner = Instance.new("UICorner") CloseCorner.CornerRadius = UDim.new(0, 5) CloseCorner.Parent = CloseBtn

-- === PANEL KIRI: Info & Tombol INJECT FOLDER ===
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.45, -6, 1, -40)
LeftPanel.Position = UDim2.new(0, 6, 0, 34)
LeftPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = MainFrame
local LeftCorner = Instance.new("UICorner") LeftCorner.CornerRadius = UDim.new(0, 6) LeftCorner.Parent = LeftPanel

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, -115, 0, 22)
LeftTitle.Position = UDim2.new(0, 6, 0, 6)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.Text = "Folder Controller"
LeftTitle.TextColor3 = Color3.fromRGB(0, 229, 255)
LeftTitle.TextSize = 11
LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
LeftTitle.Parent = LeftPanel

-- Tombol INJECT (Run Semua Remote di dalam Folder Terpilih)
local InjectBtn = Instance.new("TextButton")
InjectBtn.Size = UDim2.new(0, 52, 0, 20)
InjectBtn.Position = UDim2.new(1, -110, 0, 7)
InjectBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
InjectBtn.Font = Enum.Font.GothamBold
InjectBtn.Text = "INJECT"
InjectBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
InjectBtn.TextSize = 9
InjectBtn.Parent = LeftPanel
local InjectCorner = Instance.new("UICorner") InjectCorner.CornerRadius = UDim.new(0, 4) InjectCorner.Parent = InjectBtn

-- Tombol Save Log
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0, 50, 0, 20)
SaveBtn.Position = UDim2.new(1, -54, 0, 7)
SaveBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
SaveBtn.TextSize = 9
SaveBtn.Parent = LeftPanel
local SaveCorner = Instance.new("UICorner") SaveCorner.CornerRadius = UDim.new(0, 4) SaveCorner.Parent = SaveBtn

-- ScrollingFrame Preview Informasi Folder yang Dipilih
local PreviewScroll = Instance.new("ScrollingFrame")
PreviewScroll.Size = UDim2.new(1, -12, 1, -34)
PreviewScroll.Position = UDim2.new(0, 6, 0, 30)
PreviewScroll.BackgroundTransparency = 1
PreviewScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PreviewScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PreviewScroll.ScrollBarThickness = 3
PreviewScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 229, 255)
PreviewScroll.Parent = LeftPanel

local InfoBox = Instance.new("TextBox")
InfoBox.Size = UDim2.new(1, 0, 1, 0)
InfoBox.Position = UDim2.new(0, 0, 0, 0)
InfoBox.BackgroundTransparency = 1
InfoBox.MultiLine = true
InfoBox.ClearTextOnFocus = false
InfoBox.TextWrapped = true
InfoBox.TextEditable = true
InfoBox.Font = Enum.Font.Code
InfoBox.Text = "-- Buka ReplicatedStorage, pilih folder Efek Donate di kanan, lalu klik INJECT untuk merun semua isinya."
InfoBox.TextColor3 = Color3.fromRGB(240, 240, 240)
InfoBox.TextSize = 10
InfoBox.TextXAlignment = Enum.TextXAlignment.Left
InfoBox.TextYAlignment = Enum.TextYAlignment.Top
InfoBox.Parent = PreviewScroll

InfoBox:GetPropertyChangedSignal("Text"):Connect(function()
	InfoBox.Size = UDim2.new(1, 0, 0, InfoBox.TextBounds.Y + 40)
	PreviewScroll.CanvasSize = UDim2.new(0, 0, 0, InfoBox.TextBounds.Y + 40)
end)

-- === PANEL KANAN: Navigasi Folder Efek Donate ===
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.55, -10, 1, -40)
RightPanel.Position = UDim2.new(0.45, 4, 0, 34)
RightPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
local RightCorner = Instance.new("UICorner") RightCorner.CornerRadius = UDim.new(0, 6) RightCorner.Parent = RightPanel

-- Tombol Kembali (Back) untuk direktori folder
local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(1, -12, 0, 22)
BackBtn.Position = UDim2.new(0, 6, 0, 6)
BackBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
BackBtn.Font = Enum.Font.GothamBold
BackBtn.Text = "[ KEMBALI KE ROOT ]"
BackBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
BackBtn.TextSize = 10
BackBtn.Visible = false
BackBtn.Parent = RightPanel
local BackCorner = Instance.new("UICorner") BackCorner.CornerRadius = UDim.new(0, 4) BackCorner.Parent = BackBtn

-- ScrollingFrame untuk Daftar Folder
local ObjectScroll = Instance.new("ScrollingFrame")
ObjectScroll.Size = UDim2.new(1, -12, 1, -12)
ObjectScroll.Position = UDim2.new(0, 6, 0, 6)
ObjectScroll.BackgroundTransparency = 1
ObjectScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ObjectScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ObjectScroll.ScrollBarThickness = 3
ObjectScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 229, 255)
ObjectScroll.Parent = RightPanel

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 3)
UIList.Parent = ObjectScroll

local currentParentInstance = nil
local activeFolder = nil

-- Fungsi untuk Navigasi Folder Game
local function LoadDirectory(instanceToExplore)
	for _, child in ipairs(ObjectScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	currentParentInstance = instanceToExplore
	local itemsToDisplay = {}

	if instanceToExplore == nil then
		BackBtn.Visible = false
		ObjectScroll.Size = UDim2.new(1, -12, 1, -12)
		ObjectScroll.Position = UDim2.new(0, 6, 0, 6)
		
		itemsToDisplay = {
			ReplicatedStorage,
			Workspace,
			Players,
			game:GetService("Lighting"),
			game:GetService("ServerStorage"),
			game:GetService("ServerScriptService")
		}
	else
		BackBtn.Visible = true
		ObjectScroll.Size = UDim2.new(1, -12, 1, -36)
		ObjectScroll.Position = UDim2.new(0, 6, 0, 30)
		itemsToDisplay = instanceToExplore:GetChildren()
	end

	for _, item in ipairs(itemsToDisplay) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
		btn.Font = Enum.Font.GothamMedium
		
		local labelTag = "[OBJ] "
		if item:IsA("Folder") or item:IsA("Model") then
			labelTag = "[DIR] "
		elseif item:IsA("RemoteEvent") then
			labelTag = "[RE] "
		elseif item:IsA("RemoteFunction") then
			labelTag = "[RF] "
		end

		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.Text = " " .. labelTag .. item.Name
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.TextSize = 10
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = ObjectScroll
		
		local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = btn

		-- Klik item untuk memilih folder efek donate atau melihat isinya
		btn.MouseButton1Click:Connect(function()
			if item:IsA("Folder") or item:IsA("Model") then
				activeFolder = item
				local infoText = string.format("-- Terpilih Folder Efek Donate:\n-- Nama: %s\n-- Path: %s\n\n[Isi Remote di dalam Folder]:\n", item.Name, item.GetFullName and item:GetFullName() or item.Name)
				for _, sub in ipairs(item:GetDescendants()) do
					if sub:IsA("RemoteEvent") or sub:IsA("RemoteFunction") then
						infoText = infoText .. " - " .. sub.Name .. " (" .. sub.ClassName .. ")\n"
					end
				end
				InfoBox.Text = infoText
			else
				activeFolder = nil
				InfoBox.Text = string.format("-- Terpilih Item Tunggal:\n-- Nama: %s\n-- Kelas: %s", item.Name, item.ClassName)
			end
		end)

		-- Tombol Buka jika folder memiliki anak item di dalamnya
		if #item:GetChildren() > 0 then
			local enterBtn = Instance.new("TextButton")
			enterBtn.Size = UDim2.new(0, 38, 1, 0)
			enterBtn.Position = UDim2.new(1, -38, 0, 0)
			enterBtn.BackgroundTransparency = 1
			enterBtn.Font = Enum.Font.GothamBold
			enterBtn.Text = "BUKA >"
			enterBtn.TextColor3 = Color3.fromRGB(0, 229, 255)
			enterBtn.TextSize = 8
			enterBtn.Parent = btn
			
			enterBtn.MouseButton1Click:Connect(function()
				LoadDirectory(item)
			end)
		end
	end
end

LoadDirectory(nil)

BackBtn.MouseButton1Click:Connect(function()
	if currentParentInstance and currentParentInstance.Parent and currentParentInstance.Parent ~= game then
		LoadDirectory(currentParentInstance.Parent)
	else
		LoadDirectory(nil)
	end
end)

-- Tombol INJECT (Menjalankan / Run seluruh Remote di dalam Folder Efek Donate yang dipilih)
InjectBtn.MouseButton1Click:Connect(function()
	if not activeFolder then
		InfoBox.Text = "-- [ERROR] Silakan pilih folder 'Efek Donate' terlebih dahulu di panel kanan!"
		return
	end

	local successCount = 0
	local failCount = 0

	pcall(function()
		-- Scan seluruh RemoteEvent dan RemoteFunction di dalam folder yang dipilih
		for _, descendant in ipairs(activeFolder:GetDescendants()) do
			if descendant:IsA("RemoteEvent") then
				local ok = pcall(function()
					descendant:FireServer("IKYYXD_DonateInject", true, 99999)
				end)
				if ok then successCount = successCount + 1 else failCount = failCount + 1 end
			elseif descendant:IsA("RemoteFunction") then
				local ok = pcall(function()
					descendant:InvokeServer("IKYYXD_DonateInject", true, 99999)
				end)
				if ok then successCount = successCount + 1 else failCount = failCount + 1 end
			end
		end
	end)

	InfoBox.Text = string.format("-- [INJECT SUCCESS & RUN] Folder: %s\n-- Berhasil Trigger Remotes: %d\n-- Gagal/Ditolak Server: %d\n\nEfek donate telah di-broadcast ke server dan dapat dilihat semua player!", activeFolder.Name, successCount, failCount)
end)

SaveBtn.MouseButton1Click:Connect(function()
	if writefile then
		local filename = "IKYYXD_DonateLog_" .. os.time() .. ".txt"
		writefile(filename, InfoBox.Text)
		InfoBox.Text = "-- [SAVED] workspace/" .. filename .. "\n\n" + InfoBox.Text
	else
		InfoBox.Text = "-- [ERROR] writefile() tidak didukung.\n\n" .. InfoBox.Text
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)
