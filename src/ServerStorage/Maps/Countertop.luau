-- The Countertop: a huge flat kitchen counter seen from the size of a mouse.
-- Raised spots: stacked plates, a cutting board. Low cover: spilled cereal, salt & pepper
-- shakers. Water: a sink basin along one edge. The flattest, most readable map.

local Builder = require(script.Parent.Builder)

local Countertop = { id = "Countertop" }

local HALF = 125
local SINK = { minX = 82, maxX = 122, minZ = -45, maxZ = 45 } -- the sink cut-out (no tiles)

local function inSink(x: number, z: number): boolean
	return x > SINK.minX and x < SINK.maxX and z > SINK.minZ and z < SINK.maxZ
end

function Countertop.build(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Countertop"
	local b = Builder.new(model)

	-- counter surface: big pale tiles with a subtle grid
	local tileParts, tileFolder = b:tiles({
		half = HALF,
		include = function(x, z)
			return not inSink(x, z)
		end,
		look = function(x, z, gx, gz)
			local even = (gx + gz) % 2 == 0
			return even and "#EEE6D3" or "#E6DCC6", Enum.Material.Marble
		end,
	})

	-- counter body underneath + front edge trim
	local function body(minX, maxX, minZ, maxZ)
		b:block(Vector3.new(maxX - minX, 16, maxZ - minZ), Vector3.new((minX + maxX) / 2, -10, (minZ + maxZ) / 2), "#B88A5A", Enum.Material.Wood, nil, "CounterBody")
	end
	local E = HALF + 3
	body(-E, SINK.minX, -E, E)
	body(SINK.maxX, E, -E, E)
	body(SINK.minX, SINK.maxX, -E, SINK.minZ)
	body(SINK.minX, SINK.maxX, SINK.maxZ, E)
	b:block(Vector3.new(SINK.maxX - SINK.minX, 8, SINK.maxZ - SINK.minZ), Vector3.new((SINK.minX + SINK.maxX) / 2, -12, 0), "#B88A5A", Enum.Material.Wood, nil, "CounterBody")
	b:block(Vector3.new(HALF * 2 + 6, 1.2, 3), Vector3.new(0, 0.4, HALF + 1.5), "#C9B79C", Enum.Material.Marble)
	b:block(Vector3.new(3, 1.2, HALF * 2 + 6), Vector3.new(-HALF - 1.5, 0.4, 0), "#C9B79C", Enum.Material.Marble)
	b:block(Vector3.new(3, 1.2, HALF * 2 + 6), Vector3.new(HALF + 1.5, 0.4, 0), "#C9B79C", Enum.Material.Marble)

	-- backsplash wall (north) with subway tiles
	local splash = b:block(Vector3.new(HALF * 2 + 6, 70, 4), Vector3.new(0, 35, -HALF - 2), "#FAFAF7", Enum.Material.Brick)
	splash.Name = "Backsplash"
	for i = -5, 5 do
		b:block(Vector3.new(16, 30, 2), Vector3.new(i * 22, 52, -HALF + 0.5), "#5DA9E9", Enum.Material.SmoothPlastic).Transparency = 0.1
	end

	-- sink basin (water) along the east edge
	local sinkCenter = Vector3.new((SINK.minX + SINK.maxX) / 2, 0, (SINK.minZ + SINK.maxZ) / 2)
	local sw, sd = SINK.maxX - SINK.minX, SINK.maxZ - SINK.minZ
	b:block(Vector3.new(sw, 1, sd), Vector3.new(sinkCenter.X, -7.5, sinkCenter.Z), "#AEB6BF", Enum.Material.Metal, nil, "SinkFloor")
	b:block(Vector3.new(sw, 7, 1), Vector3.new(sinkCenter.X, -3.5, SINK.minZ), "#AEB6BF", Enum.Material.Metal)
	b:block(Vector3.new(sw, 7, 1), Vector3.new(sinkCenter.X, -3.5, SINK.maxZ), "#AEB6BF", Enum.Material.Metal)
	b:block(Vector3.new(1, 7, sd), Vector3.new(SINK.minX, -3.5, sinkCenter.Z), "#AEB6BF", Enum.Material.Metal)
	b:block(Vector3.new(1, 7, sd), Vector3.new(SINK.maxX, -3.5, sinkCenter.Z), "#AEB6BF", Enum.Material.Metal)
	-- sink rim
	b:block(Vector3.new(sw + 4, 0.6, 2), Vector3.new(sinkCenter.X, 0.3, SINK.minZ - 1), "#C7CED6", Enum.Material.Metal)
	b:block(Vector3.new(sw + 4, 0.6, 2), Vector3.new(sinkCenter.X, 0.3, SINK.maxZ + 1), "#C7CED6", Enum.Material.Metal)
	b:block(Vector3.new(2, 0.6, sd), Vector3.new(SINK.minX - 1, 0.3, sinkCenter.Z), "#C7CED6", Enum.Material.Metal)
	-- faucet (decoration, outside the play area)
	b:cylinder(4, 26, Vector3.new(HALF + 4, 0, 0), "#C7CED6", Enum.Material.Metal)
	b:log(3, 18, Vector3.new(HALF - 4, 25, 0), 0, "#C7CED6", Enum.Material.Metal)
	b:cylinder(3.4, 4, Vector3.new(HALF - 12, 21, 0), "#C7CED6", Enum.Material.Metal)

	local raised = b:folder("RaisedSpots")
	local cover = b:folder("LowCover")
	local decor = b:folder("Decor")

	-- stacked plates (raised spots): stacks of 3 to 6 plates
	local plateStacks = { { -70, -60, 3 }, { -15, -85, 4 }, { 40, -55, 5 }, { -85, 40, 4 }, { 20, 70, 6 }, { -30, 15, 3 } }
	for _, s in ipairs(plateStacks) do
		local x, z, n = s[1], s[2], s[3]
		local y = 0
		for i = 1, n do
			b:cylinder(16 - (i % 2) * 0.6, 1.2, Vector3.new(x, y, z), i % 2 == 0 and "#FFFFFF" or "#F2F0EA", Enum.Material.SmoothPlastic, raised, "Plate")
			y += 1.2
		end
		b:cylinder(10, 0.25, Vector3.new(x, y, z), "#E84A3A", Enum.Material.SmoothPlastic, decor)
		-- a step so you can get up the tall ones
		if n >= 5 then
			b:cylinder(7, 2.6, Vector3.new(x + 9, 0, z + 2), "#F2F0EA", Enum.Material.SmoothPlastic, raised, "StepPlate")
		end
	end

	-- cutting board (big step-up platform)
	b:block(Vector3.new(36, 3, 24), Vector3.new(-5, 1.5, 45), "#C98E56", Enum.Material.Wood, raised, "CuttingBoard")
	b:block(Vector3.new(14, 1.8, 10), Vector3.new(19, 0.9, 45), "#B97F48", Enum.Material.Wood, raised, "BoardStep")
	b:cylinder(4, 1, Vector3.new(-18, 3, 50), "#7A5430", Enum.Material.Wood, decor)
	-- a giant knife lying on the board
	b:block(Vector3.new(20, 0.5, 3), Vector3.new(-2, 3.25, 38), "#D8DEE4", Enum.Material.Metal, decor)
	b:block(Vector3.new(8, 1.2, 2.6), Vector3.new(13, 3.6, 38), "#2B2B2B", Enum.Material.SmoothPlastic, decor)

	-- salt & pepper shakers knocked over (low cover)
	b:log(5, 9, Vector3.new(55, 2.5, 15), math.rad(30), "#FFFFFF", Enum.Material.Glass, cover, "Salt")
	b:log(5, 9, Vector3.new(63, 2.5, 25), math.rad(80), "#3B3B3B", Enum.Material.Glass, cover, "Pepper")
	b:log(5, 9, Vector3.new(-60, 2.5, -15), math.rad(-20), "#FFFFFF", Enum.Material.Glass, cover, "Salt")
	b:log(5, 9, Vector3.new(-100, 2.5, -90), math.rad(10), "#3B3B3B", Enum.Material.Glass, cover, "Pepper")

	-- spilled cereal (low cover): little rings in clusters
	local cerealColors = { "#F4C26B", "#E8A84A", "#E84A3A", "#FFC93C", "#7B4FD6", "#4CAF50" }
	local rng = Random.new(42)
	local clusters = { { 10, -20 }, { -45, 75 }, { 70, -95 }, { -100, -40 }, { 60, 95 }, { -10, 100 }, { 30, -5 } }
	for _, c in ipairs(clusters) do
		for _ = 1, 5 do
			local x = c[1] + rng:NextNumber(-9, 9)
			local z = c[2] + rng:NextNumber(-9, 9)
			local ring = b:cylinder(4.6, 2.6, Vector3.new(x, 0, z), cerealColors[rng:NextInteger(1, #cerealColors)], Enum.Material.Sand, cover, "Cereal")
			ring.CFrame = ring.CFrame * CFrame.Angles(rng:NextNumber(-0.15, 0.15), 0, 0)
		end
	end

	-- a leaning cereal box in the north-west corner (decor)
	b:block(Vector3.new(30, 50, 12), CFrame.new(-100, 24, -112) * CFrame.Angles(0, 0, math.rad(-6)), "#E84A3A", Enum.Material.SmoothPlastic, decor, "CerealBox")
	b:block(Vector3.new(22, 14, 0.5), CFrame.new(-100, 34, -105.8) * CFrame.Angles(0, 0, math.rad(-6)), "#FFC93C", Enum.Material.SmoothPlastic, decor)
	-- a jar and a toaster against the backsplash
	b:cylinder(18, 34, Vector3.new(70, 0, -108), "#CDEBFF", Enum.Material.Glass, decor, "Jar").Transparency = 0.4
	b:cylinder(19, 3, Vector3.new(70, 34, -108), "#E84A3A", Enum.Material.SmoothPlastic, decor)
	b:block(Vector3.new(34, 24, 18), Vector3.new(10, 12, -110), "#D8DEE4", Enum.Material.Metal, decor, "Toaster")
	b:block(Vector3.new(26, 1, 4), Vector3.new(10, 24.2, -113), "#2B2B2B", Enum.Material.SmoothPlastic, decor)
	b:block(Vector3.new(26, 1, 4), Vector3.new(10, 24.2, -107), "#2B2B2B", Enum.Material.SmoothPlastic, decor)

	-- invisible walls (no falling off the counter)
	local walls = b:folder("Walls")
	b:wall(Vector3.new(HALF * 2 + 20, 60, 4), Vector3.new(0, 30, HALF + 3), walls)
	b:wall(Vector3.new(4, 60, HALF * 2 + 20), Vector3.new(-HALF - 3, 30, 0), walls)
	b:wall(Vector3.new(4, 60, HALF * 2 + 20), Vector3.new(HALF + 3, 30, 0), walls)

	model.Parent = parent

	local spawnPoints = {}
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		table.insert(spawnPoints, Vector3.new(math.cos(a) * 60 - 10, 4, math.sin(a) * 60))
	end

	return {
		id = "Countertop",
		model = model,
		floorY = 0,
		center = Vector3.new(0, 0, 0),
		shape = "square",
		bounds = { minX = -HALF, maxX = HALF, minZ = -HALF, maxZ = HALF },
		tileParts = tileParts,
		tileFolder = tileFolder,
		tileSize = 10,
		water = { center = Vector3.new(sinkCenter.X, -3.5, sinkCenter.Z), size = Vector3.new(sw - 1, 7, sd - 1), surfaceY = -0.8, bottomY = -7 },
		spawnPoints = spawnPoints,
		killY = -60,
		edgeDeath = false,
		waterColor = Color3.fromRGB(70, 150, 210),
	}
end

return Countertop
