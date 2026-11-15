local API = "https://perma-key-api-v2.herdiansyah0239.workers.dev"
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService

pcall(function()
    TweenService = game:GetService("TweenService")
end)

local function safeTweenCreate(object, tweenInfo, properties)
    local service = TweenService
    local createMethod
    if service ~= nil then
        local okMethod, method = pcall(function() return service["Create"] end)
        if okMethod then createMethod = method end
    end
    if object ~= nil and type(properties) == "table" and type(createMethod) == "function" then
        local okTween, tween = pcall(createMethod, service, object, tweenInfo, properties)
        if okTween and tween ~= nil then
            local okPlay, playMethod = pcall(function() return tween.Play end)
            if okPlay and type(playMethod) == "function" then return tween end
        end
    end
    local listeners = {}
    local completed = {}
    function completed:Connect(callback)
        if type(callback) ~= "function" then return {Disconnect = function() end} end
        local connection = {Connected = true}
        function connection:Disconnect() self.Connected = false end
        table.insert(listeners, {callback = callback, connection = connection})
        return connection
    end
    function completed:Wait() return nil end
    local tween = {Completed = completed}
    function tween:Play()
        if object ~= nil and type(properties) == "table" then
            pcall(function()
                for key, value in pairs(properties) do object[key] = value end
            end)
        end
        for _, item in ipairs(listeners) do
            if item.connection.Connected then pcall(item.callback) end
        end
    end
    function tween:Cancel() end
    function tween:Pause() end
    return tween
end

local function notify(message)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PERMA DIW STUDIO",
            Text = message,
            Duration = 6
        })
    end)
end

local logoTargets = {}
local logoAsset = nil
local logoFile = "PERMA_DIW_STUDIO_LOGO.png"

local function registerLogo(image)
    table.insert(logoTargets, image)
    if logoAsset then image.Image = logoAsset end
end

task.spawn(function()
    local env = _G
    pcall(function()
        if type(getgenv) == "function" then env = getgenv() end
    end)
    local getAsset = env.getcustomasset or env.getsynasset
    local read = env.readfile
    local isFile = env.isfile
    local write = env.writefile
    if type(getAsset) ~= "function" then return end
    
    local cached = false
    if type(isFile) == "function" and type(read) == "function" then
        pcall(function()
            if isFile(logoFile) then
                local asset = getAsset(logoFile)
                if type(asset) == "string" then logoAsset = asset; cached = true end
            end
        end)
    end
    
    if not cached and type(write) == "function" then
        local okImage, data = pcall(function()
            return game:HttpGet(API .. "/logo")
        end)
        if okImage and type(data) == "string" and #data > 1000 then
            pcall(write, logoFile, data)
            local okAsset, asset = pcall(getAsset, logoFile)
            if okAsset and type(asset) == "string" then logoAsset = asset end
        end
    end
    
    if logoAsset then
        for _, image in ipairs(logoTargets) do
            pcall(function() image.Image = logoAsset end)
        end
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "PermaKeyLoader"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 1000000
gui.Enabled = true

local ok = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)
if not ok then
    gui.Parent = player:WaitForChild("PlayerGui")
end

-- Full-screen splash dengan animasi hitung mundur
local loadingOverlay = Instance.new("Frame")
loadingOverlay.Name = "LoadingOverlay"
loadingOverlay.Position = UDim2.fromScale(0, 0)
loadingOverlay.Size = UDim2.fromScale(1, 1)
loadingOverlay.BackgroundColor3 = Color3.fromRGB(3, 7, 16)
loadingOverlay.BackgroundTransparency = 0.7
loadingOverlay.BorderSizePixel = 0
loadingOverlay.Active = true
loadingOverlay.Visible = true
loadingOverlay.ZIndex = 1
loadingOverlay.Parent = gui

