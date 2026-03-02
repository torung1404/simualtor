--[[
	EconomyHandler.lua
	Routes buy/sell/equip remotes to the appropriate services.
]]

local PayloadTypes = require(game.ReplicatedStorage.Shared.NetSchema.PayloadTypes)
local ItemsConfig = require(game.ReplicatedStorage.Shared.Configs.ItemsConfig)

local EconomyHandler = {}
EconomyHandler.__index = EconomyHandler

--- Create a new EconomyHandler.
--- @param upgradeService UpgradeService
--- @param economyService EconomyService
--- @param playerDataService PlayerDataService
--- @param antiCheatService AntiCheatService
--- @param tutorialService TutorialService
--- @return EconomyHandler
function EconomyHandler.new(upgradeService, economyService, playerDataService, antiCheatService, tutorialService)
	local self = setmetatable({}, EconomyHandler)
	self._upgrade = upgradeService
	self._economy = economyService
	self._playerData = playerDataService
	self._antiCheat = antiCheatService
	self._tutorial = tutorialService
	return self
end

--- Handle a buy upgrade request.
--- @param userId number
--- @param payload table { upgradeId: string }
--- @return table Response
function EconomyHandler:handleBuyUpgrade(userId, payload)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "BuyUpgrade")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	local valid, err = PayloadTypes.validateBuyUpgrade(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end

	local result = self._upgrade:buyUpgrade(userId, payload.upgradeId)

	-- Track tutorial progress
	if result.ok then
		local UpgradesConfig = require(game.ReplicatedStorage.Shared.Configs.UpgradesConfig)
		local config = UpgradesConfig.ById[payload.upgradeId]
		local category = config and config.category or nil
		self._tutorial:recordAction(userId, "upgrade", { category = category })
	end

	return result
end

--- Handle a sell item request.
--- @param userId number
--- @param payload table { itemId: string, quantity?: number }
--- @return table Response
function EconomyHandler:handleSellItem(userId, payload)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "SellItem")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	local valid, err = PayloadTypes.validateSellItem(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end

	local data = self._playerData:getData(userId)
	if not data then
		return PayloadTypes.response(false, nil, "Player data not found")
	end

	-- Find item in inventory
	local itemConfig = ItemsConfig.ById[payload.itemId]
	if not itemConfig then
		return PayloadTypes.response(false, nil, "Unknown item")
	end

	if itemConfig.sellValue <= 0 then
		return PayloadTypes.response(false, nil, "This item cannot be sold")
	end

	local quantity = payload.quantity or 1
	local itemIndex = nil
	for i, invItem in ipairs(data.inventory.items) do
		if invItem.itemId == payload.itemId then
			if invItem.quantity >= quantity then
				itemIndex = i
				break
			end
		end
	end

	if not itemIndex then
		return PayloadTypes.response(false, nil, "Item not found or insufficient quantity")
	end

	-- Sell
	local totalValue = itemConfig.sellValue * quantity
	data.inventory.items[itemIndex].quantity = data.inventory.items[itemIndex].quantity - quantity
	if data.inventory.items[itemIndex].quantity <= 0 then
		table.remove(data.inventory.items, itemIndex)
	end

	self._economy:addCoin(userId, totalValue, "sell:" .. payload.itemId)
	self._playerData:markDirty(userId)

	return PayloadTypes.response(true, {
		sold = payload.itemId,
		quantity = quantity,
		coinGained = totalValue,
	})
end

--- Handle an equip item request.
--- @param userId number
--- @param payload table { itemId: string, slot: number }
--- @return table Response
function EconomyHandler:handleEquipItem(userId, payload)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "EquipItem")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	local valid, err = PayloadTypes.validateEquipItem(payload)
	if not valid then
		return PayloadTypes.response(false, nil, err)
	end

	local data = self._playerData:getData(userId)
	if not data then
		return PayloadTypes.response(false, nil, "Player data not found")
	end

	-- Verify item is owned
	local hasItem = false
	for _, invItem in ipairs(data.inventory.items) do
		if invItem.itemId == payload.itemId and invItem.quantity > 0 then
			hasItem = true
			break
		end
	end
	if not hasItem then
		return PayloadTypes.response(false, nil, "Item not owned")
	end

	-- Verify item is equippable
	local itemConfig = ItemsConfig.ById[payload.itemId]
	if not itemConfig or itemConfig.type == "material" then
		return PayloadTypes.response(false, nil, "This item cannot be equipped")
	end

	-- Equip to slot
	local slotKey = "slot" .. payload.slot
	data.inventory.equippedSlots[slotKey] = payload.itemId
	self._playerData:markDirty(userId)

	-- Track tutorial
	self._tutorial:recordAction(userId, "equip")

	return PayloadTypes.response(true, {
		equipped = payload.itemId,
		slot = payload.slot,
	})
end

--- Handle an unequip item request.
--- @param userId number
--- @param payload table { slot: number }
--- @return table Response
function EconomyHandler:handleUnequipItem(userId, payload)
	local allowed, reason = self._antiCheat:checkRateLimit(userId, "UnequipItem")
	if not allowed then
		return PayloadTypes.response(false, nil, reason)
	end

	if type(payload) ~= "table" or type(payload.slot) ~= "number" then
		return PayloadTypes.response(false, nil, "Invalid payload")
	end

	local data = self._playerData:getData(userId)
	if not data then
		return PayloadTypes.response(false, nil, "Player data not found")
	end

	local slotKey = "slot" .. payload.slot
	local previousItem = data.inventory.equippedSlots[slotKey]
	data.inventory.equippedSlots[slotKey] = nil
	self._playerData:markDirty(userId)

	return PayloadTypes.response(true, {
		unequipped = previousItem,
		slot = payload.slot,
	})
end

return EconomyHandler
