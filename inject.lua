--[[\
    Project: Mini-DEX Explorer & Script Editor (Hierarki Interaktif)
    Author: sptzyy / IkyyXD
]]--

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

if CoreGui:FindFirstChild("SptzyyMiniDex") then
    CoreGui.SptzyyMiniDex:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SptzyyMiniDex"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Main Frame (Di tengah / melayang)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 680, 0, 420)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 229, 255)
UIStroke.Transparency = 0.4
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Top Bar (Dragging Handler)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -120, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "sptzyy // Mini-DEX Explorer & Inspector"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleLabel.TextSize = 12
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 45, 0, 22)
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -10, 0.5, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 11
CloseBtn.Parent = TopBar
local CloseCorner = Instance.new("UICorner") CloseCorner.CornerRadius = UDim.new(0, 6) CloseCorner.Parent = CloseBtn

-- === PANEL KIRI: Preview Info, Tombol Save, & Editor Script ===
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.45, -8, 1, -50)
LeftPanel.Position = UDim2.new(0, 8, 0, 42)
LeftPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = MainFrame
local LeftCorner = Instance.new("UICorner") LeftCorner.CornerRadius = UDim.new(0, 8) LeftCorner.Parent = LeftPanel

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, -70, 0, 25)
LeftTitle.Position = UDim2.new(0, 8, 0, 8)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.Text = "Preview & Editor"
LeftTitle.TextColor3 = Color3.fromRGB(0, 229, 255)
LeftTitle.TextSize = 12
LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
LeftTitle.Parent = LeftPanel

-- Tombol Save File .txt di sudut kiri atas panel preview
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0, 55, 0, 22)
SaveBtn.Position = UDim2.new(1, -60, 0, 9)
SaveBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "💾 Save"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize = 10
SaveBtn.Parent = LeftPanel
local SaveCorner = Instance.new("UICorner") SaveCorner.CornerRadius = UDim.new(0, 5) SaveCorner.Parent = SaveBtn

local InfoBox = Instance.new("TextBox")
InfoBox.Size = UDim2.new(1, -16, 1, -42)
InfoBox.Position = UDim2.new(0, 8, 0, 36)
InfoBox.BackgroundTransparency = 1
InfoBox.MultiLine = true
InfoBox.ClearTextOnFocus = false
InfoBox.TextEditable = true
InfoBox.Font = Enum.Font.Code
InfoBox.Text = "-- Klik objek/folder di panel kanan untuk melihat isinya di sini."
InfoBox.TextColor3 = Color3.fromRGB(0, 255, 180)
InfoBox.TextSize = 11
InfoBox.TextXAlignment = Enum.TextXAlignment.Left
InfoBox.TextYAlignment = Enum.TextYAlignment.Top
InfoBox.Parent = LeftPanel

-- === PANEL KANAN: Search & Explorer Daftar Objek ===
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.55, -12, 1, -50)
RightPanel.Position = UDim2.new(0.45, 4, 0, 42)
RightPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
local RightCorner = Instance.new("UICorner") RightCorner.CornerRadius = UDim.new(0, 8) RightCorner.Parent = RightPanel

-- Kotak Search Object di atas Panel Kanan
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -16, 0, 28)
SearchBox.Position = UDim2.new(0, 8, 0, 8)
SearchBox.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
SearchBox.ClearTextOnFocus = false
SearchBox.Font = Enum.Font.Gotham
SearchBox.PlaceholderText = "🔍 Cari objek..."
SearchBox.Text = ""
SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SearchBox.TextSize = 11
SearchBox.Parent = RightPanel
local SearchCorner = Instance.new("UICorner") SearchCorner.CornerRadius = UDim.new(0, 6) SearchCorner.Parent = SearchBox

