-- LocalScript đặt tại: StarterPlayer -> StarterPlayerScripts -> RioHubScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Trạng thái tính năng
local flyEnabled = false
local speedEnabled = false
local fixLagEnabled = false

local flySpeed = 60
local customSpeed = 80

local bodyVelocity, bodyGyro, flyConnection

-- === 1. GIAO DIỆN RIO HUB (CÁCH LY THAO TÁC GAME) ===
local playerGui = player:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("RioHubGui") then
    playerGui.RioHubGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RioHubGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.Parent = playerGui

-- Màn chắn ẩn phủ toàn màn hình chặn mọi thao tác xuống 3D World khi mở Menu
local overlayBlocker = Instance.new("TextButton")
overlayBlocker.Name = "OverlayBlocker"
overlayBlocker.Size = UDim2.new(1, 0, 1, 0)
overlayBlocker.Position = UDim2.new(0, 0, 0, 0)
overlayBlocker.BackgroundTransparency = 1
overlayBlocker.Text = ""
overlayBlocker.Active = true
overlayBlocker.Modal = true
overlayBlocker.AutoButtonColor = false
overlayBlocker.Visible = false
overlayBlocker.ZIndex = 1
overlayBlocker.Parent = screenGui

local logoBtn = Instance.new("TextButton")
logoBtn.Name = "RioLogoButton"
logoBtn.Size = UDim2.new(0, 48, 0, 48)
logoBtn.Position = UDim2.new(0.02, 0, 0.2, 0)
logoBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 210)
logoBtn.Text = "Rio"
logoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
logoBtn.TextSize = 16
logoBtn.Font = Enum.Font.SourceSansBold
logoBtn.Active = true
logoBtn.Draggable = true
logoBtn.ZIndex = 10
logoBtn.Parent = screenGui
Instance.new("UICorner", logoBtn).CornerRadius = UDim.new(1, 0)

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 460, 0, 280)
mainFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local function setMenuVisible(visible)
    mainFrame.Visible = visible
    overlayBlocker.Visible = visible
end

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -40, 0, 40)
headerLabel.Position = UDim2.new(0, 15, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "RIO HUB  |  @Rio_Hammer"
headerLabel.TextColor3 = Color3.fromRGB(240, 240, 250)
headerLabel.TextSize = 14
headerLabel.Font = Enum.Font.SourceSansBold
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.ZIndex = 3
headerLabel.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Active = true
closeBtn.ZIndex = 3
closeBtn.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function() 
    setMenuVisible(false) 
end)

logoBtn.MouseButton1Click:Connect(function() 
    setMenuVisible(not mainFrame.Visible) 
end)

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 120, 1, -50)
sidebar.Position = UDim2.new(0, 10, 0, 45)
sidebar.BackgroundColor3 = Color3.fromRGB(28, 30, 38)
sidebar.BorderSizePixel = 0
sidebar.Active = true
sidebar.ZIndex = 3
sidebar.Parent = mainFrame
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 8)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -150, 1, -55)
contentFrame.Position = UDim2.new(0, 140, 0, 45)
contentFrame.BackgroundTransparency = 1
contentFrame.Active = true
contentFrame.ZIndex = 3
contentFrame.Parent = mainFrame

local tabs = {}
local function createTab(name, index)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0.9, 0, 0, 32)
    tabBtn.Position = UDim2.new(0.05, 0, 0, (index - 1) * 38 + 8)
    tabBtn.BackgroundColor3 = Color3.fromRGB(36, 39, 50)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.Active = true
    tabBtn.ZIndex = 4
    tabBtn.Parent = sidebar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Active = true
    page.ZIndex = 4
    page.Parent = contentFrame

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Page.Visible = false
            t.Button.BackgroundColor3 = Color3.fromRGB(36, 39, 50)
        end
        page.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 210)
    end)
    tabs[name] = {Button = tabBtn, Page = page}
    return page
end

local movePage = createTab("Di chuyển", 1)
local optPage = createTab("Tối ưu", 2)
tabs["Di chuyển"].Page.Visible = true
tabs["Di chuyển"].Button.BackgroundColor3 = Color3.fromRGB(90, 50, 210)

