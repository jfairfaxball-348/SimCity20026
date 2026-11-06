# Next session: refresh and implement the M3b first-steps guide

Updated 6 November 2026 after M2h. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability and the M2h town summary are implemented and locally tested. The owner-scheduled city-builder systems (U24) are complete. The M3b guide is specified (proposed D29) but needs the refresh below before adoption. M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16-U27, D29-D34), docs/TOOLCHAIN.md, [the M3b specification](docs/M3B_SPEC.md), the [M2h specification](docs/M2H_SPEC.md) and [M2h evidence](docs/sessions/2026-11-06-m2h.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical; use live history for delivered commits. The M2h work branch was `codex/m2h-town-summary`. Create a new `codex/` branch for the next work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.10.0-m2h, save schema 8, simulation/content `m2g-1`. The export EXE/PCK and `builds/citybuilder-0.10.0-m2h-windows-x64.zip` are local, ignored and unpublished.

**Artwork note:** Kenney Roguelike Modern City is the default style (U22/U23); the original renderer is the fallback. The guide's bracket marker should fit Modern City.

## Roadmap status (U24)

| Order | Milestone | Status |
| --- | --- | --- |
| 1 | M2f | **Done (0.8.0-m2f):** demand meter and adjustable tax rate |
| 2 | M2g | **Done (0.9.0-m2g):** home desirability, workshop nuisance and the V overlay |
| 3 | M2h | **Done (0.10.0-m2h):** town summary (T) |
| 4 | **M3b guide (next)** | The deferred first-steps guide, refreshed for M2f-M2h |

After M3b the owner's roadmap is complete. On the following "Run next session", ask the owner one question before choosing further work:

- civic services (5);
- traffic (6);
- desirability for shops and workshops, or nuisance from stations;
- remaining M3 bundle items (autosaves, controller route, coherent audio);
- preparing the five-person M3 playtest.

Optional hazards (8) come only if the owner asks.

## Assignment

On a subsequent **"Run next session"**, do M3b. Do not ask the guide-or-candidate question: the owner has answered it (U24).

1. **Refresh, then adopt.** Update `docs/M3B_SPEC.md` for the current game, then adopt D29 (amended) in Decisions before code.
   - **Steps.** Keep five ordered steps from the specification, with lot wording (its M2e dependency section). Step 4 ("grow a home") may point at the H/S/W meter. Step 5 (the optional project) may also mention the town summary (T).
   - **Keys.** Check that every key named is still free and correct: T, V and F1 are now used or claimed (F1 by the guide itself).
   - **Layout.** The card must not cover the meter, the status-bar summary button, the flag or the wider inspector at text 18/20 (480/520 px).
   - **Version.** Game `0.11.0-m3b`, schema 8 / `m2g-1` unchanged, no save change. The guide is session-only, as specified.
2. **Build exactly as refreshed.** Build the card, F1 and Help re-entry, Show and the bracket marker. No file under `sim/`, `persistence/` or `content/` changes.
3. **Test.** Meet the refreshed acceptance checklist. Run pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. Record actual counts, artifact hashes and limits.
4. **Hand off.** Update README, Decisions, the asset ledger and this handoff (asking the owner's next-direction question), then deliver under the standing instruction.

**Stop after M3b.** Do not start further systems, balance tuning, final art/audio, the controller route or autosaves.

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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32 specifies. M3b's guide must change no simulation rule or save.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 8 contents.** The same fields as schema 7: a strict `tax_rate`, a ledger `tax_rate`, and the per-cell `footprint_anchor` array. Desirability is derived.
  - **Migration.** Schema 7 loads unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-7.json` before replacement.
  - **Fixtures.** Nine fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f-M2h native runs and was restored to that state after each.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/m2h/native/native_driver.py` (ignored, with V and T added) posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

M2h passed 629 source / 502 exported-PCK checks and release-EXE start-up.

A posted-window-message run of the actual EXE covered:

- a pointer-built street grown at 3x until a home was held;
- T opening the summary led by the held home;
- its Show action centring and inspecting that home;
- the status-bar button.

A final smoke run used the packaged export.

Native evidence is 1280x720 at standard text on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
