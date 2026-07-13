-- [[ CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui

local GameName = "Unknown_Game"
task.spawn(function()
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        if productInfo and productInfo.Name then
            GameName = productInfo.Name:gsub("[%s%p]", "_")
        end
    end)
end)

local FILE_PREFIX = "GameCopy_"

-- [[ DEKLARASI GUI UTAMA MAP COPY ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyzyyCopyGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true
ScreenGui.Parent = PlayerGui

-- Tombol Open/Close Mini (🛡️)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(1, -60, 1, -60)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ToggleButton.Text = "🛡️"
ToggleButton.TextSize = 20
ToggleButton.Visible = false
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(0, 200, 255)
ToggleStroke.Parent = ToggleButton

-- Main Frame Utama
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 430)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -215)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 200, 255)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -30, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🚀 COPY MAP BY SPYZYY V2.8 🚀"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Tombol Close di Atas GUI
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "❌"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.TextSize = 12
CloseBtn.Parent = MainFrame

-- [[ PANEL PROFILE USER & SCRIPT ]]
local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -24, 1, -55)
Container.Position = UDim2.new(0, 12, 0, 40)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(1, 0, 0, 75)
InfoPanel.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
InfoPanel.Parent = Container

Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 6)
local InfoLayout = Instance.new("UIListLayout")
InfoLayout.Padding = UDim.new(0, 2)
InfoLayout.Parent = InfoPanel

local function CreateProfileLabel(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 16)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.Parent = InfoPanel
    return label
end

local NameLabel = CreateProfileLabel("👤 Name: Loading...", Color3.fromRGB(255, 255, 255))
local UsernameLabel = CreateProfileLabel("🆔 User: @" .. LocalPlayer.Name, Color3.fromRGB(180, 180, 180))
local AgeLabel = CreateProfileLabel("📅 Umur Akun: Dihitung...", Color3.fromRGB(0, 200, 255))

task.spawn(function()
    pcall(function()
        NameLabel.Text = "👤 Name: " .. LocalPlayer.DisplayName
        AgeLabel.Text = "📅 Umur Akun: " .. LocalPlayer.AccountAge .. " Hari"
    end)
end)

-- [[ TOMBOL UTAMA & LIST (PENGATURAN RESPONSIVE) ]]
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(1, 0, 0, 35)
CopyButton.Position = UDim2.new(0, 0, 0, 85)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.Text = "COPY MAP & LIGHTING"
CopyButton.Font = Enum.Font.SourceSansBold
CopyButton.TextSize = 12
CopyButton.Parent = Container
Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 6)

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, 0, 0, 20)
ListLabel.Position = UDim2.new(0, 0, 0, 125)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Pilih Data Hasil Untuk Di-Paste / Tempel:"
ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.SourceSansSemibold
ListLabel.TextSize = 11
ListLabel.Parent = Container

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(1, 0, 1, -195)
ListScroll.Position = UDim2.new(0, 0, 0, 145)
ListScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ListScroll.BorderSizePixel = 0
ListScroll.ScrollBarThickness = 4
ListScroll.Parent = Container
Instance.new("UICorner", ListScroll).CornerRadius = UDim.new(0, 6)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ListScroll

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(1, 0, 0, 25)
RefreshButton.Position = UDim2.new(0, 0, 1, -25)
RefreshButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RefreshButton.TextColor3 = Color3.fromRGB(200, 200, 200)
RefreshButton.Text = "🔄 Refresh List"
RefreshButton.Font = Enum.Font.SourceSans
RefreshButton.TextSize = 11
RefreshButton.Parent = Container
Instance.new("UICorner", RefreshButton).CornerRadius = UDim.new(0, 4)

-- [[ ICON GESER LUAS / RESIZE WINDOW ]]
local ResizeBtn = Instance.new("TextButton")
ResizeBtn.Name = "ResizeBtn"
ResizeBtn.Size = UDim2.new(0, 15, 0, 15)
ResizeBtn.Position = UDim2.new(1, -15, 1, -15)
ResizeBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
ResizeBtn.Text = ""
ResizeBtn.AutoButtonColor = false
ResizeBtn.Parent = MainFrame
local ResizeCorner = Instance.new("UICorner")
ResizeCorner.CornerRadius = UDim.new(1, 0)
ResizeCorner.Parent = ResizeBtn

