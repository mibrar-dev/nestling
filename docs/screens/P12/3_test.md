# P12 · 3 TEST (iteration 3)

Route `/money`, feature `pocket_money`, parent mode. In-memory Drift DB
(`AppDatabase.memory()`) with `Seed.demo` / `Seed.empty`; the story day is
pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.

No production code was edited in this stage. No simulator was booted,
installed on, screenshotted or driven (stage 5 only). No images attached.

## Outcome

**PASS — all tests green, no bugs found.**

```
$ dart format .
Formatted 437 files (0 changed) in 1.31 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.2s)

$ flutter test
01:17 +1914 ~1: All tests passed!

$ flutter test test/features/pocket_money
00:13 +321 ~1: All tests passed!
```

The single `~1` is the intentional skip in `p12_bugs_test.dart:320`
(P12-BUG-04: six children at 320 dp shrink the **shared** `NestSegmented`
options below 44 px — `SHARED_REQUEST.md` §3; P12 must not fork a shared
control, and main's `0cdb53c` shared brief fixed *semantics*, not the
tap-target floor, so the skip correctly stands).

Per file, all green:

```
money_ledger_responsive_test.dart     +29   (5 new this iteration)
money_ledger_geometry_test.dart       +11
money_ledger_states_test.dart         +17
pocket_money_ledger_bloc_test.dart    +18
money_ledger_view_test.dart           +15
p12_bugs_test.dart                    +22 ~1
pocket_money_repository_test.dart     +18
```

## What iteration 3 changed, and what this stage added for it

Iteration 2 exited `review=FAIL` on **one major**: the 47 px status-bar reserve
was `ListView` child 0, so the longer-than-fold ledger scrolled the band away
and painted white history cards under the OS clock. The iteration-3 build
rebuilt both bodies as `Column[NestStatusBar, Expanded(ListView)]`, i.e. the
band became the scroller's *preceding sibling* exactly as
`P12-money.html:17-20` / `components.css:46/65` define it.

That fix is **pixel-identical at rest**, so no existing assertion could see it,
and it left two edges of the new layout unpinned. Both are now covered here.

### `money_ledger_responsive_test.dart` (+5, now 29)

**Group "pinned band on a notched device" (3 tests).** The whole screen's top
now hinges on `NestStatusBar`'s `max(viewPadding.top, 47)`. Everything in the
suite so far ran with a 0 inset, i.e. the design's own 47 — nothing had ever
checked a device whose inset is **taller** than the design's band, which is the
case where content would paint under a notch.

- light + dark at 390×844, 59 px top inset: the band measures **59** (not 47),
  stays at top 0, the scroller starts exactly at `band.bottom`, the title keeps
  the design's own inset-independent relationship (`.ptitle`'s 8 px
  `padding-top` below the band), and after a 120 px drag no `MoneyHistoryRow`
  paints above 59.
- 320 dp + 59 px inset at text scale 1.3: the band still pins and the whole
  ledger (hero, row buttons, footer) still lays out with no overflow.

Writing this uncovered a **test-harness** subtlety worth recording:
`TestFlutterView.padding` and `.viewPadding` are *independent* overrides, and
`NestStatusBar` reads `MediaQuery.viewPaddingOf` — setting only `padding`
(what the bottom-inset probe does, correctly, for `SafeArea`) leaves the band
at 47. The helper now sets both for a top inset. The app code was right; the
probe was incomplete.

**Group "the scroller still reaches its own end" (2 tests, light + dark).**
The `Column`/`Expanded` rebuild is the only change to this screen's scroll
geometry, and the finding-1 guard only covers the **top**. A missing
`Expanded`, or padding moved to the wrong edge, would leave the last row and
the footer caption under the tab bar. After scrolling to the end:

- the footer caption's bottom is above `NestTabBar.top` (never behind it);
- the tail space is the design's `.scroll { padding-bottom: 32px }`
  (`NestSpacing.s8`, ±1 px);
- both row buttons clear the tab bar too.

### Already covered by the iteration-3 build, verified not duplicated

I read each new test before writing anything and deliberately did **not**
re-test them here:

- **Finding 1** scrolled-state guard (`money_ledger_geometry_test.dart:98`) —
  band pinned, scroller at 47, first row ≥ 47; plus the empty body at `:259`.
- **Finding 2** shared `NestTextField.errorText` — announced once through the
  labelled node and positioned above the Note field
  (`money_ledger_view_test.dart:629-641`).
- **Finding 3** `_PendingWrite` child attribution, gated on a fake repository so
  the switch-before-round-trip state is reachable (`money_ledger_view_test.dart:652`).
- **Finding 4** `summarise()` same-second tie — both input orders pinned in
  `pocket_money_repository_test.dart`, mirrored into the shared test fallback so
  production and fakes agree.
