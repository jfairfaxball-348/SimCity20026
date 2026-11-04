# Delivery and release plan

Status, 4 November 2026: **M0/M1 and M2a implemented and locally tested; M2b–M2d and M3–M5 not started.** See the [M2a evidence](sessions/2026-11-04-m2a.md) and [foundation evidence](sessions/2026-11-04-m0-m1.md) for actual checks and limits; no public game release has occurred.

## Milestones and gates

Each milestone should produce a runnable checkpoint, a short evidence record, and an updated handoff. Dates are intentionally unset.

| Milestone | Work | Completion evidence |
| --- | --- | --- |
| M0: toolchain and display | Pin editor/templates; create the smallest project; test pixel world, scalable UI, pointer transforms, and native export | Recorded version; actual Windows executable launches; display/input checks at planned sizes |
| M1: building foundation | 64x64 model; pan/zoom; road/home-zone placement and removal; atomic costs; pause/speed clock; manual saves | Headless command/save/replay checks pass; exported build can construct, save, restart, and restore a layout |
| M2: city loop | Roads/access, power, homes/shops/workshops, population/jobs/demand, monthly budget, park, growth explanations | A town can grow from an empty start; shortages and deficit recovery are understandable; deterministic scenario tests |
| M3: playable slice | One neighbourhood project, onboarding, coherent original sample art/audio, full controller route, autosaves | A 20–30 minute experience; five-person observed test against the product brief; fresh-machine and controller evidence |
| M4: content-complete candidate | Tuned 128x128 limit if profiling supports it; bounded content/project set; settings/accessibility; save migration | No missing advertised systems; busy-city profile; content and asset provenance audit; closed beta feedback |
| M5: release candidate / 1.0 | Regression fixes, store material, distribution notices, packaging, account/store work if authorised | Release checklist passes on supported targets; store reviews complete where required; rollback package and support route ready |

The next agent's default small assignment is **M2b power access**, in [NEXT_SESSION.md](../NEXT_SESSION.md). M2a completes only the road-access part of M2; homes remain vacant. The full native 1080p and Windows DPI matrix remains unverified despite passing automated layout checks; resolve it before claiming broader display support. If M3 feedback is weak, improve the existing experience before expanding M4's content. Keep optional ports, disasters, and advanced transport out of the critical path.

## Effort and spending assumptions

No schedule or budget was supplied. The following are planning allowances, not estimates from measured project velocity:

- M0 + M1: approximately 4–10 focused developer days for someone already comfortable with Godot and testing.
- Through M3: approximately 4–8 full-time weeks in total, with a tightly limited slice and readily available original sample art/audio.
- A narrow, polished 1.0: roughly 4–8 full-time months in total, including content production, testing, and release work. Learning the engine, part-time availability, or solo production of all art/music can make this substantially longer.

These ranges overlap; do not add them together. Re-estimate after M1 using actual time and after M3 using playtest/asset throughput. Carry explicit contingency rather than turning these allowances into a release announcement.

| Cost area | Current planning treatment |
| --- | --- |
| Godot engine | No engine purchase or royalty budget under its MIT terms; include notices |
| Private prototype distribution | itch.io supports a free account and controlled access; no service was created here |
| Steam submission | Currently US$100 per product or equivalent, with applicable tax; not purchased |
| Art, animation, music, fonts | Obtain a bounded asset list and quotes or allocate the owner's production time after the slice direction works |
| QA and devices | Budget access to representative Windows hardware and a controller; additional platform devices only if support is adopted |
| Brand/legal/accounting | Scope to the actual owner, name, territories, contracts, and sales model; no professional quote obtained |
| Signing, localisation, promotion | Later explicit decisions with current quotes; not prerequisites to M1 |

Steam's fee is non-refundable but recoupable after the documented US$1,000 Adjusted Gross Revenue threshold. This is not a profit guarantee. [Steam Direct fee](https://partner.steamgames.com/doc/gettingstarted/appfee).

Do not derive net revenue from a game's headline price alone. A later commercial model must use the actual platform agreement, regional taxes, refunds, discounts, payment costs, contractor obligations, and support cost. No sales, wishlists, conversion, or profitability projections were researched or asserted here. Final price remains unset.

## Working process

1. Take a small player-visible slice from the current milestone. Specify observable behaviour and the important failure cases.
2. Implement model rules before binding UI to them. Keep scene changes and asset batches small enough to inspect.
3. Run focused invariant tests, then exercise the changed behaviour in the real game/export.
4. Record what passed, what was actually observed, and what remains unknown. Save a reproducible seed or fixture for bugs.
5. Review the milestone gate and update `NEXT_SESSION.md` before stopping.

Use short `codex/` branches for future implementation when appropriate, small coherent commits, and a buildable `main` once the initial project exists. A commit/PR should describe player behaviour, relevant design decisions, tests, and limitations. Do not commit unrelated user work. Publication is a separate task from making a local build.

Keep a small backlog grouped into current milestone, later candidates, and excluded scope. Use `docs/DECISIONS.md` for consequential changes such as engine version, save format, network rules, or release targets; a paragraph with the reason and effect is sufficient. Keep claims of planned, implemented, tested, and released distinct.

The local command flow and artifact metadata now exist. CI remains deferred until the initial source baseline and remote workflow are established; no CI run is claimed. Reuse the helpers for import, substantive model/save tests, export, and metadata. CI does not replace visual, controller, or clean-machine checks. Avoid automatic public release on every branch push.

## Release sequence

