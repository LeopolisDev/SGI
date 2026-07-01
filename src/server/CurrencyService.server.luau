local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local NumberHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("NumberHandler"))

local moneyStore = DataStoreService:GetDataStore("CashgrabMoney_v1")
local STARTING_MONEY = 0
local MAX_SAFE_NUMBER = 1e300 -- Stay well below Roblox limit

local function setupLeaderstats(player)
	local leaderstatsExists = Instance.new("Folder")
	if leaderstatsExists then
		return
	elseif not leaderstatsExists then
		leaderstatsExists.Name = "leaderstats"
		leaderstatsExists.Parent = player
	end

	local money = Instance.new("NumberValue")
	money.Name = "Money"
	money.Value = STARTING_MONEY
	money.Parent = leaderstatsExists

	player:SetAttribute("Money", money.Value)
end

local function saveMoney(player)
	local success, err = pcall(function()
		local moneyVal = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money") and player.leaderstats.Money.Value or 0
		moneyStore:SetAsync("player_"..player.UserId, moneyVal)
	end)
	if not success then
		warn("Failed to save money for", player.Name, err)
	end
end

local function loadMoney(player)
	local saved
	local success, err = pcall(function()
		saved = moneyStore:GetAsync("player_"..player.UserId)
	end)
	if not success then
		warn("Failed to load money for", player.Name, err)
	end
	return saved
end

Players.PlayerAdded:Connect(function(player)
	setupLeaderstats(player)
	local stored = loadMoney(player)
	if type(stored) == "number" then
		player.leaderstats.Money.Value = stored
	end
	player:SetAttribute("Money", player.leaderstats.Money.Value)
end)

Players.PlayerRemoving:Connect(function(player)
	saveMoney(player)
end)

local function calculatePrestigeBoost(prestigePoints)
	if prestigePoints <= 0 then return 1 end

	-- Scaling boost: 1pp = 1.5x, 10pp = 2.25x, 100pp = 3.375x, etc.
	local boost = 1.5 ^ (math.log10(math.max(1, prestigePoints)) + 1)
	return math.floor(boost * 100) / 100 -- Round to 2 decimal places
end

local function addMoney(player, amount, ignoreMultipliers)
	if not player or not player.Parent then return end
	local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if stat then
		local current = stat.Value
		local finalAmount = amount

		if not ignoreMultipliers then
			local baseMultiplier = player:GetAttribute("MoneyMultiplier") or 1
			local prestigeMoneyMulti = player:GetAttribute("PrestigeMoneyMulti") or 1
			local prestigePoints = player:GetAttribute("PrestigePoints") or 0
			local prestigeBoost = calculatePrestigeBoost(prestigePoints)
			local rebirthPoints = player:GetAttribute("RebirthPoints") or 0
			local rebirthMultiplier = 1.5 ^ rebirthPoints

			local totalMultiplier = baseMultiplier * prestigeMoneyMulti * prestigeBoost * rebirthMultiplier
			finalAmount = math.floor(amount * totalMultiplier)
			
			print(string.format("[Currency] %s: Base %d × %.2fx (Rebirth: %.2fx) = %d", 
				player.Name, amount, totalMultiplier, rebirthMultiplier, finalAmount))
		else
			print(string.format("[Currency] %s: Added raw %d", player.Name, amount))
		end

		local newValue = NumberHandler.safeAdd(current, finalAmount)

		if NumberHandler.isSafeNumber(newValue) then
			stat.Value = newValue
			player:SetAttribute("Money", stat.Value)
		else
			warn("Money overflow prevented for player", player.Name)
			-- Cap at safe limit
			stat.Value = MAX_SAFE_NUMBER
			player:SetAttribute("Money", MAX_SAFE_NUMBER)
		end
	end
end

local module = {}
module.AddMoney = addMoney
module.GetMoney = function(player)
	return player:GetAttribute("Money") or 0
end

return module