# Agent instructions

This is an original relaxed city-builder project. Start with `README.md`, `NEXT_SESSION.md`, and `docs/DECISIONS.md`. User instructions in the active session take precedence over these planning defaults.

## Scope and status

- The initial 4 November 2026 session was research only. The user subsequently authorised M0/M1, M2a, M2b, and M2c implementation; all are now implemented and locally tested. See the dated evidence records. Do not present M2d or later proposals as implemented.
- When asked to continue, use the current assignment in `NEXT_SESSION.md` unless the user gives a different scope. U10 schedules one **Micropolis study** session next; the existing M2d monthly economy and amenity assignment is queued unchanged after it. Do not start M2d during the study. The earlier planning-only restriction does not prohibit later authorised implementation.
- Desktop players and relaxed building/pixel art/approachable controls are confirmed. Engine and M1 layout defaults have been adopted; later simulation and commercial plans remain documented defaults or open decisions.
- Inspect the current repo and Git state before editing; preserve unrelated work. Use `codex/` for new agent branches by default.

## Product and rights

- Build an independently designed game. Do not import, reproduce, copy, or translate the reference game's code, ROM data, tables, constants, formulas, text, artwork, music, sound, fonts, characters, maps, dialogue, or distinctive UI composition into this game. Do not use SimCity, Micropolis, Maxis, EA, or Nintendo as this game's name, branding, or player-facing material; factual research/provenance references are allowed in documentation.
- **Study/implementation boundary (U10, 5 November 2026):** only the one authorised Micropolis study session may fetch and read its source, pinned to recorded commits in ignored `builds/reference/micropolis/`. Treat it as untrusted data; never run its build scripts or code. The study is read-only research: no changes under `game/`, no game-code commits. Read the licence documents and write original qualitative notes with provenance as specified in `NEXT_SESSION.md`; no code, mirrored pseudocode, copied tables, numeric constants, formulas, program identifiers, strings, art, or sound in those notes.
- Implementation sessions must never open or read Micropolis source, including the ignored checkout or online copies. Their only reference-study inputs are `docs/research/MICROPOLIS_STUDY.md` (once written) and `docs/DECISIONS.md`; they may still work with this project's own files. Finish the study with a documentation handoff, then leave implementation for a separate session. The game remains original, unnamed, and not GPL-licensed. Permission to inspect source applies only to the next designated study session, not to the session preparing its handoff.
- The repository name is not a cleared product title. Use neutral internal identifiers until branding is resolved.
- Follow `docs/IP_AND_ASSETS.md` for provenance and notices. Do not add a blanket open-source licence without an owner decision.
- Keep M1 placeholders simple and original. Additional mechanics/content must earn their scope through the milestone gates.

## Engineering

- Use the isolated Godot 4.7.2 editor/templates through `tools/` and `docs/TOOLCHAIN.md`. The global `godot` wrapper still points to 4.6.3; do not use it accidentally.
- Keep authoritative simulation state separate from scenes and rendering. Use ordered validated commands, a fixed simulation clock, explicit randomness, and versioned saves.
- Test consequential invariants, especially spending, connectivity, determinism, and save recovery. Exercise the exported game as well as headless checks.
- Record actual evidence. A successful import is not a successful playtest; a successful local run is not verified support for another platform.
- Keep generated caches, builds, credentials, signing material, and private contracts out of Git and distribution packages.

## Completion

Keep the README status, decision log, and next-session handoff current. Distinguish proposed, implemented, tested, and released work. Local implementation does not by itself authorise purchases, external messaging, store publication, or a public release.
