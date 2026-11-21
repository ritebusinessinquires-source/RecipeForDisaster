-- Leaderboards: this server (Wins + Chef KOs in the player list) and weekly boards
-- ("Top Chef" = most players eliminated as Chef, "Last One Standing" = most wins).
-- Weeks reset Monday 00:00 UTC. Last week's top 100 get a title; #1 gets the Golden Whisk.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Lobby = require(script.Parent.Lobby)

local Leaderboards = {}

local BOARDS = { "TopChef", "LastStanding" }
local pending: { [number]: { [string]: number } } = {}
local cache: { [string]: { { name: string, value: number, userId: number } } } = { TopChef = {}, LastStanding = {} }
local lastWeekRanks: { [string]: { [number]: number } } = { TopChef = {}, LastStanding = {} }
local nameCache: { [number]: string } = {}

local function storeFor(board: string, week: number): OrderedDataStore?
	local ok, s = pcall(function()
		return DataStoreService:GetOrderedDataStore(Config.LeaderboardPrefix .. board .. "_" .. week)
	end)
	return ok and s or nil
end

local function nameOf(userId: number): string
	if nameCache[userId] then
		return nameCache[userId]
	end
	local p = Players:GetPlayerByUserId(userId)
	if p then
		nameCache[userId] = p.DisplayName
		return p.DisplayName
	end
	local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	nameCache[userId] = ok and n or ("Chef " .. userId)
	return nameCache[userId]
end

-- session stats in the player list
function Leaderboards.setupPlayer(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = ls
	local kos = Instance.new("IntValue")
	kos.Name = "Chef KOs"
	kos.Parent = ls
	ls.Parent = player
	-- last week's title
	local title = nil
	local tc = lastWeekRanks.TopChef[player.UserId]
	local ls2 = lastWeekRanks.LastStanding[player.UserId]
	if tc then
		title = "Top Chef #" .. tc
	elseif ls2 then
		title = "Last One Standing #" .. ls2
	end
	if title then
		player:SetAttribute("Title", title)
	end
	if tc == 1 or ls2 == 1 then
		local data = PlayerData.get(player)
		if data and not data.cosmetics.owned.back_whisk then
			data.cosmetics.owned.back_whisk = true
			data.cosmetics.equipped.back = "back_whisk"
			PlayerData.sync(player)
			Net.fire(player, "Toast", { text = "You were #1 last week! The Golden Whisk is yours. 🏆", kind = "big" })
		end
	end
end

function Leaderboards.addStat(player: any, stat: string, amount: number)
	if typeof(player) ~= "Instance" then
		return
	end
	local ls = player:FindFirstChild("leaderstats")
	local name = stat == "wins" and "Wins" or "Chef KOs"
	local v = ls and ls:FindFirstChild(name)
	if v then
		v.Value += amount
	end
	if player.UserId > 0 then
		local board = stat == "wins" and "LastStanding" or "TopChef"
		pending[player.UserId] = pending[player.UserId] or {}
		pending[player.UserId][board] = (pending[player.UserId][board] or 0) + amount
	end
end

function Leaderboards.flush()
	local week = Util.weekNumber()
	local work = pending
	pending = {}
	for userId, boards in pairs(work) do
		for board, amount in pairs(boards) do
			local s = storeFor(board, week)
			if s then
				local ok = pcall(function()
					s:IncrementAsync(tostring(userId), amount)
				end)
				if not ok then
					pending[userId] = pending[userId] or {}
					pending[userId][board] = (pending[userId][board] or 0) + amount
				end
			end
		end
	end
end

local function fetchTop(board: string, week: number, n: number): { any }
	local out = {}
	local s = storeFor(board, week)
	if not s then
		return out
	end
	pcall(function()
		local pages = (s :: OrderedDataStore):GetSortedAsync(false, n)
		for _, entry in ipairs(pages:GetCurrentPage()) do
			table.insert(out, { userId = tonumber(entry.key) or 0, value = entry.value })
		end
	end)
	return out
end

function Leaderboards.refreshBoards()
	local week = Util.weekNumber()
	for _, board in ipairs(BOARDS) do
		local top = fetchTop(board, week, 10)
		local list = {}
		for _, e in ipairs(top) do
			table.insert(list, { userId = e.userId, value = e.value, name = nameOf(e.userId) })
		end
		cache[board] = list
	end
	local function render(list, unit)
		if #list == 0 then
			return "No chefs yet this week.\nBe the first!"
		end
		local lines = {}
		for i, e in ipairs(list) do
			table.insert(lines, string.format("%d. %s - %d %s", i, e.name, e.value, unit))
		end
		return table.concat(lines, "\n")
	end
	Lobby.setBoard("topChef", render(cache.TopChef, "KOs") .. "\n<font size=\"30\">Resets in " .. Util.formatDuration(Util.secondsUntilWeekReset()) .. "</font>")
	Lobby.setBoard("lastStanding", render(cache.LastStanding, "wins") .. "\n<font size=\"30\">Resets in " .. Util.formatDuration(Util.secondsUntilWeekReset()) .. "</font>")
end

function Leaderboards.refreshServerBoard()
	local rows = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local ls = p:FindFirstChild("leaderstats")
		if ls then
			table.insert(rows, { name = p.DisplayName, wins = ls.Wins.Value, kos = ls["Chef KOs"].Value })
		end
	end
	table.sort(rows, function(a, b)
		if a.wins ~= b.wins then
			return a.wins > b.wins
		end
		return a.kos > b.kos
	end)
	local lines = {}
	for i = 1, math.min(6, #rows) do
		local r = rows[i]
		table.insert(lines, string.format("%s  🏆%d  👨‍🍳%d", r.name, r.wins, r.kos))
	end
	Lobby.setBoard("server", #lines > 0 and table.concat(lines, "\n") or "Play a round!")
end

function Leaderboards.get(): any
	return { TopChef = cache.TopChef, LastStanding = cache.LastStanding, resetsIn = Util.secondsUntilWeekReset() }
end

function Leaderboards.init()
	-- last week's top 100 get titles
	task.spawn(function()
		local lastWeek = Util.weekNumber() - 1
		for _, board in ipairs(BOARDS) do
			for i, e in ipairs(fetchTop(board, lastWeek, 100)) do
				lastWeekRanks[board][e.userId] = i
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			if not p:GetAttribute("Title") then
				local tc = lastWeekRanks.TopChef[p.UserId]
				local ls = lastWeekRanks.LastStanding[p.UserId]
				if tc then
					p:SetAttribute("Title", "Top Chef #" .. tc)
				elseif ls then
					p:SetAttribute("Title", "Last One Standing #" .. ls)
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			Leaderboards.refreshBoards()
			task.wait(90)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(45)
			Leaderboards.flush()
		end
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(Leaderboards.refreshServerBoard)
	end)
	game:BindToClose(function()
		Leaderboards.flush()
	end)
	Net.func("GetLeaderboards").OnServerInvoke = function()
		return Leaderboards.get()
	end
end

return Leaderboards
