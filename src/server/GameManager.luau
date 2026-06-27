-- GameManager
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataStoreService = game:GetService("DataStoreService")
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))

print("[GM] Starting GameManager")

-- DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerData_8")

-- RemoteEvents folder
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
	print("[GM] Created RemoteEvents")
end

local function ensureEvent(name)
	local ev = RemoteEvents:FindFirstChild(name)
	if not ev then
		ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = RemoteEvents
		print("[GM] Created RemoteEvent:", name)
	end
	return ev
end

local RequestPickup = ensureEvent("RequestPickup")
local RoundTimerUpdate = ensureEvent("RoundTimerUpdate")
local PlayRequest = ensureEvent("PlayRequest")
local PrestigeRequest = ensureEvent("PrestigeRequest")
local RebirthRequest = ensureEvent("RebirthRequest")

local GOLD_SPAWN_CHANCE = 0.1 -- 10% chance for gold blocks
local RAINBOW_SPAWN_CHANCE = 0.05 -- 5% chance for rainbow blocks (NEW)
local AdminGiveMoney = ensureEvent("AdminGiveMoney")
local AdminGivePrestige = ensureEvent("AdminGivePrestige")

-- Rebirth cost defaults
local rebirthCostMoney = 1000000000 -- 1B
local rebirthCostPP = 2500000000 -- 2.5B

-- Admin Give Prestige handler
AdminGivePrestige.OnServerEvent:Connect(function(player, targetPlayerName, amount)
	if player.Name ~= "YTOpleoni_YT" then
		player:Kick("Not Owner")
		return
	end

	if not targetPlayerName or not amount then
		warn("[ADMIN] Missing parameters from", player.Name)
		return
	end

	amount = tonumber(amount)
	if not amount then
		warn("[ADMIN] Invalid amount from", player.Name)
		return
	end

	-- Find the target player
	local targetPlayer
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == targetPlayerName:lower() then
			targetPlayer = plr
			break
		end
	end

	if not targetPlayer then
		-- Try partial match
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Name:lower():find(targetPlayerName:lower(), 1, true) then
				targetPlayer = plr
				break
			end
		end
	end

	if targetPlayer then
		-- Give prestige points to the target player
		local currentPrestige = targetPlayer:GetAttribute("PrestigePoints") or 0
		local newPrestige = currentPrestige + amount

		targetPlayer:SetAttribute("PrestigePoints", newPrestige)

		print(string.format("[ADMIN] %s gave %d prestige points to %s (new total: %d)", 
			player.Name, amount, targetPlayer.Name, newPrestige))
	else
		warn("[ADMIN] Player not found:", targetPlayerName)
	end
end)

-- Admin Give Money handler
AdminGiveMoney.OnServerEvent:Connect(function(player, targetPlayerName, amount)
	if player.Name ~= "YTOpleoni_YT" then
		player:Kick("Not Owner")
		return
	end

	if not targetPlayerName or not amount then
		warn("[ADMIN] Missing parameters from", player.Name)
		return
	end

	amount = tonumber(amount)
	if not amount then
		warn("[ADMIN] Invalid amount from", player.Name)
		return
	end

	-- Find the target player
	local targetPlayer
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower() == targetPlayerName:lower() then
			targetPlayer = plr
			break
		end
	end

	if not targetPlayer then
		-- Try partial match
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Name:lower():find(targetPlayerName:lower(), 1, true) then
				targetPlayer = plr
				break
			end
		end
	end

	if targetPlayer then
		-- Give money to the target player
		local currentMoney = targetPlayer:GetAttribute("Money") or 0
		local newMoney = currentMoney + amount

		targetPlayer:SetAttribute("Money", newMoney)

		-- Update leaderstats
		local stats = targetPlayer:FindFirstChild("leaderstats")
		if stats then
			local moneyVal = stats:FindFirstChild("Money")
			if moneyVal then
				moneyVal.Value = newMoney
			end
		end

		print(string.format("[ADMIN] %s gave %d money to %s (new total: %d)", 
			player.Name, amount, targetPlayer.Name, newMoney))
	else
		warn("[ADMIN] Player not found:", targetPlayerName)
	end
end)

-- Cash template
local CashTemplate = ReplicatedStorage:FindFirstChild("CashTemplate")
if not CashTemplate then
	warn("[GM] CashTemplate missing in ReplicatedStorage!")
