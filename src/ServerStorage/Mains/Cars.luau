-- Cars (Projectile): speed across the arena in straight lines. Honk honk.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local ProjectileRunner = require(HazardLib.ProjectileRunner)

local Cars = {
	id = "Cars",
	type = "Projectile",
	danger = 4,
	sound = "Engine",
	stats = { Size = 1, Speed = 40, Count = 3, Damage = 40, Health = 300 },
	hint = { text = "Hide behind low cover - or dodge sideways!", icon = "cover" },
	projectile = { kind = "drive", radius = 2.6, knock = 85, accel = 200 },
}

function Cars.Spawn(ctx)
	ProjectileRunner.run(ctx, Cars)
end

return Cars
