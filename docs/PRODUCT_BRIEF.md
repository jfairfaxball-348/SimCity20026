# Product brief

Status: proposed design, 4 November 2026. User-confirmed priorities are recorded in [Decisions](DECISIONS.md).

Implementation checkpoint: M0/M1 provides map editing, clock controls, and saves; M2a adds road access and home-zone explanations. Power, growth, economy, projects, final art/audio, and the experience described below remain future work; see [README](../README.md) for current capabilities.

## The experience

Build a small town that becomes recognisably yours. Place streets and zones, supply basic infrastructure, watch residents move in, and complete small civic projects that change the appearance and usefulness of a neighbourhood. A session should offer a satisfying improvement in 15–30 minutes without demanding constant attention.

The game should feel welcoming without making every decision irrelevant. Players balance a simple budget and competing land uses, but can pause whenever they like, inspect why growth has stalled, and recover from mistakes. No surprise destruction or irreversible bankruptcy spiral in the default mode.

The historical reference needs a small clarification: the user named the 1989 original; Nintendo dates its Super Famicom adaptation to 26 April 1991. Nintendo's own description highlights changing seasons, additional scenarios, and music. Those are useful experience references, not permission to reproduce the presentation. [Nintendo release record](https://www.nintendo.co.jp/wii/vc/vc_sc/vc_sc_01.html), [Nintendo overview](https://www.nintendo.com/en-gb/Games/Virtual-Console-Wii-/SimCity--278964.html).

## Design pillars

1. **A town that responds visibly.** Homes fill, workshops become active, and planted public spaces develop. The map carries much of the feedback.
2. **Understandable causes.** Selecting an empty zone should explain its next requirement in ordinary language: road access, power, jobs, or demand. Show relevant coverage and costs before committing a placement.
3. **Gentle, meaningful management.** A few economic controls, predictable accounting, optional goals, and forgiving recovery. Avoid a wall of hidden ratios.
4. **Original character.** A distinct palette, architecture, interface, writing, and soundtrack. The product should be recognisable without the reference game's name beside it.

## The basic loop

Observe a local need → plan an affordable change → place roads, zones, or an amenity → let the town respond → inspect the result → choose another neighbourhood improvement.

The proposed signature feature is **neighbourhood projects**. A maturing neighbourhood offers a modest civic goal, such as establishing a garden square near occupied homes. Completing it adds a visible improvement and a small local amenity benefit. Start with one project in the playable slice. Larger theme sets, procedural stories, and complex district governance are outside the first release.

This is a hypothesis to test. Players must understand it and care about the result before more projects are produced.

## Comparable products and positioning

This is a qualitative product comparison, not a sales forecast. No competitor binaries, code, assets, or paid research were obtained.

| Reference | Publicly described offering | Implication for this project |
| --- | --- | --- |
| TheoTown | Broad city management, zoning, utilities, regional expansion, and extensive transport | A retro-looking city builder already has strong genre neighbours. Keep our simulation smaller and explanations clearer; do not compete on feature count. |
| Urbek City Builder | Neighbourhood development, surrounding-condition requirements, and a resource economy without money | Adjacency and neighbourhood identity are established design territory. Our project goals need their own execution, not a novelty claim. |
| Dorfromantik | Peaceful landscape building through tile placement and quests | A useful reference for low-pressure pacing. Our continuing economy and growing settlement should provide a different reason to return. |

Sources: [TheoTown developer store description](https://store.steampowered.com/app/1084020/TheoTown/), [Urbek developer store description](https://store.steampowered.com/app/1411740/Urbek_City_Builder/), [Toukana's Dorfromantik description](https://www.toukana.com/dorfromantik).

Proposed positioning: **a small, readable city simulation about making welcoming neighbourhoods**. This is stronger than advertising a replica of a named classic, and small enough to test with a modest slice.

## Scope boundaries

| Area | First playable slice | Narrow 1.0 candidate |
| --- | --- | --- |
| Map | One 64x64 map, land/water/trees, guaranteed connected starting land | Up to 128x128; three curated seed presets plus seed entry; one visual setting |
| Construction | Road, homes/shops/workshops zoning, power source, park, demolition | Same basic vocabulary; a small set of civic amenities and visual variants |
| Simulation | Road access, power capacity, aggregate population/jobs/demand, simple taxes and upkeep | Tuned growth, local amenity and nuisance effects, understandable decline/recovery |
| Goals | One neighbourhood project and a short guided opening | Three project types, short onboarding, free-building sandbox |
| Content | Programmer placeholders followed by one coherent sample neighbourhood | Rough planning cap: 12–18 building silhouettes, 2–3 growth appearances where useful, limited decorations |
| Input | Mouse/keyboard; complete controller path by M3 | Remapping, controller prompts, scalable text, high-contrast overlays |
| Persistence | Manual saves and reliable round trips | Several slots, rotating autosaves, backups, migration policy, recoverable errors |
| Audio | Silent foundation; original sample ambience/music in M3 | A small original or properly licensed soundtrack and consistent effects |

Counts are scope ceilings to refine after M3, not promises to players. A larger map or more buildings is not automatically a better game.

Exclude from the first release: individual simulated citizens, realistic traffic routing, multiplayer, mod loading, online accounts, live AI dialogue, cloud infrastructure, 3D or camera rotation, mobile/console ports, extensive disaster systems, campaign narrative, and a full industry supply chain. Water service is abstracted at this scope. Roads also carry the simplified power connection, so there is no separate wiring tool.

## Feel, art, and usability

- Square-grid top-down view with original building sprites showing a little height. Avoid introducing isometric coordinate/rendering complexity.
- Start with 16x16 ground tiles and a 640x360 world viewport. Use nearest filtering and integer scaling; keep interface text independently readable. The technical plan defines a display spike before committing to the layout.
- Develop an original palette, silhouettes, roof shapes, signage, and icons. Use several real-world architectural references, not traced game screenshots. Seasonal colour changes are optional polish after the core art works.
- Use compact panels for tools, treasury, population, time, and the selected tile. Include short written reasons alongside indicators; do not depend on colour alone.
- Placement previews show total cost, affected cells, and validity. Cancel is always available before committing a stroke. Do not promise unrestricted undo after the simulation advances.
- Pause, normal speed, and fast speed are sufficient. Construction works while paused. No real-time deadline in default objectives.
- Music, effects, and ambience have separate volume controls. Avoid flashing feedback, mandatory camera shake, and obligatory CRT filters.
- Text is externalisable from the start. English-only is a scope default, not a promise of immediate localisation.

## Playtest gates

Before expanding the content set, run an observed M3 test with at least five people who did not build the game, including people who are not experienced city-builder players. Record failures and comments; do not turn five opinions into market statistics.

Proposed progression criteria:

- At least four can place a viable starting neighbourhood within ten minutes with only the in-game guidance.
- At least four can explain one blocked zone and fix its cause without the developer intervening.
- At least four can complete the first neighbourhood project within a 20–30 minute session.
- At least three choose to continue building for another ten minutes when offered the choice.
- No save loss, unrecoverable economy trap, or repeated input confusion is observed.

These are working design gates, not evidence already collected. If the result is weak, simplify the loop or improve feedback before buying or making more content. Re-test the changed experience with fresh participants where possible.
