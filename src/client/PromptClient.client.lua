-- PromptClient

local Players = game:GetService("Players")
local proximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = Players.LocalPlayer
local playerGui: PlayerGui = localPlayer:WaitForChild("PlayerGui", math.huge)

local mainGui = playerGui:WaitForChild("MainGui")
local eventsFolder = mainGui:WaitForChild("Events")

proximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
    if prompt.Name == "SeedShopPrompt" then
        eventsFolder.ToggleSeedFrame:Fire(true)
    end
    if prompt.Name == "SellPrompt" then

    end
end)