-- Frozen: freezes you solid for a moment.
local ICE = Color3.fromRGB(160, 215, 255)

local function tint(model: Model)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			p.Color = p.Color:Lerp(ICE, 0.55)
		end
	end
end

return {
	id = "Frozen",
	danger = 2,
	stats = { Speed = 0.9 },
	double = { name = "Arctic", stats = { Speed = 0.85 } },
	hint = { text = "Don't get frozen - keep your distance!", icon = "away", priority = 3 },
	Creature = {
		spawn = function(ctx, level, obj)
			tint(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:freeze(target, 1.4 * level)
		end,
		boltHit = function(ctx, level, target)
			ctx:freeze(target, 1.2 * level)
		end,
	},
	Projectile = {
		spawn = function(ctx, level, obj)
			tint(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:freeze(target, 1.5 * level)
		end,
		impact = function(ctx, level, pos, radius)
			for _, t in ipairs(ctx:targets()) do
				if (t.root.Position - pos).Magnitude <= radius * 1.3 then
					ctx:freeze(t, 1.5 * level)
				end
			end
			ctx:iceAt(pos, radius * 1.2, 6)
		end,
	},
	Terrain = {
		hazardName = function(ctx, level, name)
			return "frost"
		end,
		contact = function(ctx, level, target, tile, dt)
			if not ctx.Status.isFrozen(target.player) and ctx.rng:NextNumber() < 0.08 * level then
				ctx:freeze(target, 1.2)
			end
		end,
	},
	Weather = {
		spawn = function(ctx, level, obj)
			tint(obj.model)
		end,
		hit = function(ctx, level, obj, target)
			ctx:freeze(target, 1.0 * level)
		end,
	},
}