local splashCard = Instance.new("Frame")
splashCard.Name = "LoadingCard"
splashCard.AnchorPoint = Vector2.new(0.5, 0.5)
splashCard.Position = UDim2.fromScale(0.5, 0.5)
splashCard.Size = UDim2.new(0.72, 0, 0, 108)
splashCard.BackgroundColor3 = Color3.fromRGB(8, 15, 29)
splashCard.BorderSizePixel = 0
splashCard.ZIndex = 2
splashCard.Parent = loadingOverlay

local splashConstraint = Instance.new("UISizeConstraint", splashCard)
splashConstraint.MinSize = Vector2.new(238, 108)
splashConstraint.MaxSize = Vector2.new(255, 108)
Instance.new("UICorner", splashCard).CornerRadius = UDim.new(0, 13)

local splashStroke = Instance.new("UIStroke", splashCard)
splashStroke.Color = Color3.fromRGB(45, 180, 230)
splashStroke.Thickness = 1.35

local splashGradient = Instance.new("UIGradient", splashCard)
splashGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 70, 125)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 70, 125))
})
splashGradient.Rotation = 25

local splashLogo = Instance.new("ImageLabel", splashCard)
splashLogo.Name = "PDSLogo"
splashLogo.Size = UDim2.fromOffset(28, 28)
splashLogo.Position = UDim2.fromOffset(12, 10)
splashLogo.BackgroundTransparency = 1
splashLogo.ScaleType = Enum.ScaleType.Fit
splashLogo.ZIndex = 4
registerLogo(splashLogo)

local splashTitle = Instance.new("TextLabel", splashCard)
splashTitle.Name = "Title"
splashTitle.BackgroundTransparency = 1
splashTitle.Position = UDim2.new(0, 46, 0, 9)
splashTitle.Size = UDim2.new(1, -56, 0, 30)
splashTitle.Font = Enum.Font.GothamBold
splashTitle.Text = "PERMA IMPORT RBXM TO STUDIO LITE"
splashTitle.TextColor3 = Color3.fromRGB(244, 249, 255)
splashTitle.TextScaled = true
splashTitle.TextWrapped = true
splashTitle.ZIndex = 3

local titleGradient = Instance.new("UIGradient", splashTitle)
titleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(92, 190, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})

local splashStrokeGradient = Instance.new("UIGradient", splashStroke)
splashStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(3, 7, 15)),
    ColorSequenceKeypoint.new(0.18, Color3.fromRGB(12, 45, 105)),
    ColorSequenceKeypoint.new(0.38, Color3.fromRGB(35, 130, 255)),
    ColorSequenceKeypoint.new(0.52, Color3.fromRGB(245, 250, 255)),
    ColorSequenceKeypoint.new(0.68, Color3.fromRGB(42, 130, 255)),
    ColorSequenceKeypoint.new(0.84, Color3.fromRGB(7, 18, 39)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(3, 7, 15))
})

