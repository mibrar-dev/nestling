# P02 Value tour — test notes (Stage 3, iteration 2)

Route `/value-tour`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/` and use the in-memory Drift DB through
`setUpTestScope()` (`Seed.demo` default, `Seed.empty`/`Seed.fresh`) plus the
shared `disposeApp()` drain. No screen, bloc, route or design-system code was
changed by this stage.

Iteration 2 ran against the **iteration-2 build** (pager back to the spec
400dp, `ValueTourPreviewRow`, unified scrollable, derived payout chip,
`PopScope`, 60px `_TourNav`). All 108 pre-existing tests still pass unchanged
— including the 9 un-skipped proofs in `p02_bugs_test.dart` — so the rebuild
introduced no regression. This iteration adds the two **new owner rules**
(BOTTOM EDGE, ALIGNMENT) as enforced tests.

## Tests added this stage

`app/test/features/onboarding/value_tour_view_test.dart` — 51 → **61 tests**
(10 added). New shared helpers: `_pumpTourForPixels()` (pumps the real app
inside a `RepaintBoundary`, optional OS bottom inset), `_pixelAt()` (samples
painted RGBA bytes via `RenderRepaintBoundary.toImage()`), `_rgba()`.

### Owner rule — BOTTOM EDGE (4 tests, mandatory)

The area below the bottom bar down to the physical screen edge must carry the
**same surface colour as the bar**; a page-colour strip fails the screen in
light and dark alike. The 34dp inset case is where a strip would appear, so it
is the load-bearing case.

- `light` / `dark`: **no page-colour strip under the CTA panel** — with a
  34dp OS inset, asserts the `NestBottomCta` panel's rect ends exactly at the
  physical bottom (844), then samples the actual painted pixel at y=843 and
  requires it to equal the `surface` token byte-for-byte. The test also
  asserts `paper != surface` so the probe provably discriminates and cannot
  pass vacuously. This is a true painted-pixel check, not a token
  re-statement: it fails if the Scaffold's paper shows through below the bar.
- `light` / `dark`: **bar surface is flush with the edge, inset 0** — the
  no-inset baseline, same pixel assertion.

Result: the shared `NestBottomCta` (now a `DecoratedBox` wrapping the
`SafeArea`, `nest_bottom_cta.dart:19-24`) runs the surface to the physical
edge, so P02 passes in both themes with and without an inset.

### Owner rule — ALIGNMENT (6 tests, mandatory)

- `light`/`dark` × **320/390/430dp**: **20px gutters on every edge** — the
  step-copy title, the `Next` button and the tour card all start at
  `NestSpacing.padSide` (20); the `Next` button and the `Skip` action both end
  at `width - 20`; the CTA panel is full-bleed (0 … width) as the
  bottom-edge rule requires; the card keeps the design's clipped peek
  (`20 + min(310, max(240, w - 80))`, so its right edge is intentionally *not*
  the gutter and is asserted against the clamp instead). `takeException()` is
  null, so no misalignment is being traded for an overflow.
- **card content shares one inner left edge** — head text, all 4
  `ValueTourPreviewRow`s, the progress bar and the dashed add-row start on the
  same `card.left + s4` edge. (Row *titles* sit further in behind their 36dp
  icon tile, so the row container — not the title text — is the reference;
  asserting on the title was a wrong-assertion bug in this stage's first
  draft, caught and fixed before it could mask anything.)

## Existing coverage re-verified (not duplicated)

- `onboarding_bloc_test.dart` (11 tests) still covers every event/state path of
  the single-event bloc: initial; loading → loaded on Drift; live
  multi-emission stream; empty stream; failure; plus repository
  `watchItems`/`getItems` and `Seed.demo`/`empty`/`fresh` persistence.
- `p02_bugs_test.dart` (9 proofs) covers P02-BUG-1a/b/c (pager 400dp, no copy
  clipping, short screens), BUG-2 (38dp rows), BUG-3 (375×667 / 320×568
  scroll cleanly), BUG-4 (seeded assignee/repeat), BUG-5 (chip weekday vs its
  own date), BUG-6 (system back → `/welcome`).
- `p01_bugs_test.dart` BUG-3b covers the kid-mode gate for `/value-tour`.
- Contract file: 18-combo width × scale × theme matrix, light/dark copy,
  5-state bloc matrix, `Seed.empty`/`Seed.fresh` routes, PipAvatar rule (4
  avatars, mochi/sunny, stages [3,1,2,3]), pager geometry + card content,
  pager controls, navigation (Skip/Continue/Next/dot/row), a11y (group + dots
  labels, 44dp/52dp tap targets, no icon or kid controls, add-row labels),
  dark tokens, data independence.
- Tap-target rules: Skip ≥44, Next/Continue ≥52; no `NestKidButton`, so the
  ≥56dp kid rule is vacuously satisfied on this parent screen.

## Results (run by this stage, `app/`)

- `dart format .` — 349 files, 0 changed on final pass.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **119 passed, 0 failed, 0
  skipped**.
- `flutter test` (full suite) — **443 passed, 0 failed, 0 skipped**.

## Bugs found

**None.** No screen code was patched.

One wrong assertion in this stage's own first draft of the alignment test
(comparing preview-row *title* text against the card's inner edge, which the
36dp icon tile legitimately offsets) was corrected before the suite was run;
it was a test bug, not a screen bug.

Carried observations (unchanged, non-blocking, no user impact):

- The route-level `BlocProvider<OnboardingBloc>`
  (`app/lib/features/onboarding/onboarding_routes.dart:36-40`) is lazy and the
  static tour never reads it, so the `OnboardingLoadRequested` added inside
  `create` does not run on route entry — only on the first read. Pinned
  deliberately by the "route provides a working bloc" test. P01's plan marks
  the route "Do not change"; P01/P02 display none of `items`.
- `SHARED_REQUEST.md` items 1–3 (compact nav-bar wide action, shared compact
  preview-row variant, pager-metric tokens) remain open and non-blocking; P02
  ships `_TourNav` and `ValueTourPreviewRow` behind `TODO(P02)` until they
  land.

VERDICT: PASS
