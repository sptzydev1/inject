-- Clean up existing GUI
if game.CoreGui:FindFirstChild("VoiceRedirectorPro") then
    game.CoreGui.VoiceRedirectorPro:Destroy()
end

-- Services
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local VoiceChatService = game:GetService("VoiceChatService")

-- Config Storage
local CONFIG_FILE = "Delta_VoicePro_Config.txt"

local function readConfig()
    local ok, data = pcall(function() return readfile(CONFIG_FILE) end)
    return (ok and data) or nil
end

local function writeConfig(data)
    pcall(function() writefile(CONFIG_FILE, data) end)
end

-- Base GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "VoiceRedirectorPro"
gui.Parent = game.CoreGui
gui.ResetOnSpawn = false

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 290, 0, 310)
main.Position = UDim2.new(0.5, -145, 0.3, 0)
main.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
main.BorderSizePixel = 1
main.BorderColor3 = Color3.fromRGB(60, 60, 60)
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local FONT = Enum.Font.GothamBold  

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
header.BorderSizePixel = 0
header.Parent = main
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🎙️ VC Redirector"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = FONT
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.Font = FONT
closeBtn.TextSize = 12
closeBtn.Parent = main
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

-- Game Card Header
local card = Instance.new("Frame")
card.Size = UDim2.new(1, -12, 0, 36)
card.Position = UDim2.new(0, 6, 0, 38)
card.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
card.BorderSizePixel = 0
card.Parent = main
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

local cardGameName = Instance.new("TextLabel")
cardGameName.Size = UDim2.new(1, -16, 1, 0)
cardGameName.Position = UDim2.new(0, 8, 0, 0)
cardGameName.BackgroundTransparency = 1
cardGameName.Text = "Belum ada target"
cardGameName.TextColor3 = Color3.fromRGB(255, 255, 255)
cardGameName.Font = FONT
cardGameName.TextSize = 13
cardGameName.TextXAlignment = Enum.TextXAlignment.Left
cardGameName.TextTruncate = Enum.TextTruncate.AtEnd
cardGameName.Parent = card

-- Inputs Factory
local function makeInput(v7, label, placeholder, isApi)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 85, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, v7)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = FONT
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = main
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -100, 0, 28)
    box.Position = UDim2.new(0, 92, 0, v7 - 2)
    box.BackgroundColor3 = Color3.fromRGB(58, 58, 62)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
    box.BorderSizePixel = 1
    box.BorderColor3 = Color3.fromRGB(90, 90, 90)
    box.PlaceholderText = isApi and "Masukkan API Key" or (placeholder or "")
    box.Font = FONT
    box.TextSize = 12
    box.TextTruncate = Enum.TextTruncate.AtEnd
    box.Text = ""
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    box.Parent = main
    return box
end

local universeBox = makeInput(80, "Universe ID", "cth: 123456789")
local placeBox    = makeInput(118, "Place ID", "cth: 987654321")
local apiBox      = makeInput(156, "API Key", "", true)

-- Status Display
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -12, 0, 24)
statusLabel.Position = UDim2.new(0, 6, 0, 192)
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
statusLabel.BorderSizePixel = 1
statusLabel.BorderColor3 = Color3.fromRGB(80, 80, 80)
statusLabel.Text = "Isi semua field!"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
statusLabel.Font = FONT
statusLabel.TextSize = 11
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main
Instance.new("UICorner", statusLabel).CornerRadius = UDim.new(0, 6)

-- Loading Dots Animation Setup
local dotsFrame = Instance.new("Frame")
dotsFrame.Size = UDim2.new(0, 40, 0, 12)
dotsFrame.Position = UDim2.new(0.5, -20, 0, 220)
dotsFrame.BackgroundTransparency = 1
dotsFrame.Visible = false
dotsFrame.Parent = main

local dots = {}
for i = 1, 3 do
    local dot = Instance.new("TextLabel")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.BackgroundTransparency = 1
    dot.Text = "•"
    dot.TextColor3 = Color3.fromRGB(255, 200, 0)
    dot.Font = FONT
    dot.TextSize = 14
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0, (i - 1) * 14 + 6, 0, 6)
    dot.Parent = dotsFrame
    dots[i] = dot
end

-- =========================================================
-- HELPER FUNCTIONS & LOGIC (Deklarasi sebelum pemanggilan)
-- =========================================================

local isProcessing = false
local activeTweens = {}

local function setStatus(text, state)
    if not statusLabel then return end  
    statusLabel.Text = text
    local color = Color3.fromRGB(220, 220, 100)
    if state == "process" then
        color = Color3.fromRGB(255, 255, 0)
    elseif state == "success" then
        color = Color3.fromRGB(0, 255, 100)
    elseif state == "error" then
        color = Color3.fromRGB(255, 50, 50)
    end
    statusLabel.TextColor3 = color
