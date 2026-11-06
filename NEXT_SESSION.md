# Next session: M2f demand meter and tax rate

Updated 6 November 2026 after the owner chose the city-builder route (U24). **M0/M1 through M2d, the M3a project and M2e zone lots are implemented and locally tested. M2f is planned, not yet specified or implemented. The M3b guide is specified but deferred (U24). M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16-U24, D22, D25, D29-D31), docs/TOOLCHAIN.md, [genre candidates](docs/GENRE_ALIGNMENT.md), the permitted [study notes](docs/research/MICROPOLIS_STUDY.md) and [M2e evidence](docs/sessions/2026-11-06-m2e.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical; use live history for delivered commits. Create a new `codex/` branch for the next work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.7.1-m2e, save schema 6, simulation/content `m2e-1`. The export EXE/PCK and `builds/citybuilder-0.7.1-m2e-windows-x64.zip` are local, ignored and unpublished.

**Artwork note (6 November 2026):** two CC0 Kenney packs were evaluated in-game and retained; see [the artwork evaluation](docs/artwork-review/ARTWORK_EVALUATION.md). The owner chose **Roguelike Modern City** (U22), and since 0.7.1-m2e it is the default style (U23); the original renderer is the fallback. New presentation work, including M2f's demand meter and tax control, should fit Modern City (using its sprites where they suit) rather than adding new geometric placeholders.

## City-builder roadmap (U24)

The owner chose to build the classic city-builder systems before the guide. Each **"Run next session"** delivers one milestone, in this order (candidate numbers refer to [the genre table](docs/GENRE_ALIGNMENT.md)):

| Order | Milestone | Candidates | What the player gets |
| --- | --- | --- | --- |
| 1 | **M2f (next)** | 9 + 4 | A demand meter for homes, shops and workshops, and an adjustable tax rate that trades income against growth |
| 2 | M2g | 2 + 3 | Neighbourhood desirability with a visible overlay: parks help, and workshops hold back nearby homes, so separating zones matters |
| 3 | M2h | 7 | A short town summary naming the measurable causes holding the town back |
| 4 | M3b guide | - | The deferred first-steps guide, its steps refreshed for M2f-M2h |

Civic services (5) and traffic (6) come later, each when the owner asks for it. Optional hazards (8) come only if the owner asks, opt-in and never in the default mode. The owner may reorder at any time.

Why this order: M2f is small and builds on the existing demand and budget rules, so the player quickly gets a read-out of what the town needs and a real economic choice. M2g is the larger growth change, and its effects are easier to read with the meter in place. M2h explains the combined systems, and the guide comes last so it teaches the finished loop.

## Assignment

On a subsequent **"Run next session"**, do M2f. Do not ask the guide-or-candidate question: the owner has answered it (U24).

1. **Specify first.** Write `docs/M2F_SPEC.md` and adopt its rules as D32 in Decisions before code. Use this project's own numbers, layout and wording. U18 prefers the choice closest to the classic genre where options differ, but never reference formulas, tables, constants, text or screen composition (see the rights section). Ask the owner only about a choice that is genuinely theirs.
   - **Demand meter.** Always-visible home, shop and workshop demand, derived from the existing D22 demand. It must be readable without relying on colour and at every text size, and must not hide the flag, inspector or tools.
   - **Tax rate.** A validated, ordered command sets the town's rate within its own range. The default reproduces today's D25 taxes exactly, so existing towns behave identically until the player changes it. A higher rate raises tax income and reduces demand; a lower rate does the reverse. The effect is derived, deterministic, shown in the budget and inspector, and recoverable. D25's no-debt and waiver rules stay.
2. **Saves.** The rate is canonical state, so M2f uses schema 7 and simulation/content `m2f-1`. Schemas 1-6 load with the default rate and lose nothing else. Preserve original bytes as before. Existing fixtures stay byte-identical; add a schema-7 fixture.
3. **Build and test.** Do the model and command first, then the meter and rate control. Test spending, determinism, migration and packed flows. Run pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. The game version becomes `0.8.0-m2f`. Record actual counts, artifact hashes and limits.
4. Update README, Decisions, the genre table and this handoff (pointing at M2g), then deliver under the standing instruction.

**Stop after M2f.** Do not start M2g, other candidates, the guide, balance tuning beyond the tax effect, final art/audio, the controller route or autosaves.

## Preserve the current contract

- **Lots and stations (D30).** Homes, shops and workshops are 3x3 lots anchored at their top-left tile, each replacing a single-tile plot one-for-one ($25, one power unit, levels 0-2). Power stations are 4x4, one per placement, with price, capacity and upkeep counted per station. Parks stay one tile. Access and power reach a lot through any side-sharing perimeter tile; corner contact does not count. Clearing any tile removes the whole footprint. Zone tools centre a lot on the pointer, and a drag lays a straight run of lots.
- **Unchanged numbers.** D17-D28 prices, capacities, demand, caps, clock order, budget, park priority and project rules are unchanged, with a lot in each place where a plot appeared. M2f's D32 may change only the tax and demand rules it specifies.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.** Schema 6 stores a strict per-cell `footprint_anchor` array. Schemas 1-5 load with their single-tile zones and stations cleared; everything else is kept. Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-5.json` before replacement. Seven fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical. JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before M2e's native run and was restored to that state. Record the path the tested process actually resolved, and restore it exactly afterwards. Packed tests use an isolated `user://tests/…` store.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/m2e/native/native_driver.py` (ignored) posts input only to the game's window handle and captures it with `PrintWindow`. Do not use its hover action unless the owner agrees, because hover moves the real cursor.

## Actual evidence and limits

M2e passed 479 source / 415 exported-PCK checks and release-EXE start-up. A posted-window-message run of the actual EXE covered:

- schema-5 migration with preserved originals;
- a lot town built by input, with growth at 3x speed;
- restart/load with a byte-identical resave;
- clearing a lot from its corner, and a second 4x4 station.

A smoke rerun used the final export. The 0.7.1-m2e artwork default then passed 483 source / 429 exported-PCK checks, release-EXE start-up and a native default/switch check. Native evidence is 1280x720 at standard text on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
