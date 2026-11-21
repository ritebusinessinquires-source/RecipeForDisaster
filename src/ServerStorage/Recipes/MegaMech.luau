-- Mega Mech: Robots + Giant + Magnetic. One giant robot that stomps and drags you in.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local Mover = require(HazardLib.Mover)
local Models = require(HazardLib.Models)
local Robots = require(game:GetService("ServerStorage"):WaitForChild("Mains"):WaitForChild("Robots"))

local Recipe = {
	id = "MegaMech",
	name = "Mega Mech",
	emoji = "🦾",
	main = "Robots",
	spices = { "Giant", "Magnetic" },
	type = "Creature",
	desc = "One giant robot that stomps out shockwaves and drags you in with a magnet.",
	hint = { text = "Jump the shockwaves and run against the pull!", icon = "run" },
	stats = { Size = 1.4, Speed = 7, Count = 1, Damage = 25, Health = 1 },
}

function Recipe.Spawn(ctx)
	local s = ctx.stats.Size
	local p = ctx:randomOpenPoint()
	local mech = Mover.new(ctx, Models.Mech(s), { mode = "ground", radius = 4 * s, speed = ctx.stats.Speed, position = p + Vector3.new(0, 5 * s, 0), accel = 400, turnRate = 60 })
	ctx:decorate(mech, "RobotBeep")
	local magnet = mech.model:FindFirstChild("Magnet") :: BasePart?
	ctx:addPull(magnet or mech.root, 60, 9)
	ctx:fx("Banner", { text = "MEGA MECH ONLINE", color = "#E84A3A" })
	local function stomp()
		local origin = mech.root.Position
		local ground = ctx:groundAt(origin.X, origin.Z) or 0
		local center = Vector3.new(origin.X, ground, origin.Z)
		ctx:rumble(1.5, 0.6)
		ctx:sound("Stomp", center, 1)
		ctx:fx("Shockwave", { pos = center, radius = 45, duration = 1.3 })
		for i = 1, 6 do
			ctx:delay(i * 0.2, function()
				local r = i / 6 * 45
				for _, t in ipairs(ctx:targets()) do
					local d = t.root.Position - center
					local flat = Vector3.new(d.X, 0, d.Z).Magnitude
					if math.abs(flat - r) < 4 and t.humanoid.FloorMaterial ~= Enum.Material.Air and mech:canHit(t.player, 1) then
						ctx:damage(t, ctx.stats.Damage)
						ctx:knockback(t, Vector3.new(0, 55, 0))
					end
				end
			end)
		end
	end
	ctx:loop(0.1, function(dt)
		if not mech.alive or not mech.root.Parent then
			return
		end
		local t = ctx:nearestTarget(mech.root.Position, nil, true)
		local desired = t and (t.root.Position - mech.root.Position) or mech.dir
		mech:drive(desired, dt, ctx.rampMult)
		local now = os.clock()
		if now >= (mech.data.nextStomp or 2) then
			mech.data.nextStomp = now + 4 / ctx.rampMult
			stomp()
		end
		if t and now >= (mech.data.nextShot or 0) then
			mech.data.nextShot = now + 1.6
			local muzzle = mech.root.Position + Vector3.new(0, 9 * s, 0)
			Robots.fireBolt(ctx, muzzle, t.root.Position, 18, { width = 1.2 })
		end
		for _, target in ipairs(ctx:targets()) do
			local d = target.root.Position - mech.root.Position
			if Vector3.new(d.X, 0, d.Z).Magnitude < mech.radius + 3 and d.Y < 14 * s and mech:canHit(target.player, 1) then
				ctx:damage(target, 30)
				local dir = Vector3.new(d.X, 0, d.Z)
				dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.xAxis
				ctx:knockback(target, dir * 70 + Vector3.new(0, 40, 0))
			end
		end
	end)
end

return Recipe
