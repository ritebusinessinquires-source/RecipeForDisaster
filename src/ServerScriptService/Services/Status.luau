-- Player status effects from hazards: damage with kill credit, knockback, freeze, burn, slow.
-- Movement speed is recomputed here every tick from all active effects.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Net = require(Shared.Net)

local Status = {}

type State = {
	lastDish: string?,
	lastDishAt: number,
	frozenUntil: number,
	burnUntil: number,
	burnDps: number,
	burnDish: string?,
	slows: { [string]: { factor: number, untilT: number } },
	iceBlock: BasePart?,
	fire: Fire?,
	poisonUntil: number,
	poisonDps: number,
	poisonDish: string?,
	poisonFx: ParticleEmitter?,
	invulnerableUntil: number,
}

local states: { [any]: State } = {}

local function getState(player: any): State
	local s = states[player]
	if not s then
		s = {
			lastDish = nil,
			lastDishAt = 0,
			frozenUntil = 0,
			burnUntil = 0,
			burnDps = 0,
			burnDish = nil,
			slows = {},
			iceBlock = nil,
			fire = nil,
			poisonUntil = 0,
			poisonDps = 0,
			poisonDish = nil,
			poisonFx = nil,
			invulnerableUntil = 0,
		}
		states[player] = s
	end
	return s
end

local function charParts(player: any): (Model?, Humanoid?, BasePart?)
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	return char, hum, root
end
Status.charParts = charParts

function Status.reset(player: any)
	local s = states[player]
	if s then
		if s.iceBlock then
			s.iceBlock:Destroy()
		end
		if s.fire then
			s.fire:Destroy()
		end
		if s.poisonFx then
			s.poisonFx:Destroy()
		end
	end
	states[player] = nil
end

function Status.setInvulnerable(player: any, seconds: number)
	getState(player).invulnerableUntil = os.clock() + seconds
end

function Status.recordHit(player: any, dishId: string?)
	if dishId then
		local s = getState(player)
		s.lastDish = dishId
		s.lastDishAt = os.clock()
	end
end

function Status.lastDish(player: any): string?
	local s = states[player]
	return s and s.lastDish
end

function Status.damage(player: any, amount: number, dishId: string?)
	local _, hum = charParts(player)
	if not hum or hum.Health <= 0 then
		return
	end
	local s = getState(player)
	if os.clock() < s.invulnerableUntil then
		return
	end
	Status.recordHit(player, dishId)
	hum:TakeDamage(amount)
end

function Status.kill(player: any, dishId: string?)
	local _, hum = charParts(player)
	if hum and hum.Health > 0 then
		Status.recordHit(player, dishId)
		hum.Health = 0
	end
end

function Status.knockback(player: any, velocity: Vector3)
	if Net.isRealPlayer(player) then
		Net.fire(player, "Knockback", velocity)
	else
		local _, _, root = charParts(player)
		if root then
			root.AssemblyLinearVelocity = velocity
		end
	end
end

function Status.freeze(player: any, seconds: number, dishId: string?)
	local _, _, root = charParts(player)
	if not root then
		return
	end
	local s = getState(player)
	Status.recordHit(player, dishId)
	s.frozenUntil = math.max(s.frozenUntil, os.clock() + seconds)
	if not s.iceBlock or not s.iceBlock.Parent then
		local block = Instance.new("Part")
		block.Name = "IceBlock"
		block.Size = Vector3.new(4.5, 6.5, 4.5)
		block.Color = Color3.fromRGB(170, 225, 255)
		block.Material = Enum.Material.Ice
		block.Transparency = 0.45
		block.CanCollide = false
		block.CanQuery = false
		block.CanTouch = false
		block.Massless = true
		block.CFrame = root.CFrame * CFrame.new(0, -0.5, 0)
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = block
		w.Parent = block
		block.Parent = player.Character
		s.iceBlock = block
	end
	Net.fire(player, "ClientEffect", { kind = "Frozen", duration = seconds })
end

function Status.burn(player: any, seconds: number, dps: number, dishId: string?)
	local _, _, root = charParts(player)
	if not root then
		return
	end
	local s = getState(player)
	Status.recordHit(player, dishId)
	s.burnUntil = math.max(s.burnUntil, os.clock() + seconds)
	s.burnDps = math.max(s.burnDps, dps)
	s.burnDish = dishId or s.burnDish
	if not s.fire or not s.fire.Parent then
		local f = Instance.new("Fire")
		f.Size = 5
		f.Heat = 9
		f.Parent = root
		s.fire = f
	end
end

-- Poison: green bubbles and damage over time.
function Status.poison(player: any, seconds: number, dps: number, dishId: string?)
	local _, _, root = charParts(player)
	if not root then
		return
	end
	local s = getState(player)
	Status.recordHit(player, dishId)
	s.poisonUntil = math.max(s.poisonUntil, os.clock() + seconds)
	s.poisonDps = math.max(s.poisonDps, dps)
	s.poisonDish = dishId or s.poisonDish
	if not s.poisonFx or not s.poisonFx.Parent then
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(120, 230, 60))
		e.Size = NumberSequence.new(0.8, 1.6)
		e.Transparency = NumberSequence.new(0.3, 1)
		e.Lifetime = NumberRange.new(0.6, 1)
		e.Rate = 14
		e.Speed = NumberRange.new(1, 3)
		e.Parent = root
		s.poisonFx = e
	end
	Net.fire(player, "ClientEffect", { kind = "Poisoned", duration = seconds })
end

-- Stun: you can barely move for a moment (Electric).
function Status.stun(player: any, seconds: number, dishId: string?)
	Status.recordHit(player, dishId)
	Status.slow(player, "stun", 0.08, seconds)
	Net.fire(player, "ClientEffect", { kind = "Stunned", duration = seconds })
end

function Status.slow(player: any, key: string, factor: number, seconds: number)
	local s = getState(player)
	s.slows[key] = { factor = factor, untilT = os.clock() + seconds }
end

function Status.isFrozen(player: any): boolean
	local s = states[player]
	return s ~= nil and s.frozenUntil > os.clock()
end

-- Called ~10x per second by the round manager for every living participant.
function Status.tick(player: any, dt: number)
	local s = getState(player)
	local _, hum, _ = charParts(player)
	if not hum then
		return
	end
	local now = os.clock()
	-- burning
	if s.burnUntil > now then
		Status.damage(player, s.burnDps * dt, s.burnDish)
	elseif s.fire then
		s.fire:Destroy()
		s.fire = nil
		s.burnDps = 0
	end
	-- poison
	if s.poisonUntil > now then
		Status.damage(player, s.poisonDps * dt, s.poisonDish)
	elseif s.poisonFx then
		s.poisonFx:Destroy()
		s.poisonFx = nil
		s.poisonDps = 0
	end
	-- frozen
	local frozen = s.frozenUntil > now
	if not frozen and s.iceBlock then
		s.iceBlock:Destroy()
		s.iceBlock = nil
	end
	-- slows
	local mult = 1
	for key, sl in pairs(s.slows) do
		if sl.untilT > now then
			mult *= sl.factor
		else
			s.slows[key] = nil
		end
	end
	local speed = frozen and 0 or Config.WalkSpeed * mult
	local jump = frozen and 0 or Config.JumpPower * math.clamp(mult * 1.2, 0.35, 1)
	if math.abs(hum.WalkSpeed - speed) > 0.05 then
		hum.WalkSpeed = speed
	end
	if math.abs(hum.JumpPower - jump) > 0.05 then
		hum.JumpPower = jump
	end
end

return Status
