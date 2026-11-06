UNTITLED CITY BUILDER - M2g NEIGHBOURHOOD DESIRABILITY (0.9.0-m2g)

Run citybuilder.exe. Keep citybuilder.pck beside it.
Local development checkpoint; 3x3 zone lots, 4x4 power stations, a monthly
economy with an adjustable tax rate, a demand meter, neighbourhood
desirability with a map overlay, a pocket park, and one optional project.

1 Roads ($10 per tile) / 2 Homes / 6 Shops / 7 Workshops ($25 per 3x3 lot)
P Power station (4x4, $500, 20 lots) / 8 Park ($100) / 3 Clear (free)
Zone tools centre a 3x3 lot on the pointer; drag to lay a straight row or
column of lots. Clear any tile of a lot or station to remove all of it.
B Budget: expected income/upkeep, latest actual settlement, and the tax
rate (- / + / Standard 10%; 0-25%).
J Project: choose a park with three developed, serviced home lots that each
have a tile within 3 side-steps. Complete it once to add cosmetic flowers;
no new growth or income benefit. Clear the park freely; completion remains,
flowers do not.
Left drag: preview a stroke; release to build. Right click/Escape: cancel.
Invalid strokes never partially apply. Identical repainting is free.
WASD/arrows/middle drag: pan. Wheel/+/-: zoom. Home: outside link.
R: road marks (+/-). E: power marks (bolt/x). V: desirability overlay.
Hover a tile to inspect.
Space: pause/resume. 4: normal speed. 5: fast speed.
Ctrl+S: save. Ctrl+L: load. F6: display and text settings.
Artwork: Kenney Roguelike Modern City (CC0) is the default; Display > Artwork
also offers Original (fallback) and Tiny City (experimental). Art choice is
not saved and never changes the town.

Lay a road on the east-edge gold flag. Join streets along shared sides.
A lot needs a connected road beside any of its sides; corners do not count.
Place a station beside the network. Each lot requests one power unit even
when empty. Stations supply the nearest lots first; new nearer lots can
displace grown buildings. Power works without the outside link; growth
needs both services. Stations carry power but never road access.

Every five days, eligible lots can gain one of two development levels.
A home level holds 4 residents; shops/workshops provide 2/4 jobs per level.
Starter demand supports 12 residents before jobs exist. Residents create
business demand; jobs support more homes. The H/S/W meter in the top bar
shows levels the town welcomes (up, +) or that will leave (down, -). At most eight additions per type per round, park-covered homes
first, then map order. Satisfied demand stops new growth without evicting existing buildings.
Two growth checks without road access or power lose one level. Reconnect
or add capacity to stop decline; normal demand allows recovery.

Home desirability: a park within 3 side-steps +2 (no stacking), water within
3 +1, each developed workshop lot within 2 side-steps -2 (up to three).
A workshop across a one-tile road counts. Higher-scoring homes grow first;
below 0 a home stops at level 1, and a level-2 home drops one level at the
next check. Add a park or move workshops away and it regrows. V shows the
field: + marks attract, hatching deters, smoke marks developed workshops.
Parks cover lots with a tile within 3 side-steps; overlap does not stack.
They add no extra capacity or demand. Parks need no services and carry neither road access nor power.
Tax rate (Budget): each point charges 20 cents per serviced resident and
40 cents per serviced job a month; the standard 10% is $2 and $4. Lower
rates raise demand (140% at 0%); higher rates lower it (40% at 25%), and
above 10% up to four surplus levels of each type leave per growth check.
Leaving never removes a lot; lower the rate and the town regrows.
Every 30 days after growth: $100 grant + taxes at the current rate, minus
$1 per road tile, $60 per station, $10 per park. Unserved
buildings pay no tax. All facilities pay upkeep, even disconnected ones.
A negative net is a deficit. Reduce it by clearing surplus facilities free
or restoring services. Cash never falls below zero; unpaid costs are visibly
waived, with no debt or service cuts. An empty town regains $100 each month.

Time starts paused. Construction works while paused. Unfocused windows and
dialogs suspend time. Save manually; after restarting, press Load.
Saves: %APPDATA%/OriginalCityBuilder/saves/manual.json
The previous valid save is manual.json.bak; failed loads leave the city intact.
Format 8 (desirability rules) stores the same fields as format 7: the tax
rate and lot and station anchors; desirability is derived, never saved.
Format 7 saves load unchanged; format 6 saves load at the standard 10% rate. Earlier formats (1-5) load with
their old single-tile zones and stations cleared; roads, parks, funds, time,
budget history and project completion are kept. Loading changes no files.
Saving preserves older primary/backup bytes once as manual.schema1.json to
manual.schema7.json before replacement. No retroactive charges. Older builds
cannot read format 8; use the preserved older-format copy to roll back.

Windows x64, tested on the development machine. Other hardware, Windows DPI
variants, other operating systems, and controllers remain unverified.
This export is unsigned and is not a public game release.

Map art: Kenney Roguelike Modern City (CC0, www.kenney.nl) plus original
placeholders for water, the power-station sign, empty-lot outlines and
flowers; original geometric art remains available. Engine/font notices: GODOT_LICENSE.txt,
GODOT_COPYRIGHT.txt, ASSETS.md. Keep these with the game.
