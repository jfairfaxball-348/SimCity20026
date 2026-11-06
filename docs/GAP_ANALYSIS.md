# Gap analysis: game 0.11.0-m3b against the classic city builder

Written 6 November 2026 under owner direction U30. **Planning only:** this document changes no game code, rule, version or save format. The [roadmap](ROADMAP.md) turns its gaps into ordered milestones.

## Sources and clean-room boundary

**Our side** comes from this project's own code (`game/`), [Decisions](DECISIONS.md) and the session evidence under [sessions](sessions/).

**The classic side** describes the original 1989 city-builder and its early-1990s console ports at player level, in our own words. It draws on:

- general genre knowledge;
- the permitted qualitative [study notes](research/MICROPOLIS_STUDY.md);
- public, non-source descriptions of which features exist (such as encyclopedia overviews).

No source code, ROM data, decompilation or reproduced manual was opened. The classic column deliberately gives no numbers, formulas, tables or text from the reference game. Where it says "few", "several" or "large", that is our own rough description. Plain genre words are used freely (U29). Features that only later editions added are marked **(later)** and treated as optional.

## Part 1: what 0.11.0-m3b has

Status words: **implemented** means it is in the build; **tested** means automated source and exported-PCK checks plus a native posted-input run of the Windows EXE on one machine. No feature has human playtest evidence.

| Area | What exists | Key numbers (all provisional, our own) | Status and limits |
| --- | --- | --- | --- |
| Zones and levels | Homes, shops and workshops as freely placed **3x3 lots** (D30), laid singly or in straight drag runs; whole-footprint clearing; free identical repaint | $25 per lot; levels 0-2; a home level holds 4 residents, a shop level 2 jobs, a workshop level 4 jobs; so a full lot holds 8 residents or 4 / 8 jobs | Implemented, tested. Only two built levels, one building style per type and level; no density or wealth classes; no land value outside homes |
| Demand and growth | Aggregate targets from prior-state residents and jobs, three starter home levels, five-day growth rounds, per-type round cap, demand meter (H/S/W) under the population (D22, D32) | Starter 3 home levels (12 residents); at most 8 levels per type per round; standard test town settles at about 40-48 residents / 18 jobs | Implemented, tested. Deterministic, no RNG. The town settles at a very small size, so there is little long-term growth |
| Decline | Two growth rounds without both services lose one level; tax leaving above 10%; held homes below desirability 0 (D22, D32, D33) | Up to 4 levels per type leave per round above 10% | Implemented, tested. Never demolishes or evicts zones |
| Roads and the outside link | One-tile roads; one gold-flag outside link on the east edge; side-sharing reachability gives access (D17, D18) | $10 per tile, $1 a month upkeep | Implemented, tested. No traffic, congestion, rail, bridges or road condition; roads cannot cross water |
| Power | 4x4 power stations; roads and stations relay power; nearest-first derived allocation; shortage and disconnection explanations (D19, D23, D30) | $500, 20 lots per station, $60 a month | Implemented, tested. One plant type; no separate power lines; no pollution from stations |
| Budget, taxes and upkeep | Monthly settlement, grant, taxes on serviced residents and jobs, universal facility upkeep, waiver at zero cash, Budget dialog with forecast and last settlement, tax rate (D25, D32) | Settles every 30 days; $100 grant; tax 0-25% (standard 10% = $2 per resident, $4 per job); starting funds $10,000 | Implemented, tested. No service funding levels, no loans, no debt (deliberate relaxed rule) |
| Parks and desirability | One-tile pocket park; home desirability from park, water and workshop nuisance; desirability orders growth and holds homes below 0; V overlay (D26, D33) | Park $100, $10 a month; park +2 within 3; water +1 within 3; developed workshop −2 within 2, up to 3 | Implemented, tested. Homes only; one amenity; no general land value or pollution field |
| Project | One optional "A welcoming square" with cosmetic flowers, once per town (D28) | Three serviced home lots near one park | Implemented, tested. Only one project |
| Town summary | Read-only ranked blockers with Show and Budget actions, T and status-bar button (D34) | At most five blockers plus deficit and status items | Implemented, tested. No rating, opinion, score or history |
| First steps guide | Session-only five-step card, Show bracket, Hide/Close, F1 and Help (D29) | Five steps | Implemented, tested. Not saved; not a full tutorial |
| Overlays and inspector | Hover inspector (level, residents/jobs, access, power, demand, next round, reasons, desirability parts); road marks R, power marks E, desirability overlay V, grid G | Inspector fits 320 px at every text size | Implemented, tested. No population, traffic, pollution, crime, land-value or coverage maps; no graphs |
| Saves | One manual slot with previous-good backup, explicit recovery, unsaved-change prompts, strict validation, migration from every earlier schema with preserved originals | Schema 8, simulation/content `m2g-1`; JSON cap 512 KiB; nine byte-identical fixtures | Implemented, tested. No autosave, no multiple slots, settings not remembered |
| Time | Pause, 1x and 3x; construction while paused; suspension in dialogs and on focus loss; fixed one-day tick with bounded backlog (D14) | 8 ticks a frame maximum; one simulated hour of backlog | Implemented, tested. Calendar is a day count; no months or years shown |
| Input and accessibility | Mouse and keyboard; three text sizes; four window sizes; overlays use shapes as well as colour | Text 16/18/20; 1280x720 to 1920x1080 layouts | Implemented, tested at 720p natively. No controller route, no remapping, no remembered settings, DPI variants unverified |
| Map size and generation | One seeded coastal map: water along the west edge with a wobbly shoreline; land elsewhere; trees are cosmetic only | 64x64 default; saves accept 8-128 per side; default seed 198624 | Implemented, tested. No rivers, lakes or forests in the model, no seed entry or size choice in the interface, no terrain editing |
| Art | Kenney Roguelike Modern City (CC0) as default, original geometric renderer as fallback, Tiny City experimental (D31) | 16 px cells | Implemented. Still missing supplementary sprites (shore, station, roof edges); no animation |
| Audio | None | — | Missing |
| Platforms | Windows 11 x64 export, local ZIP package | Godot 4.7.2 | Locally tested on one machine. No CI, no other OS, no public release |

