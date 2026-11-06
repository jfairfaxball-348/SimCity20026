# R2c: first civic services (police and fire)

Specified 6 November 2026 under the owner's "Run next session" request (U38), from the [roadmap](ROADMAP.md) and the [handoff](../NEXT_SESSION.md). Adopted as [D38](DECISIONS.md#d38) before model code, then implemented and locally verified as 0.15.0-r2c ([evidence](sessions/2026-11-06-r2c.md)). **Revised during implementation, before delivery:** the reach is 12 side-steps (the first draft said 10), because one central police and fire pair could not otherwise cover the standard six-lot street; and park, police and fire share one sidebar row, with the cover line shown in the legend only while the Services overlay is on, so the sidebar and inspector keep their size at the largest text. All values are this project's own provisional choices; none comes from the reference game. The study note that rejected police coverage "for the current scope" (written before U17) is superseded by the owner's roadmap; only its advice that funded facilities explain what they provide is used.

## Goal

The top density stage becomes a reward for looking after the town, not only for placing parks and water. A lot can reach level 4 only when a working police station **and** a working fire station are close enough. There is still no crime, no fire and no disaster: coverage only unlocks growth and never destroys anything.

## Rules

### Buildings

| Building | Occupancy ID | Footprint | Price | Upkeep / month | Key |
| --- | --- | --- | --- | --- | --- |
| Police station | 7 | 3x3 | $400 | $30 | 9 |
| Fire station | 8 | 3x3 | $400 | $30 | 0 |

- Placed like a power plant: one per placement, anchored at its top-left tile, the pointer at its centre; empty land only, not water or the outside-link flag. Clear removes the whole footprint for free.
- Neither building carries roads or power; they never join a network (D19 networks are roads and power plants only).

### Working

A station **works** when it has both:

- **Road access**: a connected road (D17) on a side-sharing perimeter tile, as for lots (D30);
- **Power**: one power unit, allocated with zone lots by the existing nearest-first rule (D23/D30): the same `(distance, anchor index)` order and the same capacity. A station in a shortage does not work.

Unused (not working) stations still cost upkeep, as every facility does (D25).

### Coverage

- A working station covers every zone lot whose footprint is within **12 side-steps** of its footprint (Manhattan gap between the two squares, so touching footprints are 1 apart). Terrain, water and roads between them do not matter.
- Overlapping stations do not stack; a lot is simply covered or not, separately for police and fire.
- Coverage is derived from the current town after every command and load, and is never saved.

### Level gate

- **Level 4** for every zone type needs police **and** fire coverage, in addition to the D37 land-value and workforce gates. Without both, a lot's cap is at most 3.
- Levels 0-3 are unchanged (no service is needed for level 3).
- A serviced lot above its cap drops one level per growth round, exactly as D37 drops do, counting towards that type's D32 leaving. Removing a station therefore lets level-4 lots drop to 3 gently; restoring cover lets them regrow. Nothing is demolished.

### Budget (D25 extended)

- Expenses add `$30 × police stations + $30 × fire stations`, counted per station anchor, including stations that do not work.
- The settlement ledger records `police` and `fire` counts beside `roads`, `stations` (power plants) and `parks`.
- The no-debt waiver (U32) is unchanged.

### Interface

- **Tools.** "8 Park", "9 Police" and "0 Fire" share one sidebar row; prices and upkeep are in their tooltips. The preview shows the price and what the station covers.
- **Overlay.** C (and Display) toggles the **Services** overlay. Tiles within reach of a working police station show a small square mark; tiles within reach of a working fire station show a small triangle mark; both marks together mean full cover. Stations that do not work show a cross. Never saved; readable without colour.
- **Inspector.** A station states whether it works and why not (road access, power), its reach and how many zone lots it covers. With the Services overlay on, a zone lot's legend line shows its cover ("police and fire cover", "police cover only", "fire cover only" or "no police or fire cover") in place of its land-value parts, as V does for land value. New reason **"uncovered"**: "L4 needs police and fire cover (missing fire)". Drops for this reason say "Drops to L3 next check: needs police and fire cover".
- **Town summary.** A blocker item "N lots need police and fire cover to reach level 4" (levels affected = lots), with Show; and a status item when any station does not work ("N police/fire stations are not working: give them road access and power"), with Show.
- **Budget.** Upkeep lines include police and fire stations; the recovery line mentions them.
- **Help, BUILD_README, guide.** Describe the buildings, the reach and the level-4 rule. The First steps card is unchanged (its five steps end before level 4).
- **Art.** Original buildings in all three art modes: in the original renderer a slate police station with a shield sign and a brick fire station with two bay doors and a hose tower with a flame sign; in the Kenney modes the pack's building tiles with the same original signs. Shapes differ, not only colours.

### Versions and saves

- Game **0.15.0-r2c**, schema **11**, simulation/content **`r2c-1`**.
- Schema 11 allows occupancy IDs 7 and 8 as whole 3x3 footprints with no development or service-loss state, and its non-empty ledger has exactly the keys `tick, opening_cash, residents, jobs, roads, stations, parks, police, fire, tax_rate`.
- Schema 10 loads with everything kept; a non-empty ledger gains `police: 0, fire: 0`. Schemas 1-9 migrate as before. Older bytes are preserved once as `manual.schemaN.json`.
- Earlier schemas reject IDs 7 and 8 and the new ledger keys.
- The eleven fixtures stay byte-identical. Their migrated expectations change only where level-4 lots now lack cover (the R2b fixture's two level-4 lots drop to 3 at the next round). A twelfth fixture, `r2c-schema11.json`, captures a town with both stations, covered level-4 lots and a ledger with station counts.

## Changes to earlier rules

- **D37**: the level-4 cap additionally needs police and fire coverage. Capacities, the other gates, wealth, leaving order and drops are unchanged.
- **D25**: two new upkeep lines and two ledger counts. Grant, taxes, waiver, cap and no-debt rules are unchanged.
- **D23/D30**: stations draw one power unit each in the same nearest-first allocation as lots, and are served by road access the same way.
- **D27/D37 saves**: schema 11 as above.
- D17-D22, D24, D26, D28, D29, D31-D36 are otherwise unchanged.

## Not in this part

Crime and fire fields, fires and disasters (R9, R14), service funding levels (R10), and the remaining R2b items (wealth effects and art variants, per-level power, demand in people), which are left for a later balance pass.

## Acceptance checklist

- [x] Unit tests: placement and clearing, working (access, power, shortage), coverage at radius 12 and 13 and across water, cover on a lot, budget and ledger accounting, the level-4 gate and its drop counted with leaving, a covered park town reaching level 4 while an uncovered one stops at 3, migration of every fixture, the new fixture, determinism.
- [x] Packed tests through the shipped UI: both tools, overlay, inspector and summary at every layout and text size.
- [x] `tools/verify.ps1` passes; eleven fixtures byte-identical.
- [x] Native posted-input run of the actual EXE showing both stations and a lot that reaches level 4 only with cover; profile restored.
