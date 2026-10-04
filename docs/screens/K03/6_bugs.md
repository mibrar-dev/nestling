# K03 Kid home — bug hunt (Stage 6, iteration 13)

Adversarial pass over `kid_home` K03 after the iteration-13 integration
(`shared/pet_bubble_gap` + the shared kid meadow): data edges, rapid double
taps, back navigation and deep links, restart persistence, mode guards, dark
contrast, 320 px + 1.3 scale, async gaps, Europe/London periods, integer
money, owner rules, CHILD ORDER, COPY, fonts, accessibility actions and the
UI VERDICT RULE (±2 px). No screen code was changed in this stage. No
simulator was used.

- Suite: `app/test/features/kid_home/k03_bugs_test.dart` — 62 tests:
  60 run green, 2 skipped (`K03-BUG-16`, `K03-BUG-17`; both open, shared).
- Run the proofs:
  `cd app && flutter test --run-skipped --plain-name K03-BUG-16`
  `cd app && flutter test --run-skipped --plain-name K03-BUG-17`
- Full feature suite: `flutter test test/features/kid_home/` →
  346 pass, 3 skips: the two above + the pre-existing K01-BUG-7 (backlog).
- `dart format .` clean, `flutter analyze` → No issues found.

## Iteration-13 result vs iteration 12

The `bubbleGap: 14` + stage→hearts `s4` fix landed and did what it claims:
at real fonts (`kid_home_geometry_test.dart`, ±0.5) the speech bubble is now
125.0…169.0, the pet box 183.0…419.0, hearts centre 448.0, the section row
494, the progress bar 527…542 and card 1 at 559 — every row is exact. The
hero-ART residual inside the box dropped from 9 px to 4 px by the
orchestrator's reference (274.0 vs 278). The shared meadow is adopted with no
local band, and the painted grades match both design PNGs.

**But the pixel review of the hero art this iteration found a second, larger
defect that the earlier checks attributed to "mandated v2 art": the nest bowl
itself is vertically squashed by ~22 px (K03-BUG-17).** The UI stage's own
iteration-13 capture shows it (measured below), and the design PNG proves it.

## Open bugs

### K03-BUG-16 — The pet hero art sits ~4 px above the design (Major, shared)

