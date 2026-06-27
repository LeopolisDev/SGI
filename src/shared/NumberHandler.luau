-- NumberHandler module script in ReplicatedStorage
local NumberHandler = {}

local suffixes = {"K", "M", "B", "T", "Qd", "Qt", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Od", "Nd", "V", "Uv", "Dv", "Tv", "Qav", "Qiv", "Sxv", "Spv", "Ov", "Nv", "Tr", "Utr", "Dtr"}

function NumberHandler.formatNumber(num)
	if type(num) ~= "number" then
		return "0"
	end

	if num < 1000 then
		return tostring(math.floor(num))
	end

	local exponent = math.floor(math.log10(num))
	local suffixIndex = math.floor(exponent / 3)

	-- Use scientific notation for numbers >= 1e36
	if exponent >= 36 then
		local mantissa = num / (10 ^ exponent)
		return string.format("%.2fe%d", mantissa, exponent)
	end

	-- Standard abbreviations with proper rounding
	if suffixIndex > 0 and suffixIndex <= #suffixes then
		local divisor = 10 ^ (suffixIndex * 3)
		local value = num / divisor

		-- Round to appropriate decimal places based on size
		if num >= 1e12 then -- 1T and above: 2 decimal places
			return string.format("%.2f%s", value, suffixes[suffixIndex])
		elseif num >= 1e9 then -- 1B to 999B: 2 decimal places  
			return string.format("%.2f%s", value, suffixes[suffixIndex])
		elseif num >= 1e6 then -- 1M to 999M: 2 decimal places
			return string.format("%.2f%s", value, suffixes[suffixIndex])
		else -- 1K to 999K: 2 decimal places
			return string.format("%.2f%s", value, suffixes[suffixIndex])
		end
	else
		-- Fallback for numbers between 1,000-9,999
		local value = num / 1000
		return string.format("%.2f%s", value, "K")
	end
end

return NumberHandler