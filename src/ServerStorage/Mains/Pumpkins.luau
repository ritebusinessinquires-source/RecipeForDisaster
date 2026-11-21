-- Pumpkins (seasonal Projectile, October): roll across the map and splat when they stop.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local ProjectileRunner = require(HazardLib.ProjectileRunner)

local Pumpkins = {
	id = "Pumpkins",
	type = "Projectile",
	danger = 3,
	sound = "Roll",
	seasonal = true,
	stats = { Size = 1, Speed = 22, Count = 4, Damage = 25, Health = 150 },
	hint = { text = "Duck behind low cover - mind the splat!", icon = "cover" },
	projectile = { kind = "roll", radius = 3, knock = 55, accel = 60 },
}

Pumpkins.projectile.splat = function(ctx, obj)
	ctx:explode(obj.root.Position, 9 * ctx.stats.Size, ctx.stats.Damage * 0.6, { color = Color3.fromRGB(240, 130, 30), knock = 45 })
end

function Pumpkins.Spawn(ctx)
	ProjectileRunner.run(ctx, Pumpkins)
end

return Pumpkins
