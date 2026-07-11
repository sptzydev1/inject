-- [[ CONFIGURASI UTAMA UTK EXECUTOR ]]
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Proteksi Eksekusi: Menunggu LocalPlayer benar-benar termuat agar tidak Nil/Error
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.1)
    LocalPlayer = Players.LocalPlayer
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then return end

-- Hapus GUI lama jika sudah ada agar tidak menumpuk
if PlayerGui:FindFirstChild("ModernTitleGui") then
    PlayerGui.ModernTitleGui:Destroy()
end

-- [[ SCAN ALL REMOTE EVENTS ]]
local AllRemotes = {}
for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
    if obj:IsA("RemoteEvent") then
        table.insert(AllRemotes, obj)
    end
end

local SelectedRemote = nil

-- [[ PEMBUATAN ELEMENT GUI (MODERN STYLE - EXTENDED) ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ModernTitleGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Main Frame (Diperbesar ukurannya untuk memuat list)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 380)
MainFrame.Position = UDim2.new(0.5, -150, 0.4, -190)
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

-- Header Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 40)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ADVANCED REMOTE CONTROLLER"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 12
TitleLabel.Parent = MainFrame

-- Subtitle/Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 15)
StatusLabel.Position = UDim2.new(0, 0, 0, 32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "● SCANNED REMOTES: " .. tostring(#AllRemotes)
StatusLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 9
StatusLabel.Parent = MainFrame

-- Modern Input Box
local InputBox = Instance.new("TextBox")
InputBox.Size = UDim2.new(0, 260, 0, 35)
InputBox.Position = UDim2.new(0.5, -130, 0, 55)
InputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
InputBox.Text = ""
InputBox.PlaceholderText = "Enter text / parameters..."
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

-- [[ LIST REMOTE CONTAINER (SCROLLING FRAME) ]]
local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(0, 260, 0, 15)
ListLabel.Position = UDim2.new(0.5, -130, 0, 100)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "SELECT REMOTE TARGET:"
ListLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
ListLabel.Font = Enum.Font.GothamBold
ListLabel.TextSize = 9
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Parent = MainFrame

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(0, 260, 0, 140)
ScrollingFrame.Position = UDim2.new(0.5, -130, 0, 120)
ScrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Otomatis membesar via UIListLayout
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
ScrollingFrame.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 6)
ListCorner.Parent = ScrollingFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ScrollingFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

-- Render Item List Remote
local ButtonsTable = {}
for idx, remote in pairs(AllRemotes) do
    local RemoteBtn = Instance.new("TextButton")
    RemoteBtn.Size = UDim2.new(1, -6, 0, 28)
    RemoteBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    RemoteBtn.Text = "  " .. remote.Name
    RemoteBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    RemoteBtn.Font = Enum.Font.Gotham
    RemoteBtn.TextSize = 10
    RemoteBtn.TextXAlignment = Enum.TextXAlignment.Left
    RemoteBtn.AutoButtonColor = false
    RemoteBtn.Parent = ScrollingFrame
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 4)
    BtnCorner.Parent = RemoteBtn
    
    ButtonsTable[remote] = RemoteBtn
    
    -- Logika Pilih Salah Satu (Single Selection)
    RemoteBtn.MouseButton1Click:Connect(function()
        SelectedRemote = remote
        for _, btn in pairs(ButtonsTable) do
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        RemoteBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
        RemoteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StatusLabel.Text = "● SELECTED: " .. remote.Name
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
    end)
    
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 10)
end

-- [[ ACTION BUTTONS ]]

-- Tombol Eksekusi Semua (All Remote)
local ExecAllButton = Instance.new("TextButton")
ExecAllButton.Size = UDim2.new(0, 260, 0, 32)
ExecAllButton.Position = UDim2.new(0.5, -130, 0, 280)
ExecAllButton.BackgroundColor3 = Color3.fromRGB(180, 0, 50)
ExecAllButton.Text = "⚡ EXECUTE ALL REMOTES"
ExecAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecAllButton.Font = Enum.Font.GothamBold
ExecAllButton.TextSize = 11
ExecAllButton.AutoButtonColor = false
ExecAllButton.Parent = MainFrame

