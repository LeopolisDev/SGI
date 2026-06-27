-- LocalScript inside the SurfaceGui (adorned to PrestigeButton model)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local PrestigeRequest = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PrestigeRequest")

-- references to GUI elements
local gui = script.Parent
local pointsLabel = gui:WaitForChild("PointsLabel")
local costLabel = gui:WaitForChild("CostLabel")
local clickButton = gui:WaitForChild("PrestigeButton")

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

-- Fixed precise prestige tiers calculation
local function calculatePrestigeInfo(money)
	local pointsCanGet = 0
	local nextCost = 10000

	if money >= 10000 then
		local tierCost = 10000
		local currentTier = 1

		-- Calculate how many complete tiers we can afford
		while money >= tierCost do
			pointsCanGet = currentTier
			currentTier += 1
			nextCost = math.floor(tierCost * 1.5)
			tierCost = nextCost

			-- Safety break
			if currentTier > 100 then break end
		end
	else
		pointsCanGet = 0
		nextCost = 10000
	end

	-- Apply PrestigePointsMulti AND PrestigePPMulti to the points you'll get
	local prestigeMultiplier = player:GetAttribute("PrestigePointsMulti") or 1
	local prestigePPMulti = player:GetAttribute("PrestigePPMulti") or 1
	local totalMultiplier = prestigeMultiplier * prestigePPMulti
	local finalPointsCanGet = math.floor(pointsCanGet * totalMultiplier)

	return finalPointsCanGet, nextCost
end

-- Update board labels
local function updateBoard()
	local money = player:GetAttribute("Money") or 0
	local pointsCanGet, nextCost = calculatePrestigeInfo(money)

	-- ONLY abbreviate the points label - don't change the text format
	pointsLabel.Text = "Prestige Points You Will Get: " .. formatNumber(pointsCanGet)

	-- Keep everything else EXACTLY the same
	costLabel.Text = "Next Prestige Cost: " .. formatNumber(nextCost)
	clickButton.Text = "Prestige!"  -- UNCHANGED - no formatting here
	clickButton.Active = (pointsCanGet > 0)
	clickButton.AutoButtonColor = (pointsCanGet > 0)
end

-- Click handler
clickButton.MouseButton1Click:Connect(function()
	PrestigeRequest:FireServer()
	task.delay(0.5, updateBoard) -- Give time for server to process
end)

-- Auto-update when money or multipliers change
player:GetAttributeChangedSignal("Money"):Connect(updateBoard)
player:GetAttributeChangedSignal("PrestigePointsMulti"):Connect(updateBoard)
player:GetAttributeChangedSignal("PrestigePPMulti"):Connect(updateBoard)

-- Initialize UI on first load
updateBoard()