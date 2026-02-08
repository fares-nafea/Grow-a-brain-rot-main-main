-- PlotService

local players = game:GetService("Players")

local Service = {}

local World = workspace:WaitForChild("World")
local Map = World:WaitForChild("Map")
local Plots = Map:WaitForChild("Plots")

function Service.getMaxPlots()
    return Plots:GetChildren()
end
function Service.getPlot(player: Player)
    for _, plot: Model in workspace.World.Map.Plots:GetChildren() do
        if plot:GetAttribute("Taken") == true and plot :GetAttribute("Owner") == player.UserId then
            return plot
        end
    end
    return nil
end
function Service.getAvailablePlot(player: Player)
    for _, plot: Model in ipairs(Service.getMaxPlots()) do
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
        
        local ImageSize = Enum.ThumbnailSize.Size60x60
        local ImageType = Enum.ThumbnailType.HeadShot
        local content = players:GetUserThumbnailAsync(player.UserId, ImageType, ImageSize)
        playerSign.Main.SurfaceGui.ImageLabel.ImageTransparency = 0
        playerSign.Main.SurfaceGui.ImageLabel.Image = content
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
    end
end

return Service
