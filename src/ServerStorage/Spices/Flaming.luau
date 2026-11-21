-- Flaming: on fire. Touching it sets you on fire too.
local function addFire(part: BasePart, size: number)
	local f = Instance.new("Fire")
	f.Size = size
	f.Heat = 10
	f.Parent = part
	return f
end

local function firePatch(ctx, pos: Vector3, radius: number, seconds: number, dps: number)
	local p = Instance.new("Part")
	p.Name = "FirePatch"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.3, radius * 2, radius * 2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = Color3.fromRGB(255, 120, 30)
	p.Material = Enum.Material.Neon
	p.Transparency = 0.35
	p.Parent = ctx.folder
	addFire(p, math.min(radius, 12))
	local untilT = os.clock() + seconds
	task.spawn(function()
		while ctx.alive and os.clock() < untilT and p.Parent do
			for _, t in ipairs(ctx:targets()) do
				local d = t.root.Position - pos
				if Vector3.new(d.X, 0, d.Z).Magnitude <= radius and d.Y < 5 then
					ctx:burn(t, 2.5, dps)
				end
			end
			task.wait(0.25)
		end
		p:Destroy()
	end)
end

return {
	id = "Flaming",
	danger = 2,
	stats = {},
	double = { name = "Inferno", stats = { Damage = 1.2 } },
	hint = { text = "Don't touch the flames!", icon = "away", priority = 2 },
	firePatch = firePatch,
	Creature = {
		spawn = function(ctx, level, obj)
			addFire(obj.root, math.clamp(obj.radius * 2.5, 2, 16) * level)
		end,
		hit = function(ctx, level, obj, target)
			ctx:burn(target, 3 * level, 7)
		end,
	},
	Projectile = {
		spawn = function(ctx, level, obj)
			addFire(obj.root, math.clamp(obj.radius * 3, 3, 20))
		end,
		hit = function(ctx, level, obj, target)
			ctx:burn(target, 3 * level, 8)
		end,
		impact = function(ctx, level, pos, radius)
			firePatch(ctx, pos, radius * 0.9 * level, 4.5, 8)
		end,
	},
	Terrain = {
		tileConverted = function(ctx, level, tile)
			if ctx.rng:NextNumber() < 0.25 * level then
				local f = addFire(tile.part, 6)
				ctx:onCleanup(function()
					f:Destroy()
				end)
			end
		end,
		contact = function(ctx, level, target, tile, dt)
			ctx:burn(target, 2 * level, 6)
		end,
	},
	Weather = {
		spawn = function(ctx, level, obj)
			for _, p in ipairs(obj.model:GetChildren()) do
				if p:IsA("BasePart") and p.Name == "Layer" then
					p.Color = Color3.fromRGB(255, 140, 50)
					addFire(p, 10)
				end
			end
		end,
		hit = function(ctx, level, obj, target)
			ctx:burn(target, 3 * level, 8)
		end,
	},
}
