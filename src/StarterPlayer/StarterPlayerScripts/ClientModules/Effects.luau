-- Client effects: visuals the server describes (meteors and their shadows, bolts, arcs,
-- shockwaves, warnings, lightning, death effects), plus everything applied to your own
-- character: knockback, ice sliding, magnetic/tornado pull, reversed controls, camera shake.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local Effects = {}
Effects.banner = function(_text: string, _color: Color3?, _small: boolean?) end

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local fxFolder: Folder

local function part(props: any): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		(p :: any)[k] = v
	end
	p.Parent = fxFolder
	return p
end

local function disc(pos: Vector3, radius: number, color: Color3, transparency: number): Part
	return part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, radius * 2, radius * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = transparency,
	})
end

local function burst(pos: Vector3, color: Color3, count: number, size: number?, speed: number?, texture: string?)
	local holder = part({ Size = Vector3.one, Position = pos, Transparency = 1 })
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture or "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new(size or 2, (size or 2) * 2)
	e.Transparency = NumberSequence.new(0.2, 1)
	e.Lifetime = NumberRange.new(0.5, 1.1)
	e.Speed = NumberRange.new((speed or 12) * 0.5, speed or 12)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = holder
	e:Emit(count)
	Debris:AddItem(holder, 2)
end

---------------------------------------------------------------- camera shake

local shakeUntil = 0
local shakeAmp = 0
function Effects.shake(intensity: number, duration: number)
	shakeAmp = math.max(shakeAmp, intensity)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

---------------------------------------------------------------- FX handlers

local handlers: { [string]: (any) -> () } = {}

handlers.Poof = function(p)
	burst(p.pos, p.color or Color3.new(1, 1, 1), 12, 2, 10)
end

handlers.Shockwave = function(p)
	local ring = disc(p.pos, 1, p.color or Color3.fromRGB(255, 240, 200), 0.3)
	local r = p.radius or 10
	local d = p.duration or 0.45
	TweenService:Create(ring, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.2, r * 2, r * 2), Transparency = 1 }):Play()
	Debris:AddItem(ring, d + 0.1)
end

handlers.Warning = function(p)
	local ring = disc(p.pos, p.radius or 8, p.color or Color3.fromRGB(255, 60, 40), 0.55)
	local d = p.duration or 1
	task.spawn(function()
		local t0 = os.clock()
		while ring.Parent and os.clock() - t0 < d do
			ring.Transparency = 0.35 + math.abs(math.sin((os.clock() - t0) * 10)) * 0.4
			task.wait()
		end
		ring:Destroy()
	end)
end

handlers.Meteor = function(p)
	local to: Vector3 = p.to
	local height = p.height or 90
	local dur = p.duration or 2
	local size = (p.size or 1)
	local style = p.style or "meteor"
	local from = to + Vector3.new(height * 0.25, height, -height * 0.15)
	local rockSize = style == "rubble" and 2 or 3.6 * size
	local rock = part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * rockSize,
		Position = from,
		Color = p.frozen and Color3.fromRGB(160, 215, 255) or Color3.fromRGB(110, 90, 80),
		Material = p.frozen and Enum.Material.Ice or Enum.Material.Slate,
		Transparency = p.invisible and 0.92 or 0,
		CastShadow = false,
	})
	if p.flaming then
		local f = Instance.new("Fire")
		f.Size = rockSize * 2
		f.Heat = 15
		f.Parent = rock
	elseif not p.invisible and style ~= "rubble" then
		local trail = Instance.new("Fire")
		trail.Size = rockSize * 1.2
		trail.Color = Color3.fromRGB(255, 160, 60)
		trail.SecondaryColor = Color3.fromRGB(120, 100, 90)
		trail.Heat = 10
		trail.Parent = rock
	end
	-- the shadow: grows as the meteor approaches ("watch the shadows")
	local radius = p.radius or 6
	local shadow = disc(to, radius * 0.35, Color3.fromRGB(20, 10, 10), p.invisible and 1 or 0.75)
	shadow.Material = Enum.Material.SmoothPlastic
	TweenService:Create(rock, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = to }):Play()
	TweenService:Create(shadow, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 0.35 }):Play()
	task.delay(dur, function()
		rock:Destroy()
		shadow:Destroy()
		if style ~= "rubble" then
			burst(to, p.frozen and Color3.fromRGB(200, 235, 255) or Color3.fromRGB(150, 130, 110), 10, 3 * size, 14)
		end
	end)
