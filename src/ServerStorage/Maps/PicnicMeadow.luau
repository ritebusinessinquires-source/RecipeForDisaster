-- Picnic Meadow: a grassy field with gentle rolling hills and a big picnic blanket in the
-- middle. Raised spots: two small rocky hilltops. Low cover: scattered boulders and a fallen
-- log. Water: a pond on one side. Slopes make rolling Projectiles curve and speed up.

local Builder = require(script.Parent.Builder)

local PicnicMeadow = { id = "PicnicMeadow" }

local HALF = 125
local POND = { minX = -122, maxX = -78, minZ = -30, maxZ = 40 }

local function inPond(x: number, z: number): boolean
	return x > POND.minX and x < POND.maxX and z > POND.minZ and z < POND.maxZ
end

local function inBlanket(x: number, z: number): boolean
	return math.abs(x - 5) < 30 and math.abs(z - 5) < 30
end

function PicnicMeadow.build(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "PicnicMeadow"
	local b = Builder.new(model)
	local rng = Random.new(7)

	local tileParts, tileFolder = b:tiles({
		half = HALF,
		include = function(x, z)
			return not inPond(x, z)
		end,
		look = function(x, z, gx, gz)
			if inBlanket(x, z) then
				-- red & white checkered picnic blanket
				return ((gx + gz) % 2 == 0) and "#E84A3A" or "#FFF4DC", Enum.Material.Fabric
			end
			local shade = ((gx * 7 + gz * 13) % 3)
			local colors = { "#7BC96F", "#74C267", "#82CF75" }
			return colors[shade + 1], Enum.Material.Grass
		end,
	})

	-- soil underneath
	local E = HALF + 3
	local function soil(minX, maxX, minZ, maxZ)
		b:block(Vector3.new(maxX - minX, 14, maxZ - minZ), Vector3.new((minX + maxX) / 2, -9, (minZ + maxZ) / 2), "#7A5A3A", Enum.Material.Ground, nil, "Soil")
	end
	soil(-E, POND.minX, -E, E)
	soil(POND.maxX, E, -E, E)
	soil(POND.minX, POND.maxX, -E, POND.minZ)
	soil(POND.minX, POND.maxX, POND.maxZ, E)
	local pc = Vector3.new((POND.minX + POND.maxX) / 2, 0, (POND.minZ + POND.maxZ) / 2)
	local pw, pd = POND.maxX - POND.minX, POND.maxZ - POND.minZ
	b:block(Vector3.new(pw, 6, pd), Vector3.new(pc.X, -13, pc.Z), "#6B5A3A", Enum.Material.Mud, nil, "PondBed")
	-- reeds & lily pads
	for _ = 1, 8 do
		local x = rng:NextNumber(POND.minX + 2, POND.maxX - 2)
		local z = rng:NextNumber(POND.minZ + 2, POND.maxZ - 2)
		local pad = b:cylinder(5, 0.3, Vector3.new(x, -1.2, z), "#4CAF50", Enum.Material.Grass)
		pad.CanCollide = false
		pad.CanQuery = false
	end
	for _ = 1, 10 do
		local edgeZ = rng:NextNumber() < 0.5 and POND.minZ + 1 or POND.maxZ - 1
		b:cylinder(0.6, rng:NextNumber(5, 8), Vector3.new(rng:NextNumber(POND.minX, POND.maxX), -1, edgeZ), "#5E8C3A", Enum.Material.Grass).CanQuery = false
	end

	local raised = b:folder("RaisedSpots")
	local cover = b:folder("LowCover")
	local decor = b:folder("Decor")

	-- gentle rolling hills: big domes sunk into the ground
	local hills = { { 60, -70, 150, 9 }, { -40, -75, 120, 7 }, { 70, 70, 140, 8 }, { -45, 85, 110, 6 } }
	for _, h in ipairs(hills) do
		local x, z, d, height = h[1], h[2], h[3], h[4]
		local hill = b:ball(d, Vector3.new(x, height - d / 2, z), "#74C267", Enum.Material.Grass, nil, "Hill")
		hill.Name = "Hill"
	end
	-- two small rocky hilltops (raised spots)
	local rocky = { { 60, -70, 9 }, { 70, 70, 8 } }
	for _, r in ipairs(rocky) do
		local x, z, top = r[1], r[2], r[3]
		b:cylinder(18, 4, Vector3.new(x, top - 1, z), "#8C8478", Enum.Material.Slate, raised, "RockTop")
		b:ball(9, Vector3.new(x + 6, top + 3, z - 4), "#9A9184", Enum.Material.Slate, raised, "Rock")
		b:ball(7, Vector3.new(x - 6, top + 2.5, z + 5), "#857D72", Enum.Material.Slate, raised, "Rock")
	end

	-- scattered boulders (low cover)
	local boulders = { { -10, -40 }, { 30, -20 }, { -60, 10 }, { 45, 30 }, { -25, 55 }, { 95, -15 }, { 100, 100 }, { -100, -95 }, { 10, -105 }, { -60, -30 }, { 50, 105 } }
	for _, p in ipairs(boulders) do
		local s = rng:NextNumber(4.5, 6)
		local rock = b:ball(s, Vector3.new(p[1], s * 0.35, p[2]), "#9A9184", Enum.Material.Slate, cover, "Boulder")
		rock.Size = Vector3.one * s
	end
	-- fallen log (low cover)
	b:log(4.5, 34, Vector3.new(-10, 2.2, -95), math.rad(15), "#7A5430", Enum.Material.Wood, cover, "FallenLog")
	b:cylinder(4.6, 0.2, Vector3.new(-26.5, 0, -99.5), "#C98E56", Enum.Material.Wood, decor).CFrame = CFrame.new(-26.4, 2.2, -99.5) * CFrame.Angles(0, math.rad(15), 0)

	-- the picnic: basket, plates, a cake (low cover on the blanket)
	b:block(Vector3.new(9, 4.5, 6), Vector3.new(-5, 2.25, -5), "#C98E56", Enum.Material.Wood, cover, "Basket")
	b:log(1, 9, Vector3.new(-5, 5.5, -5), 0, "#8E6239", Enum.Material.Wood, decor)
	b:cylinder(8, 0.6, Vector3.new(15, 0, 15), "#FFFFFF", Enum.Material.SmoothPlastic, decor)
	b:cylinder(8, 0.6, Vector3.new(-15, 0, 20), "#FFFFFF", Enum.Material.SmoothPlastic, decor)
	b:cylinder(7, 3.2, Vector3.new(18, 0, -15), "#FF8FB8", Enum.Material.SmoothPlastic, cover, "Cake")
	b:cylinder(7.4, 0.6, Vector3.new(18, 3.2, -15), "#FFF4DC", Enum.Material.SmoothPlastic, decor)
	b:ball(1.6, Vector3.new(18, 4.4, -15), "#E84A3A", Enum.Material.SmoothPlastic, decor)
	b:block(Vector3.new(1.2, 3.5, 1.2), Vector3.new(25, 1.75, 5), "#E84A3A", Enum.Material.Glass, decor).Transparency = 0.2

	-- hedges around the field (visible border) + invisible walls
	local walls = b:folder("Walls")
	for _, w in ipairs({
		{ Vector3.new(HALF * 2 + 8, 7, 4), Vector3.new(0, 3.5, HALF + 2) },
		{ Vector3.new(HALF * 2 + 8, 7, 4), Vector3.new(0, 3.5, -HALF - 2) },
		{ Vector3.new(4, 7, HALF * 2 + 8), Vector3.new(HALF + 2, 3.5, 0) },
		{ Vector3.new(4, 7, HALF * 2 + 8), Vector3.new(-HALF - 2, 3.5, 0) },
	}) do
		b:block(w[1], w[2], "#3F8F3A", Enum.Material.LeafyGrass, decor, "Hedge")
	end
	b:wall(Vector3.new(HALF * 2 + 20, 60, 4), Vector3.new(0, 30, HALF + 4), walls)
	b:wall(Vector3.new(HALF * 2 + 20, 60, 4), Vector3.new(0, 30, -HALF - 4), walls)
	b:wall(Vector3.new(4, 60, HALF * 2 + 20), Vector3.new(HALF + 4, 30, 0), walls)
	b:wall(Vector3.new(4, 60, HALF * 2 + 20), Vector3.new(-HALF - 4, 30, 0), walls)

	-- trees outside the hedge
	for i = 1, 22 do
		local a = i / 22 * math.pi * 2
		local r = HALF + 22 + rng:NextNumber(0, 18)
		local x, z = math.cos(a) * r, math.sin(a) * r
		if z < HALF + 10 or math.abs(x) > 60 then
			local h = rng:NextNumber(18, 30)
			b:cylinder(4, h, Vector3.new(x, -2, z), "#7A5430", Enum.Material.Wood, decor, "Trunk")
			b:ball(rng:NextNumber(16, 24), Vector3.new(x, h + 4, z), "#4E9F45", Enum.Material.LeafyGrass, decor, "Leaves")
		end
	end
	b:block(Vector3.new(700, 2, 700), Vector3.new(0, -17, 0), "#6DB761", Enum.Material.Grass, decor, "FarGround")

	model.Parent = parent

	local spawnPoints = {}
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		table.insert(spawnPoints, Vector3.new(math.cos(a) * 55 + 10, 5, math.sin(a) * 55))
	end

	return {
		id = "PicnicMeadow",
		model = model,
		floorY = 0,
		center = Vector3.new(0, 0, 0),
		shape = "square",
		bounds = { minX = -HALF, maxX = HALF, minZ = -HALF, maxZ = HALF },
		tileParts = tileParts,
		tileFolder = tileFolder,
		tileSize = 10,
		water = { center = Vector3.new(pc.X, -5, pc.Z), size = Vector3.new(pw, 10, pd), surfaceY = -0.8, bottomY = -10 },
		spawnPoints = spawnPoints,
		killY = -60,
		edgeDeath = false,
		waterColor = Color3.fromRGB(60, 150, 170),
	}
end

return PicnicMeadow
