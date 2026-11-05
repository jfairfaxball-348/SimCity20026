# Micropolis study provenance

Study date: **5 November 2026**. Author: Codex, acting on the owner's U10 study instruction and explicit request to commit, push, and merge the documentation. Baseline project commit: `443fc0472340396bdc4bfaa09e728cbd0081344f`. Study branch: `codex/micropolis-study`.

This is an audit record. **Implementation sessions must not open any reference source links or checkout files listed here.** The only reference-design inputs for implementation are [the qualitative study](MICROPOLIS_STUDY.md) and [Decisions](../DECISIONS.md).

## Reference identity and acquisition

| Item | Recorded value |
| --- | --- |
| Repository | https://github.com/SimHacker/MicropolisCore |
| Exact checked-out commit | `bd6e12eed6e148fe25270e7a4e2278f71a89f26c` |
| Commit timestamp | `2026-10-29T16:38:43+01:00` |
| Local research directory | `builds/reference/micropolis/MicropolisCore/` |
| Checkout method | Shallow Git clone with deferred blobs and no initial checkout; sparse selection of the engine source directory and root files; detached checkout at the recorded commit |
| Pin timing | Commit resolved and written to ignored `builds/reference/micropolis/PINS.txt` before file-content reads; checkout identity confirmed before licence/source inspection |
| Ignore rule | Existing `.gitignore` line 2, `builds/`; confirmed with `git check-ignore -v` before acquisition and at closeout |
| Optional repository | https://github.com/SimHacker/micropolis was neither fetched nor read; no commit or comparison claimed |

The maintained revision is the scope of this study. Its historical relationship to the original release was not independently reconstructed. Directory/tree listings were used to locate files; listed but unread files do not count as evidence. Git metadata and pinned raw web views of the root licence and name licence supplemented local text reads. No moving branch URL supplied source evidence.

Reference contents were treated as untrusted data. No reference build script, executable, package installer, test, or source code was run. Embedded instructions were not followed. No reference screenshots, assets, code excerpts, tables, formulas, numeric tuning, or program identifiers were transferred into the study analysis. File paths, revision identities, dates, and licence titles below are provenance metadata.

## Consulted file inventory

Every reference file whose text was read or searched is listed below. Review was selective and qualitative, not a complete code audit. A Git blob ID identifies the exact repository bytes at the pinned commit, independent of checkout line endings. The standalone GPL text file, repository README, frontend source, and build files were not consulted; the GPL text was read within the root licence.

