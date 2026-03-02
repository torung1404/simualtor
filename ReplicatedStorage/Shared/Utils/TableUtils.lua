--[[
	TableUtils.lua
	Common table manipulation utilities.
]]

local TableUtils = {}

--- Shallow copy a table.
--- @param source table
--- @return table
function TableUtils.shallowCopy(source)
	local copy = {}
	for k, v in pairs(source) do
		copy[k] = v
	end
	return copy
end

--- Deep copy a table (handles nested tables, not metatables/functions).
--- @param source table
--- @return table
function TableUtils.deepCopy(source)
	if type(source) ~= "table" then
		return source
	end
	local copy = {}
	for k, v in pairs(source) do
		copy[TableUtils.deepCopy(k)] = TableUtils.deepCopy(v)
	end
	return copy
end

--- Merge source into target (shallow). Source values overwrite target values.
--- @param target table
--- @param source table
--- @return table target (mutated)
function TableUtils.merge(target, source)
	for k, v in pairs(source) do
		target[k] = v
	end
	return target
end

--- Deep merge source into target. Nested tables are recursively merged.
--- @param target table
--- @param source table
--- @return table target (mutated)
function TableUtils.deepMerge(target, source)
	for k, v in pairs(source) do
		if type(v) == "table" and type(target[k]) == "table" then
			TableUtils.deepMerge(target[k], v)
		else
			target[k] = TableUtils.deepCopy(v)
		end
	end
	return target
end

--- Deep compare two tables for equality.
--- @param a table
--- @param b table
--- @return boolean
function TableUtils.deepEqual(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end

	for k, v in pairs(a) do
		if not TableUtils.deepEqual(v, b[k]) then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then return false end
	end
	return true
end

--- Check if a value exists in an array-like table.
--- @param tbl table
--- @param value any
--- @return boolean
function TableUtils.contains(tbl, value)
	for _, v in ipairs(tbl) do
		if v == value then return true end
	end
	return false
end

--- Get the count of keys in a dictionary-like table.
--- @param tbl table
--- @return number
function TableUtils.count(tbl)
	local n = 0
	for _ in pairs(tbl) do
		n = n + 1
	end
	return n
end

--- Filter an array-like table by a predicate function.
--- @param tbl table
--- @param predicate function(value) -> boolean
--- @return table
function TableUtils.filter(tbl, predicate)
	local result = {}
	for _, v in ipairs(tbl) do
		if predicate(v) then
			result[#result + 1] = v
		end
	end
	return result
end

--- Map an array-like table through a transform function.
--- @param tbl table
--- @param transform function(value) -> any
--- @return table
function TableUtils.map(tbl, transform)
	local result = {}
	for i, v in ipairs(tbl) do
		result[i] = transform(v)
	end
	return result
end

return TableUtils
