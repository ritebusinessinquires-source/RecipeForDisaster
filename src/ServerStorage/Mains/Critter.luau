-- Critter (Creature): small, fast, zig-zagging animals. Cats, dogs, rabbits, mice...
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Critter = {
	id = "Critter",
	type = "Creature",
	danger = 2,
	sound = "Squeak",
	stats = { Size = 1, Speed = 18, Count = 10, Damage = 8, Health = 30 },
	hint = { text = "Climb something - critters can't follow you up!", icon = "raised" },
	creature = { mode = "ground", radius = 1.1, turnRate = 380, cooldown = 0.8, knock = 18, zigzag = 7, hop = 16 },
}

function Critter.onSpawn(ctx, obj)
	obj.data.phase = ctx.rng:NextNumber(0, math.pi * 2)
end

function Critter.Spawn(ctx)
	CreatureRunner.run(ctx, Critter)
end

return Critter
