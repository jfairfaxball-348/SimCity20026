# Untitled city builder

**M0/M1 through M2d implemented and tested locally, 4–5 November 2026.** Version **0.5.0-m2d** adds monthly income/upkeep, an auditable budget, recoverable deficits, and a pocket park. The local M2 functional gate is met; M3 and public release remain future work.

The user confirmed desktop players, a possible Steam release, relaxed building, charming pixel art, and approachable controls. The code, map generation, geometric graphics, and interface were created independently. The repository name is a workspace identifier, not a cleared product title.

## Play or develop

The Windows export is `builds/windows/citybuilder.exe`; keep its `citybuilder.pck` beside it. The tested local package is `builds/citybuilder-0.5.0-m2d-windows-x64.zip`. Tools, caches, and builds are ignored and absent from a fresh clone.

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
- Road and three zone strokes, single power stations, demolition, preview prices, atomic costs, and free identical repainting.
- One marked outside link, orthogonal road access, immediate disconnection/reconnection, and power networks with capacity/shortage explanations.
- Home/shop/workshop levels 0-2, aggregate residents/jobs, demand, five-day growth rounds, and gradual service-loss decline/recovery. Original roofs, awnings, and workshop silhouettes distinguish plots and development.
- Hover inspection of level, residents/jobs, access, power, demand, next growth check, and reason for waiting or declining; optional road and power symbols.
- Monthly budget forecast and last settlement, explicit shortfall waivers, free deficit recovery, and park priority for nearby homes.
- Camera pan/zoom/centering, grid toggle, three text sizes, four window sizes, pause/1x/3x, construction while paused, and suspension during dialogs/focus loss.
- Validated manual saves, previous-good backup, explicit recovery, unsaved-change prompts, deterministic continuation, and migration from earlier saves with preserved originals.

There are **no projects, audio, controller route, or autosaves yet**. Prices are provisional: roads $10, zones $25, power stations $500, parks $100; clear is free with no refund; initial funds $10,000.

## Start a growing town

Start at the **gold flag**, tile `(63,32)` on the default map. Lay a road on it, join streets along shared sides, then zone beside the connected streets. Diagonals and other map-edge roads do not supply access. Place a power station beside the street with **P**. Stations relay power but never road access, so avoid putting one in the middle of the only access road.

Each station supplies **20 zone plots**, including empty zones, nearest plots first. Each plot needs one unit regardless of development. A newly zoned nearer plot can displace a farther developed plot. Add a station on that network to fix capacity shortages; reconnect roads to fix access. The two conditions have separate inspector lines.

Unpause to grow. Every five days, plots with road access, power, and demand can gain one level, up to level 2. A home level holds 4 residents; a shop/workshop level supplies 2/4 jobs. **Starter demand supports 12 residents before any jobs exist.** Residents create business demand; jobs support more homes. The HUD's H/S/W demand is the number of available level additions. Each type gains at most eight levels per round, park-covered homes first, then map order (businesses retain map order). A mixed, sufficiently serviced town can settle at 48 residents / 18 jobs under these provisional rules. These are aggregate capacities, not simulated citizens or employment assignments.

Satisfied demand stops new growth without evicting buildings. Every second growth check without both services loses one level. Restoring both services immediately resets the loss counter; demand then permits regrowth. Counts include standing development until it declines. Clear removes the building and its residents/jobs immediately.

| Control | Action |
| --- | --- |
| 1 / 2 / 6 / 7 | Roads / homes / shops / workshops |
| P / 8 / 3 | Power station / pocket park / clear |
| B | Monthly budget and last settlement |
| Left drag; right click or Escape | Preview and commit a stroke; cancel |
| WASD / arrows / middle drag | Pan |
| Wheel / + / -; Home | Zoom; return to outside link |
| Hover; R / E | Inspect; toggle road / power marks |
| Space; 4 / 5 | Pause/resume; normal/fast |
| Ctrl+S / Ctrl+L; F6 | Save/load; display and text settings |

## Budget and parks

Every 30 days, after that day's growth, the town receives a **$100 grant + $2 per serviced resident + $4 per serviced job**. Upkeep is **$1 per road + $60 per station + $10 per park**, even when unused or disconnected. Unserved buildings pay no tax, including during decline grace. First settlement is displayed on day 31. **B** shows the current forecast, input counts, last actual settlement, and any shortfall waived or surplus capped. Forecasts change as the town changes.

