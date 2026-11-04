# Untitled city builder

**M0/M1 and M2a implemented and tested locally on 4 November 2026.** Version **0.2.0-m2a** adds road access and home-zone explanations to the saveable building foundation. Growth, power, and the city economy remain future work. This is not a public release.

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
- Road and home-zone strokes, demolition, preview prices, integer funds, atomic rejection, and free identical repainting.
- A marked outside link, orthogonal road connectivity, immediate disconnection/reconnection, and home access from a connected road beside the plot.
- Hover inspection explains missing roads, isolated districts, connected access, and inactive links; optional plus/minus access marks do not rely on colour alone.
- Camera pan/zoom/centering, grid toggle, mouse/keyboard controls, three text sizes, and four window sizes.
- Pause, 1× and 3× time, construction while paused, suspension on focus loss and during dialogs.
- Manual validated saves, prior-save backup, explicit recovery, unsaved-change prompts, and restart/load.

There are **no residents, growth, power, shops/workshops, taxes, projects, audio, controller route, or autosaves yet**. Home zones remain empty even with road access. Prices are provisional: roads $10, home zones $25, clear free with no refund; initial funds $10,000.

Start at the **gold flag** on the east edge, tile `(63,32)` on the default map. Lay a road on that tile, join roads along shared sides, then place home plots beside the connected street. Diagonals and other map-edge roads do not supply access. Removing a bridge or the root road removes service immediately; rebuilding restores it. Press **Home** to return to the link.

| Control | Action |
| --- | --- |
| 1 / 2 / 3 | Road / home zone / clear |
| Left drag; right click or Escape | Preview and commit a stroke; cancel |
| WASD / arrows / middle drag | Pan; keyboard taps also move the camera |
| Wheel / + / −; Home | Zoom; return to the outside link |
| Hover; R | Inspect a tile; toggle road access marks |
| Space; 4 / 5 | Pause/resume; normal/fast |
| Ctrl+S / Ctrl+L; F6 | Save/load; display and text settings |

Saves use `%APPDATA%/OriginalCityBuilder/saves/manual.json`, with `manual.json.bak` as the previous good save. Restarting begins a new paused map; use Load to restore the saved city. M1 saves remain supported without migration: access is derived from their existing roads and never stored. Camera/display/overlay preferences are not persisted.

## Evidence and limits

The M2a local check run passed **151 model/storage/scene checks** and **133 checks against the exported PCK under the pinned editor runtime**. The actual release executable passed headless startup and native Windows checks for missing-road/isolated/connected explanations, bridge demolition, reconnection, overlay toggling, save, exit, restart, and load. The preserved M1 fixture retains its exact canonical authoritative state.

The new inspector and placement-error layout were checked natively at 1280×720 with standard/largest text. Automated checks cover 1280×720, 1366×768, 1920×1080, and 1280×800 at three text sizes, including long explanations and rejected strokes. Earlier M1 native checks at other sizes are historical, not new M2a evidence. Windows DPI variations, controllers, a fresh machine/profile, other operating systems, performance targets, and enjoyment remain unverified. See the [M2a evidence](docs/sessions/2026-11-04-m2a.md) and [M0/M1 evidence](docs/sessions/2026-11-04-m0-m1.md).

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

M2a is complete; **M2b–M2d remain unimplemented**. The next small assignment is power access, specified in the handoff. No root source licence, final title, price, release date, or additional platform support has been chosen. The owner authorised committing/pushing the source checkpoint on `codex/m2a-road-access`; builds, caches, and local test saves remain ignored. No store publication or public game release occurred.
