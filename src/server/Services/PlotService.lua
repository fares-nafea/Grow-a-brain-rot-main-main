-- PlotService

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local Service = {}

local modules = replicatedStorage.Modules
local assets = replicatedStorage.Assets

local seedDataModule = require(modules.SeedData)

local cachedModules = require(script.Parent.Parent.Server.CachedModules)

function Service.locationIsWithinPlot(plot: Model, location: CFrame)
	if plot and location then
		local rightSoil = plot:FindFirstChild("RightSoil")
		if rightSoil then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {rightSoil}
			for _, part: Part in rightSoil:GetChildren() do
				-- Casting Downwards
				local result = workspace:Raycast(location.Position+Vector3.new(0,5,0), Vector3.new(0,-999999,0), params)
				if result and result.Instance == part then
					return true
				end
			end
		end
	end
	return false
end
function Service.getMaxPlots()
    return #workspace.World.Map.Plots:GetChildren()
end
function Service.getPlot(player: Player)
    for _, plot: Model in workspace.World.Map.Plots:GetChildren() do
        if plot:GetAttribute("Taken") == true and plot:GetAttribute("Owner") == player.UserId then
            return plot
        end
    end
    return nil
end
function Service.getAvailablePlot(player: Player)
	for i = 1, Service.getMaxPlots() do
		local correspondingPlot: Model = workspace.World.Map.Plots[tostring(i)]
		if correspondingPlot:GetAttribute("Taken") == true then
			continue
		end
		return correspondingPlot
	end
	return nil
end
function Service.createServerModel(player: Player, key: string, data: any)
    local dataService = cachedModules.Cache.DataService
    local playerData = dataService.getData(player)

    local plotData = playerData.PlotData
    local saveData = plotData[key]

    local trueName = key:split(":")[1]-- Carrot:s5965s
    local correspondingFolder = assets.Plants:FindFirstChild(trueName)

    local seedData = seedDataModule.getData(trueName.." Seed")

    if cachedModules and saveData and seedData then
        local serverModel: Model = correspondingFolder.ServerModel:Clone()
        serverModel.Name = key
        serverModel:SetAttribute("Owner", player.UserId)
        serverModel:SetAttribute("Plot", Service.getPlot(player).Name)

        -- Scaling on PlantScaling
        serverModel:ScaleTo(data.PlantSize)
        --

        local serverConfig = script.ServerModelConfig:Clone()
        serverConfig.Name = "ServerConfiguration"

        -- Assigning Configuration Value For Easy Viewing on Client/Server
        serverConfig.DatePlanted.Value = data.DatePlanted
        serverConfig.GrowthPercentage.Value = data.GrowthPercentage
        serverConfig.LastGrowthincrement.Value = data.LastGrowthIncrement
        serverConfig.PlantSize.Value = data.PlantSize


        for index: number, fruitData: any in data.Fruits do
            local fruitConfig = script.FruitConfigTemplate:Clone()
            fruitConfig.Name = tostring(index)
            fruitConfig.CanHarvest.Value = fruitData.CanHarvest
            fruitConfig.LastHarvest.Value = fruitData.LastHarvest
            fruitConfig.Mutations.Value = fruitData.Mutations
            fruitConfig.SizeScaling.Value = fruitData.SizeScaling
            fruitConfig.Parent = serverConfig.Fruits

            -- Updating Folder
            for _,v in fruitConfig:GetChildren() do
                if not v:IsA("Folder") then
                    v.Changed:Connect(function()
                        if saveData.Fruits[index][v.Name] ~= nil then
							saveData.Fruits[index][v.Name] = v.Value
						end
                    end)
                end
            end
        end

        -- Creating ProximityPrompts
        if seedData.MultiHarvest.Value then
            local fruitPrompts = serverModel:FindFirstChild("FruitPrompts")
            if fruitPrompts then
                for _,v in serverConfig.Fruits:GetChildren() do
                    local correspondingPart: Part = fruitPrompts:FindFirstChild(v.Name)
                    if correspondingPart then
                        local harvestPrompt = script.HarvestPrompt:Clone()
                        harvestPrompt.ActionText = "Harvest"
                        harvestPrompt.ObjectText = trueName
                        harvestPrompt.Enabled = false
                        harvestPrompt.Parent = correspondingPart
                    end
                end
            end
        else
            local harvestPrompt = script.HarvestPrompt:Clone()
            harvestPrompt.ActionText = "Harvest"
            harvestPrompt.ObjectText = trueName
            harvestPrompt.Enabled = false
            harvestPrompt.Parent = serverModel.PrimaryPart
        end
        -- Updating Server Config Folder
        for _,v in serverConfig:GetChildren() do
            if not v:IsA("Folder") then
                v.Changed:Connect(function()
                    if saveData[v.Name] ~= nil then
                        saveData[v.Name] = v.Value
                    end
                end)
            end
        end
        --------
        serverConfig.Parent = serverModel

        local deserializeCFrame = CFrame.new(table.unpack(data.Location))
        deserializeCFrame = CFrame.new(deserializeCFrame.Position)

        -- Converting
        deserializeCFrame = Service.getPlot(player).ReferencePoint.CFrame:ToWorldSpace(deserializeCFrame)

        serverModel:PivotTo(deserializeCFrame)
        serverModel.Parent = workspace.World.Map.PlantedSeeds.Server
    end
