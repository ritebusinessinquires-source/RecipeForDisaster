# Recipe for Disaster

A Roblox party-survival game: each course, three random players secretly add one ingredient
each to a pot, and everyone has to survive the dish they cooked ("Giant Slippery Bees in the
Dark"). Chefs can type anything; it resolves onto 23 Mains × 105 Spice pairs × 7 Twist options
= **16,905 dishes**, plus 14 secret recipes.

- Universe `10778121901`, place `77411074610403` (Roblox game page: https://www.roblox.com/games/77411074610403)
- Built from the *Recipe for Disaster — Game Design Doc* (Nov 20, 2026)

## Typing anything

Chefs type their ingredient (quick-pick cards are still there as shortcuts). `ServerStorage/Lexicon.luau`
maps typed text onto the 23 Mains, 14 Spices and 6 Twists:

- ~1,500 words and phrases, with plurals and one-letter typos handled;
- well-known anime, game, film and meme names map onto generic behaviours (e.g. an energy
  fighter, a ninja, a wizard, a swordsman, a titan, a dragon, a UFO, a slime). Hazards are generic blocky
  models labelled with what the player typed; nothing recreates a character's look;
- unknown words still do something: an unknown Main falls from the sky as a labelled "Mystery
  Thing", an unknown Spice is hashed onto a Spice (the reveal explains it);
- everything stacks: extra describing words apply on top of the main pair, nouns typed anywhere
  spawn their own hazard in the same dish, dishes keep running all round, and Twists now stack too.
- Typed text is filtered with Roblox's `TextService` before anyone else sees it; if filtering fails
  the dish shows the ingredient names instead.

Every hazard has a looping 3D sound and every attack, impact and Twist has a sound cue
(45 synthesized sounds in `assets/sounds/`, IDs in `Config.Sounds`).

## Lobby and matches

One place runs in two modes (`ServerScriptService/Bootstrap.luau`):

- **Lobby** (public servers): players spawn in the TV-studio lobby. Standing on the green
  **PLAY** pad joins the queue; stepping off leaves it. A 20 s countdown starts with the first
  player (3 s once 20 are queued), then the queued players — up to **20** — are teleported
  together into a fresh reserved server. Overflow players start the next group.
- **Match** (reserved servers): waits up to 25 s for the whole group to arrive, then runs rounds
  back to back. The **🏠 Lobby** button sends a player back to a public lobby server.

Queue size, countdowns and the arrival wait are in `Config.Matchmaking`. Studio can't reserve
servers, so there a finished queue turns the current server into the match; set
`Config.ForceMode = "Match"` to skip the lobby while testing.

## What's in the game

| Area | Where |
| --- | --- |
| Lobby queue (PLAY pad, 20 per match) and teleports | `Services/Matchmaking.luau`, `Bootstrap.luau` |
| Round loop: intermission + map vote, Chef draft, reveal, cook (ramps at 30 s), stacking dishes, sudden death from course 6, winner | `ServerScriptService/RoundManager.luau` |
| Chef draft: weighted Chef picks, private hands from each Chef's Pantry, server-checked picks, ghosts and bots fill seats, Reroll Hand | `ServerScriptService/ChefDraft.luau` |
| Dish resolver: secret recipes → base stats → Spices (doubles, opposites, no dead modifiers) → hard caps → danger budget → name + hint | `ServerScriptService/DishResolver.luau` |
| 23 Mains + 2 seasonal (Pumpkins in October, Snowmen in December) | `ServerStorage/Mains/` |
| 14 Spices, each with hooks for all four types | `ServerStorage/Spices/` |
| Typed-text lexicon (words, character/media names, fallbacks) | `ServerStorage/Lexicon.luau` |
| 6 Twists (ghost-voted) | `ServerStorage/Twists/` |
| 14 secret recipes (Steam Bath, Popcorn, Avalanche, Disco Inferno, Mega Mech, Zombie Conga, Demolition Derby, Bowling Night, Volcano, Bath Time, Sinkhole, Thunderstorm, Stampede, Will-o'-Wisps) | `ServerStorage/Recipes/` |
| Hazard engine: physics movers, floor tiles, creature/projectile/terrain/weather runners | `ServerStorage/HazardLib/` |
| Maps: The Countertop, Picnic Meadow, Pizza Planet (+ the TV-studio lobby) | `ServerStorage/Maps/`, `Services/Lobby.luau` |
| Saving (session-locked DataStore), Cash economy, Pantry shop, spin wheel, codes, cosmetics, Cookbook, badges | `ServerScriptService/PlayerData.luau`, `Services/` |
| Daily login calendar, daily quests, Dish of the Day, free daily Spin, invites, weekly leaderboards + titles + Golden Whisk | `Services/Daily.luau`, `Services/Leaderboards.luau` |
| Game Passes, Developer Products, gifting | `Services/Monetization.luau` |
| Client: HUD, map vote, Tonight's Chefs, Chef hand, reveal, Eliminated, ghost vote, wipeout banner, winner, Cookbook, Pantry shop, Daily, Ranks, effects | `StarterPlayer/StarterPlayerScripts/ClientModules/` |

All tunable numbers (timings, Cash payouts, caps, odds, codes, product IDs, sound IDs) are in
`src/ReplicatedStorage/Shared/Config.luau`.

## Live Roblox setup (created through Open Cloud)

- Game Passes: VIP Chef `2096800887`, 2× Cash `2092727074`, Bigger Hand `2092948975`, Recipe Hints `2092925010`, Chef Taunts `2096950882`
- Developer Products: 1/5/15 Spins, Cash Jar S/M/L, Reroll Hand, and a "Gift" product per pass (IDs in `Config.luau`)
- Badges: Welcome, Line Cook (10 dishes), Sous Chef (50), Head Chef (250), Last One Standing. "Secret Sauce" is in-game only until a Roblox badge id is added to `Config.Badges.SecretRecipe`.
- 14 synthesized sound effects uploaded as group audio (`assets/sounds/`)
- Icon, 4 thumbnails and description on the game page (`assets/thumbnails/`)
- Server size 40 (lobby capacity; each match takes at most 20)

## Building and publishing

The repo uses the Rojo layout (`default.project.json`), so you can `rojo serve` it into Studio.
Without Rojo, `tools/build_place.py` writes `build/RecipeForDisaster.rbxlx` from `src/`:

```bash
python3 tools/build_place.py
```

```bash
ROBLOX_API_KEY=... tools/publish.sh            # Published
ROBLOX_API_KEY=... tools/publish.sh Saved      # saved version only
```

## How it was tested

There is no Studio here, so the game was tested in a real Roblox server through Open Cloud's Luau
execution API:

- every ModuleScript loads; all 6,552 dishes resolve to unique keys; the design doc's example
  dishes come out as written ("Giant Slippery Bees" = 3 huge slow bees, "Tiny Exploding Zombies" = 24);
- all three maps and the lobby build;
- every Main ran with a spread of Spices on every map with no script errors;
- full rounds ran end to end with stand-in players (draft, reveal, cook, kill credit to the right
  Chefs, falling off Pizza Planet, winner, cleanup);
- every client screen, menu, Shop tab and effect ran against realistic server payloads with no
  runtime errors (client modules run under a shim, since those sessions have no client).

- the real server start-up runs in both modes, and the queue was checked with 22 stand-ins on the
  pad (20 launched together, the other 2 as the next group, nobody re-queued mid-teleport).

Those sessions don't step physics, so **creature movement, knockback, ice sliding and pulls were not
observable there** — playtest them in Studio or a live server first.
