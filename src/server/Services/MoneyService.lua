-- MoneyService

local replicatedStorage = game:GetService("ReplicatedStorage")
local DataService = require(script.Parent.DataService)

local remotes = replicatedStorage.Remotes


local Service = {
    cachedModules = {}
}

function Service.DataLoaded(player: Player)
    
end
function Service.giveMoney(target: Player, amount: number)

    local DataService = Service.cachedModules.DataService
    local profileData = DataService.getData(target)
    if profileData then
        profileData.Sheckles += amount
        remotes.updateSheckles:FireClient(target, profileData.Sheckles)
    end
end

return Service


