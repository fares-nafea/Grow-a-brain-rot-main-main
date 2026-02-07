-- MoneyService

local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")

local Service = {
	cachedModules = {}
}

function Service.updateShecklesCount(player: Player)
    local DataService = Service.cachedModules.DataService
    local profileData = DataService.getData(player)
    if profileData then
        remotes.updateSheckles:FireClient(player, profileData.Sheckles)
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            leaderstats.Sheckles.Value = profileData.Sheckles
        end
    end
end
function Service.dataLoaded(player: Player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    local sheckles = Instance.new("IntValue")
    sheckles.Name = "Sheckles"
    sheckles.Value = 0
    sheckles.Parent = leaderstats

    leaderstats.Parent = player
    Service.updateShecklesCount(player)

    task.delay(5, function()
        Service.giveMoney(player, 100)
    end)
end
function Service.giveMoney(target: Player, amount: number)
	local DataService = Service.cachedModules.DataService
    
	local profileData = DataService.getData(target)
	if profileData then
		profileData.Sheckles += amount
        Service.updateShecklesCount(target)
	end
end

return Service