else
	print("[GM] CashTemplate found")
end

-- Collect spawn points
local spawnPoints = {}
local mapsFolder = Workspace:FindFirstChild("Maps")
local spawnMap = mapsFolder and mapsFolder:FindFirstChild("DefaultMap")
if spawnMap then
	for _, part in pairs(spawnMap:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == "CashSpawnPoint" then
			table.insert(spawnPoints, part.Position)
		end
	end
	print("[GM] Collected spawn points:", #spawnPoints)
else
	warn("[GM] Maps.DefaultMap not found")
end

-- Settings
local ROUND_DURATION = 100
local roundRunning = false

-- Helpers
local function getActivePlayers()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("InGame") then table.insert(t, p) end
	end
	return t
end

local function spawnCash(position)
	if not CashTemplate then return end

	-- Decide block type with chances: 85% Cash, 10% Gold, 5% Rainbow
	local blockType = "Cash"
	local randomValue = math.random()

	if randomValue <= RAINBOW_SPAWN_CHANCE then
		blockType = "Rainbow"
	elseif randomValue <= RAINBOW_SPAWN_CHANCE + GOLD_SPAWN_CHANCE then
		blockType = "Gold"
	end

	-- Choose template based on block type
	local template = ReplicatedStorage:FindFirstChild(blockType .. "Template") or CashTemplate

	local clone = template:Clone()
	clone.Name = blockType .. "Pickup"

	if clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new(position + Vector3.new(0, 2, 0)))
	else
		pcall(function() clone:PivotTo(CFrame.new(position + Vector3.new(0, 2, 0))) end)
	end

	clone.Parent = Workspace

	-- Calculate max amount
	local baseMaxAmount = 50
	local highestMaxMoney = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local playerMaxMoneyLevel = player:GetAttribute("MaxMoneyLevel") or 0
		local playerPrestigeMaxMoney = player:GetAttribute("PrestigeMaxMoney") or 0
		local playerTotalBonus = (playerMaxMoneyLevel * 10) + playerPrestigeMaxMoney
		if playerTotalBonus > highestMaxMoney then
			highestMaxMoney = playerTotalBonus
		end
	end

	local maxPossibleAmount = baseMaxAmount + highestMaxMoney
	local actualAmount = math.random(10, maxPossibleAmount)

	local amt = clone:FindFirstChild("Amount")
	if not amt then
		amt = Instance.new("NumberValue")
		amt.Name = "Amount"
		amt.Parent = clone
	end

	-- Apply multipliers based on block type
	if blockType == "Gold" then
		amt.Value = actualAmount * 3
		local isGoldValue = Instance.new("BoolValue", clone)
		isGoldValue.Name = "IsGold"
		isGoldValue.Value = true
	elseif blockType == "Rainbow" then
		amt.Value = actualAmount * 10
		local isRainbowValue = Instance.new("BoolValue", clone)
		isRainbowValue.Name = "IsRainbow"
		isRainbowValue.Value = true

		if not clone:FindFirstChild("RainbowParticles") then
			local particles = Instance.new("ParticleEmitter")
			particles.Name = "RainbowParticles"
			particles.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 165, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(75, 0, 130)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 130, 238))
			})
			particles.Size = NumberSequence.new(1)
			particles.Lifetime = NumberRange.new(2, 4)
			particles.Rate = 50
			particles.Parent = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		end
	else
		amt.Value = actualAmount
	end

	clone:SetAttribute("Claimed", false)
end

-- Prestige cost calculator
local function getPrestigeCost(plr)
	local level = plr:GetAttribute("PrestigeLevel") or 0
	return math.floor(10000 * (1.5 ^ level))
end

local AdminSpawnRequest = ensureEvent("AdminSpawnRequest")

