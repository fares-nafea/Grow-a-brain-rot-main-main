-- seedFrameHandler

local replicatedStorage = game:GetService("ReplicatedStorage")
local lighting = game:GetService("Lighting")
local tweenService = game:GetService("TweenService")

local remotes = replicatedStorage:WaitForChild("Remotes")
local modules = replicatedStorage:WaitForChild("Modules")
local seedDataModule = require(modules.SeedData)

local mainGui = script.Parent

local eventsFolder = mainGui:WaitForChild("Events")
local root = mainGui:WaitForChild("Root")

local seedsFrame = root:WaitForChild("Frames"):WaitForChild("SeedsFrame")
local configurationFolder = mainGui:WaitForChild("Configuration")

-- Default
seedsFrame.Visible = false
seedsFrame.Size = UDim2.new(0.3,0,0,0)

------- Scripting Seeds List

local listFrame = seedsFrame.List

local function updateList()
	for _, v in listFrame:GetChildren() do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	
	local seedOrder = seedDataModule.getSeedOrder()
	for _, seedName: string in seedOrder do
		local correspondingData = seedDataModule.getData(seedName)
		if correspondingData then
			local clone = script.Template:Clone()
			clone.Name = seedName
			clone.Cost.Text = correspondingData.Cost.Value.."$"
			clone.Title.Text = correspondingData.DisplayName.Value
			clone.StockCount.Text = "X"..correspondingData.Server.CurrentStock.Value.." Stock"
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
-------

eventsFolder.ToggleSeedFrame.Event:Connect(function(bool: boolean)
	if configurationFolder.seedFrameDebounce.Value then return end
	
	configurationFolder.seedFrameDebounce.Value = true
	task.delay(.4, function()
		configurationFolder.seedFrameDebounce.Value = false
	end)
	
	if bool == true then
		-- Make Visible
		task.spawn(function()
			local foundBlur = lighting:FindFirstChild("SeedShopBlur")
			if foundBlur then foundBlur:Destroy() end
		end)
		-- Adding in BlurEffect
		local blur = Instance.new("BlurEffect")
		blur.Name = "SeedShopBlur"
		blur.Size = 0
		blur.Parent = lighting
		tweenService:Create(blur, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = 14
		}):Play()
		------
		
		seedsFrame.Visible = true
		seedsFrame:TweenSize(UDim2.new(0.3,0,0.6,0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.25, true)
	else
		
		-- Removing Blur
		local foundBlur = lighting:FindFirstChild("SeedShopBlur")
		if foundBlur then
			tweenService:Create(foundBlur, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = 0
			}):Play()
			task.delay(.5, function()
				foundBlur:Destroy()
			end)
		end
		------
		
		-- Make Invisible
		seedsFrame:TweenSize(UDim2.new(0.3,0,0,0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.25, true)
		task.delay(.4, function()
			seedsFrame.Visible = false
		end)
	end
end)

seedsFrame.Exit.MouseButton1Click:Connect(function()
	eventsFolder.ToggleSeedFrame:Fire(false)
end)