-- [[ CONFIGURASI UTAMA UTK EXECUTOR ]]
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui

-- Hapus GUI lama jika sudah ada agar tidak menumpuk
if PlayerGui:FindFirstChild("ModernTitleGui") then
    PlayerGui.ModernTitleGui:Destroy()
end

-- [[ REMOTE EVENT SCANNER ]]
local ApplyTitleEvent = ReplicatedStorage:FindFirstChild("ApplyTitleEvent")
if not ApplyTitleEvent then
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") and (obj.Name:match("Title") or obj.Name:match("Tag")) then
            ApplyTitleEvent = obj
            break
        end
    end
end

-- [[ PEMBUATAN ELEMENT GUI (MODERN STYLE) ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernTitleGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main Frame (Cyberpunk Dark Minimalist)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 0, 180)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Jet Black / Dark Space
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

-- Rounded Corner (Pinggiran Melengkung Rapi)
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14) -- Lebih melengkung modern
MainCorner.Parent = MainFrame

-- Gradient Border (Efek Warna Gradasi di Pinggiran)
local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local BorderGradient = Instance.new("UIGradient")
BorderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),  -- Electric Blue
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))  -- Neon Purple
})
BorderGradient.Parent = MainStroke

-- Header Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "TITLE NETWORK CONTROLLER"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.Font = Enum.Font.GothamBold -- Font lebih modern
TitleLabel.TextSize = 12
TitleLabel.TextSpacing = 1 -- Jarak antar huruf elegan
TitleLabel.Parent = MainFrame

-- Subtitle/Status kecil di bawah header
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 15)
StatusLabel.Position = UDim2.new(0, 0, 0, 32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ApplyTitleEvent and "● SYSTEM CONNECTED" or "○ SYSTEM DISCONNECTED"
StatusLabel.TextColor3 = ApplyTitleEvent and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 80, 80)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 8
StatusLabel.Parent = MainFrame

-- Modern Input Box
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0, 220, 0, 38)
InputBox.Position = UDim2.new(0.5, -110, 0, 60)
InputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35) -- Glassmorphism base
InputBox.Text = ""
InputBox.PlaceholderText = "Enter custom title text..."
InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
InputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
InputBox.Font = Enum.Font.Gotham
InputBox.TextSize = 12
InputBox.ClearTextOnFocus = false
InputBox.Parent = MainFrame

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 8)
InputCorner.Parent = InputBox

local InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 1
InputStroke.Color = Color3.fromRGB(45, 45, 60)
InputStroke.Parent = InputBox

-- Modern Glow Button
local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.new(0, 220, 0, 38)
ApplyButton.Position = UDim2.new(0.5, -110, 0, 115)
ApplyButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
ApplyButton.Text = "DEPLOY TITLE"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.Font = Enum.Font.GothamBold
ApplyButton.TextSize = 12
ApplyButton.AutoButtonColor = false -- Matikan default roblox hover
ApplyButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ApplyButton

local ButtonGradient = Instance.new("UIGradient")
ButtonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 130, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 200))
})
ButtonGradient.Parent = ApplyButton


-- [[ ANIMASI TWEEN (MICRO-INTERACTIONS) ]]
ApplyButton.MouseEnter:Connect(function()
    TweenService:Create(ApplyButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}):Play()
end)

ApplyButton.MouseLeave:Connect(function()
    TweenService:Create(ApplyButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 130, 255)}):Play()
end)

InputBox.Focused:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(150, 0, 255)}):Play()
end)

InputBox.FocusLost:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(45, 45, 60)}):Play()
end)


-- [[ LOGIKA DRAGGABLE (SMOOTH & GESER LUAS) ]]
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    -- Menggunakan Tween agar gerakan mengikutinya mulus (smooth dragging)
    TweenService:Create(MainFrame, TweenInfo.new(0.08, Enum.EasingStyle.OutQuad), {
        Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    }):Play()
end

MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
        dragInput = input 
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then 
        update(input) 
    end
end)


-- [[ LOGIKA ACTION TOMBOL ]]
ApplyButton.MouseButton1Click:Connect(function()
    local text = InputBox.Text
    if text == "" then 
        ApplyButton.Text = "INPUT REQUIRED!"
        task.wait(1)
        ApplyButton.Text = "DEPLOY TITLE"
        return 
    end
    
    if ApplyTitleEvent then
        ApplyButton.Text = "⚡ TRANSMITTING..."
        ApplyTitleEvent:FireServer(text)
        task.wait(0.5)
        ApplyButton.Text = "✅ SUCCESS"
    else
        ApplyButton.Text = "❌ NODE NOT FOUND"
    end
    
    task.wait(1.5)
    ApplyButton.Text = "DEPLOY TITLE"
end)
