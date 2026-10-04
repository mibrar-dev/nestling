# Shared report — kid_trial_gate (router loop + merged kid test fixes)

## Files changed
- `app/lib/app/router.dart` — kid-mode trial branch + parent-only trial guard.
- `app/test/app/router_redirect_test.dart` — new `kid trial gate` group (8 tests).
- `app/test/features/kid_home/k03_bugs_test.dart` — 2 placeholder assertions → route assertions; gate exit now taps "Back to Pip" when present.
- `app/test/features/kid_home/kid_home_view_test.dart` — 5 placeholder assertions → route assertions.
- `app/test/features/kid_home/k01_bugs_test.dart` — rapid-lock double-tap exits via "Back to Pip" when present.

## What / why
1. LOOP (major): kid mode + expired trial redirected everything to `/paywall`,
   which is parent-only in kid mode → `/parental-gate` → trial branch →
   `/paywall` (GoException redirect loop, go_router error page). Fix per the
   orchestrator decision: in kid mode with an expired trial every location
   redirects to `/parental-gate`, and the gate is exempt from the trial branch
   (same pattern as the existing onboarding exemption). Kids never see the
   paywall; passing the gate flips to parent mode, where the unchanged trial
   branch sends the parent to `/paywall`. Parent mode and active-trial
   behaviour are unchanged (existing tests pin both).
2. MERGED TEST FIXES: the 7 `find.text('P17 Parental gate')` assertions now
   assert `pushedPath(tester) == '/parental-gate'` (stable across the scaffold
   and the real P17 gate, per the shared route-assertion rule). The two gate
   exits that used `tester.pageBack()` (needs a scaffold AppBar back button
   the real gate has no) now tap "Back to Pip" when it exists and fall back to
   `pageBack()` against the scaffold — green on main now and against the real
   P17 gate, using only route/text-existence branching (no placeholder copy
   asserted).

## Tests added (all in `test/app/router_redirect_test.dart`, group `kid trial gate`)
- `kid mode + expired trial sends <route> to the gate` × 5
  (`/kid-home`, `/who-is-playing`, `/pip`, `/paywall`, `/today`): asserts
  `currentPath == '/parental-gate'`, no `'Page Not Found'` error page,
  no exception. Mutation-checked: fails on the pre-fix router (loop repro).
- `passing the gate with an expired trial lands the parent on the paywall`
  (controller flip to parent, as the real gate does on a correct answer).
- `kid mode + active trial keeps kid screens open` (unchanged).
- `parent mode + expired trial still goes to the paywall` (unchanged).

## Verification
- `cd app && dart format .` — 0 changed.
- `flutter analyze` — "No issues found!".
- `flutter test` — all pass (2921 pass, 2 pre-existing skips, 0 fail).

## Follow-up for screens
- P17: `P17-BUG-1` (`p17_bugs_test.dart`, skip-marked loop repro) should now
  go green un-skipped — the router fix is what it waits on. The P17 gate's
  correct-answer path flips `AppModeController` to parent, which this change
  relies on to reach `/paywall`.
- K01/K03: no action — the fixed tests assert routes/exits that the real P17
  gate already provides ("Back to Pip" → pop to the kid route).

VERDICT: PASS
