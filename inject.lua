-- [[ CONFIGURASI & VARIABLE UTAMA ]]
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
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
local TargetFolder = workspace

-- ==================================================
--  FITUR CORE: PART PROCESSOR (OPTIMALISASI OBJEK)
-- ==================================================
local function processSinglePart(inst)
    pcall(function()
        if inst:IsA("BasePart") then
            inst.Anchored = true -- Otomatis Kunci Koordinat (Bebas Gravitasi)
            if inst:IsA("UnionOperation") or inst:IsA("MeshPart") then
                inst.RenderFidelity = Enum.RenderFidelity.Precise -- Kualitas Visual Tertinggi
            end
        end
    end)
end

local function processParts(root)
    for _, inst in ipairs(root:GetDescendants()) do
        processSinglePart(inst)
    end
end

-- ==================================================
--  FITUR CORE: SCRIPT UNLOCK & BYPASS (DECOMPILER)
-- ==================================================
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
    if not scr or not scr.Parent then return nil end
    local src    = tryGetSource(scr)
    local cls    = scr.ClassName
    local name   = scr.Name
    local parent = scr.Parent
    local new
    pcall(function()
        new = Instance.new(cls)
        new.Name = name
        if sethiddenproperty then
            pcall(sethiddenproperty, new, "LinkedSource", "")
            pcall(sethiddenproperty, new, "ScriptGuid",   "")
        end
        if src then
            pcall(function() new.Source = src end)
            if sethiddenproperty then pcall(sethiddenproperty, new, "Source", src) end
        end
        new.Disabled = false
        new.Parent = PlayerGui
    end)
    if not new then return nil end
    task.wait(0.01)
    pcall(function() new.Parent = parent end)
    pcall(function() scr:Destroy() end)
    if cls == "LocalScript" and src then
        task.spawn(loadstring(src))
    end
    return src
end

local function unlockAllInTree(root)
    if not root then return end
    local list = {}
    if root:IsA("LuaSourceContainer") then table.insert(list, root) end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("LuaSourceContainer") then table.insert(list, d) end
    end
    for _, s in ipairs(list) do
        pcall(unlockScript, s); task.wait(0.01)
    end
end

-- ==================================================
--  FITUR CORE: CASCADE LOADING METHOD (3 METODE BERLAPIS)
-- ==================================================
local function insertObjectsCascade(filePath, folderName)
    local errs = {}
    local MasterFolder = Instance.new("Folder")
    MasterFolder.Name = "Imported_Map_" .. folderName
    
    -- Metode 1: getcustomasset + game:GetObjects()
    if getcustomasset then
        local ok1, aid = pcall(getcustomasset, filePath)
        if ok1 and aid then
            local ok2, objs = pcall(function() return game:GetObjects(aid) end)
            if ok2 and objs and #objs > 0 then
                for _, o in ipairs(objs) do o.Parent = MasterFolder end
                MasterFolder.Parent = workspace
                return true, MasterFolder
            else table.insert(errs, "M1_Fail") end
        else table.insert(errs, "M1_Asset_Fail") end
    end

    -- Metode 2: InsertService:LoadLocalAsset()
    if InsertService and InsertService.LoadLocalAsset then
        local ok, res = pcall(function() return InsertService:LoadLocalAsset(filePath) end)
        if ok and res then
            local ch = res:GetChildren()
            if #ch == 0 then ch = {res} end
            for _, o in ipairs(ch) do o.Parent = MasterFolder end
            MasterFolder.Parent = workspace
            return true, MasterFolder
        else table.insert(errs, "M2_Fail") end
    end

    -- Metode 3: Jalur internal rbxasset://
    local ok3, o3 = pcall(function() return game:GetObjects("rbxasset://" .. filePath) end)
    if ok3 and o3 and #o3 > 0 then
        for _, o in ipairs(o3) do o.Parent = MasterFolder end
        MasterFolder.Parent = workspace
        return true, MasterFolder
    else table.insert(errs, "M3_Fail") end

    return false, nil
end

-- ==================================================
--  GUI BUILD (PERSEGI PANJANG HORIZONTAL COMPACT)
-- ==================================================
if PlayerGui:FindFirstChild("SpyzyyCopyHorizontal") then
    PlayerGui:FindFirstChild("SpyzyyCopyHorizontal"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpyzyyCopyHorizontal"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- Tombol Buka (👑 Mini Floating)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenBtn"
OpenBtn.Size = UDim2.new(0, 35, 0, 35)
OpenBtn.Position = UDim2.new(0, 10, 0, 10)
OpenBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 30)
OpenBtn.Text = "👑"
OpenBtn.TextSize = 18
OpenBtn.Visible = false
OpenBtn.ZIndex = 10
OpenBtn.Parent = ScreenGui
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(1, 0)
local OpenStroke = Instance.new("UIStroke", OpenBtn)
OpenStroke.Color = Color3.fromRGB(0, 200, 255)
OpenStroke.Thickness = 1.5

