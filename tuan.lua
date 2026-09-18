-- LocalScript đặt tại: StarterPlayer -> StarterPlayerScripts -> RioHubCombinedScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Trạng thái tính năng (Di chuyển & Tối ưu & Antiban)
local flyEnabled = false
local speedEnabled = false
local fixLagEnabled = false
local antiBanEnabled = false

local flySpeed = 60
local customSpeed = 80

local bodyVelocity, bodyGyro, flyConnection

-- Trạng thái tính năng (Aimbot & ESP)
local Settings = {
    Aimbot = false,
    ESP_Tracers = false,
    ShowFOV = false,
    FOV_Size = 120,      
    AimPart = "Head"     
}

-- === HỆ THỐNG AN TOÀN / ANTIBAN CƠ BẢN ===
local _env = (getgenv and getgenv()) or _G

local function secureCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then return nil end
    return result
end

-- === 1. GIAO DIỆN RIO HUB CHUNG (Đảm bảo luôn hiển thị & bảo vệ GUI) ===
local function getParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if success and parent then return parent end
    return player:WaitForChild("PlayerGui")
end

local playerGui = getParent()
if playerGui:FindFirstChild("RioHubGui") then
    playerGui.RioHubGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RioHubGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999
screenGui.IgnoreGuiInset = true

secureCall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = game:GetService("CoreGui")
    end
end)

if not screenGui.Parent then
    screenGui.Parent = player:WaitForChild("PlayerGui")
end

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
logoBtn.Size = UDim2.new(0, 50, 0, 50)
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
local aimPage = createTab("Aimbot", 3)
local antibanPage = createTab("Antiban", 4)

tabs["Di chuyển"].Page.Visible = true
tabs["Di chuyển"].Button.BackgroundColor3 = Color3.fromRGB(90, 50, 210)

-- Buttons trang Di chuyển
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

-- Buttons trang Tối ưu (Fix Lag)
local fixLagBtn = Instance.new("TextButton", optPage)
fixLagBtn.Size, fixLagBtn.Position = UDim2.new(0.95, 0, 0, 40), UDim2.new(0, 0, 0, 10)
fixLagBtn.BackgroundColor3, fixLagBtn.TextColor3 = Color3.fromRGB(45, 48, 60), Color3.fromRGB(220, 220, 230)
fixLagBtn.Text, fixLagBtn.TextSize, fixLagBtn.Font = "Fix Lag Ép Xung FPS: OFF", 13, Enum.Font.SourceSansBold
fixLagBtn.Active = true
fixLagBtn.ZIndex = 5
Instance.new("UICorner", fixLagBtn).CornerRadius = UDim.new(0, 6)

-- Buttons trang Antiban
local antiBanBtn = Instance.new("TextButton", antibanPage)
antiBanBtn.Size, antiBanBtn.Position = UDim2.new(0.95, 0, 0, 40), UDim2.new(0, 0, 0, 10)
antiBanBtn.BackgroundColor3, antiBanBtn.TextColor3 = Color3.fromRGB(45, 48, 60), Color3.fromRGB(220, 220, 230)
antiBanBtn.Text, antiBanBtn.TextSize, antiBanBtn.Font = "Antiban: OFF", 13, Enum.Font.SourceSansBold
antiBanBtn.Active = true
antiBanBtn.ZIndex = 5
Instance.new("UICorner", antiBanBtn).CornerRadius = UDim.new(0, 6)

antiBanBtn.MouseButton1Click:Connect(function()
    antiBanEnabled = not antiBanEnabled
    if antiBanEnabled then
        antiBanBtn.Text = "Antiban: ON"
        antiBanBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
        antiBanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        
        secureCall(function()
            if setreadonly and makewrite then
                setreadonly(table, false)
            end
        end)
    else
        antiBanBtn.Text = "Antiban: OFF"
        antiBanBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
        antiBanBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    end
end)

-- === 2. TẠO CÁC NÚT BẬT/TẮT TRONG TAB AIMBOT ===
local function createAimToggle(text, yPos, settingKey, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.95, 0, 0, 36)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    btn.TextColor3 = Color3.fromRGB(220, 220, 230)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Text = text .. ": OFF"
    btn.Active = true
    btn.ZIndex = 5
    btn.Parent = aimPage
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local isEnabled = Settings[settingKey]
        
        btn.Text = text .. ": " .. (isEnabled and "ON" or "OFF")
        btn.BackgroundColor3 = isEnabled and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(45, 48, 60)
        btn.TextColor3 = isEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 220, 230)
        
        if callback then callback(isEnabled) end
    end)
end

-- === 3. VÒNG TRÒN FOV & TRACERS CHO AIMBOT ===
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.new(0, Settings.FOV_Size * 2, 0, Settings.FOV_Size * 2)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Parent = screenGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.5
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local TracersFolder = Instance.new("Folder")
TracersFolder.Name = "TracersFolder"
TracersFolder.Parent = screenGui

createAimToggle("Aimbot (Ghim Đầu 100%)", 10, "Aimbot")
createAimToggle("ESP Định Vị (Tracer)", 55, "ESP_Tracers")
createAimToggle("Hiển Thị FOV", 100, "ShowFOV", function(val) FOVCircle.Visible = val end)

-- === 4. LOGIC TỐC ĐỘ CFRAME ===
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

-- === 5. LOGIC FLY MODE ===
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

-- === 6. LOGIC TỐI ƯU FIX LAG ===
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

-- === 7. LOGIC HỆ THỐNG AIMBOT LINH HOẠT ===
local tracerLines = {}

local function getClosestHeadInFOV()
    local closestPart = nil
    local shortestDistance = Settings.FOV_Size
    local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
            local headPart = p.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and headPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(headPart.Position)
                
                if onScreen then
                    local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (screenVector - centerScreen).Magnitude
                    
                    if distance <= Settings.FOV_Size and distance < shortestDistance then
                        shortestDistance = distance
                        closestPart = headPart
                    end
                end
            end
        end
    end
    return closestPart
end

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

    FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)

    if Settings.Aimbot then
        local targetHead = getClosestHeadInFOV()
        if targetHead then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetHead.Position)
        end
    end

    if Settings.ESP_Tracers then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("Head") then
                local head = p.Character.Head
                local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local line = tracerLines[p.Name]
                        if not line then
                            line = Instance.new("Frame")
                            line.AnchorPoint = Vector2.new(0.5, 0.5)
                            line.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
                            line.BorderSizePixel = 0
                            line.Parent = TracersFolder
                            tracerLines[p.Name] = line
                        end
                        
                        local centerScreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
                        
                        local distance = (targetScreen - centerScreen).Magnitude
                        local angle = math.atan2(targetScreen.Y - centerScreen.Y, targetScreen.X - centerScreen.X)
                        
                        line.Size = UDim2.new(0, distance, 0, 1.5)
                        line.Position = UDim2.new(0, (centerScreen.X + targetScreen.X) / 2, 0, (centerScreen.Y + targetScreen.Y) / 2)
                        line.Rotation = math.deg(angle)
                        line.Visible = true
                    elseif tracerLines[p.Name] then
                        tracerLines[p.Name].Visible = false
                    end
                elseif tracerLines[p.Name] then
                    tracerLines[p.Name].Visible = false
                end
            else
                if tracerLines[p.Name] then
                    tracerLines[p.Name].Visible = false
                end
            end
        end
    else
        for _, line in pairs(tracerLines) do
            line.Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if tracerLines[p.Name] then
        tracerLines[p.Name]:Destroy()
        tracerLines[p.Name] = nil
    end
end)
