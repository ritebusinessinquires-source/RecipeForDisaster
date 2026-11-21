-- Recipe for Disaster: server entry point. Everything that decides or runs a dish lives on
-- the server; clients only show cards, the reveal and the HUD.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

Players.CharacterAutoLoads = false

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Net = require(Shared.Net)

-- create remotes + state folder before anything else
Net.event("State")
Net.stateFolder()

StarterPlayer.CharacterWalkSpeed = Config.WalkSpeed
StarterPlayer.CharacterUseJumpPower = true
StarterPlayer.CharacterJumpPower = Config.JumpPower

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

-- bright cartoon lighting
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
cc.Saturation = 0.18
cc.Contrast = 0.05
cc.Parent = Lighting

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

local function onPlayerAdded(player: Player)
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
		warn("[Main] player setup failed", player.Name, err)
		pcall(Characters.spawnInLobby, player, false)
	end
end)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

-- ghosts respawn in the lobby if they fall off it
task.spawn(function()
	while true do
		task.wait(1)
		local round = RoundManager.current()
		for _, p in ipairs(Players:GetPlayers()) do
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root and not (round and round.alive[p]) and (root.Position.Y < Config.KillY or root.Position.Y < Lobby.Origin.Y - 60 and (root.Position - Lobby.Origin).Magnitude > 150) then
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

task.spawn(RoundManager.loop)
print("[Recipe for Disaster] server ready -", #DishResolver.RecipeList, "secret recipes loaded")
