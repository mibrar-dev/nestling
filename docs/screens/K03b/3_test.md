# 3 TEST — K03b Kid home all done (iteration 2)

Scope: `app/test/features/kid_home/` for K03b only (RULES §1). No screen
code touched by this stage; no simulator booted (stage 5 owns the one
allowed UDID); no `flutter clean`, no `pkill`, no `google_fonts`, no
`DateTime.now()` in the new tests (`appNowUtc()`/pinned clock only);
every pumped test ends with `disposeApp(tester)`; all runs use
`flutter test --timeout 120s`.

## Tests added (7)

`app/test/features/kid_home/k03b_all_done_view_test.dart`
(`_mixedApprovalItems`, :130; `_FakeRepo` gains an `items` override, :159;
`_FlappingRepo`, :209; new group `K03b iteration 2 pins`, :1583):

1. `a done quest needing no approval shows its +N coin chip` — ROW META
   third arm (orchestrator 04:52), the one arm the seeded DB cannot
   produce (every seeded quest needs approval). Fake repo serves 6 done
   quests with `q-tidy` approved + `needsApproval: false`: still
   `All done!` / `6 of 6 done`, exactly one `+15`, 2× `Mum said yes!`,
   3× `Waiting for Mum`, card semantics `Tidy your bedroom, Done`.
