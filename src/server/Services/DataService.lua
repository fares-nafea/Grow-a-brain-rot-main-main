-- DataService

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

local remotes = replicatedStorage.Remotes

local profileStore = require(script.ProfileStore)
local profileTemplate = require(script.Template)
local cachedModules = require(script.Parent.Parent.Server.CachedModules)

local PlayerStore = profileStore.New("PlayerStore_013", profileTemplate)

local Service = {
	Profiles = {}
}

function Service.getData(target: Player)
	if not target:GetAttribute("DataLoaded") then return nil end
	local profile = Service.Profiles[target]
	if profile then
		return profile.Data
	end
	return nil
end
function Service.init()	
	-- DataLoaded
	local moneyService = cachedModules.Cache.MoneyService
	local plotService = cachedModules.Cache.PlotService
	local inventoryService = cachedModules.Cache.InventoryService
	
	local function characterAdded(character: Model)
		inventoryService.characterAdded(character)
	end
	local function dataLoaded(player: Player)
		local profile = Service.Profiles[player]
		if profile then
			moneyService.dataLoaded(player)
			plotService.dataLoaded(player)
			
			-- Checking When Character Loads In
			if player.Character then
				characterAdded(player.Character)	
			end
			player.CharacterAdded:Connect(characterAdded)
		end
	end
	
	-- PlayerAdded
	local function playerAdded(player: Player)
		local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
			Cancel = function()
				return player.Parent ~= players
			end,
		})
		if profile ~= nil then
			profile:AddUserId(player.UserId)
			profile:Reconcile()

			profile.OnSessionEnd:Connect(function()
				Service.Profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)

			if player.Parent == players then
				Service.Profiles[player] = profile
				print(`Profile loaded for {player.Name}!`)
				-- Player Data Successfully Loaded
				player:SetAttribute("DataLoaded", true)
				dataLoaded(player)
				------
			else
				profile:EndSession()
			end
		else
			player:Kick(`Profile load fail - Please rejoin`)
		end
	end
	
	-- PlayerRemoved
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