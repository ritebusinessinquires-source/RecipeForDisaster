-- Procedural hazard models built from parts. Every model has an invisible ball "Root"
-- (PrimaryPart) with the visual parts welded to it, so movers only drive the root.

local Models = {}

local function newPart(shape: Enum.PartType?, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = true
	return p
end
Models.newPart = newPart

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- Creates the model + root. radius = collision radius in studs.
function Models.base(name: string, radius: number, collide: boolean?): (Model, Part)
	local model = Instance.new("Model")
	model.Name = name
	local root = newPart(Enum.PartType.Ball, Vector3.one * (radius * 2), Color3.new(1, 1, 1))
	root.Name = "Root"
	root.Transparency = 1
	root.Massless = false
	root.CanCollide = collide == true
	root.CanQuery = false
	root.CastShadow = false
	root.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0, 100, 100)
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root
	return model, root
end

-- Adds a visual part at an offset from the root (root sits at origin while building).
function Models.add(model: Model, shape: Enum.PartType?, size: Vector3, color: Color3, offset: CFrame, material: Enum.Material?, name: string?): Part
	local root = model.PrimaryPart :: BasePart
	local p = newPart(shape, size, color, material)
	p.Name = name or "Part"
	p.CFrame = root.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end

local Ball, Block, Cyl, Wedge = Enum.PartType.Ball, Enum.PartType.Block, Enum.PartType.Cylinder, Enum.PartType.Wedge
local Neon = Enum.Material.Neon

local function eyes(model: Model, s: number, y: number, z: number, spread: number, size: number)
	Models.add(model, Ball, Vector3.one * size * s, rgb(255, 255, 255), CFrame.new(-spread * s, y * s, z * s))
	Models.add(model, Ball, Vector3.one * size * s, rgb(255, 255, 255), CFrame.new(spread * s, y * s, z * s))
	Models.add(model, Ball, Vector3.one * size * 0.55 * s, rgb(20, 16, 12), CFrame.new(-spread * s, y * s, (z - size * 0.3) * s))
	Models.add(model, Ball, Vector3.one * size * 0.55 * s, rgb(20, 16, 12), CFrame.new(spread * s, y * s, (z - size * 0.3) * s))
end

-- Models face -Z (CFrame.lookAt convention).

function Models.Bees(s: number): Model
	local m = Models.base("Bee", 1.3 * s)
	Models.add(m, Ball, Vector3.new(2.2, 2.2, 2.2) * s, rgb(255, 201, 60), CFrame.new(0, 0, 0), nil, "Body")
	-- stripes: rings just wider than the body's cross-section at that point, so they wrap it
	Models.add(m, Cyl, Vector3.new(0.32, 2.24, 2.24) * s, rgb(40, 30, 20), CFrame.new(0, 0, 0.12 * s) * CFrame.Angles(0, math.rad(90), 0))
	Models.add(m, Cyl, Vector3.new(0.3, 1.84, 1.84) * s, rgb(40, 30, 20), CFrame.new(0, 0, 0.62 * s) * CFrame.Angles(0, math.rad(90), 0))
	Models.add(m, Ball, Vector3.new(1.4, 1.4, 1.4) * s, rgb(40, 30, 20), CFrame.new(0, 0.2 * s, -1.2 * s), nil, "Head")
	eyes(m, s, 0.45, -1.75, 0.35, 0.45)
	local wingColor = rgb(220, 240, 255)
	local w1 = Models.add(m, Block, Vector3.new(1.8, 0.1, 1.0) * s, wingColor, CFrame.new(-1.0 * s, 1.0 * s, 0.2 * s) * CFrame.Angles(0, 0, math.rad(25)))
	local w2 = Models.add(m, Block, Vector3.new(1.8, 0.1, 1.0) * s, wingColor, CFrame.new(1.0 * s, 1.0 * s, 0.2 * s) * CFrame.Angles(0, 0, math.rad(-25)))
	w1.Transparency, w2.Transparency = 0.35, 0.35
	Models.add(m, Wedge, Vector3.new(0.3, 0.5, 0.8) * s, rgb(30, 20, 15), CFrame.new(0, -0.2 * s, 1.5 * s))
	return m
end

