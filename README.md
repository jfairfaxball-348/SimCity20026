# Untitled city builder

**M0/M1 through M2d, the bounded M3a project, M2e zone lots, M2f taxes, M2g desirability and the M2h town summary are implemented and tested locally, 4–6 November 2026.** Version **0.7.0-m2e** makes homes, shops and workshops 3x3 lots and power stations 4x4 buildings, with schema-6 saves; **0.7.1-m2e** makes the owner-chosen Kenney Roguelike Modern City (CC0) the default artwork, with the original graphics as a fallback. **0.8.0-m2f** adds a demand meter and an adjustable tax rate (schema 7), **0.9.0-m2g** neighbourhood desirability with workshop nuisance and a map overlay (schema 8), and **0.10.0-m2h** a town summary (T): the three owner-chosen [city-builder systems](docs/GENRE_ALIGNMENT.md) (U24). M3 as a whole and public release remain future work. Next is the refreshed first-steps guide ([M3b](docs/M3B_SPEC.md)). **Artwork:** Modern City is the default (U22/U23); Display → Artwork switches to Original (fallback) or Tiny City (experimental). See the [screenshots and report](docs/artwork-review/ARTWORK_EVALUATION.md).

The user confirmed desktop players, a possible Steam release, relaxed building, charming pixel art, and approachable controls. The code, map generation, geometric graphics, and interface were created independently. The repository name is a workspace identifier, not a cleared product title.

## Play or develop

The Windows export is `builds/windows/citybuilder.exe`; keep its `citybuilder.pck` beside it. The tested local package is `builds/citybuilder-0.10.0-m2h-windows-x64.zip`. Tools, caches, and builds are ignored and absent from a fresh clone.

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

Unpause to grow. Every five days, lots with road access, power, and demand can gain one level, up to level 2. A home level holds 4 residents; a shop/workshop level supplies 2/4 jobs. **Starter demand supports 12 residents before any jobs exist.** Residents create business demand; jobs support more homes. The **demand meter** under the population count shows, for H(omes), S(hops) and W(orkshops), the level additions the town welcomes (+, bar up) or, above the standard tax rate, the levels about to leave (−, bar down). Each type gains at most eight levels per round, park-covered home lots first, then map order (businesses retain map order). A mixed, sufficiently serviced town can settle at 48 residents / 18 jobs under these provisional rules. These are aggregate capacities, not simulated citizens or employment assignments.

At or below the standard tax rate, satisfied demand stops new growth without evicting buildings. Every second growth check without both services loses one level. Restoring both services immediately resets the loss counter; demand then permits regrowth. Counts include standing development until it declines. Clear removes the building and its residents/jobs immediately.

| Control | Action |
| --- | --- |
| 1 / 2 / 6 / 7 | Roads / homes / shops / workshops |
| P / 8 / 3 | Power station / pocket park / clear |
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

**Town summary (T).** **T**, or the **Town summary** button at the right of the status bar, lists the biggest measurable causes holding the town back, biggest first: no road on the gold flag, lots without road access or power, lots short of power, homes held by workshops, levels leaving under high taxes, and demand with no lot able to use it; then any monthly deficit. Each item gives a count and a remedy, and **Show** centres the view on an example and inspects it (or **Budget** opens Budget). An empty town gets the three starting steps; a town with nothing blocking it says so. The summary is read-only and pauses time while open; the inspector remains the per-lot explanation.

A **pocket park (8)** costs $100 and $10/month. Home lots with a tile within three side-steps (Manhattan distance) gain +2 desirability, so they reserve growth demand first. Overlap does not stack. Parks need no services and relay neither roads nor power. They change which homes develop first under contention; they add no demand, capacity, tax multiplier, or protection from decline. The inspector explains coverage and priority.

## A welcoming square

Open **Project [J]**, choose a pocket park, and grow three distinct home lots, each with a tile within three side-steps of it. Each lot needs road access and power; either development level counts once. Press **Complete square** when ready to add flowers. This is optional, free, and available while paused, with no deadline. The flowers are cosmetic: the existing park priority and upkeep stay unchanged.

Completion is once per town. Service loss or decline does not undo it. Clearing the decorated park removes its flowers but keeps completion; replacing the park does not restart the project. **Show park** centres the view. At largest text, scroll the project dialog to reach its actions. Help also scrolls.

## Saves

Saves use `%APPDATA%/OriginalCityBuilder/saves/manual.json`, with `.bak` as the previous valid save. Restarting begins a fresh paused map; use Load to restore your city. Camera/display/overlay preferences are not persisted.

**Schema 8**, simulation/content **m2g-1** (the same fields as schema 7; desirability is derived), stores the tax rate (and the rate of the latest settlement), lot and station anchors, development and service-loss counters on lot anchors, the latest settlement inputs, and one project record (completed status and park location, or no location after clearing). Schema-7 saves load with everything kept; schema-6 saves load with everything kept at the standard 10% rate. Earlier saves (schemas 1-5) load with their old single-tile zones and stations cleared, because they cannot become 3x3 lots or 4x4 stations; roads, parks, funds, time, budget history and project completion are kept, and the load message counts the cleared tiles. Schemas 1-4 gain an incomplete project, with no automatic completion or retroactive collection. Loading never writes. Before replacing an older primary or backup, its exact bytes are preserved once as `manual.schema1-7.json`; failed preservation stops the save. Older builds cannot read schema 8: roll back using the preserved original. Networks, population/jobs, demand, park coverage, project eligibility and budget forecasts are derived.

