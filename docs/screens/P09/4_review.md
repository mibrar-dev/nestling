# P09 — stage 4 · QA code review (iteration 1)

Scope: `git diff main...HEAD` (31 files, +3958/−66) reviewed against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P09,
`docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html` and the owner rules in the
loop brief. Nothing was edited except this file. No simulator was booted,
installed on, screenshotted or driven.

## Verdict summary

**No blocker and no major findings.** The screen is a faithful, well-
documented transcription of the design, the diff stays inside the allowed
feature except for two pre-authorised P08 test files, and the whole
feature suite is green.

Recorded independently in this stage (not taken on trust from the builders):

```
$ cd app && flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)

$ cd app && flutter test test/features/quests/
00:09 +256: All tests passed!
```

`flutter clean` was not run. `git diff --stat -- app/lib/core app/lib/app
tools/` is empty; `app/analysis_options.yaml` and `app/pubspec.yaml` are
untouched; no `google_fonts` / `GoogleFonts` in the diff; no `skip:` and no
`// ignore:` added.

## Findings

### 1. Minor (process) — two P08 test files edited outside RULES §1

`app/test/features/today/today_view_test.dart` (11 sites),
`app/test/features/today/p08_bugs_test.dart` (4 sites).

RULES §1 allows `app/lib/features/quests/**`, `app/test/features/quests/**`
and `docs/screens/P09/**`; `app/test/features/today/**` is another feature's.
The change replaces the placeholder-title anchor `find.text('P09 Quest
editor')` with the durable route contract — `pushedPath(tester)` /
`_pushedUri(tester)` reading `GoRouter.state.uri`, and
`find.byType(QuestEditorView, skipOffstage: false)` for the two "exactly one
editor page" proofs. Every other assertion in those files (query params,
`pop` returning to `/today`, the guard latching/releasing) is untouched; no
tolerance loosened, no assertion deleted.

