# Untitled city builder

**M0/M1 through M2d, the bounded M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary and the M3b first-steps guide are implemented and tested locally, 4–6 November 2026.** Version **0.7.0-m2e** makes homes, shops and workshops 3x3 lots and power stations 4x4 buildings, with schema-6 saves; **0.7.1-m2e** makes the owner-chosen Kenney Roguelike Modern City (CC0) the default artwork, with the original graphics as a fallback. **0.8.0-m2f** adds a demand meter and an adjustable tax rate (schema 7), **0.9.0-m2g** neighbourhood desirability with workshop nuisance and a map overlay (schema 8), **0.10.0-m2h** a town summary (T): the three owner-chosen [city-builder systems](docs/GENRE_ALIGNMENT.md) (U24). **0.11.0-m3b** adds a dismissible First steps card ([M3b](docs/M3B_SPEC.md)). **0.12.0-r1** (roadmap R1, D35) renames the player-facing zones **Residential / Commercial / Industrial** and the station a **power plant**, with an **R / C / I** demand meter, and shows a **month-and-year calendar** from 1 Jan 1950. **0.13.0-r2a** (R2a, D36) gives every zone a place rule: **land value** for residential and commercial lots (commercial also gains trade from nearby residents), while industry grows nearest the outside link first (schema 9). **0.14.0-r2b** (R2b part 1, D37) adds **levels 3 and 4**, which hold far more people, gated by land value (or, for industry, by town size), so a well-placed town grows past the old ceiling (schema 10). **0.15.0-r2c** (R2c, D38) adds **police and fire stations**: level 4 now also needs police and fire cover (schema 11). **0.16.0-r3** (R3, D39) adds **autosaves**, **remembered settings** and **monthly history graphs** (H; schema 12). M3 as a whole and public release remain future work. A [gap analysis](docs/GAP_ANALYSIS.md) against the classic game and an ordered [roadmap](docs/ROADMAP.md) (R1-R17) now set the direction. **Artwork:** Modern City is the default (U22/U23); Display → Artwork switches to Original (fallback) or Tiny City (experimental). See the [screenshots and report](docs/artwork-review/ARTWORK_EVALUATION.md).

The user confirmed desktop players, a possible Steam release, relaxed building, charming pixel art, and approachable controls. The code, map generation, geometric graphics, and interface were created independently. The repository name is a workspace identifier, not a cleared product title.

## Play or develop

The Windows export is `builds/windows/citybuilder.exe`; keep its `citybuilder.pck` beside it. The tested local package is `builds/citybuilder-0.16.0-r3-windows-x64.zip`. Tools, caches, and builds are ignored and absent from a fresh clone.

From the repository root in PowerShell:

```powershell
.\tools\setup.ps1             # First use: verified isolated editor/templates
.\tools\project.ps1 Run       # Run with the pinned editor runtime
.\tools\verify.ps1            # Model/storage checks, export, PCK checks, EXE startup
.\tools\package.ps1           # Package the existing verified Windows export
```

Use **Godot 4.7.2 Standard**, `4.7.2.stable.official.ed1daf0bf`, typed GDScript, Compatibility renderer. The global Godot wrapper still points to 4.6.3; use the helpers. See [Toolchain](docs/TOOLCHAIN.md).

## What works

- Original seeded 64x64 coastal map; crisp integer-scaled world and separately scalable UI.
- Roads by the tile; homes, shops and workshops as 3x3 lots laid singly or in straight drag runs; 4x4 power stations; whole-footprint demolition, preview prices, atomic costs, and free identical repainting.
- One marked outside link, orthogonal road access, immediate disconnection/reconnection, and power networks with capacity/shortage explanations.
- Home/shop/workshop levels 0-2, aggregate residents/jobs, demand, five-day growth rounds, and gradual service-loss decline/recovery. Original pitched roofs, awnings and sawtooth workshop buildings distinguish lots and development.
- Hover inspection of level, residents/jobs, access, power, demand, next growth check, and reason for waiting or declining; optional road and power symbols.
- Monthly budget forecast and last settlement, explicit shortfall waivers, free deficit recovery, and park priority for nearby homes.
- Camera pan/zoom/centering, grid toggle, three text sizes, four window sizes, pause/1x/3x, construction while paused, and suspension during dialogs/focus loss.
- Validated manual saves, previous-good backup, explicit recovery, unsaved-change prompts, deterministic continuation, and migration from earlier saves with preserved originals.

