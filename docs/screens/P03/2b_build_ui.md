# P03 Create account — build UI notes (Stage 2b, iteration 7)

Route `/create-account` · feature `auth` · parent mode. Scope: `app/lib/features/auth/presentation/views/**`, `presentation/widgets/**`, and `app/test/features/auth/**` files whose names contain `view` or `widget` (plus referenced bug proofs). No domain/data/bloc files touched. Logic builder reports **CONTRACT CHANGES: none** in `2a_build_logic.md`; no drift found.

## FIXES_6 items done (UI/layout/copy layer)

1. **P03-BUG-23 — form block sat 2 dp below the design: fixed, both proofs green.**
   `_OrRow` styled its label with `NestType.caption` (13/18); the design's
   `.or-label` sets no line-height, so its row is 13 × Inter's CSS-normal
   ≈ 15.7 dp (SHARED_REQUEST §9). `copyWith(height: null)` cannot unset
   the token's height, and Flutter's own natural box for the bundled Inter
   build measures ~19 dp, so the or-label style is now built explicitly:
   Inter 13, w600, letterSpacing 0, `height: 15.7 / 13`, `tokens.ink2`.
   The Google-bottom → email-field-top gap now matches the design's
   71.7 dp and the field tops sit at the design's 443.00 / 535.00.

## Verified

- `dart format --set-exit-if-changed lib/features/auth test/features/auth` → clean.
- `flutter analyze lib/features/auth test/features/auth` → No issues found.
- `flutter test test/features/auth` → **159 passed, 0 skipped, 0 failed**
  (`p03_bugs_test.dart` 30/30 incl. P03-BUG-23, `typography_test.dart` 10/10).

## LEFT FOR NEXT ITERATION

- `SHARED_REQUEST.md` §7 (legal-caption 13/20 token) remains the open shared item, non-blocking; §9 wording is the neighbouring doc note for this fix.
- Filled-state simulator capture already handled by `docs/screens/P03/filled_shot.sh` (stage 3 evidence); UI stage may compare `ui/filled-*.png`.

VERDICT: PASS
