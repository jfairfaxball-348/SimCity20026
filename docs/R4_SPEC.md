# R4: original sound sample and first animations

Specified 7 November 2026 under the owner's "Run next session" request (U41), from the [roadmap](ROADMAP.md) and the [handoff](../NEXT_SESSION.md). Adopted as [D40](DECISIONS.md#d40) before code, then implemented and locally verified as 0.17.0-r4 ([evidence](sessions/2026-11-07-r4.md)). **Revised during implementation, before delivery:** the native run showed the Display dialog running off the bottom of a 720p window once Sound & motion was added, so Center view and Sound & motion share one row; a stricter packed check now measures the dialog's position as well as its size. All values, sounds and music are this project's own; nothing comes from the reference game or any third party.

## Goal

Give the town a gentle, coherent voice and a little life on screen, while keeping the relaxed default (U05): quiet sounds, calm music, slow movement, and a way to turn each off.

## Rules

### How the audio is made (provenance)

- Every sound and the music are **synthesised at run time by this project's own code** (`game/scripts/presentation/sound_kit.gd`) from our own parameters: sine and triangle tones, simple envelopes and a deterministic noise generator of our own. There are **no audio files**, downloads, samples, soundfonts, packs or generation services.
- The melody and harmony of the music are written for this project (notes listed in the code). They are not arrangements of any existing piece.
- Synthesis never uses the town's random number generator and never reads or changes the model.
- `licenses/ASSETS.md` records each sound, how it is made and that it is original.

### Sounds

| Sound | Plays when | Character |
| --- | --- | --- |
| build | a construction command changes something | two soft rising notes |
| clear | a Clear command removes something | a short soft brush of noise |
| reject | a stroke is refused | two low, soft taps |
| grow | a growth round raises the town's total levels | a small three-note chime (once per round at most) |
| alert | a monthly settlement closes with a deficit | a gentle two-tone bell |

Each is under one second, peaks at no more than half of full scale, and fades in and out without clicks.

### Music

One original looping piece of about 12 seconds (16 beats at 80 beats per minute) in a major pentatonic mood: a soft pad of sustained chords and a sparse plucked melody. It is generated once in the background after start-up and loops seamlessly. It plays only while the music volume is above zero and sound is not muted.

### Volumes and mute

- Three audio buses: Master, Effects (sounds) and Music, each with a volume of 0-100% in steps of 10.
- Defaults: Master 80%, Effects 70%, **Music 30%**. A volume of 0 silences that bus.
- **Mute all** (also the **M** key) silences everything without changing the volumes.
- A **Sound & motion** dialog, opened from Display, holds the three volumes (− / + buttons with the value as text), Mute all and Animation on/off.

### Animations (presentation only)

- **Water shimmer:** a few short light streaks on water drift slowly across their tiles (a 4-second cycle).
- **Industry smoke:** developed industrial lots release three puffs that rise and fade (a 3-second cycle), in every art mode.
- **Outside-link flag:** its outline breathes slowly between two brightnesses (a 2.4-second cycle).
- Nothing changes faster than about one cycle every two seconds and nothing flashes. The world is redrawn about ten times a second while animation is on.
- Animation follows real time, not the simulation, so it moves while paused and never affects the model. **Animation off** shows the static first frame.

### Settings (D39 extended)

`settings.json` becomes **version 2**: the nine version-1 keys plus `master_volume`, `effects_volume`, `music_volume` (0-100, multiples of 10), `muted` and `animation` (true/false). Defaults: 80, 70, 30, false, true. A valid version-1 file loads with its values kept and the new defaults added; anything else invalid still gives all defaults. The file is always written as version 2.

### Versions

Game **0.17.0-r4**. No save change: schema 12 and `r3-1` stay; the thirteen fixtures stay byte-identical.

## Changes to earlier rules

- **D10**: the first original audio arrives, made by our own code.
- **D39**: settings version 2 as above; every fallback rule is unchanged.
- **D31**: presentation gains animation, still never part of a save or the model.
- Every simulation and save rule (D17-D38) is unchanged.

## Acceptance checklist

- [x] Unit tests: every sound and the music are generated, short or looping as specified, peak at most half scale, start and end quietly, and are identical on every run; synthesis consumes no town randomness; settings version 2, version-1 migration and bounds.
- [x] Packed tests through the shipped UI: the Sound & motion dialog at every layout and text size, volumes and mute applied to the buses and remembered, M, animation on/off, sounds triggered by build, clear, reject, growth and a deficit, and the town unchanged by animation and audio.
- [x] `tools/verify.ps1` passes (headless audio must not fail).
- [x] Native run of the actual EXE showing the dialog and animation frames; record honestly that an automated run cannot judge how the audio sounds.
