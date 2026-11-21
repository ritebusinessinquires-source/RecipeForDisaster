-- Meteors (Projectile): rocks fall from the sky. Each one casts a growing shadow first.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local ProjectileRunner = require(HazardLib.ProjectileRunner)

local Meteors = {
	id = "Meteors",
	type = "Projectile",
	danger = 3,
	-- Speed = fall speed in studs/s, Count = meteors per volley
	stats = { Size = 1, Speed = 42, Count = 6, Damage = 35, Health = 1 },
	hint = { text = "Keep moving and watch the shadows!", icon = "run" },
	projectile = { kind = "fall", radius = 7, height = 95, spread = 8, volleyEvery = 4 },
}

function Meteors.Spawn(ctx)
	ProjectileRunner.run(ctx, Meteors)
end

return Meteors
