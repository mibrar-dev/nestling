# P05 · Add children — test notes (STAGE 3, iteration 5, final)

Route `/add-children`, feature `family`, parent mode. Changes are confined to
`app/test/features/family/add_children_test.dart` and these notes — no product
code touched.

**Everything is green this iteration, including the shared gate that was red in
iterations 3 and 4**: the full suite is `00:45 +672: All tests passed!`. The
remaining visual drift the QA note asked about is measured, fully attributed and
filed; nothing in it is fixable inside P05's scope.

## Results

```
dart format .        clean (366 files, 0 changed)
flutter analyze      No issues found!
flutter test         00:45 +672: All tests passed!     (full suite, green)
  test/features/family/   119 tests — 108 add_children_test.dart,
                          11 p05_bugs_test.dart, zero skips
```

The previously failing shared test is fixed on main: `cdd4cf5` /
`099748e` ("push/pop contract asserts router paths, not placeholder titles")
replaced `showsFrom: 'P05 Add children'` with path-based assertions, so
`app/test/app/router_push_test.dart` passes and my iteration-3/4 BLOCKING
filing is now historical. P05 needed no change for it. The `shared/family_time_zone`
Drift v2 migration that landed with it also left all 119 feature tests green
without edits.

## Tests added (3)

All three answer the QA note for `cmp_light_4` ("chips row centre ≈ +5 px low,
Avatar colour ≈ +12 px, helper text ≈ +12 px — cause: chip height and the gap
below the chips… take the chip height, the chip-row→label gap and the
label→swatch gap exactly from the HTML… swatch diameter 44 with 8 px gaps —
match").

1. **The chip row height, exactly** — measures the chip box and asserts the
   delta to the design rather than hand-waving it: `chip.height − 32 == 12`,
   i.e. the shared chip's 44-px tap box is in the flow where the design's
   `.chip { height: 32px }` is 32. That single number accounts for the whole
   remaining in-card drift: 44/2 − 32/2 = 6 px for the chip row's own centre
   (QA measured ≈ +5) and 44 − 32 = 12 px for every row below it (QA measured
   ≈ +12 at "Avatar colour" and the helper text). The assertion is written so it
   fails when the shared fix lands — that is its acceptance criterion.
2. **The swatch row matches the design** — five 44 px circles, gaps of exactly
   8, starting on the card content edge (20 + 14), all on one row.
3. **The head starts below the status bar and the 60-px compact nav** —
   `h1.top == statusH(47) + (44 + 4 + 12)`, derived from `.nav-bar.compact`'s
   padding rather than hard-coded. This pins the shared nav-height fix from the
   screen's side (the "DONE & verified: header" item): any regression in the bar
   moves the head and fails here.

Everything else the QA note listed as DONE is still pinned by existing tests:
Maya first (the five-test CHILD ORDER group, including the rename proof), the
kid cards (116-px tile, pencil containment, computed columns), the "Add a child"
card top (`grid → form card == 12` at 320/390/430), the full form rhythm
(`h3` 24 · 10 · label 18 · 6 · input 52 · 8 · label 18 · 4 · chips · 8 ·
label 18 · 4 · swatch 44 · 6), the focus ring, copy characters, semantics,
tap targets, navigation, and both owner rules (20 px gutters and bottom-edge at
every width and in both themes).

## Bugs found

**None.** No P05-owned test failed and no defect was found in the screen.

### One shared finding, filed and quantified (not a P05 bug)

`NestChip`'s 44-px minimum tap box is in the **flow**, so the chip row and
everything below it sit 12 px lower than the design's 32-px `.chip` — the
vertical twin of the width defect that landed in `7eaa1f7`. Measured to rule out
every other suspect: the chips→label gap is exactly 8, the label→swatch gap
exactly 4, the swatches are 44 with 8 px gaps, the note gap exactly 6, and the
on-device line-box effect is already filed separately. So the chip's flow height
is the only remaining term, and it is shared code that P05 cannot adjust without
clipping the tap area or re-implementing the component. Filed in
`SHARED_REQUEST.md` with the delta table and two owner options (move the 44-px
minimum out of the flow, or accept 44 and amend the design's `.chip`).

## Standing state of P05 (for the record)

* **CHILD ORDER** — satisfied: the repository orders by `rowid` and the screen
  renders it verbatim. The durable `createdAt` ordering is still filed; the
  rename proof keeps the ruling green after it lands.
* **COPY** — character-exact against the HTML (curly apostrophe, em dash, en
  dashes, UK `colour`), pinned by code-unit assertions.
* **P05 bug proofs** — BUG-1 … BUG-10 all un-skipped and green in
  `p05_bugs_test.dart`.
* **Carried accepts** (unchanged positions, reviewed): mid-save Continue is
  dropped by the BUG-2 guard, `onSaved` stays on the event until P15 lands,
  `child_display.dart` placement, the raw exception string, and the 1 px pencil
  offsets mirroring `.edit { top: 1px }`.

VERDICT: PASS