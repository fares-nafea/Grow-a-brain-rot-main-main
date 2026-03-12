-- InventoryService

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local httpService = game:GetService("HttpService")

local remotes = replicatedStorage.Remotes
local modules = replicatedStorage.Modules
local assets = replicatedStorage.Assets

local serverInfo = replicatedStorage.ServerInfo

local seedDataModule = require(modules.SeedData)
local seedStorage = game.ServerStorage.Seeds
local cachedModules = require(script.Parent.Parent.Server.CachedModules)
local fruitNameParser = require(modules.FruitNameParse)

local function roundToHundredth(num)
	return math.floor(num * 100 + 0.5) / 100
end

local Service = {}

function Service.generateFruitKey(fruitName: string)
	return fruitName..":"..string.sub((httpService:GenerateGUID(false)),1,8)
end
function Service.giveFruit(target: Player, fruitName: string, fruitAttributes: any)
	local dataService = cachedModules.Cache.DataService

	local seedData = seedDataModule.getData(fruitName.. " Seed")

	if target and fruitName and fruitAttributes and seedData then
		local targetData = dataService.getData(target)
		if not targetData then return end

		local playerInventory = targetData.Inventory
		--[[
			CropName:
			[Twilight, Golden, Rainbow] Blueberry [5.82kg]
		]]

		local mutations = fruitAttributes.Mutations
		local fruitSize = fruitAttributes.FruitSize
		local overallSize = fruitAttributes.OverallPlantSize

		-- Rounding to Nearest Hundredth
		local sizeToSave = 1 
		if seedData.MultiHarvest.Value then
			-- If MultiHarvest is true, different Fruits have different sizes!
			sizeToSave = roundToHundredth(fruitSize)
		else
			-- If MultiHarvest is set to false, there is only ONE fruit size for the entire plant!
			sizeToSave = roundToHundredth(overallSize)
		end

		local stringToSave = ""
		if mutations ~= "" then
			stringToSave = "["..mutations.."]"
			stringToSave = stringToSave.. " "..fruitName.." ["..tostring(sizeToSave).."kg]"
		else
			stringToSave = fruitName.." ["..tostring(sizeToSave).."kg]"
		end

		print(target, "Add Fruit To Inventory", stringToSave)

		local fruitKey = Service.generateFruitKey(fruitName)

		playerInventory[fruitKey] = stringToSave
		Service.inventoryUpdated(target, fruitKey)
	end
end
function Service.removeItem(player: Player, itemName: string, count: number)
	if player and itemName and count then
		local dataService = cachedModules.Cache.DataService

		local playerData = dataService.getData(player)

		if playerData then
			local inventory = playerData.Inventory
			local foundItem = inventory[itemName]

			if foundItem then

				local removeItem = false

				if foundItem.Count then
					-- Increment Down
					foundItem.Count = math.clamp(foundItem.Count-1,0,math.huge)
					if foundItem.Count <= 0 then
						removeItem = true
					else
						-- Update In Backpack
						Service.inventoryUpdated(player, itemName)
					end
				else
					removeItem = true
				end

				if removeItem then
					-- Removing from Inventory
					inventory[itemName] = nil

					-- Looping through backpack to check
					local backpack = player.Backpack

					local isSeed = seedStorage:FindFirstChild(itemName)
					if isSeed then
						for _,v in backpack:GetChildren() do
							if v:GetAttribute("isSeed") == true and v:GetAttribute("trueName") == itemName then
								-- Destroy
								v:Destroy()
								break
							end
						end
					else
						-- Addd Functionality for Gear Ltaer
						for _,v in backpack:GetChildren() do
							if v.Name == itemName or v:GetAttribute("fruitID") == itemName then
								v:Destroy()
							end
						end
					end

					-- Looping through character
					local tool = player.Character:FindFirstChildWhichIsA("Tool")
					if tool then
						if isSeed and tool:GetAttribute("isSeed") == true and tool:GetAttribute("trueName") == itemName then
							tool:Destroy()
						else
							-- Add Diff. Functionality Later
							if tool.Name == itemName or tool:GetAttribute("fruitID") == itemName then tool:Destroy() end
						end
					end		
				end
			end
		end
	end
