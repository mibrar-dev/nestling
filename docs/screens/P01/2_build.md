# P01 Welcome — build notes (Stage 2, iteration 1)

Implemented per `docs/screens/P01/1_plan.md` (§a–§g).

## Files changed

- `app/lib/features/onboarding/presentation/views/welcome_view.dart`
  (rewrote placeholder): `Scaffold` on `tokens.paper`; `Column` of
  `NestStatusBar`, `Expanded` scroll, `NestBottomCta`, `NestHomeIndicator`.
  Scroll is `SingleChildScrollView` with `EdgeInsets(20, 0, 20, 32)`;
  children are the 350x388 scene `Stack` (leaf-tint circle at 15/44 320x320,
  nest at 43/104 264x264, Pip stage 2 at 91/120 168x168 with the HTML alt
  text as semantics label, 3 coins 40/34/36px at the rim with -14/+16/+22
  deg rotation and `cardShadow`) plus the text block (display headline,
  12px gap, ink-2 body). Scene scales down via `LayoutBuilder`
  (`scale = min(1, maxWidth / 350)`) for 320dp widths. CTA: primary
  `Get started` → `context.go('/value-tour')`, ghost
  `I already have an account` → `context.go('/create-account')`, caption
  `Made in the UK · No ads, ever`. Same static content for every bloc
  status; no repo/domain edits (none needed). Tokens/components only, no
  hard-coded colours/sizes.
- `app/test/features/onboarding/welcome_view_test.dart` (new): renders
  copy + Pip semantics, both navigation taps (assert P02/P03 placeholder
  titles), dark theme, 320dp + text-scale 1.3 (no exception), bloc unit
  test (load → 3 static steps).
- `docs/screens/P01/SHARED_REQUEST.md` (new): shared-suite update (below).
- `docs/screens/P01/2_build.md` (this file).

## Fix items

None — iteration 1, no prior review items. One deviation from plan §g
("SHARED_REQUEST needed: None"): the shared
`test/app/router_redirect_test.dart` asserts the placeholder title
`P01 Welcome`, so it fails against the real view. Filed
`SHARED_REQUEST.md`; the redirect itself still lands on `/welcome`.
Screenshots/compare (`shot.sh`) not run — not required by this stage.

## Checks (`app/`)

- `dart format .` — clean (2 files formatted, 0 changed on re-run).
- `flutter analyze` — `No issues found!` (fixed 7 infos: dropped
  redundant `BoxFit.contain`/`softWrap`/type annotation, added `const`).
- `flutter test test/features/onboarding/welcome_view_test.dart` —
  `All tests passed!` (6/6).
- `flutter test` (full) — 292 pass, 1 fail:
  `test/app/router_redirect_test.dart: fresh install opens the welcome
  screen` — `Expected: exactly one matching candidate / Actual: Found 0
  widgets with text "P01 Welcome"`. Baseline verified via `git stash`:
  passes on placeholder, fails only because the placeholder title is
  gone. Outside §1 edit scope, hence the shared request.

VERDICT: FAIL
