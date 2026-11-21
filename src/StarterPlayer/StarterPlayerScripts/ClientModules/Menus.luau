-- Lobby menus: Cookbook, Pantry shop (ingredients, spin wheel, cosmetics, passes, codes),
-- Daily (login calendar, quests, Dish of the Day, free Spin) and weekly Ranks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Catalog = require(Shared.Catalog)
local Cosmetics = require(Shared.Cosmetics)
local Quests = require(Shared.Quests)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Toasts = require(script.Parent.Toasts)

local Menus = {}

local player = Players.LocalPlayer
local gui: ScreenGui
local window: Frame
local windowFace: Frame
local titleLabel: TextLabel
local tabBar: Frame
local content: ScrollingFrame
local current: string? = nil
local currentTab: string? = nil
local renderers: { [string]: any } = {}

local function shop(action: string, args: any?): any
	local ok, res = pcall(function()
		return Net.func("ShopAction"):InvokeServer(action, args)
	end)
	if not ok or type(res) ~= "table" then
		return { ok = false, msg = "Couldn't reach the kitchen. Try again!" }
	end
	return res
end
Menus.shop = shop

local function clear()
	for _, c in ipairs(content:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	content.CanvasPosition = Vector2.zero
end

local function section(text: string, order: number)
	return UI.label(content, { Text = text, Title = true, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = order, XAlign = Enum.TextXAlignment.Left, Color = UI.C.Tomato, MaxText = 28 })
end

local function grid(order: number, cellW: number, cellH: number): Frame
	local g = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = order, Parent = content })
	UI.new("UIGridLayout", { CellSize = UDim2.fromOffset(cellW, cellH), CellPadding = UDim2.fromOffset(10, 12), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, Parent = g })
	return g
end

local function row(order: number, height: number): Frame
	local r = UI.new("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = order, Parent = content })
	return r
end

local function buildWindow()
	local h, f = UI.panel(gui, { Name = "MenuWindow", Size = UDim2.fromScale(0.82, 0.8), Position = UDim2.fromScale(0.5, 0.5), Visible = false, ZIndex = 70 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(330, 300), MaxSize = Vector2.new(1000, 720), Parent = h })
	window, windowFace = h, f
	local band = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = UI.C.Tomato, BorderSizePixel = 0, ZIndex = 71, Parent = f })
	UI.corner(band)
	titleLabel = UI.label(band, { Text = "", Title = true, Color = UI.C.White, Stroke = 2.5, Size = UDim2.new(1, -150, 0.8, 0), Position = UDim2.new(0, 16, 0.1, 0), XAlign = Enum.TextXAlignment.Left, ZIndex = 72, MaxText = 36 })
	UI.button(band, { Name = "Close", Text = "✖", Color = UI.C.Chocolate, Size = UDim2.fromOffset(60, 60), Position = UDim2.new(1, -4, 0, -2), AnchorPoint = Vector2.new(1, 0), ZIndex = 75 }, function()
		Menus.close()
	end)
	tabBar = UI.new("Frame", { Size = UDim2.new(1, -24, 0, 62), Position = UDim2.new(0, 12, 0, 62), BackgroundTransparency = 1, ZIndex = 71, Parent = f })
	UI.list(tabBar, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	content = UI.new("ScrollingFrame", {
		Size = UDim2.new(1, -24, 1, -140),
		Position = UDim2.new(0, 12, 0, 130),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = UI.C.Chocolate,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ZIndex = 71,
		Parent = f,
	})
	UI.list(content, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Center)
	UI.new("UIPadding", { PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), Parent = content })
end

