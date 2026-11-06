# Artwork evaluation: Kenney Tiny City and Kenney Roguelike Modern City

6 November 2026. **Owner choice recorded (U22):** after reviewing the side-by-side comparison, the owner chose **Kenney Roguelike Modern City** as the artwork direction. It is not yet the game's default: the original code-drawn renderer remains the default and fallback until a later change adopts Modern City as the normal style. The roadmap in [NEXT_SESSION.md](../../NEXT_SESSION.md) is unchanged.

- **Starting commit:** `99c1868ada45ecc5872ff1b66a87f39efb530244` (M2e delivered). Work branch `codex/artwork-eval`.
- **Tested build:** game 0.7.0-m2e plus the experimental art modes, schema 6 / `m2e-1` unchanged. Release EXE SHA256 `d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562`, PCK SHA256 `4d8bc60f0aec6fc526c3a4a79d182f0606810822edf5a6c19d6df30e0fa423a3`. The version string was not bumped, so identify this build by the PCK hash, not by `0.7.0-m2e`. No package was made and nothing was published.
- **Geometry note:** the session brief anticipated 3x3 lots and 4x4 stations as future work, but M2e had already implemented them earlier the same day. The experiment therefore uses the implemented 3x3/4x4 footprints, and no footprint work was needed or done.

## Screenshots

All three are genuine captures of the running Windows EXE (`builds/windows/citybuilder.exe`), not mock-ups.

| File | Artwork mode |
| --- | --- |
| [01-original-baseline.png](01-original-baseline.png) | Original geometric (approved fallback) |
| [02-kenney-tiny-city.png](02-kenney-tiny-city.png) | Kenney Tiny City 1.0 |
| [03-kenney-roguelike-modern-city.png](03-kenney-roguelike-modern-city.png) | Kenney Roguelike Modern City 2.0 |
| [04-side-by-side-comparison.png](04-side-by-side-comparison.png) | The same map region from each capture, at native pixels, side by side |

**How they were made, identically for all three:**

- *Town:* one schema-6 save on the default map (seed 198624, 64x64), built deterministically by the model (`builds/validation/artwork/build_town.gd`, ignored). It has a street grid near the west coast, nine home lots, six shop lots and five workshop lots (developed and undeveloped), a 4x4 station, a nine-tile park block with the completed project's flowers, trees and coastline. Day 91, paused, 48 residents / 18 jobs, power 20/20.
- *Session:* the EXE was launched once in Godot's borderless fullscreen at standard text. It loaded the save with the toolbar Load button and panned west with 26 identical key taps, so the camera, zoom, day and state are identical in every frame. It then switched artwork through the in-game **Display → Artwork** buttons: Original, then Tiny City, then Modern City. The status line in each frame names the mode.
- *Input and capture:* input went only to the game's window as posted messages, and each frame was captured with `PrintWindow`. The real cursor was never moved, so the inspector shows the same tile in all three.
- *Resolution:* the fullscreen client was 1920x1082, so each capture was cropped by exactly one pixel row top and bottom to 1920x1080. A windowed 1920x1080 client does not fit this 1920x1080 display (Windows clamped it to 1920x1061, which would drop the world to 2x scale), so fullscreen was used.
- *No retouching:* no image was retouched, scaled or colour-adjusted. The side-by-side uses the same crop rectangle from each capture.

## Packs acquired and verified

| | Tiny City | Roguelike Modern City |
| --- | --- | --- |
| Creator | Kenney (kenney.nl) | Kenney (kenney.nl) |
| Official page | https://kenney.nl/assets/tiny-city | https://kenney.nl/assets/roguelike-modern-city |
| Version / creation date (from License.txt) | 1.0 / 11-10-2026 | 2.0 / 29-10-2022 |
| Licence | CC0 1.0 (official page and bundled License.txt) | CC0 1.0 (official page and bundled License.txt) |
| Downloaded | 6 Nov 2026, through the official page's signed download link | 6 Nov 2026, same method |
| Archive SHA256 | `c20fa416e2eddeb4597da59dd15e321a58ce0a1797a9f84d39d2eb7305ffcf47` (89,484 bytes) | `2a3f36b1bc3a3d1cb4b9da051c493d163c493fe54adc66e78e76b3fb4abcfc56` (519,937 bytes) |
| Contents | 132 tiles, 16x16, 12x11 sheet, 34 colours | 1,036 tiles, 16x16, 37x28 sheet, 169 colours |