-- Tombol Kembali (Back) jika sedang membuka isi folder
local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(1, -16, 0, 24)
BackBtn.Position = UDim2.new(0, 8, 0, 40)
BackBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
BackBtn.Font = Enum.Font.GothamBold
BackBtn.Text = "⬅️ [ KEMBALI KE ROOT ]"
BackBtn.TextColor3 = Color3.fromRGB(0, 229, 255)
BackBtn.TextSize = 11
BackBtn.Visible = false
BackBtn.Parent = RightPanel
local BackCorner = Instance.new("UICorner") BackCorner.CornerRadius = UDim.new(0, 5) BackCorner.Parent = BackBtn

-- ScrollingFrame untuk Daftar Objek
local ObjectScroll = Instance.new("ScrollingFrame")
ObjectScroll.Size = UDim2.new(1, -16, 1, -74)
ObjectScroll.Position = UDim2.new(0, 8, 0, 68)
ObjectScroll.BackgroundTransparency = 1
ObjectScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ObjectScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
ObjectScroll.ScrollBarThickness = 4
ObjectScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 229, 255)
ObjectScroll.Parent = RightPanel

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 4)
UIList.Parent = ObjectScroll

local currentParentInstance = nil

-- Fungsi untuk Menampilkan Daftar Objek (Hierarki / Isi dalam Folder)
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
		ObjectScroll.Size = UDim2.new(1, -16, 1, -45)
		ObjectScroll.Position = UDim2.new(0, 8, 0, 40)
		
		itemsToDisplay = {
			game:GetService("Workspace"),
			game:GetService("Players"),
			game:GetService("Lighting"),
			game:GetService("ReplicatedStorage"),
			game:GetService("ReplicatedFirst"),
			game:GetService("ServerStorage"),
			game:GetService("ServerScriptService"),
			game:GetService("StarterGui"),
		}
	else
		BackBtn.Visible = true
		ObjectScroll.Size = UDim2.new(1, -16, 1, -74)
		ObjectScroll.Position = UDim2.new(0, 8, 0, 68)
		itemsToDisplay = instanceToExplore:GetChildren()
	end

	for _, item in ipairs(itemsToDisplay) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 24)
		btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		btn.Font = Enum.Font.GothamMedium
		
		-- Tentukan ikon berdasarkan ClassName
		local icon = "📦 "
		if item:IsA("Folder") or item:IsA("Model") then
			icon = "📁 "
		elseif item:IsA("Part") or item:IsA("UnionOperation") or item:IsA("MeshPart") then
			icon = "🧱 "
		elseif item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript") then
			icon = "📜 "
		elseif item:IsA("Workspace") or item:IsA("Lighting") or item:IsA("ReplicatedStorage") then
			icon = "🌐 "
		end

		btn.Text = " " .. icon .. item.Name .. " [" .. item.ClassName .. "]"
		btn.TextColor3 = Color3.fromRGB(220, 220, 220)
		btn.TextSize = 11
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = ObjectScroll
		
		local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = btn

		-- Aksi saat item diklik (Klik 1x untuk preview info / script, Klik 2x atau tahan untuk masuk ke dalam folder)
		btn.MouseButton1Click:Connect(function()
			-- Tampilkan info/source code di panel kiri
			local infoText = string.format("-- Nama: %s\n-- Kelas: %s\n-- Parent: %s\n\n", item.Name, item.ClassName, tostring(item.Parent))
			
			if (item:IsA("Script") or item:IsA("LocalScript") or item:IsA("ModuleScript")) then
				infoText = infoText .. "-- [Source Code Script]:\n"
				local success, src = pcall(function() return item.Source end)
				if success and src ~= "" then
					infoText = infoText .. src
				else
					infoText = infoText .. "-- (Source terkunci atau kosong)"
				end
			else
				infoText = infoText .. "[Isi / Children (" .. #item:GetChildren() .. " item)]:\n"
				for _, sub in ipairs(item:GetChildren()) do
					infoText = infoText .." - " .. sub.Name .. " (" .. sub.ClassName .. ")\n"
				end
			end
			InfoBox.Text = infoText
		end)

		-- Jika item punya isi (folder/model/layanan), klik dua kali atau tekan tombol untuk masuk ke dalam
		btn.MouseButton2Click:Connect(function()
			if #item:GetChildren() > 0 or item:IsA("Folder") or item:IsA("Model") then
				LoadDirectory(item)
			end
		end)
		
		-- Tambahan shortcut agar klik teks kecil di ujung kanan bisa masuk folder
		local enterBtn = Instance.new("TextButton")
		enterBtn.Size = UDim2.new(0, 45, 1, 0)
		enterBtn.Position = UDim2.new(1, -45, 0, 0)
		enterBtn.BackgroundTransparency = 1
		enterBtn.Font = Enum.Font.GothamBold
		enterBtn.Text = "Buka ➡️"
		enterBtn.TextColor3 = Color3.fromRGB(0, 229, 255)
		enterBtn.TextSize = 9
		enterBtn.Parent = btn
		
		enterBtn.MouseButton1Click:Connect(function()
			LoadDirectory(item)
		end)
	end
