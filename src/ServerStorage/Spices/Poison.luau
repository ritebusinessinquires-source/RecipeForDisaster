-- Poison: poisons you over time and leaves toxic puddles behind.
local TOXIC = Color3.fromRGB(120, 230, 60)

local function tint(model: Model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			p.Color = p.Color:Lerp(TOXIC, 0.45)
		end
	end
end

local function puddle(ctx, pos: Vector3, radius: number, seconds: number, level: number)
	local p = Instance.new("Part")
	p.Name = "ToxicPuddle"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.25, radius * 2, radius * 2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Color = TOXIC
	p.Material = Enum.Material.Neon
	p.Transparency = 0.35
	p.Parent = ctx.folder
	local untilT = os.clock() + seconds
	task.spawn(function()
		while ctx.alive and os.clock() < untilT and p.Parent do
			for _, t in ipairs(ctx:targets()) do
				local d = t.root.Position - pos
				if Vector3.new(d.X, 0, d.Z).Magnitude <= radius and d.Y < 5 then
					ctx:poison(t, 3, 5 * level)
				end
			end
			task.wait(0.4)
		end
		p:Destroy()
	end)
end

return {
	id = "Poison",
	danger = 2,
	stats = { Damage = 0.85 },
	double = { name = "Toxic", stats = { Damage = 0.9 } },
	hint = { text = "Avoid the green puddles - poison keeps hurting!", icon = "away", priority = 3 },
	puddle = puddle,
	Creature = {
		spawn = function(ctx, level, obj)
			tint(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:poison(target, 4 * level, 5)
		end,
		tick = function(ctx, level, obj, dt)
			local now = os.clock()
			if now >= (obj.data.nextPuddle or 0) then
				obj.data.nextPuddle = now + ctx.rng:NextNumber(3, 6) / level
				local pos = obj.root.Position
				local y = ctx:groundAt(pos.X, pos.Z)
				if y then
					puddle(ctx, Vector3.new(pos.X, y, pos.Z), 4 + obj.radius, 6, level)
				end
			end
		end,
		boltHit = function(ctx, level, target)
			ctx:poison(target, 3 * level, 5)
		end,
	},
	Projectile = {
		spawn = function(ctx, level, obj)
			tint(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:poison(target, 4 * level, 6)
		end,
		impact = function(ctx, level, pos, radius)
			puddle(ctx, pos, radius * 0.9, 6, level)
		end,
	},
	Terrain = {
		hazardName = function(ctx, level, name)
			return name == "lava" and "acid" or name
		end,
		contact = function(ctx, level, target, tile, dt)
			if ctx.rng:NextNumber() < 0.1 then
				ctx:poison(target, 3, 5 * level)
			end
		end,
	},
	Weather = {
		spawn = function(ctx, level, obj)
			tint(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:poison(target, 4 * level, 5)
		end,
	},
}
