# Next session: implement the bounded M3a project prototype

Updated **5 November 2026** after M3a scoping. **M0/M1 through M2d are implemented and locally tested. The local M2 functional gate is met. M3 is unimplemented.** This is a development checkpoint, not a public release or evidence of human enjoyment.

## Start here

Read `README.md`, `AGENTS.md`, `docs/DECISIONS.md`, `docs/TOOLCHAIN.md`, and [M2d evidence](docs/sessions/2026-11-05-m2d.md). Inspect current Git and live remote refs before editing; preserve unrelated work. M2d was developed on **codex/m2d-economy**, based on **97b1f55737fde6cc015d65fdf2a110ae87e27e15**. Source delivery uses a pushed work branch and fast-forward integration into default branch `codex/m2a-road-access`; consult live Git history for the delivered commit. The owner now gives standing authorisation to commit, push, merge, and fast-forward completed work, recorded in AGENTS.md. Reconcile live state; do not assume the historical branch name describes current feature scope.

Use isolated **Godot 4.7.2 Standard**, exact `4.7.2.stable.official.ed1daf0bf`, via `tools/`. The global wrapper remains 4.6.3. No new dependencies or external assets were introduced.

- Game **0.5.0-m2d**, save **schema 4**, simulation/content **m2d-1**.
- Scene/UI: `game/scenes/main.tscn`, `game/scripts/main.gd`; model: `scripts/sim/city_state.gd`; rules: `growth.gd`, `economy.gd`, `amenity.gd`; values: `content/balance.gd`.
- Export: `builds/windows/citybuilder.exe` plus PCK. Tested package: `builds/citybuilder-0.5.0-m2d-windows-x64.zip`. Generated/ignored, not publicly distributed.
- Final verification: **361 source / 324 packed checks**, release-EXE startup, native Windows accounting/park/deficit/restart/recovery at 1280x720 standard/largest text. Original user saves restored with matching hashes/file count. Evidence under ignored `builds/validation/m2d/` and the tracked session record.

## Preserve the simulation contract

**Access/power (D17-D24).** One deterministic outside link, side-sharing roads only; all zones need an adjacent outside-connected road. Stations do not relay road access. Roads/stations relay power independently of outside access. Each station supplies 20 plots, including empty zones. Allocation remains `(station distance, row-major index)` with deterministic network ties and no saved priority; nearer plots may displace grown plots.

**Growth (D22/D26).** Levels 0–2, 4 residents per home level, 2/4 jobs per shop/workshop level. Prior-state home target `min(2*cells, 3+floor(jobs/2))`; each business target `ceil(population/16)`. Every five ticks, at most eight additions per type, one per eligible plot, applied simultaneously. Covered homes reserve home demand first, then uncovered homes; row-major within each group. Businesses retain row-major order. Missing road access or power loses one level every second growth round; restoring both immediately resets the counter. Demand alone never evicts buildings. Standing population/jobs includes unserved development until decline; taxable totals do not.

**Economy (D25).** Every 30 ticks after growth: grant 10000 cents + 200 per serviced resident + 400 per serviced job; expenses 100 per road + 6000 per station + 1000 per park, even unused/disconnected. No tax from unserved development, even during grace. Cash clamps to `[0, MAX_CASH]`; record explicit shortfall waiver/capped surplus. No debt, hidden arrears, service cuts, or automatic destruction. Free clear works at zero, paid commands require full cash, identical repaint is free. An empty town recovers $100/month. First settlement displayed on day 31. A forecast uses current state; actual ledger uses settlement-time counts.

**Park (D26).** ID 6, $100 placement, $10 upkeep, one tile per command, forbidden on outside link. Manhattan radius 3; no stacking, service requirement, power use, or network relay. Gives covered homes priority within existing demand/caps, no extra capacity/demand/tax multiplier/decline protection. Coverage is derived, rebuilt immediately on edits/load. Tree/path/bench is original code-drawn art.

**Clock.** Ordered commands between ticks; one tick/day; growth then budget on shared boundaries; no RNG consumed. Eight ticks/frame, one-hour backlog, focus/dialog suspension, no offline catch-up. Budget dialog is modal. Normal 1x/fast 3x. Do not leave native tests running across a handoff or interruption if avoidable: M2d's recovery test remained running during interruption, and its longer observed duration is recorded explicitly.

## Saves, UI and verification

