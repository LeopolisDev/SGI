-- LocalScript inside the SurfaceGui (adorned to RebirthButton model)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RebirthRequest = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RebirthRequest")

-- references to GUI elements
local gui = script.Parent
local pointsLabel = gui:WaitForChild("PointsLabel")
local costLabel = gui:WaitForChild("CostLabel")
local clickButton = gui:WaitForChild("RebirthButton")

-- Link the GUI to the physical board part
local board = game.Workspace:FindFirstChild("Lobby", true)
if board then
	board = board:FindFirstChild("Boards")
	if board then
		board = board:FindFirstChild("RebirthButton")
		if board then
			board = board:FindFirstChild("RebirthBoard")
			if board then
				gui.Adornee = board
			end
		end
	end
end

-- Infinite number formatting function
local function formatNumber(num)
	if num < 1000 then
		return tostring(math.floor(num))
	end

	local suffixes = {"K", "M", "B", "T", "Qd", "Qt", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Od", "Nd", "V", "Uv", "Dv", "Tv", "Qav", "Qiv", "Sxv", "Spv", "Ov", "Nv", "Tr", "Utr", "Dtr"}

	local exponent = math.floor(math.log10(num))
	local suffixIndex = math.floor(exponent / 3)

	if exponent >= 36 then
		return string.format("%.2fe%d", num / (10 ^ exponent), exponent)
	end

	if suffixIndex > 0 and suffixIndex <= #suffixes then
		return string.format("%.2f%s", num / (10 ^ (suffixIndex * 3)), suffixes[suffixIndex])
	else
		local value = num / 1000
		return string.format("%.2f%s", value, "K")
	end
end

-- Update board labels
local function updateBoard()
	local money = player:GetAttribute("Money") or 0
	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	local rebirthPoints = player:GetAttribute("RebirthPoints") or 0
	
	local rebirthCostMoney = 1000000000 * (1.5 ^ rebirthPoints)
	local rebirthCostPP = 2500000000 * (1.5 ^ rebirthPoints)
    
    local canRebirth = (money >= rebirthCostMoney and prestigePoints >= rebirthCostPP)
    local pointsToGet = canRebirth and 1 or 0

	pointsLabel.Text = "Rebirth Points You Will Get: " .. pointsToGet
	costLabel.Text = "Cost: " .. formatNumber(rebirthCostMoney) .. " Money & " .. formatNumber(rebirthCostPP) .. " PP"
	
	clickButton.Active = canRebirth
	clickButton.AutoButtonColor = canRebirth
    clickButton.BackgroundColor3 = canRebirth and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(130, 130, 130)
end

-- Click handler
clickButton.MouseButton1Click:Connect(function()
	RebirthRequest:FireServer()
	task.delay(0.5, updateBoard)
end)

-- Auto-update when money, PP, or rebirth points changes
player:GetAttributeChangedSignal("Money"):Connect(updateBoard)
player:GetAttributeChangedSignal("PrestigePoints"):Connect(updateBoard)
player:GetAttributeChangedSignal("RebirthPoints"):Connect(updateBoard)

-- Initialize UI on first load
updateBoard()