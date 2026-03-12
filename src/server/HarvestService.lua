-- HarvestService

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

local remotes = replicatedStorage.Remotes
local assets = replicatedStorage.Assets
local modules = replicatedStorage.Modules

local Service = {}

local cachedModules = require(script.Parent.Parent.Server.CachedModules)
local seedDataModule = require(modules.SeedData)

local serverFolder = workspace.World.Map.PlantedSeeds.Server

function Service.isWithinHarvestBounds(character: Model, part: Instance, magnitudeThreshold: number)
	if character and part and magnitudeThreshold then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local distance = (rootPart.Position-part.Position).Magnitude			
			if distance <= magnitudeThreshold then
				return true
			end
		end
	end
	return false
end
function Service.Harvest(ownerPlotData: any, player: Player, foundPlant: Model, fruitNumber: string, multiHarvest: boolean)
	local inventoryService = cachedModules.Cache.InventoryService
	--[[
		Service.Harvest() can be used to steal fruits too
	]]
	-- Assuming Most Preliminary Checks are done
	
	local fruitName = foundPlant.Name:split(":")[1]
	local serverConfiguration = foundPlant.ServerConfiguration
		
	if multiHarvest then
		-- Is Valid MultiHarvest

		-- Checking Harvest Distance, Sanity Checks | Prevent Exploits
		local prompt: ProximityPrompt = foundPlant.FruitPrompts[fruitNumber].HarvestPrompt
		if not Service.isWithinHarvestBounds(player.Character, foundPlant.FruitPrompts[fruitNumber], prompt.MaxActivationDistance) then
			return
		end
		
		-- Harvest Fruit
		local fruitFolder: Folder = serverConfiguration.Fruits:FindFirstChild(fruitNumber)
		if fruitFolder then
			if not fruitFolder.CanHarvest.Value then return end -- Can't Harvest
			
			if player.UserId == foundPlant:GetAttribute("Owner") then
				-- Owner Collecting
				inventoryService.giveFruit(
					player, 
					fruitName,
					{
						Mutations = fruitFolder.Mutations.Value,
						FruitSize = fruitFolder.SizeScaling.Value,
						OverallPlantSize = serverConfiguration.PlantSize.Value
					}
				)
			else
				-- Stealing, Add in Functionality Later
				
				return -- REMOVE RETURN AFTER ADDING IN
			end
			
			fruitFolder.SizeScaling.Value = 1
			fruitFolder.Mutations.Value = ""
			fruitFolder.CanHarvest.Value = false
			fruitFolder.LastHarvest.Value = os.time()
		end
	else
		-- Single Harvest
		if fruitNumber then return end
		local prompt: ProximityPrompt = foundPlant.PrimaryPart.HarvestPrompt
		if not Service.isWithinHarvestBounds(player.Character, foundPlant.PrimaryPart, prompt.MaxActivationDistance) then
			return
		end
		
		local fruitFolder = serverConfiguration.Fruits["1"]
		
		if player.UserId == foundPlant:GetAttribute("Owner") then
			-- Owner Collecting
			inventoryService.giveFruit(
				player, 
				fruitName,
				{
					Mutations = fruitFolder.Mutations.Value,
					FruitSize = fruitFolder.SizeScaling.Value,
					OverallPlantSize = serverConfiguration.PlantSize.Value
				}
			)
		else
			-- Stealing, Add in Functionality Later
			
			return -- REMOVE RETURN AFTER ADDING IN
		end

		fruitFolder.CanHarvest.Value = false
		fruitFolder.LastHarvest.Value = os.time()
		
		-- Destroying Model, Removing From Owner PlotData
		ownerPlotData[foundPlant.Name] = nil
		foundPlant:Destroy()
	end
end
function Service.init()
	-- [Harvest] Event
	local dataService = cachedModules.Cache.DataService
	
	remotes.Harvest.OnServerEvent:Connect(function(player: Player, plantKey: string, fruitNumber: string)		
		local foundPlant = serverFolder:FindFirstChild(plantKey)
		local seedData = seedDataModule.getData(plantKey:split(":")[1].. " Seed")
		
		if foundPlant and seedData then
			local owner = foundPlant:GetAttribute("Owner")
			local ownerPlayer = players:GetPlayerByUserId(owner)
			
			if ownerPlayer then
				local ownerData = dataService.getData(ownerPlayer)
				
				if ownerData then
					local foundPlantData = ownerData.PlotData[plantKey]
					local serverConfiguration = foundPlant:FindFirstChild("ServerConfiguration")
					
					if foundPlantData and serverConfiguration then
						if serverConfiguration.GrowthPercentage.Value < 100 then return end -- Not Fully Grown Yet lol
						
						if seedData.MultiHarvest.Value and fruitNumber and foundPlant.FruitPrompts:FindFirstChild(fruitNumber) then
							Service.Harvest(ownerData.PlotData, player, foundPlant, fruitNumber, seedData.MultiHarvest.Value)
							return
						end
						if not seedData.MultiHarvest.Value then
							-- SingleHarvest, Destroy Afterwards
							Service.Harvest(ownerData.PlotData, player, foundPlant, fruitNumber, seedData.MultiHarvest.Value)
						end
					end
				end
			end
		end
	end)
end

return Service