There is one optional project; **audio, a controller route, general onboarding, and autosaves remain future work**. Prices are provisional: roads $10 per tile, zones $25 per lot, power stations $500, parks $100; clear is free with no refund; initial funds $10,000.

## Start a growing town

Start at the **gold flag**, tile `(63,32)` on the default map. Lay a road on it, join streets along shared sides, then zone beside the connected streets. A zone tool centres a **3x3 lot** on the pointer; drag to lay a straight row or column of lots. A lot needs a connected road beside any of its sides; corners, diagonals and other map-edge roads do not supply access. Place a **4x4 power station** beside the street with **P**. Stations relay power but never road access, so avoid putting one in the middle of the only access road. Clearing any tile of a lot or station removes all of it.

Each station supplies **20 zone lots**, including empty lots, nearest lots first. Each lot needs one unit regardless of development. A newly zoned nearer lot can displace a farther developed lot. Add a station on that network to fix capacity shortages; reconnect roads to fix access. The two conditions have separate inspector lines.

Unpause to grow. Every five days, lots with road access, power, and demand can gain one level, up to level 2. A home level holds 4 residents; a shop/workshop level supplies 2/4 jobs. **Starter demand supports 12 residents before any jobs exist.** Residents create business demand; jobs support more homes. The **demand meter** under the population count shows, for R(esidential), C(ommercial) and I(ndustrial), the level additions the town welcomes (+, bar up) or, above the standard tax rate, the levels about to leave (−, bar down). Each type gains at most eight levels per round, park-covered home lots first, then map order (businesses retain map order). A mixed, sufficiently serviced town can settle at 48 residents / 18 jobs under these provisional rules. These are aggregate capacities, not simulated citizens or employment assignments.

At or below the standard tax rate, satisfied demand stops new growth without evicting buildings. Every second growth check without both services loses one level. Restoring both services immediately resets the loss counter; demand then permits regrowth. Counts include standing development until it declines. Clear removes the building and its residents/jobs immediately.

| Control | Action |
| --- | --- |
| 1 / 2 / 6 / 7 | Roads / residential / commercial / industrial |
| P / 8 / 3 | Power plant / pocket park / clear |
| B / J | Monthly budget / neighbourhood project |
| Left drag; right click or Escape | Preview and commit a stroke; cancel |
| WASD / arrows / middle drag | Pan |
| Wheel / + / -; Home | Zoom; return to outside link |
| Hover; R / E | Inspect; toggle road / power marks |
| Space; 4 / 5 | Pause/resume; normal/fast |
| Ctrl+S / Ctrl+L; F6 | Save/load; display and text settings |

## Budget and parks

**Tax rate.** Budget **B** has − / + / Standard 10% buttons for a rate from 0% to 25%. Each point charges 20 cents per serviced resident and 40 cents per serviced job a month, so the standard 10% is $2 and $4. Lower rates raise every demand target (140% at 0%) and higher rates lower them (40% at 25%). Above 10%, up to four surplus levels of each type leave per growth check, level-2 lots first. Leaving never removes a lot, cash or the project; lowering the rate lets the town regrow. Rate changes are free, ordered commands and take effect immediately, even while paused.

Every 30 days, after that day's growth, the town receives a **$100 grant + taxes at the current rate** (at 10%: **$2 per serviced resident + $4 per serviced job**). Upkeep is **$1 per road tile + $60 per station + $10 per park**, even when unused or disconnected. Unserved buildings pay no tax, including during decline grace. First settlement is displayed on day 31. **B** shows the current forecast, input counts, last actual settlement, and any shortfall waived or surplus capped. Forecasts change as the town changes.

