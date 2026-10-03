# K03 Kid home — Stage 2b UI chunk (iteration 12)

Scope: `app/lib/features/kid_home/presentation/views/**`,
`presentation/widgets/**` and the design-geometry test
`app/test/features/kid_home/kid_home_geometry_test.dart`. **No domain/data/
bloc/route/DI file touched** — `2a_build_logic.md` re-read before finishing
(written for iteration 12): still **no CONTRACT CHANGES**. No simulator was
booted, installed on, driven or screenshot (SIMULATORS rule — stage 5 only).

**The headline: `shared/speech_tail` (`b1137f3`, merged into this branch at
14:35, after the iteration-11 UI capture) shifted the whole screen up 10.25 px,
and this iteration puts it back.**

## What the shared tail change did to K03

The shared fix is correct: the CSS `.speech::after` tail is an absolutely
positioned overflow box, so the bubble's laid-out box must be the body alone.
The old shared tail was an 18×10 **in-flow** box, so `NestPetStage` lost
10.25 px of laid-out height. That is a **uniform vertical shift of the entire
screen** — the one thing the UI VERDICT RULE calls a FAIL even when every
element "looks the same". Measured at real fonts
(`kid_home_geometry_test.dart`) right after the merge, four tests failed:

| pin | design | app after `b1137f3` |
|---|---|---|
| nest rim | 278 | 269 (−9) |
| hearts centre | 448 | 438 (−10) |
| progress bar top | 527 | 516.75 (−10.25) |
| first card top | 559 | 549 (−10) |
| meadow colour at (10, 600)/(10, 700), both themes | design RGB | off by the grade (band moved up 10 px) |

The shared commit also re-based K03's own pet-slot pins (278/364/301/448/559 →
269/355/292/438/549) with the note "screens must re-verify screenshots against
the design PNGs" — so the screen's own proof now ratified a 10 px shift. Those
pins are back on the design below.

## FIXES_11 item 1 — the bubble tail: fixed by shared code, verified here

`NestSpeechBubble`'s tail is now the CSS shape (solid 18×9 ink wedge, overflow,
laid-out box = body). The white-interior finding is closed. `kid_home_view_test.dart`
(the assertions `b1137f3` added) passes untouched.

I re-measured the tail against `design/screens/light/K03-kid-home.png` (PIL,
÷3) rather than trusting the shape alone, and there is a 3 px residual that is
*also* shared: CSS `bottom: -9px` resolves against the **padding** box, so the
design's wedge is 165…174 (base 18 wide at y 165, apex ≈174.5, bubble's bottom
border 166…168), while Flutter's `Positioned(bottom: -tailHeight)` resolves
against the **border** box, putting it at 170…179 on K03's 45-tall bubble. One
line fixes it (`bottom: -(tailHeight - borderWidth)`); filed as SHARED_REQUEST
**17b(b)** with the per-row ink runs. Zero layout impact, so it does not block.

## The layout fix (the only `app/lib` change)

`_kStageToHearts` 10.75 → **21** (`kid_home_view.dart`), the one lever K03 owns
between the shared pet stage and the hearts row. The design's arithmetic, now
written into the constant's doc comment:

```
.speech 125…169 (44)  +  .k3-pet margin 14  →  pet box 183…419 (236)
+ .scroll > * + * (s4 16)                      →  hearts row top 435, centre 448
```

The shared stage puts the bubble→pet gap at `NestSpacing.s2` (8) where the
design has 14, and paints the bubble 1 px taller, so its 236-tall block runs
178…414 — 5 px above the design's 419. 21 = the design's 16 + those 5 px. The
orchestrator's note sanctions this lever ("fix by sizing the NestPetStage box —
pipSize / nest width / bottom gap — not by negative margins").

Re-measured after the change, all pins green at the **design's** numbers:

| row | design | app now |
|---|---|---|
| hearts row centre | 448 | **448.0** |
| "Today's quests" row centre (32 px chip) | 494 | ✓ |
| progress bar | 527…542 | ✓ |
| first card top | 559 | ✓ (then +12 per card, painted gap 12) |
| card 2 peek above the dock | yes | ✓ |
| dock top / bottom | 720 / 844 | ✓ |
| meadow colour (10, 600) & (10, 700), light + dark | design RGB | ✓ (4/4) |

## Left for the shared component: the hero block is still 10 px high

