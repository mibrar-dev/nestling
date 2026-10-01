# P01 Welcome — build plan (Stage 1, iteration 1)

Sources: `design/screens/light/P01-welcome.png`, `design/screens/dark/P01-welcome.png`
(1170×2532 @3x → ÷3 = 390×844 logical), `design/html-source/screens/P01-welcome.html`,
DESIGN_SPEC §5 P01, SPACING_SPEC §§0–2,8,10–11, design system barrel
`app/lib/core/design_system/design_system.dart`. Mode: parent. Route: `/welcome`.

Isolation (RULES §1): builder may edit ONLY
`app/lib/features/onboarding/presentation/**`,
`app/lib/features/onboarding/domain/**` + `data/**` (not needed — see §b),
`app/test/features/onboarding/**`, `docs/screens/P01/**`.
Never touch `app/lib/core/**`, `app/lib/app/**`, `tools/screens/**`.

## (a) Widget tree top→bottom (exact components + token spacing)

`WelcomeView` (stateless) returns `Scaffold` with `backgroundColor: tokens.paper`
(theme resolves it; never hard-code). Body is a `Column` — no nav bar, no tab bar
on P01:

1. `NestStatusBar()` — height `NestDevice.statusH` (47), internal padding
   top `NestSpacing.s3` (12) / horizontal `NestSpacing.s6` (24). Time `9:41`.
   Decorative (`ExcludeSemantics` built in).
2. `Expanded` scroll: `SingleChildScrollView` with
   `EdgeInsets.fromLTRB(NestSpacing.padSide, 0, NestSpacing.padSide, NestSpacing.s8)`
   (20,0,20,32). Children:
   - Scene `SizedBox(width: 350, height: 388)` — 350 = 390−40 content width.
     `Stack` children (all sizes logical px, from HTML `<style>` + SPACING_SPEC §8):
     - circle: `Positioned(left: 15, top: 44, width: 320, height: 320)`,
       `BoxDecoration(shape: circle, color: tokens.leafTint)`.
     - nest: `Positioned(left: 43, top: 104, width: 264, height: 264)`,
       `SvgPicture.asset(NestlingIllustrations.nest)`, `ExcludeSemantics`.
     - pip: `Positioned(left: 91, top: 120, width: 168, height: 168)`,
       `SvgPicture.asset(NestlingIllustrations.pipStage2,
       semanticsLabel: 'Pip the hatchling bird sitting in a twig nest')`.
     - 3 coins, all `ExcludeSemantics`, circle + `tokens.cardShadow`
       (`--sh-1`): 40×40 at (16,104) rotated −14°; 34×34 at (308,132)
       rotated +16°; 36×36 at (7,241) rotated +22°.
       Use `SvgPicture.asset(NestlingIllustrations.coin)`.
     - Gap accounting: circle bottom = 44+320 = 364 inside the 388 block,
       so 24px breathing room sits between circle edge and headline. The text
       block therefore uses margin-top **0** (HTML `.scroll > .p01-text`
       override wins over the base 16 sibling rule).
   - Text block (`Column`, `crossAxisAlignment: start`):
     - `Text('Chores that feel like a game.', style: context.nestText.display)`
       (Nunito 34/40 w900, ls −0.34, ink). `softWrap: true`.
     - `SizedBox(height: NestSpacing.s3)` (12 — from `.p01-text p margin-top:12`).
     - `Text('Nestling turns family jobs into quests your children actually want '
       'to finish — and keeps pocket money fair and tidy.',
       style: NestType.body(color: tokens.ink2))` (Inter 16/24, ink-2).
3. `NestBottomCta(caption: 'Made in the UK · No ads, ever', child: …)` —
   surface bg, top `tokens.line` hairline, padding vertical `NestSpacing.s4`
   (16) / horizontal `padSide` (20), child-to-caption gap `s2` (8, built in).
   Child is a `Column(spacing/gap: s2 = 8, stretch)`:
   - `NestButton(label: 'Get started', variant: primary, fullWidth: true,
     minHeight: 52, key: ValueKey('p01_get_started'))` (Inter 16 w700,
     bg `tokens.leaf`, fg `tokens.onLeaf`).
   - `NestButton(label: 'I already have an account', variant: ghost,
     fullWidth: true, minHeight: 52, key: ValueKey('p01_have_account'))`
     (transparent bg, fg `tokens.ink`).
   - Caption renders via `NestBottomCta.caption` (`NestType.caption`,
     ink-2, centred, maxLines 3).
4. `NestHomeIndicator()` — height `NestDevice.homeH` (34), pill 134×5.

Dark mode: zero code branches — all colours via `context.nest` tokens
(paper #15131F, leaf #3CC98A, onLeaf #0E1A14, leafTint #173A2B flip
automatically). Motion: static SVGs only; no Rive/Lottie/Timer, so the
`kDisableAnimations` still-frame rule is trivially satisfied.

