-- LocalScript / Executor Script - Aimbot Ghim Đầu 100% (Khắc phục triệt để lỗi bỏ sót mục tiêu)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ==========================================
-- CẤU HÌNH HỆ THỐNG
-- ==========================================
local Settings = {
    Aimbot = false,
    ESP_Tracers = false,
    ShowFOV = false,
    FOV_Size = 200,      -- Tăng kích thước FOV rộng hơn để bắt trọn tất cả người chơi xung quanh
    AimPart = "Head"     -- Ghim thẳng vào Đầu
}

-- Hàm lấy Parent an toàn
local function getParent()
    local success, parent = pcall(function()
        if gethui then return gethui() end
        return game:GetService("CoreGui")
    end)
    if success and parent then return parent end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local TargetParent = getParent()

-- Tạo ScreenGui chính
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Aimbot_ESP_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.Parent = TargetParent

-- ==========================================
-- 1. VÒNG TRÒN FOV & TRACERS FOLDER
-- ==========================================
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.new(0, Settings.FOV_Size * 2, 0, Settings.FOV_Size * 2)
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Visible = Settings.ShowFOV
FOVCircle.Parent = ScreenGui

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Thickness = 1.5
FOVStroke.Parent = FOVCircle

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local TracersFolder = Instance.new("Folder")
TracersFolder.Name = "TracersFolder"
TracersFolder.Parent = ScreenGui

-- ==========================================
-- 2. GIAO DIỆN MENU BẬT / TẮT
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 200)
MainFrame.Position = UDim2.new(0.1, 0, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Title.Text = "   MENU AIMBOT & ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 13
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local function createToggle(text, yPos, settingKey, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Text = text .. ": OFF"
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        Settings[settingKey] = not Settings[settingKey]
        local isEnabled = Settings[settingKey]
        
        btn.Text = text .. ": " .. (isEnabled and "ON" or "OFF")
        btn.BackgroundColor3 = isEnabled and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(45, 45, 45)
        btn.TextColor3 = isEnabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        
        if callback then callback(isEnabled) end
    end)
end

createToggle("Aimbot (Ghim Đầu 100%)", 50, "Aimbot")
createToggle("ESP Định Vị (Tracer)", 95, "ESP_Tracers")
createToggle("Hiển Thị FOV", 140, "ShowFOV", function(val) FOVCircle.Visible = val end)

local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 120, 0, 35)
ToggleMenuBtn.Position = UDim2.new(0.02, 0, 0.1, 0)
ToggleMenuBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 210)
ToggleMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleMenuBtn.Text = "⚡ Ẩn/Hiện Menu"
ToggleMenuBtn.Font = Enum.Font.SourceSansBold
ToggleMenuBtn.TextSize = 13
ToggleMenuBtn.Active = true
ToggleMenuBtn.Draggable = true
ToggleMenuBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleMenuBtn).CornerRadius = UDim.new(0, 6)

ToggleMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- ==========================================
-- 3. HỆ THỐNG QUÉT VÀ GHIM ĐẦU CHÍNH XÁC 100%
-- ==========================================
local tracerLines = {}
local lockedTargetPart = nil 

local function getClosestHeadInFOV()
    local closestPart = nil
    local shortestDistance = Settings.FOV_Size
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local headPart = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and headPart then
                -- Lấy trực tiếp tọa độ màn hình của đầu nhân vật
                local screenPos, onScreen = Camera:WorldToViewportPoint(headPart.Position)
                
                -- Cho phép nhận diện ngay cả khi đang ở rìa màn hình
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

local function isCurrentTargetAlive(targetPart)
    if not targetPart or not targetPart.Parent then return false end
    local character = targetPart.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local headPart = character:FindFirstChild("Head")
    if not headPart then return false end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(headPart.Position)
    if not onScreen then return false end
    
    local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local distance = (Vector2.new(screenPos.X, screenPos.Y) - centerScreen).Magnitude
    
    -- Mở rộng biên độ giữ khóa để mục tiêu không bị tuột khi di chuyển nhanh
    if distance > (Settings.FOV_Size + 80) then return false end
    
    return true
end

-- ==========================================
-- 4. VÒNG LẶP XỬ LÝ CHÍNH
-- ==========================================
RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- AIMBOT GHIM CHẶT ĐẦU CỐ ĐỊNH CHO ĐẾN KHI CHẾT
    if Settings.Aimbot then
        if not isCurrentTargetAlive(lockedTargetPart) then
            lockedTargetPart = getClosestHeadInFOV()
        end
        
        if lockedTargetPart then
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, lockedTargetPart.Position)
        end
    else
        lockedTargetPart = nil 
    end

    -- ESP TRACER (Định vị toàn bộ người chơi)
    if Settings.ESP_Tracers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                
                if humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local line = tracerLines[player.Name]
                        if not line then
                            line = Instance.new("Frame")
                            line.AnchorPoint = Vector2.new(0.5, 0.5)
                            line.BackgroundColor3 = Color3.fromRGB(255, 50, 50) 
                            line.BorderSizePixel = 0
                            line.Parent = TracersFolder
                            tracerLines[player.Name] = line
                        end
                        
                        local centerScreen = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                        local targetScreen = Vector2.new(screenPos.X, screenPos.Y)
                        
                        local distance = (targetScreen - centerScreen).Magnitude
                        local angle = math.atan2(targetScreen.Y - centerScreen.Y, targetScreen.X - centerScreen.X)
                        
                        line.Size = UDim2.new(0, distance, 0, 1.5)
                        line.Position = UDim2.new(0, (centerScreen.X + targetScreen.X) / 2, 0, (centerScreen.Y + targetScreen.Y) / 2)
                        line.Rotation = math.deg(angle)
                        line.Visible = true
                    elseif tracerLines[player.Name] then
                        tracerLines[player.Name].Visible = false
                    end
                elseif tracerLines[player.Name] then
                    tracerLines[player.Name].Visible = false
                end
            else
                if tracerLines[player.Name] then
                    tracerLines[player.Name].Visible = false
                end
            end
        end
    else
        for _, line in pairs(tracerLines) do
            line.Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if tracerLines[player.Name] then
        tracerLines[player.Name]:Destroy()
        tracerLines[player.Name] = nil
    end
end)
