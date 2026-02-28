-- Inventory Service
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ServerInfo = ReplicatedStorage:WaitForChild("ServerInfo")
local SeedDataModules = require(Modules:WaitForChild("SeedData"))
local SeedStorage = ServerStorage:WaitForChild("Seeds")

local Service = {
    cachedModules = {},
}

-- تحديث الأدوات في Inventory
function Service.inventoryUpdated(player: Player, ...)
    local dataService = Service.cachedModules.DataService
    if not dataService then return end

    local playerData = dataService.getData(player)
    if not playerData then return end

    if playerData then
        local inventory = playerData.Inventory
        
        local arguments = {...}

        for _, itemUpdated in arguments do
            local foundItemInInventory = inventory[itemUpdated]
            if foundItemInInventory then
                -- Checking in the backpack
                for  _, v in player.Backpack:GetChildren() do
                    if v:IsA("Tool") and v:GetAttribute("trueName") == itemUpdated then
                        foundItem =  v
                    end
                end

                local tool = player.Character:FindFirstChildWhichIsA("Tool")
                if tool and tool:GetAttribute("trueName") == itemUpdated then
                    foundItem = tool
                end
                if foundItem then
                    foundItem.Name = itemUpdated.." (X"..tostring(foundItemInInventory.Count)..")"
                end
            end
        end
    end
end


-- تحميل الأدوات عند دخول Character
function Service.characterAdded(character: Model)
    local player = Players:GetPlayerFromCharacter(character)
    if not player then return end

    local dataService = Service.cachedModules.DataService
    if not dataService then return end

    local playerData = dataService.getData(player)
    if not playerData then return end

    for itemName, itemData in pairs(playerData.Inventory) do
        local seedTemplate = SeedStorage:FindFirstChild(itemName)
        if seedTemplate then
            local toolClone = seedTemplate:Clone()
            toolClone.Name = itemName .. " (X" .. tostring(itemData.Count) .. ")"
            toolClone:SetAttribute("trueName", itemName)
            toolClone.Parent = player:WaitForChild("Backpack")
        end
    end
end

-- ربط اللاعبين الحاليين والجدد
function Service.init()
    local function setupPlayer(player)
        if player.Character then
            Service.characterAdded(player.Character)
        end
        player.CharacterAdded:Connect(Service.characterAdded)
    end

    -- إعداد اللاعبين الحاليين
    for _, player in pairs(Players:GetPlayers()) do
        setupPlayer(player)
    end

    -- متابعة اللاعبين الجدد
    Players.PlayerAdded:Connect(setupPlayer)
end

return Service