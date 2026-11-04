# Platform and engine decision

Recommendation dated 4 November 2026: **Godot 4.7.2 Standard, typed GDScript, Compatibility renderer; Windows 11 x64 first.**

This follows the user's desktop/possible-Steam preference and relaxed 2D scope. It is a technical judgement from documentation and project needs, not a measured comparison of implemented prototypes.

Implementation update: this recommendation was adopted for M0/M1. The pinned editor/templates now import, test, and export the foundation successfully, and the Windows executable has been exercised locally. See [Toolchain](TOOLCHAIN.md) and [evidence](sessions/2026-11-04-m0-m1.md); this remains one-machine evidence, not a comparative benchmark or cross-platform support claim.

## Choose the release target separately from the engine

| Target | Benefits for this game | Costs and limits | Decision |
| --- | --- | --- | --- |
| Native Windows desktop | Reliable local saves, offline sessions, mouse/controller support, direct Steam path; available development machine | Distribution, clean-machine testing, and eventual signing/support work | First supported target |
| Linux desktop / Steam Deck | A possible additional desktop audience and handheld fit | Actual Linux/Proton and controller testing; small-screen UI; no automatic Verified status | Evaluate after the Windows slice |
| macOS | Additional desktop audience | Test hardware/access, signing and notarisation workflow, extra support matrix | Later decision, not launch promise |
| Browser | Immediate trial with no installation; useful demo link | Browser storage durability, loading time, audio/input quirks, background throttling, and export constraints | Optional demo after native loop works |
| Modern consoles | Good fit for accessible controller play | Platform approval, SDK/middleware access, certification, contracts, and porting cost | Defer |
| Actual SNES hardware | Authentic hardware constraints | A separate specialist homebrew toolchain and much tighter technical/art constraints | Outside the confirmed desktop target |

Godot's web export currently uses WebAssembly/WebGL 2 and Compatibility rendering. Its documentation says Godot 4 C# projects cannot currently export to web; a single-threaded GDScript web build is the simpler optional route. Browser persistence still needs an explicit save-export/import design and browser tests. [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

Godot console release is possible through approved developers and appropriate SDKs/third-party arrangements; it is not an ordinary public export-template option. [Godot console support](https://godotengine.org/consoles/). macOS distribution has its own signing/notarisation requirements. [Godot macOS export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html).

## Engine comparison

| Option | Suitability | Trade-off | Conclusion |
| --- | --- | --- | --- |
| Godot + GDScript | Integrated 2D scenes, tile maps, UI, input, audio, headless tools, native exports | GDScript performance must be profiled; engine conventions require learning | Best default for this scope |
| Godot + C# | Same editor, familiar .NET tooling and types for a C# team | Extra SDK/build surface; current Godot 4 web restriction; no demonstrated need here | Choose only if the team already strongly prefers C# |
| GameMaker | Credible 2D-focused alternative with desktop/mobile/web exports | Commercial licence and proprietary workflow; a switch brings no clear benefit without existing expertise | Strong runner-up for an experienced GameMaker developer |
| Unity | Capable 2D/native tooling and C# ecosystem | More tooling and licensing administration than this small project needs | Reasonable for a team already productive in Unity |
| Phaser + TypeScript | Strong browser-first 2D approach, familiar web tooling | Native desktop uses additional packaging tools; more assembly of game UI/content workflow | Reconsider if browser becomes the main product |
| Custom engine/framework stack | Maximum control | Must also build editor, UI, asset pipeline, exports, and much more infrastructure | Poor use of this project's limited scope |

These are qualitative judgements, not benchmark scores. Existing expertise can outweigh the default recommendation; none was established in this session.

Current licensing evidence:

- Godot is MIT-licensed, including commercial use. The game can have its own licence; distributed engine and third-party notices still matter. [Godot licence](https://godotengine.org/license/).
- GameMaker's current FAQ lists free non-commercial use and a US$99.99 one-time commercial licence, with a separate console route. [GameMaker FAQ](https://gamemaker.io/en/help/articles/gamemaker-faq).
- Unity offers a free Personal tier subject to its financial eligibility rules; its Runtime Fee was cancelled. Rejecting it here is a scope/workflow judgement, not a claim that a per-install fee still exists. [Unity Personal](https://unity.com/products/unity-personal), [Unity pricing and Runtime Fee update](https://unity.com/products/pricing-updates).
- The Phaser open-source framework is MIT-licensed; JavaScript/TypeScript and browsers are its main focus. Do not confuse the framework licence with separately offered commercial services. [Phaser licence](https://phaser.io/download/license), [Phaser overview](https://www.phaser.io/oss/docs/phaser/getting-started/what-is-phaser).

Recheck prices and terms when adopting or purchasing a tool.

## Version and setup policy

The [official Windows download](https://godotengine.org/download/windows/) listed **4.7.2**, released 18 August 2026, during planning. The existing global wrapper reports **4.6.3.stable.official.7d41c59c4**. The implementation session installed a separate verified 4.7.2 editor/template pair under `.tools/`; the global wrapper was left unchanged.

Use the explicit pinned path and commands in [Toolchain](TOOLCHAIN.md), which records origins, SHA512 values, and matching template version. Do not overwrite a global installation that other projects may use.

If 4.7.2 is unavailable or fails a reproducible basic test, document the problem and deliberately select a supported stable alternative, including matching templates. Do not silently fall back to the `godot` command or use a preview release. A version change after saves exist requires the save and deterministic-replay checks again. “Stable” documentation URLs can change; consult docs matching the selected minor version during implementation.

## Why GDScript and Compatibility

The proposed city is small and aggregate-based. There is no present evidence that C++, an ECS framework, multithreading, or a separate simulation language would earn their complexity. Start with typed scripts, flat model data, and headless tests. Profile before changing representation or moving a measured hotspot to native code.

Compatibility keeps the rendering needs proportionate to a pixel-art 2D game and leaves the web-demo option available. It does not prove support for every old GPU. Hardware requirements remain provisional until measured on representative machines.

The original plan proposed `TileMapLayer` for visual layers; Godot documents its suitability for tiled layouts. [Tile-map documentation](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html). M1 deliberately uses a single custom-drawn Node2D for original geometric placeholders while preserving the separate authoritative model. Its world uses integer scaling and independent UI text scaling; see the evidence record for tested sizes. [Resolution documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html).

## Conditions that would change this recommendation

- Browser becomes the primary audience: compare a small Phaser implementation against Godot web startup, saves, and input before committing.
- The team has substantial productive Unity/GameMaker experience: reassess the cost of learning Godot.
- A verified simulation bottleneck remains after sensible profiling and simplification: isolate the hotspot before considering a language/engine change.
- Console launch becomes funded and mandatory: obtain actual porting/provider requirements before promising it.

None of those conditions was established during this session.