2. `the hero keeps the design 16 + 14 gaps (D1 structure)` — font-free
   pins for K03B-BUG-1/D1: hero `Stack` is `Clip.none`; stack top is
   bubble-bottom + 16 (`.scroll > * + *`); pet top is bubble-bottom + 30
   (16 + `.k3-pet` 14, the latter as `Padding(top: gap14)` inside the
   stack); confetti `Positioned(top: 4)` paints 4 below the stack top
   (the design's bubble + 20).
3. `the celebration nest is the design 226x226 slot (BUG-3)` — pins the
   all-done-local constants: `nestWidth/Height` 226, `fixedPipHeight`
   152, `slotHeight` 226, `pipBottom` 92 (the D1 feature-side correction
   that honours `slotHeight` without touching shared code), `PipAvatar`
   mood `happy`.
4. `Try again reloads into the celebration after a failure` — the error
   channel's retry was tap-action-tested but never recovery-tested.
   `_FlappingRepo` fails the first load on both streams, then serves the
   all-done shape: tap `Try again` → `All done!` + `6 of 6 done` +
   `Visit Pip`, no exception.
5. `Choose opens the K01 picker from the no-child channel` — the
   `Seed.empty` state offered `Choose` but never tapped it: now asserts
   it pushes `/who-is-playing`.

`app/test/features/kid_home/k03b_all_done_bloc_test.dart`
(`_withStatus` carries the flag, :72; truth table, :269/:303):

6. `needsApproval never changes the done count or the branch` — done-ness
   is the status alone (approved + no-approval still counts): 3 mixed
   items → `doneCount` 3, `allDone` true, `fraction` 1.
7. `a to-do quest breaks all-done even when it needs no approval` — the
   flag cannot celebrate a to-do quest: `doneCount` 1, `allDone` false.

`_withStatus` (:72) previously rebuilt the quest WITHOUT `needsApproval`
(test-helper-only flaw: it silently reset `false` to the `true` default).
Now carries `quest.needsApproval` through — zero behaviour change to the
existing tests (all use the default `true`).

Not added (covered elsewhere, verified by grep + green runs): light/dark
× 320/390/430 × scale 1.0/1.3 matrix, empty/loading/error/no-child
channels, every tap destination (`Visit Pip`→`/pip`, lock→`/parental-gate`,
card→`/quest-detail` with `questId+childId`), semantics labels
(`Grown-ups`, `120 coins`, `Hi Maya, all done!`, progress img label, pet
celebration label), non-control `hasAction(tap)==false`, ≥56 kid tap
targets, shapes (chip 32, bubble 260/`r18`/tail, CTA 64 lilac, card rects/
tints/12 px gap, progress 16), bottom-edge + 20 px gutters both themes,
shared kid background, PipAvatar own-Pip (Maya mochi/sunny/3, Leo
bolt/sky/2), copy character-for-character, PERIODS/BST boundaries,
restart persistence, double-tap latches (`k03b_all_done_view_test.dart`,
`k03b_all_done_bloc_test.dart`, `k03b_bugs_test.dart` clean probes).
`kid_home_bloc_test.dart` covers the whole-bloc events (load, complete,
profiles, selection, PIN); this stage's bloc file covers every
all-done-relevant path (load all-done/partial/empty, last-quest flip with
`justCompletedQuestId`, silent no-op, failed write with `actionNonce`,
mid-session stream error, load failure, hang). K03b has no interactive
chip row (`KidStatusChip` display-only; no `NestChip` in the view), so the
CHIP ROWS tap-above/below rule is N/A.

## Results (run in `app/`)

```
$ dart format test/features/kid_home/k03b_all_done_view_test.dart \
    test/features/kid_home/k03b_all_done_bloc_test.dart
Formatted 2 files (1 changed)

$ flutter analyze
Analyzing app...
No issues found!

$ flutter test --timeout 120s test/features/kid_home/k03b_all_done_bloc_test.dart \
    test/features/kid_home/k03b_all_done_view_test.dart
00:03 +83: All tests passed!                     # was 76 → +7 new, all green

$ flutter test --timeout 120s test/features/kid_home
00:18 +771 ~8: All tests passed!                 # K03 suites unmoved (K03 must not move)

$ flutter test --timeout 120s
02:31 +5016 ~16: All tests passed!               # full app suite green
```

## Bugs found

No NEW screen bugs. All 7 new tests passed on the first run; the full
plain suite is green.

Parked-proof re-check (`--run-skipped`, bugs-stage-owned file
`k03b_bugs_test.dart` — this stage did NOT edit it):

- K03B-BUG-1 (gap 30 + rows on design row), K03B-BUG-3 (226×226),
  K03B-BUG-5 (creation order), K03B-BUG-4 no-approval (`+15`): PASS on
  demand. BUG-4 approved-count and BUG-1/3/5 skips were concurrently
  being un-skipped/fixed by the bugs-stage worker during this stage
  (its card-specific `Mum said yes!` assertion matches this stage's
  finding that 3 such rows — not 1 — is the correct ROW META behaviour);
  the plain suite containing those fixes is green, so no action here.
- K03B-BUG-2 shared-unit form STILL FAILS on demand, as it must:
  `k03b_bugs_test.dart:209`
  (`K03B-BUG-2 (latent, shared): explicitGeometry adds _explicitBleed
  to slotHeight`) → `Expected: <226.0> / Actual: <257.4>`. Repro:
  `flutter test --timeout 120s --run-skipped --plain-name 'latent, shared'
  test/features/kid_home/k03b_bugs_test.dart`.
  Root cause (unchanged, see `6_bugs.md`): `PipNestFallback.explicitGeometry`
  (`app/lib/core/design_system/motion/pip_rive.dart`, ~line 677) recomputes
  `stageH` as `nestTop + nestH + _explicitBleed` instead of returning the
  `slotHeight` variable. This is pre-existing, lives in SHARED code this
  branch is forbidden to touch (ORCHESTRATOR_NOTES 04:52 D1), and is
  already recorded + dispositioned (`6_bugs.md`, `2_build.md`): the SCREEN
  half ships feature-side (`pipBottom: 92`, pinned by new test 3 above,
  widget form green in the plain suite). It needs an orchestrator
  SHARED_REQUEST if the unit contract must change — not a screen fix, and
  per stage rules this stage patches nothing.

Process note (not a finding): `k03b_bugs_test.dart`, `4_review.md` and
`docs/screens/K03b/ui/app_light_2.png` were being written by a concurrent
worker during this stage; this stage touched only the two `k03b_all_done_*`
test files plus this note (RULES §1), so nothing was clobbered. Final
`flutter test` above ran AFTER those edits landed and is green.

VERDICT: PASS
