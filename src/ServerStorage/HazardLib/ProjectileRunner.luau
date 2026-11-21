-- Projectile type: things that fall from the sky (fall), roll along the ground (roll) or
-- drive straight across the map (drive). Spices hook into spawn / tick / hit / impact / aim.

local ServerStorage = game:GetService("ServerStorage")
local HazardLib = ServerStorage:WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local ProjectileRunner = {}

local CAR_COLORS = {
	Color3.fromRGB(232, 74, 58),
	Color3.fromRGB(255, 201, 60),
	Color3.fromRGB(76, 175, 80),
	Color3.fromRGB(80, 140, 230),
	Color3.fromRGB(123, 79, 214),
	Color3.fromRGB(250, 250, 250),
}

---------------------------------------------------------------- falling (Meteors)

-- Damage at an impact point. Used by meteors and anything else that lands.
function ProjectileRunner.impact(ctx: any, pos: Vector3, radius: number, damage: number)
	local consumed = ctx:hook("impact", pos, radius)
	if consumed then
		return
	end
	for _, t in ipairs(ctx:targets()) do
		local d = t.root.Position - pos
		local m = d.Magnitude
		if m <= radius + 1.5 then
			local falloff = 1 - math.clamp(m / (radius + 1.5), 0, 1) * 0.4
			ctx:damage(t, damage * falloff)
			local dir = Vector3.new(d.X, 0, d.Z)
			dir = dir.Magnitude > 1e-3 and dir.Unit or Vector3.xAxis
			ctx:knockback(t, dir * 35 + Vector3.new(0, 30, 0))
		end
	end
	ctx:fx("Impact", { pos = pos, radius = radius, flaming = ctx:hasHook("Flaming") ~= nil, frozen = ctx:hasHook("Frozen") ~= nil })
end

function ProjectileRunner.dropOne(ctx: any, main: any, at: Vector3?)
	local cfg = main.projectile
	local stats = ctx.stats
	local radius = (cfg.radius or 6) * stats.Size
	local spread = cfg.spread or 10
	local point = at or ctx:aimPoint(spread)
	point = ctx:hookValue("aim", point)
	local g = workspace.Gravity / 196.2
	local fallSpeed = stats.Speed * ctx.rampMult * math.clamp(g ^ 0.6, 0.3, 1.5)
	local height = cfg.height or 90
	local duration = math.clamp(height / fallSpeed, 0.6, 6)
	ctx:fx("Meteor", {
		to = point,
		height = height,
		duration = duration,
		size = stats.Size,
		radius = radius,
		flaming = ctx:hasHook("Flaming") ~= nil,
		frozen = ctx:hasHook("Frozen") ~= nil,
		invisible = ctx:hasHook("Invisible"),
		style = cfg.style or "meteor",
		label = cfg.style == "thing" and ctx.dish.label or nil,
		palette = ctx.dish.palette,
	})
	ctx:delay(duration, function()
		ProjectileRunner.impact(ctx, point, radius, stats.Damage)
	end)
end

function ProjectileRunner.runFall(ctx: any, main: any)
	local cfg = main.projectile
	-- Count = objects per volley; volleys keep coming.
	ctx:loop(cfg.volleyEvery or 4, function()
		local n = math.max(1, math.floor(ctx.stats.Count * (ctx.rampMult > 1 and 1.3 or 1) + 0.5))
		for i = 1, n do
			ctx:delay(ctx.rng:NextNumber(0, (cfg.volleyEvery or 4) * 0.9), function()
				ProjectileRunner.dropOne(ctx, main)
			end)
		end
	end)
end

---------------------------------------------------------------- rolling & driving

