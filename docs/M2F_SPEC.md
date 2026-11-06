# M2f: demand meter and adjustable tax rate

Specified 6 November 2026 at the start of the owner's "Run next session" request (U25), as the first milestone of the city-builder roadmap (U24, candidates 9 and 4 in [the genre table](GENRE_ALIGNMENT.md)). These rules were adopted as [D32](DECISIONS.md#d32) before implementation code, then **implemented and locally verified as game 0.8.0-m2f** ([evidence](sessions/2026-11-06-m2f.md)). All numbers are this project's own provisional choices; none comes from the reference game, and the study notes supply no formulas or values. The meter's layout, wording and art are original.

## Player benefit

- **See what the town needs.** A meter that is always visible shows, for homes, shops and workshops, how many levels the town will currently welcome. It also shows how many will leave when taxes are high.
- **Make a real economic choice.** The tax rate trades money per person against growth:
  - a lower rate brings more homes and businesses but less income per resident and job;
  - a higher rate raises more per person, but growth slows, and above the standard rate surplus buildings lose levels.
- Every effect is derived, deterministic, explained and recoverable, and an unchanged town behaves exactly as it did in 0.7.x.

## Tax rate

- **Range and default.** The rate is a whole percentage from **0% to 25%**, and the **standard rate is 10%**. New towns and every migrated town start at 10%.
- **Taxes per settlement.** Each serviced resident pays **20 cents per percentage point**, and each serviced job **40 cents per point**. At 10% that is $2 and $4, exactly the D25 amounts. The $100 grant, upkeep, waiver, cap and no-debt rules of D25 are unchanged.
- **When it applies.** A settlement uses the rate in force at that moment, after any same-day growth round. Changing the rate never collects or refunds anything by itself.
- **Command.** `set_tax_rate(rate)` is an ordered, validated command that runs between ticks, like construction:
  - It rejects non-integers and values outside 0-25.
  - Setting the current rate is a free no-op: no sequence increment and nothing to save.
  - Any other rate increments the sequence, costs nothing, and refreshes demand and the forecast immediately, including while paused.
  - It never consumes RNG and is refused at the command limit.

## Demand under taxes

D22's prior-state demand rule stays, with tax **appeal** applied to its targets:

- **Appeal.** Appeal = 100 + 4 × (10 − rate) percent. That is 140% at 0%, 100% at 10% and 40% at 25%.
- **Targets.** They are rounded half up in integer arithmetic.
  - Home target = min(2 × map cells, ((3 + floor(J / 2)) × appeal + 50) / 100).
  - Shop target and workshop target = ((ceil(P / 16)) × appeal + 50) / 100.
  - At 10% these equal the D22 targets exactly. At 25% the empty-town starter home target is still 1, so a new town can always begin.
- **Demand.** Demand = max(0, target − existing levels), as before, with the existing eight-level round cap, park priority and row-major order.
- **Growth at lower rates.** Below about 8% the targets no longer settle at a fixed size, so growth is then limited by land, power, the round cap and money rather than by demand. That is the intended reward for low taxes, paid for with less income.

## Leaving under high taxes

- **When it applies.** Only when the rate is **above 10%**. A type's surplus is then max(0, existing levels − its target). At or below 10% the surplus is 0, so D22's "demand alone never evicts" is unchanged at the standard rate.
- **How much leaves.** On each growth round, a type with surplus loses min(surplus, **4**) levels. Each lost level comes from a different developed, serviced lot of that type: level-2 lots first, then lots later in row-major order first.
- **What is not affected.** Unserviced lots are left to the existing service-loss decline. Parks give no protection (D26 unchanged).
- **Same-round rules.** Leaving is planned from the prior completed state and applied with growth and service-loss changes.
  - A type never both grows and loses levels in one round.
  - A lot never loses more than one level per round.
  - A lot at level 0 stays zoned and regrows when demand returns.
  - Nothing is demolished, and no cash changes.

## Demand meter

