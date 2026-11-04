# Next agent: M2b power access

Updated **4 November 2026**, after the user explicitly authorised M2a road access, Windows-export testing, docs/handoff, and then committing/pushing the source checkpoint. The earlier research-only restriction is historical.

## Current checkpoint

**M0/M1 and M2a implemented and locally tested. M2b–M2d are not implemented.** Read [README](README.md), [AGENTS](AGENTS.md), [Decisions](docs/DECISIONS.md), [Toolchain](docs/TOOLCHAIN.md), and [M2a evidence](docs/sessions/2026-11-04-m2a.md) before editing. The [M0/M1 record](docs/sessions/2026-11-04-m0-m1.md) is historical foundation evidence.

- Godot **4.7.2 Standard**, exact output `4.7.2.stable.official.ed1daf0bf`, matching isolated Windows x64 templates, Compatibility renderer. Use `tools/`; the global wrapper still resolves to 4.6.3.
- Game version **0.2.0-m2a**, project `game/project.godot`, scene/script `game/scenes/main.tscn` / `game/scripts/main.gd`.
- Model `game/scripts/sim/city_state.gd`: flat arrays, ordered synchronous validated commands, integer cents, fixed clock, seeded RNG. Original 64×64 coastal map; no per-cell Nodes.
- `game/scripts/sim/road_access.gd`: scene-independent derived reachability and home access. Full rebuild after initialization/validated decoding and each successful occupancy-changing command. Home edits refresh service too. No recomputation per tick/frame, no serialized access, no RNG use.
- Roads, empty home zones, demolition, atomic costs, no-op repaint, camera, pause/1×/3×, scalable text, manual save/backup/recovery work.
- UI: original gold flag, hover inspector with reasons, R access marks (`+` connected / `−` missing), Home/outside-link button. The inspector retains the last inspected tile over UI and always states that growth/power are not implemented.
- Local export `builds/windows/citybuilder.exe` + PCK; archive `builds/citybuilder-0.2.0-m2a-windows-x64.zip`. Generated, ignored, not a public release.
- Source branch `codex/m2a-road-access`; configured remote `origin` is `https://github.com/jfairfaxball-348/SimCity20026.git`. The repo had no commits and the remote advertised no refs at M2a start. The owner authorised the initial source commit/push, including the prior uncommitted foundation. Reinspect actual Git state before editing; preserve unrelated work.
- No residents, growth, power, shops/workshops, taxes, parks, projects, autosaves, controller route, or audio. The M2 gate is still open.

## Road-access contract to retain

Decision D17 was written before implementation. The outside link is a marker on `(width - 1, height / 2)` on generated maps, using integer division. On custom/legacy terrain, choose boundary land nearest that preferred tile by Manhattan distance, breaking ties by row-major index. No boundary land means no link and an explicit unavailable-access explanation. Root selection ignores occupancy, command order, and RNG.

The marker is not a free road or reserved cell. Lay an ordinary $10 road on it to activate access. If a legacy home occupies it, preserve that home and explain that it must be cleared before laying a road. Clearing the root road removes access; the flag remains. Other edge roads are not outside connections.

Only side-sharing roads transmit access. A home gets access from a side-sharing reachable road; homes, diagonals, and open land do not relay it. Rejected commands/previews/no-op repaint leave state and service unchanged. BFS uses a fixed neighbour order and an iterative queue. Power will need connected components, not just this one-root reachability mask.

## Verification to retain

```powershell
.\tools\setup.ps1             # Only if the isolated toolchain is missing
.\tools\verify.ps1
.\tools\project.ps1 Run
.\tools\package.ps1           # After exercising the export being packaged
```

M2a passed **151 source model/storage/scene checks** and **133 exported-PCK checks**. Source tests include diagonal/row-wrap separation, isolated districts, root/bridge demolition, reconnection, alternate paths/cycles, new/cleared homes, unusual saved terrain, 128×128 full reachability, deterministic ordering, and the original M1 fixture. All prior command/clock/save-recovery checks remain.

Packed checks use the pinned **editor runtime with the release PCK**, not the release EXE as a script runner. Standard release templates disable `--script`/`--main-pack` overrides. The actual EXE has separate headless-startup and native UI evidence.