local function setTabs(tabs: { { string } }, onPick: (string) -> ())
	for _, c in ipairs(tabBar:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	tabBar.Visible = #tabs > 0
	content.Position = #tabs > 0 and UDim2.new(0, 12, 0, 130) or UDim2.new(0, 12, 0, 66)
	content.Size = #tabs > 0 and UDim2.new(1, -24, 1, -140) or UDim2.new(1, -24, 1, -76)
	for i, t in ipairs(tabs) do
		UI.button(tabBar, { Name = t[1], Text = t[2], Color = (currentTab == t[1]) and UI.C.Tomato or UI.C.Mustard, Size = UDim2.new(0, 150, 0, 56), LayoutOrder = i, MaxText = 22, ZIndex = 72 }, function()
			currentTab = t[1]
			onPick(t[1])
			setTabs(tabs, onPick)
		end)
	end
end

function Menus.open(name: string)
	if not renderers[name] then
		return
	end
	current = name
	currentTab = nil
	window.Visible = true
	UI.pop(window)
	renderers[name]()
end

-- open a menu straight on a tab (e.g. the Spins counter opens the wheel)
function Menus.openTab(name: string, tab: string)
	if not renderers[name] then
		return
	end
	current = name
	currentTab = tab
	window.Visible = true
	UI.pop(window)
	renderers[name]()
end

function Menus.close()
	current = nil
	if window.Visible then
		UI.shrinkOut(window)
	end
end

function Menus.isOpen(): boolean
	return window.Visible
end

local function rerender()
	if current and window.Visible and renderers[current] then
		renderers[current](true)
	end
end

---------------------------------------------------------------- Cookbook

renderers.Cookbook = function()
	titleLabel.Text = "📖 COOKBOOK"
	setTabs({}, function() end)
	clear()
	UI.label(content, { Text = "Loading your recipes...", Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1 })
	task.spawn(function()
		local ok, book = pcall(function()
			return Net.func("GetCookbook"):InvokeServer()
		end)
		if current ~= "Cookbook" then
			return
		end
		clear()
		if not ok or not book then
			UI.label(content, { Text = "Couldn't open the Cookbook. Try again!", Size = UDim2.new(1, 0, 0, 40) })
			return
		end
		UI.label(content, { Text = string.format("Dishes found: %s / %s", UI.fmt(book.count), UI.fmt(book.total)), Title = true, Size = UDim2.new(1, 0, 0, 44), LayoutOrder = 1, MaxText = 34 })
		-- badges
		section("Badges", 2)
		local bg = grid(3, 150, 74)
		for i, b in ipairs(Catalog.Badges) do
			local have = book.badges and book.badges[b.id]
			local h, f = UI.panel(bg, { Name = b.id, LayoutOrder = i, Color = have and UI.C.Mustard or Color3.fromHex("D9CFC0"), Corner = 12, StrokeThickness = 3 })
			UI.label(f, { Text = (have and b.emoji or "🔒") .. " " .. b.name, Title = true, Size = UDim2.fromScale(0.92, 0.5), Position = UDim2.fromScale(0.04, 0.05), MaxText = 18 })
			UI.label(f, { Text = b.desc, Size = UDim2.fromScale(0.92, 0.38), Position = UDim2.fromScale(0.04, 0.58), MaxText = 14 })
		end
		-- secret recipes
		section(string.format("Secret recipes (%d / %d)%s", (function()
			local n = 0
			for _, s in ipairs(book.secrets) do
				if s.found then
					n += 1
				end
			end
			return n
		end)(), #book.secrets, book.hasHints and "  - Recipe Hints on" or ""), 4)
		local sg = grid(5, 200, 120)
		for i, s in ipairs(book.secrets) do
			local h, f = UI.panel(sg, { Name = s.id, LayoutOrder = i, Color = s.found and UI.C.Grape or Color3.fromHex("4A3A55"), Corner = 12, StrokeThickness = 3 })
			if s.found then
				UI.label(f, { Text = s.emoji .. " " .. s.name, Title = true, Color = UI.C.White, Stroke = 2, Size = UDim2.fromScale(0.92, 0.3), Position = UDim2.fromScale(0.04, 0.04), MaxText = 20 })
				UI.label(f, { Text = s.ingredients or "", Color = UI.C.White, Size = UDim2.fromScale(0.92, 0.26), Position = UDim2.fromScale(0.04, 0.34), MaxText = 14 })
				UI.label(f, { Text = s.desc or "", Color = Color3.fromHex("E6DDFF"), Size = UDim2.fromScale(0.92, 0.34), Position = UDim2.fromScale(0.04, 0.62), MaxText = 12 })
			else
				UI.label(f, { Text = "❓ ??? ", Title = true, Color = Color3.fromHex("BFA8E0"), Size = UDim2.fromScale(0.92, 0.4), Position = UDim2.fromScale(0.04, 0.08) })
				UI.label(f, { Text = s.hint or "Cook the right combo to find it!", Color = Color3.fromHex("BFA8E0"), Size = UDim2.fromScale(0.92, 0.38), Position = UDim2.fromScale(0.04, 0.55), MaxText = 15 })
			end
		end
		if not book.hasHints and Config.GamePasses.RecipeHints.id > 0 then
			local r = row(6, 64)
			UI.button(r, { Text = "📜 Recipe Hints: see one ingredient of every secret (R$ " .. Config.GamePasses.RecipeHints.price .. ")", Color = UI.C.Grape, Size = UDim2.fromScale(0.9, 1), Position = UDim2.fromScale(0.05, 0), MaxText = 22 }, function()
				Net.event("PromptPurchase"):FireServer({ kind = "pass", key = "RecipeHints" })
			end)
		end
		-- found dishes
		section("Dishes you've survived or cooked", 7)
		local dg = grid(8, 220, 50)
		local shown = 0
		for i, e in ipairs(book.entries) do
			shown += 1
			if shown > 400 then
				break
			end
			local h, f = UI.panel(dg, { Name = "Dish", LayoutOrder = i, Color = e.secret and UI.C.Grape or UI.C.White, Corner = 10, StrokeThickness = 2 })
			UI.label(f, { Text = (e.emoji or "🍲") .. " " .. e.name, Title = true, Color = e.secret and UI.C.White or UI.C.Chocolate, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), MaxText = 16 })
		end
		if #book.entries == 0 then
			UI.label(content, { Text = "Nothing yet - survive or cook a dish to add it!", Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 9 })
		elseif #book.entries > 400 then
			UI.label(content, { Text = "...and " .. (#book.entries - 400) .. " more!", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 9 })
		end
	end)
end

---------------------------------------------------------------- Shop

local spinning = false

local function wheel(parent: Instance, order: number)
	local holder = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 330), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
	local disc = UI.new("Frame", { Size = UDim2.fromOffset(300, 300), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.White, Parent = holder })
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disc })
	UI.stroke(disc, 5)
	local colors = { common = UI.C.Basil, cash = UI.C.Mustard, ingredient = UI.C.Tomato, epic = UI.C.Grape, legendary = Color3.fromHex("FF8FB8") }
	local total = 0
	for _, o in ipairs(Config.SpinOdds) do
		total += o.weight
	end
	-- 72 spokes form the pie; each segment gets spokes in proportion to its odds
	local ranges = {}
	local acc = 0
	for _, o in ipairs(Config.SpinOdds) do
		local a0 = acc / total * 360
		acc += o.weight
		local a1 = acc / total * 360
		ranges[o.id] = { a0, a1 }
	end
	local SPOKES = 90
	for i = 0, SPOKES - 1 do
		local ang = (i + 0.5) / SPOKES * 360
		local seg = "common"
		for id, r in pairs(ranges) do
			if ang >= r[1] and ang < r[2] then
				seg = id
			end
		end
		local rot = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Rotation = ang, Parent = disc })
		UI.new("Frame", { Size = UDim2.new(0, 12, 0.5, -4), Position = UDim2.new(0.5, 0, 0, 4), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = colors[seg], BorderSizePixel = 0, Parent = rot })
	end
	-- segment labels with odds (shown on the wheel)
	for _, o in ipairs(Config.SpinOdds) do
		local r = ranges[o.id]
		local mid = math.rad((r[1] + r[2]) / 2)
		local radius = (o.weight < 5) and 0.47 or 0.3
		local lbl = UI.label(disc, { Text = o.label .. "\n" .. o.weight .. "%", Title = true, Color = UI.C.White, Stroke = 2, Size = UDim2.fromOffset(110, 40), Position = UDim2.new(0.5 + math.sin(mid) * radius, 0, 0.5 - math.cos(mid) * radius, 0), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5, MaxText = 14 })
		if o.weight < 5 then
			lbl.Position = UDim2.new(0.5 + math.sin(mid) * 0.62, 0, 0.5 - math.cos(mid) * 0.62, 0)
			lbl.TextColor3 = UI.C.Chocolate
		end
	end
	local hub = UI.new("Frame", { Size = UDim2.fromOffset(54, 54), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Chocolate, ZIndex = 6, Parent = disc })
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hub })
	local pointer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 7, Parent = disc })
	UI.new("Frame", { Size = UDim2.new(0, 10, 0.44, 0), Position = UDim2.new(0.5, 0, 0.06, 0), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Chocolate, BorderSizePixel = 0, ZIndex = 7, Parent = pointer })
	UI.label(pointer, { Text = "▲", Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0.5, 0, 0.02, 0), AnchorPoint = Vector2.new(0.5, 0), Color = UI.C.Chocolate, ZIndex = 8 })
	return pointer, ranges
