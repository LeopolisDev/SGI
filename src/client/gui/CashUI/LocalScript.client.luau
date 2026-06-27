local Players = game:GetService("Players")
local player = Players.LocalPlayer
local moneyLabel = script.Parent:WaitForChild("MoneyLabel")
local NumberHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberHandler"))

local function updateMoney(newValue)
	local currentText = moneyLabel.Text
	-- Extract numeric value from formatted text
	local currentValue = tonumber(currentText:match("%d+%.?%d*")) or 0

	-- For animation, we'll only animate if numbers are reasonably small
	if newValue < 1000000 and currentValue < 1000000 then
		for i = 1, 10 do
			local lerp = currentValue + (newValue - currentValue) * (i / 10)
			moneyLabel.Text = "₵ " .. NumberHandler.formatNumber(lerp)
			task.wait(0.01)
		end
	end

	moneyLabel.Text = "₵ " .. NumberHandler.formatNumber(newValue)
end

local function watchStat()
	local stats = player:WaitForChild("leaderstats")
	local money = stats:WaitForChild("Money")

	updateMoney(money.Value)
	money:GetPropertyChangedSignal("Value"):Connect(function()
		updateMoney(money.Value)
	end)
end

if player:FindFirstChild("leaderstats") then
	watchStat()
else
	player.ChildAdded:Connect(function(child)
		if child.Name == "leaderstats" then
			watchStat()
		end
	end)
end