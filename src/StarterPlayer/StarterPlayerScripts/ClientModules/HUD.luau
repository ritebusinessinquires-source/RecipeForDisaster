-- HUD: course number on an order ticket, phase timer, players alive (chef-hat icon), Cash in
-- a coin jar, active dishes in the corner, lobby menu buttons and the next-unlock bar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local HUD = {}
HUD.onMenu = function(_name: string) end
HUD.onSpectate = function() end

local player = Players.LocalPlayer
local gui: ScreenGui
local ticket: Frame
local courseLabel: TextLabel
local phaseLabel: TextLabel
local timerLabel: TextLabel
local aliveLabel: TextLabel
local cashLabel: TextLabel
local spinsLabel: TextLabel
local dishesFrame: Frame
local menuBar: Frame
local spectateBtn: Frame
local unlockHolder: Frame
local unlockFill: Frame
local unlockLabel: TextLabel
local sdChip: Frame
local practiceChip: Frame
local bigBanner: TextLabel

local shownCash = 0
local targetCash = 0

local PHASE_TEXT = {
	Waiting = "Waiting for players",
	Intermission = "Intermission - vote for a map!",
	Draft = "Chef draft",
	Reveal = "The reveal",
	Cook = "COOK! Survive the dish",
	CourseEnd = "Course over",
	Winner = "We have a winner!",
}

