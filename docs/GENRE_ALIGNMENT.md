# Classic-genre alignment candidates

Recorded 6 November 2026 after an owner direction (U17): lean closer to the classic city-builder target, starting with 4x4 zone lots (U16, [M2e](M2E_SPEC.md)). **These are candidates for the owner to choose from. None is adopted or scheduled.** Each chosen item needs its own scoping session, rules in Decisions before code, and the usual evidence.

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
| 1 | Multi-tile power station (and optionally a larger park) | Plants and parks read as major buildings beside 4x4 lots | D19 station footprint; D26 park footprint | Footprint, capacity, price and art chosen independently; same access/power explanations | Can be folded into M2e if chosen before M2e starts |
| 2 | Neighbourhood desirability | Lots grow sooner or denser where surroundings are pleasant; parks help, workshops hurt; visible overlay | D22 growth order; D26 park benefit | Derived, deterministic and explained per lot; no land market or wealth tiers (study: adapt a visible benefit) | After M2e; its own spec |
| 3 | Workshop nuisance | Homes beside workshops grow more slowly, so the classic separate-your-zones tension appears | D22 | Visible sources, explained and recoverable effect; never destruction (study: adopt the principle) | Pairs with 2 |
| 4 | Adjustable tax rate | A rate control that trades income against growth | D25 (no tax slider) | Own range and effect; keep the no-debt, no-spiral recovery rules | Small; after M2e |
| 5 | Civic service coverage | One or two coverage buildings with upkeep (for example safety or health) | New | Explains what it provides; no crime-as-danger or destruction in the relaxed default (study: reject crime) | Later |
| 6 | Traffic and congestion | Busy roads become visible, and congestion can slow growth | Adds to D17 without replacing it | Structural access stays the outside-link rule; derived and bounded; the product brief currently excludes realistic routing | Later; large |
| 7 | Town summary or advisor | A short, actionable read-out of what is holding the town back | New | Measurable causes only; no random complaints or approval vote (study: adapt later) | Small; with M3 |
| 8 | Optional challenges or hazards | Opt-in events with a clear extent and recovery path | U05 relaxed default | Consent first, never in the default mode; no reference scenarios or hazard list | Only if the owner wants it, late |
| 9 | Glanceable demand indicator | Home, shop and workshop demand shown at a glance | Presentation only | Our own design, not the reference's interface composition | Small; any time |

## Effect on the plan

- [M2e](M2E_SPEC.md) (4x4 lots) remains the next implementation session; candidate 1 can join it if chosen first.
- After M2e, the owner chooses whether the [M3b guide](M3B_SPEC.md) or the first chosen system comes next.
- If several systems are chosen, the product brief's positioning, "a small, readable city simulation about making welcoming neighbourhoods", and its first-release exclusions need an owner revision.
- The "Conditions and notes" column records the earlier study proposals for context. Under U17 the owner may override any of them except the rights boundary.
