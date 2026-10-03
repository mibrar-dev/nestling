# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 4)

Two parallel builders worked on P06; this stage only integrated them and fixed the
breakage the merge caused. Route `/pocket-money-setup` · feature `pocket_money` · parent mode.

## 2a — logic builder (`2a_build_logic.md`, iteration 4)

- **Contract: no event/state shape changes** (additive-only as in iteration 3:
  `withChildBase`, `copyWith(clearErrorMessage:)`, private bloc fields).
- **Files changed:** `pocket_money_bloc.dart` (load `onData` now drops the pending
  day request only once the stream *confirms* it, so an unrelated re-emission can
  no longer swallow a correction tap — P06-BUG-09 fixed and un-skipped),
  `pocket_money_setup_repository_test.dart` (new `Seed.onboardingKids` emits the
  same setup as demo test — the shoot seed), `p06_bugs_test.dart` (un-skipped BUG-09).
- **Item 1 (seed `onboarding_kids`)**: verified read-only — the seed already carries
  Maya £3.00 lilac / Leo £1.50 peach in insertion order; the view adds no defaults.

## 2b — UI builder

`2b_build_ui.md` was **not rewritten this iteration** (the file still describes
iteration 3), but its code landed in the worktree: the chip row now sits inside the
card's 16px inset with `NestChipWrap` (notes item 2 + item 6), the coin tile uses the
gold `NestlingIllustrations.coin` SVG (item 4), option-card title/sub line heights
match the HTML 22/20 (item 5), and the day pill is `_DayPill` at the design's 32px
(item 3 visual cause). Item 3 (letter-spacing 0) is the shared fix already on main.

## Integration breakages found and fixed (smallest change)

The UI chunk landed mid-rewrite, so its own test expectations disagreed with its new
geometry. Three fixes, all minimal:

1. **Day cells were 32 tall, violating the 44dp parent tap target** (accessibility
   test: "Mon is 32.0 tall") and the ±5px tap test failed because hit testing stops
   at the first ancestor whose own bounds miss the point, so the 32-tall row box
   blocked `NestChipWrap`'s slop expansion. Fix: `_DayCell` SizedBox
   `NestSpacing.s8` → `NestDevice.tapParent` with the pill centred, and the row
   SizedBox height 32 → 44 to match. The pill still paints 32.
2. **Four stale test expectations** that pinned the 32-tall cell (alignment group,
   "every tap target is at least 44dp", "tap targets hold at 320dp × 1.3", day-row
   geometry) → updated to `NestDevice.tapParent` with a note that the pill's 32px
   paint is asserted separately; the `dayPill()` finder was hoisted to file scope so
   the ±5px tap test measures the pill (its stated intent) instead of the cell.
3. **`find.byType(SvgPicture)` now matches two** (back chevron + gold coin) → the
   "decorative coin icon is not announced" test scopes its finder to the coin asset
   by name and still asserts the `ExcludeSemantics` wrapper.

## ORCHESTRATOR_NOTES "UPDATE (04:05)" items

| Item | Status |
|---|---|
| 1. seed `onboarding_kids`, children from DB in insertion order | DONE (2a, pinned by test) |
| 2. chip row inside the card's 16px inset, 32px pills, even gaps | DONE (2b) — view test asserts no chip rect leaves the padded rect |
| 3. letter-spacing 0 | DONE (shared fix on main; nothing local to change) |
| 4. gold coin glyph tile | DONE (2b, `NestlingIllustrations.coin`) |
| 5. option-card heights match HTML padding/line heights | DONE (2b, 22/20 line heights) |
| 6. `NestChipWrap` for the chip row, taps 5px above/below | DONE (2b + integrator fix 1; test green) |

## FIXES_3 items

Only one item (the ORCHESTRATOR_NOTES update above). P06-BUG-09 fixed/un-skipped by
2a; BUG-03 fixed/un-skipped by 2b; BUG-04 remains intentionally `skip: true` with a
documented comment (its ≥44 **width** demand is superseded by note item 2 — 7 chips
must fit inside the 16px inset).

## Analyze / test tails

- `dart format .` → `Formatted 386 files (0 changed) in 1.32 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 4.5s)`
- `flutter test test/features/pocket_money` → `+124 ~1: All tests passed!`
- `flutter test` (full app) → `+1114 ~3: All tests passed!` (EXIT 0). The 3 skips are
  documented `p06_bugs_test.dart` proofs (BUG-04 superseded, plus two other files'
  own skips); none are in the feature's other test files.

## Scope compliance

Integrator edits are limited to `app/lib/features/pocket_money/presentation/views/`
and `app/test/features/pocket_money/` — RULES §1. No shared code, no
`analysis_options` change, no `google_fonts`/`GoogleFonts` in the feature.

VERDICT: PASS