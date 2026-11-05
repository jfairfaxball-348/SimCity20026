UNTITLED CITY BUILDER - M2c GROWTH (0.4.0-m2c)

Run citybuilder.exe. Keep citybuilder.pck beside it.
Local development checkpoint; no taxes, upkeep, parks, or projects yet.

1 Roads ($10) / 2 Homes / 6 Shops / 7 Workshops ($25 per plot)
P Power station ($500, 20 plots) / 3 Clear (free, no refund)
Left drag: preview a stroke; release to build. Right click/Escape: cancel.
Invalid strokes never partially apply. Identical repainting is free.
WASD/arrows/middle drag: pan. Wheel/+/-: zoom. Home: outside link.
R: road marks (+/-). E: power marks (bolt/x). Hover a tile to inspect.
Space: pause/resume. 4: normal speed. 5: fast speed.
Ctrl+S: save. Ctrl+L: load. F6: display and text settings.

Lay a road on the east-edge gold flag. Join streets along shared sides.
Place zones beside connected streets and a station beside the network.
Each zone requests one power unit even when empty. Stations supply the
nearest plots first; new nearer plots can displace grown buildings.
Power works without the outside link; growth needs both services.

Every five days, eligible plots can gain one of two development levels.
A home level holds 4 residents; shops/workshops provide 2/4 jobs per level.
Starter demand supports 12 residents before jobs exist. Residents create
business demand; jobs support more homes. HUD demand H/S/W counts level
additions. At most eight additions per type per round, earlier map tiles
first. Satisfied demand stops new growth without evicting existing buildings.
Two growth checks without road access or power lose one level. Reconnect
or add capacity to stop decline; normal demand allows recovery.

Time starts paused. Construction works while paused. Unfocused windows and
dialogs suspend time. Save manually; after restarting, press Load.
Saves: %APPDATA%/OriginalCityBuilder/saves/manual.json
The previous valid save is manual.json.bak; failed loads leave the city intact.
Formats 1 and 2 load with empty development. Loading changes no files.
Saving preserves older primary/backup bytes once as manual.schema1.json or
manual.schema2.json before replacement. Older builds cannot read format 3;
use the preserved older-format copy to roll back.

Windows x64, tested on the development machine. Other hardware, Windows DPI
variants, other operating systems, and controllers remain unverified.
This export is unsigned and is not a public game release.

Original geometric placeholders. Engine/font notices: GODOT_LICENSE.txt,
GODOT_COPYRIGHT.txt, ASSETS.md. Keep these with the game.
