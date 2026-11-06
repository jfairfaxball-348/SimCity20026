# M2e: four-by-four zone lots

Scoped 6 November 2026 after an owner design note during the M3b scoping session (U16). **Specified, not implemented.** This is proposed D30. Adopt these rules in Decisions before writing implementation code. M2e comes before the M3b guide; see [M3b](M3B_SPEC.md#dependency-on-m2e).

## Owner requirement and intent

U16: homes, shops and workshops are **4x4-tile** buildings, not single tiles. Roads stay one tile.

M2e changes building geometry only. A **lot** replaces today's single-tile **plot** one-for-one: same price, same one power unit, same levels, capacities, demand, growth, decline, taxes and park priority. Changing geometry alone keeps every adopted number in D19-D28 meaningful and testable. It also makes balance changes a separate, later decision.

Power stations and pocket parks stay one tile, because U16 names only residential, commercial and industrial buildings. Making them larger is a later owner decision.

## Proposed rules (D30)

### Footprint and identity

- A lot is a 4x4 square of land tiles. Its **anchor** is its top-left tile, and its identity and order are the anchor's row-major index.
- **Occupancy.** All 16 tiles carry the zone's existing occupancy ID (home 2, shop 4, workshop 5). Lots never overlap.
- **Per-lot state.** Development level (0-2) and the service-loss counter (0-1) belong to the lot. They are stored on the anchor tile; the other 15 tiles hold zero.
- No other lot size, rotation, merged lot, or zone smaller than a lot exists.

### Placement (tools 2, 6, 7)

- **Preview position.** The pointer tile is the footprint's tile at offset (1, 1) from the anchor, so the lot sits roughly under the pointer. The preview outlines the whole footprint.
- **Click and drag.** A click places one lot. Dragging extends a straight row or column of adjacent lots from the first lot. The run follows the drag's dominant axis (ties count as horizontal), adding one lot for every whole 4-tile step from the press tile toward the pointer.
- **Validation.** All 16 tiles of every lot must be land, empty and inside the map. No lot may cover the outside-link flag; this extends the existing station/park flag rule to zones. Validate the whole stroke before any charge (atomic, as today).
- **Price.** **$25 per lot** (the existing zone price, now charged per lot). An identical lot of the same type at the same anchor costs nothing and is skipped. In a mixed stroke, only the new lots are charged. Partly overlapping a different lot, road, station or park rejects the stroke with the existing "clear first" message.
- **Clear (tool 3).** Clearing any tile of a lot removes the whole lot, for free and with no refund. A clear stroke removes the union of its tiles plus the full footprint of every lot it touches. The preview highlights everything that will be removed.
- Roads, stations and parks still need empty land, so they cannot be placed on lot tiles.

### Road access (revises D17/D18 geometry)

- A lot has road access when a road tile joined to the outside link shares a side with any of its 16 tiles. Each side of a lot has four neighbouring positions.
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
- **Feasibility.** One layout that works: a park at (10,10) with a road along row 11. Home lots go at x 5-8 and 11-14 on rows 7-10, and at x 8-11 on rows 12-15. All three lots touch the road and lie within distance 3 of the park. The implementation must assert such a case.

### Presentation

- **Buildings.** Draw original code-drawn 4x4 buildings: an outlined empty parcel with the zone's existing symbol at level 0, and distinct single and larger buildings at levels 1 and 2. Keep the home roof, shop awning and workshop sawtooth families, recognisable by shape as well as colour.
- **Marks and inspection.** Draw road and power marks once per lot, at the anchor tile's mark positions. Hovering any tile of a lot inspects that lot, with the existing access, power and growth reasons.
- **Wording.** Change "plot" to "lot" in the inspector, sidebar prices, Help, README and status text, so the sidebar reads "2 Homes · $25/lot". Leave the existing layout and dialog structure unchanged.
- **Scale.** At zoom 1 a lot is 64x64 world pixels, so the 640x360 view shows about ten by five lots. Zoom levels stay 1-3.

## Saves and migration

- **New format.** Game `0.7.0-m2e`, schema **6**, simulation/content **m2e-1**. It adds one strict byte array, `lot_anchor`, with exactly one value per cell, each 0 or 1.
- **Validation.** Every anchor's footprint must lie inside the map. All 16 tiles must hold one zone ID, and footprints must not overlap. Every zone tile must belong to exactly one anchor. Development and loss values may be non-zero only on anchors. All earlier strict rules still apply, including the project, ledger and RNG rules. Reject anything else without replacing the live town.
- **Older saves (schemas 1-5).** They cannot carry lots. After validating each under its original meaning, migration turns every home, shop and workshop tile into empty land, with zero development and loss.
  - *Kept unchanged:* terrain, roads, stations, parks, cash, tick, pending time, RNG state, sequence, the last-budget record and the project record. The park anchor stays if that park still exists.
  - *What the player sees:* the load message states how many old single-tile zone tiles were cleared, and that loading wrote nothing.
  - *Original bytes:* saving preserves them once as `manual.schema1-5.json` before any replacement, extending the existing mechanism to schema 5. A failed preservation aborts the save.
  - *Superseded rule:* this replaces only the "retain development" parts of the D24/D27/D28 migration rules for loading into `m2e-1`.
- **Fixtures.** All six historical fixtures stay byte-identical; only their migrated expectations change. Add a schema-6 lot fixture with developed lots, a park, a ledger and a completed project. Older builds reject schema 6, so roll back using the preserved original.

## Implementation boundary

- **Model:** lot helpers (footprint, anchor lookup, lot perimeter) live in the model, in `city_state.gd` or a small `sim/lots.gd`. `road_access.gd`, `power_grid.gd`, `growth.gd`, `amenity.gd`, `economy.gd` and the project count are adapted to iterate lots. Commands keep their ordered, atomic, no-RNG contract.
- **Persistence:** the schema-6 codec, the migration and schema-5 preservation, with no change to the store's general rotation rules.
- **Presentation:** lot preview and stroke stepping in `main.gd`, lot drawing and per-lot marks in `world_view.gd`, and wording changes.
- **Out of scope:** new zone types, price or balance changes, larger stations or parks, other lot sizes, rotation, automatic roads, variable building shapes, guided-opening work and any other M3 feature.

## Acceptance checklist for the implementation session

| Area | Required observable evidence |
| --- | --- |
| Placement | Single lot and dragged rows/columns place correctly, including the dominant-axis tie. Rejections are atomic for water, partial overlap, the map edge and the flag. An identical repaint is free; a mixed repaint/new stroke charges only new lots. Prices are exact per lot. Clearing any lot tile removes the whole lot for free, and a clear stroke works across several lots and roads. |
| Access | Access works through each side and each of the four edge positions. Corner-only contact is excluded. Lots do not relay access, a shared road serves lots on both sides, and disconnection and reconnection are immediate. |
| Power | One unit per lot: 21 lots on one station leave the farthest one short. Distance is measured to the nearest perimeter tile, and anchor ties break as specified. Separate networks and nearer-lot displacement give the expected results, and power never passes through lots. |
| Growth and economy | A mixed serviced town built from lots reaches the same aggregate totals as the corresponding plot scenario (48 residents / 18 jobs under these rules). Caps, decline, regrowth, park priority (radius 3/4 boundary, overlap) and month settlement match the per-plot expectations. |
| Project | The specified three-lot layout completes; shop/workshop lots and unserviced lots are excluded; a level-2 lot counts once; clearing and replacing a lot follow D28. |
| Saves | Exact schema-6 round trips. Strict rejections: overlapping footprints, an orphan zone tile, an out-of-range footprint, mixed IDs, an anchor on a non-zone tile, development on a non-anchor tile. Schemas 1-5 migrate with zones cleared and everything else kept. Schema-5 primary/backup preservation works, including injected failure. Six historical hashes are unchanged and the new schema-6 fixture continues across a month. |
| Packed UI and layout | Click, drag and clear lots through real pointer events. The preview shows the footprint and cost, marks appear once per lot, and any lot tile inspects the lot. The four existing sizes x three text sizes still pass. |
| Actual Windows EXE | **Build:** from an empty town, build roads, a station, home/shop/workshop lots and a park, then run to growth and complete the project. **Look:** inspect the 4x4 buildings at zoom 1-3. **Persistence:** save, exit, restart and load; then load a schema-5 save and confirm the clearing message and the preserved original. **Profile hygiene:** record and restore the save path the process resolved, and close the process. |

Run the pinned `tools/verify.ps1`, the native EXE checks, then `tools/package.ps1`. Record actual counts and limits.

## Original assets and stop point

The 4x4 building placeholders are to be drawn with code by this project's implementation and recorded in `licenses/ASSETS.md`. No external art, generated bitmaps, reference source or new licence is needed.

Stop after lots, migration, art, tests, native evidence, documentation/handoff and authorised delivery. The M3b guide follows in its own session.

**Balance note.** Keeping $25 and one power unit per lot keeps each building's economics unchanged, but every building now needs more land and road frontage. Roads cost $10 plus $1/month. That trade-off is provisional; observe it in the M3 playtests rather than tuning it here.
