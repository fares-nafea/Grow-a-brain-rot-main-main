-- PromptClient

local players = game:GetService("Players")
local proximityPromptService = game:GetService("ProximityPromptService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = players.LocalPlayer
local playerGui: PlayerGui = localPlayer:WaitForChild("PlayerGui", math.huge)

local remotes = replicatedStorage:WaitForChild("Remotes")

local mainGui = playerGui:WaitForChild("MainGui")
local eventsFolder = mainGui:WaitForChild("Events")

proximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	if prompt.Name == "HarvestPrompt" then
		local correspondingModel: ObjectValue = prompt:FindFirstChild("CorrespondingAdornee")
		if correspondingModel then
			script.HarvestHighlight.Adornee = correspondingModel.Value
		end
	end
end)
proximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
	if prompt.Name == "HarvestPrompt" then
		script.Highlight.Adornee = nil
	end
end)
proximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if prompt.Name == "SeedShopPrompt" then
		eventsFolder.ToggleSeedFrame:Fire(true)
	end
	if prompt.Name == "HarvestPrompt" then
		-- FireServer to Harvest Crop		
		local part = prompt.Parent
		if part and part.Parent and part.Parent.Name == "FruitPrompts" then
			-- MultiHarvest (True)
			local plantKey: string = part.Parent.Parent.Name
			local fruitNumber = part.Name			
			remotes.Harvest:FireServer(plantKey, fruitNumber)
		else
			-- SingleHarvest
			local plantKey = part.Parent.Name
			remotes.Harvest:FireServer(plantKey)
		end
	end
end)