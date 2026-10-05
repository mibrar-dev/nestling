# 5 UI CHECK — K03b Kid home all done (iteration 2)

Seed `kid_all_done` (per ORCHESTRATOR_NOTES, which overrides the brief's
`demo` arg), route `/kid-home-done`, mode kid, child maya,
simulator BC440E48-B3A3-43BC-971B-0EF5DB621874, `DISABLE_ANIMATIONS=1`.
Absolute out paths (relative `docs/...` fails at `shot.sh`'s final `cp`).

Shots: `docs/screens/K03b/ui/app_light_2.png`, `app_dark_2.png`
(1170×2532, ÷3 = logical). Compares: `cmp_light_2.png`, `cmp_dark_2.png`.

## Mean diff + bands

Light: mean diff **3.22%** (was 10.70%)
band 0 (0–105) 3.71 · 1 (105–211) 0.30 · 2 (211–316) 4.57 ·
3 (316–422) 1.32 · 4 (422–527) 1.55 · 5 (527–633) 3.61 ·
6 (633–738) 4.91 · 7 (738–844) 5.80

Dark: mean diff **2.86%** (was 9.10%)
band 0 3.71 · 1 0.32 · 2 3.49 · 3 1.30 · 4 1.07 · 5 3.50 ·
6 4.91 · 7 4.58

Residual bands: 0 = status-bar clock (OS-drawn, ignored); 2 = Pip art
swap (mandated PipAvatar vs v1 SVG) + confetti positions (shared
decorative asset); 5–6 = card meta text widths (DB-driven, see below);
7 = bottom bar + home-indicator zone (design's meadow strip vs the
owner-rule surface-to-edge, app correct).

## Measured y (logical px), design vs app — identical in all four profiles

Full-width border-edge profiler, light + dark, design + app, every row
identical: progress top 513.0, progress bottom 527.0–528.7, card1 top
**545.0**, card1 bottom 630.0–632.7, card1 height **85.0** both, card2
top **645.0**, card2 bottom 721.0–723.7, bar top border 736.0–738.7.

| Element | Design | App | Δ |
|---|---|---|---|
| Screen title "Today's quests" (xcorr strip) | — | dy 0 px | 0 |
| Header "Hi Maya!" glyph top | 64.3 | 64.3 | 0 |
| Speech bubble top / bottom | 125.0 / 190.7 | 125.0 / 190.7 | 0 / 0 |
| Kid progress outer top | 513.0 | 513.0 | 0 |
| Quest card 1 top / bottom / height | 545.0 / 630.0 / 85.0 | same | 0 |
| Quest card 2 top | 645.0 | 645.0 | 0 |
| Card left / right edges | 20.3 / 369.3 | 20.3 / 369.3 | 0 |
| "Visit Pip" lilac fill top / bottom / left / right | 739.0 / 796.7 / 23.0 / 366.7 | same | 0 |
| App card-2 status chip tint height | h32 (spec) | 32.0 | well-formed, not collapsed |

Bubble crop: line 2 "is so proud." starts at the left in the app,
matching `.speech` (shared `speech_align` fix on main). Dark crop:
title, "6 of 6 done" chip (tint bg, light-green text), glossed
progress, sky-tint icon tile, waiting chip, green check — all match
the dark design. Card 2 sits whole above the bar with a gap in both.

## Deviations

None. Iteration-1 findings are fixed: D1 stage height (title 469.3→
pixel-match at every border row; orchestrator targets 469.3/513.0/
545.0 met — card1 top measures exactly 545.0), D2 bubble alignment
(left-aligned, verified in crop). ROW ORDER now matches the design
(dishwasher, reading). ROW META follows the DB per the ruling:
`kid_all_done` leaves dishwasher/reading `done_pending` → "Waiting
for Mum" chips where the design PNG shows "Mum said yes!"/"+10" —
DB-driven content, excluded from the verdict (shapes: card/chip
geometry identical, chip h32 verified).

## Explicitly NOT deviations (rules override the PNGs)

- Status-bar clock — OS-drawn, ignored.
- Pip art (Mochi PipAvatar vs v1 SVG) — PIP rule, mandatory.
- Confetti piece positions — shared decorative asset.
- Card meta text ("Waiting for Mum" vs "Mum said yes!"/"+10") —
  DB status + approval flag per ROW META ruling; excluded.
- Bottom edge surface-to-edge (no meadow strip) — owner rule; app
  correct in both themes.
- Copy ASCII-exact vs HTML ("Hi Maya!", "All done!", bubble,
  "Today's quests", "6 of 6 done", "Visit Pip"); coin pill 120.

VERDICT: PASS
