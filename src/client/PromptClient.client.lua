-- PromptClient

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local mainGui = playerGui:WaitForChild("MainGui", 10)


local eventsFolder = mainGui:WaitForChild("Events")

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
    if prompt.Name == "SeedShopPrompt" then
        eventsFolder.ToggleSeedFrame:Fire(true)
    end
end)
