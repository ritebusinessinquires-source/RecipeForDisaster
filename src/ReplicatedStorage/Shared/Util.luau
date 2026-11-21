-- Small shared helpers.

local Util = {}

function Util.formatNumber(n: number): string
	n = math.floor(n + 0.5)
	local s = tostring(math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return (n < 0 and "-" or "") .. out
end

function Util.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

function Util.formatDuration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm", h, m)
	end
	return string.format("%dm %ds", m, seconds % 60)
end

-- UTC day number (days since 1970-01-01)
function Util.dayNumber(t: number?): number
	return math.floor((t or os.time()) / 86400)
end

-- Week number, weeks start Monday 00:00 UTC (1970-01-01 was a Thursday)
function Util.weekNumber(t: number?): number
	return math.floor((Util.dayNumber(t) + 3) / 7)
end

-- Seconds until next Monday 00:00 UTC
function Util.secondsUntilWeekReset(t: number?): number
	local now = t or os.time()
	local nextWeekStartDay = (Util.weekNumber(now) + 1) * 7 - 3
	return nextWeekStartDay * 86400 - now
end

-- Seconds until next Saturday 00:00 UTC (weekly ingredient drop)
function Util.secondsUntilSaturday(t: number?): number
	local now = t or os.time()
	local day = Util.dayNumber(now)
	-- day % 7: 0=Thu,1=Fri,2=Sat,3=Sun,4=Mon,5=Tue,6=Wed
	local dow = day % 7
	local daysAhead = (2 - dow) % 7
	if daysAhead == 0 then
		daysAhead = 7
	end
	return (day + daysAhead) * 86400 - now
end

function Util.utcMonth(t: number?): number
	return tonumber(os.date("!%m", t or os.time())) :: number
end

function Util.shuffle<T>(list: { T }, rng: Random?): { T }
	local r = rng or Random.new()
	for i = #list, 2, -1 do
		local j = r:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
	return list
end

function Util.copy<T>(t: T): T
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t :: any) do
		out[k] = Util.copy(v)
	end
	return out :: any
end

function Util.weightedPick<T>(items: { T }, weightOf: (T) -> number, rng: Random?): T?
	local r = rng or Random.new()
	local total = 0
	for _, it in ipairs(items) do
		total += math.max(0, weightOf(it))
	end
	if total <= 0 then
		return items[1]
	end
	local roll = r:NextNumber() * total
	for _, it in ipairs(items) do
		roll -= math.max(0, weightOf(it))
		if roll <= 0 then
			return it
		end
	end
	return items[#items]
end

function Util.countKeys(t: { [any]: any }): number
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

-- Stable string hash -> integer seed
function Util.hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end

function Util.dishKey(mainId: string, spiceA: string, spiceB: string, twistId: string?): string
	local a, b = spiceA, spiceB
	if a > b then
		a, b = b, a
	end
	return string.format("%s|%s|%s|%s", mainId, a, b, twistId or "none")
end

return Util
