-- Volcano: Lava + Exploding + Giant. A volcano bursts out of the middle and lobs lava bombs.
local TweenService = game:GetService("TweenService")

local Recipe = {
	id = "Volcano",
	name = "Volcano",
	emoji = "🌋",
	main = "Lava",
	spices = { "Exploding", "Giant" },
	type = "Terrain",
	desc = "A volcano bursts out of the middle of the map and lobs lava bombs everywhere.",
	hint = { text = "Watch for the landing circles and keep moving!", icon = "run" },
	stats = { Size = 1, Speed = 1, Count = 1, Damage = 28, Health = 1 },
}

function Recipe.Spawn(ctx)
	local map = ctx.map
	local center = map and map.center or Vector3.zero
	local base = ctx:groundAt(center.X, center.Z) or 0
	local cone = Instance.new("Model")
	cone.Name = "Volcano"
	local layers = { { 46, 6 }, { 36, 6 }, { 27, 6 }, { 19, 5 } }
	local y = 0
	for i, l in ipairs(layers) do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.Size = Vector3.new(l[2], l[1], l[1])
		p.CFrame = CFrame.new(center.X, base - 26 + y + l[2] / 2, center.Z) * CFrame.Angles(0, 0, math.rad(90))
		p.Color = Color3.fromRGB(110 - i * 8, 70 - i * 5, 50)
		p.Material = Enum.Material.Basalt
		p.Parent = cone
		y += l[2]
	end
	local top = Instance.new("Part")
	top.Shape = Enum.PartType.Cylinder
	top.Anchored = true
	top.CanCollide = false
	top.Size = Vector3.new(1, 15, 15)
	top.CFrame = CFrame.new(center.X, base - 26 + y + 0.2, center.Z) * CFrame.Angles(0, 0, math.rad(90))
	top.Color = Color3.fromRGB(255, 90, 20)
	top.Material = Enum.Material.Neon
	top.Parent = cone
	local fire = Instance.new("Fire")
	fire.Size = 18
	fire.Heat = 20
	fire.Parent = top
	cone.Parent = ctx.folder
	-- rise out of the ground
	ctx:rumble(1.5, 3)
	for _, p in ipairs(cone:GetChildren()) do
		if p:IsA("BasePart") then
			TweenService:Create(p, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = p.CFrame + Vector3.new(0, 26, 0) }):Play()
		end
	end
	local mouth = Vector3.new(center.X, base + y, center.Z)
	ctx:delay(3, function()
		ctx:loop(1.1, function()
			local n = ctx.rampMult > 1 and 3 or 2
			for _ = 1, n do
				local p = ctx:aimPoint(10)
				if (Vector3.new(p.X, 0, p.Z) - Vector3.new(center.X, 0, center.Z)).Magnitude > 26 then
					ctx:fx("Warning", { pos = p, radius = 9, duration = 1.6, color = Color3.fromRGB(255, 90, 20) })
					ctx:fx("Arc", { from = mouth, to = p, duration = 1.6, style = "lava", height = 40 })
					ctx:delay(1.6, function()
						ctx:explode(p, 9, ctx.stats.Damage, { knock = 50, color = Color3.fromRGB(255, 90, 20) })
						if ctx.tiles then
							for _, t in ipairs(ctx.tiles:inRadius(p, 6)) do
								if not t.hazard then
									ctx.tiles:setHazard(t, "lava", ctx.dish.id, 1)
									ctx:delay(6, function()
										if t.hazardOwner == ctx.dish.id then
											ctx.tiles:setHazard(t, nil)
										end
									end)
								end
							end
						end
					end)
				end
			end
		end)
	end)
	-- the volcano and its lava pools burn
	local TerrainRunner = require(game:GetService("ServerStorage").HazardLib.TerrainRunner)
	ctx:loop(0.1, function(dt)
		for _, t in ipairs(ctx:targets()) do
			local flat = Vector3.new(t.root.Position.X - center.X, 0, t.root.Position.Z - center.Z).Magnitude
			if flat < 24 and t.root.Position.Y < base + y + 6 then
				ctx:damage(t, 30 * dt)
				local away = Vector3.new(t.root.Position.X - center.X, 0, t.root.Position.Z - center.Z)
				away = away.Magnitude > 0.1 and away.Unit or Vector3.xAxis
				ctx:knockback(t, away * 40 + Vector3.new(0, 30, 0))
			end
			local tile = TerrainRunner.tileUnder(ctx, t.root)
			if tile and tile.hazardOwner == ctx.dish.id then
				ctx:damage(t, 25 * dt)
			end
		end
	end)
end

return Recipe
