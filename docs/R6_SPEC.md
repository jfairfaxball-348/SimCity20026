# R6: the owner's solo playtest kit

Specified 7 November 2026 under the owner's "Run next session" request (U43), from the [roadmap](ROADMAP.md) and the [handoff](../NEXT_SESSION.md). Adopted as [D42](DECISIONS.md#d42) before code, then implemented and locally verified as 0.19.0-r6 ([evidence](sessions/2026-11-07-r6.md)); the playtest itself is pending. Under U39 the playtest is the owner playing alone; this session prepares it and the owner plays. **No automated run counts as the playtest.**

## Goal

Hand the owner a build and a short kit that make a useful solo playtest easy: what to try, what to notice, where to write it down and where their saves are. Bring the in-game guidance up to date first, so the playtest tests the game as it stands.

## Rules

### First steps and Help refresh (D29 extended)

- The five First steps stay as they are in meaning, but every key they name is the player's **current** key (after any remap in Controls), for example "Zone a residential lot (Q) …".
- The finished card now points onward: "Done. Next: parks, then police (9) and fire (0) for level 4. Help has every rule." (with current keys). Every card text stays within 90 characters with the default keys.
- Help opens with a **Your keys** block listing the current keyboard keys and gamepad buttons, generated from the bindings, followed by the existing rules (which still say "default keys").
- The card stays session-light, never pauses time and never locks tools.

### Finding saves

- Help and the Menu gain **Open save folder**: it creates the saves folder if needed and asks the operating system to open it in the file manager, and the status bar names the path. It only opens a local folder; nothing is sent anywhere. In headless test runs it reports the path without opening anything.

### The kit

- `docs/playtest/PLAYTEST.txt` (also shipped beside the game as `PLAYTEST.txt`): how to start, four sessions with goals of rising depth, what to notice, a fill-in notes sheet based on the product brief's playtest questions (adapted for one player), where saves, autosaves, settings and notes are, how to hand them back (by telling Claude in a chat and pasting or attaching them; nothing is sent automatically), and the known limits (no real controller tried; audio not yet judged by anyone).
- `docs/playtest/README.md` explains the kit and how results will be recorded (in a later session, in Decisions and an evidence record, honestly, without treating one player's view as wider evidence).

### Packaging

The export copies `PLAYTEST.txt` into the build, the manifest lists it and the package script expects it. The zip stays local; no upload, message or release.

### Versions

Game **0.19.0-r6**. No save change (schema 12 / `r3-1`), settings version 3 unchanged.

## Changes to earlier rules

- **D29**: card texts use current keys; new done text.
- **D41**: Help shows current bindings.
- Packaging gains one document. No simulation, save or settings change.

## Acceptance checklist

- [x] Unit tests: card texts with default and remapped keys, length limit, the done text.
- [x] Packed tests: the card and Help after a remap, Your keys, Open save folder in Help and the Menu at every layout and text size.
- [x] `tools/verify.ps1` passes; the package contains `PLAYTEST.txt`.
- [x] Native run of the actual EXE showing the refreshed card and Help.
- [ ] The playtest itself: **pending, owner's turn.**
