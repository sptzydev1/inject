-- [[ UPDATE DELTA COPYY CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterPack = game:GetService("StarterPack")
local StarterGui = game:GetService("StarterGui")
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

-- ==================================================
--  (CORE PROCESSOR)
-- ==================================================

local function processParts(root)
    for _, inst in ipairs(root:GetDescendants()) do
        pcall(function()
            if inst:IsA("BasePart") then
                if inst:IsA("UnionOperation") or inst:IsA("MeshPart") then
                    inst.RenderFidelity = Enum.RenderFidelity.Precise
                end
            end
        end)
    end
end

local function tryGetSource(scr)
    if decompile then
        local ok, s = pcall(decompile, scr)
        if ok and type(s) == "string" and s ~= "" then return s end
    end
    if getscriptsource then
        local ok, s = pcall(getscriptsource, scr)
        if ok and type(s) == "string" and s ~= "" then return s end
    end
    local ok, s = pcall(function() return scr.Source end)
    if ok and type(s) == "string" and s ~= "" then return s end
    return nil
end

local function unlockScript(scr)
    if not scr or not scr.Parent then return end
    local src    = tryGetSource(scr)
    local cls    = scr.ClassName
    local name   = scr.Name
    local parent = scr.Parent
    local new
    local ok1 = pcall(function()
        new = Instance.new(cls)
        new.Name = name
        if sethiddenproperty then
            pcall(sethiddenproperty, new, "LinkedSource", "")
            pcall(sethiddenproperty, new, "ScriptGuid",   "")
        end
        if src then
            pcall(function() new.Source = src end)
            if sethiddenproperty then
                pcall(sethiddenproperty, new, "Source", src)
            end
        end
        new.Disabled = false
        new.Parent   = PlayerGui
    end)
    if not ok1 or not new then return end
    task.wait(0.01)
    local ok2 = pcall(function() new.Parent = parent end)
    if not ok2 then pcall(function() new:Destroy() end); return end
    pcall(function() scr:Destroy() end)
end

local function unlockAllInTree(root)
    if not root then return 0 end
    local list = {}
    if root:IsA("LuaSourceContainer") then table.insert(list, root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then table.insert(list, d) end
    end
    for _, s in ipairs(list) do
        pcall(unlockScript, s); task.wait(0.01)
    end
    return #list
end

-- [[ DEKLARASI GUI UTAMA MAP COPY ]]
if PlayerGui:FindFirstChild("SpyzyyCopyGuiV2") then
    PlayerGui:FindFirstChild("SpyzyyCopyGuiV2"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyzyyCopyGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 230, 0, 550) -- Ditambah tingginya untuk teks nama objek loop
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -275)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
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
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "🚀 COPY MAP BY SPYZYY V2.2 🚀"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = MainFrame

-- [[ PANEL PROFILE USER ]]
local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(0, 206, 0, 85)
InfoPanel.Position = UDim2.new(0, 12, 0, 40)
InfoPanel.BackgroundColor3 = Color3.fromRGB(24, 20, 32)
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = MainFrame

local InfoPanelCorner = Instance.new("UICorner")
InfoPanelCorner.CornerRadius = UDim.new(0, 6)
InfoPanelCorner.Parent = InfoPanel

local InfoPanelStroke = Instance.new("UIStroke")
InfoPanelStroke.Thickness = 1
InfoPanelStroke.Color = Color3.fromRGB(60, 45, 90)
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
        AgeLabel.Text = "📅 Umur Akun: " .. LocalPlayer.AccountAge .. " Hari"
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

-- [[ PANEL INFO SCRIPT ]]
local ScriptInfoPanel = Instance.new("Frame")
ScriptInfoPanel.Size = UDim2.new(0, 206, 0, 55)
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

local CreateScriptLabel = function(text, color, order)
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

CreateScriptLabel("✨ Script: Spyzyy Copyy", Color3.fromRGB(255, 255, 255), 1)
CreateScriptLabel("👑 Status: PREMIUM", Color3.fromRGB(255, 200, 0), 2)
CreateScriptLabel("🛠️ Engine: v2.2", Color3.fromRGB(0, 255, 200), 3)

-- [[ TOMBOL & ELEMENT GUI SCRIPT ]]
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 206, 0, 35)
CopyButton.Position = UDim2.new(0, 12, 0, 195)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.Text = "COPYY OMM"
CopyButton.Font = Enum.Font.SourceSansBold
CopyButton.TextSize = 18
CopyButton.Parent = MainFrame

local CopyButtonCorner = Instance.new("UICorner")
CopyButtonCorner.CornerRadius = UDim.new(0, 6)
CopyButtonCorner.Parent = CopyButton

-- ANIMASI PROGRESS BAR
local ProgressBarBg = Instance.new("Frame")
ProgressBarBg.Name = "ProgressBarBg"
ProgressBarBg.Size = UDim2.new(0, 206, 0, 6)
ProgressBarBg.Position = UDim2.new(0, 12, 0, 236)
ProgressBarBg.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
ProgressBarBg.BorderSizePixel = 0
ProgressBarBg.Parent = MainFrame

local ProgressBarBgCorner = Instance.new("UICorner")
ProgressBarBgCorner.CornerRadius = UDim.new(0, 3)
ProgressBarBgCorner.Parent = ProgressBarBg

local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Name = "ProgressBarFill"
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
ProgressBarFill.BorderSizePixel = 0
ProgressBarFill.Parent = ProgressBarBg

local ProgressBarFillCorner = Instance.new("UICorner")
ProgressBarFillCorner.CornerRadius = UDim.new(0, 3)
ProgressBarFillCorner.Parent = ProgressBarFill

-- LIVE OBJECT LOOP PROCESSOR LABEL (DI BAWAH PROGRESS BAR)
local LiveObjectLabel = Instance.new("TextLabel")
LiveObjectLabel.Name = "LiveObjectLabel"
LiveObjectLabel.Size = UDim2.new(0, 206, 0, 16)
LiveObjectLabel.Position = UDim2.new(0, 12, 0, 245)
LiveObjectLabel.BackgroundTransparency = 1
LiveObjectLabel.Text = "Waiting..."
LiveObjectLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
LiveObjectLabel.TextXAlignment = Enum.TextXAlignment.Center
LiveObjectLabel.Font = Enum.Font.Code
LiveObjectLabel.TextSize = 10
LiveObjectLabel.Parent = MainFrame

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, -24, 0, 20)
ListLabel.Position = UDim2.new(0, 12, 0, 265)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Pilih Data File Untuk Di-Paste (Insert):"
ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.SourceSansSemibold
ListLabel.TextSize = 12
ListLabel.Parent = MainFrame

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(0, 206, 0, 140)
ListScroll.Position = UDim2.new(0, 12, 0, 287)
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
RefreshButton.Size = UDim2.new(0, 98, 0, 26)
RefreshButton.Position = UDim2.new(0, 12, 0, 437)
RefreshButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RefreshButton.TextColor3 = Color3.fromRGB(200, 200, 200)
RefreshButton.Text = "🔄"
RefreshButton.Font = Enum.Font.SourceSansBold
RefreshButton.TextSize = 14
RefreshButton.Parent = MainFrame