A negative monthly net is a deficit. Clear surplus facilities for free or restore road/power service to recover taxes. Cash stops at zero: unpaid costs are explicitly waived, with no debt, interest, destruction, or service cuts. Construction still needs full funds. With everything cleared, the $100 monthly grant can finance a new start.

A **pocket park (8)** costs $100 and $10/month. Homes within three side-steps (Manhattan distance) receive priority when reserving growth demand. Overlap does not stack. Parks need no services and relay neither roads nor power. They change which homes develop first under contention; they add no demand, capacity, tax multiplier, or protection from decline. The inspector explains coverage and priority.

## Saves

Saves use `%APPDATA%/OriginalCityBuilder/saves/manual.json`, with `.bak` as the previous valid save. Restarting begins a fresh paused map; use Load to restore your city. Camera/display/overlay preferences are not persisted.

**Schema 4**, simulation/content **m2d-1**, stores development, service-loss counters, and the latest settlement inputs. Schemas 1/2 migrate with zero development; schema 3 retains its development and pending decline. Every older version gains an empty budget history, with no retroactive collection. Loading never writes. Before replacing an older primary or backup, its exact bytes are preserved once as `manual.schema1.json`, `manual.schema2.json`, or `manual.schema3.json`; failed preservation stops the save. Older builds cannot read schema 4: roll back using the preserved original. Networks, population/jobs, demand, park coverage, and budget forecasts are derived.

## Evidence and limits

M2d passed **361 source checks**, **324 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. Checks cover exact post-growth monthly accounting, unserved taxes, park contention and distance, cash limits, deficit recovery, fractional reload/frame partition across months, atomic spending, older migrations, corrupted saves, and storage failures. Five save fixtures are hash-checked. Three deliberate economy/priority faults were detected and reverted. A 128x128 scenario completed 250 days with valid bounded development and saves; this is not a performance-target pass.

The exact Windows release executable was exercised through park placement, growth/accounting, budget scrolling at largest text, save/exit/restart/load with byte-identical resave, zero-cash overbuild, free demolition, and recovered monthly grants. Two controlled scenarios were prepared through model commands; this was automated desktop input, not a human playtest. Original user saves were restored byte-for-byte. See [M2d evidence](docs/sessions/2026-11-05-m2d.md) for scenario details, artifact hashes, the interruption during the recovery run, and limits.

Automated layouts cover 1280x720, 1366x768, 1920x1080, and 1280x800 at text sizes 16/18/20. Native M2d evidence covers 720p at standard/largest text only. Physical human keyboard/mouse use, Windows DPI variations, controllers, other machines/OSs, performance targets, and enjoyment remain unverified. No CI is configured.

## Continue here

**M2d is complete at the local checkpoint.** Review [Next session](NEXT_SESSION.md) before further work; M3a scoping is complete and the next session implements only the [specified single-project prototype](docs/M3A_SPEC.md). No M3 code is implemented yet. The completed source-study permission remains exhausted. Implementation sessions must never open reference source; their only reference-study inputs are the [qualitative notes](docs/research/MICROPOLIS_STUDY.md) and [Decisions](docs/DECISIONS.md). The game remains original, unnamed, and not GPL-licensed.

| Document | Purpose |
| --- | --- |
| [Next session](NEXT_SESSION.md) | M2d checkpoint, bounded M3a implementation, and study boundary |
| [Decisions](docs/DECISIONS.md) | Requirements and exact adopted rules |
| [Toolchain](docs/TOOLCHAIN.md) | Setup, verification, export, packaging |
| [Technical plan](docs/TECHNICAL_PLAN.md) | Architecture and future systems |
| [Product brief](docs/PRODUCT_BRIEF.md) | Proposed finished experience and gates |
| [Delivery plan](docs/DELIVERY_PLAN.md) | Milestones and eventual release process |
| [IP and assets](docs/IP_AND_ASSETS.md) | Provenance and rights boundaries |
| [Asset ledger](licenses/ASSETS.md) | Original placeholders and notices |

**M2 local functional gate met; M3 remains unimplemented.** M2d was delivered at `f2093cb`; the documentation-only M3a scope uses `codex/m3a-scope`. Source delivery uses a pushed work branch and fast-forward integration into default branch `codex/m2a-road-access`. Commit/push/merge/fast-forward is now the standing completion workflow. No public release, title, source licence, price, release date, or additional supported platform was selected.
