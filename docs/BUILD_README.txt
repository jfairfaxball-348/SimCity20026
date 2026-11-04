UNTITLED CITY BUILDER - M2b POWER ACCESS (0.3.0-m2b)

Run citybuilder.exe. Keep citybuilder.pck beside it.
This is a local planning sandbox, not a finished city simulation.
There are no residents, growth, shops/workshops, upkeep, or taxes yet.

1: Roads ($10/tile)   2: Home zones ($25/tile)   3: Clear (free, no refund)
P: Power station ($500, one per placement)
Left-drag: preview a complete stroke; release to build.
Right-click/Escape: cancel. Conflicting/invalid strokes do not partially apply.
WASD/arrows/middle-drag: pan. Wheel/+/-: zoom. Home: outside link.
R: road access marks (+ connected, - missing).
E: power marks (bolt = powered, x = unpowered plot). Hover a tile to inspect.
Space: pause/resume. 4: normal speed. 5: fast speed.
Ctrl+S: save. Ctrl+L: load. F6: display and text settings.

Lay a road on the gold flag at the east edge to activate the outside link.
Connect roads along shared sides. A home gets access from a connected road
beside it; diagonals and other edge roads do not supply access.

A power station supplies 20 home plots through the roads and stations it
touches; each plot needs 1 unit. When a network is short, the plots nearest
a station are served first. Power works without the outside link, and a
station does not carry road access: they are separate needs. Removing a road
or station cuts supply immediately; rebuild it to restore it. The toolbar
shows power used/capacity and how many plots are short. Plots stay empty:
growth is not implemented in this checkpoint.

Saves from 0.1.0/0.2.0 (format 1) load and are updated in memory. The first
save over one keeps its original bytes as manual.schema1.json. Older builds
cannot read the new format; use that preserved copy to roll back.

Time starts paused. Construction works while paused. Unfocused windows and
open dialogs suspend time. Save/load is manual; after restarting, press Load.
Saves: %APPDATA%/OriginalCityBuilder/saves/manual.json
The preceding good save is manual.json.bak. A failed load leaves the city intact;
if a valid backup exists, the game offers to load it.

Windows x64. Tested on the development machine; broader hardware support and
other operating systems are unverified. This development export is unsigned.

Original geometric placeholder graphics. Godot/default-font licences are
included in GODOT_LICENSE.txt and GODOT_COPYRIGHT.txt. See ASSETS.md.
