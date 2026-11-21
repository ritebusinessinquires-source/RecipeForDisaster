-- Chef draft screens: "Tonight's Chefs" for everyone, and the Chef hand (4 big recipe cards,
-- the slot name and a 10 s kitchen-timer ring) for the Chefs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local Draft = {}

local gui: ScreenGui
local board: Frame
local boardSlots: Frame
local hand: Frame
local cardRow: Frame
local handTitle: TextLabel
local timerHand: Frame
local timerText: TextLabel
local rerollBtn: Frame
local status: TextLabel
local handEndsAt = 0
local picked = false

local thumbCache: { [number]: string } = {}
local function headshot(userId: number): string?
	if userId <= 0 then
		return nil
	end
	if thumbCache[userId] then
		return thumbCache[userId]
	end
	local ok, img = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	if ok then
		thumbCache[userId] = img
		return img
	end
	return nil
end

---------------------------------------------------------------- Tonight's Chefs

local function buildBoard()
	local holder, face = UI.panel(gui, { Name = "TonightsChefs", Size = UDim2.fromScale(0.56, 0.3), Position = UDim2.fromScale(0.5, 0.17), AnchorPoint = Vector2.new(0.5, 0), Color = UI.C.Chocolate, Visible = false })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(330, 150), MaxSize = Vector2.new(720, 260), Parent = holder })
	board = holder
	UI.label(face, { Text = "TONIGHT'S CHEFS", Title = true, Color = UI.C.Mustard, Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.04), Stroke = 2 })
	boardSlots = UI.new("Frame", { Size = UDim2.fromScale(0.94, 0.7), Position = UDim2.fromScale(0.03, 0.26), BackgroundTransparency = 1, ZIndex = 3, Parent = face })
	UI.list(boardSlots, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
end

local function showBoard(payload: any)
	for _, c in ipairs(boardSlots:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for i, chef in ipairs(payload.chefs) do
		local slotColor = chef.slot == "Main" and UI.C.Tomato or UI.C.Mustard
		local h, f = UI.panel(boardSlots, { Name = "Chef" .. i, Size = UDim2.fromScale(0.31, 1), LayoutOrder = i, Color = UI.C.Cream, ZIndex = 4, Rotation = (i - 2) * 1.5 })
		local band = UI.new("Frame", { Size = UDim2.fromScale(1, 0.2), BackgroundColor3 = slotColor, BorderSizePixel = 0, ZIndex = 5, Parent = f })
		UI.corner(band)
		UI.label(band, { Text = chef.slot == "Main" and "MAIN" or "SPICE", Title = true, Color = UI.C.White, Stroke = 2, ZIndex = 6, Size = UDim2.fromScale(0.9, 0.85), Position = UDim2.fromScale(0.05, 0.08) })
		local pic = UI.new("ImageLabel", { Size = UDim2.fromScale(0.42, 0.42), Position = UDim2.fromScale(0.5, 0.25), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.DarkCream, ZIndex = 5, Parent = f })
		UI.aspect(pic, 1)
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pic })
		UI.stroke(pic, 2)
		if chef.isBot then
			UI.label(pic, { Text = "🤖", ZIndex = 6 })
		else
			task.spawn(function()
				local img = headshot(chef.userId)
				if img then
					pic.Image = img
				end
			end)
		end
		UI.label(f, { Text = chef.name .. (chef.isGhost and " 👻" or ""), Title = true, Size = UDim2.fromScale(0.92, 0.16), Position = UDim2.fromScale(0.04, 0.68), ZIndex = 5, MaxText = 22 })
		local steam = UI.label(f, { Text = "♨️ cooking...", Size = UDim2.fromScale(0.92, 0.13), Position = UDim2.fromScale(0.04, 0.85), ZIndex = 5, Color = Color3.fromHex("8A6A55"), MaxText = 16 })
		steam:SetAttribute("Steam", true)
		UI.pop(h, (i - 1) * 0.12)
	end
	board.Visible = true
	UI.pop(board)
end

---------------------------------------------------------------- Chef hand

