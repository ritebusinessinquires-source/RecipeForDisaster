-- Storm (Weather): a thundercloud drifts over the arena; lightning hunts anyone standing still.
local Lighting = game:GetService("Lighting")
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local Storm = {
	id = "Storm",
	type = "Weather",
	danger = 4,
	sound = "Rain",
	-- Count = strikes per wave, Size = strike radius, Speed = how often
	stats = { Size = 1, Speed = 1, Count = 2, Damage = 34, Health = 1 },
	hint = { text = "Don't stand still - lightning finds you!", icon = "run" },
}

function Storm.Spawn(ctx)
	local savedBrightness = Lighting.Brightness
	Lighting.Brightness = math.max(0.8, savedBrightness * 0.55)
	ctx:onCleanup(function()
		Lighting.Brightness = savedBrightness
	end)
	ctx:fx("Rain", { on = true })
	ctx:onCleanup(function()
		ctx:fx("Rain", { on = false })
	end)
	local s = ctx.stats.Size
	local p = ctx:randomOpenPoint()
	local cloud = Mover.new(ctx, Models.StormCloud(math.max(0.6, s)), { mode = "phase", radius = 6 * s, speed = 8, hover = 45, position = p + Vector3.new(0, 45, 0), turnRate = 60 })
	cloud.ao.Enabled = false
	cloud.pullRadius = 22 * s
	cloud.damage = ctx.stats.Damage
	cloud.main = Storm
	ctx:hook("spawn", cloud)
	ctx:decorate(cloud, "Rain")

	local lastPos, still = {}, {}
	ctx:loop(0.25, function(dt)
		for _, t in ipairs(ctx:targets()) do
			local pos = t.root.Position
			local lp = lastPos[t.player]
			still[t.player] = (lp and (pos - lp).Magnitude < 1.5) and ((still[t.player] or 0) + dt) or 0
			lastPos[t.player] = pos
		end
	end)
	ctx:loop(0.1, function(dt)
		if not cloud.alive or not cloud.root.Parent then
			return
		end
		local t = ctx:nearestTarget(cloud.root.Position, nil, true)
		local goal = t and t.root.Position or (ctx.map and ctx.map.center or Vector3.zero)
		local d = Vector3.new(goal.X - cloud.root.Position.X, 0, goal.Z - cloud.root.Position.Z)
		local ground = ctx:groundAt(cloud.root.Position.X, cloud.root.Position.Z) or 0
		cloud:drive(d.Magnitude > 4 and d or cloud.dir, dt, ctx.rampMult, ground + 45)
		ctx:hook("tick", cloud, dt)
	end)
	local function strike(pos: Vector3)
		local r = 7 * math.sqrt(s)
		ctx:fx("Warning", { pos = pos, radius = r, duration = 1.0, color = Color3.fromRGB(255, 255, 120) })
		ctx:delay(1.0, function()
			ctx:fx("Lightning", { pos = pos })
			for _, t in ipairs(ctx:targets()) do
				if (t.root.Position - pos).Magnitude < r + 1.5 then
					local consumed = ctx:hook("hit", cloud, t)
					if not consumed then
						ctx:damage(t, ctx.stats.Damage)
						ctx:knockback(t, Vector3.new(0, 45, 0))
					end
				end
			end
		end)
	end
	ctx:loop(1.2, function()
		local waves = math.max(1, math.floor(ctx.stats.Count * (ctx.rampMult > 1 and 1.5 or 1) * (ctx.stats.Speed or 1) + 0.5))
		for _ = 1, waves do
			local best, bestT = nil, 0.8
			for _, t in ipairs(ctx:targets()) do
				local st = still[t.player] or 0
				if st > bestT then
					best, bestT = t, st
				end
			end
			if best then
				still[best.player] = 0
				local bp = best.root.Position
				strike(Vector3.new(bp.X, ctx:groundAt(bp.X, bp.Z) or bp.Y - 3, bp.Z))
			else
				strike(ctx:aimPoint(14))
			end
		end
	end)
end

return Storm
