--[[
	MathUtils.lua
	Mathematical utility functions for game calculations.
]]

local MathUtils = {}

--- Clamp a value between min and max.
--- @param value number
--- @param min number
--- @param max number
--- @return number
function MathUtils.clamp(value, min, max)
	if value < min then return min end
	if value > max then return max end
	return value
end

--- Linear interpolation between a and b.
--- @param a number
--- @param b number
--- @param t number (0 to 1)
--- @return number
function MathUtils.lerp(a, b, t)
	return a + (b - a) * MathUtils.clamp(t, 0, 1)
end

--- Weighted random selection from a table of { value, weight } entries.
--- @param entries table Array of { value = any, weight = number }
--- @return any The selected value, or nil if entries is empty
function MathUtils.weightedRandom(entries)
	if #entries == 0 then return nil end

	local totalWeight = 0
	for _, entry in ipairs(entries) do
		totalWeight = totalWeight + entry.weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(entries) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end

	-- Fallback (floating point edge case)
	return entries[#entries].value
end

--- Roll a chance (0.0 to 1.0). Returns true if the roll succeeds.
--- @param chance number (0.0 to 1.0)
--- @return boolean
function MathUtils.rollChance(chance)
	return math.random() < chance
end

--- Calculate upgrade cost: baseCost * (growthRate ^ level)
--- @param baseCost number
--- @param growthRate number
--- @param level number (current level, cost is for buying level+1)
--- @return number
function MathUtils.upgradeCost(baseCost, growthRate, level)
	return math.floor(baseCost * (growthRate ^ level))
end

--- Calculate total power from upgrade levels and equipment.
--- @param upgradeLevels table { upgradeId = level }
--- @param upgradeConfigs table The UpgradeById lookup
--- @param equipmentBonuses table { damage = N, ... }
--- @return number totalPower
function MathUtils.calculatePower(upgradeLevels, upgradeConfigs, equipmentBonuses)
	local totalDamage = 0
	local totalCrit = 0
	local totalSpeed = 0

	for upgradeId, level in pairs(upgradeLevels) do
		local config = upgradeConfigs[upgradeId]
		if config then
			local effect = config.effectPerLevel * level
			if config.category == "damage" then
				totalDamage = totalDamage + effect
			elseif config.category == "crit" then
				totalCrit = totalCrit + effect
			elseif config.category == "speed" then
				totalSpeed = totalSpeed + effect
			end
		end
	end

	-- Add equipment bonuses
	if equipmentBonuses then
		totalDamage = totalDamage + (equipmentBonuses.damage or 0)
		totalCrit = totalCrit + (equipmentBonuses.crit or 0)
		totalSpeed = totalSpeed + (equipmentBonuses.speed or 0)
	end

	-- Power formula: damage is primary, crit and speed are multipliers
	local critMultiplier = 1 + totalCrit
	local speedMultiplier = 1 + totalSpeed
	local power = totalDamage * critMultiplier * speedMultiplier

	return math.floor(power)
end

--- Round a number to N decimal places.
--- @param value number
--- @param decimals number
--- @return number
function MathUtils.round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

--- Map a value from one range to another.
--- @param value number
--- @param inMin number
--- @param inMax number
--- @param outMin number
--- @param outMax number
--- @return number
function MathUtils.mapRange(value, inMin, inMax, outMin, outMax)
	return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

return MathUtils