end

local function renderIngredients()
	clear()
	local data = State.data or { pantry = {}, cash = 0 }
	UI.label(content, { Text = "Your Chef hand is drawn only from your Pantry - more ingredients, more control!", Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 0, MaxText = 20 })
	local function card(g: Frame, id: string, info: any, slot: string, order: number)
		local owned = data.pantry[id]
		local h, f = UI.panel(g, { Name = id, LayoutOrder = order, Color = owned and Color3.fromHex("E9F6E5") or UI.C.Cream, Corner = 12, StrokeThickness = 3 })
		local band = UI.new("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = slot == "Main" and UI.C.Tomato or UI.C.Mustard, BorderSizePixel = 0, ZIndex = 3, Parent = f })
		UI.corner(band, 6)
		UI.label(f, { Text = info.emoji, Size = UDim2.fromScale(0.5, 0.36), Position = UDim2.fromScale(0.25, 0.06) })
		UI.label(f, { Text = info.name, Title = true, Size = UDim2.fromScale(0.9, 0.16), Position = UDim2.fromScale(0.05, 0.42), MaxText = 22 })
		UI.label(f, { Text = slot == "Main" and Catalog.Types[info.type].name or (info.blurb or ""), Size = UDim2.fromScale(0.9, 0.14), Position = UDim2.fromScale(0.05, 0.58), MaxText = 13, Color = Color3.fromHex("6B4A35") })
		if owned then
			UI.label(f, { Text = "✅ In your Pantry", Title = true, Size = UDim2.fromScale(0.9, 0.18), Position = UDim2.fromScale(0.05, 0.76), Color = UI.C.Basil, MaxText = 18 })
		elseif info.seasonal then
			UI.label(f, { Text = "🎉 Event only", Title = true, Size = UDim2.fromScale(0.9, 0.18), Position = UDim2.fromScale(0.05, 0.76), Color = UI.C.Grape, MaxText = 18 })
		else
			local afford = data.cash >= info.price
			UI.button(f, { Text = "💰 " .. UI.fmt(info.price), Color = afford and UI.C.Basil or Color3.fromHex("BDB3A3"), Size = UDim2.fromScale(0.86, 0.22), Position = UDim2.fromScale(0.07, 0.75), MaxText = 20, ZIndex = 4 }, function()
				local res = shop("buyIngredient", { id = id })
				Toasts.show(res.msg or "", res.ok and "quest" or "info")
				if res.ok then
					UI.sound("Coin", 0.8)
				end
			end)
		end
	end
	section("Mains", 1)
	local mg = grid(2, 170, 210)
	for i, id in ipairs(Catalog.MainOrder) do
		card(mg, id, Catalog.Mains[id], "Main", i)
	end
	for i, id in ipairs(Catalog.SeasonalOrder) do
		card(mg, id, Catalog.Mains[id], "Main", 100 + i)
	end
	section("Spices", 3)
	local sg = grid(4, 170, 210)
	for i, id in ipairs(Catalog.SpiceOrder) do
		card(sg, id, Catalog.Spices[id], "Spice", i)
	end
end

local function renderSpin()
	clear()
	local data = State.data or { spins = 0 }
	UI.label(content, { Text = "🎡 Spins: " .. tostring(data.spins), Title = true, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 0 })
	local pointer, ranges = wheel(content, 1)
	local resultLabel = UI.label(content, { Text = "Spin to win cosmetics, Cash and rare ingredients!", Title = true, Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 2, MaxText = 24 })
	local r = row(3, 66)
	UI.button(r, { Text = "SPIN!", Color = UI.C.Tomato, Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromScale(0.3, 0), MaxText = 34 }, function()
		if spinning then
			return
		end
		local res = shop("spin")
		if not res.ok then
			Toasts.show(res.msg or "No Spins left", "info")
			return
		end
		spinning = true
		local seg = res.result.segment or "cash"
		local range = ranges[seg] or { 0, 30 }
		local target = math.random() * (range[2] - range[1]) * 0.7 + range[1] + (range[2] - range[1]) * 0.15
		pointer.Rotation = pointer.Rotation % 360
		local final = 360 * 5 + target
		UI.sound("DrumRoll", 0.6)
		local tw = UI.tween(pointer, 2.6, { Rotation = final }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		tw.Completed:Connect(function()
			spinning = false
			resultLabel.Text = "You got: " .. res.result.label
			UI.pop(resultLabel)
			UI.sound("Fanfare", 0.8)
		end)
	end)
	section("Get more Spins", 4)
	local pg = grid(5, 200, 90)
	for i, key in ipairs({ "Spin1", "Spin5", "Spin15" }) do
		local p = Config.Products[key]
		if p.id > 0 then
			local h, f = UI.panel(pg, { LayoutOrder = i, Corner = 12, StrokeThickness = 3 })
			UI.label(f, { Text = "🎡 " .. p.spins .. " Spin" .. (p.spins > 1 and "s" or ""), Title = true, Size = UDim2.fromScale(0.9, 0.4), Position = UDim2.fromScale(0.05, 0.04) })
			UI.button(f, { Text = "R$ " .. p.price, Color = UI.C.Basil, Size = UDim2.fromScale(0.8, 0.46), Position = UDim2.fromScale(0.1, 0.5), MaxText = 22 }, function()
				Net.event("PromptPurchase"):FireServer({ kind = "product", key = key })
			end)
		end
	end
	UI.label(content, { Text = "Spinning a rare ingredient you already own turns it into Cash. Odds are shown on the wheel.", Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 6, MaxText = 16 })
end

local function renderCosmetics()
	clear()
	local data = State.data
	if not data then
		return
	end
	for si, slot in ipairs(Cosmetics.SlotOrder) do
		local info = Cosmetics.Slots[slot]
		section(info.emoji .. " " .. info.name, si * 10)
		local g = grid(si * 10 + 1, 160, 120)
		local ids = {}
		for id, item in pairs(Cosmetics.Items) do
			if item.slot == slot then
				table.insert(ids, id)
			end
		end
		local order = { default = 0, common = 1, epic = 2, legendary = 3, exclusive = 4 }
		table.sort(ids, function(a, b)
			local ia, ib = Cosmetics.Items[a], Cosmetics.Items[b]
			if order[ia.rarity] ~= order[ib.rarity] then
				return order[ia.rarity] < order[ib.rarity]
			end
			return ia.name < ib.name
		end)
		for i, id in ipairs(ids) do
			local item = Cosmetics.Items[id]
			local owned = data.cosmetics.owned[id]
			local equipped = data.cosmetics.equipped[slot] == id
			local h, f = UI.panel(g, { LayoutOrder = i, Color = equipped and Color3.fromHex("E9F6E5") or UI.C.Cream, Corner = 12, StrokeThickness = 3 })
			local swatch = UI.new("Frame", { Size = UDim2.fromOffset(30, 30), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Color3.fromHex(item.color), ZIndex = 3, Parent = f })
			UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = swatch })
			UI.stroke(swatch, 2)
			UI.label(f, { Text = item.name, Title = true, Size = UDim2.new(1, -50, 0, 34), Position = UDim2.new(0, 44, 0, 6), XAlign = Enum.TextXAlignment.Left, MaxText = 16 })
			UI.label(f, { Text = string.upper(item.rarity), Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 42), Color = Color3.fromHex(Cosmetics.RarityColors[item.rarity] or "#BDB3A3"), MaxText = 14, XAlign = Enum.TextXAlignment.Left })
			if owned then
				UI.button(f, { Text = equipped and "Equipped" or "Equip", Color = equipped and UI.C.Basil or UI.C.Mustard, Size = UDim2.new(1, -16, 0, 50), Position = UDim2.new(0, 8, 1, -56), MaxText = 20, ZIndex = 4 }, function()
					local res = shop("equip", { id = id })
					Toasts.show(res.msg or "", "info")
				end)
			else
				UI.label(f, { Text = "🔒 " .. (item.source or "Win it from Spins"), Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 1, -52), MaxText = 14, Color = Color3.fromHex("8A6A55") })
			end
		end
	end
	-- taunts
	local passes = State.passes()
	section("😘 Chef Taunts" .. (passes.ChefTaunts and "" or " (Chef Taunts pass)"), 100)
	local tg = grid(101, 160, 70)
	for i, t in ipairs(Catalog.Taunts) do
		local selected = data.taunt == t.id
		UI.button(tg, { Text = t.emoji .. " " .. t.name, Color = selected and UI.C.Basil or (passes.ChefTaunts and UI.C.Mustard or Color3.fromHex("BDB3A3")), LayoutOrder = i, MaxText = 18 }, function()
			if not passes.ChefTaunts then
				Net.event("PromptPurchase"):FireServer({ kind = "pass", key = "ChefTaunts" })
				return
			end
			local res = shop("setTaunt", { id = t.id })
			Toasts.show(res.msg or "", "info")
		end)
	end
