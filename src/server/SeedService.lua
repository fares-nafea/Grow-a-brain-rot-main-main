-- Seed Service

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local modules = replicatedStorage.Modules
local serverInfo = replicatedStorage.ServerInfo

local seedDataModules = require(modules.SeedData)

local Service = {
    DEFAULT_RESTOCK_TIME = 10,
}

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
            local countToAdd = seedData.getRandomStock()
            seedData.ServerData.CurrentStock = math.clamp(
                seedData.ServerData.CurrentStock*countToAdd,
                0,
                seedData.ServerData.MaxStock
            )
        end
    end
    ---
end
function Service.init()
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