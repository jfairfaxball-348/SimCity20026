# Next session: record the owner's R6 solo playtest

Updated 7 November 2026 after the R6 kit. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary, the M3b first-steps guide, roadmap R1 (terminology and calendar), R2a (land value), R2b part 1 (levels 0-4), R2c (police and fire), R3 (autosaves, settings and history), R4 (sound sample and animation), R5 (controller route) and the R6 playtest kit are implemented and locally tested. M3 as a whole is incomplete: the owner's solo playtest (U39) is pending.** The ordered [roadmap](docs/ROADMAP.md) (R1-R17) and [gap analysis](docs/GAP_ANALYSIS.md) set the direction. There is no public release and no human enjoyment evidence yet.

## Start here

Read README, AGENTS (including U29 on plain words), docs/DECISIONS.md (all U and D entries, especially U39 and D42), docs/PRODUCT_BRIEF.md (playtest gates), docs/playtest/README.md and PLAYTEST.txt, docs/ROADMAP.md and the session evidence under `docs/sessions/`. Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical. Use a new `codex/` branch for any change.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

The current build is game **0.19.0-r6**, save schema 12, simulation/content `r3-1`, settings version 3 (Godot 4.7.2 through `tools/`). The owner's package is `builds/citybuilder-0.19.0-r6-windows-x64.zip` (local only).

## Assignment

**If the owner has reported their playtest** (notes in the chat, and possibly files copied into `builds/playtest/`):

1. Write an evidence record `docs/sessions/<date>-r6-playtest.md` with the owner's notes (their words where useful, meaning kept), each session's goal and outcome, and anything found in their saves or settings. Do not publish their files.
2. Add a U-entry for the report and a Decisions entry for the R6 result: for each product-brief question, met / partly met / not met **for one player**, with the honest caveat that the owner knows the project's goals.
3. Turn the main problems into a short, ordered fix list and ask the owner whether to fix them before R7 (the delivery plan advises fixing a weak result first). Do not start R7 or large changes without the owner's agreement.
4. Update README, ROADMAP (R6 done or partly done), this handoff and AGENTS; deliver the documentation.

**If the owner has not reported yet**, say so plainly, point them to `PLAYTEST.txt` in the build folder, and ask whether they want to wait or have something else done first. Do not invent results, and do not count any automated run as the playtest.

### Still deferred

