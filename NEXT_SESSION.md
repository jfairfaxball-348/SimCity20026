# Next session: roadmap R2b, density stages and wealth

Updated 6 November 2026 after R2a. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary, the M3b first-steps guide, roadmap R1 (terminology and calendar) and R2a (land value) are implemented and locally tested. M3 as a whole is incomplete.** The ordered [roadmap](docs/ROADMAP.md) (R1-R17) and [gap analysis](docs/GAP_ANALYSIS.md) set the direction; owner answers U31-U34 are recorded (U33: target scale matches the original game, with our own numbers). There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS (including U29 on plain words), docs/DECISIONS.md (all U and D entries, especially D22, D32, D33, D36), docs/ROADMAP.md, docs/GAP_ANALYSIS.md, docs/R2A_SPEC.md, the permitted [study notes](docs/research/MICROPOLIS_STUDY.md) and the session evidence under `docs/sessions/`. Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch (for example `codex/r2b-density`).
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

The current build is game **0.13.0-r2a**, save schema 9, simulation/content `r2a-1` (Godot 4.7.2 through `tools/`).

## Assignment: roadmap R2b (density stages and wealth)

On **"Run next session"**, write `docs/R2B_SPEC.md`, adopt its rules as D37 in Decisions **before model code** (stating exactly which D22/D23/D25/D32/D33/D36 numbers it changes), then implement, test and deliver. Proposed game version **0.14.0-r2b**. Choose every number ourselves. R2b may take two or three sessions; if so, deliver a coherent, tested first part and hand off the rest.

### Scope

1. **More levels.** Raise zone development from 0-2 to our own higher range (proposed 0-4) with larger capacities per level, so a fully serviced town keeps growing into hundreds and then thousands of residents (U33). Decide how levels map to residents, jobs, power use and tax, and rebalance the D22 demand targets so growth does not stall at the old ceiling.
2. **Land value gates.** Use R2a land value for the upper levels (for example a lot needs a minimum value for level 3 and higher for level 4) with clear inspector reasons. Keep every hold recoverable and never demolish.
3. **Wealth.** Give each developed residential lot a derived or stored wealth band (for example low / middle / high) from land value; decide whether it affects tax or only appearance, and explain it.
4. **Art.** Original lot art for each new stage (and wealth variants if they show) in the default Modern City mode and the original fallback; fits 16 px cells; asset ledger updated.
5. **Saves.** Schema **10** with the wider level range (and wealth if stored), strict validation, migration of schema 9 keeping every level, preservation of old bytes; ten fixtures byte-identical plus a new fixture.
6. **Check later systems.** Power demand per lot, budget totals, the summary, the guide and the project still read correctly with more levels.

### Acceptance

- Unit tests for every level boundary, capacity, gate, decline, leaving, migration and determinism; a long-run test town grows past the old 40-48 resident ceiling and settles predictably.
- Packed tests through the shipped UI at every layout and text size; `tools/verify.ps1` passes; a native posted-input run of the actual EXE shows the new stages; profile restored.
- Update README, Decisions, ROADMAP (R2b done or part done), an evidence record and this handoff so the next "Run next session" starts **R2c (police and fire)** or the rest of R2b, then deliver. No purchases, external messages or public release.

## Preserve the current contract

- **Lots and stations (D30).** Homes, shops and workshops are 3x3 lots anchored at their top-left tile, each replacing a single-tile plot one-for-one ($25, one power unit, levels 0-2). Power stations are 4x4, one per placement, with price, capacity and upkeep counted per station. Parks stay one tile. Access and power reach a lot through any side-sharing perimeter tile; corner contact does not count. Clearing any tile removes the whole footprint. Zone tools centre a lot on the pointer, and a drag lays a straight run of lots.
- **Taxes and demand (D32).**
  - **Rate and taxes.** The town rate is 0-25%, standard 10%. That is 20/40 cents per point per serviced resident/job at settlement, so 10% equals D25.
  - **Appeal.** 100 + 4 × (10 − rate) percent, applied to the D22 targets with half-up rounding.
  - **Leaving.** Above 10% only: at most 4 levels per type per round, level 2 first, then later map order, from serviced lots, never removing zones.
  - **Interface.** The meter sits under the population count and the tax row is in Budget [B].
- **Land value (D33/D36).**
  - **Field.** +2 for a park within 3 (no stacking), +1 for water within 3, −2 for each developed industrial lot within 2 (up to three). Distances are footprint to footprint.
  - **Lots.** Residential: the field. Commercial: the field plus trade, +1 per developed residential lot within 3, up to +2. Industrial: park and water only (no effect).
  - **Order.** Residential and commercial lots with higher value reserve growth first; industry by fewest road steps from the link road; then map order.
  - **Held.** Residential and commercial lots below 0 are held at level 1; serviced level-2 lots drop one level per round, and drops count towards that type's D32 leaving.
  - **Overlay.** V or Display (Land value); never saved. Derived in `scripts/sim/desirability.gd` (module name kept).
- **Town summary (D34).**
  - **What it is.** A pure, read-only ranking of measurable blockers, opened with T or the status-bar button. It shows at most five, by levels affected, followed by a deficit item and status items.
  - **Actions.** Show centres on and inspects an example; Budget opens Budget.
  - **No side effects.** No rule or save change.
- **First steps (D29, refreshed).**
  - **What it is.** A session-only card at the bottom left of the map showing the first unmet of five steps, derived from the town plus a project-opened flag.
  - **Routes.** Show and a footprint bracket; Hide/Close; F1 and Help's Show first steps.
  - **No side effects.** It saves nothing, never pauses time and never locks tools.
  - **Packed tests.** Feature flows hide the card (`fresh_scene(…, guide = false)`), and `guide_flow` tests it shown.
- **Wording and calendar (D35).** Player-facing text says Residential / Commercial / Industrial lots and power plant; the meter reads R / C / I. Internal identifiers (`home`, `shop`, `workshop`, `power`), keys and save fields are unchanged. The calendar is derived from the tick (tick 0 = 1 Jan 1950, 30-day months, 12-month years) by `scripts/presentation/calendar.gd` and never saved.
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32/D33/D36 specify. Each roadmap milestone's decision must state exactly which earlier rules it changes.
- **Owner answers (U31-U34).** Disasters optional and off by default; the no-debt waiver stays the default; target map and population scale match the original game with our own numbers; no later-edition extras for now.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 9 contents.** The same fields as schemas 7 and 8: a strict `tax_rate`, a ledger `tax_rate`, and the per-cell `footprint_anchor` array. Land value and freight are derived.
  - **Migration.** Schemas 8 and 7 load unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-8.json` before replacement.
  - **Fixtures.** Ten fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f-R1 native runs and was restored to that state after each. In the R1 session (started from the Claude desktop app) the redirected `Claude_pzs8sxrjxfjjc` profile and `%APPDATA%` showed the same contents from the shell; both had no `saves` folder before and after.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/r2a/native/native_driver.py` (ignored, copied from M3b, with V, T and F1). Lots below the road at the right of the default view sit under the inspector; place lots above the road or pan first posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

R2a passed 716 source / 577 exported-PCK checks and release-EXE start-up; nine earlier fixtures byte-identical and a tenth added. A posted-window-message run of the actual EXE built a row of residential, commercial and industrial lots above the flag street; the industrial lot nearest the link developed first, the overlay showed trade on a commercial lot and hatching beside industry, the summary listed a held residential lot, and a schema-9 save was written. That run did not show a held commercial lot (it never reached level 1); packed tests cover it. Hover inspection was not used natively.

Native evidence is 1280x720 on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
