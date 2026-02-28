-- GetMouseCF Listener

local players = game:GetService("Players")
local replicatdStorage = game:GetService("ReplicatdStorage")

local remotes = replicatdStorage:WaitForChild("Remotes")

local player = players.LocalPlayer
local mouse = player:GetMouse()

remotes.GetMouseCF.onClientInvoke = function()
    return mouse.Hit
end