This is deliberate and pre-authorised: `docs/screens/P09/SHARED_REQUEST.md`
§3 cites `docs/screens/_shared/router_push_test_fix_REPORT.md` §4 ("Never a
placeholder view title"; §5 names these two files) and
`docs/screens/_shared/shared_batch4.md` item 4 ("You MAY edit
`app/test/features/today/**` …"). Re-adding a hidden anchor to P09 was
correctly rejected — the orchestrator ordered exactly that deleted for P10.

**Fix:** none in this worktree. The orchestrator must land these two files on
`main` with the P09 merge (they are the only lines P08's branch and this one
touch).

### 2. Minor — the Save pill is the only leaf-filled control that does not use `onLeaf`

`app/lib/features/quests/presentation/widgets/quest_editor_widgets.dart:178`

```dart
style: NestType.buttonLabel(color: tokens.surface),
```

on `color: tokens.leaf`. Every other leaf-filled surface in the design system
pairs the background with `tokens.onLeaf` — `nest_button.dart:108`
(`NestButtonVariant.primary`), `nest_fab.dart:52/57`, `nest_badge_count.dart:30`,
`nest_kid_button.dart:86`, `nest_theme.dart:27` (`onPrimary`).

`.save { background: var(--leaf); color: var(--surface) }` in the CSS is
literally what this does, and in light mode `surface == onLeaf == #FFFFFF`, so
the light render is identical. In dark mode they differ
(`surface #1F1C2E` vs `onLeaf #0E1A14`) — both near-black on the `#3CC98A`
green, so contrast is fine (~8.7:1 either way) and the measured rects do not
move, but the DS convention is broken in exactly one place.

**Fix:** `NestType.buttonLabel(color: tokens.onLeaf)`.

### 3. Minor — `Tooltip(message: 'Back')` on Cancel is product code serving a test harness

`app/lib/features/quests/presentation/views/quest_editor_view.dart:522-525`

`WidgetTester.pageBack()` resolves `find.byTooltip('Back')` and asserts
`findsOneWidget`; seven pre-existing P10 tests
(`quest_library_view_test.dart:576`, `quest_library_states_test.dart:478,520`,
`quest_library_a11y_actions_test.dart:239,268,285`, `p10_bugs_test.dart:75,102`)
push `/quest-editor` and then call `pageBack()`. Because the P09 design has no
AppBar, the only candidate was this tooltip.

Two consequences: VoiceOver/TalkBack expose a tooltip "Back" on a control
announced as "Cancel"; and if a test ever has the library's own back button
on screen together with a non-offstage editor, `pageBack()` finds two and
throws.

**Fix:** delete the `Tooltip` and convert those P10 tests to
`await tester.binding.handlePopRoute()` — the idiom `today_view_test.dart`
and `p08_bugs_test.dart` already use for "the pushed page went away". Or, if
the tooltip stays, add a P09 test that asserts exactly one
`find.byTooltip('Back')` on the editor so the invariant is pinned.

### 4. Minor — `_pencePerCoin` hard-codes a database value

`app/lib/features/quests/presentation/views/quest_editor_view.dart:249`

```dart
const int _pencePerCoin = 1;
```

`families.coin_value_pence_per_coin` is a real column
(`app/core/data/app_database.dart:34`), seeded `1`
(`app/core/data/seed.dart:150`), and plan §1-5 said the helper "derives from
`families.coinValuePencePerCoin`". A family row set to anything else would
render a lying `= {n}p at payout` (the same row already drives P12/P13).

**Fix:** read the column through the family/pocket-money repository the view
already resolves, or state explicitly that 1 is a product constant and drop
the "= 1 in every seed" justification comment.

### 5. Minor — view-local `detail` duplicates the repository and is never persisted

`app/lib/features/quests/presentation/views/quest_editor_view.dart:331-337`
(`_repeatLabel`) and `:354` (`detail: '${_repeatLabel(_repeat)} · $_coins coins'`).

`Quest.detail` is not a column: `QuestsRepositoryImpl._detail`
(`app/lib/features/quests/data/quests_repository_impl.dart:92-98`) recomputes
`'$repeat · ${row.coins} coins'` on every read. The view's copy is therefore
dead data that can silently drift from the repository (e.g. a future change to
the seed's phrasing), and it is what `Quest.props` equality sees in tests.

**Fix:** `detail: widget.initialQuest?.detail ?? ''` and delete `_repeatLabel`.

### 6. Minor — nothing guards against a double Save

`app/lib/features/quests/presentation/views/quest_editor_view.dart:308-310`
(`_canSave`) and `:540` (`QuestSavePill(onPressed: _canSave ? _save : null)`).

`_canSave` only looks at the title and the day set. The pill stays live while
`QuestsState.editorStatus == QuestEditorStatus.saving`, so a double tap queues
two `QuestsCreateRequested`s; each `_save()` builds `id:
'q-${DateTime.now().millisecondsSinceEpoch}'`, so two taps inside the same
millisecond would also collide on the primary key. The bloc has no
in-flight guard either.

**Fix:** `onPressed: (_canSave && context.watch<QuestsBloc>().state.editorStatus != QuestEditorStatus.saving) ? _save : null`.

### 7. Minor (perf) — the whole form rebuilds on every `items` emission

`app/lib/features/quests/presentation/views/quest_editor_view.dart:108-117`

`BlocConsumer.builder` returns `body` unconditionally. The editor never reads
`state.items`, but `watchItems()` re-emits on **every** `quests`-table write,
so a save, an edit or a completion recorded anywhere in the app rebuilds all
~50 widgets of a 390×844 form.

**Fix:** `buildWhen: (previous, current) => previous.status != current.status`.

### 8. Minor (perf) — every keystroke rebuilds the whole sheet

`app/lib/features/quests/presentation/views/quest_editor_view.dart:472`

`onChanged: (_) => setState(() {})` exists only to recompute `_canSave`, but
it rebuilds the six icon tiles, three person pills, the `StreamBuilder`, three
cards, the segmented control and the day row per character.

**Fix:** wrap only `QuestSavePill` in a `ValueListenableBuilder<TextEditingValue>`
over `_title` (and read the day set through the existing state), so typing
repaints one pill.

### 9. Minor — editing a quest silently re-activates it

`app/lib/features/quests/presentation/views/quest_editor_view.dart:366`

`active: true` is written unconditionally, and `QuestsRepositoryImpl.getQuest`
does not filter on `active`, so `?id=` can open an archived row and saving it
resurrects it. No UI archives a quest today, so this is latent, not a live
bug.

**Fix:** `active: widget.initialQuest?.active ?? true`.

### 10. Minor — five of the twelve seeded quests open with no icon selected

`app/lib/features/quests/presentation/views/quest_editor_view.dart:228-241`

The `aliases` field is documented as accepting "the seed's existing
spellings", but only `bins` has one. `Seed._questsDemo`
(`app/core/data/seed.dart:275-311`) also uses `plate`, `bag`, `leaf`, `shirt`
and `sofa`, none of which matches the six `.ic` tiles, so `q-table`,
`q-bag`, `q-plants`, `q-washing` and `q-living` open with an empty selection
where the design shows one. The stored value is not lost (`_icon` is seeded
from the row, so a Save with no tap keeps `plate`), but the user cannot
re-pick that icon and cannot see which one the quest has.

**Fix:** either extend `aliases` per icon and file a design request for the
missing tiles, or show the row's stored `questIconAsset` as an extra
"current icon" tile when nothing matches.

### 11. Minor — the assignee roster is mutated during build

`app/lib/features/quests/presentation/views/quest_editor_view.dart:589`

`_children = children;` inside `StreamBuilder.builder` is a build-time side
effect. `_effectiveAssignee` (`:286`) falls back to `_children.first.id`, so if
the roster changes between a snapshot and a Save tap, `_save()` can write an
`assigneeChildId` for a child that no longer exists (a dangling FK on
`quests.assignee_child_id`).

**Fix:** keep the roster in a field updated from the stream once
(`_childrenStream.listen`, cancelled in `dispose`) and validate the resolved id
against it in `_save()`.

### 12. Minor — `?idea=` is still a dead query key

`app/lib/features/quests/presentation/widgets/quest_library_body.dart:242-244`

P10's `+ Add` on an idea row pushes `/quest-editor?idea=<id>`; P09 reads only
`?id=` and `?questId=`, so that tap opens a blank NEW quest instead of a
pre-filled one. Deliberately left open and recorded in `2_build.md`
("FIXES left open"), with the stale `TODO(P10)` still in place.

**Fix:** read `QuestsEditorQuery.ideaId` and seed title/icon/coins from
`repository.ideas()`, or extend `SHARED_REQUEST.md` so the gap is owned.

### 13. Minor (docs) — `2b_build_ui.md:167` names the wrong apostrophe

The "copy to compare" list says `Who’s it for?` (curly). Both the HTML source
(`design/html-source/screens/P09-quest-editor.html`, `Who\'s it for?`) and the
code (`quest_editor_view.dart:478`) use the **ASCII** `'`, and the code is
correct. The note would send the next reviewer or the UI check after a
character that does not exist in either source.

**Fix:** correct the note. Every other P09 string was compared
character-by-character against the HTML and matches exactly, including
`Before tea (5pm) ›` (U+203A, ink-3), `= 15p at payout`, `M T W T F S S` with
only the sixth cell selected, and `New quest` / `Cancel` / `Save`.

## What was checked and found correct

- **Geometry against the PNG (independent pixel check, not the builders'
  table).** `--paper` (`#FBF7F0`) covers the last pixel row (y 2531/3 = 843.7)
  in the light design, so the app's paper-to-edge sheet matches the design and
  the owner bottom-edge rule at once — there is no `--surface-2` strip to
  argue about. Scanning column logical x = 100: input border at y 156, field
  `surface` 157→206.67, bottom border at 207, then `paper` from 208 — the
  design really does stack `Icon` **flush** under the name field, which is why
  the code (plan §8) omits the `SizedBox(16)` that plan §1 sketch. Icon tile
  top border at 232. The `NestToggle` track measures x 303.0→353.7,
  y 621.0→651.7 on the PNG, which is exactly the rect
  `QuestEditorMetrics.toggleTrackOffset = Offset(4, -2)` is derived from — the
  compensation in finding "SHARED_REQUEST §2" is correct today, and the
  real-font `quest_editor_view_geometry_test.dart` pins the absolute rects so a
  change to `NestToggle` cannot silently regress it.
- **Design system.** No hard-coded colour, size, radius, font or text style in
  the diff; `Colors.transparent` only. Colours resolve through `context.nest`,
  sizes through `NestSpacing`/`NestDevice`/`NestRadii`/`NestType`. The six
  screen-local numbers (`iconTileRadius` 14, `hairline` 1.5, `savePadding` 18,
  `saveMinWidth` 64, `cancelPadding` 6, `dueRowMinHeight` 56) live in
  `QuestEditorMetrics` with their CSS source, the same pattern the shared
  `NestPager` uses. Shared components are reused, never re-implemented:
  `NestTextField`, `NestCard`, `NestStepper`, `NestSegmented`, `NestDayPicker`,
  `NestToggle`, `NestAvatar`, `NestIcon`, `NestButton`, `NestModal`,
  `NestBottomSheet`, `NestToast`, `NestStatusBar`. No `letter-spacing` is
  added anywhere (the P09 CSS sets none), no `text-wrap: balance` heading so no
  `NestBalancedText`, and no `NestChip` row so `NestChipWrap` is correctly
  absent. No Pip on this screen.
- **Architecture.** Feature-first intact: only `presentation/**` plus the
  feature's own `quests_routes.dart` changed; `domain/` untouched (the existing
  `getQuest`/`createQuest`/`updateQuest`/`deleteQuest` sufficed); no new
  tables, no DI or router-shell change; one bloc per feature with the three
  editor events added to `QuestsBloc`, and `QuestsState.editorStatus` kept
  orthogonal to `QuestsState.status` so the `items` stream still uses
  `emit.forEach` (no reload events). `/quest-editor` is already in the router's
  `parentOnly` list, so the screen is unreachable in kid mode.
- **Accessibility.** Every screen-local tappable (`QuestCancelButton`,
  `QuestSavePill`, `QuestIconTile`, `QuestPersonPill`, `QuestDueOptionRow`, the
  due `NestCard`) passes `onTap:` on its `Semantics` node *and* on the inner
  `InkWell`, with `excludeSemantics: true` — the a11y-actions rule is honoured
  everywhere. `QuestSavePill` reports `enabled: false` and drops the action
  when disabled; `QuestSegmented`, `NestStepper`, `NestDayPicker` and
  `NestToggle` supply their own. `Semantics(header: true)` on the screen title
  and on the three group labels; the icon row is a `container` group named
  `Quest icon`, matching the HTML `role="radiogroup" aria-label`. Tap targets:
  Cancel ≥44, Save 44, tiles 44, pills 48, day cells 44 (the `SizedBox(height:
  NestDevice.tapParent)` clamp keeps `NestDayPicker`'s `Ink` hairline inside the
  design's 44 border-box without touching the shared component), stepper 44,
  toggle hit box 44, due row 88, sheet rows 44, Delete 52.
- **Children's Code.** Parent-only route, guarded in `app/lib/app/router.dart`.
  No analytics, no ads, no network. The screen reads only the family's own
  children via `FamilyRepository.watchChildren()` and writes only to `quests`.
- **Robustness.** `const` on every subtree that allows it; `_childrenStream` is
  a `late final` so the `StreamBuilder` cannot resubscribe per build; `_title`
  disposed; `SingleChildScrollView` + `minHeight: constraints.maxHeight` keeps
  the paper to the physical edge while still scrolling in edit mode (where the
  Delete button sits below the fold, as `2b_build_ui.md` predicts). Tests
  cover 320 px width, text scale 1.3, and a 5 px-inside/2 px-inside day-cell
  hit area.
- **Tests.** 256 pass. The two-stage proof is a genuinely good structure: the
  widget-test-font suite asserts sizes, gutters and block-to-block deltas
  (surviving the font that makes the assignee pills wrap), and the real
  Inter/Nunito `FontLoader` suite
  (`quest_editor_view_geometry_test.dart`) asserts the **absolute** design rects
  for ~30 elements in light and dark, the background/border rects of the pills,
  tiles, segmented thumb, day cells and cards (the "shapes, not only text" rule)
  and the bottom edge. `quest_editor_bloc_test.dart` covers
  initial→saving→saved/failure, error clearing on retry, and that the load path
  is untouched. Save/delete proofs read the real Drift DB out of the
  fake-async zone.

## LEFT FOR THE LOOP

- Nothing blocking. Findings 2, 4, 5, 6, 9, 11 and 13 are cheap in-view
  cleanups worth folding into the next builder pass.
- Findings 3 and 12 want either a small cross-feature test edit (P10's
  `pageBack()` sites, which the orchestrator already authorised for this
  screen) or an explicit SHARED_REQUEST owner.
- Finding 1 must be carried on the merge, not reverted.
- No simulator was used in this stage; stage 5 owns the ±2 px UI verdict, and
  can lean on `quest_editor_view_geometry_test.dart` for the absolute rects
  (which are stated against a 47 px `NestStatusBar` reserve — on a simulator
  with a taller system status bar the whole sheet shifts down equally, so
  compare bands, not absolutes).

VERDICT: PASS