-- The context a running dish gets: targets, damage helpers, map queries, spice hooks, cleanup.
-- One Context per dish (and one per Twist). Everything spawned lives in ctx.folder.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)
local Status = require(ServerScriptService:WaitForChild("Services"):WaitForChild("Status"))

local spiceFolder = ServerStorage:WaitForChild("Spices")
local SpiceModules: { [string]: any } = {}
for _, m in ipairs(spiceFolder:GetChildren()) do
	if m:IsA("ModuleScript") then
		SpiceModules[m.Name] = require(m) :: any
	end
end

local Context = {}
Context.__index = Context
Context.Spices = SpiceModules

export type Target = { player: any, character: Model, root: BasePart, humanoid: Humanoid }

local function hazardsFolder(): Folder
	local f = workspace:FindFirstChild("Hazards") :: Folder?
	if not f then
		local nf = Instance.new("Folder")
		nf.Name = "Hazards"
		nf.Parent = workspace
		f = nf
	end
	return f :: Folder
end
Context.hazardsFolder = hazardsFolder

-- env = { map = MapInfo, getTargets = () -> {Target}, onObjectsChanged = fn? }
function Context.new(dish: any, env: any)
	local self = setmetatable({}, Context)
	self.dish = dish
	self.env = env
	self.map = env.map
	self.tiles = env.map and env.map.tiles
	self.stats = table.clone(dish.stats or {})
	self.rng = Random.new(dish.seed or os.clock() * 1000)
	self.rampMult = 1
	self.alive = true
	self.objects = {}
	self.cleanups = {}
	self.startedAt = os.clock()
	local folder = Instance.new("Folder")
	folder.Name = "Dish_" .. tostring(dish.id)
	folder:SetAttribute("DishId", dish.id)
	folder.Parent = hazardsFolder()
	self.folder = folder
	return self
end

---------------------------------------------------------------- targets

function Context:targets(): { Target }
	return self.env.getTargets()
end

function Context:nearestTarget(pos: Vector3, maxDist: number?, flat: boolean?): (Target?, number)
	local best, bestD = nil, maxDist or math.huge
	for _, t in ipairs(self:targets()) do
		local d = t.root.Position - pos
		if flat then
			d = Vector3.new(d.X, 0, d.Z)
		end
		local m = d.Magnitude
		if m < bestD then
			best, bestD = t, m
		end
	end
	return best, bestD
end

