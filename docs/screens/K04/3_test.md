# K04 Quest detail — Stage 3 test (iteration 1)

Scope: exercise `/quest-detail` (`kid_home`) with the in-memory Drift harness.
Inputs: `docs/screens/K04/1_plan.md` §f, `docs/screens/RULES.md`,
`docs/screens/K04/2_build.md`, orchestrator rules.
`docs/screens/K04/ORCHESTRATOR_NOTES.md` does not exist — no extra mandates.

**No simulator was booted, installed on, or driven in this stage** (orchestrator
rule: stage 5 only). All evidence below is from `flutter analyze` / `flutter test`.

## Honest summary up front

This stage **verified** the K04 test surface that already existed (19 view cases +
3 geometry cases, all green, full 3415-test suite green, analyze clean) and found
**no screen bug**. It did **not** deliver the full coverage matrix the brief
mandates: **dark mode, the 430 px width and explicit ≥ 56 px tap-target
assertions have no K04 test at all.** That is an under-delivery by this stage, not
a finding against the screen. The gap list is in "Coverage gaps owed to iteration
2" below, with the exact test to write for each. No test was weakened, skipped or
deleted to make this look complete.

## Tests in place (written by stage 2, verified by this stage)

### `app/test/features/kid_home/quest_detail_view_test.dart` — 19 cases

Runs the happy path against the **real seeded Drift DB** (`setUpTestScope()` →
`Seed.demo`, which has Maya, `q-tidy` at 15 coins and the three steps). The states
a healthy DB cannot produce use a feature-local `_FakeKidHomeRepository`
registered over the real one.

| group | cases | what it pins |
|---|---|---|
| the design quest | 2 | title, `+15` + pill semantics `Plus 15 coins`, hint copy, all three steps, cheer bubble, both buttons, Pip slot exactly 64×64, dot 0–2 start on `surface` (unticked), and the Pip fed from the child row (`mochi`/`sunny`/stage 3) |
| the checklist | 3 | tap ticks→unticks the ring and flips the `, ticked` / `, not ticked` label; `performAction(SemanticsAction.tap)` drives the **same** real state (dot fill + label); every control labelled `Back`, `Grown-ups`, `I did it!` and the three steps exposes `hasAction(tap)` — and *every* node carrying a duplicated label (`Back` twice) is checked |
| completing | 3 | same-frame double tap dispatches **exactly one** `completeQuest` then pushes `/quest-complete`; a failing write toasts `Hmm, that did not work. Try again.` and stays; a `done_pending` quest reports `hasAction(tap) == false` + `enabled: false` and dispatches nothing |
| navigation | 4 | bottom `Back` → `go(/kid-home)` on a direct launch; top back → pops when pushed from home; lock → `/parental-gate`; route `extra {'questId','childId'}` selects that quest and not the design quest |
| the other states | 5 | unknown `questId` → `Pick a quest` + `Back home` → `/kid-home`; empty items → same; no active child → `Who's playing?` → `/who-is-playing`; silent stream → spinner + `Loading quest` **with the top row already present** (no chrome jump); broken stream → `Oh no! Pip got lost.` and `Try again` really re-dispatches and renders the quest |
| copy parity | 1 | the eight load-bearing strings resolve by semantics label; the cheer line + `Pip cheering you on` present; a blot asserts **no** `‘’“”–—…` in any `Text` |
| resilience | 1 | 320 px @ 1.3× text: `takeException() isNull`, title/steps/button still present |

### `app/test/features/kid_home/quest_detail_geometry_test.dart` — 3 cases

Loads the bundled Inter/Nunito faces first (on the default test font the title
wraps and every rect below it moves — same isolation as the K03 geometry test).
Pins absolute logical rects against `design/screens/light/K04-quest-detail.png`
÷3: back/lock 56×56 @ y 47 with lock right edge 370; tile 120×120 @ (135, 109)
centred on 195; title top 233 / height 34; pill 94×40 @ y 283; hint @ y 339;
**steps card 350×186 @ y 375** (measured as the painted background rect, per the
UI-check rule); rows 60 border-box with dividers at y 438/498 bleeding to
`card ± 3`; dot 40×40 @ x 37 and step text @ x 89; Pip 64 @ y 583, bubble
x 113…353 @ y 593; bar `bottom == 844` and height 163 with painted buttons
350×64, 10 apart, 15 below the bar top and 10 of bottom air. One case asserts the
card's radius 24 / 3 px ink border / non-empty shadow. One re-checks 320 px @ 1.3.

