-- RoundManager: the core loop.
--   Intermission + map vote (15 s) -> per course: Chef draft (10 s) -> Reveal (5 s) ->
--   Cook (45 s, ramps at 30 s; 30 s from course 6 with a free Fast Spice) -> next course.
--   A round keeps adding courses until one player is left. Earlier dishes keep running.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local Net = require(Shared.Net)

local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local DishResolver = require(ServerScriptService:WaitForChild("DishResolver"))
local HazardRunner = require(ServerScriptService:WaitForChild("HazardRunner"))
local ChefDraft = require(ServerScriptService:WaitForChild("ChefDraft"))
local Services = ServerScriptService:WaitForChild("Services")
local Status = require(Services:WaitForChild("Status"))
local MapManager = require(Services:WaitForChild("MapManager"))
local Characters = require(Services:WaitForChild("Characters"))
local Economy = require(Services:WaitForChild("Economy"))
local Cookbook = require(Services:WaitForChild("Cookbook"))
local Daily = require(Services:WaitForChild("Daily"))
local Badges = require(Services:WaitForChild("Badges"))
local Leaderboards = require(Services:WaitForChild("Leaderboards"))
local Monetization = require(Services:WaitForChild("Monetization"))
local Mailbox = require(Services:WaitForChild("Mailbox"))
local Lobby = require(Services:WaitForChild("Lobby"))

local RoundManager = {}

local T = Config.Timings
local state = Net.stateFolder()
local rng = Random.new()

-- session-wide
local chefCounts: { [any]: number } = {}
local serverDishes: { [string]: boolean } = {}
local lastMaps: { string } = {}
local mapVotes: { [any]: string } = {}
local mapVoteOpen = false
local blockedMap: string? = nil

local round: any = nil
RoundManager.timeScale = 1 -- tests run faster

local function setState(k: string, v: any)
	state:SetAttribute(k, v)
end

local function setPhase(phase: string, duration: number)
	setState("Phase", phase)
	setState("PhaseEndsAt", workspace:GetServerTimeNow() + duration * RoundManager.timeScale)
end

function RoundManager.current()
	return round
end

---------------------------------------------------------------- targets

local function makeTarget(p: any): any
	local char = p.Character
	if not char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return nil
	end
	return { player = p, character = char, root = root, humanoid = hum }
end

local targetCache: { any } = {}
local targetCacheAt = 0
local function getTargets(): { any }
	local now = os.clock()
	if now - targetCacheAt < 0.05 then
		return targetCache
	end
	targetCacheAt = now
	local list = {}
	if round then
		for p in pairs(round.alive) do
			local t = makeTarget(p)
			if t then
				table.insert(list, t)
			end
		end
	end
	targetCache = list
	return list
end
RoundManager.getTargets = getTargets

---------------------------------------------------------------- helpers

local function realPlayersInServer(): { Player }
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if PlayerData.isLoaded(p) then
			table.insert(out, p)
		end
	end
	return out
end

local function aliveList(): { any }
	local out = {}
	if round then
		for p in pairs(round.alive) do
			table.insert(out, p)
		end
	end
	return out
end

-- everyone in the server who isn't alive in the round: ghosts and spectators
local function ghostList(): { any }
	local out = {}
	for _, p in ipairs(realPlayersInServer()) do
		if not (round and round.alive[p]) then
			table.insert(out, p)
		end
	end
	return out
end

local function isOver(): boolean
	if not round then
		return true
	end
	if round.solo then
		return round.aliveCount <= 0
	end
	return round.aliveCount <= 1
end

local function updateActiveDishes()
	local list = {}
	if round then
		for _, entry in pairs(round.dishes) do
			if entry.handle then
				table.insert(list, {
					id = entry.dish.id,
					name = entry.dish.name,
					emoji = entry.dish.emoji,
					icon = entry.dish.hint and entry.dish.hint.icon or "run",
					course = entry.course,
					secret = entry.dish.secretId ~= nil,
				})
			end
		end
	end
	table.sort(list, function(a, b)
		return a.course > b.course
	end)
	setState("ActiveDishes", HttpService:JSONEncode(list))
end

