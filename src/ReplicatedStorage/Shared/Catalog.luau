-- Display data shared by server and client: names, icons, prices, blurbs.
-- Behaviour and stats live on the server (ServerStorage/Mains, Spices, Twists, Recipes).

local Catalog = {}

Catalog.Types = {
	Creature = { name = "Creature", emoji = "🐾", blurb = "NPCs that chase players" },
	Projectile = { name = "Projectile", emoji = "🎯", blurb = "Things that fall or fly across the map" },
	Terrain = { name = "Terrain", emoji = "🟫", blurb = "Changes the ground" },
	Weather = { name = "Weather", emoji = "🌀", blurb = "An arena-wide force" },
}

Catalog.Mains = {
	Bees = { name = "Bees", emoji = "🐝", type = "Creature", price = 0, starter = true, blurb = "A buzzing cloud that chases the nearest player. Bees turn slowly." },
	Zombies = { name = "Zombies", emoji = "🧟", type = "Creature", price = 0, starter = true, blurb = "Shambling hungry zombies. They can't climb." },
	Chickens = { name = "Chickens", emoji = "🐔", type = "Creature", price = 250, blurb = "Fast, flappy and furious. Small pecks, lots of them." },
	Sharks = { name = "Sharks", emoji = "🦈", type = "Creature", price = 1200, blurb = "Lurk in the water and lunge at anyone near the shore." },
	Robots = { name = "Robots", emoji = "🤖", type = "Creature", price = 750, blurb = "Slow walkers that fire laser bolts. Low cover blocks the shots." },
	Ghosts = { name = "Ghosts", emoji = "👻", type = "Creature", price = 1500, blurb = "Slow, floaty and they pass through everything." },
	Meteors = { name = "Meteors", emoji = "☄️", type = "Projectile", price = 0, starter = true, blurb = "Rocks fall from the sky. Watch the shadows." },
	Boulders = { name = "Boulders", emoji = "🪨", type = "Projectile", price = 400, blurb = "Roll across the map. Duck behind low cover." },
	Cars = { name = "Cars", emoji = "🚗", type = "Projectile", price = 750, blurb = "Speed across the arena in straight lines. Honk honk." },
	Lava = { name = "Lava", emoji = "🌋", type = "Terrain", price = 0, starter = true, blurb = "The floor is lava. Literally. Get high or get wet." },
	Quicksand = { name = "Quicksand", emoji = "⏳", type = "Terrain", price = 500, blurb = "Sticky sand patches that slow you down and swallow you." },
	Tornado = { name = "Tornado", emoji = "🌪️", type = "Weather", price = 1000, blurb = "A wandering twister that pulls everyone in." },
	-- Archetypes for typed ingredients (anime fighters, wizards, kaiju...)
	Fighter = { name = "Fighter", emoji = "🥋", type = "Creature", price = 900, blurb = "Dashes at you and fires energy blasts. Hide behind cover." },
	Ninja = { name = "Ninja", emoji = "🥷", type = "Creature", price = 1100, blurb = "Teleports behind you and throws shuriken. Keep moving." },
	Wizard = { name = "Wizard", emoji = "🧙", type = "Creature", price = 1100, blurb = "Keeps its distance, teleports and lobs magic orbs." },
	Swordsman = { name = "Swordsman", emoji = "⚔️", type = "Creature", price = 900, blurb = "Sends sword slashes along the ground. Jump or climb!" },
	Titan = { name = "Titan", emoji = "🗿", type = "Creature", price = 1400, blurb = "A towering giant whose stomps send out shockwaves." },
	Dragon = { name = "Dragon", emoji = "🐉", type = "Creature", price = 1500, blurb = "Circles overhead and breathes lines of fire." },
	UFO = { name = "UFO", emoji = "🛸", type = "Creature", price = 1300, blurb = "Hovers over you, beams you up and zaps lasers." },
	Slime = { name = "Slime", emoji = "🟢", type = "Creature", price = 300, blurb = "Hopping goo that slows you down." },
	Critter = { name = "Critter", emoji = "🐾", type = "Creature", price = 200, blurb = "Small, fast, zig-zagging animals." },
	Storm = { name = "Storm", emoji = "⛈️", type = "Weather", price = 1000, blurb = "Lightning strikes anyone who stands still." },
	Thing = { name = "Mystery Thing", emoji = "📦", type = "Projectile", price = 0, starter = true, blurb = "Anything the game doesn't know falls from the sky." },
	-- Seasonal (only cookable during their event month)
	Pumpkins = { name = "Pumpkins", emoji = "🎃", type = "Projectile", price = 0, seasonal = true, blurb = "October only: giant pumpkins roll and splat." },
	Snowmen = { name = "Snowmen", emoji = "⛄", type = "Creature", price = 0, seasonal = true, blurb = "December only: snowmen that waddle after you." },
}
Catalog.MainOrder = {
	"Bees", "Zombies", "Chickens", "Sharks", "Robots", "Ghosts", "Meteors", "Boulders", "Cars", "Lava", "Quicksand", "Tornado",
	"Fighter", "Ninja", "Wizard", "Swordsman", "Titan", "Dragon", "UFO", "Slime", "Critter", "Storm", "Thing",
}
Catalog.SeasonalOrder = { "Pumpkins", "Snowmen" }

