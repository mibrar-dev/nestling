# P08 · Today (home) — bug hunt (Stage 6, iteration 3)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seeds `Seed.demo()` / `Seed.empty()`. **No screen code was changed.** Re-hunted
the iteration-3 working tree (after the iteration-3 fix pass and `main`
merges `5eea2ad`, `dec0c28`, `1a279ff`).

`app/test/features/today/p08_bugs_test.dart` now has 20 tests: the 11
iteration-1 proofs and the 2 iteration-2 proofs (all unskipped, green) plus
the **3 new skipped proofs** below and 4 unskipped regression pins (once /
Reduce Motion / B11 / B12). Run the proofs with
`flutter test --run-skipped test/features/today/p08_bugs_test.dart` — all 3
fail against the current screen, by design.

## Iteration-2 ledger — closed

| ID | Iteration-2 finding | Status / proof |
|---|---|---|
| P08-B11 | period scoping missing in `rows()` | fixed — `_statusOf` uses `countsForCurrentPeriod` + injected clock (`today_repository_impl.dart:171-192`); proofs green, clock-owned boundary tests in `today_repository_test.dart` |
| P08-B12 | rapid double-tap stacked two editors | fixed — `_PushOnce` guard; proof green (see P08-B14 for its one hole) |
| Reduce-Motion pin | Bolt fallback was a dashed placeholder | fixed on `main` (`f6b02d8`); regression pin green |

## New findings (this iteration)

### P08-B13 — the approvals banner count ignores the periods ruling — MAJOR

- **Where:** `app/lib/features/today/data/today_repository_impl.dart:116-126`
  — `watchPendingCount()` counts **every** family-wide `done_pending`
  completion with no `countsForCurrentPeriod` filter, while every quest row
  (`:186-192`) is period-scoped. Also raised by `4_review` iteration 3 as its
  B2 and filed as `SHARED_REQUEST.md` §9 (pending a ruling).
- **Why it is a bug, not a taste call:** the ruling repeated in this stage's
  brief is *"a quest's status counts only for its current period … a
  completion outside the period means the quest is 'to do' again."* A stale
  `done_pending` is therefore no longer a pending status, yet the banner
  counts it. The label claims *"N quests waiting for your thumbs-up"* above a
  list with fewer "Needs a look" rows, and the stale completion still reaches
  P11, so a parent can approve and pay (P13 pays per approved completion) for
  a quest the child may immediately do — and be paid for — again. The review
  classified it major for the same double-payout reason.
- **Repro:** `flutter test --run-skipped test/features/today/p08_bugs_test.dart
  --plain-name '[P08-B13]'`
  - repository: insert a `done_pending` for daily `q-reading` before today's
    London day start → row reads `to_do` (correct), but
    `watchPendingCount()` returns **4** where the 3 seeded current-period
    pendings remain → expected **3**;
  - widget: the same data renders *"4 quests waiting for your thumbs-up"*
    above three current "Needs a look" rows → expected *"3 quests waiting for
    your thumbs-up"*.
- **Failing tests:**
  `[P08-B13] a stale pending completion does not count in the banner total`,
  `[P08-B13] the banner count matches the current-period rows`.
- **Suggested fix (feature-local):** scope `watchPendingCount()` the same way
  the rows are scoped — combine `watchAllCompletions` with the quests, keep
  only `done_pending` completions where
  `countsForCurrentPeriod(rule[c.questId] ?? 'once', c.createdAt, _clock())`
  (default `'once'` so a pending on an inactive/removed quest is not silently
  dropped; those count forever), then `.length`. Add the two proofs to the
  suite and unskip. **Coordinate with the P11 loop** (`§9`): if P11 keeps
  listing stale pendings, the two screens will still disagree — the ruling
  should land on both, or the banner label must change.

### P08-B14 — `_PushOnce` latches when the pushed page is replaced by `go` — MINOR

