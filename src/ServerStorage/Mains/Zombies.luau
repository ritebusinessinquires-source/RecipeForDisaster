-- Zombies (Creature): shamble after the nearest player. They can't climb raised spots.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Zombies = {
	id = "Zombies",
	type = "Creature",
	danger = 3,
	sound = "Groan",
	stats = { Size = 1, Speed = 10, Count = 8, Damage = 20, Health = 60 },
	hint = { text = "Get on high ground - zombies can't climb!", icon = "raised" },
	creature = { mode = "ground", radius = 1.5, turnRate = 220, cooldown = 1.1, knock = 22, poofColor = Color3.fromRGB(120, 180, 90) },
}

function Zombies.Spawn(ctx)
	CreatureRunner.run(ctx, Zombies)
end

return Zombies
