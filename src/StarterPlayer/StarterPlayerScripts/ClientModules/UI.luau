-- UI kit: rounded cream panels with thick chocolate outlines and a solid drop shadow,
-- bouncy pop-ins, tilted recipe cards. Mobile first: Scale sizes, aspect constraints,
-- touch targets at least 60 px tall, everything inside the device safe area.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Theme = require(Shared.Theme)
local Config = require(Shared.Config)

local UI = {}
UI.Theme = Theme
UI.C = Theme.Colors

local player = Players.LocalPlayer

function UI.screen(name: string, order: number?): ScreenGui
	local pg = player:WaitForChild("PlayerGui")
	local existing = pg:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = false
	g.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.DisplayOrder = order or 0
	g.Parent = pg
	return g
end

function UI.new(class: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = inst
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

function UI.corner(parent: Instance, px: number?)
	return UI.new("UICorner", { CornerRadius = UDim.new(0, px or Theme.Corner), Parent = parent })
end

function UI.stroke(parent: Instance, thickness: number?, color: Color3?)
	return UI.new("UIStroke", {
		Thickness = thickness or Theme.Stroke,
		Color = color or Theme.Colors.Chocolate,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
end

function UI.textStroke(parent: Instance, thickness: number?)
	return UI.new("UIStroke", {
		Thickness = thickness or 2.5,
		Color = Theme.Colors.Chocolate,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = parent,
	})
end

function UI.aspect(parent: Instance, ratio: number)
	return UI.new("UIAspectRatioConstraint", { AspectRatio = ratio, Parent = parent })
end

function UI.minSize(parent: Instance, x: number, y: number)
	return UI.new("UISizeConstraint", { MinSize = Vector2.new(x, y), Parent = parent })
end

function UI.pad(parent: Instance, px: number)
	return UI.new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
		Parent = parent,
	})
end

function UI.list(parent: Instance, dir: Enum.FillDirection?, pad: number?, halign: Enum.HorizontalAlignment?, valign: Enum.VerticalAlignment?)
	return UI.new("UIListLayout", {
		FillDirection = dir or Enum.FillDirection.Vertical,
		Padding = UDim.new(0, pad or 8),
		HorizontalAlignment = halign or Enum.HorizontalAlignment.Center,
		VerticalAlignment = valign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

-- A panel: holder (sized/positioned) containing a shadow and the face.
-- Returns holder, face.
function UI.panel(parent: Instance, props: any): (Frame, Frame)
	props = props or {}
	-- inside a list/grid layout, anchor top-left so the layout places it cleanly
	local inLayout = parent:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
	local holder = UI.new("Frame", {
		Name = props.Name or "Panel",
		Size = props.Size or UDim2.fromScale(0.3, 0.3),
		Position = props.Position or (inLayout and UDim2.new() or UDim2.fromScale(0.5, 0.5)),
		AnchorPoint = props.AnchorPoint or (inLayout and Vector2.zero or Vector2.new(0.5, 0.5)),
		BackgroundTransparency = 1,
		Rotation = props.Rotation or 0,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible ~= false,
		Parent = parent,
	})
	local shadow = UI.new("Frame", {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, Theme.ShadowOffset),
		BackgroundColor3 = Theme.Colors.Shadow,
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	UI.corner(shadow, props.Corner)
	local face = UI.new("Frame", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = props.Color or Theme.Colors.Cream,
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex,
		ClipsDescendants = props.Clip == true,
		Parent = holder,
	})
	UI.corner(face, props.Corner)
	UI.stroke(face, props.StrokeThickness)
	if props.Aspect then
		UI.aspect(holder, props.Aspect)
	end
	return holder, face
end

function UI.label(parent: Instance, props: any): TextLabel
	props = props or {}
	local l = UI.new("TextLabel", {
		Name = props.Name or "Label",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundTransparency = 1,
		Text = props.Text or "",
		Font = props.Title and Theme.TitleFont or Theme.BodyFont,
		TextColor3 = props.Color or Theme.Colors.Chocolate,
		TextScaled = props.Scaled ~= false,
		TextWrapped = true,
		RichText = props.Rich == true,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		ZIndex = props.ZIndex or 2,
		LayoutOrder = props.LayoutOrder or 0,
		TextSize = props.TextSize or 18,
		Parent = parent,
	})
	if props.MaxText then
		UI.new("UITextSizeConstraint", { MaxTextSize = props.MaxText, MinTextSize = props.MinText or 8, Parent = l })
	end
	if props.Stroke then
		UI.textStroke(l, props.Stroke)
	end
	return l
end

-- Bouncy button. Returns holder, button (TextButton face).
function UI.button(parent: Instance, props: any, onClick: (() -> ())?): (Frame, TextButton)
	props = props or {}
	local holder = UI.new("Frame", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromScale(0.2, 0.1),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 3,
		Visible = props.Visible ~= false,
		Parent = parent,
	})
	if props.Aspect then
		UI.aspect(holder, props.Aspect)
	end
	if props.MinTouch ~= false then
		UI.minSize(holder, props.MinWidth or 60, Theme.MinTouch)
	end
	local shadow = UI.new("Frame", {
		Name = "Shadow",
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, Theme.ShadowOffset),
		BackgroundColor3 = Theme.Colors.Shadow,
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	UI.corner(shadow, props.Corner or 14)
	local btn = UI.new("TextButton", {
		Name = "Face",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = props.Color or Theme.Colors.Mustard,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = props.Text or "",
		Font = Theme.TitleFont,
		TextScaled = true,
		TextColor3 = props.TextColor or Theme.Colors.White,
		ZIndex = holder.ZIndex,
		RichText = props.Rich == true,
		Parent = holder,
	})
	UI.corner(btn, props.Corner or 14)
	UI.stroke(btn, 3)
	if props.TextColor ~= Theme.Colors.Chocolate then
		UI.textStroke(btn, 2)
	end
	UI.pad(btn, props.Padding or 6)
	UI.new("UITextSizeConstraint", { MaxTextSize = props.MaxText or 34, MinTextSize = 10, Parent = btn })
	local scale = UI.new("UIScale", { Parent = holder })
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.92 }):Play()
	end)
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	end)
	if onClick then
		btn.Activated:Connect(function()
			UI.sound("Click")
			onClick()
		end)
	end
	return holder, btn