Schema 4 stores exact-length development/loss arrays and `last_budget` (latest tick, opening cash, taxable counts, facility counts). Outputs and all service/coverage/forecast state are derived. Empty ledger is valid for new/migrated towns; no fabricated historical accounting. Schema 1 (`m1-1`, IDs 0–2), 2 (`m2b-1`, IDs 0–3), 3 (`m2c-1`, IDs 0–5) validate under their own meanings. Versions 1/2 gain zero development; 3 retains development/loss; all retain cash/time/RNG, gain empty history, and settle at the next future month only. Before replacement, preserve older primary or backup bytes once as `manual.schema1/2/3.json`. Loading never writes; preservation failures abort replacement.

Keep all **five** fixtures byte-identical; hashes and scenarios in `game/tests/fixtures/README.md`. Schema-3 fixture still tests pending decline; schema-4 fixture tests tick 59 plus fractional time, a park, and prior ledger. Maps 8–128 per dimension; JSON cap 512 KiB; seed/RNG signed-64 decimal strings. User save path `%APPDATA%/OriginalCityBuilder/saves/manual.json` and `.bak`. Preserve and restore all real profile files before/after native tests.

Controls: 1 roads / 2 homes / 6 shops / 7 workshops / P station / 8 park / 3 clear; B budget; 4/5 speed; Space pause; R/E marks; Home centre; Ctrl+S/L; F6. Inspector cap 320 px. Budget scrolls at largest text; Help is tight at 720p. Link/zoom share a row. Automated layouts cover four sizes x three text sizes and toolbar/sidebar separation. Native M2d evidence is one-machine 720p only; DPI, other hardware/OS, controllers, performance targets and enjoyment remain unverified. No CI configured.

```powershell
.\tools\verify.ps1
.\tools\project.ps1 Run
.\tools\package.ps1
```

Packed driver uses the pinned **editor runtime with release PCK**; release EXE does not support external `--script`. Native EXE interaction is separate evidence. Do not call import/startup a gameplay test. M2d detected three intentional faults (unserved taxes, reversed park priority, missing cash floor) and restored source before final verification/export. 128x128 / 250-day local run took about 2.54 s; this is not an 8 ms tick-target pass.

## Next assignment and stop point

The M3 scoping session is complete; see [M3a specification](docs/M3A_SPEC.md) and [scoping record](docs/sessions/2026-11-05-m3a-scope.md). **No M3 game code has been implemented.**

In a subsequent conversation, **“Run next session” authorises implementation of only the M3a specification**: one optional “A welcoming square” project using an existing park and three developed, serviced home plots in its radius. Explicit completion gives an original cosmetic flower decoration; it adds no economic or growth reward. The specification defines exact commands, demolition/repeat behavior, UI, schema-5 migration and acceptance checks. Read it before editing.

1. Reconcile live Git state and create a scoped `codex/` branch; preserve unrelated work. Baseline M2d was delivered at `f2093cb60dbebe3dc7e12fc836ffa5ca749b1c34`. Use live refs for the subsequent planning commit.
2. Implement the specified model/command and strict save migration first, then minimal project dialog, binding and original decoration. Adopt the proposed D28 rules when implementing; record deviations before coding and keep scope bounded.
3. Preserve all five historical fixtures. Run source/packed checks with the pinned toolchain and exercise the actual Windows EXE as specified. Protect/restore real saves, close test processes, record evidence and package the tested export.
4. Update README, Decisions, asset ledger, relevant plans and next handoff. Commit, push, integrate into the live default branch with a fast-forward where possible, and verify local/remote agreement under the standing instruction.
5. Stop after this single verified project. M3's broader onboarding, final art/audio, controller route, autosaves and observed playtests remain future work. No public binary release.

Do not add traffic, crime, pollution, disasters, land markets, citizen agents, extra amenities, or tax policy controls by analogy. M2d's values and park benefit are provisional and have not been tested for enjoyment; changing them requires a decision and meaningful regression tests.

## Completed study boundary

The one U10 source study is complete and its source-reading permission is exhausted. **Never open/read/run the reference checkout or online/reproduced reference source during implementation.** Only `docs/research/MICROPOLIS_STUDY.md` and `docs/DECISIONS.md` may supply reference-study input. The ignored checkout is evidence only; no build scripts/code may run or enter Git/distribution. The study adopted no simulation rules. M2d introduced independent rules through D25–D27 and opened no reference source. Keep the original unnamed game separate; no GPL/root licence or reference branding was added.

No purchases, external messaging, store upload, public release, or additional platform support is implied.
