-- shecklesUpdater

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local localPlayer = players.LocalPlayer

repeat task.wait() until localPlayer:GetAttribute("DataLoaded") == true

local leaderstats = localPlayer:WaitForChild("leaderstats", math.huge)

local gui = script.Parent
local root = gui:WaitForChild("Root", math.huge)
local shecklesLabel = root.Sheckles

local remotes = replicatedStorage:WaitForChild("Remotes", math.huge)

local mockValue = Instance.new("IntValue")
mockValue.Name = "MockSheckleCount"
mockValue.Value = 0

leaderstats.Sheckles.Changed:Connect(function()
	tweenService:Create(mockValue, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Value = leaderstats.Sheckles.Value
	}):Play()
end)
mockValue.Changed:Connect(function()
	shecklesLabel.Text = mockValue.Value.."$"
end)
mockValue.Value = leaderstats.Sheckles.Value
shecklesLabel.Text = mockValue.Value.."$"