-- GetMouseCF Listener

local players = game:GetService("Players")
local replicatdStorage = game:GetService("ReplicatedStorage")

local remotes = replicatdStorage:WaitForChild("Remotes")

local player = players.LocalPlayer
local mouse = player:GetMouse()

remotes.GetMouseCF.OnClientInvoke = function()
    return mouse.Hit
end