function Context:randomTarget(): Target?
	local list = self:targets()
	if #list == 0 then
		return nil
	end
	return list[self.rng:NextInteger(1, #list)]
end

---------------------------------------------------------------- effects on players

function Context:creditId(): string
	return self.dish.creditId or self.dish.id
end

function Context:damageMult(): number
	return (self.dish.damageMult or 1) * self.rampMult
end

function Context:damage(target: Target, amount: number)
	Status.damage(target.player, amount * self:damageMult(), self:creditId())
end

function Context:knockback(target: Target, velocity: Vector3)
	Status.recordHit(target.player, self:creditId())
	Status.knockback(target.player, velocity)
end

function Context:freeze(target: Target, seconds: number)
	if not Status.isFrozen(target.player) then
		self:sound("Crack", target.root.Position, 0.6)
	end
	Status.freeze(target.player, seconds, self:creditId())
end

function Context:burn(target: Target, seconds: number, dps: number)
	Status.burn(target.player, seconds, dps * self:damageMult(), self:creditId())
end

function Context:poison(target: Target, seconds: number, dps: number)
	Status.poison(target.player, seconds, dps * self:damageMult(), self:creditId())
	self:sound("Hiss", target.root.Position, 0.5)
end

function Context:stun(target: Target, seconds: number)
	Status.stun(target.player, seconds, self:creditId())
	self:sound("Zap", target.root.Position, 0.6)
end

-- One-shot positional sound, played on every client.
function Context:sound(name: string, pos: Vector3, volume: number?, pitch: number?)
	Net.fireAll("FX", "Sound", { name = name, pos = pos, volume = volume, pitch = pitch })
end

function Context:slow(target: Target, factor: number, seconds: number, key: string?)
	Status.slow(target.player, key or ("dish" .. tostring(self.dish.id)), factor, seconds)
end

-- Explosion: visual + damage + knockback to players, damage to hazard objects.
function Context:explode(pos: Vector3, radius: number, damage: number, opts: any?)
	opts = opts or {}
	local e = Instance.new("Explosion")
	e.Position = pos
	e.BlastRadius = radius
	e.BlastPressure = 0
	e.DestroyJointRadiusPercent = 0
	e.ExplosionType = Enum.ExplosionType.NoCraters
	e.Visible = opts.visible ~= false
	e.Parent = self.folder
	self:sound(opts.sound or "Boom", pos, math.clamp(radius / 10, 0.4, 1), opts.pitch)
	Debris:AddItem(e, 3)
	for _, t in ipairs(self:targets()) do
		local d = (t.root.Position - pos)
		local m = d.Magnitude
		if m <= radius then
			local falloff = 1 - (m / radius) * 0.5
			self:damage(t, damage * falloff)
			local dir = (Vector3.new(d.X, 0, d.Z).Unit)
			if dir ~= dir then
				dir = Vector3.new(1, 0, 0)
			end
			local power = (opts.knock or 55) * falloff
			self:knockback(t, dir * power + Vector3.new(0, power * 0.7, 0))
		end
	end
	if opts.damageObjects ~= false then
		for _, obj in ipairs(self.objects) do
			if obj.alive and obj.root and obj.root.Parent then
				if (obj.root.Position - pos).Magnitude <= radius + (obj.radius or 0) then
					obj.hp = (obj.hp or 1) - damage
				end
			end
		end
	end
	self:fx("Shockwave", { pos = pos, radius = radius, color = opts.color })
end

function Context:fx(kind: string, params: any)
	Net.fireAll("FX", kind, params)
end

function Context:rumble(intensity: number, duration: number)
	Net.fireAll("Rumble", intensity, duration)
end

---------------------------------------------------------------- map queries

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

function Context:groundAt(x: number, z: number, fromY: number?): (number?, BasePart?)
	local map = self.map
	if not map or not map.model then
		return 0, nil
	end
	rayParams.FilterDescendantsInstances = { map.model }
	local origin = Vector3.new(x, (fromY or (map.floorY + 120)), z)
	local hit = workspace:Raycast(origin, Vector3.new(0, -400, 0), rayParams)
	if hit then
		return hit.Position.Y, hit.Instance :: BasePart
	end
	return nil, nil
end

function Context:inBounds(pos: Vector3, margin: number?): boolean
	local m = self.map
	if not m then
		return true
	end
	margin = margin or 0
	if m.shape == "circle" then
		local dx, dz = pos.X - m.center.X, pos.Z - m.center.Z
		return dx * dx + dz * dz <= (m.radius - margin) ^ 2
	end
	return pos.X >= m.bounds.minX + margin and pos.X <= m.bounds.maxX - margin and pos.Z >= m.bounds.minZ + margin and pos.Z <= m.bounds.maxZ - margin
end

function Context:waterLevel(): number?
	local m = self.map
	if not m then
		return nil
	end
	local base = m.water and m.water.surfaceY or nil
	local rising = m.risingWaterLevel
	if rising and (not base or rising > base) then
		return rising
	end
	return base
end

-- Is a position inside the water (the map's pond/basin, or anywhere under Rising Water)?
function Context:inWater(pos: Vector3, margin: number?): boolean
	local m = self.map
	if not m then
		return false
	end
	margin = margin or 0
	if m.risingWaterLevel and pos.Y < m.risingWaterLevel + margin then
		return true
	end
	local w = m.water
	if not w then
		return false
	end
	local rel = pos - w.center
	return math.abs(rel.X) <= w.size.X / 2 + margin and math.abs(rel.Z) <= w.size.Z / 2 + margin and pos.Y < w.surfaceY + 1 + margin
end

function Context:randomOpenPoint(opts: any?): Vector3
	opts = opts or {}
	local tiles = self.tiles
	if tiles then
		local t = tiles:random(self.rng, opts.filter)
		if t then
			local half = tiles.size / 2
			return Vector3.new(t.center.X + self.rng:NextNumber(-half, half), t.topY, t.center.Z + self.rng:NextNumber(-half, half))
		end
	end
	local m = self.map
	return (m and m.center or Vector3.zero) + Vector3.new(self.rng:NextNumber(-60, 60), 0, self.rng:NextNumber(-60, 60))
end

-- A point near a player (or random), for aimed projectiles
function Context:aimPoint(spread: number): Vector3
	local t = self:randomTarget()
	if t and self.rng:NextNumber() < 0.65 then
		local p = t.root.Position + t.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * 0.6
		local x = p.X + self.rng:NextNumber(-spread, spread)
		local z = p.Z + self.rng:NextNumber(-spread, spread)
		local y = self:groundAt(x, z)
		if y and self:inBounds(Vector3.new(x, 0, z)) then
			return Vector3.new(x, y, z)
		end
	end
	return self:randomOpenPoint()
end

-- Point on the arena edge plus the inward direction (for things that cross the map)
function Context:edgeEntry(): (Vector3, Vector3)
	local m = self.map
	local center = m and m.center or Vector3.zero
	local half = m and (m.shape == "circle" and m.radius or (m.bounds.maxX - m.bounds.minX) / 2) or 100
	local angle = self.rng:NextNumber(0, math.pi * 2)
	local edge = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (half - 6)
	-- aim across the map, through a point near a target or the middle
	local through = center + Vector3.new(self.rng:NextNumber(-40, 40), 0, self.rng:NextNumber(-40, 40))
	local t = self:randomTarget()
	if t and self.rng:NextNumber() < 0.5 then
		through = Vector3.new(t.root.Position.X, 0, t.root.Position.Z)
	end
	local dir = Vector3.new(through.X - edge.X, 0, through.Z - edge.Z)
	if dir.Magnitude < 1 then
		dir = Vector3.new(center.X - edge.X, 0, center.Z - edge.Z)
	end
	return edge, dir.Unit
end

---------------------------------------------------------------- tiles & ice

function Context:iceAt(pos: Vector3, radius: number, seconds: number)
	if self.tiles then
		self.tiles:iceRadius(pos, radius, seconds)
	end
end

-- Tag a part so clients pull their character toward it (tornado, magnets).
function Context:addPull(part: BasePart, radius: number, strength: number)
	part:SetAttribute("PullRadius", radius)
	part:SetAttribute("PullStrength", strength)
	game:GetService("CollectionService"):AddTag(part, "RFD_Pull")
end

---------------------------------------------------------------- spice hooks

-- Calls hook `stage` on every Spice in this dish for this dish's type.
function Context:hook(stage: string, ...)
	local hooks = self.dish.hooks
	if not hooks then
		return
	end
	local consumed = false
	for spiceId, level in pairs(hooks) do
		local mod = SpiceModules[spiceId]
		local typeHooks = mod and mod[self.dish.type]
		local fn = typeHooks and typeHooks[stage]
		if fn then
			local ok, res = pcall(fn, self, level, ...)
			if not ok then
				warn("[Spice hook]", spiceId, stage, res)
			elseif res == true then
				consumed = true
			end
		end
	end
	return consumed
end

-- Passes a value through every Spice's `stage` hook (each may return a replacement).
function Context:hookValue(stage: string, value: any, ...): any
	local hooks = self.dish.hooks
	if not hooks then
		return value
	end
	for spiceId, level in pairs(hooks) do
		local mod = SpiceModules[spiceId]
		local typeHooks = mod and mod[self.dish.type]
		local fn = typeHooks and typeHooks[stage]
		if fn then
			local ok, res = pcall(fn, self, level, value, ...)
			if ok and res ~= nil then
				value = res
			elseif not ok then
				warn("[Spice hook]", spiceId, stage, res)
			end
		end
	end
	return value
end

function Context:hasHook(spiceId: string): number?
	return self.dish.hooks and self.dish.hooks[spiceId]
end

---------------------------------------------------------------- lifecycle

function Context:addObject(obj: any)
	table.insert(self.objects, obj)
end

-- Floating name tag with what the Chef typed (first few objects only, so swarms stay readable).
function Context:decorate(obj: any, loopSound: string?)
	self.decorated = (self.decorated or 0) + 1
	local root = obj.root
	if not root then
		return
	end
	local label = self.dish.label
	if label and label ~= "" and self.decorated <= 6 then
		local bb = Instance.new("BillboardGui")
		bb.Name = "DishLabel"
		bb.Size = UDim2.fromOffset(180, 34)
		bb.StudsOffset = Vector3.new(0, (obj.radius or 2) + 3.5, 0)
		bb.MaxDistance = 140
		bb.LightInfluence = 0
		bb.AlwaysOnTop = false
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = label
		t.TextColor3 = Color3.fromRGB(255, 244, 220)
		t.Parent = bb
		local st = Instance.new("UIStroke")
		st.Thickness = 2.5
		st.Color = Color3.fromRGB(59, 36, 24)
		st.Parent = t
		bb.Parent = root
	end
	local id = loopSound and Config.Sounds[loopSound]
	if id and id ~= "" and self.decorated <= 4 then
		local snd = Instance.new("Sound")
		snd.Name = "HazardLoop"
		snd.SoundId = id
		snd.Looped = true
		snd.Volume = 0.55
		snd.RollOffMode = Enum.RollOffMode.InverseTapered
		snd.RollOffMinDistance = 8
		snd.RollOffMaxDistance = 110
		snd.PlaybackSpeed = math.clamp(1.15 / math.sqrt(math.max(0.3, self.stats.Size or 1)), 0.55, 1.6) * self.rng:NextNumber(0.93, 1.07)
		snd.Parent = root
		snd:Play()
	end
end

function Context:removeObject(obj: any)
	local i = table.find(self.objects, obj)
	if i then
		table.remove(self.objects, i)
	end
end

function Context:liveCount(): number
	local n = 0
	for _, o in ipairs(self.objects) do
		if o.alive then
			n += 1
		end
	end
	return n
end

function Context:onCleanup(fn: () -> ())
	table.insert(self.cleanups, fn)
end

-- Runs fn(dt) every `interval` seconds until the dish stops.
function Context:loop(interval: number, fn: (number) -> ())
	task.spawn(function()
		local last = os.clock()
		while self.alive do
			local now = os.clock()
			local ok, err = pcall(fn, now - last)
			last = now
			if not ok then
				warn("[Hazard loop]", self.dish.name, err)
			end
			task.wait(interval)
		end
	end)
end

function Context:delay(t: number, fn: () -> ())
	task.delay(t, function()
		if self.alive then
			local ok, err = pcall(fn)
			if not ok then
				warn("[Hazard delay]", self.dish.name, err)
			end
		end
	end)
end

function Context:elapsed(): number
	return os.clock() - self.startedAt
end

function Context:stop()
	if not self.alive then
		return
	end
	self.alive = false
	for _, fn in ipairs(self.cleanups) do
		pcall(fn)
	end
	for _, obj in ipairs(self.objects) do
		obj.alive = false
	end
	table.clear(self.objects)
	if self.tiles then
		self.tiles:clearOwner(self.dish.id)
	end
	self.folder:Destroy()
end

Context.Config = Config
Context.Status = Status

return Context
