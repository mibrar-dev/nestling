# P08b · 2a_build_logic — non-UI layer (iteration 1)

Scope: `today` domain/data/bloc + DI/routes only. No views/widgets edits.

## CONTRACT CHANGES

None. Events (`TodayLoadRequested` only), state shape, repository interface,
DI registration and route paths are all unchanged. UI builder codes against
the existing `TodayState` fields (`greeting`, `parentName`, `dateLine`,
`summaries`, `pendingCount`).

## Files changed

- `app/lib/features/today/presentation/bloc/today_bloc.dart` — plan §b, the
  ONE bloc change: empty summaries now yield the static design suffix
  `dateLine = '<day> · A fresh nest'` (middle dot U+00B7, as before) instead
  of `Happy week: 0 days`. Gated behind `summaries.isEmpty`, so the P08
  demo-seed path (never empty) is byte-identical. Clock still via
  `appNowUtc()`; greeting still via `dayPartForHour(toLondon(now).hour)`.
- `app/test/features/today/today_bloc_test.dart` — extended the existing
  `empty streams load with empty lists and no banner` blocTest to assert
  `dateLine == '<day> · A fresh nest'`.

## Items done (plan §b)

- [x] No new event; no repository change (`watchItems`, `watchSummaries`,
  `watchParentName`, `watchPayoutDay`, `watchPendingCount` unchanged).
- [x] Empty-state dateLine suffix implemented + covered by bloc test.
- [x] No `DateTime.now()`, no `google_fonts` in code or touched tests.
- [x] DI (`today_di.dart`: Drift repo singleton + `TodayBloc` factory) and
  routes (`today_routes.dart`: `/today-empty` → `TodayEmptyView` +
  `TodayLoadRequested`) verified already correct — no edit needed.
- [x] Shared tab-bar move (§g) NOT attempted here: it needs
  `app/lib/app/router.dart`, which RULES §1 forbids. Left for
  `SHARED_REQUEST.md` (UI builder / orchestrator owns that file).

## Verification

- `flutter analyze lib/features/today` → No issues found.
- `flutter test --timeout 120s test/features/today/today_bloc_test.dart test/features/today/today_repository_test.dart` → All tests passed (35).
- `dart format` on both touched files → clean (0 changed).

## LEFT FOR NEXT ITERATION

Nothing in this layer. Remaining P08b work is UI-builder owned
(`TodayEmptyLoadedBody`, `_EmptyGreeting`, `_EmptyCard`, tip card per plan
§a; view/semantics/alignment tests per plan §f).

VERDICT: PASS
