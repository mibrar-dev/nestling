# P02 Value tour — build notes (Stage 2, iteration 1)

Implemented per `docs/screens/P02/1_plan.md`. Placeholder replaced with the
static 3-card pager; no BLoC/repo changes (plan §b: copy mirrors
`OnboardingRepositoryImpl._steps` verbatim, pager index is local state).

## Files changed

- `app/lib/features/onboarding/presentation/views/value_tour_view.dart`
  (rewrite): `ValueTourView` (stateful: `_page` + `PageController`), pager
  (`PageView.builder`, fraction `pitch / (viewportW − 20)`, left inset 20,
  `padEnds: false`), `_TourNav` (52px bar, right-aligned Skip, 44px tap box,
  `TODO(P02)`), `_QuestPreviewCard` (4 × `NestListRow` compact + small coin
  pills, `NestProgress` 4/6, dashed "New quest"), `_PipPreviewCard`
  (`PipAvatar` mochi/sunny stage 3 in 158 box + 3 stage dots + 0.7 progress,
  dashed "Next stage: Songbird"), `_JarPreviewCard` (`NestMoney` £4.20,
  3 ledger lines, dashed "No bank card needed"), `_DashedAddRow` (1.5px
  dashed `line` border via `_DashedBorder`, non-interactive), dots/title/body
  below, `NestBottomCta` with Next (`p02_next`) → Continue (`p02_continue`).
  Skip/Continue → `context.go(AuthRoutePaths.createAccount)`; Next uses
  `nextPage` (300ms easeOut) or `jumpToPage` under reduced motion.
- `app/test/features/onboarding/value_tour_view_test.dart` (new, 29 tests):
  copy/themes, 18-combo width×scale matrix, Pip rule, pager behaviour
  (taps/swipe/reduced-motion), navigation (incl. Next-tap and row-tap stay),
  5-state bloc matrix via direct pump, a11y (header, pager group label,
  button semantics, ≥44/≥52 tap targets, no kid controls).
- `docs/screens/P02/SHARED_REQUEST.md`: already present (written stage 1);
  `_TourNav` ships behind the `TODO(P02)` comment as required. No new
  shared requests; nothing outside RULES §1 touched.

## Deviations from 1_plan §a (all measured, all documented in code)

1. **Pager base 400 → 468.** Plan assumes 56px compact rows; `NestListRow`
   compact rows are really 60px (56 min-height loses to 22px title + 18px
   subtitle + 20px row padding), so card 1 needs 444px. Plus two measured
   facts: `Container` folds a decoration border into effective padding (the
   1.5px-bordered chips are 35px, not 32 — verified by render-tree probe) and
   the widget-test fallback font wraps the 26-char caption to two lines
   (+18). Tallest measured content is 465px → base 468. All plan spacings and
   components kept; cards 2–3 absorb the extra via `Spacer`. Screen still
   fits 390×844 (scroll region absorbs 3px of bottom padding). Screenshot
   drift: pager band +68px vs design.
2. **Left inset via outer `Padding`** (`PageView` has no padding slot):
   fraction divides by the inset viewport so cards still span exactly
   `20 + pitch·i … +cardW` with a 48px peek at 390/320.
3. **Controller from `MediaQuery` in `didChangeDependencies`** instead of a
   `LayoutBuilder` (identical value — the pager is full-bleed — and safe
   controller lifecycle across width changes).
4. **`container: true` on the Skip button node, the Pip artwork node, and
   (as planned) the pager group node.** Probe finding: sibling text merges
   into one node and an `image` flag splits off label-less; `container: true`
   keeps exact labels. The Skip `Text` is additionally `ExcludeSemantics`
   (announced once by the button node — avoids a `Skip\nSkip` merge).
5. **Ledger amounts use `NestType.money` as-is** (16px vs 15px rows — same
   accepted 1px-drift class as the plan's noted title drift).

## Verification (in `app/`)

- `dart format .` — clean (0 changed on final pass).
- `flutter analyze` tail: `No issues found!`
- `flutter test test/features/onboarding/value_tour_view_test.dart` tail:
  `00:02 +29: All tests passed!`
- `flutter test` (full) tail: `00:08 +402: All tests passed!`

VERDICT: PASS
