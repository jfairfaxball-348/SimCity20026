# Agent instructions

This is an original relaxed city-builder project. Start with `README.md`, `NEXT_SESSION.md`, and `docs/DECISIONS.md`. User instructions in the active session take precedence over these planning defaults.

## Scope and status

- The initial 4 November 2026 session was research only. The user subsequently authorised M0/M1, M2a, M2b, M2c, M2d, the bounded M3a project, M2e zone lots, M2f taxes, M2g desirability, the M2h town summary and the M3b first-steps guide; all are now implemented and locally tested. See the dated evidence records. Do not present the remaining M3 bundle or later proposals as implemented.
- When asked to continue, use the current assignment in `NEXT_SESSION.md` unless the user gives a different scope. The one U10 **Micropolis study is complete**, M2d is complete, and M3a is locally verified. M2e 3x3 zone lots and 4x4 power stations (owner U16/U18/U19) are implemented and locally verified. Under owner direction U24 (6 November 2026) the city-builder systems come before the guide. M2f (demand meter and adjustable tax rate), M2g (neighbourhood desirability and workshop nuisance), M2h (town summary) and the refreshed M3b guide are implemented and locally verified, completing the U24 roadmap. Under U30 the next session is a planning-only structured gap analysis against the full classic game, followed by a new roadmap, as listed in `NEXT_SESSION.md`. The M3b guide is deferred, not cancelled, and none of this implements the full M3 bundle. The study adopted no simulation rules. Earlier planning-only restrictions do not prohibit subsequent authorised implementation.
- Desktop players and relaxed building/pixel art/approachable controls are confirmed. Engine and M1 layout defaults have been adopted; later simulation and commercial plans remain documented defaults or open decisions.
- Inspect the current repo and Git state before editing; preserve unrelated work. Use `codex/` for new agent branches by default.

## Product and rights

- **Owner direction U17 (6 November 2026):** lean closer to the classic city-builder in mechanics; earlier design-scope limits no longer block genre systems (see `docs/GENRE_ALIGNMENT.md`). The owner made this conditional on not breaking copyright rules, so every rights rule below is unchanged.
- Build an independently designed game. Do not import, reproduce, copy, or translate the reference game's code, ROM data, tables, constants, formulas, text, artwork, music, sound, fonts, characters, maps, dialogue, or distinctive UI composition into this game. Do not use SimCity, Micropolis, Maxis, EA, or Nintendo as this game's name, branding, or player-facing material; factual research/provenance references are allowed in documentation.
- **Plain genre words are allowed (owner clarification U29, 6 November 2026).** Ordinary words and generic city-builder vocabulary belong to no one. Use them freely in design notes and player-facing text, for example: residential, commercial and industrial zones or blocks, power plant, police station, fire station, land value, pollution, crime, traffic, budget and tax rate. The restriction is on the reference game's distinctive expression (its manual, messages and dialogue text), its names and branding (SimCity, Micropolis, Maxis, EA, Nintendo, and its named characters and scenarios) and anything copied (code, data, numbers, formulas, tables, art, sound, look).
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
