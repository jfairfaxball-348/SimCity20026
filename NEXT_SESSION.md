# Next session: M2g neighbourhood desirability and workshop nuisance

Updated 6 November 2026 after M2f. **M0/M1 through M2d, the M3a project, M2e zone lots and M2f taxes are implemented and locally tested. M2g is planned, not yet specified or implemented. The M3b guide is specified but deferred (U24). M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16-U25, D22, D25, D26, D29-D32), docs/TOOLCHAIN.md, [genre candidates](docs/GENRE_ALIGNMENT.md), the permitted [study notes](docs/research/MICROPOLIS_STUDY.md), the [M2f specification](docs/M2F_SPEC.md) and [M2f evidence](docs/sessions/2026-11-06-m2f.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical; use live history for delivered commits. The M2f work branch was `codex/m2f-tax-demand`. Create a new `codex/` branch for the next work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.8.0-m2f, save schema 7, simulation/content `m2f-1`. The export EXE/PCK and `builds/citybuilder-0.8.0-m2f-windows-x64.zip` are local, ignored and unpublished.

**Artwork note:** Kenney Roguelike Modern City is the default style (U22/U23); the original renderer is the fallback. New presentation work, including M2g's overlay, should fit Modern City rather than adding new geometric placeholders.

## City-builder roadmap (U24)

Each **"Run next session"** delivers one milestone, in this order (candidate numbers refer to [the genre table](docs/GENRE_ALIGNMENT.md)):

| Order | Milestone | Candidates | Status |
| --- | --- | --- | --- |
| 1 | M2f | 9 + 4 | **Done (0.8.0-m2f):** demand meter and adjustable tax rate |
| 2 | **M2g (next)** | 2 + 3 | Neighbourhood desirability with a visible overlay: parks help, and workshops hold back nearby homes, so separating zones matters |
| 3 | M2h | 7 | A short town summary naming the measurable causes holding the town back |
| 4 | M3b guide | - | The deferred first-steps guide, its steps refreshed for M2f-M2h |

Civic services (5) and traffic (6) come later, each when the owner asks for it. Optional hazards (8) come only if the owner asks, opt-in and never in the default mode. The owner may reorder at any time.

## Assignment

On a subsequent **"Run next session"**, do M2g. Do not ask the guide-or-candidate question: the owner has answered it (U24).

1. **Specify first.** Write `docs/M2G_SPEC.md` and adopt its rules as D33 in Decisions before code. Use this project's own numbers, layout and wording. U18 prefers the choice closest to the classic genre where options differ, but never reference formulas, tables, constants, text or screen composition (see the rights section). Ask the owner only about a choice that is genuinely theirs.
   - **Desirability.** A derived, deterministic per-lot score from nearby surroundings: parks raise it, and workshops lower it for homes. Water or trees may count if the spec justifies them. It changes which lots grow first and how far they can develop; it adds no new demand. Explain it per lot in the inspector.
   - **Workshop nuisance.** Homes near workshops grow more slowly or develop less. The effect is visible at its sources, explained and recoverable: moving or clearing the workshop, or adding a park, restores growth. It never destroys anything.
   - **Overlay.** A toggleable map overlay (with an unused key and a sidebar or Display control) shows desirability without relying on colour alone, at every supported size and text size.
   - **Interactions.** The tax appeal and leaving rules (D32), park priority (D26) and the project (D28) must stay consistent. State exactly what D33 supersedes.
2. **Saves.** Prefer keeping desirability derived. If the rules change how a saved schema-7 town evolves, decide in D33 whether to bump simulation/content and the schema (D20 pattern: earlier towns migrate and are preserved). Existing fixtures stay byte-identical.
3. **Build and test.** Do the model first, then the overlay and explanations. Test determinism, growth order, recovery, saves and packed flows. Run pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. The game version becomes `0.9.0-m2g`. Record actual counts, artifact hashes and limits.
4. Update README, Decisions, the genre table and this handoff (pointing at M2h), then deliver under the standing instruction.

**Stop after M2g.** Do not start M2h, other candidates, the guide, unrelated balance tuning, final art/audio, the controller route or autosaves.

## Preserve the current contract

- **Lots and stations (D30).** Homes, shops and workshops are 3x3 lots anchored at their top-left tile, each replacing a single-tile plot one-for-one ($25, one power unit, levels 0-2). Power stations are 4x4, one per placement, with price, capacity and upkeep counted per station. Parks stay one tile. Access and power reach a lot through any side-sharing perimeter tile; corner contact does not count. Clearing any tile removes the whole footprint. Zone tools centre a lot on the pointer, and a drag lays a straight run of lots.
- **Taxes and demand (D32).**
  - **Rate and taxes.** The town rate is 0-25%, standard 10%. That is 20/40 cents per point per serviced resident/job at settlement, so 10% equals D25.
  - **Appeal.** 100 + 4 × (10 − rate) percent, applied to the D22 targets with half-up rounding.
  - **Leaving.** Above 10% only: at most 4 levels per type per round, level 2 first, then later map order, from serviced lots, never removing zones.
  - **Interface.** The meter sits under the population count and the tax row is in Budget [B].
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32 specifies. M2g's D33 may change only the growth rules it specifies.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 7 contents.** A strict `tax_rate`, a ledger `tax_rate`, and the per-cell `footprint_anchor` array.
  - **Migration.** Schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-6.json` before replacement.
  - **Fixtures.** Eight fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before M2f's native run and was restored to that state.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/m2f/native/native_driver.py` (ignored) posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

M2f passed 565 source / 457 exported-PCK checks and release-EXE start-up.

A posted-window-message run of the actual EXE covered:

- loading a schema-6 town;
- raising the tax to 15% through the Budget buttons, and the meter showing leaving;
- time at 3x shrinking the town to its 15% equilibrium;
- saving schema 7 with a byte-identical schema-6 original;
- restart/load.

A final smoke run on the packaged export checked the format-6 load message and the meter at 15% and 0%.

Native evidence is 1280x720 at standard text on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
