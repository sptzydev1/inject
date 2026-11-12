--[[\
    Project: IKYYXD DEX1.0 StarterGui Copier & Injector Edition
    Author: sptzyy / IkyyXD
]]--

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
TitleLabel.Size = UDim2.new(1, -130, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "IKYYXD DEX1.0 // Gui Copier"
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

-- === PANEL KIRI: Preview Properti, Tombol COPY, PASTE, & SAVE ===
local LeftPanel = Instance.new("Frame")
LeftPanel.Size = UDim2.new(0.45, -6, 1, -40)
LeftPanel.Position = UDim2.new(0, 6, 0, 34)
LeftPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
LeftPanel.BorderSizePixel = 0
LeftPanel.Parent = MainFrame
local LeftCorner = Instance.new("UICorner") LeftCorner.CornerRadius = UDim.new(0, 6) LeftCorner.Parent = LeftPanel

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, -165, 0, 22)
LeftTitle.Position = UDim2.new(0, 6, 0, 6)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.Text = "Properties"
LeftTitle.TextColor3 = Color3.fromRGB(0, 229, 255)
LeftTitle.TextSize = 11
LeftTitle.TextXAlignment = Enum.TextXAlignment.Left
LeftTitle.Parent = LeftPanel

-- Tombol PASTE (Tempel ke StarterGui / PlayerGui)
local PasteBtn = Instance.new("TextButton")
PasteBtn.Size = UDim2.new(0, 45, 0, 20)
PasteBtn.Position = UDim2.new(1, -160, 0, 7)
PasteBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
PasteBtn.Font = Enum.Font.GothamBold
PasteBtn.Text = "PASTE"
PasteBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
PasteBtn.TextSize = 8
PasteBtn.Parent = LeftPanel
local PasteCorner = Instance.new("UICorner") PasteCorner.CornerRadius = UDim.new(0, 4) PasteCorner.Parent = PasteBtn

-- Tombol COPY
local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 45, 0, 20)
CopyBtn.Position = UDim2.new(1, -110, 0, 7)
CopyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Font = Enum.Font.GothamBold
CopyBtn.Text = "COPY"
CopyBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
CopyBtn.TextSize = 8
CopyBtn.Parent = LeftPanel
local CopyCorner = Instance.new("UICorner") CopyCorner.CornerRadius = UDim.new(0, 4) CopyCorner.Parent = CopyBtn

-- Tombol SAVE
local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0, 50, 0, 20)
SaveBtn.Position = UDim2.new(1, -60, 0, 7)
SaveBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
SaveBtn.TextSize = 8
SaveBtn.Parent = LeftPanel
local SaveCorner = Instance.new("UICorner") SaveCorner.CornerRadius = UDim.new(0, 4) SaveCorner.Parent = SaveBtn

-- ScrollingFrame Preview Properti GUI
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
InfoBox.Text = "-- Pilih objek GUI di sebelah kanan untuk melihat properti akuratnya."
InfoBox.TextColor3 = Color3.fromRGB(240, 240, 240)
InfoBox.TextSize = 10
InfoBox.TextXAlignment = Enum.TextXAlignment.Left
InfoBox.TextYAlignment = Enum.TextYAlignment.Top
InfoBox.Parent = PreviewScroll

InfoBox:GetPropertyChangedSignal("Text"):Connect(function()
	InfoBox.Size = UDim2.new(1, 0, 0, InfoBox.TextBounds.Y + 40)
	PreviewScroll.CanvasSize = UDim2.new(0, 0, 0, InfoBox.TextBounds.Y + 40)
end)

-- === PANEL KANAN: Navigasi StarterGui & Pemilihan Objek ===
local RightPanel = Instance.new("Frame")
RightPanel.Size = UDim2.new(0.55, -10, 1, -40)
RightPanel.Position = UDim2.new(0.45, 4, 0, 34)
RightPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
RightPanel.BorderSizePixel = 0
RightPanel.Parent = MainFrame
local RightCorner = Instance.new("UICorner") RightCorner.CornerRadius = UDim.new(0, 6) RightCorner.Parent = RightPanel

-- Tombol Kembali (Back)
local BackBtn = Instance.new("TextButton")
BackBtn.Size = UDim2.new(1, -12, 0, 22)
BackBtn.Position = UDim2.new(0, 6, 0, 6)
BackBtn.BackgroundColor3 = Color3.fromRGB(0, 229, 255)
BackBtn.Font = Enum.Font.GothamBold
BackBtn.Text = "[ KEMBALI KE STARTERGUI ]"
BackBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
BackBtn.TextSize = 9
BackBtn.Visible = false
BackBtn.Parent = RightPanel
local BackCorner = Instance.new("UICorner") BackCorner.CornerRadius = UDim.new(0, 4) BackCorner.Parent = BackBtn

-- ScrollingFrame untuk Daftar Objek GUI
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
local activeSelectedInstance = nil
local copiedInstanceData = nil -- Menyimpan salinan objek GUI

