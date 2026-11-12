--[[
    Project: Console Output Executor (Auto-Capture Version)
    Author: sptzyy / IkyyXD
]]--

local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")

-- Bersihkan GUI lama jika ada
if CoreGui:FindFirstChild("SptzyyExecutorConsole") then
    CoreGui.SptzyyExecutorConsole:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SptzyyExecutorConsole"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Main Frame (Persegi empat kecil, melengkung rapi, di tengah layar)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 420, 0, 260)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(0, 229, 255) -- Cyan neon accent khas sptzyy
UIStroke.Transparency = 0.5
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Top Bar (untuk drag / geser)
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "sptzyy // Auto-Scan Console"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- Tombol Clear
local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0, 50, 0, 22)
ClearButton.AnchorPoint = Vector2.new(1, 0.5)
ClearButton.Position = UDim2.new(1, -10, 0.5, 0)
ClearButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
ClearButton.Font = Enum.Font.GothamMedium
ClearButton.Text = "Clear"
ClearButton.TextColor3 = Color3.fromRGB(200, 200, 200)
ClearButton.TextSize = 11
ClearButton.Parent = TopBar

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 6)
ClearCorner.Parent = ClearButton

-- ScrollingFrame untuk Output Teks (Support Edit & Scroll)
local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -16, 1, -45)
ScrollingFrame.Position = UDim2.new(0, 8, 0, 38)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 229, 255)
ScrollingFrame.Parent = MainFrame

-- TextBox untuk Output (Support edit teks & salin manual)
local OutputBox = Instance.new("TextBox")
OutputBox.Name = "OutputBox"
OutputBox.Size = UDim2.new(1, 0, 1, 0)
OutputBox.BackgroundTransparency = 1
OutputBox.ClearTextOnFocus = false
OutputBox.MultiLine = true
OutputBox.TextEditable = true
OutputBox.Font = Enum.Font.Code
OutputBox.Text = "-- [sptzyy] Auto-Scanner aktif. Menunggu eksekusi script...\n"
OutputBox.TextColor3 = Color3.fromRGB(0, 255, 180)
OutputBox.TextSize = 12
OutputBox.TextXAlignment = Enum.TextXAlignment.Left
OutputBox.TextYAlignment = Enum.TextYAlignment.Top
OutputBox.Parent = ScrollingFrame

-- Sistem Dragging (Geser UI)
local dragging, dragInput, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Fungsi Menambahkan Log ke Console
local function AppendOutput(text: string)
    OutputBox.Text = OutputBox.Text .. "\n" .. tostring(text)
    ScrollingFrame.CanvasPosition = Vector2.new(0, ScrollingFrame.AbsoluteCanvasSize.Y)
end

ClearButton.MouseButton1Click:Connect(function()
    OutputBox.Text = "-- Log dibersihkan --"
end)

-- ==========================================================
-- AUTO-SCANNER: Menangkap semua output game / script lain
-- ==========================================================
LogService.MessageOut:Connect(function(message, messageType)
    local prefix = "[INFO]"
    if messageType == Enum.MessageType.MessageWarning then
        prefix = "[WARN]"
    elseif messageType == Enum.MessageType.MessageError then
        prefix = "[ERROR]"
    elseif messageType == Enum.MessageType.MessageOutput then
        prefix = "[OUT]"
    end
    
    AppendOutput(string.format("%s %s", prefix, message))
end)

-- Global bridge jika script lain ingin mengirim teks custom
_G.SptzyyLog = AppendOutput

-- Test simulasi scan saat pertama kali dijalankan
task.spawn(function()
    task.wait(0.5)
    print("Sistem scan & executor console berhasil diinisialisasi oleh sptzyy.")
end)
