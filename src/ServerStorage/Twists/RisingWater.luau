-- Rising Water: icy water floods the open ground. Get to high ground!
-- Sharks can swim anywhere below the waterline.
local Terrain = workspace.Terrain

return {
	id = "RisingWater",
	danger = 2,
	Start = function(ctx)
		ctx:fx("Sound", { name = "Bubble", volume = 0.8 })
		local map = ctx.map
		if not map then
			return
		end
		local floorY = map.floorY
		local bottom = floorY - 3
		local maxLevel = floorY + 4.5
		local level = floorY - 1
		local center = map.center
		local function fill(lv)
			local h = lv - bottom
			if h <= 0 then
				return
			end
			if map.shape == "circle" then
				Terrain:FillCylinder(CFrame.new(center.X, bottom + h / 2, center.Z), h, map.radius, Enum.Material.Water)
			else
				local sx = map.bounds.maxX - map.bounds.minX
				local sz = map.bounds.maxZ - map.bounds.minZ
				Terrain:FillBlock(CFrame.new(center.X, bottom + h / 2, center.Z), Vector3.new(sx, h, sz), Enum.Material.Water)
			end
		end
		ctx:fx("Banner", { text = "THE WATER IS RISING!", color = "#5DA9E9" })
		ctx:loop(1, function()
			if level < maxLevel then
				level = math.min(maxLevel, level + 0.35)
				map.risingWaterLevel = level
				fill(level)
			end
		end)
		-- icy water: hurts while you're in it
		local inWater = {}
		ctx:loop(0.25, function(dt)
			for _, t in ipairs(ctx:targets()) do
				local feet = t.root.Position.Y - 2.5
				if feet < (map.risingWaterLevel or -1e9) - 0.6 then
					inWater[t.player] = (inWater[t.player] or 0) + dt
					if inWater[t.player] > 1 then
						ctx:damage(t, 7 * dt)
					end
				else
					inWater[t.player] = nil
				end
			end
		end)
		ctx:onCleanup(function()
			map.risingWaterLevel = nil
			local h = maxLevel + 6 - bottom
			if map.shape == "circle" then
				Terrain:FillCylinder(CFrame.new(center.X, bottom + h / 2, center.Z), h, map.radius + 4, Enum.Material.Air)
			else
				local sx = map.bounds.maxX - map.bounds.minX + 8
				local sz = map.bounds.maxZ - map.bounds.minZ + 8
				Terrain:FillBlock(CFrame.new(center.X, bottom + h / 2, center.Z), Vector3.new(sx, h, sz), Enum.Material.Air)
			end
			if map.refillWater then
				map.refillWater()
			end
		end)
	end,
}
