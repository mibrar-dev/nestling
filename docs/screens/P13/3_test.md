# 3 — TEST (iteration 1) — P13 · Payout (parent)

Route `/payout`, feature `pocket_money`, build `c34904b`. In-memory Drift via
`test_scope.setUpTestScope` + `Seed.demo()`, days pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. **No simulator was booted, installed on,
screenshot or driven** (stage rule — only `5_ui` may).

## Headline

```
dart format --output=none --set-exit-if-changed .  → Formatted 465 files (0 changed)   exit 0
flutter analyze                                     → No issues found! (4.6s)          exit 0
flutter test test/features/pocket_money             → +406 ~6: All other tests passed!  exit 0
flutter test                                        → +2217 ~6: All other tests passed! exit 0
```

**Two defects blocked the gate when I started, both inside the feature test
path, both now fixed by me — no screen code was touched.** `flutter analyze`
reported 8 issues, `dart format` wanted to rewrap one file, and
`payout_states_test.dart` **hung the suite for 10 minutes per test** on a
10-minute framework timeout (3 of its 8 tests). Details in *Gate failures
found and fixed* below.

Independently of that, the screen still carries **five open product findings**
(3 major) recorded by stages 4 and 6 and confirmed by my test run. Per the
stage rule I did **not** patch the screen; they are listed in *Bugs found* and
carried in `p13_bugs_test.dart` as skipped reproducers.

**VERDICT: FAIL** — the suite is green, but bugs were found, so the stage rule
("PASS only if all tests pass **and** no bugs were found") cannot be met.

---

## Tests added (this stage, `app/test/features/pocket_money/`)

| File | Tests | Covers |
|---|---|---|
| `payout_bloc_test.dart` | 4 | plan §f.1 — `PocketMoneyPayoutSubmitted` forwards `(maya, 420, 100, goal-lego)`; zero-save variant passes `(0, null)`; a rejected write keeps `loaded` + `We couldn’t save that` (U+2019); an accepted submit emits nothing optimistically. |
| `payout_repository_test.dart` | 4 | plan §f.2 — seeded `recordPayout` writes payout −420 + `savings_move` +100, bumps `goal-lego` 1550 → 1650, zeroes Maya's owed, leaves Leo at 210; zero-save writes only the payout row. |
| `payout_view_test.dart` | 18 | plan §f.3 — design copy from DB amounts, `Saturday payout` derived from `payout_day` (not hard-coded), creation-order rows, semantics `hasAction(tap)` + `performAction` on every control, the write path landing in the DB and popping to `/money`, scrim tap + system back, empty body (`Seed.empty`), dark copy, 320 dp @1.3, short-screen scroll. |
| `payout_widget_geometry_test.dart` | 7 | plan §f.4 — real-font pins of the CSS stack: sheet 501 tall, radius-top 32, 20 px gutters, `.child` rows 76, `.saverow` 72, CTA 350×52, `.check` 48×48, avatar 44. |
| `payout_responsive_test.dart` | 9 | light/dark × 320/390/430 × text scale 1.0/1.3. ALIGNMENT: one 20 px gutter shared by title, rows, saverow, CTA and the check column. BOTTOM EDGE (owner): sampled as a **rendered pixel** via `RenderRepaintBoundary.toImage()` — paper owns the last row at every width/theme. Tap targets ≥ 44 parent, including a tap landing on the 6 px outside the 51×31 toggle pill. |
| `payout_states_test.dart` | 8 | plan §f FIXES-left #2 (`2_build.md`) — the previously untested `failure` body: message copy, `Try again` → `PocketMoneyLoadRequested`, a healthy retry really re-subscribing, the retry exposed to VoiceOver, repeated failure still offering the retry, dark copy, 320 dp. Plus loading: never-emits spinner and first emission replacing it. |
| `p13_bugs_test.dart` | 17 | stage 6 adversarial guards: 12 active "attacks that hold", 5 skipped reproducers (one per open finding). |

Total P13 coverage: **67 tests** (62 active, 5 skipped reproducers).

## Gate failures found and fixed (test code only)

### T-1 — `payout_states_test.dart` hung the suite for 10 minutes per test (major)

**Where:** the old `_pumpView` helper (`addTearDown(bloc.close)` over a
hand-built `PocketMoneyBloc`).

**Symptom.** 3 of 8 tests died on
`TimeoutException after 0:10:00 … did not complete`. First observed as
`flutter test test/features/pocket_money` stalling at `+399 ~6` for 2½ minutes
on `payout_states_test.dart: … the first emission replaces the spinner with the
sheet`.

**Repro.** `cd app && flutter test test/features/pocket_money/payout_states_test.dart`

