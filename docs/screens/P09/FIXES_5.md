# Fix list after iteration 5

## From 3_test.md
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


## From 6_bugs.md
# P09 — stage 6 · FIND BUGS (iteration 5)

Tree: `5f7def6` (“P09: checkpoint after build (iteration 5)”, clock migration)
+ the proof below. No screen code was changed — the brief forbids fixing here.

Adversarial area sweep (iteration 5): the thirteen earlier proofs re-run, then
new probes over the clock migration (`appNowUtc()` in the id, the pinned test
clock, the assert-free coin guard) and the usual edge set — 0 / 1 / 6
children, emoji-leading and long UK names, £0.00 / £999.99 / 9999 coins,
rapid double taps, back navigation and deep links, Drift restart persistence,
the parent/kid guard, dark-mode contrast, 320 dp × text scale 1.3, async
gaps, Europe/London wall-clock storage and integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. The one
iteration-5 proof is `skip: true` so the suite stays green; run it with
`--run-skipped`. Every probe in the “attacks that hold” group runs unskipped.

## Earlier findings — all FIXED, proofs unskipped and green

| id | what was wrong | fix | proof |
|---|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | streams `watchCoinValuePencePerCoin()` | green |
| BUG-P09-2 | double-tap Save created the quest twice | `_saving` guard + pill disabled | green |
| BUG-P09-3 | non-picker icon showed no selected tile | aliases cover every seeded key | green |
| BUG-P09-4 | out-of-range coins unreachable | bounds widen to the stored value | green |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown falls back to `Anyone` | green |
| BUG-P09-6 | out-of-range reward silently clamped | Save blocked + live-region caption | green |
| BUG-P09-7 | alias tile tap rewrote the stored key | selected tile’s tap is inert | green |
| BUG-P09-8 | emoji nickname threw a UTF-16 paint error | `_initial` takes the first grapheme | green |
| BUG-P09-9 | card 68 / track 307,618.5 after batch 5 | uniform padding + no Transform | green |
| BUG-P09-10 | 59×44 hit slop clipped by the 40-high row | Stack-overlaid `Positioned` toggle | green |
| BUG-P09-11 | 9999 needed 9899 taps to repair | first step jumps to the boundary | green |
| BUG-P09-12 | legacy glyphs on four tiles | `questBed/questDishes/questHoover/questBins` | green |
| BUG-P09-13 | debug range guard leaked raw assert text | `_checkCoins` throws `ArgumentError` only; bloc maps it | green (unskipped this iteration) |

All thirteen proofs run unskipped in the file (31 passing tests: 18 proofs +
13 probes).

## Summary — iteration 5

| id | severity | one-liner | failing test |
|---|---|---|---|
| BUG-P09-14 | **major** | the new-quest id is a timestamp from the pinnable app clock, so under the CLOCK rule’s pinned test clock every create mints the same `q-<ms>`: a second quest in the same session hits the primary key, the editor stays open with a raw SQL toast, and no second quest exists | `BUG-P09-14 — a second quest cannot be created in the same session` › `the pinned clock makes both creates share one id` |

---

## BUG-P09-14 — major — a second quest cannot be created in the same session

**Where:** `quest_editor_view.dart:543` —
`id: _isEdit ? widget.initialQuest!.id : 'q-${appNowUtc().millisecondsSinceEpoch}'`.

**Why it is wrong:** the id is a millisecond timestamp from `appNowUtc()`,
which the new CLOCK rule pins in every test to **Sat 3 Oct 2026 08:41 UTC**
(`test/flutter_test_config.dart` + `app_clock.dart`: with
`Seed.anchorOverride` set, `appNowUtc()` returns a fixed instant —
`q-1791016860000`). The id therefore stops being unique: the second create
in a session inserts the same primary key, Drift throws a UNIQUE violation,
`editorStatus.failure` fires, the editor stays open and the toast carries the
raw SQL error (not an `ArgumentError`, so the parent-safe mapping does not
cover it). The parent flow — create one quest, then create another — is
broken in the loop’s standard environment. Production is masked only because
the real clock advances between two separate save flows (navigation + typing
take more than a millisecond); the id must be unique by construction, not by
timing.

**Repro (proven):**
```dart
// editor: type 'Quest A', Save → lands on /quests, row q-1791016860000
await tester.tap(find.text('+ Add').first);       // P10 Ideas → editor
await tester.enterText(find.byType(TextField).first, 'Quest B');
await tester.tap(find.text('Save'));              // same pinned id
expect(find.text('New quest'), findsNothing);     // actual: editor still open
expect(items.map((q) => q.title),
    containsAll(['Quest A', 'Quest B']));         // actual: only 'Quest A'
```
A scratch run confirms both symptoms: the editor remains mounted and the DB
holds only `q-1791016860000:Quest A`. (The failure is not the `+ Add`
harness — the same collision reproduces across an app restart, where the
second app instance over the same DB creates `q-1791016860000` again.)

**Suggested fix:** make the id unique independently of clock resolution, e.g.
append a random suffix —
`'q-${appNowUtc().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}'`
(`dart:math`; no `uuid` dependency exists) — or a process/database sequence
counter. A test that creates two quests in one session (or across a restart)
then passes. If a deterministic id is wanted for tests, a per-test counter
seeded from the DB row count is also fine; a bare timestamp is not.

---

## Observations (not filed)

* **Clock pinning fixed the iteration-4 date-rollover failures.** The
  whole-app suite is fully green again (`+3097 ~3`, 3 pre-existing skips):
  the kid_home/approvals/today period tests that failed on the real-date
  rollover (Sun 4 Oct) now see the pinned Sat 3 Oct 09:41 London instant.
* **`family_repository_impl.dart:41`** still calls `DateTime.now()` in its
  anchor fallback (`Seed.anchorOverride?.toUtc() ?? DateTime.now().toUtc()`)
  — a CLOCK-rule violation in the *family* feature (P05’s loop), not P09;
  noted for the orchestrator, not filed here.
* **Post-repair stepper re-entry** (9999 → 100, then `+` → 101) remains the
  BUG-P09-4 “stored value stays reachable” contract; recoverable in one tap,
  nothing written out of range — unchanged from iteration 4.

## Attacks that hold (probes, unskipped — 13 tests)

- **Rapid double taps:** double-tap `Delete quest` → one confirm modal;
  double-tap `Due by` → one option sheet; double-tap `Cancel`, a due-sheet
  row and `Keep it` never pop a second route; double-tap **Save** is guarded
  (one quest, one write).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` (plain and with `?id=`)
  lands on `/parental-gate`.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **One-child family:** the new quest defaults to that child.
- **Six children with long names** at 320 × 1.3: pills wrap in creation
  order, `Anyone` last.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` keeps ≥ 4.5:1.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  the wall-clock `17:00`.
- **A11y actions:** due-sheet rows and delete-confirm buttons expose
  `SemanticsAction.tap`; `performAction(tap)` moves the real state/DB.
- **`?idea=` prefill, both-keys URL, emoji nicknames, blocked saves,
  parent-safe failure copy** are covered green by the feature suites.

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:04 +31 ~1: All tests passed!        # 18 fixed proofs + 13 probes
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
+31 -1: Some tests failed              # BUG-P09-14 fails as documented
$ flutter test test/features/quests
00:28 +404 ~1: All tests passed!
$ flutter test
02:39 +3097 ~3: All tests passed!
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (briefs, review/UI notes, other test files, UI
PNGs); it was left untouched.