## Part 2: the classic game, feature by feature, and our gaps

Gap size: **S** about one session, **M** two to three, **L** four or more. Status: **done**, **partial**, **missing**, or **different** (deliberately not following the classic).

### Building and growth

| # | Feature | Classic behaviour (our own words) | Our status | Gap | Depends on | Player impact | Rights note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Zone types | Residential, commercial and industrial zones on 3x3 lots; special zone-centre tiles carry the building | Done (as homes, shops, workshops; U19 lots) | S (naming only) | — | Labels feel unfamiliar to genre players | Plain words allowed (U29); keep our own icons and lot art |
| 2 | Density growth | Lots grow through several stages from small houses to dense blocks; residential lots first fill with individual houses; higher stages hold many more people | Partial: two levels, one style | L | 3, 13 | The town tops out quickly; little to aim for | Our own level count, capacities and building art |
| 3 | Wealth classes | Each stage comes in lower to upper value variants, chosen by land value | Missing | M | 3 | Visible reward for good planning | Our own art; no reference tiles |
| 4 | Demand | Citywide residential/commercial/industrial demand from the balance of people and jobs, the tax rate and outside trade; shown as a small three-bar meter; some demand caps until special buildings exist | Partial: our own meter and targets; no caps or outside trade | M | 11 | Already readable; deeper demand gives later-game goals | Our own meter design, not the reference layout (D32) |
| 5 | Land value | A city-wide field: rises near water, trees, parks and the developed centre; falls with pollution and crime; drives which wealth class grows and how much tax a lot pays | Partial: home desirability only (D33) | M | 6, 7 | Gives every zone type a place-based reason to plan | Our own sources, radii and values |
| 6 | Pollution | Industry, heavy traffic, power plants and ports pollute nearby land; pollution lowers land value and residential growth; overlay and warnings | Partial: workshop nuisance on homes only | M | 5 | Classic zone-separation tension for all types | Own field rules |
| 7 | Crime | Rises with density and low land value, lowers land value; police coverage reduces it; overlay and complaints | Missing | M | 5, 9 | A reason to build and fund police | Study proposed rejection; U17 lets the owner override. Present without danger stereotypes |
| 8 | Traffic | Zones generate trips along roads; busy roads show congestion; congestion pollutes and hurts growth; lots without nearby roads cannot grow | Partial: structural access only | L | 5, 6 | Road layout becomes a real design choice | Keep D17 access; our own derived traffic, not sampled trips |
| 9 | Rail | A rail line as an alternative transport network that carries trips without road congestion | Missing | M | 8 | A second transport choice | Own art and rules |
| 10 | Bridges and crossing water | Roads, rail and power lines can cross water as bridges or over-water lines | Missing | S | 15 | Use of rivers and coast | Own art |
| 11 | Power plants | Two plant types: a cheaper polluting one and a cleaner, larger, riskier one; separate power-line tool; zones and lines conduct power; brownouts when demand exceeds supply | Partial: one plant, roads carry power, clear shortages | M | 6 | Classic power choice and line planning | Own plant designs and capacities; D19 networks may be replaced only by a decision |
| 12 | Police and fire | Police and fire stations with coverage areas; coverage weakens without power, roads or funding; fire coverage reduces fire spread | Missing | M | 5, 7, 18 | Civic services; needed for later growth | Own buildings and coverage rules |
| 13 | Services needed for growth | Big cities stall without services and special buildings | Missing | M | 12, 14 | Long-term goals | Our own thresholds |
| 14 | Special buildings | A stadium, a seaport and an airport; each lifts a demand limit at larger sizes; ports and airports pollute and need power | Missing | M | 4, 11 | Milestone goals for a growing city | Own designs; no reference building art |
| 15 | Parks and trees | Parks and woods raise land value; trees are terrain that can be cleared | Partial: one park, cosmetic trees | S | 5, 22 | Greenery as a tool | Own art |
| 16 | Bulldozing and clearing | Bulldozer removes buildings, roads and trees for a fee; rubble remains | Different: free clear, no rubble | — | — | Relaxed play | Keep (D25 free clear) |

