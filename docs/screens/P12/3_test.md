# P12 · 3 TEST (iteration 2)

Route `/money`, feature `pocket_money`, parent mode. In-memory Drift DB
(`AppDatabase.memory()`) with `Seed.demo` / `Seed.empty`; the story day is
pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.

No production code was edited in this stage. No simulator was booted,
installed on, screenshotted or driven (stage 5 only). No images attached.

## Outcome

**PASS — all tests green, no bugs found.** The iteration-1 defect (the 16 px
uniform stack shift, P12-BUG-05) is fixed in the screen and is now *proven*
fixed by the geometry guard that failed last iteration: **7 tests / 6 red →
10 tests / 10 green**.

```
$ dart format .
Formatted 436 files (0 changed) in 1.17 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.5s)

$ flutter test
00:47 +1900 ~1: All tests passed!

$ flutter test test/features/pocket_money
00:15 +313 ~1: All tests passed!
```

The single `~1` is the intentional skip documented in `SHARED_REQUEST.md` §3
(`p12_bugs_test.dart:320`, P12-BUG-04: six children at 320 dp shrink the
**shared** `NestSegmented` options below 44 px — P12 must not fork the shared
control, so it stays skipped until that cross-screen fix lands). It is not a
P12 defect and must not be un-skipped here.

Per file (all green):

```
money_ledger_geometry_test.dart      +10
money_ledger_states_test.dart        +17
money_ledger_responsive_test.dart    +24
pocket_money_ledger_bloc_test.dart   +18
money_ledger_view_test.dart          +14
p12_bugs_test.dart                   +22 ~1
```

## Geometry vs the design (UI VERDICT RULE)

Measured in a real-font widget test at 390×844 (`FontLoader`, so the bundled
Inter/Nunito metrics apply), against `design/screens/light/P12-money.png`
(1170×2532 ÷ 3). Every value is pinned at ±1 px, inside the ±2 px rule, and
there is **no uniform vertical shift** any more:

| anchor | design y | app y | Δ |
|---|---|---|---|
| status-bar reserve | 47 | 47 | 0 |
| title line-box top | 55 | 55 | 0 |
| segmented track top (first control) | 105 | 105 | 0 |
| owed card top | 173 | 173 | 0 |
| owed card height | 211 | 211 | 0 |
| `Payout time` top | 312 | 312 | 0 |
| goal card top | 400 | 400 | 0 |
| goal card height | 88 | 88 | 0 |
| history card top | 504 | 504 | 0 |
| history tile | 40×40, r 16 | 40×40, r 16 | 0 |
| empty-state title top | 55 | 55 | 0 |

Iteration 1 recorded 71/121/189/419/525 and heights 214/90 — the +16 came
from a `SizedBox(height: NestSpacing.s4)` the design does not have between
`NestStatusBar` and the title (`components.css` gives the first child of
`.scroll` no top margin; `.ptitle` supplies its own 8 px). Both call sites
are now clean and the guard stays in the suite, so a future spacer cannot
silently come back.

## Tests added this iteration (+5)

The iteration-2 build changed the submit/error path (review findings 6 and 7).
Everything else was already covered, so this stage closed only the new gaps —
no duplication of `money_ledger_view_test.dart`, `p12_bugs_test.dart` or the
geometry guard.

### `pocket_money_ledger_bloc_test.dart` (+3, now 18)

New fake `_ThrowingSetupWriteRepository` (setup writes throw, load path
healthy), plus the group `error-message mapping (review finding 7)`:

1. **Load failure message is exact**: `We couldn’t load your ledger: Bad state:
   ledger is down` — asserted as a whole string plus a code-unit check that
   the apostrophe is U+2019 and **not** ASCII `'` (the COPY rule).
2. **Rejected submit message is exact**: `We couldn’t save that: Exception:
   add-money refused`, and the state does *not* drop to `failure`.
3. **P06 setup write failures keep their own raw copy** — a regression guard
   for the *shared* bloc: a failed `setMode` / `setPayoutDay` /
   `setWeeklyBasePence` must still produce exactly `Exception: <cause>` with
   no `We couldn…` prefix. Iteration 2 added the friendly sentence for P12;
   P06's screens assert `contains(cause)`, which would have silently passed
   with a leaked prefix. This pins byte-identity for all three writes.

### `money_ledger_states_test.dart` (+2, now 17)

New double `_RejectingWriteRepository` (delegates everything to the real
Drift repository; only `addMoney` / `recordSpending` throw
`StateError('ledger is read-only')`) — the "the database said no" half that
the sheet's own validation can never produce:

