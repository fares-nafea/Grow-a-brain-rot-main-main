local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

repeat task.wait() until localPlayer:GetAttribute("DataLoaded") == true
-- تعريف
local leaderstats = localPlayer:WaitForChild("leaderstats", math.huge)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local root = mainGui:WaitForChild("Root")
local shecklesLabel = root:WaitForChild("Sheckles", math.huge)
-----------------------------------------------------------------------
local remotes = replicatedStorage:WaitForChild("Remotes", math.huge)

local mockValue = Instance.new("IntValue")
mockValue.Name = "MockSheckleCount"
mockValue.Value = 0

leaderstats.Sheckles.Changed:Connect(function()
    tweenService:Create(mockValue, TweenInfo.new(0.5 , Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Value = leaderstats.Sheckles.Value
    }):Play()
end)

mockValue.Changed:Connect(function()
    shecklesLabel.Text = mockValue.Value.."$"
end)
mockValue.Value = leaderstats.Sheckles.Value
shecklesLabel.Text = mockValue.Value.."$"

