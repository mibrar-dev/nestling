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

VERDICT: FAIL
