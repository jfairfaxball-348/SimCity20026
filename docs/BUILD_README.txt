UNTITLED CITY BUILDER - R5 CONTROLLER ROUTE (0.18.0-r5)

Run citybuilder.exe. Keep citybuilder.pck beside it. A First steps card at
the bottom left of the map shows one next step at a time (Show centres on
it; Hide closes it for the session; F1 or Help > Show first steps returns).
Local development checkpoint; 3x3 residential, commercial and industrial
lots, 4x4 power plants, a calendar from 1 Jan 1950, a monthly
economy with an adjustable tax rate, a demand meter, neighbourhood
land value for every zone with a map overlay, police and fire stations, a town
summary, monthly history graphs, autosaves, remembered settings, original
sounds and music, gentle animation, full gamepad play, remappable controls,
a pocket park, and one optional project.

1 Roads ($10 per tile) / 2 Residential / 6 Commercial / 7 Industrial
($25 per 3x3 lot). P Power plant (4x4, $500, 20 lots) / 8 Park ($100)
9 Police station / 0 Fire station (3x3, $400 each) / 3 Clear (free)
Zone tools centre a 3x3 lot on the pointer; drag to lay a straight row or
column of lots. Clear any tile of a lot or power plant to remove all of it.
B Budget: expected income/upkeep, latest actual settlement, and the tax
rate (- / + / Standard 10%; 0-25%).
T Town summary (also the status-bar button): the biggest measurable causes
holding the town back, biggest first, each with Show or Budget.
H Graphs (also in Budget): residents, jobs (commercial solid, industrial
dashed) and funds for each month, up to the latest 240 months.
J Project: choose a park with three developed, serviced residential lots that each
have a tile within 3 side-steps. Complete it once to add cosmetic flowers;
no new growth or income benefit. Clear the park freely; completion remains,
flowers do not.
Left drag: preview a stroke; release to build. Right click/Escape: cancel.
Invalid strokes never partially apply. Identical repainting is free.
WASD/arrows/middle drag: pan. Wheel/+/-: zoom. Home: outside link.
R: road marks (+/-). E: power marks (bolt/x). V: land value overlay.
C: services overlay (square = police cover, triangle = fire cover,
cross = a station without road access or power).
Hover a tile to inspect.
M: mute or unmute all sound. Display > Sound & motion: Master, Sounds and
Music volumes (defaults 80 / 70 / 30%), Mute all and Animation on/off.
Display > Controls: change any tool, speed, dialog or overlay key and the
remappable gamepad buttons (choose Key or Pad, then press the new one;
Escape or East cancels; Reset all restores the defaults). Keys named in this
file, Help and First steps are the defaults.

Gamepad: left stick or d-pad moves a map cursor; hold South to build (move
to extend, release to place); East cancels or closes a dialog; LB/RB change
tool; LT/RT zoom; right stick pans; Start pauses; West changes speed; North
opens the Town summary; Back opens the Menu (every dialog and command);
L3 returns to the outside link. In dialogs the d-pad moves focus and South
presses. Prompts appear below the top bar while the gamepad is in use;
moving the mouse hands control back.
Space: pause/resume. 4: normal speed. 5: fast speed.
Ctrl+S: save. Ctrl+L: load. F6: display and text settings.
Artwork: Kenney Roguelike Modern City (CC0) is the default; Display > Artwork
also offers Original (fallback) and Tiny City (experimental). Art choice is
not saved and never changes the town.

Lay a road on the east-edge gold flag. Join streets along shared sides.
A lot needs a connected road beside any of its sides; corners do not count.
Place a power plant beside the network. Each lot requests one power unit even
when empty. Power plants supply the nearest lots first; new nearer lots can
displace grown buildings. Power works without the outside link; growth
needs both services. Power plants carry power but never road access.

Every five days, eligible lots can gain one level, from 0 up to 4.
A residential lot holds 4 / 8 / 20 / 40 residents at levels 1-4; commercial
lots provide 2 / 4 / 10 / 20 jobs and industrial lots 4 / 8 / 16 / 28.
Levels 3 and 4 are gated: residential lots need land value 1 / 2,
commercial lots 3 / 4 (trade plus a park), and industry needs 100 / 250
residents in town. Plain streets stop at level 2. Level 4 also needs police
and fire cover: a police or fire station works with a connected road beside
it and one power unit, and covers lots within 12 side-steps of it (terrain
does not matter; overlap does not stack). Without both, lots stop at level 3. A lot whose value falls
drops one level per check until it fits; nothing is demolished. Two yellow
pips on a lot mark level 4, one pip level 3. The inspector also shows a
residential lot's wealth (modest, comfortable, well-off) from land value;
wealth changes nothing else yet.
Starter demand supports 12 residents before jobs exist. Residents create
business demand; jobs support more residents. The R/C/I meter in the top bar
shows levels the town welcomes (up, +) or that will leave (down, -). At most eight additions per type per round:
residential and commercial lots with higher land value first, industry
nearest the outside link first, then map order. Satisfied demand stops new growth without evicting existing buildings.
Two growth checks without road access or power lose one level. Reconnect
or add capacity to stop decline; normal demand allows recovery.

