-- Client-side store: the player's data snapshot and the shared game state.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local State = {}

State.data = nil :: any
local dataChanged = Instance.new("BindableEvent")
State.DataChanged = dataChanged.Event

State.game = Net.stateFolder()

function State.get(attr: string): any
	return State.game:GetAttribute(attr)
end

function State.onGame(attr: string, fn: (any) -> ())
	State.game:GetAttributeChangedSignal(attr):Connect(function()
		fn(State.game:GetAttribute(attr))
	end)
	fn(State.game:GetAttribute(attr))
end

function State.activeDishes(): { any }
	local raw = State.get("ActiveDishes")
	if type(raw) ~= "string" or raw == "" then
		return {}
	end
	local ok, list = pcall(HttpService.JSONDecode, HttpService, raw)
	return ok and list or {}
end

function State.timeLeft(): number
	local endsAt = State.get("PhaseEndsAt")
	if type(endsAt) ~= "number" then
		return 0
	end
	return math.max(0, endsAt - workspace:GetServerTimeNow())
end

function State.isAlive(): boolean
	return Players.LocalPlayer:GetAttribute("Alive") == true
end

function State.passes(): { [string]: boolean }
	local raw = Players.LocalPlayer:GetAttribute("Passes")
	if type(raw) ~= "string" then
		return {}
	end
	local ok, t = pcall(HttpService.JSONDecode, HttpService, raw)
	return ok and t or {}
end

function State.init()
	Net.event("DataSync").OnClientEvent:Connect(function(snapshot)
		State.data = snapshot
		dataChanged:Fire(snapshot)
	end)
end

return State
