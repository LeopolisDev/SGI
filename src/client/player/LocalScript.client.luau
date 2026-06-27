local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RequestPickup = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("RequestPickup")

-- Anti-spam cooldown
local lastPickupTime = 0
local PICKUP_COOLDOWN = 0.5 -- 0.5 seconds between pickups

local function onTouch(part)
	-- Cooldown check
	local now = tick()
	if now - lastPickupTime < PICKUP_COOLDOWN then
		return
	end

	-- Check if the touched part belongs to a pickup model
	local cashModel = part:FindFirstAncestorWhichIsA("Model")
	if cashModel then
		-- Check if it has Amount value (all block types have this)
		local amountValue = cashModel:FindFirstChild("Amount")
		if amountValue then
			-- Check if it's a valid pickup by name
			if cashModel.Name == "CashPickup" or cashModel.Name == "GoldPickup" or cashModel.Name == "RainbowPickup" then
				-- Check if already claimed
				if cashModel:GetAttribute("Claimed") then
					return
				end

				print("[PICKUP] Touched:", cashModel.Name, "Amount:", amountValue.Value)

				-- Set cooldown
				lastPickupTime = now

				-- Send to server
				RequestPickup:FireServer(cashModel)
			end
		end
	end
end

local function connectTouch()
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(1) -- Wait for character to fully load
	local hrp = character:WaitForChild("HumanoidRootPart")

	hrp.Touched:Connect(function(hit)
		onTouch(hit)
	end)

	print("[PICKUP] Touch listener connected for", player.Name)
end

player.CharacterAdded:Connect(connectTouch)
if player.Character then
	connectTouch()
end