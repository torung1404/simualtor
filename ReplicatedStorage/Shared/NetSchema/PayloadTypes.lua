--[[
	PayloadTypes.lua
	Type definitions and validators for remote payloads.
	Used by server RemoteHandlers to validate incoming requests.
]]

local PayloadTypes = {}

--- Validate a fight request payload.
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateFight(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	if type(payload.enemyId) ~= "string" or payload.enemyId == "" then
		return false, "enemyId must be a non-empty string"
	end
	return true, nil
end

--- Validate a buy upgrade request payload.
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateBuyUpgrade(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	if type(payload.upgradeId) ~= "string" or payload.upgradeId == "" then
		return false, "upgradeId must be a non-empty string"
	end
	return true, nil
end

--- Validate a job action payload (start/claim/cancel).
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateJob(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	if type(payload.jobId) ~= "string" or payload.jobId == "" then
		return false, "jobId must be a non-empty string"
	end
	return true, nil
end

--- Validate an equip item payload.
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateEquipItem(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	if type(payload.itemId) ~= "string" or payload.itemId == "" then
		return false, "itemId must be a non-empty string"
	end
	if type(payload.slot) ~= "number" or payload.slot < 1 or payload.slot > 6 then
		return false, "slot must be a number between 1 and 6"
	end
	return true, nil
end

--- Validate a sell item payload.
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateSellItem(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	if type(payload.itemId) ~= "string" or payload.itemId == "" then
		return false, "itemId must be a non-empty string"
	end
	if payload.quantity ~= nil then
		if type(payload.quantity) ~= "number" or payload.quantity < 1 or payload.quantity ~= math.floor(payload.quantity) then
			return false, "quantity must be a positive integer"
		end
	end
	return true, nil
end

--- Validate a settings update payload.
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateSettings(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	-- Only allow known setting keys
	local allowed = { sfxEnabled = "boolean", musicEnabled = "boolean", uiScale = "number" }
	for k, v in pairs(payload) do
		local expectedType = allowed[k]
		if not expectedType then
			return false, "Unknown setting: " .. tostring(k)
		end
		if type(v) ~= expectedType then
			return false, k .. " must be a " .. expectedType
		end
	end
	return true, nil
end

--- Validate a referral code payload.
--- @param payload table
--- @return boolean isValid, string? errorMessage
function PayloadTypes.validateReferral(payload)
	if type(payload) ~= "table" then
		return false, "Payload must be a table"
	end
	if type(payload.code) ~= "string" or #payload.code < 4 or #payload.code > 20 then
		return false, "code must be a string between 4 and 20 characters"
	end
	return true, nil
end

--- Generic response constructor.
--- @param ok boolean
--- @param data table?
--- @param errorMsg string?
--- @return table
function PayloadTypes.response(ok, data, errorMsg)
	return {
		ok = ok,
		data = data,
		error = errorMsg,
	}
end

return PayloadTypes