## Evidence and limits

M2h passed **629 source checks**, **502 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests build the summary on constructed towns (empty, no flag road, isolated lot, shortage, held homes, 25% taxes, a buffered satisfied town, a deficit), check its purity, ordering and five-item cap, and drive T, the status-bar button, Show, the Budget action, time suspension and fit at every size in the exported game. A native run of the actual EXE opened the summary on a pointer-built town with a held home and used Show. See [M2h evidence](docs/sessions/2026-11-06-m2h.md).

M2g passed **600 source checks**, **469 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests cover every desirability part, distance and the floor, growth order, held homes, the gentle drop with D32 leaving, park and clearing recovery, schema-8 continuation and a ninth (schema-8) fixture. A native run of the actual EXE built a street by pointer, grew it at 3x until the home across from a developed workshop was held at level 1, showed the overlay, rescued the home with a pointer-placed park, saved schema 8 and reloaded it after restart; a final smoke used the packaged export. See [M2g evidence](docs/sessions/2026-11-06-m2g.md).

M2f passed **565 source checks**, **457 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. New tests cover exact taxes at 0/10/25%, the tax command, appeal, leaving order and limits, recovery, schema-7 strictness, migration of every earlier fixture at the standard rate and an eighth (schema-7) fixture. A native run of the actual EXE loaded a schema-6 town, raised the tax to 15% through Budget, watched the meter show leaving and the town settle at 28 residents / 12 jobs, saved schema 7 with the schema-6 original preserved, and restored it after restart; a final smoke used the packaged export. See [M2f evidence](docs/sessions/2026-11-06-m2f.md).

M2e passed **479 source checks**, **415 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. Tests cover lot and station footprints, access through every side position of a lot, nearest-first lot power with 4x4 stations counted per station, growth, budgets, park coverage and the project with lots, ten invalid-footprint save cases, migration of every earlier schema and schema-5 preservation. Six historical fixtures remain byte-identical; a seventh captures a completed lot square across a month.

The actual Windows EXE was driven by posted window messages to its own window (computer-use tools were unavailable). That run covered schema-5 migration with preserved originals, a lot town built by input and grown at 3x speed, restart/load with byte-identical resave, clearing a lot from its corner, and a second 4x4 station. A smoke rerun used the final export. This is automated desktop testing, not a human playtest. See [M2e evidence](docs/sessions/2026-11-06-m2e.md); [M3a evidence](docs/sessions/2026-11-05-m3a.md) and [M2d evidence](docs/sessions/2026-11-05-m2d.md) retain earlier coverage.

Automated layouts cover 1280x720, 1366x768, 1920x1080, and 1280x800 at text sizes 16/18/20. Native M2e checks cover 720p at standard text on one machine; largest-text lots are covered by automated layout checks and rendered captures. Human usability/enjoyment, Windows DPI variants, controllers, other hardware/OSs and performance targets remain unverified. No CI is configured.

## Continue here

**M2h is complete at the local checkpoint; M3 is not complete.** Owner decisions U16-U19 (6 November 2026) made homes, shops and workshops 3x3 lots and power stations 4x4, and lean the design closer to the classic genre, within unchanged copyright limits. The owner then chose the city-builder systems ahead of the guide (U24). M2f (demand meter and tax rate), M2g (neighbourhood desirability and workshop nuisance) and M2h (town summary) are done; [Next session](NEXT_SESSION.md) refreshes and implements the **M3b first-steps guide**. The source-study permission remains exhausted: never open reference source; only the permitted qualitative notes and Decisions may supply study input. The game remains original, unnamed, and not GPL-licensed.

| Document | Purpose |
| --- | --- |
| [Next session](NEXT_SESSION.md) | Current checkpoint, city-builder roadmap, M3b assignment, and study boundary |
| [M2e lots](docs/M2E_SPEC.md) / [M2f taxes](docs/M2F_SPEC.md) / [M2g desirability](docs/M2G_SPEC.md) / [M2h summary](docs/M2H_SPEC.md) / [M3b guide](docs/M3B_SPEC.md) | M2e-M2h implemented and tested; M3b specified, next after refresh |
| [Genre candidates](docs/GENRE_ALIGNMENT.md) | Classic-genre systems and the U24 schedule |
| [Artwork evaluation](docs/artwork-review/ARTWORK_EVALUATION.md) | Kenney pack screenshots and comparison; Modern City chosen and now default |
| [Decisions](docs/DECISIONS.md) | Requirements and exact adopted rules |
| [Toolchain](docs/TOOLCHAIN.md) | Setup, verification, export, packaging |
| [Technical plan](docs/TECHNICAL_PLAN.md) | Architecture and future systems |
| [Product brief](docs/PRODUCT_BRIEF.md) | Proposed finished experience and gates |
| [Delivery plan](docs/DELIVERY_PLAN.md) | Milestones and eventual release process |
| [IP and assets](docs/IP_AND_ASSETS.md) | Provenance and rights boundaries |
| [Asset ledger](licenses/ASSETS.md) | Original placeholders and notices |

**M2 local functional gate met; M3a and M2e-M2h locally verified; the full M3 gate remains open.** M2h work uses `codex/m2h-town-summary`, based on `cd035dc`, with standing commit/push/fast-forward delivery into default branch `codex/m2a-road-access`. No public release, title, source licence, price, release date or additional supported platform was selected.
