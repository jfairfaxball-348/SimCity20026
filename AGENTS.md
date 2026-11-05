# Agent instructions

This is an original relaxed city-builder project. Start with `README.md`, `NEXT_SESSION.md`, and `docs/DECISIONS.md`. User instructions in the active session take precedence over these planning defaults.

## Scope and status

- The initial 4 November 2026 session was research only. The user subsequently authorised M0/M1, M2a, M2b, M2c, and M2d implementation; all are now implemented and locally tested. See the dated evidence records. Do not present M3 or later proposals as implemented.
- When asked to continue, use the current assignment in `NEXT_SESSION.md` unless the user gives a different scope. The one U10 **Micropolis study is complete**; M2d is also complete. M3a scoping is complete; the next handoff assigns only the single-project prototype in `docs/M3A_SPEC.md`. M3a remains unimplemented; the rest of M3 stays outside that separate session. The study adopted no new simulation rules. The earlier planning-only restriction does not prohibit later authorised implementation.
- Desktop players and relaxed building/pixel art/approachable controls are confirmed. Engine and M1 layout defaults have been adopted; later simulation and commercial plans remain documented defaults or open decisions.
- Inspect the current repo and Git state before editing; preserve unrelated work. Use `codex/` for new agent branches by default.

## Product and rights

- Build an independently designed game. Do not import, reproduce, copy, or translate the reference game's code, ROM data, tables, constants, formulas, text, artwork, music, sound, fonts, characters, maps, dialogue, or distinctive UI composition into this game. Do not use SimCity, Micropolis, Maxis, EA, or Nintendo as this game's name, branding, or player-facing material; factual research/provenance references are allowed in documentation.
- **Study/implementation boundary (U10, 5 November 2026):** the one authorised source study is complete. Its permission to fetch/read source is exhausted. The pinned checkout in ignored `builds/reference/micropolis/` is retained only as research evidence; never run its build scripts or code. The study wrote no game code. Its qualitative notes and provenance are in `docs/research/`; no reference code, mirrored pseudocode, copied tables, numeric constants, formulas, program identifiers, strings, art, or sound may enter the game or design notes.
- Implementation sessions must never open or read Micropolis source, including the ignored checkout, online copies, or reproduced source elsewhere. Their only reference-study inputs are `docs/research/MICROPOLIS_STUDY.md` and `docs/DECISIONS.md`; they may still work with this project's own files. Provenance source links are audit locators, not implementation reading assignments. Keep implementation separate from the completed study. The game remains original, unnamed, and not GPL-licensed; no further source study is authorised by this handoff.
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

**Standing owner instruction (5 November 2026):** after completing and verifying an authorised session, commit the scoped changes, push the work branch, merge into the live default branch using a fast-forward when possible, and fast-forward the local default checkout. Reconcile remote refs first and verify local/remote agreement afterward. This source-delivery authorisation persists across sessions; do not ask again. Never force-push or discard unrelated work to obtain a fast-forward. Public binary release remains separate.
