# Untitled city builder

**M0/M1, M2a, and M2b implemented and tested locally on 4 November 2026.** Version **0.3.0-m2b** adds power stations, power networks, and power-shortage explanations to the saveable building and road-access foundation. Growth and the city economy remain future work. This is not a public release.

The user confirmed desktop players, a possible Steam release, relaxed building, charming pixel art, and approachable controls. The historical games informed the research; this project's code, map generation, geometric graphics, and interface were created independently. The repository name is a workspace identifier, not a cleared product title.

## Play or develop

The local Windows export is `builds/windows/citybuilder.exe`; keep its `citybuilder.pck` beside it. A local ZIP is produced by the packaging command below. Generated tools/builds are ignored by Git and are not present in a fresh clone.

From the repository root in PowerShell:

```powershell
.\tools\setup.ps1             # First use: verified, isolated editor/templates download
.\tools\project.ps1 Run       # Run through the pinned editor runtime
.\tools\verify.ps1            # Model/storage tests, export, pack checks, EXE startup
.\tools\package.ps1           # Package the existing verified Windows export
```

The explicit pin is **Godot 4.7.2 Standard**, `4.7.2.stable.official.ed1daf0bf`, typed GDScript, Compatibility renderer. The existing global Godot 4.6.3 wrapper was left intact. See [Toolchain](docs/TOOLCHAIN.md) for paths, checksums, individual commands, and test limits.

## What works

- Original seeded 64×64 coastal map; integer-scaled pixel world with separately scalable UI.
- Road and home-zone strokes, single power-station placement, demolition, preview prices, integer funds, atomic rejection, and free identical repainting.
- A marked outside link, orthogonal road connectivity, immediate disconnection/reconnection, and home access from a connected road beside the plot.
- Power stations supplying 20 home plots each through the roads and stations they touch, nearest plots first, with or without the outside link.
- Hover inspection explains road access and power separately: missing road, isolated district, missing station, disconnection, and capacity shortage. Optional +/− access marks and bolt/× power marks do not rely on colour alone. The toolbar shows power used/capacity and plots short.
- Camera pan/zoom/centering, grid toggle, mouse/keyboard controls, three text sizes, and four window sizes.
- Pause, 1× and 3× time, construction while paused, suspension on focus loss and during dialogs.
- Manual validated saves, prior-save backup, explicit recovery, unsaved-change prompts, restart/load, and migration of earlier saves with the original file preserved.

There are **no residents, growth, shops/workshops, upkeep, taxes, projects, audio, controller route, or autosaves yet**. Home plots remain empty even with road access and power. Prices are provisional: roads $10, home zones $25, power station $500, clear free with no refund; initial funds $10,000.

Start at the **gold flag** on the east edge, tile `(63,32)` on the default map. Lay a road on that tile, join roads along shared sides, then place home plots beside the connected street. Diagonals and other map-edge roads do not supply access. Press **P** and place a power station beside a street: it powers up to 20 plots on that network. When a network is overbuilt, the plots farthest from a station go without power first; add another station to that network. A station does not carry road access, so place it beside or at the end of a street rather than in the middle of it. Removing a bridge, root road, or station cuts service immediately; rebuilding restores it. Press **Home** to return to the link.

| Control | Action |
| --- | --- |
| 1 / 2 / 3; P | Road / home zone / clear; power station |
| Left drag; right click or Escape | Preview and commit a stroke; cancel |
| WASD / arrows / middle drag | Pan; keyboard taps also move the camera |
| Wheel / + / −; Home | Zoom; return to the outside link |
| Hover; R; E | Inspect a tile; toggle road access marks; toggle power marks |
| Space; 4 / 5 | Pause/resume; normal/fast |
| Ctrl+S / Ctrl+L; F6 | Save/load; display and text settings |

Saves use `%APPDATA%/OriginalCityBuilder/saves/manual.json`, with `manual.json.bak` as the previous good save. Restarting begins a new paused map; use Load to restore the saved city. The save format is now **schema 2**. M1/M2a (schema 1) saves load and are updated in memory without writing. Before a save replaces a schema-1 file (the save or its backup), its exact original bytes are kept once as `manual.schema1.json`. Version 0.2.0 cannot read schema 2, so roll back with that preserved copy. Road access and power are derived and never stored. Camera/display/overlay preferences are not persisted.

## Evidence and limits

The M2b local check run passed **233 model/storage/scene checks** and **252 checks against the exported PCK under the pinned editor runtime**, plus headless startup of the release executable. The suite includes deterministic capacity/tie/ordering tests, deliberate allocation mutations, schema-1 migration with preserved originals, and 1280×720/1366×768/1920×1080/1280×800 layouts at three text sizes.

The actual release executable was then exercised natively at 1280×720 by posting input to its window and capturing it. Desktop computer-use tools were unavailable in that session. The run covered:

- loading a real M2a save (migration message, unchanged file);
- station placement and supply;
- a five-plot shortage;
- bridge disconnection, with powered-without-access and access-without-power plots;
- save, exit, restart, and load;
- reconnection and second-station recovery;
- mark toggles, largest text, and the unsaved-change prompt;
- on the final build, migration and recovery from a schema-1 backup over a corrupt save.

Physical keyboard/mouse input, other window sizes natively, Windows DPI variations, controllers, a fresh machine/profile, other operating systems, performance targets, and enjoyment remain unverified. See the [M2b evidence](docs/sessions/2026-11-04-m2b.md), [M2a evidence](docs/sessions/2026-11-04-m2a.md), and [M0/M1 evidence](docs/sessions/2026-11-04-m0-m1.md).

## Continue here

| Document | Purpose |
| --- | --- |
| [Next session](NEXT_SESSION.md) | Current state and the smallest next implementation assignment |
| [Decisions](docs/DECISIONS.md) | Confirmed requirements, adopted defaults, and open choices |
| [Toolchain](docs/TOOLCHAIN.md) | Reproducible setup, tests, export, and packaging |
| [Technical plan](docs/TECHNICAL_PLAN.md) | Architecture, implemented boundaries, later simulation |
| [Product brief](docs/PRODUCT_BRIEF.md) | Proposed finished experience and playtest gates |
| [Delivery plan](docs/DELIVERY_PLAN.md) | Milestone status and eventual release process |
| [IP and assets](docs/IP_AND_ASSETS.md) | Originality, rights, and naming boundaries |
| [Asset ledger](licenses/ASSETS.md) | Current placeholders and bundled engine/font notices |
| [Research sources](docs/RESEARCH_SOURCES.md) | Dated planning evidence |

M2a and M2b are complete; **M2c–M2d remain unimplemented**. The next small assignment is growth (homes/shops/workshops, demand, bootstrap), specified in the handoff. No root source licence, final title, price, release date, or additional platform support has been chosen. The owner authorised committing, pushing, and merging the M2b source checkpoint: it was built on `codex/m2b-power-access` and fast-forward merged into the default branch `codex/m2a-road-access`; builds, caches, and local test saves remain ignored. No store publication or public game release occurred.
