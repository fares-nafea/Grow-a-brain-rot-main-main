local Game = game
local StarterGui = Game:GetService("StarterGui")
local Success
while true do
	Success, _ = pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
	if Success then break else task.wait() end --No need to yield if the operation was successful.
end