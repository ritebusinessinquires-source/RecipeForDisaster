-- The lobby: a cooking-show studio floating beside the arena. Players wait here during
-- intermission and ghosts watch from here. Boards show the weekly leaderboards, the Dish
-- of the Day and the countdown to the next ingredient drop.

local ServerStorage = game:GetService("ServerStorage")
local Builder = require(ServerStorage:WaitForChild("Maps"):WaitForChild("Builder"))

local Lobby = {}

Lobby.Origin = Vector3.new(0, 70, 300) -- floor top centre
local W, D = 130, 92

local boards: { [string]: any } = {}
Lobby.boards = boards

local function surfaceBoard(part: BasePart, face: Enum.NormalId, title: string, accent: string): (Frame, TextLabel)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.Parent = part
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromHex("FFF4DC")
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 14
	stroke.Color = Color3.fromHex("3B2418")
	stroke.Parent = bg
	local band = Instance.new("TextLabel")
	band.Size = UDim2.new(1, 0, 0.2, 0)
	band.BackgroundColor3 = Color3.fromHex(accent)
	band.BorderSizePixel = 0
	band.Font = Enum.Font.FredokaOne
	band.TextScaled = true
	band.TextColor3 = Color3.new(1, 1, 1)
	band.Text = title
	band.Parent = bg
	local bstroke = Instance.new("UIStroke")
	bstroke.Thickness = 4
	bstroke.Color = Color3.fromHex("3B2418")
	bstroke.Parent = band
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.03, 0)
	pad.PaddingBottom = UDim.new(0.03, 0)
	pad.Parent = band
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.new(0.92, 0, 0.74, 0)
	body.Position = UDim2.new(0.04, 0, 0.23, 0)
	body.BackgroundTransparency = 1
	body.Parent = bg
	return body, band
end

