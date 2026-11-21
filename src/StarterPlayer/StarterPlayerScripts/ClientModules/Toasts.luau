-- Toasts: Cash popups and notifications stacked at the top right.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local UI = require(script.Parent.UI)

local Toasts = {}

local container: Frame
local count = 0

local KIND_COLORS = {
	cash = UI.C.Mustard,
	big = UI.C.Tomato,
	badge = UI.C.Grape,
	quest = UI.C.Basil,
	info = UI.C.Cream,
}

function Toasts.show(text: string, kind: string?)
	kind = kind or "info"
	count += 1
	local color = KIND_COLORS[kind] or UI.C.Cream
	local big = kind == "big" or kind == "badge"
	local holder, face = UI.panel(container, {
		Name = "Toast",
		Size = UDim2.new(1, 0, 0, big and 64 or 44),
		AnchorPoint = Vector2.new(1, 0),
		Color = color,
		LayoutOrder = -count,
		StrokeThickness = 3,
		Corner = 12,
	})
	local light = kind == "info" or kind == "cash"
	UI.label(face, {
		Text = text,
		Title = true,
		Color = light and UI.C.Chocolate or UI.C.White,
		Stroke = (not light) and 2 or nil,
		Size = UDim2.fromScale(0.94, 0.8),
		Position = UDim2.fromScale(0.03, 0.1),
		MaxText = big and 26 or 20,
	})
	UI.pop(holder)
	if kind == "cash" then
		UI.sound("Coin", 0.4, 1.2)
	elseif big then
		UI.sound("Ding", 0.6)
	end
	task.delay(big and 4.5 or 2.6, function()
		UI.shrinkOut(holder, function()
			holder:Destroy()
		end)
	end)
	-- keep at most 5
	local items = {}
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("Frame") then
			table.insert(items, c)
		end
	end
	if #items > 5 then
		table.sort(items, function(a, b)
			return a.LayoutOrder > b.LayoutOrder
		end)
		items[1]:Destroy()
	end
end

function Toasts.init(gui: ScreenGui)
	container = UI.new("Frame", {
		Name = "Toasts",
		Size = UDim2.new(0.32, 0, 0.5, 0),
		Position = UDim2.new(1, -10, 0, 120),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	UI.new("UISizeConstraint", { MinSize = Vector2.new(220, 0), MaxSize = Vector2.new(420, 2000), Parent = container })
	UI.list(container, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right)
	Net.event("Toast").OnClientEvent:Connect(function(t)
		if type(t) == "table" and t.text then
			Toasts.show(t.text, t.kind)
		end
	end)
end

return Toasts
