-- Visual style: a loud cartoon TV cooking show.

local Theme = {}

Theme.Colors = {
	Tomato = Color3.fromHex("E84A3A"), -- Mains, danger
	Mustard = Color3.fromHex("FFC93C"), -- Spices, Cash
	Grape = Color3.fromHex("7B4FD6"), -- Twists, ghosts
	Basil = Color3.fromHex("4CAF50"), -- safe, confirm
	Cream = Color3.fromHex("FFF4DC"), -- panels
	Chocolate = Color3.fromHex("3B2418"), -- outlines, text
	White = Color3.new(1, 1, 1),
	Shadow = Color3.fromHex("3B2418"),
	Sky = Color3.fromHex("8FD3FF"),
	Steel = Color3.fromHex("9AA4AE"),
	DarkCream = Color3.fromHex("F2E2BE"),
	Black = Color3.new(0, 0, 0),
}

Theme.SlotColors = {
	Main = Theme.Colors.Tomato,
	Spice = Theme.Colors.Mustard,
	Twist = Theme.Colors.Grape,
}

Theme.TitleFont = Enum.Font.FredokaOne
Theme.BodyFont = Enum.Font.BuilderSansBold

Theme.Corner = 16
Theme.Stroke = 4
Theme.ShadowOffset = 4
Theme.MinTouch = 60

return Theme
