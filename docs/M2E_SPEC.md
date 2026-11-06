# M2e: three-by-three zone lots and four-by-four power stations

Scoped 6 November 2026 after owner design notes during the M3b scoping session (U16, U18, U19). **Specified, not implemented.** This is proposed D30. Adopt these rules in Decisions before writing implementation code. M2e comes before the M3b guide; see [M3b](M3B_SPEC.md#dependency-on-m2e).

## Owner requirement and intent

U16: homes, shops and workshops become multi-tile buildings, not single tiles; roads stay one tile. **U19 sets their size to 3x3**, as in the original game. U16 had first proposed 4x4.

M2e changes building geometry only. A **lot** replaces today's single-tile **plot** one-for-one: same price, same one power unit, same levels, capacities, demand, growth, decline, taxes and park priority. Changing geometry alone keeps every adopted number in D19-D28 meaningful and testable. It also makes balance changes a separate, later decision.

U18: power stations are also **4x4** buildings. The owner's guiding preference is whichever option is closest to the original game, within copyright limits, and power plants there were 4x4. A station keeps its $500 price, 20-unit capacity and $60/month upkeep, now per 4x4 station. Pocket parks stay one tile, which also matches the original's single-tile parks.

**Sizes are settled.** Zone lots are 3x3 (U19) and power stations 4x4 (U18). These footprint sizes are general knowledge of the published game's play; they were not taken from its source. All rules, numbers, art and text below are this project's own.

## Proposed rules (D30)

### Footprint and identity

- A lot is a 3x3 square of land tiles. Its **anchor** is its top-left tile, and its identity and order are the anchor's row-major index.
- **Occupancy.** All 9 tiles carry the zone's existing occupancy ID (home 2, shop 4, workshop 5). Lots never overlap.
- **Per-lot state.** Development level (0-2) and the service-loss counter (0-1) belong to the lot. They are stored on the anchor tile; the other 8 tiles hold zero.
- No other lot size, rotation, merged lot, or zone smaller than a lot exists.

### Placement (tools 2, 6, 7)

- **Preview position.** The pointer tile is the lot's centre, at offset (1, 1) from the anchor, so the lot sits under the pointer. The preview outlines the whole footprint.
- **Click and drag.** A click places one lot. Dragging extends a straight row or column of adjacent lots from the first lot. The run follows the drag's dominant axis (ties count as horizontal), adding one lot for every whole 3-tile step from the press tile toward the pointer.
- **Validation.** All 9 tiles of every lot must be land, empty and inside the map. No lot may cover the outside-link flag; this extends the existing station/park flag rule to zones. Validate the whole stroke before any charge (atomic, as today).
- **Price.** **$25 per lot** (the existing zone price, now charged per lot). An identical lot of the same type at the same anchor costs nothing and is skipped. In a mixed stroke, only the new lots are charged. Partly overlapping a different lot, road, station or park rejects the stroke with the existing "clear first" message.
- **Clear (tool 3).** Clearing any tile of a lot removes the whole lot, for free and with no refund. A clear stroke removes the union of its tiles plus the full footprint of every lot it touches. The preview highlights everything that will be removed.
- Roads, stations and parks still need empty land, so they cannot be placed on lot tiles.

### Power station footprint (U18; revises the D19 station shape)

- A station is a 4x4 square of land tiles, all carrying occupancy ID 3, with its anchor at the top-left tile. The pointer tile is at offset (1, 1) from the anchor, as for lots. Tool P places **one station per command**; a drag only moves the preview, as today.
- **Validation.** All 16 station tiles must be land, empty and inside the map, and must not cover the outside-link flag. Price **$500 per station**, charged atomically.
- **Clear.** Clearing any station tile removes the whole station, for free and with no refund (same rule as lots).
- **Network.** All 16 station tiles are network tiles at station distance 0. Roads or other stations sharing a side with any of them join that network, and a lot beside any station tile can draw from it. Stations still carry no road access.
- **Counting by station, not tile.** Capacity is the number of stations (anchors) on a network x 20 units; one 4x4 station supplies 20, not 320. Upkeep counts stations by anchor: $60/month per station, not per tile. The toolbar total, inspector and budget count stations the same way.

### Road access (revises D17/D18 geometry)

- A lot has road access when a road tile joined to the outside link shares a side with any of its 9 tiles. Each side of a lot has three neighbouring positions.
- Contact at a corner only, through a diagonal, does not count.
- Lots do not relay access. A road between two lots serves both.
- The outside-link marker, the root road and the network rules are otherwise unchanged.

### Power (revises D19/D23 geometry)

- **Demand.** Each lot requests **one unit**, developed or not. A station still supplies 20 units, which is now 20 lots.
- **Reaching a network.** A lot can draw from any network that has a road or station sharing a side with any of its tiles.
- **Distance.** A lot's distance through a network is 1 plus the smallest station distance among that network's tiles beside the lot.
- **Allocation order.** Lots are served in ascending order of (distance, anchor index). Each takes one unit from the touching network with spare capacity that has the smallest (distance, network order).
- Allocation stays derived and is never saved. Lots carry no power.

### Growth, budget, park and project (geometry only)

- **Growth (D22-D24).** Growth evaluates lots in place of plots: one level per lot per round, maximum level 2, eight levels per type per round, and ties broken by anchor order. Demand formulas, capacities per level (4 residents; 2 or 4 jobs), starter demand and two-round decline are unchanged.
- **Budget (D25).** Taxes count serviced lots' residents and jobs, so the formulas and values are unchanged. Zones still have no upkeep.
- **Park (D26).** The park stays one tile, priced at $100 with $10/month upkeep. A home lot is covered when any of its tiles is within Manhattan distance 3 of the park tile. Overlapping coverage still does not stack.
- **Project (D28).** The project needs three distinct developed home lots, each with road access and power and each with a tile within distance 3 of the chosen park. A level-2 lot counts once. The completion record and its rules are unchanged.
- **Feasibility.** One layout that works: a park at (10,10) with a road along row 11. Home lots go at x 6-8 and 11-13 on rows 8-10, and at x 9-11 on rows 12-14. Their nearest tiles are 2, 1 and 2 steps from the park. All three lots touch the road, and none overlaps the park. The implementation must assert such a case.

### Presentation

- **Buildings.** Draw original code-drawn 3x3 lot buildings and a 4x4 station building: an outlined empty parcel with the zone's existing symbol at level 0, and distinct single and larger buildings at levels 1 and 2. Keep the home roof, shop awning and workshop sawtooth families, recognisable by shape as well as colour.
- **Marks and inspection.** Draw road and power marks once per lot, at the anchor tile's mark positions. Hovering any tile of a lot inspects that lot, with the existing access, power and growth reasons.
- **Wording.** Change "plot" to "lot" in the inspector, sidebar prices, Help, README and status text, so the sidebar reads "2 Homes · $25/lot". Leave the existing layout and dialog structure unchanged.
- **Scale.** At zoom 1 a lot is 48x48 world pixels and a station 64x64, so the 640x360 view shows about thirteen by seven lots. Zoom levels stay 1-3.

## Saves and migration

- **New format.** Game `0.7.0-m2e`, schema **6**, simulation/content **m2e-1**. It adds one strict byte array, `footprint_anchor`, with exactly one value per cell, each 0 or 1. It marks the anchors of both zone lots and power stations.
- **Validation.** Every anchor's footprint must lie inside the map. All its tiles must hold one ID: a zone ID for a 3x3 lot, or 3 for a 4x4 station. Footprints must not overlap. Every zone or station tile must belong to exactly one anchor. Development and loss values may be non-zero only on zone anchors. All earlier strict rules still apply, including the project, ledger and RNG rules. Reject anything else without replacing the live town.
- **Older saves (schemas 1-5).** They cannot carry 3x3 lots or 4x4 stations. After validating each under its original meaning, migration turns every home, shop, workshop and single-tile station tile into empty land, with zero development and loss.
  - *Kept unchanged:* terrain, roads, parks, cash, tick, pending time, RNG state, sequence, the last-budget record and the project record. The park anchor stays if that park still exists.
  - *What the player sees:* the load message states how many old single-tile zone and station tiles were cleared, and that loading wrote nothing.
  - *Original bytes:* saving preserves them once as `manual.schema1-5.json` before any replacement, extending the existing mechanism to schema 5. A failed preservation aborts the save.
  - *Superseded rule:* this replaces only the "retain development" parts of the D24/D27/D28 migration rules for loading into `m2e-1`.
- **Fixtures.** All six historical fixtures stay byte-identical; only their migrated expectations change. Add a schema-6 fixture with developed lots, a 4x4 station, a park, a ledger and a completed project. Older builds reject schema 6, so roll back using the preserved original.

## Implementation boundary

- **Model:** footprint helpers for lots and stations (footprint, anchor lookup, perimeter) live in the model, in `city_state.gd` or a small `sim/lots.gd`. `road_access.gd`, `power_grid.gd`, `growth.gd`, `amenity.gd`, `economy.gd` and the project count are adapted to iterate lots and to count stations by anchor. Commands keep their ordered, atomic, no-RNG contract.
- **Persistence:** the schema-6 codec, the migration and schema-5 preservation, with no change to the store's general rotation rules.
- **Presentation:** lot and station previews and stroke stepping in `main.gd`, original code-drawn 3x3 lot and 4x4 station buildings and per-lot marks in `world_view.gd`, and wording changes.
- **Out of scope:** new zone types, price or balance changes, larger parks, other station sizes, other lot sizes, rotation, automatic roads, variable building shapes, guided-opening work and any other M3 feature.

## Acceptance checklist for the implementation session

| Area | Required observable evidence |
| --- | --- |
| Placement | Single lot and dragged rows/columns place correctly, including the dominant-axis tie. Rejections are atomic for water, partial overlap, the map edge and the flag. An identical repaint is free; a mixed repaint/new stroke charges only new lots. Prices are exact per lot. Clearing any lot tile removes the whole lot for free, and a clear stroke works across several lots and roads. |
| Access | Access works through each side and each of the three edge positions. Corner-only contact is excluded. Lots do not relay access, a shared road serves lots on both sides, and disconnection and reconnection are immediate. |
| Power | One unit per lot: 21 lots on one station leave the farthest one short. Distance is measured to the nearest perimeter tile, and anchor ties break as specified. Separate networks and nearer-lot displacement give the expected results, and power never passes through lots. |
| Growth and economy | A mixed serviced town built from lots reaches the same aggregate totals as the corresponding plot scenario (48 residents / 18 jobs under these rules). Caps, decline, regrowth, park priority (radius 3/4 boundary, overlap) and month settlement match the per-plot expectations. |
| Stations | A 4x4 station places atomically for $500 and is rejected on water, overlap, the map edge and the flag. A drag places one station. Clearing any tile removes the whole station. Roads and lots beside any station tile join or draw from its network. One station gives 20 units of capacity, and upkeep is $60 per station, not per tile. Stations carry no road access. |
| Project | The specified three-lot layout completes; shop/workshop lots and unserviced lots are excluded; a level-2 lot counts once; clearing and replacing a lot follow D28. |
| Saves | Exact schema-6 round trips. Strict rejections: overlapping footprints, an orphan zone tile, an out-of-range footprint, mixed IDs, an anchor on a non-zone tile, development on a non-anchor tile. Schemas 1-5 migrate with zones and single-tile stations cleared and everything else kept. Schema-5 primary/backup preservation works, including injected failure. Six historical hashes are unchanged and the new schema-6 fixture continues across a month. |
| Packed UI and layout | Click, drag and clear lots through real pointer events. The preview shows the footprint and cost, marks appear once per lot, and any lot tile inspects the lot. The four existing sizes x three text sizes still pass. |
| Actual Windows EXE | **Build:** from an empty town, build roads, a 4x4 station, home/shop/workshop lots and a park, then run to growth and complete the project. **Look:** inspect the 3x3 lots and 4x4 station at zoom 1-3. **Persistence:** save, exit, restart and load; then load a schema-5 save and confirm the clearing message and the preserved original. **Profile hygiene:** record and restore the save path the process resolved, and close the process. |

Run the pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. Record actual counts and limits.

## Original assets and stop point

The 3x3 lot and 4x4 station placeholders are to be drawn with code by this project's implementation and recorded in `licenses/ASSETS.md`. No external art, generated bitmaps, reference source or new licence is needed.

Stop after lots, stations, migration, art, tests, native evidence, documentation/handoff and authorised delivery. The M3b guide follows in its own session.

**Balance note.** Keeping $25 and one power unit per lot, and $500 / 20 units per station, keeps each building's economics unchanged, but every building now needs more land and road frontage. Roads cost $10 plus $1/month. That trade-off is provisional; observe it in the M3 playtests rather than tuning it here.
