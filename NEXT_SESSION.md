# Next session: roadmap R2a, land value for every zone

Updated 6 November 2026 after R1. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary, the M3b first-steps guide and roadmap R1 (terminology and calendar) are implemented and locally tested. M3 as a whole is incomplete.** The ordered [roadmap](docs/ROADMAP.md) (R1-R17) and [gap analysis](docs/GAP_ANALYSIS.md) set the direction; owner answers U31-U34 are recorded. There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS (including U29 on plain words), docs/DECISIONS.md (all U and D entries, especially D33 and D35), docs/ROADMAP.md, docs/GAP_ANALYSIS.md, docs/M2G_SPEC.md, the permitted [study notes](docs/research/MICROPOLIS_STUDY.md) (land value and pollution sections) and the session evidence under `docs/sessions/`. Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch (for example `codex/r2a-land-value`).
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

The current build is game **0.12.0-r1**, save schema 8, simulation/content `m2g-1` (Godot 4.7.2 through `tools/`).

## Assignment: roadmap R2a (land value for every zone)

On **"Run next session"**, write `docs/R2A_SPEC.md`, adopt its rules as D36 in Decisions **before model code** (stating exactly which D26/D33 rules it supersedes), then implement, test and deliver. Proposed game version **0.13.0-r2a**. Choose every number ourselves.

### Scope

1. **A derived land value for every lot.** Replace home-only desirability (D33) with a derived, deterministic **land value** for residential, commercial and industrial lots, computed from:
   - water and parks nearby (the current D33 sources);
   - developed industrial lots nearby (nuisance, as now);
   - a pull towards the developed town (for example distance to the nearest developed lots, or a simple centre of development). Choose a rule that is cheap, explainable per lot and stable;
   - trees stay cosmetic until R7 makes forest real terrain, so they are not a source yet.
2. **Effects, one per type.** Keep the residential D33 order and held/drop behaviour, driven by land value. Give commercial and industrial their own simple preferences (for example commercial prefers higher value and closeness to residents; industrial tolerates low value). Each effect must order growth or hold a lot, never demolish, and always be recoverable.
3. **Overlay and explanations.** V becomes a land-value overlay readable without colour; the inspector lists each lot's parts; the town summary held item names the type; Help, the guide and BUILD_README match.
4. **Saves.** Prefer a derived field with no new saved data (schema 8 kept; bump the simulation/content version, for example `r2a-1`, only if the rules change meaning). If a schema change is needed, add schema 9 with strict validation, migration of schema 8 keeping every lot, and preservation of the old bytes; keep all nine fixtures byte-identical and add a fixture.

### Acceptance

- Unit tests for every source, distance, cap and type effect; purity and determinism; recovery after clearing a nuisance; migration of every fixture.
- Packed tests through the shipped UI, including the overlay and inspector at every layout and text size.
- `tools/verify.ps1` passes; a native posted-input run of the actual EXE shows the overlay and a held or reordered lot of each type; profile restored.
- Update README, Decisions, ROADMAP (R2a done), an evidence record and this handoff so the next "Run next session" starts **R2b (density stages and wealth)**, then deliver. No purchases, external messages or public release.

## Preserve the current contract

- **Lots and stations (D30).** Homes, shops and workshops are 3x3 lots anchored at their top-left tile, each replacing a single-tile plot one-for-one ($25, one power unit, levels 0-2). Power stations are 4x4, one per placement, with price, capacity and upkeep counted per station. Parks stay one tile. Access and power reach a lot through any side-sharing perimeter tile; corner contact does not count. Clearing any tile removes the whole footprint. Zone tools centre a lot on the pointer, and a drag lays a straight run of lots.
- **Taxes and demand (D32).**
  - **Rate and taxes.** The town rate is 0-25%, standard 10%. That is 20/40 cents per point per serviced resident/job at settlement, so 10% equals D25.
  - **Appeal.** 100 + 4 × (10 − rate) percent, applied to the D22 targets with half-up rounding.
  - **Leaving.** Above 10% only: at most 4 levels per type per round, level 2 first, then later map order, from serviced lots, never removing zones.
  - **Interface.** The meter sits under the population count and the tax row is in Budget [B].
- **Desirability (D33).**
  - **Score.** Each home lot scores +2 for a park within 3 (no stacking), +1 for water within 3, and −2 for each developed workshop lot within 2 (up to three). Distances are footprint to footprint.
  - **Order.** Higher-scoring homes reserve growth first, then map order.
  - **Held homes.** Below 0 a home is held at level 1. Serviced level-2 homes drop one level per round, and the drops count towards D32 leaving.
  - **Overlay.** V or Display; never saved.
  - **Scope.** Shops and workshops have no score yet.
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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32/D33 specify. Each roadmap milestone's decision must state exactly which earlier rules it changes.
- **Owner answers (U31-U34).** Disasters optional and off by default; the no-debt waiver stays the default; target map and population scale match the original game with our own numbers; no later-edition extras for now.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 8 contents.** The same fields as schema 7: a strict `tax_rate`, a ledger `tax_rate`, and the per-cell `footprint_anchor` array. Desirability is derived.
  - **Migration.** Schema 7 loads unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-7.json` before replacement.
  - **Fixtures.** Nine fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f-R1 native runs and was restored to that state after each. In the R1 session (started from the Claude desktop app) the redirected `Claude_pzs8sxrjxfjjc` profile and `%APPDATA%` showed the same contents from the shell; both had no `saves` folder before and after.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/r1/native/native_driver.py` (ignored, copied from M3b, with V, T and F1) posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

R1 passed 683 source / 571 exported-PCK checks and release-EXE start-up; nine fixtures byte-identical. A posted-window-message run of the actual EXE showed 1 Jan 1950 and the R/C/I wording at launch, grew a street into February at 3x, showed Budget naming the forecast month and the closed January settlement, showed the dated town summary, saved, restarted, loaded (7 Feb 1950 restored) and checked the largest text. In that run the commercial and industrial clicks did not place lots (pointer offsets), which does not affect R1; packed tests cover every lot type.

Native evidence is 1280x720 on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
