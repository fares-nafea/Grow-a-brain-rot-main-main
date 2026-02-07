-- DataService

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage:WaitForChild("Remotes")

local profileStore = require(script.ProfileStore)
local profileTemplate = require(script.Template)

local PlayerStore = profileStore.New("PlayerStore", profileTemplate)

local Service = {
	cachedModules = {},
	Profiles = {}
}

function Service.getData(target: Player)
	if not target:GetAttribute("DataLoaded") then
		return nil
	end

	local profile = Service.Profiles[target]
	if profile then
		return profile.Data
	end

	return nil
end

function Service.init()
	-- DataLoaded
	local moneyService = Service.cachedModules.MoneyService
	local plotService = Service.cachedModules.PlotService


	local function dataLoaded(player: Player)
		local profile = Service.Profiles[player]
		if profile then
			moneyService.dataLoaded(player)
			plotService.dataLoaded(player)
		end
	end

	-- playerAdded
	local function playerAdded(player: Player)

		local profile = PlayerStore:StartSessionAsync(tostring(player.UserId), {
			Cancel = function()
				return player.Parent ~= players
			end,
		})

		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()

			profile.OnSessionEnd:Connect(function()
				Service.Profiles[player] = nil
				player:Kick("Profile session end - Please rejoin")
			end)

			if player.Parent == players then
				Service.Profiles[player] = profile
				player:SetAttribute("DataLoaded", true)
				print(`Profile loaded for {player.Name}!`)
				dataLoaded(player)
			else
				profile:EndSession()
			end
		else
			player:Kick("Profile load fail - Please rejoin")
		end
	end

	-- playerRemoved
	local function playerRemoved(player: Player)
		local profile = Service.Profiles[player]
		if profile ~= nil then

			plotService.playerRemoved(player)
			profile:EndSession()
		end
	end

	players.PlayerAdded:Connect(playerAdded)
	players.PlayerRemoving:Connect(playerRemoved)

	for _, player: Player in players:GetPlayers() do
		playerAdded(player)
	end
end

return Service
