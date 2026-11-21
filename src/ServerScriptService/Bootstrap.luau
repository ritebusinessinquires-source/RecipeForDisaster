-- Server start-up. One place, two modes:
--   Lobby  (public servers):   the studio lobby + PLAY pad queue. Queued players are teleported
--                              together (up to 20) into a fresh reserved server.
--   Match  (reserved servers): waits for the group to arrive, then runs rounds back to back.
-- In Studio the lobby can't reserve servers, so finishing the queue turns the server into a match.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local Net = require(Shared.Net)

local Bootstrap = {}
Bootstrap.mode = "Lobby"

function Bootstrap.detectMode(): string
	if Config.ForceMode == "Lobby" or Config.ForceMode == "Match" then
		return Config.ForceMode :: string
	end
	-- reserved servers have a PrivateServerId but no owner
	if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
		return "Match"
	end
	return "Lobby"
end

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(120, 110, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 140, 130)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.GlobalShadows = true
	Lighting.ExposureCompensation = 0.1
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmo = Instance.new("Atmosphere")
		atmo.Density = 0.25
		atmo.Offset = 0.1
		atmo.Color = Color3.fromRGB(255, 236, 214)
		atmo.Decay = Color3.fromRGB(255, 200, 160)
		atmo.Glare = 0.2
		atmo.Haze = 0.6
		atmo.Parent = Lighting
	end
	local cc = Lighting:FindFirstChild("RFDColor") or Instance.new("ColorCorrectionEffect")
	cc.Name = "RFDColor"
	;(cc :: ColorCorrectionEffect).Saturation = 0.18
	;(cc :: ColorCorrectionEffect).Contrast = 0.05
	cc.Parent = Lighting
end

