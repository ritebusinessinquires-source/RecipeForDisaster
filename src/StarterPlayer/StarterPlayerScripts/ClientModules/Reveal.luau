-- The reveal: a pot appears, each ingredient drops in with the name of the Chef who picked it
-- ("GIANT - by Sam"), then the dish name stamps onto the screen with a hint icon.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local Reveal = {}
Reveal.shake = function(_intensity: number, _duration: number) end

local gui: ScreenGui
local root: Frame
local dim: Frame
local potHolder: Frame
local potBody: Frame
local dropLayer: Frame
local caption: TextLabel
local nameLabel: TextLabel
local hintFrame: Frame
local hintIcon: TextLabel
local hintText: TextLabel
local hintSub: TextLabel
local secretBanner: Frame
local secretLabel: TextLabel
local tagLabel: TextLabel
local jokeLabel: TextLabel
local playing = 0

local function build()
	root = UI.new("Frame", { Name = "Reveal", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 30, Parent = gui })
	dim = UI.new("Frame", { Size = UDim2.fromScale(1, 1.2), Position = UDim2.fromScale(0, -0.1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 30, Parent = root })
	-- the pot
	potHolder = UI.new("Frame", { Size = UDim2.fromScale(0.26, 0.26), Position = UDim2.fromScale(0.5, 0.78), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, ZIndex = 31, Parent = root })
	UI.aspect(potHolder, 1.3)
	UI.new("UISizeConstraint", { MinSize = Vector2.new(160, 120), Parent = potHolder })
	potBody = UI.new("Frame", { Size = UDim2.fromScale(0.86, 0.62), Position = UDim2.fromScale(0.5, 0.36), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Steel, ZIndex = 33, Parent = potHolder })
	UI.corner(potBody, 26)
	UI.stroke(potBody, 4)
	local rim = UI.new("Frame", { Size = UDim2.fromScale(1, 0.14), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Steel, ZIndex = 34, Parent = potHolder })
	UI.corner(rim, 12)
	UI.stroke(rim, 4)
	rim:SetAttribute("PotPart", true)
	local soup = UI.new("Frame", { Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.5, 0.25), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Tomato, ZIndex = 32, Parent = potHolder })
	UI.corner(soup, 20)
	UI.stroke(soup, 3)
	for _, x in ipairs({ -0.06, 1.06 }) do
		local handle = UI.new("Frame", { Size = UDim2.fromScale(0.12, 0.12), Position = UDim2.fromScale(x, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = UI.C.Chocolate, ZIndex = 32, Parent = potHolder })
		UI.corner(handle, 8)
	end
	UI.label(potHolder, { Text = "♨️♨️♨️", Size = UDim2.fromScale(0.8, 0.28), Position = UDim2.fromScale(0.1, -0.02), ZIndex = 32 })
	dropLayer = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 35, Parent = root })
	caption = UI.label(root, { Text = "", Title = true, Size = UDim2.fromScale(0.8, 0.08), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), Color = UI.C.White, Stroke = 3, ZIndex = 40 })
	-- dish name
	nameLabel = UI.label(root, { Text = "", Title = true, Size = UDim2.fromScale(0.9, 0.14), Position = UDim2.fromScale(0.5, 0.26), AnchorPoint = Vector2.new(0.5, 0.5), Color = UI.C.Mustard, Stroke = 5, ZIndex = 41 })
	tagLabel = UI.label(root, { Text = "", Title = true, Size = UDim2.fromScale(0.5, 0.05), Position = UDim2.fromScale(0.5, 0.17), AnchorPoint = Vector2.new(0.5, 0.5), Color = UI.C.Basil, Stroke = 2.5, ZIndex = 41 })
	local hh, hf = UI.panel(root, { Name = "Hint", Size = UDim2.fromScale(0.5, 0.12), Position = UDim2.fromScale(0.5, 0.41), ZIndex = 40 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 70), MaxSize = Vector2.new(640, 110), Parent = hh })
	hintFrame = hh
	hintIcon = UI.label(hf, { Text = "⛰️", Size = UDim2.fromScale(0.18, 0.9), Position = UDim2.fromScale(0.02, 0.05), ZIndex = 41 })
	hintText = UI.label(hf, { Text = "", Title = true, Size = UDim2.fromScale(0.78, 0.5), Position = UDim2.fromScale(0.2, 0.05), XAlign = Enum.TextXAlignment.Left, ZIndex = 41 })
	hintSub = UI.label(hf, { Text = "", Size = UDim2.fromScale(0.78, 0.38), Position = UDim2.fromScale(0.2, 0.56), XAlign = Enum.TextXAlignment.Left, ZIndex = 41, Color = UI.C.Tomato })
	local sh, sf = UI.panel(root, { Name = "Secret", Size = UDim2.fromScale(0.5, 0.07), Position = UDim2.fromScale(0.5, 0.1), Color = UI.C.Grape, ZIndex = 42 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 40), Parent = sh })
	secretBanner = sh
	secretLabel = UI.label(sf, { Text = "", Title = true, Color = UI.C.White, Stroke = 2, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), ZIndex = 43 })
	jokeLabel = UI.label(root, { Text = "", Size = UDim2.fromScale(0.7, 0.05), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Color = UI.C.White, Stroke = 2, ZIndex = 41 })
end

