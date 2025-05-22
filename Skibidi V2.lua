local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if game.PlaceId ~= 7346416636 then
    warn("This script only works in Pop It Trading!")
    return
end

if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
end

local Config = {
    DuplicateDelay = 0.5,
    MaxDuplicates = 10,
    SafeMode = true,
    AdvancedSafeMode = true,
    RandomDelays = true,
    LimitBatchSize = true,
    MaxBatchSize = 3,
    CooldownPeriod = 5,
}

local function setupAntiDetection()
    local mt = getrawmetatable(game)
    local old_index = mt.__index
    setreadonly(mt, false)
    mt.__index = newcclosure(function(self, key)
        if key == "FilteringEnabled" and checkcaller() then
            return false
        end
        return old_index(self, key)
    end)
    setreadonly(mt, true)

    if Config.SafeMode then
        local old_stats = gcinfo
        gcinfo = function()
            return math.random(300, 400)
        end
    end

    if Config.AdvancedSafeMode then
        local oldFire = Instance.new("RemoteEvent").FireServer
        local oldInvoke = Instance.new("RemoteFunction").InvokeServer

        Instance.new("RemoteEvent").FireServer = newcclosure(function(self, ...)
            if Config.RandomDelays then wait(math.random(10, 50) / 100) end
            return oldFire(self, ...)
        end)

        Instance.new("RemoteFunction").InvokeServer = newcclosure(function(self, ...)
            if Config.RandomDelays then wait(math.random(10, 50) / 100) end
            return oldInvoke(self, ...)
        end)

        if hookfunction then
            local oldHttp = (syn and syn.request) or (http and http.request) or http_request or request
            if oldHttp then
                if syn then
                    syn.request = function(opts)
                        if opts.Url and (opts.Url:find("analytics") or opts.Url:find("telemetry") or opts.Url:find("tracking")) then
                            return { StatusCode = 200, Body = "{}", Headers = {} }
                        end
                        return oldHttp(opts)
                    end
                elseif http then
                    http.request = function(opts)
                        if opts.Url and (opts.Url:find("analytics") or opts.Url:find("telemetry") or opts.Url:find("tracking")) then
                            return { StatusCode = 200, Body = "{}", Headers = {} }
                        end
                        return oldHttp(opts)
                    end
                elseif http_request then
                    http_request = function(opts)
                        if opts.Url and (opts.Url:find("analytics") or opts.Url:find("telemetry") or opts.Url:find("tracking")) then
                            return { StatusCode = 200, Body = "{}", Headers = {} }
                        end
                        return oldHttp(opts)
                    end
                elseif request then
                    request = function(opts)
                        if opts.Url and (opts.Url:find("analytics") or opts.Url:find("telemetry") or opts.Url:find("tracking")) then
                            return { StatusCode = 200, Body = "{}", Headers = {} }
                        end
                        return oldHttp(opts)
                    end
                end
            end
        end
    end
end

local function toggleSafeMode(enabled)
    Config.AdvancedSafeMode = enabled
    if enabled then
        Config.DuplicateDelay = 1.0
        Config.RandomDelays = true
        Config.LimitBatchSize = true
    else
        Config.DuplicateDelay = 0.2
        Config.RandomDelays = false
        Config.LimitBatchSize = false
    end
    return enabled
end