A negative monthly net is a deficit. Clear surplus facilities for free or restore road/power service to recover taxes. Cash stops at zero: unpaid costs are explicitly waived, with no debt, interest, destruction, or service cuts. Construction still needs full funds. With everything cleared, the $100 monthly grant can finance a new start.

**Desirability (V).** Each home lot has a score: **+2** for a park within 3 side-steps (not stacking), **+1** for water within 3, and **−2** for each developed workshop lot within 2 side-steps (up to three), so a workshop directly across a one-tile road counts. Higher-scoring homes reserve growth first, then map order. Below 0 a home stops at level 1, and a level-2 home drops one level at the next check; add a park or move the workshops and it regrows. Nothing is demolished. **V** (or Display) toggles an overlay: + marks attract, hatching deters, smoke marks developed workshops; the inspector lists a home's parts. Shops and workshops are not affected.

**First steps (F1).** At every start a card at the bottom left of the map shows the first unmet step of five: road on the flag, a home lot beside it, a station, running time until a home grows, then the optional project. It rechecks after every change, so undoing a step brings it back. **Show** centres on the step's target and a corner bracket marks it; **Hide** (or **Close** when done) hides it for the session; **F1** or Help's **Show first steps** brings it back. Nothing about it is saved, and it never pauses time or locks tools.

**Town summary (T).** **T**, or the **Town summary** button at the right of the status bar, lists the biggest measurable causes holding the town back, biggest first: no road on the gold flag, lots without road access or power, lots short of power, homes held by workshops, levels leaving under high taxes, and demand with no lot able to use it; then any monthly deficit. Each item gives a count and a remedy, and **Show** centres the view on an example and inspects it (or **Budget** opens Budget). An empty town gets the three starting steps; a town with nothing blocking it says so. The summary is read-only and pauses time while open; the inspector remains the per-lot explanation.

A **pocket park (8)** costs $100 and $10/month. Home lots with a tile within three side-steps (Manhattan distance) gain +2 desirability, so they reserve growth demand first. Overlap does not stack. Parks need no services and relay neither roads nor power. They change which homes develop first under contention; they add no demand, capacity, tax multiplier, or protection from decline. The inspector explains coverage and priority.

## A welcoming square

Open **Project [J]**, choose a pocket park, and grow three distinct home lots, each with a tile within three side-steps of it. Each lot needs road access and power; either development level counts once. Press **Complete square** when ready to add flowers. This is optional, free, and available while paused, with no deadline. The flowers are cosmetic: the existing park priority and upkeep stay unchanged.

Completion is once per town. Service loss or decline does not undo it. Clearing the decorated park removes its flowers but keeps completion; replacing the park does not restart the project. **Show park** centres the view. At largest text, scroll the project dialog to reach its actions. Help also scrolls.

## Saves

Saves use `%APPDATA%/OriginalCityBuilder/saves/manual.json`, with `.bak` as the previous valid save. Restarting begins a fresh paused map; use Load to restore your city. Camera/display/overlay preferences are not persisted.

**Schema 8**, simulation/content **m2g-1** (the same fields as schema 7; desirability is derived), stores the tax rate (and the rate of the latest settlement), lot and station anchors, development and service-loss counters on lot anchors, the latest settlement inputs, and one project record (completed status and park location, or no location after clearing). Schema-7 saves load with everything kept; schema-6 saves load with everything kept at the standard 10% rate. Earlier saves (schemas 1-5) load with their old single-tile zones and stations cleared, because they cannot become 3x3 lots or 4x4 stations; roads, parks, funds, time, budget history and project completion are kept, and the load message counts the cleared tiles. Schemas 1-4 gain an incomplete project, with no automatic completion or retroactive collection. Loading never writes. Before replacing an older primary or backup, its exact bytes are preserved once as `manual.schema1-7.json`; failed preservation stops the save. Older builds cannot read schema 8: roll back using the preserved original. Networks, population/jobs, demand, park coverage, project eligibility and budget forecasts are derived.

