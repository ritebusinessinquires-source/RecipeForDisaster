-- Disco Inferno: Lava + Bouncy + any Spice. The lava floor bounces in rhythm with the music.
local Recipe = {
	id = "DiscoInferno",
	name = "Disco Inferno",
	emoji = "🪩",
	main = "Lava",
	spices = { "Bouncy" },
	anySpice = true,
	type = "Terrain",
	desc = "The lava floor bounces in rhythm with the music.",
	hint = { text = "Dance to the beat - jump off the glowing tiles!", icon = "run" },
	stats = { Size = 1, Speed = 1, Count = 1, Damage = 22, Health = 1 },
}

local DISCO = {
	Color3.fromRGB(255, 70, 170),
	Color3.fromRGB(70, 220, 255),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(150, 90, 255),
}

local PATTERNS = {
	function(t, beat) return (t.gx + t.gz + beat) % 2 == 0 end,
	function(t, beat) return (t.gx + beat) % 3 == 0 end,
	function(t, beat) return (t.gz + beat) % 3 == 0 end,
	function(t, beat) return math.floor(math.sqrt(t.gx * t.gx + t.gz * t.gz) + beat) % 3 == 0 end,
}

function Recipe.Spawn(ctx)
	local tiles = ctx.tiles
	if not tiles then
		return
	end
	local dishId = ctx.dish.id
	local beat = 0
	local pattern = PATTERNS[1]
	ctx:fx("Music", { style = "disco", on = true })
	ctx:onCleanup(function()
		ctx:fx("Music", { style = "disco", on = false })
		for _, t in ipairs(tiles.list) do
			if t.hazardOwner == dishId or t.visual == "disco" then
				t.visual = "?"
				tiles:setHazard(t, nil)
			end
		end
	end)
	local function paintDisco()
		for _, t in ipairs(tiles.list) do
			if not t.hazard or t.hazardOwner == dishId then
				t.part.Color = DISCO[((t.gx * 3 + t.gz + beat) % #DISCO) + 1]
				t.part.Material = Enum.Material.Neon
				t.visual = "disco"
			end
		end
	end
	paintDisco()
	task.spawn(function()
		while ctx.alive do
			local period = ctx.rampMult > 1 and 0.85 or 1.2
			beat += 1
			if beat % 8 == 0 then
				pattern = PATTERNS[ctx.rng:NextInteger(1, #PATTERNS)]
			end
			-- warn: the tiles that will turn to lava flash white first
			local next = {}
			for _, t in ipairs(tiles.list) do
				if (t.hazard == nil or t.hazardOwner == dishId) and pattern(t, beat) then
					table.insert(next, t)
				end
			end
			for _, t in ipairs(tiles.list) do
				if t.hazardOwner == dishId then
					tiles:setHazard(t, nil)
				end
			end
			paintDisco()
			for _, t in ipairs(next) do
				t.part.Color = Color3.fromRGB(255, 255, 255)
			end
			ctx:fx("Beat", {})
			task.wait(period * 0.45)
			if not ctx.alive then
				break
			end
			for _, t in ipairs(next) do
				tiles:setHazard(t, "lava", dishId, 1)
			end
			task.wait(period * 0.55)
		end
	end)
	local TerrainRunner = require(game:GetService("ServerStorage").HazardLib.TerrainRunner)
	ctx:loop(0.1, function(dt)
		for _, target in ipairs(ctx:targets()) do
			local t = TerrainRunner.tileUnder(ctx, target.root)
			if t and t.hazardOwner == dishId then
				ctx:damage(target, ctx.stats.Damage * dt)
				if ctx.rng:NextNumber() < 0.25 then
					ctx:knockback(target, Vector3.new(0, 60, 0))
				end
			end
		end
	end)
end

return Recipe