local function animateLoaderGradient(gradient, duration)
    task.spawn(function()
        while gui.Parent and gradient.Parent do
            gradient.Offset = Vector2.new(-1, 0)
            local tween = safeTweenCreate(gradient, TweenInfo.new(duration or 2.5, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
            tween:Play()
            task.wait(duration or 2.5)
        end
    end)
end

animateLoaderGradient(splashGradient, 2.5)
animateLoaderGradient(splashStrokeGradient, 2.5)
animateLoaderGradient(titleGradient, 2.5)

local splashSub = Instance.new("TextLabel", splashCard)
splashSub.BackgroundTransparency = 1
splashSub.Position = UDim2.new(0, 46, 0, 38)
splashSub.Size = UDim2.new(1, -56, 0, 16)
splashSub.Font = Enum.Font.GothamMedium
splashSub.Text = "PERMA DIW STUDIO"
splashSub.TextColor3 = Color3.fromRGB(190, 218, 245)
splashSub.TextSize = 11
splashSub.ZIndex = 3

local loadingStatus = Instance.new("TextLabel", splashCard)
loadingStatus.BackgroundTransparency = 1
loadingStatus.Position = UDim2.new(0, 12, 0, 54)
loadingStatus.Size = UDim2.new(1, -24, 0, 20)
loadingStatus.Font = Enum.Font.Gotham
loadingStatus.Text = "Bypassing key verification... 3"
loadingStatus.TextColor3 = Color3.fromRGB(225, 237, 250)
loadingStatus.TextSize = 10
loadingStatus.ZIndex = 3

local barBack = Instance.new("Frame", splashCard)
barBack.Position = UDim2.new(0, 14, 0, 75)
barBack.Size = UDim2.new(1, -28, 0, 5)
barBack.BackgroundColor3 = Color3.fromRGB(21, 34, 52)
barBack.BorderSizePixel = 0
barBack.ClipsDescendants = true
barBack.ZIndex = 3
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)

local barFill = Instance.new("Frame", barBack)
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(58, 167, 255)
barFill.BorderSizePixel = 0
barFill.ZIndex = 4
Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

local barGradient = Instance.new("UIGradient", barFill)
barGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 135, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})

task.spawn(function()
    while gui.Parent and splashCard.Parent do
        barGradient.Offset = Vector2.new(-1, 0)
        local tween = safeTweenCreate(barGradient, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
        tween:Play()
        task.wait(2.5)
    end
end)

local loadingFoot = Instance.new("TextLabel", splashCard)
loadingFoot.BackgroundTransparency = 1
loadingFoot.Position = UDim2.new(0, 12, 0, 85)
loadingFoot.Size = UDim2.new(1, -24, 0, 16)
loadingFoot.Font = Enum.Font.Gotham
loadingFoot.Text = "LOADING SYSTEM BYPASS"
loadingFoot.TextColor3 = Color3.fromRGB(135, 164, 197)
loadingFoot.TextSize = 8
loadingFoot.ZIndex = 3

-- Animasi rotasi gradient UI secara keseluruhan
task.spawn(function()
    local spinning = {}
    while gui.Parent do
        for _, item in ipairs(gui:GetDescendants()) do
            if item:IsA("UIGradient") and not spinning[item] then
                spinning[item] = true
                task.spawn(function()
                    if not item.Parent then spinning[item] = nil; return end
                    item.Rotation = 0
                    local tween = safeTweenCreate(item, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Rotation = 360})
                    tween:Play()
                    tween.Completed:Wait()
                    if item.Parent then item.Rotation = 0 end
                    spinning[item] = nil
                end)
            end
        end
        task.wait(0.8)
    end
end)

-- Hitung mundur splash screen loader
for second = 3, 1, -1 do
    if not gui.Parent then return end
    loadingStatus.Text = "Bypassing key verification... " .. tostring(second)
    safeTweenCreate(barFill, TweenInfo.new(1, Enum.EasingStyle.Linear), {
        Size = UDim2.new((4 - second) / 3, 0, 1, 0)
    }):Play()
    task.wait(1)
end

loadingStatus.Text = "Connecting to server..."
barFill.Size = UDim2.new(1, 0, 1, 0)

-- Mengambil skrip utama secara langsung dari server API
task.spawn(function()
    local success, result = pcall(function()
        return game:HttpGet(API .. "/execute?key=BYPASS_KEY_FULL_FEATURE")
    end)
    
    task.wait(0.5)
    loadingOverlay:Destroy()

    if not success or not result or result == "" then
        notify("Gagal mengambil skrip dari server API.")
        return
    end

    local compile, chunk = pcall(loadstring, result)
    if not compile or type(chunk) ~= "function" then
        notify("Gagal mengompilasi skrip utama.")
        return
    end

    local ran, failure = pcall(chunk)
    if not ran then
        notify("Terjadi kesalahan saat menjalankan skrip: " .. tostring(failure))
    end
end)
