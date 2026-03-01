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
    if Player:FindFirstChild("SeedFrameDebounce") then
    end
    local playerPlot: Model = plotService.getPlot(Player)

    local db = Instance.new("BoolValue")
    db.Name = "SeedFrameDebounce"
    db.Parent = Player
    debris:AddItem(db, .5)

    if playerPlot then

        local mouseCFrame = remotes.GetMouseCF:InvokeClient(Player)

        if mouseCFrame then
            if not plotService.locationIsWithinPlot(playerPlot, mouseCFrame) then
                return
            end
            -- Getting Seed Offset Form the Ground 
            local plantModel = replicatedStorage.Assets.PlantEffect:FindFirstChild(
                Tool:GetAttribute("trueName"):split(" ")[1]
            )

            if plantModel then
                plantModel = plantModel.ServerModel

                local plotCFrame, plotSize = playerPlot.RightSoil:GetBoundingBox()

                local plotTopY = plotCFrame.Position.Y + plotService.Y/2
                local plantHeightOFfset = plantModel.PrimaryPart.Size.Y

                local spwanPosition = Vector3.new(
                    mouseCFrame.Position.X,
                    plotTopY+plantHeightOFfset,
                    mouseCFrame.Position.Z
                )
                spwanPosition = CFrame.new(spwanPosition)

                seedService.plantSeed(Player, Tool:getAttribute("trueName"), spwanPosition)
            end
        end
    end
end)

return Activator