local function boardText(body: Frame, text: string, size: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.BuilderSansBold
	l.TextColor3 = Color3.fromHex("3B2418")
	l.TextScaled = true
	l.TextWrapped = true
	l.RichText = true
	l.Text = text
	l.Parent = body
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = size or 60
	c.Parent = l
	return l
end

function Lobby.build(): any
	local old = workspace:FindFirstChild("Lobby")
	if old then
		old:Destroy()
	end
	local model = Instance.new("Model")
	model.Name = "Lobby"
	local b = Builder.new(model)
	local o = Lobby.Origin

	-- studio floor (checker)
	for x = -W / 2 + 6, W / 2 - 6, 12 do
		for z = -D / 2 + 6, D / 2 - 6, 12 do
			local even = (math.floor(x / 12) + math.floor(z / 12)) % 2 == 0
			b:block(Vector3.new(12, 2, 12), o + Vector3.new(x, -1, z), even and "#FFF4DC" or "#E84A3A", Enum.Material.SmoothPlastic, nil, "Floor")
		end
	end
	b:block(Vector3.new(W + 4, 10, D + 4), o + Vector3.new(0, -7, 0), "#3B2418", Enum.Material.Wood, nil, "Base")

	-- back wall + sign
	local back = b:block(Vector3.new(W, 46, 3), o + Vector3.new(0, 23, D / 2 + 1.5), "#7B4FD6", Enum.Material.SmoothPlastic, nil, "BackWall")
	local signPart = b:block(Vector3.new(84, 16, 1), o + Vector3.new(0, 34, D / 2 - 0.5), "#FFC93C", Enum.Material.SmoothPlastic, nil, "Sign")
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 20
	sg.LightInfluence = 0
	sg.Parent = signPart
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = "RECIPE FOR DISASTER"
	title.TextColor3 = Color3.fromHex("E84A3A")
	title.Parent = sg
	local ts = Instance.new("UIStroke")
	ts.Thickness = 10
	ts.Color = Color3.fromHex("3B2418")
	ts.Parent = title
	-- signs face -Z (toward the arena/players): rotate so Front faces the room
	signPart.CFrame = CFrame.lookAt(signPart.Position, signPart.Position - Vector3.new(0, 0, 1))
	back.CFrame = CFrame.lookAt(back.Position, back.Position - Vector3.new(0, 0, 1))

	-- side walls
	b:block(Vector3.new(3, 30, D), o + Vector3.new(-W / 2 - 1.5, 15, 0), "#7B4FD6", Enum.Material.SmoothPlastic, nil, "SideWall")
	b:block(Vector3.new(3, 30, D), o + Vector3.new(W / 2 + 1.5, 15, 0), "#7B4FD6", Enum.Material.SmoothPlastic, nil, "SideWall")
	-- glass railing toward the arena
	local rail = b:block(Vector3.new(W, 4, 1), o + Vector3.new(0, 2, -D / 2 + 0.5), "#BFE6FF", Enum.Material.Glass, nil, "Railing")
	rail.Transparency = 0.5
	b:block(Vector3.new(W, 0.6, 1.4), o + Vector3.new(0, 4.2, -D / 2 + 0.5), "#FFC93C", Enum.Material.SmoothPlastic, nil, "RailTop")
	b:wall(Vector3.new(W, 40, 2), o + Vector3.new(0, 20, -D / 2 - 1))
	b:wall(Vector3.new(W + 10, 2, D + 10), o + Vector3.new(0, 48, 0))

	-- boards: helper to make a board part facing into the room
	local function board(name: string, size: Vector3, pos: Vector3, lookDir: Vector3, title: string, accent: string)
		local p = b:block(size, o + pos, "#3B2418", Enum.Material.SmoothPlastic, nil, name)
		p.CFrame = CFrame.lookAt(p.Position, p.Position + lookDir)
		local body = surfaceBoard(p, Enum.NormalId.Front, title, accent)
		return body
	end
	boards.topChef = boardText(board("TopChefBoard", Vector3.new(26, 30, 1), Vector3.new(-W / 2 + 0.6, 17, 8), Vector3.new(1, 0, 0), "🏆 TOP CHEF - this week", "#E84A3A"), "Loading...", 46)
	boards.lastStanding = boardText(board("LastStandingBoard", Vector3.new(26, 30, 1), Vector3.new(W / 2 - 0.6, 17, 8), Vector3.new(-1, 0, 0), "👑 LAST ONE STANDING", "#7B4FD6"), "Loading...", 46)
	boards.dishOfDay = boardText(board("DishOfDayBoard", Vector3.new(30, 14, 1), Vector3.new(-30, 13, D / 2 - 0.6), Vector3.new(0, 0, -1), "⭐ DISH OF THE DAY (2x Cash)", "#4CAF50"), "...", 60)
	boards.countdown = boardText(board("CountdownBoard", Vector3.new(30, 14, 1), Vector3.new(30, 13, D / 2 - 0.6), Vector3.new(0, 0, -1), "🆕 NEXT INGREDIENT DROP", "#FFC93C"), "...", 60)
	boards.howTo = boardText(board("HowToBoard", Vector3.new(24, 20, 1), Vector3.new(-W / 2 + 0.6, 14, -26), Vector3.new(1, 0, 0), "📖 HOW TO PLAY", "#FFC93C"),
		"Each course, 3 Chefs secretly pick a Main and two Spices.\nEveryone survives the dish!\nLast player standing wins.", 40)
	boards.server = boardText(board("ServerBoard", Vector3.new(24, 20, 1), Vector3.new(W / 2 - 0.6, 14, -26), Vector3.new(-1, 0, 0), "🍳 THIS SERVER", "#4CAF50"), "Wins and Chef KOs show here.", 40)

	-- the giant pot in the middle
	b:cylinder(22, 12, o + Vector3.new(0, 0, 10), "#9AA4AE", Enum.Material.Metal, nil, "BigPot")
	local soup = b:cylinder(19, 0.5, o + Vector3.new(0, 11.4, 10), "#E84A3A", Enum.Material.Neon, nil, "Soup")
	local steam = Instance.new("ParticleEmitter")
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Size = NumberSequence.new(3, 9)
	steam.Transparency = NumberSequence.new(0.4, 1)
	steam.Lifetime = NumberRange.new(2, 3)
	steam.Rate = 8
	steam.Speed = NumberRange.new(3, 6)
	steam.Parent = soup
	b:log(3, 30, o + Vector3.new(0, 13, 10), math.rad(40), "#C98E56", Enum.Material.Wood, nil, "Spoon")

	-- winner podium (3 tiers)
	local podium = b:block(Vector3.new(10, 6, 10), o + Vector3.new(0, 3, 34), "#FFC93C", Enum.Material.SmoothPlastic, nil, "Podium1")
	b:block(Vector3.new(10, 4, 10), o + Vector3.new(-11, 2, 34), "#C7CED6", Enum.Material.SmoothPlastic, nil, "Podium2")
	b:block(Vector3.new(10, 2.5, 10), o + Vector3.new(11, 1.25, 34), "#C8743A", Enum.Material.SmoothPlastic, nil, "Podium3")
	Lobby.podiumTop = podium.Position + Vector3.new(0, 6, 0)

	-- studio lights
	for _, x in ipairs({ -48, -16, 16, 48 }) do
		local lamp = b:block(Vector3.new(6, 2, 6), o + Vector3.new(x, 38, 0), "#FFF4DC", Enum.Material.Neon, nil, "StudioLight")
		local l = Instance.new("SpotLight")
		l.Face = Enum.NormalId.Bottom
		l.Range = 50
		l.Brightness = 2
		l.Angle = 80
		l.Parent = lamp
	end

	-- spawn pads
	local spawns = {}
	for i, x in ipairs({ -22, 22 }) do
		local s = Instance.new("SpawnLocation")
		s.Name = "LobbySpawn" .. i
		s.Anchored = true
		s.Neutral = true
		s.Duration = 0
		s.Size = Vector3.new(12, 1, 12)
		s.CFrame = CFrame.new(o + Vector3.new(x, 0.5, 8))
		s.Color = Color3.fromHex("4CAF50")
		s.Material = Enum.Material.SmoothPlastic
		s.TopSurface = Enum.SurfaceType.Smooth
		s.Parent = model
		table.insert(spawns, s)
	end
	Lobby.spawns = spawns

	model.Parent = workspace
	Lobby.model = model
	return Lobby
end

-- The PLAY pad (lobby servers only): stand on it to join the queue.
function Lobby.buildQueuePad(): BasePart
	local model = Lobby.model :: Model
	local b = Builder.new(model)
	local o = Lobby.Origin
	local center = o + Vector3.new(0, 0, -27)
	local ring = b:cylinder(30, 0.5, center, "#3B2418", Enum.Material.SmoothPlastic, model, "QueueRing")
	ring.CanCollide = false
	local pad = b:cylinder(26, 0.7, center, "#4CAF50", Enum.Material.Neon, model, "QueuePad")
	pad.CanCollide = false
	-- arch with the PLAY sign
	b:block(Vector3.new(2, 18, 2), center + Vector3.new(-14, 9, 0), "#FFC93C", Enum.Material.SmoothPlastic, model, "ArchPost")
	b:block(Vector3.new(2, 18, 2), center + Vector3.new(14, 9, 0), "#FFC93C", Enum.Material.SmoothPlastic, model, "ArchPost")
	local sign = b:block(Vector3.new(30, 6, 1), center + Vector3.new(0, 19, 0), "#E84A3A", Enum.Material.SmoothPlastic, model, "PlaySign")
	-- face the sign toward the spawn side (+Z) so arriving players read it
	sign.CFrame = CFrame.lookAt(sign.Position, sign.Position + Vector3.new(0, 0, 1))
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 24
		sg.LightInfluence = 0
		sg.Parent = sign
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.Text = "▶ PLAY - STAND HERE"
		t.TextColor3 = Color3.fromHex("FFF4DC")
		t.Parent = sg
		local st = Instance.new("UIStroke")
		st.Thickness = 6
		st.Color = Color3.fromHex("3B2418")
		st.Parent = t
	end
	-- live queue status floating over the pad
	local holder = b:block(Vector3.new(1, 1, 1), center + Vector3.new(0, 12, 0), "#FFFFFF", Enum.Material.SmoothPlastic, model, "QueueStatusAnchor")
	holder.Transparency = 1
	holder.CanCollide = false
	holder.CanQuery = false
	local bb = Instance.new("BillboardGui")
	bb.Name = "QueueStatus"
	bb.Size = UDim2.fromOffset(420, 110)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 160
	bb.LightInfluence = 0
	bb.Parent = holder
	local l = Instance.new("TextLabel")
	l.Name = "Text"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextScaled = true
	l.TextColor3 = Color3.fromHex("FFC93C")
	l.Text = "0 / 20 chefs"
	l.Parent = bb
	local st = Instance.new("UIStroke")
	st.Thickness = 4
	st.Color = Color3.fromHex("3B2418")
	st.Parent = l
	Lobby.queueLabel = l
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromHex("FFC93C"))
	sparkle.Size = NumberSequence.new(0.6, 0)
	sparkle.Rate = 12
	sparkle.Lifetime = NumberRange.new(1, 2)
	sparkle.Speed = NumberRange.new(2, 5)
	sparkle.SpreadAngle = Vector2.new(20, 20)
	sparkle.EmissionDirection = Enum.NormalId.Right
	sparkle.Parent = pad
	Lobby.queuePad = pad
	return pad
end

function Lobby.setQueueStatus(count: number, max: number, secondsLeft: number?, status: string)
	local l = Lobby.queueLabel
	if not l then
		return
	end
	if status == "Teleporting" then
		l.Text = "Heading to the kitchen! 🍳"
	elseif secondsLeft then
		l.Text = string.format("%d / %d chefs\nstarting in %d", count, max, math.ceil(secondsLeft))
	else
		l.Text = string.format("%d / %d chefs\nstep on to play!", count, max)
	end
	local pad = Lobby.queuePad
	if pad then
		pad.Color = secondsLeft and Color3.fromHex("FFC93C") or Color3.fromHex("4CAF50")
	end
end

function Lobby.randomSpawnCFrame(): CFrame
	local o = Lobby.Origin
	local x = math.random(-40, 40)
	local z = math.random(-25, 5)
	return CFrame.new(o + Vector3.new(x, 4, z)) * CFrame.Angles(0, math.pi, 0)
end

function Lobby.setBoard(name: string, text: string)
	local l = boards[name]
	if l then
		l.Text = text
	end
end

return Lobby
