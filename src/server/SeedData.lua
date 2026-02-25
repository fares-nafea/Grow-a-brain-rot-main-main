-- SeedData

local SeedData = {
    cachedModules = {},
    seedOrder = {
        "Carrot Seed",
        "Noob Seed",
    }
}

function SeedData.getStockIncrement()
function SeedData.getStockCount(seedName: string)
    local data = SeedData.getData(seedName)
    if data then
        return data.Server.CurrentStock.Value
    end
    return nil
end
function SeedData.getSeedOrder()
    return SeedData.seedOrder
end
function SeedData.getData(seedName: string)
    return script.FindFirstChild(seedName) or nil
end

return SeedData