end

local PASS_INFO = {
	{ "VIP", "⭐ VIP Chef", "Gold chef hat, VIP tag & chat colour, 1.5x Cash, 1 extra free Spin per day" },
	{ "DoubleCash", "💰 2x Cash", "Double Cash from every source (stacks with VIP for 3x)" },
	{ "BiggerHand", "🃏 Bigger Hand", "5 cards instead of 4 when you are Chef" },
	{ "RecipeHints", "📜 Recipe Hints", "Shows one ingredient of every locked secret recipe" },
	{ "ChefTaunts", "😘 Chef Taunts", "6 emotes that play when your dish eliminates someone" },
}

local function renderPasses()
	clear()
	local passes = State.passes()
	section("Game Passes (one-time, permanent)", 1)
	local g = grid(2, 290, 150)
	for i, p in ipairs(PASS_INFO) do
		local cfg = Config.GamePasses[p[1]]
		local h, f = UI.panel(g, { LayoutOrder = i, Corner = 12, StrokeThickness = 3, Color = passes[p[1]] and Color3.fromHex("E9F6E5") or UI.C.Cream })
		UI.label(f, { Text = p[2], Title = true, Size = UDim2.new(1, -16, 0, 34), Position = UDim2.new(0, 8, 0, 6), XAlign = Enum.TextXAlignment.Left, MaxText = 24 })
		UI.label(f, { Text = p[3], Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 0, 40), XAlign = Enum.TextXAlignment.Left, MaxText = 15 })
		if passes[p[1]] then
			UI.label(f, { Text = "✅ Owned", Title = true, Size = UDim2.new(0.5, 0, 0, 50), Position = UDim2.new(0, 8, 1, -56), Color = UI.C.Basil })
		elseif cfg.id > 0 then
			UI.button(f, { Text = "R$ " .. cfg.price, Color = UI.C.Basil, Size = UDim2.new(0.45, 0, 0, 52), Position = UDim2.new(0, 8, 1, -58), MaxText = 22 }, function()
				Net.event("PromptPurchase"):FireServer({ kind = "pass", key = p[1] })
			end)
		else
			UI.label(f, { Text = "Coming soon", Size = UDim2.new(0.5, 0, 0, 50), Position = UDim2.new(0, 8, 1, -56) })
		end
		if cfg.id > 0 and Config.Products["Gift" .. p[1]] and Config.Products["Gift" .. p[1]].id > 0 then
			UI.button(f, { Text = "🎁 Gift", Color = UI.C.Grape, Size = UDim2.new(0.42, 0, 0, 52), Position = UDim2.new(1, -8, 1, -58), AnchorPoint = Vector2.new(1, 0), MaxText = 22 }, function()
				Menus.giftPicker(p[1], p[2])
			end)
		end
	end
	section("Cash Jars", 3)
	local cg = grid(4, 200, 100)
	for i, key in ipairs({ "CashS", "CashM", "CashL" }) do
		local p = Config.Products[key]
		if p.id > 0 then
			local h, f = UI.panel(cg, { LayoutOrder = i, Corner = 12, StrokeThickness = 3, Color = UI.C.Mustard })
			UI.label(f, { Text = "💰 " .. UI.fmt(p.cash) .. " Cash", Title = true, Size = UDim2.fromScale(0.9, 0.4), Position = UDim2.fromScale(0.05, 0.04) })
			UI.button(f, { Text = "R$ " .. p.price, Color = UI.C.Basil, Size = UDim2.fromScale(0.8, 0.46), Position = UDim2.fromScale(0.1, 0.5), MaxText = 22 }, function()
				Net.event("PromptPurchase"):FireServer({ kind = "product", key = key })
			end)
		end
	end
	UI.label(content, { Text = "Nothing you can buy protects you from a hazard or brings you back to life.", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 6, MaxText = 15, Color = Color3.fromHex("8A6A55") })
