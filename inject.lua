-- [[ CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local StarterPack = game:GetService("StarterPack")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
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

local FILE_PREFIX = "NoWorkspaceGameCopy_"

-- [[ DEKLARASI GUI UTAMA SPYZYY COPY V3.1 ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyzyyNoWorkspaceCopyV3"
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
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Thickness = 2
ToggleStroke.Color = Color3.fromRGB(0, 200, 255)
ToggleStroke.Parent = ToggleButton

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 490) 
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -245)
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
Title.Text = "🚀 NO-WORKSPACE COPY V3.1"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
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

CreateScriptLabel("✨ Script: Non-Workspace Copier", Color3.fromRGB(255, 255, 255), 1)
CreateScriptLabel("👑 Status: PREMIUM VERSION", Color3.fromRGB(255, 200, 0), 2)
CreateScriptLabel("🛠️ Maker: @Spyzyy (V3.1)", Color3.fromRGB(0, 255, 200), 3)

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
CopyButton.Text = "COPY ALL EXCEPT WORKSPACE"
CopyButton.Font = Enum.Font.SourceSansBold
CopyButton.TextSize = 11
CopyButton.Parent = MainFrame

local CopyButtonCorner = Instance.new("UICorner")
CopyButtonCorner.CornerRadius = UDim.new(0, 6)
CopyButtonCorner.Parent = CopyButton

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, -24, 0, 20)
ListLabel.Position = UDim2.new(0, 12, 0, 252)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Pilih Data Hasil Untuk Di-Paste Ke Services:"
ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.SourceSansSemibold
ListLabel.TextSize = 11
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

-- [[ TOMBOL UBAH TEMA ]]
local ThemeButton = Instance.new("TextButton")
ThemeButton.Size = UDim2.new(0, 216, 0, 24)
ThemeButton.Position = UDim2.new(0, 12, 0, 440)
ThemeButton.BackgroundColor3 = Color3.fromRGB(20, 35, 45)
ThemeButton.TextColor3 = Color3.fromRGB(0, 255, 200)
ThemeButton.Text = "🎨 Switch Cool Static Theme"
ThemeButton.Font = Enum.Font.SourceSansBold
ThemeButton.TextSize = 11
ThemeButton.Parent = MainFrame

local ThemeCorner = Instance.new("UICorner")
ThemeCorner.CornerRadius = UDim.new(0, 4)
ThemeCorner.Parent = ThemeButton

local ThemeStroke = Instance.new("UIStroke")
ThemeStroke.Thickness = 1
ThemeStroke.Color = Color3.fromRGB(0, 200, 150)
ThemeStroke.Parent = ThemeButton

local function ApplyStaticCoolTheme()
    local duration = 0.5
    local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local MainBgColor = Color3.fromRGB(15, 12, 22)
    local AccentColor1 = Color3.fromRGB(255, 0, 128)
    local AccentColor2 = Color3.fromRGB(0, 255, 230)
    local PanelBgColor = Color3.fromRGB(25, 20, 35)
    
    TweenService:Create(MainFrame, info, {BackgroundColor3 = MainBgColor}):Play()
    TweenService:Create(MainStroke, info, {Color = AccentColor1}):Play()
    TweenService:Create(ToggleStroke, info, {Color = AccentColor2}):Play()
    
    TweenService:Create(InfoPanel, info, {BackgroundColor3 = PanelBgColor}):Play()
    TweenService:Create(InfoPanelStroke, info, {Color = AccentColor2}):Play()
    
    TweenService:Create(ScriptInfoPanel, info, {BackgroundColor3 = Color3.fromRGB(35, 15, 40)}):Play()
    TweenService:Create(ScriptInfoStroke, info, {Color = AccentColor1}):Play()
    
    TweenService:Create(ProgressBar, info, {BackgroundColor3 = AccentColor1}):Play()
    TweenService:Create(CopyButton, info, {BackgroundColor3 = AccentColor2, TextColor3 = Color3.fromRGB(0,0,0)}):Play()
    TweenService:Create(ListScroll, info, {BackgroundColor3 = Color3.fromRGB(10, 8, 15)}):Play()
    
    ThemeButton.Text = "✨ STYLISH SYNTHWAVE ACTIVE ✨"
    ThemeButton.TextColor3 = AccentColor1
    ThemeStroke.Color = AccentColor2
end

ThemeButton.MouseButton1Click:Connect(ApplyStaticCoolTheme)

-- [[ LOGIKA DRAGGABLE ]]
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

MakeDraggable(MainFrame)
MakeDraggable(ToggleButton)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ToggleButton.Visible = true
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    ToggleButton.Visible = false
end)

