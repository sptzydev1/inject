local API = "https://perma-key-api-v2.herdiansyah0239.workers.dev"
local ENDPOINT = API .. "/execute-public" -- Endpoint tanpa key di server

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local function notify(message)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "PERMA DIW STUDIO",
			Text = message,
			Duration = 6,
		})
	end)
end

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "PermaLoader"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 1000000

local okParent = pcall(function()
	gui.Parent = game:GetService("CoreGui")
end)
if not okParent then
	gui.Parent = player:WaitForChild("PlayerGui")
end

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(3, 7, 16)
overlay.BackgroundTransparency = 0.7
overlay.BorderSizePixel = 0
overlay.Active = true
overlay.Parent = gui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.new(0.72, 0, 0, 108)
card.BackgroundColor3 = Color3.fromRGB(8, 15, 29)
card.BorderSizePixel = 0
card.ZIndex = 2
card.Parent = overlay

local constraint = Instance.new("UISizeConstraint", card)
constraint.MinSize = Vector2.new(238, 108)
constraint.MaxSize = Vector2.new(255, 108)
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 13)

local stroke = Instance.new("UIStroke", card)
stroke.Color = Color3.fromRGB(45, 180, 230)
stroke.Thickness = 1.35

local strokeGradient = Instance.new("UIGradient", stroke)
strokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(3, 7, 15)),
	ColorSequenceKeypoint.new(0.38, Color3.fromRGB(35, 130, 255)),
	ColorSequenceKeypoint.new(0.52, Color3.fromRGB(245, 250, 255)),
	ColorSequenceKeypoint.new(0.68, Color3.fromRGB(42, 130, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(3, 7, 15)),
})

local title = Instance.new("TextLabel", card)
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 12, 0, 9)
title.Size = UDim2.new(1, -24, 0, 30)
title.Font = Enum.Font.GothamBold
title.Text = "PERMA IMPORT RBXM TO STUDIO LITE"
title.TextColor3 = Color3.fromRGB(244, 249, 255)
title.TextScaled = true
title.TextWrapped = true
title.ZIndex = 3

local sub = Instance.new("TextLabel", card)
sub.BackgroundTransparency = 1
sub.Position = UDim2.new(0, 12, 0, 38)
sub.Size = UDim2.new(1, -24, 0, 16)
sub.Font = Enum.Font.GothamMedium
sub.Text = "PERMA DIW STUDIO"
sub.TextColor3 = Color3.fromRGB(190, 218, 245)
sub.TextSize = 11
sub.ZIndex = 3

local statusLabel = Instance.new("TextLabel", card)
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 12, 0, 54)
statusLabel.Size = UDim2.new(1, -24, 0, 20)
statusLabel.Font = Enum.Font.Gotham
statusLabel.Text = "Loading system... 5"
statusLabel.TextColor3 = Color3.fromRGB(225, 237, 250)
statusLabel.TextSize = 10
statusLabel.ZIndex = 3

local barBack = Instance.new("Frame", card)
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
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
})

local foot = Instance.new("TextLabel", card)
foot.BackgroundTransparency = 1
foot.Position = UDim2.new(0, 12, 0, 85)
foot.Size = UDim2.new(1, -24, 0, 16)
foot.Font = Enum.Font.Gotham
foot.Text = "PREPARING INTERFACE"
foot.TextColor3 = Color3.fromRGB(135, 164, 197)
foot.TextSize = 8
foot.ZIndex = 3

-- ===== Animasi gradient =====
local function animateGradient(gradient, duration)
	task.spawn(function()
		while gui.Parent and gradient.Parent do
			gradient.Offset = Vector2.new(-1, 0)
			local ok, tween = pcall(function()
				return TweenService:Create(gradient, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
					Offset = Vector2.new(1, 0),
				})
			end)
			if ok and tween then tween:Play() end
			task.wait(duration)
		end
	end)
end
animateGradient(strokeGradient, 2.5)
animateGradient(barGradient, 2.5)

-- ===== Countdown 5 detik =====
for second = 5, 1, -1 do
	if not gui.Parent then return end
	statusLabel.Text = "Loading system... " .. tostring(second)
	pcall(function()
		TweenService:Create(barFill, TweenInfo.new(1, Enum.EasingStyle.Linear), {
			Size = UDim2.new((6 - second) / 5, 0, 1, 0),
		}):Play()
	end)
	task.wait(1)
end
statusLabel.Text = "System ready"
barFill.Size = UDim2.new(1, 0, 1, 0)
task.wait(0.15)

-- ===== Set Environment & Ambil Importer Tanpa Key =====
local env = _G
pcall(function()
	if type(getgenv) == "function" then env = getgenv() end
end)
env.PERMA_KEY_AUTHORIZED = true
env.PERMA_KEY_TYPE = "FREE"

statusLabel.Text = "Downloading importer..."
local ok, result = pcall(function()
	return game:HttpGet(ENDPOINT)
end)

if not ok or type(result) ~= "string" or result == "" then
	statusLabel.Text = "Connection failed."
	notify("Koneksi gagal atau endpoint tidak merespons.")
	task.wait(2)
	gui:Destroy()
	return
end

local compiled, chunk = pcall(loadstring, result)
if not compiled or type(chunk) ~= "function" then
	statusLabel.Text = "Failed to load script."
	notify("Gagal mengompilasi skrip importer.")
	gui:Destroy()
	return
end

gui:Destroy()
task.wait(0.3)

local ran, err = pcall(chunk)
if not ran then
	notify("Script error: " .. tostring(err))
end
