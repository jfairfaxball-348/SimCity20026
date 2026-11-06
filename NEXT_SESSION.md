# Next session: ask the owner for the next direction

Updated 6 November 2026 after M3b. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary and the M3b first-steps guide are implemented and locally tested. The owner's U24 roadmap is complete. M3 as a whole is incomplete:** the five-person observed test, coherent original sample audio, the full controller route and autosaves remain. There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16-U28, D29-D34), docs/TOOLCHAIN.md, [genre candidates](docs/GENRE_ALIGNMENT.md), the [delivery plan](docs/DELIVERY_PLAN.md) and [M3b evidence](docs/sessions/2026-11-06-m3b.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical; use live history for delivered commits. The M3b work branch was `codex/m3b-first-steps`. Create a new `codex/` branch for the next work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.11.0-m3b, save schema 8, simulation/content `m2g-1`. The export EXE/PCK and `builds/citybuilder-0.11.0-m3b-windows-x64.zip` are local, ignored and unpublished.

**Artwork note:** Kenney Roguelike Modern City is the default style (U22/U23); the original renderer is the fallback.

## Assignment

On a subsequent **"Run next session"**, first ask the owner **one question**: which direction comes next? Offer these options:

1. **Civic services (recommended next gameplay system, candidate 5).** One or two coverage buildings with upkeep (for example a clinic or school) that raise home desirability or a growth cap nearby. Explained per lot, with no crime-as-danger or destruction.
2. **Traffic (candidate 6).** Busy roads become visible, and congestion can slow growth. It is large, and it revises the product brief's routing exclusion.
3. **Desirability for shops and workshops**, or nuisance from power stations: a smaller extension of D33.
4. **M3 bundle items.** Autosaves with remembered settings (including remembering the guide's dismissal), the full controller route, or coherent original sample audio.
5. **Prepare the five-person M3 playtest.** A test plan and build only; recruitment and external messages still need separate owner authorisation.

If the owner says "you choose", do option 1.

For the chosen item, follow the milestone pattern:

1. Write its specification and adopt its rules in Decisions before code, using this project's own numbers, wording and art.
2. Implement it with tests.
3. Run pinned `tools/verify.ps1`, the native EXE checks and `tools/package.ps1`.
4. Record evidence, update the README, Decisions and this handoff, and deliver under the standing instruction.

Bump the game version (`0.12.0-…`). Bump the schema only if saved meaning changes.

**Stop after that one item.**

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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32 specifies. The next item's decision must state exactly which earlier rules it changes.
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
