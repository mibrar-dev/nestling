# Fix list after iteration 1

## From 3_test.md
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


## From 4_review.md
# 4 — QA code review (iteration 1) — P13 Payout (parent)

Scope reviewed: `git diff main...HEAD` — 9 code/test files, all inside the
RULES §1 allow-list for `pocket_money` (`presentation/bloc`, `presentation/
views`, `presentation/widgets`, `test/features/pocket_money`, `docs/screens/
P13`). No `core/`, no `app/`, no other feature, no `tools/screens`,
`analysis_options.yaml` untouched. Domain and data layers are unchanged —
`recordPayout` already existed, which is the right call.

Evidence gathered by this stage (no simulator used, no code edited):

- `flutter analyze` → **1 issue** (see finding 4; not in the committed diff).
- `dart format --output=none --set-exit-if-changed` on all 9 changed
  files → 0 changed.
- Design truth read from `design/html-source/screens/P13-payout.html`,
  `design/html-source/components.css`, `design/html-source/tokens.css`,
  `docs/DESIGN_SPEC.md:176`, and pixel-sampled
  `design/screens/{light,dark}/P13-payout.png` with a local reader.
- Design system read for every component used (`NestButton`, `NestToggle`,
  `NestAvatar`, `NestIcon`, `NestCard`, `NestEmptyState`, `NestType`,
  `NestSpacing`, `NestRadii`, `NestDevice`, `NestToast`, `NestBottomSheet`,
  `NestModal`).

## Verdict summary

| # | Severity | Area | One-line |
|---|---|---|---|
| 1 | **major** | Design fidelity / hit target | The scrim does **not** cover the dimmed header — the design's `.scrim` is `inset: 0`, the app starts it below the summary card |
| 2 | **major** | Data integrity | No in-flight guard on "Mark as paid": a second tap writes a second payout row and leaves a negative balance |
| 3 | **major** | Data integrity | A ticked child who owes £0.00 still gets a `Paid · <date> £0.00` row written into the ledger |
| 4 | **major** | Gate hygiene | Leftover scratch probe test breaks the `flutter analyze` gate and would be committed by the loop |
| 5 | minor | Flutter correctness | `_prime` mutates `State` inside the `BlocBuilder` builder |
| 6 | minor | Accessibility | Dimmed chrome is not `ExcludeSemantics`-d, contradicting both the plan §e and the code's own doc comment |
| 7 | minor | Copy / data | Saverow copy hard-codes "her Lego fund" for an arbitrary goal-bearing child |
| 8 | minor | Design system | Grabber height duplicates `NestSpacing.gap5` and hangs off the wrong class |
| 9 | minor | Accessibility | Sheet title announced twice; scrim has no semantics node to dismiss with |
| 10 | minor | Consistency | `_FailureBody` omits the `NestStatusBar` reserve every other state includes |

No blocker. Three majors in product code plus one gate failure ⇒ **FAIL**.

---

## Findings

### 1. MAJOR — the scrim does not cover the dimmed ledger header (design `inset: 0`)

**Where:** `app/lib/features/pocket_money/presentation/views/payout_view.dart:216-265`
(`_DimmedLedger`), specifically `:255-263`; the class doc at `:204-206`
claims the opposite; contradicted test comment at
`app/test/features/pocket_money/payout_view_test.dart:365`.

**Evidence.** The design puts one overlay over everything:

```html
<!-- P13-payout.html:19-21 -->
<div class="bg-fake">…<div class="ptitle">Pocket money</div><div class="card">…</div></div>
<div style="flex:1"></div>
<div class="scrim" aria-hidden="true"></div>
```
`components.css:164` → `.scrim { position: absolute; inset: 0; background:
var(--scrim); z-index: 20 }`, and `.pay` is `z-index: 30`, so the scrim
covers the **whole screen including the status bar, the title and the
summary card** and only the sheet sits above it.

Pixel proof from `design/screens/light/P13-payout.png` (÷3):

| Sample (logical) | Design pixel | Meaning |
|---|---|---|
| (195, 13) — above the title | `(151,148,158)` | paper `#FBF7F0` under `rgba(30,27,58,.45)` |
| (195, 300) — middle gap | `(151,148,158)` | same |
| (60, 120) — inside the summary card | `(154,152,166)` | surface `#FFFFFF` under the same scrim |
| (195, 700) — inside the sheet | `(23,128,79)` | unscrimmed leaf CTA |

Dark PNG agrees: `(8,7,12)` for paper `#15131F` under `rgba(0,0,0,.62)` and
`(12,11,17)` for surface `#1F1C2E` under it.

The app instead paints the scrim in an `Expanded` that starts **below** the
card (`payout_view.dart:257-263`), so `y = 0…~151` renders unscrimmed —
paper `(251,247,240)` and card `(255,255,255)` — producing a hard bright
band above a dimmed one in both themes, over 151 px of a 390×844 screen.
The same mistake removes the dismiss hit area: in the design tapping the
title/card region closes the sheet (`inset: 0`), in the app only the strip
below the card does.

