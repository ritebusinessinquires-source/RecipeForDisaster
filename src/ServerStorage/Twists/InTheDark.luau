-- In the Dark: lights out. Players carry a small light; hazards glow faintly.
local Lighting = game:GetService("Lighting")

return {
	id = "InTheDark",
	danger = 1,
	Start = function(ctx)
		ctx:fx("Sound", { name = "Whoosh", volume = 0.8 })
		local saved = {
			ClockTime = Lighting.ClockTime,
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			ExposureCompensation = Lighting.ExposureCompensation,
		}
		Lighting.ClockTime = 0
		Lighting.Brightness = 0.2
		Lighting.Ambient = Color3.fromRGB(10, 10, 20)
		Lighting.OutdoorAmbient = Color3.fromRGB(18, 18, 32)
		Lighting.ExposureCompensation = -0.6
		local glow = Instance.new("Highlight")
		glow.Name = "DarkGlow"
		glow.FillColor = Color3.fromRGB(255, 90, 60)
		glow.FillTransparency = 0.85
		glow.OutlineColor = Color3.fromRGB(255, 120, 80)
		glow.OutlineTransparency = 0.35
		glow.DepthMode = Enum.HighlightDepthMode.Occluded
		glow.Adornee = ctx.hazardsFolder()
		glow.Parent = ctx.folder
		local lights = {}
		ctx:loop(0.5, function()
			for _, t in ipairs(ctx:targets()) do
				if not lights[t.root] or not lights[t.root].Parent then
					local l = Instance.new("PointLight")
					l.Name = "DarkLight"
					l.Range = 20
					l.Brightness = 1.6
					l.Color = Color3.fromRGB(255, 230, 190)
					l.Parent = t.root
					lights[t.root] = l
				end
			end
		end)
		ctx:onCleanup(function()
			for k, v in pairs(saved) do
				(Lighting :: any)[k] = v
			end
			for _, l in pairs(lights) do
				l:Destroy()
			end
		end)
	end,
}