### 1. Local foundation and private slice

Produce an executable ZIP containing the required executable/data files, notices, and short controls/troubleshooting notes. Test outside the editor on a fresh user profile or another machine, including a non-administrator account and a path containing spaces/non-ASCII characters.

For external testers, a restricted itch.io project with download keys or a password is a suitable option once distribution is authorised. Restricted projects are distinct from public pages and are excluded from the site's browse/search listings. Access controls cannot prevent a tester redistributing a downloaded file. [itch.io access controls](https://itch.io/docs/creators/access-control), [itch.io getting started](https://itch.io/docs/creators/getting-started).

Collect voluntary observations and bug reports containing game version, seed, steps, and an optional save. No automatic analytics, personal-data collection, or account system is needed for the initial product. Obtain permission before recording testers or retaining identifying feedback.

### 2. Decide whether the slice earns a public demo

Review enjoyment/usability results, asset originality, save stability, and performance. Publish only claims demonstrated by the build. A small native demo is enough; a browser demo is optional and needs separate storage, loading, input, and browser checks.

Use screenshots and footage from this game. Do not use reference-game imagery, logos, music, or imitation packaging. A prototype's geometric tiles are not finished store art.

### 3. Prepare Steam if the owner chooses it

Work backwards from a realistic release window. Valve requires identity, banking/tax information and agreements, a store page, build submission, and review. The onboarding page checked on **4 November 2026** states a **21-day wait after the app fee** for the first few titles and a **public Coming Soon page for at least two weeks**. Those clocks can overlap; neither replaces verification/review. Tax verification can also take time. Recheck the current page and actual Steamworks dashboard before setting dates. [Steam onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding).

The review documentation says store/build review typically takes 3–5 business days and recommends allowing at least seven business days. Reserve a wider planning buffer, especially for corrections; this is not a guaranteed launch turnaround. Submit the store presence before the build as required. [Steam review process](https://partner.steamgames.com/doc/store/review_process), [Steam release process](https://partner.steamgames.com/doc/store/releasing).

Prepare original capsule art, screenshots, a short gameplay trailer, accurate descriptions, supported-language/platform lists, content survey, pricing, and support details. Advertise only implemented features. Check current generated-content disclosures if applicable. [Steam Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey).

A Steam SDK integration is not part of M1. Decide later whether achievements, Cloud, or platform-specific input features earn the dependency. Keep the base game functional offline. If Cloud is added, test cross-machine saves, conflicts, and version compatibility before advertising it.

Recommend a finished small 1.0 over assuming paid Early Access will finance unfinished core design. Early Access would be a separate business/support choice. No release account, fee, page, announcement, upload, or contact was made during planning.

### 4. Release and maintain

Create a versioned candidate, test that exact export, retain its checksum and build metadata, and keep the prior known-good package available. A tagged source version should identify its engine/templates, content version, save schema, and test record. Rebuilding from the same inputs should reproduce behaviour; do not claim byte-identical exports unless actually demonstrated.

After release, prioritise crashes, save loss, startup problems, and control blockers. Validate patches against the save fixtures and the exact packaging flow. A rollback must also account for saves written by the newer version; never silently load or overwrite an incompatible save with an older build.

## Release candidate checklist

- [ ] Core loop and every advertised feature work in the actual export.
- [ ] Supported operating systems/hardware were tested; unsupported ports are not listed.
- [ ] Tutorial, pause, settings, controller path if advertised, and text scaling are usable.
- [ ] Manual saves, autosaves, corruption handling, backups, and supported migrations pass.
- [ ] Busy-city profile and soak meet the documented targets or honestly revised requirements.
- [ ] No unresolved release-blocking crash, save-loss bug, or unrecoverable default-mode economy trap remains.
- [ ] Final name, art, audio, fonts, dependencies, credits, and licence notices have recorded provenance/review.
- [ ] No private keys, developer-only data, paid SDK material, tests, or source art leaked into the package.
- [ ] Store claims, content disclosures, pricing, and supported languages match the candidate.
- [ ] Distribution is authorised; required account verification, waits, and reviews are complete.
- [ ] Recovery package, patch notes, support contact, and save-compatibility policy are ready.

## Main risks

| Risk | Early response | Evidence needed before expanding |
| --- | --- | --- |
| Pleasant appearance but little reason to play | Prove one satisfying growth/project loop | M3 observed playtests |
| Scope expands toward a full metropolitan simulator | Keep one bounded map and aggregate systems | A clear player benefit before accepting any extra system |
| Art/branding is too close to the reference | Independent art brief, provenance, identity review | Reviewed final assets/name; no claim of legal clearance from this document |
| Save loss or nondeterministic bugs | Model-first state, lossless serialization, backups, replay fixtures | Save/continuation/failure tests |
| Confusing controls or unreadable UI | Display/input spike early; direct novice observation | Resolutions, text scaling, controller checks |
| Slow simulation or full-map redraws | Fixed clock, flat data, dirty visuals, profiling | Busy-city timings on recorded hardware |
| Engine/template mismatch | Explicit pinned tool path and version check | Clean import and native export |
| Art/audio production becomes the bottleneck | Validate a small coherent sample before full production | Measured production effort and asset budget |
| Store timing or commercial obligations surprise the owner | Recheck official rules before announcing a date | Actual account status and release checklist |

The largest uncertainties are enjoyment, production capacity, and finished presentation. This research reduces platform and process uncertainty; it does not resolve those uncertainties without making and testing the game.
