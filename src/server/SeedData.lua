-- SeedData

local SeedData = {
	cachedModules = {},
	seedOrder = {
		"Carrot Seed",
		"Blueberry Seed",
		"Tomato Seed",
		"Cacao Seed",
	}
}

function SeedData.getStockIncrement(seedName: string)
	if seedName == "Carrot Seed" then
		return math.random(1,5)
	end
	return 1
end
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
	return script:FindFirstChild(seedName) or nil
end

return SeedData