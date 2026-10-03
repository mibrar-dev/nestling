# P09 — stage 6 · FIND BUGS (iteration 1)

Tree: `881880a` (“P09: checkpoint after build (iteration 1)”) + the new test
file below. No screen code was changed — the brief forbids fixing here.

Adversarial area sweep: data edge cases (0 / 1 / 6 children, long UK names,
£0.00 / £999.99 / 9999 coins, empty lists), rapid double taps, back
navigation and deep links, Drift restart persistence, the parent/kid guard,
dark-mode contrast, 320 dp × text scale 1.3, async gaps, Europe/London
wall-clock storage, and integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. Each bug
proof is `skip: true` (bug id in the group name) so the suite stays green;
run them with `--run-skipped` to see them fail. Every probe in the
“attacks that hold” group runs unskipped.

## Summary

| id | severity | one-liner | failing test (group › test) |
|---|---|---|---|
| BUG-P09-1 | **major** | payout helper hard-codes 1p/coin and ignores the family’s `coinValuePencePerCoin` | `BUG-P09-1 — the payout helper ignores the family coin value` › `a 2p-per-coin family still reads "= 15p at payout"` |
| BUG-P09-2 | **major** | double-tap **Save** creates the quest twice (no in-flight guard) | `BUG-P09-2 — double-tap Save creates the quest twice` › `two Save taps before the router frame make two quests` |
| BUG-P09-3 | minor | a quest icon outside the six tiles (`plate`, `shirt`, `sofa`, `bag`, `leaf`) shows no selected tile | `BUG-P09-3 — a quest icon outside the six tiles has no selection` › `editing q-table (icon "plate") selects no tile` |
| BUG-P09-4 | minor | out-of-range stored coins (9999 / 0) cannot be restored once the stepper touches them | `BUG-P09-4 — out-of-range stored coins cannot be restored` › `a 9999-coin quest drops to 9998 with no way back` |
| BUG-P09-5 | minor | a quest assigned to a removed child shows no selected pill; Save keeps the orphan id | `BUG-P09-5 — a removed child leaves an orphaned assignee` › `q-bed assigned to deleted Leo shows no selected pill` |

---

## BUG-P09-1 — major — the payout helper ignores the family coin value

**Where:** `app/lib/features/quests/presentation/views/quest_editor_view.dart`
— `const int _pencePerCoin = 1` (line 249) feeding
`'= ${_coins * _pencePerCoin}p at payout'` (line 652).

**Why it is wrong:** the reward helper is the screen’s only money figure and
the plan (§1-5) says it “derives from `families.coinValuePencePerCoin`”.
The column is real, variable data: the schema carries it, P06’s setup screen
reads it, and P06 pins the exact opposite behaviour for the same column
(“the coin value string follows the database, not the design”,
`pocket_money_setup_view_test.dart:1944`). P09 prints 15p for a family whose
stored rate is 2p/coin — the database value the orchestrator’s DATA-over-mocks
rule says is correct. Reachability note: every shipped seed writes 1, and no
current UI writes a different value, so the wrong figure is latent today; it
becomes wrong the moment any flow (P06/P16, a migration or a seed variant)
stores another rate.

**Repro:**
```dart
final db = await setUpTestScope();
await (db.update(db.families)..where((f) => f.id.equals(Seed.familyId)))
    .write(const FamiliesCompanion(coinValuePencePerCoin: Value(2)));
await pumpAppRoute(tester, QuestsRoutePaths.editor);
// 15 coins × 2p = 30p
expect(find.text('= 30p at payout'), findsOneWidget); // FAILS
```
Expected `= 30p at payout`; actual `= 15p at payout`.

**Suggested fix:** read the rate from the database instead of the constant —
e.g. add a read-only `Stream<int>/Future<int> coinValuePencePerCoin()` to
`QuestsRepository` (feature-local, backed by the `families` row) and render
`coins * rate`; or read it through the existing read-only
`SettingsRepository.watchSettings()` / `FamilyRepository` import the way the
view already imports `family/domain` read-only. Update the widget test that
asserts `= 15p at payout` to keep the demo-seed case (rate 1) and add the 2p
case.

## BUG-P09-2 — major — double-tap Save creates the quest twice

**Where:** `_QuestEditorSheetState._save`
(`quest_editor_view.dart:345`) and the header call site
`QuestSavePill(onPressed: _canSave ? _save : null)` (line 540). `_save`
never consults `state.editorStatus`, and the pill stays enabled while
`QuestEditorStatus.saving`.

**Why it is wrong:** two taps that land before the router frame replaces the
editor both dispatch `QuestsCreateRequested`; `_save` mints the id from
`DateTime.now().millisecondsSinceEpoch` per call, so the two inserts get
different ids and both land — the parent gets two identical quests. (A
same-millisecond pair instead collides on the primary key and surfaces as a
save failure.) This is the same defect class the P10 hunt rated major
(double-tap stacking two editor routes).

**Repro:**
```dart
await pumpAppRoute(tester, QuestsRoutePaths.editor);
await tester.enterText(find.byType(TextField).first, 'Double tap quest');
await tester.tap(find.text('Save'));
await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
await tester.tap(find.text('Save'));
// settle, then read the DB
expect(quests.where((q) => q.title == 'Double tap quest').length, 1); // FAILS: 2
```
Actual: two rows, ids `q-…540` and `q-…548` (proven in a scratch diagnostic).

**Suggested fix:** guard the save in the sheet (`bool _saving = false;`
early-return + set, cleared on the bloc’s failure emission) **and** disable the
pill while `state.editorStatus == QuestEditorStatus.saving`
(`onPressed: null`), so both the visual control and the handler are safe.
Keep the `failure` path re-enabling it.

