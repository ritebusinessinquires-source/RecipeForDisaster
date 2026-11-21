-- Floor tiles: every map's open ground is a grid of tile parts. Terrain hazards (lava,
-- quicksand, frost) and ice change tiles. Raised spots and water are never tiles.

local Tiles = {}
Tiles.__index = Tiles

export type Tile = {
	part: BasePart,
	gx: number,
	gz: number,
	center: Vector3,
	topY: number,
	baseColor: Color3,
	baseMaterial: Enum.Material,
	baseTransparency: number,
	hazard: string?,
	hazardOwner: string?,
	hazardLevel: number,
	invisible: boolean,
	iceUntil: number,
	visual: string,
}

local HAZARD_LOOK = {
	lava = { color = Color3.fromRGB(255, 90, 20), material = Enum.Material.Neon },
	quicksand = { color = Color3.fromRGB(214, 178, 110), material = Enum.Material.Sand },
	frost = { color = Color3.fromRGB(150, 210, 255), material = Enum.Material.Glacier },
	steam = { color = Color3.fromRGB(235, 240, 245), material = Enum.Material.SmoothPlastic },
	acid = { color = Color3.fromRGB(120, 235, 60), material = Enum.Material.Neon },
}
Tiles.Looks = HAZARD_LOOK

local ICE_LOOK = { color = Color3.fromRGB(190, 235, 255), material = Enum.Material.Ice }

function Tiles.new(parts: { BasePart }, tileSize: number)
	local self = setmetatable({}, Tiles)
	self.size = tileSize
	self.list = {} :: { Tile }
	self.grid = {} :: { [number]: { [number]: Tile } }
	self.folder = nil :: Instance?
	for _, p in ipairs(parts) do
		local gx = math.floor(p.Position.X / tileSize + 0.5)
		local gz = math.floor(p.Position.Z / tileSize + 0.5)
		local t: Tile = {
			part = p,
			gx = gx,
			gz = gz,
			center = p.Position,
			topY = p.Position.Y + p.Size.Y / 2,
			baseColor = p.Color,
			baseMaterial = p.Material,
			baseTransparency = p.Transparency,
			hazard = nil,
			hazardOwner = nil,
			hazardLevel = 0,
			invisible = false,
			iceUntil = 0,
			visual = "base",
		}
		table.insert(self.list, t)
		self.grid[gx] = self.grid[gx] or {}
		self.grid[gx][gz] = t
		if not self.folder then
			self.folder = p.Parent
		end
	end
	return self
end

function Tiles:tileAt(x: number, z: number): Tile?
	local gx = math.floor(x / self.size + 0.5)
	local gz = math.floor(z / self.size + 0.5)
	local col = self.grid[gx]
	return col and col[gz]
end

function Tiles:neighbors(t: Tile): { Tile }
	local out = {}
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local col = self.grid[t.gx + d[1]]
		local n = col and col[t.gz + d[2]]
		if n then
			table.insert(out, n)
		end
	end
	return out
end

function Tiles:inRadius(pos: Vector3, radius: number): { Tile }
	local out = {}
	local r = math.ceil(radius / self.size)
	local cx = math.floor(pos.X / self.size + 0.5)
	local cz = math.floor(pos.Z / self.size + 0.5)
	for gx = cx - r, cx + r do
		local col = self.grid[gx]
		if col then
			for gz = cz - r, cz + r do
				local t = col[gz]
				if t then
					local dx, dz = t.center.X - pos.X, t.center.Z - pos.Z
					if dx * dx + dz * dz <= radius * radius then
						table.insert(out, t)
					end
				end
			end
		end
	end
	return out
end

function Tiles:random(rng: Random, filter: ((Tile) -> boolean)?): Tile?
	if #self.list == 0 then
		return nil
	end
	for _ = 1, 30 do
		local t = self.list[rng:NextInteger(1, #self.list)]
		if not filter or filter(t) then
			return t
		end
	end
	return nil
end

function Tiles:refresh(t: Tile)
	local p = t.part
	local want = "base"
	local look = nil
	if t.hazard then
		want = t.hazard .. (t.invisible and "_inv" or "")
		look = HAZARD_LOOK[t.hazard]
	elseif t.iceUntil > os.clock() then
		want = "ice"
		look = ICE_LOOK
	end
	if want == t.visual then
		return
	end
	t.visual = want
	if look and not t.invisible then
		p.Color = look.color
		p.Material = look.material
	elseif look and t.invisible then
		-- invisible hazards keep the floor look but sparkle slightly
		p.Color = t.baseColor:Lerp(look.color, 0.12)
		p.Material = t.baseMaterial
	else
		p.Color = t.baseColor
		p.Material = t.baseMaterial
	end
	p:SetAttribute("Hazard", t.hazard)
end

function Tiles:setHazard(t: Tile, hazard: string?, owner: string?, level: number?, invisible: boolean?)
	t.hazard = hazard
	t.hazardOwner = owner
	t.hazardLevel = level or 1
	t.invisible = invisible == true
	self:refresh(t)
end

function Tiles:setIce(t: Tile, seconds: number)
	if t.hazard then
		return
	end
	t.iceUntil = math.max(t.iceUntil, os.clock() + seconds)
	self:refresh(t)
end

function Tiles:iceRadius(pos: Vector3, radius: number, seconds: number)
	for _, t in ipairs(self:inRadius(pos, radius)) do
		self:setIce(t, seconds)
	end
end

function Tiles:clearOwner(owner: string)
	for _, t in ipairs(self.list) do
		if t.hazardOwner == owner then
			self:setHazard(t, nil)
		end
	end
end

function Tiles:countHazard(owner: string?): number
	local n = 0
	for _, t in ipairs(self.list) do
		if t.hazard and (owner == nil or t.hazardOwner == owner) then
			n += 1
		end
	end
	return n
end

-- Expire ice tiles. Call ~4x per second.
function Tiles:update()
	local now = os.clock()
	for _, t in ipairs(self.list) do
		if t.visual == "ice" and t.iceUntil <= now then
			self:refresh(t)
		end
	end
end

return Tiles