local function spawnRoller(ctx: any, main: any)
	local cfg = main.projectile
	local stats = ctx.stats
	local scale = stats.Size
	local edge, dir = ctx:edgeEntry()
	local ground = ctx:groundAt(edge.X, edge.Z) or (ctx.map and ctx.map.floorY or 0)
	local model
	if cfg.kind == "drive" then
		model = Models.Cars(scale, CAR_COLORS[ctx.rng:NextInteger(1, #CAR_COLORS)])
	else
		model = (main.build or Models[main.id])(scale, ctx)
	end
	local radius = (cfg.radius or 3) * scale
	local obj = Mover.new(ctx, model, {
		mode = "ground",
		radius = radius,
		speed = stats.Speed,
		hp = stats.Health,
		position = Vector3.new(edge.X, ground + radius + 1, edge.Z),
		dir = dir,
		accel = cfg.accel or 120,
		turnRate = 5,
	})
	if cfg.kind == "roll" then
		-- rollers spin freely; no orientation lock
		obj.ao.Enabled = false
		obj.root.CustomPhysicalProperties = PhysicalProperties.new(3, 0.8, 0.1, 1, 1)
	else
		obj.ao.CFrame = CFrame.lookAt(Vector3.zero, dir)
		model:PivotTo(CFrame.lookAt(model:GetPivot().Position, model:GetPivot().Position + dir))
	end
	obj.damage = stats.Damage
	obj.cooldown = 1.2
	obj.knock = cfg.knock or 60
	obj.main = main
	obj.bornAt = os.clock()
	obj.slowSince = nil
	obj.data.fixedDir = dir
	ctx:hook("spawn", obj)
	ctx:decorate(obj, main.sound or (cfg.kind == "drive" and "Engine" or "Roll"))
	return obj
end

local function stepRoller(ctx: any, obj: any, dt: number)
	local cfg = obj.main.projectile
	local dir = obj.data.fixedDir
	if ctx:hasHook("Magnetic") then
		-- magnetic projectiles curve toward the nearest player
		local t = ctx:nearestTarget(obj.root.Position, 60, true)
		if t then
			local want = Vector3.new(t.root.Position.X - obj.root.Position.X, 0, t.root.Position.Z - obj.root.Position.Z)
			if want.Magnitude > 1 then
				dir = Mover.turnToward(dir, want.Unit, math.rad(25 * ctx:hasHook("Magnetic")) * dt)
				obj.data.fixedDir = dir
			end
		end
	end
	obj.dir = dir
	local speed = obj.speed * ctx.rampMult
	obj.lv.PlaneVelocity = Vector2.new(dir.X * speed, dir.Z * speed)
	if cfg.kind == "drive" then
		obj.ao.CFrame = CFrame.lookAt(Vector3.zero, dir)
	end
	ctx:hook("tick", obj, dt)
end

local function rollerContacts(ctx: any, obj: any)
	local pos = obj.root.Position
	local vel = obj.root.AssemblyLinearVelocity
	local moving = Vector3.new(vel.X, 0, vel.Z).Magnitude > 4
	if not moving then
		return
	end
	local reach = obj.radius + (obj.main.projectile.kind == "drive" and 2.6 or 1.8)
	for _, t in ipairs(ctx:targets()) do
		local d = t.root.Position - pos
		if Vector3.new(d.X, 0, d.Z).Magnitude <= reach and math.abs(d.Y) <= obj.radius + 3 then
			if obj:canHit(t.player, obj.cooldown) then
				local consumed = ctx:hook("hit", obj, t)
				if not consumed then
					ctx:damage(t, obj.damage)
					local dir = obj.data.fixedDir
					ctx:knockback(t, dir * obj.knock + Vector3.new(0, obj.knock * 0.6, 0))
				end
				if not obj.alive then
					return
				end
			end
		end
	end
end

function ProjectileRunner.runRolling(ctx: any, main: any)
	local cfg = main.projectile
	local want = math.max(1, math.floor(ctx.stats.Count + 0.5))
	local pending = 0
	local killY = (ctx.map and ctx.map.killY) or -60
	local function spawnStaggered(n: number)
		for i = 1, n do
			pending += 1
			ctx:delay((i - 1) * ctx.rng:NextNumber(0.6, 1.4), function()
				pending -= 1
				if cfg.kind == "drive" then
					ctx:fx("Honk", {})
				end
				local ok, err = pcall(spawnRoller, ctx, main)
				if not ok then
					warn("[ProjectileRunner] spawn failed", err)
				end
			end)
		end
	end
	spawnStaggered(want)
	ctx:loop(0.1, function(dt)
		local now = os.clock()
		for _, obj in ipairs(table.clone(ctx.objects)) do
			if obj.alive then
				local pos = obj.root.Parent and obj.root.Position
				local dead = not pos or pos.Y < killY or obj.hp <= 0
				if not dead then
					-- leave the arena, live too long, or get stuck behind cover -> despawn
					local flatSpeed = Vector3.new(obj.root.AssemblyLinearVelocity.X, 0, obj.root.AssemblyLinearVelocity.Z).Magnitude
					if flatSpeed < 3 then
						obj.slowSince = obj.slowSince or now
					else
						obj.slowSince = nil
					end
					if (obj.slowSince and now - obj.slowSince > 2.5) or now - obj.bornAt > 16 then
						dead = true
					elseif not ctx:inBounds(pos, -4) and now - obj.bornAt > 1.5 then
						local bounced = ctx:hook("edge", obj)
						if not bounced then
							dead = true
						end
					end
				end
				if dead then
					if obj.root.Parent and cfg.splat then
						cfg.splat(ctx, obj)
					end
					obj:destroy(ctx)
				else
					stepRoller(ctx, obj, dt)
					if obj.alive then
						rollerContacts(ctx, obj)
					end
				end
			end
		end
		local target = math.floor(want * (ctx.rampMult > 1 and 1.3 or 1) + 0.5)
		local live = ctx:liveCount()
		if live + pending < target then
			spawnStaggered(target - live - pending)
		end
	end)
end

function ProjectileRunner.run(ctx: any, main: any)
	local kind = main.projectile.kind
	if kind == "fall" then
		ProjectileRunner.runFall(ctx, main)
	else
		ProjectileRunner.runRolling(ctx, main)
	end
end

return ProjectileRunner
