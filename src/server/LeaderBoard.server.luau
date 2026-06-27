local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local MoneyBoardDS = DataStoreService:GetOrderedDataStore("MoneyLeaderBoard")
local PrestigeBoardDS = DataStoreService:GetOrderedDataStore("PrestigeLeaderBoard")

local MoneyBoardGui = game.Workspace.Lobby.Boards.MoneyBoard.Show.SurfaceGui
local MoneyPlayerContainer = MoneyBoardGui.PlayerContainer

local PrestigeBoardGui = game.Workspace.Lobby.Boards.PrestigeBoard.Show.SurfaceGui
local PrestigePlayerContainer = PrestigeBoardGui.PlayerContainer

local BlackList = {
	"Player1",
	"Player2",
	"Player3",
	"Player4",
	"Player5",
	"Player6",
	"Player7",
	"Player8",
}

local MIN_MONEY = 1000
local MIN_PRESTIGE = 1
local MAX_MONEY = 1e18
local MAX_PRESTIGE = 1e18
local UPDATE_INTERVAL = 10

local function formatNumber(number)
	local abbreviations = {"", "K", "M", "B", "T", "QD", "QI", "QN"}
	for i = #abbreviations, 2, -1 do
		local divisor = 10 ^ (3 * (i - 1))
		if number >= divisor then
			return string.format("%.1f%s", number / divisor, abbreviations[i])
		end
	end
	return tostring(number)
end

local function savePlayerMoney(player, value)
	local success, err = pcall(function()
		MoneyBoardDS:UpdateAsync(player.UserId, function()
			return value
		end)
	end)
	if not success then
		warn("Failure while saving money for: " .. player.Name .. " : " .. err)
	end
end

local function savePlayerPrestige(player, value)
	local success, err = pcall(function()
		PrestigeBoardDS:UpdateAsync(player.UserId, function()
			return value
		end)
	end)
	if not success then
		warn("Failure while saving prestige for: " .. player.Name .. " : " .. err)
	end
end

local function updateMoneyLeaderboard()
	for _, frame in ipairs(MoneyPlayerContainer:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end

	local success, result = pcall(function()
		return MoneyBoardDS:GetSortedAsync(false, 100)
	end)

	if not success then
		warn("Can't get money leaderboard : " .. result)
		return
	end

	local page = result:GetCurrentPage()
	for rank, data in ipairs(page) do
		local userId = tonumber(data.key)
		local money = data.value

		local successName, playerName = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)

		if successName and playerName then
			if money >= MIN_MONEY and money <= MAX_MONEY and not table.find(BlackList, playerName) then
				local template = game:GetService("ReplicatedStorage").LeaderBoard:WaitForChild("Template"):Clone()
				template.NameText.Text = playerName
				template.money.Text = formatNumber(money)
				template.Rank.Text = "#" .. rank
				template.Parent = MoneyPlayerContainer
				template.Visible = true

				if rank == 1 then
					template.Rank.TextColor3 = Color3.fromRGB(255, 215, 0)
				elseif rank == 2 then
					template.Rank.TextColor3 = Color3.fromRGB(192, 192, 192)
				elseif rank == 3 then
					template.Rank.TextColor3 = Color3.fromRGB(205, 127, 50)
				else
					template.Rank.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end
	print("[MoneyLeaderboard] Update finished ✅")
end

local function updatePrestigeLeaderboard()
	for _, frame in ipairs(PrestigePlayerContainer:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end

	local success, result = pcall(function()
		return PrestigeBoardDS:GetSortedAsync(false, 100)
	end)

	if not success then
		warn("Can't get prestige leaderboard : " .. result)
		return
	end

	local page = result:GetCurrentPage()
	for rank, data in ipairs(page) do
		local userId = tonumber(data.key)
		local prestige = data.value

		local successName, playerName = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)

		if successName and playerName then
			if prestige >= MIN_PRESTIGE and prestige <= MAX_PRESTIGE and not table.find(BlackList, playerName) then
				local template = game:GetService("ReplicatedStorage").PrestigeLeaderBoard:WaitForChild("Template"):Clone()
				template.NameText.Text = playerName
				template.money.Text = formatNumber(prestige)
				template.Rank.Text = "#" .. rank
				template.Parent = PrestigePlayerContainer
				template.Visible = true

				if rank == 1 then
					template.Rank.TextColor3 = Color3.fromRGB(255, 215, 0)
				elseif rank == 2 then
					template.Rank.TextColor3 = Color3.fromRGB(192, 192, 192)
				elseif rank == 3 then
					template.Rank.TextColor3 = Color3.fromRGB(205, 127, 50)
				else
					template.Rank.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
		end
	end
	print("[PrestigeLeaderboard] Update finished ✅")
end

Players.PlayerAdded:Connect(function(player)
	local leaderstats = player:WaitForChild("leaderstats")
	local money = leaderstats:WaitForChild("Money")

	-- Track money changes
	money.Changed:Connect(function(newValue)
		savePlayerMoney(player, newValue)
	end)

	-- Track prestige changes
	player:GetAttributeChangedSignal("PrestigePoints"):Connect(function()
		local prestigePoints = player:GetAttribute("PrestigePoints") or 0
		savePlayerPrestige(player, prestigePoints)
	end)

	-- Initial save for prestige
	local initialPrestige = player:GetAttribute("PrestigePoints") or 0
	savePlayerPrestige(player, initialPrestige)
end)

Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats and leaderstats:FindFirstChild("Money") then
		savePlayerMoney(player, leaderstats.Money.Value)
	end

	local prestigePoints = player:GetAttribute("PrestigePoints") or 0
	savePlayerPrestige(player, prestigePoints)
end)

task.spawn(function()
	while true do
		updateMoneyLeaderboard()
		updatePrestigeLeaderboard()
		task.wait(UPDATE_INTERVAL)
	end
end)