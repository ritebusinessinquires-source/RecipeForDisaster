-- Ghosts (Creature): slow and floaty, they pass through walls and chill you on touch.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Ghosts = {
	id = "Ghosts",
	type = "Creature",
	danger = 3,
	sound = "Wail",
	stats = { Size = 1, Speed = 9, Count = 6, Damage = 15, Health = 999 },
	hint = { text = "Keep moving - ghosts are slow but float through everything!", icon = "run" },
	creature = { mode = "phase", radius = 1.6, hover = 2.5, turnRate = 140, cooldown = 1.2, knock = 10, followHeight = true, poofColor = Color3.fromRGB(200, 190, 255) },
}

function Ghosts.onHit(ctx, obj, target)
	ctx:slow(target, 0.6, 1.5, "ghostChill")
	return false
end

function Ghosts.Spawn(ctx)
	CreatureRunner.run(ctx, Ghosts)
end

return Ghosts
