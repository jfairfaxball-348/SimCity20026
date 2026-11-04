# M1 compatibility fixture

`m1-schema1.json` was written by the unchanged M1 `city_state.gd` on 4 November 2026, after the baseline 106 source / 84 packed checks and before M2a implementation. It is an 8×8 land map, seed 91, four roads, two home plots, tick 12, 250000 pending microseconds, sequence 2, and 991000 cents. It contains both a future connected district and an isolated district.

Original file SHA256: `f954b5c782f32d240e54912baea00ac6960b599fe5aa90f4eed96efeceadbb83` (UTF-8, one trailing LF). Preserve the fixture bytes. M2a must decode it without changing its canonical authoritative snapshot or RNG continuation, and derive access from its roads. There is no serialized access field or schema migration.

Fixtures and test drivers are excluded from the Windows PCK.
