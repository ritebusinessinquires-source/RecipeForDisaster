-- Bouncy: boing! Big knockback, things bounce.
local ServerStorage = game:GetService("ServerStorage")

return {
	id = "Bouncy",
	danger = 1,
	stats = {},
	double = { name = "Super Bouncy", stats = {} },
	hint = { text = "Watch out for knockback - stay away from edges!", icon = "away", priority = 1 },
	Creature = {
		spawn = function(ctx, level, obj)
			obj.data.extraHop = 30 * level
			obj.knock *= 1.8 * level
		end,
		hit = function(ctx, level, obj, target)
			local d = target.root.Position - obj.root.Position
			local flat = Vector3.new(d.X, 0, d.Z)
			flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.xAxis
			ctx:knockback(target, flat * 40 * level + Vector3.new(0, 55 * level, 0))
		end,
	},
	Projectile = {
		impact = function(ctx, level, pos, radius)
			if ctx._bouncing then
				return
			end
			local ProjectileRunner = require(ServerStorage.HazardLib.ProjectileRunner)
			local hops = level + 1
			local from = pos
			local delayAcc = 0
			for i = 1, hops do
				local dir = Vector3.new(ctx.rng:NextNumber(-1, 1), 0, ctx.rng:NextNumber(-1, 1))
				dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.xAxis
				local nx = from + dir * ctx.rng:NextNumber(10, 22)
				local y = ctx:groundAt(nx.X, nx.Z)
				if not y or not ctx:inBounds(nx) then
					break
				end
				local to = Vector3.new(nx.X, y, nx.Z)
				local dur = 0.7
				local startAt = delayAcc
				local fromCopy = from
				ctx:delay(startAt, function()
					ctx:fx("Arc", { from = fromCopy + Vector3.new(0, 2, 0), to = to, duration = dur, style = "meteor", size = ctx.stats.Size })
				end)
				ctx:delay(startAt + dur, function()
					ctx._bouncing = true
					ProjectileRunner.impact(ctx, to, radius * (1 - i * 0.15), ctx.stats.Damage * 0.6)
					ctx._bouncing = false
				end)
				delayAcc += dur
				from = to
			end
		end,
		hit = function(ctx, level, obj, target)
			ctx:knockback(target, obj.dir * 50 * level + Vector3.new(0, 70 * level, 0))
		end,
		-- rolling/driving things bounce off the arena edge instead of leaving
		edge = function(ctx, level, obj)
			local c = ctx.map and ctx.map.center or Vector3.zero
			local inward = Vector3.new(c.X - obj.root.Position.X, 0, c.Z - obj.root.Position.Z)
			if inward.Magnitude > 0.1 then
				local jitter = Vector3.new(ctx.rng:NextNumber(-0.4, 0.4), 0, ctx.rng:NextNumber(-0.4, 0.4))
				obj.data.fixedDir = (inward.Unit + jitter).Unit
				obj.root.AssemblyLinearVelocity = obj.data.fixedDir * obj.speed + Vector3.new(0, 25, 0)
				obj.bornAt = os.clock() - 4
			end
			return true
		end,
	},
	Terrain = {
		contact = function(ctx, level, target, tile, dt)
			if ctx.rng:NextNumber() < 0.12 then
				ctx:knockback(target, Vector3.new(ctx.rng:NextNumber(-15, 15), 70 * level, ctx.rng:NextNumber(-15, 15)))
			end
		end,
	},
	Weather = {
		hit = function(ctx, level, obj, target)
			if ctx.rng:NextNumber() < 0.15 then
				ctx:knockback(target, Vector3.new(0, 110 * level, 0))
			end
		end,
	},
}
