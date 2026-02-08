-- Button TPs

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart: BasePart = character:WaitForChild("HumanoidRootPart")

local gui = script.Parent

local root = gui:WaitForChild("Root", math.huge)
local gardenTPFrame = root:WaitForChild("GardenTP")
local seedsTPFrame = root:WaitForChild("SeedsTP")
local sellTPFrame = root:WaitForChild("SellTP")

repeat task.wait() until player:GetAttribute("DataLoaded") == true

gardenTPFrame.Button.MouseButton1Click:Connect(function()
    for _, plot: Model in workspace.World.Map.Plots:GetChildren() do
        if plot:GetAttribute("Taken") == true and plot:GetAttribute("Owner") == player.UserId then
            -- teleport here
            character:SetPrimaryPartCFrame(plot.TPpart.CFrame)
        end
    end
end)
