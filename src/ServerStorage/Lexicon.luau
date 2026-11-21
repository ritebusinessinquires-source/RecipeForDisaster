-- Lexicon: turns anything a player types into ingredients.
--   Mains  (things that hurt you), Spices (describing words), Twists (arena changes).
-- Well-known characters and media are recognised by name and mapped onto a generic
-- behaviour (an energy fighter, a ninja, a wizard...). Nothing recreates how they look:
-- every hazard is a generic blocky model labelled with whatever the player typed.
-- Words the game doesn't know still do something: they're hashed onto an ingredient.

local Lexicon = {}

local function hash(s: string): number
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + string.byte(s, i)) % 2147483647
	end
	return h
end
Lexicon.hash = hash

---------------------------------------------------------------- word lists

Lexicon.MainWords = {
	Bees = { "bee", "bumblebee", "wasp", "hornet", "fly", "mosquito", "bat", "bird", "crow", "pigeon", "seagull", "butterfly", "moth", "parrot", "eagle", "owl", "ladybug", "beetle", "dragonfly", "locust", "gnat", "hummingbird", "vulture", "angry bird", "angry birds", "hive", "honeybee", "insect", "bug", "cicada", "firefly" },
	Zombies = { "zombie", "undead", "walker", "mummy", "skeleton", "vampire", "werewolf", "ghoul", "monster", "creeper", "noob", "bacon hair", "villager", "clown", "goblin", "orc", "troll", "frankenstein", "dracula", "pennywise", "freddy", "jason", "steve", "herobrine", "enderman", "xenomorph", "zombie horde", "nerd", "teacher", "student", "grandpa", "grandma", "baby", "people", "person", "man", "woman", "kid", "guy", "doll", "scarecrow", "pirate zombie", "skibidi", "skibidi toilet", "cameraman", "huggy wuggy", "granny", "baldi", "piggy" },
	Chickens = { "chicken", "hen", "rooster", "duck", "goose", "turkey", "penguin", "chick", "ostrich", "chocobo", "emu", "flamingo", "peacock", "dodo", "psyduck" },
	Critter = { "cat", "kitten", "kitty", "dog", "puppy", "doggo", "rabbit", "bunny", "hamster", "mouse", "rat", "fox", "raccoon", "squirrel", "frog", "toad", "monkey", "pikachu", "eevee", "sonic", "stitch", "minion", "minions", "capybara", "pig", "goat", "sheep", "cow", "horse", "llama", "alpaca", "kangaroo", "wolf", "lion", "tiger", "panda", "koala", "raptor", "velociraptor", "lizard", "gecko", "chipmunk", "hedgehog", "ferret", "otter", "sloth", "pokemon", "doge", "shiba", "grogu", "baby yoda", "jerry", "tom", "garfield", "snoopy", "scooby", "scooby doo", "pluto", "goofy", "mickey", "mickey mouse", "bugs bunny", "tails", "knuckles", "crash", "crash bandicoot", "yoshi", "pac man", "pacman", "puppet", "gremlin", "tanuki", "corgi", "pug", "chihuahua", "beaver", "possum", "skunk", "deer", "moose", "bear", "polar bear", "teddy bear" },
	Sharks = { "shark", "jaws", "megalodon", "crocodile", "alligator", "croc", "gator", "piranha", "kraken", "octopus", "squid", "whale", "eel", "orca", "fish", "dolphin", "mermaid", "sea monster", "leviathan", "loch ness", "nessie", "hammerhead", "stingray", "jellyfish", "lobster", "crab", "barracuda", "blobfish", "seal", "walrus" },
	Robots = { "robot", "android", "cyborg", "terminator", "droid", "r2d2", "c3po", "wall e", "walle", "megaman", "mega man", "iron man", "ironman", "ultron", "genos", "roomba", "ai", "computer", "drone", "soldier", "army man", "army", "police", "cop", "sniper", "turret", "stormtrooper", "master chief", "cowboy", "gunslinger", "archer", "legolas", "hawkeye", "bounty hunter", "boba fett", "mandalorian", "dalek", "glados", "baymax", "bender", "astronaut", "space marine", "spaceship", "tank man", "laser", "lasers" },
	Ghosts = { "ghost", "spirit", "spook", "phantom", "specter", "spectre", "poltergeist", "boo", "king boo", "casper", "no face", "noface", "banshee", "soul", "reaper", "grim reaper", "wraith", "shade", "haunted", "gengar", "dementor", "nazgul", "jellyfish ghost", "wisp", "will o wisp" },
	Meteors = { "meteor", "meteorite", "asteroid", "comet", "rock", "stone", "hail", "missile", "satellite", "star", "shooting star", "space rock", "planet", "moon rock", "rain of fire", "fireball", "cannonball", "cannon", "airstrike", "nuke" },
	Boulders = { "boulder", "ball", "barrel", "wheel", "snowball", "bowling ball", "beach ball", "pinball", "donut", "doughnut", "katamari", "tire", "log", "cheese wheel", "armadillo", "marble", "soccer ball", "football", "basketball", "baseball", "orb", "bubble", "giant ball", "rolling pin", "can", "coconut", "melon", "watermelon", "orange", "meatball" },
	Cars = { "car", "truck", "bus", "train", "tank", "taxi", "van", "motorcycle", "motorbike", "bike", "bicycle", "tractor", "lightning mcqueen", "mcqueen", "thomas", "thomas the tank engine", "batmobile", "monster truck", "ambulance", "firetruck", "fire truck", "police car", "race car", "racecar", "go kart", "kart", "mario kart", "delorean", "shopping cart", "cart", "scooter", "skateboard", "bulldozer", "steamroller", "lawnmower", "subway", "locomotive", "jeep", "limo", "hovercraft", "minecart", "roller coaster", "rollercoaster", "zamboni", "forklift", "garbage truck" },
	Lava = { "lava", "magma", "acid", "hot floor", "floor is lava", "the floor is lava", "volcano", "molten", "fire floor", "hell", "inferno floor", "acid rain", "toxic waste", "radioactive waste", "sludge" },
	Quicksand = { "quicksand", "sand", "mud", "swamp", "bog", "tar", "glue", "honey", "gaara", "desert", "sinkhole", "marsh", "syrup", "maple syrup", "peanut butter", "chocolate", "pudding floor", "dough", "cement", "concrete" },
	Tornado = { "tornado", "hurricane", "twister", "cyclone", "black hole", "blackhole", "whirlpool", "vortex", "sandstorm", "wind", "blender", "fan", "washing machine", "typhoon", "dust devil", "portal", "wormhole", "vacuum", "vacuum cleaner", "toilet flush", "beyblade", "spinner", "fidget spinner" },
	Storm = { "storm", "lightning", "thunder", "thunderstorm", "zeus", "thor", "raiden", "electricity", "tesla", "lightning bolt", "rain cloud", "cloud", "thundercloud", "electro", "storm cloud", "god", "gods" },
	Fighter = { "fighter", "boxer", "martial artist", "karate", "kung fu", "wrestler", "superhero", "hero", "goku", "vegeta", "gohan", "goten", "trunks", "broly", "frieza", "freeza", "cell", "majin buu", "buu", "piccolo", "krillin", "saitama", "one punch man", "luffy", "deku", "all might", "bakugo", "todoroki", "jotaro", "dio", "giorno", "gon", "yusuke", "superman", "captain america", "rocky", "ryu", "ken", "chun li", "street fighter", "tekken", "mario", "luigi", "bowser", "kratos", "dante", "vash", "yami", "jinwoo", "sung jinwoo", "baki", "yuji", "itadori", "denji", "chainsaw man", "power", "makima", "eren yeager", "mob", "reigen", "levi", "shinji", "asta", "natsu", "lucy", "edward elric", "ed", "spike", "speedwagon", "kamehameha", "super saiyan", "saiyan", "power ranger", "power rangers", "batman", "flash", "the flash", "shazam", "black panther", "captain marvel", "punch", "fist", "karen", "chad", "sigma", "gigachad" },
	Ninja = { "ninja", "assassin", "shinobi", "thief", "naruto", "sasuke", "kakashi", "itachi", "madara", "sakura", "hinata", "minato", "jiraiya", "orochimaru", "pain", "obito", "boruto", "spiderman", "spider man", "deadpool", "impostor", "imposter", "among us", "amogus", "spy", "agent", "secret agent", "james bond", "007", "killua", "hisoka", "shadow", "shadow the hedgehog", "sly cooper", "ezio", "hitman", "ninja turtle", "ninja turtles", "leonardo", "raphael", "donatello", "michelangelo", "splinter", "shuriken", "kunai" },
	Wizard = { "wizard", "witch", "mage", "sorcerer", "sorceress", "warlock", "magician", "gojo", "satoru gojo", "sukuna", "megumin", "harry potter", "harry", "hermione", "ron", "voldemort", "gandalf", "dumbledore", "doctor strange", "dr strange", "elsa", "merlin", "frieren", "saruman", "scarlet witch", "loki", "maleficent", "ursula", "jafar", "genie", "fairy", "fairy godmother", "shaman", "necromancer", "lich", "wizard101", "magic", "spell", "spells", "potion", "hex", "anya", "yor", "loid", "rimuru tempest", "ainz", "sung", "tanya", "nami", "robin", "usopp", "sanji", "chopper", "zatanna", "mystic", "oracle", "druid", "alchemist", "warlock zombie" },
	Swordsman = { "samurai", "knight", "swordsman", "sword", "swords", "katana", "pirate", "viking", "gladiator", "zoro", "tanjiro", "zenitsu", "inosuke", "rengoku", "giyu", "muzan", "kenshin", "guts", "link", "cloud", "cloud strife", "sephiroth", "kirito", "asuna", "jedi", "sith", "darth vader", "vader", "luke skywalker", "luke", "yoda", "obi wan", "obiwan", "kylo ren", "ichigo", "jack sparrow", "captain hook", "mulan", "aragorn", "zelda", "excalibur", "king arthur", "lancelot", "musketeer", "lightsaber", "spartan", "warrior", "paladin", "barbarian", "conan", "mikasa", "levi ackerman", "rukia", "byakuya", "kaido", "shanks", "mihawk", "whitebeard", "ronin", "shogun", "berserker", "sword fighter", "fencer", "chef", "butcher", "knife", "axe", "scythe", "chainsaw" },
	Titan = { "titan", "titans", "ogre", "cyclops", "golem", "kaiju", "godzilla", "king kong", "kong", "hulk", "eren", "colossal titan", "attack on titan", "shrek", "thanos", "groot", "gundam", "evangelion", "eva", "ultraman", "optimus prime", "optimus", "megatron", "transformer", "transformers", "dinosaur", "dino", "t rex", "trex", "tyrannosaurus", "gorilla", "yeti", "bigfoot", "sasquatch", "totoro", "sumo", "mech", "mecha", "giant robot", "jaeger", "pacific rim", "colossus", "juggernaut", "big chungus", "chungus", "elephant", "mammoth", "rhino", "hippo", "behemoth", "atlas", "statue", "statue of liberty", "snorlax", "mewtwo", "groudon", "kyogre", "rayquaza", "cthulhu", "leviathan titan", "galactus", "darkseid", "blue whale", "cyborg giant", "skyscraper", "building", "tower", "eiffel tower", "mountain" },
	Dragon = { "dragon", "dragons", "wyvern", "phoenix", "shenron", "charizard", "smaug", "toothless", "drogon", "bahamut", "ender dragon", "griffin", "gryphon", "pterodactyl", "firebird", "hydra", "dragonite", "ridley", "spyro", "mushu", "fafnir", "tiamat", "wyrm", "basilisk", "dragon king", "dragonborn", "alduin", "thunderbird", "pegasus", "unicorn", "manticore", "chimera" },
	UFO = { "ufo", "alien", "aliens", "martian", "martians", "invader", "invaders", "et", "e t", "flying saucer", "saucer", "predator", "mothership", "space invader", "space invaders", "abduction", "little green men", "grey alien", "area 51", "spaceship alien", "zim", "kang", "kodos", "plankton", "ufos" },
	Slime = { "slime", "slimes", "blob", "jelly", "jello", "goo", "ooze", "pudding", "rimuru", "kirby", "spongebob", "patrick", "ditto", "gelatin", "marshmallow", "gummy bear", "gummy", "gummy bears", "booger", "snot", "flubber", "goop", "mochi", "bubblegum", "gum", "squishmallow", "stay puft", "marshmallow man", "jiggly", "jigglypuff", "metroid", "jellybean", "jelly bean", "lava lamp" },
	Thing = { "piano", "anvil", "safe", "fridge", "refrigerator", "couch", "sofa", "toilet", "sink", "chair", "table", "tv", "television", "phone", "iphone", "book", "homework", "pizza", "burger", "hamburger", "taco", "cake", "sandwich", "banana", "apple", "house", "box", "crate", "brick", "pillow", "sock", "shoe", "rubber duck", "trophy", "money", "coin", "diamond", "gold", "egg", "eggs", "spoon", "fork", "pan", "frying pan", "pot", "teapot", "cup", "mug", "bucket", "bed", "lamp", "clock", "laptop", "keyboard", "controller", "pickle", "cheese", "bread", "toast", "waffle", "pancake", "sushi", "ramen", "noodles", "spaghetti", "hotdog", "hot dog", "fries", "nugget", "nuggets", "cookie", "cookies", "candy", "lollipop", "ice cream", "potato", "carrot", "tomato", "onion", "broccoli", "lemon", "grape", "grapes", "strawberry", "pineapple", "mango", "peach", "avocado", "tree", "flower", "plant", "present", "gift", "backpack", "guitar", "drum", "trumpet", "car tire", "traffic cone", "cone", "sign", "stop sign", "mailbox", "vending machine", "microwave", "oven", "toaster", "kettle", "plunger", "brick wall", "lego", "legos", "block", "cube", "dice", "card", "cards", "pencil", "eraser", "ruler", "paper", "chalk", "backpack", "robux", "noob head", "head", "hat", "crown", "trash can", "bin" },
	Pumpkins = { "pumpkin", "pumpkins", "jack o lantern", "jackolantern", "gourd", "squash" },
	Snowmen = { "snowman", "snowmen", "frosty", "olaf", "snow golem" },
}

