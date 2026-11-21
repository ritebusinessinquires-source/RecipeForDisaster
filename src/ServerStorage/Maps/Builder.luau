-- Small helper for building maps out of parts.

local Builder = {}
Builder.__index = Builder

function Builder.new(model: Instance)
	local self = setmetatable({}, Builder)
	self.model = model
	self.parts = 0
	return self
end

local function hex(c: any): Color3
	if typeof(c) == "Color3" then
		return c
	end
	return Color3.fromHex(c)
end
Builder.hex = hex

function Builder:part(shape: Enum.PartType, size: Vector3, cf: CFrame, color: any, material: Enum.Material?, parent: Instance?, name: string?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = hex(color)
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Name = name or "Part"
	p.Parent = parent or self.model
	self.parts += 1
	return p
end

function Builder:block(size: Vector3, pos: Vector3 | CFrame, color: any, material: Enum.Material?, parent: Instance?, name: string?): Part
	local cf = typeof(pos) == "CFrame" and pos or CFrame.new(pos :: Vector3)
	return self:part(Enum.PartType.Block, size, cf, color, material, parent, name)
end

-- Upright cylinder standing on `bottom` (y = bottom of the cylinder)
function Builder:cylinder(diameter: number, height: number, bottom: Vector3, color: any, material: Enum.Material?, parent: Instance?, name: string?): Part
	local cf = CFrame.new(bottom + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	return self:part(Enum.PartType.Cylinder, Vector3.new(height, diameter, diameter), cf, color, material, parent, name)
end

-- Cylinder lying on its side along a direction (angle around Y)
function Builder:log(diameter: number, length: number, center: Vector3, yaw: number, color: any, material: Enum.Material?, parent: Instance?, name: string?): Part
	local cf = CFrame.new(center) * CFrame.Angles(0, yaw, 0)
	return self:part(Enum.PartType.Cylinder, Vector3.new(length, diameter, diameter), cf, color, material, parent, name)
end

function Builder:ball(diameter: number, center: Vector3, color: any, material: Enum.Material?, parent: Instance?, name: string?): Part
	return self:part(Enum.PartType.Ball, Vector3.one * diameter, CFrame.new(center), color, material, parent, name)
end

function Builder:wedge(size: Vector3, cf: CFrame, color: any, material: Enum.Material?, parent: Instance?, name: string?): Part
	return self:part(Enum.PartType.Wedge, size, cf, color, material, parent, name)
end

function Builder:folder(name: string, parent: Instance?): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or self.model
	return f
end

-- Invisible wall
function Builder:wall(size: Vector3, pos: Vector3, parent: Instance?)
	local p = self:block(size, pos, "#FFFFFF", Enum.Material.SmoothPlastic, parent, "InvisibleWall")
	p.Transparency = 1
	p.CastShadow = false
	p.CanQuery = false
	return p
end

-- A grid of floor tiles. `include(x, z)` decides which cells exist; `look(x, z, gx, gz)`
-- returns color, material for a cell.
function Builder:tiles(opts: any): ({ BasePart }, Folder)
	local folder = self:folder("Tiles")
	local size = opts.size or 10
	local list = {}
	local half = opts.half or 125
	local thickness = opts.thickness or 2
	local topY = opts.topY or 0
	for x = -half + size / 2, half - size / 2, size do
		for z = -half + size / 2, half - size / 2, size do
			if not opts.include or opts.include(x, z) then
				local gx, gz = math.floor(x / size + 0.5), math.floor(z / size + 0.5)
				local color, material = opts.look(x, z, gx, gz)
				local p = self:block(Vector3.new(size, thickness, size), Vector3.new(x, topY - thickness / 2, z), color, material, folder, "Tile")
				table.insert(list, p)
			end
		end
	end
	return list, folder
end

return Builder
