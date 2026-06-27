-- CurrencyService (ModuleScript)
local Players = game:GetService("Players")

local function setupLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = player:GetAttribute("Money") or 0
	money.Parent = leaderstats
end

Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)

	-- Sync leaderstats with attribute
	local moneyVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if moneyVal then
		moneyVal.Value = player:GetAttribute("Money") or 0
	end
end)

local function subtractMoney(player, amount)
	if not player or not player.Parent then return false end

	local current = player:GetAttribute("Money") or 0

	if current < amount then
		warn(string.format("[Currency] %s tried to subtract %d but only has %d", player.Name, amount, current))
		return false
	end

	local newValue = current - amount

	player:SetAttribute("Money", newValue)
	local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if stat then
		stat.Value = newValue
	end

	print(string.format("[Currency] %s: -%d (new total: %d)", player.Name, amount, newValue))
	return true
end

-- Add this function to CurrencyService
local function calculatePrestigeBoost(prestigePoints)
	if prestigePoints <= 0 then return 1 end

	-- Scaling boost: 1pp = 1.5x, 10pp = 2.25x, 100pp = 3.375x, etc.
	local boost = 1.5 ^ (math.log10(math.max(1, prestigePoints)) + 1)
	return math.floor(boost * 100) / 100 -- Round to 2 decimal places
end

-- In CurrencyService, update the addMoney function to REMOVE all money caps:
local function addMoney(player, amount)
	if not player or not player.Parent then return end

	local current = player:GetAttribute("Money") or 0

	-- Calculate all multipliers
	local baseMultiplier = player:GetAttribute("MoneyMultiplier") or 1
	local prestigeMoneyMulti = player:GetAttribute("PrestigeMoneyMulti") or 1
	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	local prestigeBoost = calculatePrestigeBoost(prestigePoints)

	local totalMultiplier = baseMultiplier * prestigeMoneyMulti * prestigeBoost
	local multipliedAmount = math.floor(amount * totalMultiplier)

	local newValue = current + multipliedAmount

	print(string.format("[Currency] %s: %d × %.2fx = %d (total: %d)", 
		player.Name, amount, totalMultiplier, multipliedAmount, newValue))

	if newValue <= 1e308 then
		player:SetAttribute("Money", newValue)
		local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
		if stat then
			stat.Value = newValue
		end
	else
		warn("Money overflow prevented for", player.Name)
	end
end

local module = {}
module.AddMoney = addMoney
module.GetMoney = function(player)
	return player:GetAttribute("Money") or 0
end

return module