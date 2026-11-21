-- Characters: spawning in the lobby, teleporting into the arena, ghosts, chef hats, aprons,
-- name tags and death effects.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Cosmetics = require(Shared.Cosmetics)
local Net = require(Shared.Net)
local PlayerData = require(ServerScriptService:WaitForChild("PlayerData"))
local Lobby = require(script.Parent.Lobby)

local Characters = {}

local function hex(s: string): Color3
	return Color3.fromHex(s)
end

local function weldTo(base: BasePart, p: BasePart, offset: CFrame)
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = base.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
end

local function mk(shape: Enum.PartType, size: Vector3, color: Color3, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local CYL = CFrame.Angles(0, 0, math.rad(90))

-- Build a hat model for a cosmetic item, sitting on top of `head`.
function Characters.buildHat(itemId: string, head: BasePart): Model
	local item = Cosmetics.Items[itemId] or Cosmetics.Items.hat_classic
	local m = Instance.new("Model")
	m.Name = "ChefHat"
	local c = hex(item.color)
	local mat = item.neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local s = math.max(head.Size.Y, 1)
	local top = head.Size.Y / 2
	local function add(shape, size, color, offset, material)
		local p = mk(shape, size * s, color, material or mat)
		weldTo(head, p, CFrame.new(0, top, 0) * offset)
		p.Parent = m
		return p
	end
	local style = item.style
	if style == "toque" or style == "tall" then
		local h = style == "tall" and 1.6 or 1.0
		add(Enum.PartType.Cylinder, Vector3.new(0.35, 1.25, 1.25), c, CFrame.new(0, 0.12 * s, 0) * CYL)
		add(Enum.PartType.Cylinder, Vector3.new(h, 1.05, 1.05), c, CFrame.new(0, (0.3 + h / 2) * s, 0) * CYL)
		add(Enum.PartType.Ball, Vector3.new(1.45, 1.45, 1.45), c, CFrame.new(0, (0.3 + h + 0.25) * s, 0))
	elseif style == "cap" then
		add(Enum.PartType.Block, Vector3.new(1.3, 0.5, 0.8), c, CFrame.new(0, 0.2 * s, 0))
		add(Enum.PartType.Block, Vector3.new(1.3, 0.1, 0.4), hex("#E84A3A"), CFrame.new(0, 0.3 * s, -0.2 * s))
	elseif style == "beret" then
		add(Enum.PartType.Cylinder, Vector3.new(0.3, 1.5, 1.5), c, CFrame.new(0.1 * s, 0.12 * s, 0) * CFrame.Angles(0, 0, math.rad(80)))
		add(Enum.PartType.Ball, Vector3.new(0.25, 0.25, 0.25), c, CFrame.new(0.1 * s, 0.35 * s, 0))
	elseif style == "bandana" then
		add(Enum.PartType.Cylinder, Vector3.new(0.35, 1.28, 1.28), c, CFrame.new(0, -0.1 * s, 0) * CYL)
		add(Enum.PartType.Block, Vector3.new(0.3, 0.5, 0.15), c, CFrame.new(0.2 * s, -0.2 * s, 0.68 * s))
	elseif style == "pot" then
		add(Enum.PartType.Cylinder, Vector3.new(0.8, 1.35, 1.35), c, CFrame.new(0, 0.25 * s, 0) * CYL, Enum.Material.Metal)
		add(Enum.PartType.Block, Vector3.new(1.2, 0.15, 0.25), hex("#3B2418"), CFrame.new(1.1 * s, 0.45 * s, 0))
	elseif style == "cupcake" then
		add(Enum.PartType.Cylinder, Vector3.new(0.5, 1.2, 1.2), hex("#8B5A2B"), CFrame.new(0, 0.2 * s, 0) * CYL)
		add(Enum.PartType.Ball, Vector3.new(1.3, 1.3, 1.3), c, CFrame.new(0, 0.6 * s, 0))
		add(Enum.PartType.Ball, Vector3.new(0.35, 0.35, 0.35), hex("#E84A3A"), CFrame.new(0, 1.3 * s, 0))
	elseif style == "crown" then
		add(Enum.PartType.Cylinder, Vector3.new(0.5, 1.2, 1.2), c, CFrame.new(0, 0.2 * s, 0) * CYL, Enum.Material.Neon)
		for i = 0, 4 do
			local a = i / 5 * math.pi * 2
			add(Enum.PartType.Block, Vector3.new(0.2, 0.4, 0.2), c, CFrame.new(math.cos(a) * 0.5 * s, 0.6 * s, math.sin(a) * 0.5 * s), Enum.Material.Neon)
		end
	elseif style == "stack" then
		for i = 0, 3 do
			add(Enum.PartType.Cylinder, Vector3.new(0.22, 1.3 - i * 0.05, 1.3 - i * 0.05), c, CFrame.new(0, (0.12 + i * 0.22) * s, 0) * CYL)
		end
		add(Enum.PartType.Block, Vector3.new(0.35, 0.15, 0.35), hex("#FFC93C"), CFrame.new(0, 1.05 * s, 0))
	elseif style == "sushi" then
		add(Enum.PartType.Cylinder, Vector3.new(0.6, 1.2, 1.2), hex("#FFFFFF"), CFrame.new(0, 0.3 * s, 0) * CYL)
		add(Enum.PartType.Cylinder, Vector3.new(0.3, 1.25, 1.25), hex("#2E2E2E"), CFrame.new(0, 0.3 * s, 0) * CYL)
		add(Enum.PartType.Block, Vector3.new(1.3, 0.25, 0.8), hex("#FF8A5B"), CFrame.new(0, 0.7 * s, 0))
	elseif style == "pineapple" then
		add(Enum.PartType.Ball, Vector3.new(1.2, 1.2, 1.2), c, CFrame.new(0, 0.5 * s, 0))
		for i = 0, 3 do
			local a = i / 4 * math.pi * 2
			add(Enum.PartType.Block, Vector3.new(0.15, 0.8, 0.3), hex("#4CAF50"), CFrame.new(math.cos(a) * 0.15 * s, 1.3 * s, math.sin(a) * 0.15 * s) * CFrame.Angles(0, -a, math.rad(20)))
		end
	end
	if item.fire then
		local f = Instance.new("Fire")
		f.Size = 3
		f.Heat = 4
		f.Parent = m:FindFirstChildWhichIsA("BasePart")
	end
	if item.rainbow then
		task.spawn(function()
			local t = 0
			while m.Parent do
				t += 0.05
				for _, p in ipairs(m:GetChildren()) do
					if p:IsA("BasePart") then
						p.Color = Color3.fromHSV((t * 0.2) % 1, 0.6, 1)
					end
				end
				task.wait(0.1)
			end
		end)
	end
	return m
end

local function torsoOf(char: Model): BasePart?
	return (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
end

function Characters.applyCosmetics(player: any)
	local char = player.Character
	if not char then
		return
	end
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local torso = torsoOf(char)
	for _, n in ipairs({ "Apron", "BackItem" }) do
		local old = char:FindFirstChild(n)
		if old then
			old:Destroy()
		end
	end
	if torso then
		local item = Cosmetics.Items[data.cosmetics.equipped.apron or "apron_white"] or Cosmetics.Items.apron_white
		local apron = Instance.new("Model")
		apron.Name = "Apron"
		local front = mk(Enum.PartType.Block, Vector3.new(torso.Size.X * 0.8, torso.Size.Y * 0.9 + 0.5, 0.12), hex(item.color), item.neon and Enum.Material.Neon or Enum.Material.Fabric)
		weldTo(torso, front, CFrame.new(0, -0.35, -(torso.Size.Z / 2 + 0.07)))
		front.Parent = apron
		local pocket = mk(Enum.PartType.Block, Vector3.new(torso.Size.X * 0.35, 0.35, 0.05), hex(item.color):Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Fabric)
		weldTo(front, pocket, CFrame.new(0, -0.35, -0.08))
		pocket.Parent = apron
		apron.Parent = char
		local back = data.cosmetics.equipped.back
		if back and Cosmetics.Items[back] then
			local whisk = Instance.new("Model")
			whisk.Name = "BackItem"
			local handle = mk(Enum.PartType.Cylinder, Vector3.new(2.2, 0.35, 0.35), hex("#FFC93C"), Enum.Material.Neon)
			weldTo(torso, handle, CFrame.new(0.3, 0.3, torso.Size.Z / 2 + 0.3) * CFrame.Angles(0, 0, math.rad(60)))
			handle.Parent = whisk
			local head = mk(Enum.PartType.Ball, Vector3.new(1.1, 1.6, 1.1), hex("#FFD34D"), Enum.Material.Neon)
			head.Shape = Enum.PartType.Ball
			weldTo(handle, head, CFrame.new(1.4, 0, 0))
			head.Transparency = 0.25
			head.Parent = whisk
			whisk.Parent = char
		end
	end
end

function Characters.setChefHat(player: any, on: boolean)
	local char = player.Character
	if not char then
		return
	end
	local old = char:FindFirstChild("ChefHat")
	if old then
		old:Destroy()
	end
	player:SetAttribute("IsChef", on or nil)
	if on then
		local head = char:FindFirstChild("Head") :: BasePart?
		if head then
			local data = PlayerData.get(player)
			local hatId = data and data.cosmetics.equipped.hat or "hat_classic"
			local hat = Characters.buildHat(hatId, head)
			hat.Parent = char
		end
	end
	Characters.updateTag(player)
end

function Characters.updateTag(player: any)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then
		return
	end
	local tag = head:FindFirstChild("RFDTag") :: BillboardGui?
	if not tag then
		local t = Instance.new("BillboardGui")
		t.Name = "RFDTag"
		t.Size = UDim2.fromOffset(200, 30)
		t.StudsOffset = Vector3.new(0, 4.2, 0)
		t.AlwaysOnTop = false
		t.MaxDistance = 90
		t.LightInfluence = 0
		local l = Instance.new("TextLabel")
		l.Name = "Label"
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.Parent = t
		local st = Instance.new("UIStroke")
		st.Thickness = 2
		st.Color = Color3.fromHex("3B2418")
		st.Parent = l
		t.Parent = head
		tag = t
	end
	local bits = {}
	if player:GetAttribute("IsChef") then
		table.insert(bits, "👨‍🍳 CHEF")
	end
	if player:GetAttribute("VIP") then
		table.insert(bits, "⭐VIP")
	end
	local title = player:GetAttribute("Title")
	if title then
		table.insert(bits, title)
	end
	local label = (tag :: BillboardGui):FindFirstChild("Label") :: TextLabel
	label.Text = table.concat(bits, "  ")
	label.TextColor3 = player:GetAttribute("IsChef") and Color3.fromHex("FFC93C") or Color3.new(1, 1, 1)
	;(tag :: BillboardGui).Enabled = #bits > 0
end

function Characters.setGhost(player: any, ghost: boolean)
	player:SetAttribute("Ghost", ghost or nil)
	local char = player.Character
	if not char then
		return
	end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			if ghost then
				if d:GetAttribute("BaseTransparency") == nil then
					d:SetAttribute("BaseTransparency", d.Transparency)
				end
				d.Transparency = math.max(d.Transparency, 0.55)
			elseif d:GetAttribute("BaseTransparency") ~= nil then
				d.Transparency = d:GetAttribute("BaseTransparency")
				d:SetAttribute("BaseTransparency", nil)
			end
		end
	end
	local h = char:FindFirstChild("GhostGlow")
	if ghost and not h then
		local hl = Instance.new("Highlight")
		hl.Name = "GhostGlow"
		hl.FillColor = Color3.fromHex("7B4FD6")
		hl.FillTransparency = 0.6
		hl.OutlineColor = Color3.fromHex("B9A2FF")
		hl.Parent = char
	elseif not ghost and h then
		h:Destroy()
	end
end

local function setCollisionGroup(char: Model)
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "Players"
		end
	end
	char.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			d.CollisionGroup = "Players"
		end
	end)
end

function Characters.teleport(player: any, cf: CFrame)
	local char = player.Character
	if not char then
		return
	end
	if Net.isRealPlayer(player) then
		pcall(function()
			player:RequestStreamAroundAsync(cf.Position, 5)
		end)
	end
	char:PivotTo(cf)
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

-- (Re)spawn a player into the lobby.
function Characters.spawnInLobby(player: any, asGhost: boolean?)
	if Net.isRealPlayer(player) then
		if player:GetAttribute("Spawning") then
			return
		end
		player:SetAttribute("Spawning", true)
		local ok = pcall(player.LoadCharacter, player)
		player:SetAttribute("Spawning", nil)
		if not ok or not player.Parent then
			return
		end
		local char = player.Character or player.CharacterAdded:Wait()
		Characters.teleport(player, Lobby.randomSpawnCFrame())
		Characters.setGhost(player, asGhost == true)
	end
end

function Characters.onCharacterAdded(player: Player, char: Model)
	setCollisionGroup(char)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = Config.JumpPower
		hum.WalkSpeed = Config.WalkSpeed
		hum.BreakJointsOnDeath = false
	end
	task.defer(function()
		Characters.applyCosmetics(player)
		Characters.updateTag(player)
		if player:GetAttribute("Ghost") then
			Characters.setGhost(player, true)
		end
	end)
end

-- Death effects (cosmetic): spawned where the player died.
function Characters.deathEffect(player: any, pos: Vector3)
	local data = PlayerData.get(player)
	local id = data and data.cosmetics.equipped.death or "death_poof"
	local item = Cosmetics.Items[id] or Cosmetics.Items.death_poof
	Net.fireAll("FX", "Death", { pos = pos, style = id, color = item.color })
	if id == "death_pancake" then
		-- a pancake lies where you fell
		local cake = Instance.new("Part")
		cake.Name = "Pancake"
		cake.Shape = Enum.PartType.Cylinder
		cake.Anchored = true
		cake.CanCollide = false
		cake.CanQuery = false
		cake.Size = Vector3.new(0.6, 5, 5)
		cake.Color = hex("#E8B86A")
		cake.CFrame = CFrame.new(pos.X, pos.Y - 2.6, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		cake.Parent = workspace
		local butter = Instance.new("Part")
		butter.Anchored = true
		butter.CanCollide = false
		butter.CanQuery = false
		butter.Size = Vector3.new(1, 0.4, 1)
		butter.Color = hex("#FFE27A")
		butter.CFrame = CFrame.new(pos.X, pos.Y - 2.1, pos.Z)
		butter.Parent = cake
		Debris:AddItem(cake, 8)
	end
end

function Characters.init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			Characters.onCharacterAdded(player, char)
		end)
		player:GetAttributeChangedSignal("VIP"):Connect(function()
			Characters.updateTag(player)
		end)
		player:GetAttributeChangedSignal("Title"):Connect(function()
			Characters.updateTag(player)
		end)
	end)
	PlayerData.Changed:Connect(function(player)
		-- keep worn cosmetics in sync with what's equipped
		local char = player.Character
		if char and typeof(player) == "Instance" then
			local data = PlayerData.get(player)
			local key = data and (tostring(data.cosmetics.equipped.apron) .. tostring(data.cosmetics.equipped.back)) or ""
			if char:GetAttribute("CosmeticKey") ~= key then
				char:SetAttribute("CosmeticKey", key)
				Characters.applyCosmetics(player)
			end
		end
	end)
end

return Characters
