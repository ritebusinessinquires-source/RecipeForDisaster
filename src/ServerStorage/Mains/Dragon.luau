-- Dragon (Creature): circles overhead and breathes a line of fire along the ground.
local ServerStorage = game:GetService("ServerStorage")
local HazardLib = ServerStorage:WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Dragon = {
	id = "Dragon",
	type = "Creature",
	danger = 4,
	stats = { Size = 1, Speed = 16, Count = 1, Damage = 20, Health = 999 },
	hint = { text = "Get out of the fire line - watch where it's looking!", icon = "run" },
	creature = { mode = "fly", radius = 3, hover = 16, turnRate = 90, cooldown = 1.5, knock = 40, respawnDelay = 4, poofColor = Color3.fromRGB(255, 120, 60) },
}

function Dragon.breathe(ctx, from: Vector3, toward: Vector3, damage: number)
	local Flaming = require(ServerStorage.Spices.Flaming)
	local flat = Vector3.new(toward.X - from.X, 0, toward.Z - from.Z)
	if flat.Magnitude < 1 then
		return
	end
	local dir = flat.Unit
	ctx:sound("Roar", from, 1)
	ctx:sound("FireBreath", from, 0.9)
	for i = 0, 5 do
		ctx:delay(0.15 * i, function()
			local p = Vector3.new(from.X, 0, from.Z) + dir * (i * 7 + 4)
			local y = ctx:groundAt(p.X, p.Z)
			if y and ctx:inBounds(p) then
				local pos = Vector3.new(p.X, y, p.Z)
				ctx:fx("Arc", { from = from, to = pos, duration = 0.25, style = "lava", height = 2 })
				Flaming.firePatch(ctx, pos, 4.5, 4, 9)
				for _, t in ipairs(ctx:targets()) do
					if (t.root.Position - pos).Magnitude < 5.5 then
						ctx:damage(t, damage * 0.5)
						ctx:burn(t, 2, 6)
					end
				end
			end
		end)
	end
end

function Dragon.step(ctx, obj, dt)
	local now = os.clock()
	local pos = obj.root.Position
	if now >= obj.retargetAt or not obj.target or not obj.target.root.Parent then
		obj.target = ctx:nearestTarget(pos, nil, true) or ctx:randomTarget()
		obj.retargetAt = now + 3
	end
	local t = obj.target
	local center = t and t.root.Position or (ctx.map and ctx.map.center or Vector3.zero)
	-- circle the target
	local a = now * 0.6 + (obj.data.phase or 0)
	local orbit = center + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26)
	local desired = Vector3.new(orbit.X - pos.X, 0, orbit.Z - pos.Z)
	local ground = ctx:groundAt(pos.X, pos.Z) or 0
	obj:drive(desired.Magnitude > 1 and desired or obj.dir, dt, ctx.rampMult, ground + obj.hover)
	if t and now >= (obj.data.nextBreath or 3) then
		obj.data.nextBreath = now + ctx.rng:NextNumber(3.5, 4.5) / ctx.rampMult
		Dragon.breathe(ctx, pos, t.root.Position, obj.damage)
	end
	return true
end

function Dragon.onSpawn(ctx, obj)
	obj.data.phase = ctx.rng:NextNumber(0, 6)
end

function Dragon.Spawn(ctx)
	CreatureRunner.run(ctx, Dragon)
end

return Dragon
