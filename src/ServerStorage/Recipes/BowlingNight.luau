-- Bowling Night: Boulders + Fast + Slippery. Bowling balls thunder down icy lanes. You're the pins.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "BowlingNight",
	name = "Bowling Night",
	emoji = "🎳",
	main = "Boulders",
	spices = { "Fast", "Slippery" },
	type = "Projectile",
	desc = "Bowling balls thunder down icy lanes. You're the pins.",
	hint = { text = "Get out of the lane - watch the arrows!", icon = "run" },
	stats = { Size = 1, Speed = 50, Count = 1, Damage = 35, Health = 1 },
}

function Recipe.Spawn(ctx)
	local map = ctx.map
	local center = map and map.center or Vector3.zero
	local half = map and (map.shape == "circle" and map.radius or (map.bounds.maxX - map.bounds.minX) / 2) or 120
	local laneWidth = 14
	local axisX = ctx.rng:NextNumber() < 0.5
	local lanes = {}
	for i = -3, 3 do
		table.insert(lanes, i * laneWidth * 2.2)
	end
	-- the lanes are icy
	ctx:loop(2, function()
		for _, off in ipairs(lanes) do
			for k = -half, half, 9 do
				local p = axisX and Vector3.new(center.X + k, 0, center.Z + off) or Vector3.new(center.X + off, 0, center.Z + k)
				ctx:iceAt(p, laneWidth * 0.5, 3)
			end
		end
	end)
	local function roll()
		local off = lanes[ctx.rng:NextInteger(1, #lanes)]
		local sign = ctx.rng:NextNumber() < 0.5 and -1 or 1
		local dir = axisX and Vector3.new(sign, 0, 0) or Vector3.new(0, 0, sign)
		local startPos = axisX and Vector3.new(center.X - sign * (half - 4), 0, center.Z + off) or Vector3.new(center.X + off, 0, center.Z - sign * (half - 4))
		local ground = ctx:groundAt(startPos.X, startPos.Z) or 0
		ctx:fx("LaneArrow", { from = Vector3.new(startPos.X, ground + 0.5, startPos.Z), dir = dir, length = half * 2, width = laneWidth, duration = 1.1 })
		ctx:delay(1.1, function()
			local m = Models.Blob(3.5, Color3.fromRGB(25, 25, 35), Enum.Material.Glass)
			local ball = Mover.new(ctx, m, { mode = "ground", radius = 3.5, speed = ctx.stats.Speed, position = Vector3.new(startPos.X, ground + 4, startPos.Z), dir = dir, accel = 200 })
			ball.ao.Enabled = false
			ctx:decorate(ball, "Roll")
			local born = os.clock()
			task.spawn(function()
				while ctx.alive and ball.alive and ball.root.Parent and os.clock() - born < 8 do
					ball.lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * ctx.stats.Speed * ctx.rampMult
					for _, t in ipairs(ctx:targets()) do
						local d = t.root.Position - ball.root.Position
						if Vector3.new(d.X, 0, d.Z).Magnitude < 5.5 and math.abs(d.Y) < 6 and ball:canHit(t.player, 1.5) then
							ctx:damage(t, ctx.stats.Damage)
							ctx:knockback(t, dir * 70 + Vector3.new(0, 75, 0))
							ctx:fx("Banner", { text = "STRIKE!", color = "#E84A3A", small = true })
						end
					end
					if not ctx:inBounds(ball.root.Position, -6) then
						break
					end
					task.wait(0.1)
				end
				ball:destroy(ctx)
			end)
		end)
	end
	ctx:loop(1.4, function()
		local n = ctx.rampMult > 1 and 2 or 1
		for _ = 1, n do
			roll()
		end
	end)
end

return Recipe