function Bootstrap.start(opts: any?)
	opts = opts or {}
	Players.CharacterAutoLoads = false
	Net.init()
	StarterPlayer.CharacterWalkSpeed = Config.WalkSpeed
	StarterPlayer.CharacterUseJumpPower = true
	StarterPlayer.CharacterJumpPower = Config.JumpPower
	setupLighting()

	local PlayerData = require(ServerScriptService.PlayerData)
	local DishResolver = require(ServerScriptService.DishResolver)
	local HazardRunner = require(ServerScriptService.HazardRunner)
	local ChefDraft = require(ServerScriptService.ChefDraft)
	local RoundManager = require(ServerScriptService.RoundManager)
	local Services = ServerScriptService.Services
	local Lobby = require(Services.Lobby)
	local Characters = require(Services.Characters)
	local Monetization = require(Services.Monetization)
	local Economy = require(Services.Economy)
	local Cookbook = require(Services.Cookbook)
	local Shop = require(Services.Shop)
	local Daily = require(Services.Daily)
	local Leaderboards = require(Services.Leaderboards)
	local Mailbox = require(Services.Mailbox)
	local Matchmaking = require(Services.Matchmaking)
	local MapManager = require(Services.MapManager)

	local state = Net.stateFolder()
	local mode = opts.mode or Bootstrap.detectMode()
	Bootstrap.mode = mode
	state:SetAttribute("Mode", mode)

	PlayerData.init()
	Lobby.build()
	HazardRunner.init()
	Monetization.init()
	Economy.init()
	Characters.init()
	Cookbook.init()
	Shop.init()
	Leaderboards.init()
	ChefDraft.init()
	RoundManager.init()

	local roundLoopStarted = false
	local function startRounds()
		if roundLoopStarted then
			return
		end
		roundLoopStarted = true
		task.spawn(RoundManager.loop)
	end

	-- Studio (or tests): the finished queue turns this lobby server into the match
	function Bootstrap.becomeMatch()
		if Bootstrap.mode == "Match" then
			return
		end
		Bootstrap.mode = "Match"
		state:SetAttribute("Mode", "Match")
		for _, name in ipairs({ "QueuePad", "QueueRing", "ArchPost", "PlaySign", "QueueStatusAnchor" }) do
			for _, d in ipairs((Lobby.model :: Model):GetChildren()) do
				if d.Name == name then
					d:Destroy()
				end
			end
		end
		MapManager.unload()
		Lobby.setBoard("howTo", "Each course, 3 Chefs secretly pick a Main and two Spices.\nEveryone survives the dish!\nLast player standing wins.")
		startRounds()
	end

	if mode == "Lobby" then
		state:SetAttribute("Phase", "Lobby")
		local pad = Lobby.buildQueuePad()
		Matchmaking.onChanged = Lobby.setQueueStatus
		if RunService:IsStudio() or opts.localLaunch then
			Matchmaking.onLocalLaunch = function(_group)
				Bootstrap.becomeMatch()
			end
		end
		Matchmaking.start(pad)
		-- a map below the studio, as scenery
		local scenery = Catalog.MapOrder[math.random(1, #Catalog.MapOrder)]
		pcall(MapManager.load, scenery)
		Lobby.setBoard("howTo", "Stand on the green PLAY pad to join the queue.\nUp to " .. Config.Matchmaking.MaxPlayers .. " chefs go into each kitchen together!")
	else
		startRounds()
	end

	-- leaving a match: back to a public lobby server
	Net.event("ReturnToLobby").OnServerEvent:Connect(function(player)
		if Bootstrap.mode ~= "Match" or player:GetAttribute("Leaving") then
			return
		end
		if RunService:IsStudio() then
			Net.fire(player, "TeleportNotice", { text = "Studio can't teleport - this would send you to the lobby.", kind = "error" })
			return
		end
		player:SetAttribute("Leaving", true)
		Net.fire(player, "TeleportNotice", { text = "Heading back to the lobby... 🏠", kind = "go" })
		task.spawn(function()
			PlayerData.save(player)
			local ok, err = pcall(TeleportService.TeleportAsync, TeleportService, game.PlaceId, { player })
			if not ok then
				warn("[Bootstrap] return to lobby failed:", err)
				player:SetAttribute("Leaving", nil)
				Net.fire(player, "TeleportNotice", { text = "Couldn't reach the lobby - try again!", kind = "error" })
			end
		end)
	end)

	local function onPlayerAdded(player: Player)
		-- match servers: the group size the lobby sent, so the first round waits for everyone
		if Bootstrap.mode == "Match" then
			local ok, joinData = pcall(player.GetJoinData, player)
			local td = ok and joinData and joinData.TeleportData
			if type(td) == "table" and type(td.expected) == "number" then
				RoundManager.expectPlayers(td.expected)
			end
		end
		local data = PlayerData.load(player)
		if not data or not player.Parent then
			return
		end
		-- invites: remember who brought this player in (rewarded after their first round)
		if data.stats.rounds == 0 and data.referral.by == 0 then
			local ok, joinData = pcall(player.GetJoinData, player)
			local by = ok and joinData and joinData.ReferredByPlayerId
			if type(by) == "number" and by > 0 and by ~= player.UserId then
				data.referral.by = by
			end
		end
		-- mail: gifts and invite rewards that arrived while away
		for _, item in ipairs(Mailbox.collect(player.UserId)) do
			if item.kind == "gift" and item.pass then
				data.gifted[item.pass] = true
				task.delay(4, function()
					Net.fire(player, "Toast", { text = (item.from or "A friend") .. " gifted you " .. (Monetization.PassNames[item.pass] or item.pass) .. "! 🎁", kind = "big" })
				end)
			elseif item.kind == "referral" and item.cash then
				data.cash += item.cash
				task.delay(4, function()
					Net.fire(player, "Toast", { text = (item.name or "Your friend") .. " played their first round! +" .. item.cash .. " Cash", kind = "big" })
				end)
			end
		end
		Monetization.refresh(player)
		Daily.onJoin(player)
		Leaderboards.setupPlayer(player)
		PlayerData.sync(player)
		Characters.spawnInLobby(player, false)
		RoundManager.onLateJoin(player)
		Leaderboards.refreshServerBoard()
	end

	Players.PlayerAdded:Connect(function(player)
		local ok, err = pcall(onPlayerAdded, player)
		if not ok then
			warn("[Bootstrap] player setup failed", player.Name, err)
			pcall(Characters.spawnInLobby, player, false)
		end
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, p)
	end

	-- keep everyone who isn't in the arena safely in the lobby
	task.spawn(function()
		while true do
			task.wait(1)
			local round = RoundManager.current()
			for _, p in ipairs(Players:GetPlayers()) do
				local char = p.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if root and not (round and round.alive[p]) and (root.Position.Y < Config.KillY or (root.Position.Y < Lobby.Origin.Y - 60 and (root.Position - Lobby.Origin).Magnitude > 150)) then
					Characters.teleport(p, Lobby.randomSpawnCFrame())
				end
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health <= 0 and not p:GetAttribute("Spawning") and not (round and round.deathTimes[p] and not round.ghosted[p]) then
					task.spawn(Characters.spawnInLobby, p, p:GetAttribute("Ghost") == true)
				end
			end
		end
	end)

	-- lobby boards: Dish of the Day + weekly ingredient countdown
	task.spawn(function()
		while true do
			local ok, dotd = pcall(Daily.dishOfTheDay)
			if ok then
				Lobby.setBoard("dishOfDay", dotd.emoji .. " " .. dotd.name .. "\n<font size=\"34\">Survive or cook it for 2x Cash!</font>")
			end
			Lobby.setBoard("countdown", "New Main or Spice every Saturday!\n" .. Util.formatDuration(Util.secondsUntilSaturday()))
			task.wait(30)
		end
	end)

	print(string.format("[Recipe for Disaster] %s server ready - %d secret recipes", mode, #DishResolver.RecipeList))
	return true
end

return Bootstrap
