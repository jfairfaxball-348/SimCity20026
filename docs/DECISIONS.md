# Decisions and assumptions

Recorded: 4 November 2026. Use this file to distinguish the user's requirements from planning choices. Current user instructions take precedence.

## Confirmed by the user

| ID | Requirement | Evidence |
| --- | --- | --- |
| U01 | The initial session was research and due diligence only | Initial request; completed before implementation |
| U02 | Leave instructions in the repo so the next agent can start the game | Initial request |
| U03 | Create an original game inspired by the classic experience, without using others' protected material improperly | Initial request |
| U04 | Target desktop players, with a possible Steam release | Answer to platform question |
| U05 | Prioritise relaxed building, charming pixel art, and approachable controls | Answer to experience question |
| U06 | Implement M0/M1 from the handoff, follow AGENTS.md, test the exported Windows build, and update docs/handoff | Subsequent explicit implementation request |
| U07 | Implement M2a road access and zone explanations, test the Windows export, update docs/handoff, then commit and push | M2a session and follow-up instruction |
| U08 | Implement M2b power access from the handoff, follow AGENTS.md, test the exported Windows build, update docs/handoff, then commit and push | M2b session request |
| U09 | Implement M2c growth, test the Windows export, update docs/handoff, then commit, push, and merge into the default branch | M2c session request |
| U10 | Authorise one next-session study of the open-source Micropolis code (EA's 2008 GPL v3 release of the original 1989 SimCity) to inform this project's own design. Studying is allowed; copying or translating its code, tables, constants, text, art, or sound is not. The game stays original, unnamed, and not GPL-licensed. | Owner decision, **5 November 2026**; prepare the handoff now, conduct the study next session |
| U11 | Perform the U10 study, follow AGENTS.md, write notes/provenance, update the handoff, then commit, push, and merge into the default branch | Explicit study-session request, **5 November 2026** |
| U12 | Run the bounded M2d session from NEXT_SESSION, then continue to completion | Owner request, **5 November 2026**; local implementation, testing, evidence and handoff |
| U13 | Run the next-session M3 scoping assignment, ending with a concrete M3a handoff | Owner request, **5 November 2026**; planning only in this session, standing source-delivery instruction applies |
| U14 | Implement the bounded M3a assignment and continue through verification and delivery | Owner “Run next session” and “Continue”, **5 November 2026**; scoped by the M3a handoff |
| U15 | Run the next-session M3b scoping assignment, ending with a concrete guided-opening handoff | Owner “Run next session”, **6 November 2026**; planning only, standing source-delivery instruction applies |
| U16 | Homes, shops and workshops are multi-tile buildings (first proposed as 4x4; size superseded by U19); roads stay one tile | Owner design note during U15, **6 November 2026** |
| U17 | Lean closer to the classic city-builder design; the owner overrules earlier design-scope limits, provided no copyright rules are broken | Owner direction during U15, **6 November 2026**; rights and U10 clean-room boundaries unchanged |
| U18 | Power stations are also 4x4 buildings; when choosing between design options, prefer whichever is closest to the original game, within copyright limits | Owner answer after U15 delivery, **6 November 2026** |
| U19 | Homes, shops and workshops are 3x3 lots, as in the original; supersedes U16's 4x4 size | Owner answer, **6 November 2026**, after being told the original's zones were 3x3 |
| U20 | Implement the M2e assignment from the handoff through verification and delivery | Owner “Run next session”, **6 November 2026** |
| U21 | Pause the roadmap for one controlled artwork evaluation of two Kenney packs, keep both as experimental assets, preserve the NEXT_SESSION assignment, and leave the final choice to the owner | Owner artwork-evaluation brief, **6 November 2026** |
| U22 | Kenney Roguelike Modern City is the chosen artwork direction | Owner answer after reviewing the side-by-side comparison, **6 November 2026**; not yet the default |

U06 superseded the earlier planning-only scope for M0/M1. U07 and U08 authorised M2a and M2b. U09 authorises M2c and source integration. U12 authorises M2d local implementation. The follow-up owner instruction authorises source delivery now and in future sessions: commit, push, merge and fast-forward completed work. Public game release remains separate.

**U10 status and boundary (5 November 2026): completed under U11.** The source study produced [original qualitative notes](research/MICROPOLIS_STUDY.md), [pinned file provenance](research/MICROPOLIS_PROVENANCE.md), and [session evidence](sessions/2026-11-05-micropolis-study.md). It executed no reference code, wrote no game code, and changed no simulation rule. Licence documents were inspected at the recorded revision; unresolved legal and runtime questions remain explicitly unverified. Adopt/adapt/reject entries in the study are proposals only. The one source-study permission is exhausted. Implementation sessions must never open reference source; their only reference-design inputs are the study notes and Decisions. The subsequent M2d session is now complete under U12; the study boundary remains unchanged. See [Next session](../NEXT_SESSION.md) and the [study boundary](IP_AND_ASSETS.md#micropolis-study-and-implementation-boundary). No GPL or root source licence was added.

## Working defaults and adoption

D01–D06, D08, and the M1 part of D10 were adopted for the foundation. Later product and commercial choices remain proposals. Change defaults when evidence or new instructions justify it, and record the reason here.

| ID | Default | Reason / revisit condition |
| --- | --- | --- |
| <a id="d01"></a>D01 | Godot 4.7.2 Standard + typed GDScript + Compatibility | Integrated 2D/UI/export tooling, permissive engine licence, modest deployment scope. Revisit only for a concrete engine blocker or a changed target. |
| <a id="d02"></a>D02 | Windows 11 x64 is the first development/release target | The native export has been exercised on one machine; this does not certify a broad hardware matrix. Add other targets only with testing capacity. |
| <a id="d03"></a>D03 | Mouse and keyboard first; input actions and focus navigation support later controller work | Keeps the first checkpoint small while retaining the console-inspired accessibility goal. Full controller coverage belongs in the playable slice. |
| <a id="d04"></a>D04 | Top-down grid; 16-pixel cells; 640x360 world view with independently scalable UI | Implemented with integer scaling/zoom. Native 720p, 1366x768, 1280x800 inspected; full 1080p capture and Windows DPI variations remain unverified. |
| <a id="d05"></a>D05 | 64x64 foundation; 128x128 initial release ceiling | Bounds simulation and content work. Raising the ceiling needs profiling and a gameplay reason. |
| <a id="d06"></a>D06 | Aggregate simulation, discrete clock, seeded randomness, independent model and renderer | Reliable saves, testability, and understandable consequences. No individual citizen simulation. |
| <a id="d07"></a>D07 | One proposed signature feature: visible neighbourhood projects | Gives a small city personal goals; validate with players before expanding content. |
| <a id="d08"></a>D08 | Offline single player, no account/backend/live AI, no monetisation systems in the prototype | Suits relaxed play and avoids unnecessary operational scope. |
| <a id="d09"></a>D09 | Restricted desktop playtests, then optional public demo, then possible Steam 1.0 | Validate usability and stability before commercial release obligations. |
| <a id="d10"></a>D10 | Original programmer placeholders first; original final art/audio with recorded rights | Avoids both premature asset spend and dependence on reference-game content. |
| <a id="d11"></a>D11 | No open-source licence grant selected in this session | Source licensing and commercial ownership remain the owner's choice; engine MIT does not decide the game's licence. |
| <a id="d12"></a>D12 | Complete small verified checkpoints before broader simulation/content | Foundation through M2d, M3a and M2e completed locally; further M3 work needs its own bounded assignment and validation. |
| <a id="d13"></a>D13 | One custom-drawn Node2D for original geometric M1 tiles | Avoids an unnecessary atlas/asset pipeline for placeholders. No per-cell processing Nodes. Revisit TileMapLayer/atlas rendering with original art and profiling evidence. |
| <a id="d14"></a>D14 | Synchronous ordered commands and a bounded fixed clock | Commands commit between clock updates, including paused. Eight ticks/frame; retain up to one simulated hour of backlog, discard only excess beyond that bound. No offline catch-up. |
| <a id="d15"></a>D15 | Schema 1, simulation/content m1-1, strict JSON and previous-good backup | Lossless RNG strings, validated temporary writes, explicit recovery. No power-loss guarantee. Schema/version superseded by D20 in M2b; strict validation and backup rules retained. |
| <a id="d16"></a>D16 | Local checks/package before remote CI adoption | Initial source commit/push authorised with M2a. Scripts are reproducible (and Windows PowerShell 5.1-safe since M2b); CI remains a future deliberate setup task, not a claimed result. |
| <a id="d17"></a>D17 | One visible outside link; orthogonal road access | M2a rule recorded before coding below. Keeps the first network understandable without traffic or growth. |
| <a id="d18"></a>D18 | Derive M2a access from existing terrain/roads; retain schema 1 and m1-1 simulation/content | M2a adds observational access only: no stored IDs, map generation, prices, clock, RNG, or growth rules change. Preserve and test an original M1 fixture; never write derived access into saves. |
| <a id="d19"></a>D19 | One single-tile power station; roads and stations form power networks; nearest-first derived allocation | M2b rule recorded before coding below. Gives one understandable supply/shortage loop without power lines, load flow, upkeep, or growth. Revisit allocation stability when M2c adds grown buildings. |
| <a id="d20"></a>D20 | Schema 2, simulation/content `m2b-1`; schema-1 saves migrate in memory and their original file is preserved on first overwrite | A new occupancy ID is a new meaning, so schema 1 is not reused. Older builds already reject schema 2 by version. Newer/unknown schemas are rejected unchanged. |
| <a id="d21"></a>D21 | P selects the power-station tool; E toggles power marks; the existing 1–5 and R bindings stay unchanged | Avoids remapping documented speed keys. Marks use distinct shapes as well as colour. |
| <a id="d22"></a>D22 | Three zones, levels 0–2, deterministic five-day aggregate growth with starter home demand | M2c rule below, recorded before coding; no citizens or monthly economy. |
| <a id="d23"></a>D23 | Retain nearest-first derived power for all zones, including grown buildings | One unit per plot at every level; service loss has a two-round grace period. No persistent allocation priority. |
| <a id="d24"></a>D24 | Schema 3, simulation/content `m2c-1`; migrate schemas 1 and 2 with zero development and preserve originals | New occupancy IDs, levels, and service-loss counters must have explicit saved meanings. |
| <a id="d25"></a>D25 | Thirty-day integer budget; serviced taxes, universal facility upkeep, explicit waiver at zero | Recoverable relaxed-play deficits with auditable income/expenses; exact rules below. |
| <a id="d26"></a>D26 | One pocket park gives covered homes growth priority within existing demand/caps | A local choice with a tested contention effect; no extra simulation system. |
| <a id="d27"></a>D27 | Schema 4 / m2d-1 with last-budget inputs and schema-3 migration | Preserve earlier development and original save bytes; no retroactive collection. |
| <a id="d31"></a>D31 | Selectable presentation-only art modes (original, Kenney Tiny City, Kenney Roguelike Modern City); owner chose Modern City (U22); original stays default and fallback until adoption | Adoption would make Modern City the default, keep the original as fallback, and add documented supplementary sprites (water/shore, power station, roof edges). Tiny City stays experimental unless the owner says otherwise. |
| <a id="d29"></a>D29 | Proposed: one dismissible, session-only First steps card derived from the current town; no save change | Replaces a start-up status line that vanishes after the first command. Implement after M2e, using lot wording. Revisit persistence of dismissal with M3 settings/autosaves or if observed players find it intrusive. |
| <a id="d30"></a>D30 | Adopted and locally verified (M2e): freely placed 3x3 zone lots replace single-tile plots one-for-one, and power stations become 4x4; schema 6 / m2e-1; older zones and stations cleared on migration | Implements U16/U18/U19 while keeping D19-D28 numbers unchanged. Revisit prices and frontage costs after M3 playtests. |

## D30 - M2e zone lots and stations, adopted 6 November 2026

**Adopted before model changes** under the owner's "Run next session" request (U20), then implemented and locally verified as game 0.7.0-m2e / schema 6 / m2e-1. Source, exported-PCK and native EXE evidence is in the [M2e record](sessions/2026-11-06-m2e.md); the one presentation deviation (sidebar price labels) is recorded in the specification. [The M2e specification](M2E_SPEC.md) turns homes, shops and workshops into 3x3 lots anchored at their top-left tile, placed by click or by straight drag runs. A lot replaces a plot one-for-one: $25, one power unit, levels 0-2, unchanged capacities, demand, growth, decline, taxes, park priority and project rules.

- Access and power use any side-sharing tile on the lot's perimeter; corner-only contact does not count.
- Clearing any lot tile removes the whole lot for free.
- Power stations become 4x4 (U18): one per placement, cleared whole, $500, 20 units and $60/month **per station, counted by anchor, not per tile**. Parks stay one tile.
- Schema 6 / `m2e-1` adds a strict per-cell `footprint_anchor` array covering lots and stations.
- Schemas 1-5 migrate with their old single-tile zones and stations cleared and everything else kept. Schema-5 originals are preserved, and the six fixtures stay byte-identical. This supersedes only the development-retention parts of the D24/D27/D28 migrations.

Adopt before implementation code under a subsequent owner request. M2e is the next implementation session; M3b follows it.

## D29 - M3b guided opening, proposed 6 November 2026

Proposed, not adopted or implemented. [The M3b specification](M3B_SPEC.md) defines one non-modal **First steps** card with five ordered steps. The steps are: lay the flag road, zone a home with road access, power a home, grow a home, then open the optional project. The card always shows the first step whose condition is currently false, so undoing a step moves it back. It is visible at each start; Hide/Close dismisses it for the session; F1 and a Help action bring it back. Show centres the camera on a derived target and points the existing inspector at it; a static code-drawn bracket marks that target.

Guide evaluation is read-only and never a command. It cannot change the canonical town, sequence, cash, time, RNG or unsaved flag. No guide state is saved: schema 5 and `m3a-1` stay; game version becomes `0.7.0-m3b`; there is no settings file and fixtures stay unchanged. D17-D28 are unchanged, and no file under `sim/`, `persistence/` or `content/` changes. Adopt before implementation code under a subsequent owner request. Passing its automated and native checks would not satisfy the five-person M3 gate.

## D28 - M3a project, adopted and locally verified 5 November 2026

The adopted M3a assignment implements one optional **A welcoming square** prototype: an existing park with three distinct developed, road-served and powered home plots within its existing radius. Explicit completion records a one-time achievement and decorates that park with original flowers. Park priority already applies from placement; completion adds no mechanical reward. Clearing the park removes the decoration, not the historical completion. This bounds the initial project hypothesis without altering D17-D27.

[The M3a specification](M3A_SPEC.md) defines the command, presentation, schema-5 record/migration, provenance and tests. U14 authorised implementation after scoping; these rules were adopted before model changes. Game 0.6.0-m3a / schema 5 / m3a-1 is locally verified with 418 source and 360 packed checks plus native Windows scenarios. A strict two-field project record stores completion and anchor; schemas 1-4 gain an incomplete record and schema-4 originals are preserved before replacement. D17-D27 simulation behavior is unchanged. No evidence of human enjoyment is claimed; the full M3 gate remains open. See [M3a evidence](sessions/2026-11-05-m3a.md).

## M2d economy and amenity rule (specified before implementation, 5 November 2026)

**D25 — Monthly budget.** A month is 30 ticks; settle at ticks 30, 60, etc. (display days 31, 61). Increment tick, apply any simultaneous five-day growth round, refresh totals, then settle using that completed development and current services. Commands remain between ticks. All arithmetic is integer cents. Each settlement receives a fixed town grant of 10,000 cents ($100), plus 200 cents per serviced resident and 400 cents per serviced job. A zone contributes only when it has both outside-road access and allocated power; standing unserved development contributes zero tax immediately, including during decline grace. There is no adjustable tax slider. Upkeep is 100 cents per road, 6,000 per station, and 1,000 per park, including disconnected/unused facilities. Empty zones have no upkeep. Forecasts use current state, not a promise about future growth.

Income = grant + resident tax + job tax. Expenses = road + station + park upkeep. Net = income - expenses. On settlement, available = opening cash + income; shortfall waiver = max(0, expenses - available); cash = min(MAX_CASH, max(0, available - expenses)). Overflow above MAX_CASH is explicitly reported as capped surplus. No debt, interest, hidden arrears, service shutdown, destruction, or growth penalty. Construction still requires full cash; free clear and identical repaint remain possible at zero. A negative operating net is a visible deficit even when reserves cover it. Clear surplus facilities for free to reduce upkeep; reconnect services for tax; with everything cleared the grant rebuilds cash every month, allowing a fresh opening. The waiver is a deliberate relaxed-play safety rule, not income or a balanced budget.

**D26 — Pocket park.** Occupancy ID 6; one tile per placement; price $100; upkeep $10/month; key 8. Empty land only, not the outside-link flag. No road/power requirement or consumption and no service relay. Covers homes at Manhattan distance at most 3, regardless of terrain between; overlap does not stack. On each existing growth round, eligible covered homes reserve the existing home demand before uncovered homes. Row-major order breaks ties within each group; shops/workshops keep row-major order. Same prior-state demand, eight-per-type cap, one level per plot, max level 2, and service requirements remain. A park changes which homes develop first under contention; it adds no population capacity, demand, tax multiplier, or decline protection. Coverage rebuilds immediately after edits/load and is derived, never saved. Inspector states coverage and priority; placement uses an independently drawn tree/path/bench placeholder.

**D27 — Persistence.** Game 0.5.0-m2d, schema 4, simulation/content m2d-1. Persist the most recent settlement's input counts, opening cash, and tick in `last_budget`; outputs are recomputed exactly for display. An empty record means no recorded settlement yet (new or migrated town). Strictly validate keys, integer ranges, counts, month boundary and nonfuture tick; no inferred historical ledger. Schema 3 retains all existing development/loss/time/cash/RNG fields and gains an empty ledger; schemas 1/2 still gain zero development. No retroactive budget collection: the next future multiple of 30 settles once. Preserve exact older primary/backup bytes as manual.schema1/2/3.json before replacement. Reject old-format park IDs or ledger fields. Current malformed ledger data fails without replacing the live town. Fixtures remain byte-identical; add a schema-4 boundary/park/ledger fixture. Money is bounded to the existing MAX_CASH; ticks and commands never consume RNG.

This supersedes only M2c's cash-on-tick and home tie-order rules. D17-D24 service contracts remain. Values are original provisional prototype choices. M3 and extra simulation systems are outside this session.

## M2c growth rule (specified before implementation)

**Zones and levels.** Home (ID 2), shop (ID 4), workshop (ID 5); each costs $25 to zone and requests one power unit even while empty. Existing IDs/prices retain their meanings. Each plot has level 0 (empty), 1, or 2. Each home level holds 4 residents; each shop level supplies 2 jobs; each workshop level supplies 4 jobs. Totals count standing development, including during service-loss grace, until it declines. These are aggregate capacities, not individual workers, employment assignments, or a traffic model. Clear immediately removes development and its totals without refund. Repainting an identical zone preserves development for free. Keys 6/7 select shops/workshops; previous bindings remain.

**Demand and bootstrap.** From the prior completed state's population P and total jobs J, target level counts are: home = min(2 × map cells, 3 + floor(J / 2)); shop = ceil(P / 16); workshop = ceil(P / 16). Demand is max(0, target minus existing levels) for each type, measured in level additions. Three home levels (12 residents) of unconditional starter demand break the empty-town deadlock; businesses then get demand from residents and support more homes. Demand alone never evicts existing development. These provisional ratios can settle at 48 residents / 18 jobs when there is enough serviced land of all types; constrained zoning can settle earlier.

**Cadence and order.** A tick is still one day. Ordered commands finish between clock advances and rebuild access, power, then growth totals/next-round eligibility. Each clock step increments tick; at ticks divisible by 5, evaluate one growth round. Evaluate every change from the same prior completed state, reserve demand, then apply all level/counter changes together and refresh totals/eligibility. Each eligible plot gains at most one level per round; each type gains at most 8 levels citywide and never exceeds its prior-state demand. Row-major plot index breaks growth ties, skipping ineligible plots. No RNG is consumed. A multi-step clock update must execute every intervening round, respecting the existing eight-step/backlog bounds.

**Requirements and decline.** Growth needs a side-sharing road connected to the outside link, allocated power, positive demand, and level below 2. Missing either service blocks empty plots immediately. A developed plot loses one level on every second consecutive *growth round* without both services. Its persistent service-loss counter is 0 or 1; a decline resets it to 0. Empty plots always have counter 0. Restoring both services resets the counter immediately, even while paused. Rebuilding can then recover levels on normal growth rounds if demand allows. No cash, command sequence, or RNG changes on ticks. No income/upkeep in M2c.

**Power and explanations.** Nearest-first allocation stays derived and independent of development. New nearer zones can displace grown plots; the two-round delay gives time to add capacity. Road/power networks never pass through zones. The inspector shows zone/level and residents or jobs, separate access/power conditions, current demand, and next-round status (growth, row-major queue, demand satisfied, full, waiting for services, or decline countdown). All text must fit the 320 px inspector at every supported text size. Original geometric silhouettes distinguish zone types and levels. Population, jobs, and demand are visible citywide.

**Persistence.** Schema 3 / `m2c-1` stores `development` and `service_loss` byte arrays with exactly one value per cell. Non-zones must have both zero, levels are 0–2, counters are 0–1, empty plots have counter 0, and a serviced plot cannot retain a loss counter. Schemas 1 (`m1-1`, IDs 0–2) and 2 (`m2b-1`, IDs 0–3) validate under their own versions, then gain two zero-filled arrays; all earlier authoritative values remain unchanged. Load never writes. Before replacing an older primary or backup, preserve its original bytes once as `manual.schema1.json` or `manual.schema2.json`; failed preservation aborts replacement. Keep the three historical fixtures byte-identical and add a schema-3 continuation fixture. Unknown versions and inconsistent development are rejected without replacing the live city. Game version: `0.4.0-m2c`.

## M2a access rule (specified before implementation)

The outside link is a marker on one boundary land tile, representing a road continuing beyond the map. On every generated coastal map it is the east-edge tile at `(width - 1, height / 2)` with integer division. For a loaded custom terrain where that tile is water, choose boundary land with the smallest Manhattan distance from that preferred tile; ties use row-major index. If the entire boundary is water, there is no outside link and the inspector explains that access is unavailable. Selection depends only on dimensions and terrain, never occupancy, RNG, or command order.

The marker adds no road, reservation, charge, or persistent data. Place an ordinary $10 road on the marked tile to activate it. Existing M1 construction is preserved, including a home plot on that tile; clear that plot and lay a road to activate the link. Clearing the root road deactivates access. Roads on other map edges are not additional roots.

Roads receive access exactly when reachable from the root road through side-sharing road tiles. A home plot receives access when at least one side-sharing road is reachable. Diagonals, intervening homes, and open land do not carry access. Recompute the full derived network at initialization/load and after each successful command that adds/removes roads; update affected home-access results after home edits as well. Failed commands and previews never change service.

The camera starts at the link; a labelled control returns to it. A persistent original flag marker identifies it. The inspector distinguishes a missing neighbouring road, an isolated road district, connected access, and a blocked/inactive link. Home text always states that growth and power are not implemented. An optional overlay may expose service, with text/symbols so colour is not the sole explanation. M2a stops here.

M2b supersedes only the "power is not implemented" wording: home text now states that growth is not implemented. Every other M2a access rule above is unchanged.

## M2b power rule (specified before implementation)

**Source.** One facility: a *power station* occupying one land tile. Provisional price **$500** (50,000 cents); capacity **20 power units**. It has no upkeep, fuel, outside-access requirement, or growth effect in M2b. The tool places exactly one station per command; a multi-tile stroke is rejected before any charge. Placing a station on the outside-link marker is rejected so the $10 link road always remains possible. Placement otherwise follows the existing rules: empty land only, whole-command validation, no partial spending. Clear removes it for free with no refund.

**Demand.** Each home-zone plot requests **1 unit**, whether or not anything has grown there (nothing grows in M2b). Roads and stations request nothing. Units are deliberately abstract so M2c can give other zones different demand under a new content version.

**Networks.** A power network is a set of road and power-station tiles joined by shared sides. Stations relay power like roads. Diagonals, home plots, open land, and water do not carry it. A network's capacity is its station count × 20. A home plot may draw from any network with a road or station on one of its four sides. Network order is the row-major index of each network's first tile; that is also the order of a row-major labelling scan.

**Power is independent of road access.** A station supplies its own network whether or not that network reaches the outside link. Road access still uses roads only: a station neither relays road access nor counts as a road beside a home. The inspector reports road access and power as separate conditions; M2c growth will be specified to need both.

**Deterministic allocation (nearest first).** Each network tile has a step distance from the nearest station in its own network (a station is 0; fixed-order multi-source search). A plot's distance through a network is 1 + the smallest distance among that network's tiles on its sides. Plots that touch at least one network containing a station are served in ascending order of (nearest distance, row-major plot index). Each takes 1 unit from its touching network with spare capacity that has the smallest (distance, network order). A plot with no such network is short of capacity. The result depends only on dimensions and occupancy, never command history, stroke order, RNG, or time. There is no stored allocation memory, so adding a plot nearer a station can move a farther plot into shortage; the inspector explains this.

**Explanations.** Home plots report one of: powered (with network use); capacity shortage (touching powered network(s) that are full; add a station to that network); disconnected (touching roads/stations, none reaching a station); no road or station beside the plot; or no power station built yet. Roads and stations report their network's use and capacity, or that no station is on that network. A city total in the toolbar shows used/capacity and the number of plots short of capacity.

**Recalculation.** Power is derived, never serialized, and never consumes RNG. It is rebuilt with road access at initialization, validated load, and after every successful occupancy-changing command; previews, rejected or no-op commands, and clock ticks never change it. All searches are iterative with a fixed neighbour order and remain bounded at 128×128.

**Persistence (D20).** Schema **2**, simulation/content **m2b-1**; occupancy ID **3** = power station. IDs 0–2 keep their schema-1 meanings. A schema-1 save (simulation/content `m1-1`, IDs 0–2 only) is validated and migrated in memory by changing only the three version fields; no other authoritative value changes. Loading never writes. When a save would replace a valid schema-1 primary, or rotate over a valid schema-1 `.bak`, the store first copies that file's exact bytes to `manual.schema1.json` beside the primary, unless such a preserved copy already exists. If that copy fails, nothing is replaced. (The backup case was added during M2b verification: recovering from a schema-1 backup over a corrupt primary would otherwise lose the old-format bytes on a later rotation.) The normal previous-good `.bak` rotation is unchanged. Schemas above 2, schema 2 with other version strings, and schema 1 containing ID 3 are rejected without changing the current city or file. Game version **0.3.0-m2b**; build 0.2.0 rejects schema 2 through its existing schema check, so rolling back requires the preserved schema-1 copy.

**Controls (D21).** P selects the power station; E toggles power marks: a bolt on powered plots and on roads/stations in a network with a station, a cross on unpowered plots. M2b stops here: no growth, residents, shops/workshops, upkeep, or monthly economics.

## Assumptions, not established facts

- Solo or small-team development; no staffing, skill level, budget, or weekly availability was confirmed.
- A small premium game with a free demo is a plausible eventual business model, not a pricing decision.
- UK and US public IP guidance is a useful starting point. The owner's legal jurisdiction and intended sales territories are unconfirmed.
- The proposed neighbourhood-project feature is a design hypothesis. It is not a claim of novelty, market demand, or legal clearance.
- The foundation now has local engine/export/input/save evidence. Performance targets, controller ergonomics, fun, sales potential, and broader hardware support remain untested.

## Open decisions and when they matter

| Decision | Default until resolved | Resolve before |
| --- | --- | --- |
| Final name and brand | Untitled city builder; neutral internal identifiers | Public store page, domain purchase, or promotional identity |
| Development time and cash budget | Keep M0/M1 narrow; make no purchases | Commissioning assets or promising a schedule |
| Legal owner, territories, source licence | No new licence grant; record authorship | Outside contributions, contracts, and publication |
| Final art/audio production route | Self-created geometric placeholders only in M1 | M3 production spending |
| Linux/macOS/Deck support | Unpromised | Advertising support for a platform |
| Final price and release date | Unset | Store launch planning after slice evidence |
| Steam or itch.io accounts and availability | Unchecked | Any external release work |

None of these unanswered commercial questions prevents local prototype implementation.

## Change record

- 2026-11-04: Planning baseline written. User's desktop and relaxed-play preferences incorporated. Repository contained no game. Local Godot 4.6.3 detected; official recommended baseline 4.7.2 documented. No implementation or external changes performed.
- 2026-11-04, subsequent implementation: user authorised M0/M1. Installed verified isolated 4.7.2 editor/templates; created original foundation, focused tests, native Windows export, packaging, and notices. Adopted D13–D16; see [evidence](sessions/2026-11-04-m0-m1.md). No purchase, public release, commit, or push performed.
- 2026-11-04, M2a: user authorised road access/zone explanations and then commit/push. Adopted D17–D18 before coding, preserved the M1 save fixture, implemented deterministic derived access and the original inspector/flag/overlay, and tested the Windows export. See [M2a evidence](sessions/2026-11-04-m2a.md).
- 2026-11-04, M2b: user authorised power access, export testing, docs/handoff, commit and push (U08). Recorded D19–D21 and the power rule before model code; captured an M2a fixture with unchanged code first. Implemented derived power networks with nearest-first allocation, schema 2 with in-memory schema-1 migration and preserved originals, and the P tool/E marks/inspector/toolbar. Tested the Windows export natively through posted window input (desktop computer-use tools were unavailable). See [M2b evidence](sessions/2026-11-04-m2b.md). M2c–M2d remain future work.

- 2026-11-04 to 2026-11-05, M2c: user authorised growth, export testing, docs/handoff, commit, push, and merge (U09). D22-D24 were recorded before model edits. Implemented three zone types, level growth/decline, demand/bootstrap, original building placeholders, and schema-3 migration. Passed 298 source / 277 packed checks and native Windows growth/shortage/restart/recovery/largest-text checks. See [M2c evidence](sessions/2026-11-05-m2c.md). M2d remains future work; no public game release.
- 2026-11-05, U10 study handoff: M2c commit `826ecc3` is pushed and merged into default branch `codex/m2a-road-access`. The owner scheduled one Micropolis study for the next session, ahead of the unchanged M2d assignment, with a strict study/implementation separation and no copying or translation. Updated the handoff and project boundaries only; no reference source was fetched, opened, or read, no study findings were claimed, and no game files or licence grants changed in this follow-up.

- 2026-11-05, U10 study completed under U11: inspected the pinned maintained engine and requested licence documents; wrote qualitative system notes, D17-D24 comparisons, and exhaustive consulted-file provenance. No reference code executed or incorporated, no game files changed, and no recommendations adopted. Updated the handoff to the unchanged M2d assignment; the reference-source reading permission is exhausted. Documentation delivery is authorised through commit, push, and default-branch integration.

- 2026-11-05, U12 M2d: specified D25–D27 before model code, implemented monthly budgets, deficit recovery, park priority, schema 4 and preserved schema-3 originals. Passed 361 source / 324 packed checks and native Windows accounting/park/deficit/restart checks; restored user saves. Local M2 functional gate met, not a human enjoyment or performance-target pass. See [M2d evidence](sessions/2026-11-05-m2d.md). Follow-up owner instruction authorises delivery from `codex/m2d-economy` to the default branch by push and fast-forward integration, and makes this the standing completion workflow. No public release.

- 2026-11-05, U13 M3 scoping: reviewed the delivered M2d checkpoint and product gates; specified proposed D28 and a bounded M3a implementation handoff. Documentation only; no game code, assets, saves or binaries changed, and no new runtime/playtest claim. See [scoping record](sessions/2026-11-05-m3a-scope.md).

- 2026-11-05, U14 M3a: adopted D28 before code, implemented one optional square project, cosmetic flowers, modal project/scrollable Help and schema-5 persistence. Verified 418 source / 360 packed checks, native completion/restart/removal and restored original saves. Updated the bounded next handoff; standing source delivery applies. No full M3 completion or public release.

- 2026-11-06, U15 M3b scoping: confirmed that M3a delivery had completed despite the previous session's interrupted close-out. Reviewed the checkpoint and recorded UX limits; found no blocking defect that must precede a guide. Specified proposed D29 and a bounded M3b handoff. During the session the owner set U16 (4x4 zone lots) and U17 (lean closer to the classic genre within copyright limits). Specified proposed D30 (M2e lots) as the next implementation. Follow-up owner answers added 4x4 power stations with a closest-to-original preference (U18) and set zone lots to 3x3, as in the original (U19). Recorded [genre candidates](GENRE_ALIGNMENT.md) for owner choice. M3b now follows M2e. Documentation only: no game code, assets, saves, fixtures or binaries changed, and no runtime or playtest claim. See [scoping record](sessions/2026-11-06-m3b-scope.md).

- 2026-11-06, U20 M2e: adopted D30 before model edits; implemented 3x3 zone lots, 4x4 power stations, footprint-aware access/power/growth/park/project/economy, original lot and station art, lot runs and whole-footprint clearing, and schema 6 with cleared-footprint migration of schemas 1-5. Verified 479 source / 415 packed checks, release-EXE startup, and a posted-window-message native run of the actual EXE (with a smoke rerun on the final export); the unpackaged profile was restored. See [M2e evidence](sessions/2026-11-06-m2e.md). No full M3 completion or public release.

- 2026-11-06, U21 artwork evaluation: acquired Kenney Tiny City 1.0 and Roguelike Modern City 2.0 (CC0 confirmed), added presentation-only art modes with the original renderer as default and fallback, captured three equivalent 1920x1080 screenshots from the real EXE and a side-by-side, and wrote the [evaluation](artwork-review/ARTWORK_EVALUATION.md). Verified 482 source / 428 packed checks plus a native run. No pack selected; owner decision pending; NEXT_SESSION assignment unchanged.

- 2026-11-06, U22: after reviewing the artwork side-by-side, the owner chose Kenney Roguelike Modern City as the artwork direction. Recorded only; it is not yet the default style, and the NEXT_SESSION assignment is unchanged.
