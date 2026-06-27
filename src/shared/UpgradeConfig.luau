-- ReplicatedStorage.UpgradeConfig
-- NOTE: Rainbow block chance should be 1%, Gold block chance should be 5%.
-- If you want to change the actual spawn rates, edit the block spawn script!

local Upgrades = {
	["MaxMoney"] = {
		DisplayName = "+10 Max Money Block Value",
		MaxLevel = 10,
		Cost = function(level) return 500 * (level ^ 2) end, -- Increased cost, quadratic scaling
		Apply = function(player, level)
			print(string.format("[Upgrade] %s: Max money block value level increased to %d", player.Name, level))
		end,
	},
	["MoneyMultiplier"] = {
		DisplayName = "x1.2 Money Multiplier",
		MaxLevel = 5,
		Cost = function(level) return 2000 * (level ^ 2) end, -- Increased cost, quadratic scaling
		Apply = function(player, level)
			local baseMultiplier = 1
			local multiplier = baseMultiplier * (1.2 ^ level)
			player:SetAttribute("MoneyMultiplier", multiplier)
		end,
	},
	["WalkSpeed"] = {
		DisplayName = "+1 WalkSpeed",
		MaxLevel = 8,
		Cost = function(level) return 1000 * (level ^ 2) end, -- Increased cost, quadratic scaling
		Apply = function(player, level)
			player:SetAttribute("WalkSpeedLevel", level)
			player:SetAttribute("WalkSpeedBonus", level)
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.WalkSpeed = 16 + level
			end
		end,
	},
	["JumpPower"] = {
		DisplayName = "+2 JumpPower",
		MaxLevel = 10,
		Cost = function(level) return 1200 * (level ^ 2) end, -- Increased cost, quadratic scaling
		Apply = function(player, level)
			player:SetAttribute("JumpPowerLevel", level)
			player:SetAttribute("JumpPowerBonus", level * 2)
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.JumpPower = 50 + (2 * level)
			end
		end,
	},
	["PrestigePointsMulti"] = {
		DisplayName = "x1.5 Prestige Points Multiplier",
		MaxLevel = 20,
		Cost = function(level) return 500000 * (10 ^ (level - 1)) end, -- 500k, 5M, 50M, etc.
		Apply = function(player, level)
			local baseMultiplier = 1
			local multiplier = baseMultiplier * (1.5 ^ level)
			player:SetAttribute("PrestigePointsMulti", multiplier)
		end,
	},
	["PrestigeMoneyMulti"] = {
		DisplayName = "x2 Money Multiplier (Prestige)",
		MaxLevel = 5,
		Cost = function(level) 
			local cost = 10 * (10 ^ (level - 1)) -- 10, 100, 1000, 10000, 100000 PP
			return math.floor(cost)
		end,
		Apply = function(player, level)
			local multiplier = 2 ^ level
			player:SetAttribute("PrestigeMoneyMulti", multiplier)
		end,
	},
	["PrestigeMaxMoney"] = {
		DisplayName = "+50 Max Money (Prestige)",
		MaxLevel = 20,
		Cost = function(level) 
			local cost = 5 * (2 ^ (level - 1)) -- 5, 10, 20, 40, ... PP
			return math.floor(cost)
		end,
		Apply = function(player, level)
			local bonus = 50 * level
			player:SetAttribute("PrestigeMaxMoney", bonus)
		end,
	},
	["PrestigePPMulti"] = {
		DisplayName = "x1.5 PP Multiplier (Prestige)",
		MaxLevel = 20,
		Cost = function(level) 
			local cost = 100 * (10 ^ (level - 1)) -- 100, 1k, 10k, 100k, ... PP
			return math.floor(cost)
		end,
		Apply = function(player, level)
			local multiplier = 1.5 ^ level
			player:SetAttribute("PrestigePPMulti", multiplier)
		end,
	},
	["AutoUpgrader"] = {
		DisplayName = "Auto Upgrader (Buys ALL Shop Upgrades)",
		MaxLevel = 1,
		Cost = function(level) 
			return 10000 -- 10,000 PP (fixed cost, much higher)
		end,
		Apply = function(player, level)
			if level > 0 then
				player:SetAttribute("AutoUpgrader", true)
				print(string.format("[AUTO] %s activated Auto Upgrader", player.Name))
			end
		end,
	},
}

return Upgrades

