-- Mystery Thing (Projectile): anything the game doesn't recognise falls from the sky as a
-- big labelled object. "My homework"? It's raining homework now.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local ProjectileRunner = require(HazardLib.ProjectileRunner)

local Thing = {
	id = "Thing",
	type = "Projectile",
	danger = 3,
	stats = { Size = 1, Speed = 40, Count = 5, Damage = 30, Health = 1 },
	hint = { text = "Keep moving and watch the shadows!", icon = "run" },
	projectile = { kind = "fall", radius = 6.5, height = 95, spread = 8, volleyEvery = 4, style = "thing" },
}

function Thing.Spawn(ctx)
	ProjectileRunner.run(ctx, Thing)
end

return Thing
