-- Pantry shop: buy ingredients with Cash, spin the wheel, equip cosmetics, redeem codes,
-- claim dailies. One RemoteFunction (ShopAction) handles every request; the server checks
-- everything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Cosmetics = require(Shared.Cosmetics)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Economy = require(script.Parent.Economy)
local Daily = require(script.Parent.Daily)
local Monetization = require(script.Parent.Monetization)

local Shop = {}

local spinRng = Random.new()
local lastAction: { [any]: number } = {}

local function priceOf(id: string): number?
	local m = Catalog.Mains[id]
	if m and not m.seasonal then
		return m.price
	end
	local s = Catalog.Spices[id]
	if s then
		return s.price
	end
	return nil
end
Shop.priceOf = priceOf

-- Spin the Pantry wheel. Odds are shown on the wheel.
function Shop.rollSpin(player: any): any
	local data = PlayerData.get(player)
	local pick = Util.weightedPick(Config.SpinOdds, function(o)
		return o.weight
	end, spinRng)
	local kind = pick and pick.id or "cash"
	local function cosmeticOf(rarity: string, slot: string?)
		local list = Cosmetics.listByRarity(rarity, slot)
		return list[spinRng:NextInteger(1, #list)]
	end
	if kind == "cash" then
		local amount = spinRng:NextInteger(Config.SpinCashRange[1], Config.SpinCashRange[2])
		amount = math.floor(amount / 10) * 10
		data.cash += amount
		return { kind = "cash", amount = amount, label = Util.formatNumber(amount) .. " Cash", segment = "cash" }
	elseif kind == "ingredient" then
		local all = {}
		for _, id in ipairs(Catalog.MainOrder) do
			if not Catalog.Mains[id].starter then
				table.insert(all, id)
			end
		end
		for _, id in ipairs(Catalog.SpiceOrder) do
			if not Catalog.Spices[id].starter then
				table.insert(all, id)
			end
		end
		local id = all[spinRng:NextInteger(1, #all)]
		local info = Catalog.ingredient(id)
		if data.pantry[id] then
			-- spinning the same rare ingredient twice turns it into Cash
			local amount = math.max(150, math.floor((priceOf(id) or 300) / 2))
			data.cash += amount
			return { kind = "dupe", id = id, amount = amount, label = info.emoji .. " " .. info.name .. " (already owned) -> " .. amount .. " Cash", segment = "ingredient" }
		end
		data.pantry[id] = true
		return { kind = "ingredient", id = id, label = info.emoji .. " " .. info.name .. "!", segment = "ingredient" }
	else
		local rarity = kind == "common" and "common" or kind == "epic" and "epic" or "legendary"
		local id = cosmeticOf(rarity, rarity == "legendary" and "hat" or nil)
		local item = Cosmetics.Items[id]
		if data.cosmetics.owned[id] then
			local amount = rarity == "common" and Config.DuplicateCommonCash or rarity == "epic" and Config.DuplicateEpicCash or Config.DuplicateLegendaryCash
			data.cash += amount
			return { kind = "dupe", id = id, amount = amount, label = item.name .. " (already owned) -> " .. amount .. " Cash", segment = kind }
		end
		data.cosmetics.owned[id] = true
		return { kind = "cosmetic", id = id, rarity = rarity, label = item.name .. "!", segment = kind }
	end
end

local handlers: { [string]: (Player, any) -> any } = {}

handlers.buyIngredient = function(player, args)
	local data = PlayerData.get(player)
	local id = type(args) == "table" and args.id
	local price = type(id) == "string" and priceOf(id) or nil
	if not price then
		return { ok = false, msg = "Not for sale" }
	end
	if data.pantry[id] then
		return { ok = false, msg = "Already in your Pantry" }
	end
	if not Economy.spend(player, price) then
		return { ok = false, msg = "Not enough Cash" }
	end
	data.pantry[id] = true
	PlayerData.sync(player)
	local info = Catalog.ingredient(id)
	return { ok = true, msg = info.emoji .. " " .. info.name .. " added to your Pantry!" }
end

handlers.equip = function(player, args)
	local data = PlayerData.get(player)
	local id = type(args) == "table" and args.id
	local item = type(id) == "string" and Cosmetics.Items[id] or nil
	if not item then
		return { ok = false, msg = "Unknown item" }
	end
	if not data.cosmetics.owned[id] then
		return { ok = false, msg = "You don't own that yet" }
	end
	if data.cosmetics.equipped[item.slot] == id and item.slot == "back" then
		data.cosmetics.equipped.back = nil
	else
		data.cosmetics.equipped[item.slot] = id
	end
	PlayerData.sync(player)
	if player:GetAttribute("IsChef") and item.slot == "hat" then
		local Characters = require(script.Parent.Characters)
		Characters.setChefHat(player, true)
	end
	return { ok = true, msg = "Equipped " .. item.name }
end

handlers.setTaunt = function(player, args)
	local data = PlayerData.get(player)
	local id = type(args) == "table" and args.id
	for _, t in ipairs(Catalog.Taunts) do
		if t.id == id then
			data.taunt = id
			PlayerData.sync(player)
			return { ok = true, msg = "Taunt set: " .. t.name }
		end
	end
	return { ok = false, msg = "Unknown taunt" }
end

handlers.spin = function(player)
	local data = PlayerData.get(player)
	if data.spins <= 0 then
		return { ok = false, msg = "No Spins left" }
	end
	data.spins -= 1
	local result = Shop.rollSpin(player)
	PlayerData.sync(player)
	return { ok = true, result = result }
end

handlers.redeemCode = function(player, args)
	local data = PlayerData.get(player)
	local code = type(args) == "table" and type(args.code) == "string" and string.upper(string.gsub(args.code, "%s", "")) or ""
	local reward = Config.Codes[code]
	if not reward then
		return { ok = false, msg = "That code doesn't exist" }
	end
	if data.codes[code] then
		return { ok = false, msg = "Already redeemed" }
	end
	data.codes[code] = true
	local parts = {}
	if reward.cash then
		data.cash += reward.cash
		table.insert(parts, Util.formatNumber(reward.cash) .. " Cash")
	end
	if reward.spins then
		data.spins += reward.spins
		table.insert(parts, reward.spins .. " Spin" .. (reward.spins > 1 and "s" or ""))
	end
	PlayerData.sync(player)
	return { ok = true, msg = "Code redeemed: +" .. table.concat(parts, " + ") }
end

handlers.claimLogin = function(player)
	local ok, msg = Daily.claimLogin(player)
	return { ok = ok, msg = msg }
end

handlers.claimQuest = function(player, args)
	local ok, msg = Daily.claimQuest(player, type(args) == "table" and tonumber(args.index) or 0)
	return { ok = ok, msg = msg }
end

handlers.claimFreeSpin = function(player)
	local ok, msg = Daily.claimFreeSpin(player)
	return { ok = ok, msg = msg }
end

handlers.claimGroupSpin = function(player)
	local data = PlayerData.get(player)
	if data.groupSpin then
		return { ok = false, msg = "Already claimed" }
	end
	local ok, inGroup = pcall(player.IsInGroup, player, Config.GroupId)
	if not ok or not inGroup then
		return { ok = false, msg = "Join the group first, then claim!" }
	end
	data.groupSpin = true
	data.spins += 1
	PlayerData.sync(player)
	return { ok = true, msg = "Thanks for joining! +1 Spin" }
end

handlers.notifyPrompted = function(player)
	local data = PlayerData.get(player)
	data.notifyPrompted = true
	PlayerData.sync(player)
	return { ok = true }
end

handlers.dailyInfo = function(player)
	local dotd = Daily.dishOfTheDay()
	return {
		ok = true,
		dishOfDay = dotd,
		weeklyHat = Daily.weeklyHat(),
		nextDrop = Util.secondsUntilSaturday(),
		freeSpinIn = math.max(0, 86400 - (os.time() - PlayerData.get(player).daily.lastFreeSpin)),
		vip = Monetization.owns(player, "VIP"),
	}
end

handlers.giftTargets = function(player)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			table.insert(list, { userId = p.UserId, name = p.DisplayName })
		end
	end
	return { ok = true, list = list }
end

function Shop.init()
	Net.func("ShopAction").OnServerInvoke = function(player, action, args)
		if type(action) ~= "string" or not handlers[action] then
			return { ok = false, msg = "Unknown action" }
		end
		if not PlayerData.isLoaded(player) then
			return { ok = false, msg = "Still loading your data..." }
		end
		-- simple rate limit
		local now = os.clock()
		if lastAction[player] and now - lastAction[player] < 0.15 then
			return { ok = false, msg = "Slow down!" }
		end
		lastAction[player] = now
		local ok, res = pcall(handlers[action], player, args)
		if not ok then
			warn("[Shop]", action, res)
			return { ok = false, msg = "Something went wrong" }
		end
		return res
	end
	Players.PlayerRemoving:Connect(function(p)
		lastAction[p] = nil
	end)
end

return Shop
