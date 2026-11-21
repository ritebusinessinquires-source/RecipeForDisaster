-- Badges: always recorded in-game (shown in the Cookbook); also awarded as a Roblox badge
-- when Config.Badges has an id for it.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))

local Badges = {}

function Badges.award(player: any, badgeKey: string)
	local data = PlayerData.get(player)
	if not data or data.badges[badgeKey] then
		return
	end
	data.badges[badgeKey] = true
	PlayerData.sync(player)
	local info
	for _, b in ipairs(Catalog.Badges) do
		if b.id == badgeKey then
			info = b
		end
	end
	if info then
		Net.fire(player, "Toast", { text = "Badge earned: " .. info.emoji .. " " .. info.name, kind = "badge" })
	end
	local id = Config.Badges[badgeKey]
	if id and id > 0 and Net.isRealPlayer(player) then
		task.spawn(function()
			pcall(function()
				BadgeService:AwardBadge(player.UserId, id)
			end)
		end)
	end
end

return Badges
