# P02 Value tour — test notes (Stage 3, iteration 1)

Route `/value-tour`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/` and use the in-memory Drift DB through
`setUpTestScope()` (`Seed.demo` default, `Seed.empty`/`Seed.fresh`) plus the
shared `disposeApp()` drain. No screen/bloc/route code was changed by this
stage.

## Tests added this stage

`app/test/features/onboarding/value_tour_view_test.dart` — 29 → **49 tests**
(20 added, in the groups below).

### Route wiring and Drift seeds (3)

- **Route provides a working bloc whose load reaches loaded** — pumps
  `/value-tour` through the real app, reads the route-level `BlocProvider`,
  asserts the state machine reaches `loaded` with the three steps. The
  comment pins the observed lazy-provider behaviour (see Observations).
- **`Seed.empty`** (onboarded parent, no children): identical tour renders.
- **`Seed.fresh`** (nothing): `/value-tour` stays put (it is an onboarding
  location, so no welcome redirect) and renders the full step 1.

### Pager geometry and card content (9)

- Width **320/390/430**: the visible card spans exactly
  `left 20 … +min(310, max(240, w − 80))` and the next card peeks one pitch
  (`cardW + 12`) later — pins the plan §a clamp + clipped-peek rule.
- **Card 1**: 4 preview rows (two 'Maya · weekly', 'Leo · once',
  'Maya · daily'), coin pills `['15','15','10','15']`, progress 4/6,
  '4 of 6 quests done today', non-interactive 'New quest' (no semantics).
- **Card 2**: 'Fledgling' chip `selected: true`, `175 of 250 coins · Pip
  evolves at 250`, progress 0.7, 'Next stage: Songbird'.
- **Card 3 ledger** matches `Seed.demo`: 'Weekly base £3.00', 'Quests (120
  coins) +£1.20', 'Total £4.20' (×2 counting the headline), 'coming on
  Saturday', 'No bank card needed'.
- **Steps 2–3 hold at 320dp × text scale 1.3** (dark) with no overflow.
- **Pager height** is 468dp at scale 1.0 and 468×1.3 at 1.3 (plan §a
  `pagerH = base × ts` scale rule).

### Pager controls (3)

- **Dots are non-interactive**: tapping them neither pages nor navigates.
- **Swipe to step 3** swaps the CTA to `p02_continue`; tapping it lands on
  `/create-account` (covers the `onPageChanged` path, not just Next taps).
- **Swipe back at step 1** stays clamped, no route change.

### Accessibility extensions (4)

- Pager group label 'Tour preview, step N of 3' and the built-in
  `NestPagerDots` 'Page N of 3' follow the page; no 'Go to page N' labels
  (dots are indicators, matching the HTML's plain spans).
- Status bar reserves exactly 47dp, home indicator is 0dp in-app
  (P01 BUG-2 contract), and there is no `BackButton`.
- **Continue**: full width (350dp at 390), ≥52dp tall, semantics label
  'Continue' + `isButton`.
- **Dark mode**: card surface colour equals the dark token surface and
  differs from the light token (proves the token wiring, not hard-coded
  colours).

### Data independence (1)

- **Late repository emissions never change the copy** — a second item list
  arriving after load leaves the static marketing copy untouched.

## Coverage notes (existing tests, not duplicated)

- `onboarding_bloc_test.dart` (11 tests, unchanged) already covers every
  event/state path of the single-event bloc: initial; loading → loaded on
  Drift; live multi-emission stream; empty stream; failure; plus repository
  `watchItems`/`getItems` and `Seed.demo`/`empty`/`fresh` persistence.
- `p01_bugs_test.dart` BUG-3b already proves kid mode gates `/value-tour` to
  `/parental-gate`.
- P02 has no icon-only buttons: the existing a11y test asserts
  `NestIconButton`/`NestKidButton` are absent, so the "semantics labels on
  icon buttons" and ≥56dp kid tap-target rules are satisfied (no kid
  controls on this parent screen).
- The Stage 2 width × scale × theme matrix (18 combos) still runs unchanged,
  as do the light/dark copy tests, the 5-state bloc matrix, the PipAvatar
  rule (4 avatars, mochi/sunny, stages [3,1,2,3]) and the Skip/Next
  navigation tests.

## Results (run by this stage, `app/`)

- `dart format .` — 346 files, 0 changed on final pass.
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **98 passed, 0 failed, 0
  skipped**.
- `flutter test` (full suite) — **422 passed, 0 failed, 0 skipped**.

## Bugs found

**None.** No screen code was patched.

Observation (non-blocking, pre-existing; *not* a P02 defect): the
route-level `BlocProvider<OnboardingBloc>`
(`app/lib/features/onboarding/onboarding_routes.dart:36-40`) is lazy, and
the static tour never reads it, so the `OnboardingLoadRequested` added
inside `create` does not run on route entry — it only runs at the first
read. Repro is pinned by the "route provides a working bloc" test: state is
`initial` until a read, `loaded` after. No user-visible impact: P02's copy
is view-local and data-independent by design, P01/P02 display none of
`items`, and the P01 plan marks this route "Do not change". Flagged only in
case eager preloading is ever needed (orchestrator decision).

Also unchanged from Stage 2: the pager base height is 468dp (not the
design's 400) per the measured deviation documented in `2_build.md`; the
screenshot +68dp pager-band drift is untouched by this stage.

VERDICT: PASS
