-- seedFrameHandler

local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")
local tweenService = game:GetService("TweenService")

local remotes = replicatedStorage:WaitForChild("Remotes")
local modules = replicatedStorage:WaitForChild("Modules")
local seedDataModule = require(modules.SeedData)

local mainGui = script.Parent

local serverInfo = replicatedStorage:WaitForChild("ServerInfo")
local eventsFolder = mainGui:WaitForChild("Events")
local root = mainGui:WaitForChild("Root")

local seedsFrame = root:WaitForChild("Frames"):WaitForChild("SeedFrame")
local configurationFolder = mainGui:WaitForChild("Configuration")

-- Default
seedsFrame.Visible = false
seedsFrame.Size = UDim2.new(0.3,0,0,0)
 --------- Scripting Seed List

local listFrame = seedsFrame:WaitForChild("List")

local function updateList()
    for _, v in listFrame:GetChildren() do
        if v:IsA("Frame") then
            v:Destroy()
        end
    end

    local seedOrder = seedDataModule:getSeedOrder()
    for _, seedName: string in seedOrder do

        local correspondingData = seedDataModule.getData(seedName)
        if correspondingData then
            local clone = script.Template:clone()
            clone.Name =  seedName
            clone.Cost.Text = correspondingData.Cost.Value.."$"
            clone.Title.Text = correspondingData.DisplayName.Value
            clone.StockCount.Text = "X"..correspondingData.Server.CurrentStock.Value.."Stock"
            clone.SeedIcon.Image = correspondingData.Icon.Value

            clone.Buy.Button.MouseButton1Click:Connect(function()
                remotes.BuySeed:FireServer(seedName)
            end)
            clone.Parent = listFrame
        else
            continue
        end
    end
end

updateList()
 -------------
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
            task.delay(0.5, function()
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

-- Update Restock Timer
local function Format(Int)
    return string.format("%02i", Int)
end

local function convertToHMS(Seconds)
    local Minutes = (Seconds - Seconds%60)/60
    Seconds = Seconds - Minutes*60
    local Hours = (Minutes - Minutes%60)/60
    Minutes = Minutes - Hours*60
    return Format(Hours)..":"..Format(Minutes)..":"..Format(Seconds)
end

local function updateRestockTimer()
    seedsFrame.TitleFrame:WaitForChild("SeedTimer").Text =
        "New seeds in: ".. convertToHMS(serverInfo.SEED_RESTOCK_TIMER.Value)
end

serverInfo.SEED_RESTOCK_TIMER.Changed:Connect(updateRestockTimer)
updateRestockTimer()

-- Detecting Changes in Stock
local function updateStockDisplay(seedName: string, currentCount: number)
    local foundFrame = listFrame:FindFirstChild(seedName)
    if foundFrame then
        foundFrame.StockCount.Text = "x"..tostring(currentCount).." Stock"
    end
end

for _, folder: Folder in modules.SeedData:GetChildren() do
    local serverInfo = folder:FindFirstChild("Server")
    if serverInfo then
        serverInfo.CurrentStock.Changed:Connect(function()
            updateStockDisplay(folder.Name, serverInfo.CurrentStock.Value)
        end)
        updateStockDisplay(folder.Name, serverInfo.CurrentStock.Value)
    end
end
---