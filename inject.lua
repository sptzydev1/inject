-- [[ UPDATE DELTA COPYY CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local LocalPlayer = Players.LocalPlayer

-- Proteksi Instan PlayerGui
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui

-- Mendapatkan Nama Game Secara Otomatis (Aman dari Delay)
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
local TargetFolder = workspace

-- ==================================================
--  (CORE PROCESSOR)
-- ==================================================

-- 1. Part Processor (Optimalisasi Part & Render Precise)
local function processParts(root)
    for _, inst in ipairs(root:GetDescendants()) do
        pcall(function()
            if inst:IsA("BasePart") then
                inst.Anchored = true
                if inst:IsA("UnionOperation") or inst:IsA("MeshPart") then
                    inst.RenderFidelity = Enum.RenderFidelity.Precise
                end
            end
        end)
    end
end

-- 2. Script Unlocker (Decompile & Bypass)
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
    task.wait(0.05)
    local ok2 = pcall(function() new.Parent = parent end)
    if not ok2 then pcall(function() new:Destroy() end); return end
    pcall(function() scr:Destroy() end)
    if cls == "LocalScript" and src then
        pcall(function() task.spawn(loadstring(src)) end)
    end
end

local function unlockAllInTree(root)
    if not root then return 0 end
    local list = {}
    if root:IsA("LuaSourceContainer") then table.insert(list, root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then table.insert(list, d) end
    end
    for _, s in ipairs(list) do
        pcall(unlockScript, s); task.wait(0.02)
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
MainFrame.Size = UDim2.new(0, 230, 0, 510)
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -255)
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
Title.Text = "🚀 COPY MAP BY SPYZYY V2.1 🚀"
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

CreateScriptLabel("✨ Script: Sptzyy Copyy", Color3.fromRGB(255, 255, 255), 1)
CreateScriptLabel("👑 Status: PREMIUM", Color3.fromRGB(255, 200, 0), 2)
CreateScriptLabel("🛠️ Engine: v2.1", Color3.fromRGB(0, 255, 200), 3)

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

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, -24, 0, 20)
ListLabel.Position = UDim2.new(0, 12, 0, 235)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Pilih Data File Untuk Di-Paste (Insert):"
ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.SourceSansSemibold
ListLabel.TextSize = 12
ListLabel.Parent = MainFrame

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(0, 206, 0, 140)
ListScroll.Position = UDim2.new(0, 12, 0, 255)
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
RefreshButton.Position = UDim2.new(0, 12, 0, 405)
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
ClearButton.Position = UDim2.new(0, 116, 0, 405)
ClearButton.BackgroundColor3 = Color3.fromRGB(180, 35, 35)
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.Text = "🗑"
ClearButton.Font = Enum.Font.SourceSansBold
ClearButton.TextSize = 14
ClearButton.Parent = MainFrame

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 4)
ClearCorner.Parent = ClearButton

-- Label Status di Bagian Paling Bawah
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -24, 0, 25)
StatusLabel.Position = UDim2.new(0, 12, 0, 475)
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

-- [[ INTEGRASI FITUR: ICON OPEN/CLOSE GUI & RESIZABLE ]]
local GuiIcon = Instance.new("TextButton")
GuiIcon.Name = "GuiToggleButton"
GuiIcon.Size = UDim2.new(0, 50, 0, 50)
GuiIcon.Position = UDim2.new(0, 20, 0, 20)
GuiIcon.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
GuiIcon.Text = "🛠️"
GuiIcon.TextSize = 22
GuiIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
GuiIcon.Visible = false -- Tersembunyi saat awal terbuka
GuiIcon.Active = true
GuiIcon.ZIndex = 10
GuiIcon.Parent = ScreenGui

local IconCorner = Instance.new("UICorner")
IconCorner.CornerRadius = UDim.new(1, 0) -- Lingkaran Sempurna
IconCorner.Parent = GuiIcon

local IconStroke = Instance.new("UIStroke")
IconStroke.Thickness = 2
IconStroke.Color = Color3.fromRGB(0, 200, 255)
IconStroke.Parent = GuiIcon

