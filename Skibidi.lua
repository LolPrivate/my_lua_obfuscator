local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
local BuyItemCash = RemoteEvents:WaitForChild("BuyItemCash")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BuyGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 200)
frame.Position = UDim2.new(0.5, -150, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 10)

local textBox = Instance.new("TextBox")
textBox.PlaceholderText = "Digite o nome do item"
textBox.Size = UDim2.new(0, 260, 0, 26)
textBox.Position = UDim2.new(0, 20, 0, 20)
textBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
textBox.TextColor3 = Color3.new(1, 1, 1)
textBox.TextScaled = true
textBox.Parent = frame
Instance.new("UICorner", textBox)

local buyButton = Instance.new("TextButton")
buyButton.Size = UDim2.new(0, 120, 0, 40)
buyButton.Position = UDim2.new(0, 20, 0, 80)
buyButton.Text = "Buyer"
buyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
buyButton.TextColor3 = Color3.new(1, 1, 1)
buyButton.TextScaled = true
buyButton.Parent = frame
Instance.new("UICorner", buyButton)

local autoButton = Instance.new("TextButton")
autoButton.Size = UDim2.new(0, 120, 0, 40)
autoButton.Position = UDim2.new(0, 160, 0, 80)
autoButton.Text = "Auto Buyer: OFF"
autoButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
autoButton.TextColor3 = Color3.new(1, 1, 1)
autoButton.TextScaled = true
autoButton.Parent = frame
Instance.new("UICorner", autoButton)

local autoEnabled = false
local autoTask

buyButton.MouseButton1Click:Connect(function()
    local itemName = textBox.Text
    if itemName ~= "" then
        BuyItemCash:FireServer(itemName)
        print(itemName .. " satÄ±n alÄ±ndÄ±!")
    end
end)

autoButton.MouseButton1Click:Connect(function()
    autoEnabled = not autoEnabled
    autoButton.Text = "Auto Buyer: " .. (autoEnabled and "ON" or "OFF")

    if autoEnabled then
        autoTask = task.spawn(function()
            while autoEnabled do
                local itemName = textBox.Text
                if itemName ~= "" then
                    BuyItemCash:FireServer(itemName)
                    print("[Auto] " .. itemName .. " satÄ±n alÄ±ndÄ±!")
                end
                task.wait(0.1)
            end
        end)
    elseif autoTask then
        task.cancel(autoTask)
    end
end)