## Evidence and limits

**Density stages (R2b part 1).** Lots now grow through levels 0-4. A residential lot holds 4 / 8 / 20 / 40 residents at levels 1-4; commercial lots provide 2 / 4 / 10 / 20 jobs and industrial lots 4 / 8 / 16 / 28. Levels 3 and 4 need land value: residential 1 / 2 (water allows 3, a park 4), commercial 3 / 4 (trade plus a park). Industry needs a workforce of 100 / 250 town residents. Otherwise lots stop at level 2, and a lot whose value falls drops one level per check. Yellow pips mark levels 3 and 4. The inspector shows a residential lot's wealth (modest, comfortable, well-off), which affects nothing else yet. Each lot still uses one power unit. Saves are schema 10 / r2b-1; schema 9 loads unchanged. *Some rule paragraphs below still describe levels 0-2 and say "home"; the in-game Help is current.*

R2b passed **752 source checks**, **583 exported-PCK checks** under the pinned editor runtime, and release-EXE headless start-up; ten earlier fixtures byte-identical and an eleventh (schema 10) added. A test park town grows to 104 residents / 44 jobs (the old ceiling was 48) and then settles. A native posted-input run of the actual EXE grew a street with parks to 72 residents with level-4 and level-3 lots, showed the summary and saved schema 10. See [R2b evidence](docs/sessions/2026-11-06-r2b.md).

**Police and fire (R2c).** 9 places a police station and 0 a fire station (3x3, $400 each, $30 a month each). A station works with a connected road beside it and one power unit, and covers every lot within 12 side-steps of its footprint. Level 4 for every zone type also needs police **and** fire cover; without both, lots stop at level 3, and a level-4 lot that loses cover drops one level per check (nothing is demolished). C toggles the Services overlay (square = police, triangle = fire, cross = a station that is not working). The town summary counts lots that need cover and stations that are not working. Saves are schema 11 / r2c-1; schema 10 loads with every lot kept. There is still no crime, fire or disaster.

R2c passed **800 source checks**, **612 exported-PCK checks** under the pinned editor runtime, and release-EXE headless start-up; eleven earlier fixtures byte-identical and a twelfth (schema 11) added. A test park town reaches level 4 with cover and stops at level 3 without it. A native posted-input run of the actual EXE stopped at level 3 (summary: "2 lots need police and fire cover"), reached level 4 after both stations were placed, saved schema 11 and reloaded after a restart. See [R2c evidence](docs/sessions/2026-11-06-r2c.md).

**Autosaves, settings and history (R3).** Every 60 days of running time the game writes one of three rotating autosave slots beside the manual save; autosaves never replace or change the manual save or its backup, and Load → Load autosave opens the newest valid one. Window size, text size, artwork, the grid, road and power marks, the land value and services overlays and the First steps choice are remembered in `settings.json`; a damaged file falls back to the defaults. Each monthly settlement records residents, commercial and industrial jobs, cash and net (up to 240 months, saved in schema 12 / r3-1); H or Budget → Graphs [H] shows them as three line graphs. Schema 11 saves load with an empty history.

R3 passed **843 source checks**, **632 exported-PCK checks** under the pinned editor runtime, and release-EXE headless start-up; twelve earlier fixtures byte-identical and a thirteenth (schema 12) added. A native posted-input run of the actual EXE autosaved during play, showed the graphs, restored changed settings after a restart and offered Load autosave. See [R3 evidence](docs/sessions/2026-11-06-r3.md).

**Land value (R2a).** The V overlay is now land value. Residential lots keep the D33 rules. Commercial lots use the same parts plus **trade** (+1 per developed residential lot within 3 side-steps, up to +2); higher-value commercial lots grow first, and below 0 they are held at level 1 like residential lots. Industry ignores land value and is not deterred by other industry; the industrial lot with the fewest road steps to the gold flag grows first. The inspector gives each lot its value parts, or its freight steps for industry. Saves are schema 9 / r2a-1 with no new fields; schema 8 loads unchanged.

