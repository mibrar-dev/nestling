# P01 Welcome — test notes (Stage 3, iteration 1)

Route `/welcome`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`. All pumping tests use the in-memory Drift DB
through `setUpTestScope()` (`Seed.demo` default, `Seed.empty`/`Seed.fresh`
where the case needs them) and the shared `disposeApp()` drain.

## Tests added

### `app/test/features/onboarding/onboarding_bloc_test.dart` — new, 11 tests

OnboardingState:

1. `copyWith` replaces only the given fields.
2. equality + hashCode driven by status/items/errorMessage.

OnboardingBloc (`blocTest`, every event/state path):

3. starts `initial`, no items, no error.
4. `OnboardingLoadRequested` on the Drift-backed repository →
   `loading` → `loaded` with the 3 static tour cards (exact items).
5. live repository stream (two emissions) → `loading` → `loaded` →
   `loaded` (second item set) — pins the `emit.forEach` subscription path.
6. empty repository stream → `loading` → `loaded` with no items.
7. repository stream error → `loading` → `failure` with `errorMessage`.

OnboardingRepository over in-memory Drift:

8. `watchItems`/`getItems` return exactly the 3 tour cards (Seed.demo).
9. `Seed.demo` has `onboardingComplete == true`.
10. `Seed.empty` is onboarded with no children.
11. `Seed.fresh` starts `false`; `completeOnboarding()` flips
    `watchComplete()` to `true`.

### `app/test/features/onboarding/welcome_view_test.dart` — extended, 29 tests

Copy/theming:

1. light @390: `9:41`, headline, body, both CTA labels, footer caption,
   Pip semantics label, no `NestIconButton`, no exception.
2. dark @390: same content, no exception.

Width × text-scale matrix (12 tests): {light, dark} × {320, 390, 430}dp ×
text scale {1.0, 1.3} — all copy present, `takeException()` null (catches
RenderFlex overflow). The app's 1.0–1.3 text-scaler clamp is exercised.

Seeds:

15. `Seed.empty` (onboarded parent, no children) still renders P01.
16. `Seed.fresh` + pump `/today` → redirect lands on the real P01 headline.

BLoC states (content is static for every status):

17. `initial` — content renders before the load event.
18. `loading` — content renders while no items have arrived.
19. `loaded` with no items — full brand screen.
20. `loaded` with the 2 scripted tour cards — cards do not alter P01.
21. `failure` — repository error never blocks the brand screen, and
    `errorMessage` is populated.

Navigation (asserted against the live `GoRouter` location, not placeholder
titles):

22. `Get started` → `/value-tour`.
23. `I already have an account` → `/create-account`.

Accessibility:

24. CTA semantics: labels found, `getSemantics(...).flagsCollection.isButton`
    true for both; Pip artwork carries the HTML alt text; status-bar `9:41`
    is excluded from semantics; no icon-only buttons (`NestIconButton`) and
    no kid controls (`NestKidButton`); CTA hit boxes are 350×52 at 390dp
    (≥44 parent rule and ≥52 spec min-height); kid ≥56 rule N/A on this
    parent screen.
25. Tap targets still ≥44 high and full-width at 320dp, text scale 1.3.

Bug regression tests:

26–29. `scene frame is painted in full (no crop) at {320, 360, 390, 430}dp`
— pumps `/welcome`, locates the scene `RenderStack` and asserts
`describeApproximatePaintClip(sceneStack.firstChild!)` is null. 390/430 pass;
**320 and 360 fail — real bug, details below.**

## Results

- `dart format .` — 340 files, 0 changed (clean).
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **38 passed, 2 failed** (40):
  the two failures are the 320dp/360dp bug regressions below (expected).
- `flutter test` (full suite) — **324 passed, 3 failed** (327): the two P01
  bug regressions plus the pre-existing shared placeholder assertion
  (below).

## Bug found — NOT patched (stage-3 rule)

### BUG-1: P01 scene crops its content at 320/360dp instead of scaling it

**Where:** `app/lib/features/onboarding/presentation/views/welcome_view.dart:91-104`
(`_WelcomeScene` LayoutBuilder). The outer `SizedBox(width: 350 * scale,
height: 388 * scale)` hands **tight** constraints to `Transform.scale`, so
the inner `SizedBox(width: 350, height: 388)` is constrained down to
280×310.4 at 320dp *before* the 0.8 paint scale. The Stack therefore lays out
350×388 design coordinates in a 280-wide frame and clips the overflow, then
the whole already-cropped box is scaled by 0.8 — the right ~20% of the scene
is lost, and the painted frame is only 224pt wide (empty band at right).

**Repro:**

```
cd app
flutter test test/features/onboarding/welcome_view_test.dart --plain-name 'no crop'
```

or pump `/welcome` on a 320×844 surface and inspect the scene `RenderStack`:

- 320dp: Stack size 280×310.4, `describeApproximatePaintClip` →
  `Rect.fromLTRB(0.0, 0.0, 280.0, 310.4)`; painted clip ends at x≈244.
  - top-right coin (design `left: 308, width: 34`) painted rect
    ≈ `LTRB(270.7, 149.4, 289.3, 183.0)` → **entirely outside the clip,
    invisible**;
  - nest painted right edge ≈265.6 → ~22pt cropped;
  - leaf-tint circle painted ≈32..288 → ~44pt cropped (should span the full
    content width).
- 360dp: Stack 320×354.7, clip non-null; coin painted `LTRB(306.5, …,
  327.8, …)` vs painted clip ending at ≈312.6 → only a thin sliver visible.
- 390/430dp: Stack 350×388, `describeApproximatePaintClip` → `null` (pass).

**Impact:** on narrow portrait devices (<390pt, e.g. iPhone SE 1st/2nd gen at
320, some 360 Android) the illustration loses the top-right floating coin
entirely and crops the nest/circle, while leaving a dead band on the right —
not the "scale down, nothing overflows" behaviour required by plan §a /
SPACING_SPEC §10.2.

**Suggested fix (build stage):** keep the 350×388 design frame laid out at
full size and scale only the paint, e.g. `SizedBox(350 * scale, 388 * scale,
child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.topLeft,
child: SizedBox(width: 350, height: 388, child: Stack(…))))`, or wrap the
inner frame in `OverflowBox(minWidth: 350, maxWidth: 350, minHeight: 388,
maxHeight: 388, alignment: Alignment.topLeft)` before the `Transform.scale`.
The 390/430 paths must stay pixel-identical (scale 1).

**Failing tests:** `welcome_view_test.dart` group
`P01 welcome — bug regressions` (lines 483–508); assertion at lines 502–503.

## Shared-suite issue (not a P01 bug)

`app/test/app/router_redirect_test.dart:20` still asserts
`find.text('P01 Welcome')`, the foundation placeholder. Already filed in
`docs/screens/P01/SHARED_REQUEST.md` (stage 2); outside §1 edit scope. The
redirect itself is verified by test 16 (`Seed.fresh` → `/today` → real P01).

## Harness note (not a product bug)

`bloc.close()` on a bloc with a pending `emit.forEach` over a
`StreamController`-backed stream deadlocks under the widget-test
fake-async zone (isolated with temporary probes, now deleted; plain-async
tests close fine). The loading-state widget test therefore uses an
immediately-completing empty stream (state stays `loading`) — the
pending-stream state path is covered by `blocTest` in
`onboarding_bloc_test.dart`.

VERDICT: FAIL
