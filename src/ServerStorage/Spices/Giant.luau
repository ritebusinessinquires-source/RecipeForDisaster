-- Giant: huge and slow. Size x3, Speed x0.7, Health x3 (fewer of them).
return {
	id = "Giant",
	danger = 2,
	sizeWord = true,
	stats = { Size = 3, Speed = 0.7, Health = 3, Count = 0.4 },
	double = { name = "Colossal", stats = { Size = 5, Speed = 0.55, Health = 6, Count = 0.2 } },
	Creature = {
		spawn = function(ctx, level, obj)
			obj.knock *= 1.6 * level
			obj.cooldown *= 1.2
		end,
	},
	Projectile = {
		-- landing sends out a shockwave ring: jump over it!
		impact = function(ctx, level, pos, radius)
			ctx:fx("Shockwave", { pos = pos, radius = radius * 2.4, duration = 0.6 })
			ctx:delay(0.35, function()
				for _, t in ipairs(ctx:targets()) do
					local d = t.root.Position - pos
					local flat = Vector3.new(d.X, 0, d.Z).Magnitude
					local grounded = t.humanoid.FloorMaterial ~= Enum.Material.Air
					if flat > radius and flat < radius * 2.4 and grounded then
						ctx:damage(t, 10 * level)
						ctx:knockback(t, Vector3.new(0, 45, 0))
					end
				end
			end)
		end,
	},
	-- Terrain and Weather: the Size multiplier already makes bigger pools / a bigger twister
}
