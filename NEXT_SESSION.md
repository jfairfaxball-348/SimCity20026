# Next agent: M2c growth

Updated **4 November 2026**, after the user explicitly authorised M2b power access, Windows-export testing, docs/handoff, then commit and push. Earlier research-only restrictions are historical.

## Current checkpoint

**M0/M1, M2a, and M2b implemented and locally tested. M2c–M2d are not implemented.** Read [README](README.md), [AGENTS](AGENTS.md), [Decisions](docs/DECISIONS.md) (especially D17–D21 and the access/power rules), [Toolchain](docs/TOOLCHAIN.md), and [M2b evidence](docs/sessions/2026-11-04-m2b.md) before editing. The [M2a](docs/sessions/2026-11-04-m2a.md) and [M0/M1](docs/sessions/2026-11-04-m0-m1.md) records are historical.

- Godot **4.7.2 Standard**, exact output `4.7.2.stable.official.ed1daf0bf`, matching isolated Windows x64 templates, Compatibility renderer. Use `tools/`; the global wrapper still resolves to 4.6.3.
- Game version **0.3.0-m2b**, project `game/project.godot`, scene/script `game/scenes/main.tscn` / `game/scripts/main.gd`.
- Model `game/scripts/sim/city_state.gd`: flat arrays, ordered synchronous validated commands, integer cents, fixed clock, seeded RNG. `rebuild_derived()` rebuilds `road_access.gd` then `power_grid.gd` after initialization, validated decoding, and each successful occupancy-changing command. Nothing derived is serialized or touched by ticks.
- UI: gold outside-link flag, P power-station tool, hover inspector with separate road-access and power lines, R access marks (+/−), E power marks (bolt/×), toolbar "Power used / capacity · N plots short", migration status message.
- Local export `builds/windows/citybuilder.exe` + PCK; archive `builds/citybuilder-0.3.0-m2b-windows-x64.zip`. Generated, ignored, not a public release.
- M2b was built on `codex/m2b-power-access` and, at the owner's instruction, fast-forward merged into the repository's default branch `codex/m2a-road-access` (the name predates M2b) and pushed; no PR was opened. Remote `origin` = `https://github.com/jfairfaxball-348/SimCity20026.git`. The `gh` CLI on this machine is signed in to an account with read-only access to that repository, so PR merges through `gh` fail; git pushes work. Reinspect Git before editing; preserve unrelated work. Build M2c on a fresh `codex/` branch from the default branch.
- No residents, growth, shops/workshops, upkeep, taxes, parks, projects, autosaves, controller route, or audio. The M2 gate is still open.

## Contracts to retain

**Road access (D17, unchanged).** One outside link on `(width - 1, height / 2)` for generated maps. Custom terrain picks the nearest boundary land by Manhattan distance, ties by row-major index; with no boundary land there is no link. The marker is not a free road: an ordinary $10 road on it activates access. Only side-sharing roads transmit access. Homes, stations, diagonals, and open land do not relay it.

**Power (D19).** One single-tile power station: $500, 20 units, one per command, never on the link marker, free clear with no refund. Each home plot needs 1 unit. Road + station tiles joined by sides form a network; stations relay power but not road access. Power does not require the outside link.

Allocation is nearest-first by (station distance, row-major plot index). Each plot draws from its touching network with room by (distance, network order), where network order is the row-major index of the network's first tile. There is no stored allocation memory, so a newly zoned nearer plot can displace a farther one. Decide explicitly whether M2c needs stable allocation once buildings grow; if so, it needs persistent state and a new version.

**Explanations.** Home power reasons: `powered`, `shortage`, `disconnected`, `no_adjacent_network`, `no_source`. Road access reasons are unchanged. The inspector keeps them on separate lines and the scope line states that growth is not implemented. M2c growth is specified to need **both** road access and power.

## Verification to retain

```powershell
.\tools\setup.ps1             # Only if the isolated toolchain is missing
.\tools\verify.ps1
.\tools\project.ps1 Run
.\tools\package.ps1           # After exercising the export being packaged
```

M2b passed **233 source checks** and **252 exported-PCK checks**, plus release-EXE headless startup. Source tests cover capacity accounting, deterministic plot and network ties, nearest-first versus row-major ordering, spill to a farther network, relay rules, bridge/source removal and recovery, rejected-command spending, reload continuation, 128×128 bounds, schema-1 migration, preserved originals, and rejected newer schemas. Five deliberate allocation mutations all fail the suite; keep a scenario that distinguishes each rule you add.