**Fix.** Overlay the scrim over the whole ledger, not inside the column —
e.g. build `_DimmedLedger` as

```dart
Stack(children: <Widget>[
  const Column(children: <Widget>[NestStatusBar(), /* title */, /* card */]),
  Positioned.fill(
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onDismiss,
      child: ColoredBox(color: tokens.scrim)),
  ),
]),
```

and pin it with a test asserting the scrim rect (`tester.getRect` of the
`ColoredBox` descendant) starts at `top == 0`, plus correct the comment at
`:255` and the test comment at `payout_view_test.dart:365`. This is a
visual-only change: the design y-coords the geometry test pins (title 55,
card 101…151, sheet 343) are unaffected because the scrim is painted, not
laid out.

### 2. MAJOR — "Mark as paid" can be submitted twice; the second write corrupts the balance

**Where:** `payout_view.dart:165-180` (`_submit`, no guard; `:179`
`setState(() => _submitted.addAll(_ticked))`), `payout_sheet.dart:157-158`
(`canSubmit`, unaware of `_submitted`), `payout_sheet.dart:228-231`
(`onPressed: canSubmit ? onSubmit : null`, no `loading:`).

**Evidence.** `NestButton` has no debounce (`nest_button.dart:170-181` is a
plain `GestureDetector.onTap`) and `PayoutSheet` is not told a submit is in
flight, so between the first tap and the first `watchLedgerData` re-emission
(i.e. until the DB write round-trips) the CTA stays enabled and
`_owedOf(data, childId)` still returns the **pre-payout** owed. A second tap
in that window dispatches a second `PocketMoneyPayoutSubmitted` per ticked
child, and `recordPayout` inserts unconditionally
(`data/pocket_money_repository_impl.dart:339-352`) — no idempotency key, no
amount check. Maya's ledger becomes `−£4.20` (a negative balance on P12),
and the confirmation still fires: `_payoutLanded`
(`payout_view.dart:184-194`) only rejects `now > 0`, so `-420` passes, the
toast says "Payout recorded — enjoy the celebration" and the sheet pops.
Silent ledger corruption behind a success message. `_submitted` is only ever
*read* (`listenWhen`), never used to lock the button.

**Fix.** Make the in-flight set authoritative:

```dart
void _submit(MoneyLedgerData data) {
  if (_submitted.isNotEmpty) return;                 // re-entry guard
  …
  setState(() => _submitted.addAll(_ticked));
}
```

and pass `busy: _submitted.isNotEmpty` into `PayoutSheet`, folding it into
`canSubmit` and into the button's `loading:` (`NestButton` already disables
and shows a spinner when `loading` is true). Test: tap the CTA twice inside
the write window, then assert exactly one new `payout` row per ticked child.

### 3. MAJOR — a ticked child with nothing owed still writes a "Paid £0.00" row

**Where:** `payout_view.dart:168-177` (one event per id in `_ticked`,
irrespective of the owed total) → `data/pocket_money_repository_impl.dart:
340-352` (`amountPence: -amountPence.abs()`, no `> 0` guard) → rendered by
`presentation/widgets/money_history_row.dart:174-183` and `:212-223`.

**Evidence.** `canSubmit` only requires that *some* ticked child owes money
(`payout_sheet.dart:157-158`), so a zero-owed child can ride along. Reachable
path: pay Maya only, re-open `/payout` (Maya now £0.00, Leo still £2.10 so
`_prime` ticks Leo), tick Maya as well, tap the CTA → `_submit` sends
`PocketMoneyPayoutSubmitted('maya', 0, 0, null)` and the repository writes a
`payout` row with `amountPence: 0` and note `Paid · Sat 3 Oct`. On P12 that
is a leaf-tinted history tile reading **"Paid · Sat 3 Oct   £0.00"** — a
payment record for money that never moved. (The builder's own `zz_probe_test`
PROBE A only covers the all-paid case, where `canSubmit` happens to be false;
this mixed case is not covered by any test.)

**Fix.** Skip non-paying children before dispatching:

```dart
for (final childId in _ticked) {
  final owed = _owedOf(data, childId);
  if (owed <= 0) continue;                       // nothing was handed over
  …
}
```

Optionally harden `recordPayout` with the same `amountPence > 0` guard
(feature-owned file, so it is in bounds), and add a regression test: pay
Maya, re-open, tick Leo (£0.00) alongside Maya, submit, assert no `payout`
row exists for Leo.

### 4. MAJOR — leftover scratch probe test fails the analyze gate and would be committed

**Where:** `app/test/features/pocket_money/zz_probe_test.dart` (untracked,
not in the diff). Its own header: *"TEMPORARY probe file — deleted before the
stage ends."*

**Evidence.** `flutter analyze` in this worktree:

