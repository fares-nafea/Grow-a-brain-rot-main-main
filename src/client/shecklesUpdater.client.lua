local Players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

repeat task.wait() until localPlayer:GetAttribute("DataLoaded") == true

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local root = mainGui:WaitForChild("Root")
local shecklesLabel = root:WaitForChild("Sheckles", math.huge)

local remotes = replicatedStorage:WaitForChild("Remotes", math.huge)

remotes.updateSheckles.OnClientEvent:Connect(function(shecklesAmount)
    shecklesLabel.Text = shecklesAmount.."$"
end)
