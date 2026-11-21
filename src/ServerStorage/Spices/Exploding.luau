-- Exploding: blows up on contact.
return {
	id = "Exploding",
	danger = 3,
	stats = {},
	double = { name = "Megaton", stats = {} },
	hint = { text = "Keep your distance - they explode!", icon = "away", priority = 5 },
	Creature = {
		spawn = function(ctx, level, obj)
			for _, p in ipairs(obj.model:GetDescendants()) do
				if p:IsA("BasePart") and p.Name == "Body" then
					p.Color = p.Color:Lerp(Color3.fromRGB(255, 60, 40), 0.35)
				end
			end
		end,
		hit = function(ctx, level, obj, target)
			local r = (7 + obj.radius * 1.5) * (level == 2 and 1.6 or 1)
			ctx:explode(obj.root.Position, r, obj.damage * 1.6, { knock = 60 * level })
			obj:destroy(ctx)
			return true
		end,
	},
	Projectile = {
		impact = function(ctx, level, pos, radius)
			ctx:explode(pos, radius * 1.5 * (level == 2 and 1.4 or 1), ctx.stats.Damage * 1.25, { knock = 65 })
			return true
		end,
		hit = function(ctx, level, obj, target)
			ctx:explode(obj.root.Position, obj.radius * 3 * level, obj.damage * 1.3, { knock = 80 })
			obj:destroy(ctx)
			return true
		end,
	},
	Terrain = {
		-- pools erupt every few seconds
		spreadTick = function(ctx, level, owned)
			local now = os.clock()
			if #owned > 0 and now >= (ctx.nextEruption or 0) then
				ctx.nextEruption = now + 2.2 / level
				local t = owned[ctx.rng:NextInteger(1, #owned)]
				local pos = Vector3.new(t.center.X, t.topY + 1, t.center.Z)
				ctx:fx("Warning", { pos = pos, radius = 10, duration = 0.8, color = Color3.fromRGB(255, 80, 40) })
				ctx:delay(0.8, function()
					ctx:explode(pos, 10 * level, 25, { knock = 50 })
				end)
			end
		end,
	},
	Weather = {
		-- the twister flings explosive debris
		tick = function(ctx, level, obj, dt)
			local now = os.clock()
			if now >= (obj.data.nextBomb or 0) then
				obj.data.nextBomb = now + 2.4 / level
				local p = obj.root.Position + Vector3.new(ctx.rng:NextNumber(-30, 30), 0, ctx.rng:NextNumber(-30, 30))
				local y = ctx:groundAt(p.X, p.Z)
				if y then
					local landing = Vector3.new(p.X, y, p.Z)
					ctx:fx("Arc", { from = obj.root.Position + Vector3.new(0, 20, 0), to = landing, duration = 1.1, style = "bomb" })
					ctx:delay(1.1, function()
						ctx:explode(landing, 9, 25, { knock = 55 })
					end)
				end
			end
		end,
	},
}
