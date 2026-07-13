-- [[ UPDATE DELTA COPYY CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserService = game:GetService("UserService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local FILE_PREFIX = "GameCopyUltimate_"

-- ==================================================
--  (CORE PROCESSOR)
-- ==================================================

local function processParts(root)
    for _, inst in ipairs(root:GetDescendants()) do
        pcall(function()
            if inst:IsA("BasePart") then
                inst.Anchored = true -- Anti berantakan / jatuh
                if inst:IsA("UnionOperation") or inst:IsA("MeshPart") then
                    inst.RenderFidelity = Enum.RenderFidelity.Precise
                end
            end
        end)
    end
end

-- [[ DEKLARASI GUI UTAMA MAP COPY ]]
if PlayerGui:FindFirstChild("SpyzyyCopyGuiV2") then
    PlayerGui:FindFirstChild("SpyzyyCopyGuiV2"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyzyyCopyGuiV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 530)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -265)
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
Title.Text = "🚀 ULTIMATE COPY v2.3 🚀"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.Parent = MainFrame

-- [[ PANEL PROFILE & SCRIPT INFO ]]
local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(0, 216, 0, 70)
InfoPanel.Position = UDim2.new(0, 12, 0, 40)
InfoPanel.BackgroundColor3 = Color3.fromRGB(24, 20, 32)
InfoPanel.Parent = MainFrame

local InfoPanelCorner = Instance.new("UICorner")
InfoPanelCorner.CornerRadius = UDim.new(0, 6)
InfoPanelCorner.Parent = InfoPanel

local UserLayout = Instance.new("UIListLayout")
UserLayout.Padding = UDim.new(0, 1)
UserLayout.Parent = InfoPanel

local function CreateProfileLabel(text, color)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 16)
    label.BackgroundTransparency = 1
    label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.SourceSansSemibold
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = "  " .. text
    label.Parent = InfoPanel
    return label
end

local NameLabel = CreateProfileLabel("👤 @" .. LocalPlayer.Name, Color3.fromRGB(255, 255, 255))
local StatusLabelPremium = CreateProfileLabel("👑 Status: MULTI-STORAGE PREMIUM", Color3.fromRGB(255, 200, 0))

-- [[ TOMBOL COPY ]]
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 216, 0, 35)
CopyButton.Position = UDim2.new(0, 12, 0, 120)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.Text = "FULL REPLICATE COPY"
CopyButton.Font = Enum.Font.SourceSansBold
CopyButton.TextSize = 16
CopyButton.Parent = MainFrame

local CopyButtonCorner = Instance.new("UICorner")
CopyButtonCorner.CornerRadius = UDim.new(0, 6)
CopyButtonCorner.Parent = CopyButton

-- PROGRESS BAR VISUAL
local ProgressBarBg = Instance.new("Frame")
ProgressBarBg.Size = UDim2.new(0, 216, 0, 6)
ProgressBarBg.Position = UDim2.new(0, 12, 0, 165)
ProgressBarBg.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
ProgressBarBg.Parent = MainFrame

local ProgressBarFill = Instance.new("Frame")
ProgressBarFill.Size = UDim2.new(0, 0, 1, 0)
ProgressBarFill.BackgroundColor3 = Color3.fromRGB(0, 210, 255)
ProgressBarFill.Parent = ProgressBarBg
Instance.new("UICorner").Parent = ProgressBarFill
Instance.new("UICorner").Parent = ProgressBarBg

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, -24, 0, 20)
ListLabel.Position = UDim2.new(0, 12, 0, 180)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "Daftar File Hasil Copy:"
ListLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.SourceSansSemibold
ListLabel.TextSize = 12
ListLabel.Parent = MainFrame

local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(0, 216, 0, 190)
ListScroll.Position = UDim2.new(0, 12, 0, 205)
ListScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ListScroll.ScrollBarThickness = 4
ListScroll.Parent = MainFrame
Instance.new("UICorner").Parent = ListScroll

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ListScroll

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(0, 100, 0, 26)
RefreshButton.Position = UDim2.new(0, 12, 0, 405)
RefreshButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RefreshButton.TextColor3 = Color3.fromRGB(200, 200, 200)
RefreshButton.Text = "🔄 Refresh"
RefreshButton.Font = Enum.Font.SourceSansBold
RefreshButton.TextSize = 12
RefreshButton.Parent = MainFrame

local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0, 106, 0, 26)
ClearButton.Position = UDim2.new(0, 122, 0, 405)
ClearButton.BackgroundColor3 = Color3.fromRGB(180, 35, 35)
ClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearButton.Text = "🗑 Clear Workspace"
ClearButton.Font = Enum.Font.SourceSansBold
ClearButton.TextSize = 12
ClearButton.Parent = MainFrame

