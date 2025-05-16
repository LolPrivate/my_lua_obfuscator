local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyItemCash  = RemoteEvents:WaitForChild("BuyItemCash")

local screenGui = Instance.new("ScreenGui")
screenGui.Name         = "UnifiedGui"
screenGui.ResetOnSpawn = false
screenGui.Parent       = PlayerGui

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size            = UDim2.new(0, 300, 0, 300)
mainFrame.Position        = UDim2.new(0.5, -150, 0.5, -150)
mainFrame.BackgroundColor3= Color3.fromRGB(35, 35, 35)
mainFrame.Active          = true
mainFrame.Draggable       = true

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.Size               = UDim2.new(1, 0, 0.1, 0)
titleLabel.Position           = UDim2.new(0, 0, 0, 0)
titleLabel.Text               = "Unified GUI"
titleLabel.TextScaled         = true
titleLabel.BackgroundTransparency = 1
titleLabel.Font               = Enum.Font.GothamBold

task.spawn(function()
    local hue = 0
    while true do
        hue = hue + 0.01
        if hue >= 1 then hue = 0 end
        titleLabel.TextColor3 = Color3.fromHSV(hue, 1, 1)
        task.wait(0.05)
    end
end)

local function dupe()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            local clone = tool:Clone()
            clone.Parent = LocalPlayer.Backpack
        else
            warn("Hold an item before clicking dupe.")
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    dupe()
end)

local dupeButton = Instance.new("TextButton", mainFrame)
dupeButton.Size               = UDim2.new(0.8,  0, 0.15, 0)
dupeButton.Position           = UDim2.new(0.1,  0, 0.12, 0)
dupeButton.Text               = "Dupe"
dupeButton.TextScaled         = true
dupeButton.Font               = Enum.Font.Gotham
dupeButton.BackgroundColor3   = Color3.fromRGB(60, 60, 60)
Instance.new("UICorner", dupeButton)
dupeButton.MouseButton1Click:Connect(dupe)

local infButton = Instance.new("TextButton", mainFrame)
infButton.Size               = UDim2.new(0.8,  0, 0.15, 0)
infButton.Position           = UDim2.new(0.1,  0, 0.30, 0)
infButton.Text               = "Infinite Yield"
infButton.TextScaled         = true
infButton.Font               = Enum.Font.Gotham
infButton.BackgroundColor3   = Color3.fromRGB(60, 60, 60)
Instance.new("UICorner", infButton)
infButton.MouseButton1Click:Connect(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/kauepsantos/fe-1/refs/heads/main/README.md"))()
end)

local textBox = Instance.new("TextBox", mainFrame)
textBox.PlaceholderText       = "Enter item name"
textBox.Size                  = UDim2.new(0.8,  0, 0.1,  0)
textBox.Position              = UDim2.new(0.1,  0, 0.48, 0)
textBox.BackgroundColor3      = Color3.fromRGB(60, 60, 60)
textBox.TextColor3            = Color3.new(1, 1, 1)
textBox.TextScaled            = true
Instance.new("UICorner", textBox)

local buyButton = Instance.new("TextButton", mainFrame)
buyButton.Size                = UDim2.new(0.35, 0, 0.15, 0)
buyButton.Position            = UDim2.new(0.1,  0, 0.60, 0)
buyButton.Text                = "Buy"
buyButton.TextScaled          = true
buyButton.Font                = Enum.Font.Gotham
buyButton.BackgroundColor3    = Color3.fromRGB(70, 130, 180)
Instance.new("UICorner", buyButton)

local autoButton = Instance.new("TextButton", mainFrame)
autoButton.Size               = UDim2.new(0.35, 0, 0.15, 0)
autoButton.Position           = UDim2.new(0.55, 0, 0.60, 0)
autoButton.Text               = "Auto Buyer: OFF"
autoButton.TextScaled         = true
autoButton.Font               = Enum.Font.Gotham
autoButton.BackgroundColor3   = Color3.fromRGB(100, 100, 100)
Instance.new("UICorner", autoButton)

local autoEnabled = false
local autoTask

buyButton.MouseButton1Click:Connect(function()
    local itemName = textBox.Text
    if itemName ~= "" then
        BuyItemCash:FireServer(itemName)
        print(itemName .. " purchased!")
    end
end)

autoButton.MouseButton1Click:Connect(function()
    autoEnabled = not autoEnabled
    autoButton.Text = "Auto Buyer: " .. (autoEnabled and "ON" or "OFF")
    if autoEnabled then
        autoTask = task.spawn(function()
            while autoEnabled do
                local item = textBox.Text
                if item ~= "" then
                    BuyItemCash:FireServer(item)
                    print("[Auto] " .. item .. " purchased!")
                end
                task.wait(0.1)
            end
        end)
    elseif autoTask then
        task.cancel(autoTask)
    end
end)
