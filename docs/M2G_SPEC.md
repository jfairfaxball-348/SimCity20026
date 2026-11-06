# M2g: neighbourhood desirability and workshop nuisance

Specified 6 November 2026 at the start of the owner's "Keep going run next one" request (U26), as the second milestone of the city-builder roadmap (U24, candidates 2 and 3 in [the genre table](GENRE_ALIGNMENT.md)). These rules were adopted as [D33](DECISIONS.md#d33) before implementation code, then **implemented and locally verified as game 0.9.0-m2g** ([evidence](sessions/2026-11-06-m2g.md)).

**Sources of the rules.**

- The numbers, layout and wording are this project's own provisional choices.
- The permitted study notes contribute only principles: visible sources, an explained local consequence, and separate explanations rather than an opaque aggregate.
- No reference formulas, values or presentation are used.

## Player benefit

Where homes are zoned now matters:

- **Pleasant surroundings attract homes.** Homes near parks and water grow first.
- **Workshops deter nearby homes.** A home lot near developed workshops stops at level 1 until the player separates them or adds a park.

This is the classic "separate your zones" tension, with a road-plus-buffer or a park as the fix. Every number behind a home's score is shown in the inspector and on an optional map overlay. Nothing is ever demolished.

## Desirability

Desirability is derived and integer, and is recomputed whenever development or construction changes. **Only home lots use it in M2g.** Shops and workshops keep map order and are not affected.

A home lot's score is the sum of three parts. Distances are Manhattan distances between footprints, and zero parts are omitted from explanations.

| Part | Rule | Value |
| --- | --- | --- |
| Park | A park within 3 side-steps (the existing D26 coverage). Overlap does not stack | **+2** |
| Water | A water tile within 3 side-steps | **+1** |
| Workshops | Each *developed* (level 1 or 2) workshop lot within **2** side-steps, counting at most 3 | **−2 each** (floor −6) |

**Range and examples.**

- The score runs from −6 to +3.
- An empty workshop lot causes no nuisance.
- A home directly across a one-tile road from a developed workshop is 2 steps away, so it is affected. A home with a further row of anything between is not.
- A park offsets one workshop.

The **overlay field** uses the same parts per tile (tile-to-footprint distances), so a player can judge land before zoning. The tiles of a home lot show that lot's score.

## Effects on homes

1. **Growth order.** Each growth round reserves home demand in order of desirability (higher first), then map order. Without water or workshops this equals D26's "park-covered homes first", which D33 generalises. Demand, the eight-per-round cap and the service requirements are unchanged.
2. **Held back.** A home lot with a score **below 0** can develop only to **level 1**.
3. **Gentle drop.**
   - **Rule.** A serviced level-2 home whose score falls below 0 loses one level at the next growth round, and never more than one level per lot per round.
   - **Recovery.** Clearing or separating the workshops, or adding a park, restores level 2 through normal growth.
   - **What is kept.** The lot stays zoned. Cash, the project and other lots are untouched.
4. **With tax leaving (D32).** A lot dropping for nuisance counts towards its type's leaving for that round, so the D32 limit of 4 is not exceeded. Tax leaving then picks other lots by the D32 order.

Unserviced lots keep the D22 service-loss decline. The D28 project still counts developed, serviced home lots near the park.

## Overlay and explanations

- **Overlay toggle.** **V** toggles a desirability overlay, and the Display dialog has the same toggle. It starts off and is never saved.
  - Positive tiles get a light tint and one small "+" per point.
  - Negative tiles get a warm tint and diagonal hatching: one stripe per 2 points, rounded up, at most 3.
  - Developed workshops, the nuisance sources, get a small smoke mark.
  - Meaning never relies on colour alone.
- **Legend.** While the overlay is on, the inspector legend line explains the marks.
- **Inspector.** For a home lot the legend line reads "Desirability N: park +2, water +1, workshops −2" (only non-zero parts), replacing the old park-priority note. The growth text adds the reasons **held** ("Held at L1 by workshops: add a park within 3 or move them 3+ away") and **dropping** ("Drops to L1 next check (workshops): …"). This keeps the inspector within its fixed height at every text size.
- **Help.** Help gains two lines.

## Saves

- **Format.** Desirability is derived and never saved. Because it changes how a saved town evolves, M2g uses game `0.9.0-m2g`, **schema 8** and simulation/content `m2g-1`, with no new fields.
- **Migration.** Schema 7 migrates with every value unchanged. Schemas 1-6 migrate as before, through D32's standard rate.
- **Preservation.** Older primary and backup bytes are preserved once as `manual.schemaN.json`, now including schema 7.
- **Fixtures.** The eight existing fixtures stay byte-identical. A schema-8 fixture records a park offsetting a workshop beside a held home.

## Acceptance checklist

1. Scores match the table for parks, water and 0-4 developed workshops, including the floor, empty workshops, and distances 2 and 3.
2. Home growth order follows the score, then map order. Without water or workshops it is unchanged from D26.
3. Held homes stop at level 1. Level-2 homes drop one level per round when their score turns negative. Clearing the workshop or adding a park restores growth to level 2. No zone, cash or project change results.
4. Nuisance drops and D32 leaving together stay within one level per lot per round and the type's leaving limit.
5. Determinism, replay and save/load continuation hold. Schema-8 round trips are exact. Schemas 1-7 migrate with preserved originals. Fixture hashes are unchanged.
6. The overlay toggles with V and from Display. The inspector explains the parts and the held/dropping reasons. Everything fits at all four window sizes and three text sizes in the exported game.
7. Pinned `tools/verify.ps1` passes. Native EXE checks show the overlay, a held home and its recovery, and save/load. The package builds.

Out of scope: desirability for shops and workshops, nuisance from stations or roads, traffic, the M2h town summary, the guide, autosaves, the controller route and final art/audio.
