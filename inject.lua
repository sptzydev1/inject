-- [[ CONFIGURASI UTAMA UTK EXECUTOR ]]
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

if PlayerGui:FindFirstChild("ModernTitleGui") then
    PlayerGui.ModernTitleGui:Destroy()
end

-- [[ RE-PATHING REMOTE EVENT SESUAI ALUR SERVER ]]
local TitleRemotes = ReplicatedStorage:WaitForChild("TitleRemotes", 5)
local ApplyTitleEvent = TitleRemotes and TitleRemotes:FindFirstChild("ApplyTitle")

-- [[ PEMBUATAN ELEMENT GUI ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernTitleGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 260, 1, -620) -- Otomatis menyesuaikan jika ditarik
MainFrame.MinSize = Vector2.new(260, 180)
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = false 
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local BorderGradient = Instance.new("UIGradient")
BorderGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 180, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))
})
BorderGradient.Parent = MainStroke

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ADITYA TITLE CONTROLLER"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 15)
StatusLabel.Position = UDim2.new(0, 0, 0, 32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ApplyTitleEvent and "● REMOTE CONNECTED" or "○ REMOTE NOT FOUND"
StatusLabel.TextColor3 = ApplyTitleEvent and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 80, 80)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 8
StatusLabel.Parent = MainFrame

local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0, 220, 0, 38)
InputBox.Position = UDim2.new(0.5, -110, 0, 60)
InputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
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

local ApplyButton = Instance.new("TextButton")
ApplyButton.Size = UDim2.new(0, 220, 0, 38)
ApplyButton.Position = UDim2.new(0.5, -110, 0, 115)
ApplyButton.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
ApplyButton.Text = "DEPLOY TITLE"
ApplyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyButton.Font = Enum.Font.GothamBold
ApplyButton.TextSize = 12
ApplyButton.AutoButtonColor = false
ApplyButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = ApplyButton

-- [[ ANIMASI TWEEN ]]
ApplyButton.MouseEnter:Connect(function()
    TweenService:Create(ApplyButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 170, 255)}):Play()
end)
ApplyButton.MouseLeave:Connect(function()
    TweenService:Create(ApplyButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = Color3.fromRGB(0, 130, 255)}):Play()
end)

-- [[ LOGIKA DRAGGABLE ]]
local dragging, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        TweenService:Create(MainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quad), {
            Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        }):Play()
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- [[ LOGIKA EMULASI PARAMETER SESUAI SERVER ]]
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
        
        -- FORMAT STRUKTUR REKAYASA DATA TABLE UNTUK LINE 1
        local PayloadData = {
            ["Target"] = LocalPlayer.Name, -- Target ke diri sendiri
            ["T1"] = text,                 -- Text Line 1
            ["M1"] = "SOLID",             -- Mode: SOLID / GRADIENT
            ["SI1"] = 2,                   -- Warna: Royal Gold (Index ke-2 dari Solid Colors)
        }
        
        -- Tembakkan data terstruktur ke server
        ApplyTitleEvent:FireServer(PayloadData)
        
        task.wait(0.5)
        ApplyButton.Text = "✅ SUCCESS SEND"
    else
        ApplyButton.Text = "❌ REMOTE NOT FOUND"
    end
    
    task.wait(1.5)
    ApplyButton.Text = "DEPLOY TITLE"
end)