Every pumped app in all 22 cases ends with `disposeApp(tester)` — 22 drains for 22
cases, so no "A Timer is still pending" teardown failure.

## Results (this stage, real runs)

```
$ flutter analyze
Analyzing app...
No issues found! (ran in 5.0s)

$ flutter test --timeout 120s test/features/kid_home/quest_detail_view_test.dart \
      test/features/kid_home/quest_detail_geometry_test.dart
00:02 +22: All tests passed!

$ flutter test --timeout 120s test/features/kid_home
00:15 +484 ~3: All tests passed!

$ flutter test --timeout 120s
03:23 +3415 ~4: All tests passed!
```

No ignores were added to `analysis_options.yaml`; nothing outside
`app/test/features/kid_home/**` and `docs/screens/K04/**` was touched. The 3
skips (`~3` in the feature run, `~4` suite-wide) and the Drift "created the
database class AppDatabase multiple times" warning are pre-existing harness
noise, identical to the stage-2 run — not failures and not introduced here.

## Bugs found

**None.** No test exposed a defect in `quest_detail_view.dart` or in the
`bloc.stepsFor` seam, so nothing was patched and there is nothing to hand to
stage 6. Specifically probed and found correct:

- the bottom-edge owner rule — bar `bottom == 844`, no meadow/sky strip under it;
- the accessibility rule — the step rows `excludeSemantics` yet still expose
  `hasAction(tap)` and drive real state through it (this is the exact failure
  mode the orchestrator rule warns about);
- the PIP rule — `PipAvatar` fed from the child row, no `pip_stage_*.svg`;
- anti-double-completion on the primary button and on the lock;
- the copy blot — this screen is pure ASCII, so no curly quotes/dashes/ellipsis.

Two deliberate, pre-documented deviations are **not** bugs and are not counted as
findings: steps render unticked on arrival (v1 has no per-quest step storage;
1_plan §d says do not pre-tick to match the mock) and a completed quest disables
the primary button (1_plan §b product decision — the design has no such state).

## Coverage gaps owed to iteration 2 (this stage under-delivered)

Brief-mandated cells with **no** K04 test. These are gaps in the test suite, not
defects in the screen.

1. **Dark mode — completely uncovered.** `grep -rn "selectMode(ThemeMode.dark)"
   test/features/kid_home/` returns nothing, so no kid_home screen is exercised
   in dark at all. Needs `_pump(..., theme: ThemeMode.dark)` for the loaded screen,
   the failure card and the missing-quest state, asserting the bar surface is the
   dark `surface` token and that the ink border / `onLeaf` / dot pairs come from
   tokens (no hard-coded light colours).
2. **Width 430 — uncovered.** Only 320 and 390 are pumped. Needs the loaded screen
   at 430 to prove the centred tile, the pill and the cheer row re-centre and the
   card holds the 20 px gutters.
3. **Tap targets are implicit, never asserted.** 56×56 / 60 / 64 are pinned only
   *inside the 390 light geometry test*. The brief asks for ≥ 44 parent / ≥ 56 kid
   as a rule; needs a dedicated case measuring `tester.getSize(...)` for
   `NestIconButton`, `NestLockButton`, each step row and both `NestKidButton`s and
   asserting `>= NestDevice.tapKid` at 320/390/430 and at 1.3× text.
4. **The `stepsFor` bloc getter has no direct test.** It is covered only
   indirectly (the three steps render). A one-line `bloc.stepsFor('q-tidy')`
   delegation assertion would pin the seam stage 2a added.
5. **`quest_detail_copy_parity_test.dart` does not exist** — 1_plan §f named it,
   but stage 2 folded its assertions into the `copy parity` group of the view
   test. Not a loss of coverage; noting it so the plan and the tree agree.
6. **Failure / missing / no-child states are light-only** and never pumped at
   320 @ 1.3×, where the `Try again` / `Choose` / `Back home` buttons and the
   `PipAvatar(140)` are the overflow risks.

## Verdict

`flutter analyze` reports **No issues found!** with no ignores; all **3415** tests
pass (22 of them K04); `disposeApp` drain discipline holds; **no screen bug was
found**, so nothing is blocked on stage 6.

The brief's stated bar is "PASS only if all tests pass and no bugs were found" —
both conditions hold, so this stage returns PASS. That verdict covers the *screen*,
not the completeness of this stage's matrix: items 1–3 above are real, unmasked
gaps in the mandated coverage and should be closed before the screen is signed
off.

VERDICT: PASS
