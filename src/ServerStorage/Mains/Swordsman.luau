-- Swordsman (Creature): sends sword slashes skimming along the ground. Jump over them or
-- stand on something high; low cover stops them.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local CreatureRunner = require(HazardLib.CreatureRunner)

local Swordsman = {
	id = "Swordsman",
	type = "Creature",
	danger = 4,
	stats = { Size = 1, Speed = 12, Count = 3, Damage = 24, Health = 110 },
	hint = { text = "Jump over the slashes or climb up high!", icon = "raised" },
	creature = { mode = "ground", radius = 1.5, turnRate = 240, cooldown = 1.1, knock = 35, poofColor = Color3.fromRGB(220, 235, 255) },
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include

function Swordsman.slash(ctx, from: Vector3, dir: Vector3, length: number, damage: number)
	local ground = ctx:groundAt(from.X, from.Z) or from.Y - 2
	local start = Vector3.new(from.X, ground + 1.2, from.Z)
	ctx:fx("Wave", { from = start, dir = dir, length = length, duration = 0.45, color = Color3.fromRGB(220, 235, 255) })
	ctx:sound("Slash", start, 0.8)
	ctx:delay(0.25, function()
		for _, t in ipairs(ctx:targets()) do
			local rel = t.root.Position - start
			local along = rel:Dot(dir)
			local side = (rel - dir * along)
			local feet = t.root.Position.Y - 2.6
			if along > 0 and along < length and Vector3.new(side.X, 0, side.Z).Magnitude < 3 and feet < ground + 2.2 then
				-- low cover between the swordsman and you stops the slash
				local blocked = false
				if ctx.map and ctx.map.model then
					rayParams.FilterDescendantsInstances = { ctx.map.model }
					local hit = workspace:Raycast(start, dir * along, rayParams)
					blocked = hit ~= nil and hit.Instance.Parent ~= (ctx.tiles and ctx.tiles.folder)
				end
				if not blocked then
					ctx:damage(t, damage)
					ctx:knockback(t, dir * 40 + Vector3.new(0, 35, 0))
				end
			end
		end
	end)
end

function Swordsman.step(ctx, obj, dt)
	CreatureRunner.defaultStep(ctx, obj, dt)
	local now = os.clock()
	local t = obj.target
	if t and now >= (obj.data.nextSlash or 1.5) then
		local d = t.root.Position - obj.root.Position
		local flat = Vector3.new(d.X, 0, d.Z)
		if flat.Magnitude < 30 and flat.Magnitude > 1 then
			obj.data.nextSlash = now + ctx.rng:NextNumber(2.4, 3.2) / ctx.rampMult
			Swordsman.slash(ctx, obj.root.Position, flat.Unit, 38 * math.sqrt(ctx.stats.Size), obj.damage)
		end
	end
	return true
end

function Swordsman.Spawn(ctx)
	CreatureRunner.run(ctx, Swordsman)
end

return Swordsman
