# M3b: a dismissible first-steps guide

Scoped 6 November 2026 under the owner's "Run next session" request. **Specified, not implemented. Deferred by U24 (6 November 2026)** until after the M2f-M2h city-builder systems; before adopting, refresh its steps, game version and save notes for them. This is proposed D29. Adopt these rules in Decisions before writing implementation code. The full M3 gate stays open after M3b.

## Dependency on M2e

During this session the owner decided that homes, shops and workshops become 3x3 lots (U16, sized by U19) and power stations 4x4 (U18). [M2e](M2E_SPEC.md) implements that first, so implement this guide only after M2e. When adopting D29, apply that geometry to the steps below:

- Read every "HOME plot" as "home lot".
- Step 2's text becomes "Zone a home lot (2) beside a road joined to the flag."
- Step 3's text becomes "Place a power station (P) touching that street. It powers 20 lots."
- Show centres on the target lot's footprint, and the bracket marker outlines the whole 3x3 footprint.
- M2e delivered game 0.7.0-m2e, schema 6, simulation/content `m2e-1`. The guide adds no save change: it becomes game `0.8.0-m3b` and keeps schema 6 and `m2e-1`, so 0.7.0-m2e and 0.8.0-m3b read each other's saves.

The other rules stay as written.

## Checkpoint review

Inputs: README, AGENTS, the M3a handoff, Decisions, product brief, delivery plan, M3a specification and evidence, M2d evidence, the retained M3a native screenshots, and this project's own `main.gd`, `city_state.gd`, `growth.gd`, `road_access.gd`, `world_view.gd`, `input_bindings.gd` and packed-test driver. The game was not run in this session. The findings below come from recorded evidence and from reading the code; none is a human usability result.

1. **Opening guidance is transient.** The only start-up instruction is one status line ("Begin at the gold flag…"). `_status()` replaces it with the first command's result, so it disappears after the first placement. After that, the rules live in Help, which has no keyboard shortcut, and in the per-tile inspector text.
2. **The flag sits at the edge of the view.** Start-up centring is clamped at the map edge. At 1280x720 the link tile spans roughly x 1216-1248, y 264-296 in the window, 8 px above the inspector. Plots south of the flag road near the link stay under the inspector until the player pans. Existing tests confirm that the link is visible and pickable. This limits where new UI may go; it is not a blocking defect.
3. **The project is found only through its button or Help.** The only routes are the Project [J] button and one Help line. At largest text its actions need scrolling (recorded in M3a).
4. **No blocking defect found.** No recorded evidence shows a defect that must be fixed before a guide. The keyboard-after-click case (Space after clicking a tool button) already has a packed regression check.

Conclusion: no separate fix comes before the guide. Proceed with one bounded guide.

## Player benefit and hypothesis

The guide gives a new player one short, current next step at a time: from the empty start, to the first homes that grow, then to the optional project. It reads the town as it is now, so after a mistake (for example, clearing the flag road) it names the requirement that is missing again. It never locks tools, pauses or unpauses time, or hides any existing control.

Hypothesis: a state-driven checklist that stays on screen helps people who did not build the game place a viable starting neighbourhood within ten minutes using only in-game guidance (product-brief gate 1). It should also help them reach the project (gate 3), and its Show action points the existing inspector at a blocked home (gate 2). Automated tests cannot establish any of this. Only the observed five-person test can.

## Proposed rules (D29)

### Steps

The card shows the first step whose condition is false, as "Step N of 5". Each condition is derived from the current town except step 5, which also uses one flag that lasts only for the session.

| Step | Done when | Proposed text | Card action |
| --- | --- | --- | --- |
| 1 | The outside-link tile holds a road | Lay a road (1) on the gold flag. It joins your town to the outside link. | Show: the link |
| 2 | At least one HOME plot has road access (a side-sharing road joined to the flag) | Zone homes (2) beside a road joined to the flag. Diagonals don't count. | Show: the link |
| 3 | At least one HOME plot has road access and allocated power | Place a power station (P) touching that street. It powers 20 plots. | Show: the first HOME plot in row-major order with road access |
| 4 | At least one HOME plot is at level 1 or 2 | Run time (Space or 1x). Every 5 days, homes with road and power can grow. | Show: the first serviced HOME plot in row-major order |
| 5 | The project dialog has been opened this session by any route, or the town's project is completed | Optional goal: open Project (J) to plan a welcoming square. | Open Project |
| Done | All five conditions hold | First steps done. Help lists every control and rule. | Close |

The implementer may tighten the wording. It must keep each step's meaning and named controls, and stay within 90 characters.

