-- Demolition Derby: Cars + Bouncy + Exploding. Bumper cars ricochet around and explode on contact.
local ServerStorage = game:GetService("ServerStorage")
local ProjectileRunner = require(ServerStorage:WaitForChild("HazardLib"):WaitForChild("ProjectileRunner"))
local Cars = require(ServerStorage:WaitForChild("Mains"):WaitForChild("Cars"))

local Recipe = {
	id = "DemolitionDerby",
	name = "Demolition Derby",
	emoji = "🏎️",
	main = "Cars",
	spices = { "Bouncy", "Exploding" },
	type = "Projectile",
	desc = "Bumper cars ricochet off the edges forever and explode when they hit you.",
	hint = { text = "Hide behind cover - the cars never leave!", icon = "cover" },
	stats = { Size = 0.8, Speed = 34, Count = 6, Damage = 30, Health = 300 },
}

local Derby = table.clone(Cars)
Derby.projectile = table.clone(Cars.projectile)
Derby.projectile.knock = 70

function Recipe.Spawn(ctx)
	-- reuse the Spice hooks: Bouncy cars bounce off edges, Exploding cars blow up on hit
	ctx.dish.hooks = { Bouncy = 1, Exploding = 1 }
	ctx.dish.type = "Projectile"
	ctx:fx("Banner", { text = "DEMOLITION DERBY!", color = "#FFC93C" })
	ProjectileRunner.run(ctx, Derby)
	-- every few seconds the cars swerve
	ctx:loop(3, function()
		for _, obj in ipairs(ctx.objects) do
			if obj.alive and obj.data.fixedDir then
				local a = ctx.rng:NextNumber(-0.7, 0.7)
				local d = obj.data.fixedDir
				obj.data.fixedDir = Vector3.new(d.X * math.cos(a) - d.Z * math.sin(a), 0, d.X * math.sin(a) + d.Z * math.cos(a)).Unit
				obj.bornAt = os.clock()
			end
		end
	end)
end

return Recipe
