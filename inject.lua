-- [[ CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
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

-- [[ DEKLARASI GUI UTAMA MAP COPY (COMPACT VERSION) ]]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyzyyCopyGuiLite"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 45, 0, 45)
ToggleButton.Position = UDim2.new(0.02, 0, 0.5, -22)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ToggleButton.Text = "🛡️"
ToggleButton.TextSize = 20
ToggleButton.Visible = false
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 230, 0, 320) -- Diperkecil, buang panel profile ga penting
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -35, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🚀 COPY MAP LITE V2.5"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 2)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = "❌"
CloseButton.TextSize = 14
CloseButton.TextColor3 = Color3.fromRGB(255, 75, 75)
CloseButton.Parent = MainFrame

-- Status Info Panel (Ringkas)
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -20, 0, 25)
InfoLabel.Position = UDim2.new(0, 10, 0, 35)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "👤 @" .. LocalPlayer.Name .. " (PREMIUM LITE)"
InfoLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
InfoLabel.Font = Enum.Font.SourceSansSemibold
InfoLabel.TextSize = 12
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.Parent = MainFrame

-- Progress Bar
local ProgressContainer = Instance.new("Frame")
ProgressContainer.Size = UDim2.new(0, 210, 0, 16)
ProgressContainer.Position = UDim2.new(0, 10, 0, 65)
ProgressContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ProgressContainer.Parent = MainFrame
Instance.new("UICorner", ProgressContainer).CornerRadius = UDim.new(0, 4)

local ProgressBar = Instance.new("Frame")
ProgressBar.Size = UDim2.new(0, 0, 1, 0)
ProgressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
ProgressBar.Parent = ProgressContainer
Instance.new("UICorner", ProgressBar).CornerRadius = UDim.new(0, 4)

local ProgressText = Instance.new("TextLabel")
ProgressText.Size = UDim2.new(1, 0, 1, 0)
ProgressText.BackgroundTransparency = 1
ProgressText.Text = "Ready"
ProgressText.TextColor3 = Color3.fromRGB(255, 255, 255)
ProgressText.Font = Enum.Font.SourceSansBold
ProgressText.TextSize = 10
ProgressText.Parent = ProgressContainer

-- Main Action Button
local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 210, 0, 35)
CopyButton.Position = UDim2.new(0, 10, 0, 90)
CopyButton.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
CopyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyButton.Text = "START COPY MAP"
CopyButton.Font = Enum.Font.SourceSansBold
CopyButton.TextSize = 13
CopyButton.Parent = MainFrame
Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 6)

-- List Saved Files
local ListScroll = Instance.new("ScrollingFrame")
ListScroll.Size = UDim2.new(0, 210, 0, 120)
ListScroll.Position = UDim2.new(0, 10, 0, 135)
ListScroll.BackgroundColor3 = Color3.fromRGB(14, 14, 16)
ListScroll.ScrollBarThickness = 3
ListScroll.Parent = MainFrame
Instance.new("UICorner", ListScroll).CornerRadius = UDim.new(0, 6)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ListScroll

local RefreshButton = Instance.new("TextButton")
RefreshButton.Size = UDim2.new(0, 210, 0, 25)
RefreshButton.Position = UDim2.new(0, 10, 0, 260)
RefreshButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
RefreshButton.TextColor3 = Color3.fromRGB(200, 200, 200)
RefreshButton.Text = "🔄 Refresh List"
RefreshButton.Font = Enum.Font.SourceSans
RefreshButton.TextSize = 11
RefreshButton.Parent = MainFrame
Instance.new("UICorner", RefreshButton).CornerRadius = UDim.new(0, 4)

