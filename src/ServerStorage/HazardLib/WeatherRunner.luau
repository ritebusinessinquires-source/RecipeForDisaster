-- Weather type: an arena-wide force. The Tornado wanders the map, pulls everyone toward it
-- (clients apply the pull to their own character) and flings anyone caught in the core.

local ServerStorage = game:GetService("ServerStorage")
local HazardLib = ServerStorage:WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)

local WeatherRunner = {}

function WeatherRunner.spawnOne(ctx: any, main: any): any
	local cfg = main.weather
	local s = ctx.stats.Size
	local model = (main.build or Models[main.id])(s, ctx)
	local p = ctx:randomOpenPoint()
	local _, d = ctx:nearestTarget(p, nil, true)
	for _ = 1, 6 do
		if d > 50 then
			break
		end
		p = ctx:randomOpenPoint()
		_, d = ctx:nearestTarget(p, nil, true)
	end
	local obj = Mover.new(ctx, model, {
		mode = "phase",
		radius = (cfg.coreRadius or 6) * s,
		speed = ctx.stats.Speed,
		hover = 4 * s,
		turnRate = 70,
		position = p + Vector3.new(0, 4 * s, 0),
	})
	obj.ao.Enabled = false
	local spin = Instance.new("AngularVelocity")
	spin.Attachment0 = obj.root:FindFirstChild("MoverAttachment") :: Attachment
	spin.AngularVelocity = Vector3.new(0, 5, 0)
	spin.MaxTorque = math.huge
	spin.RelativeTo = Enum.ActuatorRelativeTo.World
	spin.Parent = obj.root
	obj.damage = ctx.stats.Damage
	obj.main = main
	obj.pullRadius = (cfg.pullRadius or 42) * math.sqrt(s)
	obj.pullStrength = (cfg.pullStrength or 14) * (ctx.rampMult)
	ctx:addPull(obj.root, obj.pullRadius, obj.pullStrength)
	ctx:hook("spawn", obj)
	ctx:decorate(obj, main.sound or "Wind")
	return obj
end

function WeatherRunner.run(ctx: any, main: any)
	local count = math.max(1, math.floor(ctx.stats.Count + 0.5))
	for _ = 1, count do
		WeatherRunner.spawnOne(ctx, main)
	end
	local rampApplied = false
	ctx:loop(0.1, function(dt)
		local now = os.clock()
		if ctx.rampMult > 1 and not rampApplied then
			rampApplied = true
			for _, obj in ipairs(ctx.objects) do
				obj.pullStrength *= ctx.rampMult
				obj.root:SetAttribute("PullStrength", obj.pullStrength)
			end
		end
		for _, obj in ipairs(table.clone(ctx.objects)) do
			if obj.alive and obj.root.Parent then
				local pos = obj.root.Position
				-- wander toward players, loosely
				if now >= (obj.data.nextWaypoint or 0) or not obj.data.waypoint then
					obj.data.nextWaypoint = now + ctx.rng:NextNumber(2.5, 4.5)
					local t = ctx:randomTarget()
					local wp = ctx:randomOpenPoint()
					if t and ctx.rng:NextNumber() < 0.6 then
						wp = t.root.Position:Lerp(wp, 0.3)
					end
					obj.data.waypoint = wp
				end
				local desired = obj.data.waypoint - pos
				desired = Vector3.new(desired.X, 0, desired.Z)
				if not ctx:inBounds(pos, 15) then
					local c = ctx.map and ctx.map.center or Vector3.zero
					desired = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z)
				end
				local ground = ctx:groundAt(pos.X, pos.Z) or (ctx.map and ctx.map.floorY or 0)
				obj:drive(desired.Magnitude > 1 and desired.Unit or obj.dir, dt, ctx.rampMult, ground + obj.hover)
				ctx:hook("tick", obj, dt)
				-- core: damage + fling
				for _, t in ipairs(ctx:targets()) do
					local d = t.root.Position - pos
					local flat = Vector3.new(d.X, 0, d.Z)
					if flat.Magnitude <= obj.radius + 2 and d.Y < 40 * ctx.stats.Size then
						local consumed = ctx:hook("hit", obj, t)
						if not consumed then
							ctx:damage(t, obj.damage * dt)
							if obj:canHit(t.player, 2.2) then
								local outward = flat.Magnitude > 0.1 and flat.Unit or Vector3.xAxis
								local tangent = Vector3.new(-outward.Z, 0, outward.X)
								ctx:knockback(t, tangent * 45 + outward * 25 + Vector3.new(0, 75, 0))
								ctx:damage(t, obj.damage * 0.4)
							end
						end
					end
				end
			end
		end
	end)
end

return WeatherRunner
