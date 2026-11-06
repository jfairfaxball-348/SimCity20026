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

**M2g (schema 8).** `m2g-schema8.json`, SHA256 `beaeb0b9fee8d13c091b1c995be90a33f57a418fbe219abe1f44a6219a51ee61`. Captured by the M2g model (`builds/validation/m2g/capture_fixture.gd`, ignored).

- **Town.** The standard 24x12 lot town plus a park at (14,1), command sequence 6.
- **State.** After 59 days the home lot at (13,3) scores "park +2, workshop −2" (0) and is at level 2, while its neighbour at (16,3) is held at level 1 by the developed workshop across the street. That gives 44 residents / 18 jobs, 905400 cents, 234567 pending microseconds and a ledger at tick 30.
- **Continuation.** The next tick settles exactly 17000 cents.
- **Tests.** They check its hash, exact round trip, the rescued and held homes, and the continuation.

Under M2g (D33) schema 7 migrates with every value kept, and all eight earlier hashes are unchanged.

**R2a (schema 9).** `r2a-schema9.json`, SHA256 `a9684518451dc8dad85b0026e4b0cf2371c82e7d5f2406d17a37ac53d0081ab4`. Captured by the R2a model (`builds/validation/r2a/capture_fixture.gd`, ignored): seed 91, 24x12 all land; road (4..23,6), 4x4 plant at (0,5), six residential lots from (4,3), commercial lots at (4,7) and (16,7), industrial lots at (13,7) and (19,7). After 59 days and 234567 pending microseconds: 40 residents / 18 jobs, 921400 cents, sequence 5, ledger at tick 30. The commercial lot at (16,7) is held at level 1 (trade +2, industry −4); the industrial lot nearest the link, (19,7), grew first and is at level 2. The next tick settles exactly 17200 cents. Under R2a the schema-8 fixture migrates with every value kept; all nine earlier hashes are unchanged.

**R2b (schema 10).** `r2b-schema10.json`, SHA256 `b838fe109e76ba2500b21d6ba3ae722d8ec106afe4c9fec3aa2afa23d1534041`. Captured by the R2b model (`builds/validation/r2b/capture_fixture.gd`, ignored): the standard 24x12 street (seed 91, all land) with six residential lots from (4,3), parks at (5,1), (11,1) and (17,1), three commercial lots from (4,7) and three industrial lots from (13,7). After 89 days and 234567 pending microseconds: 104 residents / 44 jobs, 928000 cents, sequence 8, ledger at tick 60. Residential lots at (4,3) and (10,3) are level 4 (park, well-off); (7,3) and (16,3) are gated at level 2; (13,3) and (19,3) are held at level 1; the industrial lot at (19,7) is level 3 (workforce over 100). The next tick settles exactly 37400 cents. Under R2b the schema-9 fixture migrates with every value kept; all ten earlier hashes are unchanged.

**R2c (schema 11).** `r2c-schema11.json`, SHA256 `ba65a9bf1c608cfb1de211f7099e1f6622df3b73819d66d7938fce00bde1870e`. Captured by the R2c model (`builds/validation/r2c/capture_fixture.gd`, ignored): the R2b park town on a 24x14 map (seed 91, all land) with a side road (23,7..13) and (10..22,13), a police station at (10,10) and a fire station at (13,10). After 89 days and 234567 pending microseconds: 104 residents / 44 jobs, 812000 cents, sequence 11, ledger at tick 60 with one police and one fire station. Residential lots at (4,3) and (10,3) are level 4 and covered by both. The next tick settles exactly 29400 cents. Under R2c the schema-10 fixture migrates with every value kept (its ledger gains zero station counts); its two level-4 lots lack cover and drop to level 3 at the next round, so its continuation now settles 29400 cents with 64 residents. All eleven earlier hashes are unchanged.
