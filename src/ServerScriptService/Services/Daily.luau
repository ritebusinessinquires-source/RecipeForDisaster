-- Daily hooks: 7-day login calendar, 3 daily quests, Dish of the Day, free daily Spin.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Cosmetics = require(Shared.Cosmetics)
local Quests = require(Shared.Quests)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Economy = require(script.Parent.Economy)
local Monetization = require(script.Parent.Monetization)

local Daily = {}

-- Dish of the Day: one featured combo, same for everyone, changes at 00:00 UTC
function Daily.dishOfTheDay(day: number?): any
	day = day or Util.dayNumber()
	local rng = Random.new(Util.hash("dotd" .. tostring(day)))
	local main = Catalog.MainOrder[rng:NextInteger(1, #Catalog.MainOrder)]
	local a = Catalog.SpiceOrder[rng:NextInteger(1, #Catalog.SpiceOrder)]
	local b
	repeat
		b = Catalog.SpiceOrder[rng:NextInteger(1, #Catalog.SpiceOrder)]
	until b ~= a
	local DishResolver = require(ServerScriptService:WaitForChild("DishResolver"))
	local dish = DishResolver.resolve(main, a, b, nil)
	return { main = main, spices = { a, b }, name = dish.name, emoji = dish.emoji, key = Util.dishKey(main, a, b, nil) }
end

-- does this dish (ignoring Twist) match the Dish of the Day?
function Daily.matchesDishOfDay(dish: any): boolean
	local d = Daily.dishOfTheDay()
	return dish.mainId == d.main and Util.dishKey(dish.mainId, dish.spiceIds[1], dish.spiceIds[2], nil) == d.key
end

function Daily.weeklyHat(): string
	local week = Util.weekNumber()
	return Cosmetics.WeeklyHats[(week % #Cosmetics.WeeklyHats) + 1]
end

local function newQuests(player: any, data: any, day: number)
	local rng = Random.new(Util.hash(tostring(player.UserId or 0) .. ":" .. tostring(day)))
	local pool = {}
	for _, q in ipairs(Quests.Pool) do
		if not q.needs or data.pantry[q.needs] then
			table.insert(pool, q)
		end
	end
	Util.shuffle(pool, rng)
	local list = {}
	for i = 1, math.min(Config.QuestsPerDay, #pool) do
		table.insert(list, { id = pool[i].id, progress = 0, claimed = false })
	end
	data.daily.quests = list
	data.daily.questDay = day
	data.daily.questBonus = false
end

-- Called when the player joins: advances the login streak and rolls quests.
function Daily.onJoin(player: any)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local d = data.daily
	local today = Util.dayNumber()
	if d.lastDay ~= today then
		if d.lastDay == today - 1 then
			if d.streakDay >= 7 then
				d.streakDay = 1
				d.streakWeeks += 1
			else
				d.streakDay += 1
			end
		else
			-- missing a day restarts the current week, not the whole streak
			d.streakDay = 1
		end
		d.lastDay = today
		d.totalLogins += 1
	end
	if d.questDay ~= today then
		newQuests(player, data, today)
	end
	PlayerData.sync(player)
end

function Daily.claimLogin(player: any): (boolean, string)
	local data = PlayerData.get(player)
	if not data then
		return false, "Not loaded"
	end
	local d = data.daily
	local today = Util.dayNumber()
	if d.claimedDay == today then
		return false, "Already claimed today"
	end
	local reward = Config.LoginCalendar[math.clamp(d.streakDay, 1, 7)]
	d.claimedDay = today
	local parts = {}
	if reward.cash then
		Economy.award(player, reward.cash, "Daily login", { raw = true, quiet = true })
		table.insert(parts, Util.formatNumber(reward.cash) .. " Cash")
	end
	if reward.spins then
		data.spins += reward.spins
		table.insert(parts, reward.spins .. " Spin" .. (reward.spins > 1 and "s" or ""))
	end
	if reward.weeklyHat then
		local hat = Daily.weeklyHat()
		data.cosmetics.owned[hat] = true
		table.insert(parts, Cosmetics.Items[hat].name)
	end
	PlayerData.sync(player)
	return true, "Day " .. d.streakDay .. ": " .. table.concat(parts, " + ")
end

-- Quest progress. event: surviveDish | cookSpice | cookMain | beChef | chefElimination | win | cookbook | playRound
function Daily.progress(player: any, event: string, payload: any?, amount: number?)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if data.daily.questDay ~= Util.dayNumber() then
		newQuests(player, data, Util.dayNumber())
	end
	payload = payload or {}
	local changedAny = false
	for _, q in ipairs(data.daily.quests) do
		local def = Quests.get(q.id)
		if def and def.event == event and q.progress < def.target then
			local ok = true
			if def.filter then
				for k, v in pairs(def.filter) do
					if k == "twist" then
						if (payload.twist ~= nil) ~= v then
							ok = false
						end
					elseif k == "spice" then
						if not (payload.spices and table.find(payload.spices, v)) then
							ok = false
						end
					elseif payload[k] ~= v then
						ok = false
					end
				end
			end
			if ok then
				q.progress = math.min(def.target, q.progress + (amount or 1))
				changedAny = true
				if q.progress >= def.target then
					Net.fire(player, "Toast", { text = "Quest complete: " .. def.text .. " - claim it in Daily!", kind = "quest" })
				end
			end
		end
	end
	if changedAny then
		PlayerData.sync(player)
	end
end

function Daily.claimQuest(player: any, index: number): (boolean, string)
	local data = PlayerData.get(player)
	if not data then
		return false, "Not loaded"
	end
	local q = data.daily.quests[index]
	local def = q and Quests.get(q.id)
	if not q or not def then
		return false, "No quest"
	end
	if q.claimed then
		return false, "Already claimed"
	end
	if q.progress < def.target then
		return false, "Not finished yet"
	end
	q.claimed = true
	Economy.award(player, def.reward, "Quest: " .. def.text, { raw = true })
	local msg = "+" .. def.reward .. " Cash"
	local all = true
	for _, other in ipairs(data.daily.quests) do
		if not other.claimed then
			all = false
		end
	end
	if all and not data.daily.questBonus then
		data.daily.questBonus = true
		data.spins += Config.QuestBonusSpins
		msg ..= " + all 3 done: 1 Spin!"
	end
	PlayerData.sync(player)
	return true, msg
end

function Daily.claimFreeSpin(player: any): (boolean, string)
	local data = PlayerData.get(player)
	if not data then
		return false, "Not loaded"
	end
	local now = os.time()
	local left = 86400 - (now - data.daily.lastFreeSpin)
	if left > 0 then
		return false, "Next free Spin in " .. Util.formatDuration(left)
	end
	local n = Monetization.owns(player, "VIP") and 2 or 1
	data.daily.lastFreeSpin = now
	data.spins += n
	PlayerData.sync(player)
	return true, "+" .. n .. " free Spin" .. (n > 1 and "s" or "") .. "!"
end

return Daily