end

handlers.Impact = function(p)
	handlers.Shockwave({ pos = p.pos, radius = p.radius or 6, color = p.frozen and Color3.fromRGB(170, 225, 255) or (p.flaming and Color3.fromRGB(255, 140, 50) or nil) })
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root and (root.Position - p.pos).Magnitude < 40 then
		Effects.shake(0.35, 0.25)
	end
end

handlers.Bolt = function(p)
	local from: Vector3, to: Vector3 = p.from, p.to
	local dur = math.max(0.05, p.duration or 0.3)
	local width = p.width or 0.5
	local dir = to - from
	local len = math.min(6, dir.Magnitude)
	local bolt = part({
		Size = Vector3.new(width, width, len),
		CFrame = CFrame.lookAt(from, to),
		Color = p.color or Color3.fromRGB(255, 50, 50),
		Material = Enum.Material.Neon,
	})
	TweenService:Create(bolt, TweenInfo.new(dur, Enum.EasingStyle.Linear), { CFrame = CFrame.lookAt(to, to + dir) }):Play()
	Debris:AddItem(bolt, dur + 0.05)
	task.delay(dur, function()
		burst(to, p.color or Color3.fromRGB(255, 80, 80), 6, 1, 8)
	end)
end

handlers.Arc = function(p)
	local from: Vector3, to: Vector3 = p.from, p.to
	local dur = p.duration or 1
	local h = p.height or 25
	local style = p.style or "meteor"
	local size = style == "lava" and 3 or (style == "bomb" and 2.4 or 3 * (p.size or 1))
	local ball = part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		Position = from,
		Color = style == "lava" and Color3.fromRGB(255, 90, 20) or (style == "bomb" and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(110, 90, 80)),
		Material = style == "lava" and Enum.Material.Neon or Enum.Material.SmoothPlastic,
	})
	if style == "lava" then
		local f = Instance.new("Fire")
		f.Size = 6
		f.Parent = ball
	elseif style == "bomb" then
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(255, 200, 80)
		s.Parent = ball
	end
	task.spawn(function()
		local t0 = os.clock()
		while ball.Parent do
			local t = math.clamp((os.clock() - t0) / dur, 0, 1)
			local pos = from:Lerp(to, t) + Vector3.new(0, 4 * h * t * (1 - t), 0)
			ball.Position = pos
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		ball:Destroy()
	end)
end

handlers.Splash = function(p)
	burst(p.pos, Color3.fromRGB(180, 220, 255), 16, 1.5 * (p.size or 1), 18)
	UI.sound("Splash", 0.5)
end

handlers.Honk = function()
	UI.sound("Whoosh", 0.4, 0.6)
end

handlers.Banner = function(p)
	Effects.banner(p.text or "", p.color and Color3.fromHex(p.color) or nil, p.small)
end

local DEATH_COLORS = {
	death_confetti = { Color3.fromRGB(232, 74, 58), Color3.fromRGB(255, 201, 60), Color3.fromRGB(76, 175, 80), Color3.fromRGB(123, 79, 214) },
}
handlers.Death = function(p)
	local style = p.style or "death_poof"
	local pos = p.pos
	if style == "death_confetti" then
		for _, c in ipairs(DEATH_COLORS.death_confetti) do
			burst(pos, c, 10, 0.6, 22, "rbxasset://textures/particles/sparkles_main.dds")
		end
	elseif style == "death_splat" then
		burst(pos, Color3.fromRGB(200, 30, 20), 25, 1.2, 20)
		local s = disc(pos - Vector3.new(0, 2.8, 0), 3.5, Color3.fromRGB(200, 30, 20), 0.1)
		s.Material = Enum.Material.SmoothPlastic
		Debris:AddItem(s, 6)
	elseif style == "death_pancake" then
		burst(pos, Color3.fromRGB(232, 184, 106), 14, 1.5, 10)
	elseif style == "death_sparkle" then
		burst(pos, Color3.fromRGB(255, 143, 184), 30, 0.8, 16, "rbxasset://textures/particles/sparkles_main.dds")
	elseif style == "death_firework" then
		for i = 1, 3 do
			task.delay(i * 0.25, function()
				local c = Color3.fromHSV(math.random(), 0.7, 1)
				burst(pos + Vector3.new(0, 8 + i * 4, 0), c, 30, 0.8, 30, "rbxasset://textures/particles/sparkles_main.dds")
			end)
		end
	else
		burst(pos, Color3.new(1, 1, 1), 20, 2.5, 10)
	end