The hero block (nest, Pip) cannot be fixed from K03: the shared explicit slot
is a fixed 236 px (`_explicitSlotH`) and the only shared knob between the
bubble and the scene is the 8 px gap. With `nestHeight: 188` the shared slot
puts the rim 91 px below the block top where the design's 260×236 `.nest` puts
it 95 px below — and growing `nestHeight` to move the nest down would paint a
taller bowl (the 198 × 86 outline pin fails), so there is no K03-side value
that reaches the design's rim. Measured deviation, now named in the pins
themselves: **rim 269 vs 278, Pip head 190 vs 199, Pip feet 292 vs 301**
(−9/−9/−9). Filed as SHARED_REQUEST **#18** with the full table and two
one-line options — (a) gap 8 → `NestSpacing.gap14`, (b) gap 14 **plus**
`_explicitBleed` 31.4 → 27.4 (recommended: every hero row within 1 px) — and
with K03's side of the revert written down (`_kStageToHearts` → `NestSpacing.s4`,
the four hero pins → 278/364/301/199).

I deliberately did **not** fork the composition locally (rendering
`NestSpeechBubble` myself above `NestPetStage(speech: null)`): both are shared
public components, but ORCHESTRATOR_NOTES 08:32 mandates passing `speech:` to
`NestPetStage`, and the 236-slot arithmetic says the correct answer is a shared
one anyway (the local best case, gap 13, still leaves the rim 4 px high).

## Test changes (`kid_home_geometry_test.dart`)

Shared `b1137f3` edited this screen's geometry file, so it had to be read
against the design rather than left as-is:

- pet slot: `rimY`/bowl bottom/feet keep the app's current rows (269/355/292)
  with the **design's** number and SHARED_REQUEST #18 in every `reason` —
  a pin that names the design cannot silently pass as "correct";
- pet slot: hearts 438 → **448**, card 1 549 → **559** (restored by the fix);
- the stale header table (which still listed 438/484/517/549 and described the
  tail shift as the new normal) rewritten to the design's rows, with an
  ITERATION 12 paragraph explaining exactly what moved and why.

No other test file touched. `kid_home_view_test.dart`, `k03_bugs_test.dart` and
`kid_home_bloc_test.dart` are unmodified — `grep skip:` is clean, so there was
no skipped bug test to un-skip (FIXES_11 references none).

## Owner / orchestrator rules re-checked

- **PIP** — unchanged: the child's own `PipAvatar` (Maya: Mochi · sunny · stage 3)
  through `NestPetStage(pip:)`, in the failure and empty states too.
- **STATUS BAR / DATA OVER MOCKS / PERIODS / CHILD ORDER** — untouched; no design
  number is hard-coded in the view.
- **BOTTOM EDGE (owner)** — untouched: the dock's `Container(color:
  tokens.surface)` wraps its `SafeArea(top: false)`, so the bar's surface runs
  from y 720 to the physical edge in both themes, no meadow/sky strip. The dock
  is bottom-anchored in a `Column`, so the 10.25 px shift never touched it.
- **ALIGNMENT (owner)** — 20 px gutters and the shared nest axis unchanged; the
  restored rows put every card back on the same edges (all card tops +12).
- **COPY / FONTS / LETTER SPACING / CHIP ROWS / BALANCED HEADINGS / SHAPES /
  TRIAL / ACCESSIBILITY ACTIONS** — no copy, font, chip or semantics touched. My
  change is a single layout constant plus its comment; the semantics tree,
  `SemanticsAction.tap` asserts and `NestBalancedText` title are as they were.

## Verification (in `app/`, this worktree)

- `dart format --set-exit-if-changed lib/features/kid_home/presentation
  test/features/kid_home` → 0 changed.
- `flutter analyze lib/features/kid_home test/features/kid_home` →
  **No issues found!**
- `flutter test test/features/kid_home/kid_home_geometry_test.dart` → **+6, all
  passed** (was 4 failures on arrival: both design-row tests + both light-theme
  meadow colour pins).
- `flutter test test/features/kid_home/` → **+185, all passed** (whole feature
  folder, so the change breaks neither the bloc nor any K03-BUG proof; the
  whole-app suite is the integrator's).
- No `analysis_options.yaml` change, no `flutter clean`, no simulator.

## LEFT FOR NEXT ITERATION

- **SHARED_REQUEST #18** (recommended option b) — the hero block's 9-10 px.
  Nothing local remains: revert instructions are in the view's `_kStageToHearts`
  doc comment and in the geometry pins' reasons.
- **SHARED_REQUEST #17b(b)** — the tail's 3 px padding-box offset. No layout
  impact.
- SHARED_REQUEST **#16(b)** (`_kQuestCardShadowRoom`) and **#6** (the sky's
  missing gradient stops, the last band-1-4 heat) are unchanged and still open.
- A fresh device UI check (stage 5) to re-measure the band table with the rows
  back on the design and confirm the new tail reads as a solid ink wedge.

VERDICT: PASS