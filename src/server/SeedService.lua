-- Seed Service
local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local debris = game:GetService("Debris")
local httpService = game:GetService("HttpService")

local remotes = replicatedStorage.Remotes
local modules = replicatedStorage.Modules
local serverInfo = replicatedStorage.ServerInfo

local seedDataModules = require(modules.SeedData)
local cachedModules = require(script.Parent.Parent.Server.CachedModules)


local Service = {
    DEFAULT_RESTOCK_TIME = 10,
}

function Service.generateKey(prefix: string)
    return prefix..":"..string.sub(httpService.GenerateGUID(false), 1, 5)
end
function Service.isCloseToPlant(referencePoint: Part, plotData: any, locationToPlant: CFrame, magnitudeThreshold: number)
    if plotData and locationToPlant and magnitudeThreshold and referencePoint then
        for plantKey: string, data: any in plotData do
            -- Converting Saved location to World Location for checking
            local location = CFrame.new( table.unpack(data.location) )
            location = referencePoint.CFrame:ToObjectSpace(location)
            --

            local distance = (location.Position - locationToPlant.Position).Magnitude
            if distance < magnitudeThreshold then
                return true
            end
        end
    end
    return false
end
function Service.plantSeed(player: Player, seedName: string, location: CFrame)
    local character = player.Character

    if player and location and character then
        local dataService = cachedModules.Cache.DataService
        local inventoryService = cachedModules.Cache.InventoryService
        local plotService = cachedModules.Cache.PlotService

        local seedData = seedDataModules.getData(seedName)
        local playerData = dataService.getData(player)

        if playerData and seedData then
            local currentTool = character:FindFirstChild("Tool")
            if currentTool and currentTool:getAttribute("isSeed") == true and currentTool:getAttribute("trueName") == seedName then
                -- Checking for Tool in Inventory
                local inventory = playerData.Inventory
                local foundSeed = inventory[seedName]
                
                if foundSeed then
                    if player:FindFirstChild("PlantDebounce") then
                        return
                    end
                    local debounce = Instance.new("Folder")
                    debounce.Name = "PlantDebounce"
                    debounce.Parent = player
                    debris:AddItem(debounce, 0.5)

                    local plotData = playerData.PlotData
                    -- Checking if too close to another plant
                    local isTooClose = Service.isCloseToPlant(
                        plotService.getPlot(player).ReferencePoint,
                        plotData,
                        location,
                        2.5
                    )
                    if isTooClose then
                        return
                    end



                    local locationToSave = plotService.getPlot(player).ReferencePoint.CFrame:ToObjectSpace(location)
                    
                    -- generate key
                    local key = Service.generateKey(seedData.SeedPrefix.Value)
                end
            end
        end
    end
end
function Service.giveSeed(player: Player, seedName: string, amount: number, reduceStock: boolean)
    local inventoryService = cachedModules.Cache.InventoryService
    if not (player and seedName) then return end

    local seedData = seedDataModules.getData(seedName)
    local playerData = cachedModules.Cache.DataService.getData(player)

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

function Service.restockSeed(data: any)
    if data and data.resetTimer then
        serverInfo.SEED_RESTOCK_TIMER.Value = Service.DEFAULT_RESTOCK_TIME
    end

    for _, seedName: string in seedDataModules.getSeedOrder() do
        local seedData = seedDataModules.getData(seedName)
        if seedData then
            local countToAdd = seedDataModules.getStockIncrement(seedName)
            seedData.Server.CurrentStock.Value = math.clamp(
                seedData.Server.CurrentStock.Value + countToAdd,
                0,
                seedData.Server.MaxStock.Value
            )
        end
    end
end

function Service.init()
    local dataService = cachedModules.Cache.DataService
    local moneyService = cachedModules.Cache.MoneyService

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