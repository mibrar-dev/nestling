# K07 · 3 TEST (iteration 1, second pass) — the `/pip-evolution` suite

Job: write and extend the K07 tests in `app/test/features/pip/`, run the gates,
and record any real bug the tests expose. **No product code was changed by this
stage** — RULES §1 lets a test stage touch `app/test/features/pip/**` and
`docs/screens/K07/**` only, and nothing here needed a screen fix. No simulator
was booted, installed on or driven: only `5_ui` may touch
`BC440E48-B3A3-43BC-971B-0EF5DB621874`. No `flutter clean`, no
`analysis_options` change, no `google_fonts`, no `DateTime.now()` in any test,
no parked-proof un-skipping (those belong to the fix commit).

This is the second test pass of iteration 1 in this worktree: the suite the
earlier pass left behind (repository contract, bloc interleavings, view states,
pixel geometry, a11y, copy parity, sparks rasterisation, and the parked bug
proofs) was verified rather than rewritten, and the gaps below were filled.

## Verdict summary

- **Tests added: 8**, in one new file. **Bugs found by this stage: none.**
- `flutter analyze` → **No issues found** in every file this stage owns (it was
  red on arrival: `4_review.md` finding 3), and the whole suite passes. One
  caveat, in **Gates** below: another stage's scratch probe
  (`zz_scratch_sparks_probe_test.dart`, not mine) is currently making
  `flutter analyze` and `dart format` red for the tree as a whole.
