-- Fighter (Creature): a martial-arts brawler that dashes at you and fires energy blasts.
-- Anime fighters and superheroes typed by players become this. Low cover blocks the blasts.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)
local Robots = require(script.Parent.Robots)

local Fighter = {
	id = "Fighter",
	type = "Creature",
	danger = 4,
	sound = "Charge",
	stats = { Size = 1, Speed = 13, Count = 3, Damage = 18, Health = 120 },
	hint = { text = "Hide behind low cover - it blocks energy blasts!", icon = "cover" },
	creature = { mode = "ground", radius = 1.5, turnRate = 260, cooldown = 1.0, knock = 45, poofColor = Color3.fromRGB(255, 201, 60) },
}

function Fighter.step(ctx, obj, dt)
	local now = os.clock()
	obj.speedMult = (obj.data.dashUntil and now < obj.data.dashUntil) and 3 or 1
	CreatureRunner.defaultStep(ctx, obj, dt)
	local t = obj.target
	if not t then
		return true
	end
	local dist = (t.root.Position - obj.root.Position).Magnitude
	if now >= (obj.data.nextDash or 2) and dist < 50 then
		obj.data.nextDash = now + ctx.rng:NextNumber(4, 6)
		obj.data.dashUntil = now + 0.6
		ctx:sound("Whoosh", obj.root.Position, 0.6)
	end
	if now >= (obj.data.nextBlast or 1.5) and dist < 80 then
		obj.data.nextBlast = now + ctx.rng:NextNumber(2.4, 3.4) / ctx.rampMult
		local s = ctx.stats.Size
		local muzzle = obj.root.Position + Vector3.new(0, 1 * s, 0) + obj.dir * (obj.radius + 1)
		ctx:fx("Charge", { pos = muzzle, duration = 0.45 })
		ctx:delay(0.45, function()
			if obj.alive and t.root.Parent then
				local lead = t.root.AssemblyLinearVelocity * Vector3.new(1, 0, 1) * 0.25
				Robots.fireBolt(ctx, muzzle, t.root.Position + lead, obj.damage, { speed = 110, width = 1.8 * math.max(0.6, s), color = Color3.fromRGB(120, 220, 255), radius = 5, sound = "Blast", volume = 0.7 })
			end
		end)
	end
	return true
end

function Fighter.Spawn(ctx)
	CreatureRunner.run(ctx, Fighter)
end

return Fighter
