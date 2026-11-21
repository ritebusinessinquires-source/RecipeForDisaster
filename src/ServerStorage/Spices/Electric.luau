-- Electric: zaps and stuns you for a moment; zaps jump to whoever is standing nearby.
local function glow(model: Model)
	local root = model.PrimaryPart
	if root then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(120, 210, 255)
		l.Range = 12
		l.Brightness = 2
		l.Parent = root
		local s = Instance.new("Sparkles")
		s.SparkleColor = Color3.fromRGB(150, 230, 255)
		s.Parent = root
	end
end

-- the zap jumps to the nearest other player within range
local function chain(ctx, from, level)
	local best, bestD = nil, 14 * level
	for _, t in ipairs(ctx:targets()) do
		if t ~= from then
			local d = (t.root.Position - from.root.Position).Magnitude
			if d < bestD then
				best, bestD = t, d
			end
		end
	end
	if best then
		ctx:fx("Bolt", { from = from.root.Position, to = best.root.Position, duration = 0.12, color = Color3.fromRGB(150, 230, 255), width = 0.4 })
		ctx:damage(best, 6 * level)
		ctx:stun(best, 0.5)
	end
end

return {
	id = "Electric",
	danger = 2,
	stats = { Speed = 1.1, Damage = 1.1 },
	double = { name = "Supercharged", stats = { Speed = 1.2, Damage = 1.25 } },
	hint = { text = "Spread out - the zaps jump between players!", icon = "away", priority = 4 },
	Creature = {
		spawn = function(ctx, level, obj)
			glow(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:stun(target, 0.7 * level)
			chain(ctx, target, level)
		end,
		boltHit = function(ctx, level, target)
			ctx:stun(target, 0.6 * level)
		end,
	},
	Projectile = {
		spawn = function(ctx, level, obj)
			glow(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:stun(target, 0.8 * level)
			chain(ctx, target, level)
		end,
		impact = function(ctx, level, pos, radius)
			for _, t in ipairs(ctx:targets()) do
				if (t.root.Position - pos).Magnitude <= radius * 1.4 then
					ctx:stun(t, 0.7 * level)
				end
			end
			ctx:fx("Lightning", { pos = pos, small = true })
		end,
	},
	Terrain = {
		contact = function(ctx, level, target, tile, dt)
			if ctx.rng:NextNumber() < 0.06 * level then
				ctx:stun(target, 0.6)
			end
		end,
	},
	Weather = {
		tick = function(ctx, level, obj, dt)
			local now = os.clock()
			if now >= (obj.data.nextZap or 0) then
				obj.data.nextZap = now + 2.2 / level
				local p = obj.root.Position + Vector3.new(ctx.rng:NextNumber(-25, 25), 0, ctx.rng:NextNumber(-25, 25))
				local y = ctx:groundAt(p.X, p.Z)
				if y then
					local hit = Vector3.new(p.X, y, p.Z)
					ctx:fx("Warning", { pos = hit, radius = 6, duration = 0.8, color = Color3.fromRGB(150, 230, 255) })
					ctx:delay(0.8, function()
						ctx:fx("Lightning", { pos = hit })
						for _, t in ipairs(ctx:targets()) do
							if (t.root.Position - hit).Magnitude < 7 then
								ctx:damage(t, 15 * level)
								ctx:stun(t, 0.8)
							end
						end
					end)
				end
			end
		end,
		hit = function(ctx, level, obj, target)
			ctx:stun(target, 0.5 * level)
		end,
	},
}
