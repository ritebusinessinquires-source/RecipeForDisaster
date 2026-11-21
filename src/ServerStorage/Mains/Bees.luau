-- Bees (Creature): a buzzing swarm that flies at chest height and turns slowly.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Bees = {
	id = "Bees",
	type = "Creature",
	danger = 3,
	sound = "Buzz",
	stats = { Size = 1, Speed = 15, Count = 8, Damage = 12, Health = 40 },
	hint = { text = "Keep running - bees turn slowly!", icon = "run" },
	creature = { mode = "fly", radius = 1.3, hover = 3, turnRate = 110, cooldown = 1.0, knock = 14, followHeight = true, poofColor = Color3.fromRGB(255, 201, 60) },
}

function Bees.Spawn(ctx)
	CreatureRunner.run(ctx, Bees)
end

return Bees