-- Logika Membuka/Menutup GUI utama lewat Icon
GuiIcon.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    GuiIcon.Visible = false
end)

-- Tombol Close di MainFrame (Opsional ditambahkan di pojok kanan atas)
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

-- Draggable Logic Fungsi Umum untuk Frame dan Icon
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

-- Fitur Geser Luas Ukuran Icon Menggunakan Scroll Mouse / Input Wheel
GuiIcon.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local currentSize = GuiIcon.Size.X.Offset
        local newSize = math.clamp(currentSize + (input.Position.Z * 5), 35, 100) -- Batas min 35px, max 100px
        GuiIcon.Size = UDim2.new(0, newSize, 0, newSize)
        GuiIcon.TextSize = newSize * 0.45 -- Menyesuaikan skala icon di dalamnya
    end
end)


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

-- [[ CORE ENGINE COPY/PASTE ]]
local function getRelativePath(obj)
    local path = {}
    local current = obj.Parent
    while current and current ~= workspace and current ~= game do
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
    ["Sky"] = true, ["Atmosphere"] = true, ["Clouds"] = true,
    ["LocalScript"] = true, ["Script"] = true, ["ModuleScript"] = true
}

CopyButton.MouseButton1Click:Connect(function()
    if not writefile then 
        CopyButton.Text = "❌"
        return 
    end
    CopyButton.Text = "⏳"
    setStatus("Scanning Map...", Color3.fromRGB(255, 185, 55))
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    local objectsToScan = TargetFolder:GetDescendants()
    
    -- Loading loop variables
    local loadingFrames = {"|", "/", "-", "\\"}
    local frameIdx = 1

    for _, obj in pairs(objectsToScan) do
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") or AllowedSupportClasses[obj.ClassName] then
            if not obj:IsDescendantOf(Players) and not obj:IsA("Camera") and not obj:IsA("Terrain") and not isAPlayerCharacter(obj) then
                count = count + 1
                
                -- Loop Loading rapi per 200 item agar responsif & tampilkan nama item
                if count % 200 == 0 then 
                    frameIdx = (frameIdx % #loadingFrames) + 1
                    local cleanName = #obj.Name > 15 and string.sub(obj.Name, 1, 13) .. ".." or obj.Name
                    setStatus(loadingFrames[frameIdx] .. " Copying: " .. cleanName, Color3.fromRGB(255, 180, 50))
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
                    if obj:IsA("BasePart") then
                        data.Properties.Size = {obj.Size.X, obj.Size.Y, obj.Size.Z}
                        data.Properties.CFrame = {obj.CFrame:GetComponents()}
                        data.Properties.Color = {obj.Color.r * 255, obj.Color.g * 255, obj.Color.b * 255}
                        data.Properties.Material = obj.Material.Name
                        data.Properties.Transparency = obj.Transparency
                        data.Properties.Reflectance = obj.Reflectance
                        data.Properties.Anchored = obj.Anchored
                        data.Properties.CanCollide = obj.CanCollide
                        
                        if obj:IsA("MeshPart") then
                            data.Properties.MeshId = obj.MeshId
                            data.Properties.TextureId = obj.TextureId
                        elseif obj:IsA("UnionOperation") then
                            data.Properties.AssetId = obj.AssetId
                        end
                    elseif obj:IsA("Model") then
                        data.Properties.WorldPivot = {obj:GetPivot():GetComponents()}
                    elseif AllowedSupportClasses[obj.ClassName] then
                        pcall(function() data.Properties.Texture = obj.Texture end)
                        pcall(function() data.Properties.TextureId = obj.TextureId end)
                        pcall(function() data.Properties.MeshId = obj.MeshId end)
                        pcall(function() data.Properties.Color3 = {obj.Color3.r * 255, obj.Color3.g * 255, obj.Color3.b * 255} end)
                        pcall(function() data.Properties.Enabled = obj.Enabled end)
                    end
                    table.insert(SaveData, data)
                end)
            end
        end
    end
    
    writefile(fileName, HttpService:JSONEncode(SaveData))
    CopyButton.Text = "✅"
    setStatus("Map Berhasil Disimpan! ✓", Color3.fromRGB(90, 235, 135))
    task.wait(2)
    CopyButton.Text = "COPYY OMM"
    setStatus("Siap 🟢")
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
                setStatus("Pasting & Optimizing...", Color3.fromRGB(255, 185, 55))
                
                task.spawn(function()
                    local success, err = pcall(function()
                        local fileContent = readfile(file)
                        local loadedData = HttpService:JSONDecode(fileContent)
                        table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                        
                        local MasterFolder = workspace:FindFirstChild("Paste_" .. cleanName) or Instance.new("Folder")
                        MasterFolder.Name = "Paste_" .. cleanName
                        MasterFolder.Parent = workspace
                        
                        local function findOrCreateParent(relativePath)
                            local currentParent = MasterFolder
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
                                end
                                currentParent = found
                            end
                            return currentParent
                        end
                        
                        local pasteCount = 0
                        local loadingFrames = {"|", "/", "-", "\\"}
                        local frameIdx = 1
                        
                        for _, data in ipairs(loadedData) do
                            pcall(function()
                                local targetParent = findOrCreateParent(data.RelativePath)
                                if targetParent:FindFirstChild(data.Name) and (data.ClassName == "Folder" or data.ClassName == "Model") then return end
                                
                                pasteCount = pasteCount + 1
                                if pasteCount % 200 == 0 then
                                    frameIdx = (frameIdx % #loadingFrames) + 1
                                    local itemCleanName = #data.Name > 15 and string.sub(data.Name, 1, 13) .. ".." or data.Name
                                    setStatus(loadingFrames[frameIdx] .. " Pasting: " .. itemCleanName, Color3.fromRGB(255, 185, 55))
                                    task.wait()
                                end
                                
                                local newObj
                                local props = data.Properties or {}
                                if AllowedSupportClasses[data.ClassName] then
                                    newObj = Instance.new(data.ClassName)
                                    pcall(function() if props.Texture then newObj.Texture = props.Texture end end)
                                    pcall(function() if props.TextureId then newObj.TextureId = props.TextureId end end)
                                    pcall(function() if props.Enabled ~= nil then newObj.Enabled = props.Enabled end end)
                                elseif data.ClassName == "Folder" or data.ClassName == "Model" or data.ClassName == "Part" then
                                    newObj = Instance.new(data.ClassName)
                                else
                                    newObj = Instance.new("Part")
                                end
                                
                                newObj.Name = data.Name
                                if newObj:IsA("BasePart") and props.CFrame then
                                    newObj.Size = Vector3.new(unpack(props.Size))
                                    newObj.CFrame = CFrame.new(unpack(props.CFrame))
                                    newObj.Color = Color3.fromRGB(unpack(props.Color))
                                    pcall(function() newObj.Material = Enum.Material[props.Material] end)
                                    newObj.Transparency = props.Transparency
                                    newObj.Anchored = props.Anchored
                                    newObj.CanCollide = props.CanCollide
                                end
                                
                                newObj.Parent = targetParent
                            end)
                        end
                        
                        setStatus("Processing Parts...", Color3.fromRGB(255, 185, 55))
                        processParts(MasterFolder)
                        
                        setStatus("Unlocking Scripts...", Color3.fromRGB(255, 185, 55))
                        unlockAllInTree(MasterFolder)
                    end)
                    
                    if success then
                        FileSelectBtn.Text = " 📄 " .. cleanName
                        setStatus("Sukses Terpasang + Dioptimasi! 🎉", Color3.fromRGB(90, 235, 135))
                    else
                        FileSelectBtn.Text = " 📄 " .. cleanName
                        setStatus("Gagal Memuat Objek!", Color3.fromRGB(230, 72, 72))
                    end
                    task.wait(2)
                    setStatus("Siap 🟢")
                end)
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

RefreshButton.MouseButton1Click:Connect(_G.UpdatePasteList)
_G.UpdatePasteList()