The bundled licence states the content is free to use in personal, educational and commercial projects, with crediting Kenney appreciated but not mandatory. CC0 also permits modification and redistribution. The archive contents matched the pages: same names, tile counts and tile size. All entry paths were checked as safe, and nothing in the archives was executed; the `.url` shortcut files were not extracted.

**Files retained** in `game/assets/experiments/city_art/`. Each pack folder holds `tilemap_packed.png`, unmodified and byte-identical to the archive file, plus `License.txt` and `Tilesheet.txt` copied verbatim. Godot's `.import` sidecars use lossless compression, no mipmaps and the project's nearest filter. The archives, individual tile PNGs, previews, samples and `.url` files were not retained. Provenance is in [licenses/ASSETS.md](../../licenses/ASSETS.md).

## What each pack supplies, and the gaps

The table shows how each object is drawn in each mode. **ORIGINAL** marks this project's own placeholder, used where the pack has no suitable sprite.

| Object | Tiny City | Roguelike Modern City |
| --- | --- | --- |
| Grass | No tile. Flat fill of the pack's own sample-grass colour (132,198,105) | Pack grass tiles 888/889 |
| Water | No tile. **ORIGINAL** water colours | Only swimming-pool tiles. Flat fill of the pack's pool colour |
| Shore | **ORIGINAL** 2-px sand strip | Pack sand tile 894 on coastal land |
| Roads (1 tile wide) | Pack roads are 2-tile halves. Built from the pack asphalt colour plus pack curb strips (tiles 61/62/63/75) on unlinked sides | Pack asphalt 714 with dashed markings 712/749 on straight runs |
| Homes (3x3) | Brown 9-slice roof plus red-brick wall, windows and door (two levels) | Red roof fill with an outline in the pack's dark roof shade, brick facade, window and door overlays |
| Shops (3x3) | Blue roof plus brown wall with the green shop front | Beige roof and facade, striped awning (level 2), glass door, windows |
| Workshops (3x3) | Blue roof plus red-brick wall with double doors. Weak distinction from homes | Grey stone, garage doors, rooftop unit. Clear distinction |
| Empty zoned lots | Pack concrete plus **ORIGINAL** zone outline and symbol | Pack dirt plus **ORIGINAL** zone outline and symbol |
| Power station (4x4) | No power plant. Blue 9-slice roof, brick wall with double doors, pack power pole, **ORIGINAL** bolt sign | No power plant. Grey roof fill, stone wall with garage doors, electrical cabinet, rooftop units, **ORIGINAL** bolt sign |
| Park | Grass plus pack tree 80 | Grass plus pack tree 438 |
| Project flowers | **ORIGINAL** | **ORIGINAL** |
| Trees on open land | Pack trees 80/79 and bush 71. Its conifers share the grass colour and vanish on it, so they were not used | Pack trees 438/440 and bush 512 |
| Flag, road/power marks, previews, UI | **ORIGINAL**, unchanged in every mode | **ORIGINAL**, unchanged in every mode |

Neither pack has a power plant, natural water or an outside-link marker. The game's road-access and power marks are drawn over the art in every mode, and they look busy on both packs (as they do on the original).

## Visual assessment

| Criterion | Tiny City | Roguelike Modern City |
| --- | --- | --- |
| Charming, welcoming SNES-era pixel art | Strongest: bold dark outlines, warm saturated roofs, chunky friendly shapes | More contemporary and realistic; tidy but less cosy |
| Clearly readable buildings | Very readable silhouettes; bordered roofs separate neighbouring lots | Readable facades; flat roofs needed an outline to separate lots |
| Attractive neighbourhoods | Cohesive, but repetitive with only two wall and two roof styles | More varied: awnings, glass, stone, rooftop units, paving, street furniture |
| Clear road and zoning boundaries | Curbed roads read well; homes and workshops look alike | Dark marked roads read clearly; homes (brick), shops (awning/beige) and workshops (grey/garage) are distinct |
| Pleasant natural landscapes | Weak: no grass or water tiles, flat bright green, conifers lost on grass | Better: textured grass, sand beach, two tree shapes. Pool-coloured water is too bright for a coast |
| Consistent architectural style | Consistent | Consistent |
| Compatibility with 16x16 terrain | Native 16x16 | Native 16x16 |
| Suitability for 3x3 and 4x4 buildings | 9-slice roofs work; few facade variants | Many wall, roof, window, door and awning modules |
| Ease of expanding later | Small set; new pieces must be drawn to match | Large set; most extensions can be composed from existing modules |

## Technical assessment

