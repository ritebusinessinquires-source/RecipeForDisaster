--!strict
-- Recipe for Disaster: tunable numbers. Everything here is a starting value to tune in playtests.

local Config = {}

Config.GameName = "Recipe for Disaster"
Config.GroupId = 1104976471 -- free Spin for joining the group
Config.DataStoreName = "RFD_PlayerData_v1"
Config.MailboxStoreName = "RFD_Mailbox_v1"
Config.LeaderboardPrefix = "RFD_Weekly_v1_"

-- Phase timings (seconds)
Config.Timings = {
	Intermission = 15,
	Draft = 15, -- time to type
	Reveal = 5,
	Cook = 45,
	CookSuddenDeath = 30,
	RampAt = 30, -- hazards ramp up this many seconds into the cook
	CourseEnd = 3, -- wipeout banner between courses
	Winner = 10,
	GhostButtonDelay = 4, -- "Become a ghost" button appears after this
	AutoGhostAfter = 12,
}

Config.SuddenDeathCourse = 6
Config.MaxCourses = 14 -- hard safety stop
Config.MinPlayersForRound = 2 -- with 1 player the round runs as solo practice
Config.SoloMaxCourses = 8

-- Matchmaking: public servers are the lobby; walking onto the PLAY pad joins the queue and
-- the queue is sent together into a fresh reserved match server.
Config.Matchmaking = {
	MaxPlayers = 20, -- per match
	MinPlayers = 1, -- a lone player gets solo practice
	Countdown = 20, -- seconds after the first player steps on the pad
	FullCountdown = 3, -- when the queue is full
	ArrivalWait = 25, -- a match server waits this long for its whole group to arrive
}
-- "Lobby" or "Match" to force a mode (handy in Studio). nil = decide automatically.
Config.ForceMode = nil :: string?

-- Dish rules
Config.DangerCap = 10
Config.Caps = {
	Size = 6, -- max size multiplier
	Count = 40, -- max objects per dish
	Speed = 2.5, -- max speed multiplier
}
Config.RampMultiplier = 1.3
Config.FallbackDamageBoost = 1.3 -- "no dead modifiers"
Config.TotalDishes = 16905 -- 23 Mains x 105 Spice pairs x 7 Twist options (typed words map onto these)

Config.HandSize = 4
Config.BiggerHandSize = 5

-- Player movement
Config.WalkSpeed = 18
Config.JumpPower = 52
Config.KillY = -60

-- Economy (Cash)
Config.Economy = {
	SurviveTick = 5,
	SurviveTickInterval = 10,
	SurviveCourse = 20,
	LastStanding = 150,
	BeingChef = 20,
	PerElimination = 15,
	KitchenNightmare = 100,
	KitchenNightmareThreshold = 5,
	NewOnServer = 25,
	NewCookbookEntry = 50,
	SecretRecipe = 500,
	WastedSpice = 25,
	FriendBonus = 0.10,
	VipMultiplier = 1.5,
	DoubleCashMultiplier = 2,
	VipAndDoubleMultiplier = 3,
	DishOfTheDayMultiplier = 2,
	SoloMultiplier = 0.5,
	ReferralReward = 500,
}

Config.StarterCash = 100
Config.StarterSpins = 1

-- Daily login calendar (7 days). Missing a day restarts the current week, not the whole streak.
Config.LoginCalendar = {
	{ cash = 250 },
	{ cash = 350 },
	{ spins = 1 },
	{ cash = 500 },
	{ spins = 1 },
	{ cash = 750 },
	{ spins = 3, weeklyHat = true },
}

Config.QuestsPerDay = 3
Config.QuestBonusSpins = 1

-- Spin wheel odds (shown on the wheel)
Config.SpinOdds = {
	{ id = "common", label = "Common cosmetic", weight = 50 },
	{ id = "cash", label = "Cash", weight = 25 },
	{ id = "ingredient", label = "Rare ingredient", weight = 15 },
	{ id = "epic", label = "Epic cosmetic", weight = 8 },
	{ id = "legendary", label = "Legendary chef hat", weight = 2 },
}
Config.SpinCashRange = { 150, 600 }
Config.DuplicateCommonCash = 100
Config.DuplicateEpicCash = 400
Config.DuplicateLegendaryCash = 1500

-- Codes box (each code once per player)
Config.Codes = {
	WELCOME = { cash = 500 },
	BONAPPETIT = { spins = 1 },
	DISASTER = { cash = 1000 },
	CHEFSKISS = { spins = 2 },
}

