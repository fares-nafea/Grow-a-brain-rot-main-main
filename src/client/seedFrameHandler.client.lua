-- seedFrameHandler

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mainGui = script.Parent

local eventsFolder = ReplicatedStorage:WaitForChild("Events")
local root = mainGui:WaitForChild("Root")
local Frames = root:WaitForChild("Frames")
local seedsFrame = Frames:WaitForChild("SeedsFrame")

-- Default
seedsFrame.Visible = false

-----

eventsFolder.ToggleSeedFrame.Events:Connect(function(bool: boolean)
    if bool == true then
        -- Make Visible


    else
        -- Make Invisible
    end
end)