-- HazardRunner: spawns the Main by type (or a secret recipe), runs Spice hooks, applies the
-- ghost-voted Twist for its course, and cleans everything up at round end.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Context = require(ServerStorage:WaitForChild("HazardLib"):WaitForChild("Context"))
local Mover = require(ServerStorage.HazardLib:WaitForChild("Mover"))
local DishResolver = require(ServerScriptService:WaitForChild("DishResolver"))

local HazardRunner = {}

local running: { any } = {}

function HazardRunner.init()
	Mover.setupCollisionGroups()
	Context.hazardsFolder()
end

-- env = { map = MapInfo, getTargets = fn }
function HazardRunner.start(dish: any, env: any): any
	local ctx = Context.new(dish, env)
	local spawnFn
	if dish.secretId then
		spawnFn = DishResolver.Recipes[dish.secretId].Spawn
	else
		spawnFn = DishResolver.Mains[dish.mainId].Spawn
	end
	task.spawn(function()
		local ok, err = pcall(spawnFn, ctx)
		if not ok then
			warn("[HazardRunner] spawn error for", dish.name, err)
		end
	end)
	local handle = { dish = dish, ctx = ctx, twistCtx = nil }
	if dish.twistId and DishResolver.Twists[dish.twistId] then
		local tctx = Context.new({ id = tostring(dish.id) .. "_twist", creditId = dish.id, name = dish.name, type = "Twist", stats = {}, hooks = {} }, env)
		handle.twistCtx = tctx
		task.spawn(function()
			local ok, err = pcall(DishResolver.Twists[dish.twistId].Start, tctx)
			if not ok then
				warn("[HazardRunner] twist error", dish.twistId, err)
			end
		end)
	end
	table.insert(running, handle)
	return handle
end

function HazardRunner.ramp(handle: any)
	if handle and handle.ctx then
		handle.ctx.rampMult = Config.RampMultiplier
	end
end

-- Twists last for their own course only.
function HazardRunner.endTwist(handle: any)
	if handle and handle.twistCtx then
		handle.twistCtx:stop()
		handle.twistCtx = nil
	end
end

function HazardRunner.running(): { any }
	return running
end

function HazardRunner.stopAll()
	for _, h in ipairs(running) do
		pcall(function()
			if h.twistCtx then
				h.twistCtx:stop()
			end
			h.ctx:stop()
		end)
	end
	table.clear(running)
	local folder = workspace:FindFirstChild("Hazards")
	if folder then
		folder:ClearAllChildren()
	end
	workspace.Gravity = 196.2
end

return HazardRunner
