-- PlotService

local players = game:GetService("Players")

local Service = {}

local World = workspace:WaitForChild("World")
local Map = World:WaitForChild("Map")
local Plots = Map:WaitForChild("Plots")

function Service.getPlots()
    return Plots:GetChildren()
end

function Service.getAvailablePlot(player: Player)
    for _, plot: Model in ipairs(Service.getPlots()) do
        if plot:GetAttribute("Taken") then
            continue
        end
        return plot
    end
    return nil
end

function Service.dataLoaded(player: Player)
    local plot = Service.getAvailablePlot(player)
    if plot then
        plot:SetAttribute("Taken", true)
        plot:SetAttribute("Owner", player.UserId)

        local playerSign: Model = plot.PlayerSign
        playerSign.Main.SurfaceGui.TextLabel.Text = player.Name
        
        local ImageSize = Enum.ThumbnailSize.Size420x420
        local ImageType = Enum.ThumbnailType.HeadShot
 
        local content = players:GetUserThumbnailAsync(player.UserId, ImageType, ImageSize)
    end
end


return Service
