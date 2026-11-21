-- Invisible: only a shimmer and a sound give it away.
local function vanish(model: Model, level: number)
	local alpha = level >= 2 and 0.985 or 0.9
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then
			p.Transparency = alpha
			p.CastShadow = false
		elseif p:IsA("PointLight") then
			p.Enabled = false
		end
	end
	local root = model.PrimaryPart
	if root then
		local shimmer = Instance.new("ParticleEmitter")
		shimmer.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		shimmer.Color = ColorSequence.new(Color3.fromRGB(220, 240, 255))
		shimmer.Size = NumberSequence.new(root.Size.X * 0.25, 0)
		shimmer.Transparency = NumberSequence.new(level >= 2 and 0.6 or 0.3, 1)
		shimmer.Lifetime = NumberRange.new(0.4, 0.8)
		shimmer.Rate = level >= 2 and 4 or 10
		shimmer.Speed = NumberRange.new(0.5, 2)
		shimmer.LightEmission = 0.6
		shimmer.Parent = root
	end
end

return {
	id = "Invisible",
	danger = 2,
	stats = {},
	double = { name = "Phantom", stats = {} },
	hint = { text = "Look for the shimmer and listen!", icon = "run", priority = 4 },
	Creature = {
		spawn = function(ctx, level, obj)
			vanish(obj.model, level)
		end,
	},
	Projectile = {
		spawn = function(ctx, level, obj)
			vanish(obj.model, level)
		end,
		-- falling ones: the client hides the meteor and only shows its shadow late
	},
	Terrain = {
		-- handled by TerrainRunner: tiles keep the floor look with a faint tint
	},
	Weather = {
		spawn = function(ctx, level, obj)
			vanish(obj.model, level)
		end,
	},
}