Packed checks use the pinned **editor runtime with the release PCK**; standard release templates disable `--script`. Native M2b testing drove the actual EXE by posting window messages to its own handle. Hover moved the real cursor briefly; captures used `PrintWindow`. Desktop computer-use tools were unavailable in that session. If they are available next time, prefer them for physical-input evidence. The driver is `builds/validation/native/native_driver.py` (ignored, local).

Helpers were run under **Windows PowerShell 5.1** (PowerShell 7 was not installed this session). They are now 5.1-safe: complete logs, UTF-8 logs, BOM-free manifest. They have not been re-run under PowerShell 7 since those changes.

Native evidence covers 1280×720 at standard/largest text only. At largest text the Controls & notes dialog uses nearly the full 720p height, so shorten or scroll it before adding more lines. Keep testing real rejection and shortage text at all sizes; the inspector is capped at 320 px to keep the centred flag visible and re-fits itself after text-size changes. CI is not configured.

## Save and architecture cautions

- Schema **2**, simulation/content **m2b-1**, bounded JSON (512 KiB). Occupancy 0 empty / 1 road / 2 home / 3 power station; terrain 0 land / 1 water. Seed/RNG are signed 64-bit decimal strings.
- Schema 1 (`m1-1`, IDs 0–2) migrates in memory by changing only the version fields. Before a save replaces a schema-1 primary or rotates over a schema-1 backup, its bytes are preserved once as `manual.schema1.json`. Newer or inconsistent saves are refused without changes. Build 0.2.0 cannot read schema 2.
- Fixtures: `m1-schema1.json`, `m2a-schema1.json` (written by unchanged M2a code), `m2b-schema2.json`. Preserve their bytes; see the fixture README. Any new persistent meaning (grown buildings, zone types, development level) needs a new schema/simulation/content version, a migration from schema 2 (and 1), and a new preserved sample.
- Save path `%APPDATA%/OriginalCityBuilder/saves/manual.json`; prior good backup `.bak`. Validate a fresh model before replacing the live city. Recovery is best effort, not a power-loss guarantee.
- Prices remain provisional: $10 road, $25 home, $500 power station, free clear with no refund, $10,000 starting funds. No upkeep or income.
- One day/tick, 1 second at 1×, 3× fast, construction while paused. Eight ticks/frame; one simulated hour of retained backlog. Focus loss/dialogs suspend time. No offline catch-up.
- The world is a custom-drawn Node2D in a 640×360 SubViewport with separate scalable UI. There is no imported art/audio. Camera, window/text size, and overlay preferences reset on restart.

## Smallest next assignment: M2c growth

When asked to continue, implement **homes/shops/workshops, bounded aggregate growth, population/jobs/demand, and an explicit bootstrap rule that avoids an empty-town deadlock**, then stop at the checkpoint. Do not add monthly income/upkeep (M2d).

1. Inspect Git and rerun current verification. Preserve all three fixtures.
2. In Decisions, before coding, specify:
   - zone types and their power demand;
   - development levels and growth/decline rules;
   - the requirements (road access **and** power, plus demand);
   - the bootstrap demand;
   - tick cadence and system order;
   - deterministic tie-breaks and RNG use (if any);
   - whether power allocation must become stable for grown buildings.
3. Keep growth aggregate and bounded; no individual citizens. Evaluate from the prior completed state and apply changes together.
4. Version the new persistent state deliberately and migrate schema 2 (and 1) saves with preserved originals, or explicitly reject them with a clear explanation.
5. Explain why each plot is or is not growing, including demand, access, power, and shortage. Keep explanations within the 320 px inspector at all text sizes.
6. Test an empty town that grows, a disconnected district, a power shortage, decline/recovery, determinism across save/reload, and bounded 128×128 ticks.
7. Exercise the exact Windows export with growth, a shortage, and save/restart/load. Update README, Decisions, evidence, and this handoff.

## Later slices (future)

- **M2d:** specified monthly income/upkeep (including station upkeep), park/amenity, understandable deficit recovery, viable-opening/disconnection/shortage/overbuild scenario tests.
- **M2 gate:** an empty town can grow; shortages/failures can be explained and recovered from; save continuation and accounting invariants pass in the export.

Keep the relaxed desktop experience central. Use original placeholders and neutral identifiers. No purchases, external messaging, store upload/publication, or public game release follows from this handoff.
