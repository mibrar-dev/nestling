# P15 · Child profile — Stage 2a BUILD, LOGIC CHUNK (iteration 4)

Scope: non-UI layer of feature `family` only — `domain/**`, `data/**`,
`presentation/bloc/**`, the feature's DI/route registration files, and
unit/bloc tests. No edits to `presentation/views/**` or
`presentation/widgets/**` (the UI builder owns those). Triaged `1_plan.md`
§b and every `FIXES_3.md` item for logic-layer ownership.

## CONTRACT CHANGES

None. No events, states, repository methods, or constructor shapes changed
this iteration, so there is nothing for the UI builder to reconcile.

## Triage of FIXES_3.md (nothing in the logic layer to fix)

- **2_build items 1–5**: contract reconciliation (none needed), no compile
  breaks, placeholder anchors still green, no skips in P15 tests, the
  `child_profile_selection_test.dart` expectation verified correct upstream
  (2 is right at +1 day under PERIODS — London week Mon 29 Sep–Sun 4 Oct).
  No action.
- **2_build item 6** (`test/core/family_time_test.dart` red on main):
  shared core, RULES §1 forbids P15 from editing it; already filed as
  `SHARED_REQUEST.md` §6 (verified present). No action.
- **P15-BUG-10 (minor, the one new bug)**: the fix is one line in
  `child_profile_view.dart:57` (`GoRouterState.of` → `GoRouter.maybeOf`,
  per the suggested direction) — squarely the UI builder's file, which this
  chunk is explicitly forbidden from editing. Verified the proof fails
  exactly for that reason (`GoError: There is no GoRouterState above the
  current context`, no logic-layer involvement: the throw happens at the
  view's call site before any bloc/repository code runs). No logic-side
  change can fix it, and the route wrapper already covers the in-app deep
  links independently. Left for the UI builder; noted under LEFT below.
- **ORCHESTRATOR items**: 1–2 intact in code (row/intrinsic trail, icons),
  3–4 deliberate rulings. No action.

## Files changed

- `docs/screens/P15/2a_build_logic.md`: this file only. Deliberately no
  production or test edits — every logic-layer item in FIXES_3 is already
  closed, and the one open bug is not in this layer.

## Verification (in `app/`, no simulator)

- `flutter analyze lib/features/family` → No issues found.
- `dart format --set-exit-if-changed` on the logic scope + owned tests →
  0 changed.
- `child_profile_bloc_test.dart` + `p15_bugs_test.dart` → 31/31 green
  (incl. all un-skipped BUG-1/3/6/7/8/9 proofs).
- `test/features/family/` → 280 pass, 1 fail: solely the BUG-10 view
  proof (`child_profile_view_test.dart`, UI builder's file — fails on the
  `GoError` above).
- No whole-suite run, no simulator (integrator's stage). No `google_fonts`.
  No `skip:` markers added anywhere.

## LEFT FOR NEXT ITERATION

- **P15-BUG-10 → UI builder**: apply the one-line `GoRouter.maybeOf`
  fix in `child_profile_view.dart:57`. That is the only red in the
  feature suite and the only open FIXES_3 item.

VERDICT: PASS
