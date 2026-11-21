-- Cookbook: every dish you've survived or cooked, a completion counter, badges at 10/50/250
-- and every secret recipe.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local DishResolver = require(ServerScriptService:WaitForChild("DishResolver"))
local Economy = require(script.Parent.Economy)
local Badges = require(script.Parent.Badges)
local Monetization = require(script.Parent.Monetization)
local Daily = require(script.Parent.Daily)

local Cookbook = {}

local MILESTONES = { { 10, "Dishes10" }, { 50, "Dishes50" }, { 250, "Dishes250" } }

-- how: "cooked" | "survived"
function Cookbook.add(player: any, dish: any, how: string)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local key = dish.key
	if not data.cookbook[key] then
		data.cookbook[key] = true
		data.cookbookCount += 1
		Economy.award(player, Config.Economy.NewCookbookEntry, "New in your Cookbook: " .. dish.name)
		Daily.progress(player, "cookbook", {})
		for _, m in ipairs(MILESTONES) do
			if data.cookbookCount >= m[1] then
				Badges.award(player, m[2])
			end
		end
	end
	if dish.secretId and not data.secrets[dish.secretId] then
		data.secrets[dish.secretId] = true
		Economy.award(player, Config.Economy.SecretRecipe, "SECRET RECIPE: " .. dish.name, { quiet = true })
		Net.fire(player, "Toast", { text = "📜 SECRET RECIPE DISCOVERED: " .. dish.name .. "! +" .. Config.Economy.SecretRecipe, kind = "big" })
		Badges.award(player, "SecretRecipe")
	end
	PlayerData.sync(player)
end

function Cookbook.fetch(player: any): any
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local entries = {}
	for key in pairs(data.cookbook) do
		local info = DishResolver.info(key)
		if info then
			table.insert(entries, info)
		end
	end
	table.sort(entries, function(a, b)
		if (a.secret ~= nil) ~= (b.secret ~= nil) then
			return a.secret ~= nil
		end
		return a.name < b.name
	end)
	local hints = Monetization.owns(player, "RecipeHints")
	local secrets = {}
	for _, r in ipairs(DishResolver.RecipeList) do
		local found = data.secrets[r.id] == true
		local entry = { id = r.id, found = found }
		if found then
			entry.name = r.name
			entry.emoji = r.emoji
			entry.desc = r.desc
			local ing = {}
			if r.main then
				table.insert(ing, Catalog.Mains[r.main].emoji .. " " .. Catalog.Mains[r.main].name)
			else
				table.insert(ing, "Any Main")
			end
			for _, s in ipairs(r.spices) do
				table.insert(ing, Catalog.Spices[s].emoji .. " " .. Catalog.Spices[s].name)
			end
			if r.anySpice then
				table.insert(ing, "Any Spice")
			end
			entry.ingredients = table.concat(ing, " + ")
		elseif hints then
			-- Recipe Hints pass: one ingredient of every locked secret recipe
			local s = r.spices[1]
			entry.hint = "Contains " .. Catalog.Spices[s].emoji .. " " .. Catalog.Spices[s].name
		end
		table.insert(secrets, entry)
	end
	return {
		count = data.cookbookCount,
		total = Config.TotalDishes,
		entries = entries,
		secrets = secrets,
		badges = data.badges,
		hasHints = hints,
	}
end

function Cookbook.init()
	Net.func("GetCookbook").OnServerInvoke = function(player)
		return Cookbook.fetch(player)
	end
end

return Cookbook
