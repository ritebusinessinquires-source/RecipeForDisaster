-- Creature type: NPCs that chase players. Mains supply a model and a movement profile;
-- Spices hook into spawn / tick / hit.

local ServerStorage = game:GetService("ServerStorage")
local HazardLib = ServerStorage:WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local CreatureRunner = {}

local function spawnPoint(ctx: any, cfg: any): Vector3
	-- spawn away from players so nobody gets hit instantly
	local best, bestScore = nil, -1
	for _ = 1, 8 do
		local p
		if cfg.spawnAt then
			p = cfg.spawnAt(ctx)
		else
			p = ctx:randomOpenPoint()
		end
		local _, d = ctx:nearestTarget(p, 1e6, true)
		if d > bestScore then
			best, bestScore = p, d
		end
		if d > 35 then
			break
		end
	end
	return best or ctx:randomOpenPoint()
end

function CreatureRunner.spawnOne(ctx: any, main: any, pos: Vector3?): any
	local cfg = main.creature
	local stats = ctx.stats
	local scale = stats.Size
	local build = main.build or Models[main.id]
	local model = build(scale, ctx)
	local p = pos or spawnPoint(ctx, cfg)
	local radius = cfg.radius * scale
	local startY = p.Y + radius + 0.5
	if cfg.mode ~= "ground" then
		startY = p.Y + (cfg.hover or 4) + radius
	end
	local obj = Mover.new(ctx, model, {
		mode = cfg.mode,
		radius = radius,
		speed = stats.Speed,
		hover = (cfg.hover or 4) + radius,
		turnRate = (cfg.turnRate or 200) / math.sqrt(math.max(scale, 0.25)),
		hp = stats.Health,
		position = Vector3.new(p.X, startY, p.Z),
		accel = cfg.accel or 250,
	})
	obj.damage = stats.Damage
	obj.cooldown = cfg.cooldown or 1
	obj.knock = cfg.knock or 25
	obj.speedMult = 1
	obj.main = main
	if ctx.dish.confused then
		obj.data.confusedAt = 0
	end
	ctx:hook("spawn", obj)
	if main.onSpawn then
		main.onSpawn(ctx, obj)
	end
	ctx:decorate(obj, main.sound)
	ctx:fx("Poof", { pos = obj.root.Position, color = cfg.poofColor })
	return obj
end

local function separation(ctx: any, obj: any): Vector3
	local push = Vector3.zero
	local pos = obj.root.Position
	for _, other in ipairs(ctx.objects) do
		if other ~= obj and other.alive and other.root and other.root.Parent then
			local d = pos - other.root.Position
			d = Vector3.new(d.X, 0, d.Z)
			local m = d.Magnitude
			local minD = (obj.radius + other.radius) * 1.3
			if m > 1e-3 and m < minD then
				push += d.Unit * (1 - m / minD)
			end
		end
	end
	return push
end

