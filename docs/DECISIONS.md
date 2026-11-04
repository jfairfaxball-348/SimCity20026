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
| U07 | Implement M2a road access and zone explanations, test the Windows export, update docs/handoff, then commit and push | Current session and follow-up instruction |

U06 superseded the earlier planning-only scope for M0/M1. U07 authorises the M2a checkpoint and the initial source commit/push, not the rest of M2 or a public game release.

## Working defaults and adoption

D01–D06, D08, and the M1 part of D10 were adopted for the foundation. Later product and commercial choices remain proposals. Change defaults when evidence or new instructions justify it, and record the reason here.

| ID | Default | Reason / revisit condition |
| --- | --- | --- |
| D01 | Godot 4.7.2 Standard + typed GDScript + Compatibility | Integrated 2D/UI/export tooling, permissive engine licence, modest deployment scope. Revisit only for a concrete engine blocker or a changed target. |
| D02 | Windows 11 x64 is the first development/release target | The native export has been exercised on one machine; this does not certify a broad hardware matrix. Add other targets only with testing capacity. |
| D03 | Mouse and keyboard first; input actions and focus navigation support later controller work | Keeps the first checkpoint small while retaining the console-inspired accessibility goal. Full controller coverage belongs in the playable slice. |
| D04 | Top-down grid; 16-pixel cells; 640x360 world view with independently scalable UI | Implemented with integer scaling/zoom. Native 720p, 1366x768, 1280x800 inspected; full 1080p capture and Windows DPI variations remain unverified. |
| D05 | 64x64 foundation; 128x128 initial release ceiling | Bounds simulation and content work. Raising the ceiling needs profiling and a gameplay reason. |
| D06 | Aggregate simulation, discrete clock, seeded randomness, independent model and renderer | Reliable saves, testability, and understandable consequences. No individual citizen simulation. |
| D07 | One proposed signature feature: visible neighbourhood projects | Gives a small city personal goals; validate with players before expanding content. |
| D08 | Offline single player, no account/backend/live AI, no monetisation systems in the prototype | Suits relaxed play and avoids unnecessary operational scope. |
| D09 | Restricted desktop playtests, then optional public demo, then possible Steam 1.0 | Validate usability and stability before commercial release obligations. |
| D10 | Original programmer placeholders first; original final art/audio with recorded rights | Avoids both premature asset spend and dependence on reference-game content. |
| D11 | No open-source licence grant selected in this session | Source licensing and commercial ownership remain the owner's choice; engine MIT does not decide the game's licence. |
| D12 | Complete small verified checkpoints before broader simulation/content | Foundation and M2a completed locally; the next small assignment is M2b power access. |
| D13 | One custom-drawn Node2D for original geometric M1 tiles | Avoids an unnecessary atlas/asset pipeline for placeholders. No per-cell processing Nodes. Revisit TileMapLayer/atlas rendering with original art and profiling evidence. |
| D14 | Synchronous ordered commands and a bounded fixed clock | Commands commit between clock updates, including paused. Eight ticks/frame; retain up to one simulated hour of backlog, discard only excess beyond that bound. No offline catch-up. |
| D15 | Schema 1, simulation/content m1-1, strict JSON and previous-good backup | Lossless RNG strings, validated temporary writes, explicit recovery. No migration or power-loss guarantee yet. |
| D16 | Local checks/package before remote CI adoption | Initial source commit/push authorised with M2a. Scripts are reproducible; CI remains a future deliberate setup task, not a claimed result. |
| D17 | One visible outside link; orthogonal road access | M2a rule recorded before coding below. Keeps the first network understandable without traffic or growth. |
| D18 | Derive M2a access from existing terrain/roads; retain schema 1 and m1-1 simulation/content | M2a adds observational access only: no stored IDs, map generation, prices, clock, RNG, or growth rules change. Preserve and test an original M1 fixture; never write derived access into saves. |

## M2a access rule (specified before implementation)

The outside link is a marker on one boundary land tile, representing a road continuing beyond the map. On every generated coastal map it is the east-edge tile at `(width - 1, height / 2)` with integer division. For a loaded custom terrain where that tile is water, choose boundary land with the smallest Manhattan distance from that preferred tile; ties use row-major index. If the entire boundary is water, there is no outside link and the inspector explains that access is unavailable. Selection depends only on dimensions and terrain, never occupancy, RNG, or command order.

The marker adds no road, reservation, charge, or persistent data. Place an ordinary $10 road on the marked tile to activate it. Existing M1 construction is preserved, including a home plot on that tile; clear that plot and lay a road to activate the link. Clearing the root road deactivates access. Roads on other map edges are not additional roots.

Roads receive access exactly when reachable from the root road through side-sharing road tiles. A home plot receives access when at least one side-sharing road is reachable. Diagonals, intervening homes, and open land do not carry access. Recompute the full derived network at initialization/load and after each successful command that adds/removes roads; update affected home-access results after home edits as well. Failed commands and previews never change service.

The camera starts at the link; a labelled control returns to it. A persistent original flag marker identifies it. The inspector distinguishes a missing neighbouring road, an isolated road district, connected access, and a blocked/inactive link. Home text always states that growth and power are not implemented. An optional overlay may expose service, with text/symbols so colour is not the sole explanation. M2a stops here.

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
- 2026-11-04, M2a: user authorised road access/zone explanations and then commit/push. Adopted D17–D18 before coding, preserved the M1 save fixture, implemented deterministic derived access and the original inspector/flag/overlay, and tested the Windows export. See [M2a evidence](sessions/2026-11-04-m2a.md). M2b–M2d remain future work.