Narrow-width rule (SPACING_SPEC §10.2): fixed 350 scene overflows at 320
(content 280). Wrap the scene `Stack` in a scale-down container:
`LayoutBuilder` → `scale = min(1, maxWidth / 350)` → `SizedBox(350*scale,
388*scale)` + `Transform.scale(scale: scale, alignment: topLeft)` (or
`FittedBox(fit: BoxFit.scaleDown)`). Default 390 path keeps exact numbers.

## (b) BLoC events/states + repository calls

Reuse the existing foundation as-is — **no new events, states, or repo methods**:

- Route (`welcomeRoute` in `onboarding_routes.dart`) already provides
  `BlocProvider<OnboardingBloc>(create: (_) => sl<OnboardingBloc>()
  ..add(const OnboardingLoadRequested()))`. Do not change.
- Event: `OnboardingLoadRequested` (existing). State: `OnboardingState`
  (`initial/loading/loaded/failure` + `items`, existing `_onLoadRequested`
  with `emit.forEach(_repository.watchItems())`, existing).
- P01 displays none of `items` (the 3 static tour steps are P02 content) and
  calls **no** repository method from any interaction. Do not call
  `completeOnboarding()` here (onboarding completes at the end of the flow,
  P06/P07 territory). No `domain/` or `data/` edits needed.

## (c) Interactions → navigation (route constants)

- `Get started` `onPressed`: `context.go(OnboardingRoutePaths.valueTour)`
  (`'/value-tour'`, import `features/onboarding/onboarding_routes.dart`
  + `go_router`). Pushes P02 value tour.
- `I already have an account` `onPressed`: `context.go(AuthRoutePaths.createAccount)`
  (`'/create-account'`, import `features/auth/auth_routes.dart`). Foundation
  has no separate sign-in route; create-account is the returning-user entry.
- Nothing else is tappable (scene/coins excluded from semantics).

## (d) Empty / loading / error states

P01 has no data dependency, so render the static content for
`initial`, `loading`, **and** `loaded` identically. On `failure`, still render
the static content (never block a brand screen on the tour-steps stream).
No empty state (not a list screen). Works under every seed
(`fresh`/`empty`/`demo` — router redirect owns gating, not this view).

## (e) Accessibility

- Semantics: pip image carries the HTML alt as label
  (`'Pip the hatchling bird sitting in a twig nest'`); nest + 3 coins are
  `ExcludeSemantics` (decorative); status bar/home indicator already excluded
  in the design system; both buttons expose their labels via `NestButton`
  (`Semantics button + enabled`); heading is the first semantic node.
- Tap targets: both CTAs 52 high × full width ≥ 44 (`NestDevice.tapParent`);
  no icon-only buttons on this screen.
- Text scale to 1.3: title/body wrap (`softWrap`, no `nowrap`), ghost label
  wraps inside its `Flexible`, whole screen scrolls behind the fixed
  `NestBottomCta`; app text-scaler clamp 1.0–1.3 per SPACING_SPEC §10.1.
- Width 320: scene scales via §a LayoutBuilder rule; buttons stretch;
  coin-pill-style overflow N/A (no pills on P01).
- Contrast (both themes, token-driven): ink on paper, ink-2 body/caption ≥4.5:1;
  onLeaf on leaf ≥4.5:1; ghost ink on surface ≥4.5:1. UK spelling kept verbatim.

## (f) Test plan

New file `app/test/features/onboarding/welcome_view_test.dart` (feature dir is
editable per RULES §1). Conventions: `GoogleFonts.config.allowRuntimeFetching
= false` via `setUpTestScope`, `pumpAppRoute(tester, '/welcome')` on a 390×844
surface, every pumping test ends with `disposeApp(tester)` (Drift timer drain):

1. Renders headline, body, both CTA labels, footer caption, Pip semantics.
2. `Get started` tap → location `/value-tour`; `I already have an account`
   tap → `/create-account` (use `GetIt.instance<GoRouter>` / router location
   assertion; follow `routes_smoke_test.dart` pattern).
3. Dark theme (`pumpAppRoute(..., theme: ThemeMode.dark)`) renders same copy
   with no overflow.
4. Text scale 1.3 (`tester.platformDispatcher.textScaleFactorTestValue = 1.3`)
   + width-320 surface: no `RenderFlex overflowed` exception.
5. `OnboardingBloc` unit: `OnboardingLoadRequested` → loading → loaded with
   the 3 static steps (existing repo impl `Stream.value(_steps)`).

Then: `dart format .` clean, `flutter analyze` → No issues found (no ignores),
`flutter test` → all pass. Visual: `tools/screens/shot.sh app /welcome
<out> <udid> light fresh parent` + dark, `tools/screens/compare.py
design/screens/light|dark/P01-welcome.png` vs shots; review band table.

## (g) SHARED_REQUEST needed

None. No design-system, route, DI, schema, or seed changes required:
all widgets/tokens/assets (`pipStage2`, `nest`, `coin` SVGs in
`assets/illustrations/`) and both target routes already exist in the
foundation.

VERDICT: PASS