-- [[ LOGIKA DRAGGABLE & RESIZE SCRIPT ]]
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if UIS:GetMouseLocation().Y - MainFrame.AbsolutePosition.Y > 40 then return end -- Hanya drag bagian title bar atas
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Logika Geser Luas (Resize)
local resizing = false
local resizeStartSize, resizeStartPos
ResizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStartSize = MainFrame.Size
        resizeStartPos = input.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then resizing = false end
        end)
    end
end)
UIS.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - resizeStartPos
        local newWidth = math.clamp(resizeStartSize.X.Offset + delta.X, 200, 500)
        local newHeight = math.clamp(resizeStartSize.Y.Offset + delta.Y, 300, 700)
        MainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
    end
end)

-- Logika Open/Close (🛡️)
CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleButton.Visible = true
end)
ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleButton.Visible = false
end)

-- [[ ENGINE DRIVER COPY/PASTE ]]
local function getRelativePath(obj)
    local path = {}
    local current = obj.Parent
    while current and current ~= workspace and current ~= Lighting and current ~= game do
        table.insert(path, 1, {Name = current.Name, ClassName = current.ClassName})
        current = current.Parent
    end
    return path
end

local function isAPlayerCharacter(obj)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and (obj == p.Character or obj:IsDescendantOf(p.Character)) then return true end
    end
    return false
end

local AllowedSupportClasses = {
    ["Texture"] = true, ["Decal"] = true, ["SurfaceAppearance"] = true, 
    ["SpecialMesh"] = true, ["BlockMesh"] = true, ["CylinderMesh"] = true,
    ["ParticleEmitter"] = true, ["PointLight"] = true, ["SpotLight"] = true, ["SurfaceLight"] = true,
    ["Sky"] = true, ["Atmosphere"] = true, ["Clouds"] = true, ["SunRaysEffect"] = true, ["BloomEffect"] = true,
    ["BlurEffect"] = true, ["ColorCorrectionEffect"] = true
}

CopyButton.MouseButton1Click:Connect(function()
    if not writefile then 
        CopyButton.Text = "Executor Tak Support!"
        return 
    end
    CopyButton.Text = "🔍 Scanning..."
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    
    local objectsToScan = workspace:GetDescendants()
    for _, item in ipairs(Lighting:GetDescendants()) do
        table.insert(objectsToScan, item)
    end
    
    for _, obj in pairs(objectsToScan) do
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") or AllowedSupportClasses[obj.ClassName] then
            if not obj:IsDescendantOf(Players) and not obj:IsA("Camera") and not obj:IsA("Terrain") and not isAPlayerCharacter(obj) then
                count = count + 1
                if count % 400 == 0 then 
                    CopyButton.Text = "📸 [" .. count .. "] Scanning..." 
                    task.wait() 
                end
                
                local isLightingObj = obj:IsDescendantOf(Lighting) or obj.Parent == Lighting
                local relPath = getRelativePath(obj)
                
                local data = {
                    Name = obj.Name,
                    ClassName = obj.ClassName,
                    RelativePath = relPath,
                    Depth = #relPath,
                    IsLighting = isLightingObj,
                    Properties = {}
                }
                
                pcall(function()
                    if obj:IsA("BasePart") then
                        data.Properties.Size = {obj.Size.X, obj.Size.Y, obj.Size.Z}
                        data.Properties.CFrame = {obj.CFrame:GetComponents()}
                        data.Properties.Color = {obj.Color.r * 255, obj.Color.g * 255, obj.Color.b * 255}
                        data.Properties.Material = obj.Material.Name
                        data.Properties.Transparency = obj.Transparency
                        data.Properties.Reflectance = obj.Reflectance
                        data.Properties.Anchored = obj.Anchored
                        data.Properties.CanCollide = obj.CanCollide
                        
                    elseif obj:IsA("Model") then
                        data.Properties.WorldPivot = {obj:GetPivot():GetComponents()}
                        -- AKURASI PHYSICS MODEL: Hitung isi dominan part di dalam model (Anchored / Unanchored)
                        local isAnchoredModel = true
                        for _, desc in ipairs(obj:GetDescendants()) do
                            if desc:IsA("BasePart") and not desc.Anchored then
                                isAnchoredModel = false
                                break
                            end
                        end
                        data.Properties.ModelAnchoredState = isAnchoredModel
                        if obj.PrimaryPart then data.Properties.PrimaryPartName = obj.PrimaryPart.Name end
                    end
                    table.insert(SaveData, data)
                end)
            end
        end
    end
    
    writefile(fileName, HttpService:JSONEncode(SaveData))
    CopyButton.Text = "💾 COPIED: " .. count .. " OBJS"
    task.wait(1)
    CopyButton.Text = "COPY MAP & LIGHTING"
    _G.UpdatePasteList()
end)

