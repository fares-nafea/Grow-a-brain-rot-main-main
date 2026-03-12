-- CropReplicator

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local player = players.LocalPlayer

local assets = replicatedStorage:WaitForChild("Assets")
local modules = replicatedStorage:WaitForChild("Modules")

local seedModule = require(modules.SeedData)
local plantsFolder = assets.Plants

local world = workspace:WaitForChild("World", math.huge)
local plantedSeeds = world.Map.PlantedSeeds
local clientFolder = plantedSeeds.Client
local serverFolder = plantedSeeds.Server

repeat task.wait() until player:GetAttribute("DataLoaded") == true

task.wait(1)

local function harvestableChanged(serverModel: Model, clientModel: Model, fruitNumber: string, harvestable: boolean, multiHarvest: boolean)
	task.spawn(function()
		if harvestable == true then
			if clientModel:GetAttribute("FullyGrown") == false then
				repeat task.wait() until clientModel:GetAttribute("FullyGrown") == true
			end
			-- Enabling Prmopt
			task.spawn(function()
				if multiHarvest then
					serverModel.FruitPrompts[fruitNumber].HarvestPrompt.Enabled = true
				else
					serverModel["PrimaryPart"].HarvestPrompt.Enabled = true
				end
			end)
			task.spawn(function()
				for _,v in clientModel:GetDescendants() do
					local isTweened = v:GetAttribute("IsTweened")
					local originalSize = v:GetAttribute("OriginalSize")
					local originalCFrame = v:GetAttribute("OriginalCFrame")
					if isTweened ~= nil and originalSize then
						if isTweened then
							continue
						end
						if v:GetAttribute("FruitNumber") == tonumber(fruitNumber) then
							v:SetAttribute("IsTweened", true)
							tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
								Size = originalSize,
								["CFrame"] = originalCFrame,
								Transparency = 0
							}):Play()
						end
					end
				end
			end)
		end
	end)
end
local function growthPercentageUpdate(clientModel: Model, newValue: number)
	task.spawn(function()
		for _,v in clientModel:GetDescendants() do
			local isTweened = v:GetAttribute("IsTweened")
			local originalSize = v:GetAttribute("OriginalSize")
			local appearPercentage = v:GetAttribute("AppearPercentage")
			local originalCFrame = v:GetAttribute("OriginalCFrame")

			task.spawn(function()
				if isTweened ~= nil and originalSize and appearPercentage then
					if isTweened == false then
						if newValue >= appearPercentage then
							v:SetAttribute("IsTweened", true)
							tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
								Size = originalSize,
								["CFrame"] = originalCFrame,
								Transparency = 0
							}):Play()
						end
					end
				end
			end)
			task.wait(.05)
		end
		if newValue >= 100 then
			clientModel:SetAttribute("FullyGrown", true)
		end
	end)
end
local function childAdded(child: Instance)
	local identifier = child.Name

	if not clientFolder:FindFirstChild(identifier) then
		local trueName = identifier:split(":")[1]
		local foundModel = plantsFolder:FindFirstChild(trueName)

		if foundModel then
			local clientModel: Model = foundModel.ClientModel:Clone()
			clientModel.Name = identifier

			clientModel:ScaleTo(child.ServerConfiguration.PlantSize.Value)

			clientModel:PivotTo(child:GetPivot())

			-- Default Visibilty of Parts
			clientModel:SetAttribute("FullyGrown", false)
			for _,v in clientModel:GetDescendants() do
				local s,e = pcall(function()
					local t = v.Transparency
				end)
				if s then
					v.Transparency = 1
					v:SetAttribute("OriginalSize", v.Size)
					v:SetAttribute("OriginalCFrame", v.CFrame)
					v:SetAttribute("IsTweened", false)
					v.Size = Vector3.new(.01,.01,.01)
					v.CFrame = clientModel:GetPivot()
				end
			end

			clientModel.Parent = clientFolder

			-- Handling Client Visuals
			local serverConfig = child:FindFirstChild("ServerConfiguration")
			if serverConfig then
				-- Handling Growth Percentade
				local growthPercentage = serverConfig:WaitForChild("GrowthPercentage", math.huge)
				growthPercentage.Changed:Connect(function()
					growthPercentageUpdate(clientModel, growthPercentage.Value)
				end)
				growthPercentageUpdate(clientModel, growthPercentage.Value)

				local seed_data = seedModule.getData(trueName.. " Seed")

				-- Handling Harvest Visual
				if seed_data then
					local fruitsFolder = serverConfig.Fruits
					for _,v in fruitsFolder:GetChildren() do
						-- Handling Visiblity of Prompts
						local canHarvest = v:FindFirstChild("CanHarvest")
						if canHarvest ~= nil then
							canHarvest.Changed:Connect(function()								
							harvestableChanged(trueName, child, clientModel, v.Name, canHarvest.Value, seed_data.MultiHarvest.Value)
						    end)
						end
						if canHarvest.Value then
							harvestableChanged(trueName, child, clientModel, v.Name, canHarvest.Value, seed_data.MultiHarvest.Value)
						end
					end
				end
			end
		end
	end
end
local function childRemoved(child: Instance)
	local identifier = child.Name -- Carrot:sdkfj1
	
	local foundClientModel = clientFolder:FindFirstChild(identifier)
	if foundClientModel then
		foundClientModel:Destroy()
	end
end	

serverFolder.ChildAdded:Connect(function(child)
	task.spawn(function()
		childAdded(child)
	end)
end)
serverFolder.ChildRemoved:Connect(childRemoved)

for _, child: Instance in serverFolder:GetChildren() do
	childAdded(child)
end