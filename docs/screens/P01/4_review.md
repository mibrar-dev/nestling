# P01 Welcome — QA code review (Stage 4, iteration 1)

Scope: `git diff main` (working tree; `main...HEAD` is empty — the P01 work
is uncommitted) = `app/lib/features/onboarding/presentation/views/welcome_view.dart`
(rewritten, +231/−42) plus untracked
`app/test/features/onboarding/{welcome_view_test.dart,onboarding_bloc_test.dart}`
and `docs/screens/P01/**`. No code was edited during this review.

## Verification run by this stage (all first-hand, `app/`)

| Check | Command | Result |
|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed .` | 340 files, 0 changed — clean |
| Analyze | `flutter analyze` | `No issues found!` (3.2s) |
| Feature tests | `flutter test test/features/onboarding` | **38 passed, 2 FAILED** |
| Full suite | `flutter test` | **325 passed, 2 FAILED** |
| Shared redirect test | `flutter test test/app/router_redirect_test.dart` | **6/6 passed** (contradicts stages 2 & 3 — see finding 2) |
| Isolation | `git diff main --stat` / `git status -uall` | only RULES §1 paths touched |

The two failures are the 320dp and 360dp "scene frame is painted in full (no
crop)" regression tests, i.e. a real product defect that P01's own committed
test already catches (finding 1).

---

## Findings

### 1. BLOCKER — the illustration scene is **cropped, not scaled**, below 390dp; the feature test suite is red

**Where:** `app/lib/features/onboarding/presentation/views/welcome_view.dart:91-104`
(`_WelcomeScene` `LayoutBuilder`), offending constraints at
`welcome_view.dart:94-102`; `Stack` at `welcome_view.dart:103`.

The outer `SizedBox(width: 350 * scale, height: 388 * scale)` hands **tight**
constraints down to `Transform.scale`, and `RenderTransform` lays its child out
with those *unmodified* constraints. So the inner `SizedBox(width: 350, height:
388)` is already squeezed to `280×310.4` at 320dp **before** the 0.8 paint
scale, and the `Stack` (default `clipBehavior: Clip.hardEdge`) silently crops
every `Positioned` child that no longer fits — then the already-cropped box is
scaled again, leaving a dead band on the right. 390/430dp (`scale == 1`) are
pixel-correct, which is why the crop is invisible in the reference design.

Measured by P01's own regression test (verified failing here):
`320dp` → Stack `280×310.4`, `describeApproximatePaintClip` non-null; the
top-right coin (design `left: 308, width: 34`) paints at `LTRB(270.7 …289.3)`
— **entirely outside the clip, invisible**; nest right edge cropped ~22pt;
leaf-tint circle cropped ~44pt instead of spanning the content width.
`360dp` → the same coin shows only a sliver.
This violates plan §a / SPACING_SPEC §10.2 ("scale down, nothing overflows")
and makes `flutter test` fail, which is RULES §7.1's gate.

**Concrete fix** (minimal diff — the 390/430 path stays byte-identical because
`scale == 1`): replace the inner `SizedBox` at `welcome_view.dart:100-102`
with an `OverflowBox` so the Stack is always laid out at its full 350×388
design size and only the *paint* is scaled:

```dart
child: Transform.scale(
  scale: scale,
  alignment: Alignment.topLeft,
  child: OverflowBox(
    minWidth: _frameW,
    maxWidth: _frameW,
    minHeight: _frameH,
    maxHeight: _frameH,
    child: Stack(children: <Widget>[ /* unchanged 350×388 design coords */ ]),
  ),
),
```

Equivalent alternative the stage-3 notes suggested (also fine, and it makes the
outer `SizedBox` redundant): `FittedBox(fit: BoxFit.scaleDown,
alignment: Alignment.topLeft, child: SizedBox(width: 350, height: 388,
child: Stack(...)))`. Either way the two "no crop" tests at
`welcome_view_test.dart:484-515` must go green, and 390/430 must remain
unchanged. Do not silence or skip those tests.

### 2. MAJOR — the shared-suite failure is fictional; `SHARED_REQUEST.md` asks the orchestrator to edit a healthy test

**Where:** `docs/screens/P01/SHARED_REQUEST.md:1-13`, repeated in
`docs/screens/P01/2_build.md:31-36` and `2_build.md:45-50`, and in
`docs/screens/P01/3_test.md:145-150`.

All three claim `app/test/app/router_redirect_test.dart:20` asserts
`find.text('P01 Welcome')` (the placeholder title) and therefore fails. It does
not: that line asserts `expect(currentPath(tester), '/welcome')` — a
**route-location** check, and `test/test_scope.dart:62-67` documents it as
deliberately screen-agnostic ("so redirect tests keep passing when a
placeholder view is replaced by the real screen"). Verified here:
`flutter test test/app/router_redirect_test.dart` → `All tests passed!` (6/6),
and the full suite is `325 passed, 2 failed` — both failures P01-owned.

**Impact:** the orchestrator batches SHARED_REQUESTs onto `main` across 30
parallel waves. Filing a request against a passing test invites a change that
turns a screen-agnostic redirect assertion into a P01-specific text
assertion — a regression in the shared suite caused by this screen's paperwork.

**Fix:** delete `docs/screens/P01/SHARED_REQUEST.md` (no shared change is
needed — RULES §1 was respected and nothing is blocked) and record the
correction in the next iteration's build/test notes so the stale numbers
("292/293", "324/327") stop propagating. If a request is genuinely wanted
later, it must cite a reproducible failure.

### 3. MINOR — the coins' `--sh-1` shadow is clipped by the `Stack`, which the HTML does not clip

**Where:** `welcome_view.dart:103` (the `Stack`, default
`clipBehavior: Clip.hardEdge`) with the coins at `welcome_view.dart:143-172`.

`design/html-source/screens/P01-welcome.html:15-25` puts `box-shadow: var(--sh-1)`
on absolutely positioned images inside `.scene`, and `.scene` has no
`overflow: hidden` — so the shadow may paint outside the 350×388 frame.
Rotating the coins grows their bounding boxes: `c3` (36px @22°) reaches
`x ≈ 1.6` and `c2` (34px @16°) reaches `x ≈ 346` of a 350 frame, while
`--sh-1` (`shadows.dart:18-20`) blurs 4px per side (+2px y-offset). Result:
1–4px of shadow cut on the left and right, which is far more visible in dark
(`black@40%`) than light (`ink@6%`).

**Fix:** `Stack(clipBehavior: Clip.none, children: …)`. The overflow then paints
into the 20pt side padding, exactly as the HTML does. Do this **after** finding 1
(finding 1's own crop must not be "fixed" by turning the clip off — the crop
comes from layout, not from the clip) and re-check the 320dp band in stage 5.

### 4. MINOR — the five first-frame SVGs are never pre-cached, on the very screen the asset manifest names

**Where:** `welcome_view.dart:117-172` (5 × `SvgPicture.asset`),
`app/lib/core/design_system/assets/nestling_assets.dart:530-556`.

`NestlingImages.precache` exists precisely for this ("Pip, the nest and the coin
are on screen on the very first paint (**P01** …) so decoding them lazily causes
a visible hitch"), but (a) `grep -rn precache app/lib` finds only the doc
comment — nothing calls it — and (b) the list holds the **webp rasters**
(`assets/images/*.webp`), while every widget in `app/lib` renders the **SVG**
paths via `NestlingIllustrations`. So the documented warm-up warms assets no
screen draws, and P01's nest (264²), Pip (168²) and 3 coins decode lazily on
the app's first frame.

**Fix:** SHARED_REQUEST (shared path, `core/**` / `app/**` — P01 must not
edit it): wire the pre-cache into the app shell and add the SVG paths using
`precachePicture` (flutter_svg), not `precacheImage`. The same request can
cover finding 8.

### 5. MINOR — scene geometry hard-codes `350` where the token exists, and the 19 design literals are unanchored

**Where:** `welcome_view.dart:93, 100-101, 105-172`.

Every other dimension on the screen comes from a token (`NestSpacing.*`,
`NestDevice.statusH/homeH`, `NestType.*`, colour tokens) — colours and fonts are
100% token-driven, which is correct. The scene is the one exception, and it is
defensible (it is artwork geometry, not UI spacing), but `NestDevice.width`
exists and `nestling_assets`/`spacing.dart:36-38` explicitly ask for
`NestDevice.width - NestSpacing.padSide * 2` rather than a bare 350.

**Fix:** introduce `static const double _frameW = 350.0;` /
`_frameH = 388.0;` (or derive `_frameW` from
`NestDevice.width - NestSpacing.padSide * 2`) with a one-line comment
anchoring the block to `design/html-source/screens/P01-welcome.html:12-25` and
SPACING_SPEC §8, and reference `_frameW` in the `scale` expression. This also
keeps finding 1's fix to a single place instead of three literals.

### 6. MINOR — dead `BlocBuilder` plus a doc comment that misstates why the bloc is watched

**Where:** `welcome_view.dart:17-19` (doc comment) and
`welcome_view.dart:31-33` (`BlocBuilder<OnboardingBloc, OnboardingState>` with
`builder: (_, _) => const _WelcomeScroll()`).

The comment claims the subscription "keeps the route-level `watchItems()`
stream live for the rest of the onboarding flow", but the subscription lives in
`OnboardingBloc._onLoadRequested` (`presentation/bloc/onboarding_bloc.dart`),
started by the route-level `BlocProvider` in
`features/onboarding/onboarding_routes.dart:30-37` — a `BlocBuilder` with an
ignored state and a `const` child has no effect on it. Cost: one no-op rebuild
per state emission and a misleading reason for the dependency (performance is
fine — no storm, no `setState`, no animations; `const` is used correctly
throughout, and no stream is created or leaked by the view, since the
`emit.forEach` subscription is owned and closed by the route's bloc).

**Fix:** drop the `BlocBuilder` (and the now-unused
`flutter_bloc` / `onboarding_bloc` / `onboarding_state` imports) and delete the
claim from the doc comment; keep ARCHITECTURE's route-level `BlocProvider`
untouched. Re-add a `BlocBuilder` when P01 actually reads state.

### 7. MINOR — the accessibility group never asserts the heading flag

**Where:** `welcome_view_test.dart:403-456` vs `welcome_view.dart:215-221`.

`welcome_view.dart:215-221` correctly marks the headline
`Semantics(header: true, …)` (matching the HTML `<h1 class="display">` and the
`header: true` convention in `nest_section_label.dart:12` /
`nest_chrome.dart:58`), and the test asserts `isButton` on both CTAs — but
nothing pins `isHeader`, so a future refactor could silently demote the only
heading on the screen. Everything else in the a11y contract is genuinely
covered and correct: decorative nest/coins excluded, `9:41` chrome excluded,
Pip alt text present, 52dp full-width targets ≥ `NestDevice.tapParent`, no
icon-only or kid controls, and no overflow across
{light, dark} × {320, 390, 430}dp × {1.0, 1.3} scale.

**Fix:** add to the a11y group
`expect(tester.getSemantics(find.text(_headline)).getSemanticsData().flagsCollection.isHeader, isTrue);`

### 8. MINOR — first paint of P01 triggers an outbound Google-Fonts fetch (privacy/latency in a children's app)

**Where:** `app/lib/core/design_system/tokens/typography.dart:13-43` (every
`NestType` style goes through `GoogleFonts.inter` / `GoogleFonts.nunito`),
`app/pubspec.yaml:67-82` (no `fonts:` block — nothing bundled), and
`app/lib/main.dart` (no `GoogleFonts.config.allowRuntimeFetching = false`;
`grep -rn allowRuntimeFetching app/lib` finds only a doc comment). Tests set the
flag, production does not.

So the first screen a user ever sees issues HTTPS requests to
fonts.gstatic.com — a third-party network call in a family/kids app, plus
launch latency on a cold cache.

**Fix:** SHARED_REQUEST (shared path): bundle Inter + Nunito and set
`GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart`, or record
the CDN as an accepted processor in the privacy copy (P04 territory).

### 9. MINOR — cross-feature import of another feature's route constants

**Where:** `welcome_view.dart:8` — `import
'package:nestling/features/auth/auth_routes.dart';` for
`AuthRoutePaths.createAccount` (used at `welcome_view.dart:50`). Plan §c
explicitly chose this and ARCHITECTURE places route constants per feature, so
it is compliant as written; it is the only cross-feature coupling in the
screen. Flagged only so it is a conscious decision: if a shared route-name
registry is ever added, switch to it. No change now.

### 10. MINOR — redundant `Scaffold.backgroundColor`

**Where:** `welcome_view.dart:26`. `NestTheme` already sets
`scaffoldBackgroundColor: colors.paper` (`theme/nest_theme.dart:76`), so
`context.nest.paper` here duplicates the theme. Harmless and token-driven;
prefer deleting the line so the theme stays the single source of truth for
screen backgrounds.

### 11. INFO — above 390dp the scene stays 350pt and left-aligned

`welcome_view.dart:93` clamps `scale` to 1.0, so at 430dp the scene keeps its
design size with ~40pt of trailing space (and the text block spans the full
390pt). That matches `.scene { width: 350px }`, and scaling the artwork *up*
would alter design proportions — the right call. Confirm the wide-device band
drift in the stage-5 `compare.py` run; only revisit if the 430pt result reads
as unbalanced.

---

## What passed

- **Architecture (docs/ARCHITECTURE.md):** feature-first shape kept; the view
  lives at `features/onboarding/presentation/views/welcome_view.dart`, uses
  the existing `OnboardingBloc` provided at the route level, adds no use-case
  or extra folder, and imports only `package:nestling/...`. `domain/` + `data/`
  untouched (no repo call is needed on a static brand screen) — matches plan
  §b. DI and routes remain per feature and unmodified; navigation uses the
  route constants (`OnboardingRoutePaths.valueTour`,
  `AuthRoutePaths.createAccount`), not string literals, and both targets are
  asserted against the live `GoRouter` location.
- **Isolation (docs/screens/RULES.md):** only §1 paths changed —
  `git diff main --stat` lists exactly one file, and the untracked set is
  `app/test/features/onboarding/**` + `docs/screens/P01/**`. No `core/**`,
  no `app/**`, no `tools/**`, no other feature. Nothing weakened:
  `analysis_options.yaml` untouched, no skipped/ignored tests.
- **Design system:** every colour, font, spacing and device value resolves
  through `context.nest` / `context.nestText` / `NestSpacing` / `NestType` /
  `NestlingIllustrations` — no hex literals, no `TextStyle` construction, no
  re-implemented button/chrome components (`NestStatusBar`,
  `NestHomeIndicator`, `NestBottomCta`, `NestButton` primary + ghost are all
  reused, with the design system's own 52dp/full-width defaults).
- **Spec parity (docs/DESIGN_SPEC.md §5 P01, DESIGN_SPEC.md:146):** all
  elements present and in order — status bar `9:41`, leaf-tint circle
  (15/44, 320²), nest.svg (43/104, 264²), Pip stage 2 (91/120, 168², the HTML
  `alt` string verbatim as its semantics label), 3 floating coins at the HTML
  coordinates and rotations with `--sh-1`, headline, body, primary
  "Get started", ghost "I already have an account", caption. Copy is
  character-exact and UK ("Made in the UK · No ads, ever"), and the em dash in
  the body is preserved.
- **Error handling:** the brand screen renders for `initial`, `loading`,
  `loaded` (empty and populated) and `failure` — a repository error never
  blocks or blanks the screen (covered by five widget tests, including a
  stream-error repository that asserts `errorMessage` is still populated).
- **Motion rule (RULES §6):** static SVGs only — no Rive, Lottie,
  `Timer` or `AnimationController` in the view, so the `kDisableAnimations`
  still-frame requirement is met by construction.
- **Children's Code:** nothing in the screen collects, transmits or displays
  child data; no analytics, ads, tracking or identifiers; P01 is parent mode
  with no kid controls; the only outbound call on this screen is the
  font-CDN issue in finding 8 (shared, not P01's code).
- **Analyze / format / shared suites:** `No issues found!`, 340 files clean,
  and every non-P01 test in the full suite passes.

## For iteration 2

1. Fix finding 1 (blocker) — the narrow-width scene scale — and get
   `welcome_view_test.dart` "scene frame is painted in full (no crop)" green at
   320/360/390/430dp; keep 390/430 pixel-identical.
2. Delete `docs/screens/P01/SHARED_REQUEST.md` and correct the shared-suite
   claims in the build/test notes (finding 2) — the orchestrator must not be
   sent to a passing test.
3. Fold in the cheap minors while the file is open: 3, 5, 6, 7, 10 (and 4/8 as
   one SHARED_REQUEST about the startup precache + bundled fonts).
4. Re-run: `dart format .`, `flutter analyze`, `flutter test` — the only
   acceptable final state for this branch is `All tests passed!`.
5. Visual parity (`shot.sh` + `compare.py`, light and dark, band table) is
   still unrun — that is stage 5's gate, not stage 4's, but the 320dp finding 1
   fix should be eyeballed there too.

VERDICT: FAIL
