-- Physics movers: an unanchored root driven by LinearVelocity + AlignOrientation, owned by the
-- server (SetNetworkOwner(nil)) so clients see smooth, interpolated movement.
--   mode "ground": horizontal velocity only, gravity does the rest (blocked by walls, can't climb)
--   mode "fly":    full 3D velocity, hovers above the ground, passes over obstacles
--   mode "phase":  like fly but ignores everything (ghosts)

local PhysicsService = game:GetService("PhysicsService")

local Mover = {}
Mover.__index = Mover

local HAZARD_GROUP = "Hazards"

function Mover.setupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(HAZARD_GROUP)
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Players")
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(HAZARD_GROUP, "Players", false)
		PhysicsService:CollisionGroupSetCollidable(HAZARD_GROUP, HAZARD_GROUP, false)
	end)
end

export type Obj = {
	model: Model,
	root: BasePart,
	radius: number,
	speed: number,
	mode: string,
	dir: Vector3,
	alive: boolean,
	hp: number,
	lastHit: { [any]: number },
	target: any,
	retargetAt: number,
	hover: number,
	turnRate: number,
	lv: LinearVelocity,
	ao: AlignOrientation,
	data: { [string]: any },
}

function Mover.new(ctx: any, model: Model, opts: any): Obj
	local root = model.PrimaryPart :: BasePart
	local mode = opts.mode or "ground"
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = HAZARD_GROUP
			d:SetAttribute("DishId", ctx.dish.id)
		end
	end
	if mode ~= "ground" then
		root.CanCollide = false
	end
	local att = Instance.new("Attachment")
	att.Name = "MoverAttachment"
	att.Parent = root

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	if mode == "ground" then
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		lv.PrimaryTangentAxis = Vector3.xAxis
		lv.SecondaryTangentAxis = Vector3.zAxis
		lv.PlaneVelocity = Vector2.zero
	else
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		lv.VectorVelocity = Vector3.zero
	end
	lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
	lv.MaxForce = math.max(root.AssemblyMass, root:GetMass()) * (opts.accel or 300)
	lv.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = math.huge
	ao.Responsiveness = opts.responsiveness or 18
	ao.CFrame = CFrame.new()
	ao.Parent = root

	local pos = opts.position or Vector3.zero
	model:PivotTo(CFrame.new(pos))
	model.Parent = opts.parent or ctx.folder
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local self: Obj = setmetatable({
		model = model,
		root = root,
		radius = opts.radius or (root.Size.X / 2),
		speed = opts.speed or 10,
		mode = mode,
		dir = (opts.dir or Vector3.new(0, 0, -1)),
		alive = true,
		hp = opts.hp or 50,
		lastHit = {},
		target = nil,
		retargetAt = 0,
		hover = opts.hover or 4,
		turnRate = math.rad(opts.turnRate or 240),
		lv = lv,
		ao = ao,
		data = {},
	}, Mover) :: any
	ctx:addObject(self)
	return self
end

-- Rotate current direction toward desired, limited by turn rate.
local function turnToward(cur: Vector3, desired: Vector3, maxAngle: number): Vector3
	if desired.Magnitude < 1e-3 then
		return cur
	end
	desired = desired.Unit
	local dot = math.clamp(cur:Dot(desired), -1, 1)
	local angle = math.acos(dot)
	if angle <= maxAngle then
		return desired
	end
	local axis = cur:Cross(desired)
	if axis.Magnitude < 1e-4 then
		axis = Vector3.yAxis
	end
	return (CFrame.fromAxisAngle(axis.Unit, maxAngle) * cur).Unit
end
Mover.turnToward = turnToward

-- desired: world direction to move; speedMult scales speed; targetY for fly/phase modes.
function Mover:drive(desired: Vector3, dt: number, speedMult: number?, targetY: number?)
	if not self.alive or not self.root.Parent then
		return
	end
	local flatDesired = desired
	if self.mode == "ground" then
		flatDesired = Vector3.new(desired.X, 0, desired.Z)
	end
	local cur = self.dir
	if self.mode == "ground" then
		cur = Vector3.new(cur.X, 0, cur.Z)
		if cur.Magnitude < 1e-3 then
			cur = Vector3.new(0, 0, -1)
		end
		cur = cur.Unit
	end
	self.dir = turnToward(cur, flatDesired.Magnitude > 1e-3 and flatDesired or cur, self.turnRate * dt)
	local speed = self.speed * (speedMult or 1)
	local v = self.dir * speed
	if self.mode == "ground" then
		self.lv.PlaneVelocity = Vector2.new(v.X, v.Z)
	else
		local y = self.root.Position.Y
		local vy = 0
		if targetY then
			vy = math.clamp((targetY - y) * 3, -30, 30)
		end
		self.lv.VectorVelocity = Vector3.new(v.X, vy, v.Z)
	end
	local face = Vector3.new(self.dir.X, 0, self.dir.Z)
	if face.Magnitude > 1e-3 then
		self.ao.CFrame = CFrame.lookAt(Vector3.zero, face)
	end
end

function Mover:stopMoving()
	if self.mode == "ground" then
		self.lv.PlaneVelocity = Vector2.zero
	else
		self.lv.VectorVelocity = Vector3.zero
	end
end

function Mover:position(): Vector3
	return self.root.Position
end

function Mover:destroy(ctx: any?)
	self.alive = false
	if self.model then
		self.model:Destroy()
	end
	if ctx then
		ctx:removeObject(self)
	end
end

-- Hit cooldown per target
function Mover:canHit(key: any, cooldown: number): boolean
	local now = os.clock()
	local last = self.lastHit[key]
	if last and now - last < cooldown then
		return false
	end
	self.lastHit[key] = now
	return true
end

return Mover
