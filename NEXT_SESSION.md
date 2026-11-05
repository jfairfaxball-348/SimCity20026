# Next session: scope a bounded guided opening

Updated 5 November 2026 after M3a. **M0/M1 through M2d and the single M3a project are implemented and locally tested. M3 as a whole is incomplete.** No public release or human enjoyment evidence.

## Start here

Read README, AGENTS, docs/DECISIONS.md, docs/TOOLCHAIN.md, docs/M3A_SPEC.md and [M3a evidence](docs/sessions/2026-11-05-m3a.md). Inspect the local diff and fetch/reconcile live remote refs before editing. M3a work branch is `codex/m3a-project`, based on `4631b3e99dfa822f9773af33057af9b0a3003fb1`; use live history for its delivered commit. Default branch is currently `codex/m2a-road-access`, whose name is historical. Standing commit/push/fast-forward delivery applies; never force-push or discard unrelated work.

Use isolated Godot 4.7.2 Standard, `4.7.2.stable.official.ed1daf0bf`, through `tools/`. The global wrapper is still 4.6.3. Game 0.6.0-m3a, save schema 5, simulation/content m3a-1. Export EXE/PCK and `builds/citybuilder-0.6.0-m3a-windows-x64.zip` are local, ignored and unpublished.

## Preserve the current contract

D17-D27 remain unchanged: one side-sharing outside-road network; independent nearest-first power allocation at 20 zone plots per station; five-day growth with starter demand, park home priority, simultaneous limits and two-round service-loss decline; monthly post-growth budget with explicit shortfall waivers and free deficit recovery. Exact equations and values are in Decisions and the M2d evidence. No RNG is consumed by commands/ticks. Fixed clock, dialog/focus suspension, eight ticks/frame and bounded backlog remain.

D28 adds one optional project. Three distinct developed HOME plots with current road access and power, each within Manhattan radius 3 of the selected park, permit explicit free completion. Levels do not multiply plot counts. Completion increments command sequence once and changes only the project record. Flowers are cosmetic; no new economic/growth benefit. Service loss does not undo completion. Clearing the anchor removes its decoration/location but retains completion; replacing it never restarts the project. New town resets it.

Schema 5 stores strict `project = {completed: bool, park_index: int}`. Incomplete requires -1; complete permits -1 or an occupied park index. Counts are derived; no UI selection is saved. Schemas 1-4 validate under their original meanings, migrate with an incomplete project, and never auto-complete on load. Schema 4 keeps its ledger; earlier migrations keep their established behavior. Preserve exact schema-1/2/3/4 primary/backup bytes once before replacement; load never writes. Keep all six fixtures byte-identical; hashes/scenarios are in `game/tests/fixtures/README.md`. JSON cap 512 KiB; maps 8-128 per dimension; seed/RNG remain signed-64 decimal strings.

Model/command: `game/scripts/sim/city_state.gd` (`project_homes`, `complete_project`). Persistence: `scripts/persistence/save_codec.gd`, generic preservation in `save_store.gd`. Dialog and inspector: `scripts/main.gd`; art: `scripts/presentation/world_view.gd`. J/Project opens a modal scrollable dialog; chosen parks are row-major, default first on each opening. Show park centres/closes. Project/Help need scrolling at largest text; actions remain reachable. No general onboarding has been added.

## Actual evidence and limits

418 source / 360 packed checks and release-EXE startup passed. Packed tests use the pinned editor with the release PCK, not external scripts on the EXE. Tests cover geometry/services/atomic command/repeat/demolition, three-month simulation equivalence, strict saves/migrations/preservation failures and six fixture hashes. Modal button bindings are exercised directly in packed checks; actual mouse clicks are separate native evidence.

Native Windows: empty-town construction, 0/3 then 3/3 eligibility, largest-text completion, decoration/inspector, save/exit/restart/load with byte-identical resave, free park removal/reload with retained completion, final Help text/scrolling at 1280x720. The final Help-only rebuild and native run are distinguished in the session record. Two original user profile files were restored byte-for-byte; test process closed. Evidence is under ignored `builds/validation/m3a/`.

Automated layout matrix remains four resolutions x three text sizes. Human enjoyment/usability, DPI variants, other hardware/OSs, controller, performance targets and CI remain unverified. Do not turn these automated scenarios into the five-person M3 playtest gate.

## Next assignment and stop point

A subsequent **“Run next session” starts planning only**: scope one small M3b guided-opening prototype against the existing loop and product-brief gates.

1. Review the checkpoint and recorded UX limits. Specify an optional, dismissible opening that helps a new player activate the outside link, service homes and find the project, or identify a concrete usability defect that should precede it.
2. Define exact triggers, dismissal/re-entry behavior, input/layout acceptance cases, save implications, original text/art provenance and a bounded implementation stop point. Keep existing simulation/balance unchanged.
3. Produce a concrete M3b handoff, update README/Decisions, validate documentation and deliver the scoped planning commit under the standing instruction. Stop before implementation.

Do not start the full M3 bundle: final art/audio, controller route, autosaves, further projects and observed playtests need separate scope. No recruitment/external messages, purchases, store upload or public distribution. M3's five-person product-brief gates remain outstanding.

## Completed source-study boundary

The one U10 study is complete and its source-reading permission exhausted. Never open/read/run the ignored reference checkout or online/reproduced reference source. Only `docs/research/MICROPOLIS_STUDY.md` and Decisions may supply study input. No reference source was opened in M3a. The game stays original, unnamed and not GPL-licensed.