local function buildHand()
	hand = UI.new("Frame", { Name = "ChefHand", Size = UDim2.fromScale(0.9, 0.48), Position = UDim2.new(0.5, 0, 1, -10), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 5, Parent = gui })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(1000, 420), Parent = hand })
	handTitle = UI.label(hand, { Text = "Pick the MAIN", Title = true, Size = UDim2.fromScale(0.7, 0.14), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0), Color = UI.C.Mustard, Stroke = 3, ZIndex = 6 })
	status = UI.label(hand, { Text = "", Title = true, Size = UDim2.fromScale(0.7, 0.1), Position = UDim2.fromScale(0.5, 0.14), AnchorPoint = Vector2.new(0.5, 0), Color = UI.C.White, Stroke = 2, ZIndex = 6 })
	cardRow = UI.new("Frame", { Size = UDim2.fromScale(1, 0.72), Position = UDim2.fromScale(0, 0.27), BackgroundTransparency = 1, ZIndex = 6, Parent = hand })
	UI.list(cardRow, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	-- kitchen timer ring
	local th, tf = UI.panel(hand, { Name = "Timer", Size = UDim2.fromScale(0.11, 0.24), Position = UDim2.fromScale(0.02, 0.0), AnchorPoint = Vector2.zero, Aspect = 1, Corner = 100, Color = UI.C.White })
	UI.minSize(th, 64, 64)
	-- GUI rotation pivots on the centre, so the needle lives in a full-size rotating frame
	timerHand = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 4, Parent = tf })
	UI.new("Frame", { Size = UDim2.fromScale(0.07, 0.4), Position = UDim2.fromScale(0.5, 0.1), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Tomato, BorderSizePixel = 0, ZIndex = 4, Parent = timerHand })
	timerText = UI.label(tf, { Text = "10", Title = true, Size = UDim2.fromScale(0.5, 0.4), Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
	rerollBtn = UI.button(hand, { Name = "Reroll", Text = "🔄 Reroll", Color = UI.C.Grape, Size = UDim2.fromScale(0.16, 0.16), Position = UDim2.fromScale(0.98, 0.02), AnchorPoint = Vector2.new(1, 0), MinWidth = 120, Visible = false }, function()
		Net.event("PromptPurchase"):FireServer({ kind = "product", key = "RerollHand" })
	end)
end

local function cardInfo(id: string, slot: string): (string, string, string?)
	if slot == "Main" then
		local m = Catalog.Mains[id]
		return m.emoji, m.name, Catalog.Types[m.type].name
	end
	local s = Catalog.Spices[id]
	return s.emoji, s.name, s.blurb
end

local function showHand(offer: any)
	picked = false
	handEndsAt = offer.endsAt or (workspace:GetServerTimeNow() + 10)
	for _, c in ipairs(cardRow:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local slotName = offer.slot == "Main" and "MAIN" or "SPICE"
	handTitle.Text = (offer.slot == "Main" and "Pick the " or "Pick a ") .. slotName .. "!"
	status.Text = "Your pick stays secret until the reveal"
	local n = #offer.cards
	local slotColor = offer.slot == "Main" and UI.C.Tomato or UI.C.Mustard
	local holders = {}
	for i, id in ipairs(offer.cards) do
		local emoji, name, sub = cardInfo(id, offer.slot)
		local rot = (i - (n + 1) / 2) * 3
		local holder
		holder = UI.recipeCard(cardRow, {
			Name = id,
			Size = UDim2.fromScale(0.18, 1),
			Rotation = rot,
			LayoutOrder = i,
			SlotColor = slotColor,
			SlotText = slotName,
			Emoji = emoji,
			Text = name,
			Sub = sub,
			ZIndex = 7,
			OnClick = function()
				if picked then
					return
				end
				picked = true
				Net.event("PickIngredient"):FireServer(id)
				UI.sound("Stamp")
				for _, h in ipairs(holders) do
					if h ~= holder then
						UI.tween(h, 0.2, { Size = UDim2.fromScale(0.12, 0.7) })
						for _, d in ipairs(h:GetDescendants()) do
							if d:IsA("GuiObject") then
								d.BackgroundTransparency = math.max(d.BackgroundTransparency, 0.5)
							end
						end
					end
				end
				UI.pop(holder)
				status.Text = "Locked in! Waiting for the other Chefs..."
				rerollBtn.Visible = false
			end,
		})
		table.insert(holders, holder)
		UI.pop(holder, (i - 1) * 0.06)
	end
	rerollBtn.Visible = offer.canReroll == true
	hand.Visible = true
	board.Position = UDim2.fromScale(0.5, 0.12)
	UI.sound("Pop")
end

local function hideAll()
	hand.Visible = false
	if board.Visible then
		UI.shrinkOut(board)
	end
	board.Position = UDim2.fromScale(0.5, 0.17)
end

function Draft.init(screen: ScreenGui)
	gui = screen
	buildBoard()
	buildHand()
	Net.event("TonightsChefs").OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and payload.chefs then
			showBoard(payload)
		end
	end)
	Net.event("OfferHand").OnClientEvent:Connect(function(offer)
		if type(offer) == "table" and offer.cards then
			showHand(offer)
		end
	end)
	Net.event("PickConfirmed").OnClientEvent:Connect(function(p)
		if type(p) == "table" and p.auto then
			status.Text = "Time's up! A random card was played."
			picked = true
			rerollBtn.Visible = false
		end
	end)
	State.onGame("Phase", function(phase)
		if phase ~= "Draft" then
			hideAll()
		end
	end)
	RunService.RenderStepped:Connect(function()
		if hand.Visible then
			local left = math.max(0, handEndsAt - workspace:GetServerTimeNow())
			timerText.Text = tostring(math.ceil(left))
			timerHand.Rotation = (1 - left / 10) * 360
			timerText.TextColor3 = left < 4 and UI.C.Tomato or UI.C.Chocolate
		end
		if board.Visible then
			local t = os.clock()
			for _, d in ipairs(boardSlots:GetDescendants()) do
				if d:IsA("TextLabel") and d:GetAttribute("Steam") then
					d.TextTransparency = 0.3 + math.sin(t * 4) * 0.3
				end
			end
		end
	end)
end

return Draft
