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

function Service.giveSeed(player: Player, seedName: string, amount: number, reduceStock: boolean)
    if player and seedName then
        -- Give the [player] the [seedName]
        local seedData = seedDataModules.getData(seedName)
        local playerData = Service.cachedModules.DataService.getData(player)
        if playerData and seedData then
            local inventory = playerData.Inventory
            local foundSeed = inventory[seedName]

            if reduceStock == true then
                -- Reduce
                seedData.Server.CurrentStock.Value = math.clamp(
                    seedData.Server.CurrentStock.Value-amount,
                    0,
                    seedData.Server.MaxStock.Value
                )
            end
            if foundSeed then
                foundSeed.Count += amount
            else
                inventory[seedName] = {Count = amount}
            end
        end
    end
end
function Service.restockSeed(data: any)
    if data then
        if data.resetTimer then
            -- Reset Timer
            serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
        end
    end
    -- Restocking
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
    ---
end
function Service.init()
    local dataService = Service.cachedModules.DataService
    local moneyService = Service.cachedModules.MoneyService
    -- Handling Remote Events
    remotes.BuySeed.onServerEvent:Connect(function(player, seedName: string)
        if player:GetAttribute("DataLoaded") ~= true then return end

        local playerData = dataService.getData(player)
        if not playerData then return end

        local seedData = seedDataModules.getData(seedName)
        if seedData then
            -- Checking if inStock
            if seedData.Server.CurrentStock.Value <= 0 then
                return
            end
            --- Checking if has enough money
            if playerData.Sheckles < seedData.Cost.Value then
                return
            end
            -- Buy the Seed
            moneyService.giveMoney(player, - seedData.Cost.Value)
            Service.giveSeed(player, seedName, 1, true)
        end
    end)
    -- Restocking Timer
    serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
    task.spawn(function()
        while true do
            if serverInfo.SEED_RESTOCK_TIMER.Value <= 0 then
                -- Restock Seeds

                Service.restockSeed()


                -- Reset Timer
                serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
            else
                serverInfo.SEED_RESTOCK_TIMER.Value -= 1
            end
            task.wait(1)
        end
    end)
    -------------------
end

return Service