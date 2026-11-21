-- DishResolver: turns three card IDs (+ optional Twist) into one dish definition.
-- Always in this order, so the same ingredients always make the same dish:
--   1. secret recipes  2. Main base stats  3. apply each Spice  4. danger budget  5. name

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)

local DishResolver = {}

local function loadFolder(name: string): { [string]: any }
	local out = {}
	for _, m in ipairs(ServerStorage:WaitForChild(name):GetChildren()) do
		if m:IsA("ModuleScript") then
			out[m.Name] = require(m) :: any
		end
	end
	return out
end

DishResolver.Mains = loadFolder("Mains")
DishResolver.Spices = loadFolder("Spices")
DishResolver.Twists = loadFolder("Twists")
DishResolver.Recipes = loadFolder("Recipes")

-- secret recipes sorted most specific first
local recipeList = {}
for id, r in pairs(DishResolver.Recipes) do
	r.id = r.id or id
	table.insert(recipeList, r)
end
table.sort(recipeList, function(a, b)
	local sa = (a.main and 1 or 0) + #a.spices
	local sb = (b.main and 1 or 0) + #b.spices
	if sa ~= sb then
		return sa > sb
	end
	return a.id < b.id
end)
DishResolver.RecipeList = recipeList

local OPPOSITES = {
	["Giant|Tiny"] = { word = "Perfectly Normal", kind = "normal" },
	["Fast|Slow"] = { word = "Confused", kind = "confused" },
}

local SIZE_WORDS = { Giant = true, Tiny = true }
local SPEED_WORDS = { Fast = true, Slow = true }

local function wordPriority(spiceId: string?, kind: string?): number
	if kind == "normal" then
		return 1
	elseif kind == "confused" then
		return 3
	end
	if spiceId and SIZE_WORDS[spiceId] then
		return 1
	elseif spiceId == "Swarm" then
		return 2
	elseif spiceId and SPEED_WORDS[spiceId] then
		return 3
	end
	return 4
end

local function spiceOrderIndex(id: string): number
	return table.find(Catalog.SpiceOrder, id) or 99
end

function DishResolver.matchRecipe(mainId: string, spiceA: string, spiceB: string): any
	for _, r in ipairs(recipeList) do
		if r.main == nil or r.main == mainId then
			local have = { spiceA, spiceB }
			local ok = true
			for _, need in ipairs(r.spices) do
				local i = table.find(have, need)
				if i then
					table.remove(have, i)
				else
					ok = false
					break
				end
			end
			if ok then
				if #have == 0 or r.anySpice then
					return r
				end
			end
		end
	end
	return nil
end

local function isEmpty(t: any): boolean
	return t == nil or next(t) == nil
end