Lexicon.SpiceWords = {
	Giant = { "giant", "huge", "big", "massive", "colossal", "enormous", "mega", "titanic", "jumbo", "large", "gigantic", "ginormous", "tall", "fat", "chonky", "chunky", "xl", "xxl", "supersized", "mammoth", "humongous", "immense", "monstrous", "great", "grand", "king size", "kingsize", "oversized", "thick", "beefy", "buff", "swole", "muscular", "strong" },
	Tiny = { "tiny", "small", "mini", "little", "micro", "smol", "itty", "teeny", "pocket", "miniature", "petite", "wee", "bitty", "itty bitty", "microscopic", "nano", "puny", "short", "chibi", "lil" },
	Fast = { "fast", "quick", "speedy", "rapid", "turbo", "zoomy", "hyper", "swift", "angry", "crazy", "rabid", "caffeinated", "sugar", "sugary", "furious", "rushing", "running", "sprinting", "racing", "zooming", "blazing fast", "lightspeed", "nitro", "speed", "insane", "wild", "feral", "unhinged", "aggressive", "berserk", "rage", "raging", "mad", "energetic", "hyperactive", "speedrun", "sonic fast" },
	Slow = { "slow", "sleepy", "lazy", "tired", "sluggish", "chill", "relaxed", "old", "elderly", "snail", "drowsy", "slowmo", "slow motion", "bored", "sad", "depressed", "heavy", "clumsy", "sticky", "gooey", "dizzy", "drunk", "hungover", "cozy", "comfy", "calm", "peaceful", "shy", "nervous" },
	Slippery = { "slippery", "oily", "greasy", "buttery", "butter", "wet", "soapy", "slick", "banana peel", "lubed", "wax", "waxed", "glassy", "smooth", "slidey", "sliding", "skating", "ice skating", "slipping", "sweaty", "moist", "soggy", "drippy" },
	Exploding = { "exploding", "explosive", "bomb", "bombs", "boom", "nuclear", "dynamite", "tnt", "kaboom", "explody", "volatile", "firework", "fireworks", "rocket", "rockets", "atomic", "grenade", "grenades", "c4", "detonating", "blast", "blasting", "kamikaze", "explosion", "explosions", "fizzy", "mentos", "popping", "popcorn", "boomer", "michael bay", "self destructing" },
	Flaming = { "flaming", "fire", "fiery", "burning", "hot", "spicy", "blazing", "inferno", "on fire", "scorching", "burnt", "chili", "pepper", "jalapeno", "habanero", "heated", "flame", "flames", "lit", "toasted", "roasted", "grilled", "fried", "deep fried", "bbq", "barbecue", "smoking", "smoky", "sun", "solar", "molten hot", "ghost pepper", "hellfire", "dragon fire" },
	Frozen = { "frozen", "ice", "icy", "cold", "frosty", "freezing", "snowy", "chilly", "arctic", "glacier", "glacial", "winter", "frost", "snow", "polar", "brrr", "brr", "freezer", "iced", "cool", "chilled", "subzero", "sub zero", "frostbite", "blizzard", "icicle", "popsicle", "slushy", "cryo", "antarctic" },
	Invisible = { "invisible", "hidden", "sneaky", "stealthy", "stealth", "transparent", "clear", "see through", "camouflage", "camo", "secret", "sus", "suspicious", "shadowy", "ghostly", "silent", "quiet", "mysterious", "mystery", "unseen", "cloaked", "ninja like", "vanishing", "disappearing", "glass", "spooky", "creepy", "haunting" },
	Bouncy = { "bouncy", "bouncing", "jumpy", "jumping", "springy", "rubber", "rubbery", "trampoline", "boing", "hoppy", "hopping", "happy", "silly", "goofy", "funny", "derpy", "wobbly", "jiggly", "bubbly", "excited", "hyper bouncy", "pogo", "pogo stick", "kangaroo like", "flubbery", "squishy", "dancing", "party", "partying", "disco", "groovy", "funky" },
	Swarm = { "swarm", "swarming", "many", "lots", "lots of", "army of", "horde", "hordes", "crowd", "million", "millions", "thousand", "thousands", "hundred", "hundreds", "infinite", "multiple", "clones", "cloned", "gang", "flock", "pack", "mob", "squad", "team", "family", "plenty", "endless", "a bunch of", "bunch", "100", "1000", "999", "69", "zillion", "gazillion", "billion", "every", "all", "too many", "multiplying", "duplicating", "shadow clone", "shadow clones", "copies" },
	Magnetic = { "magnetic", "magnet", "attractive", "rizz", "rizzler", "charming", "cute", "lovely", "adorable", "hungry", "greedy", "clingy", "needy", "loving", "romantic", "flirty", "sucking", "vacuuming", "gravitational", "pulling", "grabbing", "hugging", "huggy", "kawaii", "uwu", "sticky hands", "tractor beam" },
	Electric = { "electric", "electrified", "shocking", "zappy", "zapping", "static", "charged", "volt", "volts", "voltage", "neon", "plasma", "energy", "energized", "electrical", "thunderous", "lightning fast", "sparky", "sparkly", "sparkling", "glowing", "glow", "laser powered", "battery", "batteries", "powered", "cyber", "digital", "robotic", "techno", "pikachu powered", "chidori", "rasengan", "spirit bomb" },
	Poison = { "poison", "poisonous", "toxic", "venom", "venomous", "radioactive", "stinky", "smelly", "rotten", "moldy", "sick", "gross", "cursed", "evil", "dark", "demonic", "corrupted", "infected", "diseased", "acidic", "nasty", "slimy", "muddy", "dirty", "spoiled", "expired", "zombified", "mutant", "mutated", "nuclear waste", "sewer", "trash", "garbage", "cringe", "sussy", "goopy", "sludgy", "bad", "mean", "villain", "villainous", "wicked", "sinister" },
}

