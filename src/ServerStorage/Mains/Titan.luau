-- Titan (Creature): a towering giant. Every few steps it stomps, sending a shockwave ring
-- across the ground. Jump the ring!
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Titan = {
	id = "Titan",
	type = "Creature",
	danger = 4,
	stats = { Size = 1, Speed = 7, Count = 1, Damage = 35, Health = 999 },
	hint = { text = "Jump the shockwaves - stay out from under its feet!", icon = "run" },
	creature = { mode = "ground", radius = 5.25, turnRate = 70, cooldown = 1.3, knock = 75, accel = 400, respawnDelay = 4, poofColor = Color3.fromRGB(200, 180, 160) },
}

function Titan.stomp(ctx, center: Vector3, maxR: number, damage: number, key: any)
	ctx:rumble(1.4, 0.6)
	ctx:sound("Stomp", center, 1)
	ctx:fx("Shockwave", { pos = center, radius = maxR, duration = 1.2 })
	for i = 1, 6 do
		ctx:delay(i * 0.2, function()
			local r = i / 6 * maxR
			for _, t in ipairs(ctx:targets()) do
				local d = t.root.Position - center
				local flat = Vector3.new(d.X, 0, d.Z).Magnitude
				if math.abs(flat - r) < 4 and t.humanoid.FloorMaterial ~= Enum.Material.Air then
					ctx:damage(t, damage * 0.6)
					ctx:knockback(t, Vector3.new(0, 50, 0))
				end
			end
		end)
	end
end

function Titan.step(ctx, obj, dt)
	CreatureRunner.defaultStep(ctx, obj, dt)
	local now = os.clock()
	if now >= (obj.data.nextStomp or 2) then
		obj.data.nextStomp = now + ctx.rng:NextNumber(3.5, 4.5) / ctx.rampMult
		local p = obj.root.Position
		local y = ctx:groundAt(p.X, p.Z) or (p.Y - obj.radius)
		Titan.stomp(ctx, Vector3.new(p.X, y, p.Z), 40 * math.sqrt(ctx.stats.Size), obj.damage)
	end
	return true
end

function Titan.build(s, ctx)
	local Models = require(HazardLib.Models)
	return Models.Titan(s, ctx)
end

function Titan.Spawn(ctx)
	CreatureRunner.run(ctx, Titan)
end

return Titan