end

-- Muat direktori awal (Root)
LoadDirectory(nil)

-- Tombol Kembali ke Root
BackBtn.MouseButton1Click:Connect(function()
	if currentParentInstance and currentParentInstance.Parent and currentParentInstance.Parent ~= game then
		LoadDirectory(currentParentInstance.Parent)
	else
		LoadDirectory(nil)
	end
end)

-- Fitur Search Box (Pencarian Objek)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	local query = SearchBox.Text:lower()
	if query == "" then
		LoadDirectory(currentParentInstance)
		return
	end

	for _, child in ipairs(ObjectScroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	local function searchRecursive(parentObj)
		for _, obj in ipairs(parentObj:GetChildren()) do
			if obj.Name:lower():find(query) or obj.ClassName:lower():find(query) then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 24)
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				btn.Font = Enum.Font.GothamMedium
				btn.Text = " 🔍 " .. obj.Name .. " [" .. obj.ClassName .. "]"
				btn.TextColor3 = Color3.fromRGB(220, 220, 220)
				btn.TextSize = 11
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = ObjectScroll
				local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(0, 4) bc.Parent = btn

				btn.MouseButton1Click:Connect(function()
					local infoText = string.format("-- Nama: %s\n-- Kelas: %s\n-- Parent: %s\n\n", obj.Name, obj.ClassName, tostring(obj.Parent))
					if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
						local success, src = pcall(function() return obj.Source end)
						infoText = infoText .. (success and src or "-- (Source terkunci)")
					else
						infoText = infoText .. "[Isi / Children]:\n"
						for _, sub in ipairs(obj:GetChildren()) do
							infoText = infoText .. " - " .. sub.Name .. " (" .. sub.ClassName .. ")\n"
						end
					end
					InfoBox.Text = infoText
				end)
			end
			if #ObjectScroll:GetChildren() < 100 then
				searchRecursive(obj)
			end
		end
	end

	searchRecursive(game:GetService("Workspace"))
end)

-- Tombol Save File .txt ke internal penyimpanan executor
SaveBtn.MouseButton1Click:Connect(function()
	if writefile then
		local filename = "sptzyy_dex_export_" .. os.time() .. ".txt"
		writefile(filename, InfoBox.Text)
		InfoBox.Text = "-- [SUCCESS] Berhasil disimpan ke internal file: workspace/" .. filename .. "\n\n" .. InfoBox.Text
	else
		InfoBox.Text = "-- [ERROR] Executor Anda tidak mendukung fungsi writefile()\n\n" .. InfoBox.Text
	end
end)

-- Tombol Close Aksi
CloseBtn.MouseButton1Click:Connect(function()
	ScreenGui:Destroy()
end)

-- Sistem Dragging Jendela Utama
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
