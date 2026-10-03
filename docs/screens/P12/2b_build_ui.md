# P12 · 2b BUILD (UI chunk, iteration 2)

Files touched (all inside the 2b ownership boundary — `presentation/views/**`,
`presentation/widgets/**`, view/widget tests, `docs/screens/P12/`):

```
app/lib/features/pocket_money/presentation/views/money_ledger_view.dart
app/lib/features/pocket_money/presentation/widgets/money_history_row.dart
app/lib/features/pocket_money/presentation/widgets/money_edit_sheet.dart
app/test/features/pocket_money/money_ledger_view_test.dart      (+2 tests)
app/test/features/pocket_money/money_ledger_geometry_test.dart  (+3 asserts, 7→10 tests)
app/test/features/pocket_money/p12_bugs_test.dart               (un-skips only)
docs/screens/P12/SHARED_REQUEST.md                             (new)
docs/screens/P12/2b_build_ui.md                                (this file)
```

No `bloc/`, no `domain/`, no `data/`, no `core/`, no `app/`, no other feature,
no `tools/`, no `analysis_options`. No simulator booted, installed on,
screenshotted or driven. No image attached. No whole-app `flutter test`.

## Every ORCHESTRATOR_NOTES item

| Mandate | Done |
|---|---|
| Find the extra 16 px above the title | Deleted the `SizedBox(height: NestSpacing.s4)` between `NestStatusBar` and `_PageTitle` in **both** the loaded and the empty body |
| Title on the design y (P10's header layout) | 55 — `.ptitle` is the `.scroll`'s first child, so it gets only its own 8 px padding |
| Segmented / owed / goal / history tops | 105 / 173 / 400 / 504 — all within ±1 px, now pinned |
| Hero `-0.4` letter spacing | Kept (`NestType.kidHero(...).copyWith(letterSpacing: -0.4)`) |
| Real-font geometry test | `money_ledger_geometry_test.dart` now 10 tests, **10 green** (was 7 with 6 red) |
| History rows / dates / amounts | Unchanged — DB-driven (DATA OVER MOCKS) |

## FIXES_1.md — every UI/layout/copy item

| # | Sev | Item | Fix |
|---|---|---|---|
| 1 | major | Whole screen 16 px low | Removed both spacers. Title 71 → **55**, segmented 121 → **105**, owed 189 → **173** |
| 2 | major | Goal card 90 vs 88 | `.goal .t` is a 22 px line box; `copyWith(height: 22 / 16)` on `NestType.bodyStrong` at the call site → card **88**, goal top **400** |
| 3 | major | History tile radius 12 vs 16 | `NestRadii.allM` in `MoneyHistoryRow` (`NestSpacing.s3` is a *spacing* token). Radius + 40×40 size now asserted in the geometry test |
| 4 | minor | Hero +3 px after 1–3 | **Closed by measurement**, see below |
| 5 | minor | Sheet error is not announced | `Semantics(liveRegion: true)` around the inline error; asserted with `SemanticsFlag.isLiveRegion` |
| 6 | minor | Toast before the write is confirmed | Success toast now fires from a second `BlocListener` when the ledger stream re-emits with one more row for that child; a rejected write clears the pending copy so only the error toast shows |
| 11 | minor | `BlocBuilder` without `buildWhen` | `buildWhen: status \|\| data \|\| selectedChildId` (same as the sibling P06 view) |
| BUG-01 | major | Unbounded amount → int64 + 98 px row overflow | Integer-pence parser capped at £1,000,000.00 (whole part ≤ 9 digits), plus the row's amount is bounded by `maxWidth − 64` with an ellipsis as defence in depth |
| BUG-02 | major | `1,50` recorded as £150.00 | The parser **validates** (`^\s*£?\s*(?:\d{1,9}(\.\d{1,2})?|\.\d{1,2})\s*$`) instead of stripping separators — no silent 10–100× rewrite |
| BUG-03 | minor | `1.005` stored £1.00 | No float multiply anywhere: `whole * 100 + int.parse(fraction.padRight(2,'0'))`; >2 decimals is rejected |
| BUG-05 | major | Stack 15–21 px low | Same as findings 1–3; the skipped reproducer is **un-skipped and green** |

### Finding 4 — how the hero's 3 px was closed

The review forbade guessing and asked for a measurement. Measured off
`design/screens/light/P12-money.png` (÷3), the hero fill runs 519…1151 px =
**173…383.7** (exactly 211 px) and the `Payout time` fill starts at 936 px =
**312.0**. The CSS arithmetic only closes on a **17 px** label line box:

```text
20 pad + 17 lab + 44 amt + 4 brk-top + 40 brk (2 × 20) + 14 btn-top + 52 btn + 20 pad = 211
```

`.hero .lab` (`P12-money.html:5`) declares `font-size:14px` and **no**
line-height, so the design render resolved the browser's `normal` — Inter's
font metrics (ascender 0.969 em + descender 0.241 em, lineGap 0) at 14 px give
16.94 ≈ 17. With the token's 20 px the button would land at 315 and the card at
384+3. So the whole residual was the label, and it is pinned at the call site
(`copyWith(height: 17 / 14)`) exactly like `.hero .amt`'s −0.4 tracking — the
shared `NestType` styles are untouched. New geometry assertions pin the hero
height (211), the `Payout time` top (312), the goal height (88) and the tile
radius (16) so this cannot silently drift again.

### Not mine — handed on (logic layer, `pocket_money_bloc.dart`)

* **Finding 7 — raw `error.toString()` reaches the parent.** `money_ledger_
  states_test.dart` asserts the raw text (`find.textContaining('ledger is
  down')`), so the friendly mapping must happen in the bloc, not the view.
  Not patched here: that file and the bloc belong to the logic builder.
* **Findings 8/9/10/13** — `domain/next_payout.dart` placement,
  `MoneyLedgerData.setup` coupling, `state.items` semantics for P13. Finding 9
  is already done this iteration (`ledgerDataFallback` now lives in
  `test/features/pocket_money/ledger_data_fallback.dart`).

### Filed for the orchestrator (`SHARED_REQUEST.md`)

1. `nest_list_row.dart` — standard tile radius must be `--r-m` (16), not the
   compact 12. Every other screen's tiles are 4 px off for the same reason.
2. `NestPageTitle` — `.ptitle` is a private class on four screens.
3. `NestSegmented` — a 44 px floor so six children at 320 dp cannot collapse
   to 42 px. **P12-BUG-04 stays `skip: true`** because P12 must not fork the
   shared control; its comment now says so.

## Owner rules re-checked

* **BOTTOM EDGE** — untouched: `ParentShell` + `NestTabBar` paint `surface`
  through to the physical edge; `money_ledger_responsive_test.dart`'s pixel
  probe still passes in light and dark at OS inset 0 and 34.
* **ALIGNMENT** — 20 px gutters on every block; the responsive suite's gutter
  test still passes at 320/390/430 in both themes.
* **CHILD ORDER** — unchanged, `data.children` creation order.
* **COPY** — unchanged; the copy audit still passes character by character
  (`—` U+2014, `·` U+00B7, `−` U+2212, `→` U+2192, no ASCII hyphen). The only
  new string is the validation message `Enter an amount up to £1,000,000.00`,
  which follows the sheet's existing `Enter an amount …` pattern.
* **LETTER SPACING** — `NestType` untouched; the single call-site tracking is
  still the hero's −0.4.
* **BALANCED HEADINGS / CHIP ROWS / PIP / TRIAL / PERIODS** — not applicable:
  `.ptitle` sets no `text-wrap: balance`, the screen has no `NestChip`, no Pip,
  no trial copy and no quests.
* **FONTS** — no `google_fonts`, no `GoogleFonts.*`.
* **ACCESSIBILITY** — every control is unchanged and still exposes
  `SemanticsAction.tap`; the new `Semantics(liveRegion: true)` wraps
  non-interactive error text, and the new listener adds no node. The
  `performAction(tap)`-drives-real-DB test still passes.
* **DESIGN SYSTEM** — no re-implemented component, no colour or size literal;
  the only screen-local constants are two measured line-height ratios and the
  existing `.hrow` 56 / `.goal img` 56.

## Verification

```
dart format .                                     clean (0 changed)
flutter analyze lib/features/pocket_money
                  test/features/pocket_money     No issues found!

money_ledger_geometry_test.dart   +10  All tests passed   (was +1 −6)
p12_bugs_test.dart                +22 ~1 All tests passed  (BUG-01/02/03/05
                                                            un-skipped and green;
                                                            only BUG-04 skipped)
money_ledger_view_test.dart       +14  All tests passed   (2 new)
money_ledger_states_test.dart     +15  All tests passed
money_ledger_responsive_test.dart +24  All tests passed
flutter test test/features/pocket_money
                                    +308 ~1 All tests passed
```

Whole-app `flutter test` and the simulator captures are the integrator's.

## LEFT FOR NEXT ITERATION

1. **Finding 7** — friendly `errorMessage` in `pocket_money_bloc.dart`
   (logic layer). The `_FailureBody` and the error toast render whatever the
   bloc hands them, so the fix has to happen upstream; `money_ledger_states_
   test.dart` currently pins the raw text and needs updating with it.
2. **Findings 8/10/13** — `domain/next_payout.dart` placement, the
   `MoneyLedgerData.setup` coupling and the P13 hand-off note for
   `state.items` (logic layer, already listed in `4_review.md`).
3. **P12-BUG-04** — the 320 dp six-child segment, once `NestSegmented` has a
   44 px floor (`SHARED_REQUEST.md` §3).
4. **Stage 5** must re-shoot light + dark and re-run `compare.py`: the
   16 px constant translation is gone, so the band table should now be
   dominated only by the accepted differences (status bar, DB rows). Expect
   the hero/goal/history anchors at exactly 173 / 400 / 504.

VERDICT: PASS