The remaining R2b items (wealth effects and art variants, per-level power, demand counted in people) stay for a later balance pass; take them on only if the owner asks (the playtest may say).

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
- **Playtest kit and guidance (D42).** `docs/playtest/PLAYTEST.txt` ships beside the game as `PLAYTEST.txt` (the export and package scripts copy and expect it). The First steps card (`opening_guide.gd` templates filled by `texts(keys)` / `done_text(keys)`) and Help (a generated Your keys block over `help_body`) name the current keys; Open save folder is in Help and the Menu (15 entries) and never opens anything in headless runs.
- **Controller and controls (D41).** `scripts/input/input_bindings.gd` holds every default, the remappable lists (23 keyboard actions, 7 gamepad buttons), the fixed and reserved inputs, `problem()` validation and `install()`; it also adds the gamepad to Godot's `ui_*` actions. Gamepad: stick / d-pad cursor (tile steps, 0.3 s delay then 12 a second), South hold to build, East cancel / close, LB/RB tool, LT/RT zoom, right stick pan, Start pause, West speed, North summary, Back Menu, L3 link. `main.gd` routes gamepad events in `_input` when no dialog is open; every dialog is in `modal_windows` and focuses a button when it opens; the Controls dialog reads a waiting change through its own `window_input`. Prompts sit below the top bar only while the gamepad is in use. Settings version 3 adds `bindings` (changes only). Effects do not play in headless runs (requests are still recorded) so test runs leak no audio playback.
- **Sound and animation (D40).** Five sounds (build, clear, reject, grow once per round, alert on a deficit settlement) and a 12-second, 80 BPM music loop are synthesised at run time by `scripts/presentation/sound_kit.gd` (no audio files); `audio_director.gd` owns the Effects and Music buses, effect players and the background-made music. Volumes Master / Sounds / Music default 80 / 70 / 30%, Mute all and M, in Sound & motion (opened from Display, on a row with Center view). Animation (water shimmer, industry smoke, breathing flag) follows real time at about ten redraws a second and can be turned off. Settings version 2 adds `master_volume`, `effects_volume`, `music_volume`, `muted`, `animation`; version 1 migrates. Every asset is in the `licenses/ASSETS.md` ledger.
- **Autosaves, settings and history (D39).**
  - **Autosaves.** `autosave1-3.json` and `autosave.index` beside the manual save, written while time runs after the frame that passes each multiple of 60 days, rotating 1 → 2 → 3, with the D15 validated write; they never touch `manual.json`, its `.bak` or preserved copies, and do not clear the unsaved flag. With any autosave on disk, Load always opens its dialog, which offers Load autosave (newest valid slot, falling back to older ones).
  - **Settings.** `settings.json`, version 1: window, text size, art, grid, road and power marks, land value and services overlays, `guide_hidden`. Written on each player change, read at start-up; any invalid file gives all defaults. `SettingsStore.override_path` isolates tests (source and packed runs set it).
  - **History.** Each settlement appends `[tick, residents, commercial jobs, industrial jobs, closing cash, net]`, at most 240 records, saved in schema 12; H and Budget → Graphs [H] show three graphs.
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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32/D33/D36/D37/D38/D39 specify; D40 and D41 changed presentation and input only. Each roadmap milestone's decision must state exactly which earlier rules it changes.
- **Owner answers (U31-U34).** Disasters optional and off by default; the no-debt waiver stays the default; target map and population scale match the original game with our own numbers; no later-edition extras for now.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 12 contents.** The schema-11 fields (strict `tax_rate`, ledger `tax_rate` and `police`/`fire` counts, per-cell `footprint_anchor`, development 0-4, IDs up to 8) plus a strictly validated `history`. Land value, freight and cover are derived; settings are never in a save.
  - **Migration.** Schema 11 loads with every value kept and an empty history. Schema 10 loads with every lot kept and zero ledger station counts (its uncovered level-4 lots then drop); schemas 9, 8 and 7 load unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-11.json` before replacement.
  - **Fixtures.** Thirteen fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f-R1 native runs and was restored to that state after each. In the R1 session (started from the Claude desktop app) the redirected `Claude_pzs8sxrjxfjjc` profile and `%APPDATA%` showed the same contents from the shell; both had no `saves` folder before and after.
  - **R6.** The native run wrote no settings or saves except where noted in the R6 record; the profile was restored to no `saves` folder or settings file. Seven older packed-test folders remain under `tests`.
  - **R5.** The native runs wrote only `settings.json` (with the Q remap); it was moved to `builds/validation/r5/profile-saves/`, leaving no `saves` folder or settings file. Seven older packed-test folders remain under `tests` as found.
  - **R4.** The native runs wrote only `settings.json` (no saves); it was moved to `builds/validation/r4/profile-saves/`, leaving no `saves` folder or settings file, as before.
  - **R3.** The native runs also create `settings.json` and autosave files in the profile; record and restore them too. In R3 the profile had no `saves` folder and no `settings.json` before, and again none after.
  - **R2c.** The tested process again resolved `%APPDATA%\OriginalCityBuilder\` (the redirected `Claude_pzs8sxrjxfjjc` profile showed the same contents); no `saves` folder before or after. Seven older packed-test folders from earlier sessions remain under `tests` as found.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/r6/native/native_driver.py` (ignored, copied from R5). It posts keyboard and mouse messages only; it cannot simulate a gamepad. Lots below the road at the right of the default view sit under the inspector; place lots above the road or pan first posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

The R6 kit passed 914 source / 705 exported-PCK checks and release-EXE start-up; thirteen fixtures byte-identical; the package contains PLAYTEST.txt. A posted-window-message run of the actual EXE showed the refreshed First steps card, Help's Your keys block and Open save folder. **No human has played the game yet; the owner's solo playtest is the next evidence.**

Native evidence is 1280x720 on one machine. Human enjoyment and usability, audio quality, a real gamepad, DPI variants, other hardware and operating systems, performance targets and CI remain unverified.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