AdminSpawnRequest.OnServerEvent:Connect(function(player, spawnType)
	if player.Name ~= "YTOpleoni_YT" then
		player:Kick("Not Owner")
		return
	end

	spawnType = spawnType or "cash"
	local blockCount = (spawnType == "cash") and 10 or (spawnType == "gold" and 3 or 1)

	for i = 1, blockCount do
		local spawnPos = spawnPoints[math.random(1, #spawnPoints)]
		spawnCash(spawnPos)
	end
end)

local function loadPlayerData(plr)
	local data
	local success, err = pcall(function()
		data = playerDataStore:GetAsync(plr.UserId)
	end)

	if success and data then
		plr:SetAttribute("Money", data.Money or 0)
		plr:SetAttribute("MoneyMultiplier", data.MoneyMultiplier or 1)
		plr:SetAttribute("MaxMoney", data.MaxMoney or 100)
		plr:SetAttribute("WalkSpeedBonus", data.WalkSpeedBonus or 0)
		plr:SetAttribute("JumpPowerBonus", data.JumpPowerBonus or 0)
		plr:SetAttribute("PrestigePoints", data.PrestigePoints or 0)
		plr:SetAttribute("PrestigeLevel", data.PrestigeLevel or 0)
		plr:SetAttribute("PrestigePointsMulti", data.PrestigePointsMulti or 1)
		plr:SetAttribute("PrestigeMoneyMulti", data.PrestigeMoneyMulti or 1)
		plr:SetAttribute("PrestigeMaxMoney", data.PrestigeMaxMoney or 0)
		plr:SetAttribute("PrestigePPMulti", data.PrestigePPMulti or 1)
		plr:SetAttribute("RebirthPoints", data.RebirthPoints or 0)

		if data.UpgradeLevels then
			for name, value in pairs(data.UpgradeLevels) do
				plr:SetAttribute(name, value)
			end
		end
	else
		plr:SetAttribute("Money", 0)
		plr:SetAttribute("MoneyMultiplier", 1)
		plr:SetAttribute("MaxMoney", 100)
		plr:SetAttribute("WalkSpeedBonus", 0)
		plr:SetAttribute("JumpPowerBonus", 0)
		plr:SetAttribute("PrestigePoints", 0)
		plr:SetAttribute("PrestigeLevel", 0)
		plr:SetAttribute("PrestigePointsMulti", 1)
		plr:SetAttribute("PrestigeMoneyMulti", 1)
		plr:SetAttribute("PrestigeMaxMoney", 0)
		plr:SetAttribute("PrestigePPMulti", 1)
		plr:SetAttribute("RebirthPoints", 0)
	end
end

local function savePlayerData(plr)
	local upgradeLevels = {}
	for name, value in pairs(plr:GetAttributes()) do
		if string.match(name, "Level$") then
			upgradeLevels[name] = value
		end
	end

	local data = {
		Money = plr:GetAttribute("Money") or 0,
		MoneyMultiplier = plr:GetAttribute("MoneyMultiplier") or 1,
		MaxMoney = plr:GetAttribute("MaxMoney") or 100,
		WalkSpeedBonus = plr:GetAttribute("WalkSpeedBonus") or 0,
		JumpPowerBonus = plr:GetAttribute("JumpPowerBonus") or 0,
		PrestigePoints = plr:GetAttribute("PrestigePoints") or 0,
		PrestigeLevel = plr:GetAttribute("PrestigeLevel") or 0,
		PrestigePointsMulti = plr:GetAttribute("PrestigePointsMulti") or 1,
		PrestigeMoneyMulti = plr:GetAttribute("PrestigeMoneyMulti") or 1,
		PrestigeMaxMoney = plr:GetAttribute("PrestigeMaxMoney") or 0,
		PrestigePPMulti = plr:GetAttribute("PrestigePPMulti") or 1,
		RebirthPoints = plr:GetAttribute("RebirthPoints") or 0,
		UpgradeLevels = upgradeLevels
	}

	pcall(function() playerDataStore:SetAsync(plr.UserId, data) end)
end

Players.PlayerRemoving:Connect(savePlayerData)

task.spawn(function()
	while true do
		task.wait(30)
		for _, plr in ipairs(Players:GetPlayers()) do
			savePlayerData(plr)
		end
	end
end)

PrestigeRequest.OnServerEvent:Connect(function(player)
	local money = player:GetAttribute("Money") or 0
	local pointsEarned = 0

	if money >= 10000 then
		local tierCost = 10000
		local currentTier = 1
		while money >= tierCost do
			pointsEarned = currentTier
			currentTier += 1
			tierCost = math.floor(tierCost * 1.5)
			if currentTier > 100 then break end
		end
	end

	if pointsEarned > 0 then
		local prestigeMultiplier = player:GetAttribute("PrestigePointsMulti") or 1
		local prestigePPMulti = player:GetAttribute("PrestigePPMulti") or 1
		local finalPointsEarned = math.floor(pointsEarned * prestigeMultiplier * prestigePPMulti)

		player:SetAttribute("Money", 0)
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Money") then stats.Money.Value = 0 end

		player:SetAttribute("MoneyMultiplier", 1)
		player:SetAttribute("MaxMoney", 100)
		player:SetAttribute("MoneyMultiplierLevel", 0)
		player:SetAttribute("MaxMoneyLevel", 0)

		local currentPoints = player:GetAttribute("PrestigePoints") or 0
		player:SetAttribute("PrestigePoints", currentPoints + finalPointsEarned)
	end
end)

RebirthRequest.OnServerEvent:Connect(function(player)
	local money = player:GetAttribute("Money") or 0
	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	
	if money >= rebirthCostMoney and prestigePoints >= rebirthCostPP then
		player:SetAttribute("Money", money - rebirthCostMoney)
		player:SetAttribute("PrestigePoints", prestigePoints - rebirthCostPP)
		
		local stats = player:FindFirstChild("leaderstats")
		if stats and stats:FindFirstChild("Money") then stats.Money.Value = money - rebirthCostMoney end
		
		local currentRP = player:GetAttribute("RebirthPoints") or 0
		player:SetAttribute("RebirthPoints", currentRP + 1)
	end
end)

local function endRound()
	if not roundRunning then return end
	roundRunning = false

	local ranked = Players:GetPlayers()
	table.sort(ranked, function(a,b) return (a:GetAttribute("Money") or 0) > (b:GetAttribute("Money") or 0) end)

	local bonuses = {500, 300, 150}
	for i = 1, math.min(3, #ranked) do
		local plr = ranked[i]
		if plr then CurrencyService.AddMoney(plr, bonuses[i]) end
	end

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and (obj.Name:find("Pickup")) then
			obj:Destroy()
		end
	end

	local lobbySpawn = Workspace:FindFirstChild("LobbySpawn")
	for _, plr in ipairs(Players:GetPlayers()) do
		plr:SetAttribute("InGame", false)
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			if lobbySpawn then plr.Character:MoveTo(lobbySpawn.Position + Vector3.new(0,5,0)) end
		end
	end
end

local function startRound()
	local active = getActivePlayers()
	if #active == 0 or #spawnPoints == 0 then return end

	roundRunning = true
	task.spawn(function()
		for t = ROUND_DURATION, 0, -1 do
			RoundTimerUpdate:FireAllClients(t)
			task.wait(1)
		end
		RoundTimerUpdate:FireAllClients(-1)
		if roundRunning then endRound() end
	end)

	task.spawn(function()
		while roundRunning do
			local pos = spawnPoints[math.random(1, #spawnPoints)]
			spawnCash(pos)
			task.wait(2)
		end
	end)
end

RequestPickup.OnServerEvent:Connect(function(player, cashInstance)
	local amt = cashInstance:FindFirstChild("Amount")
	if not amt then return end

	local multiplier = player:GetAttribute("MoneyMultiplier") or 1
	CurrencyService.AddMoney(player, math.floor(amt.Value * multiplier))
	cashInstance:Destroy()
end)

PlayRequest.OnServerEvent:Connect(function(player)
	player:SetAttribute("InGame", true)
	local playZoneSpawn = Workspace:FindFirstChild("PlayZoneSpawn")
	if playZoneSpawn and player.Character then
		player.Character:MoveTo(playZoneSpawn.Position + Vector3.new(0,5,0))
	end
end)

Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("InGame", false)
	loadPlayerData(plr)
	plr.CharacterAdded:Connect(function(character)
		task.wait(1)
		local wsLevel = plr:GetAttribute("WalkSpeedLevel") or 0
		if character:FindFirstChild("Humanoid") and wsLevel > 0 then
			character.Humanoid.WalkSpeed = 16 + wsLevel
		end
		local jpLevel = plr:GetAttribute("JumpPowerLevel") or 0
		if character:FindFirstChild("Humanoid") and jpLevel > 0 then
			character.Humanoid.UseJumpPower = true
			character.Humanoid.JumpPower = 50 + (2 * jpLevel)
		end
	end)
end)

task.spawn(function()
	while true do
		if #getActivePlayers() > 0 and not roundRunning then
			startRound()
			task.wait(ROUND_DURATION + 5)
		else
			task.wait(2)
		end
	end
end)