Lexicon.TwistWords = {
	InTheDark = { "dark", "night", "midnight", "blackout", "darkness", "lights out", "no lights", "nighttime", "pitch black", "eclipse", "shadows", "power outage", "candle", "spooky night" },
	LowGravity = { "moon", "space", "low gravity", "floaty", "zero gravity", "zero g", "astronaut", "gravity", "float", "floating", "flying", "outer space", "mars", "jupiter", "orbit", "weightless", "feather", "balloon", "balloons", "bubble gravity" },
	RisingWater = { "flood", "water", "ocean", "sea", "rain", "tsunami", "wave", "waves", "rising water", "underwater", "pool", "swimming pool", "lake", "river", "bath", "bathtub", "titanic", "sinking", "atlantis", "monsoon", "splash" },
	Fog = { "fog", "mist", "smoke", "foggy", "misty", "cloudy", "steam", "haze", "hazy", "smog", "silent hill", "dust", "dusty", "vapor", "spooky fog", "clouds" },
	Earthquake = { "earthquake", "quake", "shaking", "shake", "tremor", "rumble", "rumbling", "dance party", "stampede", "chaos", "vibrate", "vibrating", "wobble", "jiggle", "bass drop", "drop the bass", "doomsday", "apocalypse", "end of the world" },
	UpsideDown = { "upside down", "reverse", "reversed", "backwards", "flipped", "flip", "opposite", "mirror", "inverted", "australia", "confused", "confusing", "topsy turvy", "uno reverse", "reverse card", "stranger things", "the upside down", "dizzy world" },
}

