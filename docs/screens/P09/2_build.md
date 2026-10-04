# P09 — stage 2 · INTEGRATE (iteration 5)

A **FIXES_4** round with a single-item brief (`ORCHESTRATOR_NOTES` 00:25: fix
ONLY P09-TEST-6, change nothing else). 2a took the repository half of that
item, 2b its proof plus the CLOCK-rule cleanup, and the only integration
breakage left was a P09-owned proof whose premise a `main` merge had voided —
fixed here in `test/features/quests/**` (§3).

## 1. What 2a handed over (logic half)

- **P09-TEST-6 / BUG-P09-13 — fixed at the source.** `QuestsRepositoryImpl
  ._checkCoins` no longer `assert`s first: in a debug build the assert fired
  before the throw and its text (`Quest coins must be 1..100, got 9999`, plus
  file/line) rode `editorError` into the parent's toast, defeating
  `QuestsBloc._editorError`'s `ArgumentError` → `saveFailedMessage` mapping.
  The guard now throws `ArgumentError.value(...)` **unconditionally**, so debug
  and release agree and the toast can only ever show the product copy. Release
  behaviour is unchanged. The interface doc (finding 8, from iteration 4) is
  updated to promise exactly that, and `quests_repository_test.dart`'s two
  range-rejection tests now expect `throwsArgumentError`.
  I verified the end state in the tree: `_checkCoins` (impl lines 100–104) is
  the bare `if (…) throw ArgumentError.value(…)`, with no assert.
- Flagged, not acted on: the CLOCK-rule violation in the view (2b's line) and
  the voided `BUG-P09-5` proof (mine, below). Domain/data/bloc/routes otherwise
  untouched; no `DateTime.now()` anywhere in its layer.

## 2. What 2b handed over (UI half)

- The `BUG-P09-13` proof un-skipped and retitled in `p09_bugs_test.dart`,
  exercising the real repository + real bloc (9999 coins → `editorError ==
  saveFailedMessage`, no `Failed assertion:` text anywhere).
- **CLOCK rule** — the one app-code `DateTime.now()` in the feature, the
  create-id minter at `quest_editor_view.dart`, now reads
  `appNowUtc().millisecondsSinceEpoch` from `core/data/app_clock.dart`
  (`clock.now()` in production, the pinned Sat 3 Oct 2026 09:41 London in
  tests). One line plus an import; no layout or behaviour change.
- Nothing else on disk. Feature scope for 2b: green except the voided
  `BUG-P09-5` proof, which it measured and attributed but deliberately left
  (`p09_bugs_test.dart` is the bugs stage's file).

## 3. FIXES in this stage

**F1 — `BUG-P09-5`'s proof had a void premise (the only red in the repo).**

```
test/features/quests/p09_bugs_test.dart
  BUG-P09-5 — a removed child leaves an orphaned assignee ›
    q-bed assigned to deleted Leo shows no selected pill
  Expected 1, Actual 0
```

The proof removed Leo through `FamilyRepository.removeChild`. The `main` merge
brought P15-BUG-6, where that call now **cascade-deletes the removed child's
quests** — so `q-bed` no longer exists, `?id=q-bed` renders "Quest not found",
and the screen legitimately has zero pills. The premise ("an orphan survives
child deletion") can no longer be produced through the repository, so the
proof was testing nothing. Both builders measured it failing identically with
and without their diffs, and the repair belongs to this file, which is inside
RULES §1 for this screen.

The fix keeps the bug's real subject and only drops the void premise: the
child row is deleted straight into Drift (bypassing the new cascade) and the
quest row is deliberately kept, so the app state under test is exactly what
the bug describes — a quest whose `assigneeChildId` names a child the roster
no longer lists.

```dart
final db = await setUpTestScope();
await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-bed');
```

`quests.assigneeChildId` is a plain nullable text column with no foreign-key
pragma, so the orphan row is legitimate and the plant is deterministic. The
assertion is **tightened, not relaxed**: where the old proof counted one
selected pill, it now also pins *which* pill —

```dart
expect(pills.singleWhere((pill) => pill.selected).label, 'Anyone');
```

which is the actual contract of the fix (BUG-P09-5's view half: an id the
roster no longer lists falls back to `Anyone`, so Save clears the dangling FK
instead of writing it back). No production code touched.

**Nothing else needed fixing.** `dart format .` reported 0 changed before and
after my edit, and the halves met on the untouched bloc surface.

## 4. Mandatory orchestrator items — all satisfied

- **00:25 (P09-TEST-6)** — done by 2a at the source plus 2b's proof; verified
  in the tree above.
- **00:25 ("The family_time_test failure is fixed on main")** — verified: it
  is fixed in this tree (`5ca5a1c` merge) and no longer fails. My
  `SHARED_REQUEST.md` §7 from iteration 4 is therefore closed by the core
  owner; nothing to redo.
- **23:55** — that red is gone; no exemption was needed this time, because the
  only red was P09's own (F1).
- **23:03 (`toggleTrackOffset`)** — already removed in iteration 4; still
  absent, only doc comments mention it.
- **CLOCK rule** — `lib/` has **no** `DateTime.now()` outside one shared line
  in `family_repository_impl.dart:41` (`Seed.anchorOverride?.toUtc() ??
  DateTime.now().toUtc()`, a seed-anchor fallback in another feature);
  `test/features/quests` has zero `skip:` markers.
- **KID BACKGROUND rule** — n/a, P09 is a parent screen.

## 5. FIXES left open

- **Review finding 9** — `GetIt.instance` with no graceful degradation; optional
  (2b, iteration 4).
- **Review finding 7** — `docs/DESIGN_SPEC.md:168` says 48 px tiles, the design
  is 44; shared `docs/`, the orchestrator's pass.
- **`family_repository_impl.dart:41`'s `DateTime.now()`** — the one remaining
  CLOCK-rule line in the repo; shared `family/`, flagged here for visibility,
  not actionable by this screen.

## 6. Verification (tails)

```
$ dart format .
Formatted 534 files (0 changed) in 1.75 seconds.

$ dart format --set-exit-if-changed .   # after F1
Formatted 534 files (0 changed) in 2.03 seconds.   (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 8.6s)

$ flutter test test/features/quests/p09_bugs_test.dart
00:03 +31: All tests passed!

$ flutter test test/features/quests
00:29 +403: All tests passed!

$ flutter test
01:26 +3092 ~2: All tests passed!
```

`~2` are the repo's two pre-existing skips, both other features' and neither
introduced here: `test/features/pocket_money/p12_bugs_test.dart:321` (P12-BUG-05)
and `test/features/kid_home/k01_bugs_test.dart:566` (K01, from the K01 merge).
`test/features/quests` has **zero** skipped tests. The
`WARNING (drift): AppDatabase created multiple times` notices are the
repo-wide debug-build notice from `test_scope.dart`, not failures.

No simulator was booted, installed on, screenshotted or driven. `flutter clean`
was never run; no `// ignore:` was added; `analysis_options.yaml` untouched;
`git status --short -- app/lib/core app/lib/app tools/` is empty.

## 7. Handover

The gate is fully green: analyze clean, 3092 tests pass, both halves' work
integrated, the one mandatory item (P09-TEST-6) provably closed at the source,
and the CLOCK rule satisfied inside this feature. Stage 3 has 403 P09 tests
with no skips and no parked proofs; stage 5 can re-shoot against the batch-5
icon paths and the 72-high approval card.

VERDICT: PASS