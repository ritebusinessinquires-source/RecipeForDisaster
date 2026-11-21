-- Stampede: Chickens + Fast + Swarm. Waves of chickens charge across the arena. Find the gap!
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "Stampede",
	name = "Stampede",
	emoji = "🐓",
	main = "Chickens",
	spices = { "Fast", "Swarm" },
	type = "Creature",
	desc = "Waves of chickens charge across the arena in a line. Find the gap!",
	hint = { text = "Find the gap in each wave - or climb up high!", icon = "raised" },
	stats = { Size = 1, Speed = 30, Count = 1, Damage = 16, Health = 1 },
}

function Recipe.Spawn(ctx)
	local map = ctx.map
	local center = map and map.center or Vector3.zero
	local half = map and (map.shape == "circle" and map.radius or (map.bounds.maxX - map.bounds.minX) / 2) or 120
	local function wave()
		local dirs = { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }
		local dir = dirs[ctx.rng:NextInteger(1, 4)]
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local gapA = ctx.rng:NextNumber(-half * 0.7, half * 0.7)
		local gapB = ctx.rng:NextNumber(-half * 0.7, half * 0.7)
		ctx:fx("Banner", { text = "STAMPEDE!", color = "#E84A3A", small = true })
		ctx:fx("Sound", { name = "Cluck", volume = 1 })
		for off = -half + 4, half - 4, 7 do
			if math.abs(off - gapA) > 8 and math.abs(off - gapB) > 8 then
				local p = center - dir * (half - 3) + side * off
				local y = ctx:groundAt(p.X, p.Z)
				if y then
					local c = Mover.new(ctx, Models.Chickens(1.5), { mode = "ground", radius = 1.65, speed = ctx.stats.Speed, position = Vector3.new(p.X, y + 2, p.Z), dir = dir, accel = 300, turnRate = 1 })
					c.data.dir = dir
					c.data.born = os.clock()
				end
			end
		end
	end
	ctx:loop(5.5, function()
		wave()
	end)
	ctx:loop(0.1, function(dt)
		for _, c in ipairs(table.clone(ctx.objects)) do
			if c.alive and c.root.Parent then
				local v = c.data.dir * ctx.stats.Speed * ctx.rampMult
				c.lv.PlaneVelocity = Vector2.new(v.X, v.Z)
				c.ao.CFrame = CFrame.lookAt(Vector3.zero, c.data.dir)
				if os.clock() - c.data.born > 1 and not ctx:inBounds(c.root.Position, -6) or os.clock() - c.data.born > 12 then
					c:destroy(ctx)
				else
					for _, t in ipairs(ctx:targets()) do
						local d = t.root.Position - c.root.Position
						if Vector3.new(d.X, 0, d.Z).Magnitude < 3.9 and math.abs(d.Y) < 4 and c:canHit(t.player, 1) then
							ctx:damage(t, ctx.stats.Damage)
							ctx:knockback(t, c.data.dir * 40 + Vector3.new(0, 30, 0))
						end
					end
				end
			end
		end
	end)
end

return Recipe
