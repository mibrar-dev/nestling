# P04 · Privacy consent — STAGE 2b UI build (iteration 9)

Scope: `presentation/views/**` + view/widget tests in
`app/test/features/privacy_consent/`. No edits to `domain/`, `data/`,
`presentation/bloc/` (logic builder's layer).

## FIXES_8 items — what was done

### Finding 1 (MAJOR) — P04-11: Material tracking leaks into every text run — FIXED locally

The iteration-8 test stage's new `privacy_consent_geometry_test.dart`
(letter-spacing contract group) pinned the P04-10 class screen-wide: 3 red
tests (light, dark, dialog) because `NestType` omits `letterSpacing` and
Material's `bodyMedium` (0.25px) inherits into all 14 remaining runs.

Fix, all inside `privacy_consent_view.dart`:

1. **Screen:** the Scaffold body is wrapped in
   `DefaultTextStyle.merge(letterSpacing: 0)`. The design gives tracking only
   to `.display`/`.status-time` (neither used on P04), so zeroing the ambient
   for the whole screen is design-exact — and, unlike per-Text `copyWith`s,
   it also reaches **core-rendered labels** a screen agent cannot edit
   (`NestButton`'s `Continue`, which the review's own offender list included
   and its per-site fix list could not cover).
2. **Dialog:** the Privacy Notice dialog now renders its title inside the
   child instead of via `NestModal(title:)`. Probe evidence (temporary
   probe, since deleted): the dialog route DOES capture the screen's zeroed
   DefaultTextStyle, but the `Dialog`'s `Material` then re-applies
   `AnimatedDefaultTextStyle(theme.textTheme.bodyMedium)` (0.25) nearer to
   the content, so a core-rendered `NestModal` title can never be reached
   from the screen. The inlined title is pixel-identical to NestModal's own
   slot (same `NestType.h3(ink)` + `letterSpacing: 0`, centred, maxLines 3,
   ellipsis, `SizedBox(s4)` before the content) — the dialog body lines
   already measured `null` tracking under NestModal's own DefaultTextStyle,
   so they needed no change. SHARED_REQUEST §7 carries the new evidence:
   **every `NestModal` title on every screen** renders with 0.25px tracking
   until core lands the zero default.

Result: the 3 contract tests are green and the whole feature suite is
166/166. The existing P04-10 `copyWith` on the opt-card title is kept
(harmless, documents the original wrap site).

### Finding 3 (MINOR) — a11y test's banned-font literals false-positive plain greps — FIXED

`privacy_consent_a11y_test.dart` now builds the needles from pieces
(`'google' '_fonts'`, `'Google' 'Fonts'`, const), rewords the comments/reason
to not name the package, and drops the self-exclusion so the scanner also
covers its own file. Verified: `grep -rn "google_fonts|GoogleFonts"` over
`app/lib`, `app/test`, `app/pubspec.yaml` → **zero hits**.

### Finding 2 (MINOR) — geometry test untracked

Loop bookkeeping: the loop commits each iteration; the file is present and
green in the tree, so it lands tracked with this iteration's commit.

### Finding 4 (MINOR) — git-history bookkeeping

Orchestrator's iteration-9 UPDATE (03:58): explicitly **not** a finding. No
action.

## Orchestrator UPDATE (03:58, iteration 9) — conformance

- Fix locally until `shared/letter_spacing_zero` lands → done (wrapper +
  dialog title); the 3 contract tests are green and kept — they also pass
  unchanged once the shared zero lands (explicit 0 wins over any ambient).
- Geometry test tracked → lands with this commit.
- a11y literals from pieces → done.

## Files changed (all inside RULES §1)

- `app/lib/features/privacy_consent/presentation/views/privacy_consent_view.dart`
  — DefaultTextStyle.merge wrapper; dialog title inlined (P04-11).
- `app/test/features/privacy_consent/privacy_consent_a11y_test.dart` —
  piecewise needles, self-scan, comment rewording (review finding 3). Not a
  `view`/`widget`-named file, but FIXES_8 assigns the item and it is not in
  the logic builder's layer.
- `docs/screens/P04/SHARED_REQUEST.md` — §7 iteration-9 status + the
  Dialog-Material evidence.

No changes needed in the view/widget test files: the geometry contract (the
test stage's file) pins the behaviour and is green against the fix.

## Logic-builder contract check

Re-read `docs/screens/P04/2a_build_logic.md` (iteration 9) before finishing:
**CONTRACT CHANGES: none.**

## Verification (feature scope only — no whole-app run, no simulator)

```
dart format --set-exit-if-changed lib/features/privacy_consent \
  test/features/privacy_consent        → 20 files, 0 changed
flutter analyze lib/features/privacy_consent \
  test/features/privacy_consent        → No issues found!
flutter test test/features/privacy_consent/
  → 00:11 +166: All tests passed!   (166 passed, 0 skipped, 0 failed —
    previously 163 + 3 red letter-spacing contract tests)
```

## LEFT FOR NEXT ITERATION

- **Shared (not P04's):** `shared/letter_spacing_zero` (NestType zero
  default) — when it lands, the view's `DefaultTextStyle.merge` wrapper and
  the dialog's inlined title become redundant no-ops that can be simplified;
  the geometry contract tests keep passing either way. SHARED_REQUEST §7 open.
- The integrator owns this iteration's whole-app `flutter test` and the
  simulator re-shoot.

VERDICT: PASS
