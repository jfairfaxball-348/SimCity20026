# Micropolis study: qualitative design notes

Study completed **5 November 2026** under U10 and the owner's instruction to start the study. This is documentation-only research. **The session wrote no game code. M2d remains unimplemented.** All adopt/adapt/reject recommendations below are proposals; none changes the adopted rules in [Decisions](../DECISIONS.md).

The reference is the maintained [MicropolisCore repository](https://github.com/SimHacker/MicropolisCore), pinned at `bd6e12eed6e148fe25270e7a4e2278f71a89f26c`. The [provenance record](MICROPOLIS_PROVENANCE.md) inventories every consulted reference file and its immutable identity. The optional legacy repository was not fetched or read. These observations concern this pinned engine, not a verified reconstruction of the original release or a comparison between ports.

**Evidence language:** an **observation** comes from static source inspection. **Player feedback** describes the information the engine supplies to a frontend, not a tested screen or play session. An **interpretation** is the study author's assessment. **Gaps** remain unverified. No reference code, build scripts, tests, binaries, or game were executed. No reference images or audio were opened.

Implementation sessions must never open the reference checkout, linked source, or reproduced source elsewhere. Their only reference-design inputs are this document and Decisions. Source links in the provenance record are audit locators, not implementation reading assignments.

## Licence documents and limits

The pinned **LICENSE** contains the GPL text and additional notices. The **Micropolis GPL License Notice** permits use under GPL v3 or a later version and adds EA terms: retain the notices, identify modifications honestly, claim no trademark/publicity rights or affiliation, and observe its conditional indemnity when assuming contractual liability to recipients. It also disclaims warranties. Distribution of covered source or binaries carries GPL obligations, including appropriate notices and corresponding source; consumer-device installation information can also matter. This is a brief document summary, not a determination of how a future product would be classified. [Licence provenance](MICROPOLIS_PROVENANCE.md#licensing).

The **Micropolis Public Name License**, dated **1 October 2024**, separately describes a revocable, non-commercial permission for the name in connection with the project. It requests attribution, including in writing about the project, limits confusing or promotional use, and restricts branding, domains, prominent accounts, and publication covers without the stated permissions. It also contains cessation and dispute provisions. These are the document's stated terms; their enforceability and application to this research have not been adjudicated here. Attribution: the document identifies **Micropolis** as a registered trademark of **Micropolis GmbH / Micropolis Corporation** ([named owner](https://www.micropolis.com/)). Its name is used here solely to identify the research subject. [Name-licence provenance](MICROPOLIS_PROVENANCE.md#licensing).

All requested licence documents were present. This review did not audit every contributor, asset, dependency, or jurisdiction, nor establish historical licence terms across revisions. The current name document is later than the original source release. The project's study/implementation separation is a working rule, not legal clearance. No licence was added to this game, no reference material was incorporated, and no product title was selected. [D10](../DECISIONS.md#d10), [D11](../DECISIONS.md#d11), and the [project rights boundary](../IP_AND_ASSETS.md#micropolis-study-and-implementation-boundary) remain in force.

## Demand, homes, shops, and workshops

**Observation.** The reference has residential, commercial, and industrial development. Those are only broad counterparts to this project's homes, shops, and workshops. Citywide demand depends on aggregate development, employment/market relationships, past counts, tax policy, and difficulty. Local development also responds to power, transport attempts, and environmental suitability. Homes and businesses do not all use the same local tests. Civic infrastructure can limit expansion. Demand changes and individual growth decisions are separate processes. [Demand evidence](MICROPOLIS_PROVENANCE.md#demand).

**Player feedback and cost.** The engine supplies demand indicators, population history, local development status, and advice. It revisits districts during portions of a map sweep, while aggregate demand updates on its own cadence. Random selection reduces how often some local decisions are attempted. Interpretation: a positive demand indicator describes pressure for development, not a promise that a selected plot will grow next.

**Pitfall and proposal.** Several random checks intervene between favourable conditions and a building change. A status category alone cannot explain a particular wait. **Adopt as a design principle** the distinction between city demand and local eligibility. **Reject for this project** random permission to grow, hidden civic prerequisites, and demand-driven eviction. Retain the published bootstrap, completed-state evaluation, bounded growth, and recoverable service loss of [D22](../DECISIONS.md#d22). Any later amenity should expose its contribution separately. No reference demand relationships or tuning become our specification.

## Land value

**Observation.** Land value reflects proximity to the developed city centre and surrounding terrain, with pollution and sufficiently severe crime reducing it. It influences residential suitability, commercial development, tax receipts, and the city's assessment of housing expense. Thus a favourable location can help growth while also worsening an affordability complaint. [Spatial evidence](MICROPOLIS_PROVENANCE.md#spatial).

**Player feedback and cost.** The engine provides a spatial field and a local category, while averages feed other systems. A coarser grid and neighbourhood smoothing avoid detailed property markets. These fields refresh separately from zone visits. Interpretation: local conditions can be stale relative to a recent edit, and a broad category can conceal a meaningful change.

**Pitfall and proposal.** **Adapt** the idea of a visible neighbourhood benefit for the already queued amenity. **Reject for M2d** a separate land market, wealth tiers, and an assumed city-centre preference. They add coupled effects without a clear decision for this small game. Choose the amenity's own coverage and effect later, within [D12](../DECISIONS.md#d12) and [D22](../DECISIONS.md#d22); do not make the park depend on implementing land value first.

## Pollution

**Observation.** Transport activity and certain developed uses contribute pollution. The spatial field lowers land value; local pollution can also prevent residential expansion. Citywide pollution contributes to evaluation and can influence a disaster trigger. Industrial animation is presentation, not a reliable substitute for the underlying environmental field. [Spatial evidence](MICROPOLIS_PROVENANCE.md#spatial), [growth evidence](MICROPOLIS_PROVENANCE.md#demand), [disaster evidence](MICROPOLIS_PROVENANCE.md#disasters).

**Player feedback and cost.** The engine offers local categories, a spatial field, history, and city warnings. Contributions are aggregated and smoothed periodically on reduced-resolution maps. Interpretation: broad spread and lag are cheap, but a player can mistake a delayed update for an ineffective intervention.

**Pitfall and proposal.** **Adopt as a future principle** visible sources and an explained local consequence if nuisance earns a later milestone. **Reject for M2d** adding pollution, or making this project's workshops inherit an industrial penalty by analogy. A nuisance feature would need its own recovery and explanation tests under [D06](../DECISIONS.md#d06), [D10](../DECISIONS.md#d10), and [D12](../DECISIONS.md#d12).

## Crime

**Observation.** Crime is an aggregate spatial model: density and land value affect it, and police coverage reduces it. Crime in turn can lower land value and worsen the city evaluation. Police effectiveness depends on funding and access to services. This is a designed feedback loop, not evidence about actual neighbourhoods or people. [Spatial evidence](MICROPOLIS_PROVENANCE.md#spatial), [services evidence](MICROPOLIS_PROVENANCE.md#services).

**Player feedback and cost.** Local categories, spatial information, warnings, and evaluation complaints expose the results. Periodic coarse-grid analysis and smoothed coverage avoid individual incidents or agents. Interpretation: mutually reinforcing low value and crime can be hard to diagnose if the interface only reports the result.

**Pitfall and proposal.** **Reject for the current scope** crime, police coverage, and density-as-danger assumptions. They are unnecessary to the relaxed building loop and would create another expenditure/recovery dependency. If safety services are considered much later, **adapt** only the general idea that funded facilities should explain what they provide. [U05](../DECISIONS.md#confirmed-by-the-user), [D06](../DECISIONS.md#d06), [D12](../DECISIONS.md#d12).

## Traffic and road access

**Observation.** The reference attempts journeys from zones toward suitable destinations. Successful attempts contribute to a remembered traffic field; lack of nearby transport and failed journeys have different effects on development. Random route choices and a search limit mean a failed attempt is not proof that no route exists. Traffic affects road appearance, pollution, upkeep demand, and evaluation. [Transport evidence](MICROPOLIS_PROVENANCE.md#transport).

**Player feedback and cost.** Road appearance, density information, and congestion advice convey traffic. Journey work is bounded and sampled during zone processing; remembered activity fades on a separate update. It is not a simulation of persistent individual commuters. Source annotations flag concerns about route recovery; this study did not reproduce a runtime defect.

**Pitfall and proposal.** **Adopt** bounded network work as a principle. **Reject** sampled journeys as an access test here. Keep [D17](../DECISIONS.md#d17)'s explicit outside link and side-sharing reachability, with derived state under [D18](../DECISIONS.md#d18). Do not add traffic in M2d. A later traffic proposal must distinguish structural access from congestion and must not silently replace the existing access contract.

## Power

**Observation.** The reference has generation capacity, conducting terrain/buildings, and a powered-state field. Shortage can stop a scan before every reachable place receives power. The inspected treatment pools generation for that scan; its allocation depends on traversal rather than this project's separately accounted networks and nearest-first plot policy. Power affects development and public-service effectiveness. [Power evidence](MICROPOLIS_PROVENANCE.md#power).

**Player feedback and cost.** The engine supplies power-map updates, local powered state, and shortage warnings. Iterative traversal and bounded storage avoid recursive per-building simulation. Power refreshes in a scheduled phase, followed by updates to local status. Interpretation: scan order and delayed refresh can make a particular outage difficult to predict from citywide capacity alone.

**Pitfall and proposal.** **Adopt** explicit supply, connectivity, and shortage explanations. **Reject** importing conducting-building rules, pooled capacity, or scan-order allocation. Retain [D19](../DECISIONS.md#d19), [D21](../DECISIONS.md#d21), and [D23](../DECISIONS.md#d23): distinct access/power explanations and the existing allocation policy. New nearby plots displacing older ones is already a known local tradeoff; preserve its explanation and grace period rather than silently adding allocation memory.

## Services and budget

**Observation.** Roads, fire protection, and policing have operating funding. Tax income depends on aggregate development and value, while tax policy also affects demand. Insufficient funds reduce effective provision. Fire/police coverage is weakened by missing power or nearby roads; fire protection improves suppression and police provision reduces the crime field. Underfunded transport can deteriorate. [Services evidence](MICROPOLIS_PROVENANCE.md#services).

**Player feedback and cost.** Budget and tax updates, financial history, funding warnings, and service fields expose the loop. Accounting uses aggregate totals on a slower cadence; coverage spreads through coarse spatial analysis. Interpretation: cheap aggregate accounting is suitable for a small city builder, but building a facility is not the same as funding or supplying it.

**Pitfall and proposal.** The reference contains annotations questioning empty-city treatment and the timing of budget-dialog acceptance; those are audit leads, not tested failures. **Adopt** visible expected income, expenses, and reasons for inadequate provision. **Adapt** coverage only to the queued park/amenity. **Reject** hidden funding priorities, automatic infrastructure destruction, and a spiral that removes the means of recovery. M2d must specify its own integer accounting, month boundary, service treatment, station upkeep, deficit recovery, and save contract before implementation. This restates the existing assignment under [D06](../DECISIONS.md#d06), [D12](../DECISIONS.md#d12), [D14](../DECISIONS.md#d14), and [D24](../DECISIONS.md#d24); it does not settle any economic value.

## City evaluation

**Observation.** Evaluation combines citywide difficulties, service provision, growth, and power into a smoothed assessment. It also produces sampled opinion and complaint ordering. High land value can be treated as housing expense. Population/economic quantities are aggregates with different roles, not individual residents reporting experiences. [Evaluation evidence](MICROPOLIS_PROVENANCE.md#evaluation).

**Player feedback and cost.** The engine offers an overall assessment, population change, city category, and selected complaints. Evaluation runs periodically and mostly reuses totals, with bounded sampling and coarse traffic aggregation. Interpretation: an overall rating can communicate direction, but it does not identify the cause of a particular stalled plot. Random complaints can change without a proportionate underlying change.

**Pitfall and proposal.** **Adapt later** a short, actionable city summary backed by measurable causes. **Reject for M2d** an approval score, simulated voting, and complaint randomness. The existing inspector and understandable budget take priority. Keep residents/jobs described as capacities under [D22](../DECISIONS.md#d22); the proposed neighbourhood projects in [D07](../DECISIONS.md#d07) remain a separate, unvalidated idea.

## Disasters

**Observation.** The reference supports random hazards, scripted scenario events, fire/flood spread, and facility-related failure. Damage removes usable development and can disrupt the systems that support recovery. Fire protection affects suppression. The inspected scheduling handles scenario events separately from the switch controlling random disasters, so that switch alone is not evidence that every source of damage is disabled. [Disaster evidence](MICROPOLIS_PROVENANCE.md#disasters).

**Player feedback and cost.** The engine emits event notices and changes damaged map cells. Some hazards propagate through later map visits; other events perform a bounded burst of work when triggered. The complete moving-hazard implementation and frontend presentation were not reviewed. There is no frame-time measurement here.

**Pitfall and proposal.** **Reject** disasters in M2d and mandatory destructive events in the relaxed default. **Adapt only if separately authorised later** the broad idea of voluntary challenges with clear consent, a stated extent, and a viable recovery path. Do not carry over scenario names, event sequences, assets, or hazard tuning. [U05](../DECISIONS.md#confirmed-by-the-user), [D10](../DECISIONS.md#d10), [D12](../DECISIONS.md#d12).

## Scheduling, randomness, and explanation

**Observation.** Work is spread between map portions and periodic analyses. Derived spatial fields use compact grids; totals and histories avoid citizen simulation; change notifications reduce unnecessary presentation updates. Different analyses can describe different moments of the city. Selected speed affects some analysis cadences. Random choices occur in growth, routes, hotspot selection, opinion, hazards, and some visual choices, using the same engine random facility. [Scheduling evidence](MICROPOLIS_PROVENANCE.md#scheduling).

**Interpretation.** Those techniques keep work manageable but trade immediate consistency and causal clarity for approximation. A seed alone does not establish identical continuation if call order, speed, intermediate state, or saved random state differs. This study did not audit reference save files or prove its replay behaviour. Source annotations and historical reputation are not performance or correctness evidence.

**Proposals for our architecture.** Retain [D05](../DECISIONS.md#d05)'s bounded map, [D06](../DECISIONS.md#d06)'s independent aggregate model, [D13](../DECISIONS.md#d13)'s rendering separation, and [D14](../DECISIONS.md#d14)'s fixed logical clock. Keep the D22 growth outcome predictable from the completed state. If later profiling justifies spreading work, define when results become visible and ensure partial calculations cannot change decisions. Do not make simulation outcomes depend on rendering or selected speed. Keep cosmetic variation separate from authoritative randomness, as already proposed in the technical plan.

For each future blocker, the inspector should be able to explain the current condition, the next decision point, and a remedy available to the player. If several conditions fail, retain their separate explanations. Do not replace that contract with an aggregate desirability score or a random wait. These are qualitative design goals, not a reference-derived algorithm.

## Explicit decision cross-check

| Existing decision | Study recommendation; no adoption change |
| --- | --- |
| [D17](../DECISIONS.md#d17) | Retain the outside-link access rule. A sampled trip is not a substitute for reachability. |
| [D18](../DECISIONS.md#d18) | Retain derived access and historical save meanings; do not serialize a spatial cache by analogy. |
| [D19](../DECISIONS.md#d19) | Retain our power topology and per-network accounting; reference conductivity is different. |
| [D20](../DECISIONS.md#d20) | Retain explicit migration and preserved originals; no legacy save format is an input. |
| [D21](../DECISIONS.md#d21) | Retain controls and distinct power marks; no reference interface layout, strings, or bindings are adopted. |
| [D22](../DECISIONS.md#d22) | Retain deterministic bounded growth, bootstrap, separate causes, and relaxed decline/recovery. |
| [D23](../DECISIONS.md#d23) | Retain derived allocation and its documented displacement behaviour; no new priority state. |
| [D24](../DECISIONS.md#d24) | Retain versioned authoritative state, validation, and fixture preservation. M2d must separately decide any new persisted meaning. |

Earlier desktop, offline, original-art, small-checkpoint, and local-verification choices also remain unchanged. The study supplies no reason to change engine, platform, input route, or packaging. No proposed land value, pollution, crime, traffic, evaluation, or disaster system is added to the next assignment.

## Gaps and handoff

The static engine review establishes the relationships described above, not actual UI quality, enjoyment, numerical balance, runtime performance, historical equivalence, or legal clearance. The optional original-C repository, frontend layouts, moving-hazard internals, save/reload implementation, dependencies, and assets were not studied. No claim of absent features follows from that limited coverage.

The documentation-only study is complete. Its [provenance](MICROPOLIS_PROVENANCE.md) and [session evidence](../sessions/2026-11-05-micropolis-study.md) record the boundary checks. The next session is the **unchanged M2d economy and amenity assignment** in [NEXT_SESSION.md](../../NEXT_SESSION.md#queued-after-the-study-m2d-economy-and-amenity-unchanged). Choose and test our own rules there. Do not reopen the reference source.
