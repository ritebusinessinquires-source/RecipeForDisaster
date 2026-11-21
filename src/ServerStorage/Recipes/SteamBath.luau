-- Steam Bath: any Main + Flaming + Frozen. Scalding fog fills the map instead of the Main.
local Recipe = {
	id = "SteamBath",
	name = "Steam Bath",
	emoji = "♨️",
	main = nil, -- any
	spices = { "Flaming", "Frozen" },
	type = "Weather",
	desc = "Scalding fog fills the map instead of the Main.",
	hint = { text = "Climb high - the steam stays low!", icon = "raised" },
	stats = { Size = 1, Speed = 1, Count = 1, Damage = 14, Health = 1 },
}

function Recipe.Spawn(ctx)
	local map = ctx.map
	local floorY = map and map.floorY or 0
	local center = map and map.center or Vector3.zero
	local top = floorY + 1
	local maxTop = floorY + 3.6
	local fog = Instance.new("Part")
	fog.Name = "Steam"
	fog.Anchored = true
	fog.CanCollide = false
	fog.CanQuery = false
	fog.CanTouch = false
	fog.CastShadow = false
	fog.Material = Enum.Material.SmoothPlastic
	fog.Color = Color3.fromRGB(240, 244, 248)
	fog.Transparency = 0.45
	local w = map and (map.shape == "circle" and map.radius * 2 or (map.bounds.maxX - map.bounds.minX)) or 250
	local d = map and (map.shape == "circle" and map.radius * 2 or (map.bounds.maxZ - map.bounds.minZ)) or 250
	local function place()
		local h = top - (floorY - 1)
		if map and map.shape == "circle" then
			fog.Shape = Enum.PartType.Cylinder
			fog.Size = Vector3.new(h, w, w)
			fog.CFrame = CFrame.new(center.X, floorY - 1 + h / 2, center.Z) * CFrame.Angles(0, 0, math.rad(90))
		else
			fog.Size = Vector3.new(w, h, d)
			fog.CFrame = CFrame.new(center.X, floorY - 1 + h / 2, center.Z)
		end
	end
	place()
	fog.Parent = ctx.folder
	-- steam vents
	for _ = 1, 10 do
		local p = ctx:randomOpenPoint()
		local vent = Instance.new("Part")
		vent.Anchored = true
		vent.CanCollide = false
		vent.CanQuery = false
		vent.Transparency = 1
		vent.Size = Vector3.one
		vent.Position = p
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.new(1, 1, 1))
		e.Size = NumberSequence.new(4, 12)
		e.Transparency = NumberSequence.new(0.3, 1)
		e.Lifetime = NumberRange.new(2, 3)
		e.Rate = 12
		e.Speed = NumberRange.new(2, 5)
		e.SpreadAngle = Vector2.new(60, 60)
		e.Parent = vent
		vent.Parent = ctx.folder
	end
	ctx:loop(0.5, function()
		local goal = ctx.rampMult > 1 and maxTop + 1 or maxTop
		if top < goal then
			top = math.min(goal, top + 0.25)
			place()
		end
	end)
	ctx:loop(0.2, function(dt)
		for _, t in ipairs(ctx:targets()) do
			local feet = t.root.Position.Y - 2.6
			if feet < top - 0.3 then
				ctx:damage(t, ctx.stats.Damage * dt)
			end
		end
	end)
end

return Recipe
