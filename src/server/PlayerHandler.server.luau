local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local playEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):FindFirstChild("PlayRequest")

if not playEvent then
	playEvent = Instance.new("RemoteEvent")
	playEvent.Name = "PlayRequest"
	playEvent.Parent = ReplicatedStorage:WaitForChild("RemoteEvents")
end

local playZoneSpawn = workspace:WaitForChild("PlayZoneSpawn")

playEvent.OnServerEvent:Connect(function(player)
	if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		player:SetAttribute("InGame", true)
		player.Character:MoveTo(playZoneSpawn.Position + Vector3.new(0, 5, 0))
	end
end)

-- Reset InGame flag when player dies or respawns
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("InGame", false)

	player.CharacterAdded:Connect(function(char)
		task.wait(1)
		if not player:GetAttribute("InGame") then
			-- send back to lobby
			local lobbySpawn = workspace:WaitForChild("Lobby"):WaitForChild("LobbySpawn")
			char:MoveTo(lobbySpawn.Position + Vector3.new(0, 5, 0))
		end
	end)
end)