Land value: a park within 3 side-steps +2 (no stacking), water within
3 +1, each developed industrial lot within 2 side-steps -2 (up to three).
Industry across a one-tile road counts. Commercial lots also gain trade:
+1 per developed residential lot within 3 side-steps (up to +2).
Residential and commercial lots with higher value grow first; below 0 a
lot stops at level 1, and a level-2 lot drops one level at the next check.
Add a park, move industry away or grow residents nearby and it regrows.
Industry ignores land value and is not deterred by other industry; the
industrial lot with the fewest road steps to the gold flag grows first.
V shows the field: + raises, hatching lowers, smoke marks industry.
Parks cover lots with a tile within 3 side-steps; overlap does not stack.
They add no extra capacity or demand. Parks need no services and carry neither road access nor power.
Tax rate (Budget): each point charges 20 cents per serviced resident and
40 cents per serviced job a month; the standard 10% is $2 and $4. Lower
rates raise demand (140% at 0%); higher rates lower it (40% at 25%), and
above 10% up to four surplus levels of each type leave per growth check.
Leaving never removes a lot; lower the rate and the town regrows.
Every 30 days after growth: $100 grant + taxes at the current rate, minus
$1 per road tile, $60 per power plant, $10 per park, $30 per police or fire
station. Unserved
buildings pay no tax. All facilities pay upkeep, even disconnected ones.
A negative net is a deficit. Reduce it by clearing surplus facilities free
or restoring services. Cash never falls below zero; unpaid costs are visibly
waived, with no debt or service cuts. An empty town regains $100 each month.

Dates run in 30-day months (12 a year) from 1 Jan 1950; the date is
derived from elapsed days and never saved. Time starts paused. Construction works while paused. Unfocused windows and
dialogs suspend time. Save manually; after restarting, press Load.
Autosaves: every 60 days of running time the game also writes one of three
rotating autosave slots (saves/autosave1-3.json). They never replace or
change your manual save or its backup. Load > Load autosave opens the newest
valid one (an older slot if the newest is damaged); save it to keep it.
Settings: window size, text size, artwork, the grid, road/power marks, the
land value and services overlays and whether the First steps card is hidden
as well as volumes, mute and animation, are remembered in
%APPDATA%/OriginalCityBuilder/settings.json (version 2; version-1 files keep
their values; version 3 adds remapped controls). A damaged
settings file is ignored and the defaults are used; it never affects saves.
Saves: %APPDATA%/OriginalCityBuilder/saves/manual.json
The previous valid save is manual.json.bak; failed loads leave the city intact.
Format 12 (0.16.0-r3) adds the monthly history (up to 240 months) to format 11, which stores
the tax rate, lot, power plant and police/fire station anchors and their upkeep counts; land
value, freight and police/fire cover are derived, never saved, and the guide, calendar and
settings are not part of a save. Format 11 saves load with every value kept and an empty history.
Format 10 saves load with every lot kept (level-4 lots without police and fire cover then drop to 3 one level per check);
formats 9, 8 and 7 load unchanged; format 6 saves load at the standard 10% rate. Earlier formats (1-5) load with
their old single-tile zones and power stations cleared; roads, parks, funds, time,
budget history and project completion are kept. Loading changes no files.
Saving preserves older primary/backup bytes once as manual.schema1.json to
manual.schema11.json before replacement. No retroactive charges. Older builds
cannot read format 12; use the preserved older-format copy to roll back.

Windows x64, tested on the development machine. Other hardware, Windows DPI
variants and other operating systems remain unverified. The gamepad route was
tested with simulated gamepad input only; no real controller has been tried.
This export is unsigned and is not a public game release.

Sound: five short sounds (build, clear, refused action, growth, a deficit
month) and one calm 12-second music loop, all synthesised by the game's own
code while it runs; there are no audio files. Animation: water shimmer,
industry smoke and a slowly breathing link flag; nothing flashes, and it can
be turned off. Neither changes the town.

Map art: Kenney Roguelike Modern City (CC0, www.kenney.nl) plus original
placeholders for water, the power-plant sign, the police shield and fire flame
signs, empty-lot outlines and flowers; original geometric art remains available. Engine/font notices: GODOT_LICENSE.txt,
GODOT_COPYRIGHT.txt, ASSETS.md. Keep these with the game.
