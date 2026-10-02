# K03 Kid home — test notes (Stage 3, iteration 3)

Iteration 3 re-tests the fixed screen (period scoping, PipAvatar in the
empty/failure states, SafeArea bottom chrome, K03-BUG-8/9 latches) and
extends the suite for the PERIODS ruling and the new owner rules merged from
main. One real screen bug was found (the dock surface does not cover the OS
inset); the screen was NOT patched.

## Files

- `app/test/features/kid_home/kid_home_view_test.dart` — 36 → 44 tests.
- `app/test/features/kid_home/kid_home_bloc_test.dart` — 20 tests
  (unchanged this iteration; still green).
- `app/test/features/kid_home/k03_bugs_test.dart` — bug-hunt proofs
  (unchanged; all run green, 1 conditional skip = the shared motion flag).
- No `app/lib/**` change in this stage; nothing outside RULES §1 touched.

## New tests (this iteration, +8)

Periods (PERIODS ruling, DB-backed):
- daily: a completion one minute before the London day start reads `to do`
  again (0 done today, coin pill, no chip); moving it inside the day makes it
  count again (`1 done today`, `Done` chip);
- weekly: a completion one minute before the London week start (Mon 00:00)
  reads `to do`; moving it inside the week counts;
- once: a completion 400 days old still counts (`Done` chip);
- a period-expired daily quest starts a fresh completion on tap: the card
  flips to `Waiting for Mum`, K05 opens, and the DB holds exactly two rows —
  the old out-of-period `approved` row untouched plus a new `done_pending`.

Bottom edge / alignment (owner rules merged from main):
- the dock surface must reach the physical screen edge with a 34 px bottom
  inset (**FAILS** — K03-BUG-10);
- the dock top lifts by exactly the 34 px inset (passes);
- no mock home pill is rendered (`NestHomeIndicator` is 0×0, OS draws it);
- gutters align: header avatar, quest cards and dock buttons all start at the
  20 px side gutter.

Pip:
- an accessorised child (storybook/mint/scarf/stage 4) drives the full look
  mapping in the still frame, no v1 art.

## Results

- `dart format --set-exit-if-changed .` — clean.
- `flutter analyze` — `No issues found!`
- `flutter test` — `+467 ~1 -2`: 467 pass, 1 skip (shared motion-flag proof,
  see below), 2 fail — the light + dark proofs of K03-BUG-10.
- K03 alone: bloc 20/20; view 42/44.

## Bug found (screen NOT patched)

### K03-BUG-10 — the dock surface does not cover the OS bottom inset

**Severity: Major (owner rule, "UI checks must FAIL a screen that shows
one").**
Where: `app/lib/features/kid_home/presentation/views/kid_home_view.dart:471`
— `SafeArea(top: false)` wraps the dock `Container` (line 476), so the inset
padding lands *below* the surface container and the KidScope meadow/sky shows
through as a coloured strip under the bar.

Rule: `tools/screens/stages/common.md` BOTTOM EDGE (OWNER RULE, overrides the
designs): the area below any bottom bar down to the physical screen edge MUST
use the same surface colour as that bar; never a coloured strip under a bar
or around the home indicator, light or dark. This supersedes the second half
of `ORCHESTRATOR_NOTES.md` #8 (meadow to the edge), which came from the
design.

Repro:
`flutter test test/features/kid_home/kid_home_view_test.dart --plain-name
"the dock owns the OS bottom inset"` (both themes).
A 34 px system inset (`tester.view.padding = FakeViewPadding(bottom: 34*3)`)
is set; the dock surface's bottom edge is measured at **810** (844 − 34)
instead of 844, i.e. a 34 px meadow strip sits under the bar. Without an
inset the surface does reach the edge, so the bug only appears on a real
device.

Failing tests: `kid_home_view_test.dart:791` "light: the dock owns the OS
bottom inset" and its dark twin — `Expected: a numeric value within <0.5> of
<844>; Actual: <810.0>`.

Fix hint (feature-local): keep the SafeArea/dock geometry but paint the
surface through the inset — move the `SafeArea` inside the surface
`Container` (surface → `SafeArea` → padded content), or add the bottom inset
to the container's bottom padding, so the surface colour runs to the edge
while the buttons stay above the inset. The dock-top-lift assertion must keep
passing.

## Shared item (not a K03 screen bug)

**K03-BUG-7 (`DISABLE_ANIMATIONS=1`) is still open on this branch's main.**
`ORCHESTRATOR_NOTES.md` claims main fixed it; main's tip
(`5eea2ad`/`c83d4bd`) still has
`kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS')`, which
parses `"1"` as false, and `app.dart` only mirrors the flag into
`MediaQuery.disableAnimations` when it is true. Evidence:
`flutter test --dart-define=DISABLE_ANIMATIONS=1 --plain-name "K03-BUG-7"
test/features/kid_home/k03_bugs_test.dart` → `Expected: true; Actual:
<false>`. The proof stays conditionally skipped in the plain suite (by
design), so it is not a failing test here; fix belongs to `core/data` +
`app/` (SHARED_REQUEST #5). No K03 screen change can fix it.

## Verified green this iteration

- Pip mandate: pet slot (Maya mochi/sunny/none/stage 3 at 152), Leo
  (bolt/sky/stage 2), accessorised child, empty-quests state (child's own
  PipAvatar, 120), failure state (neutral mochi/sunny/stage 1) — no v1
  `pip_stage_*.svg` anywhere (iteration-2 bugs K03-BUG-7/8 are fixed).
- Periods: daily/weekly/once scoping rendered correctly and the fresh-row
  write path for a new period (K03-BUG-4 ruling holds on screen).
- Iteration-2 fixes still hold: celebration rides the flip, failed write
  never celebrates, retry works, double-tap guards (check + lock).
- Iterations 1–2 coverage still green: 12-cell light/dark × 320/390/430 ×
  scale 1.0/1.3 matrix, empty/loading/error states, every tap destination,
  semantics labels, kid tap targets ≥ 56.

## Notes / observations (not bugs)

1. The dock-top lift and surface-to-edge requirements are independent; only
   the surface coverage fails (K03-BUG-10).
2. `test/flutter_test_config.dart` pins `Seed.anchorOverride` to Sat 3 Oct
   2026 while the repo reads `DateTime.now()`; the period tests compute their
   boundaries from `londonDayStartUtc/londonWeekStartUtc(now)`, so they stay
   deterministic as long as the machine clock is in the same London week as
   the anchor (same coupling the bug suite documents).
3. Harness notes unchanged: direct Drift work inside a `testWidgets` body
   must use `tester.runAsync`; set bottom insets via `tester.view.padding`
   (physical px) before pumping; avoid `pumpAndSettle` while a loading
   spinner can be on screen.

VERDICT: FAIL
