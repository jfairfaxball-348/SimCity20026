# Classic-genre alignment candidates

Recorded 6 November 2026 after an owner direction (U17): lean closer to the classic city-builder target, starting with 3x3 zone lots and 4x4 power stations (U16/U18/U19, [M2e](M2E_SPEC.md)). **Scheduled by the owner (U24, 6 November 2026):** candidates 9 + 4 as M2f, 2 + 3 as M2g, and 7 as M2h, ahead of the M3b guide; 5 and 6 later on request; 8 only if asked. M2f (9 + 4) is adopted as D32 and implemented in 0.8.0-m2f; the rest are not yet adopted. Each milestone writes its specification and adopts its rules in Decisions before code, then implements and tests in the same session, with the usual evidence.

## What U17 changes and what stays

**Relaxed by the owner.** The earlier design-scope limits no longer block a candidate:

- the study notes' "reject for this project / for the current scope" proposals;
- the product brief's first-release exclusions;
- the preference for the smallest possible system.

Relaxed play (U05) stays the default. A candidate that conflicts with it (for example hazards) is decided case by case.

**Unchanged: rights, which U17 itself requires.** The classic genre's mechanics are shared ground: zoned growth, utilities, budgets, desirability, nuisance, services, traffic and optional hazards appear in many city builders. This project adopts them with its own rules, numbers, art, interface layout, text and names. It does not recreate the reference game itself:

- no copied or translated code, data or tables;
- no art, tiles or buildings, music or sound from it;
- no text, characters, scenarios or maps from it;
- no name or branding from it;
- no reproduction of its recognisable look or screen composition.

**Unchanged: the clean-room boundary (U10).** Implementation sessions never read reference source, which also keeps the game clear of GPL obligations. The only permitted reference input is the qualitative [study notes](research/MICROPOLIS_STUDY.md) and Decisions. Widely known genre conventions need no source. See [AGENTS.md](../AGENTS.md) and [IP and assets](IP_AND_ASSETS.md).

## Candidates

| # | Candidate | What the player gets | Decisions it would revise | Conditions and notes | Suggested timing |
| --- | --- | --- | --- | --- | --- |
| 1 | Multi-tile power station | Plants read as major buildings beside lots | D19 station footprint | **Chosen (U18): 4x4 stations in M2e.** Parks stay one tile, as in the original | In M2e |
| 2 | Neighbourhood desirability | Lots grow sooner or denser where surroundings are pleasant; parks help, workshops hurt; visible overlay | D22 growth order; D26 park benefit | Derived, deterministic and explained per lot; no land market or wealth tiers (study: adapt a visible benefit) | **Scheduled: M2g** (U24) |
| 3 | Workshop nuisance | Homes beside workshops grow more slowly, so the classic separate-your-zones tension appears | D22 | Visible sources, explained and recoverable effect; never destruction (study: adopt the principle) | **Scheduled: M2g**, with 2 |
| 4 | Adjustable tax rate | A rate control that trades income against growth | D25 (no tax slider) | Own range and effect; keep the no-debt, no-spiral recovery rules | **Done: M2f** (D32, 0.8.0-m2f), with 9 |
| 5 | Civic service coverage | One or two coverage buildings with upkeep (for example safety or health) | New | Explains what it provides; no crime-as-danger or destruction in the relaxed default (study: reject crime) | Later, on owner request |
| 6 | Traffic and congestion | Busy roads become visible, and congestion can slow growth | Adds to D17 without replacing it | Structural access stays the outside-link rule; derived and bounded; the product brief currently excludes realistic routing | Later, on owner request; large |
| 7 | Town summary or advisor | A short, actionable read-out of what is holding the town back | New | Measurable causes only; no random complaints or approval vote (study: adapt later) | **Scheduled: M2h** |
| 8 | Optional challenges or hazards | Opt-in events with a clear extent and recovery path | U05 relaxed default | Consent first, never in the default mode; no reference scenarios or hazard list | Only if the owner wants it, late |
| 9 | Glanceable demand indicator | Home, shop and workshop demand shown at a glance | Presentation only | Our own design, not the reference's interface composition | **Done: M2f** (D32, 0.8.0-m2f), with 4 |

## Effect on the plan

- [M2e](M2E_SPEC.md) (3x3 lots and 4x4 stations) is implemented and locally verified. U18 also sets a standing preference: when choosing between options, prefer whichever is closest to the original game, within the rights boundary above.
- **U24:** the owner chose the city-builder systems before the [M3b guide](M3B_SPEC.md). Order: M2f (9 + 4), M2g (2 + 3), M2h (7), then the guide refreshed for them. See [NEXT_SESSION.md](../NEXT_SESSION.md).
- None of the scheduled systems conflicts with the product brief's first-release exclusions (its 1.0 column already lists amenity and nuisance effects). Its positioning line, "a small, readable city simulation about making welcoming neighbourhoods", should be revisited with the owner before the M3 playtest; candidates 6 and 8 would also revise the exclusions.
- The "Conditions and notes" column records the earlier study proposals for context. Under U17 the owner may override any of them except the rights boundary.