end

handlers.Lightning = function(p)
	local pos: Vector3 = p.pos
	local top = pos + Vector3.new(math.random(-10, 10), 120, math.random(-10, 10))
	local prev = top
	for i = 1, 8 do
		local t = i / 8
		local nextP = top:Lerp(pos, t) + (i < 8 and Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)) or Vector3.zero)
		local seg = part({
			Size = Vector3.new(0.8, 0.8, (nextP - prev).Magnitude),
			CFrame = CFrame.lookAt((prev + nextP) / 2, nextP),
			Color = Color3.fromRGB(255, 255, 170),
			Material = Enum.Material.Neon,
		})
		Debris:AddItem(seg, 0.25)
		prev = nextP
	end
	local cc = Lighting:FindFirstChild("RFDFlash") or Instance.new("ColorCorrectionEffect")
	cc.Name = "RFDFlash"
	cc.Parent = Lighting
	cc.Brightness = 0.5
	TweenService:Create(cc, TweenInfo.new(0.3), { Brightness = 0 }):Play()
	Effects.shake(0.5, 0.3)
end

local musicTint: ColorCorrectionEffect? = nil
local musicOn = false
handlers.Music = function(p)
	musicOn = p.on == true
	local snd = SoundService:FindFirstChild("RFDMusic") :: Sound?
	if not snd then
		local ns = Instance.new("Sound")
		ns.Name = "RFDMusic"
		ns.SoundId = Config.Sounds.Music or ""
		ns.Looped = true
		ns.Volume = 0.45
		ns.Parent = SoundService
		snd = ns
	end
	if musicOn then
		(snd :: Sound):Play()
	else
		(snd :: Sound):Stop()
	end
	if musicOn and not musicTint then
		musicTint = Instance.new("ColorCorrectionEffect")
		musicTint.Name = "RFDDisco"
		musicTint.Parent = Lighting
		task.spawn(function()
			local t = 0
			while musicOn and musicTint do
				t += 0.1
				musicTint.TintColor = Color3.fromHSV((t * 0.15) % 1, 0.25, 1)
				task.wait(0.1)
			end
			if musicTint then
				musicTint:Destroy()
				musicTint = nil
			end
		end)
	end
end

handlers.Beat = function()
	UI.sound("Tick", 0.5, 0.7)
	Effects.shake(0.15, 0.1)
end

local rainPart: Part? = nil
handlers.Rain = function(p)
	if p.on and not rainPart then
		rainPart = part({ Size = Vector3.new(200, 1, 200), Transparency = 1, Position = Vector3.new(0, 80, 0) })
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(180, 200, 230))
		e.Size = NumberSequence.new(0.15)
		e.Transparency = NumberSequence.new(0.3)
		e.Lifetime = NumberRange.new(1.2)
		e.Speed = NumberRange.new(80)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.Rate = 400
		e.Parent = rainPart
	elseif not p.on and rainPart then
		rainPart:Destroy()
		rainPart = nil
	end
end

handlers.LaneArrow = function(p)
	local from: Vector3 = p.from
	local dir: Vector3 = p.dir
	local len = p.length or 200
	local strip = part({
		Size = Vector3.new(p.width or 12, 0.2, len),
		CFrame = CFrame.lookAt(from + dir * len / 2, from + dir * len) + Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(255, 70, 60),
		Material = Enum.Material.Neon,
		Transparency = 0.6,
	})
	task.spawn(function()
		local t0 = os.clock()
		while strip.Parent and os.clock() - t0 < (p.duration or 1) do
			strip.Transparency = 0.4 + math.abs(math.sin((os.clock() - t0) * 12)) * 0.4
			task.wait()
		end
		strip:Destroy()
	end)