-- [[ MAP REPOSITORY SERVICES (TANPA WORKSPACE) ]]
local ServiceMap = {
    ["Lighting"] = Lighting,
    ["Players"] = Players,
    ["StarterGui"] = StarterGui,
    ["StarterPack"] = StarterPack,
    ["StarterPlayer"] = StarterPlayer,
    ["ReplicatedStorage"] = ReplicatedStorage,
    ["ReplicatedFirst"] = ReplicatedFirst,
    ["ServerStorage"] = ServerStorage,
    ["ServerScriptService"] = ServerScriptService
}

local function getRootServiceAndPath(obj)
    local path = {}
    local current = obj
    local rootServiceName = "ReplicatedStorage"
    
    while current and current ~= game do
        for name, serviceObj in pairs(ServiceMap) do
            if current == serviceObj then
                rootServiceName = name
                return rootServiceName, path
            end
        end
        table.insert(path, 1, {Name = current.Name, ClassName = current.ClassName})
        current = current.Parent
    end
    
    return rootServiceName, path
end

-- [[ UNIVERSAL SERIALIZER PROPERTI ]]
local function ExtractUniversalProperties(obj)
    local props = {}
    
    local function serializeVal(v)
        local t = typeof(v)
        if t == "Color3" then
            return {Type = "Color3", R = v.R * 255, G = v.G * 255, B = v.B * 255}
        elseif t == "UDim2" then
            return {Type = "UDim2", XS = v.X.Scale, XO = v.X.Offset, YS = v.Y.Scale, YO = v.Y.Offset}
        elseif t == "UDim" then
            return {Type = "UDim", S = v.Scale, O = v.Offset}
        elseif t == "Vector3" then
            return {Type = "Vector3", X = v.X, Y = v.Y, Z = v.Z}
        elseif t == "CFrame" then
            return {Type = "CFrame", Components = {v:GetComponents()}}
        elseif t == "Vector2" then
            return {Type = "Vector2", X = v.X, Y = v.Y}
        elseif t == "Rect" then
            return {Type = "Rect", MinX = v.Min.X, MinY = v.Min.Y, MaxX = v.Max.X, MaxY = v.Max.Y}
        elseif t == "EnumItem" then
            return {Type = "Enum", EnumType = tostring(v.EnumType), Name = v.Name}
        elseif t == "number" or t == "string" or t == "boolean" then
            return v
        end
        return nil
    end

    local generalProps = {
        "Size", "Position", "CFrame", "Color", "Material", "Transparency", "Reflectance", "Anchored", "CanCollide", "CastShadow",
        "MeshId", "TextureId", "AssetId", "Value",
        "Size", "Position", "AnchorPoint", "ZIndex", "LayoutOrder", "Visible", "ClipsDescendants",
        "BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "BorderColor3", "AutomaticSize",
        "Text", "TextColor3", "TextSize", "Font", "TextTransparency", "TextScaled", "TextWrapped",
        "TextXAlignment", "TextYAlignment", "PlaceholderText",
        "Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "TileSize",
        "CornerRadius", "Thickness", "ApplyStrokeMode", "LineJoinMode",
        "PaddingLeft", "PaddingRight", "PaddingTop", "PaddingBottom", "Padding", "FillDirection",
        "HorizontalAlignment", "VerticalAlignment", "SortOrder", "CellSize", "CellPadding",
        "AspectRatio", "AspectType", "DominantAxis", "MinSize", "MaxSize",
        "ResetOnSpawn", "Enabled", "DisplayOrder", "IgnoreGuiInset",
        "CanvasSize", "ScrollBarThickness", "ScrollBarImageColor3",
        "SoundId", "Volume", "PlaybackSpeed", "Looped", "Playing", "TimePosition",
        "Brightness", "Range", "Face"
    }

    for _, p in ipairs(generalProps) do
        pcall(function()
            local val = obj[p]
            if val ~= nil then
                local sVal = serializeVal(val)
                if sVal ~= nil then
                    props[p] = sVal
                end
            end
        end)
    end
    
    return props
end

local function ApplyUniversalProperties(obj, props)
    local function deserializeVal(v)
        if type(v) == "table" and v.Type then
            if v.Type == "Color3" then
                return Color3.fromRGB(v.R, v.G, v.B)
            elseif v.Type == "UDim2" then
                return UDim2.new(v.XS, v.XO, v.YS, v.YO)
            elseif v.Type == "UDim" then
                return UDim.new(v.S, v.O)
            elseif v.Type == "Vector3" then
                return Vector3.new(v.X, v.Y, v.Z)
            elseif v.Type == "CFrame" then
                return CFrame.new(unpack(v.Components))
            elseif v.Type == "Vector2" then
                return Vector2.new(v.X, v.Y)
            elseif v.Type == "Rect" then
                return Rect.new(v.MinX, v.MinY, v.MaxX, v.MaxY)
            elseif v.Type == "Enum" then
                local enumType = v.EnumType
                if Enum[enumType] and Enum[enumType][v.Name] then
                    return Enum[enumType][v.Name]
                end
            end
        end
        return v
    end

    for pName, pVal in pairs(props) do
        pcall(function()
            obj[pName] = deserializeVal(pVal)
        end)
    end
