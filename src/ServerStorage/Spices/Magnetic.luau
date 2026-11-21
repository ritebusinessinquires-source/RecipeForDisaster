-- Magnetic: pulls players in. Magnets don't stick to wind, so on Weather it falls back
-- to the generic +30% Damage.
return {
	id = "Magnetic",
	danger = 2,
	stats = {},
	double = { name = "Mega-Magnetic", stats = {} },
	hint = { text = "Run against the pull!", icon = "run", priority = 6 },
	deadOn = { Weather = "Magnets don't stick to wind... so it hits 30% harder instead!" },
	Creature = {
		spawn = function(ctx, level, obj)
			ctx:addPull(obj.root, 20 + 8 * level + obj.radius * 2, 5 * level)
			local m = Instance.new("Part")
			m.Name = "MagnetIcon"
			m.Anchored = false
			m.CanCollide = false
			m.CanQuery = false
			m.CanTouch = false
			m.Massless = true
			m.Shape = Enum.PartType.Cylinder
			m.Size = Vector3.new(0.4, 1, 1) * math.max(1, obj.radius)
			m.Color = Color3.fromRGB(232, 74, 58)
			m.Material = Enum.Material.Neon
			m.CFrame = obj.root.CFrame * CFrame.new(0, obj.radius + 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))
			local w = Instance.new("WeldConstraint")
			w.Part0 = obj.root
			w.Part1 = m
			w.Parent = m
			m.Parent = obj.model
		end,
	},
	Projectile = {
		-- falling things home in on players
		aim = function(ctx, level, point)
			local t = ctx:randomTarget()
			if t then
				local p = t.root.Position + t.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * 0.8
				local y = ctx:groundAt(p.X, p.Z)
				if y then
					return Vector3.new(p.X, y, p.Z)
				end
			end
			return point
		end,
		spawn = function(ctx, level, obj)
			ctx:addPull(obj.root, 18 * level + obj.radius, 4 * level)
		end,
	},
	Terrain = {
		-- pools creep toward the nearest player
		spreadPick = function(ctx, level, pick, free)
			local best, bestD = pick, math.huge
			for _, t in ipairs(free) do
				local target, d = ctx:nearestTarget(t.center, nil, true)
				if target and d < bestD then
					best, bestD = t, d
				end
			end
			return best
		end,
	},
}
