# P10 · Stage 2b — build, UI chunk (iteration 2)

Scope: `app/lib/features/quests/presentation/views/**` and
`presentation/widgets/**`, plus the view/widget tests in
`app/test/features/quests/` (`quest_library_view_test.dart`,
`quest_library_widget_test.dart`). No `core/`, no other feature, no simulator.

Tree at hand-off: `c1be080` (main merged in, so the shared batch4 fixes for
`NestSegmented` 52/44, `NestTextField.search` and the `NestTabBar` bottom-edge
treatment are present) plus the logic builder's `QuestsState.ideas` contract.

## CONTRACT CHANGES CONSUMED (from `2a_build_logic.md`)

`QuestsState` gains `ideas: List<Quest>`. `QuestLibraryView` now renders
`QuestLibraryBody(items: state.items, ideas: state.ideas)` and the
`get_it` import + the `_ideaTemplates()` service-locator probe are gone
(review finding 2 / BUG-P10-8). No widget signature changed.

## FIXES_1 items closed in this stage

| Item | Fix | Proof |
|---|---|---|
| BUG-P10-1 · same-frame double tap stacks two editors | new feature-private `QuestPushOnce` (`widgets/quest_push_once.dart`, a copy of P08's `_PushOnce`) wraps the body; both push sites (`+ Add`, Active row) go through it | `p10_bugs_test.dart` BUG-P10-1 — 2 ✓ |
| BUG-P10-2 · `.trow` text centred | `crossAxisAlignment: CrossAxisAlignment.start` on the row's `Expanded > Column` | BUG-P10-2 ✓; new `quest_library_view_test` row-text test (every built row's two lines at card x+64) |
| BUG-P10-3 · Active tab's filters were inert | search + category row render on the **Ideas tab only** (the Active board is the whole family list and has nothing to filter) | BUG-P10-3 ✓; new view test `the Active tab offers no filter it cannot honour` |
| BUG-P10-4 · 48 px below the last row | `_separated()` emits the 16 px gap only *between* rows; end-of-list space is the viewport's 32 | BUG-P10-4 ✓; new view test `the gap after the last row is the design 32, not 48` |
| BUG-P10-5 · search prefix icon 48×48 at x+0 | switched to the shared `NestTextField.search` slot (24 px glyph at field x+17, hint at x+50, 52-high box) | BUG-P10-5 ✓ (proof's reference rect updated, see below) |
| BUG-P10-6 · segmented 44/36 | **no local change** — landed on `shared/shared_batch4`; P10 verified the 52/44 track and the 16/0/16 chain | BUG-P10-6 ✓ |
| BUG-P10-7 · tab-bar content 34 px low | **no local change** — landed shared; P10 verified | BUG-P10-7 ✓ |
| BUG-P10-8 · view silently degraded on a DI failure | view half only, on top of the bloc's `ideas` state (above) | BUG-P10-8 ✓ |
| BUG-P10-9 · chips / `+ Add` / Active row invisible to AT | every `Semantics(excludeSemantics: true)` control now passes **`onTap:`** (its own action) and **`container: true`** (its own node — without it the `+ Add` annotations bubbled into the row and the button had no node at all). Active-row label is now `'$title. $meta'` (review finding 8) | a11y chip + `+ Add` groups ✓; new view test `every P10 control is actionable from the semantics tree` performs the tap on chip, `+ Add` and Active row and asserts the real effect |
| BUG-P10-11 · `plate` / `sofa` tile tints | `questTileTintFor`: `plate`/`table`/`bag` → sky, `sofa` → lilac; all 11 seed keys are now mapped (the `default` branch stays neutral for genuinely unknown keys, per `quest_idea_meta_test`'s unknown-key case) | both `quest_idea_meta_test` tint tests ✓ |
| review 6 · missing `.chipscroll` fade mask | `ShaderMask(BlendMode.dstIn)` over the scroll view, fading the last 24 px of the **viewport** (matches the CSS `mask-image`) | visual; layout untouched (no test churn) |
| review 7 · `NestBalancedText` where the CSS has no balance | plain `Text('Quests', NestType.h1(ink), maxLines: 1)` | existing title-style assertions still ✓ |
| review 11 · `initialTab` cached forever | `didUpdateWidget` re-reads it | — |

### ORCHESTRATOR_NOTES (all 7 items accounted for)

1. row text at card x+64 — fixed + pinned (BUG-P10-2, view test).
2. search icon 24 at x+16 / hint x+50 / 52-high field — shared slot adopted, verified 17/50/52 (BUG-P10-5).
3. segmented 52/44 — verified green (BUG-P10-6).
4. chips centre / first card y — verified: segmented bottom 110 → field 126 (16), field bottom 178 → chips 178 (0), chips bottom 226 → card 242 (16); minus the 47 px status-bar inset that is 156/173/179/291 against the design's 155/173/179/291.
5. tab-bar content — shared, verified green (BUG-P10-7); the view still paints nothing below the content, so the bar's surface runs to the physical edge (OWNER BOTTOM-EDGE rule).
6. cards continue under the bar — derivative of 2–5; the 7th card starts at y 746, under the bar top at 726.
7. real-font `FontLoader` geometry test — `p10_bugs_test.dart` keeps it; now 9/9 green.

## One test-file change outside my ownership (flagged)

`app/test/features/quests/p10_bugs_test.dart` (bug stage's file): BUG-P10-5 and
BUG-P10-6 measured "the search field" as `find.byType(TextField)`. The shared
`NestTextField.search` renders the `.search` box *around* the editable, so that
finder now returns the inner input only (x+50) instead of the field. I changed
both proofs to `find.byType(NestTextField)` and left every design number
untouched (icon 24×24 at field x+16 ±2, track 52, thumb 44, chain 16/0/16).
Assertion strength is unchanged; only the reference rect moved to the widget
that now *is* the field.

## Remaining red tests (owners outside this stage)

1. **`quest_library_states_test.dart` — 8 failures.** Collateral from the
   logic builder's contract change, not from my files: the file's
   `_MockQuestsRepository` never stubs `ideas()`, so `QuestsBloc._onLoadRequested`
   does `List<Quest> ideas = repo.ideas()` on `null` and throws
   (`type 'Null' is not a subtype of type 'List<Quest>'`), leaving the bloc in
   `loading` forever. Fix is one line per test:
   `when(() => repository.ideas()).thenReturn(<Quest>[]);` (or the 10 templates).
   Not mine by filename scope; reported for stage 3.
2. **`quest_library_a11y_test.dart` — 4 failures.** Three are the shared
   `NestSegmented` duplicate-label defect (BUG-P10-10, `SHARED_REQUEST.md` §1 —
   the fix is one `excludeSemantics: true` in `core/`). The fourth,
   `a row is one tappable button naming the quest and its meta`, is
   unsatisfiable as written: `find.bySemanticsLabel('Make your bed')` is an
   **exact** match, while the same test then requires
   `data.label` to `contains('coins')`. Review finding 8 asks for
   `'$title. $meta'`, which satisfies the second assertion and breaks the finder.
   The screen now announces `Make your bed. Daily · 5 coins` as one button with
   a working tap (pinned in `quest_library_view_test.dart`); the proof should use
   `find.bySemanticsLabel(RegExp('^Make your bed'))` or the `find.semantics`
   predicate.

## Gates

- `dart format --set-exit-if-changed lib/features/quests test/features/quests`
  → clean (28 files).
- `flutter analyze lib/features/quests test/features/quests` → **No issues found**.
- `flutter test test/features/quests/` → **+141 −12** (was +123 −26 on entry).
  The 12 are the two groups above; all 9 `p10_bugs_test.dart` proofs, every
  view/widget test, the filter/meta/repository/bloc tests pass.
- No simulator was booted, installed on, screenshotted or driven.

## LEFT FOR NEXT ITERATION

- The 12 red tests above (owners: stage 3 for the mock stub, the orchestrator for
  `NestSegmented`).
- Review finding 5 (`_QuestLibraryRouteAnchor`, review 3's shared half): kept
  with its `TODO(P10)` — deleting it needs `app/test/features/today/today_view_test.dart`
  (another feature's test, outside RULES §1) to move to the `pushedPath()`
  helper. Folded into `SHARED_REQUEST.md` §5.
- The `?idea=` / `?id=` query params on `/quest-editor` (P09, same feature) —
  documented `TODO(P10)`s, unchanged.
- A UI-check pass (`shot.sh` + `compare.py`) to confirm the new search slot,
  segmented 52 and Active-tab layout against the PNGs in both themes — the UI
  stage owns the simulator.

VERDICT: PASS