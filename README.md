# Untitled city builder

**M0/M1 through M2c implemented and tested locally, 4-5 November 2026.** Version **0.4.0-m2c** adds homes, shops, workshops, residents/jobs/demand, bounded growth, and service-loss recovery. Monthly economy and amenities remain future work. This is not a public game release.

The user confirmed desktop players, a possible Steam release, relaxed building, charming pixel art, and approachable controls. The code, map generation, geometric graphics, and interface were created independently. The repository name is a workspace identifier, not a cleared product title.

## Play or develop

The Windows export is `builds/windows/citybuilder.exe`; keep its `citybuilder.pck` beside it. The tested local package is `builds/citybuilder-0.4.0-m2c-windows-x64.zip`. Tools, caches, and builds are ignored and absent from a fresh clone.

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
- Camera pan/zoom/centering, grid toggle, three text sizes, four window sizes, pause/1x/3x, construction while paused, and suspension during dialogs/focus loss.
- Validated manual saves, previous-good backup, explicit recovery, unsaved-change prompts, deterministic continuation, and migration from earlier saves with preserved originals.

There are **no taxes, upkeep, parks/amenities, projects, audio, controller route, or autosaves yet**. Prices are provisional: roads $10, all zones $25, power stations $500, clear free with no refund, initial funds $10,000.

## Start a growing town

Start at the **gold flag**, tile `(63,32)` on the default map. Lay a road on it, join streets along shared sides, then zone beside the connected streets. Diagonals and other map-edge roads do not supply access. Place a power station beside the street with **P**. Stations relay power but never road access, so avoid putting one in the middle of the only access road.

Each station supplies **20 zone plots**, including empty zones, nearest plots first. Each plot needs one unit regardless of development. A newly zoned nearer plot can displace a farther developed plot. Add a station on that network to fix capacity shortages; reconnect roads to fix access. The two conditions have separate inspector lines.

Unpause to grow. Every five days, plots with road access, power, and demand can gain one level, up to level 2. A home level holds 4 residents; a shop/workshop level supplies 2/4 jobs. **Starter demand supports 12 residents before any jobs exist.** Residents create business demand; jobs support more homes. The HUD's H/S/W demand is the number of available level additions. Each type gains at most eight levels per round, earlier map tiles first. A mixed, sufficiently serviced town can settle at 48 residents / 18 jobs under these provisional rules. These are aggregate capacities, not simulated citizens or employment assignments.

Satisfied demand stops new growth without evicting buildings. Every second growth check without both services loses one level. Restoring both services immediately resets the loss counter; demand then permits regrowth. Counts include standing development until it declines. Clear removes the building and its residents/jobs immediately.

| Control | Action |
| --- | --- |
| 1 / 2 / 6 / 7 | Roads / homes / shops / workshops |
| P / 3 | Power station / clear |
| Left drag; right click or Escape | Preview and commit a stroke; cancel |
| WASD / arrows / middle drag | Pan |
| Wheel / + / -; Home | Zoom; return to outside link |
| Hover; R / E | Inspect; toggle road / power marks |
| Space; 4 / 5 | Pause/resume; normal/fast |
| Ctrl+S / Ctrl+L; F6 | Save/load; display and text settings |

## Saves

Saves use `%APPDATA%/OriginalCityBuilder/saves/manual.json`, with `.bak` as the previous valid save. Restarting begins a fresh paused map; use Load to restore your city. Camera/display/overlay preferences are not persisted.

**Schema 3**, simulation/content **m2c-1**, stores development and service-loss counters. Schemas 1 (M1/M2a) and 2 (M2b) validate and migrate in memory with zero development and unchanged earlier values. Loading never writes. Before replacing an older primary or backup, the game preserves its exact bytes once as `manual.schema1.json` or `manual.schema2.json`; failed preservation stops the save. Older builds cannot read schema 3: roll back using the preserved original. Networks, population/jobs, and demand are derived, never serialized.

## Evidence and limits

M2c passed **298 source checks**, **277 exported-PCK checks** under the pinned editor runtime, and release-EXE headless startup. Checks cover bootstrap, prior-state demand budgets, row-major ties, round caps, power shortages, service-loss grace/recovery, spending, migrations, corrupted saves, injected storage failures, and deterministic reload/frame partitioning. All four save fixtures are hash-checked. Four deliberate growth faults are detected. A 128x128 map completed 250 days / 50 growth rounds with bounded levels and a valid save.

The exact release executable was also exercised through Windows desktop computer-use input at 1280x720: build all three zones, grow to 48 residents / 18 jobs, create a five-plot shortage, save/exit/restart/load, disconnect and decline, reconnect/add capacity and regrow, largest text/help, and the unsaved-change prompt. The pre-existing user save files were restored byte-for-byte after testing. See the [M2c evidence](docs/sessions/2026-11-05-m2c.md) for artifact hashes, observations, and corrections.

Automated layouts cover 1280x720, 1366x768, 1920x1080, and 1280x800 at text sizes 16/18/20. Native M2c evidence covers 720p at standard/largest text only. Physical human keyboard/mouse use, Windows DPI variations, controllers, other machines/OSs, performance targets, and enjoyment remain unverified. No CI is configured.

## Continue here

The next assignment is one **Micropolis study** session under owner decision U10 (5 November 2026), followed by the unchanged M2d implementation assignment. The study is authorised but not yet performed. This follow-up prepared the study handoff only; no Micropolis or SimCity reference source was downloaded, opened, or read in this session. Study notes will be qualitative and original; implementation sessions must never open the reference source. See [Next session](NEXT_SESSION.md) and the [study boundary](docs/IP_AND_ASSETS.md#micropolis-study-and-implementation-boundary). The game remains unnamed and not GPL-licensed.

| Document | Purpose |
| --- | --- |
| [Next session](NEXT_SESSION.md) | Micropolis study next; unchanged M2d assignment queued afterward |
| [Decisions](docs/DECISIONS.md) | Requirements and exact adopted rules |
| [Toolchain](docs/TOOLCHAIN.md) | Setup, verification, export, packaging |
| [Technical plan](docs/TECHNICAL_PLAN.md) | Architecture and future systems |
| [Product brief](docs/PRODUCT_BRIEF.md) | Proposed finished experience and gates |
| [Delivery plan](docs/DELIVERY_PLAN.md) | Milestones and eventual release process |
| [IP and assets](docs/IP_AND_ASSETS.md) | Provenance and rights boundaries |
| [Asset ledger](licenses/ASSETS.md) | Original placeholders and notices |

**M2d remains unimplemented and the full M2 gate is open.** M2c commit `826ecc3`, built on `codex/m2c-growth`, is pushed and merged into default branch `codex/m2a-road-access` (its name predates M2b/M2c). U10 changes the next-session order and research boundary only. No final title, source licence, price, release date, public release, or additional supported platform has been selected.