- **Rechecking.** Recheck the steps after every successful command, clock advance, load, project-dialog opening, and whenever the card is shown. If a later action undoes an earlier step (clearing the flag road, losing power), the card returns to that step. Progress is never stored.
- **What counts.** Only HOME plots count for steps 2-4; shops and workshops never advance them. A level-2 home counts like a level-1 home. Standing development without services satisfies step 4, but the card still shows step 3 first because it shows the first unmet step.
- **No outside link.** This happens only on loaded custom terrain whose whole boundary is water. The card then reads "This map has no outside link, so road access is unavailable." It offers only Close and shows no target.
- **Read-only.** Evaluating the guide never changes the canonical town, command sequence, cash, tick, pending time, RNG state or unsaved flag. No guide action is a model command.

### Visibility, dismissal and re-entry

All guide state lasts only for the session.

- The card is visible at every application start. Each start is already a fresh, paused town.
- **Hide** (labelled **Close** on the Done and no-link cards) hides the card for the rest of the session. It never reappears by itself, including after Load.
- **Re-entry.** **F1** toggles the card. Help gains a **Show first steps** dialog action beside OK, so it never needs scrolling, which closes Help and shows the card. Both routes work at any step, including Done.
- **Load.** A successful Load keeps the current visibility and the project-opened flag, then rechecks the steps against the loaded town. A failed load changes nothing.
- **Restart.** Restarting the application resets the session: the card is visible and the project-opened flag is false.
- The card never suspends time, never changes speed and never opens itself in response to game events.

### Show

- **Show** centres the camera on the step's target cell at zoom 1, using the same offset as the existing Show park action. It also points the inspector at that cell, so the existing access, power and growth explanation appears. When the pointer next moves over the map, the inspector follows it again (existing behaviour).
- Show changes no model state and does not set the unsaved flag.
- While the card is visible and its step has a target, the world draws a static corner-bracket marker on that cell. The marker is four small L-shaped corners drawn with code, distinct in shape from the hover and stroke previews. When the card is hidden, no marker is drawn.

## Presentation and layout

- **Panel type.** Add one non-modal `PanelContainer` to `ui_panels`, so the existing world-input exclusion applies. Clicks over the card never paint, and a stroke released over it cancels without charge (existing behaviour).
- **Placement.** Place it at the top left of the map area: x = sidebar right edge + 12, y = sidebar top, width 480 px, height set by its content.
- **Contents.** A muted heading "FIRST STEPS · N OF 5", following the "LAY OUT YOUR TOWN" pattern. Then the wrapped step text at the current interface text size. Then one button row: Show or Open Project where applicable, plus Hide/Close.
- **Re-layout.** Lay it out again in `_layout_ui` on window-size and text-size changes.
- **Layout invariants.** These must hold at all 12 supported layouts (four window sizes x three text sizes):
  - The card is fully inside the window.
  - It does not intersect the top bar, sidebar, inspector or status bar.
  - After Home, it does not cover the link tile.
  - In the default-map opening, each Show target lies inside the world view and is not covered by any panel.
  - All text and buttons fit inside the card without clipping.
- **Known limit.** Like Show park, Show centring is clamped at the map edges. A target near a map's bottom or right edge can land under the inspector or status bar. Record this if it is observed; do not redesign the camera in M3b.
- Use text and shape, not colour alone. No animation, popup, sound or flashing.
- **Leave unchanged:** the start-up status line, the Help rules text (apart from one F1 line and the new dialog action), the toolbar, the sidebar and the inspector layout.

## Input

- F1 is a new `toggle_guide` action, with physical and logical key events like the existing bindings. It is ignored while a modal dialog is open, like the other shortcuts. No existing binding changes.
- After any card button is clicked, Space still toggles pause and the existing keys still select tools. This is the same regression covered for tool buttons.
- The card uses ordinary buttons, and dialog focus rules are unchanged. The controller route remains future M3 work.

## Saves and versions

- **No save-format change.** Schema 5 and simulation/content `m3a-1` stay as they are. The game version becomes `0.7.0-m3b`. Because the format is unchanged, 0.6.0-m3a and 0.7.0-m3b read each other's saves.
- **Nothing written.** Guide visibility and the project-opened flag are never written: not to the town save, and not to any new settings file. M3b creates no new user files.
- **Saves unaffected.** Saving the same town gives identical bytes whether the card is visible, hidden, or at any step, and whether or not the player used the guide. Load never writes (unchanged).
- **Fixtures.** All six fixtures stay byte-identical; no new fixture is needed.
- **Revisit condition.** Remembering dismissal across launches belongs with later M3 settings/autosave work. Revisit if observed players find the start-up card intrusive.