-- Frame Menu Utama Horizontal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 40)
MainFrame.Position = UDim2.new(0.5, -240, 0.05, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(0, 200, 255)
MainStroke.Thickness = 1.5

local HorizontalLayout = Instance.new("UIListLayout")
HorizontalLayout.FillDirection = Enum.FillDirection.Horizontal
HorizontalLayout.SortOrder = Enum.SortOrder.LayoutOrder
HorizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center
HorizontalLayout.Padding = UDim.new(0, 6)
HorizontalLayout.Parent = MainFrame

local LeftPadding = Instance.new("UIPadding", MainFrame)
LeftPadding.PaddingLeft = UDim.new(0, 8)
LeftPadding.PaddingRight = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 90, 0, 30)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Spyzyy v2 👑"
TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 14
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.LayoutOrder = 1
TitleText.Parent = MainFrame

local function createSeparator(order)
    local sep = Instance.new("Frame")
    sep.Size = UDim2.new(0, 1, 0, 20)
    sep.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
    sep.BorderSizePixel = 0
    sep.LayoutOrder = order
    sep.Parent = MainFrame
end
createSeparator(2)

local CopyBtn = Instance.new("TextButton")
CopyBtn.Size = UDim2.new(0, 85, 0, 26)
CopyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyBtn.Text = "📸 COPY MAP"
CopyBtn.Font = Enum.Font.SourceSansBold
CopyBtn.TextSize = 11
CopyBtn.LayoutOrder = 3
CopyBtn.Parent = MainFrame
Instance.new("UICorner", CopyBtn).CornerRadius = UDim.new(0, 4)

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0, 75, 0, 26)
ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ClearBtn.Text = "🗑 CLEAR WS"
ClearBtn.Font = Enum.Font.SourceSansBold
ClearBtn.TextSize = 11
ClearBtn.LayoutOrder = 4
ClearBtn.Parent = MainFrame
Instance.new("UICorner", ClearBtn).CornerRadius = UDim.new(0, 4)

local PasteBtn = Instance.new("TextButton")
PasteBtn.Size = UDim2.new(0, 80, 0, 26)
PasteBtn.BackgroundColor3 = Color3.fromRGB(30, 140, 90)
PasteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PasteBtn.Text = "📥 PASTE MAP"
PasteBtn.Font = Enum.Font.SourceSansBold
PasteBtn.TextSize = 11
PasteBtn.LayoutOrder = 5
PasteBtn.Parent = MainFrame
Instance.new("UICorner", PasteBtn).CornerRadius = UDim.new(0, 4)

createSeparator(6)

local AboutBtn = Instance.new("TextButton")
AboutBtn.Size = UDim2.new(0, 55, 0, 26)
AboutBtn.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
AboutBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
AboutBtn.Text = "ℹ️ About"
AboutBtn.Font = Enum.Font.SourceSansBold
AboutBtn.TextSize = 11
AboutBtn.LayoutOrder = 7
AboutBtn.Parent = MainFrame
Instance.new("UICorner", AboutBtn).CornerRadius = UDim.new(0, 4)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 24, 0, 24)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "⛔️"
MinimizeBtn.TextSize = 14
MinimizeBtn.LayoutOrder = 8
MinimizeBtn.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "❌"
CloseBtn.TextSize = 14
CloseBtn.LayoutOrder = 9
CloseBtn.Parent = MainFrame

-- ==================================================
--  INTERACTION & DRAGGABLE LOGIC
-- ==================================================
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)