-- opts: { id, course, suddenDeath, seed }
function DishResolver.resolve(mainId: string, spiceA: string, spiceB: string, twistId: string?, opts: any?)
	opts = opts or {}
	local main = DishResolver.Mains[mainId]
	assert(main, "unknown main " .. tostring(mainId))
	assert(DishResolver.Spices[spiceA] and DishResolver.Spices[spiceB], "unknown spice")
	local twist = twistId and DishResolver.Twists[twistId] or nil
	local twistInfo = twistId and Catalog.Twists[twistId] or nil

	local dish: any = {
		id = opts.id or "D",
		course = opts.course,
		key = Util.dishKey(mainId, spiceA, spiceB, twistId),
		mainId = mainId,
		spiceIds = { spiceA, spiceB },
		twistId = twistId,
		type = main.type,
		hooks = {},
		damageMult = 1,
		jokes = {},
		wasted = false,
		confused = false,
		suddenDeath = opts.suddenDeath == true,
		seed = opts.seed or os.clock() * 1000,
		emoji = Catalog.Mains[mainId] and Catalog.Mains[mainId].emoji or "🍲",
	}

	-- 1. secret recipes
	local recipe = DishResolver.matchRecipe(mainId, spiceA, spiceB)
	if recipe then
		dish.secretId = recipe.id
		dish.type = recipe.type or main.type
		dish.stats = table.clone(recipe.stats)
		dish.emoji = recipe.emoji or dish.emoji
		dish.hint = { text = recipe.hint.text, icon = recipe.hint.icon }
		dish.danger = Config.DangerCap
		if dish.suddenDeath then
			dish.stats.Speed *= 1.25
		end
		dish.name = recipe.name .. (twistInfo and (" " .. twistInfo.suffix) or "")
		dish.words = { recipe.name }
		return dish
	end

	-- 2. Main base stats
	local base = main.stats
	local mult = { Size = 1, Speed = 1, Count = 1, Damage = 1, Health = 1 }
	local words = {}
	local danger = main.danger or 3

	local function applyStats(st: any)
		for k, v in pairs(st or {}) do
			mult[k] = (mult[k] or 1) * v
		end
	end

	-- 3. apply Spices (doubles upgrade, opposites cancel as a joke)
	local a, b = spiceA, spiceB
	if spiceOrderIndex(a) > spiceOrderIndex(b) then
		a, b = b, a
	end
	local opposite = OPPOSITES[a .. "|" .. b] or OPPOSITES[b .. "|" .. a]
	if spiceA == spiceB then
		local mod = DishResolver.Spices[spiceA]
		applyStats(mod.double and mod.double.stats or mod.stats)
		dish.hooks[spiceA] = 2
		danger += (mod.danger or 1) * 2
		table.insert(words, { text = mod.double and mod.double.name or ("Double " .. spiceA), pri = wordPriority(spiceA), order = spiceOrderIndex(spiceA) })
		dish.double = spiceA
	elseif opposite then
		dish.wasted = true
		if opposite.kind == "confused" then
			dish.confused = true
		end
		table.insert(words, { text = opposite.word, pri = wordPriority(nil, opposite.kind), order = 0 })
		danger += 1
	else
		for _, s in ipairs({ a, b }) do
			local mod = DishResolver.Spices[s]
			applyStats(mod.stats)
			dish.hooks[s] = 1
			danger += mod.danger or 1
			table.insert(words, { text = Catalog.Spices[s].name, pri = wordPriority(s), order = spiceOrderIndex(s) })
		end
	end

	-- no dead modifiers: a Spice with no real effect on this type -> +30% Damage
	for s, _ in pairs(dish.hooks) do
		local mod = DishResolver.Spices[s]
		local dead = mod.deadOn and mod.deadOn[dish.type]
		if not dead and mod[dish.type] == nil and isEmpty(mod.stats) and (mod.double == nil or isEmpty(mod.double.stats)) then
			dead = string.format("%s does nothing to %s... so it hits 30%% harder instead!", Catalog.Spices[s].name, Catalog.Types[dish.type].name)
		end
		if dead then
			dish.damageMult *= Config.FallbackDamageBoost
			table.insert(dish.jokes, (Catalog.Spices[s].emoji or "") .. " " .. dead)
		end
	end

	if dish.suddenDeath then
		mult.Speed *= 1.5 -- the free Fast Spice
		danger += 1
	end
	if twist then
		danger += twist.danger or 0
	end

	-- hard caps keep the server alive
	local stats = {
		Size = math.clamp((base.Size or 1) * mult.Size, 0.25, Config.Caps.Size),
		Speed = (base.Speed or 1) * math.clamp(mult.Speed, 0.25, Config.Caps.Speed),
		Count = math.clamp(math.floor((base.Count or 1) * mult.Count + 0.5), 1, Config.Caps.Count),
		Damage = (base.Damage or 10) * mult.Damage,
		Health = (base.Health or 1) * mult.Health,
	}

	-- 4. danger budget: lower Count first, then Speed, until the dish is survivable
	dish.dangerRaw = danger
	local excess = danger - Config.DangerCap
	while excess > 0 do
		if stats.Count > 1 then
			stats.Count = math.max(1, math.floor(stats.Count * 0.8))
		else
			stats.Speed *= 0.9
		end
		excess -= 1
	end
	dish.danger = math.min(danger, Config.DangerCap)
	dish.stats = stats

	-- 5. name: [size word] [other spices] [Main] [Twist]
	table.sort(words, function(x, y)
		if x.pri ~= y.pri then
			return x.pri < y.pri
		end
		return x.order < y.order
	end)
	local parts = {}
	for _, w in ipairs(words) do
		table.insert(parts, w.text)
	end
	table.insert(parts, Catalog.Mains[mainId].name)
	if twistInfo then
		table.insert(parts, twistInfo.suffix)
	end
	dish.name = table.concat(parts, " ")
	local wordList = {}
	for _, w in ipairs(words) do
		table.insert(wordList, w.text)
	end
	dish.words = wordList

	-- hint: the Main's counter, plus the most important Spice hint
	local hint = { text = main.hint.text, icon = main.hint.icon }
	local best, bestPri = nil, -1
	for s, _ in pairs(dish.hooks) do
		local h = DishResolver.Spices[s].hint
		if h and (h.priority or 0) > bestPri then
			best, bestPri = h, h.priority or 0
		end
	end
	if best then
		hint.sub = best.text
		if (best.priority or 0) >= 5 then
			hint.icon = best.icon
		end
	end
	if dish.confused then
		hint.sub = "They can't decide how fast to go - watch them!"
	end
	dish.hint = hint
	return dish
end

-- Lightweight info for Cookbook entries
local infoCache: { [string]: any } = {}
function DishResolver.info(key: string): any
	local cached = infoCache[key]
	if cached then
		return cached
	end
	local mainId, sa, sb, tw = string.match(key, "^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
	if not mainId or not DishResolver.Mains[mainId] or not DishResolver.Spices[sa] or not DishResolver.Spices[sb] then
		return nil
	end
	local twist = (tw ~= "none" and DishResolver.Twists[tw]) and tw or nil
	local ok, dish = pcall(DishResolver.resolve, mainId, sa, sb, twist)
	if not ok then
		return nil
	end
	local info = {
		key = key,
		name = dish.name,
		emoji = dish.emoji,
		main = mainId,
		spices = { sa, sb },
		twist = twist,
		secret = dish.secretId,
		type = dish.type,
	}
	infoCache[key] = info
	return info
end

-- How many distinct dishes exist (for the Cookbook counter)
function DishResolver.totalDishes(): number
	return Config.TotalDishes
end

return DishResolver
