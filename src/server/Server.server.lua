-- Server

local servicesFolder = script.Parent.Services

local startTime = os.clock()

local cachedModules = {}



for _, moduleScript: ModuleScript in servicesFolder:GetChildren() do
	if moduleScript:IsA("ModuleScript") then
		cachedModules[moduleScript.Name] = require(moduleScript)
	end
end

for moduleName: string, moduleScript in cachedModules do
	if moduleScript.init then
		moduleScript.init()
	end
	moduleScript.cachedModules = cachedModules

end



warn("Game services loaded in ".. os.clock()-startTime.."s")

