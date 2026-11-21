-- Ninja (Creature): fast, teleports behind you and throws fans of shuriken.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)
local Robots = require(script.Parent.Robots)

local Ninja = {
	id = "Ninja",
	type = "Creature",
	danger = 4,
	stats = { Size = 1, Speed = 18, Count = 3, Damage = 11, Health = 80 },
	hint = { text = "Keep moving - ninjas teleport behind you!", icon = "run" },
	creature = { mode = "ground", radius = 1.5, turnRate = 400, cooldown = 0.9, knock = 25, zigzag = 5, poofColor = Color3.fromRGB(40, 40, 50) },
}

function Ninja.step(ctx, obj, dt)
	CreatureRunner.defaultStep(ctx, obj, dt)
	local now = os.clock()
	local t = obj.target
	if not t then
		return true
	end
	if now >= (obj.data.nextBlink or 3) then
		obj.data.nextBlink = now + ctx.rng:NextNumber(4, 6) / ctx.rampMult
		local behind = t.root.Position - t.root.CFrame.LookVector * 8
		local y = ctx:groundAt(behind.X, behind.Z)
		if y and ctx:inBounds(behind, 6) then
			ctx:fx("Poof", { pos = obj.root.Position, color = Color3.fromRGB(60, 60, 70) })
			obj.model:PivotTo(CFrame.lookAt(Vector3.new(behind.X, y + obj.radius + 0.5, behind.Z), Vector3.new(t.root.Position.X, y + obj.radius + 0.5, t.root.Position.Z)))
			ctx:fx("Poof", { pos = obj.root.Position, color = Color3.fromRGB(60, 60, 70) })
			ctx:sound("Whoosh", obj.root.Position, 0.7, 1.4)
		end
	end
	if now >= (obj.data.nextThrow or 1.5) then
		obj.data.nextThrow = now + ctx.rng:NextNumber(2, 3)
		local from = obj.root.Position + Vector3.new(0, 1, 0)
		local aim = t.root.Position - from
		local flat = Vector3.new(aim.X, 0, aim.Z)
		if flat.Magnitude > 2 and flat.Magnitude < 70 then
			for _, a in ipairs({ -0.18, 0, 0.18 }) do
				local d = CFrame.fromAxisAngle(Vector3.yAxis, a) * aim
				Robots.fireBolt(ctx, from, from + d, obj.damage, { speed = 95, width = 0.6, color = Color3.fromRGB(200, 205, 215), radius = 3, sound = "Shuriken", volume = 0.5 })
			end
		end
	end
	return true
end

function Ninja.Spawn(ctx)
	CreatureRunner.run(ctx, Ninja)
end

return Ninja