local function chefNames(chefs: { any }): string
	local names = {}
	for _, c in ipairs(chefs) do
		table.insert(names, c.name)
	end
	if #names <= 1 then
		return names[1] or "?"
	end
	return table.concat(names, ", ", 1, #names - 1) .. " & " .. names[#names]
end

local function dishPayloadIngredients(entry: any): { any }
	local dish = entry.dish
	local chefs = entry.chefs or {}
	local out = {}
	local ids = { dish.mainId, dish.spiceIds[1], dish.spiceIds[2] }
	for i, id in ipairs(ids) do
		local info = Catalog.ingredient(id)
		table.insert(out, { id = id, name = info and info.name or id, emoji = info and info.emoji or "?", slot = i == 1 and "Main" or "Spice", chef = chefs[i] and chefs[i].name or "?" })
	end
	return out
end

---------------------------------------------------------------- ghosts & twist vote

local function sendGhostVote(p: any)
	if round and round.ghostVote and not round.alive[p] then
		local gv = round.ghostVote
		local counts = {}
		for _, id in pairs(gv.votes) do
			counts[id] = (counts[id] or 0) + 1
		end
		Net.fire(p, "GhostVoteOptions", { options = gv.options, counts = counts, course = gv.course, mine = gv.votes[p] })
	end
end

local function openGhostVote(nextCourse: number)
	local pool = Util.shuffle(table.clone(Catalog.TwistOrder), rng)
	round.ghostVote = { options = { pool[1], pool[2], pool[3] }, votes = {}, course = nextCourse }
	for _, p in ipairs(ghostList()) do
		sendGhostVote(p)
	end
end

local function closeGhostVote(): string?
	if not round or not round.ghostVote then
		return nil
	end
	local gv = round.ghostVote
	round.ghostVote = nil
	Net.fireAll("GhostVoteOptions", nil)
	local counts = {}
	local best, bestN = {}, 0
	for _, id in pairs(gv.votes) do
		counts[id] = (counts[id] or 0) + 1
	end
	for id, n in pairs(counts) do
		if n > bestN then
			best, bestN = { id }, n
		elseif n == bestN then
			table.insert(best, id)
		end
	end
	if bestN == 0 then
		return nil
	end
	return best[rng:NextInteger(1, #best)]
end

local function makeGhost(p: any)
	if not round or round.ghosted[p] then
		return
	end
	round.ghosted[p] = true
	if Net.isRealPlayer(p) then
		task.spawn(function()
			Characters.spawnInLobby(p, true)
			sendGhostVote(p)
		end)
	end
end

---------------------------------------------------------------- eliminations

local function onEliminated(p: any, reason: string?)
	if not round or not round.alive[p] then
		return
	end
	round.alive[p] = nil
	round.aliveCount -= 1
	round.deathTimes[p] = os.clock()
	round.order += 1
	p:SetAttribute("Alive", nil)
	setState("AliveCount", round.aliveCount)

	local dishId = Status.lastDish(p)
	local entry = dishId and round.dishes[dishId] or nil
	if entry then
		round.courseKills[dishId] = (round.courseKills[dishId] or 0) + 1
		for _, rec in ipairs(entry.chefs) do
			local chef = rec.player
			if chef and chef ~= p and (not Net.isRealPlayer(chef) or chef.Parent) then
				Economy.award(chef, Config.Economy.PerElimination, "Your dish got " .. (p.DisplayName or p.Name) .. "!", { dishKey = entry.dish.key })
				local data = PlayerData.get(chef)
				if data then
					data.stats.chefKOs += 1
				end
				round.chefKOs[chef] = (round.chefKOs[chef] or 0) + 1
				Leaderboards.addStat(chef, "kos", 1)
				Daily.progress(chef, "chefElimination")
				if Monetization.owns(chef, "ChefTaunts") and data then
					Net.fireAll("Taunt", { userId = chef.UserId, taunt = data.taunt })
				end
			end
		end
	end
	local data = PlayerData.get(p)
	if data then
		data.stats.deaths += 1
	end
	local fell = reason == "fell" or round.fellOff[p] == true
	if reason ~= "left" then
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if root then
			Characters.deathEffect(p, root.Position)
		end
		local survived = os.clock() - round.startClock
		Net.fire(p, "Eliminated", {
			dishName = entry and entry.dish.name or (fell and "Gravity" or "A Kitchen Accident"),
			emoji = entry and entry.dish.emoji or "💫",
			secret = entry and entry.dish.secretId ~= nil or false,
			ingredients = entry and dishPayloadIngredients(entry) or {},
			twist = entry and entry.dish.twistId or nil,
			survived = survived,
			cash = Economy.roundEarnings(p),
			course = round.course,
			fell = fell,
			ghostDelay = Config.Timings.GhostButtonDelay,
			place = round.aliveCount + 1,
		})
		local myRound = round
		task.delay(Config.Timings.AutoGhostAfter * RoundManager.timeScale, function()
			if round == myRound then
				makeGhost(p)
			end
		end)
	end
	Status.reset(p)
	Characters.setChefHat(p, false)
end

local function watchParticipant(p: any)
	local char = p.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		onEliminated(p, "left")
		return
	end
	local myRound = round
	local conn
	conn = hum.Died:Connect(function()
		conn:Disconnect()
		if round == myRound then
			onEliminated(p)
		end
	end)
	table.insert(round.connections, conn)
	table.insert(round.connections, (char :: Model).AncestryChanged:Connect(function(_, parent)
		if parent == nil and round == myRound and round.alive[p] then
			onEliminated(p, "left")
		end
	end))
end

---------------------------------------------------------------- per-tick

local lastTileUpdate = 0
local function tick(dt: number)
	if not round then
		return
	end
	local map = round.map
	for p in pairs(round.alive) do
		Status.tick(p, dt)
		local char = p.Character
		local hum0 = char and char:FindFirstChildOfClass("Humanoid")
		if hum0 and hum0.Health <= 0 then
			-- safety net in case Died didn't fire
			onEliminated(p)
			continue
		end
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and root.Position.Y < map.killY then
			-- falling off counts as a kill for the last dish that hit you
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health > 0 then
				Status.recordHit(p, Status.lastDish(p))
				round.fellOff[p] = true
				hum.Health = 0
			end
		end
	end
	round.survivalAccum += dt
	local interval = Config.Economy.SurviveTickInterval * RoundManager.timeScale
	while round.survivalAccum >= interval do
		round.survivalAccum -= interval
		for p in pairs(round.alive) do
			Economy.award(p, Config.Economy.SurviveTick, "Survived 10s", { quiet = true })
		end
	end
	local now = os.clock()
	if now - lastTileUpdate > 0.25 and map.tiles then
		lastTileUpdate = now
		map.tiles:update()
	end
end

-- Waits up to `seconds` (scaled), ticking the round. Stops early when the round is over or
-- `until` returns true. `each(elapsed)` runs every tick.
local function waitFor(seconds: number, untilFn: (() -> boolean)?, each: ((number) -> ())?)
	local total = seconds * RoundManager.timeScale
	local start = os.clock()
	local last = start
	while true do
		task.wait(0.1)
		local now = os.clock()
		local dt = now - last
		last = now
		tick(dt)
		if each then
			each((now - start) / RoundManager.timeScale)
		end
		if now - start >= total or isOver() or (untilFn and untilFn()) then
			break
		end
	end
end

---------------------------------------------------------------- course pieces

local function awardChefs(dish: any, chefs: { any })
	local isNew = not serverDishes[dish.key]
	serverDishes[dish.key] = true
	local dotd = Daily.matchesDishOfDay(dish)
	for i, rec in ipairs(chefs) do
		local p = rec.player
		if p and (not Net.isRealPlayer(p) or p.Parent) then
			local data = PlayerData.get(p)
			Economy.award(p, Config.Economy.BeingChef, "Being a Chef", { dishKey = dotd and dish.key or nil })
			if isNew then
				Economy.award(p, Config.Economy.NewOnServer, "A dish nobody here has made before!")
			end
			if dish.wasted and i >= 2 then
				Economy.award(p, Config.Economy.WastedSpice, "Wasted Spice consolation")
			end
			if data then
				data.stats.timesChef += 1
				data.stats.dishesCooked += 1
			end
			Daily.progress(p, "beChef")
			if i == 1 then
				Daily.progress(p, "cookMain")
			end
			Daily.progress(p, "cookSpice", { spices = dish.spiceIds })
			Cookbook.add(p, dish, "cooked")
		end
	end
	return isNew
end

local function courseEnd(course: number, entry: any)
	local dish = entry.dish
	for p in pairs(round.alive) do
		Economy.award(p, Config.Economy.SurviveCourse, "Survived course " .. course, { dishKey = dish.key })
		local data = PlayerData.get(p)
		if data then
			data.stats.courses += 1
		end
		Cookbook.add(p, dish, "survived")
		Daily.progress(p, "surviveDish", { type = dish.type, twist = dish.twistId })
	end
	-- Chef wipeout bonus + banner
	local results = {}
	for dishId, kills in pairs(round.courseKills) do
		local e = round.dishes[dishId]
		if e and kills > 0 then
			if kills >= Config.Economy.KitchenNightmareThreshold then
				for _, rec in ipairs(e.chefs) do
					if rec.player and (not Net.isRealPlayer(rec.player) or rec.player.Parent) then
						Economy.award(rec.player, Config.Economy.KitchenNightmare, "KITCHEN NIGHTMARE! " .. e.dish.name)
					end
				end
			end
			table.insert(results, { dish = e.dish.name, emoji = e.dish.emoji, chefs = chefNames(e.chefs), count = kills, nightmare = kills >= Config.Economy.KitchenNightmareThreshold })
		end
	end
	table.sort(results, function(a, b)
		return a.count > b.count
	end)
	table.clear(round.courseKills)
	Net.fireAll("CourseResults", { course = course, results = results, alive = round.aliveCount })
end

local function revealPayload(dish: any, chefs: { any }, isNew: boolean): any
	local potSkin = "#9AA4AE"
	local mainChef = chefs[1] and chefs[1].player
	if mainChef then
		local data = PlayerData.get(mainChef)
		local Cosmetics = require(Shared.Cosmetics)
		local item = data and Cosmetics.Items[data.cosmetics.equipped.pot]
		if item then
			potSkin = item.color
		end
	end
	local secret = nil
	if dish.secretId then
		local r = DishResolver.Recipes[dish.secretId]
		secret = { id = r.id, name = r.name, emoji = r.emoji, desc = r.desc }
	end
	return {
		course = dish.course,
		name = dish.name,
		emoji = dish.emoji,
		words = dish.words,
		ingredients = dishPayloadIngredients({ dish = dish, chefs = chefs }),
		twist = dish.twistId and { id = dish.twistId, name = Catalog.Twists[dish.twistId].name, emoji = Catalog.Twists[dish.twistId].emoji } or nil,
		hint = dish.hint,
		secret = secret,
		jokes = dish.jokes,
		wasted = dish.wasted,
		confused = dish.confused,
		suddenDeath = dish.suddenDeath,
		potColor = potSkin,
		isNew = isNew,
		dishOfDay = Daily.matchesDishOfDay(dish),
		duration = T.Reveal,
	}
end

---------------------------------------------------------------- the round

-- participants: Players (or test stand-ins with the same fields)
function RoundManager.runRound(participants: { any }, mapId: string)
	local map = MapManager.load(mapId)
	table.insert(lastMaps, 1, mapId)
	while #lastMaps > 2 do
		table.remove(lastMaps)
	end
	local solo = #participants < Config.MinPlayersForRound
	round = {
		id = HttpService:GenerateGUID(false),
		mapId = mapId,
		map = map,
		participants = participants,
		alive = {},
		aliveCount = 0,
		deathTimes = {},
		ghosted = {},
		fellOff = {},
		dishes = {},
		courseKills = {},
		chefKOs = {},
		prevChefs = {},
		connections = {},
		course = 0,
		order = 0,
		solo = solo,
		survivalAccum = 0,
		startClock = os.clock(),
		ghostVote = nil,
	}
	Economy.resetRound()
	Economy.setSolo(solo)
	Economy.setDishOfTheDay(Daily.dishOfTheDay().key)
	setState("Map", mapId)
	setState("Practice", solo)
	setState("TotalCount", #participants)
	setState("RoundActive", true)
	setState("SuddenDeath", false)
	setState("ActiveDishes", "[]")

	-- everyone into the arena (drop each spawn point onto whatever ground is there)
	local spawnParams = RaycastParams.new()
	spawnParams.FilterType = Enum.RaycastFilterType.Include
	spawnParams.FilterDescendantsInstances = { map.model }
	for i, p in ipairs(participants) do
		local sp = map.spawnPoints[((i - 1) % #map.spawnPoints) + 1]
		local hit = workspace:Raycast(Vector3.new(sp.X, map.floorY + 80, sp.Z), Vector3.new(0, -200, 0), spawnParams)
		if hit then
			sp = Vector3.new(sp.X, hit.Position.Y + 4, sp.Z)
		end
		Status.reset(p)
		p:SetAttribute("Ghost", nil)
		p:SetAttribute("Alive", true)
		Characters.setGhost(p, false)
		local look = CFrame.lookAt(sp, Vector3.new(map.center.X, sp.Y, map.center.Z))
		Characters.teleport(p, look)
		Status.setInvulnerable(p, 2)
		round.alive[p] = true
		round.aliveCount += 1
		watchParticipant(p)
		local data = PlayerData.get(p)
		if data then
			data.stats.rounds += 1
		end
		Daily.progress(p, "playRound")
		Badges.award(p, "Welcome")
	end
	setState("AliveCount", round.aliveCount)

	-- courses
	for course = 1, Config.MaxCourses do
		if isOver() or (solo and course > Config.SoloMaxCourses) then
			break
		end
		round.course = course
		local sudden = course >= Config.SuddenDeathCourse
		setState("Course", course)
		setState("SuddenDeath", sudden)

		-- 1. Chef draft
		local twistId = course >= 2 and closeGhostVote() or nil
		setPhase("Draft", T.Draft)
		ChefDraft.start(course, aliveList(), ghostList(), round.prevChefs, chefCounts)
		waitFor(T.Draft, ChefDraft.isDone)
		local picks = ChefDraft.finish()
		if isOver() or not picks then
			break
		end
		local dishId = "C" .. course
		local dish = DishResolver.resolve(picks.main, picks.spice1, picks.spice2, twistId, {
			id = dishId,
			course = course,
			suddenDeath = sudden,
			seed = rng:NextInteger(1, 2 ^ 30),
		})
		local entry = { dish = dish, chefs = picks.chefs, course = course, handle = nil }
		round.dishes[dishId] = entry
		table.clear(round.prevChefs)
		for _, rec in ipairs(picks.chefs) do
			if rec.player then
				round.prevChefs[rec.player] = true
				chefCounts[rec.player] = (chefCounts[rec.player] or 0) + 1
				if round.alive[rec.player] then
					Characters.setChefHat(rec.player, true)
				end
			end
		end

		-- 2. Reveal
		local isNew = not serverDishes[dish.key]
		setPhase("Reveal", T.Reveal)
		Net.fireAll("RevealDish", revealPayload(dish, picks.chefs, isNew))
		waitFor(T.Reveal)
		awardChefs(dish, picks.chefs)
		if isOver() then
			break
		end

		-- 3. Cook
		local handle = HazardRunner.start(dish, { map = map, getTargets = getTargets })
		entry.handle = handle
		updateActiveDishes()
		local cookTime = sudden and T.CookSuddenDeath or T.Cook
		setPhase("Cook", cookTime)
		openGhostVote(course + 1)
		local ramped = false
		waitFor(cookTime, nil, function(elapsed)
			if not ramped and elapsed >= math.min(T.RampAt, cookTime * 0.66) then
				ramped = true
				HazardRunner.ramp(handle)
				Net.fireAll("FX", "Banner", { text = "IT'S HEATING UP! 🔥", color = "#E84A3A" })
			end
		end)
		HazardRunner.endTwist(handle)
		courseEnd(course, entry)
		for _, rec in ipairs(picks.chefs) do
			if rec.player then
				Characters.setChefHat(rec.player, false)
			end
		end
		if isOver() then
			break
		end
		setPhase("CourseEnd", T.CourseEnd)
		waitFor(T.CourseEnd)
	end

	RoundManager.finishRound()
end

function RoundManager.finishRound()
	if not round then
		return
	end
	local r = round
	ChefDraft.cancel()
	closeGhostVote()
	-- winner: last player standing; if the last ones die together, whoever lasted longest
	local winner = nil
	if not r.solo then
		local alive = aliveList()
		if #alive == 1 then
			winner = alive[1]
		elseif #alive > 1 then
			winner = alive[rng:NextInteger(1, #alive)]
		else
			local best, bestT = {}, -1
			for p, t in pairs(r.deathTimes) do
				if t > bestT + 0.05 then
					best, bestT = { p }, t
				elseif math.abs(t - bestT) <= 0.05 then
					table.insert(best, p)
				end
			end
			winner = best[1] and best[rng:NextInteger(1, #best)] or nil
		end
	end
	local topChef, topKOs = nil, 0
	for p, n in pairs(r.chefKOs) do
		if n > topKOs then
			topChef, topKOs = p, n
		end
	end
	if winner and (not Net.isRealPlayer(winner) or winner.Parent) then
		Economy.award(winner, Config.Economy.LastStanding, "LAST ONE STANDING!")
		local data = PlayerData.get(winner)
		if data then
			data.stats.wins += 1
		end
		Leaderboards.addStat(winner, "wins", 1)
		Badges.award(winner, "FirstWin")
		Daily.progress(winner, "win")
	end
	-- surviving practice players still get their course credit; nothing extra
	setPhase("Winner", T.Winner)
	Net.fireAll("Winner", {
		winner = winner and { name = winner.DisplayName or winner.Name, userId = winner.UserId or 0 } or nil,
		topChef = topChef and { name = topChef.DisplayName or topChef.Name, userId = topChef.UserId or 0, kos = topKOs } or nil,
		practice = r.solo,
		courses = r.course,
		participants = #r.participants,
	})

	-- referral reward: the first round an invited player finishes pays whoever invited them
	for _, p in ipairs(r.participants) do
		local data = PlayerData.get(p)
		if data and data.referral and data.referral.by > 0 and not data.referral.rewarded then
			data.referral.rewarded = true
			local inviter = Players:GetPlayerByUserId(data.referral.by)
			if inviter and PlayerData.isLoaded(inviter) then
				Economy.award(inviter, Config.Economy.ReferralReward, (p.DisplayName or "Your friend") .. " played their first round!", { raw = true })
			else
				Mailbox.send(data.referral.by, { kind = "referral", cash = Config.Economy.ReferralReward, name = p.DisplayName })
			end
		end
	end

	-- clean up
	for _, c in ipairs(r.connections) do
		c:Disconnect()
	end
	HazardRunner.stopAll()
	MapManager.unload()
	round = nil
	setState("RoundActive", false)
	setState("ActiveDishes", "[]")
	setState("AliveCount", 0)
	setState("SuddenDeath", false)
	for _, p in ipairs(r.participants) do
		Status.reset(p)
		p:SetAttribute("Alive", nil)
		p:SetAttribute("Ghost", nil)
		Characters.setChefHat(p, false)
	end
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("Ghost", nil)
		p:SetAttribute("Alive", nil)
		task.spawn(function()
			Characters.spawnInLobby(p, false)
			if p == winner then
				task.wait(0.3)
				Characters.teleport(p, CFrame.new(Lobby.podiumTop + Vector3.new(0, 3, 0)))
			end
		end)
	end
	Leaderboards.refreshServerBoard()
	RoundManager.waitPlain(T.Winner)
end

function RoundManager.waitPlain(seconds: number)
	task.wait(seconds * RoundManager.timeScale)
end

---------------------------------------------------------------- intermission

local function broadcastMapVote()
	local counts = {}
	for _, id in pairs(mapVotes) do
		counts[id] = (counts[id] or 0) + 1
	end
	Net.fireAll("MapVoteState", {
		options = Catalog.MapOrder,
		counts = counts,
		blocked = blockedMap,
		endsAt = state:GetAttribute("PhaseEndsAt"),
		open = mapVoteOpen,
	})
end

function RoundManager.intermission(): string
	table.clear(mapVotes)
	-- the same map can't be played more than twice in a row
	blockedMap = (lastMaps[1] and lastMaps[1] == lastMaps[2]) and lastMaps[1] or nil
	mapVoteOpen = true
	setState("Course", 0)
	setPhase("Intermission", T.Intermission)
	broadcastMapVote()
	task.wait(T.Intermission * RoundManager.timeScale)
	mapVoteOpen = false
	local counts = {}
	for _, id in pairs(mapVotes) do
		if id ~= blockedMap then
			counts[id] = (counts[id] or 0) + 1
		end
	end
	local best, bestN = {}, 0
	for _, id in ipairs(Catalog.MapOrder) do
		if id ~= blockedMap then
			local n = counts[id] or 0
			if n > bestN then
				best, bestN = { id }, n
			elseif n == bestN then
				table.insert(best, id)
			end
		end
	end
	local chosen = best[rng:NextInteger(1, #best)]
	broadcastMapVote()
	Net.fireAll("MapVoteState", { chosen = chosen, options = Catalog.MapOrder, counts = counts, open = false })
	return chosen
end

-- A fresh match server waits for the group the lobby sent before the first round.
RoundManager.expected = 0
RoundManager.arrivalDeadline = 0
function RoundManager.expectPlayers(n: number)
	if n > RoundManager.expected then
		if RoundManager.expected == 0 then
			RoundManager.arrivalDeadline = os.clock() + Config.Matchmaking.ArrivalWait
		end
		RoundManager.expected = math.min(n, Config.Matchmaking.MaxPlayers)
	end
end

function RoundManager.loop()
	while true do
		local ok, err = pcall(function()
			while #realPlayersInServer() == 0 do
				setState("Phase", "Waiting")
				task.wait(1)
			end
			if RoundManager.expected > 0 then
				setState("Phase", "Arriving")
				setState("PhaseEndsAt", workspace:GetServerTimeNow() + math.max(0, RoundManager.arrivalDeadline - os.clock()))
				while #realPlayersInServer() < RoundManager.expected and os.clock() < RoundManager.arrivalDeadline do
					setState("ArrivedCount", #realPlayersInServer())
					task.wait(0.5)
				end
				RoundManager.expected = 0
			end
			local mapId = RoundManager.intermission()
			local participants = {}
			for _, p in ipairs(realPlayersInServer()) do
				if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
					table.insert(participants, p)
				end
			end
			if #participants > 0 then
				RoundManager.runRound(participants, mapId)
			end
		end)
		if not ok then
			warn("[RoundManager] round error:", err)
			pcall(function()
				if round then
					round = nil
				end
				HazardRunner.stopAll()
				MapManager.unload()
				for _, p in ipairs(Players:GetPlayers()) do
					p:SetAttribute("Alive", nil)
					p:SetAttribute("Ghost", nil)
					task.spawn(Characters.spawnInLobby, p, false)
				end
			end)
			task.wait(3)
		end
	end
end

function RoundManager.init()
	Net.event("MapVote").OnServerEvent:Connect(function(player, mapId)
		if mapVoteOpen and type(mapId) == "string" and Catalog.Maps[mapId] and mapId ~= blockedMap then
			mapVotes[player] = mapId
			broadcastMapVote()
		end
	end)
	Net.event("GhostVote").OnServerEvent:Connect(function(player, twistId)
		if round and round.ghostVote and not round.alive[player] and type(twistId) == "string" and table.find(round.ghostVote.options, twistId) then
			round.ghostVote.votes[player] = twistId
			for _, p in ipairs(ghostList()) do
				sendGhostVote(p)
			end
		end
	end)
	Net.event("BecomeGhost").OnServerEvent:Connect(function(player)
		if round and round.deathTimes[player] and not round.ghosted[player] then
			makeGhost(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		mapVotes[p] = nil
		chefCounts[p] = nil
		if round and round.alive[p] then
			onEliminated(p, "left")
		end
		if round and round.ghostVote then
			round.ghostVote.votes[p] = nil
		end
	end)
end

-- a player who joins mid-round watches as a ghost until the next round
function RoundManager.onLateJoin(player: Player)
	if round then
		player:SetAttribute("Ghost", true)
		round.ghosted[player] = true
		sendGhostVote(player)
	end
end

return RoundManager