end

---------------------------------------------------------------- your own character

local slideVel = Vector3.zero
local lastPull = Vector3.zero
local upsideDown = false
local frozenUntil = 0
local overlay: Frame
local overlayLabel: TextLabel

local function myParts(): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function onKnockback(v: Vector3)
	local _, hum, root = myParts()
	if not root or not hum or typeof(v) ~= "Vector3" then
		return
	end
	if v.Y > 8 then
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	if v.Magnitude > 45 then
		UI.sound("Boing", 0.5, 0.9 + math.random() * 0.3)
	end
	root.AssemblyLinearVelocity = v
	slideVel = Vector3.new(v.X, 0, v.Z)
end

local function setOverlay(text: string?, color: Color3?)
	if text then
		overlay.Visible = true
		overlay.BackgroundColor3 = color or UI.C.Grape
		overlayLabel.Text = text
	else
		overlay.Visible = false
	end
end

local controls = nil
local function getControls()
	if controls then
		return controls
	end
	local ok, pm = pcall(function()
		return require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	end)
	if ok and pm then
		controls = pm:GetControls()
	end
	return controls
end

local function onClientEffect(e: any)
	if type(e) ~= "table" then
		return
	end
	if e.kind == "Frozen" then
		frozenUntil = os.clock() + (e.duration or 1)
		setOverlay("❄️ FROZEN!", Color3.fromRGB(150, 210, 255))
		task.delay(e.duration or 1, function()
			if os.clock() >= frozenUntil and not upsideDown then
				setOverlay(nil)
			end
		end)
	elseif e.kind == "UpsideDown" then
		upsideDown = e.on == true and State.isAlive()
		if upsideDown then
			setOverlay("🙃 UPSIDE DOWN! Controls reversed!", UI.C.Grape)
			UI.sound("Whoosh", 0.6, 0.7)
		else
			setOverlay(nil)
		end
	end
end

local function step(dt: number)
	local _, hum, root = myParts()
	if not hum or not root or hum.Health <= 0 then
		return
	end
	local alive = State.isAlive()
	-- ice: keep your momentum
	if alive and hum.FloorMaterial == Enum.Material.Ice then
		local want = hum.MoveDirection * hum.WalkSpeed
		slideVel = slideVel:Lerp(want, math.clamp(dt * 1.1, 0, 1))
		if slideVel.Magnitude < 2 and want.Magnitude < 1 then
			slideVel = slideVel * 0.98
		end
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(slideVel.X, v.Y, slideVel.Z)
	else
		local v = root.AssemblyLinearVelocity
		slideVel = Vector3.new(v.X, 0, v.Z)
	end
	-- pull sources (tornado, magnets, sinkhole, wisps)
	if alive then
		local pull = Vector3.zero
		for _, src in ipairs(CollectionService:GetTagged("RFD_Pull")) do
			if src:IsA("BasePart") and src:IsDescendantOf(workspace) then
				local r = src:GetAttribute("PullRadius") or 30
				local s = src:GetAttribute("PullStrength") or 8
				local d = src.Position - root.Position
				local flat = Vector3.new(d.X, 0, d.Z)
				local m = flat.Magnitude
				if m < r and m > 1.5 then
					pull += flat.Unit * s * (1 - m / r * 0.6)
				end
			end
		end
		-- conveyor-style: replace last frame's pull with this frame's so it never stacks up
		local v = root.AssemblyLinearVelocity - lastPull
		root.AssemblyLinearVelocity = v + pull
		lastPull = pull
	else
		lastPull = Vector3.zero
	end
end

local function reverseControls()
	if not upsideDown or not State.isAlive() then
		return
	end
	local c = getControls()
	if c then
		local mv = c:GetMoveVector()
		if mv.Magnitude > 0 then
			player:Move(-mv, true)
		end
	end
