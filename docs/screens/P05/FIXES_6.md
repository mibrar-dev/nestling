# Fix list after iteration 6

## From 3_test.md
# P05 · Add children — test notes (STAGE 3, iteration 6)

Route `/add-children`, feature `family`, parent mode. Changes are confined to
`app/test/features/family/` and these notes — no product code touched.

The suite is green (`+816 ~1` full, **+122 ~1** in `test/features/family/`,
zero failures, one documented skip), but this stage **found a real bug**:
the age-band chips expose a **32-px tap target** where parent mode requires
≥44 (P05-BUG-11). So: PASS is not available, and FAIL is the honest verdict.

## Tests added (3, in `add_children_test.dart`)

The shared batch-2 chip landed (`NestChip` = 32-px visual + a `_ExpandedHitBox`
that widens the hit test to 44×44), and the build stage correctly flipped my
iteration-5 expectations to 32. That left a **coverage hole**, which is what this
stage is about:

1. **`[P05-BUG-11] the vertical overlay is clipped by the chip Wrap`** — the new
   behaviour the batch introduced was previously only asserted as *layout*
   (32 px tall box), which proves nothing about the hit area. This test taps
   the pill (reachable), moves the selection away, then taps 3 px above the
   first chip: the point is inside the 44-px target by design and is **dropped**,
   because the `Wrap`'s own box is the 32-px run. Both assertions are written to
   flip to `isTrue` when the shared fix lands.
2. **The pill is the design size and selects on tap** — 32 px visual, selection
   stays single, and the inert "Age band" label strip above the block belongs
   to no control (a tap there changes nothing).
3. **No added letter spacing** — sweeps every `Text` on the loaded screen and
   fails if any style carries positive tracking, guarding the new ruling
   (`main fd92d95`: `NestType` defaults `letterSpacing: 0`; Material's
   positive tracking must not come back). P05 currently has none.

Also updated: a stale comment in `p05_bugs_test.dart` still credited the
removed `IntrinsicWidth` workaround for the chip fix — it now describes the
shared fix accurately.

## Results

```
dart format .        clean (373 files, 0 changed)
flutter analyze      No issues found!
flutter test         00:24 +816 ~1: All tests passed!
  test/features/family/   122 tests (+1 skipped), 0 failures
```

`flutter test --run-skipped test/features/family/p05_bugs_test.dart` executes
the skipped proof. Every app-pumping test ends with `disposeApp(tester)`.

## Bugs found

### P05-BUG-11 — age chips expose a 32-px tap target, not 44 (major, shared root cause)

The batch-2 chip keeps the design's 32-px visual and widens the hit test to
44×44 with `_ExpandedHitBox`. The **vertical** half of that never takes effect:
the chips sit in a `Wrap` whose box is exactly the run height, so Flutter stops
the hit test at the `Wrap` and the ±6 px overlay is dropped.

Measured (390 px, scale 1.0, first row of the age-chip block; pill
`34,527 → 104,559`):

| tap y | inside the 44-px target? | selects the chip |
|---|---|---|
| 520–526 (above the pill) | yes | **no** — clipped by the Wrap |
| 527–559 (the pill) | yes | yes |
| 564 (below the pill) | yes | **no** — clipped |

Repro (in `add_children_test.dart`, group *P05 chip tap area*):
tap `4–6`, tap `7–9`, then `tester.tapAt(Offset(pill.center.dx, pill.top - 3))`
→ `4–6` stays unselected. So all four age bands expose a 32-px-tall touch
target, against `SPACING_SPEC` §3/§10.6 (≥44 in parent mode) — precisely the
regression the shared fix was meant to avoid. The horizontal half does work
(the pill is 44-min wide by construction), and `_RenderExpandedHitBox`
documents the constraint itself: "ancestors that are themselves tight … cannot
forward hits outside their own box".

Not fixable in P05 (RULES §1): the tight ancestor is the `Wrap` in
`add_child_form_card.dart`, and every way to widen it (row padding, larger
`runSpacing`, a `Stack` with a taller box) puts 44 px back **in the flow** —
the 12-px drift batch 2 just removed. The fix has to come from the component
side; filed in `SHARED_REQUEST.md` with the measurement table and options.
Reported by the bugs stage as P05-BUG-11 first; my measurement adds the
per-pixel reachability table and the repro.

### Standing item reported explicitly: one skipped test

`p05_bugs_test.dart` carries `skip: true` on the P05-BUG-11 proof (placed by
the bugs stage, id in the test name, runnable with `--run-skipped`). It is the
proof for the bug above; it stays skipped until the shared fix lands, because
the "correct" assertion fails today. My own green characterisation test (1)
covers the same defect in the passing suite, so the behaviour is visible either
way.

## Rules audited this iteration

* **FONTS** — `google_fonts` is gone from `pubspec.yaml`; `app/lib` and
  `app/test` contain no `google_fonts` import and no `GoogleFonts.*` call, so
  there was nothing to delete in this feature's tests (verified by grep).
  `test_scope.dart` no longer carries the old `allowRuntimeFetching` line, and
  the whole suite builds without the package.
* **LETTER SPACING** — `NestType` now defaults `letterSpacing: 0`
  (`typography.dart:33,51`); P05 sets none, and test 3 now guards it.
* **CHILD ORDER / COPY / BOTTOM EDGE / ALIGNMENT / PIP** — unchanged and still
  pinned (Maya-first group incl. the rename proof; code-unit copy assertions;
  CTA-to-edge and 20-px gutters at every width in both themes; no Pip slot on
  this screen).


## From 6_bugs.md
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

