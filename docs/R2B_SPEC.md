# R2b: density stages and wealth (part 1)

Specified 6 November 2026 under the owner's request to start R2b (U37), from the [roadmap](ROADMAP.md). Adopted as [D37](DECISIONS.md#d37) before model code, then implemented and locally verified as 0.14.0-r2b ([evidence](sessions/2026-11-06-r2b.md)). **Two gate changes during implementation, before any delivery:** commercial lots need 2 more land value than residential (3 / 4), and industry is gated by town residents (100 / 250) instead of being ungated. Without them, trade (+2) and ungated industry let every plain street concentrate levels on one lot, which changed the standard town and contradicted "plain streets stop at level 2". All values are this project's own provisional choices; none comes from the reference game. This is the first part of R2b; the [handoff](../NEXT_SESSION.md) lists what remains.

## Goal

A well-placed town keeps growing past the old ceiling of level 2. Lots can reach levels 3 and 4, which hold far more people, but only where land value is high enough. Plain streets still settle at level 2, so the reward goes to parks, water and good shop placement.

## Rules

### Levels and capacities

Zone lots have levels 0-4 (was 0-2). Capacity is per lot, by level:

| Level | Residential residents | Commercial jobs | Industrial jobs |
| --- | --- | --- | --- |
| 0 | 0 | 0 | 0 |
| 1 | 4 | 2 | 4 |
| 2 | 8 | 4 | 8 |
| 3 | 20 | 10 | 16 |
| 4 | 40 | 20 | 28 |

Levels 1-2 are unchanged. Totals are the sum over lots. Each lot still asks for one power unit at every level (D23; R8 revisits power).

### Land-value gates

A lot's highest allowed level (its cap) is:

| Lot | Cap |
| --- | --- |
| Lot | Below 0 | Level 2 cap | Level 3 needs | Level 4 needs |
| --- | --- | --- | --- | --- |
| Residential | held at 1 (D33) | value 0 | value 1 | value 2 |
| Commercial | held at 1 (D36) | value 0-2 | value 3 | value 4 |
| Industrial | never held | fewer than 100 town residents | 100 residents | 250 residents |

So a park (+2) lets a residential lot reach level 4 and water (+1) level 3. A commercial lot needs trade plus a park (value 4) for level 4. Industry ignores land value (D36) but needs a workforce; residents are the prior completed state.

**Drops.** A serviced lot above its cap drops one level per growth round, as D33 drops do, and the drop counts towards that type's D32 leaving. Nothing is demolished. Raising land value lets it regrow.

### Demand

Demand is still counted in **levels** (the meter and the D22/D32 targets are unchanged). Because upper levels hold more people, each upper level raises the residents/jobs totals more, and those totals feed the D22 targets, so a high-value town keeps generating demand until its lots and gates are full. Per-type growth stays at most 8 levels per round, one level per lot per round.

### Leaving and decline

- D32 leaving takes the highest-level serviced lots first (level 4, then 3, 2, 1), then later map order.
- Service-loss decline is unchanged: one level per two rounds without both services.

### Wealth (derived, display only)

Each developed residential lot has a wealth band from its land value: **modest** (value below 1), **comfortable** (1), **well-off** (2 or more). It is shown in the inspector only. It changes no tax, demand or growth rule in this part.

### Interface

- Inspector: the level shows "L3"/"L4" with the larger residents or jobs; residential lots add the wealth band. New reason **"gated"**: "Level N needs land value V (now X): add a park or water nearby" (commercial: "park or residents"; industry: "L3 needs 100 residents in town (now N)"). The held reason (below 0) is unchanged.
- Town summary: the no-room text also suggests raising land value (industry: growing past 100 residents).
- Art: new original-drawn stages for levels 3 and 4 in the original renderer (taller blocks with more window rows), and taller facades with an original stage marker (small pips) in the Modern City and Tiny City modes.
- Help, BUILD_README and README describe the levels and gates.

### Versions and saves

- Game **0.14.0-r2b**, schema **10**, simulation/content **`r2b-1`**. The field list is unchanged; schema 10 allows development values 0-4 (schemas 3-9 still only 0-2) and a larger budget-ledger resident/job bound.
- Schema 9 loads with everything kept; schemas 1-8 migrate as before. Older bytes are preserved once as `manual.schemaN.json`.
- The ten fixtures stay byte-identical; an eleventh, `r2b-schema10.json`, captures a town with lots at levels 3 and 4.

## Not in this part (remaining R2b)

Wealth affecting tax or appearance, per-level power use, wealth art variants, a separate demand unit (people instead of levels), and any demand-cap rebalancing found in play. R2c (police and fire) adds services as further gates.

## Acceptance checklist

- [x] Unit tests: capacities per level, every gate, drops above the cap counted with leaving, leaving order from level 4, decline, wealth bands, a park town growing past 48 residents and settling, migration of every fixture, the new fixture.
- [x] Packed tests: upper-level lots through the shipped UI, inspector gate reason and wealth at every layout and text size.
- [x] `tools/verify.ps1` passes; ten fixtures byte-identical.
- [x] Native posted-input run of the actual EXE showing level 3-4 lots; profile restored.
