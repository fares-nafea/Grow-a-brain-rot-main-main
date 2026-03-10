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

local function harvestableChanged(serverModel: Model, clientModel: Model, fruitNumber: string, harvestable: boolean, MultiHarvest: boolean)
	task.spawn(function()

		if harvestable == true then

			if clientModel:GetAttribute("FullyGrown") == false then
				repeat task.wait() until clientModel:GetAttribute("FullyGrown") == true

				-- Enable Prompt
				task.spawn(function()
					if MultiHarvest then
						serverModel.FruitPrompts[fruitNumber].HarvestPrompt.Enabled = true
					else
						serverModel.PrimaryPart.HarvestPrompt.Enabled = true
					end
				end)

				task.spawn(function()

					for _,v in clientModel:GetDescendants() do

						local isTweened = v:GetAttribute("isTweened")
						local originalSize = v:GetAttribute("OriginalSize")
						local originalCFrame = v:GetAttribute("OriginalCFrame")

						if isTweened ~= nil and originalSize then

							if isTweened then
								continue
							end

							if v:GetAttribute("FruitNumber") == tonumber(fruitNumber) then

								v:SetAttribute("isTweened", true)

								tweenService:Create(
									v,
									TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
									{
										Size = originalSize,
										CFrame = originalCFrame,
										Transparency = 0
									}
								):Play()

							end
						end
					end
				end)

			end

		else

			task.spawn(function()

				if MultiHarvest then
					serverModel.FruitPrompts[fruitNumber].HarvestPrompt.Enabled = false
				else
					serverModel.PrimaryPart.HarvestPrompt.Enabled = false
				end

			end)

		end

	end)
end


local function growthPercentageUpdate(clientModel: Model, newValue: number)

	task.spawn(function()

		for _,v in clientModel:GetDescendants() do

			local isTweened = v:GetAttribute("isTweened")
			local originalSize = v:GetAttribute("OriginalSize")
			local originalCFrame = v:GetAttribute("OriginalCFrame")

			if isTweened ~= nil and originalSize then

				if isTweened then
					continue
				end

				v:SetAttribute("isTweened", false)

				tweenService:Create(
					v,
					TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{
						Size = Vector3.new(.01,.01,.01),
						CFrame = clientModel:GetPivot(),
						Transparency = 1
					}
				):Play()

			end

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
			clientModel:PivotTo(child:GetPivot())

			clientModel:SetAttribute("FullyGrown", false)

			for _,v in clientModel:GetDescendants() do

				local s = pcall(function()
					local t = v.Transparency
				end)

				if s then

					v.Transparency = 1

					v:SetAttribute("OriginalSize", v.Size)
					v:SetAttribute("OriginalCFrame", v.CFrame)
					v:SetAttribute("isTweened", false)

					v.Size = Vector3.new(.01,.01,.01)
					v.CFrame = clientModel:GetPivot()

				end

			end

			clientModel.Parent = clientFolder

			local serverConfig = child:FindFirstChild("ServerConfiguration")

			if serverConfig then

				local growthPercentage = serverConfig:WaitForChild("GrowthPercentage", math.huge)

				growthPercentage.Changed:Connect(function()

					growthPercentageUpdate(clientModel, growthPercentage.Value)

				end)

				growthPercentageUpdate(clientModel, growthPercentage.Value)

				local seed_data = seedModule.getData(trueName.." Seed")

				if seed_data then

					local fruitsFolder = serverConfig.Fruits

					for _,v in fruitsFolder:GetChildren() do

						if seed_data.MultiHarvest.Value then

							local foundModel = clientModel:FindFirstChild("fruit_"..tostring(v.Name))

							if foundModel then

								local objectValue = Instance.new("ObjectValue")

								objectValue.Name = "CorrespondingAdornee"
								objectValue.Value = foundModel

								objectValue.Parent = child.FruitPrompts:WaitForChild(tostring(v.Name)).HarvestPrompt

							end

						else

							local objectValue = Instance.new("ObjectValue")

							objectValue.Name = "CorrespondingAdornee"
							objectValue.Value = clientModel

							objectValue.Parent = child.PrimaryPart:WaitForChild("HarvestPrompt")

						end

					end

				end

			end

		end

	end

end


local function childRemoved(child: Instance)

	local identifier = child.Name

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