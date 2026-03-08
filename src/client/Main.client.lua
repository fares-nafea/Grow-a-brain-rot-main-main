-- CropReplicator

local players = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local tweenService = game:GetService("TweenService")

local player = players.LocalPlayer

local assets = replicatedStorage:WaitForChild("Assets")
local modules = replicatedStorage:WaitForChild("Modules")

local seedModule = require(modules.SeedData)
local plantsFolder = assets.Plants

local world = workspace:WaitForChild("World", math.huge)
local plantedSeeds = world.Map.PlantedSeeds
local clientFolder = plantedSeeds.Client
local serverFolder = plantedSeeds.Server

repeat task.wait() until player:GetAttribute("DataLoaded") == true

task.wait(1)

local function growthPercentageUpdate(clientModel: Model, newValue: number)
    task.spawn(function()
        for _,v in clientModel:GetDescendants() do
            local isTweened = v:GetAttribute("IsTweened")
            local originalSize = v:GetAttribute("OriginalSize")
            local appearPercentage = v:GetAttribute("AppearPercentage")
            local originalCFrame = v:GetAttribute("OriginalCFrame")

            task.spawn(function()
                if isTweened ~= nil and originalSize and appearPercentage then
                    if isTweened == false then
                        if newValue >= appearPercentage then
                            v:SetAttribute("IsTweened", true)
                            tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                                Size = originalSize,
                                ["CFrame"] = originalCFrame,
                                Transparency = 0
                            }):Play()
                        end
                    end
                end
            end)
            task.wait(.05)
        end
        if newValue >= 100 then
            clientModel:SetAttribute("FullyGrown", true)
        end
    end)
end
local function childAdded(child: Instance)
    local identifier = child.Name

    if not clientFolder:FindFirstChild(identifier) then

        local trueName = identifier:split(":")[1]
        local foundModel = plantsFolder:FindFirstChild(trueName)

        if foundModel then
            local clientModel: Model = foundModel.ClientModel:Clone()
            clientModel.Name = identifier
            clientModel:PivotTo(child:GetPivot())

            -- Default Visibilty of Parts
            clientModel:SetAttribute("FullyGrown", false)
            for _,v in clientModel:GetDescendants() do
                local s,e = pcall(function()
                    local t = v.Transparency
                end)
                if s then
                    v.Transparency = 1
                    v:SetAttribute("OriginalSize", v.Size)
                    v:SetAttribute("OriginalCFrame", v.CFrame)
                    v:SetAttribute("IsTweened", false)
                    v.Size = Vector3.new(.01,.01,.01)
                    v.CFrame = clientModel:GetPivot()
                end
            end

            clientModel.Parent = clientFolder

            -- Handling Client Visuals (etc...)
            local serverConfig = child:FindFirstChild("ServerConfiguration")
            if serverConfig then
                -- Handling Growth Percentage
                local growthPercentage = serverConfig:WaitForChild("GrowthPercentage", math.huge)
                growthPercentage.Changed:Connect(function()
                    growthPercentageUpdate(clientModel, growthPercentage.Value)
                end)
                growthPercentageUpdate(clientModel, growthPercentage.Value)
            end
        end
    end
end
local function childRemoved(child: Instance)
    local identifier = child.Name

    local foundClientModel = clientFolder:FindFirstChild(identifier)
    if foundClientModel then
        foundClientModel:Destroy()
    end
end

serverFolder.childAdded:Connect(function(child)
    task.spawn(function()
        childAdded(child)
    end)
end)
serverFolder.ChildRemoved:Connect(childRemoved)

for _, child: Instance in serverFolder:GetChildren() do
    childAdded(child)
end

