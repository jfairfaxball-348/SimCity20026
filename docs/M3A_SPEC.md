# M3a: one neighbourhood project prototype

Scoped and subsequently implemented 5 November 2026 under the next-session owner request. **Implemented and locally tested; the full M3 gate remains open.** See [session evidence](sessions/2026-11-05-m3a.md). The rules below were specified before implementation.

## Player benefit and hypothesis

**A welcoming square** gives the player one optional, legible goal: grow three occupied, serviced home plots around a pocket park, then celebrate the square with a visible flower decoration. The checklist connects roads, power, development and the existing park benefit to a specific place. No deadline, failure penalty, recurring quest or reward farming.

The prototype tests whether a local goal and a visible result make the existing loop easier to understand and worth continuing. It does not establish enjoyment. The product brief's small amenity benefit is supplied by the existing park priority from placement onward; completion adds only appearance and acknowledgement. This deliberately tests a smaller hypothesis than a new mechanical reward. Do not imply that flowers improve growth or taxes.

M2d evidence records tight Help space at 720p but no demonstrated blocking usability defect. Accommodating the new control without crowding is part of M3a; general onboarding and UI redesign remain separate.

## Adopted rules

- One project type, one completion per town. Available from a new town or migrated save; optional throughout. No automatic acceptance or completion on load, growth, placement or opening a dialog.
- The player chooses an existing pocket park. A qualifying home is a distinct HOME plot at level 1 or 2 with both current outside-road access and allocated power, at Manhattan distance at most 3 from that chosen park. Count plots, not residents or levels; a level-2 home counts once. Shops, workshops and empty/unserved homes do not count. Terrain between cells does not affect distance. Other parks do not expand the selected park's radius.
- Ready means at least three qualifying homes around the same park. Show the actual count and the required three. Two level-2 homes are insufficient; three level-1 homes suffice. This is feasible within existing starter demand without requiring a new demand rule.
- Completion is an explicit ordered model command with the park cell as its target. Revalidate the target and conditions at execution, including while paused. On first valid completion, record completed status and that park index, increment the existing command sequence once and mark the town unsaved. No cost, cash reward, tick advance, RNG use, occupancy change or service/growth/budget modification.
- Failed commands and repeat completion attempts leave the canonical state and sequence unchanged. Completion persists even if nearby homes decline or lose services. Current eligibility is not a condition for retaining historical completion.
- Draw an original small flower cluster on the completed park, retaining its existing tree/path/bench silhouette. Decoration conveys no additional service or benefit; a written completed label accompanies it.
- Clearing that park is still free and removes the decoration and its anchor, but retains the town's completed status. Replacing a park there does not restore the decoration or allow another completion. Clearing other cells has no effect on the completion record. A new town resets it. There is no relocation, cancellation, second project or unlock chain in M3a.

D17-D27 remain unchanged: prices, upkeep, park priority, demand, allocation, clock order and decline all retain their current meanings. No new occupancy ID, amenity, nuisance, economic parameter or simulation tick stage.

## Minimal presentation

Add a labelled **Project** button and unused **J** shortcut opening one modal, scrollable project dialog. It suspends time using the existing dialog contract. Escape/Close returns to play without changes. Do not put another persistent panel over the map or expand the already tight Help beyond its available area; make Help scroll if necessary for the new binding.

Before completion, the dialog lists existing parks in row-major order with coordinates; choose one to see its qualifying-home count, requirements, existing $100 placement/$10 monthly upkeep, and the explicit cosmetic-only completion result. Default to the first park on each opening; selection is transient UI state. With no parks, show the requirements and tell the player to place a pocket park with 8. Completion is disabled until ready. A **Show park** action centres on the selected park and closes the dialog. Opening/selection/centering does not modify the town or consume RNG.

The completion button uses the selected cell, never a moving hover target. Model validation remains mandatory even if the button was enabled. Rebuild the list on each opening, including after load or deletion. Completed towns show acknowledgement, a Show park action only if the anchor exists, and an explicit note if the decorated park was cleared. Inspector text identifies the completed park and states that its park benefit is unchanged. Use text/shapes as well as colour; no mandatory animation, popup or audio.

## Save and implementation boundary

Implemented version: **0.6.0-m3a**, schema **5**, simulation/content **m3a-1**. Earlier local build 0.5.0-m2d uses schema 4.