-- Default chase step. Returns the target it went after.
function CreatureRunner.defaultStep(ctx: any, obj: any, dt: number)
	local now = os.clock()
	local cfg = obj.main.creature
	local pos = obj.root.Position
	if now >= obj.retargetAt or not obj.target or not obj.target.root.Parent then
		local list = ctx:targets()
		-- pick nearest most of the time, sometimes a random one so creatures spread out
		if #list > 0 and ctx.rng:NextNumber() < 0.25 then
			obj.target = list[ctx.rng:NextInteger(1, #list)]
		else
			obj.target = ctx:nearestTarget(pos, nil, true)
		end
		obj.retargetAt = now + ctx.rng:NextNumber(1.2, 2.2)
	end
	local target = obj.target
	local desired
	if target then
		desired = target.root.Position - pos
	else
		desired = (obj.data.wander or Vector3.new(ctx.rng:NextNumber(-1, 1), 0, ctx.rng:NextNumber(-1, 1)))
		obj.data.wander = desired
	end
	desired = Vector3.new(desired.X, 0, desired.Z)
	if desired.Magnitude > 1e-3 then
		desired = desired.Unit
	end
	desired += separation(ctx, obj) * 1.2
	if cfg.zigzag then
		local side = Vector3.new(-desired.Z, 0, desired.X)
		desired += side * math.sin(now * cfg.zigzag + (obj.data.phase or 0)) * 0.8
	end
	-- keep inside the arena
	if not ctx:inBounds(pos, 8) then
		local c = ctx.map and ctx.map.center or Vector3.zero
		desired = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z).Unit * 2
	end
	local speedMult = ctx.rampMult * obj.speedMult
	if ctx.dish.confused then
		if now >= (obj.data.confusedAt or 0) then
			obj.data.confusedAt = now + ctx.rng:NextNumber(1.5, 3.5)
			obj.data.confusedMult = ctx.rng:NextNumber() < 0.5 and 1.7 or 0.45
		end
		speedMult *= obj.data.confusedMult or 1
	end
	local targetY = nil
	if obj.mode ~= "ground" then
		local ground = ctx:groundAt(pos.X + obj.dir.X * 4, pos.Z + obj.dir.Z * 4) or (ctx.map and ctx.map.floorY or 0)
		local wantY = ground + obj.hover
		if target and cfg.followHeight then
			wantY = math.max(wantY, target.root.Position.Y + 0.5)
		end
		targetY = wantY
	end
	obj:drive(desired, dt, speedMult, targetY)
	-- periodic hops (chickens, bouncy)
	local hop = (cfg.hop or 0) + (obj.data.extraHop or 0)
	if hop > 0 and obj.mode == "ground" and now >= (obj.data.nextHop or 0) then
		obj.data.nextHop = now + ctx.rng:NextNumber(1.2, 2.6)
		obj.root:ApplyImpulse(Vector3.new(0, obj.root.AssemblyMass * hop, 0))
	end
	return target
end

function CreatureRunner.checkContacts(ctx: any, obj: any)
	local pos = obj.root.Position
	for _, t in ipairs(ctx:targets()) do
		local d = t.root.Position - pos
		local flat = Vector3.new(d.X, 0, d.Z).Magnitude
		local reach = obj.radius + 2.2
		if flat <= reach and math.abs(d.Y) <= obj.radius + 3 then
			if obj:canHit(t.player, obj.cooldown) then
				local consumed = ctx:hook("hit", obj, t)
				if obj.main.onHit then
					consumed = obj.main.onHit(ctx, obj, t) or consumed
				end
				if not consumed then
					ctx:damage(t, obj.damage)
					local dir = Vector3.new(d.X, 0, d.Z)
					dir = dir.Magnitude > 1e-3 and dir.Unit or Vector3.xAxis
					ctx:knockback(t, dir * obj.knock + Vector3.new(0, obj.knock * 0.5, 0))
				end
				if not obj.alive then
					return
				end
			end
		end
	end
end

function CreatureRunner.kill(ctx: any, obj: any, quiet: boolean?)
	if not obj.alive then
		return
	end
	if not quiet and obj.root and obj.root.Parent then
		ctx:fx("Poof", { pos = obj.root.Position })
	end
	obj:destroy(ctx)
end

function CreatureRunner.run(ctx: any, main: any)
	local cfg = main.creature
	local target = math.max(1, math.floor(ctx.stats.Count + 0.5))
	ctx.desiredCount = target
	for i = 1, target do
		local ok, err = pcall(CreatureRunner.spawnOne, ctx, main)
		if not ok then
			warn("[CreatureRunner] spawn failed", main.id, err)
			break
		end
		if i % 8 == 0 then
			task.wait()
		end
	end
	local pending = 0
	local killY = (ctx.map and ctx.map.killY) or -60
	ctx:loop(0.1, function(dt)
		for _, obj in ipairs(table.clone(ctx.objects)) do
			if obj.alive then
				if not obj.root.Parent or obj.root.Position.Y < killY or obj.hp <= 0 then
					CreatureRunner.kill(ctx, obj, not obj.root.Parent)
				else
					local handled = false
					if main.step then
						handled = main.step(ctx, obj, dt) == true
					end
					if not handled then
						CreatureRunner.defaultStep(ctx, obj, dt)
					end
					ctx:hook("tick", obj, dt)
					if obj.alive then
						CreatureRunner.checkContacts(ctx, obj)
					end
				end
			end
		end
		-- keep the count topped up (things explode, fall off Pizza Planet...)
		local want = math.floor(ctx.desiredCount * (ctx.rampMult > 1 and 1.25 or 1) + 0.5)
		local live = ctx:liveCount()
		if live + pending < want then
			pending += 1
			ctx:delay(cfg.respawnDelay or 2.5, function()
				pending -= 1
				if ctx:liveCount() < want then
					CreatureRunner.spawnOne(ctx, main)
				end
			end)
		end
	end)
end

return CreatureRunner
