-- Zombie Conga: Zombies + Bouncy + Slow. Zombies form a conga line that snakes around the map.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "ZombieConga",
	name = "Zombie Conga",
	emoji = "💃",
	main = "Zombies",
	spices = { "Bouncy", "Slow" },
	type = "Creature",
	desc = "The zombies form a conga line that snakes around the map.",
	hint = { text = "Jump over the line or get on high ground!", icon = "raised" },
	stats = { Size = 1, Speed = 12, Count = 14, Damage = 18, Health = 1 },
}

function Recipe.Spawn(ctx)
	local start = ctx:randomOpenPoint()
	local line = {}
	local history = {}
	for i = 1, ctx.stats.Count do
		local m = Models.Zombies(1)
		local z = Mover.new(ctx, m, { mode = "ground", radius = 1.5, speed = ctx.stats.Speed, position = start + Vector3.new(0, 2, i * 3), accel = 400, turnRate = 400 })
		table.insert(line, z)
	end
	ctx:fx("Music", { style = "conga", on = true })
	ctx:onCleanup(function()
		ctx:fx("Music", { style = "conga", on = false })
	end)
	local spacing = 4 -- history samples between dancers
	ctx:loop(0.1, function(dt)
		local leader = line[1]
		if not leader or not leader.alive or not leader.root.Parent then
			return
		end
		local t = ctx:nearestTarget(leader.root.Position, nil, true)
		local desired = t and (t.root.Position - leader.root.Position) or leader.dir
		local wiggle = Vector3.new(-desired.Z, 0, desired.X)
		if wiggle.Magnitude > 0.01 then
			desired = desired.Unit + wiggle.Unit * math.sin(os.clock() * 2) * 0.7
		end
		if not ctx:inBounds(leader.root.Position, 10) then
			local c = ctx.map and ctx.map.center or Vector3.zero
			desired = c - leader.root.Position
		end
		leader:drive(desired, dt, ctx.rampMult)
		table.insert(history, 1, leader.root.Position)
		if #history > #line * spacing + 5 then
			table.remove(history)
		end
		for i = 2, #line do
			local z = line[i]
			if z.alive and z.root.Parent then
				local goal = history[math.min(#history, (i - 1) * spacing)]
				if goal then
					local d = goal - z.root.Position
					z:drive(d, dt, d.Magnitude > 2 and ctx.rampMult * 1.25 or 0.3)
				end
			end
		end
		for _, z in ipairs(line) do
			if z.alive and z.root.Parent then
				for _, target in ipairs(ctx:targets()) do
					local d = target.root.Position - z.root.Position
					if Vector3.new(d.X, 0, d.Z).Magnitude < 3.6 and math.abs(d.Y) < 4.2 and z:canHit(target.player, 1) then
						ctx:damage(target, ctx.stats.Damage)
						local dir = Vector3.new(d.X, 0, d.Z)
						dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.xAxis
						ctx:knockback(target, dir * 45 + Vector3.new(0, 60, 0))
					end
				end
			end
		end
	end)
end

return Recipe