OpenBtn.MouseButton1Click:Connect(function()
    OpenBtn.Visible = false
    MainFrame.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

AboutBtn.MouseButton1Click:Connect(function()
    AboutBtn.Text = "By SPTZYY"
    task.wait(2)
    AboutBtn.Text = "ℹ️ About"
end)

-- ==================================================
--  SYSTEM CORE: COPY MECHANISM WITH FULL INTEGRATION
-- ==================================================
local function getRelativePath(obj)
    local path = {}
    local current = obj.Parent
    while current and current ~= workspace and current ~= game do
        table.insert(path, 1, {Name = current.Name, ClassName = current.ClassName})
        current = current.Parent
    end
    return path
end

ClearBtn.MouseButton1Click:Connect(function()
    for _, ch in ipairs(workspace:GetChildren()) do
        if not ch:IsA("Terrain") and ch ~= workspace.CurrentCamera then
            pcall(function() ch:Destroy() end)
        end
    end
    ClearBtn.Text = "🗑 Cleared!"
    task.wait(1.5)
    ClearBtn.Text = "🗑 CLEAR WS"
end)

CopyBtn.MouseButton1Click:Connect(function()
    if not writefile then 
        CopyBtn.Text = "No Support!"
        return 
    end
    CopyBtn.Text = "⏳ Core Run..."
    task.wait(0.1)

    local SaveData = {}
    local count = 0
    local uniqueID = math.random(1000, 9999) .. "_" .. os.date("%H%M%S")
    local fileName = FILE_PREFIX .. GameName .. "_" .. uniqueID .. ".json"
    
    local AllowedClasses = {
        ["Folder"] = true, ["Model"] = true, ["BasePart"] = true, ["MeshPart"] = true, ["UnionOperation"] = true,
        ["LocalScript"] = true, ["Script"] = true, ["ModuleScript"] = true, ["Texture"] = true, ["Decal"] = true
    }

    for _, obj in pairs(TargetFolder:GetDescendants()) do
        if AllowedClasses[obj.ClassName] or obj:IsA("BasePart") then
            if not obj:IsDescendantOf(Players) and not obj:IsA("Camera") and not obj:IsA("Terrain") then
                count = count + 1
                
                -- PROSES 1 (Saat Copy): Bypass & Unlock Script Langsung Dari Map Game Asli
                local decompiledSource = nil
                if obj:IsA("LuaSourceContainer") then
                    decompiledSource = tryGetSource(obj)
                end
                
                -- PROSES 2 (Saat Copy): Part Processor Diterapkan ke Map Terpindah
                if obj:IsA("BasePart") then
                    processSinglePart(obj)
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
                        data.Properties.Anchored = obj.Anchored
                        data.Properties.CanCollide = obj.CanCollide
                    elseif obj:IsA("LuaSourceContainer") and decompiledSource then
                        data.Properties.Source = decompiledSource -- Sumber script tersimpan aman di berkas eksternal
                    end
                end)
                table.insert(SaveData, data)
            end
        end
    end
    
    writefile(fileName, HttpService:JSONEncode(SaveData))
    CopyBtn.Text = "✅ Saved " .. count
    task.wait(2)
    CopyBtn.Text = "📸 COPY MAP"
end)

-- ==================================================
--  SYSTEM CORE: CASCADE PASTE AUTOMATION
-- ==================================================
PasteBtn.MouseButton1Click:Connect(function()
    if not listfiles or not readfile then
        PasteBtn.Text = "No Support!"
        return
    end
    
    PasteBtn.Text = "🔨 Cascade Load..."
    task.spawn(function()
        local files = pcall(listfiles, "") and listfiles("") or {}
        local targetFile = nil
        
        for _, f in pairs(files) do
            if f:match(FILE_PREFIX) and f:match("%.json$") then
                targetFile = f
            end
        end
        
        if not targetFile then
            PasteBtn.Text = "❌ No JSON!"
            task.wait(1.5)
            PasteBtn.Text = "📥 PASTE MAP"
            return
        end
        
        -- Eksekusi Metode Berlapis (Cascade Method)
        local loadedSuccess, TargetRoot = insertObjectsCascade(targetFile, GameName)
        
        if loadedSuccess and TargetRoot then
            PasteBtn.Text = "⚡ Optimizing..."
            task.wait(0.1)
            
            -- Menjalankan Part Processor & Script Unlocker kembali saat Asset dimuat ke Workspace
            processParts(TargetRoot)
            unlockAllInTree(TargetRoot)
            
            PasteBtn.Text = "✅ Complete!"
        else
            -- Jalur Cadangan Konvensional (Fallback Pemuatan Instan)
            local manualSuccess = pcall(function()
                local fileContent = readfile(targetFile)
                local loadedData = HttpService:JSONDecode(fileContent)
                table.sort(loadedData, function(a, b) return (a.Depth or 0) < (b.Depth or 0) end)
                
                local FallbackFolder = Instance.new("Folder")
                FallbackFolder.Name = "Imported_Map_Fallback_" .. GameName
                FallbackFolder.Parent = workspace
                
                for _, data in ipairs(loadedData) do
                    pcall(function()
                        local newObj = Instance.new(data.ClassName or "Part")
                        newObj.Name = data.Name
                        local props = data.Properties or {}
                        
                        if newObj:IsA("BasePart") and props.CFrame then
                            newObj.Size = Vector3.new(unpack(props.Size))
                            newObj.CFrame = CFrame.new(unpack(props.CFrame))
                            newObj.Color = Color3.fromRGB(unpack(props.Color))
                            pcall(function() newObj.Material = Enum.Material[props.Material] end)
                            newObj.Transparency = props.Transparency
                        elseif newObj:IsA("LuaSourceContainer") and props.Source then
                            newObj.Source = props.Source
                        end
                        newObj.Parent = FallbackFolder
                    end)
                end
                processParts(FallbackFolder)
                unlockAllInTree(FallbackFolder)
            end)
            
            if manualSuccess then
                PasteBtn.Text = "✅ Done (FB)!"
            else
                PasteBtn.Text = "❌ Error!"
            end
        end
        
        task.wait(2)
        PasteBtn.Text = "📥 PASTE MAP"
    end)
end)
