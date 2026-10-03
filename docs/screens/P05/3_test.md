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

VERDICT: FAIL