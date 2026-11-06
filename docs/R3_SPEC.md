# R3: autosaves, remembered settings and monthly history

Specified 6 November 2026 under the owner's request to do the next session now (U40), from the [roadmap](ROADMAP.md) and the [handoff](../NEXT_SESSION.md). Adopted as [D39](DECISIONS.md#d39) before code, then implemented and locally verified as 0.16.0-r3 ([evidence](sessions/2026-11-06-r3.md)). **Revised during implementation, before delivery:** the native run showed that Load went straight to the manual save when nothing was unsaved, hiding Load autosave, so with any autosave on disk the Load dialog now always opens. An autosave happens after the frame that passes the 60-day mark, so its date can be a few days later at 3x. All values are this project's own provisional choices; none comes from the reference game.

## Goal

Protect the player's work during longer sessions, remember how they like the game set up, and let them see how the town has grown.

## Rules

### Autosaves

- **Slots.** Three autosave files beside the manual save: `autosave1.json`, `autosave2.json`, `autosave3.json` in the saves folder, plus a one-line `autosave.index` naming the slot written last.
- **When.** While time runs, each time the date passes a multiple of **60 days** (every second month boundary), counted from the period the town was started or loaded in. Never while paused, in a dialog or unfocused (time is stopped then). Building while paused does not autosave.
- **Rotation.** The slot after the one in the index (1 → 2 → 3 → 1). With no valid index, the first missing slot, else slot 1.
- **Safety.** An autosave uses the same validate → temporary write → read-back → replace steps as the manual save (D15), but it **never touches `manual.json`, its `.bak` or the preserved `manual.schemaN.json` copies**, and it has no backup of its own: the other two slots are its backup. An autosave does not clear the unsaved-changes flag, so quitting still offers to save.
- **Feedback.** Success shows "Autosaved 1 Mar 1950 (slot 2 of 3)." in the status bar. A failure shows the error and "Your manual save is unchanged."
- **Loading.** The Load dialog gains **Load autosave**: it loads the newest valid autosave, starting at the index slot and going backwards; a corrupt or missing slot falls back to the next older one. With none valid it reports "No valid autosave yet. Current city unchanged." A loaded autosave is treated as unsaved work.

### Settings file

- **File.** `settings.json` in the user folder, separate from saves, with `"settings_version": 1` and exactly these keys:

| Key | Values | Default |
| --- | --- | --- |
| `window` | one of the four Display window sizes, as `[w, h]` | none (`[]`: leave the window as started) |
| `text_size` | 16, 18 or 20 | 16 |
| `art` | `original`, `tiny_city`, `modern_city` | `modern_city` |
| `grid`, `road_marks`, `power_marks` | true / false | true |
| `land_value`, `services` | true / false | false |
| `guide_hidden` | true / false | false |

- **Written** whenever the player changes one of them (Display buttons, G, R, E, V, C, Hide/Close on the First steps card, F1 or Help's Show first steps). The same validated temporary write is used.
- **Read** once at start-up and applied after the interface is built. A launch `--art=` argument still overrides the art for that run.
- **Fallback.** A missing, unreadable, oversized (over 4 KiB), malformed, wrong-version or out-of-range file gives all defaults; the bad file is left untouched until the next change replaces it. Settings never affect saves, the model or determinism.
- **D29 change.** Hiding the First steps card is now remembered across sessions; F1 or Help's Show first steps brings it back and clears the remembered choice. Its steps, wording and read-only evaluation are unchanged.

### Monthly history

- At every D25 settlement the town appends one record: `[tick, residents, commercial jobs, industrial jobs, closing cash, net]`, where residents and jobs are the town totals after that round's growth, and cash and net are the settlement's closing cash and net (cents).
- At most **240** records (20 years); the oldest is dropped beyond that.
- History is saved: **schema 12** adds a `history` array. Validation is strict: at most 240 records of six integers; ticks positive multiples of 30, strictly increasing and not after the save's tick; residents, jobs and cash within their existing bounds; net within ±MAX_CASH.
- Schema 11 and earlier load with an empty history; earlier schemas reject the field. History never consumes randomness and never changes any rule.
- A full 240-month history on the largest 128x128 map must stay under the 512 KiB cap (tested).

### Graphs

- **H** and a **Graphs [H]** button in Budget open a **Town history** dialog with three original line graphs: Residents; Jobs (commercial solid, industrial dashed); Funds (closing cash), each with its highest value and the first and last month (R1 calendar) as text. Readable without colour; fits 720p at every text size; suspends time like other dialogs.
- Before the first settlement it says "No months recorded yet. The graphs fill in at each monthly settlement."

### Interface and documents

Help, BUILD_README and README describe autosaves, Load autosave, remembered settings and H.

### Versions

Game **0.16.0-r3**, schema **12**, simulation/content **`r3-1`**. Settings version 1.

## Changes to earlier rules

- **D15/D20**: a second, independent save path (autosaves) with the same validated write; the manual slot, backup and preservation rules are unchanged and untouched by it.
- **D27/D38 saves**: schema 12 adds `history`. Twelve fixtures stay byte-identical; schema 11 migrates with an empty history.
- **D29**: First steps dismissal is remembered in settings.
- **D31**: the art choice is remembered in settings (still never saved in the town).
- **D25**: unchanged arithmetic; each settlement also appends a history record.
- D17-D24, D26, D28, D30, D32-D38 are otherwise unchanged.

## Acceptance checklist

- [x] Unit tests: autosave rotation and index fallback, the manual slot and backup untouched, corrupt slot fallback, settings defaults and every fallback case, history records at settlements and its bound, strict history validation, migration of all twelve fixtures and a new schema-12 fixture, largest-map size, determinism.
- [x] Packed tests through the shipped UI: autosave during play, Load autosave, settings remembered across a scene restart, graphs at every layout and text size.
- [x] `tools/verify.ps1` passes; twelve fixtures byte-identical.
- [x] Native posted-input run of the actual EXE: an autosave, settings remembered after a restart, the Graphs dialog; profile restored.
