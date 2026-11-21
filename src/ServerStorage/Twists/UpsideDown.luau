-- Upside Down: controls reversed for 10 s at a time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

return {
	id = "UpsideDown",
	danger = 1,
	Start = function(ctx)
		ctx:fx("Sound", { name = "Whoosh", volume = 0.8 })
		local on = false
		local function setAll(state: boolean)
			on = state
			Net.fireAll("ClientEffect", { kind = "UpsideDown", on = state })
		end
		ctx:delay(1, function()
			setAll(true)
		end)
		local nextFlip = os.clock() + 11
		ctx:loop(0.5, function()
			if os.clock() >= nextFlip then
				if on then
					setAll(false)
					nextFlip = os.clock() + 6
				else
					setAll(true)
					nextFlip = os.clock() + 10
				end
			end
		end)
		ctx:onCleanup(function()
			Net.fireAll("ClientEffect", { kind = "UpsideDown", on = false })
		end)
	end,
}