end

local function renderCodes()
	clear()
	section("Codes", 1)
	UI.label(content, { Text = "New codes drop with every weekly update on our group page!", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2, MaxText = 18 })
	local r = row(3, 66)
	local boxHolder, boxFace = UI.panel(r, { Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromScale(0, 0), AnchorPoint = Vector2.zero, Color = UI.C.White, Corner = 12 })
	local box = UI.new("TextBox", { Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), BackgroundTransparency = 1, Text = "", PlaceholderText = "Enter a code", Font = UI.Theme.TitleFont, TextScaled = true, TextColor3 = UI.C.Chocolate, ClearTextOnFocus = false, ZIndex = 4, Parent = boxFace })
	UI.button(r, { Text = "Redeem", Color = UI.C.Basil, Size = UDim2.new(0.36, 0, 1, 0), Position = UDim2.fromScale(0.64, 0), MaxText = 26 }, function()
		local res = shop("redeemCode", { code = box.Text })
		Toasts.show(res.msg or "", res.ok and "big" or "info")
		if res.ok then
			box.Text = ""
		end
	end)
end

renderers.Shop = function(refresh: boolean?)
	titleLabel.Text = "🛒 PANTRY SHOP"
	local tabs = { { "Ingredients", "🥕 Ingredients" }, { "Spin", "🎡 Spin" }, { "Cosmetics", "👨‍🍳 Style" }, { "Passes", "⭐ Passes" }, { "Codes", "🎟️ Codes" } }
	local function pick(t)
		if t == "Ingredients" then
			renderIngredients()
		elseif t == "Spin" then
			renderSpin()
		elseif t == "Cosmetics" then
			renderCosmetics()
		elseif t == "Passes" then
			renderPasses()
		elseif t == "Codes" then
			renderCodes()
		end
	end
	currentTab = currentTab or "Ingredients"
	setTabs(tabs, pick)
	if not (refresh and currentTab == "Spin") then
		pick(currentTab)
	end
