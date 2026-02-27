local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local seedStorage = game.ServerStorage:WaitForChild("Seeds")

local Service = {
	cachedModules = {},
}

function Service.inventoryUpdated(player: Player, seedName: string)

	local dataService = Service.cachedModules.DataService
	if not dataService then return end

	local playerData = dataService.getData(player)
	if not playerData then return end

	local inventory = playerData.Inventory
	local seedData = inventory[seedName]
	if not seedData then return end

	local backpack = player:WaitForChild("Backpack")
	local seedTemplate = seedStorage:FindFirstChild(seedName)
	if not seedTemplate then return end

	local tool = nil

	for _, t in ipairs(backpack:GetChildren()) do
		if t:IsA("Tool") and t:GetAttribute("trueName") == seedName then
			tool = t
			break
		end
	end

	if not tool then
		tool = seedTemplate:Clone()
		tool:SetAttribute("trueName", seedName)
		tool.Parent = backpack
	end

	tool.Name = seedName .. " (X" .. tostring(seedData.Count) .. ")"
end

function Service.characterAdded(character: Model)

	local player = players:GetPlayerFromCharacter(character)
	if not player then return end

	local dataService = Service.cachedModules.DataService
	if not dataService then return end

	local playerData = dataService.getData(player)
	if not playerData then return end

	local backpack = player:WaitForChild("Backpack")

	for seedName, data in pairs(playerData.Inventory) do
		if data.Count > 0 then

			local toolExists = false

			for _, t in ipairs(backpack:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("trueName") == seedName then
					toolExists = true
					break
				end
			end

			if not toolExists then
				local seedTemplate = seedStorage:FindFirstChild(seedName)
				if seedTemplate then
					local toolClone = seedTemplate:Clone()
					toolClone:SetAttribute("trueName", seedName)
					toolClone.Name = seedName .. " (X" .. tostring(data.Count) .. ")"
					toolClone.Parent = backpack
				end
			end
		end
	end
end

function Service.init()

	local function setupPlayer(player)
		if player.Character then
			Service.characterAdded(player.Character)
		end

		player.CharacterAdded:Connect(Service.characterAdded)
	end

	for _, player in ipairs(players:GetPlayers()) do
		setupPlayer(player)
	end

	players.PlayerAdded:Connect(setupPlayer)
end

return Service