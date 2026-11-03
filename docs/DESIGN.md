# CRISPEE Design Document

As of 2026-11-03. Review copy: https://claude.ai/artifact/K5aYngxp8PYnrQmBYo5JvH

## Premise and tone

CRISPEE is a 3D third-person comedy platformer about an eight-pound blonde terrier who believes everything he pees on belongs to him. The world agrees, and takes his claims with escalating seriousness.

- **Crispee** is recognizably the owner's real dog: scruffy cream-and-blonde coat, little beard, floppy ears, skinny legs, upright tail. No diaper. He stays on four legs and behaves like a dog.
- **The joke** is in the systems, not the lines. Humans reorganize their lives around Crispee's ownership while he cares about smells, snacks, comfort, and claiming things.
- **References**: Stray for movement, camera, and the feeling that environments are enormous from dog height. Untitled Goose Game for level structure and mischief comedy. Katamari for the escalation of scale. Jedi Knight for the power wheel and Force-style vision.
- **Look**: stylized 3D, warm lighting, expressive animation, an original world.
- **Story arc**: home, then yard and street, then town, then a space center, then orbit, then parallel universes (home with things subtly wrong). The ending is puppy Crispee looking at Earth in a solemn 2001-style scene, one tiny puppy pee, cut to black. The synthetic-pee empire stays optional.

## Core mechanic: claiming

Reach a thing, mark it, and the world rearranges itself around the fact that it is now Crispee's. A claim is a state change, not a score.

Once Crispee owns the mailman's bag, the mail goes to his couch. Once he owns the kitchen floor, the family eats standing on chairs. Once he owns the car, it won't start for anyone else, and the car becomes a locked room he can be carried into. Humans take ownership with total seriousness and change their behavior and routes, so every claim is both a payoff and a new piece of level geometry.

The loop:

1. Find what can be claimed and how to get there (Pee Vision, Sniff).
2. Solve the traversal to reach it (hop, squeeze, dig, carry, use a human).
3. Mark it and watch the reaction.
4. Use the changed world to reach the next claim.

Later claims in a level are only reachable because of earlier ones. That dependency chain is the puzzle and the comedy, because it is an escalating record of a small dog taking over a place.

**The test for a level idea**: can you name the claims, what each one changes, and which later claim it unlocks? "Pee on five things" is a toy. "Owning the thermostat makes the house cold enough that the family leaves the back door open" is the game.

**Rule**: claims open routes and almost never close them. The rare claim that closes something is a deliberate trade-off for speedrunners to argue about.

## Level structure

The game is a fixed sequence of self-contained levels. Each level is a territory with a set of pee spots, shown up front, and a par count to finish.

- **The intro shows every pee spot but not the routes.** A quick flyover, like a heist briefing. Some spots are visibly unreachable, and finding out which claim opens them is the puzzle.
- **Par to finish, all for mastery.** Roughly five of eight spots exits the level. The rest are optional.
- **Score and time.** Score is time plus claims plus a small bonus for not being caught. Each level keeps the player's best time and a ghost of their best run, so replaying for time has something to race.
- **Routing is the meta.** Because claim order changes what opens, the fast route through a level is a choice of which claims to take and in what sequence. Some shortcuts are visible immediately. Others only show up through exploration or a better method. That is the replayability.
- **Session length.** Ten to twenty minutes per level, with autosave on every claim, so it fits phone play.

## Puzzle types

The puzzles are always about how to get to a pee spot. They come in three flavors, and every level mixes them.

- **Dexterity.** Accurate running and jumping: ledges, gaps, moving things, timing past humans.
- **Adventure logic.** Point-and-click style chains: get the human to open the door, get carried in the bag, put something in motion so a route appears.
- **Routing.** Which claims in which order, which human with which power, where to spend a limited mark.

Every spot has multiple paths. The obvious one works. The clever one saves time.

## Controls and camera

Four buttons under the right thumb plus a move stick under the left. Controller mapping is one to one.

| Control | What it does |
| --- | --- |
| Move stick | Walk and run |
| Pee | Mark, only at a valid spot |
| Jump | Free jump. Needed for dexterity platforming and time-shaving |
| Action | Contextual: interact, pick up, drop, bark at a human, Act Injured near a human |
| Power (top) | Hold to open the power wheel, slide to a slice, release to use. Tap to use the last-selected power |

**Camera.** Semi-automatic, like Mario 3D World or A Short Hike, framing the route for the player. Swipe anywhere on the right half to nudge it. No manual camera drag, because the right thumb is on buttons. Precision platforming on a phone lives or dies on the camera, so this is a bigger deal than the button layout.

