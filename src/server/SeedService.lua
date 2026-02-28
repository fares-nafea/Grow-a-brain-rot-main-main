-- Seed Service
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local remotes = replicatedStorage.Remotes
local modules = replicatedStorage.Modules
local serverInfo = replicatedStorage.ServerInfo

local seedDataModules = require(modules.SeedData)

local Service = {
    cachedModules = {},
    DEFAULT_RESTOCK_TIME = 10,
}

-- Give Seed to Player
function Service.giveSeed(player: Player, seedName: string, amount: number, reduceStock: boolean)
    local inventoryService = Service.cachedModules.InventoryService
    if not (player and seedName) then return end

    local seedData = seedDataModules.getData(seedName)
    local playerData = Service.cachedModules.DataService.getData(player)

    if playerData and seedData then
        local inventory = playerData.Inventory
        local foundSeed = inventory[seedName]

        -- Reduce stock if needed
        if reduceStock then
            seedData.Server.CurrentStock.Value = math.clamp(
                seedData.Server.CurrentStock.Value - amount,
                0,
                seedData.Server.MaxStock.Value
            )
        end

        -- Update inventory
        if foundSeed then
            foundSeed.Count += amount
        else
            inventory[seedName] = { Count = amount }
        end

        inventoryService.inventoryUpdated(player, seedName)
    end
end

-- Restock Seeds
function Service.restockSeed(data: any)
    if data and data.resetTimer then
        serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
    end

    for _, seedName: string in seedDataModules.getSeedOrder() do
        local seedData = seedDataModules.getData(seedName)
        if seedData then
            local countToAdd = seedDataModules.getStockIncrement(seedName)
            seedData.Server.CurrentStock.Value = math.clamp(
                seedData.Server.CurrentStock.Value * countToAdd,
                0,
                seedData.Server.MaxStock.Value
            )
        end
    end
end

-- Initialize Service
function Service.init()
    local dataService = Service.cachedModules.DataService
    local moneyService = Service.cachedModules.MoneyService

    -- Handle BuySeed Remote Event
    remotes.BuySeed.onServerEvent:Connect(function(player, seedName: string)
        if player:GetAttribute("DataLoaded") ~= true then return end

        local playerData = dataService.getData(player)
        if not playerData then return end

        local seedData = seedDataModules.getData(seedName)
        if not seedData then return end

        -- Check stock and money
        if seedData.Server.CurrentStock.Value <= 0 then return end
        if playerData.Sheckles < seedData.Cost.Value then return end

        -- Process purchase
        moneyService.giveMoney(player, -seedData.Cost.Value)
        Service.giveSeed(player, seedName, 1, true)
    end)

    -- Start Restocking Timer
    serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
    task.spawn(function()
        while true do
            if serverInfo.SEED_RESTOCK_TIMER.Value <= 0 then
                Service.restockSeed()
                serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
            else
                serverInfo.SEED_RESTOCK_TIMER.Value -= 1
            end
            task.wait(1)
        end
    end)
end

return Service