-- Buttons
local flyBtn = Instance.new("TextButton", movePage)
flyBtn.Size, flyBtn.Position = UDim2.new(0.95, 0, 0, 36), UDim2.new(0, 0, 0, 10)
flyBtn.BackgroundColor3, flyBtn.TextColor3 = Color3.fromRGB(45, 48, 60), Color3.fromRGB(220, 220, 230)
flyBtn.Text, flyBtn.TextSize, flyBtn.Font = "Fly Mode: OFF", 13, Enum.Font.SourceSansBold
flyBtn.Active = true
flyBtn.ZIndex = 5
Instance.new("UICorner", flyBtn).CornerRadius = UDim.new(0, 6)

local speedInput = Instance.new("TextBox", movePage)
speedInput.Size, speedInput.Position = UDim2.new(0.95, 0, 0, 34), UDim2.new(0, 0, 0, 55)
speedInput.BackgroundColor3, speedInput.TextColor3 = Color3.fromRGB(35, 38, 48), Color3.fromRGB(255, 255, 255)
speedInput.Text, speedInput.PlaceholderText = "100", "Nhập tốc độ..."
speedInput.TextSize, speedInput.Font = 12, Enum.Font.SourceSansBold
speedInput.Active = true
speedInput.ZIndex = 5
Instance.new("UICorner", speedInput).CornerRadius = UDim.new(0, 6)

local speedBtn = Instance.new("TextButton", movePage)
speedBtn.Size, speedBtn.Position = UDim2.new(0.95, 0, 0, 36), UDim2.new(0, 0, 0, 98)
speedBtn.BackgroundColor3, speedBtn.TextColor3 = Color3.fromRGB(45, 48, 60), Color3.fromRGB(220, 220, 230)
speedBtn.Text, speedBtn.TextSize, speedBtn.Font = "Tốc Độ: OFF", 13, Enum.Font.SourceSansBold
speedBtn.Active = true
speedBtn.ZIndex = 5
Instance.new("UICorner", speedBtn).CornerRadius = UDim.new(0, 6)

local fixLagBtn = Instance.new("TextButton", optPage)
fixLagBtn.Size, fixLagBtn.Position = UDim2.new(0.95, 0, 0, 40), UDim2.new(0, 0, 0, 10)
fixLagBtn.BackgroundColor3, fixLagBtn.TextColor3 = Color3.fromRGB(45, 48, 60), Color3.fromRGB(220, 220, 230)
fixLagBtn.Text, fixLagBtn.TextSize, fixLagBtn.Font = "Fix Lag Ép Xung FPS: OFF", 13, Enum.Font.SourceSansBold
fixLagBtn.Active = true
fixLagBtn.ZIndex = 5
Instance.new("UICorner", fixLagBtn).CornerRadius = UDim.new(0, 6)

-- === 2. TỐC ĐỘ CFRAME ===
speedInput.FocusLost:Connect(function()
    local val = tonumber(speedInput.Text)
    if val and val > 0 then customSpeed = val end
end)

speedBtn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    if speedEnabled then
        speedBtn.Text = "Tốc Độ CFrame: ON"
        speedBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        speedBtn.Text = "Tốc Độ: OFF"
        speedBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    end
end)

RunService.RenderStepped:Connect(function(deltaTime)
    if speedEnabled then
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * (customSpeed * deltaTime))
            end
        end
    end
end)

-- === 3. FLY MODE ===
local function stopFlying()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    local char = player.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        char:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

local function startFlying()
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    char:FindFirstChildOfClass("Humanoid").PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root

    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled or not char or not root then stopFlying() return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end

        bodyVelocity.Velocity = dir.Magnitude > 0 and dir.Unit * flySpeed or Vector3.zero
        bodyGyro.CFrame = camera.CFrame
    end)
end

flyBtn.MouseButton1Click:Connect(function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        flyBtn.Text = "Fly Mode: ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        startFlying()
    else
        flyBtn.Text = "Fly Mode: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
        stopFlying()
    end
end)

-- === 4. TỐI ƯU FIX LAG ===
fixLagBtn.MouseButton1Click:Connect(function()
    fixLagEnabled = not fixLagEnabled
    if fixLagEnabled then
        fixLagBtn.Text = "Fix Lag Ép Xung FPS: ON"
        fixLagBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        Lighting.GlobalShadows = false
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then v.Material = Enum.Material.SmoothPlastic v.CastShadow = false
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then v.Enabled = false end
        end
    else
        fixLagBtn.Text = "Fix Lag Ép Xung FPS: OFF"
        fixLagBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
        Lighting.GlobalShadows = true
    end
end)
