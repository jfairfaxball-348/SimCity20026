# Next agent: M2d monthly economy and amenity

Updated **5 November 2026** after owner-authorised M2c implementation, Windows-export testing, documentation, commit, push, and merge. This handoff does not execute M2d.

## Current checkpoint

**M0/M1 through M2c are implemented and locally tested. M2d and later work are unimplemented.** Read [README](README.md), [AGENTS](AGENTS.md), [Decisions](docs/DECISIONS.md), [Toolchain](docs/TOOLCHAIN.md), and [M2c evidence](docs/sessions/2026-11-05-m2c.md) first. Earlier session records are historical.

- Engine: isolated Godot **4.7.2 Standard**, exact `4.7.2.stable.official.ed1daf0bf`, matching x64 templates, Compatibility renderer. Use `tools/`; the global wrapper is 4.6.3.
- Game **0.4.0-m2c**, schema **3**, simulation/content **m2c-1**. Project/scene: `game/project.godot` / `game/scenes/main.tscn`; UI: `scripts/main.gd`; authoritative model: `sim/city_state.gd`; growth: `sim/growth.gd`; clock: `sim/simulation_clock.gd`; values: `content/balance.gd`.
- Work branch `codex/m2c-growth`, based on `c18cf6f`; remote `https://github.com/jfairfaxball-348/SimCity20026.git`. Default branch is **`codex/m2a-road-access`**, a historical name. Reinspect remote HEAD, Git state, and current files before editing. Use a fresh `codex/` branch for M2d. Source integration is owner-authorised; public binary release is not.
- The connected GitHub owner account has repository write/admin access (verified 5 November). Earlier notes about a different read-only `gh` login do not describe that connector. Ordinary Git pushes also work.
- Export `builds/windows/citybuilder.exe` + PCK; local ZIP `builds/citybuilder-0.4.0-m2c-windows-x64.zip`. Generated/ignored. No CI configured.
- No income, upkeep, taxes, parks/amenities, nuisance, projects, audio, controller route, or autosaves. The full M2 gate remains open.

## Contracts to retain

**Road access (D17).** One outside link: `(width-1,height/2)` on generated maps; nearest boundary land by Manhattan distance and row-major tie on custom terrain; no boundary land means no link. An ordinary paid road activates it. Only side-sharing roads relay access. All three zones need a connected road beside them; stations do not relay road access.

**Power (D19/D23).** Single-tile $500 stations supply 20 units. All zone plots request 1, empty or developed. Roads/stations form side-sharing networks independent of outside access. Serve plots by `(station distance, row-major plot index)`; choose a touching network with room by `(distance, network order)`. No allocation memory: new nearer zones can displace grown ones. Growth never changes allocation. Legacy internal names `served_homes`, `home_state`, `home_reason` now cover all zone types.

**Growth (D22).** Levels 0-2; a home level holds 4 residents, shop/workshop levels provide 2/4 jobs. Totals count standing development until decline, not individual citizens or assigned employment. Prior-state targets: home `min(2*cells,3+floor(jobs/2))`, each business `ceil(population/16)`. Demand is positive remaining level count. Three starter home levels prevent deadlock; serviced mixed zoning can settle at 48 residents/18 jobs. Demand satisfaction alone never evicts development.

Every fifth tick reserves at most eight additions per type, one per plot, row-major, skipping missing services and full plots. Apply all changes together from the same prior state. Developed plots lose one level every second consecutive growth check without both services. Persistent loss counter 0/1 resets on decline; restoring both services resets it immediately, even paused. Empty/non-zone cells have counter 0. Identical repaint preserves buildings free; clear removes levels/totals immediately without refund. Ticks never change cash, command sequence, or RNG.

**Clock/order.** One day/tick, one second at 1x, 3x fast. Ordered commands run between clock advances and rebuild access, power, growth totals/eligibility. Each clock step increments tick, runs a round on multiples of five, then refreshes growth totals/eligibility. Retain eight ticks/frame, one-hour backlog, focus/dialog suspension, no offline catch-up. Display day = tick+1; first growth displays on day 6.