## Implementation boundary

- **New `game/scripts/presentation/opening_guide.gd`:** a static, read-only evaluation such as `evaluate(city, project_seen) -> {state, step, total, text, target, action}`.
- **`main.gd`:** builds, lays out and refreshes the card. Adds the Show/Hide/Close/Open Project actions, the two session flags, the Help dialog action and F1 handling. `_open_project` sets the project-opened flag.
- **`input_bindings.gd`:** the `toggle_guide` action (F1).
- **`world_view.gd`:** a `guide_target` cell and the bracket marker.
- **`project.godot`:** version `0.7.0-m3b`.
- **Tests:** new source guide tests, packed-test additions and `run_tests.gd` registration.
- **Untouched code:** no file under `game/scripts/sim/`, `game/scripts/persistence/` or `game/content/` changes. If the guide appears to need such a change, stop and record why; do not widen scope.

## Acceptance checklist for the implementation session

| Area | Required observable evidence |
| --- | --- |
| Step logic (source) | **Progression:** a fresh default town is step 1 targeting the link. A flag road gives step 2; a home beside it gives step 3, targeting that home. A serviced home gives step 4 with that target, and one growth round gives step 5. **Non-advancing cases:** a disconnected road district or a diagonal home stays at step 2. Shops or workshops alone never advance steps 2-4. A station on a separate network stays at step 3. **Endings and regression:** the project-opened flag or the completed M3a fixture gives Done. Clearing the flag road in a step-5 town returns to step 1. All-water boundary terrain gives the no-link state. All six fixtures evaluate deterministically. |
| Purity | For each scenario, evaluation leaves `canonical()`, `rng.state` and `sequence` unchanged, and repeated evaluation gives identical results. |
| Packed UI | **Start and progression:** at start-up the card is visible at step 1, time is paused and the town is clean. Real pointer and key input advances steps 1-5 (flag road, home, station, Space, growth); J or Open Project gives Done. **Show and visibility:** Show recentres the camera, sets the inspector and draws the bracket, with no canonical or unsaved change. Hide removes the card and bracket. F1 re-shows the current step, and so does Help's Show first steps. **Input safety:** clicks over the card never paint, and a stroke released over it cancels with no charge. Space and the tool keys still work after card clicks. F1 is ignored while any modal is open. **Saves and restart:** Load of a saved town or fixture rechecks the steps and keeps visibility; a failed load changes nothing. Saved bytes are identical with the card visible or hidden. A scene restart resets the card to visible. |
| Layout | All layout invariants above at 4 sizes x 3 text sizes, and a text-size change while the card is visible. |
| Regression | All prior checks still pass (418 source / 360 packed at M3a; counts will rise). The six fixture hashes are unchanged. There is no diff under `sim/`, `persistence/` or `content/`. |
| Actual Windows EXE | **Walkthrough:** launch fresh at 1280x720, at standard and at largest text. Follow the card from the empty town to Done using only the card text and Show. **Visibility routes:** Hide, F1 and Help re-entry. **Restart and load:** save, exit and restart (the card returns on the fresh town), then Load (the steps are rechecked). Screenshot each step. **Profile hygiene:** record the save path the tested process actually resolved, restore it exactly afterwards (including removing a folder that did not exist before), and close the process. |

Run the pinned `tools/verify.ps1`, then the native release-EXE checks, then `tools/package.ps1` on the tested artifact. Record actual counts, failures, artifact hashes and automation limits. Automated desktop input is not a human playtest.

## Original text, art and stop point

The step text above was written for this project in this scoping session. The bracket marker is to be drawn with code from lines in `world_view.gd`. No external art, fonts, audio, generated images, reference source or new licence is needed. When implemented, extend `licenses/ASSETS.md` with the card text and the marker.

Stop after the card, the F1 and Help re-entry routes, the marker, tests, native evidence, documentation/handoff and authorised delivery. **Not in M3b:** a forced tutorial, locked tools, scripted camera tours, characters or dialogue, a tooltip overhaul, Help or UI redesign, persisted settings, autosaves, the controller route, audio, final art, more projects, balance changes and analytics. M3 is still incomplete after M3b.

Before content expands, the product brief still requires the five-person observed test and its gates. When that test is authorised, also record:
- time to the first serviced home;
- whether players use Show;
- whether anyone hides the card, and when;
- whether the start-up card is reported as intrusive.

Recruitment, external messages and public distribution are not authorised by this specification.
