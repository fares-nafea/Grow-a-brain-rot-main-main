-- Plot Service


local Service = {}

function Service.getMaxPlots()
    return workspace.World.Map.Plots:GetChildren()
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
function Service.dataLoaded(player: Player)
    local plot = Service.getAvailablePlot(player)
    if plot then
        plot:SetAttribute("Taken", true)
        plot:SetAttribute("Owner", player.UserId)

        print(player.Name, plot, plot.Name)
    end
end

return Service