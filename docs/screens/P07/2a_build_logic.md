# P07 Paywall — Stage 2a logic chunk (iteration 3)

Scope: non-UI layer only — `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, and unit/bloc tests. Views/widgets untouched (the
parallel UI builder owns them; its in-flight view edits are visible in
`git diff` but were not made here).

## CONTRACT CHANGES

One additive repository method (no event/state shape change — the UI
builder's contract is untouched):

- `PaywallRepository.readSubscription()` → `Future<SubscriptionStatus>`
  (one-shot read; missing row → `trial`/null, same default as
  `watchSubscription()`). All existing fakes keep compiling: the only
  behavioural override is in `PaywallRepositoryImpl` (direct SELECT) and
  the bloc-test fake (canned value); the other two fakes delegate to
  `watchSubscription().first`, preserving exact legacy semantics.

Behavioural note (no shape change): a trial tap while the subscription is
already `active` now emits `success` with `request: restore` instead of
`request: trial`, so the view takes its restore branch
(`setSubscription('active')` — a no-op for a paying family — +
`completeOnboarding()` → `/today`) rather than regressing the user to
`trial`. Events, `PaywallAction`, and `PaywallRequest` are unchanged.

## Files changed

- `app/lib/features/paywall/domain/paywall_repository.dart` — added
  `readSubscription()` with a `watchSubscription().first` default.
- `app/lib/features/paywall/data/paywall_repository_impl.dart` —
  overrode `readSubscription()` with a one-shot SELECT. Rationale
  (probe-verified): awaiting a fresh Drift watch stream inside a widget
  test never resolves (`watch().first` stayed pending over 3 s of pumped
  time while the SELECT returned immediately), so the guard cannot use
  the watch stream. Plain unit tests are unaffected.
- `app/lib/features/paywall/presentation/bloc/paywall_bloc.dart` —
  P07-BUG-12 guard in `_onTrialStarted`: if `readSubscription()` is
  `active`, skip `startTrial()` and emit `success(restore)`; read errors
  fail open to the legacy trial path. Double-tap `working` guard kept.
- `app/test/features/paywall/paywall_bloc_test.dart` (my file) — fake
  gained `subscription`/`failSubscription` + `readSubscription()`
  override; 4 new tests: active-tap emits working→success(restore) with
  zero `startTrial` calls, fail-open on unreadable subscription,
  `readSubscription` matches the watched status under demo/empty/fresh.
- `app/test/features/paywall/p07_bugs_test.dart` — un-skipped
  `[P07-BUG-12]` (now passing); added the one-line `readSubscription`
  stub `_FlakyRepository` needs to compile (delegates to the watch
  stream; that fake never reads subscriptions).
- `app/test/features/paywall/paywall_view_test.dart` — same one-line
  `readSubscription` stub on its fake (empty watch stream → fail-open,
  byte-identical legacy behaviour). No other touch; view expectations
  untouched.

## Items done (FIXES_2, logic layer only)

- P07-BUG-12 (minor) — FIXED end-to-end from this layer: proof
  un-skipped and green (status stays `active`, `trial_start` untouched,
  → `/today`). The `paywall_bloc_test` pin "activate then startTrial is
  reachable (trial wins, by design)" stays valid as the raw repository
  contract — the guard lives only in the bloc action path.
- Iteration-1 bugs 1–7 proofs: still green (no logic-layer change except
  the guarded trial path, which is fail-open for every fake).
- P07-BUG-10/11: view layer — the UI builder fixed and un-skipped both
  in parallel (visible in the worktree diff); not touched here.
- P07-BUG-8/9: shared code — remain `skip: true`, `SHARED_REQUEST.md`
  already filed; untouched.
- UI deviations 1–4 (legal row, CTA panel, overlap, title orphan):
  view/design-system — not this layer.
- No `google_fonts`/`GoogleFonts` in the feature (grep clean);
  ORCHESTRATOR_NOTES item 1 holds (both success paths still
  `completeOnboarding()` → `/today`).

## Evidence (`app/`)

- `dart format` on touched files → clean.
- `flutter analyze lib/features/paywall test/features/paywall/` →
  No issues found!
- `flutter test test/features/paywall/paywall_bloc_test.dart` → +29,
  all passed.
- `flutter test test/features/paywall/p07_bugs_test.dart --plain-name
  '[P07-BUG-12]'` → pass (un-skipped).
- `flutter test test/features/paywall/` → +100 ~2, all passed (the 2
  skips are the shared BUG-8/9 proofs).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. Whole-app `flutter test`, simulator shots,
and the view-side BUG-10/11 verification belong to the UI builder /
integrator. A temporary probe test used to diagnose the watch-stream
hang was deleted.

VERDICT: PASS