4. **A rejected `Add money` never shows a success message.** The sheet pops,
   `Added £…` is absent, the parent-facing reason
   `We couldn’t save that: … ledger is read-only` appears **as a live region**
   (`SemanticsFlag.isLiveRegion` — a toast appears with no focus change, so it
   must announce), the hero still reads `£4.20`, the note never lands in the
   ledger, and the `gift` row count in the real database is unchanged.
5. **A rejected `Record spending`** likewise: no `Spent £…`, the reason
   toast, unchanged row count, ledger intact.

Together with 2b's validation-rejection test, the review-6 guarantee is now
pinned on both halves: a success message cannot precede a write that was
rejected, whether the rejection came from the sheet or from the database.

## Re-verified from the brief (no new tests needed — all green)

- **bloc**: every event/state path — load, child selected (before load, same
  child, unknown child, dropped child, empty family), both submits (accepted
  silent write-through, rejected), stream failure, retry, terminal-error
  close, and the three P06 setup writes.
- **States**: loading (spinner, no chrome), failure (message, operable
  `Try again` that really re-subscribes), repeated failure, one child with an
  empty ledger, no children (`Seed.empty` → `/add-children`).
- **Navigation**: `Payout time` pushes `/payout` (never `go`), back restores
  `/money`, all four tab-bar branches, the segment is not a navigation.
- **Responsive**: light+dark × 320/390/430 × text scale 1.0/1.3, no overflow.
- **Owner rules**: one 20 px gutter on every block; tab-bar surface runs to
  the physical edge in light and dark, with and without a 34 px OS inset,
  probed as a rendered pixel (must be `surface`, never `paper`).
- **a11y**: `SemanticsAction.tap` on every control, each action driving real
  state or a real DB write; icon-only close labelled + ≥ 44 dp; sheet fields
  labelled; inline error is a live region; progressbar announces
  `Savings goal progress` / `62 percent` and is not a button.
- **Copy**: em dash U+2014, middle dot U+00B7, minus U+2212, arrow U+2192, no
  ASCII hyphen anywhere; `CHILD ORDER` (Maya then Leo) in the segment, the
  repository and the bloc; `google_fonts` absent; no `NestChip` rows on this
  screen (segmented + buttons only), so `NestChipWrap` is N/A.
- **Data**: every number asserted from the seeded database (`£4.20` / `£2.10`
  / 62% / `Sat 3 Oct`); no design number hard-coded.

## Bugs found

**None.**

Checked and deliberately **not** reported, per the brief:

- *Process items* (uncommitted work, branch vs main, merge order) — handled by
  the loop.
- *Deferred shared items* in `SHARED_REQUEST.md` §1–3 (tile radius in the
  shared `NestListRow`, a shared `NestPageTitle`, the `NestSegmented` 44 px
  floor) — P12 works around them correctly at the call site and the results
  are pinned; they are other screens' / design-system items, not P12 defects.
- *Review 8 / 10 / 13* — declined or hand-off items already documented in
  `2_build.md` (review 13 is a P13 hand-off about `state.items`).
- *Hero semantics merge* (card + `Payout time` in one node) and the
  *`NestProgress` node merge* — operable and labelled; the same `NestCard`
  behaviour ships on P08, and the required label/value are both announced.
  Design-system note, not a P12 defect (unchanged from iteration 1).

## Handed to stages 4/5

1. `money_ledger_geometry_test.dart` now pins ten anchors at ±1 px; a new
   spacer above the title will fail the suite immediately, which is the
   intended guard.
2. Stage 5 still owes a fresh light+dark capture and `compare.py`: the
   iteration-1 verdict was overruled on the basis of `cmp_light_1`, and no
   screenshot has been taken since the fix. Widget-space geometry is proven;
   the pixel band table is not.
3. Stage 5 should verify shape rects, not only text: segmented thumb
   173×44 at x 24, `Payout time` 310×52 at top 312, row buttons 170×48.
4. `/payout` (P13) is still the placeholder the ledger pushes to — other
   screen's loop.

## Scope

`git status --porcelain` shows only `app/test/features/pocket_money/**` (2
files edited by me) plus this note. No `app/lib/**`, no `app/lib/core/**`, no
`app/lib/app/**`, no other feature, no `tools/screens/**`. No `flutter clean`,
no interactive `flutter run`, no simulator, `analysis_options` untouched.

VERDICT: PASS
