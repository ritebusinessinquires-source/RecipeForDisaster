-- Recipe for Disaster: client entry point. Clients only show cards, the reveal and the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local player = Players.LocalPlayer
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Modules = script.Parent:WaitForChild("ClientModules")

local UI = require(Modules.UI)
local State = require(Modules.State)
local HUD = require(Modules.HUD)
local Toasts = require(Modules.Toasts)
local MapVote = require(Modules.MapVote)
local Draft = require(Modules.Draft)
local Reveal = require(Modules.Reveal)
local Results = require(Modules.Results)
local Menus = require(Modules.Menus)
local Effects = require(Modules.Effects)
local Spectate = require(Modules.Spectate)

State.init()

local hudGui = UI.screen("RFD_HUD", 1)
local roundGui = UI.screen("RFD_Round", 5)
local menuGui = UI.screen("RFD_Menus", 10)
local topGui = UI.screen("RFD_Top", 20)

HUD.init(hudGui)
Toasts.init(topGui)
MapVote.init(roundGui)
Draft.init(roundGui)
Reveal.init(roundGui)
Results.init(roundGui)
Menus.init(menuGui)
Effects.init(topGui)
Spectate.init(hudGui)

HUD.onMenu = function(name: string)
	if Menus.isOpen() then
		Menus.close()
		task.wait(0.22)
	end
	if name == "Lobby" then
		Toasts.show("Heading back to the lobby... 🏠", "info")
		Net.event("ReturnToLobby"):FireServer()
		return
	end
	if name == "Spin" then
		Menus.openTab("Shop", "Spin")
	elseif name == "Ranks" or name == "Cookbook" or name == "Shop" or name == "Daily" then
		Menus.open(name)
	end
end
HUD.onSpectate = function()
	Spectate.toggle()
end
Reveal.shake = Effects.shake
Effects.banner = function(text: string, color: Color3?, small: boolean?)
	HUD.bigText(text, color, small and 1 or 1.8)
end
Results.confetti = function()
	Effects.confetti(topGui)
end

-- matchmaking / teleport messages
Net.event("TeleportNotice").OnClientEvent:Connect(function(n)
	if type(n) == "table" and n.text then
		Toasts.show(n.text, n.kind == "error" and "big" or "quest")
		if n.kind == "go" then
			HUD.bigText(n.text, UI.C.Basil, 3)
		end
	end
end)

-- VIP name tag colour in chat
pcall(function()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local props = Instance.new("TextChatMessageProperties")
		local src = message.TextSource
		if src then
			local p = Players:GetPlayerByUserId(src.UserId)
			if p and p:GetAttribute("VIP") then
				props.PrefixText = "<font color='#FFC93C'>[VIP]</font> " .. message.PrefixText
			end
		end
		return props
	end
end)

-- first-time welcome
task.delay(3, function()
	local data = State.data
	if data and data.stats and data.stats.rounds == 0 then
		Toasts.show("Welcome to Recipe for Disaster! 3 Chefs cook, everyone survives. 👨‍🍳", "big")
		task.wait(5)
		Toasts.show("Tip: claim your daily reward in 📅 Daily and try code WELCOME!", "quest")
	end
end)
