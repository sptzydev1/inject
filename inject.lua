--[[\
    Project: Mini-DEX Explorer & Script Editor (With Save & Search)
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
MainFrame.Size = UDim2.new(0, 660, 0, 400)
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
TitleLabel.Text = "sptzyy // Mini-DEX Object & Script Inspector"
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

-- Tombol Icon File Save di Sudut Kiri Atas Panel Preview
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
InfoBox.Text = "-- Klik objek di panel kanan untuk melihat & mengedit isinya di sini."
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

-- ScrollingFrame untuk Daftar Objek
local ObjectScroll = Instance.new("ScrollingFrame")
ObjectScroll.Size = UDim2.new(1, -16, 1, -45)
ObjectScroll.Position = UDim2.new(0, 8, 0, 40)
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

-- Fungsi untuk Mengisi Daftar Objek Game dengan Filter Search
local function PopulateExplorer(filter)
	for _, child in ipairs(ObjectScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local roots = {
		game:GetService("Workspace"),
		game:GetService("Players"),
		game:GetService("Lighting"),
		game:GetService("ReplicatedStorage"),
		game:GetService("ReplicatedFirst"),
		game:GetService("ServerStorage"),
		game:GetService("ServerScriptService"),
		game:GetService("StarterGui"),
	}

	filter = filter:lower()

	for _, root in ipairs(roots) do
		-- Rekursif untuk mencakup anak objek jika menggunakan search
		local function scanInstance(inst)
			local match = (filter == "") or (inst.Name:lower():find(filter)) or (inst.ClassName:lower():find(filter))
			
			if match then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 24)
				btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
				btn.Font = Enum.Font.GothamMedium
				btn.Text = "📁 " .. inst.Name .. " [" .. inst.ClassName .. "]"
				btn.TextColor3 = Color3.fromRGB(220, 220, 220)
				btn.TextSize = 11
				btn.TextXAlignment = Enum.TextXAlignment.Left
				btn.Parent = ObjectScroll
				
				local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = btn

				-- Aksi saat objek diklik
				btn.MouseButton1Click:Connect(function()
					local infoText = string.format("-- Nama: %s\n-- Kelas: %s\n-- Parent: %s\n\n", inst.Name, inst.ClassName, tostring(inst.Parent))
					
					-- Jika objek adalah Script atau LocalScript, coba tampilkan sourcenya jika diizinkan executor
					if (inst:IsA("Script") or inst:IsA("LocalScript") or inst:IsA("ModuleScript")) then
						infoText = infoText .. "-- [Source Code Script]:\n"
						local success, src = pcall(function()
							return inst.Source
						end)
						if success and src ~= "" then
							infoText = infoText .. src
						else
							infoText = infoText .. "-- (Source terkunci atau kosong di sisi client)"
						end
					else
						infoText = infoText .. "[Isi / Children]:\n"
						for _, sub in ipairs(inst:GetChildren()) do
							infoText = infoText .. " - " .. sub.Name .. " (" .. sub.ClassName .. ")\n"
						end
					end
					
					InfoBox.Text = infoText
				end)
			end

			-- Batasi kedalaman pencarian agar ringan
			for _, child in ipairs(inst:GetChildren()) do
				if #ObjectScroll:GetChildren() < 150 then -- Batasi max item list agar tidak lag
					scanInstance(child)
				end
			end
		end

		scanInstance(root)
	end
end

PopulateExplorer("")

-- Event saat mengetik di SearchBox
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	PopulateExplorer(SearchBox.Text)
end)

-- Tombol Save File Aksi (.txt ke internal penyimpanan executor)
SaveBtn.MouseButton1Click:Connect(function()
	if writefile then
		local filename = "sptzyy_export_" .. os.time() .. ".txt"
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