Native M2a testing covered missing-road/isolated/connected explanations, construction costs, bridge demolition, save/close/restart/reload while disconnected, reconnection, and connected-save reload. The new layout was inspected at 1280×720 with standard/largest text. Automated checks cover 1280×720, 1366×768, 1920×1080, 1280×800 and text 16/18/20, including first-frame geometry and long explanations/rejection text. Do not infer broader native display, DPI, controller, performance, fresh-machine, or other-platform support.

The first native run caught oversized initial autowrap geometry; widths are now set before layout. Largest text plus placement-error messages also exposed sidebar overflow; compact controls and regression coverage now reserve room. Keep testing real rejection messages, not only the short idle cost label.

Logs and copied native test cities are under ignored `builds/validation/`. The original manual save and backup were preserved/restored after native testing; use the session record for exact local evidence. CI is not configured or claimed executed. Its adoption is a separate future task now that a source baseline is authorised.

## Save and architecture cautions

- Schema **1**, simulation/content **m1-1**, bounded JSON (512 KiB). Game version is separate. M2a adds observational derived access without changing serialized IDs, generation, prices, RNG, or the clock.
- `game/tests/fixtures/m1-schema1.json` was produced by unchanged M1 code before M2a. Its exact canonical state and deterministic continuation must remain intact. See the fixture README/hash. No general migration exists.
- Dimensions 8..128; terrain 0 land / 1 water; occupancy 0 empty / 1 road / 2 home. Seed/RNG are signed 64-bit decimal strings. Money/tick/microseconds/sequence are bounded integers.
- Save path `%APPDATA%/OriginalCityBuilder/saves/manual.json`; prior good backup `.bak`. Validate a fresh model before replacing the live city. Temporary writes are verified; failure preserves current city. Recovery is best effort, not a power-loss guarantee.
- Prices remain provisional: $10 road, $25 home, free clear/no refund, $10,000 starting funds.
- One day/tick, 1 second at 1×, 3× fast, construction while paused. Eight ticks/frame; retain one simulated hour of backlog, discard excess. Focus loss/dialogs suspend time. No offline catch-up or economics.
- Synchronous input-order commands between clock updates; strokes sort/deduplicate before atomic validation. Command records are logged, but there is no durable replay journal.
- World is a custom-drawn Node2D in a 640×360 SubViewport, separate scalable UI. No imported art/audio. Camera, window/text size, and overlay preferences reset on restart.
- New persistent facilities/power state will require explicit schema/simulation/content version decisions. Do not add new meanings to schema-1 occupancy IDs silently.

## Smallest next assignment: M2b power access

When asked to continue, implement **one small power source, component supply/capacity, deterministic allocation, and clear zone power explanations**, then stop at the checkpoint. Do not add growth or monthly economics to complete M2b.

1. Inspect Git and rerun current verification. Preserve the M1 fixture and an M2a continuation example.
2. Specify the power-source placement/price/capacity, zone demand units, adjacency rules, and shortage allocation order in Decisions before coding. Decide explicitly whether power works on an isolated road component; outside access and local supply are distinct conditions.
3. Add scene-independent deterministic road components and bounded supply/demand allocation. Retain road access as its own prerequisite/diagnostic. No detailed electrical simulation or separate power-line tools are needed.
4. Introduce only the minimum persistent source state and commands. Deliberately version it and test migration of supported M1/M2a saves, preserving original files, or explicitly reject unsupported saves with a clear explanation. Do not silently reinterpret schema 1.
5. Explain missing source, disconnection, and capacity shortage in the inspector. Keep empty plots and the unimplemented-growth boundary clear.
6. Test capacity accounting, isolated components, source/bridge removal, reconnection, deterministic shortage ties, rejected-command spending, and save/reload continuation.
7. Exercise the exact Windows export with a working component and a shortage/disconnection/recovery, including save/restart/load. Update README, Decisions, evidence, and this handoff.

## Later slices (future)

- **M2c:** homes/shops/workshops, bounded aggregate growth, population/jobs/demand, explicit bootstrap rule avoiding an empty-town deadlock.
- **M2d:** specified monthly income/upkeep, park/amenity, understandable deficit recovery, viable-opening/disconnection/shortage/overbuild scenario tests.
- **M2 gate:** an empty town can grow; shortages/failures can be explained and recovered from; save continuation and accounting invariants pass in the export.

Keep the relaxed desktop experience central. Use original placeholders and neutral identifiers. No purchases, external messaging, store upload/publication, or public game release follows from this handoff.