| Ref | Consulted file at the pinned revision | Git blob ID | Review extent |
| --- | --- | --- | --- |
| L-A | [LICENSE](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/LICENSE) | `06fba0bbd04d86ed79c5b41ae8d7d76d72a6d42b` | Licensing index, embedded GPL distribution/notice terms, additional terms, warranty/liability, and embedded name licence |
| L-B | [MicropolisGPLLicenseNotice.md](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/MicropolisGPLLicenseNotice.md) | `d2bab216ceedae77d482b690239f5e0fafd0be4d` | Complete standalone notice |
| L-C | [MicropolisPublicNameLicense.md](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/MicropolisPublicNameLicense.md) | `3e22c0f160523ba438355f00d8afc4e4f7bc7ba9` | Complete standalone name licence |
| E-A | [packages/micropolis-engine/src/simulate.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/simulate.cpp) | `b04febf2d0acc78e8064f9dfd40fb72c01d48c66` | Scheduling, demand, census/history, tax/funding effects, map sweep, transport wear, fire suppression, and facility effectiveness; declaration/randomness search |
| E-B | [packages/micropolis-engine/src/scan.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/scan.cpp) | `4b4e3a68a8bb94cfdc10aeedfd17fd644f480279` | Spatial analyses, land value, pollution, density, crime, and service smoothing |
| E-C | [packages/micropolis-engine/src/zone.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/zone.cpp) | `e88ec900f3d2aa25c2d819727ade25109ad9709e` | Zone selection, services, power status, local suitability, development/decline and randomness; declaration search |
| E-D | [packages/micropolis-engine/src/power.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/power.cpp) | `18db0acb33c45cf581dbc398299791f199a6cc35` | Conductivity, capacity, traversal, shortage, bounded storage |
| E-E | [packages/micropolis-engine/src/traffic.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/traffic.cpp) | `dfa260b6cf4906fe480807d3521706d633170a4b` | Road search, bounded journey attempts, destination checks, random direction, traffic accumulation; inactive branch distinguished from active behaviour |
| E-F | [packages/micropolis-engine/src/budget.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/budget.cpp) | `aaaa0cf7600e22904c0a6916b53b6cc20e8a6045` | Funding, shortfall, automatic/manual budget paths and presentation callbacks |
| E-G | [packages/micropolis-engine/src/evaluate.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/evaluate.cpp) | `6d41d5e82031347d74ade07e0fdfa2a22cc459ae` | Evaluation, aggregate measures, sampled opinion/complaints and frontend notification |
| E-H | [packages/micropolis-engine/src/disasters.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/disasters.cpp) | `130f497d7e6eddb128292ea238aa694e1ee42fcf` | Random/scenario scheduling, event entry points, fire, earthquake and flood effects |
| E-I | [packages/micropolis-engine/src/map_type.h](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/map_type.h) | `0b9ccdd3e392af19ca86dfe37198c202278ba01d` | Map storage and grouped-cell representation; declarations searched |
| E-J | [packages/micropolis-engine/src/random.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/random.cpp) | `e701cf529d5d87ab910ca689b3bf46d3c6b6ba73` | Random state, draws, seeding and portability annotations |
| E-K | [packages/micropolis-engine/src/update.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/update.cpp) | `1c737cccfe7f776730cccc022090ebc5fd7f4627` | Funds, demand, date, options and changed-data notifications |
| E-L | [packages/micropolis-engine/src/message.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/message.cpp) | `3aaa335ff7a045ca7b5c9cc27342c3a6ecac05a1` | Periodic advice, service warnings, civic growth limits and scenario assessment |
| E-M | [packages/micropolis-engine/src/tool.cpp](https://github.com/SimHacker/MicropolisCore/blob/bd6e12eed6e148fe25270e7a4e2278f71a89f26c/packages/micropolis-engine/src/tool.cpp) | `d79ee1c4baa49d62fb3c010fa890ac716c7170ab` | Status-related search and local query/category reporting only |

## Evidence groups

These groups connect the study's qualitative claims to the consulted files. They contain no executable design specification.

### Licensing

L-A, L-B, L-C. All requested documents were present. Registration, ownership history, enforceability, and jurisdiction-specific application were not independently verified. The study includes an original attribution to the owner identified by the name document. No preferred attribution string was copied.

### Demand

E-A, E-C, E-K, E-L, E-M. Aggregate pressure, local development conditions, stochastic checks, advisory outputs, and query information.

### Spatial

E-A, E-B, E-C, E-G, E-I, E-L, E-M. Land value, pollution, density, crime, cross-system inputs and spatial/category outputs.

### Transport

E-A, E-C, E-E, E-G, E-L. Bounded journeys, local access, remembered traffic, road presentation and operating consequences.

### Power

E-A, E-C, E-D, E-L. Generation, connected supply, shortfall, refresh timing, local power and service effects.

### Services

E-A, E-B, E-F, E-K, E-L. Operating funds, income, effective coverage, financial feedback and annotated concerns.

### Evaluation

E-A, E-G, E-K, E-L. Aggregate assessment, sampled complaints/opinion, cadence and frontend notification.

### Disasters

E-A, E-H. Random and scenario events, damage, propagation and suppression. Moving-hazard internals were not opened.

### Scheduling

E-A through E-M, particularly E-A, E-B, E-I, E-J and E-K. Phased work, bounded/sampled processing, compact fields, random-state use and presentation notifications. No timing benchmark or save-continuation proof was performed.

## Project comparison and closeout

Project inputs read: `AGENTS.md`, `README.md`, `NEXT_SESSION.md`, `docs/DECISIONS.md`, `docs/IP_AND_ASSETS.md`, `docs/TOOLCHAIN.md`, `docs/sessions/2026-11-05-m2c.md`, `docs/TECHNICAL_PLAN.md` (architecture sections), `.gitignore`, and `tools/package.ps1` (read only). Live Git/remote state was checked before changes. The earlier memory lookup was used only to locate project conventions; live files governed this study.

**The session wrote no game code and changed no file under `game/`.** No reference content was staged or packaged. The reference checkout remains ignored, at the recorded detached revision, with no tracked modifications. The game's source licence, version, simulation rules, saves, assets, and existing Windows package were not changed. The M2d assignment text was preserved verbatim.

See [session evidence](../sessions/2026-11-05-micropolis-study.md) for the actual documentation checks and delivery boundary. The isolated checkout is retained as research evidence only; the completed study does not authorise any future implementation session to read it.