end

local function stopAnim()
    isProcessing = false
    dotsFrame.Visible = false
    for _, tw in ipairs(activeTweens) do
        tw:Cancel()
    end
    table.clear(activeTweens)
    for _, dot in ipairs(dots) do
        dot.TextTransparency = 1
        dot.TextSize = 8
    end
end

local function startAnim()
    if isProcessing then return end
    isProcessing = true
    dotsFrame.Visible = true
    
    for _, dot in ipairs(dots) do
        dot.TextTransparency = 1
        dot.TextSize = 8
    end
    
    task.spawn(function()
        while isProcessing do
            for _, dot in ipairs(dots) do
                if not isProcessing then break end
                
                local twIn = TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.2, TextSize = 16})
                table.insert(activeTweens, twIn)
                twIn:Play()
                
                task.wait(0.15)
                if not isProcessing then break end
                
                local twOut = TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextSize = 8})
                table.insert(activeTweens, twOut)
                twOut:Play()
                
                task.wait(0.15)
            end
            task.wait(0.1)
        end
        stopAnim()
    end)
end

local function updateGameInfo(universeId, apiKey)
    if not cardGameName then return end  
    local univ = tonumber(universeId)
    if not univ then
        cardGameName.Text = "Universe ID tidak valid"
        return
    end
    if #apiKey == 0 then
        cardGameName.Text = "Isi API Key untuk nama"
        return
    end

    task.spawn(function()
        local ok, result = pcall(function()
            local url = "https://apis.roblox.com/cloud/v5/universes/" .. universeId
            local headers = {
                ["x-api-key"] = apiKey,
                ["v6-api-key"] = apiKey
            }
            local response
            if HttpService.RequestAsync then
                response = HttpService:RequestAsync({
                    Url = url,
                    Method = "GET",
                    Headers = headers
                })
                if response.Success then
                    local data = HttpService:JSONDecode(response.Body)
                    return data.displayName or data.name or ("Universe " .. universeId)
                end
            else
                local res = HttpService:GetAsync(url, false, headers)
                local data = HttpService:JSONDecode(res)
                return data.displayName or data.name or ("Universe " .. universeId)
            end
            return nil
        end)

        if ok and result then
            cardGameName.Text = result
        else
            cardGameName.Text = "Gagal memuat nama"
        end
    end)
end

local function apiSet(univ, key, enable)
    local url = "https://apis.roblox.com/cloud/v5/universes/" .. univ
    local body = HttpService:JSONEncode({ voice_chat_enabled = enable })
    local headers = {
        ["x-api-key"] = key,
        ["v6-api-key"] = key,
        ["Content-Type"] = "application/json"
    }
    local ok, res = pcall(function()
        if HttpService.RequestAsync then
            return HttpService:RequestAsync({
                Url = url,
                Method = "PATCH",
                Headers = headers,
                Body = body
            })
        else
            return HttpService:PostAsync(url, body, "ApplicationJson", false, headers)
        end
    end)
    return ok, res
end

local function getVoiceInternal()
    local vc
    pcall(function() vc = game:GetService("VoiceChatInternal") end)
    if not vc then
        pcall(function() vc = getsenv(VoiceChatService).VoiceChatInternal end)
    end
    return vc
end

local function forceJoin(placeId)
    local vc = getVoiceInternal()
    if not vc then return false, "VoiceChatInternal tidak ada" end
    
    local methods = {
        function()
            if vc.RequestJoinByPlaceId then vc:RequestJoinByPlaceId(placeId)
            elseif vc.RequestJoin then vc:RequestJoin(placeId) end
            task.wait(0.8)
            return vc:IsContextVoiceEnabled()
        end,
        function()
            local gid = vc:GetGroupId()
            if gid and gid ~= "" then
                vc:JoinByGroupId(gid, false)
                task.wait(0.8)
                return vc:IsContextVoiceEnabled()
            end
            return false
        end,
        function()
            pcall(function() replicatesignal(VoiceChatService.ClientRetryJoin) end)
            task.wait(1.5)
            return vc:IsContextVoiceEnabled()
        end,
        function()
            if vc.Connect then
                vc:Connect()
                task.wait(0.8)
                return vc:IsContextVoiceEnabled()
            end
            return false
        end
    }

    for idx, method in ipairs(methods) do
        local ok, result = pcall(method)
        if ok and result then
            return true, "Metode " .. idx
        end
    end
    return false, "Semua metode gagal"
end

local function disconnectVoice()
    local vc = getVoiceInternal()
    if vc and vc.Disconnect then vc:Disconnect() end
    pcall(function() VoiceChatService:RejoinVoice() end)