end
function Service.updatePlot(player: Player, action: string, data: any)
    local playerData = cachedModules.Cache.DataService.getData(player)
    if playerData then
        if action == "seedPlanted" then
            local itemKey: string = data.itemKey
            if itemKey then
                local newItemData = playerData.PlotData[itemKey]

                if newItemData then
                    -- Update the Plot With New Item
                    Service.createServerModel(player, itemKey, newItemData)
                end
            end
        end
        if action == "fruitHarvested" then
        end
    end
end

function Service.dataLoaded(player: Player)
    local plot = Service.getAvailablePlot(player)
    if plot then
        plot:SetAttribute("Taken", true)
        plot:SetAttribute("Owner", player.UserId)

        local playerSign: Model = plot.PlayerSign
        playerSign.Main.SurfaceGui.TextLabel.Text = player.Name
        
        local ImageSize = Enum.ThumbnailSize.Size60x60
        local ImageType = Enum.ThumbnailType.HeadShot
        local content = players:GetUserThumbnailAsync(player.UserId, ImageType, ImageSize)
        playerSign.Main.SurfaceGui.ImageLabel.ImageTransparency = 0
        playerSign.Main.SurfaceGui.ImageLabel.Image = content

        -- Loading Plot
        local plotData = cachedModules.Cache.DataService.getData(player).PlotData
        task.spawn(function()
            for Key: string, data: any in plotData do
                Service.createServerModel(player, Key, data)
            end
        end)
        warn(player, "PlotData", plotData)
    end
end

function Service.playerRemoved(player: Player)
    local foundPlot = Service.getPlot(player)
    if foundPlot then
        foundPlot:SetAttribute("Taken", nil)
        foundPlot:SetAttribute("Owner", nil)
        local playerSign: Model = foundPlot.PlayerSign
        playerSign.Main.SurfaceGui.TextLabel.Text = "Empty Garden"
        playerSign.Main.SurfaceGui.ImageLabel.ImageTransparency = 1
        playerSign.Main.SurfaceGui.ImageLabel.Image = ""

        -- Claering Plot
        for _, plant: Model in workspace.World.Map.PlantedSeeds.Server:GetChildren() do
            if plant:GetAttribute("Owner") == player.UserId then
                plant:Destroy()
            end
        end
        ---
    end
end

function Service.init()
    -- Growing Seed
    -- Includes Offline Growing

    local dataService = cachedModules.Cache.DataService

    task.spawn(function()
        while task.wait(1) do
            for _, crop: Model in workspace.World.Map.PlantedSeeds.Server:GetChildren() do
                local plotNumber = crop:GetAttribute("Plot")
                local owner = crop:GetAttribute("Owner")

                local player = players:GetPlayerByUserId(owner)
                if not player then
                    continue
                end
                local playerData = dataService.getData(player)

                local serverConfig = crop:FindFirstChild("ServerConfiguration")
                if serverConfig then
                    local growthPercentage = serverConfig.GrowthPercentage
                    local lastGrowthincrement = serverConfig.LastGrowthincrement
                    local datePlanted = serverConfig.DatePlanted

                    local seedName = crop.Name:split(":")[1].." Seed"
                    local foundSeed = seedDataModule.getData(seedName)

                    local harvestInterval = foundSeed.HarvestInterval.Value

                    if plotNumber and owner and foundSeed then

                        if growthPercentage.Value >= 100 then
                            -- Harvest Seed Part
                            if foundSeed.MultiHarvest.Value then
                                -- Multi Harvest Crop
                                task.spawn(function()
                                    for _, fruit in serverConfig.Fruits:GetChildren() do
                                        local lastHarvest = fruit.LastHarvest
                                        local canHarvest = fruit.CanHarvest
                                        local mutations = fruit.Mutations

                                        if os.time()-lastHarvest.Value >= harvestInterval then
                                            canHarvest.Value = true
                                        else
                                            canHarvest.Value = false
                                        end
                                    end
                                end)
                            else
                                -- Single Harvest Crop
                                local folder = serverConfig.Fruits["1"]
                                if folder.CanHarvest.Value then
                                    continue
                                end
                                folder.CanHarvest.Value = true
                            end

                        else
                            local growthTime = foundSeed.GrowthTime.Value
                            if os.time()-lastGrowthincrement.Value >= 1 then
                                -- Increment
                                lastGrowthincrement.Value = os.time()
                                growthPercentage.Value = math.clamp(
                                    ((os.time()-datePlanted.Value)/growthTime)*100,
                                    0,
                                    100
                                )
                            end
                        end
                    end
                end
            end
        end   
    end)
end

return Service