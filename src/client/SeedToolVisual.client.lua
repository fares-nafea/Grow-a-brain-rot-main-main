-- SeedToolVisual

local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")

local player = players.LocalPlayer
local character = script.Parent

local plots = workspace:WaitForChild("World", math.huge).Map.Plots

local humanoid: Humanoid = character:WaitForChild("humanoid", math.huge)

local highlightToUse = script:WaitForChild("Highlight", math.huge)

-- Defaulting Highlight

highlightToUse.FillTransparency = 1

local tweenIn = tweenService:Create(highlightToUse, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    FillTransparency = .5
})

local tweenOut = tweenService:Create(highlightToUse, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
    FillTransparency = 1
})
--

repeat task.wait() until player:GetAttribute("DataLoaded") == true

local function getPlayerPlot()
    for _,v in plots:GetChildren()do
        if v:IsA("Model") and v:GetAttribute("Taken") == true and v:GetAttribute("Owner") == player.UserId then
            return v
        end
    end
    return nil
end

repeat task.wait() until getPlayerPlot()
highlightToUse.Adornee = getPlayerPlot().RightSoil

character.ChildAdded:Connect(function(child: Instance)
    if child:IsA("Tool") and child:GetAttributes("isSeed") == true then
        tweenOut:Pause()
        tweenIn:Play()
    end
end)
character.ChildRemoved:Connect(function(child: Instance)
    if child:IsA("Tool") and child:GetAttributes("isSeed") == true then
        tweenIn:Pause()
        tweenOut:Play()
    end
end)