```
info • Empty class bodies should be written using a ';' rather than '{}' …
      test/features/pocket_money/zz_probe_test.dart:30:59 • empty_container_bodies
1 issue found.
```

RULES §7.1 requires `flutter analyze` → *No issues found*. The file is 9
`debugPrint` probes with no assertions; because the loop commits the worktree
each iteration, an untracked file inside `app/test/` is exactly what would be
swept into a commit. Running it also did not complete here: PROBE A finished
and PROBE B never started after ~10 minutes (other screen loops were building
concurrently, so this is reported as an observation, not a diagnosis — but a
file that can stall the suite must not survive the stage).

**Fix.** `rm app/test/features/pocket_money/zz_probe_test.dart` before the
loop commits, then re-run `flutter analyze`. Its findings must be promoted
into real assertions — which is findings 2 and 3: add the double-submit test
and the zero-owed-child test to `payout_view_test.dart`, and keep the
regression tests from the temporary file (`payout_widget_geometry_test.dart`
already covers the rest of what the probes measured).

### 5. MINOR — `_prime` mutates `State` during the build phase

**Where:** `payout_view.dart:97` (`_prime(data)` called from inside the
`BlocBuilder` builder), writing `_primed` and `_ticked` at `:129-140`.

**Evidence.** A builder must be pure; here it mutates two fields of the
`State` and relies on the *same* build reading the freshly mutated set in
`PayoutSheet` (`:107`). It happens to work only because
`buildWhen` (`:79-82`) lets every emission through. Any later narrowing of
`buildWhen`, a `didChangeDependencies` rebuild, or a second consumer of the
sheet would read a half-updated `_ticked`, and the mutation is invisible to
the framework.

**Fix.** Move the priming out of `build`: seed it from a `BlocListener` on
the first `loaded` emission (the same place the error/success listeners
already run) with a `setState`, or guard it in
`PocketViewState.didChangeDependencies`-equivalent. Keep `build` free of
writes.

### 6. MINOR — the dimmed chrome is not `ExcludeSemantics`-d (plan §e, and the code's own comment)

**Where:** `payout_view.dart:204-206` (doc comment) vs `:216-265` (no
`ExcludeSemantics` anywhere).

**Evidence.** The class doc states *"`ExcludeSemantics` — it is not
actionable and a modal sheet must not leave a focus trap behind itself"*, and
plan §e requires *"summary card behind scrim `ExcludeSemantics`"*, but the
`Semantics(header: true)` title at `:228-236` and the summary text at
`:246-252` stay in the semantics tree. VoiceOver/TalkBack can therefore still
land on the ledger title and the "Maya is owed £4.20 · Leo is owed £2.10"
card behind a modal sheet — precisely the trap the comment claims to close.

**Fix.** Wrap the covered chrome in `ExcludeSemantics(child: …)`, keeping the
dismiss `GestureDetector` outside it (after finding 1 the scrim is a sibling,
so the chrome Column can be excluded wholesale).

### 7. MINOR — the saverow copy hard-codes a gendered, goal-specific noun

**Where:** `payout_sheet.dart:399-408` with `saveChild` resolved at `:84-89`
and `:137-141`.

**Evidence.** The row belongs to "the first child in creation order that has
a savings goal", but the copy is the design's literal
`Move £1.00 of {nick} to her Lego fund`. Any family whose goal-bearing child
is Leo — or whose goal is not the Lego one — gets **"Move £1.00 of Leo's to
her Lego fund"**. The design string is correct for the seeded
Maya/`goal-lego` case, and character-for-character copy is the rule, so this
cannot be silently reworded here.

**Fix.** Raise it as a `SHARED_REQUEST` (or an `ORCHESTRATOR_NOTES` item)
asking for the data-driven form, e.g. *"Move £1.00 of {nick}'s money to
{goal.title}"*, and use it whenever `goalFor(id)?.title != 'Lego Friends
set'`. Keep the design string verbatim on the seeded path. Until then the
risk is documented at the call site (the build note flags the decision but
not the data-driven failure mode).

### 8. MINOR — the grabber height duplicates `NestSpacing.gap5` on the wrong class

**Where:** `payout_sheet.dart:451` (`static const double grabberHeight = 5;`
declared on `PayoutCheck`) used at `:58` by `_PayoutGrabber`.

**Evidence.** `NestSpacing.gap5 == 5` exists (`tokens/spacing.dart:29`) and
`NestBottomSheet` uses it for the identical 40×5 grabber pill
(`nest_bottom_sheet.dart:49`). One pill, two sources of truth, and the
constant sits on a class it has nothing to do with.

**Fix.** Delete `PayoutCheck.grabberHeight` and use
`height: NestSpacing.gap5` in `_PayoutGrabber`. (Keep `size`/`radius`/
`borderWidth` as feature-local documented consts — 48/14/2 are not on any
token scale and `core/` is off-limits per RULES §1.)

