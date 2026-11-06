# Experimental city artwork (evaluation only)

Two CC0 tile packs by Kenney (www.kenney.nl), retained for the 6 November 2026 artwork evaluation. The owner chose **Roguelike Modern City** (U22); since game 0.7.1-m2e it is the default artwork (U23). The original code-drawn renderer remains the fallback, and Tiny City stays experimental. The folder name is kept for stable resource paths. See `docs/artwork-review/ARTWORK_EVALUATION.md` and `licenses/ASSETS.md` for provenance, hashes and the owner decision that is still pending.

| Folder | Pack | Source | Licence |
| --- | --- | --- | --- |
| `tiny_city/` | Tiny City 1.0 | https://kenney.nl/assets/tiny-city | CC0 1.0 (`License.txt`) |
| `roguelike_modern_city/` | Roguelike Modern City 2.0 | https://kenney.nl/assets/roguelike-modern-city | CC0 1.0 (`License.txt`) |

Each folder keeps only the unmodified packed atlas (`tilemap_packed.png`, 16x16 tiles, no spacing), the pack's `License.txt` and `Tilesheet.txt`. Sprite indices used by the game are listed in `game/scripts/presentation/art_kit.gd`.
