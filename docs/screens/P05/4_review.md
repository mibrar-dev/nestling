# P05 · Add children — QA code review (STAGE 4, iteration 7)

Scope reviewed: `git diff main...HEAD` scoped to P05-owned paths. The
iteration-7 checkpoint (`6ba0cb8`) overlies iteration 6's build with only
test-doc edits, so this pass re-verifies the iteration-6 build surface and
records the gates on this exact tree.

Reviewed against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P05, `docs/design/SPACING_SPEC.md`, the design
system as it is used here, and `docs/screens/P05/ORCHESTRATOR_NOTES.md`.

Gates re-run independently on this tree:

```
dart format --set-exit-if-changed .   → 382 files, 0 changed
flutter analyze                        → 1 info Lint (finding 1)
flutter test test/features/family     → 00:13 +128 ~1: All tests passed!
flutter test (full suite)              → 00:40 +990 ~1: All tests passed!
grep -c "skip:" test/features/family/*.dart → 0 in add_children_test.dart,
                                        1 in p05_bugs_test.dart (the
                                        mandated P05-BUG-11 proof)
git status                             → clean apart from the four
                                        docs/screens/P05/.brief_* stubs
```

**Result: 0 blocker, 0 major, 2 minor. The P05 product surface is unchanged
from the iteration-6 PASS (the durable `createdAt` sort via the shared
helper, the retired rowid interim with accurate comments, 116 px cards, the
inverted chip-geometry tests). Verification of the iteration-7 delta finds
no new product defect. VERDICT: PASS.**

---

## Findings

### 1. MINOR — `flutter analyze` emits one lint on the test stage's new (correct) overhang assertion

`app/test/features/family/add_children_test.dart:2224:7`

```
final overhang = (NestDevice.tapParent - NestSpacing.s8) / 2;
```

`prefer_const_declarations` fires because both operands are `const`-valued
(`NestDevice.tapParent = 44`, `NestSpacing.s8 = 32`). The earlier full-app
run was clean (`No issues found!`) for iteration 6; the iteration-7 test
additions introduced exactly this one.

Fix (one token): `const overhang = (NestDevice.tapParent - NestSpacing.s8) / 2;`
— once done the gate returns to zero issues.

### 2. MINOR — `flutter test` numbers in the stage notes predate this run

`docs/screens/P05/2_build.md` and `docs/screens/P05/3_test.md` were written
when the family suite read **122 passed ~1** and the full suite read
**672 passed**. The current branch — including the same files minus the
noted rewrites, plus my own two runs — reports `test/features/family`
**128 passed ~1** and the full suite **990 passed ~1**. The extra tests are
the ones this iteration added around the chip-overhang contract. The notes
are descriptive history, not a gate record; no product code is implicated.

Fix: one number in each note for the reader that comes after, matching the
fresh figures above.

### Carries over, corrected in favour of PASS but recorded for the file

* **P05-BUG-11 (open, shared).** The chip `Wrap`'s reachability does not
  carry the overlaid 44-px hit box: the skip proof in
  `p05_bugs_test.dart` stays skipped **with the inline reason referencing
  `shared/chip_wrap_hit_area (NestChipWrap)`** — as the 04:31 orchestrator
  decision mandates — and the live flip-to-`isTrue` proof in
  `add_children_test.dart` that flips when it lands is correct. Nothing
  done to it in this iteration changes that posture; from P05's side the
  shared dependency now exists in core (see "Shared state" below) and the
  loop will fold it on the next main merge.
* **Mid-save Continue, `onSaved` callback in the bloc, `child_display.dart`
  placement, `error.toString()` in the failure UI, 1 px pencil offsets** —
  unchanged positions, accepted with reasons on earlier reviews.

---

## Iteration-6 findings — closed this cycle

| # | Finding | State |
|---|---|---|
| a | `add_children_test.dart` in-flight test was a mirror contradiction of the bugs-stage skip | reconciled now that the iteration-7 test stage paired the skipped defect proof with a live, passing contract test; the live one documents the current (clipped) behaviour and is annotated to flip when `NestChipWrap` lands |
| b | skip reason for P05-BUG-11 did not name its shared branch inline | fixed in the iteration-7 `p05_bugs_test.dart` header — the skip comment literally annotates `shared/chip_wrap_hit_area (NestChipWrap)` |
| c | the `rowid` interim + the three-line archive comment | both retired in iteration 6 and not reintroduced; the repository calls the shared ordered query directly |

## What is owed from this branch, not counted against it

* **NestChipWrap adoption.** `main` reads `e572850` (chip wrap with the 44-px
  reach in tight rows), `f1915fe` merges it, `2333c35` gates the hit test to
  hit-slop, and `e3ae2b2` teaches stages to use it. In this worktree those
  four commits post-date the last main import (merge-base `d6423ee`, iteration
  6's sync) — i.e. they are not yet in `screen/P05`. That is the loop's
  expected "branch behind main" process item, not a P05 defect. Per the
  04:31 ruling, the moment main is merged into this build the age-chip `Wrap`
  becomes `NestChipWrap`, BUG-11's skip lifts, the overlay reach test flips
  to true, and the overhang test restores `atLeast44(chip)` in both axes.
  Until then the BUG-11 skip and the clipped-behaviour live test are the
  honest record.

## Confirmed clean (no action)

* **RULES §1 scope.** This iteration changes only test files and docs in
  P05's tree; the only modified source files are within `app/test/features/family/`
  and `docs/screens/P05/`. Nothing in `app/lib/core`, `app/lib/app`, another
  feature, or `app/test/app`. `analysis_options.yaml` untouched; zero `skip:`
  on `add_children_test.dart`, exactly one on the BUG-11 proof.
* **ARCHITECTURE.md.** One bloc per feature; one view per route;
  feature-private widgets only; repository interface unchanged; DI and routes
  untouched since the iteration-4 PASS.
* **State layer.** `FamilyRepositoryImpl` delegates ordering to the shared
  core `watchChildren` (createdAt, then rowid); the interim `CustomExpression`
  path is gone. No local reordering anywhere in P05 code, so the ruling holds
  regardless of which branch is synced.
* **Design-system usage.** No re-implemented component; colours from
  `context.nest`; sizes from `NestSpacing` / `NestDevice` / `NestAvatarSize`;
  type from `NestType` (with the whole-app grep for `google_fonts`/`GoogleFonts`
  and for stray `letterSpacing` calls across P05 files both still at zero).
* **Copy / typography.** U+2019 in the h1, U+2014 in the subtitle, U+2013 in
  the age-band labels and card ages; "Avatar colour" spelt UK, never "color";
  no mutating case of positive tracking anywhere on the screen; no Material
  tracking reintroduced.
* **Owner rules.** Bottom edge is `NestBottomCta` surface to the safety
  margin with a `SafeArea(top: false)` filling underneath; alignment is a
  single `padSide` column with the card edges = gutter = CTA edges.
* **Tests running clean.** `test/features/family/` passes `+128 ~1`; full
  suite passes `+990 ~1`; the two deleted-proof files are green as the other
  stage records both.

## For the next stages (not findings)

* Apply finding 1's one-token `const` to return `flutter analyze` to zero.
* Refresh the two gate-count numbers in `2_build.md`/`3_test.md` when they
  rewrite for iteration 8.
* When `main` is merged into this branch, take `NestChipWrap` in the form card,
  un-skip the BUG-11 proof, and restore the `atLeast44(chip)` both axes — per
  04:31 and the skipped proof's inline reason.

VERDICT: PASS