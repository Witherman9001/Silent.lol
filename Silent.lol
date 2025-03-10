local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CamLockEnabled = false
local CurrentTarget = nil

getgenv().Rake = {
    Settings = {
        AimPart = "HumanoidRootPart",
        Prediction = { -- Set-based Prediction Values
            Close = 0.131,
            Mid = 0.1201,
            Far = 0.1912
        }
    }
}

local function getPrediction(target)
    if not target then return 0 end
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - target.Position).Magnitude
    if distance < 50 then
        return getgenv().Rake.Settings.Prediction.Close
    elseif distance < 150 then
        return getgenv().Rake.Settings.Prediction.Mid
    else
        return getgenv().Rake.Settings.Prediction.Far
    end
end

local function findNearestEnemy()
    local ClosestDistance, ClosestPlayer, ClosestPart = math.huge, nil, nil
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            local Character = Player.Character
            if Character and Character:FindFirstChild("Humanoid") and Character.Humanoid.Health > 0 then
                local Part = Character:FindFirstChild(getgenv().Rake.Settings.AimPart)
                if Part then
                    local Distance = (LocalPlayer.Character[getgenv().Rake.Settings.AimPart].Position - Part.Position).Magnitude
                    if Distance < ClosestDistance then
                        ClosestPlayer = Player
                        ClosestPart = Part
                        ClosestDistance = Distance
                    end
                end
            end
        end
    end
    return ClosestPlayer, ClosestPart
end

-- GUI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "Silent.lol"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 180, 0, 80)
Frame.Position = UDim2.new(0.4, 0, 0.6, 0)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Button = Instance.new("TextButton", Frame)
Button.Size = UDim2.new(1, -20, 0, 40)
Button.Position = UDim2.new(0, 10, 0.5, -20)
Button.Text = "Toggle Silent.lol"
Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 18
Button.BorderSizePixel = 0
Button.TextColor3 = Color3.fromRGB(255, 255, 255)

local UICornerBtn = Instance.new("UICorner", Button)
UICornerBtn.CornerRadius = UDim.new(0, 8)

-- Rainbow Circle
local Circle = Drawing.new("Circle")
Circle.Radius = 10
Circle.Filled = false
Circle.Thickness = 2
Circle.Visible = false

Button.MouseButton1Click:Connect(function()
    CamLockEnabled = not CamLockEnabled
    CurrentTarget = CamLockEnabled and select(2, findNearestEnemy())
    Button.Text = CamLockEnabled and "Silent.Lol ON" or "Silent.lol OFF"
    Circle.Visible = CamLockEnabled and CurrentTarget ~= nil
end)

local mt = getrawmetatable(game)
local old = mt.__index
setreadonly(mt, false)

old = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and typeof(self) == "Instance" and self:IsA("Mouse") and key == "Hit" then
        if CamLockEnabled and CurrentTarget then
            local prediction = getPrediction(CurrentTarget)
            local targetPos = CurrentTarget.Position + (CurrentTarget.Velocity * prediction)
            return CFrame.new(targetPos)
        end
    end
    return old(self, key)
end)

RunService.RenderStepped:Connect(function()
    local t = tick() * 2
    local rainbowColor = Color3.fromHSV((t % 1), 1, 1)

    Button.TextColor3 = rainbowColor

    if CamLockEnabled and CurrentTarget then
        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, CurrentTarget.Position)

        local screenPos, onScreen = Camera:WorldToViewportPoint(CurrentTarget.Position)
        if onScreen then
            Circle.Color = rainbowColor
            Circle.Position = Vector2.new(screenPos.X, screenPos.Y)
            Circle.Visible = true
        else
            Circle.Visible = false
        end
    else
        Circle.Visible = false
    end
end)
