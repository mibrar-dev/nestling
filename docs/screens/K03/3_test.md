# K03 Kid home — Stage 3 (TEST), iteration 12

Scope: `kid_home` / `/kid-home`, kid mode. Tests in
`app/test/features/kid_home/` (`kid_home_view_test.dart`,
`kid_home_bloc_test.dart`, `k03_bugs_test.dart`, `kid_home_geometry_test.dart`).
Per RULES §1 this stage only touched `app/test/features/kid_home/**` and
`docs/screens/K03/**` — **no screen code was patched, and no new bug was found,
so there is nothing new to record as a defect**.

**No simulator was booted, installed on or captured** (SIMULATORS rule: only the
UI-check stage may, and only `BC440E48-…`).

## Verification run (in `app/`, this iteration)

- `dart format --set-exit-if-changed .` → **381 files, 0 changed**.
- `flutter analyze` → **No issues found!** (`analysis_options.yaml` untouched, no
  new suppressions).
- `flutter test` (whole app) → **exit 0, `+1936 ~2`** — 1936 pass, 2 skip, 0 fail.
  Both skips are outside `kid_home` (onboarding P02, pocket-money P12).
- `flutter test test/features/kid_home/` → **exit 0, `+186 ~1`** — 186 pass,
  **1 skip** (the bugs stage's parked K03-BUG-16, see below), 0 fail.

| File | Iteration 11 | Now |
| --- | --- | --- |
| `kid_home_view_test.dart` | 89 | **89** |
| `kid_home_bloc_test.dart` | 31 | **31** |
| `k03_bugs_test.dart` | 59 | **59** (+1 parked proof from the bugs stage) |
| `kid_home_geometry_test.dart` | 6 | **7** (+1 from this stage) |

## What iteration 12 delivered (the surface under test)

1. **`shared/speech_tail` (main b1137f3)** turned the bubble's tail from a
   10.25 px **in-flow** box into a CSS `.speech::after` **overflow**
   (`NestSpeechBubble` is now a `Stack` with a `Positioned` tail). Correct in
   itself, but it removed 10.25 px from the pet stage's laid-out height.
2. **K03 absorbed it with `_kStageToHearts = 21`** (was 10.75) — the only lever
   the screen has, since the shared stage owns the bubble→pet gap. The rows
   below the nest are back on the design's numbers; the hero block is now ~10 px
   high (see "Known shared residual").
3. **The build moved the geometry pins to the current values** and put the
   design's number in every `reason` (rim `closeTo(269, 2)` "the design's rim is
   278 — 10 px high until SHARED_REQUEST #18"), so the pins hold the app where
   it is *and* document where it must go back to.
4. **The bugs stage added a parked proof, K03-BUG-16**, asserting the hero art
   against the design's rows (`flutter test --run-skipped --plain-name
   K03-BUG-16` → rim 269.02 vs 278).

## Tests added (this stage)

`kid_home_geometry_test.dart`, real Inter/Nunito, 390×844:

**`the speech tail is an out-of-flow 9 px ink triangle`**
- `NestSpeechBubble.height − body.height == 0` — **the tail must not size the
  bubble.** This is the contract K03's single compensation lever depends on: if
  the tail goes back in flow, the bubble grows 10.25 px, the block drops, and
  `_kStageToHearts = 21` over-compensates and pushes the whole column down.
- the tail's centre column is `tokens.ink` for **4…9 px** below the body's
  bottom border — `.speech::after` is `bottom: -9px` with a 9 px ink top
  border, and 5_ui iteration 9 measured the app's tail **10 px too tall**. The
  count is measured on the rendered bytes (the build's `RepaintBoundary` +
  `_pixelAt` harness), so "the tail is painted, and no taller than the design"
  is a pixel fact, not a comment.

## Results — measured rows at real fonts (390×844, light)

| row | measured | design | Δ |
| --- | --- | --- | --- |
| speech bubble | 125…170 (45 tall) | 125…169 (44) | +1 (own band's tolerance) |
| **pet slot (hero block)** | **178…414** | **183…419** | **−5 (high)** |
| nest rim (box × 95/240) | **269.02** | 278 | **−8.98** |
| bowl bottom | 355 | 364 | −9 |
| Pip feet (box − 21.2) | **292.02** | 301 | −8.98 |
| hearts row centre | **448.00** | 448 | **0.00** |
| section row centre | 493.8 | 494 | −0.2 |
| progress bar | 526.8…542.8 | 527…542 | −0.2 / +0.8 |
| card 1 painted top | 558.8 | 559 | −0.2 |
| cards 2…6 painted tops | 658.8 · 758.8 · 858.8 · 958.8 · 1062.8 | 12 px painted gaps | 0.0 each |
| dock painted top | 719.0 | ≈720 | −1.0 |

Everything **below** the hero block is inside the ±2 px band, including all six
card tops and the dock. The hero block is 9 px high (the shared gap 8 vs the
design's 14, SHARED_REQUEST #18), which the build's pins hold and the bugs
stage's parked proof fails on.

All 186 runnable K03 tests pass; nothing else moved (layout matrix light + dark ×
320/390/430 × 1.0/1.3, layout invariants on painted rects, PERIODS, bottom-edge
and alignment owner rules, navigation, labels, tap targets, the accessibility
matrix, the PipAvatar mandate and its bowl seat, the completion/celebration
state machine, the shapes group, quest order).

## Bugs found

**None new.** No test I added or inherited failed, and no K03 code misbehaved.

### Known shared residual (already filed twice — not a new finding)

**The hero art sits ~9 px above the design's rows.** Measured above: rim 269.02
vs 278, bowl bottom 355 vs 364, Pip feet 292.02 vs 301. Cause: the shared
`NestPetStage` lays the bubble→pet gap out as `NestSpacing.s2` (8) where the
design's `.k3-pet` has `margin: 14px auto 0` — **SHARED_REQUEST #18**, named in
the geometry pins' reasons and in the bugs stage's K03-BUG-16. K03 cannot edit
`core/` (RULES §1), and the screen's only lever is the gap *below* the nest,
which is exactly what `_kStageToHearts = 21` now carries (and which the build
documents reverting to `NestSpacing.s4` when #18 lands). The UI VERDICT RULE's
±2 px judgement on this belongs to the UI-check stage; from the test side it is
already pinned on both sides — the build at the current values, the bugs stage as
a parked proof at the design's values, and my new tail pin at the contract that
would otherwise make the compensation silently wrong.

## Owner rules re-checked

- **BOTTOM EDGE:** the K03-BUG-10 proofs (light + dark, 34 px inset) pass; the
  real-font dock pin re-confirms the painted surface runs 719 → 844 in one
  piece, and the tail change did not move it.
- **ALIGNMENT:** gutters and shared card/bar/dock edges pass; the pet slot is on
  the axis at 320/390/430 with no clipping; dock labels cannot wrap; the six
  cards keep 12 px painted gaps.

## Rule coverage

| Rule | Status on K03 |
| --- | --- |
| PIP | Mandated `PipAvatar` in every state, seated in the bowl (feet 23 px below the rim) — **its row is the shared residual above** |
| UI VERDICT RULE | Every row below the hero pinned within ±2 px at real fonts; the hero's 9 px delta is measured, named and pinned on both sides |
| BOTTOM EDGE / ALIGNMENT | Proven by tests (above) |
| PERIODS + DATA OVER MOCKS | Counts from the DB; daily/weekly/once + new-period proofs green; quest order pinned as documented |
| COPY | Re-verified against the HTML source (straight apostrophes, en dash, middle dot) |
| FONTS / LETTER SPACING | No `google_fonts`; every rendered string asserts `letterSpacing == 0` |
| CHIP ROWS (`NestChipWrap`) | Not applicable: K03's chips are the non-interactive `KidStatusChip` |
| UI CHECK MEASURES SHAPES | Painted rects, pixel bytes (meadow grade **and** the new tail), outline/feet geometry, chip/tile/check/bubble boxes |
| BALANCED HEADINGS | The only `.kid-title` heading renders through `NestBalancedText` |
| ACCESSIBILITY ACTIONS | Iteration 9's matrix still green (tap action on every control, real effect, none on non-controls) |
| CHILD ORDER | No child list here; pinned at the repository level (K03-BUG-12) |
| TRIAL | No test writes `subscription_status` |
| SIMULATORS | None booted by this stage |

## Harness notes (carry forward)

- **Font-load timing is NOT a geometry factor here.** The plausible explanation
  for the 269-vs-278 disagreement (fonts loaded in `setUpAll` vs inside the test
  body) was measured and ruled out: all three configurations — fonts in
  `setUpAll`, fonts inside the body, and with the bottom inset emulated — give
  the identical rows (rim 269.02, feet 292.02, hearts 448.00). The 9 px is the
  screen's, not the harness's.
- `.speech::after` geometry to keep in mind: `bottom: -9px; left: 50%; border:
  9px solid transparent; border-top-color: ink; border-bottom: 0` → an 18 px
  wide, ≤9 px tall ink triangle hanging below the body, now painted out of flow.
- The design's outline fractions are asymmetric (the bowl starts 95/240 down its
  box, height 110/240) and the v2 Pip's feet sit 21.2 px above the bottom of its
  152 px box; `PipNestFallback.nestRimTopFraction` is 95/240.
- The design's arithmetic, for reference: 125 + 44 bubble + 14 (`.k3-pet`
  margin) = pet box 183…419, then `s4` 16 → hearts row 435, centre 448.
- Offstage cards have **no semantics node**; scroll a control into view before
  asserting or performing its semantics action. `pushedPath`, not `currentPath`,
  for `push`ed routes. The design source uses a **straight** apostrophe.
- Direct Drift work inside `testWidgets` must run inside `tester.runAsync`; never
  `pumpAndSettle` while a loading spinner is on screen; seed the DB before
  pumping the route.

VERDICT: PASS
