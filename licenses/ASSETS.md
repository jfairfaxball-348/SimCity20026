# Prototype asset provenance (M1 through M2e, plus experimental candidates)

All map graphics are original code-drawn geometric placeholders in `game/scripts/presentation/world_view.gd`, created for this project on 4 November 2026. No third-party game graphics, screenshots, maps, music, sound effects, fonts, or source code were imported. This prototype has no audio.

M2a adds an original geometric gold outside-link flag and plus/minus access marks in the same script, with an original text inspector. M2b adds an original power-station glyph (a squat hall with a chimney and bolt sign) and bolt/cross power marks drawn from rectangles and lines in the same script. No image-generation service or external asset pack was used.

M2c adds original line/rectangle home roofs, shop awnings, workshop sawtooth roofs, and level-dependent building heights/windows in the same script. Empty zones retain distinct symbols. These are code-drawn placeholders; no external image or generated bitmap was used.

M2d (5 November 2026) adds an original pocket-park placeholder: a rounded tree crown, trunk, diagonal path, and rectangular bench in the same script. The budget text, coverage, arithmetic, and tuning were designed independently for this project. No reference source was opened during implementation. No external bitmap, asset pack, or image-generation service was used.

M3a (5 November 2026) adds an original three-flower cluster drawn with stems and square petals in `world_view.gd`, plus original project goal/checklist/acknowledgement text in `main.gd`. Flowers are cosmetic only. No external assets or reference source were used.

M2e (6 November 2026) replaces the single-tile zone and station placeholders with original code-drawn 3x3 lot buildings (pitched-roof homes, striped-awning shops and sawtooth-roof workshops at two development levels, plus an outlined empty parcel) and an original 4x4 generating hall with two chimneys and a large bolt sign, all drawn from rectangles, lines and polygons in `world_view.gd`. Lot and station wording in `main.gd` and the distribution README is original. The 3x3 and 4x4 footprint sizes follow the owner's U18/U19 decisions; they come from general knowledge of the genre, not from reference source, art or tables. No external assets, generated bitmaps or reference source were used.

## Experimental third-party artwork (evaluation only, not adopted)

On 6 November 2026 two tile packs were acquired for an owner-requested artwork evaluation ([report](../docs/artwork-review/ARTWORK_EVALUATION.md)). The owner chose **Roguelike Modern City** as the artwork direction (U22); it is not yet the default. The original placeholders above remain the default and fallback, and Tiny City stays an experimental candidate.

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
| Status | Experimental, selectable in Display → Artwork; not chosen | Chosen direction (U22), selectable in Display → Artwork; not yet the default |

The PNG atlases are packed into the exported PCK because the experimental mode can load them. Credit: artwork by Kenney (www.kenney.nl), CC0. Archives, individual tiles, preview/sample images and `.url` shortcuts were not retained. No reference-game material was used.

The interface uses Godot's supplied default font and widgets. The pinned Godot 4.7.2 engine's MIT notice is in `GODOT_LICENSE.txt`; its complete third-party notice collection, including bundled fonts, is in `GODOT_COPYRIGHT.txt`. These unmodified texts were obtained from the official `godotengine/godot` repository's `4.7.2-stable` tag and are copied into the Windows distribution.

No blanket open-source licence for original project code or assets has been chosen. These dependency notices do not license the project's original work under MIT.
