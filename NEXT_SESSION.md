# Next session: roadmap R3, autosaves, settings and history

Updated 6 November 2026 after R2c. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary, the M3b first-steps guide, roadmap R1 (terminology and calendar), R2a (land value), R2b part 1 (levels 0-4) and R2c (police and fire) are implemented and locally tested. M3 as a whole is incomplete.** The ordered [roadmap](docs/ROADMAP.md) (R1-R17) and [gap analysis](docs/GAP_ANALYSIS.md) set the direction; owner answers U31-U34 are recorded. There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS (including U29 on plain words), docs/DECISIONS.md (all U and D entries, especially D15, D20, D27, D29, D38), docs/ROADMAP.md, docs/R2C_SPEC.md and the session evidence under `docs/sessions/`. Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch (for example `codex/r3-autosave-history`).
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

The current build is game **0.15.0-r2c**, save schema 11, simulation/content `r2c-1` (Godot 4.7.2 through `tools/`).

## Assignment: roadmap R3 (autosaves, settings and history)

On **"Run next session"**, write `docs/R3_SPEC.md`, adopt its rules as D39 in Decisions **before code** (stating exactly which D15/D20/D27/D29 rules it changes), then implement, test and deliver. Proposed game version **0.16.0-r3**. Choose every number ourselves.

### Scope

1. **Autosaves.** Rotating autosave slots beside the manual save, at our own interval (in game months or real minutes) and count. An autosave never replaces or rotates the manual slot or its backup, uses the same validated temporary write, and is skipped (with a quiet status) when nothing changed. Load offers the manual save or the newest valid autosave; a corrupt autosave falls back to an older one.
2. **Settings file.** A separate, versioned settings file remembering window size, text size, art mode, overlay toggles (grid, road and power marks, land value, services) and First steps dismissal (this revisits the D29 session-only rule). Corrupt, unknown-version or out-of-range settings fall back to defaults without touching saves.
3. **History.** Per-month records (population, jobs, funds, net, and per-type levels or residents) appended at each D25 settlement, bounded in length so the largest map stays well under the 512 KiB save cap (raise the cap only by decision). Schema **12** with strict validation; schema 11 migrates with an empty history.
4. **Graphs dialog.** A key and button opening simple original line graphs of the history, using the R1 calendar for month and year labels, readable without colour, fitting 720p at every text size.
5. **Interface and docs.** Help, BUILD_README, README; Budget may link to Graphs. Save preservation (`manual.schemaN.json`) continues.

### Acceptance

- Unit tests for autosave rotation and the manual-slot guarantee, settings fallback, history bounds and exact values at settlements, migration of all twelve fixtures (byte-identical) plus a new schema-12 fixture, and determinism (history never consumes RNG).
- Packed tests through the shipped UI at every layout and text size; `tools/verify.ps1` passes; a native posted-input run of the actual EXE showing an autosave, remembered settings after a restart and the Graphs dialog; profile restored (settings and autosave files included).
- Update README, Decisions, ROADMAP (R3 done), an evidence record and this handoff so the next "Run next session" starts **R4 (sound sample and animation)**, then deliver. No purchases, external messages or public release.

### Still deferred

The remaining R2b items (wealth effects and art variants, per-level power, demand counted in people) stay for a later balance pass; take them on only if the owner asks.

## Preserve the current contract

- **Lots and stations (D30).** Homes, shops and workshops are 3x3 lots anchored at their top-left tile, each replacing a single-tile plot one-for-one ($25, one power unit at every level). Power stations are 4x4, one per placement, with price, capacity and upkeep counted per station. Parks stay one tile. Access and power reach a lot through any side-sharing perimeter tile; corner contact does not count. Clearing any tile removes the whole footprint. Zone tools centre a lot on the pointer, and a drag lays a straight run of lots.
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
- **Police and fire (D38).** Police (ID 7) and fire (ID 8) stations are 3x3, $400, $30 a month each (counted per station, working or not), keys 9 and 0, placed one at a time. A station works with a connected road beside it and one power unit, drawn with zone lots in the nearest-first order. A working station covers zone lots within 12 side-steps footprint to footprint (terrain ignored, no stacking); derived in `scripts/sim/services.gd`, never saved. Level 4 for every zone type also needs police and fire cover; a lot above the new cap drops one level per round, counted with D32 leaving. Services overlay C (square police, triangle fire, cross not working); with it on, a lot's legend shows its cover. Summary items `uncovered` and `idle_station`. Park, Police and Fire share one sidebar row.
- **Levels (D37).** Levels 0-4; per-lot capacity residential 0/4/8/20/40, commercial 0/2/4/10/20, industrial 0/4/8/16/28 (`Balance.capacity`). Caps: below 0 held at 1; otherwise level 2 unless residential value ≥1 (L3) / ≥2 (L4), commercial ≥3 / ≥4, industry 100 / 250 town residents. Lots above their cap drop one level per round (counted with D32 leaving); leaving takes the highest levels first. Wealth (modest / comfortable / well-off) is display-only. Original stage art plus yellow pips (one for L3, two for L4) in all art modes.
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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32/D33/D36/D37/D38 specify. Each roadmap milestone's decision must state exactly which earlier rules it changes.
- **Owner answers (U31-U34).** Disasters optional and off by default; the no-debt waiver stays the default; target map and population scale match the original game with our own numbers; no later-edition extras for now.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 11 contents.** The schema-10 fields (strict `tax_rate`, ledger `tax_rate`, per-cell `footprint_anchor`, development 0-4) plus occupancy IDs 7-8 as whole 3x3 footprints and ledger counts `police` and `fire`. Land value, freight and cover are derived.
  - **Migration.** Schema 10 loads with every lot kept and zero ledger station counts (its uncovered level-4 lots then drop); schemas 9, 8 and 7 load unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-10.json` before replacement.
  - **Fixtures.** Twelve fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f-R1 native runs and was restored to that state after each. In the R1 session (started from the Claude desktop app) the redirected `Claude_pzs8sxrjxfjjc` profile and `%APPDATA%` showed the same contents from the shell; both had no `saves` folder before and after.
  - **R2c.** The tested process again resolved `%APPDATA%\OriginalCityBuilder\` (the redirected `Claude_pzs8sxrjxfjjc` profile showed the same contents); no `saves` folder before or after. Seven older packed-test folders from earlier sessions remain under `tests` as found.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/r2c/native/native_driver.py` (ignored, copied from R2b, with 9, 0, C and Enter added). Lots below the road at the right of the default view sit under the inspector; place lots above the road or pan first posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

R2c passed 800 source / 612 exported-PCK checks and release-EXE start-up; eleven earlier fixtures byte-identical and a twelfth added. A posted-window-message run of the actual EXE built a street with two parks, stopped at level 3 with the summary "2 lots need police and fire cover to reach level 4", placed both stations by keys and clicks, showed the Services overlay, reached level 4 (72 residents), showed both Budget lines, saved schema 11 and reloaded it after a restart. Three layout fixes came from the packed checks during implementation (a shared sidebar row, cover in the legend only with the overlay, a shorter idle text).

Native evidence is 1280x720 on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
