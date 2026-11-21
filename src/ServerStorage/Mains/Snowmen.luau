-- Snowmen (seasonal Creature, December): waddle after you and throw freezing snowballs.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)
local Robots = require(script.Parent.Robots)

local Snowmen = {
	id = "Snowmen",
	type = "Creature",
	danger = 3,
	seasonal = true,
	stats = { Size = 1, Speed = 8, Count = 6, Damage = 12, Health = 70 },
	hint = { text = "Hide behind low cover - dodge the snowballs!", icon = "cover" },
	creature = { mode = "ground", radius = 1.6, turnRate = 180, cooldown = 1.2, knock = 18, poofColor = Color3.fromRGB(245, 250, 255) },
}

function Snowmen.step(ctx, obj, dt)
	CreatureRunner.defaultStep(ctx, obj, dt)
	local now = os.clock()
	local t = obj.target
	if t and now >= (obj.data.nextThrow or 0) then
		local dist = (t.root.Position - obj.root.Position).Magnitude
		if dist < 60 then
			obj.data.nextThrow = now + ctx.rng:NextNumber(2.5, 3.5)
			local muzzle = obj.root.Position + Vector3.new(0, 3 * ctx.stats.Size, 0)
			Robots.fireBolt(ctx, muzzle, t.root.Position, obj.damage, {
				speed = 60,
				color = Color3.fromRGB(240, 250, 255),
				width = 1.4,
				onHit = function(target)
					ctx:freeze(target, 1.0)
				end,
			})
		end
	end
	return true
end

function Snowmen.Spawn(ctx)
	CreatureRunner.run(ctx, Snowmen)
end

return Snowmen