_G.UpdatePasteList = function()
    for _, child in pairs(ListScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
    end
    if not listfiles then return end
    local files = pcall(listfiles, "") and listfiles("") or {}
    
    for _, file in pairs(files) do
        if file:match(FILE_PREFIX) and file:match("%.json$") then
            local cleanName = file:gsub(FILE_PREFIX, ""):gsub("%.json", ""):gsub(".*/", "")
            local ItemFrame = Instance.new("Frame")
            ItemFrame.Size = UDim2.new(1, -6, 0, 26)
            ItemFrame.BackgroundTransparency = 1
            ItemFrame.Parent = ListScroll
            
            local FileSelectBtn = Instance.new("TextButton")
            FileSelectBtn.Size = UDim2.new(1, -26, 1, 0)
            FileSelectBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            FileSelectBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            FileSelectBtn.Text = " 📄 " .. cleanName
            FileSelectBtn.Font = Enum.Font.SourceSansSemibold
            FileSelectBtn.TextSize = 10
            FileSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
            FileSelectBtn.Parent = ItemFrame
            
            local DeleteBtn = Instance.new("TextButton")
            DeleteBtn.Size = UDim2.new(0, 22, 1, 0)
            DeleteBtn.Position = UDim2.new(1, -22, 0, 0)
            DeleteBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
            DeleteBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
            DeleteBtn.Text = "❌"
            DeleteBtn.Parent = ItemFrame

            DeleteBtn.MouseButton1Click:Connect(function()
                if delfile then pcall(delfile, file); ItemFrame:Destroy() end
            end)
            
            FileSelectBtn.MouseButton1Click:Connect(function()
                FileSelectBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
                task.spawn(function()
                    local success, err = pcall(function()
                        local loadedData = HttpService:JSONDecode(readfile(file))
                        table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                        
                        local MasterFolder = workspace:FindFirstChild("Paste_" .. cleanName) or Instance.new("Folder")
                        MasterFolder.Name = "Paste_" .. cleanName
                        MasterFolder.Parent = workspace
                        
                        for _, data in ipairs(loadedData) do
                            pcall(function()
                                local props = data.Properties or {}
                                local newObj = Instance.new(data.ClassName == "Model" and "Model" or (data.ClassName == "Folder" and "Folder" or "Part"))
                                newObj.Name = data.Name
                                
                                if newObj:IsA("BasePart") and props.CFrame then
                                    newObj.Size = Vector3.new(unpack(props.Size))
                                    newObj.CFrame = CFrame.new(unpack(props.CFrame))
                                    newObj.Color = Color3.fromRGB(unpack(props.Color))
                                    newObj.Transparency = props.Transparency
                                    newObj.CanCollide = props.CanCollide
                                    newObj.Anchored = (props.Anchored ~= nil) and props.Anchored or true
                                elseif newObj:IsA("Model") then
                                    if props.WorldPivot then newObj:PivotTo(CFrame.new(unpack(props.WorldPivot))) end
                                    
                                    -- Sinkronisasi Kunci Fisik Model Sesuai Data Asli
                                    task.defer(function()
                                        for _, subPart in ipairs(newObj:GetDescendants()) do
                                            if subPart:IsA("BasePart") then
                                                subPart.Anchored = (props.ModelAnchoredState ~= nil) and props.ModelAnchoredState or subPart.Anchored
                                            end
                                        end
                                    end)
                                end
                                newObj.Parent = MasterFolder
                            end)
                        end
                    end)
                    FileSelectBtn.BackgroundColor3 = success and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(150, 0, 0)
                    task.wait(1)
                    FileSelectBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                end)
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

RefreshButton.MouseButton1Click:Connect(_G.UpdatePasteList)
_G.UpdatePasteList()
