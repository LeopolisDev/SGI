-- PrestigeShopUI LocalScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local BuyUpgrade = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("BuyUpgrade")
local UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))

local gui = script.Parent

-- Prestige upgrade buttons (these should be in your PrestigeShopUI)
local buttons = {
	PrestigeMoneyMulti = gui:WaitForChild("PrestigeMoneyMultiButton"),
	PrestigeMaxMoney = gui:WaitForChild("PrestigeMaxMoneyButton"),
	PrestigePPMulti = gui:WaitForChild("PrestigePPMultiButton"),
	AutoUpgrader = gui:WaitForChild("AutoUpgraderButton"),
}

-- Prestige boost display label
local boostLabel = gui:WaitForChild("PrestigeBoostLabel")

-- Function to calculate prestige boost based on PP
local function calculatePrestigeBoost(prestigePoints)
	if prestigePoints <= 0 then return 1 end

	-- Scaling boost: 1pp = 1.5x, 10pp = 2.25x, 100pp = 3.375x, etc.
	local boost = 1.5 ^ (math.log10(math.max(1, prestigePoints)) + 1)
	return math.floor(boost * 100) / 100 -- Round to 2 decimal places
end

-- Function to format cost with PP abbreviation
local function formatPPCost(cost)
	if cost < 1000 then
		return math.floor(cost) .. " PP"
	else
		local suffixes = {"K", "M", "B", "T"}
		for i = #suffixes, 1, -1 do
			local divisor = 10 ^ (3 * i)
			if cost >= divisor then
				return string.format("%.1f%s PP", cost / divisor, suffixes[i])
			end
		end
		return math.floor(cost) .. " PP"
	end
end

-- Update the prestige boost display
local function updatePrestigeBoost()
	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	local boost = calculatePrestigeBoost(prestigePoints)

	boostLabel.Text = string.format("Prestige Boost: %.2fx Money", boost)
end

-- Update shop display
local function updateDisplay()
	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	updatePrestigeBoost()

	for upgradeName, cfg in pairs(UpgradeConfig) do
		-- Show prestige upgrades AND the auto-upgrader in this shop
		if string.sub(upgradeName, 1, 8) == "Prestige" or upgradeName == "AutoUpgrader" then
			local levelName = upgradeName .. "Level"
			local level = player:GetAttribute(levelName) or 0

			-- DEBUG: Print the level to see what's happening
			print(string.format("[UI DEBUG] %s - Level: %d, MaxLevel: %d", upgradeName, level, cfg.MaxLevel))

			local btn = buttons[upgradeName]

			if btn then
				if level < cfg.MaxLevel then
					local cost = cfg.Cost(level + 1)

					-- Show the effect of the upgrade
					local effectText = ""
					if upgradeName == "PrestigeMoneyMulti" then
						local currentMulti = player:GetAttribute("PrestigeMoneyMulti") or 1
						local nextMulti = 2 ^ (level + 1)
						effectText = string.format("(%.1fx → %.1fx)", currentMulti, nextMulti)
					elseif upgradeName == "PrestigeMaxMoney" then
						local currentBonus = player:GetAttribute("PrestigeMaxMoney") or 0
						local nextBonus = 50 * (level + 1)
						effectText = string.format("(+%d → +%d to blocks)", currentBonus, nextBonus)
					elseif upgradeName == "PrestigePPMulti" then
						local currentMulti = player:GetAttribute("PrestigePPMulti") or 1
						local nextMulti = 1.5 ^ (level + 1)
						effectText = string.format("(%.2fx → %.2fx)", currentMulti, nextMulti)
					elseif upgradeName == "AutoUpgrader" then
						effectText = "(Automatically buys shop upgrades)"
					end

					btn.Text = string.format("%s\nLevel: %d / %d %s\nCost: %s PP",
						cfg.DisplayName, level, cfg.MaxLevel, effectText, formatPPCost(cost))
					btn.AutoButtonColor = true
					btn.BackgroundTransparency = (prestigePoints >= cost) and 0 or 0.6
					btn.Active = (prestigePoints >= cost)
				else
					-- MAX LEVEL DISPLAY
					local maxEffectText = ""
					if upgradeName == "AutoUpgrader" then
						maxEffectText = "\nACTIVE - Auto-buying upgrades"
					end

					btn.Text = string.format("%s\nLevel: %d / %d%s\nMAX",
						cfg.DisplayName, level, cfg.MaxLevel, maxEffectText)
					btn.AutoButtonColor = false
					btn.Active = false
					btn.BackgroundTransparency = 0.4
				end
			end
		end
	end
end

-- Connect attribute-changed signals
for upgradeName, cfg in pairs(UpgradeConfig) do
	if string.sub(upgradeName, 1, 8) == "Prestige" then
		local levelName = upgradeName .. "Level"
		player:GetAttributeChangedSignal(levelName):Connect(updateDisplay)
	end
end

player:GetAttributeChangedSignal("PrestigePoints"):Connect(function()
	updateDisplay()
	updatePrestigeBoost()
end)

-- Buy on click
for name, btn in pairs(buttons) do
	if btn then
		btn.MouseButton1Click:Connect(function()
			BuyUpgrade:FireServer(name)
		end)
	end
end

-- Green styling for prestige buttons
for _, btn in pairs(buttons) do
	if btn then
		-- Set green color scheme
		btn.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Forest Green
		btn.TextColor3 = Color3.fromRGB(255, 255, 255) -- White text
		btn.BorderColor3 = Color3.fromRGB(0, 100, 0) -- Dark Green border

		-- Hover effects
		local originalColor = btn.BackgroundColor3
		local originalTextColor = btn.TextColor3

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(50, 205, 50) -- Lime Green on hover
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)

		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = originalColor
			btn.TextColor3 = originalTextColor
		end)

		-- Disabled state styling
		btn:GetPropertyChangedSignal("Active"):Connect(function()
			if not btn.Active then
				btn.BackgroundColor3 = Color3.fromRGB(107, 142, 35) -- Olive Green when disabled
				btn.TextColor3 = Color3.fromRGB(200, 200, 200) -- Gray text when disabled
			else
				btn.BackgroundColor3 = Color3.fromRGB(34, 139, 34) -- Back to normal green
				btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end)
	end
end

-- Also style the boost label with green theme
if boostLabel then
	boostLabel.TextColor3 = Color3.fromRGB(50, 205, 50) -- Lime Green
	boostLabel.TextStrokeColor3 = Color3.fromRGB(0, 100, 0) -- Dark Green outline
	boostLabel.TextStrokeTransparency = 0.5
end

-- React to server feedback
BuyUpgrade.OnClientEvent:Connect(function(success, msg)
	print("[PrestigeShop] Purchase result:", success, msg)
end)

-- Initial sync
updateDisplay()