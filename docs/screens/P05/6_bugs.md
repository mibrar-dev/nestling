# P05 · Add children — bug hunt (STAGE 6, iteration 8)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on the
iteration-8 build (`3ccfdf1 P05: checkpoint after build (iteration 8)`, main
merged through `b466c96`: shared `NestChipWrap`, chip pill padding, balanced
text). This stage ran in the loop’s parallel wave with the iteration-8
test / review / UI stages, so suite numbers are snapshots.

Gates on my snapshot:

* `app/test/features/family/p05_bugs_test.dart` — **12 passed, 0 skipped**
  (P05-BUG-11 is un-skipped again and green);
* family suite — **130 passed, 0 skipped, 0 failed**; zero `skip:` across all
  three family test files;
* `dart format` clean · `flutter analyze` No issues found;
* the build stage’s clean full-suite run was `+1155: All tests passed!` (my
  own full-suite attempt is not quoted: the other stages were running their
  tests concurrently, the known flake source).

**Result: 0 new bugs. P05-BUG-11 is fixed and re-proved; the chip pill shape
is fixed; no P05-owned bugs are open. VERDICT: PASS.**

---

## P05-BUG-11 — FIXED (was: the 44 px chip tap area clipped by the row)

Both interactive rows (age chips **and** swatches) now use the shared
`NestChipWrap`, whose render object widens only the hit test
(`hitSlop = (44 − 32) / 2 = 6`). The proof is un-skipped and rewritten to tap
the block’s unambiguous outer edges; my independent probe confirms:

```
ageChip-4-6  pill 34,527 → 104,559 (70 × 32)
painted DecoratedBox rect == pill rect (same=true)
tap 5 px above the first pill  → 4–6 selected ✓
```

The build also found and fixed the hidden blocker: the former
`Semantics(container: true)` wrapper around the row was itself a tight render
box that clipped the widened hit test, so the group label moved onto the
row’s `.lbl` heading (see the observation below). The old
“32-px target” characterisation test (which asserted the bug) was deleted.

## Chip pill shape — FIXED (FIXES_7 §1 / UI-shapes rule)

The shared `shared/chip_pill_padding` fix moved the 14 px visual padding
**inside** the `DecoratedBox`, so the background and 1.5 px border paint the
full pill instead of just the text. `p05_view_metrics_test.dart` (bundled
Inter faces) pins pill = text + 28, 32 high, painted rect == chip box, one
row, 8 px gaps, content-edge x.

Independent check against the design PNG (light, pill centre rows, ÷3):

| pill | design PNG (measured) | app (bundled Inter, metrics test) | Δ |
|---|---|---|---|
| 4–6 | 55.0 (34.0–89.0) | 53.28 | −1.7 |
| 7–9 | 54.0 (97.0–151.0) | 52.02 | −2.0 |
| 10–12 | 67.0 (159.0–226.0) | 64.80 | −2.2 |
| 13+ | 54.0 (234.0–288.0) | 52.25 | −1.8 |

Gaps 8/8/8 and left edge 34 (= 20 gutter + 14 card padding) match exactly.
The 1.7–2.2 px width delta is the design PNG’s antialiased edges (my
non-white threshold counts ~0.5–1 px per side) plus a font-build difference;
it is for the UI stage’s shape check to settle, not a layout defect. No pill
is text-width any more.

## Verified sound (probes + suite on this build)

| Check | Result |
|---|---|
| All fixed proofs | P05-BUG-1…11 un-skipped and green (12 proofs, 0 skips) |
| Child order (ruling) | Maya left (30), Leo right (210) from `createdAt, rowid` ✓ |
| Kid cards | 116.0, design rhythm ✓ |
| Chip geometry | pill 70 × 32 (test font), painted rect == box, 8 px gaps ✓ |
| Balanced h1 | `NestBalancedText` inside `Semantics(header: true)`; box top 107 == plain-h1 anchor; 320×1.3 no overflow ✓ |
| Same-frame double tap | one child inserted ✓ |
| Restart / Drift persistence | child persisted and rendered after relaunch ✓ |
| Kid-mode guard | deep link → `/parental-gate` ✓ |
| Data edges | 6 children + long names at 320×1.3 → no exceptions ✓ |
| Fonts / letter spacing | no `google_fonts`/`GoogleFonts` in the feature or its tests; `NestType` letterSpacing 0 ✓ |
| Copy / owner rules / dark | unchanged from the verified iteration-6 UI PASS; h1 copy still U+2019 ✓ |

## Observations (not findings)

* **Group semantics.** The design’s `role="group" aria-label="Age band"` is now
  a labelled node on the row’s `.lbl` heading, a *sibling* of the chips — the
  alternative (a `Semantics` container around the row) is a tight render box
  and clips the widened hit test, which is exactly BUG-11. The semantics tree
  confirms every chip remains its own node with `isButton`, `hasSelectedState`
  and `isSelected` (“4–6” … “13+”), and the label still precedes them in
  traversal order. Acceptable trade-off; flagged so it is a conscious choice.
* **Two-run gap taps.** In the wider test font the chips wrap to two runs;
  a tap in the 8 px run gap is routed to the *nearest* chip (e.g. 5 px below
  `4–6` selects the chip directly beneath it). That is the component’s
  documented nearest-chip rule and only occurs where runs wrap (320 px /
  1.3×); on the device the row is a single run.
* The UI stage still owes the iteration-8 re-shoot with the shapes rule
  (pill/field/card background rects); this stage is simulator-forbidden.

VERDICT: PASS
