# Fix list after iteration 4

## From 2_build.md
# P09 — stage 2 · INTEGRATE (iteration 4)

A **FIXES_3** round: 2a (logic) and 2b (UI) split the loop's
`test=FAIL / review=FAIL / ui=FAIL / bugs=FAIL` findings and fixed them in
parallel. Their halves met on the same contract and needed **no** integration
repair from me — but the **whole-app gate is red on one shared core test**
that no screen agent may fix, so this stage is a FAIL on the evidence, not on
the work (§4, §5).

## 1. What 2a handed over (logic half)

One behaviour change at the bloc boundary:

- **`QuestsBloc.saveFailedMessage`** (`'Could not save the quest. Try
  again.'`) — all three editor handlers now emit
  `editorError: _editorError(error)`; an `ArgumentError` (only the coins-range
  guard, unreachable from the clamped editor) maps to the parent-safe copy with
  the technical detail going to `dart:developer log(name: 'quests')`, and every
  other failure (offline, disk full) still surfaces the repository message, so
  the states suite's toast pins stay untouched.
- `quests_repository.dart` doc correction (finding 8): the create/update
  contract now promises `AssertionError` in debug / `ArgumentError` in release
  — the behaviour already did; only the comment lied.
- Docs in this screen's own dir: `SHARED_REQUEST.md` §2/§4/§5/§6 retitled
  `— RESOLVED on main (shared/shared_batch5)`, and the stale
  `FIXES_2.md:77` `NestIcons.basket` pointer corrected.
- Feature scope: 384 pass, `~7` skips (the BUG-P09-6/7/8 proofs 2b then
  un-skipped, plus P12-BUG-05 elsewhere).

## 2. What 2b handed over (UI half)

Every P09-local item from `FIXES_3.md` plus the mandatory 20:09 switch:

- **BUG-P09-9 + review 2** — both stale batch-5 compensations deleted: the
  approval card's bottom padding is back to `NestSpacing.s4` (16) and the
  `Transform.translate(toggleTrackOffset)` is gone (the constant itself is
  deleted; only doc references remain). The card renders 72 again and the
  51×31 track lands on the design rect 303 / 620.5 / 51 / 31.
- **BUG-P09-10** — the toggle is no longer a child of the 40-high approval row:
  the card padding moved into a `Stack` and the toggle is a
  `Positioned(top: 20.5, right: s4)` sibling of the padded row, so every
  ancestor render box is at least as tall as the 59×44 hit slop and taps 5 px
  above/below the track land on it.
- **BUG-P09-11** — the first step in the direction of the valid band jumps to
  the boundary (`−` from 9999 → 100), so repairing a corrupt stored value is
  one tap instead of 9899; Save stays blocked until it is in range.
- **BUG-P09-12 + review 3** — the picker runs on the batch-5 design paths
  `NestIcons.questBed / questDishes / questHoover / questBins` in the design's
  order (Bed, Dishes, Hoover, Book, Bins, Paw), stored `quests.icon` keys
  untouched.
- Seven more proofs un-skipped (BUG-P09-9 ×2, -10 ×3, -11, -12); the
  BUG-P09-4 stepper test rewritten around the new jump brace (the only assertion
  change, forced by BUG-P09-11).
- Feature scope: **394 pass, 0 skipped**.

## 3. Mandatory orchestrator items — done

