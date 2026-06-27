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

local function addMoney(player, amount)
	if not player or not player.Parent then return end
	local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Money")
	if stat then
		local current = stat.Value
		local newValue = NumberHandler.safeAdd(current, amount)

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