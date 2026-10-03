# P10 · Stage 2 — INTEGRATE (iteration 2)

Job: make the two halves (`2a_build_logic.md`, `2b_build_ui.md`) compile and
pass together. Smallest change, no redesign, no shared-file edits (RULES §1).

**Result: `dart format` clean · `flutter analyze` → No issues found ·
`flutter test` → `+1921 −3`.** The 3 remaining failures are all one shared-code
defect (`NestSegmented` announces every option label twice) that I may not fix
here — detail and the exact one-line shared fix under FIXES-4. Per the brief,
PASS requires the full suite green, so this stage is **FAIL on that single
blocker**; everything in my scope is green.

## What landed (summary of the two halves)

### 2a — logic chunk (`bloc/**` + logic tests)

No contract *removal*: `QuestsState` **gained** `ideas: List<Quest>` (default
`const []`, threaded through `copyWith`/`props`), populated by
`QuestsBloc._onLoadRequested` from `_repository.ideas()` on the loading state
and every loaded emission; a failure keeps the last ideas. That closes review
finding 2 / BUG-P10-8 (the view no longer probes the service locator — the
`get_it` import and `_ideaTemplates()` are gone). The repository order test now
pins **creation order** per the orchestrator's §5 ruling (main `8ad0cdc`,
`watchActiveQuests` ordered by `createdAt, id`). Added/updated:
`quests_bloc_test.dart` (16), `quests_repository_test.dart` (10).

### 2b — UI chunk (`views/**`, `widgets/**` + view/widget tests)

`QuestLibraryView` now renders `QuestLibraryBody(items: state.items, ideas:
state.ideas)` and no longer touches GetIt. Closed BUG-P10-1 (`QuestPushOnce`
guard, new `widgets/quest_push_once.dart`), BUG-P10-2 (row text left-aligned at
card x+64), BUG-P10-3 (search + category row only on the Ideas tab), BUG-P10-4
(16 px separators *between* rows only), BUG-P10-5/6/7 (shared fixes adopted),
BUG-P10-9 (`onTap:` **and** `container: true` on every `Semantics` control,
Active-row label now `'$title. $meta'`), BUG-P10-11 (`plate`/`sofa` tints),
review 6 (`.chipscroll` fade mask via `ShaderMask`), 7 (plain `Text` for the
un-balanced title), 11 (`didUpdateWidget` re-reads `initialTab`). Verified all
7 `ORCHESTRATOR_NOTES` items; shared batch4 fixes (`NestTextField.search`,
`NestSegmented` 52/44, `NestTabBar` bottom-edge) are in the tree at `c1be080`.

Handed to me: **12 red tests**, which 2b correctly reported as owned elsewhere.

## FIXES

### FIXES-1 — DONE · 8 tests: `quest_library_states_test.dart` mock never stubbed `ideas()`

`2a`'s new `QuestsState.ideas` means the bloc calls `_repository.ideas()` on
every load. `_MockQuestsRepository` (a bare `extends Mock`) returned mocktail's
`null` for it, so the handler threw
`type 'Null' is not a subtype of type 'List<Quest>'` and the bloc never left
`loading` — the spinner, the failure block and both empty states were all
unreachable in that file.

Fix, in `app/test/features/quests/quest_library_states_test.dart` only: the mock
now stubs the method once, in its constructor, with the *real* templates —
`setUpTestScope()` registers the real `QuestsRepository`, so the body keeps
rendering the same 10 ideas the view used to read straight from GetIt:

```dart
class _MockQuestsRepository extends Mock implements QuestsRepository {
  _MockQuestsRepository() {
    when(ideas).thenReturn(GetIt.instance<QuestsRepository>().ideas());
  }
}
```

(+1 import: `get_it`.) No assertion touched; the 8 tests now exercise the real
status switch again (spinner colour/centring, error copy, `Try again` retry,
`Active (0)` empty state).

### FIXES-2 — DONE · 1 test: unsatisfiable exact-match finder on the Active row

`quest_library_a11y_test.dart` → `a row is one tappable button naming the quest
and its meta` asserted `find.bySemanticsLabel('Make your bed')` (an **exact**
match) while two lines later requiring `data.label` to `contains('coins')`.
Review finding 8 mandates the single combined label `'$title. $meta'`, so the
two assertions could never both hold.

