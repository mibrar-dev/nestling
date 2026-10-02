# P08 · Today (home) — bug hunt (Stage 6, iteration 2)

Route `/today` (+ `/today-empty` · P08b), feature `today`, mode parent,
seeds `Seed.demo()` / `Seed.empty()`. **No screen code was changed.** Re-hunted
the iteration-2 working tree (after the fix pass and `main` merges `b0809f6`,
`f6b02d8`, `e7ad050`).

The feature suite now has 86 tests
(82 passed, 4 skipped). `p08_bugs_test.dart` itself has 17: the 11
iteration-1 proofs (unskipped, green), **4 new skipped proofs** for the two
findings below, and 2 unskipped regression pins. Run the proofs with
`flutter test --run-skipped test/features/today/p08_bugs_test.dart` — all 4
fail against the current screen, by design.

## Iteration-1 ledger — all 11 fixed and re-verified

| ID | Iteration-1 finding | Status / proof |
|---|---|---|
| P08-B01 | kid mode could open `/today-empty` | fixed on `main` (`ded8eb9`); proof green |
| P08-B02/B03 | v1 Pip SVGs instead of per-child `PipAvatar` | fixed; proofs assert Maya mochi·sunny·3 / Leo bolt·sky·2, P08b mochi·1 |
| P08-B04 | questless children invisible | fixed (`watchSummaries` from `watchChildren`); proof green |
| P08-B05 | kids grid N-up, 3+/6 children | fixed (pair chunking); proofs green + new width assertion (170 px) |
| P08-B06 | banner ignored family-wide pendings | fixed (`watchPendingCount`); proof green |
| P08-B07 | back from Review exited the app | fixed (`push`); proof green |
| P08-B08 | retry leaked watchers | fixed (`_closeOnError`); proof green |
| P08-B09 | single child card 350 px | fixed (`Row + Spacer`); proof green |
| P08-B10 | quest rows α-sorted | fixed (rank then title); proof green |

Carried C1–C15 from the iteration-1 list: fixed or dispositioned in
`2_build.md` (accepted: C9/B16 balance wrap; deferred: C10/B17 liveRegion,
C11/B21 P08b polish; shared: C13 §2, C14 §5, §6, §7).

## New findings (this iteration)

### P08-B11 — a quest's status ignores the mandatory period ruling — MAJOR

- **Where:** `app/lib/features/today/data/today_repository_impl.dart:154-168`
  — `_statusOf()` returns the latest completion's raw status with no
  `countsForCurrentPeriod` check, and `rows()` (`:119-152`) never passes the
  quest's `repeatRule` or a `now`. The summaries' `done` count (`:59-64`)
  inherits the stale statuses.
- **Rule:** `ORCHESTRATOR_NOTES.md` §"Ruling on 'done today'" (K03-BUG-4):
  *"treat a quest's latest completion as current only if
  `countsForCurrentPeriod(quest.repeatRule, completion.createdAt,
  DateTime.now().toUtc())`; otherwise the quest is 'to do'."* The ruling is
  restated in this stage's brief. Stages 2/3/5 claimed it done; the feature
  contains no call to `countsForCurrentPeriod` (grep: only `core/data/
  london_time.dart` and `test/core/london_period_test.dart` reference it).
- **Repro:** `flutter test --run-skipped test/features/today/p08_bugs_test.dart
  --plain-name '[P08-B11]'`
  - daily quest with a completion *before today's London day start* →
    expected `to_do`, actual `approved`;
  - weekly quest with a completion *before this London week's start* →
    expected `to_do`, actual `approved`;
  - Maya's kid card with one stale daily approval → expected `4 of 6 quests`,
    actual `5 of 6 quests` (probe measured `5of6=1, 4of6=0`).
- **Failing tests:**
  `[P08-B11] a daily completion from the previous London day is to do`,
  `[P08-B11] a weekly completion from last week is to do again`,
  `[P08-B11] the kid card count excludes stale completions`.
  Unskipped pin (passes now and must keep passing):
  `[P08-B11] a "once" completion from years ago still counts`.
- **Suggested fix (feature-local, `data/`+`domain/` only):**
  1. `_statusOf(Quest quest, String childId, List<QuestCompletion>
     completions, DateTime now)`: keep the latest completion; if `latest ==
     null` → `'to_do'`; else `countsForCurrentPeriod(quest.repeatRule,
     latest.createdAt, now) ? latest.status : 'to_do'`.
  2. Pass the `Quest` (not just its id) and a single
     `now = DateTime.now().toUtc()` computed once per `rows()` call
     (sort and rows must agree).
  3. `done`/progress follow automatically — they are derived from item
     statuses.
  4. **Testability caveat:** `flutter_test_config.dart` pins only
     `Seed.anchorOverride`, not the wall clock. With a hard-wired
     `DateTime.now()`, the demo assertions ("4 of 6", pending chips) become a
     time bomb — they pass while the real date sits within the seed's
     London day/week and fail after. Inject a clock seam
     (`TodayRepositoryImpl({required db, DateTime Function()? clock})`,
     default `() => DateTime.now().toUtc()`) and pin it in tests, or pin
     `now` the same way `Seed.anchorOverride` is pinned. (The ruling's
     "do not hard-code dates" still holds.)
  5. Decide explicitly whether `watchPendingCount` (approvals banner) should
     also be period-scoped. Today it is family-wide to match P11, and P11
     lists every `done_pending`; if the banner is scoped but P11 is not, the
     Review list will disagree with the count. Flag for the orchestrator
     rather than guessing.