- **The screen is still not done, and this stage did not make it done.** Four
  bugs found by stages 4 and 6 are open in the tree as it stands; their parked
  proofs all still FAIL (evidence below). Two of them are major:
  `K07-BUG-1` (a pending evolution stream is rendered as the "Oh no! Pip got
  lost." card with a dead *Try again*, measured 5/5 cold opens) and
  `K07-BUG-SPARK-1` (every sparkle loses its top point, so the mandatory
  `ORCHESTRATOR_NOTES` D2 item — "the exact HTML 4-point path" — is not
  delivered). This stage's PASS means *its tests pass and it found nothing
  new*; it is not a statement that K07 is shippable.

## Files

| file | state | tests |
|---|---|---|
| `pip_evolution_data_test.dart` | **new** | 8 |
| `pip_evolution_bloc_test.dart` | 1 edit: the parked `K07-BUG-1` state proof now cascades, clearing `4_review.md` finding 3's `cascade_invocations` info | 20 (unchanged count) |

Everything else in `app/test/features/pip/` was left exactly as found. The
suite as a whole is **374 passing / 9 parked** in that directory.

## The new file — `pip_evolution_data_test.dart`

The suite's existing view tests prove the celebration agrees with **the demo
seed**. That is one lucky database: it cannot tell a data-driven screen from one
that happens to be right about Maya, and it says nothing about the three
orchestrator rulings that are easiest to break silently. This file changes the
rows and watches the screen follow.

### PERIODS — the milestone is LIFETIME (4 repository tests + 1 widget test)

`watchEvolution` counts every `done_pending` / `approved` completion, all time,
so the ruling that a quest counts only for its current period (daily → the
current London day, weekly → the current London week) deliberately does **not**
apply. Nothing in the suite proved that, and a future "fix" could apply
`countsForCurrentPeriod` here and stay green. Each test therefore proves its own
row is *outside* its period before asserting the screen counts it, so the
assertion cannot pass vacuously:

| test | row | non-vacuity check | expected |
|---|---|---|---|
| a daily quest approved YESTERDAY still counts | `q-reading`, `approved`, Fri 2 Oct | `countsForCurrentPeriod('daily', …) == false` | 4 → 5 |
| a weekly quest approved LAST WEEK still counts | `q-veggies` (a weekly quest inserted for the case — Maya's two seeded weekly quests are already done), `approved`, Fri 25 Sep | `countsForCurrentPeriod('weekly', …) == false` | 4 → 5 |
| a daily quest approved LAST MONTH still counts | `q-tidy`, `approved`, 12 Aug | `countsForCurrentPeriod('daily', …) == false` | 4 → 5 |
| a `done_pending` row from last month counts too | `q-washing`, 12 Aug | — (awaiting a grown-up still helped) | 4 → 5 |
| the screen counts a month-old completion and shows the singular sub | one row only, 12 Aug | — | `Because you helped 1 time`, stat `1`, and **no** `… times` anywhere |

`london_time.dart`'s `countsForCurrentPeriod` is called from the test, so the
ruling's own helper is the oracle; `appNowUtc()` supplies "now" (the pinned
Sat 3 Oct 2026 08:41Z — no wall clock is read anywhere in the file). The
`1 time` singular form was previously only proven as a copy-helper string; it is
now reachable from the database alone.

### DATA OVER MOCKS + ORCHESTRATOR PIP — the active child's own Pip (3 widget tests)

- **Leo, not Maya.** `app_state.active_child_id = leo`, then pump
  `/pip-evolution`: `Pip grew into a Hatchling!`,
  `Because you helped 2 times`, `Hello! Pip is out of the egg!`,
  `Meet Hatchling Pip`, stats `2` / `60` / `2` (looked up
  per card, because Leo legitimately shows the same number in two cards), the
  image label `Leo's Pip, a hatchling`, and **both** stage slots rendering
  `PipStyle.bolt` / `PipSkin.sky` at stages `[1, 2]`. `Fledgling` appears
  nowhere. Before this file the ORCHESTRATOR PIP rule was only ever proven
  against Maya's Mochi, which a hard-coded `PipStyle.mochi` would also satisfy.
- **Live child switch.** With Maya on screen, the active child is switched to
  Leo and the screen re-renders `Hatchling` copy, `60` coins and Bolt Pips
  **without any interaction** and without leaving the route
  (`currentPath == '/pip-evolution'`). This is the `switchMap` on
  `watchAppState()` reaching the widget tree.
- **Accessory.** `pip_accessory = 'scarf'` on the child row (what the K06
  wardrobe writes) must reach **both** slots as `PipAccessory.scarf` while the
  milestone numbers stay `4` / `175` / `3` — the look comes from the row, and it
  cannot disturb the counts.

## Coverage against this stage's brief

| required | where it is pinned |
|---|---|
| bloc_test for every event/state path | `pip_evolution_bloc_test.dart` (20: every `PipState` helper, both stream-failure shapes, retry-after-error, double-load guard, `close()`, `Seed.demo` end-to-end), plus `pip_bloc_test.dart` / `pip_bloc_actions_test.dart` for K06's paths on the shared bloc |
| light + dark | `pip_evolution_view_test.dart`, `pip_evolution_widget_test.dart`, `pip_evolution_a11y_test.dart`, `pip_evolution_copy_test.dart` — every state and both bottom-edge decoration colours |
| widths 320 / 390 / 430 | `pip_evolution_widget_test.dart` fit matrix (`{320, 390, 430} × {light, dark} × text scale {1.0, 1.3}`, each asserting no overflow, all five content rows, the 20 px gutters and a working CTA) |
| text scale 1.0 and 1.3 | same matrix, plus the a11y file's 320 px / 1.3 target check |
| empty / loading / error states | `pip_evolution_view_test.dart` (`loading` group with a gated repository, `load failure` with a flaky repository, `Seed.empty` no-child card, and the nest-healthy/evolution-failing case) |
| every tap navigates to the right route | CTA → `/pip`, lock → `/parental-gate` (pushed), *Try again* → a real reload, *Choose* → `/who-is-playing`; each asserted through the **pointer** and through `performAction(SemanticsAction.tap)` |
| semantics labels on icon buttons | `pip_evolution_a11y_test.dart` — the lock speaks the design's `aria-label` `Grown-ups`, the whole semantics tree is swept so "exactly these labelled buttons are tappable" is the assertion, and every non-control is proven to advertise no tap |
| tap targets ≥ 44 parent / ≥ 56 kid | `pip_evolution_a11y_test.dart` uses the **kid** bound (`NestDevice.tapKid` = 56) for lock / CTA / retry / choose, at 390 px and at 320 px with text scale 1.3; the CTA's painted card (64 + the 6 px `--sh-kid` room) is asserted too |
| in-memory Drift with `Seed.demo` / `Seed.empty` | `test_scope.dart`'s `setUpTestScope` in every file; the no-child path re-seeds `Seed.empty` |

## Bugs found

**None new.** The eight tests above are green against the current screen, and
writing them surfaced no defect in `app/lib/features/pip/**`.

### The four open bugs are still open (re-confirmed here, not re-reported)

These belong to `4_review.md` / `6_bugs.md` and to stage 6's `k07_bugs_test.dart`
("iteration 2"). Nothing in this stage fixed or worsened them; the point of
re-running them is that the fixes cannot land as "delete the parked test".

```
$ flutter test --timeout 120s --run-skipped \
    test/features/pip/k07_bugs_test.dart \
    test/features/pip/k07_sparkles_bug_test.dart \
    test/features/pip/pip_evolution_bloc_test.dart
00:02 +29 -8: Some tests failed.
```

| id | severity | still fails, measured today |
|---|---|---|
| **K07-BUG-1** | **MAJOR** | a *pending* evolution stream renders `Oh no! Pip got lost.` (`Found 1 widget with text "Oh no! Pip got lost."` where the spinner is required); the real-repository proof is **5 of 5** cold opens (`Expected: <0> Actual: <5>`); the state-level proof in `pip_evolution_bloc_test.dart` still sees `PipStatus.loaded` where `loading` is required |
| **K07-BUG-SPARK-1** | **MAJOR** | the painted sparkle has **no top tip** (`Expected: <6> Actual: <0>` rows carrying ink at the design's y 28..33; the symmetry proof `Expected: >= <10> Actual: <0>`). The third proof — the one that pins Flutter's `Path.addPolygon` semantics rather than the screen — still PASSES, so the trap stays documented after the fix |
| K07-BUG-2 | minor | at 320 px the grown 240 px Pip still covers the arrow (`Expected: >= <-2.0> Actual: <-72.0>`) |
| K07-BUG-3 | minor | `quests done` still counts completion ROWS (`Expected: '4' Actual: '5'` after q-bins is completed twice) |

### K07-BUG-SPARK-1 — file:line + repro (carried forward, still accurate)

`app/lib/features/pip/presentation/widgets/pip_evolution_sparks.dart:168-179`
(`_SparksPainter._sparkPath`, consumed at `:152`):

```dart
return Path()
  ..moveTo(numbers[0], numbers[1])          // the design's `M` point
  ..addPolygon(<Offset>[ /* the REMAINING pairs */ ], true);
```

`Path.addPolygon` starts its own contour and, when the last block is already a
`moveTo`, **overwrites** it — so the design's first vertex is dropped and the
polygon has seven vertices with a flat top instead of eight with a point. The
design's bbox is `(13, 30) – (51, 68)`; what the screen paints is
`(13, 44) – (51, 68)`.

```
cd app && flutter test --timeout 120s --run-skipped \
    test/features/pip/k07_sparkles_bug_test.dart
```

Fix shape (screen-local, RULES §1-legal — drop the separate `moveTo` and let
`addPolygon` take the `M` pair as its first point), and `ORCHESTRATOR_NOTES`
(19:10) D2 already rules it mandatory: *"sparkles: fix as the UI check says (the
exact HTML 4-point path at the 4 spots, token fills, ink 3 px stroke)"*.

## Observations (documented, not findings)

1. **A Drift write to `children` from inside a live `tester.runAsync` wedges
   this project's test scope.** The first draft of the accessory test pumped
   the app, then wrote `pip_accessory` inside `tester.runAsync`. The file hung:
   `--timeout 30s` produced no timeout error, the run had to be killed after
   3 min, and `flutter test` finally reported the case as "did not complete".
   The same shape with a write to `app_state` (the child switch) and to
   `quest_completions` (stage 6's `K07-BUG-3` proof) completes normally, so it
   is not "any post-pump write" — it is specific enough to be worth knowing.
   **Not a product bug**: no app code path performs that write, and the screen
   renders the row correctly. Worked around by making the accessory write a
   *pre-pump* setup step (which is also the order K02's tests use); the
   `app_state` write in the child-switch test stays post-pump, because that
   shape completes normally. If a future test needs a live child-row change,
   expect this trap.
2. **The new milestone tests are deliberately agnostic to K07-BUG-3.** Every row
   they insert belongs to a quest the child has **never** completed (`q-reading`,
   a fresh weekly `q-veggies`, `q-tidy`, `q-washing`), so the count is the same
   whether a milestone counts completion rows (today's behaviour) or distinct
   quests (K07-BUG-3's expected fix). Had they re-used `q-dishwasher` / `q-bins`
   / `q-table` — the obvious choice — they would have encoded the open bug as
   correct and would have had to be rewritten by whoever fixes it.
3. **Carried forward from this iteration's earlier pass** (both are pinned in
   the suite, not just noted): the design's inline `#3D7FF0` sparkle dot is not
   a token (`tokens.css` defines `--sky: #2563D6`), so the screen paints
   `tokens.sky` and `pip_evolution_sparks_test.dart` pins that deviation in both
   directions; and every shared control (`NestKidButton`, `NestLockButton`)
   exposes an extra **unlabelled** tap node inside its labelled parent — a
   design-system characteristic measured identically on `/pip` and `/today`, so
   `tappableLabels` counts button-flagged nodes only.
4. **The parked-proof count moved 7 → 9 while this stage ran** (stage 6's
   iteration-2 `K07-BUG-3` added two parked proofs and three passing controls
   to `k07_bugs_test.dart`). A process item, not a finding; the quoted totals are
   from the tree as it stands now.
5. **A scratch probe from another stage is in the directory, and it is what
   makes the tree's analyze/format red.**
   `app/test/features/pip/zz_scratch_sparks_probe_test.dart` appeared at 21:34
   while this stage ran. It is not mine, it passes on its own
   (`+1: All tests passed!`), and it was left untouched — same as the earlier
   pass's note about the probes that came and went. The "374 passing / 9 parked"
   figure above was measured before it arrived; the gate is green either way.

## Gates

No simulator; `--timeout 120s` on every run. **Read block 3 first**: the tree's
`flutter analyze` / `dart format` are red, entirely inside one scratch file that
belongs to another stage and is not part of K07.

```
# 1. On arrival: the two infos `4_review.md` finding 3 recorded, both in a file
#    this stage is allowed to edit — RESOLVED here.
$ flutter analyze
Analyzing app...
No issues found! (ran in 3.4s)

$ dart format --output=none --set-exit-if-changed .
Formatted 611 files (0 changed) in 2.37 seconds.

# 2. With the whole suite
$ flutter test --timeout 120s test/features/pip/
00:11 +374 ~9: All other tests passed!      # 9 skipped = the parked proofs

$ flutter test --timeout 120s test/features/pip/pip_evolution_data_test.dart
00:02 +8: All tests passed!

$ flutter test --timeout 120s            # the whole app, every feature
01:38 +4003 ~13: All tests passed!       # 13 skipped = parked proofs repo-wide

$ flutter test --timeout 120s --run-skipped \
    test/features/pip/k07_bugs_test.dart \
    test/features/pip/k07_sparkles_bug_test.dart \
    test/features/pip/pip_evolution_bloc_test.dart
00:02 +29 -8: Some tests failed.          # EXPECTED: the four open bugs

# 3. LATER, after another stage dropped its scratch probe into the directory
$ flutter analyze
warning • Unused import: 'dart:typed_data' … zz_scratch_sparks_probe_test.dart:3:8
… 7 diagnostics in that ONE file …
7 issues found.

$ flutter analyze | grep '•' | grep -v zz_scratch_sparks_probe_test | wc -l
0
```

So **every file in the repo analyses clean except
`app/test/features/pip/zz_scratch_sparks_probe_test.dart`**, another stage's
in-flight scratch probe (7 diagnostics; `dart format` also wants to reformat
it). It is not mine — I did not create, edit or delete it (its own mtime, 21:34,
falls inside this stage's run, and it contains nothing of this stage's) — and a
stage's probe file is exactly the kind of in-flight work the loop owns. It
passes (`+1: All tests passed!`), so the suite is green either way; whoever was
writing it should delete it, as the earlier probes (`k07_probe_test.dart`,
`zz_stream_order_probe_test.dart`) were deleted after use. **This is not a K07
defect and not a blocker for the screen**, but `flutter analyze` is red for
whoever runs the next gate until that file goes.

The two infos `4_review.md` finding 3 recorded on arrival
(`cascade_invocations` at `pip_evolution_bloc_test.dart:391` and the ignore
comment that no longer applied at `:404`) are resolved; the file now analyses
clean.

VERDICT: PASS