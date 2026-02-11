local Game = game
local StarterGui = game:GetService("StarterGui")
local Success
while true do
    Success, _= pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false)
    if Success then break else task.wait() end
end