R2a passed **716 source checks**, **577 exported-PCK checks** under the pinned editor runtime, and release-EXE headless start-up; the nine earlier fixtures are byte-identical and a tenth (schema 9) was added. A native posted-input run of the actual EXE showed industry nearest the link growing first, the land value overlay with trade on a commercial lot and hatching beside industry, the summary, and a schema-9 save. See [R2a evidence](docs/sessions/2026-11-06-r2a.md).

**Wording and calendar (R1).** In the game, homes, shops and workshops are called residential, commercial and industrial lots, and power stations are power plants; this README keeps some older words in its rule descriptions. Keys are unchanged. The status bar shows the date: tick 0 is 1 Jan 1950, months are the 30-day budget month and a year is 12 months. The inspector, Budget and town summary use dates; Budget names the month each settlement covers. The date is derived and never saved.

R1 passed **683 source checks**, **571 exported-PCK checks** under the pinned editor runtime, and release-EXE headless start-up; all nine fixtures are byte-identical. New tests cover month and year boundaries, the settlement month, the tick limit, purity, the R/C/I meter and wording, the shipped calendar through the first settlement and the first year, and a save that stays schema 8 with no date. A native posted-input run of the actual EXE built a street, grew it into February, opened Budget and the summary, saved, restarted, loaded and checked the largest text. See [R1 evidence](docs/sessions/2026-11-06-r1.md).

M3b passed **669 source checks**, **562 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests cover every step, the non-advancing cases (disconnected district, diagonal home, businesses only, separate network), no-link, regression after clearing the flag, all nine fixtures, purity, the card's layout at 12 layouts with Show targets uncovered, real pointer and key progression, Show/Hide/F1/Help routes, F1 ignored in dialogs, input safety over the card, identical saves and load/restart behaviour. A native walkthrough of the actual EXE followed the card from the empty town to Done. See [M3b evidence](docs/sessions/2026-11-06-m3b.md).

M2h passed **629 source checks**, **502 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests build the summary on constructed towns (empty, no flag road, isolated lot, shortage, held homes, 25% taxes, a buffered satisfied town, a deficit), check its purity, ordering and five-item cap, and drive T, the status-bar button, Show, the Budget action, time suspension and fit at every size in the exported game. A native run of the actual EXE opened the summary on a pointer-built town with a held home and used Show. See [M2h evidence](docs/sessions/2026-11-06-m2h.md).

M2g passed **600 source checks**, **469 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests cover every desirability part, distance and the floor, growth order, held homes, the gentle drop with D32 leaving, park and clearing recovery, schema-8 continuation and a ninth (schema-8) fixture. A native run of the actual EXE built a street by pointer, grew it at 3x until the home across from a developed workshop was held at level 1, showed the overlay, rescued the home with a pointer-placed park, saved schema 8 and reloaded it after restart; a final smoke used the packaged export. See [M2g evidence](docs/sessions/2026-11-06-m2g.md).

M2f passed **565 source checks**, **457 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests cover exact taxes at 0/10/25%, the tax command, appeal, leaving order and limits, recovery, schema-7 strictness, migration of every earlier fixture at the standard rate and an eighth (schema-7) fixture. A native run of the actual EXE loaded a schema-6 town, raised the tax to 15% through Budget, watched the meter show leaving and the town settle at 28 residents / 12 jobs, saved schema 7 with the schema-6 original preserved, and restored it after restart; a final smoke used the packaged export. See [M2f evidence](docs/sessions/2026-11-06-m2f.md).

M2e passed **479 source checks**, **415 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. Tests cover lot and station footprints, access through every side position of a lot, nearest-first lot power with 4x4 stations counted per station, growth, budgets, park coverage and the project with lots, ten invalid-footprint save cases, migration of every earlier schema and schema-5 preservation. Six historical fixtures remain byte-identical; a seventh captures a completed lot square across a month.

