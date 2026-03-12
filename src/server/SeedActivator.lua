-- SeedActivator
--[[
   Used for handling tools
]]

local debris = game:GetService("Debris")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage.Remotes

local cachedModules = require(game.ServerScriptService.Server.CachedModules)
local seedService = cachedModules.Cache.SeedService
local plotService = cachedModules.Cache.PlotService

local Activator = {}

local Tool: Tool = script.Parent
local Player: Player = Tool.Parent.Parent

Tool.Activated:Connect(function()
	if Player:FindFirstChild("SeedPlantDebounce") then
		return
	end
	
	local playerPlot: Model = plotService.getPlot(Player)
	
	local db = Instance.new("BoolValue")
	db.Name = "SeedPlantDebounce"
	db.Parent = Player
	debris:AddItem(db, .5)

    if playerPlot then
        local mouseCFrame = remotes.GetMouseCF:InvokeClient(Player)

        if mouseCFrame then
            if not plotService.locationIsWithinPlot(playerPlot, mouseCFrame) then
                return
            end
            -- Getting Seed Offset Form the Ground 
            local plantModel = replicatedStorage.Assets.Plants:FindFirstChild(
				Tool:GetAttribute("trueName"):split(" ")[1]
            )

            if plantModel then
                local mockPlantModel = plantModel.ServerModel:Clone()

                -- Gatting Final Plant Scaling
                local PlantSize = seedService.getRandomPlantSize(Tool.Name, { })
                ---
                mockPlantModel:ScaleTo(PlantSize)

                local plotCFrame, plotSize = playerPlot.RightSoil:GetBoundingBox()

                local plotTopY = plotCFrame.Position.Y + plotSize.Y/2
                local plantHeightOFfset = mockPlantModel.PrimaryPart.Size.Y/2

                local spawnPosition = Vector3.new(
					mouseCFrame.Position.X,
					plotTopY+plantHeightOFfset,
					mouseCFrame.Position.Z
				)
				spawnPosition = CFrame.new(spawnPosition)

                mockPlantModel:Destroy( )

				seedService.plantSeed(Player, Tool:GetAttribute("trueName"), spawnPosition, PlantSize )
            end
        end
    end
end)

return Activator