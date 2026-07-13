-- [[ CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- Proteksi Instan PlayerGui
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui

-- Mendapatkan Nama Game Secara Otomatis
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

-- Tombol Open/Toggle (🛡️)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0.05, 0, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ToggleButton.Text = "🛡️"
ToggleButton.TextSize = 25
ToggleButton.Visible = false
ToggleButton.Active = true
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0) -- Lingkaran sempurna
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(0, 200, 255)
ToggleStroke.Parent = ToggleButton

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 460)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -230)
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
Title.Size = UDim2.new(1, -40, 0, 40)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🚀 COPY MAP SPYZYY V2.5"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Tombol Close (❌)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 5)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "❌"
CloseButton.TextSize = 16
CloseButton.TextColor3 = Color3.fromRGB(255, 50, 50)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Parent = MainFrame

-- [[ PANEL PROFILE USER ]]
local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(0, 216, 0, 85)
InfoPanel.Position = UDim2.new(0, 12, 0, 40)
InfoPanel.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = MainFrame

local InfoPanelCorner = Instance.new("UICorner")
InfoPanelCorner.CornerRadius = UDim.new(0, 6)
InfoPanelCorner.Parent = InfoPanel

local InfoPanelStroke = Instance.new("UIStroke")
InfoPanelStroke.Thickness = 1
InfoPanelStroke.Color = Color3.fromRGB(50, 50, 60)
InfoPanelStroke.Parent = InfoPanel

local UserLayout = Instance.new("UIListLayout")
UserLayout.Padding = UDim.new(0, 2)
UserLayout.SortOrder = Enum.SortOrder.LayoutOrder
UserLayout.Parent = InfoPanel

local function CreateProfileLabel(text, color, order)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 18)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.LayoutOrder = order
    label.Parent = InfoPanel
    return label
end

local NameLabel = CreateProfileLabel("👤 Name: Loading...", Color3.fromRGB(255, 255, 255), 1)
local UsernameLabel = CreateProfileLabel("🆔 User: @" .. LocalPlayer.Name, Color3.fromRGB(180, 180, 180), 2)
local AgeLabel = CreateProfileLabel("📅 Umur Akun: Dihitung...", Color3.fromRGB(0, 200, 255), 3)
local BioLabel = CreateProfileLabel("📝 Bio: Loading...", Color3.fromRGB(150, 150, 150), 4)

task.spawn(function()
    pcall(function()
        NameLabel.Text = "👤 Name: " .. LocalPlayer.DisplayName
        local accountAge = LocalPlayer.AccountAge
        AgeLabel.Text = "📅 Umur Akun: " .. accountAge .. " Hari"
        
        local playerInfo = UserService:GetUserInfosByUserIdsAsync({LocalPlayer.UserId})
        if playerInfo and playerInfo[1] and playerInfo[1].Description ~= "" then
            local bio = playerInfo[1].Description
            if #bio > 22 then bio = string.sub(bio, 1, 20) .. ".." end
            BioLabel.Text = "📝 Bio: " .. bio
        else
            BioLabel.Text = "📝 Bio: (Kosong)"
        end
    end)
end)

-- [[ PANEL INFO SCRIPT PREMIUM ]]
local ScriptInfoPanel = Instance.new("Frame")
ScriptInfoPanel.Size = UDim2.new(0, 216, 0, 55)
ScriptInfoPanel.Position = UDim2.new(0, 12, 0, 130)
ScriptInfoPanel.BackgroundColor3 = Color3.fromRGB(28, 20, 35)
ScriptInfoPanel.BorderSizePixel = 0
ScriptInfoPanel.Parent = MainFrame

local ScriptInfoCorner = Instance.new("UICorner")
ScriptInfoCorner.CornerRadius = UDim.new(0, 6)
ScriptInfoCorner.Parent = ScriptInfoPanel

local ScriptInfoStroke = Instance.new("UIStroke")
ScriptInfoStroke.Thickness = 1
ScriptInfoStroke.Color = Color3.fromRGB(120, 0, 255)
ScriptInfoStroke.Parent = ScriptInfoPanel