### Money and rules

| # | Feature | Classic behaviour (our own words) | Our status | Gap | Depends on | Player impact | Rights note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 17 | Taxes | One citywide tax rate; higher raises income but slows growth | Done (D32, our own range and effect) | — | — | — | Own numbers |
| 18 | Funding levels | Yearly budget with separate funding for transport, police and fire; underfunding degrades roads and weakens coverage | Missing | M | 8, 12 | Real budget choices | Own budget layout; avoid copying the reference dialog composition |
| 19 | Budget timing | Taxes collected yearly; cash flow history | Different: monthly (D25) | S | 21 | Monthly is easier to follow; keep, add yearly summary | — |
| 20 | Debt and failure | Building needs cash; running out of money leaves the city unable to build; some editions allow loans (later); some console ports end the game in long bankruptcy | Different: no debt, waiver at zero, grant recovery (D25); kept by owner choice U32 | — | — | Relaxed play promise | Owner choice |
| 21 | Graphs and history | Line graphs of residential/commercial/industrial population, cash flow, crime and pollution over short and long spans | Missing | M | — | Seeing the town's story | Own chart design |
| 22 | Disasters | Fire, flood, tornado, earthquake, plane or ship accidents, a plant meltdown, a fictional creature attack; can be switched off; some are triggered by conditions | Missing | L | 12, 15 | Drama; conflicts with relaxed default | No reference event list, creature or tuning; optional, off by default (U31) |
| 23 | Scenarios | Several pre-built cities with a crisis and a time-limited goal | Missing | L | 22, 24 | Challenge mode | Never reuse the reference scenarios, cities or text; own challenges only |
| 24 | Evaluation and public opinion | Yearly city rating, approval percentage, top problems listed by citizens, overall score | Partial: measurable town summary (D34) | M | 7, 8, 21 | Sense of progress | Study: no random complaints; own wording and layout |
| 25 | City size milestones | The city gains titles as population grows, from village upwards | Missing | S | 2 | Long-term goals | Own titles and thresholds |
| 26 | Rewards and gifts | Console ports give gifts at milestones (a mayor's home, landmarks, parks and so on), placed by the player | Missing | M | 25 | Personal goals and decoration | Never copy the gift list, names or art; our projects (D07) are the natural vehicle |
| 27 | Difficulty | Easy, medium and hard starts with different funds and demand pressure | Missing | S | — | Choice of challenge | Own values |
| 28 | Advisors and news | Console ports have an advisor character; messages report problems | Partial: town summary and inspector | — | — | — | Never recreate the advisor character; study rejects random complaints |

### Information and presentation

| # | Feature | Classic behaviour (our own words) | Our status | Gap | Depends on | Player impact | Rights note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 29 | Map overlays | Mini-map with views for zones, power, transport, population, growth, traffic, pollution, crime, land value and police/fire coverage | Partial: three overlays (roads, power, desirability), no mini-map | M | 5-12 | Diagnosing problems | Own overlay style; not the reference panel composition |
| 30 | Query tool | Click a tile to see its type, density, value, crime, pollution and growth | Done and deeper (inspector with reasons) | — | — | — | — |
| 31 | Terrain | Random maps with rivers, lakes, coast and forest | Partial: one coastline | M | — | Variety and planning around water | Own generator; no reference maps |
| 32 | Map generation choice | New-city choice of random terrain; city name and difficulty | Missing (fixed seed) | S | 31 | Replay | Own interface |
| 33 | Terrain editing | Separate terrain editor in the PC line; landfill and terraforming (later) | Missing | M | 31 | Optional sandbox | (later) optional |
| 34 | Time controls | Pause and several speeds; calendar of months and years from an early-century start | Partial: pause, 1x, 3x, day count | S | — | Sense of years passing | Own start year |
| 35 | Sound | Effects for building, traffic and alerts | Missing | M | — | Feedback and charm | Fully original audio only |
| 36 | Music | Console ports have a soundtrack that changes with city size | Missing | M | 35 | Mood | Fully original compositions; no rearranged melodies |
| 37 | Animation | Moving cars and trains, smoke, planes, ships, fire | Missing | M | 8, 9, 14 | A living town | Own sprites |
| 38 | Seasons | Console ports change tile colours by season | Missing | S | 34 | Charm | (port feature) own palettes |
| 39 | Map scale | A larger map than ours (roughly twice each side) | Partial: 64x64, save ceiling 128 | M | profiling | Room for a big city | Our own size |
| 40 | Population scale | Cities reach very large populations | Partial: tens of residents | L | 2 | Sense of a real city | Our own capacities |
| 41 | Save and load | Save and load city files | Done and safer | S (autosave) | — | — | — |

### Later-edition extras (optional)

Water pipes and pumps, zone density choice, highways, subways and buses, education and health buildings, ordinances, loans and bonds, neighbouring cities and trade, arcologies, elevation and isometric views, advisors per department, newspapers and terrain editing in-game. None is needed to match the classic baseline; the owner chose none for now (U34).

## Verdict on the biggest gaps

The game already matches the classic *opening*: zones on 3x3 lots, an outside link, power stations, a demand meter, a tax rate, a monthly budget and better explanations than the classic offered. What it lacks is the **middle and late game**. A town settles at a few dozen residents on two development levels, so there is nothing to grow towards. The biggest gaps, in order of player impact, are: **growth depth** (density stages, wealth classes, land value for every zone, and services needed for the top levels); the **pressure systems** that make layout matter (pollution, crime with police and fire, traffic with rail, two power plant types with lines); **information over time** (calendar, graphs, overlays, a rating and size milestones); and **presentation** (sound, music, animation, varied terrain and a bigger map). Special buildings, disasters and scenarios are the classic's goals and drama; the owner chose optional disasters, off by default (U31), and kept the no-debt rule (U32), so the relaxed default (U05) stands. The target scale matches the original game (U33). Every gap can be closed with our own rules, numbers and art inside the rights boundary.
