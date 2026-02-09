-- PromptClient

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("players")
local proximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = players.LocalPlayer
local playerGui: PlayerGui = localPlayer:WaitForChild("playerGui", math.huge)

local mainGui = playerGui:WaitForChild("MainGui")
local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local ToggleSeedFrame = eventsFolder:WaitForChild("ToggleSeedFrame")

proximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
    if prompt.Name == "SeedShopPrompt" then
        eventsFolder.ToggleSeedFrame:Fire()
    end
    if prompt.Name == "SellPrompt" then
    end
end)