end

---------------------------------------------------------------- taunts

local function onTaunt(t: any)
	if type(t) ~= "table" then
		return
	end
	local chef = Players:GetPlayerByUserId(t.userId or 0)
	local info
	for _, x in ipairs(Catalog.Taunts) do
		if x.id == t.taunt then
			info = x
		end
	end
	if not chef or not info then
		return
	end
	local head = chef.Character and chef.Character:FindFirstChild("Head")
	if head then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(160, 70)
		bb.StudsOffset = Vector3.new(0, 6, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 150
		bb.Parent = head
		UI.label(bb, { Text = info.emoji .. " " .. info.name, Title = true, Color = UI.C.Mustard, Stroke = 3 })
		UI.pop(bb:FindFirstChildOfClass("TextLabel") :: any)
		Debris:AddItem(bb, 2.5)
	end
	if chef == player then
		local _, hum = myParts()
		if hum then
			pcall(function()
				hum:PlayEmote(info.emote)
			end)
		end
	end
end

---------------------------------------------------------------- confetti (winner)

function Effects.confetti(gui: ScreenGui)
	local colors = { UI.C.Tomato, UI.C.Mustard, UI.C.Grape, UI.C.Basil, UI.C.White }
	for i = 1, 70 do
		local c = UI.new("Frame", {
			Size = UDim2.fromOffset(math.random(8, 16), math.random(10, 20)),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			BackgroundColor3 = colors[math.random(1, #colors)],
			BorderSizePixel = 0,
			Rotation = math.random(0, 360),
			ZIndex = 90,
			Parent = gui,
		})
		local dur = math.random(25, 45) / 10
		local tw = UI.tween(c, dur, { Position = UDim2.new(c.Position.X.Scale + (math.random() - 0.5) * 0.3, 0, 1.1, 0), Rotation = c.Rotation + math.random(-400, 400) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw.Completed:Connect(function()
			c:Destroy()
		end)
	end
end

function Effects.init(gui: ScreenGui)
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "ClientFX"
	fxFolder.Parent = workspace
	overlay = UI.new("Frame", { Name = "EffectOverlay", Size = UDim2.new(0.5, 0, 0, 44), Position = UDim2.new(0.5, 0, 0.62, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Grape, BackgroundTransparency = 0.15, Visible = false, ZIndex = 25, Parent = gui })
	UI.corner(overlay, 12)
	UI.stroke(overlay, 3)
	overlayLabel = UI.label(overlay, { Text = "", Title = true, Color = UI.C.White, Stroke = 2, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), ZIndex = 26 })

	Net.event("FX").OnClientEvent:Connect(function(kind, params)
		local h = handlers[kind]
		if h and type(params) == "table" then
			local ok, err = pcall(h, params)
			if not ok then
				warn("[FX]", kind, err)
			end
		end
	end)
	Net.event("Knockback").OnClientEvent:Connect(onKnockback)
	Net.event("Rumble").OnClientEvent:Connect(function(intensity, duration)
		Effects.shake(tonumber(intensity) or 0.5, tonumber(duration) or 0.5)
	end)
	Net.event("ClientEffect").OnClientEvent:Connect(onClientEffect)
	Net.event("Taunt").OnClientEvent:Connect(onTaunt)
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if not State.isAlive() then
			upsideDown = false
			setOverlay(nil)
		end
	end)

	RunService.Heartbeat:Connect(step)
	RunService:BindToRenderStep("RFD_ReverseControls", Enum.RenderPriority.Input.Value + 1, reverseControls)
	RunService:BindToRenderStep("RFD_Shake", Enum.RenderPriority.Camera.Value + 1, function()
		local now = os.clock()
		if now < shakeUntil then
			local a = shakeAmp * ((shakeUntil - now) / 0.5) * 0.04
			camera.CFrame = camera.CFrame * CFrame.Angles((math.random() - 0.5) * a, (math.random() - 0.5) * a, (math.random() - 0.5) * a)
		else
			shakeAmp = 0
		end
		if upsideDown then
			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(8))
		end
	end)
end

return Effects
