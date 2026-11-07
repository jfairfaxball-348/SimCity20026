# R5: controller route and remappable controls

Specified 7 November 2026 under the owner's "Run next session" request (U42), from the [roadmap](ROADMAP.md) and the [handoff](../NEXT_SESSION.md). Adopted as [D41](DECISIONS.md#d41) before code, then implemented and locally verified as 0.18.0-r5 ([evidence](sessions/2026-11-07-r5.md)). **Revised during implementation, before delivery:** Godot's interface actions (`ui_accept`, `ui_cancel`, `ui_up` and so on) did not include the gamepad in this project, so the bindings add South, East, the d-pad and left stick to them; a waiting Controls row reads input on the dialog itself (an embedded window takes its own input) and Escape there cancels rather than closes; each Controls row's **Key** and **Pad** buttons start a change (there is no separate Change button); Center view, Sound & motion and Controls share one Display row so Display fits 720p. Every mapping, prompt and number is this project's own.

## Goal

Everything in the game can be done with a standard gamepad, and both keyboard keys and gamepad buttons can be changed. Mouse and keyboard keep working exactly as before.

## Rules

### Gamepad layout (defaults)

Buttons are named by position, as Godot reports them: **South**, **East**, **West**, **North** face buttons; **LB / RB** shoulders; **LT / RT** triggers; **Start**, **Back**; **L3** (left stick click).

| Input | Action |
| --- | --- |
| Left stick or d-pad | move the map cursor one tile at a time (held: about 12 tiles a second after a short delay) |
| South (hold) | press to start a stroke at the cursor, move to extend it, release to build |
| East | cancel the stroke; in a dialog, close it (Godot's own "cancel") |
| LB / RB | previous / next tool, in sidebar order |
| LT / RT | zoom out / in |
| Right stick | pan the map |
| Start | pause / resume |
| West | change speed: paused → 1x → 3x → paused |
| North | Town summary |
| Back | the **Menu** |
| L3 | return the view to the outside link |

- **Cursor.** Using the gamepad shows a map cursor (a bright square outline with corner ticks) and the usual placement preview at it; the inspector follows it. Moving the mouse hands control back to the mouse. The cursor keeps itself in view by panning.
- **Dialogs.** In every dialog the d-pad / left stick moves focus between buttons and South presses the focused one (Godot's own UI navigation). Each dialog puts focus on its first button when it opens, so focus is never lost behind the map. Dialogs still suspend time.
- **Menu (Back).** A dialog with buttons for Resume, Budget, Town summary, Graphs, Project, Help, Display, Sound & motion, Controls, Save, Load, First steps (show / hide) and Show next step. Everything otherwise reached by mouse or keyboard is reachable from here.

### On-screen prompts

When the gamepad was used last, a small prompt strip appears just below the top bar: "South build · East cancel · LB/RB tool · LT/RT zoom · North summary · Back menu". The names are plain words drawn as text by our own code; no console maker's button artwork, logos or trade marks. It hides again when the mouse or keyboard is used.

### Remapping (Controls dialog)

- **Controls…** in Display and in the Menu opens a scrolling list of remappable actions: the nine tools, pause, normal and fast speed, Budget, Project, Town summary, Graphs, grid, road marks, power marks, land value, services, mute and centre view (keyboard), plus pause, speed, summary, previous / next tool, menu and centre view (gamepad).
- Each row shows the current key and gamepad button as buttons; pressing one waits for the next key (or gamepad button) and assigns it; **Escape** or the East button while waiting cancels. Buttons that name a key (tools, Budget, Project, Town summary, Road / Power marks, Link) relabel themselves; Help and the First steps card keep naming the default keys.
- **Refused** assignments (with a status line saying why): a key or button already used by another remappable action; the reserved keys Escape, F1, F6, the modifier keys (Ctrl, Alt, Shift, Meta), the movement keys (WASD and arrows) and the zoom keys; and the gamepad South, East and d-pad buttons, which stay fixed for navigation.
- **Reset all** restores every default.
- Fixed and not remappable: Escape, Ctrl+S / Ctrl+L, F1, F6, the mouse, the movement keys (WASD and arrows), zoom keys, and the gamepad sticks, d-pad, South, East and triggers.

### Settings (D39/D40 extended)

`settings.json` becomes **version 3**: the version-2 keys plus `bindings`, an object `{"keys": {action: key code}, "pad": {action: button index}}` holding only the changed bindings. Validation: known remappable actions only, key codes that Godot can name and that are not reserved, button indices 0-20 that are not fixed, and no two actions sharing a key or a button (including defaults they would collide with). Version 1 and 2 files migrate with no bindings; anything invalid gives all defaults.

### Versions

Game **0.18.0-r5**. No save change: schema 12 and `r3-1` stay; thirteen fixtures byte-identical.

## Changes to earlier rules

- **D03**: the controller route is implemented (D03 planned it).
- **D21** and later key choices: still the defaults, now remappable.
- **D39/D40**: settings version 3 with `bindings`; every fallback rule unchanged.
- No simulation or save rule changes.

## Limits

An agent cannot connect a real controller. Evidence is from simulated Godot joypad events in packed tests; the owner should try a real gamepad (for example during the R6 solo playtest).

## Acceptance checklist

- [x] Unit tests: default bindings, remap validation (reserved, fixed, duplicates), settings version 3 and migration from 1 and 2.
- [x] Packed tests with simulated joypad events: cursor movement and repeat, a stroke built with South, cancel, tools, zoom, pan, pause and speed, summary, the Menu reaching every item, dialog focus and closing, prompts shown and hidden, remapping a key and a button and reset, settings restored after a restart, at every layout and text size where dialogs appear.
- [x] `tools/verify.ps1` passes.
- [x] Native run of the actual EXE with posted keyboard input showing the Menu-free paths unchanged and the Controls dialog; a real controller recorded as untested.
