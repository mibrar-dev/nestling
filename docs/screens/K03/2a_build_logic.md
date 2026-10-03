# K03 Kid home — Stage 2a logic chunk (iteration 7)

Scope: non-UI layer of `kid_home` only. No edits to
`presentation/views/**` or `presentation/widgets/**`.

## CONTRACT CHANGES (for the UI builder — please read)

Two ADDITIVE events in `presentation/bloc/kid_home_event.dart`; every
existing event/state name and field is untouched, so current view code
compiles and behaves identically:

- `KidHomeDataReceived(home)` — bloc-internal; the bloc raises it from its
  own home-stream subscription. Views must never send it.
- `KidHomeStreamFailed(error)` — bloc-internal; same.

Reason (review finding 6): the load handler can no longer `await
emit.forEach(...)` on a never-ending stream, because a failure-state
"Try again" then stacks a second live subscription. The handler now owns a
`StreamSubscription` (cancelled before every reload and on `close()`); stream
output re-enters as the two events above. Observable behaviour is unchanged
apart from the leak fix.

## Files changed

- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`: manual
  `_homeSub` subscription, cancel-before-reload, `close()` override,
  `_onDataReceived` / `_onStreamFailed` handlers (celebration/error logic
  moved verbatim). No DI/route changes.
- `app/lib/features/kid_home/presentation/bloc/kid_home_event.dart`: the
  two internal events above (sealed family — same library, no contract
  break).
- `app/test/features/kid_home/kid_home_bloc_test.dart`: new
  `_ManualHomeRepository` (hand-driven `watchHome` controllers) + test
  "reloading cancels the previous home subscription" (old controller
  listener-free, orphaned emission ignored, live stream still drives,
  `close()` detaches) + "internal stream events carry their payload".
- `docs/screens/K03/SHARED_REQUEST.md`: new entry #14 (finding 7).

## FIXES_6 items in my layer

- Finding 6 [minor] retry stacks subscriptions — DONE (above), proven by
  the new test.
- Finding 7 [minor] `switchMapStream` in domain — recorded as
  SHARED_REQUEST #14 (K03 may not edit `core/`). Helper stays tested in
  place; no code moved.
- Finding 1 [blocker] "double tap across frames" widget failure — already
  gone from the tree (no such test in `k03_bugs_test.dart`; repo-level
  idempotency still proven by the K03-BUG-1 row-count test). Nothing to fix.
- Finding 3 [major] `probe_temp_test.dart` — already deleted from the
  tree. Nothing to fix.
- Findings 2 (pet slot), 4 (`NestBalancedText`), 5
  (`tileBackground`/`wrapLabel`), 8 (hearts caption) — views/shared, UI
  builder's. K03-BUG-13/14 stay skipped: shared-component cause, K03 cannot
  fix in `core/`; un-skipping would keep the suite red.

## Verification

- `dart format` on touched dirs — clean.
- `flutter analyze` on domain/data/bloc + `kid_home_bloc_test.dart` —
  No issues found.
- `flutter test test/features/kid_home/kid_home_bloc_test.dart` — 28/28
  pass (26 existing + 2 new).
- No `google_fonts` in my files. No letter-spacing touches (no text styles
  in my layer). Period/copy logic untouched.
- Full-folder `flutter test` and the simulator are the integrator's;
  `k03_bugs_test.dart` / `kid_home_view_test.dart` were not run here
  (widget files; UI builder is editing views concurrently).

## LEFT FOR NEXT ITERATION

- Nothing open in my layer. If the orchestrator lands `stream_combine.dart`
  hosting `switchMapStream` (#14), adopt the import (mechanical).

VERDICT: PASS