**Severity: Major (UI VERDICT RULE; shared — SHARED_REQUEST #18(b)).**
Inside a pet box that is now pixel-exact (183…419), the nest art is seated by
the shared `PipNestFallback.explicitGeometry`:
`nestTop = 236 − nestH − _explicitBleed` = 236 − 188 − 31.4 = 16.6, so the
rim lands at 183 + 95/240 × 188 = **274.0**.

Design references:
- ORCHESTRATOR_NOTES / 5_ui's reference: rim **278** → app 4 px high.
- The PNG itself, x=195 (the design's rim stroke is behind Pip there):
  the first clean ink run is 275.3…279.0; at x=110/280 the outer bowl arc
  runs 302…310 → the app's equivalent arc is 294…301 (8 px high).

Everything between the bubble and the box is exact; K03 cannot fix this
privately (any `nestHeight` > 188 drives `nestTop` negative and lifts the rim
tens of px; `ORCHESTRATOR_NOTES` 10:14 pins 188).

Failing test (skipped so the suite stays green):
- `K03-BUG-16: the pet hero art sits on the design rows`
  (`Expected within 2 of 278, Actual 274.017`).

Suggested fix (shared, SHARED_REQUEST #18(b)): `_explicitBleed` 31.4 → 27.4
(`pip_rive.dart`), which puts the rim on 278.0 per the shared arithmetic.
Option (c) below fixes this and K03-BUG-17 together.

### K03-BUG-17 — The nest bowl is vertically squashed 86 px vs the design's 108 px (Major, shared)

**Severity: Major (UI VERDICT RULE: the bowl is a visible shape ~22 px off;
shared — SHARED_REQUEST #18 option (c)).**

The design rasterises `nest.svg` at its intrinsic 240×240 ratio inside the
236-tall `.k3-pet` box (browser `contain`): art 236×236, bottom 0 at the
slot's bottom (419), so the box top is 183 and the bowl's outer stroke (art
95…205) paints at `183 + 95/240 × 236 = 276.4` … `183 + 205/240 × 236 =
384.6` — a **108.2 px bowl** at **198.6 px** wide.

`design/screens/light/K03-kid-home.png` ÷3 confirms it:
- x=195: bowl ink runs 275.3…384.3 (the back rim is behind Pip; the outer
  bottom stroke is the 378.7…384.3 run);
- x=110/280: outer arcs 302…310 and 350…358 (widest row y 330,
  x 95.7…294 = 198.3 wide, matching the 236 box).

The app stretches the same art into the mandated `nestHeight: 188` with
`BoxFit.fill` (y-scale 188/240 = 0.783 vs the design's 0.983):
- box top `199.6`, rim `274.0`, bowl bottom `199.6 + 205/240 × 188 = 360.2`
  → the bowl paints **198.6 × 86.2**;
- measured on the iteration-13 device capture `ui/app_light_13.png`:
  x=110 294…301, x=280 295…301, x=195 bowl bottom 355…360 — the widget probe
  reproduces these exactly (86.17 vs 108.2; bottom 360.2 vs 384.6).
- User-visible: the design's deep bowl renders as a flat plate; the ground
  shadow and the bowl's whole lower half are ~22–24 px high.

Note: 5_ui iteration 13 recorded "bowl bottom 364" and the orchestrator's
10:14 target "198×86"; both disagree with the PNG bytes at x=110/195/280
above. Whatever the reference, the app cannot match "364" either — it paints
360.2 with the same squash — and the shape difference (86 vs 108) is the
decisive, unambiguous defect.

Failing test (skipped so the suite stays green):
- `K03-BUG-17: the nest bowl keeps the design painted height`
  (`Expected within 2 of 108.2, Actual 86.167`, and bowl bottom
  `360.2` vs `384.6`).

Suggested fix (shared + K03, SHARED_REQUEST #18 option (c), one batch):
1. shared `pip_rive.dart`: `_explicitBleed` 31.4 → 0;
2. K03 `kid_home_view.dart`: `_kNestBoxHeight` 188 → 236.
Then `nestTop = 0`, art scale 236/240, bowl 276.4…384.6 (108.2 tall) and the
rim on 276–278; the stage stays 236 tall, so the bubble, hearts, progress,
cards and dock do not move. When it lands, re-pin `kid_home_geometry_test.dart`
(currently pinning the deviated 274.0/360.2 with KNOWN-DEVIATION comments) and
un-skip both proofs.

## Verified clean this iteration (new probes)

| Category | Probe | Result |
|---|---|---|
| design rows (bubble/box/hearts/title/progress/cards/dock) | real fonts, all ±0.5 | pass |
| data edge: 1 child / 6 children / long UK name / 9999 coins / +0 / empty quest list / long quest title | widget probes | pass |
| data edge: `Seed.fresh` (no children, onboarding incomplete) | router redirects to onboarding; no crash | pass |
| data edge: active child row deleted mid-session | flips to "Who's playing?", no exception | pass |
| quest status `not_yet` (P11 "Not yet") | renders as to-do; tap flips the SAME row to `done_pending` (no duplicate) | pass |
| +9999 reward at 320 px / 1.3 scale | no overflow, no clipping | pass |
| empty quest title | renders, no exception | pass |
| rapid double taps (same frame and one frame apart) | one repo write, one celebration route | pass |
| back from K05 | home shows the flipped card | pass |
| deep links /kid-home (kid), guard paths, restart persistence | earlier proofs still green | pass |
| text scale 2.0 | app shell clamps to 1.3; no overflow | pass |
| speech tail, real fonts | app ink 166…176 vs design 165…174.5 (~1.5 px) | pass |
| meadow grades (both themes, rows 522–718, after scroll) | shared KidScope; no local band | pass |
| a11y actions (tap presence + performAction drives DB/state) | all controls | pass |
| child order, fonts, copy, bottom edge, contrast, periods/BST | earlier proofs still green | pass |

## Observations (not defects)

1. No retry affordance for a mid-session watch error (kept-list design).
2. Period rollover computes at stream-map time; no injectable clock — a
   screen left open across London midnight keeps its counts until the next
   DB emission.
3. Parent-mode `/kid-home` deep link and PIN bypass remain product-level
   questions.
4. The K03 geometry pins currently encode the deviated hero rows
   (274.0/360.2) as KNOWN-DEVIATION; the two skipped proofs hold the design
   values so the deviation cannot become permanent.
5. Static `PipAvatar` fallback omits accessories (no seed child equips one).

## Summary

| ID | Severity | Status |
|---|---|---|
| K03-BUG-16 | **Major (UI VERDICT RULE, shared)** | **open — rim 274 vs 278 ref (PNG stroke 275.3…279); SHARED_REQUEST #18(b)** |
| K03-BUG-17 | **Major (UI VERDICT RULE, shared)** | **open — bowl 86.2 vs design 108.2 (bottom 360.2 vs 384.6); SHARED_REQUEST #18 option (c)** |
| K03-BUG-1..15 | Major..Moderate | fixed; proofs green |

The iteration-13 layout fix (bubble gap + `s4`) is verified exact for every
row of the screen, and the new probes found no further data/tap/guard/async
defects. The screen still cannot pass the ±2 px UI rule: the nest bowl is
22–24 px flatter than the design (K03-BUG-17) and the hero art is off its
reference row (K03-BUG-16). Both are shared-component geometry K03 cannot
reach; the exact fix is filed as SHARED_REQUEST #18, option (c).

VERDICT: FAIL