- **Where:** `today_loaded_body.dart:252-266`. `_busy` is set on tap and
  cleared **only** when `context.push(...)` completes; a pushed page that
  navigates home with `go` (the pattern P09/P11 may legitimately use — §4 asks
  for `pop`, but the guard must not depend on another screen's contract)
  replaces the stack without ever completing the push future.
- **Repro:** `--run-skipped … --plain-name '[P08-B14]'`
  - tap `+` → editor pushed;
  - the pushed page calls `go('/today')` → back on Today;
  - tap `+` again → **nothing happens** (probe: second-push editor count 0).
  The guard never clears, so `+`, Review, every quest row and P08b's
  "Add a quest" stay dead for the life of the screen. Related: if
  `context.push` itself throws, `unawaited(_pushAndClear())` leaves an
  unhandled async error and the same latch.
- **Failing test:** `[P08-B14] a pushed page navigating with go() unlatches it`.
  (First raised by `4_review` iteration 3 as B4; this stage proved it.)
- **Suggested fix:** do not couple the guard's lifetime to the push future
  alone — clear `_busy` when the route is no longer current (a
  `NavigatorObserver`/`RouteObserver` `didPopNext`/`didRemove`, or listen to
  the router's delegate) and wrap the await in `try/finally`; alternatively
  replace the latch with a short time-window debounce (ignore re-taps within
  ~500-600 ms), which cannot latch by construction. Keep `push` semantics.

## External blocker (shared, not P08-editable)

- **`4_review` B1 / `SHARED_REQUEST.md` §8** — `flutter test` (full) is red on
  the shared contract test `test/core/data/repositories_test.dart`
  ("today Maya 4 of 6, Leo 2 of 4": expected `2`, actual `1`). The periods
  ruling invalidated the pre-ruling expectation (`q-bag` is daily and its
  approval is yesterday's), so the one-line fix is `expect(leo.done, 1)` in a
  file RULES §1 forbids this agent to touch. It blocks RULES §7.1's
  full-suite-green requirement for the screen until the orchestrator lands it.

## Carried minors from `4_review` iteration 3 (still open)

- **B3** statuses are not re-evaluated at a day/week rollover while the app
  stays open (needs the same treatment on every per-period screen → shared
  note).
- **B5** period boundary tests duplicate the `flutter_test_config.dart` pin as
  literals (drift risk).
- **B6** non-Mochi still art is only covered by P08's regression pin; the
  shared `pip_avatar_test.dart` still loops Mochi only (`§10`).
- **B7** `shot.sh` cannot produce a stable frame until shared `§6`
  (`DISABLE_ANIMATIONS=1` never parses) is fixed.
- **B8** childless family header still reads "Happy week: 0 days" (P08b
  header copy is that loop's scope).
- **B9** P08b content inset 36 px vs the design's 20 (P08b loop).
- **B10** `liveRegion` banner re-announces on unrelated emissions (deferred).
- **B11** `TodayState.happyDays` is write-only (kept as a seam).
- **B12** the three-child copy test in `today_view_test.dart` still lacks the
  grid-width assertion (P08's `p08_bugs_test.dart` B05 proof has it).
- **B13** ~10 Drift watchers per open (perf smell, not user-visible).

## Owner rules — re-verified on the iteration-3 shots

- **Bottom edge:** read `ui/app_light_3.png` and `ui/app_dark_3.png` with the
  file reader — the tab-bar surface runs to the physical bottom edge in both
  themes (`rgb(255,255,255)` light / `rgb(31,28,46)` dark; the home pill is
  the only different element). No meadow/tint strip. Pass.
- **Alignment:** header, banner, kid cards, quest cards and the tab labels all
  sit on the same 20 px gutters in both shots; the review's numeric check
  (every card `x 20.00 → 369.67`) matches. Pass.

## Checked, no bug found (this iteration)

- Parent/kid guard (`/today`, `/today-empty`, `/quest-editor`), deep links,
  back navigation from approvals/editor (`push` + `handlePopRoute` proofs
  green).
- Rapid double-taps on the four push sites are blocked by `_PushOnce` (B12
  proof green) — its latch hole is P08-B14 above.
- Restart persistence unchanged; period statuses recompute from the DB and
  the injected clock on every load.
- Single-double-tap on `go` destinations (`/settings`, `/child-profile`,
  `/who-is-playing`, `/quests`) is idempotent.
- Dark-mode contrast, 320 px / 1.3x, long UK names, 0/1/6 children, empty
  lists, 9999 coins all covered by the existing suites; P08 shows coins only,
  so £0.00/£999.99 and integer-pence rounding do not apply.
- Europe/London/BST maths: `countsForCurrentPeriod` + day/week starts are
  correct incl. the 25 Oct 2026 switch (`test/core/london_period_test.dart`
  and the repository's boundary group).
- Emit-after-close / failed-stream retry: `_closeOnError` + bloc cancellation;
  proof green.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test test/features/today` → **96 passed, 3 skipped, 0 failed**.
- `flutter test` (full) → **468 passed, 3 skipped, 1 failed** — the one
  failure is the shared `repositories_test.dart` expectation above (`§8`),
  not P08 code. The 3 skips are this stage's proofs.

## Verdict

One new **major** bug (P08-B13 — the banner contradicts the mandatory periods
ruling and can route a stale completion into a double payout) plus one minor
(P08-B14), and a shared blocker that keeps the full suite red. No PASS is
possible.

VERDICT: FAIL
