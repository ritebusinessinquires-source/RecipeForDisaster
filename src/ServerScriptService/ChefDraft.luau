-- ChefDraft: picks 3 Chefs, deals each a private hand from their own Pantry, and collects
-- their secret picks. Checks each pick is a card the server dealt to that player; no pick
-- in time = a random card. Ghosts fill empty seats; bots pick if there still aren't enough.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Services = ServerScriptService:WaitForChild("Services")
local Monetization = require(Services:WaitForChild("Monetization"))
local Lexicon = require(game:GetService("ServerStorage"):WaitForChild("Lexicon"))
local TextService = game:GetService("TextService")

local MAX_TEXT = 40

local ChefDraft = {}

local BOT_NAMES = { "RoboChef 3000", "Auntie Bot", "Sir Spatula", "Chef Bleep", "Captain Crumb", "Madame Mixer", "Toasty", "Whiskers" }
local SLOTS = { "Main", "Spice", "Spice" }

local active: any = nil
local rng = Random.new()

export type ChefRec = { player: any?, name: string, userId: number, isBot: boolean, isGhost: boolean, slot: string, slotIndex: number }

local function seasonalMains(): { string }
	local out = {}
	local month = Util.utcMonth()
	for id, s in pairs(Config.Seasonal) do
		if s.month == month then
			table.insert(out, id)
		end
	end
	return out
end
ChefDraft.seasonalMains = seasonalMains

-- weight: players who haven't been Chef yet this session get a higher chance
local function pickFrom(pool: { any }, n: number, chefCounts: { [any]: number }): { any }
	local out = {}
	local list = table.clone(pool)
	while #out < n and #list > 0 do
		local p = Util.weightedPick(list, function(pl)
			return (chefCounts[pl] or 0) == 0 and 3 or 1
		end, rng)
		table.insert(out, p)
		table.remove(list, table.find(list, p) :: number)
	end
	return out
end