- **Atlases.** Both are packed sheets without spacing: Tiny City 192x176 px (12x11) and Modern City 592x448 px (37x28). Tiles are addressed by row-major index and drawn with `draw_texture_rect_region` at the existing integer zoom, so the result is crisp, unblurred and unstretched in the captures.
- **Integration.** About 150 lines in a new `game/scripts/presentation/art_kit.gd` hold each pack's sprite map. `world_view.gd` dispatches to the kit when a pack is selected; the original drawing code is untouched and remains the default. The only UI changes are a temporary **Artwork (experimental evaluation)** row in the Display dialog and an optional `-- --art=tiny_city|modern_city` launch argument. The selection is not saved, and it does not touch the model, commands, simulation or save format.
- **Rendering behaviour.** No problem was observed at 1920x1080 (3x world scale) on this machine. Frame time was not measured, and the 128x128 maximum was not profiled. This is not a performance claim.
- **Supplementary sprites needed before adoption:**
  - *Both packs:* a power station and natural water/shore.
  - *Tiny City:* grass and terrain, a one-tile road set (or a two-tile road decision), an industrial building family, and more wall and roof variants for variety.
  - *Modern City:* a sloped or edged roof treatment to replace the drawn outline, a calmer water palette, and possibly warmer colour choices for the intended tone.
- **Estimated permanent-adoption effort** (planning estimates, not measured):
  - *Tiny City:* moderate code, but substantial art. A large share of the visible world (terrain, water, industry, power) would be new matching art.
  - *Modern City:* small-to-moderate code, with moderate art for water, the station and roof edges. Most building variety already exists.
- **Modifications.** The image files are unmodified. At runtime the kit composites: curb strips (Tiny City), roof outlines in the pack's own dark shades (Modern City), overlays of pack doors, windows, awnings and props, and the original placeholders listed above.
- **Licence and provenance.** CC0 1.0 for both, confirmed on the official pages and in the downloaded licence files. "Kenney" is credited in the asset ledger and not used as branding. No Micropolis, SimCity or SNES material was accessed or used. The packs are general city tilesets, not reproductions of the reference game.

## Recommendation (not a selection)

Based on these captures, **Roguelike Modern City is the stronger practical base**:

- it already covers terrain (grass, sand, paving), gives the clearest home/shop/workshop distinction, has the road markings, and has enough modules to build varied 3x3 and 4x4 buildings without much new art;
- its weaknesses (contemporary tone, flat roofs, pool-like water, no power plant) can be fixed with a small number of matching additions.

**Tiny City has more of the intended charm.** But the pack lacks most of the world around its buildings, and its workshops are hard to tell from homes. Adopting it would mean drawing much of the game's art ourselves to match.

If charm matters more than coverage, a third option is to keep Modern City's terrain and road approach and commission or draw warmer building art in Tiny City's style. That is a larger production decision.

**Owner decision (U22, 6 November 2026):** Roguelike Modern City is the chosen direction. Adoption is a separate, later change: make it the default style, keep the original renderer as a fallback, and supply documented supplementary sprites for the gaps above (water and shore, power station, roof edges). No gameplay work depends on that change.

## Test results

- **Automated.** Pinned `tools/verify.ps1` (Godot 4.7.2, Windows PowerShell 5.1) passed **482 source checks** and **428 exported-PCK checks**, with zero failures, plus release-EXE headless start-up. The log is `builds/validation/artwork/verify-attempt1.log`. New checks cover:
  - both atlases resolving inside the release PCK;
  - all three Display buttons selecting their mode;
  - the town staying byte-identical across switches;
  - saves never recording the artwork mode;
  - the simulation running under both packs;
  - an unknown mode falling back to the original;
  - the Display dialog fitting at 720p.

  All existing checks, including fixture migrations and the gameplay flows, still pass.
- **Native EXE (fullscreen, posted window messages).** It loaded the schema-6 save, panned, and switched all three modes through the Display dialog (the captures above). Under Modern City it placed a home lot by pointer (exactly $25, command sequence +1), ran time at 3x (day 90 → 103) and paused. It switched to Tiny City and saved: the saved file has the same fields as before (no artwork field), and `.bak` equals the loaded save. Game closed afterwards.
- **Profile hygiene.** The process used `%APPDATA%\OriginalCityBuilder\`, which had no `saves` folder. It was seeded for the run and restored to absent afterwards, and today's packed-test folders were moved out. Native saves and raw captures are kept under ignored `builds/validation/artwork/`.
- **Not tested natively:** the art modes at zoom 2-3, at largest text, at other window sizes, or on another machine; frame-time measurement; physical input; and human preference.
