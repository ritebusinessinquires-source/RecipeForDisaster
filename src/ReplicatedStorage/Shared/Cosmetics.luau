-- Cosmetics: chef hats, aprons, pot skins for the reveal, death effects.
-- Nothing here affects survival.

local Cosmetics = {}

Cosmetics.Slots = {
	hat = { name = "Chef Hats", emoji = "👨‍🍳" },
	apron = { name = "Aprons", emoji = "🥼" },
	pot = { name = "Pot Skins", emoji = "🍲" },
	death = { name = "Death Effects", emoji = "💫" },
	back = { name = "Trophies", emoji = "🏆" },
}
Cosmetics.SlotOrder = { "hat", "apron", "pot", "death", "back" }

-- rarity: default | common | epic | legendary | exclusive
Cosmetics.Items = {
	-- Hats (worn while you are a Chef)
	hat_classic = { slot = "hat", name = "Classic Toque", rarity = "default", color = "#FFFFFF", style = "toque" },
	hat_tomato = { slot = "hat", name = "Tomato Toque", rarity = "common", color = "#E84A3A", style = "toque" },
	hat_paper = { slot = "hat", name = "Paper Diner Cap", rarity = "common", color = "#F5F5F5", style = "cap" },
	hat_beret = { slot = "hat", name = "Baker's Beret", rarity = "common", color = "#3B2418", style = "beret" },
	hat_bandana = { slot = "hat", name = "Kitchen Bandana", rarity = "common", color = "#4CAF50", style = "bandana" },
	hat_mustard = { slot = "hat", name = "Mustard Toque", rarity = "common", color = "#FFC93C", style = "toque" },
	hat_tall = { slot = "hat", name = "Tall Toque", rarity = "epic", color = "#FFFFFF", style = "tall" },
	hat_grape = { slot = "hat", name = "Grape Toque", rarity = "epic", color = "#7B4FD6", style = "tall" },
	hat_pot = { slot = "hat", name = "Pot Helmet", rarity = "epic", color = "#9AA4AE", style = "pot" },
	hat_cupcake = { slot = "hat", name = "Cupcake Hat", rarity = "epic", color = "#FF8FB8", style = "cupcake" },
	hat_rainbow = { slot = "hat", name = "Rainbow Toque", rarity = "legendary", color = "#FF5DA2", style = "tall", rainbow = true },
	hat_flame = { slot = "hat", name = "Flaming Toque", rarity = "legendary", color = "#FF7A1A", style = "tall", fire = true },
	hat_crown = { slot = "hat", name = "Royal Chef Crown", rarity = "legendary", color = "#FFD34D", style = "crown" },
	hat_gold = { slot = "hat", name = "Golden Toque", rarity = "exclusive", color = "#FFC93C", style = "tall", neon = true, source = "VIP Chef pass" },
	-- Weekly login-streak exclusives (rotate by week)
	hat_waffle = { slot = "hat", name = "Waffle Hat", rarity = "exclusive", color = "#E0A44A", style = "cap", source = "Day 7 login reward" },
	hat_pancake = { slot = "hat", name = "Pancake Stack", rarity = "exclusive", color = "#E8B86A", style = "stack", source = "Day 7 login reward" },
	hat_sushi = { slot = "hat", name = "Sushi Hat", rarity = "exclusive", color = "#FFFFFF", style = "sushi", source = "Day 7 login reward" },
	hat_pineapple = { slot = "hat", name = "Pineapple Hat", rarity = "exclusive", color = "#F2C230", style = "pineapple", source = "Day 7 login reward" },

	-- Aprons (always worn)
	apron_white = { slot = "apron", name = "Plain Apron", rarity = "default", color = "#FFFFFF" },
	apron_tomato = { slot = "apron", name = "Tomato Apron", rarity = "common", color = "#E84A3A" },
	apron_basil = { slot = "apron", name = "Basil Apron", rarity = "common", color = "#4CAF50" },
	apron_mustard = { slot = "apron", name = "Mustard Apron", rarity = "common", color = "#FFC93C" },
	apron_denim = { slot = "apron", name = "Denim Apron", rarity = "common", color = "#3D6FA8" },
	apron_grape = { slot = "apron", name = "Grape Apron", rarity = "epic", color = "#7B4FD6" },
	apron_chocolate = { slot = "apron", name = "Chocolate Apron", rarity = "epic", color = "#5A3A26" },
	apron_gold = { slot = "apron", name = "Golden Apron", rarity = "legendary", color = "#FFD34D", neon = true },

	-- Pot skins (your pot at the reveal when you cook the Main)
	pot_steel = { slot = "pot", name = "Steel Pot", rarity = "default", color = "#9AA4AE" },
	pot_copper = { slot = "pot", name = "Copper Pot", rarity = "common", color = "#C8743A" },
	pot_red = { slot = "pot", name = "Tomato Pot", rarity = "common", color = "#E84A3A" },
	pot_cauldron = { slot = "pot", name = "Witch Cauldron", rarity = "epic", color = "#2E2A35" },
	pot_teal = { slot = "pot", name = "Retro Teal Pot", rarity = "epic", color = "#2FB5A8" },
	pot_gold = { slot = "pot", name = "Golden Pot", rarity = "legendary", color = "#FFC93C" },

	-- Death effects
	death_poof = { slot = "death", name = "Puff of Flour", rarity = "default", color = "#FFFFFF" },
	death_confetti = { slot = "death", name = "Confetti", rarity = "common", color = "#FFC93C" },
	death_splat = { slot = "death", name = "Ketchup Splat", rarity = "common", color = "#E84A3A" },
	death_pancake = { slot = "death", name = "Turn into a Pancake", rarity = "epic", color = "#E8B86A" },
	death_sparkle = { slot = "death", name = "Sparkle Sprinkles", rarity = "epic", color = "#FF8FB8" },
	death_firework = { slot = "death", name = "Fireworks", rarity = "legendary", color = "#7B4FD6" },

	-- Trophies
	back_whisk = { slot = "back", name = "Golden Whisk", rarity = "exclusive", color = "#FFC93C", source = "#1 on a weekly leaderboard" },
}

Cosmetics.Defaults = { hat = "hat_classic", apron = "apron_white", pot = "pot_steel", death = "death_poof" }
Cosmetics.WeeklyHats = { "hat_waffle", "hat_pancake", "hat_sushi", "hat_pineapple" }

Cosmetics.RarityColors = {
	default = "#BDB3A3",
	common = "#4CAF50",
	epic = "#7B4FD6",
	legendary = "#FFC93C",
	exclusive = "#E84A3A",
}

function Cosmetics.listByRarity(rarity: string, slot: string?): { string }
	local out = {}
	for id, item in pairs(Cosmetics.Items) do
		if item.rarity == rarity and (slot == nil or item.slot == slot) then
			table.insert(out, id)
		end
	end
	table.sort(out)
	return out
end

return Cosmetics
