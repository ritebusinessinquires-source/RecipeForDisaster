-- Eliminated screen, ghost Twist vote, Chef wipeout banner and the winner podium.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Catalog)
local Util = require(Shared.Util)
local Net = require(Shared.Net)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local Results = {}
Results.confetti = function() end

local gui: ScreenGui
local player = Players.LocalPlayer

---------------------------------------------------------------- Eliminated

local elim: Frame
local elimFace: Frame
local elimBody: Frame
local ghostBtn: Frame

local function buildEliminated()
	local h, f = UI.panel(gui, { Name = "Eliminated", Size = UDim2.fromScale(0.42, 0.62), Position = UDim2.fromScale(0.5, 0.5), Rotation = -2, Visible = false, ZIndex = 50 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 330), MaxSize = Vector2.new(520, 560), Parent = h })
	elim, elimFace = h, f
	local band = UI.new("Frame", { Size = UDim2.fromScale(1, 0.16), BackgroundColor3 = UI.C.Tomato, BorderSizePixel = 0, ZIndex = 51, Parent = f })
	UI.corner(band)
	UI.label(band, { Text = "ELIMINATED!", Title = true, Color = UI.C.White, Stroke = 3, ZIndex = 52, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	elimBody = UI.new("Frame", { Size = UDim2.fromScale(0.9, 0.62), Position = UDim2.fromScale(0.05, 0.18), BackgroundTransparency = 1, ZIndex = 51, Parent = f })
	ghostBtn = UI.button(f, { Name = "Ghost", Text = "👻 Become a ghost", Color = UI.C.Grape, Size = UDim2.fromScale(0.7, 0.13), Position = UDim2.fromScale(0.5, 0.97), AnchorPoint = Vector2.new(0.5, 1), Visible = false, ZIndex = 55 }, function()
		Net.event("BecomeGhost"):FireServer()
		UI.shrinkOut(elim)
	end)
end

local function showEliminated(p: any)
	for _, c in ipairs(elimBody:GetChildren()) do
		c:Destroy()
	end
	UI.list(elimBody, Enum.FillDirection.Vertical, 6)
	UI.label(elimBody, { Text = "The dish that got you:", Size = UDim2.new(1, 0, 0.09, 0), LayoutOrder = 1, ZIndex = 52 })
	UI.label(elimBody, { Text = (p.emoji or "") .. " " .. (p.dishName or "?"), Title = true, Size = UDim2.new(1, 0, 0.16, 0), Color = p.secret and UI.C.Grape or UI.C.Tomato, LayoutOrder = 2, ZIndex = 52 })
	for i, ing in ipairs(p.ingredients or {}) do
		local row, rf = UI.panel(elimBody, { Name = "Ing", Size = UDim2.new(1, 0, 0.13, 0), LayoutOrder = 2 + i, Color = ing.slot == "Main" and Color3.fromHex("FBD3CC") or Color3.fromHex("FFF0C2"), Corner = 10, StrokeThickness = 3, ZIndex = 52 })
		UI.label(rf, { Text = string.format("%s %s%s  <font color=\"#8A6A55\">by %s</font>", ing.emoji, ing.name, (ing.acts and ing.acts ~= ing.name) and (" <font color=\"#8A6A55\">(" .. ing.acts .. ")</font>") or "", ing.chef), Rich = true, Title = true, Size = UDim2.fromScale(0.94, 0.8), Position = UDim2.fromScale(0.03, 0.1), XAlign = Enum.TextXAlignment.Left, ZIndex = 53, MaxText = 22 })
	end
	if p.twist and Catalog.Twists[p.twist] then
		local tw = Catalog.Twists[p.twist]
		UI.label(elimBody, { Text = tw.emoji .. " Twist: " .. tw.name .. " (ghost vote)", Size = UDim2.new(1, 0, 0.08, 0), LayoutOrder = 7, ZIndex = 52, Color = UI.C.Grape })
	end
	if p.fell then
		UI.label(elimBody, { Text = "You fell off the edge!", Size = UDim2.new(1, 0, 0.08, 0), LayoutOrder = 8, ZIndex = 52, Color = UI.C.Tomato })
	end
	UI.label(elimBody, {
		Text = string.format("⏱️ Survived %s   •   💰 %s Cash earned   •   #%d", Util.formatTime(p.survived or 0), UI.fmt(p.cash or 0), p.place or 0),
		Title = true,
		Size = UDim2.new(1, 0, 0.1, 0),
		LayoutOrder = 9,
		ZIndex = 52,
	})
	ghostBtn.Visible = false
	elim.Visible = true
	UI.pop(elim)
	UI.sound("Eliminated", 0.8)
	task.delay(p.ghostDelay or 4, function()
		if elim.Visible then
			ghostBtn.Visible = true
			UI.pop(ghostBtn)
		end
	end)
end

---------------------------------------------------------------- Ghost vote

local ghostVote: Frame
local ghostRow: Frame
local ghostTitle: TextLabel

local function buildGhostVote()
	ghostVote = UI.new("Frame", { Name = "GhostVote", Size = UDim2.fromScale(0.56, 0.4), Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 20, Parent = gui })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(330, 230), MaxSize = Vector2.new(700, 340), Parent = ghostVote })
	ghostTitle = UI.label(ghostVote, { Text = "👻 GHOSTS: VOTE THE NEXT TWIST", Title = true, Size = UDim2.fromScale(1, 0.15), Color = Color3.fromHex("C9B6FF"), Stroke = 3, ZIndex = 21 })
	ghostRow = UI.new("Frame", { Size = UDim2.fromScale(1, 0.58), Position = UDim2.fromScale(0, 0.16), BackgroundTransparency = 1, ZIndex = 21, Parent = ghostVote })
	-- ...or type a twist ("flood", "night", "moon"...)
	local th, tf = UI.panel(ghostVote, { Name = "TwistBox", Size = UDim2.fromScale(0.66, 0.2), Position = UDim2.fromScale(0, 0.78), AnchorPoint = Vector2.zero, Color = UI.C.White, Corner = 12, ZIndex = 22 })
	UI.minSize(th, 180, 60)
	local box = UI.new("TextBox", {
		Size = UDim2.fromScale(0.94, 0.8),
		Position = UDim2.fromScale(0.03, 0.1),
		BackgroundTransparency = 1,
		Text = "",
		PlaceholderText = "...or type a twist: flood, night, moon...",
		PlaceholderColor3 = Color3.fromHex("A08A78"),
		Font = UI.Theme.TitleFont,
		TextScaled = true,
		TextColor3 = UI.C.Chocolate,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 23,
		Parent = tf,
	})
	UI.new("UITextSizeConstraint", { MaxTextSize = 26, MinTextSize = 12, Parent = box })
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > 40 then
			box.Text = string.sub(box.Text, 1, 40)
		end
		if box:IsFocused() then
			UI.sound("Type", 0.3, 0.9 + math.random() * 0.3)
		end
	end)
	local function send()
		local text = string.gsub(box.Text, "^%s+", "")
		if text ~= "" then
			Net.event("GhostVote"):FireServer({ text = text })
			box.Text = ""
			UI.sound("Stamp", 0.6)
		end
	end
	box.FocusLost:Connect(function(enter)
		if enter then
			send()
		end
	end)
	UI.button(ghostVote, { Name = "SendTwist", Text = "VOTE 👻", Color = UI.C.Grape, Size = UDim2.fromScale(0.3, 0.2), Position = UDim2.fromScale(1, 0.78), AnchorPoint = Vector2.new(1, 0), ZIndex = 22 }, send)
	UI.list(ghostRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
end

local function showGhostVote(s: any)
	if not s then
		ghostVote.Visible = false
		return
	end
	for _, c in ipairs(ghostRow:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local nOpts = #(s.options or {})
	for i, id in ipairs(s.options or {}) do
		local tw = Catalog.Twists[id]
		local n = s.counts and s.counts[id] or 0
		UI.recipeCard(ghostRow, {
			Name = id,
			Size = UDim2.fromScale(math.min(0.3, 0.95 / math.max(1, nOpts)), 1),
			Rotation = (i - 2) * 3,
			LayoutOrder = i,
			SlotColor = UI.C.Grape,
			SlotText = s.mine == id and "✅ TWIST" or "TWIST",
			Emoji = tw.emoji,
			Text = tw.name,
			Sub = n .. (n == 1 and " vote" or " votes"),
			Aspect = 0.8,
			ZIndex = 22,
			OnClick = function()
				Net.event("GhostVote"):FireServer(id)
			end,
		})
	end
	ghostTitle.Text = "👻 VOTE THE TWIST FOR COURSE " .. tostring(s.course or "")
	if not ghostVote.Visible then
		ghostVote.Visible = true
		UI.pop(ghostVote)
	end
end

---------------------------------------------------------------- Wipeout banner

local wipe: Frame
local wipeList: Frame

local function buildWipe()
	local h, f = UI.panel(gui, { Name = "Wipeouts", Size = UDim2.fromScale(0.56, 0.22), Position = UDim2.fromScale(0.5, 0.3), Color = UI.C.Mustard, Visible = false, ZIndex = 45 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(320, 110), MaxSize = Vector2.new(720, 240), Parent = h })
	wipe = h
	wipeList = UI.new("Frame", { Size = UDim2.fromScale(0.94, 0.9), Position = UDim2.fromScale(0.03, 0.05), BackgroundTransparency = 1, ZIndex = 46, Parent = f })
	UI.list(wipeList, Enum.FillDirection.Vertical, 2)
end

local function showWipe(r: any)
	for _, c in ipairs(wipeList:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local results = r.results or {}
	UI.label(wipeList, { Text = "COURSE " .. tostring(r.course) .. " - " .. tostring(r.alive) .. " still standing", Title = true, Size = UDim2.new(1, 0, 0.28, 0), LayoutOrder = 0, ZIndex = 47, Color = UI.C.White, Stroke = 2.5 })
	if #results == 0 then
		UI.label(wipeList, { Text = "Nobody got cooked this course!", Title = true, Size = UDim2.new(1, 0, 0.3, 0), LayoutOrder = 1, ZIndex = 47 })
	end
	for i, res in ipairs(results) do
		if i > 3 then
			break
		end
		UI.label(wipeList, {
			Text = string.format("%s's %s %s got %d player%s!%s", res.chefs, res.emoji or "", res.dish, res.count, res.count == 1 and "" or "s", res.nightmare and "  KITCHEN NIGHTMARE!" or ""),
			Title = true,
			Size = UDim2.new(1, 0, 0.22, 0),
			LayoutOrder = i,
			ZIndex = 47,
			Color = res.nightmare and UI.C.Tomato or UI.C.Chocolate,
		})
	end
	wipe.Visible = true
	UI.pop(wipe)
	task.delay(3.2, function()
		UI.shrinkOut(wipe)
	end)
end

---------------------------------------------------------------- Winner

local winner: Frame
local winnerName: TextLabel
local winnerPic: ImageLabel
local winnerSub: TextLabel

local function buildWinner()
	local h, f = UI.panel(gui, { Name = "Winner", Size = UDim2.fromScale(0.44, 0.56), Position = UDim2.fromScale(0.5, 0.48), Color = UI.C.Cream, Visible = false, ZIndex = 60 })
	UI.new("UISizeConstraint", { MinSize = Vector2.new(300, 300), MaxSize = Vector2.new(560, 520), Parent = h })
	winner = h
	UI.label(f, { Text = "🏆 LAST ONE STANDING 🏆", Title = true, Color = UI.C.Mustard, Stroke = 3, Size = UDim2.fromScale(0.94, 0.14), Position = UDim2.fromScale(0.03, 0.03), ZIndex = 61 })
	-- podium
	local podium = UI.new("Frame", { Size = UDim2.fromScale(0.4, 0.2), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.Mustard, ZIndex = 61, Parent = f })
	UI.corner(podium, 8)
	UI.stroke(podium, 3)
	UI.label(podium, { Text = "1", Title = true, Color = UI.C.White, Stroke = 2, ZIndex = 62 })
	winnerPic = UI.new("ImageLabel", { Size = UDim2.fromScale(0.3, 0.3), Position = UDim2.fromScale(0.5, 0.38), AnchorPoint = Vector2.new(0.5, 0), BackgroundColor3 = UI.C.DarkCream, ZIndex = 62, Parent = f })
	UI.aspect(winnerPic, 1)
	UI.new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = winnerPic })
	UI.stroke(winnerPic, 3)
	winnerName = UI.label(f, { Text = "", Title = true, Size = UDim2.fromScale(0.9, 0.14), Position = UDim2.fromScale(0.05, 0.2), ZIndex = 61, Color = UI.C.Tomato })
	winnerSub = UI.label(f, { Text = "", Size = UDim2.fromScale(0.9, 0.08), Position = UDim2.fromScale(0.05, 0.9), ZIndex = 61 })
end

local function showWinner(w: any)
	winnerPic.Image = ""
	if w.practice then
		winnerName.Text = "Practice over!"
		winnerSub.Text = string.format("You lasted %d course%s. Invite friends for real rounds!", w.courses or 0, (w.courses or 0) == 1 and "" or "s")
	elseif w.winner then
		winnerName.Text = w.winner.name
		if w.winner.userId and w.winner.userId > 0 then
			task.spawn(function()
				local ok, img = pcall(Players.GetUserThumbnailAsync, Players, w.winner.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				if ok then
					winnerPic.Image = img
				end
			end)
		end
		winnerSub.Text = w.topChef and string.format("Top Chef: %s (%d KO%s)", w.topChef.name, w.topChef.kos, w.topChef.kos == 1 and "" or "s") or "Nobody got cooked by a Chef this round!"
	else
		winnerName.Text = "Nobody survived!"
		winnerSub.Text = ""
	end
	winner.Visible = true
	UI.pop(winner)
	UI.sound("Fanfare", 0.9)
	Results.confetti()
	task.delay(8, function()
		UI.shrinkOut(winner)
	end)
end

function Results.init(screen: ScreenGui)
	gui = screen
	buildEliminated()
	buildGhostVote()
	buildWipe()
	buildWinner()
	Net.event("Eliminated").OnClientEvent:Connect(function(p)
		if type(p) == "table" then
			showEliminated(p)
		end
	end)
	Net.event("GhostVoteOptions").OnClientEvent:Connect(function(s)
		if s ~= nil and State.isAlive() then
			return
		end
		showGhostVote(s)
	end)
	Net.event("CourseResults").OnClientEvent:Connect(function(r)
		if type(r) == "table" then
			showWipe(r)
		end
	end)
	Net.event("Winner").OnClientEvent:Connect(function(w)
		if type(w) == "table" then
			elim.Visible = false
			ghostVote.Visible = false
			showWinner(w)
		end
	end)
	player.CharacterAdded:Connect(function()
		if elim.Visible and not State.isAlive() and player:GetAttribute("Ghost") then
			elim.Visible = false
		end
	end)
end

return Results
