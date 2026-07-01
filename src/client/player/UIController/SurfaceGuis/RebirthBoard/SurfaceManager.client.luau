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

-- Infinite number formatting function for the points label ONLY
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

-- Fixed precise rebirth calculation
local function calculateRebirthInfo(money, prestigePoints, rebirthPoints)
	local rebirthCostMoney = 1000000000 * (1.5 ^ rebirthPoints)
	local rebirthCostPP = 2500000000 * (1.5 ^ rebirthPoints)
	
	local canRebirth = (money >= rebirthCostMoney and prestigePoints >= rebirthCostPP)
	local pointsCanGet = canRebirth and 1 or 0

	return pointsCanGet, rebirthCostMoney, rebirthCostPP
end

-- Update board labels
local function updateBoard()
	local money = player:GetAttribute("Money") or 0
	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	local rebirthPoints = player:GetAttribute("RebirthPoints") or 0
	
	local pointsCanGet, rebirthCostMoney, rebirthCostPP = calculateRebirthInfo(money, prestigePoints, rebirthPoints)

	-- Update labels
	pointsLabel.Text = "Rebirth Points You Will Get: " .. formatNumber(pointsCanGet)
	costLabel.Text = "Next Rebirth Cost: " .. formatNumber(rebirthCostMoney) .. " Money & " .. formatNumber(rebirthCostPP) .. " PP"
	clickButton.Text = "Rebirth!"
	clickButton.Active = (pointsCanGet > 0)
	clickButton.AutoButtonColor = (pointsCanGet > 0)
end

-- Click handler
clickButton.MouseButton1Click:Connect(function()
	RebirthRequest:FireServer()
	task.delay(0.5, updateBoard) -- Give time for server to process
end)

-- Auto-update when money, PP, or rebirth points changes
player:GetAttributeChangedSignal("Money"):Connect(updateBoard)
player:GetAttributeChangedSignal("PrestigePoints"):Connect(updateBoard)
player:GetAttributeChangedSignal("RebirthPoints"):Connect(updateBoard)

-- Initialize UI on first load
updateBoard()