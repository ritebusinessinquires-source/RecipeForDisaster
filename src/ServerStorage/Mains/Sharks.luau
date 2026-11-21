-- Sharks (Creature): swim in the water and lunge at anyone near the shoreline.
-- With Rising Water they can reach everyone below the waterline.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Sharks = {
	id = "Sharks",
	type = "Creature",
	danger = 3,
	stats = { Size = 1, Speed = 16, Count = 4, Damage = 35, Health = 80 },
	hint = { text = "Stay away from the shoreline!", icon = "away" },
	creature = { mode = "fly", radius = 1.6, hover = 0, turnRate = 160, cooldown = 1.4, knock = 30, respawnDelay = 3 },
}

-- The area sharks can swim in: the map's water, or everything under Rising Water.
local function swimRegion(ctx)
	local m = ctx.map
	if m and m.risingWaterLevel and m.risingWaterLevel > m.floorY + 1 then
		return m.center, Vector3.new((m.bounds.maxX - m.bounds.minX), 0, (m.bounds.maxZ - m.bounds.minZ)), m.risingWaterLevel
	end
	if m and m.water then
		return m.water.center, m.water.size, m.water.surfaceY
	end
	-- no water: land sharks, fins cutting through the floor
	local c = m and m.center or Vector3.zero
	return c, Vector3.new(200, 0, 200), (m and m.floorY or 0) + 0.6
end

local function clampInto(p, center, size, margin)
	return Vector3.new(
		math.clamp(p.X, center.X - size.X / 2 + margin, center.X + size.X / 2 - margin),
		p.Y,
		math.clamp(p.Z, center.Z - size.Z / 2 + margin, center.Z + size.Z / 2 - margin)
	)
end

Sharks.creature.spawnAt = function(ctx)
	local center, size, surface = swimRegion(ctx)
	local p = Vector3.new(
		center.X + ctx.rng:NextNumber(-size.X / 2 + 3, size.X / 2 - 3),
		surface,
		center.Z + ctx.rng:NextNumber(-size.Z / 2 + 3, size.Z / 2 - 3)
	)
	return p - Vector3.new(0, 1.2, 0)
end

function Sharks.step(ctx, obj, dt)
	local now = os.clock()
	local center, size, surface = swimRegion(ctx)
	local pos = obj.root.Position
	local s = ctx.stats.Size
	local swimY = surface - 1.0 * s
	local margin = obj.radius
	-- lunging?
	if obj.data.lungeUntil and now < obj.data.lungeUntil then
		local t = obj.data.lungeTarget
		if t and t.root.Parent then
			local d = t.root.Position - pos
			obj:drive(d, dt, 3.2 * ctx.rampMult, t.root.Position.Y + 0.5)
		end
		return true
	end
	if now >= obj.retargetAt or not obj.target or not obj.target.root.Parent then
		obj.target = ctx:nearestTarget(pos, nil, true)
		obj.retargetAt = now + 1
	end
	local goal = center
	local t = obj.target
	if t then
		goal = clampInto(t.root.Position, center, size, margin)
		local flat = Vector3.new(t.root.Position.X - pos.X, 0, t.root.Position.Z - pos.Z).Magnitude
		local nearShore = ctx:inWater(Vector3.new(t.root.Position.X, swimY, t.root.Position.Z), 7)
		if flat < 11 * math.max(1, s * 0.7) and nearShore and now >= (obj.data.nextLunge or 0) then
			obj.data.lungeUntil = now + 0.55
			obj.data.nextLunge = now + 2.2
			obj.data.lungeTarget = t
			ctx:fx("Splash", { pos = Vector3.new(pos.X, surface, pos.Z), size = s })
			return true
		end
	end
	local desired = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
	-- stay in the water: if the next spot is dry, turn back toward the middle of the water
	local ahead = pos + obj.dir * (obj.radius + 2)
	if not ctx:inWater(Vector3.new(ahead.X, swimY, ahead.Z), -1) and swimY > (ctx.map and ctx.map.floorY or 0) + 0.8 then
		desired = Vector3.new(center.X - pos.X, 0, center.Z - pos.Z)
	end
	if desired.Magnitude < 1.5 then
		desired = obj.dir
	end
	obj:drive(desired, dt, ctx.rampMult * obj.speedMult, swimY)
	return true
end

function Sharks.Spawn(ctx)
	CreatureRunner.run(ctx, Sharks)
end

return Sharks
