# P08 · Today (home) — build notes (Stage 2, iteration 1)

Implemented exactly per `docs/screens/P08/1_plan.md` (§a–§g).

## Files changed (all RULES §1-legal)

- `app/lib/features/today/domain/entities/today_item.dart` — added
  `repeatRule` (default `''`) and `iconKey` (default `''`) to `TodayItem`.
- `app/lib/features/today/domain/entities/child_day_summary.dart` — added
  `ageYears: int?` and `happyDays` (default `0`).
- `app/lib/features/today/domain/today_repository.dart` — added
  `watchParentName()` and `watchPayoutDay()` (plan §b; payout day drives
  `· Weekly · Sat` meta text, read from `families.payout_day`).
- `app/lib/features/today/data/today_repository_impl.dart` — carries
  `repeatRule`/`iconKey` in `rows()`; summaries carry `ageYears`/`happyDays`
  and sort eldest-first (Maya 9 before Leo 6, then nickname); new streams
  read `members` (owner row, else first by name, else `'Sarah'`) and
  `families` (else `6`). No schema/seed change.
- `app/lib/features/today/data/models/today_item_model.dart` — new fields in
  ctor + `fromJson`/`toJson`.
- `app/lib/features/today/presentation/bloc/today_state.dart` — extended
  state: `summaries`, `pendingCount`, `parentName` (`'Sarah'`),
  `greeting` (day part), `dateLine` (`Sat 3 Oct · Happy week: 4 days` shape,
  via `london_time.dart`), `happyDays`, `payoutDay` (`6`).
- `app/lib/features/today/presentation/bloc/today_bloc.dart` — single
  `emit.forEach` over nested `combineLatest2(watchItems+watchSummaries,
  watchParentName+watchPayoutDay)` (contract-compliant, no re-added events);
  pure `dayPartForHour()` helper. `pendingCount` = `done_pending` rows;
  `happyDays` = max over summaries.
- `app/lib/features/today/presentation/widgets/today_loaded_body.dart` (new)
  — shared `TodayLoadedBody` (+ `TodayFailureBody`, `TodayStatusChip`, icon /
  tint / repeat / Pip / avatar maps). Greeting row, leaf-tint approvals
  banner (hidden when 0), kids 2-up `Expanded` grid, `Today's quests` header,
  `MAYA · 9` group labels, `NestQuestCard(maxLines: 2)` rows with coin pill +
  repeat + status chip in HTML order, `Hand to …` button, P08b empty card.
  Zero theme branches (tokens only). Navigation per plan §c:
  `+`→`/quest-editor`, avatar→`/settings`, Review→`/approvals`, kid
  card→`/child-profile?childId=`, See all→`/quests`, quest
  row→`/quest-editor?questId=`, Hand→`/who-is-playing`.
- `app/lib/features/today/presentation/views/today_view.dart`,
  `today_empty_view.dart` — placeholder replaced; both render the shared body
  (empty card appears when `summaries.isEmpty`, i.e. `Seed.empty()`).
- `app/test/features/today/` (new) — `today_repository_test.dart` (10 rows,
  α-order, latest-completion wins incl. newer `done_pending`/`not_yet`
  inserts, Maya 4/6+120 / Leo 2/4+45, parent `Sarah`, payout `6`, model
  round-trip), `today_bloc_test.dart` (loaded with counts, error→failure,
  empty streams, `dayPartForHour` boundaries), `today_view_test.dart`
  (light content + all navigation taps, dark content, empty card + Browse
  ideas, 320-wide + textScale 1.3 no-overflow + ≥44 taps; every widget test
  ends with `disposeApp`).

## Fix items (plan had no numbered fix list; deviations/decisions)

- Plan test expected the header date `Sat 3 Oct`; the header shows *today*
  (live `DateTime.now` via `london_time`), so tests compute the expected date
  string at runtime instead. Seed-anchor note concerns static content only.
- Group order: DB streams are α-ordered (Leo first); view/summaries use
  eldest-first so Maya leads, matching the design.
- All 10 assigned quests render (design mock shows 5 of 10); scroll handles it.
- Status chip: first built as fixed-height `Container(alignment: center)` —
  screenshots showed it stretching full-width on its own Wrap line, and a
  `Row` variant overflowed at 320/1.3 (nested flex-in-flex). Final: padding-
  sized pill (26px at base scale) as a direct `Wrap` child — one line at 390,
  graceful wrap at 320, zero overflow.
- No `SHARED_REQUEST` needed for the build itself (sofa/plate icons fall back
  to `table`/`questCard` in-feature). One request filed for the stale shared
  router test (see below).

## Verification tails

- `dart format .` → `Formatted 342 files (0 changed)`.
- `flutter analyze` → `No issues found!` (whole app, incl. info lints).
- `flutter test test/features/today` → `All tests passed!` (+22).
- `flutter test` (full) → `+308 -1`; sole failure is the shared
  `test/app/router_redirect_test.dart` (`onboarded parent lands on Today`
  expects the removed placeholder text `P08 Today`). Screen agent may not
  touch shared files (RULES §1) — filed as `SHARED_REQUEST.md` (blocking).
- `shot.sh` light + dark + empty screenshots in `docs/screens/P08/ui/`;
  `compare.py` vs `design/screens/light/P08-today.png` → mean diff 6.66%
  (bands 4.6–9.4%). Residual is content, not spacing: live greeting/date
  (`Good evening / Thu 1 Oct` vs mock `Good morning / Sat 4 Oct`) and all 10
  real quest rows vs the mock's 5. Meta-row geometry, banner, kid cards and
  tab bar align with the design.

VERDICT: FAIL
