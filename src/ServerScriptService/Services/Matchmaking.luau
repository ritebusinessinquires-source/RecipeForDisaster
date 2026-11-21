-- Matchmaking (lobby servers only): walk onto the PLAY pad to join the queue, walk off to
-- leave. A countdown starts with the first player; when it ends (or the queue fills up) the
-- queued players are teleported together into a fresh reserved match server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Matchmaking = {}

local MM = Config.Matchmaking
local state = Net.stateFolder()

local queue: { any } = {}
local countdownEndsAt: number? = nil
local launching = false
-- players already sent to a match: they're still standing on the pad while the teleport
-- happens, so they must not be queued again (cleared if the teleport fails)
local launched: { [any]: number } = {}
local LAUNCH_COOLDOWN = 45
local pad: BasePart? = nil

-- Overridable for tests
Matchmaking.getPlayers = function(): { any }
	return Players:GetPlayers()
end
Matchmaking.isReady = function(p: any): boolean
	return PlayerData.isLoaded(p)
end
-- Called in Studio (no reserved servers there) or by tests instead of teleporting.
Matchmaking.onLocalLaunch = nil :: ((group: { any }) -> ())?

local function onPad(p: any): boolean
	local char = p.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or not pad then
		return false
	end
	local rel = (pad :: BasePart).CFrame:PointToObjectSpace(root.Position)
	local r = (pad :: BasePart).Size.Y / 2 -- the pad is a cylinder lying on its side: Y/Z are its diameter
	return Vector2.new(rel.Y, rel.Z).Magnitude <= r and root.Position.Y > pad.Position.Y - 1 and root.Position.Y < pad.Position.Y + 10
end

local function publish()
	local status = "Waiting"
	if launching then
		status = "Teleporting"
	elseif countdownEndsAt then
		status = "Starting"
	end
	state:SetAttribute("QueueCount", #queue)
	state:SetAttribute("QueueMax", MM.MaxPlayers)
	state:SetAttribute("QueueEndsAt", countdownEndsAt and (workspace:GetServerTimeNow() + (countdownEndsAt - os.clock())) or nil)
	state:SetAttribute("QueueStatus", status)
	if Matchmaking.onChanged then
		Matchmaking.onChanged(#queue, MM.MaxPlayers, countdownEndsAt and math.max(0, countdownEndsAt - os.clock()) or nil, status)
	end
end
Matchmaking.onChanged = nil :: ((count: number, max: number, secondsLeft: number?, status: string) -> ())?

local function setQueued(p: any, on: boolean)
	if typeof(p) == "Instance" then
		p:SetAttribute("InQueue", on or nil)
	elseif p.SetAttribute then
		p:SetAttribute("InQueue", on or nil)
	end
end

local function remove(p: any)
	local i = table.find(queue, p)
	if i then
		table.remove(queue, i)
		setQueued(p, false)
	end
end

local function teleportGroup(group: { Player })
	local ok, code = pcall(TeleportService.ReserveServer, TeleportService, game.PlaceId)
	if not ok then
		warn("[Matchmaking] ReserveServer failed:", code)
		Net.fireList(group, "TeleportNotice", { text = "Couldn't open a kitchen - step back on the pad to try again!", kind = "error" })
		return false
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = code
	options:SetTeleportData({ match = true, expected = #group })
	for attempt = 1, 3 do
		local alive = {}
		for _, p in ipairs(group) do
			if p.Parent then
				table.insert(alive, p)
			end
		end
		if #alive == 0 then
			return true
		end
		local tok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, alive, options)
		if tok then
			return true
		end
		warn("[Matchmaking] TeleportAsync failed (attempt " .. attempt .. "):", err)
		task.wait(2 * attempt)
	end
	Net.fireList(group, "TeleportNotice", { text = "Teleport failed - step back on the pad to try again!", kind = "error" })
	return false
end

function Matchmaking.launch()
	if launching or #queue == 0 then
		return
	end
	launching = true
	local group = {}
	while #group < MM.MaxPlayers and #queue > 0 do
		local p = table.remove(queue, 1)
		setQueued(p, false)
		table.insert(group, p)
	end
	countdownEndsAt = nil
	publish()
	for _, p in ipairs(group) do
		launched[p] = os.clock()
	end
	Net.fireList(group, "TeleportNotice", { text = "Heading to the kitchen! " .. #group .. " chef" .. (#group == 1 and "" or "s") .. " 🍳", kind = "go" })
	if Matchmaking.onLocalLaunch then
		Matchmaking.onLocalLaunch(group)
	elseif not teleportGroup(group) then
		for _, p in ipairs(group) do
			launched[p] = nil -- let them queue again
		end
	end
	launching = false
	publish()
end

function Matchmaking.tick()
	if launching then
		return
	end
	-- who's standing on the pad?
	for _, p in ipairs(Matchmaking.getPlayers()) do
		local sentAt = launched[p]
		if sentAt and os.clock() - sentAt > LAUNCH_COOLDOWN then
			launched[p] = nil
			sentAt = nil
		end
		local here = sentAt == nil and onPad(p) and Matchmaking.isReady(p)
		local queued = table.find(queue, p) ~= nil
		if here and not queued and #queue < MM.MaxPlayers then
			table.insert(queue, p)
			setQueued(p, true)
		elseif not here and queued then
			remove(p)
		end
	end
	-- drop anyone who left the server
	for i = #queue, 1, -1 do
		local p = queue[i]
		if typeof(p) == "Instance" and not p.Parent then
			table.remove(queue, i)
		end
	end
	local now = os.clock()
	if #queue >= MM.MinPlayers then
		countdownEndsAt = countdownEndsAt or (now + MM.Countdown)
		if #queue >= MM.MaxPlayers then
			countdownEndsAt = math.min(countdownEndsAt :: number, now + MM.FullCountdown)
		end
	else
		countdownEndsAt = nil
	end
	publish()
	if countdownEndsAt and now >= countdownEndsAt then
		task.spawn(Matchmaking.launch)
	end
end

function Matchmaking.queue(): { any }
	return queue
end

function Matchmaking.start(padPart: BasePart)
	pad = padPart
	state:SetAttribute("QueueMax", MM.MaxPlayers)
	TeleportService.TeleportInitFailed:Connect(function(player, result, message)
		warn("[Matchmaking] teleport failed for", player.Name, result, message)
		launched[player] = nil
		Net.fire(player, "TeleportNotice", { text = "Teleport failed (" .. tostring(result.Name) .. ") - step back on the pad!", kind = "error" })
	end)
	Players.PlayerRemoving:Connect(function(p)
		remove(p)
		launched[p] = nil
	end)
	if RunService:IsStudio() and not Matchmaking.onLocalLaunch then
		warn("[Matchmaking] Studio can't reserve servers; the queue will turn this server into the match instead.")
	end
	task.spawn(function()
		while pad and pad.Parent do
			local ok, err = pcall(Matchmaking.tick)
			if not ok then
				warn("[Matchmaking] tick error:", err)
			end
			task.wait(0.25)
		end
	end)
end

return Matchmaking