### 9. MINOR — the sheet's dialog semantics double-announce the title, and the scrim cannot be dismissed from the semantics tree

**Where:** `payout_sheet.dart:160-163` (`Semantics(container: true, label:
title, explicitChildNodes: true)`) together with `:190-198`
(`Semantics(header: true, child: Text(title))`); `payout_view.dart:257-262`.

**Evidence.** The design is `role="dialog" aria-modal="true" aria-label=
"Saturday payout"` (`P13-payout.html:22`). The Flutter approximation sets the
title as a container label *and* as a header child, so "Saturday payout" is
announced twice on entry, and the dismiss surface is a bare
`GestureDetector` with no `Semantics` node — a screen-reader user has no
labelled control to close the sheet (only the platform back gesture, which
the design's semantics do not offer either).

**Fix.** Drop `label:` from the container and keep `container: true` +
`explicitChildNodes: true`, so the header text is the single announcement;
and give the scrim `Semantics(button: true, label: 'Close payout',
onTap: onDismiss)` (per the brief's `excludeSemantics`/`onTap` rule) or state
in the code that dismissal is deliberately back-gesture-only.

### 10. MINOR — `_FailureBody` skips the status-bar reserve the other states include

**Where:** `payout_view.dart:336-362` vs `:292` (`_EmptyBody`) and `:219`
(`_DimmedLedger`).

**Evidence.** Every other body on this route mounts `NestStatusBar()`
(47 px reserve). The failure body is a bare centred `Column`, so on a short
screen (the 320×568 case the view tests already exercise) the message and
the "Try again" button are centred on the full window rather than on the safe
area, and the two states disagree about the chrome. Cosmetic only in the
844-tall case.

**Fix.** Wrap the failure body in the same `NestStatusBar()` + `Padding`
chrome as `_EmptyBody` (or move the reserve up into `PayoutView` so all
three states inherit it).

---

## Checked and found correct (no action)

- **Architecture.** Feature-first; no new domain/data files (the existing
  `recordPayout` is reused); one BLoC per feature with a new event + handler
  that mirrors the P12 add/spend write-through pattern; the route already
  provides the bloc and `PocketMoneyLoadRequested`
  (`pocket_money_routes.dart:48-58`) and the kid-mode guard is in
  `router.dart:95`. No DI or route edits, none needed.
- **RULES §1.** Every path in the diff is inside the allow-list.
- **Copy, character-by-character** against `P13-payout.html`: ASCII `0x27` in
  `you've` / `Maya's`, `&` (not `&amp;`) in the CTA, U+00B7 (`kMoneyDot`) in
  the summary and in `Weekly + quests · £4.20`, U+2014 spaced em dash in the
  success toast, `£1.00` from `moneyPounds(100)`. No US spellings.
  `NestBalancedText` correctly **not** used: the design sets
  `text-wrap: balance` only on `.display/.h1/.kid-title/.kid-hero/.balance`,
  and `.pay h2` / `.bg-fake .ptitle` are none of those.
- **Tokens only.** No literal colour anywhere; `scrim`, `surface`, `line`,
  `leaf`, `paper`, `cardShadow` all from `context.nest`; sizes from
  `NestSpacing`/`NestRadii`/`NestDevice`; the only numeric literals are the
  documented `.pay h2` 24/30 w900 and `.nm` 16/22 call-site overrides plus
  the sheet-local 88 % / 48 / 14 / 2 / 5 (finding 8 covers the one that has
  a shared token). No Material letter-spacing reintroduced; no
  `google_fonts`.
- **DS reuse.** `NestStatusBar`, `NestCard`, `NestButton`, `NestToggle`,
  `NestAvatar`, `NestIcon`, `NestEmptyState`, `NestToast` reused.
  `NestBottomSheet`/`NestModal` legitimately not usable for `.pay` (left
  h3 + close button + 92 % vs a centred 24/30 w900 title + grabber, 88 %),
  and `PayoutCheck` has no DS equivalent (the shared check is the kid 56 px
  ring).
- **Owner rules.** Bottom edge: the sheet's `paper` reaches the last pixel
  row (`homeH + s4` bottom pad, `sheet.bottom == 844`, pinned by
  `payout_widget_geometry_test.dart:100-124`). Alignment: 20 px gutters on
  title, both rows, saverow and CTA, all pinned by rect assertions.
  Child order: creation order everywhere (rows, saverow, summary string,
  `_prime`, `saveChildId`), asserted by
  `payout_view_test.dart:478-491`. Zero dark-mode branches.
- **Accessibility actions.** Every control exposes `SemanticsAction.tap`;
  both `excludeSemantics: true` wrappers (`PayoutCheck` at
  `payout_sheet.dart:457-464`, and the button inside `NestButton`) pass
  `onTap:`; `performAction` is asserted to change the real state
  (`payout_view_test.dart:193-235`); the disabled CTA passes no tap and
  reports `enabled: false` (`:237-256`). Tap targets: check 48, toggle ≥ 44,
  CTA 52, scrim full width.
- **Data over mocks.** Amounts, weekday, avatar tint and the goal all come
  from `Seed.demo`; nothing design-specific is hard-coded except the
  design-fixed £1.00. Child order follows creation order, not alphabetical.
- **Error handling.** A rejected write keeps `loaded`, toasts the friendly
  message and stays on the sheet; the success toast/pop fires only from the
  stream proof (never optimistically). The stale-error-after-retry case
  self-heals because the load handler emits `clearErrorMessage: true` on the
  next stream emission (`pocket_money_bloc.dart:81`), so a retry that
  succeeds is not swallowed by finding 9's sibling condition.
- **Performance.** No `Timer`/`AnimationController` (so the
  `DISABLE_ANIMATIONS` contract holds trivially), no stream subscriptions to
  leak (only `BlocListener`/`BlocBuilder`), `buildWhen` narrowing the
  rebuild to `status`/`data`/`errorMessage`, `_goBack` and the toast are
  guarded by `mounted`. No rebuild storm found.
- **Children's Code.** Parent-mode screen; no analytics, ads, tracking or
  third-party SDK anywhere in the app's `pubspec.yaml`, nothing added by this
  diff, no child data leaves the device (all reads are local Drift), and no
  `£` copy appears in kid mode from this screen.
- **Test hygiene.** `money_ledger_states_test.dart`'s single-line change
  (`tester.pageBack()` → `tester.binding.handlePopRoute()`) is mechanics only
  — the real `/payout` has no app bar, so there is no back button to find —
  and the original assertions (`/money`, "Maya is owed") are intact. Not a
  weakening.
- **Format.** `dart format` clean on all 9 changed files.

## Recommended order of work

1. Delete `zz_probe_test.dart`, re-run `flutter analyze`
   (finding 4) — restores the §7.1 gate.
2. Fix the submit path: in-flight guard + busy CTA, and skip zero-owed
   children (findings 2, 3), each with the regression test the probe was
   written to justify.
3. Move the scrim over the whole ledger and pin it with a `top == 0`
   assertion (finding 1), then re-shoot light + dark.
4. Tidy-ups: findings 5-10.


## From 5_ui.md
# P13 · Payout — Stage 5 UI check (iteration 1)

Route `/payout`, simulator BC440E48-B3A3-43BC-971B-0EF5DB621874 (390×844).
Shots: `docs/screens/P13/ui/app_light_1.png`, `app_dark_1.png`
(seed demo, parent mode, Maya). Compares: `cmp_light_1.png`, `cmp_dark_1.png`
vs `design/screens/light|dark/P13-payout.png` (1170×2532 ÷ 3 = logical px;
all y/x below are logical px). Status-bar glyphs excluded per orchestrator
rule (OS draws the real bar).

## Mean diff

- Light: **7.44 %** — band 0 (y 0–105) 36.89 %, band 1 (y 105–211) 16.96 %,
  bands 2–7 (y 211–844) 0.00 / 0.19 / 1.74 / 1.53 / 0.90 / 1.41 %.
- Dark: **2.21 %** — band 0 8.22 %, band 1 3.93 %, bands 2–7
  0.00 / 0.19 / 1.68 / 1.48 / 0.76 / 1.45 %.

Bands 0–1 carry the failure below. Bands 2–7 residual (~1–2 %) is text
rasterisation (bundled Nunito/Inter vs browser render; glyph edges within
±2 px, invisible at 1×) plus the OS home-pill mock (see non-findings).

## Measured y positions (design vs app, light)

| Element | Design y | App y | Δ |
|---|---|---|---|
| Scrim top edge (full-screen dim) | 0 (covers header) | ~152 (below summary card) | **+152 FAIL** |
| Sheet top edge (paper) | ~343 | ~343 | 0 |
| Sheet title "Saturday payout" first glyph row | ~383 | ~383 | 0 |
| Subtitle "Tick once…" | ~413 | ~413 | 0 |
| Maya check rect (green, shape) | x 307–355 @ y 470 | x 307–355 @ y 470 | 0 |
| Leo check rect (empty, shape) | x 307–355 @ y 560 | x 307–355 @ y 560 | 0 |
| CTA rect (green pill, shape) | x 20–369, bottom ~750 | x 20–369, bottom ~750 | 0 |
| Caption "Your children…" last row | ~790 | ~790 | 0 |
| Bottom edge | paper to y 844 | paper to y 844 | 0 |

Sampled colours prove the scrim gap: at (350, 50–150) design is
`#97949E` (= paper × scrim 45 %: exact match for dimmed paper) while app is
`#FBF7F0` pure paper with a bright-white summary card. Dark theme same
shape: design header near-black dimmed, app bright `#15131F` paper + bright
card. Sheet content below y ~343 is pixel-aligned (title, both checks, CTA,
caption all Δ 0).

## Deviations

1. **Scrim does not cover the background header (both themes).**
   Design: `.scrim{position:absolute;inset:0}` dims the whole screen —
   "Pocket money" title and the "Maya is owed £4.20 · Leo is owed £2.10"
   summary card render dimmed (`#97949E` light). App: title + summary card
   render bright/undimmed (`#FBF7F0` paper, white card); scrim starts at
   ~y152. Visible side-by-side without zoom; a designer would reject.
   Fix: in `app/lib/features/pocket_money/presentation/views/payout_view.dart`,
   follow `1_plan.md` §(a) — `_DimmedLedger` must be a plain undimmed Column
   (`Positioned.fill`), with a separate full-`Positioned.fill` scrim
   `GestureDetector` (`ColoredBox(tokens.scrim)`, `onTap: _goBack`) layered
   between it and the `PayoutSheet` `Align(bottomCenter)`. Do not keep the
   scrim as the `Expanded` tail of the header Column (current lines 255–263).
   Side benefit: scrim-tap dismissal then works over the header area too.
2. **Leo name/amount block sits ~2 px high** (design name top ~555, app
   ~553 at x=100; amount baseline +2 px extent). Within the ±2 px rule and
   invisible at 1× — recorded, no fix required beyond the rebuild in (1);
   re-measure after the scrim fix.

Checked OK (no deviation): presence/order of all elements; child order
Maya→Leo; copy incl. `you've`/`Maya's` ASCII apostrophes, `·` U+00B7
separators, `&`, two-line wraps identical; Maya ticked/Leo unticked; savings
toggle ON with `Move £1.00 of Maya's to her Lego fund`; CTA label + caption;
avatars (lilac M / peach L, s44); check 48×48 r14, toggle 51×31, CTA min-h 52
pill, grabber 40×5, sheet radius-top 32, 20 px gutters, cards/sheet/CTA
aligned; dark-mode leaf CTA/cards/toggle; OWNER bottom-edge rule (paper to
y 844 both themes, no coloured strip); no overflow/clipping/ellipsis faults.

Non-findings (not deviations): status-bar time/glyphs (OS-drawn, excluded);
design home-indicator pill (y 825–829, OS-drawn live; app correctly runs
paper to the edge); sheet-text rasterisation ≤2 px.


## From 6_bugs.md
# P13 · Payout (parent) — Stage 6 bug hunt (iteration 1)

Route `/payout` (feature `pocket_money`), build `c34904b` ("P13: checkpoint
after build (iteration 1)"). First adversarial pass over the shipped screen.

Method: widget and pure probes on the in-memory and file-backed Drift
databases, plus a **gated repository** that holds `recordPayout` mid-flight so
the double-tap race is deterministic instead of timing-dependent, a semantics
tree audit, and a restart persistence round-trip. **No simulator was used**
(stage rule; only stage 5_ui may). No screen code was edited (stage rule).

Guards: `app/test/features/pocket_money/p13_bugs_test.dart` — 17 tests
(12 active "attacks that hold" probes, 5 skipped reproducers, one per
finding). During the hunt every skipped test was run unskipped and fails
exactly as recorded below (12 passed / 5 failed); the quiet suite is green.

**VERDICT: FAIL — three open major findings (P13-BUG-01/02/03).**

Stages 4 (code review) and 5 (UI check) ran in parallel with this hunt and
independently reached the same majors: review #1 / UI deviation 1 = this
file's BUG-03 (scrim not `inset: 0`, UI measured +152 px), review #2 =
BUG-01 (double submit). Review #3 (a ticked £0.00 child still writes a
`Paid · <date> £0.00` row) shares its view-side root with BUG-02 here
(`_submit` dispatches for every ticked child without an owed guard); the two
should be fixed together. The review's finding 4 was the leftover
`zz_probe_test.dart` scratch file — it has been deleted (see the test-suite
note) so the loop cannot commit it or stall the suite.

---

## Findings

| # | Severity | Status | Failing test (skipped in the suite) |
|---|---|---|---|
| P13-BUG-01 | major | OPEN | `P13-BUG-01: a second tap while the payout write is in flight double-writes the payout, the savings move and the goal bump` |
| P13-BUG-02 | major | OPEN | `P13-BUG-02: the £1.00 savings move is not clamped to the amount paid` |
| P13-BUG-03 | major | OPEN | `P13-BUG-03: the scrim is not inset 0 — the P12 backdrop stays lit and the top of the screen does not dismiss the sheet` |
| P13-BUG-04 | minor | OPEN | `P13-BUG-04: a repeated identical write failure gives the parent no feedback at all` |
| P13-BUG-05 | minor | OPEN | `P13-BUG-05: the ledger behind the modal stays in the semantics tree` |

### P13-BUG-01 — a fast second tap double-writes the payout (major)

**Repro.** Open `/money` → "Payout time". Tap "Mark as paid & start the
celebration", then tap it again while the first write is still in flight
(80 ms later in the test; a real Drift round trip on device is longer).
The sheet shows no in-flight state — the CTA stays enabled and unchanged, so
nothing discourages the second tap.

**Evidence.** With the write gated, the second tap dispatches a second
`PocketMoneyPayoutSubmitted`. Result: `attempted = 2`; **two `payout` rows**
(−420 each), **two `savings_move` rows** (100 each) and the Lego goal at
**1750 instead of 1650** — a £2.00 move recorded for a £1.00 option, plus a
duplicate "Paid" row in the child's ledger. (Probe also confirmed the simpler
same-frame double tap gives the same state.)

**Suggested fix.** Make the submit non-reentrant: `if (_submitted.isNotEmpty)
return;` at the top of `_submit`, and pass a `submitting` flag into
`PayoutSheet` so the CTA disables (and, ideally, the checks/toggle are inert)
until the stream proof or a failure clears it. The failure path already
clears `_submitted`, so retries stay possible. A per-child idempotency key in
`recordPayout` would be belt-and-braces, but the view guard is the minimal
fix.

### P13-BUG-02 — the £1.00 savings move is not clamped to the payout (major)

**Repro.** A small week for the family: Maya is owed exactly **£0.50** (one
50p weekly-base row, everything before the last payout). Open `/payout`; Maya
is ticked by default and the saverow is ON by default. Tap "Mark as paid".

**Evidence.** Payout row **−50**, `savings_move` row **+100**, goal
**1550 → 1650**. £1.00 moved to savings on a £0.50 payout — the extra 50p
never existed in the child's jar (the jar's balance *is* "owed since the last
payout"). The same root hits the ticked-£0-child case: after a partial payout
a parent can tick a child who owes £0.00 next to a paying sibling and the
screen writes a −0 payout row **plus a £1.00 move** for that child.

**Suggested fix.** Clamp the move to the money actually being paid:
`savingsMovePence = min(PayoutSheet.savingsMovePence, owed)` (and skip the
move when `owed == 0`), or hide/disable the saverow while the goal child's
owed is below £1.00. `recordPayout` already bumps the goal by the value the
view passes, so the clamped value is the single source.

### P13-BUG-03 — the scrim is not `inset: 0` (major)

**Repro.** Open `/payout` from `/money`. Compare with either design PNG:
the whole backdrop (status-bar reserve, "Pocket money" title, "… is owed"
summary card) is behind the darkened scrim in the design, and
`docs/design/SPACING_SPEC.md` §5 defines `.scrim → absolute inset 0`. In the
app the scrim only paints the `Expanded` area *below* the summary card.

**Evidence.** The scrim rect measures **(0, 169, 390, 844)** (169 is the card
bottom in the test's unloaded-font metrics; ≈151 with the bundled fonts), so
the top band is undimmed. A tap over the title — inside the scrim in the
design and in `1_plan.md` §a (`Positioned.fill → Container(color: scrim);
tap = pop`) — does **not** dismiss the sheet (path stays `/payout`).

**Suggested fix.** Put the scrim in its own full-screen stack layer between
the ledger and the sheet: `Stack[Positioned.fill(ledger),
Positioned.fill(GestureDetector(scrim)), Align(sheet)]`, or wrap the ledger
content in the scrim while keeping a full-screen dismiss gesture. Do not grow
the existing `Expanded` scrim — it inherits the card's bottom edge.

### P13-BUG-04 — a repeated identical write failure gives no feedback (minor)

**Repro.** Force `recordPayout` to fail with the same error twice.
Tap "Mark as paid": the failure toast appears. Let it expire, tap again
(same failure): **nothing happens** — no toast, no state change, and
`_submitted` stays armed.

**Evidence.** The bloc's error path emits `copyWith(errorMessage: …)`; the
second identical message produces an **equal state, which Bloc suppresses**,
so the view's `listenWhen` (`previous.errorMessage != current.errorMessage`)
never fires. The failing test asserts a new `SnackBar` after the retry;
measured `0`.

**Suggested fix.** Give the retry a visible outcome: clear `errorMessage`
before the write (`emit(state.copyWith(clearErrorMessage: true))` ahead of
the `recordPayout` await) so a repeat failure is a state change again, or
have the view surface the retry directly (toast on tap once an error is
already on screen). Keep the in-flight guard from BUG-01 in mind: the guard
must clear on failure so this retry path stays reachable.

### P13-BUG-05 — the dimmed ledger stays in the semantics tree (minor)

**Repro.** Enable a screen reader, open `/payout`, swipe back from the sheet.

**Evidence.** With semantics enabled, `find.bySemanticsLabel('Pocket money')`
and `find.bySemanticsLabel('Maya is owed £4.20 · Leo is owed £2.10')` each
match a node *behind* the modal. `1_plan.md` §e requires the summary card
(and the whole dimmed backdrop) to be `ExcludeSemantics`, and
`_DimmedLedger`'s own doc comment claims it is — the build method never wraps
the column.

**Suggested fix.** Wrap the non-sheet subtree in `ExcludeSemantics` (the
title/card are not actionable). If the scrim's tap-to-dismiss should stay
announced, keep a separate semantics node with `onTap` outside the excluded
subtree; otherwise the system back gesture remains the accessible dismiss.

---

## Attacks that hold (active tests — no finding)

- **Gated single write**: one tap → one payout row (−420), one `savings_move`
  (100), goal 1650, pop to `/money`, toast
  `Payout recorded — enjoy the celebration`, no exception. (Positive control
  for BUG-01.)
- **Real 320 dp × text scale 1.3 with six children and
  "Maximilian-Alexander"**: rows in creation order (Maya, Leo, then the
  added four), no overflow exception, the sheet scrolls and the CTA is
  operable; one payout row lands (−420). NOTE: the width is set *after* the
  first pump because `pumpAppRoute` forces 390×844 (see the test-suite note).
- **Real 320×568**: the sheet scrolls to the CTA, the tap lands and the
  screen returns to `/money`; no exception.
- **Goal child unticked / sibling paid**: only `leo:−210` is written, no
  `savings_move`, goal stays 1550.
- **Everyone at £0.00**: two `Weekly + quests · £0.00` rows render and the
  CTA reports `enabled: false` with no tap action.
- **One-child family**: one row, no stale Leo copy, no exception.
- **Deep links**: kid mode `/payout` → `/parental-gate` (guard intact);
  fresh/never-onboarded `/payout` → `/welcome`; launched at `/payout` with
  nothing to pop, the scrim tap still reaches `/money` via `_goBack`.
- **System back mid-write**: no exception, exactly one payout row lands (the
  tap was already committed before the pop).
- **Restart persistence (file-backed)**: payout row, `savings_move` and the
  1550 → 1650 goal bump all survive a close/reopen; owed back to 0.
- **Dark/light contrast**: `ink/ink2` on `surface`/`paper` and
  `onLeaf/leaf` all ≥ 4.5:1 in both themes.
- **Money maths**: every P13 amount is an integer-pence value read from the
  ledger (`owedFor().totalPence`); no float parsing/rounding exists on this
  screen. The only money defect is BUG-02's *unclamped* move, not rounding.
- **Timezone/BST**: the sheet title is the `families.payout_day` integer
  (`kPayoutWeekdayNames[day − 1]`); no date arithmetic runs in P13, so there
  is no BST-sensitive path here. The repository's `formatDay(now, zone)` note
  is covered by the existing P06/P12 timezone tests.

## Test-suite note (not a screen bug)

`test_scope.pumpAppRoute` unconditionally sets `physicalSize = 390×844`, so
`payout_view_test.dart`'s "320 px" cases (`_pumpPayout(size: Size(320, …))`)
and its "short screen" case in fact run at **390×844** — the size is
overwritten before the first frame. The new bugs file sets the width after
the first pump so its 320 dp probes are real. Suggested follow-up (allowed
paths): give `pumpAppRoute` an optional `size` parameter, or set the size
post-pump in the responsive tests.

Worktree hygiene: the review stage's `zz_probe_test.dart` (untracked,
breaking `flutter analyze` and stalling the runner) was deleted in this
stage; its £0.00-row finding is carried by review #3 and by BUG-02 above, so
no coverage is lost. The quiet suite now contains only committed test files.

## How to reproduce the skipped failures

```bash
cd app
# the green suite (5 skips):
flutter test test/features/pocket_money/p13_bugs_test.dart
# prove the five findings (12 pass / 5 fail) — unskip a temp copy:
sed 's/^    skip: true, \/\/ P13-BUG-/    \/\/ skip: true, \/\/ P13-BUG-/' \
  test/features/pocket_money/p13_bugs_test.dart \
  > test/features/pocket_money/_unskip_test.dart
flutter test test/features/pocket_money/_unskip_test.dart   # 5 failures
rm test/features/pocket_money/_unskip_test.dart
```

## Hand-off state

- `dart format` clean; `flutter analyze` → **No issues found!**
- `flutter test test/features/pocket_money` → **366 passed / 6 skipped /
  0 failed** (the 5 reproducers above + the pre-existing P12-BUG-04 skip).
- `app/test/features/pocket_money/p13_bugs_test.dart`: 17 tests — 12 active,
  5 skipped reproducers. No product or shared code was touched; only the
  feature test path and `docs/screens/P13/**` (plus the stray scratch file
  removal above).
- Build under test: `c34904b` (iteration 1 checkpoint). Re-run the skipped
  tests after the iteration-2 fixes and unskip the ones that pass (P12's
  `p12_bugs_test.dart` is the precedent for retiring fixed findings).