local RefreshCorner = Instance.new("UICorner")
RefreshCorner.CornerRadius = UDim.new(0, 4)
RefreshCorner.Parent = RefreshButton

local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0, 102, 0, 26)
ClearButton.Position = UDim2.new(0, 116, 0, 437)
ClearButton.BackgroundColor3 = Color3.fromRGB(180, 35, 35)
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.Text = "🗑"
ClearButton.Font = Enum.Font.SourceSansBold
ClearButton.TextSize = 14
ClearButton.Parent = MainFrame

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 4)
ClearCorner.Parent = ClearButton

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -24, 0, 25)
StatusLabel.Position = UDim2.new(0, 12, 0, 515)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Siap 🟢"
StatusLabel.TextColor3 = Color3.fromRGB(95, 235, 140)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

local function setStatus(msg, col)
    StatusLabel.Text = "Status: " .. msg
    StatusLabel.TextColor3 = col or Color3.fromRGB(95, 235, 140)
end

local function updateProgress(current, total, currentItemName)
    local percentage = math.clamp(current / total, 0, 1)
    TweenService:Create(ProgressBarFill, TweenInfo.new(0.02, Enum.EasingStyle.Linear), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
    if currentItemName then
        local displayText = "[" .. current .. "/" .. total .. "] " .. currentItemName
        if #displayText > 35 then
            displayText = string.sub(displayText, 1, 32) .. "..."
        end
        LiveObjectLabel.Text = displayText
    else
        LiveObjectLabel.Text = "Processing..."
    end
end

-- [[ INTEGRASI FITUR DRAG ]]
local GuiIcon = Instance.new("TextButton")
GuiIcon.Name = "GuiToggleButton"
GuiIcon.Size = UDim2.new(0, 50, 0, 50)
GuiIcon.Position = UDim2.new(0, 20, 0, 20)
GuiIcon.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
GuiIcon.Text = "🛠️"
GuiIcon.TextSize = 22
GuiIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
GuiIcon.Visible = false
GuiIcon.Active = true
GuiIcon.ZIndex = 10
GuiIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0)
IconCorner.Parent = GuiIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Thickness = 2
IconStroke.Color = Color3.fromRGB(0, 200, 255)
IconStroke.Parent = GuiIcon

GuiIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    GuiIcon.Visible = false
end)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "❌"
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Parent = MainFrame

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    GuiIcon.Visible = true
end)

local function makeDraggable(frame)
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
makeDraggable(MainFrame)
makeDraggable(GuiIcon)

ClearButton.MouseButton1Click:Connect(function()
    for _, ch in ipairs(workspace:GetChildren()) do
        if not ch:IsA("Terrain") and ch ~= workspace.CurrentCamera then
            pcall(function() ch:Destroy() end)
        end
    end
    setStatus("WORKSPACE Dibersihkan!", Color3.fromRGB(255, 185, 55))
    task.wait(1.5)
    setStatus("Siap 🟢")
end)

local function getRelativePath(obj)
    local path = {}
    local current = obj.Parent
    while current and current ~= game do
        table.insert(path, 1, {Name = current.Name, ClassName = current.ClassName})
        current = current.Parent
    end
    return path
end

local function isAPlayerCharacter(obj)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and (obj == p.Character or obj:IsDescendantOf(p.Character)) then return true end
    end
    if obj:IsA("Player") or obj.Name == LocalPlayer.Name then return true end
    return false
end

-- [[ CORE ENGINE COPY/PASTE (OPTIMIZED & EXPANDED ALL SERVICES) ]]
CopyButton.MouseButton1Click:Connect(function()
    if not writefile then 
        CopyButton.Text = "❌"
        return 
    end
    CopyButton.Text = "⏳"
    setStatus("Scanning Object...", Color3.fromRGB(255, 185, 55))
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    
    -- Mengumpulkan data dari semua Container Utama game
    local containers = {workspace, Lighting, ReplicatedStorage, ServerStorage, StarterPack, StarterGui}
    local objectsToScan = {}
    
    for _, container in ipairs(containers) do
        if container then
            pcall(function()
                for _, obj in pairs(container:GetDescendants()) do
                    if not obj:IsDescendantOf(Players) and not obj:IsA("Camera") and not obj:IsA("Terrain") and not isAPlayerCharacter(obj) then
                        table.insert(objectsToScan, obj)
                    end
                end
            end)
        end
    end
    
    local totalObjects = #objectsToScan

    for _, obj in pairs(objectsToScan) do
        count = count + 1
        
        if count % 20 == 0 or count == totalObjects then 
            local cleanName = obj.Name
            setStatus("Copying Process...", Color3.fromRGB(255, 180, 50))
            updateProgress(count, totalObjects, cleanName)
            task.wait() 
        end
        
        local relPath = getRelativePath(obj)
        local data = {
            Name = obj.Name,
            ClassName = obj.ClassName,
            RelativePath = relPath,
            Depth = #relPath,
            Properties = {}
        }
        
        pcall(function()
            -- Universal Textures, Meshes, Ids, & Values
            local props = {
                "Texture", "TextureId", "MeshId", "AssetId", "Value", "Volume", "SoundId", "Image", 
                "Enabled", "Face", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", 
                "CelestialBodiesShown", "MoonId", "SunId", "Text", "TextColor3", "PlaceholderText", "Size"
            }
            for _, propName in ipairs(props) do
                pcall(function()
                    if obj[propName] ~= nil then 
                        if typeof(obj[propName]) == "Color3" then
                            data.Properties[propName] = {obj[propName].r * 255, obj[propName].g * 255, obj[propName].b * 255}
                        elseif typeof(obj[propName]) == "Vector3" then
                            data.Properties[propName] = {obj[propName].X, obj[propName].Y, obj[propName].Z}
                        elseif typeof(obj[propName]) == "UDim2" then
                            data.Properties[propName] = {obj[propName].X.Scale, obj[propName].X.Offset, obj[propName].Y.Scale, obj[propName].Y.Offset}
                        else
                            data.Properties[propName] = tostring(obj[propName]) 
                        end
                    end
                end)
            end
            
            -- Anti-Brantakan Properti Fisik (3D Objects / Parts / Mesh)
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
            elseif obj:IsA("Model") then
                data.Properties.WorldPivot = {obj:GetPivot():GetComponents()}
            elseif obj:IsA("Lighting") or obj:IsA("Sky") or obj:IsA("Atmosphere") then
                -- Menjaga Pencahayaan Tetap Sesuai
                pcall(function() data.Properties.ClockTime = obj.ClockTime end)
                pcall(function() data.Properties.Ambient = {obj.Ambient.r * 255, obj.Ambient.g * 255, obj.Ambient.b * 255} end)
                pcall(function() data.Properties.OutdoorAmbient = {obj.OutdoorAmbient.r * 255, obj.OutdoorAmbient.g * 255, obj.OutdoorAmbient.b * 255} end)
                pcall(function() data.Properties.Brightness = obj.Brightness end)
            end
            
            table.insert(SaveData, data)
        end)
    end
    
    writefile(fileName, HttpService:JSONEncode(SaveData))
    CopyButton.Text = "✅"
    setStatus("Map Berhasil Disimpan! ✓", Color3.fromRGB(90, 235, 135))
    updateProgress(1, 1, "Completed!")
    task.wait(1.5)
    CopyButton.Text = "COPYY OMM"
    setStatus("Siap 🟢")
    LiveObjectLabel.Text = "Waiting..."
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
                setStatus("Pasting Data...", Color3.fromRGB(255, 185, 55))
                
                task.spawn(function()
                    local success, err = pcall(function()
                        local fileContent = readfile(file)
                        local loadedData = HttpService:JSONDecode(fileContent)
                        table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                        
                        -- Penempatan Ungroup Sesuai Lokasi Asal Container
                        local function getTargetFolder(pathData)
                            if #pathData == 0 then return workspace end
                            local baseContainerName = pathData[1].Name
                            if baseContainerName == "Lighting" then return Lighting end
                            if baseContainerName == "ReplicatedStorage" then return ReplicatedStorage end
                            if baseContainerName == "ServerStorage" then return ServerStorage end
                            if baseContainerName == "StarterPack" then return StarterPack end
                            if baseContainerName == "StarterGui" then return StarterGui end
                            return workspace
                        end
                        
                        local function findOrCreateParent(relativePath)
                            local currentParent = getTargetFolder(relativePath)
                            for i = 2, #relativePath do
                                local pathInfo = relativePath[i]
                                local found = currentParent:FindFirstChild(pathInfo.Name)
                                if not found then
                                    pcall(function() found = Instance.new(pathInfo.ClassName) end)
                                    if not found then found = Instance.new("Folder") end
                                    found.Name = pathInfo.Name
                                    found.Parent = currentParent
                                end
                                currentParent = found
                            end
                            return currentParent
                        end
                        
                        local pasteCount = 0
                        local totalPaste = #loadedData
                        
                        for _, data in ipairs(loadedData) do
                            pcall(function()
                                if data.ClassName == "DataModel" then return end
                                local targetParent = findOrCreateParent(data.RelativePath)
                                if targetParent:FindFirstChild(data.Name) and (data.ClassName == "Folder" or data.ClassName == "Model") then return end
                                
                                pasteCount = pasteCount + 1
                                if pasteCount % 20 == 0 or pasteCount == totalPaste then
                                    setStatus("Pasting Objects...", Color3.fromRGB(255, 185, 55))
                                    updateProgress(pasteCount, totalPaste, data.Name)
                                    task.wait()
                                end
                                
                                local newObj
                                local props = data.Properties or {}
                                
                                local createSuccess = pcall(function() newObj = Instance.new(data.ClassName) end)
                                if not createSuccess or not newObj then return end
                                
                                newObj.Name = data.Name
                                
                                if newObj:IsA("BasePart") and props.CFrame then
                                    newObj.Size = Vector3.new(unpack(props.Size))
                                    newObj.CFrame = CFrame.new(unpack(props.CFrame))
                                    newObj.Color = Color3.fromRGB(unpack(props.Color))
                                    pcall(function() newObj.Material = Enum.Material[props.Material] end)
                                    newObj.Transparency = props.Transparency
                                    newObj.Anchored = props.Anchored
                                    newObj.CanCollide = props.CanCollide
                                    pcall(function() newObj.CastShadow = props.CastShadow end)
                                elseif newObj:IsA("Model") and props.WorldPivot then
                                    pcall(function() newObj:PivotTo(CFrame.new(unpack(props.WorldPivot))) end)
                                end
                                
                                -- Re-Apply Properti Khusus agar Anti-Brantakan
                                for pName, pVal in pairs(props) do
                                    pcall(function()
                                        if pName ~= "Size" and pName ~= "CFrame" and pName ~= "Color" and pName ~= "Material" and pName ~= "Transparency" and pName ~= "Anchored" and pName ~= "CanCollide" and pName ~= "WorldPivot" then
                                            if type(pVal) == "table" and #pVal == 3 then
                                                newObj[pName] = Color3.fromRGB(unpack(pVal))
                                            elseif type(pVal) == "table" and #pVal == 4 then
                                                newObj[pName] = UDim2.new(unpack(pVal))
                                            else
                                                newObj[pName] = pVal
                                            end
                                        end
                                    end)
                                end
                                
                                newObj.Parent = targetParent
                            end)
                        end
                        
                        processParts(workspace)
                        unlockAllInTree(workspace)
                    end)
                    
                    if success then
                        FileSelectBtn.Text = " 📄 " .. cleanName
                        setStatus("Sukses Terpasang! 🎉", Color3.fromRGB(90, 235, 135))
                    else
                        FileSelectBtn.Text = " 📄 " .. cleanName
                        setStatus("Gagal Memuat Objek!", Color3.fromRGB(230, 72, 72))
                    end
                    updateProgress(1, 1, "Done!")
                    task.wait(1.5)
                    setStatus("Siap 🟢")
                    LiveObjectLabel.Text = "Waiting..."
                end)
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

RefreshButton.MouseButton1Click:Connect(_G.UpdatePasteList)
_G.UpdatePasteList()
