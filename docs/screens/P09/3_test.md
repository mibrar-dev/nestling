# P09 — stage 3 · TEST (iteration 5)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` touched; `flutter clean` never run; no simulator booted, installed
on, screenshotted or driven; no `skip:` added, no test weakened, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

A single-item iteration: ORCHESTRATOR_NOTES 00:25 says *fix ONLY P09-TEST-6,
change nothing else*. Stage 2 fixed it at the source, so this stage's job was
to verify the fix, guard it against regression, close the gaps the new code
opened, and keep hunting.

## 1. Gates — all green

```
$ dart format --set-exit-if-changed .
Formatted 534 files (0 changed) in 3.78 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 5.8s)

$ flutter test test/features/quests/
00:26 +409 ~1: All tests passed!

$ flutter test
01:25 +3098 ~3: All tests passed!
```

Per file: states 22, coin-rules 15, data-integrity 23, toggle-hit-area 4,
robustness 22, copy 8, a11y 15, bloc 7, view 42, view-geometry 5, bugs 31.

- **P09-TEST-6 is closed and proven.** `_checkCoins` now throws
  `ArgumentError.value(...)` unconditionally (no `assert` first), and
  `p09_bugs_test.dart`'s BUG-P09-13 proof — real repository, real bloc, 9999
  coins, asserting `saveFailedMessage` and the absence of any
  `Failed assertion:` text — is **un-skipped and green**.
- **23:55's known red is gone.** `test/core/family_time_test.dart` was fixed on
  `main` and merged (`5ca5a1c`); my iteration-4 `SHARED_REQUEST.md` §7 is
  closed by the core owner.
- The `~3` skips are the repo's pre-existing ones (`p12_bugs_test.dart:321`,
  `k01_bugs_test.dart:566`, and stage 6's parked BUG-P09-14). This feature has
  **no** skip of its own that stage 2 did not author.

## 2. Review of the mechanical changes (stage 2, this iteration)

| File | Change | Verdict |
|---|---|---|
| `p09_bugs_test.dart` BUG-P09-13 | un-skipped, retitled, real repo + real bloc | correct — it is the regression guard for this iteration's mandated fix |
| `p09_bugs_test.dart` BUG-P09-5 | the proof's premise died with `main` (P15-BUG-6 cascade-deletes the removed child's quests), so it now deletes the **child row straight into Drift** and keeps the quest | correct and **tighter**: it went from "one pill selected" to `pills.singleWhere((p) => p.selected).label == 'Anyone'`, which is the actual contract. My own data-integrity tests plant the same orphan state and were unaffected. |
| `quests_repository_test.dart` | the two range-rejection tests now expect `throwsArgumentError` | correct — that is what the guard throws in both modes now |

Nothing weakened; the design values (card 72, track 303→354 / 620.5→651.5) are
still the ones asserted.

## 3. Tests added (6 new, 2 files)

### 3.1 The CLOCK contract, asserted behaviourally (states, +1)

The new rule is "app code never calls `DateTime.now()`; use
`clock.now()` / `appNowUtc()`". A grep proves the absence; this proves the
*behaviour*: the id a new quest is stored under is exactly
`q-${appNowUtc().millisecondsSinceEpoch}`, and explicitly **not**
`q-${DateTime.now().millisecondsSinceEpoch}`. Because `flutter test` pins the
story instant (Sat 3 Oct 2026 08:41Z) and the wall clock has moved on since
(the date rolled over during this iteration), a revert to `DateTime.now()`
fails this assertion rather than passing quietly.

### 3.2 The approval toggle's placement on every surface (robustness, +5)

BUG-P09-10's fix made the switch a `Positioned(top: 20.5, right: s4)` sibling
of the padded row — a structure that had never been tested at any width or
scale other than the design frame. Five new cases (320/390/430 × 1.0, plus 390
and 320 at scale 1.3) assert the invariants that must hold wherever the text
block wraps: the track stays inside the card's 16 px content box, is flush to
the content edge exactly as the design has it, never overlaps the sub-line,
and the title and the switch share one row without colliding. All five pass.
§4.3 is what they found at the same time.

## 4. Bugs found

### P09-TEST-7 (major) — a second quest cannot be created in the same session — **same as stage 6's BUG-P09-14**

- File: `app/lib/features/quests/presentation/views/quest_editor_view.dart:543`
  — `id: 'q-${appNowUtc().millisecondsSinceEpoch}'`.
- Repro (measured, this tree): save a quest → from the library tap `+ Add` →
  save again. Both creates mint `q-1791016860000`, because `appNowUtc()` is
  *frozen* at the anchor instant (`core/data/app_clock.dart`), so the second
  insert hits the primary key. After the second save:
  ```
  path after 2nd save: /quest-editor          ← the parent stays (correct)
  toast text: [SqliteException(1555): while executing statement,
               UNIQUE constraint failed: quests.id, constraint failed (code 1555)]
  rows = [q-1791016860000:First quest]        ← the second quest is not stored
  after retry: path=/quest-editor  toast=[…same SqliteException…]
  ```
  The retry produces the identical failure, so while the clock is pinned there
  is **no way out**. Before the CLOCK rule this could not happen inside a test
  (the wall clock advanced between the two saves); in production it needs two
  saves within the same millisecond.