end

-- Pop an element in with a Back ease (0.3 s)
function UI.pop(inst: GuiObject, delay: number?)
	local scale = inst:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = inst })
	scale.Scale = 0.3
	inst.Visible = true
	task.delay(delay or 0, function()
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)
end

function UI.shrinkOut(inst: GuiObject, after: (() -> ())?)
	local scale = inst:FindFirstChildOfClass("UIScale") or UI.new("UIScale", { Parent = inst })
	local tw = TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 })
	tw.Completed:Connect(function()
		inst.Visible = false
		scale.Scale = 1
		if after then
			after()
		end
	end)
	tw:Play()
end

function UI.tween(inst: Instance, t: number, props: any, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- A recipe card: slot colour band on top, big ingredient icon and its name.
function UI.recipeCard(parent: Instance, props: any): (Frame, TextButton?)
	local slotColor = props.SlotColor or Theme.Colors.Tomato
	local holder, face = UI.panel(parent, {
		Name = props.Name or "Card",
		Size = props.Size or UDim2.fromScale(0.2, 1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Rotation = props.Rotation or 0,
		LayoutOrder = props.LayoutOrder,
		Aspect = props.Aspect or 0.72,
		ZIndex = props.ZIndex or 2,
		Clip = false,
	})
	UI.minSize(holder, 60, 80)
	local band = UI.new("Frame", {
		Name = "Band",
		Size = UDim2.fromScale(1, 0.2),
		BackgroundColor3 = slotColor,
		BorderSizePixel = 0,
		ZIndex = face.ZIndex + 1,
		Parent = face,
	})
	UI.corner(band)
	UI.new("Frame", { Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = slotColor, BorderSizePixel = 0, ZIndex = face.ZIndex + 1, Parent = band })
	UI.label(band, { Text = props.SlotText or "", Title = true, Color = Theme.Colors.White, Stroke = 2, ZIndex = face.ZIndex + 2, Size = UDim2.fromScale(0.9, 0.8), Position = UDim2.fromScale(0.05, 0.1) })
	UI.label(face, { Name = "Icon", Text = props.Emoji or "?", Size = UDim2.fromScale(0.8, 0.45), Position = UDim2.fromScale(0.1, 0.22), ZIndex = face.ZIndex + 1 })
	UI.label(face, { Name = "CardName", Text = props.Text or "", Title = true, Size = UDim2.fromScale(0.9, 0.17), Position = UDim2.fromScale(0.05, 0.66), ZIndex = face.ZIndex + 1 })
	if props.Sub then
		UI.label(face, { Name = "Sub", Text = props.Sub, Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.05, 0.84), ZIndex = face.ZIndex + 1, Color = Color3.fromHex("6B4A35") })
	end
	local btn = nil
	if props.OnClick then
		btn = UI.new("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = face.ZIndex + 5, Parent = face })
		btn.Activated:Connect(function()
			UI.sound("Click")
			props.OnClick()
		end)
	end
	return holder, btn
end

---------------------------------------------------------------- sounds

local soundCache: { [string]: Sound } = {}
function UI.sound(name: string, volume: number?, pitch: number?)
	local id = Config.Sounds[name]
	if not id or id == "" then
		return
	end
	local s = soundCache[name]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		s.Parent = SoundService
		soundCache[name] = s
	end
	s.Volume = volume or 0.6
	s.PlaybackSpeed = pitch or 1
	if s.IsLoaded or true then
		SoundService:PlayLocalSound(s)
	end
end

function UI.fmt(n: number): string
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

return UI