function Models.Zombies(s: number): Model
	local m = Models.base("Zombie", 1.5 * s, true)
	local skin, shirt, pants = rgb(120, 180, 90), rgb(90, 120, 160), rgb(70, 60, 90)
	Models.add(m, Block, Vector3.new(2, 2, 1) * s, shirt, CFrame.new(0, 0.95 * s, 0), nil, "Torso")
	Models.add(m, Block, Vector3.new(1.3, 1.3, 1.3) * s, skin, CFrame.new(0, 2.6 * s, 0), nil, "Head")
	eyes(m, s, 2.75, -0.66, 0.3, 0.35)
	Models.add(m, Block, Vector3.new(0.5, 0.15, 0.1) * s, rgb(60, 20, 20), CFrame.new(0, 2.3 * s, -0.66 * s))
	Models.add(m, Block, Vector3.new(0.8, 0.8, 2.2) * s, skin, CFrame.new(-1.4 * s, 1.55 * s, -1.0 * s))
	Models.add(m, Block, Vector3.new(0.8, 0.8, 2.2) * s, skin, CFrame.new(1.4 * s, 1.55 * s, -1.0 * s))
	Models.add(m, Block, Vector3.new(0.9, 1.4, 0.9) * s, pants, CFrame.new(-0.5 * s, -0.75 * s, 0))
	Models.add(m, Block, Vector3.new(0.9, 1.4, 0.9) * s, pants, CFrame.new(0.5 * s, -0.75 * s, 0))
	return m
end

function Models.Chickens(s: number): Model
	local m = Models.base("Chicken", 1.1 * s, true)
	Models.add(m, Ball, Vector3.new(2.2, 2.2, 2.2) * s, rgb(250, 250, 245), CFrame.new(0, 0.5 * s, 0.2 * s), nil, "Body")
	Models.add(m, Ball, Vector3.new(1.3, 1.3, 1.3) * s, rgb(250, 250, 245), CFrame.new(0, 1.7 * s, -0.7 * s), nil, "Head")
	Models.add(m, Block, Vector3.new(0.3, 0.6, 0.8) * s, rgb(232, 74, 58), CFrame.new(0, 2.45 * s, -0.7 * s))
	Models.add(m, Wedge, Vector3.new(0.4, 0.35, 0.6) * s, rgb(255, 180, 40), CFrame.new(0, 1.6 * s, -1.45 * s) * CFrame.Angles(math.rad(90), 0, 0))
	eyes(m, s, 1.9, -1.2, 0.3, 0.3)
	Models.add(m, Block, Vector3.new(0.6, 1.2, 1.4) * s, rgb(235, 235, 230), CFrame.new(-1.1 * s, 0.6 * s, 0.2 * s))
	Models.add(m, Block, Vector3.new(0.6, 1.2, 1.4) * s, rgb(235, 235, 230), CFrame.new(1.1 * s, 0.6 * s, 0.2 * s))
	Models.add(m, Block, Vector3.new(0.2, 0.9, 0.2) * s, rgb(255, 180, 40), CFrame.new(-0.4 * s, -0.7 * s, 0.1 * s))
	Models.add(m, Block, Vector3.new(0.2, 0.9, 0.2) * s, rgb(255, 180, 40), CFrame.new(0.4 * s, -0.7 * s, 0.1 * s))
	return m
end

function Models.Sharks(s: number): Model
	local m = Models.base("Shark", 1.6 * s)
	local grey = rgb(120, 135, 150)
	Models.add(m, Ball, Vector3.new(2.6, 2.2, 6.5) * s, grey, CFrame.new(0, -0.4 * s, 0), nil, "Body")
	Models.add(m, Wedge, Vector3.new(0.4, 2.2, 2.0) * s, grey, CFrame.new(0, 1.6 * s, 0.4 * s), nil, "Fin")
	Models.add(m, Wedge, Vector3.new(0.4, 1.8, 1.4) * s, grey, CFrame.new(0, 0.3 * s, 3.6 * s) * CFrame.Angles(0, math.rad(180), 0))
	Models.add(m, Block, Vector3.new(1.6, 0.2, 0.6) * s, rgb(240, 240, 240), CFrame.new(0, -0.9 * s, -2.6 * s))
	eyes(m, s, 0.0, -2.4, 0.9, 0.35)
	return m
end

