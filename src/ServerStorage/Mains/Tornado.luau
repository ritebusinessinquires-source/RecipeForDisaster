-- Tornado (Weather): a wandering twister that pulls everyone in and flings anyone it catches.
local HazardLib = game:GetService("ServerStorage"):WaitForChild("HazardLib")
local WeatherRunner = require(HazardLib.WeatherRunner)

local Tornado = {
	id = "Tornado",
	type = "Weather",
	danger = 4,
	sound = "Wind",
	stats = { Size = 1, Speed = 9, Count = 1, Damage = 25, Health = 1 },
	hint = { text = "Stay in the open and run from the funnel!", icon = "run" },
	weather = { coreRadius = 6, pullRadius = 45, pullStrength = 14 },
}

function Tornado.Spawn(ctx)
	WeatherRunner.run(ctx, Tornado)
end

return Tornado
