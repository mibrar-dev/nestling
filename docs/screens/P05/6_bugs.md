# P05 · Add children — bug hunt (STAGE 6, iteration 7)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on the
iteration-7 build (`6ba0cb8 P05: checkpoint after build (iteration 7)`; the
iteration made **no product change** — tests and notes only, because the one
open item is shared and the shared fix had not merged yet). This stage again
ran in the loop’s parallel wave with the iteration-7 test / review / UI
stages, so suite numbers are snapshots.

Gates on my snapshot:

* `app/test/features/family/p05_bugs_test.dart` — **11 passed, 1 skipped**
  (the mandated P05-BUG-11 skip); `dart format` clean; `flutter analyze`
  No issues found (full app);
* family suite — **128 passed, 1 skipped, 0 failed** (the parallel test stage
  is still adding tests; no failures);
* full-suite snapshot — my run overlapped the other stages’ test runs and
  showed two `p02_bugs_test.dart` proofs red; both **pass in isolation**
  (13/13), so it is the known parallel-run concurrency artifact, not a
  finding. The build stage’s own clean run was `+984 ~1: All tests passed!`.

**Result: 0 new bugs. P05-BUG-11 remains a standing shared-pending skip by
orchestrator ruling — not a P05 finding while `NestChipWrap` is pending.
VERDICT: PASS.**

---

## P05-BUG-11 — standing orchestrator-mandated skip (shared fix pending)

`ORCHESTRATOR_NOTES.md` (04:31) ruled: keep **both** owner rules (32 px visual
chips **and** a 44 px tap target), do not take the accept/amend options from
the iteration-6 report; the fix is the shared `NestChipWrap` on
`shared/chip_wrap_hit_area`; until it merges, keep `[P05-BUG-11]` skipped with
a reason that references that branch, and treat the item as **not a P05
finding**.

Verified in the tree this stage:

* `NestChipWrap` is **not** present in `lib/core/design_system` on this
  branch; `add_child_form_card.dart` still uses the plain `Wrap` (correct —
  swapping now would be pre-merge).
* The skip reason on `[P05-BUG-11]` references
  `shared/chip_wrap_hit_area` and says it must pass once merged.
* The test stage’s green characterisation tests are in place and passing: the
  form card `Column` and `NestCard` both reach ≥6 px beyond the chip row (the
  reachability precondition for `NestChipWrap`), the row gaps are the design’s
  4 above / 8 below, and the 2 px top overhang lands on the inert “Age band”
  label, so no control can be stolen.

**Update for the next build:** `NestChipWrap` has now landed on `main`
(`e572850` add, `2333c35` hitSlop fallback gate, `f1915fe` merge,
`e3ae2b2` “chip rows use NestChipWrap”) — it is not yet merged into this
branch. When main is merged before the next build: replace the age-chip `Wrap`
with `NestChipWrap`, restore `atLeast44(chip)` in **both** width and height,
un-skip `[P05-BUG-11]` (it must pass), and re-shoot the UI.

## Verified sound (probes + suite on this build)

| Check | Result |
|---|---|
| All fixed proofs | P05-BUG-1…10 un-skipped and green (11 proofs, 1 mandated skip in the file) |
| Child order (ruling) | Maya left (30), Leo right (210) from `createdAt, rowid` ✓ |
| Kid cards / chip row | card 116.0; chip 32.0 (design) ✓ |
| Same-frame double tap | one child inserted ✓ |
| Restart / Drift persistence | child persisted and rendered after relaunch ✓ |
| Kid-mode guard | deep link → `/parental-gate` ✓ |
| Data edges | 6 children + long names at 320×1.3 → no exceptions; chips wrap to 2 rows in the wider test font (1 on device) ✓ |
| Head anchor | `h1.top == 107` = status 47 + compact nav 60 ✓ |
| Fonts / letter spacing | no `google_fonts`/`GoogleFonts` in the feature or its tests; `NestType` letterSpacing defaults 0 ✓ |
| Copy / owner rules / dark | iteration-6 UI check PASS: light 1.34%, dark 1.25%, every element row ±1 px; bottom edge and 20 px gutters verified ✓ |

## Notes

* Iteration-6 outcomes for the record: review PASS; UI PASS (the shared
  batch-2 chip closed the +5/+12 residual — band5 10.8% → 0.14%); the test
  stage independently found the same chip-tap clipping (P05-BUG-11), which the
  orchestrator has since assigned to the shared fix.
* No skipped proofs were added beyond the mandated one; no P05-owned bugs are
  open.

VERDICT: PASS