-- Seasonal Mains: only cookable during their month (UTC)
Config.Seasonal = {
	Pumpkins = { month = 10 },
	Snowmen = { month = 12 },
}

-- Monetization. Filled in from the Roblox API; 0 = not configured (button hidden).
Config.GamePasses = {
	VIP = { id = 2096800887, price = 299 },
	DoubleCash = { id = 2092727074, price = 199 },
	BiggerHand = { id = 2092948975, price = 249 },
	RecipeHints = { id = 2092925010, price = 149 },
	ChefTaunts = { id = 2096950882, price = 99 },
}

Config.Products = {
	Spin1 = { id = 3734058747, price = 25, spins = 1 },
	Spin5 = { id = 3734058769, price = 99, spins = 5 },
	Spin15 = { id = 3734058772, price = 249, spins = 15 },
	CashS = { id = 3734058783, price = 49, cash = 5000 },
	CashM = { id = 3734058793, price = 199, cash = 25000 },
	CashL = { id = 3734058806, price = 499, cash = 100000 },
	RerollHand = { id = 3734058811, price = 15 },
	GiftVIP = { id = 3734058816, price = 299, gift = "VIP" },
	GiftDoubleCash = { id = 3734058824, price = 199, gift = "DoubleCash" },
	GiftBiggerHand = { id = 3734058829, price = 249, gift = "BiggerHand" },
	GiftRecipeHints = { id = 3734058832, price = 149, gift = "RecipeHints" },
	GiftChefTaunts = { id = 3734058838, price = 99, gift = "ChefTaunts" },
}

-- Roblox badges (0 = in-game badge only)
Config.Badges = {
	Welcome = 3602323113322334,
	Dishes10 = 1683510497424881,
	Dishes50 = 4282462293267807,
	Dishes250 = 3868501690722170,
	SecretRecipe = 0, -- daily free badge quota was used up; create it in the Creator Dashboard and paste the id
	FirstWin = 398769584994467,
}

-- Sound ids (synthesized for this game, owned by the group). Empty string = silent.
Config.Sounds = {
	Click = "rbxassetid://97011738288105",
	Pop = "rbxassetid://71599032805746",
	Coin = "rbxassetid://115483473069673",
	Ding = "rbxassetid://119697125033787",
	DrumRoll = "rbxassetid://71455320606233",
	Stamp = "rbxassetid://76524049543784",
	Sizzle = "rbxassetid://103261481633709",
	Splash = "rbxassetid://90101055899773",
	Eliminated = "rbxassetid://88182887404473",
	Fanfare = "rbxassetid://104777836026536",
	Tick = "rbxassetid://140687570719353",
	Whoosh = "rbxassetid://112252659998069",
	Boing = "rbxassetid://91307414403922",
	Music = "rbxassetid://70597692785149",
	Type = "rbxassetid://71205436093914",
	-- hazard loops
	Buzz = "rbxassetid://105046532575682",
	Groan = "rbxassetid://116372826413496",
	Cluck = "rbxassetid://118792371969679",
	RobotBeep = "rbxassetid://88601344009995",
	Wail = "rbxassetid://75513535695179",
	Roll = "rbxassetid://84891534292190",
	Engine = "rbxassetid://124951866374366",
	Bubble = "rbxassetid://137005501107893",
	Squelch = "rbxassetid://71400276621596",
	Wind = "rbxassetid://134605282940980",
	Charge = "rbxassetid://79295051265306",
	UfoHum = "rbxassetid://78387826782921",
	Squeak = "rbxassetid://81170183032782",
	Rain = "rbxassetid://138691723218916",
	-- hazard one-shots
	Laser = "rbxassetid://76237537994741",
	Chomp = "rbxassetid://132117922953797",
	Blast = "rbxassetid://127165171095209",
	Shuriken = "rbxassetid://96888986873887",
	Chime = "rbxassetid://140616152326542",
	Zap = "rbxassetid://99843500128830",
	Slash = "rbxassetid://93209109170049",
	Stomp = "rbxassetid://71511013448094",
	Roar = "rbxassetid://99527896185656",
	FireBreath = "rbxassetid://110101002762842",
	Boom = "rbxassetid://139218488869141",
	Crack = "rbxassetid://100293605909783",
	Hiss = "rbxassetid://100553952100552",
	Whistle = "rbxassetid://95123740602768",
	Thunder = "rbxassetid://107673912576850",
	Honk = "rbxassetid://96052234701297",
}

return Config