The actual Windows EXE was driven by posted window messages to its own window (computer-use tools were unavailable). That run covered schema-5 migration with preserved originals, a lot town built by input and grown at 3x speed, restart/load with byte-identical resave, clearing a lot from its corner, and a second 4x4 station. A smoke rerun used the final export. This is automated desktop testing, not a human playtest. See [M2e evidence](docs/sessions/2026-11-06-m2e.md); [M3a evidence](docs/sessions/2026-11-05-m3a.md) and [M2d evidence](docs/sessions/2026-11-05-m2d.md) retain earlier coverage.

Automated layouts cover 1280x720, 1366x768, 1920x1080, and 1280x800 at text sizes 16/18/20. Native M2e checks cover 720p at standard text on one machine; largest-text lots are covered by automated layout checks and rendered captures. Human usability/enjoyment, Windows DPI variants, controllers, other hardware/OSs and performance targets remain unverified. No CI is configured.

## Continue here

**M3b is complete at the local checkpoint; M3 is not complete.** Owner decisions U16-U19 (6 November 2026) made homes, shops and workshops 3x3 lots and power stations 4x4, and lean the design closer to the classic genre, within unchanged copyright limits. M2f-M2h and the M3b guide are done. The U30 planning session wrote the [gap analysis](docs/GAP_ANALYSIS.md) and the [roadmap](docs/ROADMAP.md); the owner chose optional disasters off by default (U31), kept the no-debt rule (U32), set the target scale to match the original game (U33) and deferred later-edition extras (U34). R1 (terminology and calendar) is done as 0.12.0-r1, R2a (land value) as 0.13.0-r2a, R2b part 1 (levels 0-4) as 0.14.0-r2b, R2c (police and fire) as 0.15.0-r2c and R3 (autosaves, settings and history) as 0.16.0-r3. The owner will run the R6 playtest alone (U39). [Next session](NEXT_SESSION.md) implements **R4: sound sample and animation**. The source-study permission remains exhausted: never open reference source; only the permitted qualitative notes and Decisions may supply study input. The game remains original, unnamed, and not GPL-licensed.

| Document | Purpose |
| --- | --- |
| [Next session](NEXT_SESSION.md) | Current checkpoint, the R4 assignment, and study boundary |
| [Roadmap](docs/ROADMAP.md) / [Gap analysis](docs/GAP_ANALYSIS.md) | Ordered milestones R1-R17 to a classic-style city builder; feature-by-feature gaps |
| [M2e lots](docs/M2E_SPEC.md) / [M2f taxes](docs/M2F_SPEC.md) / [M2g desirability](docs/M2G_SPEC.md) / [M2h summary](docs/M2H_SPEC.md) / [M3b guide](docs/M3B_SPEC.md) | M2e-M2h and M3b implemented and tested |
| [Genre candidates](docs/GENRE_ALIGNMENT.md) | Superseded by the roadmap; record of U17-U24 |
| [Artwork evaluation](docs/artwork-review/ARTWORK_EVALUATION.md) | Kenney pack screenshots and comparison; Modern City chosen and now default |
| [Decisions](docs/DECISIONS.md) | Requirements and exact adopted rules |
| [Toolchain](docs/TOOLCHAIN.md) | Setup, verification, export, packaging |
| [Technical plan](docs/TECHNICAL_PLAN.md) | Architecture and future systems |
| [Product brief](docs/PRODUCT_BRIEF.md) | Proposed finished experience and gates |
| [Delivery plan](docs/DELIVERY_PLAN.md) | Milestones and eventual release process |
| [IP and assets](docs/IP_AND_ASSETS.md) | Provenance and rights boundaries |
| [Asset ledger](licenses/ASSETS.md) | Original placeholders and notices |

**M2 local functional gate met; M3a, M3b and M2e-M2h locally verified; the full M3 gate remains open.** M3b work uses `codex/m3b-first-steps`, based on `e3a5ff2`, with standing commit/push/fast-forward delivery into default branch `codex/m2a-road-access`. No public release, title, source licence, price, release date or additional supported platform was selected.