end

function Menus.giftPicker(passKey: string, passName: string)
	clear()
	titleLabel.Text = "🎁 GIFT " .. string.upper(passName)
	local res = shop("giftTargets")
	local list = res.ok and res.list or {}
	if #list == 0 then
		UI.label(content, { Text = "Nobody else is in the server to gift to yet!", Size = UDim2.new(1, 0, 0, 40), LayoutOrder = 1 })
		return
	end
	local g = grid(1, 220, 70)
	for i, p in ipairs(list) do
		UI.button(g, { Text = p.name, Color = UI.C.Grape, LayoutOrder = i, MaxText = 22 }, function()
			Net.event("PromptPurchase"):FireServer({ kind = "gift", key = passKey, target = p.userId })
		end)
	end
end

---------------------------------------------------------------- Daily

renderers.Daily = function()
	titleLabel.Text = "📅 DAILY KITCHEN"
	setTabs({}, function() end)
	clear()
	local data = State.data
	if not data then
		return
	end
	local d = data.daily
	section(string.format("Login streak - week %d", d.streakWeeks + 1), 1)
	local cal = grid(2, 110, 120)
	for day = 1, 7 do
		local reward = Config.LoginCalendar[day]
		local isToday = day == d.streakDay
		local claimed = day < d.streakDay or (isToday and d.claimedDay == Util.dayNumber())
		local h, f = UI.panel(cal, { LayoutOrder = day, Color = isToday and UI.C.Mustard or (claimed and Color3.fromHex("E9F6E5") or UI.C.Cream), Corner = 12, StrokeThickness = 3 })
		UI.label(f, { Text = "Day " .. day, Title = true, Size = UDim2.fromScale(0.9, 0.24), Position = UDim2.fromScale(0.05, 0.04) })
		local txt = reward.cash and ("💰 " .. UI.fmt(reward.cash)) or ("🎡 x" .. reward.spins)
		if reward.weeklyHat then
			txt ..= "\n+ 🎩 hat"
		end
		UI.label(f, { Text = txt, Title = true, Size = UDim2.fromScale(0.9, 0.44), Position = UDim2.fromScale(0.05, 0.3), MaxText = 20 })
		UI.label(f, { Text = claimed and "✅" or (isToday and "TODAY" or ""), Title = true, Size = UDim2.fromScale(0.9, 0.2), Position = UDim2.fromScale(0.05, 0.76), Color = UI.C.Tomato })
	end
	local r = row(3, 64)
	local canClaim = d.claimedDay ~= Util.dayNumber()
	UI.button(r, { Text = canClaim and "Claim today's reward!" or "Come back tomorrow!", Color = canClaim and UI.C.Basil or Color3.fromHex("BDB3A3"), Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.fromScale(0.2, 0), MaxText = 26 }, function()
		local res = shop("claimLogin")
		Toasts.show(res.msg or "", res.ok and "big" or "info")
	end)
	UI.label(content, { Text = "Missing a day restarts the current week, not your whole streak.", Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 4, MaxText = 15, Color = Color3.fromHex("8A6A55") })

	section("Daily quests (all 3 = 1 Spin)", 5)
	for i, q in ipairs(d.quests or {}) do
		local def = Quests.get(q.id)
		if def then
			local h, f = UI.panel(content, { LayoutOrder = 5 + i, Size = UDim2.new(1, 0, 0, 78), AnchorPoint = Vector2.zero, Corner = 12, StrokeThickness = 3, Color = q.claimed and Color3.fromHex("E9F6E5") or UI.C.Cream })
			UI.label(f, { Text = def.text, Title = true, Size = UDim2.new(0.62, 0, 0, 30), Position = UDim2.new(0, 10, 0, 6), XAlign = Enum.TextXAlignment.Left, MaxText = 22 })
			local bar = UI.new("Frame", { Size = UDim2.new(0.6, 0, 0, 20), Position = UDim2.new(0, 10, 0, 44), BackgroundColor3 = UI.C.DarkCream, ZIndex = 3, Parent = f })
			UI.corner(bar, 8)
			UI.stroke(bar, 2)
			UI.new("Frame", { Size = UDim2.fromScale(math.clamp(q.progress / def.target, 0, 1), 1), BackgroundColor3 = UI.C.Basil, ZIndex = 4, Parent = bar }, { UI.new("UICorner", { CornerRadius = UDim.new(0, 8) }) })
			UI.label(bar, { Text = q.progress .. " / " .. def.target, Title = true, ZIndex = 5, MaxText = 16 })
			local done = q.progress >= def.target
			UI.button(f, { Text = q.claimed and "Claimed" or (done and ("Claim 💰" .. def.reward) or ("💰" .. def.reward)), Color = (done and not q.claimed) and UI.C.Basil or Color3.fromHex("BDB3A3"), Size = UDim2.new(0.32, 0, 0, 60), Position = UDim2.new(1, -8, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), MaxText = 20 }, function()
				local res = shop("claimQuest", { index = i })
				Toasts.show(res.msg or "", res.ok and "quest" or "info")
			end)
		end
	end

	task.spawn(function()
		local info = shop("dailyInfo")
		if current ~= "Daily" or not info.ok then
			return
		end
		section("⭐ Dish of the Day (2x Cash)", 20)
		local h, f = UI.panel(content, { LayoutOrder = 21, Size = UDim2.new(1, 0, 0, 70), AnchorPoint = Vector2.zero, Corner = 12, StrokeThickness = 3, Color = UI.C.Mustard })
		UI.label(f, { Text = info.dishOfDay.emoji .. " " .. info.dishOfDay.name .. " - survive it or cook it for double Cash!", Title = true, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), MaxText = 24 })
		section("Freebies", 22)
		local fr = grid(23, 280, 80)
		local spinReady = info.freeSpinIn <= 0
		UI.button(fr, { Text = spinReady and ("🎡 Free daily Spin" .. (info.vip and " x2" or "")) or ("🎡 Next free Spin in " .. Util.formatDuration(info.freeSpinIn)), Color = spinReady and UI.C.Basil or Color3.fromHex("BDB3A3"), LayoutOrder = 1, MaxText = 20 }, function()
			local res = shop("claimFreeSpin")
			Toasts.show(res.msg or "", res.ok and "big" or "info")
		end)
		if not data.groupSpin then
			UI.button(fr, { Text = "👥 Join our group: free Spin", Color = UI.C.Grape, LayoutOrder = 2, MaxText = 20 }, function()
				local res = shop("claimGroupSpin")
				Toasts.show(res.msg or "", res.ok and "big" or "info")
			end)
		end
		UI.button(fr, { Text = "📨 Invite friends (+" .. Config.Economy.ReferralReward .. ")", Color = UI.C.Tomato, LayoutOrder = 3, MaxText = 20 }, function()
			pcall(function()
				local opts = Instance.new("ExperienceInviteOptions")
				opts.PromptMessage = "Cook up some chaos with me in Recipe for Disaster!"
				SocialService:PromptGameInvite(player, opts)
			end)
		end)
		UI.button(fr, { Text = "🔔 Notify me about new ingredients", Color = UI.C.Mustard, LayoutOrder = 4, MaxText = 18 }, function()
			pcall(function()
				game:GetService("ExperienceNotificationService"):PromptOptIn()
			end)
			shop("notifyPrompted")
		end)
		UI.label(content, { Text = "🆕 Next ingredient drop in " .. Util.formatDuration(info.nextDrop), Title = true, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 24, MaxText = 22 })
	end)
