local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local button = script.Parent
local playEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlayRequest")

button.MouseButton1Click:Connect(function()
	button.Visible = false
	playEvent:FireServer()
end)

player:GetAttributeChangedSignal("InGame"):Connect(function()
	if not player:GetAttribute("InGame") then
		button.Visible = true
	end
end)
