-- Ghost spectate: cycle the camera through the players still alive.

local Players = game:GetService("Players")
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local Spectate = {}

local player = Players.LocalPlayer
local index = 0
local active = false
local label: TextLabel

local function aliveOthers(): { Player }
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p:GetAttribute("Alive") and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
			table.insert(out, p)
		end
	end
	return out
end

function Spectate.stop()
	active = false
	label.Visible = false
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		workspace.CurrentCamera.CameraSubject = hum
	end
end

function Spectate.next()
	local list = aliveOthers()
	if #list == 0 then
		Spectate.stop()
		return
	end
	index = (index % #list) + 1
	if index > #list then
		index = 1
	end
	local target = list[index]
	local hum = target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		active = true
		workspace.CurrentCamera.CameraSubject = hum
		label.Text = "👀 Watching " .. target.DisplayName .. "  (" .. index .. "/" .. #list .. ") - tap Spectate again for next"
		label.Visible = true
	end
end

function Spectate.toggle()
	if active and #aliveOthers() <= 1 then
		Spectate.stop()
	else
		Spectate.next()
	end
end

function Spectate.init(gui: ScreenGui)
	label = UI.label(gui, { Text = "", Title = true, Size = UDim2.new(0.6, 0, 0, 30), Position = UDim2.new(0.5, 0, 1, -160), AnchorPoint = Vector2.new(0.5, 1), Color = UI.C.White, Stroke = 2.5, ZIndex = 15 })
	label.Visible = false
	State.onGame("RoundActive", function(activeRound)
		if not activeRound and active then
			Spectate.stop()
		end
	end)
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if State.isAlive() and active then
			Spectate.stop()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			if active then
				local subject = workspace.CurrentCamera.CameraSubject
				local model = subject and subject.Parent
				local p = model and Players:GetPlayerFromCharacter(model)
				if not p or not p:GetAttribute("Alive") then
					Spectate.next()
				end
			end
		end
	end)
end

return Spectate
