# P03 Create account — build UI notes (Stage 2b, iteration 6)

Route `/create-account` · feature `auth` · parent mode. Scope: `app/lib/features/auth/presentation/views/**`, `presentation/widgets/**`, and `app/test/features/auth/**` files whose names contain `view` or `widget` (plus the referenced bug proofs). No domain/data/bloc files touched.

## FIXES_5 items done (UI/layout/copy layer)

1. **P03-BUG-16 (danger border on invalid fields) — fixed, proof un-skipped and green.**
   `SHARED_REQUEST.md` §8 has landed on main (`nest_text_field.dart` now wraps its
   gutter error row in `Semantics(liveRegion: true, label: errorText)`), so the
   screen-owned live-region error rows are redundant. Both `NestTextField`s in
   `create_account_view.dart` now take `errorText:` (`state.emailError` /
   `state.passwordError ?? state.formError`); the owned error rows and their
   `buildWhen` selectors are deleted, and the password helper row stays owned
   (hidden while an error shows, matching the shared field's error-wins
   behaviour). The danger border and the announcement now arrive together —
   BUG-16 and BUG-20/21 are closed by the same shared component.
   `P03-BUG-16` proof un-skipped; its border detection was rewritten to read
   the field's painted `InputDecoration` borders (the shared field paints
   from the decoration, not a `BoxDecoration` border).

2. **P03-BUG-22 (`_HitTestExpand` overhang fallback double-fires) — fixed, proof un-skipped and green.**
   `hit` alone could not gate the fallback: the bar's `RenderDecoratedBox`
   claims empty-bar taps (`hit == true`), and that is exactly where the
   fallback is needed to reach the overhanging link boxes (BUG-18). The
   fallback is now suppressed only when the normal path's entries (added by
   the bar subtree — ancestors add theirs after) include a gesture target
   (`RenderPointerListener`/`RenderSemanticsGestureHandler`), i.e. when the
   submit button (or the link itself) already owns the point. BUG-18
   (overhang targets reachable) stays green in the same run.

3. **google_fonts leftovers deleted** (orchestrator iteration-5 update):
   `GoogleFonts.config.allowRuntimeFetching` lines and the
   `package:google_fonts/...` import removed from
   `p03_bugs_test.dart` and `create_account_view_test.dart`.

`SHARED_REQUEST.md` §5's "Decision A skip" disposition is now superseded by
this switch (Decision B). §5/§8 wording and the 4_review owner-adjudication
item are doc edits for the test/review/owner stages.

## Verified

- `dart format --set-exit-if-changed lib/features/auth test/features/auth` → clean.
- `flutter analyze lib/features/auth test/features/auth` → No issues found.
- `flutter test test/features/auth` → **147 passed, 0 skipped, 0 failed**
  (previously 144 green + 1 red; BUG-16/BUG-22 un-skipped, both green;
  BUG-20/21 still green via the shared row).

## LEFT FOR NEXT ITERATION

- Nothing UI-local. Remaining loop items: SHARED_REQUEST §5/§8 disposition
  wording (owner), subtitle wrap (shared `body_text_width` fix — orchestrator
  merge), filled-state simulator capture (UI stage, host-blocked before).

VERDICT: PASS
