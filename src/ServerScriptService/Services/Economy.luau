-- Economy: every Cash payout goes through here so multipliers, toasts and round totals
-- stay consistent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Monetization = require(script.Parent.Monetization)

local Economy = {}

local roundEarnings: { [any]: number } = {}
local friendBonus: { [any]: boolean } = {}
local solo = false
local dishOfDayKey: string? = nil

function Economy.setSolo(v: boolean)
	solo = v
end

function Economy.setDishOfTheDay(key: string?)
	dishOfDayKey = key
end

function Economy.resetRound()
	table.clear(roundEarnings)
end

function Economy.roundEarnings(player: any): number
	return roundEarnings[player] or 0
end

function Economy.multiplier(player: any, dishKey: string?): number
	local m = Monetization.cashMultiplier(player)
	if friendBonus[player] then
		m *= 1 + Config.Economy.FriendBonus
	end
	if dishKey and dishOfDayKey and dishKey == dishOfDayKey then
		m *= Config.Economy.DishOfTheDayMultiplier
	end
	if solo then
		m *= Config.Economy.SoloMultiplier
	end
	return m
end

-- opts: { dishKey = string?, raw = bool (no multipliers), quiet = bool }
function Economy.award(player: any, amount: number, reason: string, opts: any?): number
	opts = opts or {}
	local data = PlayerData.get(player)
	if not data or amount <= 0 then
		return 0
	end
	local total = amount
	if not opts.raw then
		total = math.floor(amount * Economy.multiplier(player, opts.dishKey) + 0.5)
	end
	data.cash += total
	data.stats.cashEarned += total
	roundEarnings[player] = (roundEarnings[player] or 0) + total
	PlayerData.sync(player)
	if not opts.quiet then
		Net.fire(player, "Toast", { text = string.format("+%d  %s", total, reason), kind = "cash", cash = total })
	end
	return total
end

function Economy.spend(player: any, amount: number): boolean
	local data = PlayerData.get(player)
	if not data or data.cash < amount then
		return false
	end
	data.cash -= amount
	PlayerData.sync(player)
	return true
end

-- +10% Cash while a friend is in the server
local function refreshFriends()
	local list = Players:GetPlayers()
	for _, p in ipairs(list) do
		local has = false
		for _, q in ipairs(list) do
			if q ~= p then
				local ok, isFriend = pcall(p.IsFriendsWith, p, q.UserId)
				if ok and isFriend then
					has = true
					break
				end
			end
		end
		friendBonus[p] = has
		p:SetAttribute("FriendBonus", has)
	end
end

function Economy.init()
	Players.PlayerAdded:Connect(function()
		task.delay(3, refreshFriends)
	end)
	Players.PlayerRemoving:Connect(function(p)
		friendBonus[p] = nil
		roundEarnings[p] = nil
		task.delay(1, refreshFriends)
	end)
end

return Economy
