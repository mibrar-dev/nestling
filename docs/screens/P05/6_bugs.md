# P05 · Add children — bug hunt (STAGE 6, iteration 6)

Route `/add-children` (feature `family`, parent mode). Adversarial pass on the
iteration-6 build: schema v3 `createdAt` ordering, the shared batch-2 chip
(32 px layout / 44 px overlay), the bundled-font and letter-spacing merges.
This stage ran in the loop’s parallel wave together with the iteration-6
test / review / UI stages, so the family-suite snapshot below includes the
test stage’s in-flight edits (a process item, not a finding — noted so the
gate record is honest).

Gates on my snapshot:

* my proof file `app/test/features/family/p05_bugs_test.dart` —
  **11 passed, 1 skipped**; with
  `flutter test --run-skipped test/features/family/p05_bugs_test.dart` the
  eleven fixed proofs pass and the new **P05-BUG-11** fails exactly as
  recorded;
* `dart format` clean for my files; `flutter analyze` shows **2 warnings in
  `add_children_test.dart`** (the concurrently edited test-stage file) and
  none in mine;
* family suite at snapshot: **red only on the test stage’s in-flight
  `P05 chip tap area … the ≥44 tap area extends past the 32-px pill and stops
  there`** — their file, still being written; it asserts the same behaviour as
  P05-BUG-11 and fails, which corroborates the finding.

**Result: iteration-5/6 items verified fixed; 1 new major open (P05-BUG-11:
the chip’s overlaid 44 px hit area is clipped by the chip `Wrap`, so the
effective tap target is 44×32). VERDICT: FAIL.**

---

## P05-BUG-11 — MAJOR — the age-chip tap target is 32 px high, not 44: the overlaid hit area is clipped by the chip `Wrap`

**Where:** `app/lib/features/family/presentation/widgets/add_child_form_card.dart`
(chips inside `Wrap(spacing: 8, runSpacing: 8)`) + the shared
`app/lib/core/design_system/components/nest_chip.dart` `_ExpandedHitBox`.

**Repro / proof:** `[P05-BUG-11] the overlaid tap area above/below the chip
selects it` (skip: true). Measured at 390×844:

```
ageChip-4-6  rect 34,527 → 104,559  (44 × 32)
tap 5 px above the pill (inside the intended 44 px target)  → not selected
tap 5 px below the pill (inside the intended 44 px target)  → not selected
tap the pill centre                                          → selected ✓
```

**Mechanism.** `_ExpandedHitBox` accepts hits up to 6 px outside its own
32 px box, but Flutter hit testing stops at the first ancestor whose bounds do
not contain the point — here the `Wrap` run is exactly the 32 px pill, so the
overhang is never reached. The component’s own comment states it: *“Ancestors
that are themselves tight (e.g. a 32-high `Wrap` run) cannot forward hits
outside their own box … but roomy parents forward the full area.”* P05’s chip
row is precisely that tight `Wrap`, so the design’s `flex-wrap` chip row
cannot get the overlaid 44 px target.

**Impact.** SPACING_SPEC §10.6 (“base 32 high is below 44 → Flutter must wrap
in 44-min tap area”, “keep visual size”) is not met in the app’s actual chip
row: the target is 44 wide × 32 high. The P05 tap-target test was changed this
iteration from `atLeast44(chip)` to `width ≥ 44, height == 32`, so nothing in
the suite proves a 44-high target any more — the a11y guarantee is asserted
away rather than delivered.

**Suggested fix (owner/shared decision — no P05-local fix exists; probed):**
the hit region has to occupy layout somewhere, so either

1. accept 32-high chip targets as the design’s trade-off — then amend
   SPACING_SPEC §10.6 (chip rows are 32-high targets), delete this proof, and
   fix the tap-target test comment to match reality; or
2. reserve 44 px in the chip row (reverts the +12 px visual fix the UI gate
   fought for); or
3. a shared row-level component that owns a 44-high hit region without layout
   shift (custom hit routing at the form-card level — substantial, app-wide).

The shared batch-2 chip fix itself is correct for roomy parents; only the
`Wrap` case is clipped.

---

## Iteration-5/6 items — verified sound

| Check | Result |
|---|---|
| Child order (CHILD ORDER ruling, durable fix) | `AppDatabase.watchChildren` orders `createdAt, rowid`; `FamilyRepositoryImpl` delegates; demo + `onboarding_kids` both render **Maya left (30), Leo right (210)** |
| Two quick adds | `Zoe` then `Adam` → rows `[Zoe, Adam]`, Zoe left (same-second ties fall back to `rowid`) ✓ |
| `addChild` creation marker | writes explicit `createdAt: now()` + `createdAtTz`; v2→v3 migration adds the column with a 0 placeholder and backfills `now + rowid − min(rowid)` oldest-first (read and verified) |
| Chip row height (layout half) | 32.0 — design `.chip` height, +12 shift gone ✓ |
| Kid cards | 116.0, design rhythm ✓ |
| Same-frame double tap | one child inserted ✓ |
| Kid-mode guard | deep link → `/parental-gate` ✓ |
| Restart / Drift persistence | child persisted and rendered after relaunch ✓ |
| Data edges | 0/1/6 children, long names, 320×1.3 → no exceptions (existing tests; my 6-child probe needed a scroll, as the tests do) |
| Fonts / letter spacing | no `google_fonts`/`GoogleFonts` in `lib/features/family` or `test/features/family`; `NestType` letterSpacing defaults 0; P05 CSS sets no tracking ✓ |
| Copy / owner rules / dark | unchanged from the verified iteration-5 state ✓ |

## Notes

* The concurrent test stage has a test asserting the same tap-above behaviour
  (currently failing, plus two analyzer warnings in its file). It is their
  artifact; this report does not count it, but it independently reaches the
  same wall as P05-BUG-11.
* If the orchestrator chooses option 1 above, P05-BUG-11 becomes a documented
  exception rather than a bug and the skipped proof should be deleted with the
  spec amendment — the report says so explicitly so the decision is not
  half-applied.

VERDICT: FAIL