local ExecAllCorner = Instance.new("UICorner")
ExecAllCorner.CornerRadius = UDim.new(0, 6)
ExecAllCorner.Parent = ExecAllButton

-- Tombol Eksekusi yang Dipilih (Selected Single Remote)
local ExecSelectButton = Instance.new("TextButton")
ExecSelectButton.Size = UDim2.new(0, 260, 0, 32)
ExecSelectButton.Position = UDim2.new(0.5, -130, 0, 322)
ExecSelectButton.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
ExecSelectButton.Text = "🎯 EXECUTE SELECTED"
ExecSelectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ExecSelectButton.Font = Enum.Font.GothamBold
ExecSelectButton.TextSize = 11
ExecSelectButton.AutoButtonColor = false
ExecSelectButton.Parent = MainFrame

local ExecSelectCorner = Instance.new("UICorner")
ExecSelectCorner.CornerRadius = UDim.new(0, 6)
ExecSelectCorner.Parent = ExecSelectButton

-- [[ LOGIKA EKSKUSI DENGAN SUPPORT ALL PARAMETER ]]
local function fireRemoteWithAllParameters(remoteInstance, textValue)
    if not remoteInstance or not remoteInstance:IsA("RemoteEvent") then return end
    
    pcall(function()
        -- 1. Normal single text parameter
        remoteInstance:FireServer(textValue) 
        
        -- 2. Common Action Prefix Tuples
        remoteInstance:FireServer("SetTitle", textValue)
        remoteInstance:FireServer("Equip", textValue)
        remoteInstance:FireServer("Change", textValue)
        remoteInstance:FireServer("Update", textValue)
        
        -- 3. Dictionary / Array Structures Table
        remoteInstance:FireServer({Text = textValue, Title = textValue, Name = textValue, Value = textValue})
        remoteInstance:FireServer({textValue})
        
        -- 4. Multi Variable Arguments (Fallback Tuple)
        remoteInstance:FireServer(textValue, true, 1, "Default")
    end)
end

-- Event Handler: Execute All Remotes
ExecAllButton.MouseButton1Click:Connect(function()
    local text = InputBox.Text
    if text == "" then 
        ExecAllButton.Text = "INPUT REQUIRED!"
        task.wait(1)
        ExecAllButton.Text = "⚡ EXECUTE ALL REMOTES"
        return 
    end
    
    ExecAllButton.Text = "FIRING ALL NODES..."
    for _, remote in pairs(AllRemotes) do
        fireRemoteWithAllParameters(remote, text)
    end
    task.wait(0.5)
    ExecAllButton.Text = "✅ ALL REMOTES FIRED"
    task.wait(1.5)
    ExecAllButton.Text = "⚡ EXECUTE ALL REMOTES"
end)

-- Event Handler: Execute Selected Single Remote
ExecSelectButton.MouseButton1Click:Connect(function()
    local text = InputBox.Text
    if text == "" then 
        ExecSelectButton.Text = "INPUT REQUIRED!"
        task.wait(1)
        ExecSelectButton.Text = "🎯 EXECUTE SELECTED"
        return 
    end
    
    if not SelectedRemote then
        ExecSelectButton.Text = "SELECT A REMOTE FIRST!"
        task.wait(1.5)
        ExecSelectButton.Text = "🎯 EXECUTE SELECTED"
        return
    end
    
    ExecSelectButton.Text = "TRANSMITTING..."
    fireRemoteWithAllParameters(SelectedRemote, text)
    task.wait(0.5)
    ExecSelectButton.Text = "✅ TRANSMITTED SUCCESSFULLY"
    task.wait(1.5)
    ExecSelectButton.Text = "🎯 EXECUTE SELECTED"
end)

-- [[ TWEENING & DRAGGING EFFECT ]]
InputBox.Focused:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(150, 0, 255)}):Play()
end)
InputBox.FocusLost:Connect(function()
    TweenService:Create(InputStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(45, 45, 60)}):Play()
end)

local dragging = false
local dragStart = Vector3.new()
local startPos = UDim2.new()

local function initDrag(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end

MainFrame.InputBegan:Connect(initDrag)
TitleLabel.InputBegan:Connect(initDrag)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        TweenService:Create(MainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        }):Play()
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
