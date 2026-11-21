-- PlayerData: Cash, Pantry, Cookbook, cosmetics, dailies. Saved per player in a DataStore
-- with a light session lock and retries. Saves on leave, every 2 minutes and on shutdown.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Cosmetics = require(Shared.Cosmetics)
local Net = require(Shared.Net)
local Util = require(Shared.Util)

local PlayerData = {}

local SAVE_INTERVAL = 120
local LOCK_TIMEOUT = 300
local DATA_VERSION = 1

local store: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(Config.DataStoreName)
end)

type Profile = { data: any, userId: number, loaded: boolean, noSave: boolean, dirty: boolean, lastSave: number }
local profiles: { [any]: Profile } = {}

local changed = Instance.new("BindableEvent")
PlayerData.Changed = changed.Event -- (player, data)
local loadedEvent = Instance.new("BindableEvent")
PlayerData.Loaded = loadedEvent.Event -- (player, data)

function PlayerData.default(): any
	local pantry = {}
	for id, m in pairs(Catalog.Mains) do
		if m.starter then
			pantry[id] = true
		end
	end
	for id, s in pairs(Catalog.Spices) do
		if s.starter then
			pantry[id] = true
		end
	end
	local owned = {}
	for slot, id in pairs(Cosmetics.Defaults) do
		owned[id] = true
	end
	return {
		version = DATA_VERSION,
		cash = Config.StarterCash,
		spins = Config.StarterSpins,
		pantry = pantry,
		cookbook = {},
		cookbookCount = 0,
		secrets = {},
		badges = {},
		cosmetics = { owned = owned, equipped = table.clone(Cosmetics.Defaults) },
		taunt = "chefs_kiss",
		stats = { wins = 0, rounds = 0, courses = 0, chefKOs = 0, timesChef = 0, deaths = 0, cashEarned = 0, dishesCooked = 0 },
		daily = {
			lastDay = 0,
			streakDay = 0,
			streakWeeks = 0,
			totalLogins = 0,
			claimedDay = 0,
			lastFreeSpin = 0,
			questDay = 0,
			quests = {},
			questBonus = false,
		},
		codes = {},
		gifted = {},
		groupSpin = false,
		referral = { by = 0, rewarded = false },
		receipts = {},
		firstJoin = os.time(),
		notifyPrompted = false,
	}
end

-- Fill in any fields added after the profile was first saved.
local function reconcile(data: any, template: any)
	for k, v in pairs(template) do
		if data[k] == nil then
			data[k] = Util.copy(v)
		elseif type(v) == "table" and type(data[k]) == "table" and next(v) ~= nil and #v == 0 then
			reconcile(data[k], v)
		end
	end
end

local function isReal(player: any): boolean
	return Net.isRealPlayer(player) and player.UserId > 0
end

local function key(userId: number): string
	return "u_" .. tostring(userId)
end

function PlayerData.load(player: any): any
	if profiles[player] then
		return profiles[player].data
	end
	local data = nil
	local noSave = false
	if isReal(player) and store then
		for attempt = 1, 5 do
			local ok, result = pcall(function()
				return (store :: DataStore):UpdateAsync(key(player.UserId), function(old)
					old = old or PlayerData.default()
					local lock = old.lock
					if lock and lock.jobId ~= game.JobId and os.time() - (lock.time or 0) < LOCK_TIMEOUT and attempt < 4 then
						return nil -- another server still has it; try again shortly
					end
					old.lock = { jobId = game.JobId, time = os.time() }
					return old
				end)
			end)
			if ok and result then
				data = result
				break
			end
			if not ok and (string.find(tostring(result), "Studio", 1, true) or string.find(tostring(result), "not allowed", 1, true)) then
				break -- Studio without API access: don't keep the player waiting
			end
			if not player.Parent then
				return nil
			end
			task.wait(1.5 * attempt)
		end
		if not data then
			warn("[PlayerData] could not load data for", player.Name, "- progress won't save this session")
			noSave = true
		end
	else
		noSave = true
	end
	data = data or PlayerData.default()
	reconcile(data, PlayerData.default())
	data.lock = nil
	if not player.Parent and isReal(player) then
		return nil
	end
	profiles[player] = { data = data, userId = (player.UserId or 0), loaded = true, noSave = noSave, dirty = false, lastSave = os.clock() }
	loadedEvent:Fire(player, data)
	PlayerData.sync(player)
	return data
end

function PlayerData.get(player: any): any
	local p = profiles[player]
	if p then
		return p.data
	end
	if not isReal(player) then
		-- test participants / bots get an in-memory profile
		local data = PlayerData.default()
		profiles[player] = { data = data, userId = 0, loaded = true, noSave = true, dirty = false, lastSave = 0 }
		return data
	end
	return nil
end

function PlayerData.isLoaded(player: any): boolean
	return profiles[player] ~= nil
end

function PlayerData.markDirty(player: any)
	local p = profiles[player]
	if p then
		p.dirty = true
	end
end

-- Snapshot sent to the owning client (Cookbook entries are fetched separately).
function PlayerData.snapshot(player: any): any
	local d = PlayerData.get(player)
	if not d then
		return nil
	end
	return {
		cash = d.cash,
		spins = d.spins,
		pantry = d.pantry,
		cookbookCount = d.cookbookCount,
		secretsFound = Util.countKeys(d.secrets),
		badges = d.badges,
		cosmetics = d.cosmetics,
		taunt = d.taunt,
		stats = d.stats,
		daily = d.daily,
		groupSpin = d.groupSpin,
		notifyPrompted = d.notifyPrompted,
	}
end

local pendingSync: { [any]: boolean } = {}
function PlayerData.sync(player: any)
	PlayerData.markDirty(player)
	if pendingSync[player] then
		return
	end
	pendingSync[player] = true
	task.defer(function()
		pendingSync[player] = nil
		local d = PlayerData.get(player)
		if d then
			changed:Fire(player, d)
			Net.fire(player, "DataSync", PlayerData.snapshot(player))
		end
	end)
end

function PlayerData.save(player: any, release: boolean?)
	local p = profiles[player]
	if not p or p.noSave or not store or p.userId <= 0 then
		return
	end
	local snapshot = Util.copy(p.data)
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			(store :: DataStore):UpdateAsync(key(p.userId), function(old)
				if old and old.lock and old.lock.jobId ~= game.JobId and os.time() - (old.lock.time or 0) < LOCK_TIMEOUT then
					return nil -- another server took over this profile; don't clobber it
				end
				snapshot.lock = (not release) and { jobId = game.JobId, time = os.time() } or nil
				return snapshot
			end)
		end)
		if ok then
			p.dirty = false
			p.lastSave = os.clock()
			return
		end
		warn("[PlayerData] save failed", p.userId, err)
		task.wait(1 + attempt)
	end
end

function PlayerData.release(player: any)
	PlayerData.save(player, true)
	profiles[player] = nil
end

function PlayerData.init()
	Players.PlayerRemoving:Connect(function(player)
		if profiles[player] then
			PlayerData.release(player)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(10)
			for player, p in pairs(profiles) do
				if p.dirty and os.clock() - p.lastSave >= SAVE_INTERVAL and isReal(player) then
					task.spawn(PlayerData.save, player)
				end
			end
		end
	end)
	game:BindToClose(function()
		local threads = 0
		for player, _ in pairs(profiles) do
			threads += 1
			task.spawn(function()
				PlayerData.save(player, true)
				threads -= 1
			end)
		end
		local t0 = os.clock()
		while threads > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)
end

return PlayerData