local function buildTicket()
	local holder, face = UI.panel(gui, {
		Name = "Ticket",
		Size = UDim2.fromScale(0.2, 0.13),
		Position = UDim2.new(0.5, 0, 0, 6),
		AnchorPoint = Vector2.new(0.5, 0),
		Rotation = -2,
		Corner = 10,
	})
	UI.new("UISizeConstraint", { MinSize = Vector2.new(190, 70), MaxSize = Vector2.new(330, 120), Parent = holder })
	ticket = holder
	courseLabel = UI.label(face, { Text = "ORDER #0", Title = true, Size = UDim2.fromScale(0.5, 0.4), Position = UDim2.fromScale(0.04, 0.06), XAlign = Enum.TextXAlignment.Left, Color = UI.C.Tomato })
	timerLabel = UI.label(face, { Text = "0:15", Title = true, Size = UDim2.fromScale(0.42, 0.5), Position = UDim2.fromScale(0.55, 0.04), XAlign = Enum.TextXAlignment.Right })
	phaseLabel = UI.label(face, { Text = "", Size = UDim2.fromScale(0.92, 0.38), Position = UDim2.fromScale(0.04, 0.56) })
	-- perforated edge
	for i = 0, 9 do
		UI.new("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.new(0.05 + i * 0.1, 0, 1, -3), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Chocolate, BorderSizePixel = 0, ZIndex = 3, Parent = face }, { UI.new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	end
	local sdh, sdf = UI.panel(gui, { Name = "SuddenDeath", Size = UDim2.fromOffset(200, 34), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0), Color = UI.C.Tomato, Visible = false, Corner = 10 })
	UI.label(sdf, { Text = "🔥 SUDDEN DEATH 🔥", Title = true, Color = UI.C.White, Stroke = 2, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	sdChip = sdh
	local ph, pf = UI.panel(gui, { Name = "Practice", Size = UDim2.fromOffset(230, 30), Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0), Color = UI.C.Grape, Visible = false, Corner = 10 })
	UI.label(pf, { Text = "SOLO PRACTICE - invite friends!", Title = true, Color = UI.C.White, Stroke = 2, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	practiceChip = ph
end

local function buildCorners()
	-- players alive
	local ah, af = UI.panel(gui, { Name = "Alive", Size = UDim2.fromOffset(150, 50), Position = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.zero, Corner = 12 })
	aliveLabel = UI.label(af, { Text = "👨‍🍳 0", Title = true, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	-- coin jar + spins
	local ch, cf = UI.panel(gui, { Name = "CoinJar", Size = UDim2.fromOffset(190, 50), Position = UDim2.new(1, -8, 0, 8), AnchorPoint = Vector2.new(1, 0), Color = UI.C.Mustard, Corner = 12 })
	cashLabel = UI.label(cf, { Text = "💰 0", Title = true, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	local sh, sf = UI.panel(gui, { Name = "Spins", Size = UDim2.fromOffset(110, 40), Position = UDim2.new(1, -8, 0, 66), AnchorPoint = Vector2.new(1, 0), Color = UI.C.Cream, Corner = 12 })
	spinsLabel = UI.label(sf, { Text = "🎡 0", Title = true, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	local spinHit = UI.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = sf })
	spinHit.Activated:Connect(function()
		if not State.isAlive() then
			HUD.onMenu("Spin")
		end
	end)
	-- active dishes
	dishesFrame = UI.new("Frame", { Name = "ActiveDishes", Size = UDim2.new(0.26, 0, 0.5, 0), Position = UDim2.fromOffset(8, 66), BackgroundTransparency = 1, Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(200, 0), MaxSize = Vector2.new(340, 1000), Parent = dishesFrame })
	UI.list(dishesFrame, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Left)
end

local function buildMenuBar()
	menuBar = UI.new("Frame", { Name = "MenuBar", Size = UDim2.new(0.62, 0, 0.11, 0), Position = UDim2.new(0.5, 0, 1, -8), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 64), MaxSize = Vector2.new(760, 96), Parent = menuBar })
	UI.list(menuBar, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local items = {
		{ "Cookbook", "📖 Cookbook", UI.C.Tomato },
		{ "Shop", "🛒 Pantry", UI.C.Basil },
		{ "Daily", "📅 Daily", UI.C.Mustard },
		{ "Ranks", "🏆 Ranks", UI.C.Grape },
	}
	for i, it in ipairs(items) do
		UI.button(menuBar, { Name = it[1], Text = it[2], Color = it[3], Size = UDim2.fromScale(0.23, 1), LayoutOrder = i, MaxText = 26 }, function()
			HUD.onMenu(it[1])
		end)
	end
	spectateBtn = UI.button(gui, { Name = "Spectate", Text = "👻 Spectate", Color = UI.C.Grape, Size = UDim2.fromOffset(170, 60), Position = UDim2.new(1, -8, 1, -84), AnchorPoint = Vector2.new(1, 1), Visible = false }, function()
		HUD.onSpectate()
	end)
	-- progress toward the next affordable ingredient
	local uh, uf = UI.panel(gui, { Name = "NextUnlock", Size = UDim2.new(0.42, 0, 0, 34), Position = UDim2.new(0.5, 0, 1, -112), AnchorPoint = Vector2.new(0.5, 1), Corner = 10 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(260, 30), MaxSize = Vector2.new(560, 40), Parent = uh })
	unlockHolder = uh
	unlockFill = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = UI.C.Basil, BorderSizePixel = 0, ZIndex = 2, Parent = uf }, { UI.new("UICorner", { CornerRadius = UDim.new(0, 10) }) })
	unlockLabel = UI.label(uf, { Text = "", Title = true, ZIndex = 3, Size = UDim2.fromScale(0.96, 0.8), Position = UDim2.fromScale(0.02, 0.1) })
end

function HUD.bigText(text: string, color: Color3?, duration: number?)
	bigBanner.Text = text
	bigBanner.TextColor3 = color or UI.C.Mustard
	bigBanner.Visible = true
	UI.pop(bigBanner)
	local myText = text
	task.delay(duration or 1.6, function()
		if bigBanner.Text == myText then
			UI.shrinkOut(bigBanner)
		end
	end)
end

local HINT_EMOJI = {}
for k, v in pairs(Catalog.HintIcons) do
	HINT_EMOJI[k] = v.emoji
end

function HUD.refreshDishes()
	for _, c in ipairs(dishesFrame:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local list = State.activeDishes()
	for i, d in ipairs(list) do
		if i > 6 then
			break
		end
		local h, f = UI.panel(dishesFrame, { Name = "Dish", Size = UDim2.new(1, 0, 0, 38), AnchorPoint = Vector2.zero, LayoutOrder = i, Color = d.secret and UI.C.Grape or UI.C.Cream, Corner = 10, StrokeThickness = 3 })
		UI.label(f, {
			Text = string.format("%s %s  %s", d.emoji or "🍲", d.name or "?", HINT_EMOJI[d.icon] or ""),
			Title = true,
			Color = d.secret and UI.C.White or UI.C.Chocolate,
			Size = UDim2.fromScale(0.94, 0.8),
			Position = UDim2.fromScale(0.03, 0.1),
			XAlign = Enum.TextXAlignment.Left,
			MaxText = 20,
		})
		if i == 1 then
			UI.pop(h)
		end
	end
end

local function nextUnlock(data: any): (string?, number)
	local best, bestPrice = nil, math.huge
	for _, id in ipairs(Catalog.MainOrder) do
		local m = Catalog.Mains[id]
		if not data.pantry[id] and m.price > 0 and m.price < bestPrice then
			best, bestPrice = id, m.price
		end
	end
	for _, id in ipairs(Catalog.SpiceOrder) do
		local s = Catalog.Spices[id]
		if not data.pantry[id] and s.price > 0 and s.price < bestPrice then
			best, bestPrice = id, s.price
		end
	end
	return best, bestPrice
end

local function refreshData(data: any)
	if not data then
		return
	end
	targetCash = data.cash
	spinsLabel.Text = "🎡 " .. tostring(data.spins)
	local id, price = nextUnlock(data)
	if id then
		local info = Catalog.ingredient(id)
		local have = math.min(data.cash, price)
		unlockLabel.Text = string.format("%s / %s Cash to %s %s", UI.fmt(have), UI.fmt(price), info.emoji, info.name)
		unlockFill.Size = UDim2.fromScale(math.clamp(have / price, 0.02, 1), 1)
		unlockFill.BackgroundColor3 = data.cash >= price and UI.C.Basil or UI.C.Mustard
		if data.cash >= price then
			unlockLabel.Text = info.emoji .. " " .. info.name .. " is ready to buy! Open the Pantry"
		end
	else
		unlockLabel.Text = "Your Pantry is complete! 👨‍🍳"
		unlockFill.Size = UDim2.fromScale(1, 1)
	end
end

local function refreshVisibility()
	local phase = State.get("Phase")
	local alive = State.isAlive()
	local roundActive = State.get("RoundActive") == true
	menuBar.Visible = not alive
	unlockHolder.Visible = not roundActive or not alive
	spectateBtn.Visible = roundActive and not alive
	sdChip.Visible = roundActive and State.get("SuddenDeath") == true
	practiceChip.Visible = roundActive and State.get("Practice") == true and not sdChip.Visible
	dishesFrame.Visible = roundActive
	local course = State.get("Course") or 0
	courseLabel.Text = course > 0 and ("COURSE " .. course) or "LOBBY"
	phaseLabel.Text = PHASE_TEXT[phase] or ""
	if not alive and roundActive then
		phaseLabel.Text = (player:GetAttribute("Ghost") and "👻 Ghost - " or "") .. (PHASE_TEXT[phase] or "")
	end
end

function HUD.init(screen: ScreenGui)
	gui = screen
	buildTicket()
	buildCorners()
	buildMenuBar()
	bigBanner = UI.label(gui, { Name = "BigBanner", Text = "", Title = true, Size = UDim2.fromScale(0.8, 0.12), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), Color = UI.C.Mustard, Stroke = 4, ZIndex = 20 })
	bigBanner.Visible = false

	State.DataChanged:Connect(refreshData)
	if State.data then
		refreshData(State.data)
	end
	for _, attr in ipairs({ "Phase", "RoundActive", "SuddenDeath", "Practice", "Course" }) do
		State.onGame(attr, function()
			refreshVisibility()
		end)
	end
	player:GetAttributeChangedSignal("Alive"):Connect(refreshVisibility)
	player:GetAttributeChangedSignal("Ghost"):Connect(refreshVisibility)
	State.onGame("ActiveDishes", function()
		HUD.refreshDishes()
	end)
	State.onGame("Phase", function(phase)
		if phase == "Cook" then
			HUD.bigText("COOK!", UI.C.Tomato, 1.2)
			UI.sound("Ding", 0.8)
			UI.sound("Sizzle", 0.35)
		elseif phase == "Intermission" then
			HUD.bigText("INTERMISSION", UI.C.Mustard, 1.2)
		end
	end)
	State.onGame("SuddenDeath", function(v)
		if v then
			HUD.bigText("🔥 SUDDEN DEATH 🔥", UI.C.Tomato, 2)
		end
	end)

	-- timer, alive count, cash count-up
	local lastSecond = -1
	RunService.RenderStepped:Connect(function(dt)
		local left = State.timeLeft()
		timerLabel.Text = Util.formatTime(left)
		local sec = math.ceil(left)
		if sec ~= lastSecond then
			lastSecond = sec
			local phase = State.get("Phase")
			if sec <= 3 and sec > 0 and (phase == "Draft" or phase == "Intermission") then
				UI.sound("Tick", 0.5)
			end
		end
		timerLabel.TextColor3 = (left <= 5 and State.get("Phase") ~= "Waiting") and UI.C.Tomato or UI.C.Chocolate
		local roundActive = State.get("RoundActive") == true
		if roundActive then
			aliveLabel.Text = string.format("👨‍🍳 %d / %d", State.get("AliveCount") or 0, State.get("TotalCount") or 0)
		else
			aliveLabel.Text = "👨‍🍳 " .. #Players:GetPlayers() .. " here"
		end
		if shownCash ~= targetCash then
			local diff = targetCash - shownCash
			local step = math.max(1, math.abs(diff) * math.min(1, dt * 6))
			if math.abs(diff) <= step then
				shownCash = targetCash
			else
				shownCash += step * math.sign(diff)
			end
			cashLabel.Text = "💰 " .. UI.fmt(shownCash)
		end
		-- stack the chips under the ticket
		local y = ticket.AbsolutePosition.Y + ticket.AbsoluteSize.Y - gui.AbsolutePosition.Y + 10
		sdChip.Position = UDim2.new(0.5, 0, 0, y)
		practiceChip.Position = UDim2.new(0.5, 0, 0, y)
	end)
	refreshVisibility()
end

return HUD
