-- SeedService

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local debris = game:GetService("Debris")
local httpService = game:GetService("HttpService")

local remotes = replicatedStorage.Remotes
local modules = replicatedStorage.Modules
local serverInfo = replicatedStorage.ServerInfo

local seedDataModule = require(modules.SeedData)
local cachedModules = require(script.Parent.Parent.Server.CachedModules)

local Service = {
	DEFAULT_RESTOCK_TIME = 5,
}

function Service.getRandomPlantSize(name: string, extraData: any)
	return Random.new():NextNumber(1,3)
end
function Service.getRandomFruitSize(name: string, extraData: any)
	if name == "Carrot Seed" then
		return 1
	end
	return Random.new():NextNumber(1,3)
end
function Service.generateKey(prefix: string)
	return prefix..":"..string.sub(httpService:GenerateGUID(false),1,5)
	-- "Carrot:12kd5"
end
function Service.isCloseToPlant(referencePoint: Part, plotData: any, locationToPlant: CFrame, magnitudeThreshold: number)
	if plotData and locationToPlant and magnitudeThreshold and referencePoint then
		for plantKey: string, data: any in plotData do
			-- Converting Saved Location to World Location for Checking
			local location = CFrame.new( table.unpack(data.Location) )
			location = referencePoint.CFrame:ToWorldSpace(location)
			--
			
			local distance = (location.Position - locationToPlant.Position).Magnitude
			if distance <= magnitudeThreshold then
				return true
			end
		end
	end
	return false
end
function Service.plantSeed(player: Player, seedName: string, location: CFrame, plantScaling: number)
	local character = player.Character
	
	if player and seedName and location and character then
		local dataService = cachedModules.Cache.DataService
		local inventoryService = cachedModules.Cache.InventoryService
		local plotService = cachedModules.Cache.PlotService
		
		local seedData = seedDataModule.getData(seedName)
		local playerData = dataService.getData(player)
		
		if playerData and seedData then
			-- Checking for Tool in Character
			local currentTool = character:FindFirstChildWhichIsA("Tool")
			if currentTool and currentTool:GetAttribute("isSeed") == true and currentTool:GetAttribute("trueName") == seedName then
				-- Checking for Seed in Inventory
				local inventory = playerData.Inventory
				local foundSeed = inventory[seedName]
				
				if foundSeed then
					if player:FindFirstChild("PlantDebounce") then
						return
					end
					
					local debounce = Instance.new("Folder")
					debounce.Name = "PlantDebounce"
					debounce.Parent = player
					debris:AddItem(debounce, .5)
					
					local plotData = playerData.PlotData
					-- Checking if too close to another plant
					local isTooClose = Service.isCloseToPlant(
						plotService.getPlot(player).ReferencePoint,
						plotData,
						location,
						2.5
					)
					
					if isTooClose then
						-- Notify Too Close
						return
					end
					
					-- Reduce Seeds
					inventoryService.removeItem(player, seedName, 1)
					--
					
					-- Changing Location to be relative to the Plot's ReferencePoint CFrame
					local locationToSave: CFrame = plotService.getPlot(player).ReferencePoint.CFrame:ToObjectSpace(location)
					
					-- Generating PlantKey
					local key = Service.generateKey(seedData.SeedPrefix.Value)
					
					local fruitsArray = {}
					for i = 1, seedData.HarvestCount.Value do
						fruitsArray[i] = {
							CanHarvest = false, 
							LastHarvest = os.time(), 
							Mutations = "",
							SizeScaling = Service.getRandomFruitSize(seedName, {})
						}
					end
					
					plotData[key] = {
						GrowthPercentage = 0,
						LastGrowthIncrement = os.time(),
						DatePlanted = os.time(),
						Location = { locationToSave:GetComponents() },
						Fruits = fruitsArray,
						["PlantSize"] = plantScaling or 1
					}
					
					-- PlantEffect
					task.spawn(function()
						-- Raycasting Down to the Ground
						local rightPlot = plotService.getPlot(player):FindFirstChild("RightSoil")
						if rightPlot then
							local params = RaycastParams.new()
							params.FilterType = Enum.RaycastFilterType.Include
							params.FilterDescendantsInstances = {rightPlot}
							local result = workspace:Raycast(location.Position+Vector3.new(0,5,0), Vector3.new(0,-999999,0), params)
							if result then
								remotes.ClientEffects:FireAllClients("PlantEffect", {Location = CFrame.new(result.Position)})
							end
						end
					end)
					
					-- Updating Plot
					plotService.updatePlot(player, "seedPlanted", {itemKey = key})
				end
			end
		end
	end
end
function Service.giveSeed(player: Player, seedName: string, amount: number, reduceStock: boolean)
	local inventoryService = cachedModules.Cache.InventoryService
	
	if player and seedName then
		-- Give the [player] the [seedName]
		local seedData = seedDataModule.getData(seedName)
		local playerData = cachedModules.Cache.DataService.getData(player)
		if playerData and seedData then
			local inventory = playerData.Inventory
			local foundSeed = inventory[seedName]
			
			if reduceStock == true then
				-- Reduce
				seedData.Server.CurrentStock.Value = math.clamp(
					seedData.Server.CurrentStock.Value-amount,
					0,
					seedData.Server.MaxStock.Value
				)
			end
			
			if foundSeed then
				foundSeed.Count += amount
			else
				inventory[seedName] = {Count = amount}
			end
			inventoryService.inventoryUpdated(player, seedName)
		end
	end
end
function Service.restockSeeds(data: any)
	if data then
		if data.resetTimer then
			-- Reset Timer
			serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
		end
	end
	-- Restocking
	
	for _, seedName: string in seedDataModule.getSeedOrder() do
		local seedData = seedDataModule.getData(seedName)
		if seedData then
			local countToAdd = seedDataModule.getStockIncrement(seedName)
			seedData.Server.CurrentStock.Value = math.clamp(
				seedData.Server.CurrentStock.Value+countToAdd,
				0,
				seedData.Server.MaxStock.Value
			)
		end
	end
	--
end
function Service.init()
	local dataService = cachedModules.Cache.DataService
	local moneyService = cachedModules.Cache.MoneyService
	
	-- Handling RemoteEvents
	remotes.BuySeed.OnServerEvent:Connect(function(player, seedName: string)
		if player:GetAttribute("DataLoaded") ~= true then return end
		
		local playerData = dataService.getData(player)
		if not playerData then return end
		
		local seedData = seedDataModule.getData(seedName)
		if seedData then
			-- Checking if inStock
			if seedData.Server.CurrentStock.Value <= 0 then
				return
			end
			-- Checking if has enough money
			if playerData.Sheckles < seedData.Cost.Value then
				return
			end
			
			-- Buy the Seed
			moneyService.giveMoney(player, -seedData.Cost.Value)
			Service.giveSeed(player, seedName, 1, true)
		end
	end)
	
	-- Restocking Timer
	serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
	task.spawn(function()
		while true do
			if serverInfo.SEED_RESTOCK_TIMER.Value <= 0 then
				-- Restock Seeds
				Service.restockSeeds()
				
				--print(seedDataModule.cachedModules)
				
				-- Reset Timer
				serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
			else
				serverInfo.SEED_RESTOCK_TIMER.Value -= 1
			end
			task.wait(1)
		end
	end)
	-----
end

return Service