# Toolchain and local commands

Verified on **4 November 2026**. This document describes executed local tooling; the broader platform comparison remains in [Platform decision](PLATFORM_DECISION.md).

## Exact pin and provenance

- Godot **4.7.2 Standard**, Windows x64, output `4.7.2.stable.official.ed1daf0bf`.
- Matching **4.7.2.stable** Windows export templates; GDScript and Compatibility rendering.
- Machine used: Windows 11 Home x64 10.0.26300, Intel i7-11800H, 15.7 GiB visible RAM, Intel UHD + NVIDIA RTX 3050 Ti Laptop GPU. This lists installed hardware, not a measured minimum specification or proof of which GPU served every run.
- M0/M1 and M2a commands were exercised with PowerShell **7.6.5**. M2b commands were exercised with **Windows PowerShell 5.1.26100.9818** (PowerShell 7 was not installed in that session). The helpers now capture native stderr as text under a local `Continue`, write UTF-8 logs, and write a BOM-free `BUILD.json`. They have not been re-run under PowerShell 7 since. No other shell/runtime combination is claimed tested.
- No third-party GDScript framework, .NET SDK, backend, Steam SDK, or package manager is required.

[Official build release](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable), [official SHA512 manifest](https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/SHA512-SUMS.txt). Both downloaded archives matched their pinned hashes before extraction/execution. The machine-readable pin is [tools/toolchain.json](../tools/toolchain.json).

| Archive | SHA512 |
| --- | --- |
| `Godot_v4.7.2-stable_win64.exe.zip` | `83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993` |
| `Godot_v4.7.2-stable_export_templates.tpz` | `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079` |

Setup downloads the official full template archive (about 1.28 GB), then extracts only the Windows x64 debug/release templates and console companions. Allow space for the archives, extracted tools, and exports. A checksum mismatch stops setup; inspect/remove only the identified incomplete archive before retrying.

The isolated console executable is:
`C:\SimCity20026\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`.

Templates are in `.tools/godot/4.7.2/templates/` and explicitly selected by `game/export_presets.cfg`. The global `C:\dev\tools\godot\godot.cmd` still points to 4.6.3 and was not replaced. All project commands resolve the local pin and verify the editor's version.

## Commands

Run from the repo root:

```powershell
.\tools\setup.ps1
.\tools\project.ps1 Import
.\tools\project.ps1 Test
.\tools\project.ps1 Run
.\tools\project.ps1 Export
.\tools\verify.ps1
.\tools\package.ps1
```

- **Setup:** downloads/verifies/extracts the pinned tools locally. No global install or PATH change.
- **Import:** headless project import; useful but not a gameplay test.
- **Test:** import plus the source model/storage/scene runner; logs to `builds/validation/`. Fails on engine errors or nonzero exit.
- **Run:** launches the game through the pinned editor runtime.
- **Export:** imports and makes an unsigned x64 Windows release EXE/PCK, adds notices/README, writes `BUILD.json` with SHA256 file hashes and the game version/save schema read from `project.godot` and `city_state.gd`.
- **Verify:** Test + Export, input/layout/save checks against the exported PCK, then headless startup of the actual release EXE. It does not replace native UI checks.
- **Package:** validates the existing export against its manifest and an explicit file allowlist, then creates `builds/citybuilder-<game version>-windows-x64.zip` (currently `0.3.0-m2b`) and a SHA256 sidecar. It does not rebuild or upload the game. Exercise the export before packaging.

Setup and project scripts stop on failures. Do not bypass checksum/version errors by using another editor silently. Local archives/tools, `.godot` caches, builds/logs, and export credentials are ignored. Keep Godot `.uid` source sidecars in Git.

## Test layers and release-template limitation

1. `game/tests/run_tests.gd` tests data/command/clock/save invariants and scene binding with the pinned editor runtime, headlessly.
2. `game/tests/packed_integration.gd` is an **external** test script run by that runtime using `--main-pack builds/windows/citybuilder.pck`. It checks shipped resources, exclusion of tests, actual controls/input mapping, four layout sizes × three text sizes, and save/reload through the main scene.
3. `citybuilder.console.exe --headless --quit-after 6` checks startup of the actual release binary.
4. Native interaction with `citybuilder.exe` checks graphics and desktop input separately.

Standard release templates disable path/script overrides. An early attempt to use `--script` directly on the release EXE launched the game instead of the test driver. Do not mistake that for a test pass. The [Godot 4.7 command-line documentation](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html) documents extended options being restricted to the editor or templates built with path overrides enabled.

To demonstrate the source runner's failure exit deliberately:

```powershell
& .\.tools\godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe --headless --path game --script res://tests/run_tests.gd -- --prove-failure-exit
$LASTEXITCODE # Expected 1; this deliberate failure is not a product regression.
```

Source tests use isolated directories under `builds/validation/headless` when invoked through the helper. Packed checks use unique `user://tests/export_*/` paths; they do not overwrite the manual city save. Their log message still displays the scene's nominal save path, so use the adapter code to interpret this correctly.

## Distribution and compatibility

Keep EXE/PCK together. The console wrapper is optional for play but included for diagnostics. Bundle `GODOT_LICENSE.txt`, `GODOT_COPYRIGHT.txt`, `ASSETS.md`, `README.txt`, and `BUILD.json`.

Notices were copied unmodified from the pinned source tag: [MIT licence](https://github.com/godotengine/godot/blob/4.7.2-stable/LICENSE.txt), [third-party/font notices](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt). No blanket licence for the original game has been selected.

The M2b game version is `0.3.0-m2b`; its save format is schema 2, simulation/content `m2b-1`. Schema-1 (M1/M2a) saves migrate in memory by changing only version fields. Before a schema-1 primary or backup is replaced, its bytes are preserved once as `manual.schema1.json`. The M1, M2a, and M2b fixtures are hash-checked by the source runner. No general cross-version migration beyond schema 1 → 2, and no cross-platform replay promise, exists. Check fixtures before changing these contracts. Byte-identical rebuilds are not asserted.

M2b verification passes 233 source checks and 252 exported-PCK checks. These include power capacity/allocation/migration tests, flag visibility, longest access and power reasons, three rejection messages at all four sizes and three text sizes, and a shipped-input supply/shortage/disconnection/recovery/reload flow. Native M2b evidence is in [the session record](sessions/2026-11-04-m2b.md). It drove the real EXE through window messages because desktop computer-use tools were unavailable. Headless pack checks still do not count as actual release-binary gameplay tests.

CI is not configured or executed. Keep local verification reproducible; adopt a minimal pinned CI workflow when the initial source baseline and remote workflow are established. Store publication, signing, additional OS support, controller claims, and external distribution remain later tasks.
