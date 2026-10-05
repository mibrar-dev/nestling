# K10 · Payout day — 3 TEST (iteration 2)

Feature `kid_jar`, route `/payout-day` (`KidJarRoutePaths.payoutDay`), kid
mode. Per-test timeout `120s` throughout; no simulator was booted, installed on
or driven (only `5_ui` may use one, and only
`604697A9-11DA-462F-9837-396E9CA2493A`). **No screen code was patched by this
stage** — every screen change reverted (`git diff HEAD -- app/lib` is empty at
the end). Iteration 1's version of this file is preserved in
`FIXES_1.md`; this file is iteration 2 only.

## Headline

| gate | command | result |
|---|---|---|
| format | `dart format test/features/kid_jar/{payout_day_iter2_test,kid_jar_bloc_test}.dart` | `Formatted 2 files (0 changed)` |
| analyze (this stage's files) | `flutter analyze test/features/kid_jar/payout_day_iter2_test.dart test/features/kid_jar/kid_jar_bloc_test.dart` | **No issues found!** |
| tests (new file) | `flutter test --timeout 120s test/features/kid_jar/payout_day_iter2_test.dart` | **`+40`** — all pass |
| tests (bloc file, extended) | `flutter test --timeout 120s test/features/kid_jar/kid_jar_bloc_test.dart` | **`+38`** (36 inherited + my 2) |
| tests (iteration-1 matrix, untouched by me) | `flutter test --timeout 120s test/features/kid_jar/payout_day_matrix_test.dart` | **`+78`** green — the build's un-parked `(320, 1.3)` copy-fit cells hold |
| tests (whole feature) | `flutter test --timeout 120s test/features/kid_jar` | **`+316 ~6`, All tests passed!** |
| tests (whole app) | `flutter test --timeout 120s` | **`+4806 ~13`, All tests passed!** (a first parallel run showed only the known `paywall_coparent_test.dart` `libsqlite3.dylib` native-asset race — §6.1) |

**No bug found.** All three iteration-1 defects are fixed and now pinned by
tests that would fail if the fixes regressed (§2, §3). The one genuine
coverage hole this stage could still find — **screen HEIGHT** — is closed
(§4). Verdict PASS.

## 1. Baseline on arrival

Iteration 2's build (`905a54a`) fixed all three registered defects and
un-parked their proofs, so this stage extended rather than repaired:

```
flutter test --timeout 120s test/features/kid_jar → +265 ~6, All tests passed!
```

Per file, as inherited:

| file | tests | state on arrival |
|---|---|---|
| `payout_day_matrix_test.dart` | 78 | iteration-1's matrix; the build added the `(320, 1.3)` copy-fit cell (both themes) and deleted my parked K10-BUG-3 proof |
| `kid_jar_bloc_test.dart` | 36 | iteration-1's coverage + the build's two `_closing`-guard regressions |
| `payout_celebration_test.dart` | 14 | + the build's overshoot-percent proof |
| `k10_bugs_test.dart` | 14 ~3 | the bugs stage's file; K10-BUG-1/1b/2 un-skipped by the build |
| `payout_day_view_test.dart`, `payout_day_view_geometry_test.dart`, K09 files | 9 / 3 / rest | unchanged since iteration 1 |

## 2. The iteration-1 defects, re-proved at the level they are rendered

### 2.1 K10-BUG-3 (major) — whole money at 320/1.3×, untouched everywhere else

Iteration 1 proved *not truncated*. That is necessary but not sufficient: a
"fix" that shrank every amount on every screen would pass it and would be
rejected by a designer. `payout_day_iter2_test.dart` adds the other half.

| test | what it pins |
|---|---|
| `320px @1.3x: both amounts render whole and stay legible` | `didExceedMaxLines == false` for `£15.50` and `£9.49 to go`; **no `…` character anywhere on the screen**; and the `FittedBox` scale for each amount is in `(0.8, 1.0]` — measured **0.963** for `£9.49 to go`, i.e. the glyphs shrank 4 % instead of losing a character. A scale below 0.8 (unreadable money) fails the test. The note title, now unclamped, is asserted whole too. |
| `the amounts keep their design size when they already fit` (5 cells: 320@1.0, 390@1.0, 390@1.3, 430@1.0, 430@1.3) | scale is **1.0 ± 0.001** for both amounts. The fix is invisible where the design already fits — the design's 17 px Nunito w900 is never shrunk for a comfortable cell. |
| `the 320 @1.3x shrink is the same in light and dark` | the shrink is geometry, not a token: both themes measure the same scale, dark truncates nothing, and it really is the shrink cell (`< 1`). |
| `the amounts row keeps the design rects at the design cell` | `.k10-amts` still sits 16 px inside the fund card's 3 px border (left amount at x = 39, right amount ending at x = 351 at 390) and both amounts share one baseline row — the fix must not shift the ALIGNMENT (owner rule). |

### 2.2 The clamp removal must not have moved the design bands

`390/1.0: removing the title clamp kept every design band` re-measures the
screen after the layout change: title 107/34, rain 105/141/180×270, note 1
427/66, note 2 top 509, fund top 613 width 350, bar to 844 (89 tall). Deleting
the `.k10-t` line clamp is the kind of edit that silently re-flows a card; this
proves it did not move anything at the design cell.

### 2.3 K10-BUG-2 (minor) — through the widget, not just the entity

`an overshot goal reads 100% there, with a full bar and a 100% spoken value, in
both themes` drives the **real product API**
(`PocketMoneyRepositoryImpl.recordPayout(2000, move 2000)` → saved £35.50 of a
£24.99 target) and then asserts all four layers agree: the caption reads
`100% there!` (and never `142% there!`), `NestProgress.fraction == 1`, the
progress node is announced as `100% of the Lego Friends set saved`, and nothing
throws. The bugs file pins the caption; this adds the **bar** and the **spoken
value**, which a caption-only assertion cannot see (a 100 % caption over a
part-full bar would be the same bug one layer down). `Seed.demo` re-seeds
between the two themes, because `recordPayout` accumulates.

`the fund card still fits its gutter at 320/1.3 with an overshot goal` — the
same data on the narrowest cell: every amount stays inside the 20 px gutters.

### 2.4 K10-BUG-1 (minor) — the new `_closing` guard must not break the pair

The fix added one shared `_closing` flag to **both** `*Requested` handlers. Two
new bloc tests pin that the two screens' events can still interleave safely on
one bloc instance:

- `interleaved K09/K10 events keep one live subscription per stream` — jar load
  → payout load → jar load again leaves exactly **one** live jar subscription
  (replaced, never stacked) and **one** live payout subscription (untouched), and
  `close()` releases both. This is the regression the new flag could have
  introduced: a payout load that cancelled the jar stream, or a guard that
  disabled the other handler.
- `close() is idempotent and never throws with a load queued` — the K09 and K10
  teardown paths can both reach an instance; a second `close()` is a no-op, not
  a double-cancel `Bad state`.

Mutation proof for the first one (§5, probe 3): making `_onPayoutRequested`
cancel `_jarSub` fails it (`Expected: <1>, Actual: <0>`).

## 3. Bloc / repository audit — still complete

Re-audited against the brief's "bloc_test for every event/state path":
`KidJarLoadRequested`, `KidJarSnapshotReceived`, `KidJarPayoutRequested`,
`KidJarPayoutReceived`, `KidJarStreamFailed` × `initial / loading / loaded /
failure` (including failure-after-load keeping the celebration), the reload
guard, `close()`, `copyWithPayout`, the sentinel `copyWith`, `copyWithLoaded`,
`props`, plus the repository contract (demo figures, `recordPayout` re-render,
no-move → null, no-payout → null, `Seed.empty`, active-child switch, live
re-emission, clamped helpers). **Every path is covered**; the only additions
worth making were the two interleaving tests above, which cover a path the fix
created. Nothing else added — a deliberate decision, not an omission.

## 4. The hole this stage found: no K10 test had ever pumped a short screen

Every K10 test — the geometry test, the view test, iteration 1's 12-cell matrix,
the bugs stage's probes — pumps **390×844**. Height was never a variable. On a
667-tall phone (iPhone 13 mini / SE class) the celebration's own chrome
(status bar 47 + top row 60) plus the fixed 89 px bar leaves ~325 px of scroll
viewport, and at 568 px about 226 px — while the jar-rain box alone is 270 px
tall, so the notes and the Pip row are far below the fold and the layout is
under real pressure.

New group `K10 short viewports — 844 / 667 / 568 tall` (24 tests):
**12 cells** (3 heights × light/dark × 1.0/1.3) × 2 assertions:

- *the celebration renders and nothing overflows* — every string, the rain box,
  both notes, the fund card and the CTA exist; `takeException()` is null. (A
  shorter viewport is where an unbounded-height row or a fixed-height
  illustration would throw.)
- *the bar keeps its rect and the physical edge* — the bar is still 89 tall,
  still 390 wide, still bleeds to `left 0 / right 390 / bottom = height`, and the
  CTA keeps the 20 px gutters and the 56 px kid floor. A shorter screen makes a
  bottom-edge strip *more* likely, not less (owner BOTTOM EDGE rule).

Plus:

- `the Pip row is reachable by scrolling at every height` — at 667 and 568 the
  Pip row starts below the fold; after a drag it is on screen, inside the
  gutters, and nothing threw. (At 844 it is already visible, so the same test
  covers both.)
- `320px on a 568-tall screen: the notes and bar still line up` — the narrowest
  width on the shortest height at 1.3×: both notes share the fund card's edges
  and the bar still owns 568.

And the three state frames on the short viewport (`loading`, `empty`,
`failure`): their 96 px glyph + copy + 64 px button must fit the ~226 px the
`Expanded` leaves, and the failure frame's lock must still reach
`/parental-gate`.

## 5. The new tests are not vacuous — three mutation probes, all reverted

Each probe patched the screen, ran the new tests, and was reverted with
`git checkout --` (final `git status --short app/lib`: empty).

| # | temporary mutation | result |
|---|---|---|
| 1 | revert the K10-BUG-3 fix: drop the right amount's `FittedBox` back to a bare `Flexible`+`maxLines: 1`+ellipsis (`payout_fund_card.dart`) | `320px @1.3x: both amounts render whole and stay legible` **fails** — `Expected: false / Actual: <true>` on `£9.49 to go`. The fix is genuinely pinned. |
| 2 | `alignment: Alignment.centerRight` → `centerLeft` on the right amount | **not caught** — at a scale of 1.0 the alignment has no visible effect, so that mutation is a no-op rather than a hole. Recorded rather than overclaimed (§6.3). |
| 3 | make `_onPayoutRequested` also `await _jarSub?.cancel()` (`kid_jar_bloc.dart`) | `interleaved K09/K10 events keep one live subscription per stream` **fails** — `Expected: <1> / Actual: <0>`. The new flag has not broken the two screens' independence. |

## 6. Suite hygiene and what is *not* a K10 finding

1. **Whole-app suite:** the first parallel run showed the same
   `paywall_coparent_test.dart` reds as iteration 1 — `Couldn't resolve native
   function 'sqlite3_initialize' … libsqlite3.dylib (no such file)`, the
   native-asset race that concurrent `flutter test` processes in one worktree
   cause. That file passes standalone (`+7`) and the clean re-run is
   **`+4806 ~13`, All tests passed! (§ Headline). Not K10, not reproducible, not
   actionable by a screen agent.**
2. **A concurrent stage's live file** is present in the feature directory:
   `app/test/features/kid_jar/_k10_i2_probe_test.dart` (the iteration-2 bugs
   stage's scratch probes, "deleted after this stage"). It is untracked, it is
   not mine, and it was not edited — the `+316` directory figure above includes
   it. Per-file figures in §1/§Headline are the ones this stage owns.
3. `dart format` clean; `flutter analyze` clean for both files this stage
   touched. `flutter analyze test/features/kid_jar` reports 20 infos, **none of
   them in this stage's files**: 18 in the concurrent bugs stage's scratch
   `_k10_i2_probe_test.dart` (ignore-comment documentation, cascades) and one
   in its committed `k10_bugs_test.dart:786`; the two that briefly appeared in
   `kid_jar_bloc_test.dart` (`cascade_invocations`) were mine and are fixed, so
   that file analyzes clean on its own.
   `analysis_options.yaml` untouched; no `google_fonts`, no
   `DateTime.now()`, no wall-clock assertion (the clock is pinned to
   Sat 3 Oct 2026 09:41 Europe/London by `test/flutter_test_config.dart`); every
   pumped app ends with `disposeApp` (test_scope.dart) so Drift's deferred
   stream-close timer is drained.

## 7. Observations recorded, not bugs

1. **Note 2 is still 88 px tall with the database's goal name** (fund top 613
   instead of the mock's 591). Unchanged by iteration 2 and deliberately so:
   DATA OVER MOCKS, and the card grows with content exactly as the CSS does.
   `5_ui.md` PASSed on that basis (UI VERDICT RULE excludes DB-driven content).
2. **The title's `FittedBox(scaleDown)` is still never exercised** at any
   supported cell (carried over from iteration 1 §6.1: the design's longest
   title fits even at 320/1.3×). Harmless; it becomes load-bearing only for a
   longer data-driven title.
3. The K10-BUG-3 amounts `FittedBox` is a **painted** transform, so rect
   assertions cannot see the shrink — `_amountScale` in the new file reads it
   off the enclosing `RenderFittedBox`. Worth remembering for any future
   money-string work on this screen.
4. Review findings 3 and 4 (`stale errorMessage` during a payout reload,
   newest-vs-oldest companion move) remain **deliberately unfixed** per
   `2_build.md`, with their reasoning; nothing in this stage's tests depends on
   either being changed.

## 8. Coverage against the stage brief (iteration 2)

| Required | Where | Status |
|---|---|---|
| bloc_test for every event/state path | inherited 36 + the 2 interleaving tests (§2.4, §3) — audited, complete | ✅ |
| light + dark | every short-viewport cell runs both themes; the shrink parity test is cross-theme | ✅ |
| widths 320 / 390 / 430 | iteration-1 matrix + the new 320×568 cell and the amount-scale cells | ✅ |
| text scale 1.0 and 1.3 | both, in every new group | ✅ |
| empty / loading / error | §4 — the three state frames re-checked at 568 tall / 1.3× | ✅ |
| every tap navigates to the right route | inherited; this stage adds the lock escape from the failure frame on a short viewport | ✅ |
| semantics labels on icon buttons | inherited; this stage adds the progress node's spoken value under the K10-BUG-2 fix | ✅ |
| tap targets ≥ 44 parent / ≥ 56 kid | the CTA's 56 px floor re-asserted at all three heights, both themes, both scales | ✅ |
| in-memory Drift, `Seed.demo` / `Seed.empty` | `setUpTestScope()` (demo) + a `Seed.demo` re-seed for the overshoot pair + a feature-local fake for the state frames | ✅ |
| verify the iteration-1 fixes | §2 — each fix pinned at the layer it renders, plus two mutation proofs | ✅ |

## 9. Verdict

All 40 tests in the new file pass, the extended bloc file is green (38), the
inherited iteration-1 matrix is green with the build's un-parked `(320, 1.3)`
cells (78), the whole feature is green (`+316 ~6`) and the whole app is green
on a clean run. All three iteration-1 defects are fixed and pinned by tests
that demonstrably fail when the fix is removed. The one real hole left — no
K10 test had ever pumped a screen shorter than 844 — is now covered at 667 and
568 in both themes at both scales, together with the state frames. **No new bug
found; no screen patched.**

VERDICT: PASS