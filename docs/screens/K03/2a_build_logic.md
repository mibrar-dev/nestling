# K03 Kid home — Stage 2a logic chunk (iteration 8)

Scope: non-UI layer of `kid_home` only. No edits to
`presentation/views/**` or `presentation/widgets/**`.

## CONTRACT CHANGES (for the UI builder — please read)

Two ADDITIVE events in `presentation/bloc/kid_home_event.dart`; every
existing event/state name and field is untouched, so current view code
compiles and behaves identically:

- `KidHomeDataReceived(home)` — bloc-internal; the bloc raises it from its
  own home-stream subscription. Views must never send it.
- `KidHomeStreamFailed(error)` — bloc-internal; same.

Reason (K03-BUG-15 / review finding 1): the load handler can no longer
`await emit.forEach(...)` on a never-ending stream — the failure card's
"Try again" stacked a second live handler per tap. The handler now owns a
`StreamSubscription` guarded by early-return while live, released on error
and on `close()`; stream output re-enters as the two events above.

## Files changed

- `app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`:
  `_homeSub` guard + manual subscription, `_onDataReceived` /
  `_onStreamFailed` handlers (celebration logic moved verbatim),
  `close()` override. Mid-session error keeps a loaded list: failure state
  only when `state.child == null` (review finding 6); healthy emissions
  restore `loaded` via `copyWithLoaded`. No DI/route changes.
- `app/lib/features/kid_home/presentation/bloc/kid_home_event.dart`: the
  two internal events above (sealed family — same library, no break).
- `app/test/features/kid_home/kid_home_bloc_test.dart`: BUG-15 comment
  updated; new "two completion taps one frame apart celebrate exactly once"
  (review finding 5: both taps reach the repo — row dedupe stays with the
  K03-BUG-1 transaction proof — bloc celebrates once); new "mid-session
  stream error keeps the loaded list" via a `failItemsNow` fake hook.
- `app/test/features/kid_home/k03_bugs_test.dart`: K03-BUG-15 un-skipped
  (one word; same in-scope defect, per "keep one proof, un-skipped").

## FIXES_7 items in my layer

- Finding 1 [blocker] K03-BUG-15 — DONE. Both proofs pass (bloc-suite
  counters 1/1; bugs-suite peak ≤ 2 with 0 live after failure — release
  comes from cancelling the chain on error, which also keeps Try-again
  working).
- Finding 5 [minor] — duplicate-proof half DONE (bugs proof un-skipped and
  green); cross-frame double-dispatch proof ADDED at bloc level.
- Finding 6 [minor] mid-session error — DONE (keep-list rule above).
- Finding 8 [minor] `switchMapStream` in domain — no action (SHARED_REQUEST
  #14 already carries it).
- Findings 3, 4 (pet slot, meadow) — shared/views, not mine. BUG-13/14 stay
  skipped (shared #13).

## Verification

- `dart format` on touched dirs — clean (`0 changed` on re-run).
- `flutter analyze` on domain/data/bloc + both touched test files —
  No issues found.
- `flutter test test/features/kid_home/kid_home_bloc_test.dart` — 29/29.
- `flutter test .../k03_bugs_test.dart --plain-name K03-BUG-15` — pass;
  full file — +47 ~4 (4 skips are BUG-13/14, shared), all pass.
- No `google_fonts` in my files; no letter-spacing touches; period/copy
  logic untouched.

## LEFT FOR NEXT ITERATION

- Nothing open in my layer. Shared #13/#14/#15 and the pet/meadow UI work
  belong to the orchestrator / UI builder.

VERDICT: PASS
