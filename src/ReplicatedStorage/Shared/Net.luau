-- Remote definitions. The server creates them; clients wait for them.
-- Remotes the design doc names: OfferHand, PickIngredient, RevealDish, GhostVote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

Net.Events = {
	"OfferHand", -- server -> chef: { slot, cards, endsAt, course, canReroll }
	"PickIngredient", -- chef -> server: cardId
	"PickConfirmed", -- server -> chef: cardId
	"RevealDish", -- server -> all: dish reveal payload
	"GhostVote", -- ghost -> server: twistId
	"GhostVoteOptions", -- server -> ghosts: { options, counts, endsAt } / nil to close
	"MapVote", -- player -> server: mapId
	"MapVoteState", -- server -> all: { options, counts, blocked, endsAt }
	"TonightsChefs", -- server -> all: { chefs = { {name, userId, slot} } }
	"Eliminated", -- server -> victim: recipe card payload
	"BecomeGhost", -- victim -> server
	"Winner", -- server -> all
	"CourseResults", -- server -> all: wipeout banners
	"DataSync", -- server -> player: profile snapshot
	"Toast", -- server -> player: { text, kind, cash }
	"FX", -- server -> all: visual effect
	"Knockback", -- server -> player: velocity
	"Taunt", -- server -> all: { userId, tauntId }
	"Spectate", -- client -> server (unused payload) / server -> client targets
	"Rumble", -- server -> all: camera shake
	"ClientEffect", -- server -> player: { kind, ... } (freeze overlay, upside down, etc.)
	"PromptPurchase", -- client -> server: { kind, key, target }
}

Net.Functions = {
	"ShopAction", -- client -> server: (action, args) -> result
	"GetCookbook",
	"GetLeaderboards",
}

local folder: Folder? = nil

local function getFolder(): Folder
	if folder then
		return folder
	end
	if RunService:IsServer() then
		local f = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
		if not f then
			local newFolder = Instance.new("Folder")
			newFolder.Name = "Remotes"
			for _, name in ipairs(Net.Events) do
				local r = Instance.new("RemoteEvent")
				r.Name = name
				r.Parent = newFolder
			end
			for _, name in ipairs(Net.Functions) do
				local r = Instance.new("RemoteFunction")
				r.Name = name
				r.Parent = newFolder
			end
			newFolder.Parent = ReplicatedStorage
			f = newFolder
		end
		folder = f
	else
		folder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
	end
	return folder :: Folder
end

function Net.event(name: string): RemoteEvent
	return getFolder():WaitForChild(name) :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return getFolder():WaitForChild(name) :: RemoteFunction
end

local function isRealPlayer(p: any): boolean
	return typeof(p) == "Instance" and p:IsA("Player") and p.Parent ~= nil
end
Net.isRealPlayer = isRealPlayer

-- Server helpers: safe for test participants (plain tables) and departed players.
function Net.fire(player: any, name: string, ...)
	if isRealPlayer(player) then
		Net.event(name):FireClient(player, ...)
	end
end

function Net.fireAll(name: string, ...)
	Net.event(name):FireAllClients(...)
end

function Net.fireList(players: { any }, name: string, ...)
	for _, p in ipairs(players) do
		Net.fire(p, name, ...)
	end
end

-- Shared game state lives in attributes on this folder (replicates to late joiners).
function Net.stateFolder(): Folder
	local f = ReplicatedStorage:FindFirstChild("GameState") :: Folder?
	if f then
		return f
	end
	if RunService:IsServer() then
		local nf = Instance.new("Folder")
		nf.Name = "GameState"
		nf.Parent = ReplicatedStorage
		return nf
	end
	return ReplicatedStorage:WaitForChild("GameState") :: Folder
end

return Net
