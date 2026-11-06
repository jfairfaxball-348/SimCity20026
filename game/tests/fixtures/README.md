# Save compatibility fixtures

Preserve these bytes. Each file is UTF-8 with one trailing LF; `.gitattributes` keeps JSON at LF so checkout does not change the hashes. Fixtures and test drivers are excluded from the Windows PCK.

| File | Written by | SHA256 |
| --- | --- | --- |
| `m1-schema1.json` | Unchanged M1 `city_state.gd`, before M2a | `f954b5c782f32d240e54912baea00ac6960b599fe5aa90f4eed96efeceadbb83` |
| `m2a-schema1.json` | Unchanged M2a code (commit `1e1d143`), before M2b | `a85895efbc23707538a8c97399a7cf9bd831bfeb21b8182144b68653d82f0c93` |
| `m2b-schema2.json` | Final M2b code, continuing the M2a fixture | `27dbbaefca8ec3e1419d61b0e278c855cd8392c81d76b553128cf9c4c2b8c37a` |
| `m2d-schema4.json` | M2d town at next-month boundary, with park and prior ledger | `59bdaa0de040c6a6ab8afb8ce48779312e4731a55c28e3a88005d0d415d445be` |
| `m2c-schema3.json` | M2c code, mixed town with pending decline | `cbcd607b2f9996da22be16944b792f8617479118b1f4e567ab64604630af9dfc` |

**M1 (schema 1).** 8×8 land map, seed 91, four roads, two home plots, tick 12, 250000 pending microseconds, sequence 2, 991000 cents. It contains a future connected district and an isolated district.

**M2a (schema 1).** 10×8 generated coastal map, seed 2026 (12 water tiles on the west edge), root `(9,4)`. Seven commands including a bridge built and then cleared: a six-road connected district with four served homes, an isolated three-road district with two homes, one home with no road, tick 37, 400000 pending microseconds, 971500 cents. Unchanged M2a code derived 6 connected roads and 4 served homes; reasons for all seven homes are asserted in `run_tests.gd`.

**M2b (schema 2).** The M2a fixture migrated, then a power station at `(7,1)` beside the isolated district and two more homes, then three fast ticks. It contains occupancy ID 3, one station using 4 of 20 units, plots that are powered without road access, and plots with road access but no power.

**M2c (schema 3).** Seed 91, 12×8 map changed to all land before commands. Road `(1..11,4)`, station `(0,4)`, homes `(1..6,3)`, shops `(1..3,5)`, workshops `(4..6,5)`. After 40 days it has 48 residents / 18 jobs. Clear `(11,4)`, advance five days and 400000 microseconds: tick 45, ten developed plots with loss counter 1, 909000 cents, sequence 6. The next growth round must decline to 24 residents / 6 jobs. This sample exercises both new zone IDs, both development levels, persisted grace, and fractional-day continuation.

**M2d (schema 4).** Same 12x8 serviced mixed-town arrangement, with a park at `(7,2)`. Tick 59, 234567 pending microseconds, 915300 cents, sequence 6. Last settlement at tick 30: opening 899000 cents, 36 serviced residents, 18 jobs, 11 roads, one station, one park; net 16300 cents. Next tick settles 18700 cents, retaining fractional time. Written by the M2d model and validated before capture.

Under M2e (D30) every earlier schema migrates by clearing its single-tile zone and station tiles (they cannot become 3x3 lots or 4x4 stations), zeroing development/loss and adding a zero `footprint_anchor` array. Roads, parks, cash, time, RNG, sequence, budget history and the project record are kept; schemas 1-4 gain an incomplete project. No retroactive settlements or automatic project completion. All six historical hashes remain unchanged; only their migrated expectations changed. Earlier (M2c-M3a) migration notes in this file describe those builds.

**M3a (schema 5).** `m3a-schema5.json`, SHA256 `805fb299a49c14babfa7d96a375026c435037d5db546f89b01565e743cf489ef`. Captured by the M3a model: seed 91, 8x8 all-land map; roads (1..7,4), station (1,5), homes (4..6,3), park (5,2). After 59 days: 12 residents, 930200 cents, 234567 pending microseconds; project explicitly completed at index 21, command sequence 5. The next tick settles 4700 cents without changing completion or pending time. Tests check its hash, exact round trip and continuation; separate model tests cover incomplete and cleared-anchor round trips. Fixtures are excluded from release packages.

**M2e (schema 6).** `m2e-schema6.json`, SHA256 `c6bbc25000b43e4084be8e318f48fab74ca0418982fab17868210f25cd8b41f4`. Captured by the M2e model (`builds/validation/m2e/capture_fixture.gd`, ignored): seed 91, 16x22 all-land map; road (6..15,11), 4x4 station anchored at (12,12), home lots anchored at (6,8), (11,8) and (9,12), park (10,10). After 59 days: 12 residents in three level-1 lots, 926900 cents, 234567 pending microseconds, ledger at tick 30; project explicitly completed at park index 170, command sequence 5. The next tick settles exactly 4400 cents without changing completion or pending time. Tests check its hash, exact round trip and continuation.

**M2f (schema 7).** `m2f-schema7.json`, SHA256 `59f46e3f0b01d0f2b8b9e149b21cae97fce860b8849d5e9f48207e24639b339c`. Captured by the M2f model (`builds/validation/m2f/capture_fixture.gd`, ignored): the standard 24x12 lot town (seed 91, all land; road (4..23,6), 4x4 station at (0,5), six home lots from (4,3), three shop lots from (4,7), three workshop lots from (13,7)). The rate was set to 14% on day 10 (command sequence 6). After 59 days it has 32 residents / 12 jobs, 917680 cents and 234567 pending microseconds, with a ledger at tick 30 recording 14%. The next tick settles exactly 17680 cents at 14%. Tests check its hash, exact round trip and continuation.

Under M2f (D32) the six earlier schemas still migrate as described above. Schema 6 now also migrates, keeping every value including its lots, and every earlier town gains the standard 10% rate (and a 10% rate on any recorded ledger). All seven earlier hashes are unchanged.
