-- Button TPs

local players = game:GetService("Players")

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart: BasePart = character:WaitForChild("HumanoidRootPart", math.huge)

local gui = script.Parent

local root = gui:WaitForChild("Root", math.huge)
local gardenTPFrame = root.GardenTp
local seedsTPFrame = root.SeedsTP
local sellTPFrame = root.SellTP

repeat task.wait() until player:GetAttribute("DataLoaded") == true

gardenTPFrame.Button.MouseButton1Click:Connect(function()
    for _, plot: Model in workspace.World.Map.Plots:GetChildren() do
        if plot:GetAttribute("Taken") == true and plot:GetAttribute("Owner") == player.UserId then
            -- teleport here
            character:SetPrimaryPartCFrame(plot.TPPart.CFrame)
            return
        end
    end
end)