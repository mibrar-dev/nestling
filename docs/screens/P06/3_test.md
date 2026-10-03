# P06 Pocket money setup — Stage 3 TEST (iteration 3)

Route `/pocket-money-setup` · feature `pocket_money` · parent mode · in-memory
Drift DB (`Seed.demo` / `Seed.empty`), real router + DI + themes.

Iteration 2 ended FAIL with one real defect (P06-BUG-01, stepper lost update)
found by these tests. The iteration-3 build fixed BUG-01/02/03/04/05/06/07
(`2_build.md`). This stage re-verifies every fix, then extends coverage over
the new code paths (`_requestedBase` accumulation, `_pendingDay` guard,
`clearErrorMessage`, `withChildBase`, `_DayRow`/`_DayPill`, the inline
write-error path).

## Tests added (20 new; 83 → 103 in my three files)

### `pocket_money_setup_bloc_test.dart` (+12, now 29)

| Test | What it pins |
|---|---|
| `copyWith keeps the message unless clearErrorMessage is set` | the new `clearErrorMessage` flag: default keeps the message (a status flip must not silently drop it), `true` clears it, `true` also wins over an explicit message, and clearing touches nothing else |
| `withChildBase` × 3 | new entity helper: replaces only the named child, keeps insertion order (Maya → Leo), reuses the untouched child instance, never mutates the original, returns an equal setup for an unknown id, and is a no-op with no children |
| three rapid steps add 50p each: £3.00 → £4.50 | the BUG-01 fix at 3 taps: emits 300 → 350 → 400 → 450, DB ends at 450, and **Leo's row is untouched** by Maya's taps |
| the accumulation keeps the 2000p ceiling | 1950 + 3×50 in one turn clamps at 2000, the extra taps are no-ops, the `children` row never exceeds the cap |
| the accumulation keeps the 0p floor | 100 + 3×(−50) lands on 0 and never goes negative |
| a rejected step forgets the request | new `_requestedBase.remove` path: after a failed write the next tap builds on the confirmed 300p, so the writes are `[350, 350]`, not `[350, 400]` (a phantom +50p) |
| a rejected payout-day write unsticks the guard | new `_pendingDay = null` on error: retrying the same day reaches the repository again (`[7, 7]`) instead of being swallowed by the no-op guard |

`_RecordingRepository.throwOnWrite` became mutable so a test can fail one write
and succeed the next.

### `pocket_money_setup_view_test.dart` (+9, now 60)

| Group | Coverage |
|---|---|
| day row geometry (P06-BUG-03/04) — `every day cell is at least 44×44 and paints a 32dp pill` | light/dark × 320/390/430: every cell is ≥44 wide **and** 44 tall, and the painted `.chip.day` pill is exactly 32 high and fills its cell (the old FittedBox-scaled `NestChip` measured ~19) |
| — `at 390 and 430 all seven cells sit inside the card` | the design width shows all seven pills inside the card with no horizontal scroller |
| — `at 320 the row scrolls and Sun is still reachable` | the scroll branch really scrolls: Sun starts off-viewport (right edge 366 > 320), a −120 drag brings it to ≤320, and tapping it selects day 7 |
| — `the selected pill is token-coloured in light and dark` | Saturday's pill = `leafTint` fill + 1.5px `leaf` border, Monday = `surface2` + transparent border, and the two themes resolve **different** colours (discrimination guard, so the dark assertion cannot pass vacuously) |
| failed write keeps the form (P06-BUG-05) — light + dark | a rejected `setMode` renders the message inline in `tokens.danger` while every option card, day chip, weekly row, coin row and the CTA stay on screen, the rejected selection is not applied (Both stays selected), and no `Retry` appears |
| — (same test, second half) | the next successful write re-emits and clears the message (BUG-06), and `bloc.state.errorMessage` is null again |
| — `the router keeps working while an error is on screen` | with the flaky repository injected into GetIt, Back still reaches `/add-children` and Continue still reaches `/paywall` with an error on screen |

New helper `_FlakyModeRepository` delegates to the **real** Drift repository and
rejects one mode write. This matters: recovery from a write error rides the real
watch stream re-emission, which a one-shot fake stream can never reproduce (my
first attempt with a `Stream.value` fake kept the message and would have been a
false alarm).

Also updated the stale comment on the two-quick-taps test (it now guards a
fixed defect) and added `three rapid + taps reach £4.50 and then clamp at
£20.00` (a 1950p seed, four taps, DB verified at 2000 through the real row).

## Results

- `dart format test/features/pocket_money` → clean (0 changed after the last edit).
- `flutter analyze` (full app) → **No issues found!** (ran in 4.5s).
- `flutter test test/features/pocket_money/pocket_money_setup_bloc_test.dart` → **+29: All tests passed!**
- `flutter test test/features/pocket_money/pocket_money_setup_repository_test.dart` → **+14: All tests passed!**
- `flutter test test/features/pocket_money/pocket_money_setup_view_test.dart` → **+60: All tests passed!**
- `flutter test test/features/pocket_money/` → **+120 ~2: All tests passed!**
- `flutter test` (full app) → **+784 ~2: All tests passed!**, exit 0.
- The 2 skips are in `p06_bugs_test.dart` (the parallel BUGS stage's file, now
  2 open bugs). **My three files contain no `skip:`** and no
  `google_fonts`/`GoogleFonts`; scope is `app/test/features/pocket_money/**`
  only (RULES §1).

## Bugs found

**None.** Every iteration-3 fix is now covered by a passing regression test
(BUG-01 accumulation + clamps + the forgotten-request recovery, BUG-02 the
unstuck guard, BUG-04 the 44×44 cells and the 320 scroll branch, BUG-05 the
inline error with the form intact, BUG-06 the cleared message, BUG-07 the
no-write unknown child), and I found no new defect in the rewritten bloc/view.

## Measurements for the UI stage (not defects — for the record)

The day-row rewrite is a deliberate trade-off documented in the code: to reach
≥44dp cells the row breaks out of the card's 16px content inset down to a 2px
(`NestSpacing.gap2`) inset. Measured, with the card at x = 20…370 (390dp):

| Width | Cell | Pill row span | Inside the card? |
|---|---|---|---|
| 320 | 44.0 wide × 44 tall | 22 → 366 (scroll extent 68) | no — scrolls, by design |
| **390** | 44.3 wide × 44 tall | 22 → 368 | yes, 2px inset each side |
| 430 | 50.0 wide × 44 tall | 22 → 408 | yes |

Every other settings row keeps the card's 16px inset, so at 390 the day pills
now sit 14px closer to the card border than `Payout day` / `Weekly base` /
`Coin value` do, and the cell pitch is 44.3dp against the design's ~40.3dp. All
seven pills are visible at the design width, which is what the ALIGNMENT and
the 7-across design both need; whether the 2px inset is acceptable against
`design/html-source/screens/P06-pocket-money.html` (where `.day-row` sits
inside the card's 16px padding) is a UI-stage call. The `.chip.day` glyph size
(13px `fieldLabel`, `TODO(P06)` until `SHARED_REQUEST.md` lands) stays the one
open shared item, and its 32dp height — the visual cause of BUG-03 — is now
pinned here at every width, theme and scale.

## Cross-stage notes

- The BUGS stage's file has two proofs still skipped (it now reports two open
  bugs rather than one); neither is in my scope and none of my tests cover the
  same defect twice.
- `pocket_money_setup_repository_test.dart` needed no iteration-3 changes: the
  repository contract (`watchSetup`, the mirrored `families`/`settings` writes,
  the 0..2000 clamp, insertion order) is unchanged by this iteration.

VERDICT: PASS