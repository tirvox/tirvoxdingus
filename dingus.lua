local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "TirvoxHub",
    SubTitle = "by Tirvox",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ================================================
-- ESP (Chams)
-- ================================================
local espEnabled = false
local highlights = {}

local function createHighlight(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end

    if highlights[player] then
        highlights[player]:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    highlights[player] = highlight
end

local function clearESP()
    for _, hl in pairs(highlights) do
        hl:Destroy()
    end
    highlights = {}
end

local function enableESP()
    espEnabled = true
    clearESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                createHighlight(player)
            end
            player.CharacterAdded:Connect(function(char)
                if espEnabled then createHighlight(player) end
            end)
        end
    end
    Players.PlayerAdded:Connect(function(player)
        if espEnabled and player ~= LocalPlayer then
            if player.Character then
                createHighlight(player)
            end
            player.CharacterAdded:Connect(function(char)
                if espEnabled then createHighlight(player) end
            end)
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
    end)
end

local function disableESP()
    espEnabled = false
    clearESP()
end

Tabs.Main:AddToggle("ESP", {
    Title = "Player Chams (ESP)",
    Default = false
}):OnChanged(function()
    if Options.ESP.Value then
        enableESP()
    else
        disableESP()
    end
end)

-- ================================================
-- Fly / Noclip
-- ================================================
local flyEnabled = false
local flySpeed = 50
local bodyGyro, bodyVelocity, flyConnection

local function getRoot(character)
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function startFly()
    if flyEnabled then return end
    flyEnabled = true
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local root = getRoot(character)
    if not root then return end

    root.CanCollide = false
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.P = 9e4
    bodyGyro.MaxTorque = Vector3.new(9e4, 9e4, 9e4)
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
    bodyVelocity.Parent = root

    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled then return end
        local currentChar = LocalPlayer.Character
        if not currentChar then return end
        local currentRoot = getRoot(currentChar)
        if not currentRoot then return end

        local moveDir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir -= Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * flySpeed
        end

        bodyVelocity.Velocity = moveDir
        bodyGyro.CFrame = Camera.CFrame
    end)
end

local function stopFly()
    flyEnabled = false
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end

    local char = LocalPlayer.Character
    if char then
        local root = getRoot(char)
        if root then root.CanCollide = true end
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

Tabs.Main:AddToggle("Fly", {
    Title = "Fly / Noclip",
    Default = false
}):OnChanged(function()
    if Options.Fly.Value then
        startFly()
    else
        stopFly()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if flyEnabled then
        stopFly()
        task.wait(0.3)
        startFly()
    end
end)

-- ================================================
-- Walk Speed
-- ================================================
local targetSpeed = 16
local walkConnection

local function setSpeed(character)
    local humanoid = character and character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = targetSpeed
    end
end

local function startWalkLoop()
    if walkConnection then walkConnection:Disconnect() end
    walkConnection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = targetSpeed
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(character)
    setSpeed(character)
    startWalkLoop()
end)

Tabs.Main:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Постоянная скорость",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(Value)
        targetSpeed = Value
        setSpeed(LocalPlayer.Character)
        startWalkLoop()
    end
})

if LocalPlayer.Character then
    setSpeed(LocalPlayer.Character)
end
startWalkLoop()

-- ================================================
-- Instant Tasks (0.5 Hold)
-- ================================================
local instantEnabled = false
local instantThread

local function setAllPrompts()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            obj.HoldDuration = 0.5
        end
    end
end

local function startInstantTasks()
    if instantEnabled then return end
    instantEnabled = true
    setAllPrompts()

    instantThread = task.spawn(function()
        while instantEnabled do
            setAllPrompts()
            task.wait(1)
        end
    end)

    game.DescendantAdded:Connect(function(desc)
        if instantEnabled and desc:IsA("ProximityPrompt") then
            desc.HoldDuration = 0.5
        end
    end)
end

local function stopInstantTasks()
    instantEnabled = false
    if instantThread then
        task.cancel(instantThread)
        instantThread = nil
    end
end

Tabs.Main:AddToggle("InstantTasks", {
    Title = "Instant Tasks (0.5 Hold)",
    Default = false
}):OnChanged(function()
    if Options.InstantTasks.Value then
        startInstantTasks()
    else
        stopInstantTasks()
    end
end)

