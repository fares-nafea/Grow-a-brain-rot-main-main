-- Seed Service

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local serverInfo = replicatedStorage.ServerInfo
local Service = {
    DEFAULT_RESTOCK_TIME = 10,
}

function Service.init()
    -- Restocking Timer
    serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
    task.spawn(function()
        while true do
            if serverInfo.SEED_RESTOCK_TIMER.Value <= 0 then
                -- Restock Seeds

                print("Restock Seeds")

                
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