**20:09** ("Integrator: switch the icon picker to `NestIcons.questBed /
questDishes / questHoover / questBins` (in the design order) and delete the
`toggleTrackOffset` Transform.translate, as in `shared_batch5_REPORT.md`
~87-90 / ~209") — 2b landed both and I verified them in the tree:

- `_questIcons` → `NestIcons.questBed` (line 301), `questDishes` (307),
  `questHoover` (313), `NestIcons.book` (315, byte-identical per the report),
  `questBins` (320), `NestIcons.paw` (322) — the report's mapping, design order;
- `toggleTrackOffset` no longer exists as a constant and no `Transform` wraps
  the toggle; the only remaining mentions are two explanatory doc comments.

`shared/shared_batch5` itself reached this tree in the loop's merge (`3f1b045`,
confirmed by `git merge-base --is-ancestor 9bbf65a HEAD`), so iteration 3's
four follow-ups are closed, not deferred. Batch-5 also closed 17:57 item 2
(`NestTextField` 12 px content padding) — `SHARED_REQUEST.md` §6 records the
measured text x 38.3 vs 37.7.

## 4. FIXES in this stage

**None were needed for the merge.** `dart format .` reported **0 changed**;
the halves met on the untouched bloc surface (`QuestEditorStatus`,
`editorStatus`, `editorError` — 2a added one constant, no shape change), and
2b's test updates were the mechanical ones its own string/harness changes
forced (toggle-rect pins, glyph expectations, the stepper-jump test). I made
**no code edit this stage**; the only files I touched are this doc set and the
SHARED_REQUEST entry below.

## 5. The one failing test — shared, clock-dependent, not P09

```
$ flutter test
01:39 +2608 ~1 -1: Some tests failed.
Failing tests:
  test/core/family_time_test.dart:
    seed + repository zone plumbing › kid_home completions are stamped with the family zone
  Bad state: Too many elements (dart:core List.single) at line 319
```

Everything else is green: `dart format --set-exit-if-changed .` → 0 changed,
`flutter analyze` → **No issues found!**, `flutter test test/features/quests`
→ **394/394**, whole suite **2608 pass, 1 fail, 1 skip** (the skip is P12's
`p12_bugs_test.dart:320`).

**Attribution, measured not guessed.** `Seed.demo()` stamps a `to_do`
completion for `q-plants`/`leo` at `2026-10-03T06:00Z` and `q-plants` repeats
**daily** (`seed.dart`'s `quest()` default). After `Seed.movedToDubai(db)` the
zone is `Asia/Dubai`, and `KidHomeRepositoryImpl.completeQuest` updates the
existing row only while it is still in the current period, else inserts a fresh
one (K03-BUG-4). A temporary probe (run, then deleted) printed:

| now | `countsForCurrentPeriod('daily', 2026-10-03T06:00Z, now, 'Asia/Dubai')` | path | rows for `q-plants` |
|---|---|---|---|
| 2026-10-03 19:00Z (when iterations 1–3 ran) | `true` | update | 1 → `.single` passes |
| 2026-10-03 22:17Z (now = 02:17 on **4 Oct** in Dubai) | `false` | **insert** | 2 → **throws** |

So the test went red when the machine clock crossed **Dubai midnight
(2026-10-03 20:00Z)**; the same trap arms for its London half at London
midnight (23:00Z). Nothing about P09 changed — `git diff main --
app/test/core app/lib/core app/lib/features/kid_home` is **empty**, so `main`
is red in exactly the same way right now, and this branch's own suite passed
the identical test 3 hours earlier. The file is `app/test/core/**`, which RULES
§1 puts off-limits to a screen agent, so I did not touch it; the request with
three one-line fix options is filed as **`SHARED_REQUEST.md` §7 (blocking,
shared, NOT P09)** for the core owner.

## 6. FIXES left open

- **§7 above** — the only red in the repo; needs the core owner (pin `now` in
  the test, assert the newest row, or move the story-day stamp).
- **Review finding 9** — `GetIt.instance` with no graceful degradation; optional,
  2b left it (P10's BUG-P10-8 is the precedent).
- **Review finding 7** — `docs/DESIGN_SPEC.md:168` says 48 px tiles, the design
  is 44; shared `docs/`, orchestrator's pass.

## 7. Verification (tails)

```
$ dart format .
Formatted 495 files (0 changed) in 2.22 seconds.

$ dart format --set-exit-if-changed .   # re-run
Formatted 495 files (0 changed) in 2.20 seconds.   (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 4.7s)

$ flutter test test/features/quests
00:15 +394: All tests passed!

$ flutter test
01:39 +2608 ~1 -1: Some tests failed.
  test/core/family_time_test.dart: seed + repository zone plumbing ›
    kid_home completions are stamped with the family zone
```

The stage's own rule is "PASS only if analyze is clean **and the full suite
passes**". Analyze is clean and every P09 test passes, but the full suite does
not, for a reason outside this screen's scope and outside RULES §1 — so the
verdict follows the evidence rather than the intent.

No simulator was booted, installed on, screenshotted or driven. `flutter clean`
was never run; no `// ignore:` was added; no test was skipped, weakened or
deleted to reach green; `git status --short -- app/lib/core app/lib/app tools/`
is empty.

## 8. Handover

P09 is code-complete for this iteration and its own suite is green. The loop
should route **`SHARED_REQUEST.md` §7** to the core owner; once that lands (or
the clock/seed makes the test self-consistent again) this tree passes the
whole suite unchanged, and stage 5 can re-take the icon-tile and toggle shots
now that the batch-5 paths and the 72-high approval card are in.


## From 3_test.md
# P09 — stage 3 · TEST (iteration 4)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` touched; `flutter clean` never run; no simulator booted, installed
on, screenshotted or driven; no `skip:` added, no test weakened, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

Iteration 3 closed with three red assertions and four open findings. Stage 2
has since applied the mandated integrator change (batch-5 glyphs, `toggleTrack
Offset` deleted, the approval card back to 72) and fixed BUG-P09-9/10/11/12.
This stage reviews what that did to its suites, adds eight tests for the new
behaviour, and records one bug that is still live.

## 1. Review of the mechanical test changes (six assertions, in my files)

Stage 2 touched five of this feature's test files. I reviewed each diff in
`git diff 8dec9b2..8022be3`:

| File | Change | Verdict |
|---|---|---|
| `quest_editor_coin_rules_test.dart:187` | `−` on 9999 now expects **100 / `= 100p at payout`** instead of 9998 (BUG-P09-11's repair jump) | correct — the behaviour changed by design; the test still asserts the *number* and the *helper* |
| `quest_editor_data_integrity_test.dart:227` | glyph list → `questBed / questDishes / questHoover / book / questBins / paw` | correct — exactly batch 5's mapping, design order preserved |
| `quest_editor_bloc_test.dart:~180` | an `ArgumentError` now maps to `QuestsBloc.saveFailedMessage` and must NOT contain `Invalid argument` | correct and stronger |
| `quest_editor_view_geometry_test.dart:325-343` | the toggle pins become the **track** (51×31 at 303 / 620.5 / 354 / 651.5), the 59×44 box assertions go | correct — this is what ORCHESTRATOR_NOTES 23:03 asked for |
| `quest_editor_view_test.dart` | toggle-rect pins + the a11y toggle lookup | correct |

Nothing was weakened: the design values in the geometry file (card 72, track
303→354 / 620.5→651.5) are the ones now asserted, and the glyph/labels
expectations moved to the shared batch's real paths.

## 2. Tests added (8 new, 3 files)

| File | Before → after | New tests |
|---|---|---|
| `quest_editor_toggle_hit_area_test.dart` (**new**) | — → 4 | the toggle's 59×44 tap area at **real** metrics |
| `quest_editor_coin_rules_test.dart` | 12 → 15 | the repair jump's full contract (3) |
| `quest_editor_states_test.dart` | 20 → 21 | a programmer error shows the parent-safe copy only |

### 2.1 `quest_editor_toggle_hit_area_test.dart` — closing my own blind spot

Iteration 3's report recorded (P09-TEST-5) that my slop test could not see
BUG-P09-10: it ran in a suite whose widget-test font wraps
`Coins land after your thumbs-up` onto two lines, so the approval row was ~76
high instead of the design's 40 — and a 59×44 hit slop cannot be clipped by a
row that is already taller. A test that cannot fail is not a test.

This file loads the same bundled Inter/Nunito faces
`quest_editor_view_geometry_test.dart` uses, asserts the premise (the card is
the design's 72 and the sub-line really is one 18 px line), and then proves the
slop at the design's metrics: taps **5 px above/below the track and 2 px right
of it** (the exact offsets the bug report used), plus the whole slop —
±6.5 vertical, ±4 horizontal, and all four **corners**, where a clipped box
fails first. All pass, so 2b's fix (the toggle is now a `Positioned` sibling
of the padded row rather than a child of it) is verified where it matters.

### 2.2 The repair jump (BUG-P09-11) — three tests, not one

The stepper now jumps to the valid band instead of stepping 9899 times. The
updated test only pins the landing value; the contract is bigger:

- **The jump lands exactly on the boundary and unlocks the save** — 9999 →
  100, `= 100p at payout`, the `Coins must be 1–100` caption disappears, the
  Save pill comes back, and the stored row is 100. (One short of the boundary
  would leave the save blocked, which is why "exactly" is the assertion.)
- **The jump is a one-shot repair** — the second `−` gives 99 and `+` gives 100
  again, so it cannot degenerate into a mode where every tap jumps.
- **An in-range value never jumps** — walked to 100 and to 1 the ordinary way,
  both ends step by exactly one and the save stays available. This is the guard
  against a fix that jumps whenever it can.

### 2.3 Parent-safe save copy, end to end

`_FaultyRepository` grew a `writeError` parameter so a test can inject a
specific error. With an `ArgumentError` reaching the bloc, the toast carries
`QuestsBloc.saveFailedMessage` and **neither** `Invalid argument` **nor** the
coins range detail is on screen; the parent stays on the editor and Save is
live again. (The sibling test pins the other half: an operational failure
still shows the repository's own message.) See §4 for what this does *not*
cover.

## 3. Results

```
$ dart format --set-exit-if-changed .
Formatted 497 files (0 changed) in 1.39 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.6s)

$ flutter test test/features/quests/
00:15 +411: All tests passed!          # 0 skipped — every parked proof is fixed

$ flutter test
00:56 +2625 ~1 -1: Some tests failed.
  test/core/family_time_test.dart: seed + repository zone plumbing ›
    kid_home completions are stamped with the family zone
```

Per file (all green): states 21, coin-rules 15, data-integrity 23,
toggle-hit-area 4, robustness 17, copy 8, a11y 15, bloc 7, view 42,
view-geometry 5, bugs 30 (~1 = the parked BUG-P09-13 proof, another stage's
file).

## 4. Bugs found

### P09-TEST-6 — major — in debug builds the coin guard leaks its assert text into the toast

- File: the error is produced at
  `app/lib/features/quests/data/quests_repository_impl.dart:99`
  (`assert(coins >= minCoins && coins <= maxCoins, 'Quest coins must be
  1..100, got $coins')`) and mis-mapped at
  `app/lib/features/quests/presentation/bloc/quests_bloc.dart:123-129`
  (`_editorError` maps **only** `ArgumentError`).
- What happens: `flutter test` — and every debug build of the app — runs with
  asserts on, so the guard throws `_AssertionError`, whose type is not
  `ArgumentError`. The mapping misses, `error.toString()` becomes
  `editorError`, and the **parent is shown the raw assert string**. Measured
  first-hand in a throwaway probe on this tree (real repository, `coins:
  9999`):
  ```
  type = _AssertionError
  toString = 'package:nestling/features/quests/data/quests_repository_impl.dart':
             Failed assertion: line 99 pos 7: 'coins >= minCoins && coins <= maxCoins':
             Quest coins must be 1..100, got 9999
  is ArgumentError = false
  ```
  That is a source path, an assert message and an internal range in a toast a
  parent reads — the opposite of review finding 4's "parent-safe copy", and it
  contradicts the doc comment on `_editorError`, which claims the coins guard
  throws an `ArgumentError` (that is only true in release).
- Repro: any quest write whose coins are outside 1..100 in a debug build (the
  editor clamps before dispatching, so today this is reachable only from a
  future caller that bypasses the clamp — which is precisely why the last line
  of defence should not leak).
- **Not patched** (stage 3 records). Fix direction for whoever owns it: either
  make `_checkCoins` throw the `ArgumentError` unconditionally (the assert then
  only adds noise for the same condition), or widen `_editorError` to treat
  `AssertionError` as a programmer error too. Stage 6 parked the same defect as
  **BUG-P09-13** (`p09_bugs_test.dart:592`, `skip: true`); my probe is an
  independent reproduction that also supplies the exact string.
- Note for whoever reads my §2.3 test as coverage: it injects an
  `ArgumentError` directly, so it proves the **release** mapping only. In this
  repository the real guard can never produce that type under `flutter test`.

### Resolved since iteration 3 (all four of that report's findings)

| Was | Now |
|---|---|
| P09-TEST-3 — approval card 68 vs the design's 72 | card back to 72, track on 303→354 / 620.5→651.5, pinned in the geometry file **and** re-pinned in the new hit-area file |
| P09-TEST-4 — an out-of-range reward needed 9899 taps | one tap jumps to the boundary, unlocks Save and stores it; the jump is proven to be a one-shot |
| P09-TEST-5 — my slop test was font-dependent | closed: real-font file, premise asserted, taps at 5/2 and at all four slop corners |
| P09-TEST-1/2 — the U+002D minus, the emoji-nickname crash | fixed on `main`/iteration 2 and covered by the copy audit and three nickname tests |

### Observation, outside this screen's scope (unchanged, one day older)

`test/core/family_time_test.dart:319` fails: after `Seed.movedToDubai(db)` the
`q-plants` completion is inserted a second time, so `.single` throws. Stage 2
traced it precisely (2_build.md §5): the seed stamps that completion at
`2026-10-03T06:00Z`, and once the machine clock passed Dubai midnight
(2026-10-03 20:00Z) `countsForCurrentPeriod('daily', …)` is false, so the
repository inserts instead of updating. It is `app/test/core/**` — off-limits
under RULES §1 — and `SHARED_REQUEST.md` §7 carries the three one-line fixes
for the core owner. Today is now **4 Oct** locally, so the trap is armed; it
will arm again for the London half at 23:00Z. Not P09's to fix, and not caused
by anything in this feature (`git diff main -- app/test/core app/lib/core
app/lib/features/kid_home` is empty).

## 5. Notes for the next stages

- **Nothing in this feature's suite is coupled to a pending change any more.**
  The remaining coupling is the *bug* above (one assertion in
  `p09_bugs_test.dart`, another stage's file, parked and waiting on the fix).
- **`buildWhen`** (review 7) and the `ValueListenableBuilder` (review 4) remain
  untested: both are performance properties with no observable contract.
- **Observation, unreachable today:** `QuestEditorView.didChangeDependencies`
  fetches `?id=` once (`if (_loadedQuest != null) return`), so going straight
  from `/quest-editor?id=a` to `?id=b` on the same `State` would keep showing
  quest `a`. Every in-app path pushes a new page, so nothing reaches it — but a
  future "switch to another quest from this screen" affordance would inherit
  it.
- Every widget test here ends with `disposeApp(tester)`, and every semantics
  handle is disposed **inside** the test body.

