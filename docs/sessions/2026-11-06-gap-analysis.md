# 2026-11-06: U30 gap analysis and roadmap (planning only)

**Request.** Owner "run next session" with the U30 assignment in NEXT_SESSION: audit 0.11.0-m3b, list the classic game's features and the gaps, write a roadmap, ask at most four owner questions, update the handoff and deliver.

**Branch.** `codex/gap-analysis-roadmap` from `29f3a0a` (default branch `codex/m2a-road-access`, clean, matching origin after fetch).

## What was done

- Audited the build from this project's own code (`game/content/balance.gd`, `game/scripts/`), Decisions and session evidence. Key numbers in the audit are this project's own provisional values.
- Wrote [GAP_ANALYSIS.md](../GAP_ANALYSIS.md): an inventory of 0.11.0-m3b, 41 classic features at player level in our own words with status, gap size, dependencies, player impact and rights notes, later-edition extras marked optional, and a verdict.
- Wrote [ROADMAP.md](../ROADMAP.md): milestones R1-R17 with scope, reasons, dependencies, sizes, schema effects and acceptance gates; placement of the remaining M3 gate items (R3 autosaves/settings, R4 audio sample, R5 controller, R6 five-person playtest).
- Asked the owner four questions in session and recorded the answers as U31-U34: disasters optional, off by default; keep the no-debt default; scale matches the original game; no later-edition extras for now.
- Updated README, AGENTS, Decisions, DELIVERY_PLAN (points at the roadmap), GENRE_ALIGNMENT (superseded) and NEXT_SESSION (assigns R1).

## Clean-room boundary

No reference source, ROM, decompilation or reproduced manual was opened; the ignored checkout was not touched. Classic features were described from general genre knowledge, the permitted study notes and public non-source descriptions. No reference numbers, formulas, tables, text or art were copied; the only classic-scale figures quoted (map size, population order of magnitude, in the U33 note) are public descriptive facts used as a scale target, with our own exact values to be chosen.

## Evidence and limits

Documentation only: no game code, version, save schema, fixture or binary changed, so no tests were run. Gap sizes and session counts are rough planning estimates, not measured velocity. No purchase, external message or release.
