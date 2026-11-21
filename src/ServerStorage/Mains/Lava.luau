-- Lava (Terrain): the floor turns to lava from a few seeds and spreads.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local TerrainRunner = require(HazardLib.TerrainRunner)

local Lava = {
	id = "Lava",
	type = "Terrain",
	danger = 4,
	sound = "Bubble",
	-- Count = seed pools, Size = pool size, Speed = spread rate, Damage = per second
	stats = { Size = 1, Speed = 1, Count = 4, Damage = 32, Health = 1 },
	hint = { text = "The floor is lava! Get on high ground or into the water!", icon = "raised" },
	terrain = {
		hazard = "lava",
		warnColor = Color3.fromRGB(255, 90, 20),
		onContact = function(ctx, target, tile, dt)
			ctx:damage(target, ctx.stats.Damage * dt)
			if ctx.rng:NextNumber() < 0.08 then
				ctx:knockback(target, Vector3.new(0, 38, 0))
			end
		end,
	},
}

function Lava.Spawn(ctx)
	TerrainRunner.run(ctx, Lava)
end

return Lava
