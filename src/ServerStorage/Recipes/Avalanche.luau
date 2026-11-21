-- Avalanche: Boulders + Frozen + Giant. One huge snowball rolls across the map, growing as it goes.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "Avalanche",
	name = "Avalanche",
	emoji = "🏔️",
	main = "Boulders",
	spices = { "Frozen", "Giant" },
	type = "Projectile",
	desc = "One huge snowball rolls across the map, growing as it goes.",
	hint = { text = "Get behind cover and dodge sideways!", icon = "cover" },
	stats = { Size = 1, Speed = 20, Count = 1, Damage = 45, Health = 1 },
}

local function spawnBall(ctx)
	local edge, dir = ctx:edgeEntry()
	local m = Models.Blob(4, Color3.fromRGB(245, 250, 255), Enum.Material.Snow)
	local root = m.PrimaryPart :: BasePart
	root.CustomPhysicalProperties = PhysicalProperties.new(2, 0.7, 0.1, 1, 1)
	local ground = ctx:groundAt(edge.X, edge.Z) or 0
	local obj = Mover.new(ctx, m, { mode = "ground", radius = 4, speed = ctx.stats.Speed, position = Vector3.new(edge.X, ground + 5, edge.Z), dir = dir, accel = 80 })
	obj.ao.Enabled = false
	obj.data.fixedDir = dir
	obj.data.r = 4
	obj.data.born = os.clock()
	return obj
end

function Recipe.Spawn(ctx)
	local obj = spawnBall(ctx)
	ctx:loop(0.1, function(dt)
		if not obj.alive or not obj.root.Parent or obj.root.Position.Y < (ctx.map and ctx.map.killY or -60) then
			obj = spawnBall(ctx)
			return
		end
		local pos = obj.root.Position
		-- grow
		local r = math.min(16, obj.data.r + dt * 0.55 * ctx.rampMult)
		if r - obj.root.Size.X / 2 > 0.4 then
			obj.root.Size = Vector3.one * r * 2
			obj.radius = r
		end
		obj.data.r = r
		-- steer gently toward players, bounce off the edges
		local t = ctx:nearestTarget(pos, nil, true)
		if t then
			local want = Vector3.new(t.root.Position.X - pos.X, 0, t.root.Position.Z - pos.Z)
			if want.Magnitude > 1 then
				obj.data.fixedDir = Mover.turnToward(obj.data.fixedDir, want.Unit, math.rad(18) * dt)
			end
		end
		if not ctx:inBounds(pos, r) then
			local c = ctx.map and ctx.map.center or Vector3.zero
			obj.data.fixedDir = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z).Unit
		end
		local v = obj.data.fixedDir * ctx.stats.Speed * ctx.rampMult
		obj.lv.PlaneVelocity = Vector2.new(v.X, v.Z)
		ctx:iceAt(pos, r + 3, 6)
		for _, target in ipairs(ctx:targets()) do
			local d = target.root.Position - pos
			if d.Magnitude <= r + 2.5 and obj:canHit(target.player, 1.2) then
				ctx:damage(target, ctx.stats.Damage)
				ctx:freeze(target, 1)
				local dir = Vector3.new(d.X, 0, d.Z)
				dir = dir.Magnitude > 0.1 and dir.Unit or obj.data.fixedDir
				ctx:knockback(target, dir * 60 + Vector3.new(0, 50, 0))
			end
		end
		-- when it gets huge it shatters and a new one starts
		if r >= 16 or os.clock() - obj.data.born > 30 then
			ctx:explode(pos, r + 6, 20, { knock = 60, color = Color3.fromRGB(230, 245, 255) })
			obj:destroy(ctx)
		end
	end)
end

return Recipe
