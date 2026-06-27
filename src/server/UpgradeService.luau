-- ServerScriptService/UpgradeService
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local BuyUpgrade = RemoteEvents:FindFirstChild("BuyUpgrade") or Instance.new("RemoteEvent", RemoteEvents)
BuyUpgrade.Name = "BuyUpgrade"

-- Optional event to notify client about success/failure
local UpgradeResult = RemoteEvents:FindFirstChild("UpgradeResult")
if not UpgradeResult then
	UpgradeResult = Instance.new("RemoteEvent", RemoteEvents)
	UpgradeResult.Name = "UpgradeResult"
end

-- Require CurrencyService (adjust path if your module is elsewhere)
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))

local function applyPlayerUpgradeEffects(player, upgradeName, newLevel)
	-- Keep Apply logic in UpgradeConfig.Apply (if present)
	local cfg = UpgradeConfig[upgradeName]
	if cfg and type(cfg.Apply) == "function" then
		-- call it safely (it might try to change Humanoid)
		local ok, err = pcall(function() cfg.Apply(player, newLevel) end)
		if not ok then
			warn("Apply failed for", upgradeName, err)
		end
	end
end

-- In UpgradeService, update the initPlayer function:
local function initPlayer(plr)
	if plr:GetAttribute("MoneyMultiplier") == nil then plr:SetAttribute("MoneyMultiplier", 1) end
	if plr:GetAttribute("MaxMoney") == nil then plr:SetAttribute("MaxMoney", 100) end

	for name, _ in pairs(UpgradeConfig) do
		local levelName = name .. "Level"
		if plr:GetAttribute(levelName) == nil then
			plr:SetAttribute(levelName, 0)
		end
	end

	-- ensure upgrades applied on spawn
	plr.CharacterAdded:Connect(function(char)
		-- small delay for Humanoid to exist
		task.wait(0.5)
		for name, _ in pairs(UpgradeConfig) do
			local lvl = plr:GetAttribute(name .. "Level") or 0
			if lvl > 0 then
				applyPlayerUpgradeEffects(plr, name, lvl)
				print("[UpgradeService] Re-applied", name, "level", lvl, "to", plr.Name)
			end
		end
	end)
end

Players.PlayerAdded:Connect(initPlayer)

