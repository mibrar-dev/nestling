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

VERDICT: FAIL