-- Inventory Service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local modules = ReplicatedStorage:WaitForChild("Modules")
local ServerInfo = ReplicatedStorage:WaitForChild("ServerInfo")

local SeedDataModules = require(modules.SeedData)
local seedStorage = ServerStorage:WaitForChild("Seeds")
local cachedModules = require(script.Parent.Parent.Server.CachedModules)


local Service = {
}

function Service.removeItem(player: Player, itemName: string, count:number)
    if player and itemName and count then
        local dataService = cachedModules.Cache.DataService

        local playerData = dataService.getData(player)

        if playerData then
            local inventory = playerData.Inventory
            local foundItem = inventory[itemName]

            if foundItem then
                local removeItem = false

                if foundItem.Count then

                    foundItem.Count = math.clamp(foundItem.Count-1,0,math.huge)
                    if foundItem.Count <= 0 then
                        removeItem = true
                    else
                        Service.inventoryUpdated(player, itemName)
                    end
                else
                    removeItem = true
                end
                if removeItem then
                    inventory[itemName] = nil

                    -- looping throuth
                    local backpack = player.Backpack
                    local isSeed = seedStorage:FindFirstChild(itemName)

                    if isSeed then
                        for _,v in backpack:GetChildren() do
                            if v:GetAttribute("isSeed") == true and v:GetAttribute("trueName") == itemName then
                                -- destroy
                                v:Destroy()
                                break
                            end
                        end
                        local tool = player.Character:FindFirstChildWhichIsA("Tool")
                        if tool then
                            if isSeed and tool:GetAttribute("isSeed") == true and tool:GetAttribute("trueName") == itemName then
                                tool:Destroy()
                            end
                        end
                    end
                    -- add functionality
                end 
            end
        end
    end
end
function Service.createNewTool(player: Player, toolName: string)
    local dataService = cachedModules.Cache.DataService
    local playerData = dataService.getData(player)
    
    if playerData then
        local inventory = playerData.Inventory
        local itemData = inventory[toolName]

        if itemData then
            local isSeed = game.ServerStorage.Seeds:FindFirstChild(toolName)
            if isSeed then
                local toolClone = isSeed:Clone()
                toolClone.Name = toolName .. " (X" .. tostring(itemData.Count) .. ")"
                toolClone:SetAttribute("isSeed", true)
                toolClone:SetAttribute("trueName", toolName)
                toolClone.Parent = player:WaitForChild("Backpack")

                local activator = script.SeedActivator:Clone()
                activator.Parent = toolClone
                require(activator)
            end
        end
    end
end
function Service.inventoryUpdated(player: Player, ...)
    local dataService = cachedModules.Cache.DataService
    if not dataService then return end

    local playerData = dataService.getData(player)
    if not playerData then return end

    local inventory = playerData.Inventory
    local arguments = {...}

    for _, itemUpdated in ipairs(arguments) do
        local foundItemInInventory = inventory[itemUpdated]
        if foundItemInInventory then
            local foundItem = nil
            -- Checking in the backpack
            for _, v in player.Backpack:GetChildren() do
                if v:IsA("Tool") and v:GetAttribute("trueName") == itemUpdated then
                    foundItem = v
                    break
                end
            end

            if not foundItem and player.Character then
                local tool = player.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool:GetAttribute("trueName") == itemUpdated then
                    foundItem = tool
                end
            end
            if foundItem then
                foundItem.Name = itemUpdated .. " (X" .. tostring(foundItemInInventory.Count) .. ")"
            else
                Service.createNewTool(player, itemUpdated)
            end
        end
    end
end


-- تحميل الأدوات عند دخول Character
function Service.characterAdded(character: Model)
    local player = Players:GetPlayerFromCharacter(character)

    local dataService = cachedModules.Cache.DataService
    local playerData = dataService.getData(player)

    if playerData then
        -- Loads in tool
        for itemName, data in pairs(playerData.Inventory) do
            Service.createNewTool(player, itemName)
        end
    end
end

function Service.init()

end

return Service