-- ShopGui LocalScript (Client)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local BuyUpgrade = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyUpgrade")
local UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))

local gui = script.Parent

-- Buttons: ensure these objects exist in your GUI
local buttons = {
	MaxMoney = gui:WaitForChild("MaxMoneyButton"),
	MoneyMultiplier = gui:WaitForChild("MoneyMultiplierButton"),
	WalkSpeed = gui:WaitForChild("WalkSpeedButton"),
	JumpPower = gui:WaitForChild("JumpPowerButton"),
	PrestigePointsMulti = gui:WaitForChild("PrestigePointsMultiButton"),
}

local function formatCost(cost)
	if type(cost) == "number" then return tostring(cost) end
	return tostring(cost)
end

local function updateDisplay()
	local money = player:GetAttribute("Money") or 0

	for upgradeName, cfg in pairs(UpgradeConfig) do
		local levelName = upgradeName .. "Level"
		local level = player:GetAttribute(levelName) or 0
		local btn = buttons[upgradeName]
		if not btn then
			-- if button missing, skip
		else
			if level < cfg.MaxLevel then
				local cost = cfg.Cost(level + 1)

				-- Show the actual effect of the next level (no boosts)
				local effectText = ""
				if upgradeName == "MoneyMultiplier" then
					local currentMulti = 1.2 ^ level
					local nextMulti = 1.2 ^ (level + 1)
					effectText = string.format("(%.2fx → %.2fx)", currentMulti, nextMulti)
				elseif upgradeName == "MaxMoney" then
					-- FIXED: Calculate actual block value changes
					local baseMax = 50  -- Base max block value
					local currentMax = baseMax + (10 * level)  -- +10 per level
					local nextMax = baseMax + (10 * (level + 1))
					effectText = string.format("(%d → %d per block)", currentMax, nextMax)
				elseif upgradeName == "PrestigePointsMulti" then
					local currentMulti = 1.5 ^ level
					local nextMulti = 1.5 ^ (level + 1)
					effectText = string.format("(%.2fx → %.2fx)", currentMulti, nextMulti)
				elseif upgradeName == "WalkSpeed" then
					local currentSpeed = 16 + level
					local nextSpeed = 16 + (level + 1)
					effectText = string.format("(%d → %d)", currentSpeed, nextSpeed)
				elseif upgradeName == "JumpPower" then
					local currentPower = 50 + (2 * level)
					local nextPower = 50 + (2 * (level + 1))
					effectText = string.format("(%d → %d)", currentPower, nextPower)
				end

				btn.Text = string.format("%s\nLevel: %d / %d %s\nCost: %s",
					cfg.DisplayName, level, cfg.MaxLevel, effectText, formatCost(cost))
				btn.AutoButtonColor = true
				btn.BackgroundTransparency = (money >= cost) and 0 or 0.6
				btn.Active = (money >= cost)
			else
				-- Show final stats for max level (no boosts)
				local finalEffectText = ""
				if upgradeName == "MoneyMultiplier" then
					local finalMulti = 1.2 ^ level
					finalEffectText = string.format("(%.2fx)", finalMulti)
				elseif upgradeName == "MaxMoney" then
					-- FIXED: Show actual final block value
					local baseMax = 50
					local finalMax = baseMax + (10 * level)
					finalEffectText = string.format("(%d per block)", finalMax)
				elseif upgradeName == "PrestigePointsMulti" then
					local finalMulti = 1.5 ^ level
					finalEffectText = string.format("(%.2fx)", finalMulti)
				elseif upgradeName == "WalkSpeed" then
					local finalSpeed = 16 + level
					finalEffectText = string.format("(%d)", finalSpeed)
				elseif upgradeName == "JumpPower" then
					local finalPower = 50 + (2 * level)
					finalEffectText = string.format("(%d)", finalPower)
				end

				btn.Text = string.format("%s\nLevel: %d / %d %s\nMAX",
					cfg.DisplayName, level, cfg.MaxLevel, finalEffectText)
				btn.AutoButtonColor = false
				btn.Active = false
				btn.BackgroundTransparency = 0.4
			end
		end
	end
end

-- Connect attribute-changed signals for levels and money so UI updates live
for upgradeName, cfg in pairs(UpgradeConfig) do
	local levelName = upgradeName .. "Level"
	player:GetAttributeChangedSignal(levelName):Connect(updateDisplay)
end
player:GetAttributeChangedSignal("Money"):Connect(updateDisplay)

-- Buy on click
for name, btn in pairs(buttons) do
	btn.MouseButton1Click:Connect(function()
		BuyUpgrade:FireServer(name)
	end)
end

-- React to server feedback (optional)
BuyUpgrade.OnClientEvent:Connect(function(success, msg)
	-- optionally show a message to the player (Toast / Label)
	print("[BuyUpgrade feedback]", success, msg)
end)

-- Initial sync
updateDisplay()