**Root cause.** `PocketMoneyBloc._onLoadRequested`
(`lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart:40-93`)
holds a live `await emit.forEach<MoneyLedgerData>(_repository.watchLedgerData…)`.
On the `loaded` path that Drift `QueryStream` never completes, so
`await bloc.close()` never returns. I isolated it with a temporary probe that
printed a marker around each step: the test body finished (`PROBE disposeApp
done`) and the tear-down printed `PROBE teardown: bloc.close start` and never
printed `done`.

**Fix.** Pump the real route instead of hand-building the bloc.
`pocketMoneyBloc` is a GetIt **factory** that reads `sl<PocketMoneyRepository>()`
(`lib/features/pocket_money/pocket_money_di.dart:16-18`), so `_scripted()`
registering its wrapper in GetIt *before* the pump is enough for
`payoutRoute`'s `BlocProvider` to build the bloc over the scripted stream —
and `BlocProvider` closes the bloc **without awaiting it**, which is why every
other P13 test was never affected. `p13_bugs_test.dart` already used this
pattern. The hazard is documented in the helper's doc comment and matches
`pocket_money_ledger_bloc_test.dart:802-803`, which hits the same wall and
works around it with `close().timeout(...)`.

**Result.** `8/8 pass in 5 s`. This file had been written *after* the last full
green run, which is why no earlier stage caught it.

### T-2 — `flutter analyze` reported 8 issues, `dart format` wanted 1 file (major)

Both were in my own test files, so both were mine to fix.

- `payout_responsive_test.dart:102-104` — three
  `unnecessary_non_null_assertion` on `data!` where `Image.toByteData()`
  returns `ByteData?`. Removing the `!` then produced
  `unchecked_use_of_nullable_value` (the analyzer treats the receiver as
  non-nullable after promotion, so the `!` was redundant *and* the bare call
  unsafe). Resolved with an explicit null check that throws, which satisfies
  both readings and fails loudly instead of silently sampling garbage.
- `payout_states_test.dart:39` — `comment_references`: the class doc used
  `[onWatch]`, a constructor parameter not in scope at the class.
  Reworded to backticks.
- `payout_states_test.dart:163,169,175,184` — four
  `async_return_with_no_await`; dropped the redundant `async`.
- `payout_responsive_test.dart` — not `dart format` clean. Reformatted
  (whitespace only; the diff is line-wrapping, no assertion changed).

`analysis_options.yaml` was not touched and no ignore was added.

## Bugs found (screen code — recorded, not patched)

All five are in `lib/features/pocket_money/presentation/` and are **open**.
Stages 4 (review) and 6 (bugs) found them independently; my test run confirms
all five reproducers still fail, so they are carried here rather than
re-derived. Full repro detail in `6_bugs.md`; file:line below is as of
`c34904b`.

| # | Sev | Where | One line | Repro test (skipped) |
|---|---|---|---|---|
| P13-BUG-01 | major | `views/payout_view.dart:165` `_submit` | A second tap while the write is in flight double-writes: 2 payout rows (−420 each), 2 `savings_move` rows, goal **1750** not 1650. No in-flight guard. | `p13_bugs_test.dart:354` |
| P13-BUG-02 | major | `views/payout_view.dart:174` + `widgets/payout_sheet.dart:128` | The £1.00 move is not clamped to the amount paid: a £0.50 owed writes payout −50 **and** `savings_move` +100, goal 1550 → 1650 — £0.50 that was never in the jar. | `p13_bugs_test.dart:422` |
| P13-BUG-03 | major | `views/payout_view.dart:255-263` | The scrim is not `inset: 0` (design `components.css:164`): the header stays undimmed and a tap over the title does not dismiss. UI stage measured **+152 px**. | `p13_bugs_test.dart:474` |
| P13-BUG-04 | minor | `views/payout_view.dart` listen path | A repeated identical write failure gives **no** feedback: bloc re-emits an equal state, which Bloc suppresses, so the view's `listenWhen` never fires. Measured `0` new SnackBars. | `p13_bugs_test.dart:530` |
| P13-BUG-05 | minor | `views/payout_view.dart:207` `_DimmedLedger` | The dimmed ledger stays in the semantics tree; its own doc comment claims `ExcludeSemantics` and the build method never wraps it. | `p13_bugs_test.dart:570` |

Plus **review #3** (no reproducer of its own, same view-side root as BUG-02):
a ticked child who owes £0.00 still writes a `Paid · <date> £0.00` row into
the P12 ledger, because `_submit` (`payout_view.dart:168`) iterates every ticked
child with no `owed > 0` guard while `canSubmit`
(`widgets/payout_sheet.dart:157`) only requires ≥1 child owing > 0.