-- Fungsi untuk Menampilkan Hierarki StarterGui & PlayerGui
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
		
		-- Root utama GUI game
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer and localPlayer:FindFirstChild("PlayerGui")
		
		itemsToDisplay = {
			StarterGui,
			playerGui
		}
	else
		BackBtn.Visible = true
		ObjectScroll.Size = UDim2.new(1, -12, 1, -36)
		ObjectScroll.Position = UDim2.new(0, 6, 0, 30)
		itemsToDisplay = instanceToExplore:GetChildren()
	end

	for _, item in ipairs(itemsToDisplay) do
		if item then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 22)
			btn.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
			btn.Font = Enum.Font.GothamMedium
			
			local labelTag = "[GUI] "
			if item:IsA("ScreenGui") then
				labelTag = "[SG] "
			elseif item:IsA("Frame") then
				labelTag = "[FRM] "
			elseif item:IsA("TextButton") or item:IsA("ImageButton") then
				labelTag = "[BTN] "
			elseif item:IsA("TextLabel") or item:IsA("ImageLabel") then
				labelTag = "[LBL] "
			elseif item:IsA("Folder") then
				labelTag = "[DIR] "
			end

			btn.TextTruncate = Enum.TextTruncate.AtEnd
			btn.Text = " " .. labelTag .. item.Name
			btn.TextColor3 = Color3.fromRGB(240, 240, 240)
			btn.TextSize = 10
			btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = ObjectScroll
			
			local btnCorner = Instance.new("UICorner") btnCorner.CornerRadius = UDim.new(0, 4) btnCorner.Parent = btn

			-- Klik item untuk melihat Properti Akuratnya
			btn.MouseButton1Click:Connect(function()
				activeSelectedInstance = item
				
				local propText = string.format("-- [PROPERTIES: %s]\n-- ClassName: %s\n-- Parent: %s\n\n", item.Name, item.ClassName, tostring(item.Parent))
				
				-- Ambil properti umum yang akurat sesuai aslinya
				pcall(function()
					if item:IsA("GuiObject") or item:IsA("LayerCollector") then
						propText = propText .. string.format("Size = UDim2.new(%s)\n", tostring(item.Size))
						propText = propText .. string.format("Position = UDim2.new(%s)\n", tostring(item.Position))
						propText = propText .. string.format("BackgroundColor3 = Color3.fromRGB(%d, %d, %d)\n", item.BackgroundColor3.R*255, item.BackgroundColor3.G*255, item.BackgroundColor3.B*255)
						propText = propText .. string.format("BackgroundTransparency = %.2f\n", item.BackgroundTransparency)
						propText = propText .. string.format("Visible = %s\n", tostring(item.Visible))
					end
					if item:IsA("TextButton") or item:IsA("TextLabel") or item:IsA("TextBox") then
						propText = propText .. string.format("Text = \"%s\"\n", item.Text)
						propText = propText .. string.format("TextSize = %d\n", item.TextSize)
						propText = propText .. string.format("TextColor3 = Color3.fromRGB(%d, %d, %d)\n", item.TextColor3.R*255, item.TextColor3.G*255, item.TextColor3.B*255)
					end
				end)

				propText = propText .. "\n[Children (" .. #item:GetChildren() .. ")]:\n"
				for _, sub in ipairs(item:GetChildren()) do
					propText = propText .. " - " .. sub.Name .. " (" .. sub.ClassName .. ")\n"
				end

				InfoBox.Text = propText
			end)

			-- Tombol Buka jika objek memiliki anak (children)
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
end

LoadDirectory(nil)

BackBtn.MouseButton1Click:Connect(function()
	if currentParentInstance and currentParentInstance.Parent and currentParentInstance.Parent ~= game then
		LoadDirectory(currentParentInstance.Parent)
	else
		LoadDirectory(nil)
	end
end)

-- Tombol COPY (Menyalin objek GUI yang sedang dipilih)
CopyBtn.MouseButton1Click:Connect(function()
	if not activeSelectedInstance then
		InfoBox.Text = "-- [ERROR] Pilih objek GUI terlebih dahulu di panel kanan untuk di-COPY!"
		return
	end

	pcall(function()
		copiedInstanceData = activeSelectedInstance:Clone()
		InfoBox.Text = string.format("-- [SUCCESS] Objek '%s (%s)' berhasil di-COPY ke memori!\n-- Sekarang Anda bisa pindah ke game lain dan tekan tombol PASTE.", activeSelectedInstance.Name, activeSelectedInstance.ClassName)
	end)
end)

-- Tombol PASTE (Menempelkan objek GUI yang disalin ke StarterGui / PlayerGui)
PasteBtn.MouseButton1Click:Connect(function()
	if not copiedInstanceData then
		InfoBox.Text = "-- [ERROR] Belum ada objek GUI yang di-COPY!"
		return
	end

	local success, err = pcall(function()
		local targetParent = StarterGui
		local lp = Players.LocalPlayer
		if lp and lp:FindFirstChild("PlayerGui") then
			targetParent = lp.PlayerGui
		end

		local clonedObj = copiedInstanceData:Clone()
		clonedObj.Parent = targetParent
		InfoBox.Text = string.format("-- [SUCCESS] Objek '%s' berhasil di-PASTE ke dalam game (%s)!", clonedObj.Name, targetParent.Name)
	end)

	if not success then
		InfoBox.Text = string.format("-- [PASTE FAILED]: %s", tostring(err))
	end
end)

-- Tombol SAVE (Menyimpan data properti ke file teks internal)
SaveBtn.MouseButton1Click:Connect(function()
	if writefile then
		local filename = "IKYYXD_GuiBackup_" .. os.time() .. ".txt"
		writefile(filename, InfoBox.Text)
		InfoBox.Text = "-- [SAVED] workspace/" .. filename .. "\n\n" .. InfoBox.Text
	else
		InfoBox.Text = "-- [ERROR] writefile() tidak didukung di executor ini.\n\n" .. InfoBox.Text
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
