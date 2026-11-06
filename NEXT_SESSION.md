# Next session: roadmap R1, terminology and calendar

Updated 6 November 2026 after the U30 planning session. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary and the M3b first-steps guide are implemented and locally tested. M3 as a whole is incomplete.** The [gap analysis](docs/GAP_ANALYSIS.md) and the ordered [roadmap](docs/ROADMAP.md) (R1-R17) are written; owner answers U31-U34 are recorded. There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS (including U29 on plain words), docs/DECISIONS.md (all U and D entries), docs/ROADMAP.md, docs/GAP_ANALYSIS.md, docs/PRODUCT_BRIEF.md, the permitted [study notes](docs/research/MICROPOLIS_STUDY.md) and the session evidence under `docs/sessions/`. Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch (for example `codex/r1-terms-calendar`).
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

The current build is game 0.11.0-m3b, save schema 8, simulation/content `m2g-1` (Godot 4.7.2 through `tools/`).

## Assignment: roadmap R1 (terminology and calendar)

On **"Run next session"**, specify, adopt (as D35 in Decisions, before code), implement, test and deliver R1. Proposed game version **0.12.0-r1**. Scope:

### 1. Terminology (U29)

- Player-facing **Residential / Commercial / Industrial** (zones, lots, blocks) in place of Homes / Shops / Workshops everywhere a player reads it: sidebar tools and tooltips, inspector, Budget, demand meter (**R / C / I** in place of H / S / W), town summary items, First steps card, project dialog, Help, status lines and load messages; README controls table and player text.
- "Power station" may stay or become "power plant"; choose one and use it consistently. "Workshop nuisance" becomes industrial nuisance (or pollution, if the wording stays honest about what is modelled).
- **Unchanged:** key bindings (2 / 6 / 7), internal identifiers and command names (`home`, `shop`, `workshop`), occupancy IDs, save fields, content version and every rule. This is wording only.
- Every changed string must fit at every supported layout and text size (existing layout checks), and tests that match text must be updated rather than weakened.

### 2. Calendar

- Show a **month and year** in place of the bare day count, derived from the tick: months stay the D25 30-day month, 12 months a year. Choose our own start year and record it in D35 (not the reference game's).
- The Budget forecast and last settlement name the month they cover. The tick, clock order, settlement timing and saves are unchanged; no schema change.
- Tests: month and year boundaries, the first settlement month, very large ticks, and load continuity.

### 3. Evidence and delivery

Run `tools/verify.ps1` (source, exported PCK, release-EXE start-up), confirm the nine fixtures stay byte-identical, and do a native posted-input check of the actual EXE at 720p and largest text. Update README, Decisions (D35 and change record), ROADMAP (R1 done), the evidence record under `docs/sessions/`, and this handoff so the next "Run next session" starts **R2a (land value for every zone)**. Then deliver under the standing instruction. No purchases, external messages or public release.

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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32 specifies. R1 changes no rule; each later roadmap milestone's decision must state exactly which earlier rules it changes.
- **Owner answers (U31-U34).** Disasters optional and off by default; the no-debt waiver stays the default; target map and population scale match the original game with our own numbers; no later-edition extras for now.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 8 contents.** The same fields as schema 7: a strict `tax_rate`, a ledger `tax_rate`, and the per-cell `footprint_anchor` array. Desirability is derived.
  - **Migration.** Schema 7 loads unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-7.json` before replacement.
  - **Fixtures.** Nine fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f-M3b native runs and was restored to that state after each.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/m3b/native/native_driver.py` (ignored, with V, T and F1 added) posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

M3b passed 669 source / 562 exported-PCK checks and release-EXE start-up.

A posted-window-message walkthrough of the actual EXE followed the card from the empty town to Done using its text and Show. It also covered:

- Close, F1 and Help re-entry;
- save, restart (the card returns) and load (the steps are rechecked);
- the card at the largest text.

Native evidence is 1280x720 on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
