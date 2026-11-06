# M2h: town summary

Specified 6 November 2026 at the start of the owner's "Run next session" request (U27), as the third milestone of the city-builder roadmap (U24, candidate 7 in [the genre table](GENRE_ALIGNMENT.md)). These rules were adopted as [D34](DECISIONS.md#d34) before implementation code, then **implemented and locally verified as game 0.10.0-m2h** ([evidence](sessions/2026-11-06-m2h.md)).

**Sources of the rules.**

- The layout, wording and ordering are this project's own.
- From the permitted study notes, only the explanation contract is used: each blocker names its condition, where it is, and a remedy, and separate causes keep separate explanations.
- There are no random complaints, opinion polls or approval rating.

## Player benefit

One key gives a short, ranked answer to "what is holding my town back?":

- each answer has a count, a place to look and something to do about it;
- the per-lot inspector stays the detailed explanation;
- the summary only gathers its conditions town-wide.

## Rules

The summary is **derived and read-only**. It is a pure function of the current town and changes nothing: no command, sequence, cash, time, RNG or unsaved flag.

**Growth blockers**, each listed only when its count is above zero:

| Kind | Condition (from existing derived state) | Levels affected | Action |
| --- | --- | --- | --- |
| No link | The gold flag has no road, and zone lots exist. This replaces the access item | 2 per zone lot | Show the flag |
| Access | Zone lots without road access to the flag | 2 per lot | Show the first such lot |
| No power | Zone lots on no powered network | 2 per lot | Show the first such lot |
| Short of power | Zone lots on a full network | 2 per lot | Show the first such lot |
| Held homes | Serviced home lots held at level 1, or dropping, by workshops (D33) | 1 per lot | Show the first such lot |
| Leaving | Levels above target while taxes are above 10% (D32) | The surplus levels | Open Budget |
| No room | A zone type has demand, but no serviced lot of that type can grow (none below its cap) | The demand levels | Show the gold flag |

- **Counts and examples.** Counts are lots (or levels for Leaving and No room). Text notes how many of the affected lots already hold buildings. "First" means the lowest anchor index.
- **Ordering.** Blockers are ordered by levels affected (most first), then in the table order. At most **five** are shown.
- **Budget.** A **Deficit** item (forecast net below zero) follows the blockers and opens Budget.
- **Status items.** These appear when nothing above applies.
  - **Empty town** appears when no zone lots exist. It gives the three starting steps and shows the flag.
  - **Nothing holding back** appears otherwise. It explains that demand is met and how growth resumes.

## Interface

- **Opening it.** **T** opens a *Town summary* dialog, and a **Town summary [T]** button sits at the right end of the status bar.
- **Contents.** The dialog has a heading with residents, jobs, tax rate and day, then one row per item: its text and an action button.
- **Show.** Show closes the dialog, centres the view on the example and points the inspector at it, like the project's Show park.
- **Budget.** The Budget action opens the Budget dialog.
- **Time.** The dialog is modal, so time stays suspended while it is open, like the other dialogs.
- **Fit.** It fits 720p at text 16, 18 and 20.
- **Help** gains one line.

## Saves and versions

- No save change. The game becomes `0.10.0-m2h` with schema 8 / `m2g-1` unchanged, so 0.9.0-m2g and 0.10.0-m2h read each other's saves.
- Fixtures are unchanged.

## Acceptance checklist

1. Each item kind appears exactly when its condition holds, with correct counts, levels and examples, on constructed towns.
2. Ordering follows levels and then the table order; at most five blockers appear; the deficit follows them; and empty and satisfied towns get their status items.
3. Building the summary and opening the dialog change no model state: canonical text, sequence and RNG are unchanged.
4. In the exported game, T and the status-bar button open the dialog. Show centres on and inspects the example, and the Budget action opens Budget. The dialog suspends time and fits at all four window sizes and three text sizes.
5. Pinned `tools/verify.ps1` passes. Native EXE checks show the summary on a real town and a Show action. The package builds.

Out of scope: new simulation rules, notifications or pop-ups during play, desirability for businesses, the M3b guide, autosaves, the controller route and final art/audio.
