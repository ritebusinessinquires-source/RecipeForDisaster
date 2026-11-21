-- Bath Time: Sharks + Tiny + Bouncy. Rubber duckies bounce out of the water and boop everyone.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "BathTime",
	name = "Bath Time",
	emoji = "🦆",
	main = "Sharks",
	spices = { "Tiny", "Bouncy" },
	type = "Creature",
	desc = "Rubber duckies bounce out of the water and boop everyone.",
	hint = { text = "Duckies barely hurt - but they boop you off edges!", icon = "away" },
	stats = { Size = 1, Speed = 14, Count = 12, Damage = 5, Health = 40 },
}

local Duck = {
	id = "Duck",
	stats = Recipe.stats,
	creature = {
		mode = "ground",
		radius = 1.4,
		turnRate = 300,
		cooldown = 0.6,
		knock = 75,
		hop = 55,
		respawnDelay = 1.5,
		spawnAt = function(ctx)
			local w = ctx.map and ctx.map.water
			if w then
				return Vector3.new(
					w.center.X + ctx.rng:NextNumber(-w.size.X / 2 + 2, w.size.X / 2 - 2),
					w.surfaceY + 1,
					w.center.Z + ctx.rng:NextNumber(-w.size.Z / 2 + 2, w.size.Z / 2 - 2)
				)
			end
			return ctx:randomOpenPoint()
		end,
	},
	build = function(s)
		return Models.Duck(s)
	end,
	sound = "Squeak",
}

function Recipe.Spawn(ctx)
	ctx:fx("Banner", { text = "BATH TIME!", color = "#FFC93C" })
	ctx:fx("Sound", { name = "Splash", volume = 1 })
	CreatureRunner.run(ctx, Duck)
end

return Recipe
