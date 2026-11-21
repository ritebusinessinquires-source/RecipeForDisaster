-- Low Gravity: floaty jumps and slow-falling projectiles.
return {
	id = "LowGravity",
	danger = 0,
	Start = function(ctx)
		ctx:fx("Sound", { name = "Chime", volume = 0.8 })
		local saved = workspace.Gravity
		workspace.Gravity = 62
		ctx:onCleanup(function()
			workspace.Gravity = saved
		end)
	end,
}
