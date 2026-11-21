-- UFO (Creature): hovers over you with a tractor beam that pulls you in and lifts you up,
-- and zaps lasers at anyone nearby.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)
local Robots = require(script.Parent.Robots)

local UFO = {
	id = "UFO",
	type = "Creature",
	danger = 4,
	sound = "UfoHum",
	stats = { Size = 1, Speed = 12, Count = 2, Damage = 14, Health = 999 },
	hint = { text = "Don't stand under the beam - run against the pull!", icon = "run" },
	creature = { mode = "fly", radius = 4, hover = 15, turnRate = 160, cooldown = 1.2, knock = 20, respawnDelay = 3, poofColor = Color3.fromRGB(150, 255, 150) },
}

function UFO.onSpawn(ctx, obj)
	ctx:addPull(obj.root, 16 * math.sqrt(ctx.stats.Size), 9)
end

function UFO.step(ctx, obj, dt)
	local now = os.clock()
	local pos = obj.root.Position
	if now >= obj.retargetAt or not obj.target or not obj.target.root.Parent then
		obj.target = ctx:randomTarget()
		obj.retargetAt = now + ctx.rng:NextNumber(4, 7)
	end
	local t = obj.target
	local goal = t and t.root.Position or (ctx.map and ctx.map.center or Vector3.zero)
	local desired = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
	local ground = ctx:groundAt(pos.X, pos.Z) or 0
	obj:drive(desired.Magnitude > 2 and desired or obj.dir, dt, ctx.rampMult, ground + obj.hover)
	-- abduction: stay under the beam too long and up you go
	for _, target in ipairs(ctx:targets()) do
		local d = target.root.Position - pos
		if Vector3.new(d.X, 0, d.Z).Magnitude < 5 * math.sqrt(ctx.stats.Size) and d.Y < 0 then
			obj.data.under = obj.data.under or {}
			obj.data.under[target.player] = (obj.data.under[target.player] or 0) + dt
			if obj.data.under[target.player] > 1.2 then
				obj.data.under[target.player] = 0
				ctx:sound("Zap", target.root.Position, 0.7, 0.7)
				ctx:knockback(target, Vector3.new(ctx.rng:NextNumber(-20, 20), 70, ctx.rng:NextNumber(-20, 20)))
				ctx:damage(target, obj.damage)
			end
		elseif obj.data.under then
			obj.data.under[target.player] = nil
		end
	end
	if t and now >= (obj.data.nextShot or 2) then
		obj.data.nextShot = now + ctx.rng:NextNumber(1.8, 2.6) / ctx.rampMult
		local near = ctx:nearestTarget(pos, 60)
		if near then
			Robots.fireBolt(ctx, pos - Vector3.new(0, 2, 0), near.root.Position, obj.damage, { speed = 90, color = Color3.fromRGB(120, 255, 120), width = 0.7 })
		end
	end
	return true
end

function UFO.Spawn(ctx)
	CreatureRunner.run(ctx, UFO)
end

return UFO
