# R2a: land value for every zone

Specified 6 November 2026 under the owner's request to start R2a (U36), from the [roadmap](ROADMAP.md). Adopted as [D36](DECISIONS.md#d36) before model code, then implemented and locally verified as 0.13.0-r2a ([evidence](sessions/2026-11-06-r2a.md)). **One wording change during implementation:** the customers part is shown as "trade", because "customers" made the longest inspector line wrap at the largest text size. All values are this project's own provisional choices; none comes from the reference game.

## Goal

Every lot type now has a place-based reason to be put somewhere. Residential and commercial lots read a shared, derived **land value**: parks and water raise it, and developed industry nearby lowers it. Commercial lots also like customers nearby. Industry ignores land value and prefers to be near the outside link, where freight leaves town.

## Rules

### Land value (derived, never saved)

**Field.** Each tile has a value:

- **+2** if a park covers it (D26 coverage, within 3 side-steps, not stacking);
- **+1** if water is within 3 side-steps;
- **−2** for each developed (level 1-2) industrial lot within 2 side-steps, counting at most three.

This is the D33 field, unchanged, now named land value. Distances are footprint to footprint (Manhattan side-steps).

**Lot value.** A lot's value uses the same parts for its whole footprint:

| Lot | Value |
| --- | --- |
| Residential | park + water − industry (D33 unchanged) |
| Commercial | park + water − industry + **customers** (shown to players as "trade"): +1 for each developed residential lot within 3 side-steps, at most +2 |
| Industrial | park + water only; industry does not deter industry |

### Effects

| Type | Growth order | Held |
| --- | --- | --- |
| Residential | Higher value first, then map order (D33) | Below 0: held at level 1; a serviced level-2 lot drops one level per round (D33) |
| Commercial | **Higher value first, then map order** (new; was map order) | **Below 0: held at level 1; a serviced level-2 lot drops one level per round** (new) |
| Industrial | **Fewer freight steps first, then map order** (new; was map order) | Never held by land value |

**Freight steps.** The number of road steps from the outside-link road to the nearest connected road beside the lot: the link road itself is 0. Only connected roads count, so an unserviced lot has no freight distance and cannot grow anyway.

**Drops.** Commercial drops count towards commercial leaving under D32 in the same round, exactly as residential drops already do. No lot loses more than one level per round. Nothing is demolished; cash, zones and the project are untouched. Recovery is normal growth once the value is 0 or more (clear the industry, add a park or let residents grow nearby).

**Unchanged.** Per-type growth budgets (8 levels per round), demand, appeal, tax leaving, services, decline, capacities, prices, the budget and the project. Commercial and industrial still never compete with residential for budget.

### Interface

- **V overlay** is renamed **Land value**. Its marks are unchanged: plus marks for positive points, hatching for negative, smoke on developed industrial lots. Lot tiles show their lot's value, so commercial lots include customers.
- **Inspector legend line** for every zone lot:
  - residential and commercial: "Land value N: park +2, water +1, trade +2, industry −2" (non-zero parts only; "nothing nearby" when empty);
  - industrial: "Freight N road steps · ignores land value" (or "not joined to the link").
- **Inspector reasons.** "Held at L1 by industry" and "Drops to L1 next check (industry)" apply to commercial lots too; "Waiting turn" says "higher land value first" for residential/commercial and "nearer the link first" for industrial.
- **Town summary.** The held item counts held residential and commercial lots and names the type ("2 residential lots held …", "1 commercial lot held …", or "3 lots held …" when mixed).
- **Help, tooltips, status and BUILD_README** describe the three rules.

### Versions and saves

- Game **0.13.0-r2a**, schema **9**, simulation/content **`r2a-1`**. The rules change growth meaning, so the version changes (precedent: M2g). There are **no new saved fields**: schema 9 has exactly the schema-8 fields.
- Schema 8 (`m2g-1`) loads with every value kept (`migrated_from` 8). Schemas 1-7 migrate as before.
- Saving over an older primary or backup first preserves its exact bytes once as `manual.schemaN.json`, as before (now including `manual.schema8.json`).
- Load never writes. The nine fixtures stay byte-identical; a tenth fixture, `r2a-schema9.json`, captures a town with a held commercial lot and an industrial lot that grew first by freight.

## Acceptance checklist

- [x] Unit tests: every value part and radius; the customers cap; industry not deterring industry; commercial order and hold; commercial drop counted with D32 leaving; freight distance and industrial order; recovery after clearing industry; purity and determinism; every earlier fixture migrates; the new fixture's hash, round trip and continuation.
- [x] Packed tests: overlay name; inspector legend for each type at every layout and text size; a held commercial lot through the shipped UI; summary item wording.
- [x] `tools/verify.ps1` passes; nine historical fixtures byte-identical.
- [x] Native posted-input run of the actual EXE: the overlay and a held or reordered lot; profile restored. (The native town showed industry nearest the link first, trade on a commercial lot, and hatching beside industry; its held commercial lot never grew past level 0, so the held commercial lot is covered by packed tests.)