BuyUpgrade.OnServerEvent:Connect(function(player, upgradeName)
	if not player or not upgradeName then return end
	local cfg = UpgradeConfig[upgradeName]
	if not cfg then
		UpgradeResult:FireClient(player, false, "Unknown upgrade")
		return
	end

	local levelName = upgradeName .. "Level"
	local currentLevel = player:GetAttribute(levelName) or 0

	if currentLevel >= cfg.MaxLevel then
		UpgradeResult:FireClient(player, false, "Already at max level")
		return
	end

	local cost = cfg.Cost(currentLevel + 1)

	-- FIXED: Explicit list of upgrades that cost PP
	local prestigeUpgrades = {
		"PrestigeMoneyMulti",
		"PrestigeMaxMoney", 
		"PrestigePPMulti",
		"AutoUpgrader"  -- THIS MUST BE INCLUDED
	}

	local isPrestigeUpgrade = false
	for _, name in ipairs(prestigeUpgrades) do
		if upgradeName == name then
			isPrestigeUpgrade = true
			break
		end
	end

	print(string.format("[UPGRADE DEBUG] %s buying %s - Prestige: %s, Cost: %d", 
		player.Name, upgradeName, tostring(isPrestigeUpgrade), cost))

	if isPrestigeUpgrade then
		-- Prestige upgrade - cost PP
		local pp = player:GetAttribute("PrestigePoints") or 0
		print(string.format("[UPGRADE DEBUG] Player PP: %d, Needed: %d", pp, cost))
		if pp < cost then
			UpgradeResult:FireClient(player, false, "Not enough prestige points")
			return
		end

		-- Deduct PP
		player:SetAttribute("PrestigePoints", pp - cost)
		print(string.format("[UPGRADE DEBUG] Deducted %d PP, new PP: %d", cost, pp - cost))
	else
		-- Normal upgrade - cost money
		local money = player:GetAttribute("Money") or 0
		print(string.format("[UPGRADE DEBUG] Player Money: %d, Needed: %d", money, cost))
		if money < cost then
			UpgradeResult:FireClient(player, false, "Not enough money")
			return
		end

		-- Directly deduct money WITHOUT using CurrencyService.AddMoney
		local newMoney = money - cost
		player:SetAttribute("Money", newMoney)

		-- Update leaderstats
		local stats = player:FindFirstChild("leaderstats")
		if stats then
			local moneyVal = stats:FindFirstChild("Money")
			if moneyVal then
				moneyVal.Value = newMoney
			end
		end
		print(string.format("[UPGRADE DEBUG] Deducted %d money, new money: %d", cost, newMoney))
	end

	-- Increase level and apply effect
	player:SetAttribute(levelName, currentLevel + 1)
	applyPlayerUpgradeEffects(player, upgradeName, currentLevel + 1)

	UpgradeResult:FireClient(player, true, "Purchased " .. tostring(upgradeName))
	print(string.format("[UpgradeService] %s bought %s lvl %d for %d %s", 
		player.Name, upgradeName, currentLevel+1, cost, isPrestigeUpgrade and "PP" or "money"))
end)

	-- Automation system
	local AUTO_UPGRADE_INTERVAL = 1 -- Check every 10 seconds

	local function getNextAffordableUpgrade(player)
		local money = player:GetAttribute("Money") or 0
		local affordableUpgrades = {}

		for upgradeName, cfg in pairs(UpgradeConfig) do
			-- Skip prestige upgrades and the auto-upgrader itself
			if string.sub(upgradeName, 1, 8) ~= "Prestige" and upgradeName ~= "AutoUpgrader" then
				local levelName = upgradeName .. "Level"
				local currentLevel = player:GetAttribute(levelName) or 0

				if currentLevel < cfg.MaxLevel then
					local cost = cfg.Cost(currentLevel + 1)
					if money >= cost then
						table.insert(affordableUpgrades, {
							Name = upgradeName,
							Cost = cost,
							Level = currentLevel + 1
						})
					end
				end
			end
		end

		-- Sort by cost (cheapest first) or priority
		table.sort(affordableUpgrades, function(a, b)
			return a.Cost < b.Cost
		end)

		return affordableUpgrades[1] -- Return the cheapest affordable upgrade
	end

	local function performAutoUpgrade(player)
		if not player:GetAttribute("AutoUpgrader") then return end

		local nextUpgrade = getNextAffordableUpgrade(player)
		if nextUpgrade then
			-- Simulate buying the upgrade
			local upgradeName = nextUpgrade.Name
			local cfg = UpgradeConfig[upgradeName]
			local levelName = upgradeName .. "Level"
			local currentLevel = player:GetAttribute(levelName) or 0
			local cost = nextUpgrade.Cost

			-- Deduct money
			local money = player:GetAttribute("Money") or 0
			player:SetAttribute("Money", money - cost)

			-- Update leaderstats
			local stats = player:FindFirstChild("leaderstats")
			if stats then
				local moneyVal = stats:FindFirstChild("Money")
				if moneyVal then
					moneyVal.Value = money - cost
				end
			end

			-- Increase level and apply effect
			player:SetAttribute(levelName, currentLevel + 1)
			applyPlayerUpgradeEffects(player, upgradeName, currentLevel + 1)

			print(string.format("[AUTO] %s automatically bought %s level %d for %d", 
				player.Name, upgradeName, currentLevel + 1, cost))

			-- Notify player
			local AutoUpgradeNotification = RemoteEvents:FindFirstChild("AutoUpgradeNotification")
			if AutoUpgradeNotification then
				AutoUpgradeNotification:FireClient(player, upgradeName, currentLevel + 1, cost)
			end
		end
	end

	-- Auto-upgrade loop
	task.spawn(function()
		while true do
			task.wait(AUTO_UPGRADE_INTERVAL)

			for _, player in ipairs(Players:GetPlayers()) do
				if player:GetAttribute("AutoUpgrader") then
					local success, err = pcall(function()
						performAutoUpgrade(player)
					end)
					if not success then
						warn("[AUTO] Error in auto-upgrade for", player.Name, err)
					end
				end
			end
		end
	end)