end

-- [[ PROCESS COPY (TANPA WORKSPACE) ]]
CopyButton.MouseButton1Click:Connect(function()
    if not writefile then 
        CopyButton.Text = "Executor Tak Support!"
        return 
    end
    CopyButton.Text = "🔍 Scanning Non-Workspace Services..."
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressText.Text = "Scanning... 0%"
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    
    local objectsToScan = {}
    
    for _, sObj in pairs(ServiceMap) do
        pcall(function()
            for _, item in ipairs(sObj:GetDescendants()) do
                if not item:IsDescendantOf(ScreenGui) and item ~= ScreenGui then
                    table.insert(objectsToScan, item)
                end
            end
        end)
    end
    
    local totalObjects = #objectsToScan
    
    if totalObjects == 0 then
        CopyButton.Text = "Objek Kosong!"
        ProgressText.Text = "Kosong - 0 Objek"
        return
    end

    for idx, obj in pairs(objectsToScan) do
        count = count + 1
        
        if idx % 50 == 0 or idx == totalObjects then
            local pct = math.floor((idx / totalObjects) * 100)
            ProgressBar.Size = UDim2.new(pct / 100, 0, 1, 0)
            ProgressText.Text = "Copying... " .. pct .. "%"
            CopyButton.Text = "📸 Objs: [" .. count .. "]"
            task.wait()
        end
        
        local rootService, relPath = getRootServiceAndPath(obj)
        
        local data = {
            Name = obj.Name,
            ClassName = obj.ClassName,
            RootService = rootService,
            RelativePath = relPath,
            Depth = #relPath,
            Properties = ExtractUniversalProperties(obj)
        }
        
        table.insert(SaveData, data)
    end
    
    ProgressBar.Size = UDim2.new(1, 0, 1, 0)
    ProgressText.Text = "Saving to JSON..."
    writefile(fileName, HttpService:JSONEncode(SaveData))
    
    ProgressText.Text = "Done - 100%"
    CopyButton.Text = "💾 COPIED: " .. count .. " OBJS"
    task.wait(2)
    CopyButton.Text = "COPY ALL EXCEPT WORKSPACE"
    _G.UpdatePasteList()
end)

-- [[ PROCESS PASTE KE SERVICES KEMBALI ]]
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
                    print("============ [ START NON-WORKSPACE PASTE PROCESS ] ============")
                    local success, err = pcall(function()
                        local fileContent = readfile(file)
                        local loadedData = HttpService:JSONDecode(fileContent)
                        
                        table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                        
                        local function getTargetRoot(serviceName)
                            local baseObj = ServiceMap[serviceName] or ReplicatedStorage
                            
                            local testOk = pcall(function()
                                local test = Instance.new("Folder")
                                test.Name = "__TestWrite"
                                test.Parent = baseObj
                                test:Destroy()
                            end)
                            
                            if not testOk then
                                if serviceName == "StarterGui" then return PlayerGui end
                                return ReplicatedStorage
                            end
                            
                            return baseObj
                        end

                        local function findOrCreateParent(rootServiceName, relativePath)
                            local currentParent = getTargetRoot(rootServiceName)
                            
                            for idx, pathInfo in ipairs(relativePath) do
                                if idx < #relativePath then
                                    local found = currentParent:FindFirstChild(pathInfo.Name)
                                    if not found then
                                        local ok, created = pcall(function() return Instance.new(pathInfo.ClassName) end)
                                        if not ok or not created then
                                            created = Instance.new("Folder")
                                        end
                                        created.Name = pathInfo.Name
                                        pcall(function() created.Parent = currentParent end)
                                        found = created
                                    end
                                    currentParent = found
                                end
                            end
                            return currentParent
                        end
                        
                        local pasteCount = 0
                        local totalObjs = #loadedData
                        
                        for _, data in ipairs(loadedData) do
                            pcall(function()
                                local targetParent = findOrCreateParent(data.RootService, data.RelativePath)
                                
                                pasteCount = pasteCount + 1
                                if pasteCount % 50 == 0 then
                                    FileSelectBtn.Text = "🔨 [" .. pasteCount .. "/" .. totalObjs .. "] Pasting..."
                                    task.wait()
                                end
                                
                                local ok, newObj = pcall(function() return Instance.new(data.ClassName) end)
                                if not ok or not newObj then
                                    newObj = Instance.new("Folder")
                                end
                                
                                newObj.Name = data.Name
                                
                                if data.Properties then
                                    ApplyUniversalProperties(newObj, data.Properties)
                                end
                                
                                pcall(function() newObj.Parent = targetParent end)
                            end)
                        end
                    end)
                    
                    if success then
                        FileSelectBtn.Text = " ✅ SUCCESSFUL!"
                        FileSelectBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
                    else
                        FileSelectBtn.Text = " ❌ ERROR OCCURRED!"
                        FileSelectBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
                    end
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