-- ================================================
-- Server Hide (Desync Mode)
-- ================================================
local desyncEnabled = false
local fakeCharacter = nil
local desyncBodyPos

local function createFakeCharacter(realChar)
    -- Клонируем модель персонажа
    local clone = realChar:Clone()
    clone.Parent = Workspace
    clone.Name = "FakeChar"
    -- Делаем оригинал невидимым для клиента
    for _, part in ipairs(realChar:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
        end
    end
    local humanoid = realChar:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    -- Закрепляем реальный HumanoidRootPart под картой
    local root = getRoot(realChar)
    if root then
        root.Anchored = true
        root.CFrame = root.CFrame - Vector3.new(0, 50, 0)
    end
    -- Подготавливаем копию для управления
    clone.PrimaryPart = clone:FindFirstChild("HumanoidRootPart")
    if clone.PrimaryPart then
        clone.PrimaryPart.Anchored = false
        clone.PrimaryPart.CanCollide = true
    end
    -- Перемещаем копию на место реального персонажа
    clone:SetPrimaryPartCFrame(realChar:GetPrimaryPartCFrame() + Vector3.new(0, 50, 0))
    -- Привязываем камеру к копии
    Camera.CameraSubject = clone:FindFirstChild("Humanoid") or clone.PrimaryPart
    -- Управление: перенаправляем движения на копию
    local cloneHumanoid = clone:FindFirstChild("Humanoid")
    if cloneHumanoid then
        cloneHumanoid.WalkSpeed = targetSpeed
        cloneHumanoid.JumpPower = humanoid and humanoid.JumpPower or 50
    end
    -- Заставляем реального персонажа следовать за копией на расстоянии 50 вниз
    desyncBodyPos = Instance.new("BodyPosition")
    desyncBodyPos.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    desyncBodyPos.P = 1e6
    desyncBodyPos.Position = root.CFrame.Position
    desyncBodyPos.Parent = root

    -- Синхронизируем позицию реала с копией по X и Z, но Y на -50
    RunService.RenderStepped:Connect(function()
        if not desyncEnabled then return end
        local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
        local realRoot = getRoot(realChar)
        if cloneRoot and realRoot and desyncBodyPos then
            local newPos = cloneRoot.Position - Vector3.new(0, 50, 0)
            desyncBodyPos.Position = newPos
        end
    end)

    fakeCharacter = clone
    return clone
end

local function removeFakeCharacter()
    if fakeCharacter then
        fakeCharacter:Destroy()
        fakeCharacter = nil
    end
    if desyncBodyPos then
        desyncBodyPos:Destroy()
        desyncBodyPos = nil
    end
    -- Возвращаем реального персонажа наверх и делаем видимым
    local realChar = LocalPlayer.Character
    if realChar then
        for _, part in ipairs(realChar:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
        local hum = realChar:FindFirstChild("Humanoid")
        if hum then
            hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
        end
        local root = getRoot(realChar)
        if root then
            root.Anchored = false
            root.CFrame = fakeCharacter and fakeCharacter:GetPrimaryPartCFrame() or root.CFrame + Vector3.new(0, 50, 0)
        end
        Camera.CameraSubject = realChar:FindFirstChild("Humanoid") or realChar.PrimaryPart
    end
end

local function startDesync()
    if desyncEnabled then return end
    desyncEnabled = true
    local realChar = LocalPlayer.Character
    if not realChar then return end
    createFakeCharacter(realChar)
end

local function stopDesync()
    desyncEnabled = false
    removeFakeCharacter()
end

Tabs.Main:AddToggle("ServerHide", {
    Title = "Server Hide (Desync)",
    Default = false
}):OnChanged(function()
    if Options.ServerHide.Value then
        startDesync()
    else
        stopDesync()
    end
end)

-- Обработка возрождения
LocalPlayer.CharacterAdded:Connect(function(character)
    if desyncEnabled then
        stopDesync()
        task.wait(0.3)
        startDesync()
    end
end)

-- ================================================
-- Invisible (клиентская невидимость) оставим как есть
-- ================================================
-- (можно удалить или оставить на своё усмотрение, но ServerHide уже скрывает вас от сервера)

-- ================================================
-- Менеджеры сохранения / интерфейса
-- ================================================
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("TirvoxHub")
SaveManager:SetFolder("TirvoxHub/configs")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "TirvoxHub",
    Content = "Все функции загружены. Server Hide экспериментальный!",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