-- words that carry no meaning on their own
local STOP = {}
for _, w in ipairs({ "a", "an", "the", "of", "with", "and", "very", "super", "made", "on", "in", "my", "is", "that", "really", "extra", "so", "some", "to", "it", "its", "it's", "this", "his", "her", "their", "your", "our", "for", "as", "like", "kinda", "sort", "type", "kind", "from", "at", "by", "be", "are", "was", "who", "which", "but", "or", "just", "too", "most", "more", "less", "ultra", "hella", "totally", "literally", "real", "actual", "x", "vs", "plus", "times" }) do
	STOP[w] = true
end

---------------------------------------------------------------- index

type Entry = { kind: string, id: string, mods: { string }? }
local index: { [string]: { Entry } } = {}
local maxPhrase = 1

local function add(phrase: string, entry: Entry)
	local list = index[phrase]
	if not list then
		list = {}
		index[phrase] = list
	end
	for _, existing in ipairs(list) do
		if existing.kind == entry.kind and existing.id == entry.id then
			return -- the same word listed twice means the same thing once
		end
	end
	table.insert(list, entry)
	local words = 1
	for _ in string.gmatch(phrase, " ") do
		words += 1
	end
	maxPhrase = math.max(maxPhrase, words)
end

-- character/media names that also bring a describing word
Lexicon.AliasMods = {
	megumin = { "Exploding" },
	bakugo = { "Exploding" },
	elsa = { "Frozen" },
	todoroki = { "Frozen", "Flaming" },
	charizard = { "Flaming" },
	rengoku = { "Flaming" },
	zenitsu = { "Electric" },
	killua = { "Electric" },
	pikachu = { "Electric" },
	raiden = { "Electric" },
	thor = { "Electric" },
	zeus = { "Electric" },
	sonic = { "Fast" },
	flash = { "Fast" },
	["the flash"] = { "Fast" },
	goku = { "Fast" },
	["super saiyan"] = { "Fast", "Electric" },
	kirby = { "Bouncy" },
	jigglypuff = { "Bouncy" },
	spongebob = { "Bouncy" },
	tigger = { "Bouncy" },
	yoda = { "Tiny" },
	grogu = { "Tiny" },
	["baby yoda"] = { "Tiny" },
	minions = { "Swarm" },
	minion = { "Swarm" },
	naruto = { "Swarm" },
	["shadow clone"] = { "Swarm" },
	["darth vader"] = { "Magnetic" },
	vader = { "Magnetic" },
	thanos = { "Magnetic" },
	["black hole"] = { "Magnetic" },
	blackhole = { "Magnetic" },
	impostor = { "Invisible" },
	imposter = { "Invisible" },
	["among us"] = { "Invisible" },
	predator = { "Invisible" },
	shrek = { "Slow" },
	snorlax = { "Slow", "Giant" },
	totoro = { "Slow" },
	godzilla = { "Giant" },
	["king kong"] = { "Giant" },
	hulk = { "Giant" },
	["colossal titan"] = { "Giant" },
	creeper = { "Exploding" },
	["toxic waste"] = { "Poison" },
	["acid rain"] = { "Poison" },
	acid = { "Poison" },
	sukuna = { "Poison" },
	orochimaru = { "Poison" },
	gaara = { "Swarm" },
	volcano = { "Exploding", "Giant" },
	sinkhole = { "Giant", "Magnetic" },
	nuke = { "Exploding", "Giant" },
	fireball = { "Flaming" },
	["shooting star"] = { "Fast" },
	pennywise = { "Invisible" },
	["skibidi toilet"] = { "Fast" },
	["chainsaw man"] = { "Fast" },
	["one punch man"] = { "Giant" },
	saitama = { "Giant" },
	["all might"] = { "Giant" },
	gojo = { "Invisible" },
	["satoru gojo"] = { "Invisible" },
	spiderman = { "Bouncy" },
	["spider man"] = { "Bouncy" },
	deadpool = { "Bouncy" },
	frosty = { "Frozen" },
	olaf = { "Frozen", "Bouncy" },
	dementor = { "Frozen" },
	["ender dragon"] = { "Magnetic" },
	phoenix = { "Flaming" },
	smaug = { "Flaming" },
	drogon = { "Flaming" },
	mushu = { "Tiny" },
	gengar = { "Invisible" },
	["king boo"] = { "Giant" },
	cthulhu = { "Poison" },
	["stay puft"] = { "Giant" },
	["marshmallow man"] = { "Giant" },
	["big chungus"] = { "Giant" },
}

