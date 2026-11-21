-- Robots (Creature): slow walkers that fire laser bolts. Low cover blocks the shots.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Robots = {
	id = "Robots",
	type = "Creature",
	danger = 3,
	sound = "RobotBeep",
	stats = { Size = 1, Speed = 8, Count = 5, Damage = 18, Health = 90 },
	hint = { text = "Hide behind low cover - it blocks lasers!", icon = "cover" },
	creature = { mode = "ground", radius = 1.6, turnRate = 150, cooldown = 1.2, knock = 20, poofColor = Color3.fromRGB(170, 180, 190) },
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

-- Fire a bolt from a muzzle at a point. Map geometry (cover) stops it.
function Robots.fireBolt(ctx, from, to, damage, opts)
	opts = opts or {}
	local dir = to - from
	if ctx.map and ctx.map.model then
		rayParams.FilterDescendantsInstances = { ctx.map.model }
		local hit = workspace:Raycast(from, dir, rayParams)
		if hit then
			to = hit.Position
		end
	end
	local speed = opts.speed or 85
	local travel = (to - from).Magnitude / speed
	ctx:sound(opts.sound or "Laser", from, opts.volume or 0.55)
	ctx:fx("Bolt", { from = from, to = to, duration = travel, color = opts.color, width = opts.width })
	ctx:delay(travel, function()
		for _, t in ipairs(ctx:targets()) do
			if (t.root.Position - to).Magnitude <= (opts.radius or 3.5) then
				local consumed = ctx:hook("boltHit", t)
				if not consumed then
					ctx:damage(t, damage)
					if opts.onHit then
						opts.onHit(t)
					end
				end
			end
		end
		if opts.onLand then
			opts.onLand(to)
		end
	end)
end

function Robots.step(ctx, obj, dt)
	CreatureRunner.defaultStep(ctx, obj, dt)
	local now = os.clock()
	local t = obj.target
	if t and now >= (obj.data.nextShot or 0) then
		local dist = (t.root.Position - obj.root.Position).Magnitude
		if dist < 75 then
			obj.data.nextShot = now + ctx.rng:NextNumber(2.2, 3.2) / ctx.rampMult
			local s = ctx.stats.Size
			local muzzle = obj.root.Position + Vector3.new(0, 1.2 * s, 0) + obj.dir * (obj.radius + 0.5)
			local lead = t.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * (dist / 85) * 0.5
			Robots.fireBolt(ctx, muzzle, t.root.Position + lead, obj.damage)
		end
	end
	return true
end

function Robots.Spawn(ctx)
	CreatureRunner.run(ctx, Robots)
end

return Robots
