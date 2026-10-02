# P03 Create account — build note (Stage 2, iteration 2)

Route `/create-account` · parent mode · feature `auth`. Implements
`1_plan.md` plus every item in `FIXES_1.md` (bugs P03-BUG-1…8, review
findings 1–8, the six mandatory `ORCHESTRATOR_NOTES.md` items).

## Files changed (all inside RULES §1)

- `app/lib/features/auth/domain/auth_repository.dart` — now also owns
  `enum AuthProvider` (review finding 6).
- `app/lib/features/auth/domain/auth_provider.dart` — deleted (finding 6).
- `app/lib/features/auth/presentation/bloc/auth_event.dart`,
  `data/auth_repository_impl.dart`,
  `presentation/views/create_account_view.dart` — import updates for the move.
- `app/lib/features/auth/presentation/bloc/auth_state.dart` — new
  `submitAttempted` flag (copyWith/props).
- `app/lib/features/auth/presentation/bloc/auth_bloc.dart` — dirty-gated
  validation (P03-BUG-2), `on Object` catches (P03-BUG-5).
- `app/lib/features/auth/presentation/views/create_account_view.dart` —
  caption overlay (P03-BUG-1/4), headline cap (P03-BUG-7), feature-owned
  helper (P03-BUG-8), `title: null` revert (P03-BUG-3 cleanup), scoped
  rebuilds (finding 8).
- `app/test/features/auth/p03_bugs_test.dart` — un-skipped 1a–1d, 2a–2c, 4,
  5, 7, 8 (all green); BUG-3/2d untouched green; BUG-6 stays skipped
  (shared core, SHARED_REQUEST §4).
- `app/test/features/auth/auth_bloc_test.dart` — updated the four tests that
  pinned first-keystroke errors; flag coverage added.
- `app/test/features/auth/create_account_view_test.dart` — validation group
  rewritten for gated errors; caption finders moved to `textContaining`;
  Terms/Privacy assertions tightened to `equals`; link sizes measured on the
  keyed targets.
- `docs/screens/P03/SHARED_REQUEST.md` — item 1 marked fully done (revert
  landed); items 2/4 still open/non-blocking.

## What was done about each fix item

- **BUG-1 (MAJOR, caption eats the form)**: `_LegalLine` is now a
  `Text.rich` visual (exact text lines, `ExcludeSemantics`) with the two
  keyed 44dp `_LegalHitTarget`s in a zero-height `Positioned.fill` overlay —
  the HTML negative-margin trick. Caption is text-height; targets keep keys
  and 44dp boxes. Proofs 1a–1d green.
- **BUG-2 (MAJOR, first-keystroke errors)**: new `submitAttempted` state, set
  only when a submit is rejected as invalid; change handlers write the value
  always but set/clear the error only when already errored or attempted,
  while always dropping a stale `formError`. Empty-submit path unchanged.
  Proofs 2a–2c green, 2d stays green.
- **BUG-3 (nav 60dp)**: was already fixed on main; reverted the `title: ''`
  workaround to `title: null`, proof stays green.
- **BUG-4 (double-announced links)**: overlay targets carry the exact single
  button label (no inner `Text` to merge); caption sentence exposed once via
  `explicitChildNodes`. Proof green; view assertions now `equals`.
- **BUG-5 (non-Exception spinner)**: both submit handlers catch `Object` and
  surface `formError`. Proof green (no `addError`, so the zone stays clean).
- **BUG-6 (shared NestButton doubling)**: not patchable here; proof stays
  skipped, SHARED_REQUEST §4 open.
- **BUG-7 (headline break)**: `ConstrainedBox(maxWidth: 240)` — inside the
  measured [198, 252) window, no hard newline. Proof green.
- **BUG-8 (helper indent)**: helper is now a feature-owned caption row 6dp
  under the input on the 20dp gutter (hidden while an error shows
  in-decoration). Proof green.
- **Findings 5/6/8**: moot by redesign (no padding literals left) / enum
  moved, file deleted / brand buttons on `BlocSelector(isSubmitting)`,
  fields on `buildWhen` error selectors, CTA unchanged.
- **ORCHESTRATOR_NOTES**: §1 shared-done; §2 headline cap; §3 filled-state
  widget pin kept green (filled simulator capture is UI-stage work, not run
  here); §4 helper gutter+6dp; §5 two-line caption; §6 note row untouched.
- Screenshots intentionally not re-captured in this stage (UI stage owns
  `shot.sh`/`compare.py`); geometry is pinned by the widget proofs.

## Evidence tails (app/)

- `dart format --set-exit-if-changed .` → `Formatted 359 files (0 changed)`.
- `flutter analyze` → `No issues found! (ran in 3.7s)` — no ignores.
- `flutter test test/features/auth` → `104 passed, 1 skipped` (the skip is
  shared P03-BUG-6 only).
- `flutter test` (full suite) → `591 passed, 1 skipped, 0 failed`.
- `git status` touches only `app/lib/features/auth/**`,
  `app/test/features/auth/**`, `docs/screens/P03/**` — nothing shared.

VERDICT: PASS