Catalog.Spices = {
	Giant = { name = "Giant", emoji = "🐘", price = 0, starter = true, sizeWord = true, double = "Colossal", blurb = "Huge and slow. Size x3, Speed x0.7." },
	Tiny = { name = "Tiny", emoji = "🤏", price = 0, starter = true, sizeWord = true, double = "Microscopic", blurb = "Small but many. They can't climb." },
	Fast = { name = "Fast", emoji = "💨", price = 0, starter = true, double = "Turbo", blurb = "Everything moves faster." },
	Slow = { name = "Slow", emoji = "🐌", price = 250, double = "Glacial", blurb = "Slower, but hits harder." },
	Slippery = { name = "Slippery", emoji = "🧈", price = 0, starter = true, double = "Greased", blurb = "Leaves ice behind. Hard to stop on." },
	Exploding = { name = "Exploding", emoji = "💥", price = 1000, double = "Megaton", blurb = "Blows up on contact." },
	Flaming = { name = "Flaming", emoji = "🔥", price = 500, double = "Inferno", blurb = "On fire. Sets you on fire too." },
	Frozen = { name = "Frozen", emoji = "❄️", price = 500, double = "Arctic", blurb = "Freezes you solid for a moment." },
	Invisible = { name = "Invisible", emoji = "🙈", price = 1200, double = "Phantom", blurb = "Only a shimmer and a sound." },
	Bouncy = { name = "Bouncy", emoji = "🏀", price = 400, double = "Super Bouncy", blurb = "Boing! Big knockback." },
	Swarm = { name = "Swarm", emoji = "🐜", price = 750, double = "Horde", blurb = "Three times as many, a bit smaller." },
	Magnetic = { name = "Magnetic", emoji = "🧲", price = 1500, double = "Mega-Magnetic", blurb = "Pulls players in." },
	Electric = { name = "Electric", emoji = "⚡", price = 800, double = "Supercharged", blurb = "Zaps and stuns you for a moment." },
	Poison = { name = "Poison", emoji = "☠️", price = 800, double = "Toxic", blurb = "Leaves you poisoned and leaves toxic puddles." },
}
Catalog.SpiceOrder = { "Giant", "Tiny", "Fast", "Slow", "Slippery", "Exploding", "Flaming", "Frozen", "Invisible", "Bouncy", "Swarm", "Magnetic", "Electric", "Poison" }

