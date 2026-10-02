# P07 Paywall — Stage 2a logic chunk (iteration 2)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, and unit/bloc tests. Views/widgets untouched.

## CONTRACT CHANGES

None. Public names match `1_plan.md` §b exactly (`PaywallLoadRequested`,
`PaywallTrialStarted`, `PaywallRestoreRequested`, `PaywallState` with
`status` + `action: PaywallAction{idle,working,success,failure}`), plus the
`PaywallRequest{none,trial,restore}` discriminator foreseen in `2_build.md`
(trial must not call `startTrialNow()` on the restore path and vice versa).
The parallel UI builder codes against these names — the view already
consumes them (`paywall_view.dart:43-68,682-721`, read-only check, no edit).

One documented deviation from the plan (from `2_build.md`, kept): the view
uses `GetIt.instance<AppSession>()`, not `context.read<AppSession>()`,
because `AppSession` is registered in GetIt (`app/lib/app/di.dart`) but is
not a Provider ancestor (`app/lib/app/app.dart`). Read-only use, no shared
edit needed.

## Files changed

No edits were needed this stage — the logic layer in HEAD already
implements the plan, and this stage verified it (`dart format`: 0 changed,
`flutter analyze`: No issues found). Files verified (not modified):

- `app/lib/features/paywall/presentation/bloc/paywall_event.dart` — both
  action events present.
- `app/lib/features/paywall/presentation/bloc/paywall_state.dart` —
  `action` + `request` + `copyWith(clearError:)` present.
- `app/lib/features/paywall/presentation/bloc/paywall_bloc.dart` —
  `_onTrialStarted` (`startTrial()` → success/failure) and
  `_onRestoreRequested` (`activate()` → success/failure); double-tap guard
  (`if working return`) so a rapid second tap is a no-op.
- `app/lib/features/paywall/data/paywall_repository_impl.dart` — upsert
  writes (P01 BUG-4 class fixed); static annual plan detail carries the
  design copy: sub without stray full stop, caption with "the", tag
  included, em-dash separators.
- `app/lib/features/paywall/domain/**`, `paywall_di.dart`,
  `paywall_routes.dart` — unchanged, contract-stable.
- `app/test/features/paywall/paywall_bloc_test.dart` — 25 tests, pin the
  `PaywallStatus` machine, action transitions (working→success|failure with
  discriminator), and the Drift repository under demo/empty/fresh seeds.

## Items done (FIXES_1, logic layer only)

- P07-BUG-2 (logic part): trial/restore events, action state, request
  discriminator, double-tap guard — done; session writes + navigation are
  the view's job (already wired per read-only check above).
- P07-BUG-3 (caption "the"): `detail` contains
  `£29.99/year after the 14-day trial.` — done.
- P07-BUG-4/5 (detail punctuation + tag): no `billed yearly.`, tag
  `One price, the whole family` reachable from the data layer — done.
- P07-BUG-6 (stale error): `clearError` path used on load and both
  actions — done.
- P07-BUG-7 (UPDATE-only writes): `_upsert` mirrors `AppSession._write` —
  done.
- P07-BUG-8/9: shared code (`app_session.dart`, `router.dart`) — NOT this
  layer; `SHARED_REQUEST.md` already filed, proofs stay `skip: true`.
- P07-BUG-3 (bottom-bar order): view/core concern — UI builder's, not mine.
- No `google_fonts`/`GoogleFonts` or `pip_stage_*` references in the
  feature's non-UI code (grep clean).

## Evidence

- `dart format lib/features/paywall test/features/paywall/paywall_bloc_test.dart` → 0 changed.
- `flutter analyze lib/features/paywall test/features/paywall/paywall_bloc_test.dart` → No issues found!
- `flutter test test/features/paywall/paywall_bloc_test.dart` → +25 All tests passed.
- `p07_bugs_test.dart --plain-name '[P07-BUG-4]'` → pass (un-skipped).
- `--plain-name '[P07-BUG-5]'` → +2 pass (un-skipped).
- `--plain-name '[P07-BUG-6]'` → pass (un-skipped).
- `--plain-name '[P07-BUG-7]'` → pass (un-skipped).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Widget/view proofs (BUG-1/2/3 groups,
`paywall_view_test.dart`) belong to the UI builder; whole-app `flutter
test` and the simulator belong to the integrator. Note:
`app/test/features/paywall/zz_debug_test.dart` (semantics dump, UI
builder's debug helper) was left untouched — not mine to remove.

VERDICT: PASS