local ScriptLayout = Instance.new("UIListLayout")
ScriptLayout.Padding = UDim.new(0, 1)
ScriptLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScriptLayout.Parent = ScriptInfoPanel

local function CreateScriptLabel(text, color, order)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 16)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = text
    label.LayoutOrder = order
    label.Parent = ScriptInfoPanel
    return label
end

CreateScriptLabel("✨ Script: Spyzyy Copy Map + Lighting", Color3.fromRGB(255, 255, 255), 1)
CreateScriptLabel("👑 Status: PREMIUM VERSION", Color3.fromRGB(255, 200, 0), 2)
CreateScriptLabel("🛠️ Maker: @Spyzyy (V2.5)", Color3.fromRGB(0, 255, 200), 3)

-- [[ ELEMENT PROGRESS BAR LOADING ]]
local ProgressContainer = Instance.new("Frame")
ProgressContainer.Name = "ProgressContainer"
ProgressContainer.Size = UDim2.new(0, 216, 0, 18)
ProgressContainer.Position = UDim2.new(0, 12, 0, 192)
ProgressContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ProgressContainer.BorderSizePixel = 0
ProgressContainer.Parent = MainFrame

local ProgressContainerCorner = Instance.new("UICorner")
ProgressContainerCorner.CornerRadius = UDim.new(0, 4)
ProgressContainerCorner.Parent = ProgressContainer

local ProgressBar = Instance.new("Frame")
ProgressBar.Name = "ProgressBar"
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
ProgressBar.BorderSizePixel = 0
ProgressBar.Parent = ProgressContainer

local ProgressBarCorner = Instance.new("UICorner")
ProgressBarCorner.CornerRadius = UDim.new(0, 4)
ProgressBarCorner.Parent = ProgressBar

local ProgressText = Instance.new("TextLabel")
ProgressText.Size = UDim2.new(1, 0, 1, 0)
ProgressText.BackgroundTransparency = 1
ProgressText.Text = "Ready - 0%"
ProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressText.Font = Enum.Font.SourceSansBold
ProgressText.TextSize = 11
ProgressText.Parent = ProgressContainer

-- [[ TOMBOL & ELEMENT GUI SCRIPT ]]
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 216, 0, 32)
CopyButton.Position = UDim2.new(0, 12, 0, 215)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.Text = "COPY MAP & LIGHTING"
CopyButton.Font = Enum.Font.SourceSansBold
CopyButton.TextSize = 12
CopyButton.Parent = MainFrame

local CopyButtonCorner = Instance.new("UICorner")
CopyButtonCorner.CornerRadius = UDim.new(0, 6)
CopyButtonCorner.Parent = CopyButton

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, -24, 0, 20)
ListLabel.Position = UDim2.new(0, 12, 0, 252)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Pilih Data Hasil Untuk Di-Paste / Tempel:"
ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.SourceSansSemibold
ListLabel.TextSize = 12
ListLabel.Parent = MainFrame

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(0, 216, 0, 125)
ListScroll.Position = UDim2.new(0, 12, 0, 275)
ListScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ListScroll.BorderSizePixel = 0
ListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
ListScroll.ScrollBarThickness = 4
ListScroll.Parent = MainFrame

local ListScrollCorner = Instance.new("UICorner")
ListScrollCorner.CornerRadius = UDim.new(0, 6)
ListScrollCorner.Parent = ListScroll

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ListScroll

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(0, 216, 0, 24)
RefreshButton.Position = UDim2.new(0, 12, 0, 410)
RefreshButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RefreshButton.TextColor3 = Color3.fromRGB(200, 200, 200)
RefreshButton.Text = "🔄 Refresh List"
RefreshButton.Font = Enum.Font.SourceSans
RefreshButton.TextSize = 11
RefreshButton.Parent = MainFrame

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 4)
RefreshCorner.Parent = RefreshButton

