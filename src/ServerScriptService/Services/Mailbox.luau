-- Mailbox: rewards for players who aren't in this server (gifted passes, invite rewards).
-- Delivered the next time they join.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Mailbox = {}

local store: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(Config.MailboxStoreName)
end)

function Mailbox.send(userId: number, item: any): boolean
	if not store or userId <= 0 then
		return false
	end
	local ok = pcall(function()
		(store :: DataStore):UpdateAsync("m_" .. userId, function(old)
			old = old or {}
			if #old < 50 then
				table.insert(old, item)
			end
			return old
		end)
	end)
	return ok
end

-- Returns and clears every item waiting for this user.
function Mailbox.collect(userId: number): { any }
	if not store or userId <= 0 then
		return {}
	end
	local items = {}
	pcall(function()
		(store :: DataStore):UpdateAsync("m_" .. userId, function(old)
			items = old or {}
			if #items == 0 then
				return nil
			end
			return {}
		end)
	end)
	return items
end

return Mailbox
