local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local roundTimerEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RoundTimerUpdate")
local label = script.Parent:WaitForChild("TimerLabel")

label.Visible = false

roundTimerEvent.OnClientEvent:Connect(function(timeLeft)
	-- timeLeft == -1 -> hide
	if timeLeft == -1 or not player:GetAttribute("InGame") then
		label.Visible = false
		return
	end

	-- only show while in-game
	if player:GetAttribute("InGame") then
		label.Visible = true
		label.Text = "⏱️ Round Time: " .. timeLeft
	else
		label.Visible = false
	end
end)

player:GetAttributeChangedSignal("InGame"):Connect(function()
	if not player:GetAttribute("InGame") then
		label.Visible = false
	end
end)
