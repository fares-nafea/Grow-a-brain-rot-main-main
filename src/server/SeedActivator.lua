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
        end
    end
end)

return Activator