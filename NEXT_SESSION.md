# Next session: M2h town summary

Updated 6 November 2026 after M2g. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes and M2g desirability are implemented and locally tested. M2h is planned, not yet specified or implemented. The M3b guide is specified but deferred (U24). M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16-U26, D22, D25, D26, D29-D33), docs/TOOLCHAIN.md, [genre candidates](docs/GENRE_ALIGNMENT.md), the permitted [study notes](docs/research/MICROPOLIS_STUDY.md) (especially its explanation contract), the [M2g specification](docs/M2G_SPEC.md) and [M2g evidence](docs/sessions/2026-11-06-m2g.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical; use live history for delivered commits. The M2g work branch was `codex/m2g-desirability`. Create a new `codex/` branch for the next work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.9.0-m2g, save schema 8, simulation/content `m2g-1`. The export EXE/PCK and `builds/citybuilder-0.9.0-m2g-windows-x64.zip` are local, ignored and unpublished.

**Artwork note:** Kenney Roguelike Modern City is the default style (U22/U23); the original renderer is the fallback. New presentation work should fit Modern City rather than adding new geometric placeholders.

## City-builder roadmap (U24)

Each **"Run next session"** delivers one milestone, in this order (candidate numbers refer to [the genre table](docs/GENRE_ALIGNMENT.md)):

| Order | Milestone | Candidates | Status |
| --- | --- | --- | --- |
| 1 | M2f | 9 + 4 | **Done (0.8.0-m2f):** demand meter and adjustable tax rate |
| 2 | M2g | 2 + 3 | **Done (0.9.0-m2g):** home desirability, workshop nuisance and the V overlay |
| 3 | **M2h (next)** | 7 | A short town summary naming the measurable causes holding the town back |
| 4 | M3b guide | - | The deferred first-steps guide, its steps refreshed for M2f-M2h |

Civic services (5) and traffic (6) come later, each when the owner asks for it. Optional hazards (8) come only if the owner asks, opt-in and never in the default mode. The owner may reorder at any time.

## Assignment

On a subsequent **"Run next session"** (or "run next one"), do M2h. Do not ask the guide-or-candidate question: the owner has answered it (U24).

1. **Specify first.** Write `docs/M2H_SPEC.md` and adopt its rules as D34 in Decisions before code. Use this project's own layout and wording. Follow the study's explanation contract: each item names a measurable condition, where it is, and a remedy, and the summary never replaces the per-lot inspector. No random complaints, opinion polls or approval vote.
   - **Town summary.** A read-only panel or dialog, with its own unused key and a visible control. It lists the few biggest measurable causes holding the town back, ordered by how many levels or how much money each affects. Candidate causes:
     - lots without road access, or unpowered or short of power;
     - homes held by workshops;
     - demand with no zoned lot to use it;
     - levels leaving under high taxes;
     - a monthly deficit;
     - an empty or satisfied town.
     - Each cause has a count and a "Show" that centres the view and points the inspector at an example.
   - **Derived only.** It changes no rules, so prefer no save change: the game version becomes `0.10.0-m2h` with schema 8 / `m2g-1` unchanged, unless D34 justifies otherwise.
2. **Build and test.** Do the derivation first (a pure function of the model, tested on constructed towns), then the panel. Test ordering, counts, Show targets, fit at every size, and no model change. Run pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. Record actual counts, artifact hashes and limits.
3. Update README, Decisions, the genre table and this handoff (pointing at the refreshed M3b guide), then deliver under the standing instruction.

**Stop after M2h.** Do not start the guide, other candidates, balance tuning, final art/audio, the controller route or autosaves.

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
- **Unchanged numbers.** D17-D28 prices, capacities, caps, clock order, budget, park priority and project rules are unchanged except as D32 specifies. M2h's D34 should change no simulation rule.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - **Schema 8 contents.** The same fields as schema 7: a strict `tax_rate`, a ledger `tax_rate`, and the per-cell `footprint_anchor` array. Desirability is derived.
  - **Migration.** Schema 7 loads unchanged; schema 6 loads unchanged at 10%. Schemas 1-5 load with their single-tile zones and stations cleared.
  - **Loading and preservation.** Load never writes. Older primary/backup bytes are preserved once as `manual.schema1-7.json` before replacement.
  - **Fixtures.** Nine fixtures (hashes in `game/tests/fixtures/README.md`) stay byte-identical.
  - **Limits.** JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.**
  - **Which profile.** Processes started from a packaged app (such as the Codex desktop app) use a redirected profile under `%LOCALAPPDATA%\Packages\…\LocalCache\Roaming\OriginalCityBuilder\`. Processes started from an ordinary shell use `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder before the M2f and M2g native runs and was restored to that state after each.
  - **Recording and restoring.** Record the path the tested process actually resolved, and restore it exactly afterwards (including any leftover `.recovery_mode_lock`).
  - **Packed tests.** They use an isolated `user://tests/…` store, and their folders are moved out after runs.
- **Native driver.** When computer-use tools are unavailable, `builds/validation/m2g/native/native_driver.py` (ignored, with V added) posts input only to the game's window handle and captures it with `PrintWindow`.
  - Posted Ctrl shortcuts do not register, because Godot reads modifiers from the real keyboard, so use the Save/Load buttons.
  - Do not use the hover action unless the owner agrees, because hover moves the real cursor.
- **Packed-test hangs.** A script error inside the packed driver stops it before it quits, so `tools/verify.ps1` then waits indefinitely. If a run exceeds about 10 minutes, stop it and rerun the packed driver directly with a timeout to see the error.

## Actual evidence and limits

M2g passed 600 source / 469 exported-PCK checks and release-EXE start-up.

A posted-window-message run of the actual EXE covered:

- a street built by pointer and grown at 3x until the home across from a developed workshop was held at level 1;
- the V overlay with hatching and the workshop smoke mark;
- a pointer-placed park rescuing that home to level 2;
- a schema-8 save, and restart/load with the overlay.

A final smoke run on the packaged export checked a schema-7 load and the thicker hatching.

Native evidence is 1280x720 at standard text on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