for id, words in pairs(Lexicon.MainWords) do
	for _, w in ipairs(words) do
		add(w, { kind = "main", id = id, mods = Lexicon.AliasMods[w] })
	end
end
for id, words in pairs(Lexicon.SpiceWords) do
	for _, w in ipairs(words) do
		add(w, { kind = "spice", id = id })
	end
end
for id, words in pairs(Lexicon.TwistWords) do
	for _, w in ipairs(words) do
		add(w, { kind = "twist", id = id })
	end
end

-- Mains/Spices/Twists by their own names too
local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Catalog"))
for id, m in pairs(Catalog.Mains) do
	add(string.lower(m.name), { kind = "main", id = id })
	add(string.lower(id), { kind = "main", id = id })
end
for id, s in pairs(Catalog.Spices) do
	add(string.lower(s.name), { kind = "spice", id = id })
	if s.double then
		add(string.lower(s.double), { kind = "spice", id = id, mods = { id } })
	end
end
for id, t in pairs(Catalog.Twists) do
	add(string.lower(t.name), { kind = "twist", id = id })
end

---------------------------------------------------------------- parsing

function Lexicon.normalize(text: string): string
	local s = string.lower(text or "")
	s = string.gsub(s, "[%c]", " ")
	s = string.gsub(s, "[%-_'/%.]", " ")
	s = string.gsub(s, "[^%w%s]", "")
	s = string.gsub(s, "%s+", " ")
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	return s
end

