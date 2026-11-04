# Research sources and evidence limits

Research date: **4 November 2026**, using the user's Europe/London date. Sources below are official documentation, public authority guidance, or developer/publisher descriptions. Links were consulted for this planning session; no paid market research, game purchase, or contact with a publisher was performed.

This is the **historical initial planning record**. A subsequent user-authorised session implemented M0/M1; current toolchain/build evidence is in [TOOLCHAIN.md](TOOLCHAIN.md) and [the milestone record](sessions/2026-11-04-m0-m1.md). Statements below about unexecuted work describe the end of planning, not the current repository.

Facts from these sources inform the recommendations. The recommended architecture, game concept, scope limits, milestone estimates, and playtest thresholds are this project's proposed decisions; they are not claims made by the cited organisations.

## Historical reference and IP

| ID | Source | What it supports / limits |
| --- | --- | --- |
| S01 | [Nintendo Japan: SimCity Virtual Console description](https://www.nintendo.co.jp/wii/vc/vc_sc/vc_sc_01.html) | Dates the Super Famicom game to 26 April 1991; historical reference only |
| S02 | [Nintendo UK: SimCity overview](https://www.nintendo.com/en-gb/Games/Virtual-Console-Wii-/SimCity--278964.html) | Describes the SNES adaptation's seasons, scenarios, and music; does not grant reuse rights |
| S03 | [US Copyright Office: Games](https://www.copyright.gov/register/tx-games.html) | General distinction between game ideas/methods and protectable expression; not title or finished-product clearance |
| S04 | [UK Government: Intellectual property and your work](https://www.gov.uk/intellectual-property-an-overview) | IP categories and ownership, including commissioned work by self-employed creators |
| S05 | [UK Government: Search for a trade mark](https://www.gov.uk/search-for-trademark) | A route for UK brand searches; no name search or clearance completed here |
| S06 | [USPTO: Search our trademark database](https://www.uspto.gov/trademarks/search) | A route for US searches; not evidence that any proposed name is available |

## Engine, platform, and workflow

| ID | Source | What it supports / limits |
| --- | --- | --- |
| S07 | [Godot Windows download](https://godotengine.org/download/windows/) | Official page lists 4.7.2, dated 18 August 2026; Standard and .NET variants and export templates |
| S08 | [Godot licence](https://godotengine.org/license/) | MIT engine licensing; game content has its own licensing choice |
| S09 | [Godot web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) | WebAssembly/WebGL 2, Compatibility renderer, C# limitation, single-threaded option and browser caveats |
| S10 | [Godot tile-map guide](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html) | TileMapLayer presentation capabilities; not a benchmark of this game's simulation |
| S11 | [Godot multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) | Integer scaling and pixel-art display guidance; actual project layout still requires testing |
| S12 | [Godot version-control guide](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html) | Cache exclusions and version-sensitive export configuration considerations |
| S13 | [Godot command-line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) | Headless import, script execution, and exports; example commands in this plan are unexecuted |
| S14 | [Godot licence compliance](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html) | Engine and third-party notices for distributions |
| S15 | [Godot console support](https://godotengine.org/consoles/) | Approval, SDK, and middleware/porting constraints for closed consoles |
| S16 | [Godot macOS export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html) | Signing/notarisation considerations; no macOS test or certificate verified here |
| S17 | [GameMaker FAQ](https://gamemaker.io/en/help/articles/gamemaker-faq) | Non-commercial use, current one-time commercial price, and distinct console requirements |
| S18 | [Unity Personal](https://unity.com/products/unity-personal) | Free tier subject to financial eligibility; not a legal determination of this owner's eligibility |
| S19 | [Unity pricing changes](https://unity.com/products/pricing-updates) | Current plan information and Runtime Fee cancellation |
| S20 | [Phaser framework licence](https://phaser.io/download/license) | MIT licence for the open-source framework |
| S21 | [What is Phaser?](https://www.phaser.io/oss/docs/phaser/getting-started/what-is-phaser) | Browser focus, JavaScript/TypeScript, and third-party native packaging route |

The `/stable/` Godot documentation URLs are moving references. Confirm APIs against the engine version actually adopted. This session did not download 4.7.2, verify its distribution checksums, install templates, or prove that the local 4.6.3 installation is suitable for the future project.

## Comparable games

| ID | Source | What it supports / limits |
| --- | --- | --- |
| S22 | [TheoTown developer store page](https://store.steampowered.com/app/1084020/TheoTown/) | Broad city systems and transportation scope from its own description |
| S23 | [Urbek City Builder developer store page](https://store.steampowered.com/app/1411740/Urbek_City_Builder/) | Neighbourhood conditions and a resource economy without money |
| S24 | [Toukana: Dorfromantik](https://www.toukana.com/dorfromantik) | Peaceful landscape/tile building and quests |

Descriptions establish competing design offerings. They do not establish market size, sales, development cost, conversion, or whether this proposed game will find buyers. No gameplay sessions or player interviews were conducted in this research.

## Release and distribution

| ID | Source | What it supports / limits |
| --- | --- | --- |
| S25 | [Steam Direct fee](https://partner.steamgames.com/doc/gettingstarted/appfee) | US$100 fee, applicable taxes, and recoupment conditions |
| S26 | [Steam onboarding](https://partner.steamgames.com/doc/gettingstarted/onboarding) | Account/legal/tax/banking steps, current waiting period, and Coming Soon requirement |
| S27 | [Steam review process](https://partner.steamgames.com/doc/store/review_process) | Review timing guidance and requirement that listed features work |
| S28 | [Steam release process](https://partner.steamgames.com/doc/store/releasing) | Store/build checklists, submission sequence, and release controls |
| S29 | [Steam Content Survey](https://partner.steamgames.com/doc/gettingstarted/contentsurvey) | Current generated-content disclosure distinctions |
| S30 | [Steam hardware compatibility review](https://partner.steamgames.com/doc/steamhardware/compat) | Controller, text, and hardware requirements; no compatibility badge is claimed for this project |
| S31 | [itch.io getting started](https://itch.io/docs/creators/getting-started) | Account/page setup, downloadable packages, and demo options |
| S32 | [itch.io access controls](https://itch.io/docs/creators/access-control) | Draft, restricted, public, download-key, and password options |

Steam onboarding returned a **21-day fee-to-release waiting period for the first few titles** and at least **two weeks publicly Coming Soon** when checked. Keep this dated observation separate from remembered older requirements. Recheck the live requirements and the account dashboard before scheduling a launch. Engine versions, store policies, pricing, and eligibility can change.

## Local evidence

Read-only inspection on 4 November 2026 found:

- `C:\SimCity20026` initially contained only `.git`; Git reported no commits on `main`.
- Origin configured as `https://github.com/jfairfaxball-348/SimCity20026.git`. The remote's actual contents, visibility, and access were not verified.
- `godot --version`: `4.6.3.stable.official.7d41c59c4`.
- `Get-Command godot`: `C:\dev\tools\godot\godot.cmd`.
- `git --version`: `2.54.0.windows.1`.
- Windows 11 Home, 64-bit, approximately 15.7 GiB physical RAM.

No existing parent/repo `AGENTS.md` was found at inspection. The current root instructions were written as part of the handoff. No unrelated personal files or earlier project memories informed the plan.

## What was unverified at the end of planning

Actual game behaviour and performance; the final simulation equations; player enjoyment; development capacity; original asset production cost; legal jurisdiction and title/visual clearance; current remote/account state; Steam eligibility or readiness; non-Windows hardware; controller/Deck support; and all implementation/release milestones.

The planned M0/M1 checkpoint has since supplied bounded implementation evidence. Use the current handoff and later gates for remaining design and commercial uncertainty. Revisit settled capabilities only when relevant circumstances change.
