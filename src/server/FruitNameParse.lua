local function trim(s)
	return s:match("^%s*(.-)%s*$")
end
local function parseFruitInfo(fruitName: string)
	-- Match optional mutations in the first brackets
	local mutationStr = fruitName:match("^%[(.-)%]") or ""

	-- Match the weight in the last brackets (e.g., [7.15kg])
	local weightStr = fruitName:match("%[(%d+%.?%d*)kg%]") or "0"
	local weight = tonumber(weightStr)

	-- Split mutations by comma
	local mutations = {}
	for mutation in mutationStr:gmatch("[^,%s]+") do
		table.insert(mutations, mutation)
	end

	-- Remove mutation and weight brackets to isolate name
	local nameCleaned = fruitName
		:gsub("^%[.-%]%s*", "")                 -- remove leading [mutations]
		:gsub("%[%d+%.?%d*kg%]%s*", "")         -- remove trailing [weight]

	local fruitNameOnly = trim(nameCleaned)
	
	--[[
		["Twilight", "Golden", "Shocked"] Blueberry [5.42kg]
		
		mutations = {
			"Twilight",
			"Golden",
			"Shocked"
		}
		fruitNameOnly = "Blueberry"
		weight = 5.42
	]]

	return mutations, weight, fruitNameOnly
end

return parseFruitInfo