-- Builds the voted map into workspace.Arena, sets up its tiles and water, and tears it down.

local ServerStorage = game:GetService("ServerStorage")

local Tiles = require(ServerStorage:WaitForChild("HazardLib"):WaitForChild("Tiles"))
local MapsFolder = ServerStorage:WaitForChild("Maps")

local MapManager = {}

local current: any = nil

local function arenaFolder(): Folder
	local f = workspace:FindFirstChild("Arena") :: Folder?
	if not f then
		local nf = Instance.new("Folder")
		nf.Name = "Arena"
		nf.Parent = workspace
		f = nf
	end
	return f :: Folder
end

local function fillWater(info: any, material: Enum.Material)
	local w = info.water
	if not w then
		return
	end
	local terrain = workspace.Terrain
	local height = w.surfaceY - w.bottomY
	local mid = (w.surfaceY + w.bottomY) / 2
	if w.circle then
		terrain:FillCylinder(CFrame.new(w.center.X, mid, w.center.Z), height, w.radius, material)
	else
		terrain:FillBlock(CFrame.new(w.center.X, mid, w.center.Z), Vector3.new(w.size.X, height, w.size.Z), material)
	end
end

function MapManager.load(mapId: string): any
	MapManager.unload()
	local mod = require(MapsFolder:WaitForChild(mapId)) :: any
	local info = mod.build(arenaFolder())
	info.tiles = Tiles.new(info.tileParts, info.tileSize)
	-- tiles hidden under raised spots / cover never get picked as hazard seeds
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { info.model }
	for _, t in ipairs(info.tiles.list) do
		local hit = workspace:Raycast(t.center + Vector3.new(0, 60, 0), Vector3.new(0, -70, 0), params)
		t.covered = hit ~= nil and hit.Instance ~= t.part
	end
	local origRandom = info.tiles.random
	info.tiles.random = function(self, rng, filter)
		return origRandom(self, rng, function(t)
			return not t.covered and (filter == nil or filter(t))
		end)
	end
	info.refillWater = function()
		fillWater(info, Enum.Material.Water)
	end
	workspace.Terrain.WaterColor = info.waterColor or Color3.fromRGB(70, 150, 210)
	workspace.Terrain.WaterTransparency = 0.35
	workspace.Terrain.WaterWaveSize = 0.08
	workspace.Terrain.WaterReflectance = 0.2
	info.refillWater()
	info.model:SetAttribute("MapId", mapId)
	current = info
	return info
end

function MapManager.current(): any
	return current
end

function MapManager.unload()
	if current then
		if current.model then
			current.model:Destroy()
		end
		current = nil
	end
	workspace.Terrain:Clear()
	for _, c in ipairs(arenaFolder():GetChildren()) do
		c:Destroy()
	end
end

-- For thumbnails/tests: dump simple geometry of the current map
function MapManager.describe(): { any }
	local out = {}
	if not current then
		return out
	end
	for _, p in ipairs(current.model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			table.insert(out, p)
		end
	end
	return out
end

return MapManager