**First person** is never a play mode. The sniff and vision powers borrow it for a moment, which gives the dog's-eye view without making anyone platform from it.

**Jump feel** gets tuned on the phone. A debug panel exposes gravity, jump height, and coyote time so the owner can adjust in the app and report the numbers that felt right.

## Dog powers

A power wheel in the Jedi Knight style. Powers unlock across levels, the way Jedi Knight hands out Force powers, so the escalating story has a progression under it. Each power has its own cooldown rather than a shared pool. Six is the ceiling for the whole game.

| Power | Role | What it does |
| --- | --- | --- |
| Pee Vision | Where | Momentary, a few seconds. The whole world goes yellow with a soft vignette, like Force Seeing. Pee spots glow through walls: unclaimed spots pulse, owned spots glow steady and brighter, Extra's spots glow a sicklier yellow. A low mystical drone swells on activation and reverses on fade. Crispee stops panting and his ears go up like he is receiving a transmission. Available from level one |
| Sniff | How | Camera drops to nose height, the world goes scent-colored. Shows scent trails, which human opens which door, where the water is |
| Big Bark | Move humans | A shockwave bark. Every human in earshot turns, drops what they are holding, or opens a door to see what is wrong. Crowd control |
| Puppy Eyes | Move one human | Lock onto one human and they do the one thing you need: lift you, carry you, open the thing. The mind trick |
| Zoomies | Move Crispee | A few seconds of absurd speed with a drifting turn. The time-trial power. Should feel the best of all of them |

Every power either reveals, moves humans, or moves Crispee. Anything that does none of those three is a gag that belongs in a level, not the wheel. Cooldowns are what make routing interesting: Zoomies now, or save it for the stairs.

## Humans as puzzle pieces

Powers do not work the same on everybody. Each human has a short profile, like an enemy type, and Sniff reveals it. The routing problem becomes which human, which power, in which order.

| Human | Puppy Eyes | Big Bark | Note |
| --- | --- | --- | --- |
| Grandma | Melts | Can't hear it | The softest door-opener in the house |
| Dad | Immune | Comes running to check the house | Useful for pulling him away from where you want to be |
| Teenager | Nothing | Nothing | Headphones in. Knock them off first and the profile changes |
| Mailman | Works | Flees | Fleeing leaves the bag behind |
| The cat | Immune | Immune | Judges you |

**Act Injured** is not a power. It is a contextual Action near a human: Crispee lifts a paw and limps, and the human drops everything to fuss over him. The comedy is in where you do it. Limp in front of the vet and you get carried into the back room. Limp in front of Dad and he looks it up on his phone while you walk through the door he left open.

Humans are tools: door openers, lifters, carriers. Riding in a bag, being carried through a gate, being lifted onto a table are all traversal, and they scale up through the whole game. By the space level it is an astronaut's duffel.

## Extra, the arch enemy

Extra is a black Chihuahua the same size as Crispee who pees over Crispee's spots. He is a mirror, not a pest: anywhere Crispee can go, Extra can go, with the same hop reach, gaps, and speed. A route you found is a route he can use against you.

**Character.** Extra in both senses: surplus, the dog nobody asked for, and too much. Every entrance is dramatic. He arrives like he is owed something. He has no powers and does not need them, because humans do what he wants out of sheer intimidation. The mailman just hands him the bag. He would never fake an injury. His theme is Crispee's theme played lower and slower. Black where Crispee is blonde, so they read as opposites at a glance.

**As a system.** He is built once and levels use him in different ways.

- **He roams.** A visible patrol with a tiny ominous theme, so you can hear where he is. Pee Vision shows his spots in an angrier yellow.
- **Contested claims.** When he re-marks a spot, the world flips to his. The mail now goes to his house. The route you opened may close. That is the real penalty, and the joke compounding.
- **Reclaiming costs a mark.** He taxes bladder and time. In a time trial, he is what makes the obvious route slow.
- **Trapping him is the clever route.** Close a gate, shut a car door, Big Bark him into the bathroom and let Dad shut it, get the mailman to pick him up. Trapped means your claims are locked for the rest of the level. Each level with him has at least two traps, one obvious and one that saves a minute.
- **Both options always exist.** Race him or trap him. Racing is the floor, trapping is the ceiling, and par is reachable either way.
- **Same-size rule.** If a trap can hold Extra it could hold Crispee, so every trap is also a hazard.

**Pacing.** Not in every level. Introduce him in the second territory, leave him out of the third so he is missed, then bring him back with escalation. By the space level he has his own tiny spacesuit.

## Other rules