Per the stage rule I did **not** touch any of this. Two of the majors
(BUG-02, review #3) share one fix — guard `_submit` on `owed > 0` and clamp
`savingsMovePence = min(100, owed)`.

## Attacks that hold (no finding)

Recorded so a regression is caught here:

- **Gated single write** — one tap → exactly one payout row (−420), one
  `savings_move` (100), goal 1650, pop to `/money`, toast
  `Payout recorded — enjoy the celebration` (U+2014). Positive control for
  BUG-01.
- **Real 320 dp @ text scale 1.3, six children** including
  "Maximilian-Alexander": creation order kept, no overflow, sheet scrolls, CTA
  operable, one payout row.
- **Real 320×568**: scrolls to the CTA, tap lands, returns to `/money`.
- **Goal child unticked, sibling paid** → only `leo:−210`, no `savings_move`,
  goal stays 1550.
- **Everyone at £0.00** → two rows render, CTA reports `enabled: false`.
- **One-child family** → one row, no stale copy.
- **Deep links** → kid mode `/payout` stops at `/parental-gate`; fresh seed
  lands on `/welcome`; launched at `/payout` with nothing to pop, the scrim tap
  reaches `/money`.
- **System back mid-write** → no exception, exactly one row.
- **Restart persistence** (file-backed) → payout, `savings_move` and the goal
  bump all survive a close/reopen.
- **Contrast** — `ink`/`ink2` on `surface`/`paper` and `onLeaf`/`leaf` all
  ≥ 4.5:1 in both themes.
- **Money maths** — every P13 amount is integer pence from
  `owedFor().totalPence`; no float parsing or rounding on this screen. The only
  money defect is BUG-02's *unclamped* move, not rounding.
- **Periods / trial / Pip / NestChipWrap / BALANCED HEADINGS** — not touched by
  P13. No `subscription_status` write, no quest-period logic, no Pip on this
  screen, no `NestChip` row, and `NestBalancedText` is correctly absent
  (`P13-payout.html` `.pay h2` sets no `text-wrap: balance`, and the rule
  forbids it on `.h2`).
- **FONTS** — `grep -rn "google_fonts\|GoogleFonts" lib/features/pocket_money
  test/features/pocket_money` → **no hits**.
- **CHILD ORDER** — rows and the saverow child both iterate `data.children`
  (creation order, Maya → Leo); asserted by position in
  `payout_view_test.dart`.
- **COPY** — ASCII `0x27` in `you've` / `Maya's`, U+00B7 in
  `Weekly + quests · `, `&` in the CTA, U+2014 in the toast — checked
  character-by-character against `design/html-source/screens/P13-payout.html`.
- **disposeApp** — every widget test that pumps the app ends with
  `disposeApp(tester)` (RULES §7.1), which drains Drift's deferred
  stream-close. No test was skipped, ignored or `@`-disabled to reach green.

## Test-suite defect (harness, not this screen)

`test_scope.pumpAppRoute` (`app/test/test_scope.dart:34-46`) hard-codes
`tester.view.physicalSize = 390×844`, so **any size a test sets before calling
it is silently overwritten**. Two `payout_view_test.dart` cases therefore pass
while running at 390 and cannot catch a 320 dp regression:

- `320 px at text scale 1.3 overflows nothing`
- `a short screen scrolls the sheet instead of overflowing`

`test/test_scope.dart` is shared and outside RULES §1, so I did not edit it.
Filed `docs/screens/P13/SHARED_REQUEST.md` asking for an optional `size`
parameter, marked both tests with a `HARNESS TRAP` comment pointing at it, and
confirmed the real 320 dp surface **is** covered: `payout_responsive_test.dart`
and `p13_bugs_test.dart` pump `NestlingApp` directly with their own
`physicalSize`. Non-blocking.

## Scope (RULES §1)

`git status --porcelain` outside `docs/screens/P13/`,
`app/lib/features/pocket_money/` and `app/test/features/pocket_money/` is
**empty**. No `core/`, no `app/`, no other feature, no `tools/screens/`,
`analysis_options.yaml` untouched. No `flutter clean`, no `flutter run`, no
simulator. No source file changed in this stage — only four test files, one new
`SHARED_REQUEST.md`, and this file.

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **406 passed / 6 skipped / 0
  failed** (17 s). The 6 skips are the 5 open reproducers above + the
  pre-existing `p12_bugs_test.dart:320`.
- `flutter test` (whole repo) → **2217 passed / 6 skipped / 0 failed** (1:17).
- Re-run `p13_bugs_test.dart` unskipped after the iteration-2 fixes and retire
  the ones that pass (`p12_bugs_test.dart` is the precedent).
- Iteration 2 should fix BUG-01 + BUG-02 + review #3 together: one `owed > 0`
  guard plus one clamp in `_submit`.

VERDICT: FAIL
