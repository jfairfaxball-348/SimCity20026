# Prototype asset provenance (M1 through M3b, plus experimental candidates)

All map graphics are original code-drawn geometric placeholders in `game/scripts/presentation/world_view.gd`, created for this project on 4 November 2026. No third-party game graphics, screenshots, maps, music, sound effects, fonts, or source code were imported. This prototype has no audio.

M2a adds an original geometric gold outside-link flag and plus/minus access marks in the same script, with an original text inspector. M2b adds an original power-station glyph (a squat hall with a chimney and bolt sign) and bolt/cross power marks drawn from rectangles and lines in the same script. No image-generation service or external asset pack was used.

M2c adds original line/rectangle home roofs, shop awnings, workshop sawtooth roofs, and level-dependent building heights/windows in the same script. Empty zones retain distinct symbols. These are code-drawn placeholders; no external image or generated bitmap was used.

M2d (5 November 2026) adds an original pocket-park placeholder: a rounded tree crown, trunk, diagonal path, and rectangular bench in the same script. The budget text, coverage, arithmetic, and tuning were designed independently for this project. No reference source was opened during implementation. No external bitmap, asset pack, or image-generation service was used.

M3a (5 November 2026) adds an original three-flower cluster drawn with stems and square petals in `world_view.gd`, plus original project goal/checklist/acknowledgement text in `main.gd`. Flowers are cosmetic only. No external assets or reference source were used.

M2e (6 November 2026) replaces the single-tile zone and station placeholders with original code-drawn 3x3 lot buildings (pitched-roof homes, striped-awning shops and sawtooth-roof workshops at two development levels, plus an outlined empty parcel) and an original 4x4 generating hall with two chimneys and a large bolt sign, all drawn from rectangles, lines and polygons in `world_view.gd`. Lot and station wording in `main.gd` and the distribution README is original. The 3x3 and 4x4 footprint sizes follow the owner's U18/U19 decisions; they come from general knowledge of the genre, not from reference source, art or tables. No external assets, generated bitmaps or reference source were used.

M2f (6 November 2026) adds an original code-drawn H/S/W demand meter (letters, small centre-line bars and signed numbers in the interface palette) in `game/scripts/presentation/demand_meter.gd`, plus original tax-row, budget, inspector and help text in `main.gd`. The tax range, rates, appeal and leaving rules were designed for this project; no external assets or reference sources were used.

M2g (6 November 2026) adds an original code-drawn desirability overlay in `world_view.gd` (translucent tints, small plus marks, diagonal hatching and a three-puff smoke mark on developed workshops), plus original inspector, legend, help and status text in `main.gd`. The desirability parts, radii and values were designed for this project; no external assets or reference sources were used.

M2h (6 November 2026) adds an original *Town summary* dialog and status-bar button in `main.gd`, with original item wording and ordering in `game/scripts/presentation/town_summary.gd`. It adds no images or sounds, and no external assets or reference sources were used.

R3 (6 November 2026) adds an original *Town history* dialog in `main.gd` and original code-drawn line graphs (solid and dashed lines, axes and text labels) in `game/scripts/presentation/history_graph.gd`, plus original autosave, settings, load and help wording. No images, sounds, external assets or reference sources were used.

R2c (6 November 2026) adds original code-drawn police and fire stations in `world_view.gd` for the original renderer (a slate hall with a column porch, and a brick hall with two bay doors and a hose tower), an original shield sign and flame sign drawn from polygons on every station in all art modes, an original thin slate or brick band on the Kenney-tile stations in `art_kit.gd` (built from the packs' own wall, roof and front tiles), and an original Services overlay (small squares, triangles and a two-tone cross). Station, overlay, inspector, summary and help wording is original. No external assets or reference sources were used.

M3b (6 November 2026) adds the original First steps card (step texts written for this project, refreshed for 0.10.0-m2h) in `game/scripts/presentation/opening_guide.gd` and `main.gd`, and an original code-drawn corner-bracket marker (four two-tone L-shaped corners) in `world_view.gd`. No external assets or reference sources were used.

R1-R2b (6 November 2026) add original wording only (R1), an original land-value overlay legend and freight text (R2a), and original code-drawn level 3-4 buildings in `world_view.gd` (flat-roofed residential blocks and a tower, a storeyed shop and an office block, larger factories with more chimneys) plus an original yellow stage-pip marker drawn in every art mode (R2b). In the Kenney modes, levels 3-4 reuse pack facade tiles at full height with an original roof edge and parapet band; Tiny City reuses its level-2 tiles. No external assets or reference sources were used.

## Experimental third-party artwork (evaluation only, not adopted)

On 6 November 2026 two tile packs were acquired for an owner-requested artwork evaluation ([report](../docs/artwork-review/ARTWORK_EVALUATION.md)). The owner chose **Roguelike Modern City** (U22), and since game 0.7.1-m2e it is the **default map artwork** (U23). The original placeholders above remain available as the fallback, and Tiny City stays an experimental candidate.

| Field | Kenney Tiny City | Kenney Roguelike Modern City |
| --- | --- | --- |
| Creator | Kenney (www.kenney.nl) | Kenney (www.kenney.nl) |
| Source | https://kenney.nl/assets/tiny-city (official download link) | https://kenney.nl/assets/roguelike-modern-city (official download link) |
| Version | 1.0 (creation date 11-10-2026 in License.txt) | 2.0 (creation date 29-10-2022 in License.txt) |
| Acquired | 6 November 2026 | 6 November 2026 |
| Archive SHA256 | `c20fa416e2eddeb4597da59dd15e321a58ce0a1797a9f84d39d2eb7305ffcf47` | `2a3f36b1bc3a3d1cb4b9da051c493d163c493fe54adc66e78e76b3fb4abcfc56` |
| Licence | Creative Commons CC0 1.0; commercial use, modification and redistribution permitted; credit appreciated, not required | Same |
| Files retained | `game/assets/experiments/city_art/tiny_city/`: `tilemap_packed.png` (SHA256 `e4b371dd…ec2b9`), `License.txt`, `Tilesheet.txt` | `game/assets/experiments/city_art/roguelike_modern_city/`: `tilemap_packed.png` (SHA256 `e8b653bd…b59f`), `License.txt`, `Tilesheet.txt` |
| Modifications | None to the files. At runtime: road curb strips composited from pack tiles; empty lots, water, bolt sign and flowers use original placeholders | None to the files. At runtime: roof outlines in the pack's own dark roof shades; pack overlays composed into facades; water is a flat fill of the pack's pool colour; original zone outline, bolt sign and flowers |
| Status | Experimental, selectable in Display → Artwork; not chosen | **Default artwork since 0.7.1-m2e** (U22/U23); Display → Artwork can select the original fallback |

The PNG atlases are packed into the exported PCK because the experimental mode can load them. Credit: artwork by Kenney (www.kenney.nl), CC0. Archives, individual tiles, preview/sample images and `.url` shortcuts were not retained. No reference-game material was used.

The interface uses Godot's supplied default font and widgets. The pinned Godot 4.7.2 engine's MIT notice is in `GODOT_LICENSE.txt`; its complete third-party notice collection, including bundled fonts, is in `GODOT_COPYRIGHT.txt`. These unmodified texts were obtained from the official `godotengine/godot` repository's `4.7.2-stable` tag and are copied into the Windows distribution.

No blanket open-source licence for original project code or assets has been chosen. These dependency notices do not license the project's original work under MIT.
