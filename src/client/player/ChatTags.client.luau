local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")

	local source = message.TextSource
	if source then
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then
			local tag = player:GetAttribute("ChatTag")
			if tag then
				-- 🌈 Optionnel : couleur personnalisée
				local colorString = player:GetAttribute("ChatTagColor")
				local colorText = ""
				if colorString then
					local r,g,b = string.match(colorString, "(%d+),%s*(%d+),%s*(%d+)")
					if r and g and b then
						colorText = string.format("<font color='rgb(%d,%d,%d)'>[%s]</font> ", tonumber(r), tonumber(g), tonumber(b), tag)
					end
				else
					colorText = string.format("[%s] ", tag)
				end

				properties.PrefixText = colorText .. message.PrefixText
			end
		end
	end

	return properties
end