-- Status Monitor (Tempat menampilkan nama item yang sedang di-copy)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -24, 0, 45)
StatusLabel.Position = UDim2.new(0, 12, 0, 440)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Ready 🟢"
StatusLabel.TextColor3 = Color3.fromRGB(95, 235, 140)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

local function setStatus(msg, col)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = col or Color3.fromRGB(95, 235, 140)
end

local function updateProgress(current, total)
    local percentage = math.clamp(current / total, 0, 1)
    TweenService:Create(ProgressBarFill, TweenInfo.new(0.02, Enum.EasingStyle.Linear), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
end

-- Fitur Close / Dragging sederhana
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "❌"
CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local function makeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true dragStart = input.Position startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(MainFrame)

ClearButton.MouseButton1Click:Connect(function()
    for _, ch in ipairs(workspace:GetChildren()) do
        if not ch:IsA("Terrain") and ch ~= workspace.CurrentCamera then pcall(function() ch:Destroy() end) end
    end
    setStatus("Workspace dibersihkan!", Color3.fromRGB(255, 185, 55))
end)

-- ==================================================
--  CORE MULTI-STORAGE SERIALIZATION SYSTEM
-- ==================================================

local function getHierarchyPath(obj)
    local path = {}
    local current = obj.Parent
    local rootName = "Workspace"
    
    while current and current ~= game do
        if current == workspace then rootName = "Workspace" break
        elseif current == Lighting then rootName = "Lighting" break
        elseif current == ReplicatedStorage then rootName = "ReplicatedStorage" break
        elseif current == StarterPack then rootName = "StarterPack" break
        elseif current == StarterGui then rootName = "StarterGui" break
        end
        table.insert(path, 1, {Name = current.Name, ClassName = current.ClassName})
        current = current.Parent
    end
    return rootName, path
end

local function checkValidData(obj)
    if obj:IsDescendantOf(Players) or obj:IsA("Camera") or obj:IsA("Terrain") then return false end
    if obj.ClassName == "PlayerGui" then return false end
    return true
end

CopyButton.MouseButton1Click:Connect(function()
    if not writefile then setStatus("Executor tidak mendukung writefile!", Color3.fromRGB(255, 70, 70)) return end
    CopyButton.Text = "⏳ MEMPROSES..."
    
    local SaveData = {}
    local rawObjects = {}
    
    -- Target Folder Multi-Storage (Daftar folder/service yang akan dicopy)
    local ServicesToScan = {workspace, Lighting, ReplicatedStorage, StarterPack, StarterGui}
    
    setStatus("Memindai seluruh Service data...", Color3.fromRGB(255, 185, 55))
    for _, srv in ipairs(ServicesToScan) do
        for _, obj in ipairs(srv:GetDescendants()) do
            if checkValidData(obj) then table.insert(rawObjects, obj) end
        end
    end
    
    local totalObjects = #rawObjects
    local count = 0
    
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    
    for _, obj in pairs(rawObjects) do
        count = count + 1
        
        -- Menampilkan nama yang sedang dicopy secara realtime pada panel status status
        if count % 20 == 0 or count == totalObjects then
            local locationName, _ = getHierarchyPath(obj)
            setStatus("📂 ["..locationName.."]\n✍️ Copying: " .. obj.Name .. "\n(" .. count .. "/" .. totalObjects .. ")", Color3.fromRGB(0, 200, 255))
            updateProgress(count, totalObjects)
            task.wait()
        end
        
        local rootLocation, relPath = getHierarchyPath(obj)
        local data = {
            Name = obj.Name,
            ClassName = obj.ClassName,
            RootLocation = rootLocation,
            RelativePath = relPath,
            Depth = #relPath,
            Properties = {}
        }
        
        pcall(function()
            -- Serialisasi Properti Terlengkap (Pencahayaan, Sky, Part, Tools, Asset ID)
            local targetProps = {
                "Texture", "TextureId", "MeshId", "AssetId", "Value", "Volume", "SoundId", "Image", "Enabled", "Face",
                "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId",
                "Ambient", "OutdoorAmbient", "ColorShift_Bottom", "ColorShift_Top", "Brightness", "ClockTime", "GeographicLatitude",
                "ExposureCompensation", "ShadowSoftness", "EnvironmentSpecularScale", "EnvironmentDiffuseScale",
                "Brightness", "Color", "Range", "Shadows", "Angle", "Face", "StudsPerTileU", "StudsPerTileV",
                "Tip", "Grip", "ToolTip"
            }
            
            for _, prop in ipairs(targetProps) do
                pcall(function()
                    if obj[prop] ~= nil then
                        if typeof(obj[prop]) == "Color3" then
                            data.Properties[prop] = {obj[prop].r * 255, obj[prop].g * 255, obj[prop].b * 255}
                        else
                            data.Properties[prop] = tostring(obj[prop])
                        end
                    end
                end)
            end
            
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
            end
            
            table.insert(SaveData, data)
        end)
    end
    
    writefile(fileName, HttpService:JSONEncode(SaveData))
    CopyButton.Text = "FULL REPLICATE COPY"
    setStatus("🎉 Copy Selesai! File Tersimpan:\n" .. fileName, Color3.fromRGB(90, 235, 135))
    updateProgress(1, 1)
    _G.UpdatePasteList()
end)

_G.UpdatePasteList = function()
    for _, child in pairs(ListScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
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
            FileSelectBtn.Text = " 📄 " .. (string.sub(cleanName, 1, 18) .. "..")
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
                pcall(delfile, file) ItemFrame:Destroy() _G.UpdatePasteList()
            end)
            
            FileSelectBtn.MouseButton1Click:Connect(function()
                setStatus("Mengurai data file JSON...", Color3.fromRGB(255, 185, 55))
                
                task.spawn(function()
                    local success, _ = pcall(function()
                        local fileContent = readfile(file)
                        local loadedData = HttpService:JSONDecode(fileContent)
                        table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                        
                        local totalPaste = #loadedData
                        local pasteCount = 0
                        
                        -- Penentuan Root Target Lokasi
                        local rootMapping = {
                            ["Workspace"] = workspace,
                            ["Lighting"] = Lighting,
                            ["ReplicatedStorage"] = ReplicatedStorage,
                            ["StarterPack"] = StarterPack,
                            ["StarterGui"] = StarterGui
                        }
                        
                        for _, data in ipairs(loadedData) do
                            pcall(function()
                                local baseRoot = rootMapping[data.RootLocation] or workspace
                                
                                -- Membangun jalur folder/parent di service masing-masing
                                local currentParent = baseRoot
                                for _, pathInfo in ipairs(data.RelativePath) do
                                    local found = currentParent:FindFirstChild(pathInfo.Name)
                                    if not found then
                                        pcall(function() found = Instance.new(pathInfo.ClassName) end)
                                        if not found then found = Instance.new("Folder") end
                                        found.Name = pathInfo.Name
                                        found.Parent = currentParent
                                    end
                                    currentParent = found
                                end
                                
                                pasteCount = pasteCount + 1
                                if pasteCount % 20 == 0 or pasteCount == totalPaste then
                                    setStatus("📥 ["..data.RootLocation.."]\n🧱 Pasting: " .. data.Name, Color3.fromRGB(255, 185, 55))
                                    updateProgress(pasteCount, totalPaste)
                                    task.wait()
                                end
                                
                                -- Hindari duplikasi Root Folder atau Model utama
                                if currentParent:FindFirstChild(data.Name) and (data.ClassName == "Folder" or data.ClassName == "Model") then return end
                                
                                local newObj
                                local props = data.Properties or {}
                                
                                local createSuccess = pcall(function() newObj = Instance.new(data.ClassName) end)
                                if not createSuccess or not newObj then newObj = Instance.new("Part") end
                                
                                newObj.Name = data.Name
                                
                                -- Setup Properti Fisik (Part & Model)
                                if newObj:IsA("BasePart") and props.CFrame then
                                    newObj.Size = Vector3.new(unpack(props.Size))
                                    newObj.CFrame = CFrame.new(unpack(props.CFrame))
                                    newObj.Color = Color3.fromRGB(unpack(props.Color))
                                    pcall(function() newObj.Material = Enum.Material[props.Material] end)
                                    newObj.Transparency = props.Transparency
                                    newObj.Anchored = props.Anchored
                                    newObj.CanCollide = props.CanCollide
                                elseif newObj:IsA("Model") and props.WorldPivot then
                                    pcall(function() newObj:PivotTo(CFrame.new(unpack(props.WorldPivot))) end)
                                end
                                
                                -- Kembalikan data string/id/Color3 universal pencahayaan/sky/tools
                                for pName, pVal in pairs(props) do
                                    pcall(function()
                                        if type(pVal) == "table" then
                                            newObj[pName] = Color3.fromRGB(unpack(pVal))
                                        else
                                            newObj[pName] = pVal
                                        end
                                     pcall(function() if pName == "Enabled" then newObj.Enabled = (pVal == "true") end end)
                                     pcall(function() if pName == "Anchored" then newObj.Anchored = (pVal == "true") end end)
                                    end)
                                end
                                
                                newObj.Parent = currentParent
                            end)
                        end
                        
                        setStatus("Mengoptimasi Rendering Map...", Color3.fromRGB(255, 185, 55))
                        processParts(workspace)
                    end)
                    
                    if success then
                        setStatus("🎉 Paste Berhasil & Seluruh Storage Sinkron!", Color3.fromRGB(90, 235, 135))
                    else
                        setStatus("Gagal memproses data paste!", Color3.fromRGB(230, 72, 72))
                    end
                    updateProgress(0, 1)
                end)
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

RefreshButton.MouseButton1Click:Connect(_G.UpdatePasteList)
_G.UpdatePasteList()