Catalog.Twists = {
	InTheDark = { name = "In the Dark", emoji = "🌑", suffix = "in the Dark", blurb = "Lights out. Hazards glow faintly." },
	LowGravity = { name = "Low Gravity", emoji = "🪐", suffix = "in Low Gravity", blurb = "Floaty jumps, slow falling." },
	RisingWater = { name = "Rising Water", emoji = "🌊", suffix = "with Rising Water", blurb = "The water rises. Find high ground." },
	Fog = { name = "Fog", emoji = "🌫️", suffix = "in the Fog", blurb = "Thick fog. Listen carefully." },
	Earthquake = { name = "Earthquake", emoji = "📳", suffix = "in an Earthquake", blurb = "The ground shakes and shoves you." },
	UpsideDown = { name = "Upside Down", emoji = "🙃", suffix = "Upside Down", blurb = "Controls reversed for 10 s at a time." },
}
Catalog.TwistOrder = { "InTheDark", "LowGravity", "RisingWater", "Fog", "Earthquake", "UpsideDown" }

Catalog.Maps = {
	Countertop = {
		name = "The Countertop",
		emoji = "🍽️",
		blurb = "A huge kitchen counter seen from the size of a mouse.",
		colors = { "#E9E2D0", "#C9B79C", "#5DA9E9" },
	},
	PicnicMeadow = {
		name = "Picnic Meadow",
		emoji = "🧺",
		blurb = "Rolling hills, a picnic blanket and a pond.",
		colors = { "#7BC96F", "#E84A3A", "#5DA9E9" },
	},
	PizzaPlanet = {
		name = "Pizza Planet",
		emoji = "🍕",
		blurb = "A giant pizza floating in the sky. Don't fall off!",
		colors = { "#F4C26B", "#E84A3A", "#8FD3FF" },
	},
}
Catalog.MapOrder = { "Countertop", "PicnicMeadow", "PizzaPlanet" }

-- Hint icons: readable without words
Catalog.HintIcons = {
	raised = { emoji = "⛰️", label = "Get on high ground" },
	cover = { emoji = "🧱", label = "Hide behind low cover" },
	run = { emoji = "🏃", label = "Keep moving" },
	water = { emoji = "💧", label = "Get in the water" },
	away = { emoji = "↔️", label = "Keep your distance" },
}

Catalog.Taunts = {
	{ id = "chefs_kiss", name = "Chef's Kiss", emoji = "😘", emote = "wave" },
	{ id = "mic_drop", name = "Mic Drop", emoji = "🎤", emote = "point" },
	{ id = "stir_pot", name = "Stir the Pot", emoji = "🥄", emote = "dance" },
	{ id = "salt", name = "Pinch of Salt", emoji = "🧂", emote = "dance2" },
	{ id = "too_hot", name = "Too Hot!", emoji = "🥵", emote = "dance3" },
	{ id = "bon_appetit", name = "Bon Appetit", emoji = "🍽️", emote = "cheer" },
}

Catalog.SecretRecipeCount = 14

Catalog.Badges = {
	{ id = "Welcome", name = "Welcome to the Kitchen", emoji = "👋", desc = "Play your first round." },
	{ id = "Dishes10", name = "Line Cook", emoji = "🥄", desc = "Find 10 dishes." },
	{ id = "Dishes50", name = "Sous Chef", emoji = "🍳", desc = "Find 50 dishes." },
	{ id = "Dishes250", name = "Head Chef", emoji = "👨‍🍳", desc = "Find 250 dishes." },
	{ id = "FirstWin", name = "Last One Standing", emoji = "🏆", desc = "Win a round." },
	{ id = "SecretRecipe", name = "Secret Sauce", emoji = "📜", desc = "Discover a secret recipe." },
}

function Catalog.ingredient(id: string)
	return Catalog.Mains[id] or Catalog.Spices[id] or Catalog.Twists[id]
end

function Catalog.slotOf(id: string): string?
	if Catalog.Mains[id] then
		return "Main"
	elseif Catalog.Spices[id] then
		return "Spice"
	elseif Catalog.Twists[id] then
		return "Twist"
	end
	return nil
end

return Catalog
