-- AdminPanel LocalScript (UPDATED)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local AdminSpawnRequest = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AdminSpawnRequest")
local AdminGiveMoney = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AdminGiveMoney")
local AdminGivePrestige = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AdminGivePrestige")

local adminPanel = script.Parent
local spawnButton = adminPanel:WaitForChild("SpawnButton")
local goldSpawnButton = adminPanel:WaitForChild("GoldSpawnButton")
local rainbowSpawnButton = adminPanel:WaitForChild("RainbowSpawnButton")
local giveMoneyButton = adminPanel:WaitForChild("GiveMoneyButton")
local givePrestigeButton = adminPanel:WaitForChild("GivePrestigeButton")
local playerNameBox = adminPanel:WaitForChild("PlayerNameBox")
local amountBox = adminPanel:WaitForChild("AmountBox")

-- Function to check if player is admin/owner
local function isAdmin(player)
	return player.Name == "YTOpleoni_YT"
end

-- Function to find player by name (case-insensitive)
local function findPlayerByName(playerName)
	local lowerName = string.lower(playerName)
	for _, p in pairs(Players:GetPlayers()) do
		if string.lower(p.Name) == lowerName then
			return p
		end
	end
	return nil
end

-- Function to validate and get target player
local function getTargetPlayer(playerName)
	if playerName == "" then
		print("[ADMIN] Please enter a player name")
		return nil
	end

	local targetPlayer = findPlayerByName(playerName)
	if not targetPlayer then
		print("[ADMIN] Player not found:", playerName)
		print("[ADMIN] Online players:")
		for _, p in pairs(Players:GetPlayers()) do
			print(" - " .. p.Name)
		end
		return nil
	end

	return targetPlayer
end

-- Show/hide admin panel based on admin status
local function setupAdminPanel()
	if isAdmin(player) then
		adminPanel.Enabled = false -- Start hidden
		print("[ADMIN] Admin panel available for", player.Name)
	else
		adminPanel.Enabled = false
		print("[ADMIN] Admin panel hidden for non-admin:", player.Name)
	end
end

-- Spawn regular cash blocks
spawnButton.MouseButton1Click:Connect(function()
	if not isAdmin(player) then return end
	AdminSpawnRequest:FireServer("cash")
	print("[ADMIN] Requested cash block spawn")
end)

-- Spawn gold blocks
goldSpawnButton.MouseButton1Click:Connect(function()
	if not isAdmin(player) then return end
	AdminSpawnRequest:FireServer("gold")
	print("[ADMIN] Requested gold block spawn")
end)

-- Rainbow spawn button
rainbowSpawnButton.MouseButton1Click:Connect(function()
	if not isAdmin(player) then return end
	AdminSpawnRequest:FireServer("rainbow")
	print("[ADMIN] Requested rainbow block spawn")
end)

-- Give money to player
giveMoneyButton.MouseButton1Click:Connect(function()
	if not isAdmin(player) then return end

	local targetPlayerName = playerNameBox.Text
	local amountText = amountBox.Text

	if amountText == "" then
		print("[ADMIN] Please enter an amount")
		return
	end

	local amount = tonumber(amountText)
	if not amount then
		print("[ADMIN] Invalid amount:", amountText)
		return
	end

	local targetPlayer = getTargetPlayer(targetPlayerName)
	if targetPlayer then
		AdminGiveMoney:FireServer(targetPlayer.Name, amount) -- Use exact name from player object
		print("[ADMIN] Requested to give", amount, "money to", targetPlayer.Name)
	end
end)

-- Give prestige points to player
givePrestigeButton.MouseButton1Click:Connect(function()
	if not isAdmin(player) then return end

	local targetPlayerName = playerNameBox.Text
	local amountText = amountBox.Text

	if amountText == "" then
		print("[ADMIN] Please enter an amount")
		return
	end

	local amount = tonumber(amountText)
	if not amount then
		print("[ADMIN] Invalid amount:", amountText)
		return
	end

	local targetPlayer = getTargetPlayer(targetPlayerName)
	if targetPlayer then
		AdminGivePrestige:FireServer(targetPlayer.Name, amount) -- Use exact name from player object
		print("[ADMIN] Requested to give", amount, "prestige points to", targetPlayer.Name)
	end
end)

-- Initial setup when player joins
setupAdminPanel()