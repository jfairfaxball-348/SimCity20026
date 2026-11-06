# Roadmap: from 0.11.0-m3b to a feature-complete classic-style city builder

Written 6 November 2026 under owner direction U30, from the [gap analysis](GAP_ANALYSIS.md). **This supersedes the candidate table in [GENRE_ALIGNMENT.md](GENRE_ALIGNMENT.md).** The [Delivery plan](DELIVERY_PLAN.md) gates (M3 playable slice, M4 content-complete, M5 release) still apply; the milestones below are the work that reaches them.

**Planning only.** Nothing here is implemented. Every milestone writes its specification and adopts its rules in [Decisions](DECISIONS.md) before code, states exactly which earlier rules it changes, and then implements, tests and delivers in the usual way. All numbers are chosen by this project; none comes from the reference game. Sizes are in agent sessions and are rough.

Owner answers U31-U34 (end of this document) are reflected below.

## Ordering principles

1. **Depth before breadth.** The town currently settles at a few dozen residents. Every later system needs a city that can keep growing, so growth depth comes first.
2. **Fields before pressures.** Land value is the shared field that pollution, crime, traffic and services act on. Build it once, then add sources to it.
3. **Protect the player's work early.** Autosaves and remembered settings come before the long-session systems.
4. **Test with people before the big expansion.** The M3 five-person playtest comes after growth depth, autosaves, a sound sample and the controller route, and before traffic, special buildings and disasters.
5. **Drama last.** Disasters and scenarios depend on services, terrain and evaluation, and need the owner's consent rules.

## Milestones

| # | Milestone | Scope | Why here | Depends on | Size | Save / schema | Acceptance gate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R1 | Terminology and calendar (**done**: 0.12.0-r1, D35) | Player-facing **Residential / Commercial / Industrial** in place of Homes / Shops / Workshops (meter R/C/I; keys unchanged); a month-and-year calendar derived from the tick, from our own start year | Cheap, makes the game read as the genre before deeper systems add more text; years are needed for graphs and yearly summaries | — | 1 | No schema change (labels and a derived date); content version unchanged | Every label, help, summary, guide and inspector line uses the new words and fits at every text size; date correct across month/year boundaries; fixtures unchanged; native run |
| R2a | Land value for every zone (**done**: 0.13.0-r2a, D36; the town-centre pull was replaced by commercial trade from nearby residents and industrial freight to the link) | Replace home-only desirability with a derived **land value** field for all zone types: water, parks, trees on terrain (if R7 not yet, coast only), distance from the town's developed centre, and nuisance; residential uses it for order and holds; commercial and industrial get their own preferences; overlay V becomes land value | The shared field that later pollution, crime and services modify | R1 | 1-2 | Derived; content version change; schema bump only if a stored field is needed | Every source and radius tested; overlay readable without colour; inspector lists parts; migration keeps all development |
| R2b | Density stages and wealth | Raise levels from 0-2 to our own higher range (proposed 0-4 visible stages) with larger capacities; wealth variant per developed residential lot from land value (low/middle/high); new lot art for each stage and variant; demand targets rebalanced so a serviced town keeps growing into hundreds and then thousands | The core of the "nothing to grow towards" gap | R2a | 2-3 | **Schema 10**: wider level range and stored wealth; older saves migrate keeping levels | A test town grows past the old ceiling; growth order, holds and decline stay deterministic; all fixtures load; art fits 16 px cells in all art modes |
| R2c | First civic services: police and fire | Police and fire stations (our own footprints) with coverage areas, upkeep and power/road needs; the top density stages require coverage; coverage overlay | "Services needed for the top levels" completes growth depth | R2b | 2 | **Schema 10**: new occupancy IDs | Coverage tested at edges and through water; top-stage growth held without coverage and explained; summary item added |
| R3 | Autosaves, settings and history | Rotating autosaves (our own interval and count) beside the manual slot; remembered display, text, art, overlay and guide-dismissal settings in a settings file; history of population by type, funds and net per month for graphs; a Graphs dialog | M3 gate items; longer cities need protection; graphs need R1 calendar | R1 | 2 | **Schema bump** for history; new settings file with its own version | Autosave never replaces the manual slot; corrupt settings fall back to defaults; history bounded in size under the 512 KiB cap (raise the cap only by decision); graphs fit 720p |
| R4 | Sound sample and animation | Coherent original sound effects (build, clear, growth, alerts) and one original music sample; separate volume controls; first animations (traffic dots or cars on busy roads later, smoke on industry, water shimmer) | M3 gate "coherent original audio"; makes the playtest town feel alive | R2b | 2 | Settings only | Every asset in the ledger with provenance; volumes remembered; no flashing; silence option |
| R5 | Controller route | Full controller play: cursor, tool wheel or bar, dialogs, budget, summary, guide; on-screen prompts; key remapping | M3 gate item | R3 | 2 | Settings only | Every action reachable without mouse/keyboard; focus never lost; tested with a real controller |
| R6 | **M3 playtest gate** | Refresh the guide for R1-R5; prepare a playtest kit (build, consent note, observation sheet, save capture); the owner runs a five-person observed test against the [product brief](PRODUCT_BRIEF.md) gates | Validate the core loop before large expansion | R1-R5 | 1 agent session + owner time | None | Product brief criteria met or fixes listed; results recorded honestly; no automated run counted as a playtest |
| R7 | Terrain and new-city choices | A new generator with rivers, lakes and forest as model terrain (trees clearable, raise land value); map size choice including a classic-sized map (U33); seed entry and three presets; city name; difficulty choice (starting funds and demand pressure) | Variety, replay and water for bridges and ports | R2a | 2 | **Schema bump**: forest terrain; size choice | Starting land always connected to the outside link; generation deterministic per seed; profiling at the largest size meets a recorded target |
| R8 | Power depth | Separate **power line** tool (lines may cross water); zones conduct power to neighbours; two plant types, a cheap polluting one and a cleaner, costlier one; plant pollution feeds land value | Classic power planning; replaces roads-as-power (D19) | R2a, R7 | 2 | **Schema bump**: line occupancy; migration keeps road-powered towns working (auto-lines or grace rule decided in spec) | Network, capacity and shortage rules tested; migration leaves no existing town unpowered without explanation |
| R9 | Pollution and crime fields | General **pollution** field (industry, plants, later traffic and ports) and **crime** field (density, low land value, police coverage reduces) acting on land value and growth; overlays; summary items | The classic zone-separation and services tension | R2c, R8 | 2 | Derived fields; content version | Sources, decay and caps tested; every effect recoverable and explained; no danger stereotypes in wording |
| R10 | Service funding and budget depth | Funding levels for roads, police and fire in Budget; underfunding weakens coverage and road condition gently; a yearly summary alongside monthly settlement; the no-debt default kept (U32), with an optional stricter rule only for challenges or hard difficulty | Real budget trade-offs once services exist | R2c, R9 | 1-2 | **Schema bump**: funding levels | Exact integer accounting at every level; no-debt default kept unless the owner changes it |
| R11 | Traffic and rail | Derived, deterministic **traffic** from zone trips along the network (no random sampling); congestion shown on roads and overlay; congestion adds pollution and slows growth; bridges for roads; **rail** as a second network that carries trips without congestion; car and train animation | The largest system gap; makes road layout matter | R9, R7 | 3-4 | **Schema bump**: rail occupancy, bridges | Structural access (D17) unchanged; traffic bounded and profiled on the largest map; explanations name the congested segment |
| R12 | Special buildings and demand caps | Stadium, seaport and airport (our own designs and footprints); demand caps that lift when each exists, at our own population thresholds; port needs coast, airport needs space; they pollute | The classic mid-game goals | R11 | 2 | **Schema bump**: new IDs | Each cap and lift tested; summary explains a cap; art fits |
| R13 | Evaluation, milestones and rewards | Town rating from measurable causes (no random complaints), yearly evaluation with top problems from real data, city size titles, and milestone **rewards** delivered as our own neighbourhood projects (D07) with original landmarks; more project types | Progress and personal goals for a long city | R3, R9, R12 | 2 | **Schema bump**: milestone and project records | No reference advisor, gift list or wording; rewards placed by the player; ratings reproducible from state |
| R14 | Disasters (optional, off by default, U31) | Our own hazard set with fire spread first (needs fire coverage), then flood and others; a switch in new-city options and in settings; clear extent and recovery; no reference creature or event list | Classic drama, placed after services so recovery exists | R2c, R7, R10 | 2-3 | **Schema bump**: damage and fire state, option flag | Off-switch truly disables every hazard; recovery always possible; default off (U31) |
| R15 | Challenges (scenarios) | A small set of our own challenge maps with goals and optional time limits, on our own generated terrain | Classic scenario mode without copying any | R13, R14 | 2 | **Schema bump**: challenge record | No reference city, map, scenario or text; each challenge winnable in tests |
| R16 | Presentation completion | Full original music set, seasons, remaining animation (ships, planes), mini-map, supplementary sprites, polish; no later-edition extras (U34) | Finish the look and sound once systems settle | R11-R13 | 3+ | Settings only | Asset provenance audit; performance on the largest map |
| R17 | **M4 content-complete gate** | Balance pass across all systems, busy-city profile and soak, save-migration audit across every schema, accessibility pass, closed beta preparation | Delivery plan M4 | All above | 2-3 | Possibly a final schema | Delivery plan M4 evidence; then M5 release work is a separate owner decision |