local function singular(w: string): { string }
	local out = {}
	if #w > 4 and string.sub(w, -3) == "ies" then
		table.insert(out, string.sub(w, 1, -4) .. "y")
	end
	if #w > 3 and string.sub(w, -2) == "es" then
		table.insert(out, string.sub(w, 1, -3))
	end
	if #w > 2 and string.sub(w, -1) == "s" then
		table.insert(out, string.sub(w, 1, -2))
	end
	if #w > 3 and string.sub(w, -3) == "men" then
		table.insert(out, string.sub(w, 1, -4) .. "man")
	end
	return out
end

local function lookup(phrase: string): { Entry }?
	local e = index[phrase]
	if e then
		return e
	end
	-- plural on the last word
	local head, last = string.match(phrase, "^(.-)%s?(%S+)$")
	if last then
		for _, s in ipairs(singular(last)) do
			local candidate = (head ~= "" and (head .. " ") or "") .. s
			if index[candidate] then
				return index[candidate]
			end
		end
	end
	return nil
end

local function distance1(a: string, b: string): boolean
	-- true if a and b differ by at most one edit (insert, delete, substitute or swap)
	local la, lb = #a, #b
	if math.abs(la - lb) > 1 then
		return false
	end
	local i, j, edits = 1, 1, 0
	while i <= la and j <= lb do
		if string.sub(a, i, i) == string.sub(b, j, j) then
			i += 1
			j += 1
		else
			edits += 1
			if edits > 1 then
				return false
			end
			if la > lb then
				i += 1
			elseif lb > la then
				j += 1
			else
				-- swapped neighbours count as one edit
				if string.sub(a, i, i) == string.sub(b, j + 1, j + 1) and string.sub(a, i + 1, i + 1) == string.sub(b, j, j) then
					i += 2
					j += 2
				else
					i += 1
					j += 1
				end
			end
		end
	end
	edits += (la - i + 1) + (lb - j + 1)
	return edits <= 1
