local player = game.Players.LocalPlayer
local label = script.Parent:WaitForChild("PointsLabel")

-- Infinite number formatting function
local function formatNumber(num)
	if num < 1000 then
		return tostring(math.floor(num))
	end

	local suffixes = {"k", "m", "b", "t", "qd", "qt", "sx", "sp", "oc", "no", "dc", "ud", "dd", "td", "qad", "qid", "sxd", "spd", "od", "nd", "v", "uv", "dv", "tv", "qav", "qiv", "sxv", "spv", "ov", "nv", "tr", "utr", "dtr"}

	local exponent = math.floor(math.log10(num))
	local suffixIndex = math.floor(exponent / 3)

	if suffixIndex <= #suffixes then
		local value = num / (10 ^ (suffixIndex * 3))
		return string.format("%.2f%s", value, suffixes[suffixIndex])
	else
		return string.format("%.2fe%d", num / (10 ^ exponent), exponent)
	end
end

-- Function to update label text
local function updatePoints()
	local points = player:GetAttribute("PrestigePoints") or 0
	label.Text = "Prestige Points: " .. formatNumber(points)
end

-- Update whenever PrestigePoints changes
player:GetAttributeChangedSignal("PrestigePoints"):Connect(updatePoints)

-- Initial update
updatePoints()