-- PurchaseService (Script)
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local CurrencyService = require(script.Parent:WaitForChild("CurrencyService"))

-- Developer product IDs (replace with yours)
local DEVPRODUCTS = {
	[12345678] = { name = "Small Pack", amount = 500 },
	[23456789] = { name = "Medium Pack", amount = 1200 },
	[34567890] = { name = "Huge Pack", amount = 3000 },
}

-- ProcessReceipt: Handles all Dev Product purchases
MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- player left; retry later
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local productData = DEVPRODUCTS[receiptInfo.ProductId]
	if not productData then
		warn("Unknown product ID:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Grant the product
	CurrencyService.AddMoney(player, productData.amount)
	print("Granted", productData.name, "to", player.Name)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end
