local SendSystemMessage = {}

local TextChatService = game:GetService("TextChatService")
local RunService = game:GetService("RunService")
local RemoteEvent = script:WaitForChild("RemoteEvent")

-- 📡 Fonction utilisée côté serveur
function SendSystemMessage:Send(msg: string, target, msgType)
	assert(RunService:IsServer(), "SendSystemMessage:Send doit être appelée côté serveur")

	if target then
		if typeof(target) == "table" then
			for _, player in ipairs(target) do
				RemoteEvent:FireClient(player, msg, msgType)
			end
		elseif typeof(target) == "Instance" then
			RemoteEvent:FireClient(target, msg, msgType)
		end
	else
		RemoteEvent:FireAllClients(msg, msgType)
	end
end

-- 💬 Partie exécutée côté client : affichage dans le chat
if RunService:IsClient() then
	local RBXGeneral = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

	RemoteEvent.OnClientEvent:Connect(function(message, msgType)
		local success, err = pcall(function()
			RBXGeneral:DisplaySystemMessage(message)
		end)

		if success then
			print("[✅ CHAT] Message affiché :", message)
		else
			warn("[❌ CHAT] Erreur :", err)
		end
	end)
end

return SendSystemMessage
