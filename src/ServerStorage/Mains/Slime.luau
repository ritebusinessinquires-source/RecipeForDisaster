-- Slime (Creature): hopping goo. Getting hit slows you down for a bit.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Slime = {
	id = "Slime",
	type = "Creature",
	danger = 2,
	sound = "Squelch",
	stats = { Size = 1, Speed = 9, Count = 8, Damage = 10, Health = 60 },
	hint = { text = "Climb up high - slimes slow you down!", icon = "raised" },
	creature = { mode = "ground", radius = 1.6, turnRate = 200, cooldown = 1, knock = 30, hop = 38, poofColor = Color3.fromRGB(120, 230, 90) },
}

function Slime.onHit(ctx, obj, target)
	ctx:slow(target, 0.5, 2, "slime")
	ctx:sound("Squelch", target.root.Position, 0.7)
	return false
end

function Slime.Spawn(ctx)
	CreatureRunner.run(ctx, Slime)
end

return Slime