Persist one strict `project` record with exactly `completed` (Boolean) and `park_index` (integer). Initial/migrated record is `{completed: false, park_index: -1}`. Incomplete requires index -1. Completed permits -1 (cleared) or an in-range index whose occupancy is PARK. Reject wrong types, extra/missing keys, out-of-range indices, or non-park anchors; validate integers with existing bounded-number rules. Do not require qualifying homes in a completed save. No saved progress counts, selected dialog row or additional derived data.

Schemas 1-4 validate under their existing meanings, then gain the empty project record; retain all existing cash/time/RNG/development/ledger values through their established migrations. Loading never completes a project and never writes. Preserve schema-4 primary or backup bytes once as `manual.schema4.json` before replacing them, alongside existing schema-1/2/3 preservation; preservation failure aborts save. Preserve all five current fixtures byte-for-byte. Add schema-5 incomplete, completed and cleared-anchor coverage, including at least one continuation fixture. Older builds reject schema 5; rollback uses the preserved original.

Keep eligibility and completion in the authoritative model, with a small `sim/project.gd` helper if useful. Integrate with `sim/city_state.gd`, `persistence/save_codec.gd`, `persistence/save_store.gd`, existing input bindings, main UI and world renderer. Do not restructure unrelated systems. Eligibility is derived on demand after existing service/growth updates; no new tick scheduling or saved allocation memory.

## Acceptance checklist for the implementation session

| Area | Required observable evidence |
| --- | --- |
| Eligibility | 0/2/3 homes; level-2 counts once; radius 3 included/4 excluded; map corners; disjoint parks cannot pool homes; empty plots, shops/workshops excluded. |
| Services | Road loss, power displacement and restoration change readiness immediately, including while paused; standing unserved development does not qualify. Park still needs no service of its own. |
| Command integrity | Valid completion once; repeated/invalid target/insufficient/stale request leaves state unchanged; success changes only project and sequence; exact cash/tick/RNG preservation. Zero cash permits completion. |
| Lifetime | Decline/service loss after completion retains completion and decoration; clearing the anchor removes only decoration/anchor; repainting the same park retains it; rebuilding there cannot repeat it; new town resets. |
| Simulation regression | Paired identical M2d-style towns with/without project completion have identical services, growth, budget, cash and RNG over growth/month boundaries; compare all non-project state except the intentional command-sequence offset. |
| Saves | Exact round trips before/after completion and after anchor removal; deterministic continuation across a month with fractional pending time; invalid records rejected without replacing live town; schemas 1-4 migrate; schema-4 primary/backup preservation and injected preservation failure. Five old fixture hashes unchanged. |
| Packed UI/layout | Button/J, choice among parks, no-park/ready/completed/cleared states, Show park, modal suspension, cancel, stale target guard, save/load refresh; four existing window sizes x three text sizes with readable controls and no toolbar overlap. |
| Actual Windows EXE | From an empty town, build the neighbourhood and complete; inspect decoration and unchanged park explanation; save/exit/restart/load; remove decorated park and reload; verify largest-text dialog and Help at 1280x720. Preserve/restore all real profile files with hashes and close the tested process. |

Run pinned `tools/verify.ps1`, native release-EXE interaction separately, then `tools/package.ps1` on the tested artifact. Record actual counts, failures, artifact hashes and automation limits. Source/packed checks are not human playtests. Investigate failures before delivery; do not expand features to compensate for a weak design assumption.

## Original assets and stop point

The goal text, checklist and flower geometry are to be created independently in this project. Extend `licenses/ASSETS.md` for the new bounded code-drawn decoration and UI/text; retain engine/font notices. No downloaded art, generated bitmap, purchased asset, reference-source reading or new licence is needed. The scoping session created no assets; implementation added the code-drawn cluster and original UI text to the asset ledger.

Stop after this single project, tests, native export evidence, documentation/handoff and authorised commit/push/default-branch integration. Record UX issues for the following session rather than implementing the full M3 bundle. No general onboarding, final art/audio, controller path, autosaves, extra amenities/projects or balance tuning. M3 is still incomplete after M3a.

Before content expansion, the product brief still requires five observed participants and its 4/5 starting-neighbourhood, blocked-zone and project-completion gates, 3/5 voluntary-continuation gate, and no save loss/economy trap/repeated input confusion. This prototype alone cannot pass those gates; recruitment/external messages and public distribution are not authorised here. Record whether players can distinguish the existing park benefit from the cosmetic reward when an observed test is later authorised.
