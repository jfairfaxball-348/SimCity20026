UNTITLED CITY BUILDER - M2a ROAD ACCESS (0.2.0-m2a)

Run citybuilder.exe. Keep citybuilder.pck beside it.
This is a local planning sandbox, not a finished city simulation.
There are no residents, growth, power, or taxes yet.

1: Roads ($10/tile)   2: Home zones ($25/tile)   3: Clear (free, no refund)
Left-drag: preview a complete stroke; release to build.
Right-click/Escape: cancel. Conflicting/invalid strokes do not partially apply.
WASD/arrows/middle-drag: pan. Wheel/+/-: zoom. Home: outside link.
R: toggle road access marks (+ connected, - missing). Hover a tile to inspect.
Space: pause/resume. 4: normal speed. 5: fast speed.
Ctrl+S: save. Ctrl+L: load. F6: display and text settings.

Lay a road on the gold flag at the east edge to activate the outside link.
Connect roads along shared sides. A home gets access from a connected road
beside it; diagonals and other edge roads do not supply access. Removing a
connecting road cuts service immediately. Rebuild it to reconnect the district.
Home plots stay empty: growth and power are not implemented in this checkpoint.
M1 saves remain supported; road access is derived from their existing layouts.

Time starts paused. Construction works while paused. Unfocused windows and
open dialogs suspend time. Save/load is manual; after restarting, press Load.
Saves: %APPDATA%/OriginalCityBuilder/saves/manual.json
The preceding good save is manual.json.bak. A failed load leaves the city intact;
if a valid backup exists, the game offers to load it.

Windows x64. Tested on the development machine; broader hardware support and
other operating systems are unverified. This development export is unsigned.

Original geometric placeholder graphics. Godot/default-font licences are
included in GODOT_LICENSE.txt and GODOT_COPYRIGHT.txt. See ASSETS.md.
