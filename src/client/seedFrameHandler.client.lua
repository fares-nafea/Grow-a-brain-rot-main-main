-- seedFrameHandler

local lighting = game:GetService("Lighting")
local tweenService = game:GetService("TweenService")

local mainGui = script.Parent

local eventsFolder = mainGui:WaitForChild("Events")
local root = mainGui:WaitForChild("Root")
local configurationFolder = mainGui:WaitForChild("Configuration")

local seedsFrame = root:WaitForChild("Frames"):WaitForChild("SeedFrame")

-- Default
seedsFrame.Visible = false
seedsFrame.Size = UDim2.new(0.3,0,0,0)
-----------


eventsFolder:WaitForChild("ToggleSeedFrame").Event:Connect(function(bool: boolean)

    if configurationFolder:WaitForChild("seedFrameDebounce").Value then return end

    configurationFolder.seedFrameDebounce.Value = true
    task.delay(0.4, function()
        configurationFolder.seedFrameDebounce.Value = false
    end)

    if bool then
        -- Make Visible
        task.spawn(function()
            local foundBlur = lighting:FindFirstChild("seedShopBlur")
            if foundBlur then foundBlur:Destroy() end
        end)

        -- Adding in BlurEffect
        local blur = Instance.new("BlurEffect")
        blur.Name = "seedShopBlur"
        blur.Size = 0
        blur.Parent = lighting
        tweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = 14
        }):Play()
        ----------------------

        seedsFrame.Visible = true
        seedsFrame:TweenSize(UDim2.new(0.3,0,0.6,0),Enum.EasingDirection.Out,Enum.EasingStyle.Back,0.25,true)
    else
        -- Removing Blur
        local foundBlur = lighting:FindFirstChild("seedShopBlur")
        if foundBlur then
            tweenService:Create(foundBlur,TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = 0
            }):Play()
            task.wait(0.1, function()
                foundBlur:Destroy()
            end)
        end
        -------

        -- Make Visible
        seedsFrame:TweenSize(UDim2.new(0.3,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Back,0.25,true)
        task.delay(0.4, function()
            seedsFrame.Visible = false
        end)
    end
end)

seedsFrame:WaitForChild("Exit").MouseButton1Click:Connect(function()
    eventsFolder.ToggleSeedFrame:Fire(false)
end)
