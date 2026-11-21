-- Quicksand (Terrain): sticky patches that slow you down, then swallow you if you stay.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local TerrainRunner = require(HazardLib.TerrainRunner)

local Quicksand = {
	id = "Quicksand",
	type = "Terrain",
	danger = 3,
	stats = { Size = 1, Speed = 1, Count = 5, Damage = 22, Health = 1 },
	hint = { text = "Keep to high ground - don't stop in the sand!", icon = "raised" },
	terrain = {
		hazard = "quicksand",
		warnColor = Color3.fromRGB(214, 178, 110),
		onContact = function(ctx, target, tile, dt, sinkTime)
			ctx:slow(target, 0.35, 0.35, "quicksand")
			local t = (sinkTime[target.player] or 0) + dt
			sinkTime[target.player] = t
			if t > 1.2 then
				ctx:damage(target, ctx.stats.Damage * dt * math.min(2, t / 1.2))
			end
		end,
	},
}

function Quicksand.Spawn(ctx)
	TerrainRunner.run(ctx, Quicksand)
end

return Quicksand