Total: roughly 40-50 agent sessions before M4, plus owner playtest time. Re-estimate after R6.

## Placement of the remaining M3 gate items

| M3 item | Where |
| --- | --- |
| Five-person observed playtest | R6 |
| Coherent original audio | R4 (sample), R16 (full) |
| Controller route | R5 |
| Autosaves and remembered settings | R3 |
| Onboarding | R6 guide refresh, then kept current in each milestone |

## Rights reminders for every milestone

Our own rules, numbers, art, sound, text, names, interface layout and maps. Plain genre words are fine (U29). Never open reference source (U10); the only reference inputs are the study notes and Decisions. No reference scenario, disaster creature, advisor character, gift list or recognisable screen composition.

## Owner questions and answers

The four questions were put to the owner on 6 November 2026. The answers are recorded in [Decisions](DECISIONS.md#confirmed-by-the-user) and already shape the table above.

| # | Question | Owner answer | Effect on the roadmap |
| --- | --- | --- | --- |
| U31 | Disasters: off, optional or on by default? | **Optional, off by default** | R14 builds our own hazards with a new-city and settings switch, default off; the relaxed default (U05) stays |
| U32 | Failure states: no-debt rule, or debt/bankruptcy? | **Keep the no-debt default** | D25 waiver stays in the default game. R10 may offer a stricter money rule only as an opt-in (challenges or hard difficulty), never as the default |
| U33 | Target map and population scale | **Match the original game** | R7 offers a map of comparable size to the classic's (public descriptions put it at roughly 120x100 tiles), within the existing 128-per-side save ceiling; R2b and later rebalance our own capacities so a full map can reach a comparably large city (public descriptions: hundreds of thousands of residents). Exact dimensions and capacities are our own choices, set in those specifications with profiling |
| U34 | Later-edition extras | **None for now** | Water pipes, education/health, highways, subways, loans and other later extras stay out of R1-R17; revisit after M4 |