-- [[ LOGIKA GLOBAL DRAGGABLE LUAS ]]
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(MainFrame) -- Geser luas GUI Utama
MakeDraggable(ToggleButton) -- Geser luas Icon 🛡️

-- Logika Open & Close GUI
CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleButton.Visible = true
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleButton.Visible = false
end)


-- [[ CORE ENGINE COPY/PASTE ]]
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
    CopyButton.Text = "🔍 Scanning Map..."
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressText.Text = "Scanning... 0%"
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    
    local objectsToScan = workspace:GetDescendants()
    for _, item in ipairs(Lighting:GetDescendants()) do
        table.insert(objectsToScan, item)
    end
    
    local totalObjects = #objectsToScan
    
    for idx, obj in pairs(objectsToScan) do
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") or AllowedSupportClasses[obj.ClassName] then
            if not obj:IsDescendantOf(Players) and not obj:IsA("Camera") and not obj:IsA("Terrain") and not isAPlayerCharacter(obj) then
                count = count + 1
                
                -- Update Progress Bar per data item secara akurat %
                if idx % 200 == 0 or idx == totalObjects then
                    local pct = math.floor((idx / totalObjects) * 100)
                    ProgressBar.Size = UDim2.new(pct / 100, 0, 1, 0)
                    ProgressText.Text = "Copying... " .. pct .. "%"
                    CopyButton.Text = "📸 Objs: [" .. count .. "]"
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
                        data.Properties.CastShadow = obj.CastShadow
                        
                        if obj:IsA("MeshPart") then
                            data.Properties.MeshId = obj.MeshId
                            data.Properties.TextureId = obj.TextureId
                        elseif obj:IsA("UnionOperation") then
                            data.Properties.AssetId = obj.AssetId
                        end
                    elseif obj:IsA("Model") then
                        data.Properties.WorldPivot = {obj:GetPivot():GetComponents()}
                        if obj.PrimaryPart then
                            data.Properties.PrimaryPartName = obj.PrimaryPart.Name
                        end
                    elseif AllowedSupportClasses[obj.ClassName] then
                        pcall(function() data.Properties.Texture = obj.Texture end)
                        pcall(function() data.Properties.TextureId = obj.TextureId end)
                        pcall(function() data.Properties.MeshId = obj.MeshId end)
                        pcall(function() data.Properties.Color3 = {obj.Color3.r * 255, obj.Color3.g * 255, obj.Color3.b * 255} end)
                        pcall(function() data.Properties.Color = {obj.Color.r * 255, obj.Color.g * 255, obj.Color.b * 255} end)
                        pcall(function() data.Properties.Enabled = obj.Enabled end)
                        pcall(function() data.Properties.Brightness = obj.Brightness end)
                        pcall(function() data.Properties.Range = obj.Range end)
                        pcall(function() data.Properties.Intensity = obj.Intensity end)
                        pcall(function() data.Properties.Size = obj.Size end)
                        pcall(function() data.Properties.Face = obj.Face.Name end) -- Arah Decal/Sticker
                        -- Properti Skybox
                        pcall(function() data.Properties.SkyboxBk = obj.SkyboxBk end)
                        pcall(function() data.Properties.SkyboxDn = obj.SkyboxDn end)
                        pcall(function() data.Properties.SkyboxFt = obj.SkyboxFt end)
                        pcall(function() data.Properties.SkyboxLf = obj.SkyboxLf end)
                        pcall(function() data.Properties.SkyboxRt = obj.SkyboxRt end)
                        pcall(function() data.Properties.SkyboxUp = obj.SkyboxUp end)
                    end
                    table.insert(SaveData, data)
                end)
            end
        end
    end
    
    ProgressBar.Size = UDim2.new(1, 0, 1, 0)
    ProgressText.Text = "Saving to JSON..."
    writefile(fileName, HttpService:JSONEncode(SaveData))
    
    ProgressText.Text = "Done - 100%"
    CopyButton.Text = "💾 COPIED: " .. count .. " OBJS"
    task.wait(2)
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
            FileSelectBtn.TextSize = 11
            FileSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
            FileSelectBtn.Parent = ItemFrame
            
            local BtnCorner = Instance.new("UICorner")
            BtnCorner.CornerRadius = UDim.new(0, 4)
            BtnCorner.Parent = FileSelectBtn
            
            local DeleteBtn = Instance.new("TextButton")
            DeleteBtn.Size = UDim2.new(0, 22, 1, 0)
            DeleteBtn.Position = UDim2.new(1, -22, 0, 0)
            DeleteBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
            DeleteBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
            DeleteBtn.Text = "❌"
            DeleteBtn.Font = Enum.Font.SourceSansBold
            DeleteBtn.TextSize = 10
            DeleteBtn.Parent = ItemFrame
            
            local DelCorner = Instance.new("UICorner")
            DelCorner.CornerRadius = UDim.new(0, 4)
            DelCorner.Parent = DeleteBtn

            DeleteBtn.MouseButton1Click:Connect(function()
                if delfile then
                    pcall(delfile, file)
                    ItemFrame:Destroy()
                    _G.UpdatePasteList()
                end
            end)
            
            FileSelectBtn.MouseButton1Click:Connect(function()
                FileSelectBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
                task.spawn(function()
                    print("============ [ START PASTE PROCESS Studio Console ] ============")
                    local success, err = pcall(function()
                        local fileContent = readfile(file)
                        local loadedData = HttpService:JSONDecode(fileContent)
                        
                        -- Mengurutkan hierarki agar parent dibuat terlebih dahulu sebelum objek di dalamnya
                        table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                        
                        local MasterFolder = workspace:FindFirstChild("Paste_" .. cleanName) or Instance.new("Folder")
                        MasterFolder.Name = "Paste_" .. cleanName
                        MasterFolder.Parent = workspace
                        
                        local function findOrCreateParent(relativePath, isLighting)
                            local currentParent = isLighting and Lighting or MasterFolder
                            for _, pathInfo in ipairs(relativePath) do
                                local found = currentParent:FindFirstChild(pathInfo.Name)
                                if not found then
                                    if pathInfo.ClassName == "Folder" or pathInfo.ClassName == "Model" then
                                        found = Instance.new(pathInfo.ClassName)
                                    else
                                        found = Instance.new("Folder")
                                    end
                                    found.Name = pathInfo.Name
                                    found.Parent = currentParent
                                    print("⚙️ Created Hierarchy Parent: " .. pathInfo.Name .. " [" .. pathInfo.ClassName .. "]")
                                end
                                currentParent = found
                            end
                            return currentParent
                        end
                        
                        local pasteCount = 0
                        local totalObjs = #loadedData
                        
                        for _, data in ipairs(loadedData) do
                            pcall(function()
                                local targetParent = findOrCreateParent(data.RelativePath, data.IsLighting)
                                
                                -- Cegah duplikasi struktur folder/model dasar
                                if targetParent:FindFirstChild(data.Name) and (data.ClassName == "Folder" or data.ClassName == "Model") then return end
                                
                                pasteCount = pasteCount + 1
                                if pasteCount % 200 == 0 then
                                    FileSelectBtn.Text = "🔨 [" .. pasteCount .. "/" .. totalObjs .. "] Pasting..."
                                    task.wait()
                                end
                                
                                -- Console Log output Studio
                                print(string.format("🔨 [%d/%d] Generating: %s (%s)", pasteCount, totalObjs, data.Name, data.ClassName))
                                
                                local newObj
                                local props = data.Properties or {}
                                
                                if AllowedSupportClasses[data.ClassName] then
                                    newObj = Instance.new(data.ClassName)
                                    pcall(function() if props.Texture then newObj.Texture = props.Texture end end)
                                    pcall(function() if props.TextureId then newObj.TextureId = props.TextureId end end)
                                    pcall(function() if props.Enabled ~= nil then newObj.Enabled = props.Enabled end end)
                                    pcall(function() if props.Brightness then newObj.Brightness = props.Brightness end end)
                                    pcall(function() if props.Range then newObj.Range = props.Range end end)
                                    pcall(function() if props.Intensity then newObj.Intensity = props.Intensity end end)
                                    pcall(function() if props.Color3 then newObj.Color3 = Color3.fromRGB(unpack(props.Color3)) end end)
                                    pcall(function() if props.Color then newObj.Color = Color3.fromRGB(unpack(props.Color)) end end)
                                    pcall(function() if props.Face then newObj.Face = Enum.NormalId[props.Face] end end)
                                    
                                    -- Sky properties paste
                                    pcall(function() if props.SkyboxBk then newObj.SkyboxBk = props.SkyboxBk end end)
                                    pcall(function() if props.SkyboxDn then newObj.SkyboxDn = props.SkyboxDn end end)
                                    pcall(function() if props.SkyboxFt then newObj.SkyboxFt = props.SkyboxFt end end)
                                    pcall(function() if props.SkyboxLf then newObj.SkyboxLf = props.SkyboxLf end end)
                                    pcall(function() if props.SkyboxRt then newObj.SkyboxRt = props.SkyboxRt end end)
                                    pcall(function() if props.SkyboxUp then newObj.SkyboxUp = props.SkyboxUp end end)
                                elseif data.ClassName == "Folder" or data.ClassName == "Model" then
                                    newObj = Instance.new(data.ClassName)
                                    if data.ClassName == "Model" and props.WorldPivot then
                                        newObj:PivotTo(CFrame.new(unpack(props.WorldPivot)))
                                    end
                                else
                                    newObj = Instance.new("Part") -- Fallback aman ke Part biasa
                                end
                                
                                newObj.Name = data.Name
                                
                                -- Pengaturan Part Base Properties
                                if newObj:IsA("BasePart") and props.CFrame then
                                    newObj.Size = Vector3.new(unpack(props.Size))
                                    newObj.CFrame = CFrame.new(unpack(props.CFrame))
                                    newObj.Color = Color3.fromRGB(unpack(props.Color))
                                    pcall(function() newObj.Material = Enum.Material[props.Material] end)
                                    newObj.Transparency = props.Transparency
                                    newObj.Reflectance = props.Reflectance or 0
                                    newObj.Anchored = props.Anchored
                                    newObj.CanCollide = props.CanCollide
                                    if props.CastShadow ~= nil then newObj.CastShadow = props.CastShadow end
                                end
                                
                                -- Auto-Ungroup/Insert logic: Melekat otomatis ke layer part terdalam
                                newObj.Parent = targetParent
                                
                                -- Sinkronisasi PrimaryPart Model
                                if data.ClassName == "Model" and props.PrimaryPartName then
                                    task.defer(function()
                                        local pPart = newObj:FindFirstChild(props.PrimaryPartName)
                                        if pPart and pPart:IsA("BasePart") then
                                            newObj.PrimaryPart = pPart
                                        end
                                    end)
                                end
                            end)
                        end
                        
                        -- Membersihkan Folder Kosong pasca render berlapis
                        for _, child in ipairs(MasterFolder:GetChildren()) do
                            if child:IsA("Folder") and #child:GetChildren() == 0 then
                                child:Destroy()
                            end
                        end
                    end)
                    
                    if success then
                        print("✅ SUCCESS: Map berhasil di-paste seutuhnya!")
                        FileSelectBtn.Text = " ✅ SUCCESSFUL!"
                        FileSelectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                    else
                        warn("❌ ERROR: Terjadi kendala saat paste: ", err)
                        FileSelectBtn.Text = " ❌ ERROR OCCURRED!"
                        FileSelectBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                    end
                    print("============ [ END PASTE PROCESS ] ============")
                    task.wait(1.5)
                    FileSelectBtn.Text = " 📄 " .. cleanName
                    FileSelectBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                end)
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

RefreshButton.MouseButton1Click:Connect(_G.UpdatePasteList)
_G.UpdatePasteList()
