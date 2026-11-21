-- Terrain type: changes the ground. Seeds appear on floor tiles and spread. Standing on an
-- owned tile applies the Main's effect. Raised spots and water are never tiles, so they're safe.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local TerrainRunner = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Which tile (if any) is this player standing on?
function TerrainRunner.tileUnder(ctx: any, root: BasePart): any
	local tiles = ctx.tiles
	if not tiles or not tiles.folder then
		return nil
	end
	-- cast against the whole map so standing on a raised spot or cover blocks the tile below
	rayParams.FilterDescendantsInstances = { ctx.map.model }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -5.5, 0), rayParams)
	if not hit or hit.Instance.Parent ~= tiles.folder then
		return nil
	end
	return tiles:tileAt(hit.Instance.Position.X, hit.Instance.Position.Z)
end

function TerrainRunner.run(ctx: any, main: any)
	local tiles = ctx.tiles
	if not tiles then
		warn("[TerrainRunner] map has no tiles")
		return
	end
	local cfg = main.terrain
	local dishId = ctx.dish.id
	local hazardName = ctx:hookValue("hazardName", cfg.hazard)
	local invisible = ctx:hasHook("Invisible") ~= nil
	local level = 1
	local owned: { any } = {}
	local frontier: { any } = {}
	local sinkTime: { [any]: number } = {}

	local maxTiles = math.floor(math.clamp(ctx.stats.Count * 7 * ctx.stats.Size ^ 2, 4, #tiles.list * 0.42))
	ctx.maxTiles = maxTiles

	local loops = 0
	local function convert(t: any)
		if t.hazard then
			return
		end
		tiles:setHazard(t, hazardName, dishId, level, invisible)
		table.insert(owned, t)
		table.insert(frontier, t)
		ctx:hook("tileConverted", t)
		-- a few bubbling / squelching sounds spread over the pools
		if loops < 4 and #owned % 6 == 1 then
			loops += 1
			local id = Config.Sounds[main.sound or "Bubble"]
			if id and id ~= "" then
				local snd = Instance.new("Sound")
				snd.SoundId = id
				snd.Looped = true
				snd.Volume = 0.5
				snd.RollOffMaxDistance = 80
				snd.Parent = t.part
				snd:Play()
				ctx:onCleanup(function()
					snd:Destroy()
				end)
			end
		end
	end

	local function seed()
		local filter = function(t)
			return t.hazard == nil
		end
		local t = tiles:random(ctx.rng, filter)
		if not t then
			return
		end
		ctx:fx("Warning", { pos = Vector3.new(t.center.X, t.topY, t.center.Z), radius = tiles.size * (1 + ctx.stats.Size * 0.6), duration = 1.2, color = cfg.warnColor })
		ctx:delay(1.2, function()
			convert(t)
			-- seed blob: grow a small patch right away
			local r = tiles.size * (0.6 + ctx.stats.Size * 0.6)
			for _, n in ipairs(tiles:inRadius(t.center, r)) do
				if #owned < maxTiles then
					convert(n)
				end
			end
		end)
	end

	local seeds = math.max(1, math.floor(ctx.stats.Count + 0.5))
	for i = 1, seeds do
		ctx:delay((i - 1) * 0.4, seed)
	end

	-- spread
	local spreadEvery = math.clamp(0.9 / (ctx.stats.Speed or 1), 0.2, 3)
	ctx:loop(spreadEvery, function()
		local cap = math.floor(maxTiles * (ctx.rampMult > 1 and 1.25 or 1))
		if #owned >= cap then
			-- full: shift the pools around so it stays dynamic
			if #owned > 0 and ctx.rng:NextNumber() < 0.5 then
				local i = ctx.rng:NextInteger(1, #owned)
				local t = table.remove(owned, i)
				if t and t.hazardOwner == dishId then
					tiles:setHazard(t, nil)
				end
			end
		end
		local grow = math.max(1, math.floor(#frontier * 0.25))
		for _ = 1, grow do
			if #owned >= cap or #frontier == 0 then
				break
			end
			local fi = ctx.rng:NextInteger(1, #frontier)
			local f = frontier[fi]
			local ns = tiles:neighbors(f)
			local free = {}
			for _, n in ipairs(ns) do
				if not n.hazard then
					table.insert(free, n)
				end
			end
			if #free == 0 then
				table.remove(frontier, fi)
			else
				local pick = free[ctx.rng:NextInteger(1, #free)]
				pick = ctx:hookValue("spreadPick", pick, free) or pick
				convert(pick)
			end
		end
		if #frontier == 0 and #owned < cap then
			seed()
		end
		ctx:hook("spreadTick", owned)
	end)

	-- effects on players standing on owned tiles
	ctx:loop(0.1, function(dt)
		for _, target in ipairs(ctx:targets()) do
			local t = TerrainRunner.tileUnder(ctx, target.root)
			if t and t.hazardOwner == dishId then
				local consumed = ctx:hook("contact", target, t, dt)
				if not consumed then
					main.terrain.onContact(ctx, target, t, dt, sinkTime)
				end
			else
				sinkTime[target.player] = nil
			end
		end
	end)

	ctx:onCleanup(function()
		table.clear(owned)
		table.clear(frontier)
	end)
	ctx.ownedTiles = owned
end

return TerrainRunner