- **The shared `NestSegmented` semantics change** (`0cdb53c`, one node per
  option) — my states suite still asserts `hasAction(tap)` on both options and
  `performAction` driving real bloc state; it was unaffected.

## Geometry vs the design (UI VERDICT RULE)

`money_ledger_geometry_test.dart` (real fonts via `FontLoader`, 390×844) pins
all ten anchors at ±1 px — inside the ±2 px rule, with no uniform shift:

| anchor | design y | app y |
|---|---|---|
| status-bar reserve | 47 | 47 |
| title line-box top | 55 | 55 |
| segmented track top (first control) | 105 | 105 |
| owed card top / height | 173 / 211 | 173 / 211 |
| `Payout time` top | 312 | 312 |
| goal card top / height | 400 / 88 | 400 / 88 |
| history card top | 504 | 504 |

Iteration 2's numbers (71/121/189/419/525) remain in the git history as the
before-picture; the pin is what stops the spacer coming back.

## Re-verified from the brief (all green, no new tests needed)

- **bloc**: every event/state path — load, `ChildSelected` (before load, same
  child, unknown child, dropped child, empty family), both submits (silent
  write-through when accepted; message-only when rejected), stream failure,
  retry, terminal-error close, the exact `We couldn’t…` copy (U+2019), P06's
  own raw setup copy kept byte-identical, and the three P06 setup writes.
- **States**: loading, failure (operable `Try again` that really re-subscribes),
  repeated failure, one child with an empty ledger, no children
  (`Seed.empty` → `/add-children`), a database-rejected write that toasts the
  reason and never a success.
- **Navigation**: `Payout time` pushes `/payout` (never `go`), back restores
  `/money`, all four tab-bar branches, the segment is not a navigation.
- **Responsive**: light+dark × 320/390/430 × text scale 1.0/1.3, no overflow.
- **Owner rules**: one 20 px gutter on every block; the tab-bar surface runs to
  the physical edge in light and dark with and without a 34 px OS inset,
  verified as a rendered pixel (must be `surface`, never `paper`).
- **a11y**: `SemanticsAction.tap` on every control with each action driving real
  state or a real DB write; icon-only close labelled and ≥ 44 dp; sheet fields
  labelled; inline error a live region attached to Amount; progressbar
  announces `Savings goal progress` / `62 percent` and is not a button.
- **Copy**: em dash U+2014, middle dot U+00B7, minus U+2212, arrow U+2192, no
  ASCII hyphen anywhere; `CHILD ORDER` (Maya then Leo) in the segment, the
  repository and the bloc; no `google_fonts`; no `NestChip` rows on this screen,
  so `NestChipWrap` is N/A; every number asserted from the seeded database.
- **DATA OVER MOCKS**: `£4.20` / `£2.10` / 62% / `Sat 3 Oct` come from
  `Seed.demo`, never from the design PNG.

## Bugs found

**None.**

Checked and deliberately **not** reported:

- *Process items* (uncommitted work, branch vs main, merge order) — the loop's
  business.
- The iteration-2 review's remaining minors, all documented with rationale in
  `2_build.md`: finding 7 (raw exception suffix retained — ≈12 pinned
  `contains` expectations depend on it), finding 6 (`.ptitle` is a 4th private
  copy — `SHARED_REQUEST.md` §2, needs `core/`), findings 5/8/9 (plan-mandated
  path, P13 hand-off, declined P06-compat trade-off).
- `SHARED_REQUEST.md` §1–4 — cross-screen/design-system/core items, non-blocking,
  with P12 correct at the call site.
- The hero-card semantics merge and the `NestProgress` node merge — operable and
  labelled, same `NestCard` behaviour that ships on P08.
- *Not a bug, but worth the loop's attention:* the test-harness `padding` vs
  `viewPadding` trap above. Any screen test that fakes a **top** inset must set
  `tester.view.viewPadding` as well, or it silently tests the 0-inset case.
  That is a shared-test-knowledge item, not a P12 defect.

## Handed to stages 4/5

1. Stage 5 still owes a fresh light + dark capture and `compare.py`: the
   finding-1 pin is deliberately pixel-identical **at rest**, so `cmp_*_3` must
   show no band movement. The scrolled state has never been pixel-compared; it
   is now covered by widget guards at 47 and at a 59 px inset instead.
2. Stage 5 should verify shape rects, not only text: segmented thumb 173×44 at
   x 24, `Payout time` 310×52 at top 312, row buttons 170×48.
3. `/payout` (P13) is still the placeholder the ledger pushes to — other
   screen's loop.

## Scope

`git status --porcelain` shows only `app/test/features/pocket_money/
money_ledger_responsive_test.dart` (edited by me) plus this note. No
`app/lib/**`, no `app/lib/core/**`, no `app/lib/app/**`, no other feature, no
`tools/screens/**`. No `flutter clean`, no interactive `flutter run`, no
simulator, `analysis_options` untouched.

VERDICT: PASS
