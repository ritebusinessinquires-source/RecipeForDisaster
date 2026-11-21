-- Pizza Planet: a giant round pizza floating in the sky. Raised spots: the crust around the
-- edge. Low cover: pepperoni bumps and olive slices. Water: a tomato-sauce puddle in the
-- centre. No walls: falling off the edge eliminates you.

local Builder = require(script.Parent.Builder)

local PizzaPlanet = { id = "PizzaPlanet" }

local R = 125
local SAUCE_R = 20

function PizzaPlanet.build(parent: Instance)
	local model = Instance.new("Model")
	model.Name = "PizzaPlanet"
	local b = Builder.new(model)
	local rng = Random.new(11)

	local tileParts, tileFolder = b:tiles({
		half = R,
		include = function(x, z)
			local d = math.sqrt(x * x + z * z)
			return d < R - 9 and d > SAUCE_R + 2
		end,
		look = function(x, z, gx, gz)
			local shade = (gx * 5 + gz * 3) % 4
			local colors = { "#F4C26B", "#F2BA5E", "#F6C977", "#F0B455" }
			return colors[shade + 1], Enum.Material.SmoothPlastic
		end,
	})

	-- the dough underneath
	local base = b:part(Enum.PartType.Cylinder, Vector3.new(6, R * 2 + 4, R * 2 + 4), CFrame.new(0, -5, 0) * CFrame.Angles(0, 0, math.rad(90)), "#E0A44A", Enum.Material.Sand, nil, "Dough")
	base.CanQuery = true
	-- the sauce puddle bottom (the puddle itself is terrain water tinted red)
	b:part(Enum.PartType.Cylinder, Vector3.new(0.4, SAUCE_R * 2 + 2, SAUCE_R * 2 + 2), CFrame.new(0, -1.8, 0) * CFrame.Angles(0, 0, math.rad(90)), "#B23A26", Enum.Material.SmoothPlastic, nil, "SauceBed")

	local raised = b:folder("RaisedSpots")
	local cover = b:folder("LowCover")
	local decor = b:folder("Decor")

	-- crust ring (raised spots) around the edge
	local segments = 56
	for i = 0, segments - 1 do
		local a = i / segments * math.pi * 2
		local mid = R - 5.5
		local len = (2 * math.pi * mid) / segments + 0.6
		local cf = CFrame.new(math.cos(a) * mid, 2, math.sin(a) * mid) * CFrame.Angles(0, -a, 0)
		local seg = b:block(Vector3.new(9, 4, len), cf, (i % 2 == 0) and "#D9913F" or "#CF8838", Enum.Material.Sand, raised, "Crust")
		seg.Name = "Crust"
	end

	-- a low rim of sauce around the puddle
	for i = 0, 23 do
		local a = i / 24 * math.pi * 2
		local cf = CFrame.new(math.cos(a) * (SAUCE_R + 1.5), 0.25, math.sin(a) * (SAUCE_R + 1.5)) * CFrame.Angles(0, -a, 0)
		local rim = b:block(Vector3.new(2.5, 0.5, 6.2), cf, "#C8432F", Enum.Material.SmoothPlastic, decor, "SauceRim")
		rim.CanCollide = false
	end

	-- pepperoni bumps (low cover)
	local placed = {}
	local function free(x, z, r)
		for _, p in ipairs(placed) do
			if (Vector2.new(x, z) - p.pos).Magnitude < r + p.r + 4 then
				return false
			end
		end
		return true
	end
	local tries = 0
	while #placed < 16 and tries < 400 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(SAUCE_R + 15, R - 22)
		local x, z = math.cos(a) * d, math.sin(a) * d
		if free(x, z, 6) then
			table.insert(placed, { pos = Vector2.new(x, z), r = 6 })
			b:cylinder(12, 2.6, Vector3.new(x, 0, z), "#C8432F", Enum.Material.SmoothPlastic, cover, "Pepperoni")
			b:cylinder(3, 0.3, Vector3.new(x + 2, 2.6, z - 1), "#A8321F", Enum.Material.SmoothPlastic, decor)
		end
	end
	-- olive slices (low cover)
	tries = 0
	local olives = 0
	while olives < 14 and tries < 400 do
		tries += 1
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(SAUCE_R + 10, R - 18)
		local x, z = math.cos(a) * d, math.sin(a) * d
		if free(x, z, 3) then
			table.insert(placed, { pos = Vector2.new(x, z), r = 3 })
			olives += 1
			b:cylinder(6, 2.2, Vector3.new(x, 0, z), "#2E2A2A", Enum.Material.SmoothPlastic, cover, "Olive")
			b:cylinder(2.4, 2.3, Vector3.new(x, 0, z), "#F4C26B", Enum.Material.SmoothPlastic, decor)
		end
	end
	-- basil leaves (decor, flat)
	for _ = 1, 8 do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(SAUCE_R + 10, R - 20)
		local leaf = b:block(Vector3.new(7, 0.2, 4), CFrame.new(math.cos(a) * d, 0.1, math.sin(a) * d) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), "#4CAF50", Enum.Material.Grass, decor, "Basil")
		leaf.CanCollide = false
		leaf.CanQuery = false
	end

	-- clouds far below
	for _ = 1, 14 do
		local x, z = rng:NextNumber(-300, 300), rng:NextNumber(-300, 300)
		local c = b:ball(rng:NextNumber(30, 60), Vector3.new(x, rng:NextNumber(-140, -90), z), "#FFFFFF", Enum.Material.SmoothPlastic, decor, "Cloud")
		c.CanCollide = false
		c.CanQuery = false
		c.Transparency = 0.15
	end

	model.Parent = parent

	local spawnPoints = {}
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		table.insert(spawnPoints, Vector3.new(math.cos(a) * 65, 4, math.sin(a) * 65))
	end

	return {
		id = "PizzaPlanet",
		model = model,
		floorY = 0,
		center = Vector3.new(0, 0, 0),
		shape = "circle",
		radius = R - 2,
		bounds = { minX = -R, maxX = R, minZ = -R, maxZ = R },
		tileParts = tileParts,
		tileFolder = tileFolder,
		tileSize = 10,
		water = { center = Vector3.new(0, -1.2, 0), size = Vector3.new(SAUCE_R * 2, 2, SAUCE_R * 2), surfaceY = -0.4, bottomY = -1.6, circle = true, radius = SAUCE_R },
		spawnPoints = spawnPoints,
		killY = -45,
		edgeDeath = true,
		waterColor = Color3.fromRGB(200, 60, 40),
	}
end

return PizzaPlanet
