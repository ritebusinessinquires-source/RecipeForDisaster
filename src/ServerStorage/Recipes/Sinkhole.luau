-- Sinkhole: Quicksand + Giant + Magnetic. A huge sand whirlpool drags everyone toward its centre.
local Recipe = {
	id = "Sinkhole",
	name = "Sinkhole",
	emoji = "🌀",
	main = "Quicksand",
	spices = { "Giant", "Magnetic" },
	type = "Terrain",
	desc = "A huge sand whirlpool opens up and drags everyone toward its centre.",
	hint = { text = "Run against the pull and climb something!", icon = "raised" },
	stats = { Size = 1, Speed = 4, Count = 1, Damage = 35, Health = 1 },
}

function Recipe.Spawn(ctx)
	local map = ctx.map
	local center = (map and map.center or Vector3.zero) + Vector3.new(ctx.rng:NextNumber(-30, 30), 0, ctx.rng:NextNumber(-30, 30))
	local ground = ctx:groundAt(center.X, center.Z) or 0
	local pos = Vector3.new(center.X, ground, center.Z)
	local radius = 16
	local core = Instance.new("Part")
	core.Name = "SinkholeCore"
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.Shape = Enum.PartType.Cylinder
	core.Size = Vector3.new(0.4, radius * 2, radius * 2)
	core.Color = Color3.fromRGB(150, 115, 60)
	core.Material = Enum.Material.Sand
	core.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	core.Parent = ctx.folder
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = "rbxasset://textures/particles/smoke_main.dds"
	swirl.Color = ColorSequence.new(Color3.fromRGB(200, 165, 100))
	swirl.Size = NumberSequence.new(3, 6)
	swirl.Rate = 30
	swirl.Lifetime = NumberRange.new(1, 2)
	swirl.RotSpeed = NumberRange.new(200, 300)
	swirl.Speed = NumberRange.new(2, 4)
	swirl.Parent = core
	ctx:addPull(core, 75, 9)
	local angle = 0
	ctx:loop(0.1, function(dt)
		-- drift slowly toward players, spin, grow
		local t = ctx:nearestTarget(pos, nil, true)
		if t then
			local d = Vector3.new(t.root.Position.X - pos.X, 0, t.root.Position.Z - pos.Z)
			if d.Magnitude > 2 then
				pos += d.Unit * ctx.stats.Speed * ctx.rampMult * dt
				local y = ctx:groundAt(pos.X, pos.Z)
				if y and ctx:inBounds(pos, 10) then
					pos = Vector3.new(pos.X, y, pos.Z)
				end
			end
		end
		radius = math.min(26, radius + dt * 0.25)
		angle += dt * 2
		core.Size = Vector3.new(0.4, radius * 2, radius * 2)
		core.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, angle, math.rad(90))
		if ctx.tiles then
			for _, tile in ipairs(ctx.tiles:inRadius(pos, radius + 6)) do
				if not tile.hazard then
					ctx.tiles:setHazard(tile, "quicksand", ctx.dish.id, 1)
				end
			end
		end
		for _, target in ipairs(ctx:targets()) do
			local d = target.root.Position - pos
			local flat = Vector3.new(d.X, 0, d.Z).Magnitude
			if flat < radius + 6 and d.Y < 6 then
				ctx:slow(target, 0.4, 0.3, "sinkhole")
			end
			if flat < radius * 0.35 and d.Y < 6 then
				ctx:damage(target, ctx.stats.Damage * dt)
			end
		end
	end)
end

return Recipe
