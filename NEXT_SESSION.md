# Next session: implement the M3b first-steps guide

Updated 6 November 2026 after M2e. **M0/M1 through M2d, the M3a project and M2e zone lots are implemented and locally tested. The M3b guide is specified, not implemented. M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16-U20, D29, D30), docs/TOOLCHAIN.md, [the M3b specification](docs/M3B_SPEC.md) with its M2e dependency section, [genre candidates](docs/GENRE_ALIGNMENT.md) and [M2e evidence](docs/sessions/2026-11-06-m2e.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The M2e work branch is `codex/m2e-lots`; use live history for its delivered commit. The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch for the next work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.7.0-m2e, save schema 6, simulation/content `m2e-1`. The export EXE/PCK and `builds/citybuilder-0.7.0-m2e-windows-x64.zip` are local, ignored and unpublished.

**Artwork experiment note (6 November 2026):** two CC0 Kenney packs were evaluated in-game and retained as experimental assets; see [the artwork evaluation](docs/artwork-review/ARTWORK_EVALUATION.md). The owner has not chosen a pack. The original renderer stays the default. This does not change or block the assignment below.

## Assignment

On a subsequent **"Run next session"**, first ask the owner one question: implement the M3b guide (the default), or scope a chosen [genre candidate](docs/GENRE_ALIGNMENT.md) first. Without a different answer, implement only M3b:

1. Adopt D29 in Decisions before code, applying the specification's M2e dependency section (lot wording, footprint marker, game `0.8.0-m3b` with schema 6 / `m2e-1` unchanged).
2. Build the card, F1 and Help re-entry, Show and the bracket marker exactly as specified. No file under `sim/`, `persistence/` or `content/` changes.
3. Meet the M3b acceptance checklist. Run pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. Record actual counts, artifact hashes and limits.
4. Update README, Decisions, the asset ledger and this handoff, then deliver under the standing instruction.

**Stop after M3b.** Do not start further M3 work, genre candidates, balance tuning, final art/audio, the controller route or autosaves.

## Preserve the current contract

- **Lots and stations (D30).** Homes, shops and workshops are 3x3 lots anchored at their top-left tile, each replacing a single-tile plot one-for-one ($25, one power unit, levels 0-2). Power stations are 4x4, one per placement, with price, capacity and upkeep counted per station. Parks stay one tile. Access and power reach a lot through any side-sharing perimeter tile; corner contact does not count. Clearing any tile removes the whole footprint. Zone tools centre a lot on the pointer, and a drag lays a straight run of lots.
- **Unchanged numbers.** D17-D28 prices, capacities, demand, caps, clock order, budget, park priority and project rules are unchanged, with a lot in each place where a plot appeared.
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

A smoke rerun used the final export. Native evidence is 1280x720 at standard text on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17/U18 let the owner lean closer to the classic genre in mechanics and prefer the original's choices where options differ. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
