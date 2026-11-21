-- Earthquake: the ground shakes every few seconds and shoves everyone around.
return {
	id = "Earthquake",
	danger = 1,
	Start = function(ctx)
		ctx:fx("Sound", { name = "Stomp", volume = 0.8 })
		ctx:loop(3.5, function()
			if ctx:elapsed() < 1 then
				return
			end
			ctx:rumble(1.2, 1.2)
			for _, t in ipairs(ctx:targets()) do
				local a = ctx.rng:NextNumber(0, math.pi * 2)
				ctx:knockback(t, Vector3.new(math.cos(a) * 26, 22, math.sin(a) * 26))
			end
			-- a little falling rubble
			for _ = 1, 3 do
				local p = ctx:aimPoint(14)
				ctx:fx("Meteor", { to = p, height = 50, duration = 1.2, size = 0.4, radius = 3, style = "rubble" })
				ctx:delay(1.2, function()
					for _, t in ipairs(ctx:targets()) do
						if (t.root.Position - p).Magnitude < 4 then
							ctx:damage(t, 8)
						end
					end
				end)
			end
		end)
	end,
}
