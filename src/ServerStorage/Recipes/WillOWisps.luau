-- Will-o'-Wisps: Ghosts + Flaming + Invisible. Pretty floating lights lure you in... and burn.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "WillOWisps",
	name = "Will-o'-Wisps",
	emoji = "✨",
	main = "Ghosts",
	spices = { "Flaming", "Invisible" },
	type = "Creature",
	desc = "Pretty floating lights lure you toward them... and burn.",
	hint = { text = "Don't follow the lights - run against the pull!", icon = "run" },
	stats = { Size = 1, Speed = 8, Count = 7, Damage = 10, Health = 1 },
}

function Recipe.Spawn(ctx)
	for _ = 1, ctx.stats.Count do
		local p = ctx:randomOpenPoint()
		local w = Mover.new(ctx, Models.Wisp(1.2), { mode = "phase", radius = 1.2, speed = ctx.stats.Speed, position = p + Vector3.new(0, 4, 0), turnRate = 120 })
		ctx:addPull(w.root, 30, 6)
		w.data.phase = ctx.rng:NextNumber(0, 6)
	end
	ctx:loop(0.1, function(dt)
		for _, w in ipairs(ctx.objects) do
			if w.alive and w.root.Parent then
				local t = ctx:nearestTarget(w.root.Position, nil, true)
				local desired = t and (t.root.Position - w.root.Position) or w.dir
				local ground = ctx:groundAt(w.root.Position.X, w.root.Position.Z) or 0
				w:drive(desired, dt, ctx.rampMult, ground + 3.5 + math.sin(os.clock() * 2 + w.data.phase) * 1.5)
				for _, target in ipairs(ctx:targets()) do
					if (target.root.Position - w.root.Position).Magnitude < 4 and w:canHit(target.player, 1.2) then
						ctx:damage(target, ctx.stats.Damage)
						ctx:burn(target, 4, 7)
					end
				end
			end
		end
	end)
end

return Recipe