-- [[ INTERAKSI GUI DRAG & TOGGLE ]]
local function MakeDraggable(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
MakeDraggable(MainFrame)
MakeDraggable(ToggleButton)

CloseButton.MouseButton1Click:Connect(function() MainFrame.Visible = false; ToggleButton.Visible = true end)
ToggleButton.MouseButton1Click:Connect(function() MainFrame.Visible = true; ToggleButton.Visible = false end)

-- [[ CORE LIGHTWEIGHT ENGINE ]]
local AllowedSupportClasses = {
    ["Texture"] = true, ["Decal"] = true, ["SurfaceAppearance"] = true, 
    ["SpecialMesh"] = true, ["BlockMesh"] = true, ["CylinderMesh"] = true,
    ["ParticleEmitter"] = true, ["PointLight"] = true, ["SpotLight"] = true, ["SurfaceLight"] = true,
    ["Sky"] = true, ["Atmosphere"] = true, ["Clouds"] = true, ["SunRaysEffect"] = true, ["BloomEffect"] = true,
    ["BlurEffect"] = true, ["ColorCorrectionEffect"] = true, ["Sound"] = true
}

local function getRelativePath(obj)
    local path = {}
    local current = obj.Parent
    while current and current ~= workspace and current ~= Lighting and current ~= game do
        table.insert(path, 1, {Name = current.Name, ClassName = current.ClassName})
        current = current.Parent
    end
    return path
end

local function isPlayerChar(obj)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and (obj == p.Character or obj:IsDescendantOf(p.Character)) then return true end
    end
    return false
end

CopyButton.MouseButton1Click:Connect(function()
    if not writefile then CopyButton.Text = "Executor Not Supported!"; return end
    
    CopyButton.Text = "Scanning..."
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local fileName = FILE_PREFIX .. GameName .. "_" .. math.random(1000, 9999) .. ".json"
    
    local objectsToScan = workspace:GetDescendants()
    for _, item in ipairs(Lighting:GetDescendants()) do table.insert(objectsToScan, item) end
    
    local totalObjects = #objectsToScan
    local BATCH_SIZE = 400 -- Jumlah objek diproses sebelum memberi jeda nafas (anti-lag)

    for idx, obj in ipairs(objectsToScan) do
        -- Anti Lag/Freeze System
        if idx % BATCH_SIZE == 0 then
            local pct = idx / totalObjects
            ProgressBar.Size = UDim2.new(pct, 0, 1, 0)
            ProgressText.Text = string.format("Scanning: %d%%", math.floor(pct * 100))
            task.wait() -- Memberi jeda 1 frame agar CPU tidak overload
        end

        local cName = obj.ClassName
        if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("BasePart") or AllowedSupportClasses[cName] then
            if not obj:IsDescendantOf(Players) and cName ~= "Camera" and cName ~= "Terrain" and not isPlayerChar(obj) then
                count = count + 1
                
                local data = {
                    Name = obj.Name,
                    ClassName = cName,
                    RelativePath = getRelativePath(obj),
                    Depth = #getRelativePath(obj),
                    IsLighting = obj:IsDescendantOf(Lighting),
                    Properties = {}
                }
                
                -- Gabungkan pembacaan properti esensial (Mengurangi overhead pcall berlebih)
                pcall(function()
                    local props = data.Properties
                    if obj:IsA("BasePart") then
                        props.Size = {obj.Size.X, obj.Size.Y, obj.Size.Z}
                        props.CFrame = {obj.CFrame:GetComponents()}
                        props.Color = {obj.Color.r * 255, obj.Color.g * 255, obj.Color.b * 255}
                        props.Material = obj.Material.Name
                        props.Transparency = obj.Transparency
                        props.Anchored = obj.Anchored
                        props.CanCollide = obj.CanCollide
                        
                        if obj:IsA("MeshPart") then
                            props.MeshId = obj.MeshId
                            props.TextureId = obj.TextureId
                        end
                    elseif obj:IsA("Model") then
                        props.WorldPivot = {obj:GetPivot():GetComponents()}
                    elseif AllowedSupportClasses[cName] then
                        if obj:IsA("Decal") or obj:IsA("Texture") then
                            props.Texture = obj.Texture
                            props.Face = obj.Face.Name
                        elseif obj:IsA("Light") then
                            props.Color = {obj.Color.r * 255, obj.Color.g * 255, obj.Color.b * 255}
                            props.Enabled = obj.Enabled
                            props.Brightness = obj.Brightness
                            props.Range = obj.Range
                        elseif obj:IsA("Sound") then
                            props.SoundId = obj.SoundId
                            props.Volume = obj.Volume
                            props.Playing = obj.IsPlaying
                        end
                    end
                end)
                table.insert(SaveData, data)
            end
        end
    end
    
    ProgressText.Text = "Saving to JSON..."
    writefile(fileName, HttpService:JSONEncode(SaveData))
    
    ProgressBar.Size = UDim2.new(1, 0, 1, 0)
    ProgressText.Text = "Done 100%"
    CopyButton.Text = "💾 SAVED: " .. count .. " OBJS"
    task.wait(1.5)
    CopyButton.Text = "START COPY MAP"
    _G.UpdatePasteList()
end)

_G.UpdatePasteList = function()
    for _, child in ipairs(ListScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    if not listfiles then return end
    
    local files = pcall(listfiles, "") and listfiles("") or {}
    local PASTE_BATCH = 200 -- Dicicil saat mem-paste objek

    for _, file in ipairs(files) do
        if file:match(FILE_PREFIX) and file:match("%.json$") then
            local cleanName = file:gsub(FILE_PREFIX, ""):gsub("%.json", ""):gsub(".*/", "")
            
            local ItemFrame = Instance.new("Frame")
            ItemFrame.Size = UDim2.new(1, -4, 0, 24)
            ItemFrame.BackgroundTransparency = 1
            ItemFrame.Parent = ListScroll
            
            local FileSelectBtn = Instance.new("TextButton")
            FileSelectBtn.Size = UDim2.new(1, -24, 1, 0)
            FileSelectBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            FileSelectBtn.TextColor3 = Color3.fromRGB(0, 255, 150)
            FileSelectBtn.Text = " 📄 " .. (cleanName:sub(1,18))
            FileSelectBtn.Font = Enum.Font.SourceSans
            FileSelectBtn.TextSize = 11
            FileSelectBtn.TextXAlignment = Enum.TextXAlignment.Left
            FileSelectBtn.Parent = ItemFrame
            
            local DeleteBtn = Instance.new("TextButton")
            DeleteBtn.Size = UDim2.new(0, 20, 1, 0)
            DeleteBtn.Position = UDim2.new(1, -20, 0, 0)
            DeleteBtn.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
            DeleteBtn.TextColor3 = Color3.fromRGB(255, 70, 70)
            DeleteBtn.Text = "❌"
            DeleteBtn.Parent = ItemFrame

            DeleteBtn.MouseButton1Click:Connect(function()
                if delfile then pcall(delfile, file); ItemFrame:Destroy() end
            end)
            
            FileSelectBtn.MouseButton1Click:Connect(function()
                task.spawn(function()
                    local success, loadedData = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
                    if not success or not loadedData then return end
                    
                    table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                    
                    local MasterFolder = workspace:FindFirstChild("Paste_" .. cleanName) or Instance.new("Folder")
                    MasterFolder.Name = "Paste_" .. cleanName
                    MasterFolder.Parent = workspace
                    
                    local totalObjs = #loadedData
                    for idx, data in ipairs(loadedData) do
                        if idx % PASTE_BATCH == 0 then
                            FileSelectBtn.Text = string.format("🔨 Paste: %d%%", math.floor((idx/totalObjs)*100))
                            task.wait()
                        end
                        
                        pcall(function()
                            -- Logic pembuatan hierarki folder & object generation
                            local currentParent = data.IsLighting and Lighting or MasterFolder
                            for _, pathInfo in ipairs(data.RelativePath) do
                                local found = currentParent:FindFirstChild(pathInfo.Name)
                                if not found then
                                    found = Instance.new(pathInfo.ClassName == "Model" and "Model" or "Folder")
                                    found.Name = pathInfo.Name
                                    found.Parent = currentParent
                                end
                                currentParent = found
                            end
                            
                            if currentParent:FindFirstChild(data.Name) and (data.ClassName == "Folder" or data.ClassName == "Model") then return end
                            
                            local newObj = Instance.new(data.ClassName)
                            newObj.Name = data.Name
                            local props = data.Properties
                            
                            if newObj:IsA("BasePart") and props.CFrame then
                                newObj.Size = Vector3.new(unpack(props.Size))
                                newObj.CFrame = CFrame.new(unpack(props.CFrame))
                                newObj.Color = Color3.fromRGB(unpack(props.Color))
                                newObj.Material = Enum.Material[props.Material] or Enum.Material.Plastic
                                newObj.Transparency = props.Transparency
                                newObj.Anchored = props.Anchored
                                newObj.CanCollide = props.CanCollide
                                if props.MeshId then newObj.MeshId = props.MeshId; newObj.TextureId = props.TextureId end
                            elseif newObj:IsA("Model") and props.WorldPivot then
                                newObj:PivotTo(CFrame.new(unpack(props.WorldPivot)))
                            end
                            
                            newObj.Parent = currentParent
                        end)
                    end
                    FileSelectBtn.Text = "✅ SUCCESS!"
                    task.wait(1)
                    FileSelectBtn.Text = " 📄 " .. (cleanName:sub(1,18))
                end)
            end)
        end
    end
    ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
end

RefreshButton.MouseButton1Click:Connect(_G.UpdatePasteList)
_G.UpdatePasteList()
