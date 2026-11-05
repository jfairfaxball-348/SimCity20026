UNTITLED CITY BUILDER - M2d ECONOMY AND PARK (0.5.0-m2d)

Run citybuilder.exe. Keep citybuilder.pck beside it.
Local development checkpoint; monthly economy and a pocket park; no projects yet.

1 Roads ($10) / 2 Homes / 6 Shops / 7 Workshops ($25 per plot)
P Power station ($500, 20 plots) / 8 Park ($100) / 3 Clear (free)
B Budget: expected income/upkeep and latest actual settlement.
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
additions. At most eight additions per type per round, park-covered homes
first, then map order. Satisfied demand stops new growth without evicting existing buildings.
Two growth checks without road access or power lose one level. Reconnect
or add capacity to stop decline; normal demand allows recovery.

Parks cover homes within 3 side-steps; overlap does not stack. They give
priority within existing growth demand/caps, not extra capacity or demand.
Parks need no services and carry neither road access nor power.
Every 30 days after growth: $100 grant + $2 per serviced resident + $4 per
serviced job, minus $1 per road, $60 per station, $10 per park. Unserved
buildings pay no tax. All facilities pay upkeep, even disconnected ones.
A negative net is a deficit. Reduce it by clearing surplus facilities free
or restoring services. Cash never falls below zero; unpaid costs are visibly
waived, with no debt or service cuts. An empty town regains $100 each month.

Time starts paused. Construction works while paused. Unfocused windows and
dialogs suspend time. Save manually; after restarting, press Load.
Saves: %APPDATA%/OriginalCityBuilder/saves/manual.json
The previous valid save is manual.json.bak; failed loads leave the city intact.
Formats 1 and 2 load with empty development; format 3 retains development. Loading changes no files.
Saving preserves older primary/backup bytes once as manual.schema1.json or
manual.schema2.json / manual.schema3.json before replacement.
Schema 4 stores the last budget; older saves start without budget history.
No retroactive charges. Older builds cannot read format 4;
use the preserved older-format copy to roll back.

Windows x64, tested on the development machine. Other hardware, Windows DPI
variants, other operating systems, and controllers remain unverified.
This export is unsigned and is not a public game release.

Original geometric placeholders. Engine/font notices: GODOT_LICENSE.txt,
GODOT_COPYRIGHT.txt, ASSETS.md. Keep these with the game.
