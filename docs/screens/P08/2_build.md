# P08 · Today (home) — build notes (Stage 2, iteration 3)

Built per `1_plan.md` + every item in `FIXES_2.md` + the stage brief's
PERIODS ruling. The 4 skipped proofs (P08-B11 ×3, P08-B12) are unskipped and
pass; the 2 unskipped regression pins still pass.

## Files changed (all RULES §1-legal)

Lib (`app/lib/features/today/**`):

- `data/today_repository_impl.dart` — **P08-B11**: `_statusOf` now takes the
  `Quest` + a single `now` and applies `countsForCurrentPeriod(repeatRule,
  latest.createdAt, now)` (daily → London day, weekly → London week, once →
  forever); stale completions read `to_do`, and `done`/progress derive from
  the scoped statuses. `rows()` gained an optional `now` (one clock read per
  call so sort and rows agree). New clock seam:
  `TodayRepositoryImpl({required this._db, DateTime Function()? clock})`
  defaulting to `Seed.anchorOverride ?? DateTime.now().toUtc()` — tests pin
  the anchor (story "today"), production uses the wall clock, so demo
  assertions ("4 of 6", banner 3) are date-independent. No DI change needed.
- `presentation/bloc/today_state.dart` — m4: `pendingCount` doc now says
  family-wide DB count, not "items with done_pending".
- `presentation/widgets/today_loaded_body.dart` —
  - **P08-B12**: new `_PushOnce` StatefulWidget (per-push-site `_busy` flag,
    cleared when the pushed page pops) wrapping Review, `+`, quest rows and
    P08b `Add a quest`. `go` destinations need no guard. (A
    `ModalRoute.isCurrent` check would not work: both taps run before the
    Navigator rebuilds.)
  - m10: `sofa` tint arm documented as unreachable-by-construction.
- `today_view.dart` / `today_empty_view.dart` — untouched this iteration.

Tests (`app/test/features/today/**`):

- `p08_bugs_test.dart` — 4 skips removed; all 11 + 4 + 2 green.
- `today_view_test.dart` — m5: the three-children test now also asserts
  Sam's card is ≈170 px wide (measured after scrolling it into view;
  `NestCard.at(2)` only exists once built).
- Expectations updated for the ruling (Leo `done 1` / `1 of 4 quests` —
  see below; scroll loops already follow render order).

## Fix-item ledger (FIXES_2 refs)

- **P08-B11 (major)** — fixed as above. Consequence worth stating: Leo now
  renders **1 of 4 quests** (was "2 of 4"): `q-bag` repeats `daily` and its
  approval is from the previous London day, so per the ruling it is "to do"
  again. The design mock's "2 of 4" predates the ruling; the brief's
  ORCHESTRATOR RULES + PERIODS section explicitly override design PNGs, and
  DATA OVER MOCKS says the DB is right — the expectation (not the code) was
  updated, in P08's tests and filed for the shared contract test
  (`SHARED_REQUEST.md` §8, blocking).
- **P08-B12 (minor)** — fixed as above; proof also asserts one system-back
  returns to `Today's quests`.
- **m4** (pendingCount doc) — fixed. **m5** (grid width assertion) — added.
  **m10** (sofa arm) — commented.
- **m6** ("Happy week: 0 days" for a childless family) — left: P08b header
  copy is that loop's scope. **m8** (liveRegion re-announce) — still
  deferred. **m9** (`happyDays` write-only) — kept as the seam (the ledger
  allows keep-or-drop). **m11** (watcher count) — unchanged, not
  user-visible. **B16/C9** (balance wrap) — accepted platform limit, note
  only. **B21/C11/m7** (P08b) — that loop's scope.
- **M1** (Bolt placeholder under Reduce Motion) — resolved on main
  (`f6b02d8`); the regression pin passes; no filing needed. **M2/M3** —
  process items per the brief ("handled by the loop and the orchestrator"),
  not reported as findings.
- **B11.5** (should the banner be period-scoped?) — kept family-wide so the
  banner ≡ the P11 list; filed as `SHARED_REQUEST.md` §9 for a ruling.

## Verification tails

- `dart format .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!` (whole app).
- `flutter test test/features/today` → `All tests passed!` (+86).
- `flutter test` (full) → `+458 −1`; the single failure is the **shared**
  `test/core/data/repositories_test.dart` (`leo.done == 2`, pre-ruling
  number) — screen agents may not touch shared files (RULES §1), filed as
  `SHARED_REQUEST.md` §8 (blocking).
- `shot.sh` light + dark + empty from final sources (all newer; all three
  read back). Every run warns `frame never stabilised in 25 s` — shared §6
  (`DISABLE_ANIMATIONS=1` parses to false, Rive idle loop runs); captures
  are complete. Two dark captures in a row showed another screen entirely
  (K03 kid-home, then springboard) — parallel-loop contention on the shared
  simulator; a third run captured the correct screen.
- `compare.py`: light mean **5.20 %**, dark **4.84 %**. Residual is
  data-driven: live date (`Fri 2 Oct` vs mock `Sat 4 Oct`), ruling-driven
  Leo count/repeat labels, all 10 real rows vs the mock's 5, banner
  balance-wrap. Dark: zero theme branches, everything flips.

VERDICT: FAIL
