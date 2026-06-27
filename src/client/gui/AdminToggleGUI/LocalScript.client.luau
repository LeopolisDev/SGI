local Players = game:GetService("Players")
local player = Players.LocalPlayer

local adminToggleGUI = script.Parent
local adminToggleButton = adminToggleGUI:WaitForChild("AdminToggleButton")

-- Function to check if player is admin/owner - FIXED
local function isAdmin()
	return player.Name == "YTOpleoni_YT"
end

-- Function to get the AdminGUI
local function getAdminGUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local adminGUI = playerGui:WaitForChild("AdminGUI")
	return adminGUI
end

-- Reset protection
local hasInitialized = false

-- Function to safely initialize admin panel
local function initializeAdminPanel()
	if hasInitialized then return end

	if isAdmin() then
		adminToggleGUI.Enabled = true

		-- Ensure admin panel starts CLOSED on reset
		local success, adminGUI = pcall(getAdminGUI)
		if success and adminGUI then
			adminGUI.Enabled = false
			adminToggleButton.Text = "Admin ▲"
			player:SetAttribute("AdminPanelOpen", false)
			print("[ADMIN] Admin panel initialized and hidden after reset")
		end

		hasInitialized = true
	else
		adminToggleGUI.Enabled = false
		hasInitialized = true
	end
end

-- Toggle admin panel visibility
local function toggleAdminPanel()
	if not isAdmin() then return end

	-- Get the AdminGUI
	local success, adminGUI = pcall(getAdminGUI)

	if success and adminGUI then
		if adminGUI.Enabled then
			adminGUI.Enabled = false
			adminToggleButton.Text = "Admin ▲"
			player:SetAttribute("AdminPanelOpen", false)
			print("[ADMIN] Admin panel hidden")
		else
			adminGUI.Enabled = true
			adminToggleButton.Text = "Admin ▼"
			player:SetAttribute("AdminPanelOpen", true)
			print("[ADMIN] Admin panel shown")
		end
	else
		warn("[ADMIN] AdminGUI not found!")
	end
end

-- Connect toggle button
adminToggleButton.MouseButton1Click:Connect(toggleAdminPanel)

-- Initialize when GUI loads
local function initialize()
	-- Wait a moment for all GUIs to load after reset
	task.wait(1)
	initializeAdminPanel()
end

-- Re-initialize when character respawns (on reset)
player.CharacterAdded:Connect(function(character)
	task.wait(1) -- Wait for character to fully load
	initializeAdminPanel()
end)

-- Also initialize when player joins
initialize()