end

local singleWords: { string } = {}
for phrase in pairs(index) do
	if not string.find(phrase, " ") and #phrase >= 4 then
		table.insert(singleWords, phrase)
	end
end
table.sort(singleWords)

local function fuzzy(word: string): { Entry }?
	if #word < 5 then
		return nil
	end
	for _, w in ipairs(singleWords) do
		if string.sub(w, 1, 1) == string.sub(word, 1, 1) and distance1(word, w) then
			return index[w]
		end
	end
	return nil
end

export type Parsed = { mains: { string }, spices: { string }, twists: { string }, unknown: { string }, aliasMods: { string }, normalized: string }

function Lexicon.parse(text: string): Parsed
	local norm = Lexicon.normalize(text)
	local tokens = {}
	for t in string.gmatch(norm, "%S+") do
		table.insert(tokens, t)
		if #tokens >= 12 then
			break
		end
	end
	local out: Parsed = { mains = {}, spices = {}, twists = {}, unknown = {}, aliasMods = {}, normalized = norm }
	local i = 1
	while i <= #tokens do
		local found, used = nil, 0
		for n = math.min(maxPhrase, #tokens - i + 1), 1, -1 do
			local phrase = table.concat(tokens, " ", i, i + n - 1)
			local e = lookup(phrase)
			if e then
				found, used = e, n
				break
			end
		end
		if not found and not STOP[tokens[i]] then
			found = fuzzy(tokens[i])
			used = found and 1 or 0
		end
		if found then
			-- a phrase can mean several things ("fire" is a Spice, "fire floor" a Main...)
			for _, entry in ipairs(found) do
				if entry.kind == "main" then
					table.insert(out.mains, entry.id)
					for _, m in ipairs(entry.mods or {}) do
						table.insert(out.aliasMods, m)
					end
				elseif entry.kind == "spice" then
					table.insert(out.spices, entry.id)
					for _, m in ipairs(entry.mods or {}) do
						table.insert(out.spices, m)
					end
				elseif entry.kind == "twist" then
					table.insert(out.twists, entry.id)
				end
			end
			i += used
		else
			if not STOP[tokens[i]] then
				table.insert(out.unknown, tokens[i])
			end
			i += 1
		end
	end
	return out
end

---------------------------------------------------------------- slot resolution

local FALLBACK_MAINS = { "Thing", "Thing", "Thing", "Thing", "Thing", "Critter", "Slime", "Zombies", "Bees", "Boulders", "Ghosts", "Fighter" }

local SPICE_TO_MAIN = {
	Flaming = "Lava", Frozen = "Boulders", Electric = "Storm", Poison = "Lava", Exploding = "Meteors",
	Invisible = "Ghosts", Swarm = "Bees", Giant = "Titan", Tiny = "Critter", Fast = "Cars", Slow = "Slime",
	Slippery = "Slime", Bouncy = "Slime", Magnetic = "Tornado",
}
local TWIST_TO_MAIN = {
	RisingWater = "Sharks", InTheDark = "Ghosts", Fog = "Ghosts", LowGravity = "Meteors", Earthquake = "Boulders", UpsideDown = "Critter",
}

local function seasonal(id: string, month: number): string?
	if id == "Pumpkins" then
		return month == 10 and "Pumpkins" or "Boulders"
	elseif id == "Snowmen" then
		return month == 12 and "Snowmen" or "Zombies"
	end
	return id
end

-- The Main slot: the thing that hurts you.
-- returns { main, extraMains, spices, unknown (bool), label (display hint) }
function Lexicon.resolveMain(text: string, month: number?): any
	local p = Lexicon.parse(text)
	local m = month or tonumber(os.date("!%m")) :: number
	local mains = {}
	for _, id in ipairs(p.mains) do
		local s = seasonal(id, m)
		if s and not table.find(mains, s) then
			table.insert(mains, s)
		end
	end
	local spices = {}
	for _, id in ipairs(p.aliasMods) do
		table.insert(spices, id)
	end
	for _, id in ipairs(p.spices) do
		table.insert(spices, id)
	end
	local unknown = false
	if #mains == 0 and (#spices > 0 or #p.twists > 0) then
		-- only describing words in the Main slot ("fire", "flood"): pick a thing that fits
		mains = { SPICE_TO_MAIN[spices[1]] or TWIST_TO_MAIN[p.twists[1]] or "Thing" }
	end
	if #mains == 0 then
		unknown = true
		local key = p.normalized ~= "" and p.normalized or "nothing"
		mains = { FALLBACK_MAINS[(hash(key) % #FALLBACK_MAINS) + 1] }
	end
	return {
		main = mains[1],
		extraMains = { mains[2], mains[3] },
		spices = spices,
		twists = p.twists,
		unknown = unknown,
		normalized = p.normalized,
	}
end

-- A Spice slot: describing words. Nouns typed here become extra things in the dish.
function Lexicon.resolveSpice(text: string, month: number?): any
	local p = Lexicon.parse(text)
	local spices = {}
	for _, id in ipairs(p.spices) do
		table.insert(spices, id)
	end
	for _, id in ipairs(p.aliasMods) do
		table.insert(spices, id)
	end
	local m = month or tonumber(os.date("!%m")) :: number
	local mains = {}
	for _, id in ipairs(p.mains) do
		local s = seasonal(id, m)
		if s and not table.find(mains, s) then
			table.insert(mains, s)
		end
	end
	local guessed = false
	if #spices == 0 then
		guessed = true
		local key = p.normalized ~= "" and p.normalized or "nothing"
		local order = Catalog.SpiceOrder
		spices = { order[(hash(key) % #order) + 1] }
	end
	return { spices = spices, mains = mains, twists = p.twists, guessed = guessed, normalized = p.normalized }
end

-- A ghost's typed Twist.
function Lexicon.resolveTwist(text: string): string
	local p = Lexicon.parse(text)
	if #p.twists > 0 then
		return p.twists[1]
	end
	local key = p.normalized ~= "" and p.normalized or "nothing"
	return Catalog.TwistOrder[(hash(key) % #Catalog.TwistOrder) + 1]
end

-- Random typed-looking picks for bots
Lexicon.BotMains = { "bees", "zombie sharks", "angry chickens", "robots", "ghosts", "meteors", "boulders", "monster trucks", "lava", "quicksand", "a tornado", "ninjas", "a wizard", "samurai", "a dragon", "aliens", "slime", "cats", "a thunderstorm", "pianos", "flying pizza", "a titan", "rubber ducks", "dinosaurs", "a kaiju", "jelly", "penguins", "skeletons" }
Lexicon.BotSpices = { "giant", "tiny", "super fast", "sleepy", "slippery", "exploding", "on fire", "frozen", "invisible", "bouncy", "a thousand", "magnetic", "electric", "toxic", "angry", "spicy", "made of butter", "disco", "cursed", "radioactive", "rubber", "glowing", "chonky" }

function Lexicon.botPick(slot: string, rng: Random): string
	local list = slot == "Main" and Lexicon.BotMains or Lexicon.BotSpices
	return list[rng:NextInteger(1, #list)]
end

return Lexicon
