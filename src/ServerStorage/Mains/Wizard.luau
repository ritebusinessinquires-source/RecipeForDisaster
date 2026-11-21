-- Wizard (Creature): keeps its distance, teleports around and lobs exploding magic orbs.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Wizard = {
	id = "Wizard",
	type = "Creature",
	danger = 4,
	stats = { Size = 1, Speed = 10, Count = 2, Damage = 22, Health = 90 },
	hint = { text = "Watch for the glowing circles - magic lands there!", icon = "run" },
	creature = { mode = "ground", radius = 1.5, turnRate = 220, cooldown = 1.2, knock = 30, poofColor = Color3.fromRGB(170, 120, 255) },
}

function Wizard.step(ctx, obj, dt)
	local now = os.clock()
	local pos = obj.root.Position
	if now >= obj.retargetAt or not obj.target or not obj.target.root.Parent then
		obj.target = ctx:nearestTarget(pos, nil, true)
		obj.retargetAt = now + 2
	end
	local t = obj.target
	if not t then
		CreatureRunner.defaultStep(ctx, obj, dt)
		return true
	end
	-- keep a casting distance: back off if close, close in if far, strafe in between
	local to = Vector3.new(t.root.Position.X - pos.X, 0, t.root.Position.Z - pos.Z)
	local dist = to.Magnitude
	local dir = dist > 0.1 and to.Unit or obj.dir
	local desired
	if dist < 18 then
		desired = -dir
	elseif dist > 32 then
		desired = dir
	else
		desired = Vector3.new(-dir.Z, 0, dir.X) * (math.sin(now * 0.7 + (obj.data.phase or 0)) > 0 and 1 or -1)
	end
	if not ctx:inBounds(pos, 12) then
		local c = ctx.map and ctx.map.center or Vector3.zero
		desired = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z).Unit
	end
	obj:drive(desired, dt, ctx.rampMult)
	if now >= (obj.data.nextCast or 1.5) and dist < 75 then
		obj.data.nextCast = now + ctx.rng:NextNumber(2.0, 2.8) / ctx.rampMult
		local landing = t.root.Position + t.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * 0.9
		local y = ctx:groundAt(landing.X, landing.Z)
		if y then
			landing = Vector3.new(landing.X, y, landing.Z)
			local r = 7 * math.sqrt(ctx.stats.Size)
			ctx:sound("Chime", pos, 0.7)
			ctx:fx("Warning", { pos = landing, radius = r, duration = 1.1, color = Color3.fromRGB(170, 120, 255) })
			ctx:fx("Arc", { from = pos + Vector3.new(0, 4, 0), to = landing, duration = 1.1, style = "magic", height = 18 })
			ctx:delay(1.1, function()
				ctx:explode(landing, r, obj.damage, { knock = 45, color = Color3.fromRGB(170, 120, 255), sound = "Zap" })
			end)
		end
	end
	if now >= (obj.data.nextBlink or 6) then
		obj.data.nextBlink = now + ctx.rng:NextNumber(6, 9)
		local p = ctx:randomOpenPoint()
		ctx:fx("Poof", { pos = pos, color = Color3.fromRGB(170, 120, 255) })
		obj.model:PivotTo(CFrame.new(p + Vector3.new(0, obj.radius + 0.5, 0)))
		ctx:fx("Poof", { pos = obj.root.Position, color = Color3.fromRGB(170, 120, 255) })
		ctx:sound("Chime", obj.root.Position, 0.6, 1.3)
	end
	return true
end

function Wizard.onSpawn(ctx, obj)
	obj.data.phase = ctx.rng:NextNumber(0, 6)
end

function Wizard.Spawn(ctx)
	CreatureRunner.run(ctx, Wizard)
end

return Wizard