local function dropIngredient(emoji: string, text: string, slotColor: Color3, chef: string, index: number, acts: string?)
	local holder = UI.recipeCard(dropLayer, {
		Name = "Drop",
		Size = UDim2.fromScale(0.12, 0.22),
		Position = UDim2.fromScale(0.5 + (index - 2) * 0.05, -0.2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = (index - 2) * 12,
		SlotColor = slotColor,
		SlotText = "",
		Emoji = emoji,
		Text = text,
		ZIndex = 36,
	})
	caption.Text = string.upper(text) .. ((acts and acts ~= text) and ("  (" .. acts .. ")") or "") .. "  -  by " .. chef
	caption.Visible = true
	UI.pop(caption)
	UI.sound("Whoosh", 0.5, 1 + index * 0.1)
	local tw = UI.tween(holder, 0.45, { Position = UDim2.fromScale(0.5, 0.66), Rotation = (index - 2) * 25 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw.Completed:Connect(function()
		UI.sound("Splash", 0.4)
		UI.tween(holder, 0.2, { Size = UDim2.fromScale(0.02, 0.04) })
		task.delay(0.25, function()
			holder:Destroy()
		end)
	end)
end

local function play(payload: any)
	playing += 1
	local myPlay = playing
	root.Visible = true
	nameLabel.Text = ""
	tagLabel.Text = ""
	jokeLabel.Text = ""
	caption.Text = ""
	hintFrame.Visible = false
	secretBanner.Visible = false
	potHolder.Visible = true
	local potColor = Color3.fromHex(payload.potColor or "9AA4AE")
	potBody.BackgroundColor3 = potColor
	for _, c in ipairs(potHolder:GetChildren()) do
		if c:GetAttribute("PotPart") then
			c.BackgroundColor3 = potColor
		end
	end
	UI.tween(dim, 0.3, { BackgroundTransparency = 0.45 })
	UI.pop(potHolder)
	UI.sound("DrumRoll", 0.7)
	local steps = {}
	for i, ing in ipairs(payload.ingredients or {}) do
		local color = ing.slot == "Main" and UI.C.Tomato or UI.C.Mustard
		table.insert(steps, { ing.emoji, ing.name, color, ing.chef, i, ing.acts })
	end
	if payload.twist then
		table.insert(steps, { payload.twist.emoji, payload.twist.name, UI.C.Grape, "the ghosts", 4 })
	end
	local per = math.min(0.8, 2.6 / math.max(1, #steps))
	for i, st in ipairs(steps) do
		task.delay(0.25 + (i - 1) * per, function()
			if playing == myPlay then
				dropIngredient(st[1], st[2], st[3], st[4], st[5], st[6])
			end
		end)
	end
	-- stamp the dish name
	task.delay(0.35 + #steps * per, function()
		if playing ~= myPlay then
			return
		end
		caption.Text = ""
		potHolder.Visible = false
		nameLabel.Text = (payload.emoji or "") .. " " .. string.upper(payload.name or "?")
		nameLabel.TextColor3 = payload.secret and Color3.fromHex("C9B6FF") or UI.C.Mustard
		local scale = nameLabel:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = nameLabel })
		scale.Scale = 2.6
		UI.tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		UI.sound("Stamp", 0.9, 0.8)
		Reveal.shake(0.6, 0.35)
		local tags = {}
		if payload.isNew then
			table.insert(tags, "✨ NEW ON THIS SERVER")
		end
		if payload.dishOfDay then
			table.insert(tags, "⭐ DISH OF THE DAY - 2x CASH")
		end
		if payload.suddenDeath then
			table.insert(tags, "🔥 SUDDEN DEATH: FREE FAST SPICE")
		end
		if (payload.stacked or 1) > 1 then
			table.insert(tags, "🍲 " .. payload.stacked .. " DISHES STACKED")
		end
		tagLabel.Text = table.concat(tags, "   ")
		if payload.secret then
			secretBanner.Visible = true
			secretLabel.Text = "📜 SECRET RECIPE: " .. payload.secret.desc
			UI.pop(secretBanner)
			UI.sound("Fanfare", 0.8)
		end
		local hint = payload.hint or {}
		hintIcon.Text = Catalog.HintIcons[hint.icon or "run"] and Catalog.HintIcons[hint.icon or "run"].emoji or "🏃"
		hintText.Text = hint.text or ""
		hintSub.Text = hint.sub or ""
		hintFrame.Visible = true
		UI.pop(hintFrame, 0.15)
		local jokes = payload.jokes or {}
		if payload.wasted then
			table.insert(jokes, 1, payload.confused and "Fast + Slow = Confused! Wasted Spice bonus for both Chefs." or "Giant + Tiny cancel out! Wasted Spice bonus for both Chefs.")
		end
		local extras = {}
		for _, x in ipairs(payload.extraMains or {}) do
			table.insert(extras, x.emoji .. " " .. x.name)
		end
		for _, x in ipairs(payload.extraSpices or {}) do
			table.insert(extras, x.emoji .. " " .. x.name)
		end
		if #extras > 0 then
			table.insert(jokes, 1, "Also in the pot: " .. table.concat(extras, ", "))
		end
		jokeLabel.Text = table.concat(jokes, "  ")
	end)
	-- leave the name up briefly once cooking starts
	task.delay((payload.duration or 5) + 1.8, function()
		if playing == myPlay then
			UI.tween(dim, 0.3, { BackgroundTransparency = 1 })
			root.Visible = false
		end
	end)
end

function Reveal.init(screen: ScreenGui)
	gui = screen
	build()
	Net.event("RevealDish").OnClientEvent:Connect(function(payload)
		if type(payload) == "table" then
			play(payload)
		end
	end)
	State.onGame("RoundActive", function(active)
		if not active then
			playing += 1
			root.Visible = false
			dim.BackgroundTransparency = 1
		end
	end)
end

return Reveal
