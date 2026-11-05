# Save compatibility fixtures

Preserve these bytes. Each file is UTF-8 with one trailing LF; `.gitattributes` keeps JSON at LF so checkout does not change the hashes. Fixtures and test drivers are excluded from the Windows PCK.

| File | Written by | SHA256 |
| --- | --- | --- |
| `m1-schema1.json` | Unchanged M1 `city_state.gd`, before M2a | `f954b5c782f32d240e54912baea00ac6960b599fe5aa90f4eed96efeceadbb83` |
| `m2a-schema1.json` | Unchanged M2a code (commit `1e1d143`), before M2b | `a85895efbc23707538a8c97399a7cf9bd831bfeb21b8182144b68653d82f0c93` |
| `m2b-schema2.json` | Final M2b code, continuing the M2a fixture | `27dbbaefca8ec3e1419d61b0e278c855cd8392c81d76b553128cf9c4c2b8c37a` |
| `m2c-schema3.json` | M2c code, mixed town with pending decline | `cbcd607b2f9996da22be16944b792f8617479118b1f4e567ab64604630af9dfc` |

**M1 (schema 1).** 8×8 land map, seed 91, four roads, two home plots, tick 12, 250000 pending microseconds, sequence 2, 991000 cents. It contains a future connected district and an isolated district.

**M2a (schema 1).** 10×8 generated coastal map, seed 2026 (12 water tiles on the west edge), root `(9,4)`. Seven commands including a bridge built and then cleared: a six-road connected district with four served homes, an isolated three-road district with two homes, one home with no road, tick 37, 400000 pending microseconds, 971500 cents. Unchanged M2a code derived 6 connected roads and 4 served homes; reasons for all seven homes are asserted in `run_tests.gd`.

**M2b (schema 2).** The M2a fixture migrated, then a power station at `(7,1)` beside the isolated district and two more homes, then three fast ticks. It contains occupancy ID 3, one station using 4 of 20 units, plots that are powered without road access, and plots with road access but no power.

**M2c (schema 3).** Seed 91, 12×8 map changed to all land before commands. Road `(1..11,4)`, station `(0,4)`, homes `(1..6,3)`, shops `(1..3,5)`, workshops `(4..6,5)`. After 40 days it has 48 residents / 18 jobs. Clear `(11,4)`, advance five days and 400000 microseconds: tick 45, ten developed plots with loss counter 1, 909000 cents, sequence 6. The next growth round must decline to 24 residents / 6 jobs. This sample exercises both new zone IDs, both development levels, persisted grace, and fractional-day continuation.

Schemas 1 and 2 migrate by changing the three version fields and adding zero-filled `development` and `service_loss` arrays; every earlier authoritative value, road/power result, and RNG continuation must stay identical. The schema-3 fixture must decode to its exact canonical bytes. Tests hash all four fixtures. Any future schema change needs its own preserved sample and migration test before replacing these rules.
