-- Slippery: leaves ice behind. Ice tiles make players slide (handled on the client).
return {
	id = "Slippery",
	danger = 1,
	stats = {},
	double = { name = "Greased", stats = {} },
	hint = { text = "Stay off the ice!", icon = "run", priority = 3 },
	Creature = {
		tick = function(ctx, level, obj, dt)
			local now = os.clock()
			if now >= (obj.data.nextIce or 0) then
				obj.data.nextIce = now + 0.35
				local r = math.max(4, obj.radius * 1.8) * (1 + 0.5 * (level - 1))
				ctx:iceAt(obj.root.Position, r, 7 * level)
			end
		end,
	},
	Projectile = {
		impact = function(ctx, level, pos, radius)
			ctx:iceAt(pos, radius * 1.7 * level, 9)
		end,
		tick = function(ctx, level, obj, dt)
			local now = os.clock()
			if now >= (obj.data.nextIce or 0) then
				obj.data.nextIce = now + 0.25
				ctx:iceAt(obj.root.Position, obj.radius * 1.5 * level, 8)
			end
		end,
	},
	Terrain = {
		-- the floor around every pool turns to ice
		spreadTick = function(ctx, level, owned)
			for _ = 1, 3 * level do
				if #owned > 0 then
					local t = owned[ctx.rng:NextInteger(1, #owned)]
					ctx:iceAt(t.center, ctx.tiles.size * 2.2, 8)
				end
			end
		end,
	},
	Weather = {
		tick = function(ctx, level, obj, dt)
			local now = os.clock()
			if now >= (obj.data.nextIce or 0) then
				obj.data.nextIce = now + 0.4
				ctx:iceAt(obj.root.Position, obj.pullRadius * 0.45 * level, 6)
			end
		end,
	},
}