function ChefDraft.selectChefs(alive: { any }, ghosts: { any }, prevChefs: { [any]: boolean }, chefCounts: { [any]: number }): { ChefRec }
	local candidates = {}
	for _, p in ipairs(alive) do
		if not prevChefs[p] then
			table.insert(candidates, p)
		end
	end
	local chosen = pickFrom(candidates, 3, chefCounts)
	local isGhost = {}
	if #chosen < 3 then
		local ghostPool = {}
		for _, p in ipairs(ghosts) do
			if not prevChefs[p] and not table.find(chosen, p) then
				table.insert(ghostPool, p)
			end
		end
		for _, g in ipairs(pickFrom(ghostPool, 3 - #chosen, chefCounts)) do
			table.insert(chosen, g)
			isGhost[g] = true
		end
	end
	Util.shuffle(chosen, rng)
	local recs = {}
	local botNames = Util.shuffle(table.clone(BOT_NAMES), rng)
	for i = 1, 3 do
		local p = chosen[i]
		if p then
			table.insert(recs, { player = p, name = p.DisplayName or p.Name, userId = p.UserId or 0, isBot = not Net.isRealPlayer(p), isGhost = isGhost[p] == true, slot = SLOTS[i], slotIndex = i })
		else
			table.insert(recs, { player = nil, name = botNames[i], userId = 0, isBot = true, isGhost = false, slot = SLOTS[i], slotIndex = i })
		end
	end
	return recs
end

function ChefDraft.dealHand(rec: ChefRec, exclude: { string }?): { string }
	local pool = {}
	local data = rec.player and PlayerData.get(rec.player) or nil
	local order = rec.slot == "Main" and Catalog.MainOrder or Catalog.SpiceOrder
	for _, id in ipairs(order) do
		if rec.isBot or not data or data.pantry[id] then
			table.insert(pool, id)
		end
	end
	if rec.slot == "Main" then
		for _, id in ipairs(seasonalMains()) do
			table.insert(pool, id)
		end
	end
	if exclude and #pool > #exclude + 1 then
		local filtered = {}
		for _, id in ipairs(pool) do
			if not table.find(exclude, id) then
				table.insert(filtered, id)
			end
		end
		if #filtered >= 2 then
			pool = filtered
		end
	end
	local size = Config.HandSize
	if rec.player and Monetization.owns(rec.player, "BiggerHand") then
		size = Config.BiggerHandSize
	end
	Util.shuffle(pool, rng)
	local hand = {}
	for i = 1, math.min(size, #pool) do
		table.insert(hand, pool[i])
	end
	return hand
end

local function offer(rec: ChefRec, hand: { string })
	if rec.player and Net.isRealPlayer(rec.player) then
		Net.fire(rec.player, "OfferHand", {
			slot = rec.slot,
			slotIndex = rec.slotIndex,
			cards = hand,
			endsAt = active.endsAt,
			course = active.course,
			canReroll = Config.Products.RerollHand.id > 0 and not active.rerolled[rec.player],
			rerollPrice = Config.Products.RerollHand.price,
			typing = true,
			maxLength = MAX_TEXT,
		})
	end
end

-- Starts the draft (non-blocking). The round manager keeps ticking and calls finish().
function ChefDraft.start(course: number, alive: { any }, ghosts: { any }, prevChefs: { [any]: boolean }, chefCounts: { [any]: number })
	local recs = ChefDraft.selectChefs(alive, ghosts, prevChefs, chefCounts)
	active = {
		course = course,
		chefs = recs,
		hands = {},
		picks = {},
		rerolled = {},
		endsAt = workspace:GetServerTimeNow() + Config.Timings.Draft,
	}
	local banner = {}
	for i, rec in ipairs(recs) do
		active.hands[i] = ChefDraft.dealHand(rec)
		table.insert(banner, { name = rec.name, userId = rec.userId, slot = rec.slot, slotIndex = i, isBot = rec.isBot, isGhost = rec.isGhost })
		if rec.player then
			rec.player:SetAttribute("ChefSlot", rec.slot)
		end
	end
	Net.fireAll("TonightsChefs", { chefs = banner, endsAt = active.endsAt, course = course })
	for i, rec in ipairs(recs) do
		if rec.player and Net.isRealPlayer(rec.player) then
			offer(rec, active.hands[i])
		else
			-- bots (and test participants) pick after a short "think"
			local hand = active.hands[i]
			local myDraft = active
			task.delay(rng:NextNumber(1.5, 4.5), function()
				if active == myDraft and not myDraft.picks[i] then
					local text = Lexicon.botPick(rec.slot, rng)
					myDraft.picks[i] = { raw = text, display = text }
				end
			end)
		end
	end
	return active
end

function ChefDraft.isDone(): boolean
	if not active then
		return true
	end
	for i = 1, 3 do
		if not active.picks[i] then
			return false
		end
	end
	return true
end

local function cardPick(id: string): any
	local info = Catalog.ingredient(id)
	local name = info and info.name or id
	return { raw = string.lower(name), display = name, card = id }
end

-- Clean up typed text: printable characters only, single spaces, capped length.
function ChefDraft.sanitize(text: any): string?
	if type(text) ~= "string" then
		return nil
	end
	local t = string.gsub(text, "[%c]", " ")
	t = string.gsub(t, "%s+", " ")
	t = string.gsub(t, "^%s+", "")
	t = string.gsub(t, "%s+$", "")
	if utf8.len(t) == nil then
		return nil
	end
	if #t > MAX_TEXT then
		t = string.sub(t, 1, MAX_TEXT)
		while #t > 0 and utf8.len(t) == nil do
			t = string.sub(t, 1, -2)
		end
	end
	if t == "" then
		return nil
	end
	return t
end

-- Roblox requires typed text to be filtered before other players see it. If filtering
-- fails nothing typed is shown (the dish falls back to the ingredient names).
function ChefDraft.filter(player: any, text: string): string?
	if not Net.isRealPlayer(player) then
		return text
	end
	local ok, result = pcall(function()
		local r = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return r:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" then
		return result
	end
	return nil
end

-- Finishes the draft: a random card for anyone who didn't pick, then filters typed text.
function ChefDraft.finish(): any
	local d = active
	if not d then
		return nil
	end
	active = nil
	for i = 1, 3 do
		local rec = d.chefs[i]
		if not d.picks[i] then
			local hand = d.hands[i]
			local id = hand[rng:NextInteger(1, #hand)]
			d.picks[i] = cardPick(id)
			if rec.player then
				Net.fire(rec.player, "PickConfirmed", { card = id, auto = true })
			end
		end
		local pick = d.picks[i]
		if pick.needsFilter then
			pick.display = ChefDraft.filter(rec.player, pick.raw)
			pick.needsFilter = nil
		end
		if rec.player and typeof(rec.player) == "Instance" then
			rec.player:SetAttribute("ChefSlot", nil)
		end
	end
	return {
		chefs = d.chefs,
		entries = { main = d.picks[1], spices = { d.picks[2], d.picks[3] } },
		picks = d.picks,
	}
end

function ChefDraft.cancel()
	active = nil
end

-- Reroll Hand (developer product): swap your cards for new ones, once per course.
function ChefDraft.reroll(player: any): boolean
	if not active then
		return false
	end
	for i, rec in ipairs(active.chefs) do
		if rec.player == player and not active.picks[i] and not active.rerolled[player] then
			active.rerolled[player] = true
			active.hands[i] = ChefDraft.dealHand(rec, active.hands[i])
			offer(rec, active.hands[i])
			return true
		end
	end
	return false
end

function ChefDraft.init()
	-- payload: a card id the server dealt, or { text = "anything you like" }
	Net.event("PickIngredient").OnServerEvent:Connect(function(player, payload)
		if not active then
			return
		end
		for i, rec in ipairs(active.chefs) do
			if rec.player == player and not active.picks[i] then
				if type(payload) == "string" then
					-- only accept a card the server actually dealt to this player
					if table.find(active.hands[i], payload) then
						active.picks[i] = cardPick(payload)
						Net.fire(player, "PickConfirmed", { card = payload })
					end
				elseif type(payload) == "table" then
					local text = ChefDraft.sanitize(payload.text)
					if text then
						active.picks[i] = { raw = text, needsFilter = true }
						Net.fire(player, "PickConfirmed", { text = true })
					end
				end
				return
			end
		end
	end)
	Monetization.onProduct("RerollHand", function(player)
		if ChefDraft.reroll(player) then
			return true
		end
		-- couldn't reroll (draft already over): give a Spin instead so the purchase isn't lost
		local data = PlayerData.get(player)
		if data then
			data.spins += 1
			Net.fire(player, "Toast", { text = "Too late to reroll - here's a free Spin instead! 🎡", kind = "big" })
			return true
		end
		return false
	end)
end

return ChefDraft