end
function Service.createNewTool(player: Player, toolName: string)
	local dataService = cachedModules.Cache.DataService
	local playerData = dataService.getData(player)

	if playerData then
		local inventory = playerData.Inventory
		local itemData = inventory[toolName]

		if itemData then
			-- SEEDS
			local isSeed = game.ServerStorage.Seeds:FindFirstChild(toolName)
			if isSeed then
				local toolClone = isSeed:Clone()
				toolClone.Name = toolName.. " (X"..tostring(itemData.Count)..")"
				toolClone:SetAttribute("isSeed", true)
				toolClone:SetAttribute("trueName", toolName)
				local activator = script.SeedActivator:Clone()
				activator.Parent = toolClone
				toolClone.Parent = player.Backpack
				require(activator)
			else
				-- FRUITS
				local mutations: any, weight: number, fruitName: string = fruitNameParser(itemData)				
				if mutations and weight>0 and fruitName then
					-- Valid Fruit
					local foundTool = replicatedStorage.Assets.Crops:FindFirstChild(fruitName)
					if foundTool then
						local toolClone: Tool = foundTool:Clone()
						toolClone.Name = itemData
						toolClone:SetAttribute("fruitID", toolName)
						toolClone:SetAttribute("isFruit", true)

						-- Scaling Based on Weight
						for _, part in ipairs(toolClone:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Size *= weight

								local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
								if mesh then
									mesh.Scale *= weight
								end
							end
						end
						-- Scale all Welds and Motor6Ds (position offsets)
						local function scaleCFrame(cf, scaleFactor)
							local pos, rot = cf.Position, cf - cf.Position
							return CFrame.new(pos * scaleFactor) * rot
						end
						for _, weld in ipairs(toolClone:GetDescendants()) do
							if weld:IsA("Weld") or weld:IsA("Motor6D") then
								weld.C0 = scaleCFrame(weld.C0, weight)
								weld.C1 = scaleCFrame(weld.C1, weight)
							end
						end
						if toolClone:FindFirstChild("Handle") then
							local modelTemplate = replicatedStorage.Assets.Plants[fruitName]["ClientModel"]
							if modelTemplate then
								local _, size = modelTemplate:GetBoundingBox()
								local longestAxis = math.max(size.X, size.Y, size.Z)
								toolClone.GripPos = Vector3.new(0, 0, longestAxis * 0.125)
							end
						end
						toolClone.Parent = player.Backpack
					end
				end
			end
		end
	end
end
function Service.inventoryUpdated(player: Player, ...)
	local dataService = cachedModules.Cache.DataService

	local playerData = dataService.getData(player)

	if playerData then
		local inventory = playerData.Inventory

		local arguments = {...}
		for _, itemUpdated in arguments do
			local foundItemInInventory = inventory[itemUpdated]			
			if foundItemInInventory then

				-- CHECKING IF SEED
				local isSeed = seedStorage:FindFirstChild(itemUpdated)
				if isSeed then
					local foundItem = nil
					-- Checking in the backpack
					for _, v in player.Backpack:GetChildren() do
						if v:IsA("Tool") and v:GetAttribute("trueName") == itemUpdated then
							foundItem = v
						end
					end
					local tool = player.Character:FindFirstChildWhichIsA("Tool")
					if tool and tool:GetAttribute("trueName") == itemUpdated then
						foundItem = tool
					end
					if foundItem then
						foundItem.Name = itemUpdated.." (X"..tostring(foundItemInInventory.Count)..")"
					else
						Service.createNewTool(player, itemUpdated)
					end
					continue
				end

				-- CHECKING IF GEAR OR OTHER BLAH BLAH
				if player.Character:FindFirstChild(itemUpdated) or player.Backpack:FindFirstChild(itemUpdated) then
					-- Ignore
				else
					Service.createNewTool(player, itemUpdated)
				end
			end
		end		
	end
end
function Service.characterAdded(character: Model)
	local player = players:GetPlayerFromCharacter(character)

	local dataService = cachedModules.Cache.DataService
	local playerData = dataService.getData(player)

	if playerData then
		-- Load In The Tools
		for itemName: string, data: any in playerData.Inventory do
			Service.createNewTool(player, itemName)
		end
	end
end
function Service.init()

end

return Service