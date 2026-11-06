# Toolchain and local commands

Verified through **6 November 2026**. This document describes executed local tooling; the broader platform comparison remains in [Platform decision](PLATFORM_DECISION.md).

## Exact pin and provenance

- Godot **4.7.2 Standard**, Windows x64, output `4.7.2.stable.official.ed1daf0bf`.
- Matching **4.7.2.stable** Windows export templates; GDScript and Compatibility rendering.
- Machine used: Windows 11 Home x64 10.0.26300, Intel i7-11800H, 15.7 GiB visible RAM, Intel UHD + NVIDIA RTX 3050 Ti Laptop GPU. This lists installed hardware, not a measured minimum specification or proof of which GPU served every run.
- M0/M1 and M2a commands were exercised with PowerShell **7.6.5**. M2b commands were exercised with **Windows PowerShell 5.1.26100.9818** (PowerShell 7 was not installed in that session). The helpers now capture native stderr as text under a local `Continue`, write UTF-8 logs, and write a BOM-free `BUILD.json`. M2c reran Test/Export/Verify/Package under PowerShell **7.6.5**; the 5.1-safe helpers passed. No other shell/runtime combination is claimed tested.
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
- **Package:** validates the existing export against its manifest and an explicit file allowlist, then creates `builds/citybuilder-<game version>-windows-x64.zip` (currently `0.7.0-m2e`) and a SHA256 sidecar. It does not rebuild or upload the game. Exercise the export before packaging.

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

The M2d game version is `0.5.0-m2d`; save schema 4, simulation/content `m2d-1`. Older schemas retain their original values; schemas 1/2 gain zero development, schema 3 retains development/loss, and all gain empty budget history without retroactive settlement. Before an older primary/backup is replaced, preserve exact bytes as `manual.schema1/2/3.json`. All five fixtures are hash-checked.

M2d verification passes **361 source / 324 exported-PCK checks**, plus release-EXE startup. Native SendInput-based Windows checks exercised park placement, growth, monthly ledger, largest-text budget scrolling, save/restart/load, and zero-cash overbuild/free-clear/recovery at 1280x720. See [M2d evidence](sessions/2026-11-05-m2d.md), including the interruption during native recovery. Two original save files were restored with matching hashes/count. Headless pack checks remain separate from release-binary gameplay. No additional shell, OS, DPI, hardware, controller, or performance target is certified by these results.

CI is not configured or executed. Keep local verification reproducible; adopt a minimal pinned CI workflow when the initial source baseline and remote workflow are established. Store publication, signing, additional OS support, controller claims, and external distribution remain later tasks.

## M3a checkpoint, 5 November 2026

Game 0.6.0-m3a, schema 5 / m3a-1. Final verification passed 418 source / 360 packed checks and actual EXE headless startup. Native Windows tests exercised project construction/completion, largest-text actions, save/restart/byte-identical resave, demolition/reload and final scrollable Help. Both original profile files were restored with matching hashes and count. [M3a evidence](sessions/2026-11-05-m3a.md) separates the initial native completion run from the final Help-only rebuild and subsequent native checks. The final distribution README and its manifest entry were refreshed without changing EXE/PCK bytes before packaging. Earlier M2d records above remain historical evidence.

## M2e checkpoint, 6 November 2026

Game 0.7.0-m2e, schema 6 / m2e-1: 3x3 zone lots and 4x4 power stations. Final verification under Windows PowerShell 5.1 passed 479 source / 415 packed checks and actual EXE headless startup. PowerShell 7 was not on this session's PATH and was not used. Computer-use tools were unavailable, so the actual EXE was driven through posted window messages to its own window (`builds/validation/m2e/native/`, ignored), with `PrintWindow` captures and no cursor movement. A smoke rerun used the final export. The tested process resolved `%APPDATA%/OriginalCityBuilder`; its absent `saves` folder was restored afterwards. Seven fixtures are hash-checked. See [M2e evidence](sessions/2026-11-06-m2e.md).
