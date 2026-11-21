-- Fast: everything moves (or spreads) faster.
return {
	id = "Fast",
	danger = 2,
	stats = { Speed = 1.6 },
	double = { name = "Turbo", stats = { Speed = 2.3 } },
	Creature = {
		spawn = function(ctx, level, obj)
			obj.turnRate *= 1 + 0.3 * level
		end,
	},
}
