-- Popcorn: Chickens + Exploding + Flaming. Chickens burst into bouncing popcorn that knocks players around.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)
local Models = require(HazardLib.Models)

local Recipe = {
	id = "Popcorn",
	name = "Popcorn",
	emoji = "🍿",
	main = "Chickens",
	spices = { "Exploding", "Flaming" },
	type = "Creature",
	desc = "Chickens burst into bouncing popcorn that knocks players around.",
	hint = { text = "Stay away from the edges - popcorn bounces you!", icon = "away" },
	stats = { Size = 1, Speed = 15, Count = 18, Damage = 6, Health = 30 },
}

local Kernel = {
	id = "Kernel",
	stats = Recipe.stats,
	creature = { mode = "ground", radius = 1.1, turnRate = 360, cooldown = 0.7, knock = 70, hop = 48, zigzag = 4, respawnDelay = 1.5 },
	sound = "Bubble",
	build = function(s)
		local colors = { Color3.fromRGB(255, 250, 225), Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 245, 200) }
		local m = Models.Blob(1.1 * s, colors[math.random(1, #colors)])
		local root = m.PrimaryPart :: BasePart
		Models.add(m, Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5) * s, Color3.fromRGB(255, 250, 230), CFrame.new(0.7 * s, 0.6 * s, 0))
		Models.add(m, Enum.PartType.Ball, Vector3.new(1.3, 1.3, 1.3) * s, Color3.fromRGB(255, 240, 190), CFrame.new(-0.6 * s, 0.5 * s, 0.4 * s))
		root.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0, 0.9, 100, 100)
		return m
	end,
}

function Recipe.Spawn(ctx)
	-- first a few flaming chickens appear and POP
	local chickens = {}
	for _ = 1, 6 do
		local p = ctx:randomOpenPoint()
		local m = Models.Chickens(1.3)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
		m:PivotTo(CFrame.new(p + Vector3.new(0, 1.6, 0)))
		local f = Instance.new("Fire")
		f.Parent = m.PrimaryPart
		m.Parent = ctx.folder
		table.insert(chickens, m)
	end
	task.wait(1.5)
	for _, m in ipairs(chickens) do
		local pos = m:GetPivot().Position
		ctx:explode(pos, 8, 10, { knock = 40 })
		m:Destroy()
	end
	CreatureRunner.run(ctx, Kernel)
end

return Recipe