function Models.Robots(s: number): Model
	local m = Models.base("Robot", 1.6 * s, true)
	local metal = rgb(170, 180, 190)
	Models.add(m, Block, Vector3.new(2.4, 2.2, 1.6) * s, metal, CFrame.new(0, 0.6 * s, 0), Enum.Material.DiamondPlate, "Torso")
	Models.add(m, Block, Vector3.new(1.6, 1.3, 1.4) * s, metal, CFrame.new(0, 2.4 * s, 0), Enum.Material.Metal, "Head")
	Models.add(m, Block, Vector3.new(1.3, 0.35, 0.1) * s, rgb(255, 40, 40), CFrame.new(0, 2.5 * s, -0.72 * s), Neon, "Visor")
	Models.add(m, Cyl, Vector3.new(1.2, 0.15, 0.15) * s, rgb(60, 60, 60), CFrame.new(0, 3.5 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	Models.add(m, Ball, Vector3.new(0.4, 0.4, 0.4) * s, rgb(255, 201, 60), CFrame.new(0, 4.15 * s, 0), Neon)
	Models.add(m, Block, Vector3.new(0.6, 0.6, 1.8) * s, rgb(90, 95, 105), CFrame.new(-1.5 * s, 0.9 * s, -0.6 * s), nil, "Gun")
	Models.add(m, Block, Vector3.new(0.6, 0.6, 1.8) * s, rgb(90, 95, 105), CFrame.new(1.5 * s, 0.9 * s, -0.6 * s))
	Models.add(m, Block, Vector3.new(0.8, 1.0, 2.0) * s, rgb(60, 60, 70), CFrame.new(-0.7 * s, -1.1 * s, 0))
	Models.add(m, Block, Vector3.new(0.8, 1.0, 2.0) * s, rgb(60, 60, 70), CFrame.new(0.7 * s, -1.1 * s, 0))
	return m
end

function Models.Ghosts(s: number): Model
	local m = Models.base("Ghost", 1.6 * s)
	local c = rgb(240, 240, 255)
	local body = Models.add(m, Ball, Vector3.new(3, 3, 3) * s, c, CFrame.new(0, 0.6 * s, 0), nil, "Body")
	local tail = Models.add(m, Cyl, Vector3.new(2.2, 2.9, 2.9) * s, c, CFrame.new(0, -0.6 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	body.Transparency, tail.Transparency = 0.25, 0.25
	Models.add(m, Ball, Vector3.new(0.6, 0.8, 0.3) * s, rgb(20, 16, 30), CFrame.new(-0.5 * s, 0.9 * s, -1.35 * s))
	Models.add(m, Ball, Vector3.new(0.6, 0.8, 0.3) * s, rgb(20, 16, 30), CFrame.new(0.5 * s, 0.9 * s, -1.35 * s))
	Models.add(m, Ball, Vector3.new(0.7, 0.5, 0.3) * s, rgb(20, 16, 30), CFrame.new(0, 0.1 * s, -1.4 * s))
	local light = Instance.new("PointLight")
	light.Color = rgb(180, 160, 255)
	light.Range = 10 * s
	light.Brightness = 1
	light.Parent = body
	return m
end

function Models.Snowmen(s: number): Model
	local m = Models.base("Snowman", 1.6 * s, true)
	local snow = rgb(245, 250, 255)
	Models.add(m, Ball, Vector3.new(3.2, 3.2, 3.2) * s, snow, CFrame.new(0, 0, 0), Enum.Material.Snow)
	Models.add(m, Ball, Vector3.new(2.4, 2.4, 2.4) * s, snow, CFrame.new(0, 2.4 * s, 0), Enum.Material.Snow)
	Models.add(m, Ball, Vector3.new(1.7, 1.7, 1.7) * s, snow, CFrame.new(0, 4.2 * s, 0), Enum.Material.Snow, "Head")
	Models.add(m, Wedge, Vector3.new(0.3, 0.3, 1.0) * s, rgb(255, 140, 30), CFrame.new(0, 4.2 * s, -1.2 * s) * CFrame.Angles(0, math.rad(180), 0))
	Models.add(m, Cyl, Vector3.new(1.0, 1.6, 1.6) * s, rgb(30, 30, 30), CFrame.new(0, 5.4 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	Models.add(m, Block, Vector3.new(2.6, 0.4, 0.4) * s, rgb(232, 74, 58), CFrame.new(0, 3.4 * s, 0))
	eyes(m, s, 4.4, -0.75, 0.3, 0.25)
	return m
end

function Models.Boulders(s: number): Model
	local m = Models.base("Boulder", 3 * s, true)
	local root = m.PrimaryPart :: Part
	root.Transparency = 0
	root.Color = rgb(125, 110, 95)
	root.Material = Enum.Material.Slate
	root.CustomPhysicalProperties = PhysicalProperties.new(3, 0.6, 0.2, 1, 1)
	Models.add(m, Ball, Vector3.new(2.5, 2.5, 2.5) * s, rgb(105, 95, 85), CFrame.new(1.6 * s, 1.2 * s, 0.6 * s), Enum.Material.Slate)
	Models.add(m, Ball, Vector3.new(2.2, 2.2, 2.2) * s, rgb(140, 125, 105), CFrame.new(-1.4 * s, -0.8 * s, -1.2 * s), Enum.Material.Slate)
	return m
end

function Models.Pumpkins(s: number): Model
	local m = Models.base("Pumpkin", 3 * s, true)
	local root = m.PrimaryPart :: Part
	root.Transparency = 0
	root.Color = rgb(240, 130, 30)
	root.CustomPhysicalProperties = PhysicalProperties.new(2, 0.6, 0.2, 1, 1)
	Models.add(m, Cyl, Vector3.new(1.4, 0.8, 0.8) * s, rgb(70, 120, 40), CFrame.new(0, 3.2 * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	Models.add(m, Block, Vector3.new(0.9, 0.9, 0.3) * s, rgb(40, 20, 10), CFrame.new(-1 * s, 1 * s, -2.7 * s), Neon)
	Models.add(m, Block, Vector3.new(0.9, 0.9, 0.3) * s, rgb(40, 20, 10), CFrame.new(1 * s, 1 * s, -2.7 * s), Neon)
	return m
end

function Models.Cars(s: number, color: Color3?): Model
	local m = Models.base("Car", 2.2 * s, false)
	local paint = color or rgb(232, 74, 58)
	local root = m.PrimaryPart :: Part
	-- cars use a box root so they slide straight
	root.Shape = Enum.PartType.Block
	root.Size = Vector3.new(5, 2.2, 9) * s
	root.CanCollide = true
	root.CustomPhysicalProperties = PhysicalProperties.new(1.5, 0, 0, 100, 100)
	Models.add(m, Block, Vector3.new(5, 1.6, 9) * s, paint, CFrame.new(0, 0.2 * s, 0), nil, "Body")
	Models.add(m, Block, Vector3.new(4.4, 1.5, 4.2) * s, paint, CFrame.new(0, 1.7 * s, 0.6 * s), nil, "Cabin")
	local glass = Models.add(m, Block, Vector3.new(4.0, 1.1, 0.2) * s, rgb(150, 210, 255), CFrame.new(0, 1.8 * s, -1.55 * s), Enum.Material.Glass)
	glass.Transparency = 0.3
	for _, x in ipairs({ -2.5, 2.5 }) do
		for _, z in ipairs({ -2.8, 2.8 }) do
			Models.add(m, Cyl, Vector3.new(0.8, 2, 2) * s, rgb(30, 30, 30), CFrame.new(x * s, -0.1 * s, z * s) * CFrame.Angles(0, 0, 0))
		end
	end
	Models.add(m, Block, Vector3.new(1, 0.6, 0.2) * s, rgb(255, 250, 200), CFrame.new(-1.6 * s, 0.4 * s, -4.55 * s), Neon)
	Models.add(m, Block, Vector3.new(1, 0.6, 0.2) * s, rgb(255, 250, 200), CFrame.new(1.6 * s, 0.4 * s, -4.55 * s), Neon)
	return m
end

function Models.Tornado(s: number): Model
	local m = Models.base("Tornado", 4 * s)
	local layers = 7
	for i = 1, layers do
		local t = i / layers
		local r = (3 + t * 12) * s
		local p = Models.add(m, Cyl, Vector3.new(4 * s, r * 2, r * 2), rgb(200, 200, 210), CFrame.new(0, (i - 1) * 4.5 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.SmoothPlastic, "Layer")
		p.Transparency = 0.45 + t * 0.2
		p.CastShadow = false
	end
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(rgb(190, 180, 160))
	dust.Size = NumberSequence.new(4 * s, 9 * s)
	dust.Transparency = NumberSequence.new(0.5, 1)
	dust.Lifetime = NumberRange.new(1.5, 2.5)
	dust.Rate = 25
	dust.Speed = NumberRange.new(4, 10)
	dust.SpreadAngle = Vector2.new(180, 30)
	dust.RotSpeed = NumberRange.new(-180, 180)
	dust.Parent = m.PrimaryPart
	return m
end

-- Popcorn kernel / generic blob
function Models.Blob(s: number, color: Color3, material: Enum.Material?): Model
	local m = Models.base("Blob", 1 * s, true)
	local root = m.PrimaryPart :: Part
	root.Transparency = 0
	root.Color = color
	root.Material = material or Enum.Material.SmoothPlastic
	return m
end

-- Rubber duck (Bath Time)
function Models.Duck(s: number): Model
	local m = Models.base("Duck", 1.4 * s)
	Models.add(m, Ball, Vector3.new(2.6, 2.2, 3) * s, rgb(255, 214, 40), CFrame.new(0, 0, 0))
	Models.add(m, Ball, Vector3.new(1.6, 1.6, 1.6) * s, rgb(255, 214, 40), CFrame.new(0, 1.4 * s, -0.8 * s), nil, "Head")
	Models.add(m, Wedge, Vector3.new(0.9, 0.3, 0.8) * s, rgb(255, 120, 30), CFrame.new(0, 1.3 * s, -1.8 * s))
	eyes(m, s, 1.7, -1.45, 0.35, 0.3)
	return m
end

function Models.Wisp(s: number): Model
	local m = Models.base("Wisp", 1 * s)
	local core = Models.add(m, Ball, Vector3.new(1.6, 1.6, 1.6) * s, rgb(140, 220, 255), CFrame.new(), Neon, "Core")
	core.Transparency = 0.2
	local fire = Instance.new("Fire")
	fire.Color = rgb(120, 200, 255)
	fire.SecondaryColor = rgb(200, 120, 255)
	fire.Size = 4 * s
	fire.Heat = 6
	fire.Parent = core
	local l = Instance.new("PointLight")
	l.Color = rgb(140, 200, 255)
	l.Range = 14
	l.Brightness = 2
	l.Parent = core
	return m
end

function Models.Mech(s: number): Model
	local m = Models.base("Mech", 4 * s, true)
	local metal = rgb(150, 160, 175)
	Models.add(m, Block, Vector3.new(7, 6, 5) * s, metal, CFrame.new(0, 5 * s, 0), Enum.Material.DiamondPlate)
	Models.add(m, Block, Vector3.new(4, 3, 3.6) * s, metal, CFrame.new(0, 9.5 * s, 0), Enum.Material.Metal)
	Models.add(m, Block, Vector3.new(3.4, 0.8, 0.2) * s, rgb(255, 40, 40), CFrame.new(0, 9.7 * s, -1.85 * s), Neon)
	Models.add(m, Block, Vector3.new(2, 2, 8) * s, rgb(90, 95, 105), CFrame.new(-4.6 * s, 5.5 * s, -1.5 * s))
	Models.add(m, Block, Vector3.new(2, 2, 8) * s, rgb(90, 95, 105), CFrame.new(4.6 * s, 5.5 * s, -1.5 * s))
	Models.add(m, Block, Vector3.new(2.4, 5, 2.4) * s, rgb(70, 70, 80), CFrame.new(-1.8 * s, 0.2 * s, 0))
	Models.add(m, Block, Vector3.new(2.4, 5, 2.4) * s, rgb(70, 70, 80), CFrame.new(1.8 * s, 0.2 * s, 0))
	local magnet = Models.add(m, Cyl, Vector3.new(1.2, 4, 4) * s, rgb(232, 74, 58), CFrame.new(0, 13 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Neon)
	magnet.Name = "Magnet"
	return m
end

---------------------------------------------------------------- archetype rigs
-- Generic blocky figures. Colours come from a palette picked by the typed word, so two
-- different words give different-looking figures. Nothing here copies any character's look.

local PALETTES = {
	{ shirt = rgb(232, 74, 58), pants = rgb(60, 60, 80), skin = rgb(242, 201, 160), accent = rgb(255, 201, 60) },
	{ shirt = rgb(76, 175, 80), pants = rgb(70, 50, 40), skin = rgb(205, 150, 110), accent = rgb(255, 244, 220) },
	{ shirt = rgb(80, 140, 230), pants = rgb(40, 40, 60), skin = rgb(242, 201, 160), accent = rgb(232, 74, 58) },
	{ shirt = rgb(123, 79, 214), pants = rgb(50, 40, 70), skin = rgb(150, 105, 75), accent = rgb(255, 201, 60) },
	{ shirt = rgb(255, 201, 60), pants = rgb(80, 60, 50), skin = rgb(242, 201, 160), accent = rgb(59, 36, 24) },
	{ shirt = rgb(255, 143, 184), pants = rgb(70, 70, 90), skin = rgb(220, 175, 130), accent = rgb(255, 255, 255) },
	{ shirt = rgb(47, 181, 168), pants = rgb(40, 60, 60), skin = rgb(110, 75, 55), accent = rgb(255, 201, 60) },
	{ shirt = rgb(40, 40, 48), pants = rgb(25, 25, 30), skin = rgb(242, 201, 160), accent = rgb(232, 74, 58) },
}
Models.PALETTES = PALETTES

local function palette(ctx: any?): any
	local i = (ctx and ctx.dish and ctx.dish.palette) or 1
	return PALETTES[((i - 1) % #PALETTES) + 1]
end
Models.palette = palette

-- Blocky figure standing on its root ball (radius 1.5*s, feet at -1.5*s).
function Models.Rig(name: string, s: number, pal: any): Model
	local m = Models.base(name, 1.5 * s, true)
	Models.add(m, Block, Vector3.new(0.9, 1.6, 0.9) * s, pal.pants, CFrame.new(-0.5 * s, -0.7 * s, 0))
	Models.add(m, Block, Vector3.new(0.9, 1.6, 0.9) * s, pal.pants, CFrame.new(0.5 * s, -0.7 * s, 0))
	Models.add(m, Block, Vector3.new(2, 1.9, 1) * s, pal.shirt, CFrame.new(0, 1.05 * s, 0), nil, "Body")
	Models.add(m, Block, Vector3.new(0.8, 1.8, 0.8) * s, pal.shirt, CFrame.new(-1.4 * s, 1.0 * s, -0.2 * s) * CFrame.Angles(math.rad(25), 0, 0), nil, "ArmL")
	Models.add(m, Block, Vector3.new(0.8, 1.8, 0.8) * s, pal.shirt, CFrame.new(1.4 * s, 1.0 * s, -0.2 * s) * CFrame.Angles(math.rad(25), 0, 0), nil, "ArmR")
	Models.add(m, Block, Vector3.new(1.25, 1.25, 1.25) * s, pal.skin, CFrame.new(0, 2.65 * s, 0), nil, "Head")
	eyes(m, s, 2.75, -0.63, 0.25, 0.3)
	return m
end

function Models.Fighter(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local m = Models.Rig("Fighter", s, pal)
	Models.add(m, Block, Vector3.new(2.05, 0.3, 1.05) * s, rgb(30, 30, 30), CFrame.new(0, 0.35 * s, 0))
	Models.add(m, Block, Vector3.new(1.3, 0.25, 1.3) * s, pal.accent, CFrame.new(0, 3.0 * s, 0))
	for _, x in ipairs({ -1.4, 1.4 }) do
		local f = Models.add(m, Ball, Vector3.new(0.9, 0.9, 0.9) * s, rgb(120, 220, 255), CFrame.new(x * s, 0.1 * s, -0.6 * s), Neon, "Fist")
		f.Transparency = 0.25
	end
	-- spiky "power" aura
	local aura = Models.add(m, Ball, Vector3.new(3.4, 4.6, 3.4) * s, pal.accent, CFrame.new(0, 1.2 * s, 0), Neon, "Aura")
	aura.Transparency = 0.85
	aura.CastShadow = false
	return m
end

function Models.Ninja(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local dark = { shirt = rgb(35, 35, 45), pants = rgb(25, 25, 32), skin = pal.skin, accent = pal.accent }
	local m = Models.Rig("Ninja", s, dark)
	Models.add(m, Block, Vector3.new(1.3, 0.7, 1.3) * s, rgb(30, 30, 38), CFrame.new(0, 2.4 * s, 0))
	Models.add(m, Block, Vector3.new(1.32, 0.25, 1.32) * s, pal.accent, CFrame.new(0, 3.0 * s, 0))
	Models.add(m, Block, Vector3.new(0.3, 0.25, 1.6) * s, pal.accent, CFrame.new(0.4 * s, 3.0 * s, 0.9 * s) * CFrame.Angles(0, math.rad(20), math.rad(-20)))
	Models.add(m, Block, Vector3.new(2.1, 0.5, 1.1) * s, pal.accent, CFrame.new(0, 1.9 * s, 0))
	return m
end

function Models.Wizard(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local m = Models.Rig("Wizard", s, pal)
	-- robe down to the floor
	Models.add(m, Block, Vector3.new(2.2, 2.4, 1.3) * s, pal.shirt, CFrame.new(0, -0.3 * s, 0), Enum.Material.Fabric, "Robe")
	-- pointy hat: stacked cylinders getting narrower
	for i = 0, 4 do
		local d = (1.9 - i * 0.38) * s
		Models.add(m, Cyl, Vector3.new(0.45 * s, d, d), pal.accent, CFrame.new(0, (3.35 + i * 0.4) * s, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end
	-- staff with a glowing orb
	Models.add(m, Cyl, Vector3.new(4.6, 0.25, 0.25) * s, rgb(120, 80, 45), CFrame.new(1.8 * s, 1.0 * s, -0.6 * s) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Wood)
	local orb = Models.add(m, Ball, Vector3.new(0.8, 0.8, 0.8) * s, rgb(170, 120, 255), CFrame.new(1.8 * s, 3.4 * s, -0.6 * s), Neon, "Orb")
	local l = Instance.new("PointLight")
	l.Color = rgb(170, 120, 255)
	l.Range = 10
	l.Parent = orb
	return m
end

function Models.Swordsman(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local m = Models.Rig("Swordsman", s, pal)
	Models.add(m, Block, Vector3.new(2.15, 1.2, 1.15) * s, rgb(170, 175, 185), CFrame.new(0, 1.4 * s, 0), Enum.Material.Metal)
	Models.add(m, Block, Vector3.new(1.35, 0.4, 1.35) * s, rgb(170, 175, 185), CFrame.new(0, 3.2 * s, 0), Enum.Material.Metal)
	-- sword held out front
	Models.add(m, Block, Vector3.new(0.25, 0.25, 1.0) * s, rgb(60, 40, 30), CFrame.new(1.4 * s, 0.2 * s, -1.0 * s))
	Models.add(m, Block, Vector3.new(0.9, 0.2, 0.2) * s, pal.accent, CFrame.new(1.4 * s, 0.2 * s, -1.5 * s))
	local blade = Models.add(m, Block, Vector3.new(0.12, 0.4, 3.6) * s, rgb(220, 235, 255), CFrame.new(1.4 * s, 0.2 * s, -3.4 * s), Enum.Material.Metal, "Blade")
	blade.Reflectance = 0.2
	return m
end

function Models.Titan(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local big = 3.5 * s
	local m = Models.Rig("Titan", big, { shirt = pal.shirt:Lerp(rgb(120, 100, 90), 0.5), pants = pal.pants, skin = pal.skin:Lerp(rgb(200, 120, 100), 0.3), accent = pal.accent })
	Models.add(m, Block, Vector3.new(0.7, 0.25, 0.1) * big, rgb(60, 20, 20), CFrame.new(0, 2.35 * big, -0.63 * big))
	return m
end

function Models.Dragon(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local c = pal.shirt
	local m = Models.base("Dragon", 3 * s)
	Models.add(m, Ball, Vector3.new(6, 6, 6) * s, c, CFrame.new(0, 0, 0), nil, "Body")
	Models.add(m, Ball, Vector3.new(4.6, 4.6, 4.6) * s, c, CFrame.new(0, 0.2 * s, 3.4 * s))
	Models.add(m, Cyl, Vector3.new(4, 2, 2) * s, c, CFrame.new(0, 2.2 * s, -3.6 * s) * CFrame.Angles(0, math.rad(90), math.rad(40)))
	Models.add(m, Block, Vector3.new(2.6, 2.2, 3.4) * s, c, CFrame.new(0, 3.8 * s, -5.6 * s), nil, "Head")
	eyes(m, s, 4.4, -7.3, 0.7, 0.45)
	Models.add(m, Wedge, Vector3.new(0.4, 1.6, 1.0) * s, pal.accent, CFrame.new(-0.8 * s, 5.4 * s, -5.0 * s))
	Models.add(m, Wedge, Vector3.new(0.4, 1.6, 1.0) * s, pal.accent, CFrame.new(0.8 * s, 5.4 * s, -5.0 * s))
	for _, side in ipairs({ -1, 1 }) do
		local wing = Models.add(m, Block, Vector3.new(9, 0.3, 5) * s, pal.accent:Lerp(c, 0.4), CFrame.new(side * 6.5 * s, 2 * s, 0) * CFrame.Angles(0, 0, math.rad(side * 18)), nil, "Wing")
		wing.Transparency = 0.1
	end
	for i = 1, 4 do
		local d = (2.2 - i * 0.4) * s
		Models.add(m, Ball, Vector3.new(d, d, d), c, CFrame.new(0, -0.2 * s, (5 + i * 1.8) * s))
	end
	return m
end

function Models.UFO(s: number, ctx: any?): Model
	local m = Models.base("UFO", 4 * s)
	Models.add(m, Cyl, Vector3.new(1.4, 12, 12) * s, rgb(180, 190, 205), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), Enum.Material.Metal, "Saucer")
	local dome = Models.add(m, Ball, Vector3.new(5, 5, 5) * s, rgb(150, 230, 255), CFrame.new(0, 1.2 * s, 0), Enum.Material.Glass, "Dome")
	dome.Transparency = 0.35
	-- the pilot
	Models.add(m, Ball, Vector3.new(1.8, 2.2, 1.8) * s, rgb(120, 230, 90), CFrame.new(0, 1.4 * s, 0))
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		Models.add(m, Ball, Vector3.new(0.8, 0.8, 0.8) * s, i % 2 == 0 and rgb(255, 201, 60) or rgb(255, 90, 90), CFrame.new(math.cos(a) * 5.6 * s, -0.2 * s, math.sin(a) * 5.6 * s), Neon)
	end
	local glow = Models.add(m, Cyl, Vector3.new(0.3, 5, 5) * s, rgb(150, 255, 150), CFrame.new(0, -0.8 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), Neon, "Beam")
	glow.Transparency = 0.3
	return m
end

function Models.Slime(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local m = Models.base("Slime", 1.6 * s, true)
	local root = m.PrimaryPart :: Part
	root.Transparency = 0.25
	root.Color = pal.shirt:Lerp(rgb(110, 220, 90), 0.6)
	root.Material = Enum.Material.Glass
	root.CustomPhysicalProperties = PhysicalProperties.new(0.8, 0, 0.6, 100, 100)
	eyes(m, s, 0.4, -1.3, 0.45, 0.45)
	Models.add(m, Ball, Vector3.new(1.4, 1.4, 1.4) * s, root.Color:Lerp(rgb(255, 255, 255), 0.4), CFrame.new(0.5 * s, 0.7 * s, 0.4 * s)).Transparency = 0.4
	return m
end

function Models.Critter(s: number, ctx: any?): Model
	local pal = palette(ctx)
	local fur = pal.shirt:Lerp(rgb(200, 160, 110), 0.55)
	local m = Models.base("Critter", 1.1 * s, true)
	Models.add(m, Block, Vector3.new(1.6, 1.3, 2.4) * s, fur, CFrame.new(0, 0.25 * s, 0.2 * s), nil, "Body")
	Models.add(m, Block, Vector3.new(1.3, 1.2, 1.2) * s, fur, CFrame.new(0, 0.9 * s, -1.4 * s), nil, "Head")
	eyes(m, s, 1.05, -2.0, 0.3, 0.3)
	Models.add(m, Wedge, Vector3.new(0.35, 0.7, 0.5) * s, fur, CFrame.new(-0.4 * s, 1.8 * s, -1.4 * s))
	Models.add(m, Wedge, Vector3.new(0.35, 0.7, 0.5) * s, fur, CFrame.new(0.4 * s, 1.8 * s, -1.4 * s))
	Models.add(m, Ball, Vector3.new(0.4, 0.3, 0.3) * s, rgb(40, 30, 30), CFrame.new(0, 0.8 * s, -2.02 * s))
	for _, x in ipairs({ -0.55, 0.55 }) do
		for _, z in ipairs({ -0.6, 0.9 }) do
			Models.add(m, Block, Vector3.new(0.4, 0.8, 0.4) * s, fur:Lerp(rgb(0, 0, 0), 0.2), CFrame.new(x * s, -0.65 * s, z * s))
		end
	end
	Models.add(m, Block, Vector3.new(0.3, 0.3, 1.2) * s, fur, CFrame.new(0, 0.6 * s, 1.8 * s) * CFrame.Angles(math.rad(-30), 0, 0))
	return m
end

function Models.StormCloud(s: number): Model
	local m = Models.base("StormCloud", 6 * s)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local p = Models.add(m, Ball, Vector3.one * (9 + (i % 3) * 3) * s, rgb(90, 95, 110), CFrame.new(math.cos(a) * 7 * s, (i % 2) * 2 * s, math.sin(a) * 5 * s))
		p.Transparency = 0.15
		p.CastShadow = true
	end
	return m
end

return Models