## BUG-P09-3 — minor — a quest icon outside the six tiles shows no selection

**Where:** `_questIcons` (`quest_editor_view.dart:228`) + the selection test
`selected == option.key || option.aliases.contains(selected)` (line 554).

**Why it is wrong:** the seed stores ten distinct icon keys
(`plate`, `shirt`, `sofa`, `bag`, `leaf`, …) but the picker has six tiles and
only one alias (`bins` → `bin`). Editing `q-table` (`plate`), `q-washing`
(`shirt`), `q-living` (`sofa`), `q-bag` (`bag`) or `q-plants` (`leaf`) renders
the whole `role="radiogroup"` with **no checked tile**, so the parent cannot
see the quest’s current icon (and screen readers announce no selection). The
icon is preserved on save, so this is a visible-state/a11y defect, not data
loss.

**Repro:** `pumpAppRoute('/quest-editor?id=q-table')`; count
`QuestIconTile.selected` → expected 1, actual 0.

**Suggested fix:** extend the alias map so every icon the DB can hold maps to
a tile, or render the stored icon as an extra selected tile when it is not one
of the six; the durable fix is to align the seed’s icon vocabulary with the
six-tile picker (shared/seed change → SHARED_REQUEST, orchestrator-owned).

## BUG-P09-4 — minor — out-of-range stored coins cannot be restored

**Where:** `_coins` initialised straight from the row (line 269) with button
bounds `onDecrease: _coins > 1` / `onIncrease: _coins < 100` (lines 666–667).

**Why it is wrong:** the stepper clamps only its buttons. A stored value
outside the design’s 1–100 range is displayed and can be moved one step, but
never back: a 9999-coin quest drops to 9998 and `+` is dead (9998 is not
< 100); a 0-coin quest can be raised to 1 but never returned to 0. The editor
neither clamps the stored data nor offers a representation for it, so a single
mis-tap permanently rewrites an existing value.

**Repro:** insert a quest with `coins: 9999`, open `?id=q-9999`, tap
`decrease`; `find.text('9998')` passes, then
`NestStepper.onIncrease` is null → the test expects it non-null and fails.

**Suggested fix:** clamp on load (`_coins = quest.coins.clamp(1, 100)`, the
same repair the rest of the app does for out-of-range data) or size the upper
bound to `max(100, storedValue)` so the stored value stays reachable; add a
repo-level range check so such rows cannot be written.

## BUG-P09-5 — minor — a removed child leaves an orphaned assignee

**Where:** `_assignee` seeded from the row (line 300) and
`_effectiveAssignee` (line 287); `FamilyRepository.removeChild` deletes the
child without touching `quests.assigneeChildId`.

**Why it is wrong:** after a child is removed, editing one of their quests
shows the pill row with **nothing selected** (`_assignee` matches no pill and
is not `_anyone`), and Save writes the dead id straight back — the quest stays
assigned to a child who no longer exists, with no visual indication.

**Repro:** `removeChild('leo')`, open `?id=q-bed` (assigned to Leo); count
selected `QuestPersonPill` → expected 1, actual 0.

**Suggested fix:** once the roster is loaded, treat an assignee that matches
no child as `_anyone` (fall back and let Save clear the id), or show a
selected “Anyone” fallback; a cascade/reassign belongs in the family feature
(SHARED_REQUEST, orchestrator-owned).

---

## Attacks that hold (probes, unskipped — 12 tests)

- **Double-tap `Delete quest`** → one confirm modal: the first tap pushes the
  dialog route synchronously, so the modal barrier is the hit-test target for
  the second tap and the framework swallows it.
- **Double-tap `Due by`** → one option sheet (same modal-barrier protection).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` lands on
  `/parental-gate`; the editor never builds.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **Six children with long names** (`Maximilian-Alexander`,
  `Annabella-Rose`, `Cassandra-Jane`, `Fitzwilliam`) at 320 × 1.3: pills wrap,
  creation order preserved (Maya, Leo, then the added children, `Anyone`
  last).
- **One-child family:** the new quest defaults to that child.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` pair keeps ≥ 4.5:1
  contrast.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  stored as the wall-clock string `17:00` (`dueLabel` `Before tea (5pm)`).
- **Due-sheet a11y:** all three rows expose `SemanticsAction.tap`, and
  `performAction(tap)` moves the real due label (and the saved `HH:MM`).
- **Delete modal a11y:** `Keep it` and `Delete` expose tap; `Keep it` driven
  through semantics keeps the Drift row.

Existing suites already cover the other listed edges: 0 children / `Seed.empty`
(`quest_editor_view_test.dart` — Anyone only), unknown `?id=` → “Quest not
found”, blank title disables Save, weekly-with-no-days blocks Save.

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:02 +12 ~5: All tests passed!        # 12 probes pass, 5 bug proofs skipped
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
+12 -5: Some tests failed              # the five BUG-P09-* proofs fail as documented
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (`quest_editor_a11y_test.dart`,
`quest_editor_states_test.dart`, `4_review.md`, `5_ui.md`, `ui/`). It was left
untouched. At the time of writing, two of that file’s tests fail for
test-side reasons (it expects `NestToggle`’s node to carry the `isButton`
flag — Flutter’s switch role is `toggled` + `onTap`, which is what the
component publishes — and it compares `Tristate.isSelected` to a `bool`); they
are not P09 screen defects and are that stage’s to resolve.

VERDICT: FAIL
