-- Boulders (Projectile): roll across the map from the edges. Low cover stops them.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local ProjectileRunner = require(HazardLib.ProjectileRunner)

local Boulders = {
	id = "Boulders",
	type = "Projectile",
	danger = 3,
	stats = { Size = 1, Speed = 24, Count = 4, Damage = 30, Health = 200 },
	hint = { text = "Duck behind low cover!", icon = "cover" },
	projectile = { kind = "roll", radius = 3, knock = 60, accel = 60 },
}

function Boulders.Spawn(ctx)
	ProjectileRunner.run(ctx, Boulders)
end

return Boulders
