-- Chickens (Creature): fast, zig-zagging and hoppy. Small pecks, lots of them.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Chickens = {
	id = "Chickens",
	type = "Creature",
	danger = 2,
	sound = "Cluck",
	stats = { Size = 1, Speed = 17, Count = 10, Damage = 8, Health = 25 },
	hint = { text = "Climb up high - chickens can't fly!", icon = "raised" },
	creature = { mode = "ground", radius = 1.1, turnRate = 320, cooldown = 0.8, knock = 18, zigzag = 6, hop = 22, poofColor = Color3.fromRGB(255, 255, 255) },
}

function Chickens.onSpawn(ctx, obj)
	obj.data.phase = ctx.rng:NextNumber(0, math.pi * 2)
end

function Chickens.Spawn(ctx)
	CreatureRunner.run(ctx, Chickens)
end

return Chickens
