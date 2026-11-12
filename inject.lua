--[[\
    Project: IKYYXD DEX1.0 Remote Explorer & Injector Edition
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
TitleLabel.Text = "IKYYXD DEX1.0 // Remotes"
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

-- === PANEL KIRI: Console & Remote Fire Injector ===
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
LeftTitle.Text = "Remote Injector"
LeftTitle.TextColor3 = Color3.fromRGB(0, 229, 255)
LeftTitle.TextSize = 11
LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
LeftTitle.Parent = LeftPanel

-- Tombol Fire / Invoke Remote yang dipilih
local FireBtn = Instance.new("TextButton")
FireBtn.Size = UDim2.new(0, 52, 0, 20)
FireBtn.Position = UDim2.new(1, -110, 0, 7)
FireBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
FireBtn.Font = Enum.Font.GothamBold
FireBtn.Text = "FIRE"
FireBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
FireBtn.TextSize = 9
FireBtn.Parent = LeftPanel
local FireCorner = Instance.new("UICorner") FireCorner.CornerRadius = UDim.new(0, 4) FireCorner.Parent = FireBtn

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

-- ScrollingFrame Preview & Argumen Remote
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
InfoBox.Text = "-- Klik salah satu RemoteEvent / RemoteFunction di kanan untuk mengakses & Fire."
InfoBox.TextColor3 = Color3.fromRGB(240, 240, 240)
InfoBox.TextSize = 10
InfoBox.TextXAlignment = Enum.TextXAlignment.Left
InfoBox.TextYAlignment = Enum.TextYAlignment.Top
InfoBox.Parent = PreviewScroll

InfoBox:GetPropertyChangedSignal("Text"):Connect(function()
	InfoBox.Size = UDim2.new(1, 0, 0, InfoBox.TextBounds.Y + 40)
	PreviewScroll.CanvasSize = UDim2.new(0, 0, 0, InfoBox.TextBounds.Y + 40)
end)

-- === PANEL KANAN: Scan Remotes & Daftar Objek ===
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.55, -10, 1, -40)
RightPanel.Position = UDim2.new(0.45, 4, 0, 34)
RightPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
local RightCorner = Instance.new("UICorner") RightCorner.CornerRadius = UDim.new(0, 6) RightCorner.Parent = RightPanel

-- Tombol Khusus Scan Remotes
local ScanRemotesBtn = Instance.new("TextButton")
ScanRemotesBtn.Size = UDim2.new(1, -12, 0, 24)
ScanRemotesBtn.Position = UDim2.new(0, 6, 0, 6)
ScanRemotesBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
ScanRemotesBtn.Font = Enum.Font.GothamBold
ScanRemotesBtn.Text = "SCAN ALL REMOTES"
ScanRemotesBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
ScanRemotesBtn.TextSize = 10
ScanRemotesBtn.Parent = RightPanel
local ScanCorner = Instance.new("UICorner") ScanCorner.CornerRadius = UDim.new(0, 5) ScanCorner.Parent = ScanRemotesBtn

-- ScrollingFrame untuk Daftar Remotes
local ObjectScroll = Instance.new("ScrollingFrame")
ObjectScroll.Size = UDim2.new(1, -12, 1, -38)
ObjectScroll.Position = UDim2.new(0, 6, 0, 34)
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

local selectedRemote = nil

-- Fungsi untuk MenScan dan Menampilkan Semua RemoteEvent & RemoteFunction di Game
local function ScanRemotes()
	for _, child in ipairs(ObjectScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	InfoBox.Text = "-- Memindai seluruh RemoteEvent & RemoteFunction dalam game..."

	local foundRemotes = {}
	
	-- Scan dari ReplicatedStorage, Workspace, dan Players
	local containers = {ReplicatedStorage, Workspace}
	for _, container in ipairs(containers) do
		local success, descendants = pcall(function() return container:GetDescendants() end)
		if success and descendants then
			for _, obj in ipairs(descendants) do
				if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
					table.insert(foundRemotes, obj)
				end
			end
		end
	end

	if #foundRemotes == 0 then
		InfoBox.Text = "-- Tidak ditemukan RemoteEvent/RemoteFunction."
		return
	end

	for _, remote in ipairs(foundRemotes) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
		btn.Font = Enum.Font.GothamMedium
		
		local tag = remote:IsA("RemoteEvent") and "[RE] " or "[RF] "
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		btn.Text = " " .. tag .. remote.Name
		btn.TextColor3 = Color3.fromRGB(240, 240, 240)
		btn.TextSize = 10
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = ObjectScroll
		
		local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			selectedRemote = remote
			local path = remote:GetFullName()
			InfoBox.Text = string.format("-- Dipilih: %s\n-- Tipe: %s\n-- Path: %s\n\n-- Ketik argumen di bawah ini lalu klik FIRE untuk eksekusi:\narguments = {\n    \"arg1\",\n    123\n}", remote.Name, remote.ClassName, path)
		end)
	end
	
	InfoBox.Text = string.format("-- Selesai memindai! Ditemukan %d Remotes. Silakan pilih salah satu di panel kanan.", #foundRemotes)
end

ScanRemotes()

ScanRemotesBtn.MouseButton1Click:Connect(function()
	ScanRemotes()
end)

-- Tombol Fire / Invoke Remote Terpilih
FireBtn.MouseButton1Click:Connect(function()
	if not selectedRemote then
		InfoBox.Text = "-- [ERROR] Belum ada Remote yang dipilih dari panel kanan!"
		return
	end

	local success, err = pcall(function()
		if selectedRemote:IsA("RemoteEvent") then
			selectedRemote:FireServer("IKYYXD_Injected", os.time())
			InfoBox.Text = string.format("-- [SUCCESS] Berhasil FireServer() pada: %s", selectedRemote.Name)
		elseif selectedRemote:IsA("RemoteFunction") then
			local res = selectedRemote:InvokeServer("IKYYXD_Injected", os.time())
			InfoBox.Text = string.format("-- [SUCCESS] Berhasil InvokeServer() pada: %s\n-- Hasil Response: %s", selectedRemote.Name, tostring(res))
		end
	end)

	if not success then
		InfoBox.Text = string.format("-- [FIRE FAILED]: %s", tostring(err))
	end
end)

SaveBtn.MouseButton1Click:Connect(function()
	if writefile then
		local filename = "IKYYXD_Remotes_" .. os.time() .. ".txt"
		writefile(filename, InfoBox.Text)
		InfoBox.Text = "-- [SAVED] workspace/" .. filename .. "\n\n" .. InfoBox.Text
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
