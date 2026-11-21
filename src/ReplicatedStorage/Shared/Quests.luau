-- Daily quest pool. Each day a player gets 3 quests picked from this pool (seeded by day + user).
-- event: the server event that advances the quest. filter: optional match on the event payload.

local Quests = {}

Quests.Pool = {
	{ id = "survive_creature", text = "Survive 3 Creature dishes", event = "surviveDish", filter = { type = "Creature" }, target = 3, reward = 200 },
	{ id = "survive_projectile", text = "Survive 3 Projectile dishes", event = "surviveDish", filter = { type = "Projectile" }, target = 3, reward = 200 },
	{ id = "survive_terrain", text = "Survive 2 Terrain dishes", event = "surviveDish", filter = { type = "Terrain" }, target = 2, reward = 200 },
	{ id = "survive_weather", text = "Survive a Weather dish", event = "surviveDish", filter = { type = "Weather" }, target = 1, reward = 150 },
	{ id = "survive_twist", text = "Survive a dish with a Twist", event = "surviveDish", filter = { twist = true }, target = 1, reward = 150 },
	{ id = "survive_courses", text = "Survive 10 courses", event = "surviveDish", target = 10, reward = 250 },
	{ id = "cook_frozen", text = "Cook a dish with Frozen", event = "cookSpice", filter = { spice = "Frozen" }, target = 1, reward = 200, needs = "Frozen" },
	{ id = "cook_giant", text = "Cook a dish with Giant", event = "cookSpice", filter = { spice = "Giant" }, target = 1, reward = 150, needs = "Giant" },
	{ id = "cook_fast", text = "Cook a dish with Fast", event = "cookSpice", filter = { spice = "Fast" }, target = 1, reward = 150, needs = "Fast" },
	{ id = "cook_flaming", text = "Cook a dish with Flaming", event = "cookSpice", filter = { spice = "Flaming" }, target = 1, reward = 200, needs = "Flaming" },
	{ id = "cook_main", text = "Pick the Main as Chef 2 times", event = "cookMain", target = 2, reward = 200 },
	{ id = "be_chef", text = "Be a Chef 3 times", event = "beChef", target = 3, reward = 200 },
	{ id = "elim_chef", text = "Eliminate 5 players as Chef", event = "chefElimination", target = 5, reward = 300 },
	{ id = "win_round", text = "Win a round", event = "win", target = 1, reward = 300 },
	{ id = "find_dishes", text = "Add 5 dishes to your Cookbook", event = "cookbook", target = 5, reward = 250 },
	{ id = "play_rounds", text = "Play 3 rounds", event = "playRound", target = 3, reward = 150 },
}

function Quests.get(id: string)
	for _, q in ipairs(Quests.Pool) do
		if q.id == id then
			return q
		end
	end
	return nil
end

return Quests
