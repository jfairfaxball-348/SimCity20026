# Next session: structured gap analysis and roadmap

Updated 6 November 2026 after M3b and owner directions U29/U30. **M0/M1 through M2d, the M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary and the M3b first-steps guide are implemented and locally tested. The U24 roadmap is complete. M3 as a whole is incomplete.** There is no public release and no human enjoyment evidence.

## Start here

Read README, AGENTS (including U29 on plain words), docs/DECISIONS.md (all U and D entries), docs/PRODUCT_BRIEF.md, docs/DELIVERY_PLAN.md, docs/GENRE_ALIGNMENT.md, the permitted [study notes](docs/research/MICROPOLIS_STUDY.md) and the session evidence under `docs/sessions/`. Inspect the local diff, and fetch and reconcile live remote refs before editing.

- **Branches.** The default branch is still `codex/m2a-road-access`, whose name is historical. Create a new `codex/` branch for this work.
- **Delivery.** Standing commit/push/fast-forward delivery applies. Never force-push or discard unrelated work.

The current build is game 0.11.0-m3b, save schema 8, simulation/content `m2g-1` (Godot 4.7.2 through `tools/`). This session changes **no game code**.

## Assignment (U30): audit, then roadmap

On a subsequent **"Run next session"**, do a planning-only session in three parts, then deliver.

### 1. Audit what we have

Inventory every player-facing feature and system in 0.11.0-m3b from this project's own code, Decisions and evidence. For each, give its status (implemented, tested locally, limits) and its key numbers. Cover at least:

- zones and their levels;
- demand and growth;
- roads and the outside link;
- power;
- budget, taxes and upkeep;
- parks and desirability;
- the project, summary and guide;
- overlays and the inspector;
- saves;
- input and accessibility;
- map size and generation;
- art, audio and platforms.

### 2. List what the full classic game has, then the gaps

**Baseline.** Use the original classic city-builder (the 1989 game and its console ports) as the baseline, and mark features that only later editions added as optional.

**Feature list.** Describe its features at player level, in our own words: what the player can build, see and manage, and what the simulation responds to. Cover at least:

- **Building and growth:**
  - zone types and density or wealth growth;
  - demand;
  - land value;
  - pollution;
  - crime;
  - traffic and transport (road, rail);
  - power (plant types, lines, shortages);
  - services (police, fire) and their funding;
  - special buildings (stadium, seaport, airport);
- **Money and rules:**
  - budget, taxes and funding levels;
  - disasters;
  - scenarios;
  - the city evaluation, public opinion and problems;
  - city size milestones;
  - rewards or gifts;
- **Information and presentation:**
  - map overlays and graphs;
  - terrain, map generation and editing;
  - time controls;
  - sound and music;
  - animation and presentation;
  - map and population scale.

**Allowed inputs (clean-room boundary).** General genre knowledge, the permitted study notes, and public non-source feature descriptions (such as encyclopedia overviews) for what features exist.

- Never open source code, ROM data, decompilations or reproduced manuals.
- Never copy numbers, formulas, tables, text or artwork.
- Plain genre words are fine (U29).

**Gap matrix.** Write `docs/GAP_ANALYSIS.md` with one row per feature, giving:

- the classic behaviour, briefly and in our own words;
- our status: done, partial, missing, or deliberately different (for example the relaxed no-debt rule);
- the size of the gap (S, M or L);
- what it depends on;
- the player impact;
- any rights note.

Also give a one-paragraph verdict on the biggest gaps.

### 3. Set the roadmap

**The document.** Write `docs/ROADMAP.md`, which supersedes the candidate table in `docs/GENRE_ALIGNMENT.md`. It lays out ordered milestones from 0.11.0-m3b to a feature-complete, classic-style city builder. Each milestone gives:

- its scope;
- why it comes at that point;
- its dependencies;
- a size in sessions;
- whether it changes the save format or schema;
- its acceptance gate.

**Items to place.**

- **Early.** The U29 terminology pass: player-facing "Residential / Commercial / Industrial" in place of Homes / Shops / Workshops, where the owner wants it.
- **Recommended first big milestone.** Growth depth: more density levels, land value for all zone types, and services needed for the top levels.
- **The remaining M3 gate items** at sensible points: the five-person observed playtest, coherent original audio, the controller route, autosaves and remembered settings.

**Owner questions.** End with at most four questions, only for choices that are genuinely the owner's:

- disasters (off, optional or on by default);
- failure states such as debt or bankruptcy versus the relaxed no-debt rule;
- the target map and population scale;
- whether to include later-edition extras.

Record the answers as U entries.

### Deliver

Update README, Decisions, DELIVERY_PLAN (pointing at the roadmap), GENRE_ALIGNMENT (marked superseded) and this handoff, so the next "Run next session" starts the first roadmap milestone. Then deliver under the standing instruction.

**Planning only.** Write no game code, change no version, and make no purchases, external messages or public release.

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