- **Placement and reading.** The meter is one compact line in the top bar, directly under the population count. It has three entries labelled **H**, **S** and **W**.
  - Each entry shows its letter, a small bar from a centre line (up for demand, down for levels that will leave) and a signed number.
  - Zero shows "0" with no bar.
  - The bar is full at 8 levels, the round cap, on a square-root scale so that a single level is clearly visible. The number shows the true value.
  - It can be read without colour: letters, signs and direction. Bars use the existing palette.
- **Text size.** It is sized from the current text size and fits the top bar at every supported window and text size, without covering the flag, sidebar, inspector or footer.
- **Accompanying text and tooltip.**
  - A tooltip explains the meter.
  - The line under the meter reads "Tax N% · Net $X" (the monthly forecast, with "· DEFICIT" when negative), replacing the old demand and monthly-net text lines.

## Budget and explanations

- **Tax row.** The Budget dialog has a tax row: "Tax rate N%", **−** and **+** buttons (one point each) and a **Standard 10%** button. All are keyboard-focusable inside the dialog.
- **Rate explanation.** Text under the tax row states the per-resident and per-job tax at the current rate, the appeal percentage, and the leaving rule.
- **Forecast and history.** The forecast uses the current rate. The last settlement shows the rate it used.
- **Status line.** A rate change reports the new rate, its per-person tax and its demand effect.
- **Inspector.** It keeps "Demand N" and adds two lot states: **leaving** ("High taxes: loses a level next check") and **surplus** ("Taxes above 10%: more levels may leave"). Help gains one line about the tax rate.

## Saves

- **Format.** Game `0.8.0-m2f`, schema 7, simulation/content `m2f-1`.
- **Schema 7 records.**
  - Schema 7 stores a required top-level integer `tax_rate` in 0-25.
  - Every non-empty `last_budget` record also stores the `tax_rate` it settled at, with the same strict range.
  - An empty ledger stays `{}`.
- **Migration from schema 6.** Everything is kept unchanged, footprints included. The town gains `tax_rate` 10, and a non-empty ledger gains `tax_rate` 10, the rate it actually used.
- **Migration from schemas 1-5.** They keep D30's clearing migration and gain the same tax fields.
- **Rejection.** Earlier schemas containing `tax_rate` anywhere are rejected unchanged.
- **Preservation.** Load never writes. Older primary and backup bytes are preserved once as `manual.schemaN.json` (now including schema 6) before replacement.
- **Fixtures.** All seven existing fixtures stay byte-identical. A new schema-7 fixture records a non-standard rate and a ledger at that rate.

## Acceptance checklist

1. At 10%, an existing schema-6 town migrates and then evolves identically to 0.7.x: same growth, settlements and cash.
2. Taxes are exact integer cents at 0%, 10% and 25%. The forecast, settlement and last-settlement display agree.
3. Appeal changes demand as specified: the 25% starter is never 0, and demand at a low rate exceeds demand at the standard rate.
4. Above 10%, surplus leaves at most 4 levels per type per round, in the specified order. It stops at the target and never affects unserviced lots. A town recovers after the rate is lowered.
5. The tax command is validated, ordered, free and deterministic. A no-op does not advance the sequence. Replays and save/load continuation match an uninterrupted town.
6. Schema-7 round trips are exact. Schemas 1-6 migrate as specified, with preserved originals. Malformed rates or ledger rates are rejected without replacing the live town. Fixture hashes are unchanged.
7. The meter and Budget tax row work in the exported game at 1280x720, 1366x768, 1920x1080 and 1280x800, with text 16, 18 and 20, and nothing overlaps the flag, sidebar, inspector or footer.
8. Pinned `tools/verify.ps1` passes. Native EXE checks show the meter, a rate change through the Budget dialog, and save/load. The package builds.

Out of scope: the M2g desirability overlay, workshop nuisance, the town summary, the guide, other balance changes, autosaves, the controller route and final art/audio.