### P08-B12 — a rapid double-tap pushes two pages — MINOR

- **Where:** `today_loaded_body.dart:658` (quest row), `:376` (`+`), `:460`
  (Review) — `context.push` with no in-flight guard. The taps land before the
  first frame rebuilds, so each runs its own push.
- **Repro:** `--run-skipped … --plain-name '[P08-B12]'` — double-tap
  "Empty the dishwasher": two `/quest-editor?questId=q-dishwasher` pages are
  stacked (`skipOffstage: false` count = 2; probe: after the first system back
  the editor is still on screen for a second back). `+` and `Review` behave
  the same.
- **Failing test:** `[P08-B12] a rapid double-tap opens one quest editor`.
- **Suggested fix (feature-local):** guard the push while a navigation is
  already in flight — e.g. `if (ModalRoute.of(context)?.isCurrent ?? true)
  context.push(...)`, or hold a local `_pushing` flag cleared on return; keep
  `push` (the back-stack contract from B07). Re-run the proof (it also
  asserts one back returns to `Today's quests`).

## Resolved during this stage

- **4_review M1 — Reduce Motion drew the dashed Pip placeholder for Leo.**
  Was real (probe: `bolt/placeholder.svg` for Leo). `main` `f6b02d8`
  ("PipAvatar fallback: approved art for every style") landed while this
  stage ran and is merged (`e7ad050`); the new unskipped regression pin
  *"Leo's Pip renders real art, not the placeholder"* passes. With §6 fixed,
  the screenshots will now fall back to real art rather than placeholders —
  the §6/§8 coupling noted in `4_review` is no longer a hazard.
- **M3 — branch behind `main`.** Resolved by `e7ad050`: P01's tests are
  present and the full suite is green (455 tests).

## Carried / still open

- **M2 (process).** The iteration-2 work is still uncommitted at hand-off
  (`app/` working tree modified). The loop's rule "process items are not
  review findings" applies; the orchestrator commits between stages.
- **m4** `TodayState.pendingCount` doc comment still describes it as "items
  with status done_pending" while it is now the family-wide DB count.
- **m6** childless family header still reads "Happy week: 0 days" (P08b's own
  header copy is a separate loop's scope).
- **m7** P08b empty-card content inset 36 px vs the design's 20 (P08b loop).
- **m8** `liveRegion` banner re-announces on unrelated emissions (deferred).
- **m9** `TodayState.happyDays` is write-only (nothing reads it).
- **m10** unreachable `'sofa'` arm in `todayTintFor`.
- **m11** ~10 Drift watchers per open (re-subscription smell; not
  user-visible).
- **Shared §6** `kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS')`
  still never parses `=1` (screenshot frame stability); **§2** core card
  semantics duplication; **§4** push coordination for P09/P11; **§5** stale
  DESIGN_SPEC floating-pill line; **§7** quest-meta `runSpacing` 4 vs 6.

## Checked, no bug found (this iteration)

- Parent/kid guard: `/today`, `/today-empty`, `/quest-editor` all gated;
  `[P08-B01]` green.
- Back navigation: `push` + system back from approvals and editor returns to
  Today (proofs green).
- Restart persistence: no changes to the load path since the iteration-1
  check (approve → dispose → relaunch keeps the banner hidden, statuses
  approved).
- Dark-mode contrast (labels unchanged, tokens unchanged) and 320 px / 1.3×,
  long UK names, 0/1/6 children, empty lists, 9 999 coins, `£`/pence: all
  covered by the existing suites and iteration-1 checks; P08 still renders
  coins only, so money rounding is N/A.
- `once`/daily/weekly boundary maths: `countsForCurrentPeriod`,
  `londonDayStartUtc`, `londonWeekStartUtc` are correct incl. BST
  (`test/core/london_period_test.dart`); the gap is that the feature never
  calls them (P08-B11).
- Emit-after-close / async gaps: `_closeOnError` + bloc 9.2.1 cancellation;
  `[P08-B08]` green.

## Suite state at hand-off

- `dart format --set-exit-if-changed .` → `350 files (0 changed)`.
- `flutter analyze` → `No issues found!`.
- `flutter test test/features/today` → **82 passed, 4 skipped, 0 failed**.
- `flutter test` (full) → **455 passed, 4 skipped, 0 failed**.
- The 4 skips are this stage's proofs for P08-B11 (×3) and P08-B12; they are
  the only red results under `--run-skipped`.

## Verdict

One new **major** bug (P08-B11 — the mandatory periods ruling is not
implemented, so stale completions keep showing as done/pending and inflate
the kid-card counts) plus one minor (P08-B12). Fix them, unskip the four
proofs, and re-run the suite; B11's clock seam is part of the fix so the demo
assertions do not become date-dependent.

VERDICT: FAIL
