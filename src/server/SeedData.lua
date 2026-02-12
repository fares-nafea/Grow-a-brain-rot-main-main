-- SeedData

local SeedData = {
    cachedModules = {},
    seedOrder = {
        "Carrot Seed",
    }
}

for _,  moduleScript: ModuleScript in script:GetChildren() do
    if moduleScript:IsA("ModuleScript") then
        SeedData.cachedModules[moduleScript.Name] = require(moduleScript)
    end
end

function SeedData.getStockCount(seedName: string)
    local data = SeedData.getData(seedName)
    if data then
        return data.ServerData.CurrrentStock
    end
    return nil
end
function SeedData.getSeedOrder()
    return SeedData.seedOrder
end
function SeedData.getData(seedName: string)
    return SeedData.cachedModules[seedName] or nil
end

return SeedData