**UI.** 1 road / 2 homes / 6 shops / 7 workshops / P station / 3 clear; 4/5 retain speed meanings. R/E marks, Home centering, Ctrl+S/L, F6. HUD residents/jobs/demand; inspector level/count, separate road/power, demand/next check, growth/queue/full/wait/decline reasons. Keep the 320 px inspector cap. Display/Help share a row to fit 720p. Largest-text Help fits tightly; shorten or scroll before adding lines. Camera/display/overlay preferences reset on restart.

## Persistence and verification

- Occupancy 0 empty / 1 road / 2 home / 3 station / 4 shop / 5 workshop. Saved `development` and `service_loss` arrays have exact cell count and bounds 0-2 / 0-1, with non-zone/empty/serviced-counter consistency checks. Networks, totals, and demand are derived.
- Schema 1 (`m1-1`, IDs 0-2) and schema 2 (`m2b-1`, IDs 0-3) migrate with zero-filled new arrays, retaining all old fields/RNG. Load never writes. Before replacing an older primary or backup, preserve its bytes once as `manual.schema1.json` / `manual.schema2.json`; failed preservation aborts replacement. Newer/inconsistent data fails without replacing the live city.
- Keep four fixtures byte-identical: `m1-schema1.json`, `m2a-schema1.json`, `m2b-schema2.json`, `m2c-schema3.json`. The M2c sample has 48 residents/18 jobs, tick 45, fractional time, and ten pending loss counters; its next round yields 24/6. See the fixture README and `growth_tests.gd`.
- Save path `%APPDATA%/OriginalCityBuilder/saves/manual.json`; `.bak` is previous-good. Preserve real user saves before native testing, restore/verify afterward. M2c did so; ignored evidence is under `builds/validation/m2c/`.
- Provisional costs: roads $10, all zones $25, stations $500; free clear/no refund; starting funds $10,000. No income/upkeep. JSON cap 512 KiB; maps 8-128 in each dimension; seed/RNG are signed 64-bit decimal strings.

```powershell
.\tools\verify.ps1
.\tools\project.ps1 Run
.\tools\package.ps1
```

M2c passes **298 source / 277 exported-PCK checks**, plus release-EXE startup. The external PCK driver uses the pinned **editor runtime**; release templates disable `--script`. Native M2c used the computer-use skill's SendInput-backed desktop API: build all zones, grow, shortage, save/restart/load, decline/recovery, largest text/help, and unsaved-change prompt at 1280x720. Automated layouts cover four sizes x three text sizes. Physical human input, DPI variants, other hardware/OS, controller, performance-target, and enjoyment evidence remains absent.

The 128x128 scenario took about 1.27-1.40 seconds for 250 days / 50 rounds; this is not an 8 ms tick-target pass. Four deliberate growth mutations fail the suite; source was restored byte-identical before final verification/export. Helpers passed under PowerShell **7.6.5** in M2c, retaining the 5.1-safe changes from M2b.

## Smallest next assignment: M2d economy and amenity

When explicitly asked to continue, implement the last bounded M2 slice and stop at that checkpoint:

1. Inspect Git/live remote, preserve fixtures/user saves, and rerun verification.
2. Before coding, specify in Decisions: month boundary; exact integer income/tax/upkeep equations (including stations); treatment of unserved development; affordability/debt limits; visible and recoverable deficit rules; one park/amenity's cost, coverage, and growth effect; order relative to growth; save/schema/content migration; deterministic ties. Economic values are not settled defaults.
3. Keep accounting aggregate/auditable; show expected income/expenses and causes of deficit. Preserve bounded work and simultaneous prior-state growth. Avoid citizens, traffic, disasters, projects, or extra content systems.
4. Implement one small park/amenity with original geometric placeholders and provenance. Its effect must be explained in the inspector and distinguished by a meaningful test.
5. Test exact monthly accounting, frame partition/reload across a month, a viable empty-town opening, disconnection, shortage, costly overbuild, and recovery from deficit without an irreversible trap. Retain atomic spending and older migrations.
6. Exercise the exact Windows export through accounting, amenity, deficit recovery, and save/restart/load. Update README, Decisions, evidence, and handoff. Integrate source only within the active owner's instructions.

**M2 gate:** a town grows from empty; shortages and deficits are understandable/recoverable; accounting and deterministic continuation pass, including the export. M3 projects, onboarding polish, production art/audio, controller route, autosaves, and observed enjoyment tests remain later work. No purchases, external messaging, store upload, or public release is implied.
