-- GetMouseCF Listener

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")

local player = players.LocalPlayer
local mouse = player:GetMouse()

remotes.GetMouseCF.OnClientInvoke = function()
	return mouse.Hit
end