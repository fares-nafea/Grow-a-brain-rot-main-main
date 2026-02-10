-- seedFrameHandler

local mainGui = script.Parent

local eventsFolder = mainGui:WaitForChild("Events")
local root = mainGui:WaitForChild("Root")

local seedsFrame = root.Frames.SeedFrame
local configurationFolder = mainGui:WaitForChild("Configuration")
-- Default
seedsFrame.Visible = false
seedsFrame.Size = UDim2.new(0.3,0,0.55,0)
----------

eventsFolder.ToggleSeedFrame.Events:Connect(function(bool: boolean)
    if configurationFolder.seedFrameDebounce.Value then return end

    configurationFolder.seedFrameDebounce.Value = true
    task.delay(.4, function()
        configurationFolder.seedFrameDebounce.Value = false
    end)



    if bool == true then
        -- Make Visible
        seedsFrame.Value = true
        seedsFrame:TweenSize(UDim2.new(0.3,0,0.6,0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
    else
        -- Make invisible
        seedsFrame:TweenSize(UDim2.new(0.3,0,0.55,0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
        task.delay(.4, function()
            seedsFrame.Value = false
        end)
    end
end)