end

---------------------------------------------------------------- Ranks

renderers.Ranks = function()
	titleLabel.Text = "🏆 LEADERBOARDS"
	setTabs({}, function() end)
	clear()
	UI.label(content, { Text = "Loading...", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1 })
	task.spawn(function()
		local ok, lb = pcall(function()
			return Net.func("GetLeaderboards"):InvokeServer()
		end)
		if current ~= "Ranks" then
			return
		end
		clear()
		if not ok or type(lb) ~= "table" then
			UI.label(content, { Text = "Couldn't load the leaderboards.", Size = UDim2.new(1, 0, 0, 30) })
			return
		end
		UI.label(content, { Text = "Weekly boards reset in " .. Util.formatDuration(lb.resetsIn or 0) .. ". Top 100 get a title; #1 gets the Golden Whisk!", Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 0, MaxText = 18 })
		local function board(title: string, list: any, unit: string, order: number)
			section(title, order)
			if #list == 0 then
				UI.label(content, { Text = "No chefs yet this week - be the first!", Size = UDim2.new(1, 0, 0, 30), LayoutOrder = order + 1 })
			end
			for i, e in ipairs(list) do
				local h, f = UI.panel(content, { LayoutOrder = order + i, Size = UDim2.new(1, 0, 0, 46), AnchorPoint = Vector2.zero, Corner = 10, StrokeThickness = 2, Color = i == 1 and UI.C.Mustard or UI.C.Cream })
				UI.label(f, { Text = string.format("#%d  %s", i, e.name), Title = true, Size = UDim2.new(0.7, 0, 0.8, 0), Position = UDim2.new(0, 10, 0.1, 0), XAlign = Enum.TextXAlignment.Left, MaxText = 22 })
				UI.label(f, { Text = e.value .. " " .. unit, Title = true, Size = UDim2.new(0.28, -10, 0.8, 0), Position = UDim2.new(0.72, 0, 0.1, 0), XAlign = Enum.TextXAlignment.Right, MaxText = 22 })
			end
		end
		board("👨‍🍳 Top Chef (most players eliminated as Chef)", lb.TopChef or {}, "KOs", 10)
		board("👑 Last One Standing (most wins)", lb.LastStanding or {}, "wins", 40)
	end)
end

function Menus.init(screen: ScreenGui)
	gui = screen
	buildWindow()
	State.DataChanged:Connect(function()
		if current == "Shop" or current == "Daily" then
			rerender()
		end
	end)
	-- menus close when you're pulled into a round
	player:GetAttributeChangedSignal("Alive"):Connect(function()
		if State.isAlive() then
			Menus.close()
		end
	end)
end

return Menus
