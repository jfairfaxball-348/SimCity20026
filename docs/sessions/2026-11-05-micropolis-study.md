# Micropolis study: documentation evidence

Date: **5 November 2026**. Scope: the single U10 read-only study, explicitly started and authorised for commit, push, and default-branch integration by U11. **Complete as research; no game implementation or release.** M2d remains unimplemented, with its original assignment preserved for a separate session.

## Deliverables and findings

- [Study notes](../research/MICROPOLIS_STUDY.md): qualitative coverage of every requested system, scheduling and cost, player feedback, pitfalls, and proposed adopt/adapt/reject choices. D17-D24 and relevant earlier decisions are linked directly; no proposal was adopted as a new game rule.
- [Provenance](../research/MICROPOLIS_PROVENANCE.md): repository URL, exact detached commit, date, every consulted reference file, Git blob identities, licensing documents, review limits, and evidence groups.
- README, AGENTS, Decisions, rights guidance, and NEXT_SESSION now identify the study as complete and prohibit further reference-source reading by implementation sessions.

The reference pin is `bd6e12eed6e148fe25270e7a4e2278f71a89f26c` from `SimHacker/MicropolisCore`. All requested licence documents were present. The optional legacy repository was not needed and was not fetched or read. Maintained-engine observations are not represented as verified original-release behaviour. UI descriptions concern static engine outputs; no frontend or reference game was exercised.

The strongest design recommendation is to retain understandable local conditions and deterministic growth. Random attempts, stale spatial fields, and citywide scores can obscure why a particular plot is waiting. The study recommends keeping the already queued economy/amenity scope small. It settles no accounting values, formulas, park effects, new saved state, or future simulation systems.

## Boundary verification

The working tree was clean at baseline `443fc0472340396bdc4bfaa09e728cbd0081344f`; local and remote default heads agreed. The default branch was verified through both remote HEAD and connected repository metadata as `codex/m2a-road-access`. The connected owner account had write/admin access. Work used `codex/micropolis-study`.

Actual checks for this documentation change:

| Check | Evidence/result |
| --- | --- |
| Reference isolation | Existing `builds/` ignore rule matched the checkout and pin record before acquisition and at closeout; no reference content is tracked in the project |
| Pin and cleanliness | Reference Git metadata confirmed the detached recorded commit and no tracked reference modifications |
| No game changes | Diff against the baseline is empty for `game/`; no new untracked game files; original game tree is `271739662b24f7554a8c4787f7331c7e7174378f` |
| M2d unchanged | The entire queued M2d section matches the baseline, including its gate and exclusions; LF-normalised UTF-8 SHA256 is `b3bb4877c3296ecbc86442e5a40c13b133fdbdcf4efeb18d888be550359e8970` |
| Documentation diff | Whitespace check passed; all eight changed/staged paths are the documentation deliverables; no game code, scripts, root licence, generated files, or binary additions |
| Links and anchors | All 103 local links/fragments across eight changed documents passed; D01-D24 now have explicit anchors without rule changes |
| Qualitative boundary | Reviewed study for copied code, mirrored pseudocode, source tuning/formulas, program identifiers, source text, assets and screenshots; none included. Provenance carries only the permitted source metadata |
| Existing Windows package | SHA256 remains `88da9dc2b61bcba338044cfad205dd78e1609e74de91c83d68636414caf3f6a9`; ZIP still contains only its original eight allowlisted entries |

**The session wrote no game code.** No reference source, build script, executable, installer, test, image, or sound was executed or imported. The existing export was neither rebuilt nor repackaged. User saves were not opened or changed.

Game checks and native playtesting were not rerun: no game, toolchain, packaging, or asset behaviour changed. The prior source/packed/native results remain the dated M2c evidence, not new study results. No CI workflow was added or CI success claimed. Static inspection did not measure reference performance or prove its correctness, save continuation, balance, legal clearance, or enjoyment.

## Delivery and next session

The owner authorised committing and pushing `codex/micropolis-study` and merging it into the live default branch. Delivery uses a fast-forward only when the rechecked default head is still the verified ancestor; a changed head requires inspection before integration. Git history and remote refs identify the delivered commit, rather than a self-referential hash in this file. The completion reply records the actual delivery outcome after remote readback.

The next assignment is the unchanged [M2d economy and amenity slice](../../NEXT_SESSION.md#queued-after-the-study-m2d-economy-and-amenity-unchanged). The study's permission to read source is exhausted. Only its qualitative notes and Decisions may supply reference-design input to that separate implementation session. The game remains original, unnamed, and not GPL-licensed.
