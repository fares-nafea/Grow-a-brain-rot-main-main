-- Button TPs

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")

local gui = script.Parent
local root = gui:WaitForChild("Root", 5)
if not root then return end  -- لو Root مش موجود بعد 5 ثواني، يوقف السكريبت

local gardenTPFrame = root:WaitForChild("GardenTP", 5)
if not gardenTPFrame then return end

repeat task.wait() until player:GetAttribute("DataLoaded") == true

local character = player.Character or player.CharacterAdded:Wait()
local rootPart: BasePart = character:WaitForChild("HumanoidRootPart")

gardenTPFrame.Button.MouseButton1Click:Connect(function()
    for _, plot: Model in ipairs(workspace.World.Map.Plots:GetChildren()) do
        if plot:GetAttribute("Taken") == true and plot:GetAttribute("Owner") == player.UserId then
            local tpPart: BasePart = plot:WaitForChild("TPpart")
            rootPart.CFrame = tpPart.CFrame
            return
        end
    end
end)