local function findTradingRemotes()
    local remotes = {}
    local paths = {
        ReplicatedStorage:FindFirstChild("TradingRemotes"),
        ReplicatedStorage:FindFirstChild("Remotes"),
        ReplicatedStorage:FindFirstChild("RemoteEvents"),
    }
    for _, p in pairs(paths) do
        if p then
            for _, r in pairs(p:GetDescendants()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    remotes[r.Name] = r
                end
            end
        end
    end
    if next(remotes) == nil then
        warn("Failed to find trading remotes!")
        return nil
    end
    return remotes
end

local function getInventoryItems()
    local items = {}
    local inv = LocalPlayer:FindFirstChild("Inventory")
        or LocalPlayer:FindFirstChild("Backpack")
        or ReplicatedStorage:FindFirstChild("Inventory")
    if not inv then
        for _, v in pairs(LocalPlayer:GetDescendants()) do
            if v.Name == "Inventory" or v.Name == "Items" then
                inv = v
                break
            end
        end
    end
    if inv then
        for _, item in pairs(inv:GetChildren()) do
            table.insert(items, { Name = item.Name, Instance = item })
        end
    else
        warn("Could not find inventory folder!")
    end
    return items
end

local function duplicateItem(item, remotes, callback)
    local trade = remotes["StartTrading"] or remotes["RequestTrade"] or remotes["Trade"]
    if not trade then
        callback(false, "Trading remote not found")
        return
    end
    spawn(function()
        local target
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                target = p
                break
            end
        end
        if not target then
            callback(false, "No other players found")
            return
        end
        local success, err = pcall(function()
            trade:FireServer(target)
            wait(0.2)
            if remotes["CancelTrade"] then
                remotes["CancelTrade"]:FireServer()
            end
        end)
        if not success then
            warn("Duplication error:", err)
            callback(false, err)
        else
            callback(true)
        end
    end)
end

local function createUI()
    if game:GetService("CoreGui"):FindFirstChild("PopItDuplicatorUI") then
        game:GetService("CoreGui"):PopItDuplicatorUI:Destroy()
    end
    local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
    ScreenGui.Name = "PopItDuplicatorUI"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 300, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true

    local TitleBar = Instance.new("Frame", MainFrame)
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 30)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    TitleBar.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -30, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Text = "PopItDuplicator"

    local CloseButton = Instance.new("TextButton", TitleBar)
    CloseButton.Name = "CloseButton"
    CloseButton.Size = UDim2.new(0, 30, 0, 30)
    CloseButton.Position = UDim2.new(1, -30, 0, 0)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Font = Enum.Font.SourceSansBold
    CloseButton.TextSize = 20
    CloseButton.TextColor3 = Color3.fromRGB(255, 100, 100)
    CloseButton.Text = "X"
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local Container = Instance.new("Frame", MainFrame)
    Container.Name = "Container"
    Container.Size = UDim2.new(1, 0, 1, -30)
    Container.Position = UDim2.new(0, 0, 0, 30)
    Container.BackgroundTransparency = 1

    local Instructions = Instance.new("TextLabel", Container)
    Instructions.Name = "Instructions"
    Instructions.Size = UDim2.new(1, -20, 0, 40)
    Instructions.Position = UDim2.new(0, 10, 0, 10)
    Instructions.BackgroundTransparency = 1
    Instructions.Font = Enum.Font.SourceSans
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(200, 200, 200)
    Instructions.TextWrapped = true
    Instructions.TextXAlignment = Enum.TextXAlignment.Left
    Instructions.Text = "Select items below to duplicate."

    local ItemsFrame = Instance.new("ScrollingFrame", Container)
    ItemsFrame.Name = "ItemsFrame"
    ItemsFrame.Size = UDim2.new(1, -20, 0, 160)
    ItemsFrame.Position = UDim2.new(0, 10, 0, 60)
    ItemsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ItemsFrame.BorderSizePixel = 0
    ItemsFrame.ScrollBarThickness = 6
    ItemsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ItemsFrame.ScrollingDirection = Enum.ScrollingDirection.Y

    local StatusLabel = Instance.new("TextLabel", Container)
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -20, 0, 25)
    StatusLabel.Position = UDim2.new(0, 10, 0, 230)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Font = Enum.Font.SourceSans
    StatusLabel.TextSize = 14
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Text = "Ready"

    local CountLabel = Instance.new("TextLabel", Container)
    CountLabel.Name = "CountLabel"
    CountLabel.Size = UDim2.new(1, -20, 0, 20)
    CountLabel.Position = UDim2.new(0, 10, 0, 260)
    CountLabel.BackgroundTransparency = 1
    CountLabel.Font = Enum.Font.SourceSans
    CountLabel.TextSize = 14
    CountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CountLabel.TextXAlignment = Enum.TextXAlignment.Left
    CountLabel.Text = "Number of duplicates: 5"

    local CountSlider = Instance.new("Frame", Container)
    CountSlider.Name = "CountSlider"
    CountSlider.Size = UDim2.new(1, -20, 0, 20)
    CountSlider.Position = UDim2.new(0, 10, 0, 280)
    CountSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    CountSlider.BorderSizePixel = 0

    local SliderButton = Instance.new("TextButton", CountSlider)
    SliderButton.Name = "SliderButton"
    SliderButton.Size = UDim2.new(0, 20, 0, 20)
    SliderButton.Position = UDim2.new(0.5, -10, 0, 0)
    SliderButton.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    SliderButton.BorderSizePixel = 0
    SliderButton.Text = ""

    local DuplicateButton = Instance.new("TextButton", Container)
    DuplicateButton.Name = "DuplicateButton"
    DuplicateButton.Size = UDim2.new(1, -20, 0, 30)
    DuplicateButton.Position = UDim2.new(0, 10, 0, 310)
    DuplicateButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    DuplicateButton.BorderSizePixel = 0
    DuplicateButton.Font = Enum.Font.SourceSansBold
    DuplicateButton.TextSize = 16
    DuplicateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    DuplicateButton.Text = "Duplicate Selected Items"

    local selectedItems = {}
    local duplicateCount = 5
    local sliderDragging = false

    SliderButton.MouseButton1Down:Connect(function() sliderDragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliderDragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if sliderDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = UserInputService:GetMouseLocation()
            local framePos = CountSlider.AbsolutePosition
            local frameSize = CountSlider.AbsoluteSize
            local rel = math.clamp((pos.X - framePos.X) / frameSize.X, 0, 1)
            SliderButton.Position = UDim2.new(rel, -10, 0, 0)
            duplicateCount = math.floor(rel * 9) + 1
            CountLabel.Text = "Number of duplicates: " .. duplicateCount
        end
    end)

    DuplicateButton.MouseButton1Click:Connect(function()
        local count = 0
        for _ in pairs(selectedItems) do count = count + 1 end
        if count == 0 then
            StatusLabel.Text = "No items selected!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        DuplicateButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        DuplicateButton.Text = "Duplicating..."
        DuplicateButton.Active = false

        local remotes = findTradingRemotes()
        if not remotes then
            StatusLabel.Text = "Failed to find trading system!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            DuplicateButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
            DuplicateButton.Text = "Duplicate Selected Items"
            DuplicateButton.Active = true
            return
        end

        StatusLabel.Text = "Starting duplication..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)

        for itemName, item in pairs(selectedItems) do
            local successCount = 0
            for i = 1, duplicateCount do
                StatusLabel.Text = string.format("Duplicating %s (%d/%d)", itemName, i, duplicateCount)
                duplicateItem(item, remotes, function(success)
                    if success then successCount = successCount + 1 end
                end)
                wait(Config.DuplicateDelay)
            end
            StatusLabel.Text = string.format("%s - %d/%d duplicated", itemName, successCount, duplicateCount)
            wait(0.2)
        end

        StatusLabel.Text = "All items processed!"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        DuplicateButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        DuplicateButton.Text = "Duplicate Selected Items"
        DuplicateButton.Active = true
    end)

    local items = getInventoryItems()
    for i, data in ipairs(items) do
        local btn = Instance.new("TextButton", ItemsFrame)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.Position = UDim2.new(0, 5, 0, (i-1)*35)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Text = data.Name
        btn.MouseButton1Click:Connect(function()
            if selectedItems[data.Name] then
                selectedItems[data.Name] = nil
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            else
                selectedItems[data.Name] = data
                btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
            end
        end)
        ItemsFrame.CanvasSize = UDim2.new(0, 0, 0, i * 35)
    end
end

setupAntiDetection()
createUI()