Fix: the finder is now `find.bySemanticsLabel(RegExp('^Make your bed'))`.
`findsOneWidget`, `isButton`, `hasAction(SemanticsAction.tap)` and both
`contains(...)` assertions are unchanged — the proof is the same strength, it
just stops demanding that the quest name be the *entire* label. This matches
what 2b recommended.

### FIXES-3 — DONE · mandatory orchestrator item: delete the hidden route anchor

`ORCHESTRATOR_NOTES.md` (update 10:00) says: *"After the merge, delete the
hidden anchor."* The shared batch4 "today test anchor" fix has landed —
`app/test/features/today/today_view_test.dart:286-287` now asserts
`pushedPath(tester) == '/quests'` ("Route-path assertion only: P10 owns the
library view and its copy"), and no `P10 Quest library` literal remains in
another feature's tests.

So `QuestLibraryView` is back to 2b's plain `Scaffold → SafeArea →
BlocBuilder` body: the `Stack(fit: StackFit.passthrough)` wrapper, the
`Positioned` anchor and the whole `_QuestLibraryRouteAnchor` class (with its
`TODO(P10)`) are deleted. Verified: P08's two navigation tests and
`router_push_test.dart` pass without it, which is what the shared fix was for.
P08b's "Browse ideas" assertion has the same `pushedPath` shape.

### FIXES-4 — LEFT (shared code, cannot fix here) · 3 tests: `NestSegmented` double label

All three failures are the same assertion and the same root cause:

```
Expected: exactly one matching candidate
  Actual: _ElementPredicateWidgetFinder:<Found 2 widgets with a semantics label named "Ideas">
   Which: is too many
```

* `quest_library_a11y_test.dart` → `P10 segmented control each option is one
  labelled, tappable button`
* …→ `P10 icon buttons every interactive node announces what it does`
* …→ `P10 dark mode the same semantics contract holds in dark`

`app/lib/core/design_system/components/nest_segmented.dart:53-58` wraps each
option in `Semantics(button: true, selected:, label: option.label, onTap: …)`
but has no `excludeSemantics: true`, so the option's inner `Text` (`:78`) and
the `InkWell`'s own node keep their own semantics — a screen reader walks
"Ideas" twice on every segmented control in the app (`NestSegmented` is used by
`quest_library_body.dart` and the gallery). Batch4 added the missing `onTap:`
but not `excludeSemantics`.

**Fix (shared, one line):** add `excludeSemantics: true` to that per-option
`Semantics`; the `onTap` batch4 added stays, so the node keeps its action.
`nest_chip.dart:119-121` already does exactly this ("One node per chip").

Left here on purpose: `app/lib/core/**` is forbidden to a screen agent
(RULES §1); `ExcludeSemantics` around the control would delete its tap actions
from the semantics tree (worse than the duplicate); re-implementing the control
is forbidden; and relaxing the three proofs to `findsWidgets` would mask a real
MAJOR a11y defect that `SHARED_REQUEST.md` §1 is tracking. `SHARED_REQUEST.md`
§1 now records that this is the *only* remaining blocker plus the exact proof
names.

## LEFT / notes (not blockers)

1. Chip-row right-edge fade and the real-font geometry proofs are green per 2b
   (`ShaderMask` + `p10_bugs_test.dart` 9/9); a UI pass (`shot.sh` +
   `compare.py`, both themes) still belongs to stage 5 — no simulator was
   booted, installed on, screenshotted or driven in this stage.
2. `?idea=` / `?id=` query params on `/quest-editor` (P09, same feature) remain
   documented `TODO(P10)`s.
3. `SHARED_REQUEST.md` §5 (shared `NestChip` tap action), §6 (`QuestPushOnce`
   → `core/`) and §7 (`plate` tint disagreement with P08) stay open for the
   orchestrator; no P10 test is red on any of them.

## Verification tails

```
$ dart format .
Formatted 435 files (0 changed) in 1.13s.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.5s)

$ flutter test
00:36 +1921 -3: Some tests failed.
  test/features/quests/quest_library_a11y_test.dart: P10 segmented control each option is one labelled, tappable button
  test/features/quests/quest_library_a11y_test.dart: P10 icon buttons every interactive node announces what it does
  test/features/quests/quest_library_a11y_test.dart: P10 dark mode the same semantics contract holds in dark
```

On entry: `+1912 −12`. Of the 12, **9 are fixed in scope** (FIXES-1, FIXES-2)
and 3 are FIXES-4. The `WARNING (drift): AppDatabase created multiple times`
notices in the output are the repo-wide debug-build notice from `test_scope.dart`,
not failures.

VERDICT: FAIL