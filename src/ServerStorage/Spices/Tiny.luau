-- Tiny: small but many. They can't climb.
return {
	id = "Tiny",
	danger = 2,
	sizeWord = true,
	stats = { Size = 0.45, Count = 3, Health = 0.5, Damage = 0.7 },
	double = { name = "Microscopic", stats = { Size = 0.3, Count = 5, Health = 0.3, Damage = 0.5 } },
	hint = { text = "They're tiny - they can't climb!", icon = "raised", priority = 2 },
}
