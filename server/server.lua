local VORPInv = exports.vorp_inventory:vorp_inventoryApi()

for _, item in pairs(Config.PomadeItems) do
	VORPInv.RegisterUsableItem(item, function(data)
		VORPInv.CloseInv(data.source)
		VORPInv.subItem(data.source, item, 1)
		TriggerClientEvent('xakra_pomade:TaskPomade', data.source)
	end)
end
