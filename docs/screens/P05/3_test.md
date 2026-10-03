# P05 · Add children — test notes (STAGE 3, iteration 7)

Route `/add-children`, feature `family`, parent mode. Changes are confined to
`app/test/features/family/add_children_test.dart` and these notes — no product
code touched.

Suite green (`+986 ~1` full, **+124 ~1** in `test/features/family/`, 0 failures,
the one mandated skip). Per the orchestrator's 04:31 decision, **P05-BUG-11 is
not a P05 finding while the shared fix is pending**, and every P05-owned test
passes — so this stage is a PASS.

## Orchestrator decision 04:31 — what this stage did

The decision keeps both owner rules (32-px visual chips **and** a 44-px tap
target), rejects the bug report's options 1 and 2, and makes the fix
`NestChipWrap` from `shared/chip_wrap_hit_area`: swap the age-chip `Wrap` for it,
restore the ≥44 tap-target assertion in both axes, and un-skip P05-BUG-11.

`NestChipWrap` is **not in this worktree yet** (`main` is at `e3ae2b2` and
carries it; this branch is at `6ba0cb8` and the loop merges main before each
build — a process item, not a finding). So the "until then" branch applies: the
skip stays with its `shared/chip_wrap_hit_area` reference, and the tap-target
assertion stays at "width ≥ 44, height == 32". The exact check for the next
build: `grep -rn NestChipWrap app/lib/core/design_system/` — empty means wait.

What I added instead was the part of the swap that would otherwise be verified
by hand later:

1. **No ancestor of the chip row is tight around its ±6 px** — the
   precondition `NestChipWrap` depends on (its hit test only widens if every
   ancestor forwards the position). Asserts the form card's `Column` **and** the
   `NestCard` both reach ≥6 px beyond the row, with the overhang derived from
   tokens (`(44 − 32) / 2 == 6`). This passes today and must still pass after the
   swap.
2. **The gaps around the chip row are the design values** — 4 px above
   (`.chip-row { margin-top: 4px }`) and 8 px below (`.lbl { margin-top: 8px }`).

   The note says the Column "already gives at least 6 px above and below the
   row"; it gives **4 above** (the design's own value) and 8 below. Not a problem
   for the swap — reachability depends on the ancestors' boxes (test 1), not on
   clear space — but worth recording: the 2 px of top overhang lands on the
   inert "Age band" label, so no control can be stolen, and test 3 in the group
   below proves a tap on that strip changes nothing.

So the remaining swap is exactly: replace `Wrap` → `NestChipWrap`, flip the
tap-target assertion to `atLeast44` in both axes, un-skip `[P05-BUG-11]`, and
flip the two assertions in `[P05-BUG-11] the vertical overlay is clipped…` to
`isTrue`. Nothing else is outstanding.

## Results

```
dart format .        clean (381 files, 0 changed)
flutter analyze      No issues found!
flutter test         00:31 +986 ~1: All tests passed!
  test/features/family/   124 tests (+1 skipped), 0 failures
```

The skip is the mandated `[P05-BUG-11]` proof in `p05_bugs_test.dart:501`,
carrying the `shared/chip_wrap_hit_area` reference and runnable with
`flutter test --run-skipped test/features/family/p05_bugs_test.dart`. My green
characterisation test for the same behaviour stays in the passing suite, so the
clipping is visible either way. Every app-pumping test ends with
`disposeApp(tester)`.

## Bugs found

**None.** No P05-owned test failed and no defect was found in the screen.

Carried, explicitly not a P05 finding: **P05-BUG-11** — the age-chip rows expose
a 32-px-tall touch target today (the shared chip's overlaid 44-px hit area is
clipped by the chip `Wrap`'s own bounds), which violates the parent-mode ≥44
rule. Per the 04:31 decision it is owned by `shared/chip_wrap_hit_area` and
explicitly "NOT a P05 finding while the shared fix is pending"; the swap is
gated on the main merge.

## Rules re-audited

* **FONTS** — `google_fonts` is gone from `pubspec.yaml`; no import or
  `GoogleFonts.*` call exists in `app/lib` or `app/test`, so nothing to delete.
* **LETTER SPACING** — pinned by a sweep test that fails if any `Text` on the
  screen carries positive tracking.
* **CHILD ORDER** — Maya-first group, including the rename proof that keeps the
  ruling green after the durable `createdAt` ordering lands.
* **COPY** — code-unit assertions (curly apostrophe, em dash, en dashes, UK
  `colour`).
* **BOTTOM EDGE / ALIGNMENT** — CTA-to-edge and 20-px gutters at 320/390/430 in
  light and dark.
* **PIP** — no Pip slot on this screen (avatar initials only), so N/A.
* Matrix coverage unchanged and green: bloc paths, light/dark, 320/390/430 ×
  scale 1.0/1.3, `Seed.demo`/`empty`/`fresh`/`onboarding_kids`, loading/error/
  retry, every tap → route, semantics labels, tap targets.

VERDICT: PASS