end

-- =========================================================
-- BUTTON CONTROLLERS & LISTENERS
-- =========================================================

closeBtn.MouseButton1Click:Connect(function()
    stopAnim()  
    gui:Destroy()
end)

local function makeSmallButton(v6, v7, text, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 26)
    btn.Position = UDim2.new(0, v6, 0, v7)
    btn.BackgroundColor3 = Color3.fromRGB(0, 130, 200)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = FONT
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Parent = main
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- Load & Save Buttons
makeSmallButton(6, 238, "Load", function()
    local raw = readConfig()
    if raw then
        local ok, tbl = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and tbl then
            universeBox.Text = tbl.UniverseID or ""
            placeBox.Text    = tbl.PlaceID or ""
            apiBox.Text      = tbl.APIKey or ""
            updateGameInfo(tbl.UniverseID, tbl.APIKey)  
            setStatus("Config dimuat.", "info")
        else
            setStatus("Format rusak.", "error")
        end
    else
        setStatus("File tidak ada.", "info")
    end
end)

makeSmallButton(82, 238, "Save", function()
    local data = {
        UniverseID = universeBox.Text,
        PlaceID    = placeBox.Text,
        APIKey     = apiBox.Text
    }
    writeConfig(HttpService:JSONEncode(data))
    setStatus("Config tersimpan.", "success")
end)

-- Main Enable / Disable Buttons
local enableBtn = Instance.new("TextButton")
enableBtn.Size = UDim2.new(0, 125, 0, 34)
enableBtn.Position = UDim2.new(0, 6, 0, 270)
enableBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 70)
enableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
enableBtn.BorderSizePixel = 0
enableBtn.Text = "ENABLE"
enableBtn.Font = FONT
enableBtn.TextSize = 13
Instance.new("UICorner", enableBtn).CornerRadius = UDim.new(0, 8)
enableBtn.Parent = main

local disableBtn = Instance.new("TextButton")
disableBtn.Size = UDim2.new(0, 125, 0, 34)
disableBtn.Position = UDim2.new(0, 140, 0, 270)
disableBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
disableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
disableBtn.BorderSizePixel = 0
disableBtn.Text = "DISABLE"
disableBtn.Font = FONT
disableBtn.TextSize = 13
Instance.new("UICorner", disableBtn).CornerRadius = UDim.new(0, 8)
disableBtn.Parent = main

-- Enable Action
enableBtn.MouseButton1Click:Connect(function()
    if isProcessing then
        setStatus("Proses berjalan, tunggu...", "process")
        return
    end
    local univ = universeBox.Text
    local place = tonumber(placeBox.Text)
    local key = apiBox.Text
    
    if #univ == 0 or not place or #key == 0 then
        setStatus("Isi semua field!", "error")
        return
    end

    startAnim()
    task.spawn(function()
        setStatus("Menghubungi API...", "process")
        task.wait(0.2)
        local apiOk = apiSet(univ, key, true)
        if apiOk then
            setStatus("Voice Chat diaktifkan!", "success")
        else
            setStatus("API gagal, lanjut join...", "process")
        end
        task.wait(0.4)
        setStatus("Menyambung ke suara...", "process")
        local joinOk, info = forceJoin(place)
        if joinOk then
            setStatus("Berhasil! (" .. info .. ")", "success")
        else
            setStatus("Gagal: " .. info, "error")
        end
        stopAnim()
    end)
end)

-- Disable Action
disableBtn.MouseButton1Click:Connect(function()
    if isProcessing then
        setStatus("Proses berjalan, tunggu...", "process")
        return
    end
    local univ = universeBox.Text
    local key = apiBox.Text
    
    if #univ == 0 or #key == 0 then
        setStatus("Isi Universe ID & API Key!", "error")
        return
    end

    startAnim()
    task.spawn(function()
        setStatus("Menghubungi API...", "process")
        task.wait(0.2)
        local apiOk = apiSet(univ, key, false)
        if apiOk then
            setStatus("Voice Chat dinonaktifkan!", "success")
            disconnectVoice()
        else
            setStatus("API gagal, putus paksa...", "process")
            disconnectVoice()
            setStatus("Koneksi diputus.", "success")
        end
        stopAnim()
    end)
end)

-- Event Handlers for Input Changes
local function onFieldChanged()
    updateGameInfo(universeBox.Text, apiBox.Text)
end

universeBox.FocusLost:Connect(onFieldChanged)
placeBox.FocusLost:Connect(onFieldChanged)
apiBox.FocusLost:Connect(onFieldChanged)   

-- Initial Load Check & Name Fetch
updateGameInfo(universeBox.Text, apiBox.Text)
