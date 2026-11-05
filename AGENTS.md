# Agent instructions

This is an original relaxed city-builder project. Start with `README.md`, `NEXT_SESSION.md`, and `docs/DECISIONS.md`. User instructions in the active session take precedence over these planning defaults.

## Scope and status

- The initial 4 November 2026 session was research only. The user subsequently authorised M0/M1, M2a, M2b, and M2c implementation; all are now implemented and locally tested. See the dated evidence records. Do not present M2d or later proposals as implemented.
- When asked to continue, use the current assignment in `NEXT_SESSION.md` unless the user gives a different scope. The next small checkpoint is M2d monthly economy and amenity. The earlier planning-only restriction does not prohibit later implementation.
- Desktop players and relaxed building/pixel art/approachable controls are confirmed. Engine and M1 layout defaults have been adopted; later simulation and commercial plans remain documented defaults or open decisions.
- Inspect the current repo and Git state before editing; preserve unrelated work. Use `codex/` for new agent branches by default.

## Product and rights

- Build an independently designed game. Do not import or reproduce the reference game's code, ROM data, artwork, music, fonts, characters, maps, dialogue, or distinctive UI composition.
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
