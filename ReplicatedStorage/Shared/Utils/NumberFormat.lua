--[[
	NumberFormat.lua
	Number abbreviation and formatting utilities.
	Examples: 1200 -> "1.2K", 3400000 -> "3.4M"
]]

local NumberFormat = {}

local SUFFIXES = {
	{ threshold = 1e15, suffix = "Q" },
	{ threshold = 1e12, suffix = "T" },
	{ threshold = 1e9,  suffix = "B" },
	{ threshold = 1e6,  suffix = "M" },
	{ threshold = 1e3,  suffix = "K" },
}

--- Abbreviate a number with K/M/B/T/Q suffixes.
--- @param value number
--- @return string
function NumberFormat.abbreviate(value)
	if value == nil then return "0" end
	if value < 0 then
		return "-" .. NumberFormat.abbreviate(-value)
	end

	for _, entry in ipairs(SUFFIXES) do
		if value >= entry.threshold then
			local shortened = value / entry.threshold
			if shortened >= 100 then
				return string.format("%.0f%s", shortened, entry.suffix)
			elseif shortened >= 10 then
				return string.format("%.1f%s", shortened, entry.suffix)
			else
				return string.format("%.2f%s", shortened, entry.suffix)
			end
		end
	end

	-- Below 1000: show integer
	if value == math.floor(value) then
		return tostring(math.floor(value))
	end
	return string.format("%.1f", value)
end

--- Format a number with comma separators: 1234567 -> "1,234,567"
--- @param value number
--- @return string
function NumberFormat.commaFormat(value)
	local formatted = tostring(math.floor(value))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

--- Format seconds into M:SS or H:MM:SS.
--- @param seconds number
--- @return string
function NumberFormat.formatTime(seconds)
	seconds = math.floor(seconds)
	if seconds < 0 then seconds = 0 end

	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local secs = seconds % 60

	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%d:%02d", minutes, secs)
	end
end

--- Format a percentage: 0.15 -> "15%"
--- @param value number (0 to 1 range)
--- @return string
function NumberFormat.formatPercent(value)
	return string.format("%.1f%%", value * 100)
end

return NumberFormat