- **Not patched** (stage 3 records). Fix direction: make the id unique by
  construction rather than by clock resolution — e.g. a monotonic counter, or
  an `Uuid`-style random suffix, with the timestamp kept for ordering.
- Stage 6 filed the identical defect as **BUG-P09-14** with a parked proof
  (`p09_bugs_test.dart:645`, the feature's only `skip:`). This is an
  independent reproduction, not a second report; the retry detail is new.

### P09-TEST-8 (major, broader than P09-TEST-6) — any non-`ArgumentError` save failure reaches the parent verbatim

- File: `app/lib/features/quests/presentation/bloc/quests_bloc.dart:123-129`
  — `_editorError` maps **only** `ArgumentError` to
  `saveFailedMessage`; everything else is `return error.toString()`.
- Evidence: the P09-TEST-7 repro shows the parent reading
  `SqliteException(1555): while executing statement, UNIQUE constraint failed:
  quests.id, constraint failed (code 1555)` in a toast — a SQL statement
  failure with a driver error code.
- Why it matters beyond that repro: iteration 5's mandated fix closed this
  hole for **one** error type (the coins guard). A storage failure — the most
  likely real-world save failure on a phone — is still a driver diagnostic on
  screen, which is what review finding 4 asked to end. My own states test
  asserts the *other* half of the current contract (an operational
  `StateError('disk full')` shows the repository's message), so the intended
  behaviour is currently ambiguous in the tests as well as in the code.
- **Not patched.** Fix direction: treat anything that is not a recognised
  operational error as a programmer/infra error — surface `saveFailedMessage`
  and move `error.toString()` to the `log(name: 'quests')` call that already
  exists in that method — and pin the operational cases explicitly
  (disk full / offline keep their own parent-safe copy, not the exception
  text).
- Not filed by stage 6; BUG-P09-14's description mentions the raw SQL toast as
  part of the id collision, so this is the same class generalised.

### P09-TEST-9 (minor, new) — the switch rides high whenever the text wraps

- File: `app/lib/features/quests/presentation/views/quest_editor_view.dart`
  — `Positioned(top: QuestEditorMetrics.approvalTrackTopInCard /* 20.5 */,
  right: NestSpacing.s4, …)` in the approval card's `Stack`.
- `20.5` is the design frame's *centred* offset: 16 px padding + the
  `(40 − 31) / 2` that the design's 40-high text block leaves. The CSS rule it
  approximates is `.switchrow { align-items: center }`, so the offset is a
  measurement of one frame rather than the rule, and it does not survive a
  taller text block.
- Measured on this tree (widget-test font, so the wrap is even more generous
  than the real one):

  | width / scale | card height | track centre vs text-block centre |
  |---|---|---|
  | 390 / 1.0 | 112 | **20 px high** |
  | 320 / 1.0 | 130 | **29 px high** |
  | 390 / 1.3 | 159 | **43.5 px high** |
  | 320 / 1.3 | 159 | **43.5 px high** |

  The switch stays inside the card, never covers the sub-line and stays fully
  operable (the five new tests in §3.2 prove exactly that), so this is a
  visual-alignment deviation only — but it is the owner's ALIGNMENT rule
  ("nothing a few px off") and it is visible on a 320 px phone and at the
  app's maximum text scale.
- **Not patched.** Fix direction: `Positioned.fill` + `Align(centerRight)`
  with the same 16 px right inset — that reproduces the design frame's
  `y 620.5` exactly (16 + (40 − 31) / 2) *and* centres on every other metric,
  and it keeps the 59×44 slop unclipped, which is why the slop was moved out
  of the row in the first place.

## 5. Notes for the next stages

- **One park and one fix are all that stand between this suite and green**:
  BUG-P09-14 (P09-TEST-7, parked by stage 6) and P09-TEST-8/P09-TEST-9 above.
- The next iteration's single-item brief should be P09-TEST-7 + -8 (they are
  one story: the save path's error handling), with -9 as the alignment tail.
- **Still deliberately untested:** `buildWhen` (review 7) and the
  `ValueListenableBuilder` (review 4) — performance properties with no
  observable contract.
- **Still-unreachable observation:** `QuestEditorView.didChangeDependencies`
  fetches `?id=` once, so `/quest-editor?id=a` → `?id=b` on the same `State`
  would keep showing `a`. Every in-app path pushes a new page, so nothing
  reaches it.
- Every widget test ends with `disposeApp(tester)`, and every semantics handle
  is disposed **inside** the test body.

VERDICT: FAIL