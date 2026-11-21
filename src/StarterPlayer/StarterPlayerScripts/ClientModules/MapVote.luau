-- Map vote: three map cards with a picture, name and live vote count.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Net = require(Shared.Net)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local MapVote = {}

local root: Frame
local cards: { [string]: any } = {}
local myVote: string? = nil

-- a tiny painted "picture" of each map from flat shapes
local function picture(parent: Instance, mapId: string)
	local info = Catalog.Maps[mapId]
	local bg = UI.new("Frame", { Size = UDim2.fromScale(0.92, 0.5), Position = UDim2.fromScale(0.04, 0.05), BackgroundColor3 = Color3.fromHex(info.colors[3]), BorderSizePixel = 0, ZIndex = 4, ClipsDescendants = true, Parent = parent })
	UI.corner(bg, 10)
	UI.stroke(bg, 3)
	if mapId == "PizzaPlanet" then
		local pizza = UI.new("Frame", { Size = UDim2.fromScale(0.62, 0.62), Position = UDim2.fromScale(0.5, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromHex("D9913F"), ZIndex = 5, Parent = bg })
		UI.aspect(pizza, 1)
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pizza })
		local cheese = UI.new("Frame", { Size = UDim2.fromScale(0.84, 0.84), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromHex(info.colors[1]), ZIndex = 6, Parent = pizza })
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = cheese })
		for _, p in ipairs({ { 0.3, 0.3 }, { 0.68, 0.35 }, { 0.45, 0.7 }, { 0.72, 0.68 } }) do
			local pep = UI.new("Frame", { Size = UDim2.fromScale(0.2, 0.2), Position = UDim2.fromScale(p[1], p[2]), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromHex(info.colors[2]), ZIndex = 7, Parent = cheese })
			UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pep })
		end
	elseif mapId == "PicnicMeadow" then
		UI.new("Frame", { Size = UDim2.fromScale(1, 0.55), Position = UDim2.fromScale(0, 0.45), BackgroundColor3 = Color3.fromHex(info.colors[1]), BorderSizePixel = 0, ZIndex = 5, Parent = bg })
		local hill = UI.new("Frame", { Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0.25, 0.55), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromHex("74C267"), ZIndex = 5, Parent = bg })
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hill })
		local blanket = UI.new("Frame", { Size = UDim2.fromScale(0.34, 0.2), Position = UDim2.fromScale(0.62, 0.72), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromHex(info.colors[2]), Rotation = -8, ZIndex = 6, Parent = bg })
		UI.stroke(blanket, 2, Color3.new(1, 1, 1))
	else
		UI.new("Frame", { Size = UDim2.fromScale(1, 0.4), BackgroundColor3 = Color3.fromHex("FAFAF7"), BorderSizePixel = 0, ZIndex = 5, Parent = bg })
		UI.new("Frame", { Size = UDim2.fromScale(1, 0.6), Position = UDim2.fromScale(0, 0.4), BackgroundColor3 = Color3.fromHex(info.colors[1]), BorderSizePixel = 0, ZIndex = 5, Parent = bg })
		local plate = UI.new("Frame", { Size = UDim2.fromScale(0.3, 0.3), Position = UDim2.fromScale(0.3, 0.68), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6, Parent = bg })
		UI.aspect(plate, 1.6)
		UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = plate })
		UI.stroke(plate, 2)
		UI.new("Frame", { Size = UDim2.fromScale(0.25, 0.5), Position = UDim2.fromScale(0.75, 0.5), BackgroundColor3 = Color3.fromHex(info.colors[3]), ZIndex = 6, Parent = bg })
	end
	UI.label(bg, { Text = info.emoji, Size = UDim2.fromScale(0.3, 0.45), Position = UDim2.fromScale(0.02, 0.02), ZIndex = 9 })
end

local function build(gui: ScreenGui)
	root = UI.new("Frame", { Name = "MapVote", Size = UDim2.fromScale(0.7, 0.42), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Visible = false, Parent = gui })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(900, 380), Parent = root })
	UI.label(root, { Text = "VOTE FOR THE KITCHEN!", Title = true, Size = UDim2.fromScale(1, 0.16), Color = UI.C.Mustard, Stroke = 3 })
	local row = UI.new("Frame", { Size = UDim2.fromScale(1, 0.82), Position = UDim2.fromScale(0, 0.18), BackgroundTransparency = 1, Parent = root })
	UI.list(row, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	for i, id in ipairs(Catalog.MapOrder) do
		local info = Catalog.Maps[id]
		local holder, face = UI.panel(row, { Name = id, Size = UDim2.fromScale(0.3, 1), LayoutOrder = i, Aspect = 0.85, Rotation = (i - 2) * 2 })
		picture(face, id)
		UI.label(face, { Text = info.name, Title = true, Size = UDim2.fromScale(0.92, 0.16), Position = UDim2.fromScale(0.04, 0.57), ZIndex = 4 })
		local votes = UI.label(face, { Text = "0 votes", Size = UDim2.fromScale(0.92, 0.12), Position = UDim2.fromScale(0.04, 0.73), ZIndex = 4, Color = UI.C.Tomato })
		local blocked = UI.label(face, { Text = "Needs a break!", Title = true, Size = UDim2.fromScale(0.92, 0.12), Position = UDim2.fromScale(0.04, 0.86), ZIndex = 4, Color = UI.C.Grape, Visible = false })
		local check = UI.label(face, { Text = "✅", Size = UDim2.fromScale(0.22, 0.2), Position = UDim2.fromScale(0.76, -0.06), ZIndex = 10, Visible = false })
		local hit = UI.new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 12, Parent = face })
		hit.Activated:Connect(function()
			UI.sound("Click")
			myVote = id
			Net.event("MapVote"):FireServer(id)
			for mid, c in pairs(cards) do
				c.check.Visible = mid == id
			end
			UI.pop(holder)
		end)
		cards[id] = { holder = holder, face = face, votes = votes, blocked = blocked, check = check }
	end
end

function MapVote.init(gui: ScreenGui)
	build(gui)
	Net.event("MapVoteState").OnClientEvent:Connect(function(s)
		if type(s) ~= "table" then
			return
		end
		if s.chosen then
			local info = Catalog.Maps[s.chosen]
			for mid, c in pairs(cards) do
				if mid ~= s.chosen then
					c.holder.Visible = false
				end
			end
			UI.sound("Ding")
			task.delay(1.5, function()
				root.Visible = false
				for _, c in pairs(cards) do
					c.holder.Visible = true
				end
			end)
			return
		end
		if s.open then
			if not root.Visible then
				myVote = nil
				for _, c in pairs(cards) do
					c.check.Visible = false
				end
				root.Visible = true
				UI.pop(root)
			end
		end
		for id, c in pairs(cards) do
			local n = s.counts and s.counts[id] or 0
			c.votes.Text = n .. (n == 1 and " vote" or " votes")
			local isBlocked = s.blocked == id
			c.blocked.Visible = isBlocked
			c.face.BackgroundColor3 = isBlocked and Color3.fromHex("D9CFC0") or UI.C.Cream
		end
	end)
	State.onGame("Phase", function(phase)
		if phase ~= "Intermission" and root.Visible then
			task.delay(1.6, function()
				if State.get("Phase") ~= "Intermission" then
					root.Visible = false
				end
			end)
		end
	end)
end

return MapVote
