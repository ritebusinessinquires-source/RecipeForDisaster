-- Fog: thick fog rolls in. Listen carefully.
local Lighting = game:GetService("Lighting")

return {
	id = "Fog",
	danger = 1,
	Start = function(ctx)
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		local saved = atmo and { Density = atmo.Density, Haze = atmo.Haze, Color = atmo.Color, Decay = atmo.Decay, Offset = atmo.Offset } or nil
		if atmo then
			atmo.Density = 0.72
			atmo.Offset = 0
			atmo.Haze = 3
			atmo.Color = Color3.fromRGB(215, 220, 225)
			atmo.Decay = Color3.fromRGB(190, 195, 200)
		end
		local savedFog = Lighting.FogEnd
		Lighting.FogEnd = 70
		ctx:onCleanup(function()
			if atmo and saved then
				for k, v in pairs(saved) do
					(atmo :: any)[k] = v
				end
			end
			Lighting.FogEnd = savedFog
		end)
	end,
}
