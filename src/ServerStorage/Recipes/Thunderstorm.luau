-- Thunderstorm: Tornado + Exploding + Magnetic. Lightning hunts anyone who stands still.
local Lighting = game:GetService("Lighting")

local Recipe = {
	id = "Thunderstorm",
	name = "Thunderstorm",
	emoji = "⛈️",
	main = "Tornado",
	spices = { "Exploding", "Magnetic" },
	type = "Weather",
	desc = "Storm clouds roll in and lightning hunts anyone who stands still.",
	hint = { text = "Don't stand still - lightning finds you!", icon = "run" },
	stats = { Size = 1, Speed = 1, Count = 1, Damage = 38, Health = 1 },
}

function Recipe.Spawn(ctx)
	local savedBrightness = Lighting.Brightness
	Lighting.Brightness = math.max(0.6, savedBrightness * 0.45)
	ctx:onCleanup(function()
		Lighting.Brightness = savedBrightness
	end)
	ctx:fx("Rain", { on = true })
	ctx:onCleanup(function()
		ctx:fx("Rain", { on = false })
	end)
	local lastPos = {}
	local stillTime = {}
	ctx:loop(0.25, function(dt)
		for _, t in ipairs(ctx:targets()) do
			local p = t.root.Position
			local lp = lastPos[t.player]
			if lp and (p - lp).Magnitude < 1.5 then
				stillTime[t.player] = (stillTime[t.player] or 0) + dt
			else
				stillTime[t.player] = 0
			end
			lastPos[t.player] = p
		end
	end)
	local function strike(pos: Vector3)
		ctx:fx("Warning", { pos = pos, radius = 7, duration = 1.1, color = Color3.fromRGB(255, 255, 120) })
		ctx:delay(1.1, function()
			ctx:fx("Lightning", { pos = pos })
			ctx:explode(pos, 7, ctx.stats.Damage, { knock = 45, visible = false, color = Color3.fromRGB(255, 255, 150) })
		end)
	end
	ctx:loop(0.7, function()
		local rate = ctx.rampMult > 1 and 2 or 1
		for _ = 1, rate do
			-- prefer whoever has been standing still the longest
			local best, bestT = nil, 0.8
			for _, t in ipairs(ctx:targets()) do
				local st = stillTime[t.player] or 0
				if st > bestT then
					best, bestT = t, st
				end
			end
			if best then
				stillTime[best.player] = 0
				local p = best.root.Position
				local y = ctx:groundAt(p.X, p.Z) or p.Y - 3
				strike(Vector3.new(p.X, y, p.Z))
			else
				strike(ctx:aimPoint(12))
			end
		end
	end)
end

return Recipe
