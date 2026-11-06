# Next session: implement M2e zone lots and 4x4 power stations

Updated 6 November 2026 after the M3b scoping session. **M0/M1 through M2d and the single M3a project are implemented and locally tested. M2e lots and the M3b guide are specified, not implemented. M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md (U16, U17, U18, D30, D29), docs/TOOLCHAIN.md, [the M2e specification](docs/M2E_SPEC.md), [M3b](docs/M3B_SPEC.md), [genre candidates](docs/GENRE_ALIGNMENT.md) and [the scoping record](docs/sessions/2026-11-06-m3b-scope.md). Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The scoping branch is `codex/m3b-scope`; use live history for its delivered commit. The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch for M2e.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

Use the isolated Godot 4.7.2 Standard (`4.7.2.stable.official.ed1daf0bf`) through `tools/`; the global wrapper is still 4.6.3. The current build is game 0.6.0-m3a, save schema 5, simulation/content m3a-1. The export EXE/PCK and `builds/citybuilder-0.6.0-m3a-windows-x64.zip` are local, ignored and unpublished.

## Assignment

On a subsequent **"Run next session"**, implement only M2e as specified:

1. Adopt D30 in Decisions before any model edits.
   - **Owner check first:** ask whether zones are 4x4 (U16) or 3x3, which the original game used and which the owner's U18 closest-to-original preference would favour. Record the answer, and apply S = 3 throughout the spec if they choose 3x3. Power stations are 4x4 either way (U18); parks stay one tile.
2. Build in this order:
   - **Model:** lot and station footprints, placement, clear, access, power (stations counted by anchor), growth, park, project and economy.
   - **Saves:** schema 6 with `footprint_anchor`, migration of schemas 1-5 with old zones and stations cleared, and schema-5 preservation.
   - **Presentation:** original code-drawn lot and 4x4 station buildings, footprint previews, per-lot marks and inspection, and "plot" to "lot" wording.
3. Meet the M2e acceptance checklist. Run pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. Record actual counts, artifact hashes and limits.
4. Update README, Decisions, the asset ledger, fixture notes and this handoff, then deliver under the standing instruction.

**Stop after M2e.** The M3b guide is its own later session: after M2e, the owner chooses whether the guide or a chosen genre candidate comes next. Do not start further M3 work, the genre candidates, balance tuning, final art/audio, the controller route or autosaves.

## Preserve the current contract

- **Unchanged numbers.** M2e changes building geometry only. Keep D17-D28's prices, capacities, demand, caps, clock order, budget, park priority and project rules, with a lot in each place where a plot appears.
- **Determinism.** No commands or ticks consume RNG. The fixed clock, dialog/focus suspension, eight ticks per frame and bounded backlog stay.
- **Saves.**
  - Validation stays strict.
  - Load never writes.
  - Preserve exact older primary/backup bytes once before replacement, now including `manual.schema5.json`.
  - All six fixtures stay byte-identical (hashes in `game/tests/fixtures/README.md`). Their migrated expectations change, because zones and stations are cleared.
  - JSON cap 512 KiB; maps 8-128 per dimension; seed and RNG state remain signed-64 decimal strings.
- **Evidence profile.** M3a's native runs were launched from a packaged app. They used a redirected save folder under `%LOCALAPPDATA%\Packages\OpenAI.Codex_…\LocalCache\Roaming\OriginalCityBuilder\saves\` (see the scoping record). The unredirected `%APPDATA%\OriginalCityBuilder\` currently has no `saves` folder. Record the path the tested process actually resolved, and restore it exactly afterwards, including removing a folder you created. Packed tests use an isolated `user://tests/…` store.

## Actual evidence and limits

The M3a record reports 418 source / 360 packed checks and release-EXE start-up; the scoping session checked the retained logs and artifact hashes but did not rerun them. Native Windows evidence covers 1280x720 at standard and largest text on one machine. Human enjoyment and usability, DPI variants, other hardware and operating systems, the controller, performance targets and CI remain unverified. Do not turn automated scenarios into the five-person M3 playtest gate.

## Rights and source-study boundary

U17 lets the owner lean closer to the classic genre in mechanics. The rights rules do not change:

- No copying or translation of the reference game's code, data, tables, art, sound, text, characters, scenarios, maps, name or branding.
- No recreation of its recognisable look or screen composition.

The one U10 study is complete and its source-reading permission is exhausted. Never open, read or run the ignored reference checkout or any online or reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. The game stays original, unnamed and not GPL-licensed. No recruitment, external messages, purchases, store upload or public distribution.
