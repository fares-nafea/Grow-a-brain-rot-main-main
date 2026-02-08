local Players = game:GetService("Players")
local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local rootPart: BasePart = character:WaitForChild("HumanoidRootPart", math.huge)

local gardenTPFrame = player:WaitForChild("PlayerGui")
    :WaitForChild("MainGui")
    :WaitForChild("Root")
    :WaitForChild("GardenTP")
    :WaitForChild("Button")

local SellTPFrame = player:WaitForChild("PlayerGui")
    :WaitForChild("MainGui")
    :WaitForChild("Root")
    :WaitForChild("SellTP")
    :WaitForChild("Button")

local SeedsTPFrame = player:WaitForChild("PlayerGui")
    :WaitForChild("MainGui")
    :WaitForChild("Root")
    :WaitForChild("SeedsTP")
    :WaitForChild("Button")

gardenTPFrame.MouseButton1Click:Connect(function()
    for _, plot: Model in pairs(workspace.World.Map.Plots:GetChildren()) do
        if plot:GetAttribute("Taken") == true and plot:GetAttribute("Owner") == player.UserId then
            local TPpart = plot:WaitForChild("TPpart")
            -- teleport here
            character:SetPrimaryPartCFrame(TPpart.CFrame)
        end
    end
end)

SellTPFrame.MouseButton1Click:Connect(function()
    character:SetPrimaryPartCFrame(workspace.World.Map.Stands.SellStuff.TPpart.CFrame)
end)

SeedsTPFrame.MouseButton1Click:Connect(function()
    character:SetPrimaryPartCFrame(workspace.World.Map.Stands.SeedShop.TPpart.CFrame)
end)