- **Bladder is pacing, not punishment.** A small number of marks per refill. Water bowls, puddles, and sprinklers refill. It makes every mark a choice and makes refilling a small traversal problem. It stays its own resource, separate from power cooldowns.
- **No failure state.** Getting caught means being picked up and put back somewhere with a sigh. No death.
- **No spoken dialogue.** Humans mumble. The jokes live in documents, signs, news tickers, overheard calls, and the escalating paperwork of Crispee's ownership. Cheaper, funnier, and readable on a phone.
- **Scale escalation.** The mechanic never changes from a living room to a launch pad. Only what the humans are willing to reorganize for him does.
- **Single-player first.**

## Engine and platform

**Decision: Godot 4, GDScript, Forward Mobile renderer. iPhone first, landscape, touch and controller.** Not provisional anymore.

The deciding factor is the development process, not abstract engine quality. Everything is written by Claude, directed from a phone, built on free GitHub Mac runners, and sideloaded as an unsigned IPA, the same pipeline as the owner's existing game ports. The engine has to be authored entirely as text, built headlessly on a CI runner, and runnable on Linux so Claude can take screenshots of the game it made.

| | Godot 4 | Unity 6 | Unreal 5 |
| --- | --- | --- | --- |
| Scenes and assets as readable text | Yes, .tscn and .tres are plain text | Partly, YAML that is hard to hand-write | No, binary assets and Blueprints |
| Headless iOS build on CI | One command exports an Xcode project, then xcodebuild with signing off | Needs the editor installed and a license activated on the runner every run | Needs a source build and an Apple certificate even for test builds |
| Claude can run it on Linux and screenshot | Yes, software-rendered under Xvfb | No practical way | No |
| Cost and licensing | Free, MIT | Free under the revenue cap, with activation friction | Free until revenue, heavy |
| 3D quality ceiling | Good enough for stylized | Highest tooling, best asset store | Highest fidelity, irrelevant here |
| Touch and controller on iOS | Built in | Built in | Built in |

Unity is the stronger 3D engine, and with a Mac and a human in the editor it would win. Without one, its editor is dead weight and CI activation is a recurring failure point. Unreal is out for a phone-directed solo project.

**Godot on iPhone.** Native Metal renderer on Apple since Godot 4.4. iOS export is Godot's least battle-tested platform, so expect touch and audio quirks of the kind already fixed in the ports.

**Linux screenshots are the real win.** Every change, CI boots the game on a Linux runner, plays a scripted sequence, and attaches screenshots or a short video. That is how a non-programmer reviews a 3D game from a phone. Ghosts, time trials, replays, and a modular level kit are all plain text and script.

**Architecture.** Modular from the start: movement, camera, interactions, NPC reactions, objectives, saving, input.

## Art and animation

The biggest risk in the project is not code. It is art and animation. A Stray-like game is sold by its animal.

**Proposed path: low-poly stylized Crispee, generated from the owner's photos.** Claude scripts Blender to build him from the reference pictures, rigs him, and drives most motion procedurally in Godot: inverse-kinematics legs that find the ground, a physics tail, floppy ears that react to movement. The style reads as charming on a phone and is the one Untitled Goose Game and A Short Hike used for the same reasons.

**Alternative:** buy or commission one fluffier, more detailed model, and Claude handles everything else.

The owner has reference photos of Crispee. The decision between the two paths is made when they are shared, with an honest estimate of how close the generated version can get. Extra is the same rig recolored black, with his own idle and walk attitude.

## First playable and open decisions

**First playable**, in two steps:

1. A grey-box room with a capsule dog, to nail movement, jump, and camera feel on the phone before any art.
2. Crispee and the couch-to-door scene on top of it: he hops off his couch, explores a room, follows a scent beyond a closed door, gets a human to open it, and marks something that triggers a worthwhile reaction.

**Decided so far**

- Claiming as the core mechanic, with the world changing around each pee
- Levels with pee spots shown up front, par to finish, score and time, ghost replays
- Four buttons: Pee, Jump, Action, Power wheel. Free jump is in
- Powers: Pee Vision, Sniff, Big Bark, Puppy Eyes, Zoomies. Six is the cap
- Powers work differently on different humans. Act Injured is a contextual action, not a power
- Extra: black Chihuahua, same size as Crispee, contested claims, race or trap
- Bladder as light pacing. No failure state. No spoken dialogue
- 3D third person with a semi-automatic camera. First person only inside powers
- Godot 4 with Linux screenshot CI from day one

**Still open**

- [ ] Art path: generated low-poly Crispee or a commissioned model, decided from the photos
- [ ] The first level's claim list: each spot, what it changes, what it unlocks
- [ ] Which two or three powers are available in level one
- [ ] Exact par and spot counts per level
- [ ] Whether a sixth power exists, and what it is
- [ ] Names and profiles of the household humans
