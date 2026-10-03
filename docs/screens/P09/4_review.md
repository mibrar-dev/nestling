# P09 — stage 4 · QA code review (iteration 2)

Scope reviewed: `git diff main...HEAD` on branch `screen/P09` (57 files,
+8293/−70) against `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P09 (line 168), `docs/design/SPACING_SPEC.md`, the
design system in `app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html`, the design PNGs, and every
mandatory item in `docs/screens/P09/ORCHESTRATOR_NOTES.md`.

No code was edited. Nothing except this file was written. No simulator was
booted, installed on, screenshotted or driven; `flutter clean` was never run.

Because another stage is writing in this worktree at the same time (see
"Process note" at the end), every check below was run against an **isolated
`git archive HEAD` export** (`…/opencode/p09-head`) so its in-flight,
uncommitted files could not colour the result:

```
$ cd …/opencode/p09-head/app && flutter analyze
No issues found! (ran in 6.8s)

$ flutter test test/features/quests/
00:19 +335: All tests passed!

$ flutter test test/features/today/
00:08 +110: All tests passed!

$ flutter test
02:46 +2530 ~1: All tests passed!        # the ~1 skip is main's P12-BUG-05
```

`git diff --stat -- app/lib/core app/lib/app app/test/core tools` is empty;
`analysis_options.yaml` and `pubspec.yaml` are untouched; no `skip:` and no
`// ignore:` anywhere in the diff; no `google_fonts` / `GoogleFonts`.

## Verdict summary

**Two major findings — both actionable inside this worktree, one of them a
violation of a mandatory orchestrator instruction. VERDICT: FAIL.**

The screen is otherwise a careful, faithful transcription of the design: no
hard-coded colours, sizes or fonts; shared components reused rather than
re-implemented; every screen-local tappable carries `onTap:` on its own
`Semantics` node; streams and controllers disposed; the geometry test pins the
design's absolute rects with the bundled real fonts, and my own pixel probe of
the design PNG confirms those numbers are real (see "What was checked").

---

## Findings

### 1. MAJOR — the Dishes tile draws a look-alike glyph, which the mandatory ORCHESTRATOR_NOTES item 1 forbids

**Where:** `app/lib/features/quests/presentation/views/quest_editor_view.dart:257-280`
(`_questIcons`, line 269 `icon: NestIcons.basket`).

**Why it is wrong.** `ORCHESTRATOR_NOTES.md` (17:57, item 1) is mandatory and
says: *"If a glyph is missing from `app/assets/icons`, write `SHARED_REQUEST.md`
with the exact names and SVG source (from design/html-source) rather than
substituting a look-alike."* Three independent records in this worktree agree
with the rule and against the code:

* `SHARED_REQUEST.md` §4 **CORRECTION**: *"`ic_basket.svg` … this look-alike
  substitution must be REVERTED, not kept: the exact design glyph is missing
  from `app/assets/icons`, so the DS must gain it."*
* `5_ui.md` (iteration 2, deviation 1, the item's own blocker):
  *"The substitution violates the mandatory orchestrator instruction … and must
  be replaced with the exact design glyph, not kept."*
* `2b_build_ui.md:114-121` argues for keeping it on the premise that *"`ic_hoover.svg`
  … has since been redrawn in the DS"*. That premise is **false**. I verified it
  against git and bytes: `git log --all -- app/assets/icons` last touches
  `ic_*.svg` in `7eaa1f7` / `f912ef0` (pre-branch), and the working assets are
  still `ic_hoover.svg` = rounded canister `rect x=3 y=10.8 w=11.8 h=8.2 rx=3.4`
  + dot wheels (design: `rect x=3 y=8 w=13 h=8 rx=2` + leg lines) and
  `ic_dishwasher.svg` = appliance with rack line and two control dots (design:
  plain basket `M4 11h16v9…` + one arch handle `M8 11V7a4 4 0 0 1 8 0v4`).
  So the basket is not "the closest available match to a redrawn DS" — it is a
  third, wrong object, chosen to look closer to the design than the glyph that
  the mapping is actually named after.

The request the rule asks for is already filed correctly (§4, with the four
verbatim design SVGs), so nothing blocks the fix.

**Fix.** Revert line 269 to the semantically correct glyph the mapping is named
for and delete the justifying comment at 262-268:

```dart
(key: 'dishwasher', aliases: <String>['plate'], label: 'Dishes',
 icon: NestIcons.dishwasher),
```

Keep `SHARED_REQUEST.md` §4 as the request for the exact path; when the DS
gains it, swap the constant in and delete the note. **Do not** re-justify the
basket with the "main redrew the glyphs" claim — delete
`2b_build_ui.md:105-121` or strike the claim, so the next iteration does not
re-open it.

*(Not a P09 defect, for the record: Bed, Hoover and Bins also miss the design
glyphs — `ic_bed.svg` adds a headboard arc, `ic_bin.svg` is a wheelie bin — and
`core/` is off-limits to a screen agent. That part is correctly filed as
§4 and correctly blocks only the stage-5 verdict.)*

---

### 2. MAJOR — `?idea=` is still a dead query key: "+ Add" on an Ideas row opens a blank new quest

**Where:** `app/lib/features/quests/presentation/widgets/quest_library_body.dart:241-245`
and the contract in `app/lib/features/quests/quests_routes.dart:19-36`.

**Why it is wrong.** P10's Ideas tab pushes
`/quest-editor?idea=<id>`; `QuestEditorView` reads only `?id=` and `?questId=`
(`quest_editor_view.dart:56-60`), so the tap lands on the editor pre-filled with
the **default template** — `Hoover the stairs`, the hoover tile, 15 coins,
Weekly + Saturday — rather than the idea the parent chose. Saving then creates a
quest unrelated to the row that was tapped. That is a wrong-result write on a
parent-facing screen, not a cosmetic gap.

Iteration 1 filed this as a minor (finding 12); the deferral has now expired.
The stale comment still says *"TODO(P10): P09 does not read a `?idea=` yet"* —
P09 exists, this diff even changed the **sibling** row three lines above
(`quest_library_body.dart:202`, now `?id=`), so the file contradicts itself and
the ownership has fallen between two screens. Both files are inside
`features/quests/**`, i.e. inside RULES §1, and the data is already available:
`QuestsRepository.ideas()` (`data/quests_repository_impl.dart:47`) returns the
templates with title, icon and suggested coins.

**Fix.**

1. `quests_routes.dart` — add to `QuestsEditorQuery`:
   `static const String ideaId = 'idea';` with the doc comment the other two keys
   carry.
2. `quest_editor_view.dart` — read it next to `_questIdOf`; when there is no
   `?id=` but there is an `?idea=`, seed the sheet from
   `GetIt.instance<QuestsRepository>().ideas()` (title, `icon`, `coins`,
   `repeatRule`, `needsApproval`) instead of `_defaultTitle` / `_defaultIcon` /
   `15` — i.e. pass an `initialQuest` built from the template with a fresh id,
   and keep the mode so no `QuestsUpdateRequested` is dispatched (the template
   is not a row).
3. `quest_library_body.dart:242` — delete the `TODO(P10)` comment (the key is
   read) and update it to name `QuestsEditorQuery.ideaId`.
4. Test: add to `quest_editor_view_test.dart` — `/quest-editor?idea=idea-bed`
   shows `Make your bed`, 5 coins, `= 5p at payout`, the Bed tile selected, and
   saving persists a **new** row (not an update of `idea-bed`).

P10's existing assertions (`quest_library_a11y_actions_test.dart:236,263`) pin
the push side and need no change.

---

### 3. MINOR — `Tooltip(message: 'Back')` on Cancel is product code serving a test harness

`quest_editor_view.dart:645-648`.

Carried from iteration 1 (finding 3). The P09 design has no AppBar, so the
tooltip was added to satisfy `WidgetTester.pageBack()`, which resolves
`find.byTooltip('Back')`, for seven P10 tests. VoiceOver impact is smaller than
iteration 1 assumed (`excludeSemantics: true` on the `Semantics` node drops the
tooltip from the announcement, and the 25-label set-equality test passes), but
the coupling is still real: a future library back button on screen together
with a non-offstage editor makes `pageBack()` find two and throw.

**Fix.** Delete the `Tooltip` and convert the P10 sites to
`await tester.binding.handlePopRoute()` — the idiom `today_view_test.dart` and
`p08_bugs_test.dart` already use. Those files are `quest_library_*_test.dart` /
`p10_bugs_test.dart`, so this needs the same "another file of the feature"
authorisation the iteration-1 builders already used for `quest_library_*`.
Cheaper alternative: keep the tooltip and add one P09 test pinning exactly one
`find.byTooltip('Back')`.

---

### 4. MINOR (perf) — every keystroke rebuilds the whole sheet

`quest_editor_view.dart:595` — `onChanged: (_) => setState(() {})`.

The only reason it exists is to recompute `_canSave`, so typing a 20-character
quest name rebuilds the six icon tiles, three person pills, the two
`LayoutBuilder`s, three cards, the segmented control and the seven day cells per
character. Carried from iteration 1 (finding 8), deliberately deferred.

**Fix.** Wrap only `QuestSavePill` in
`ValueListenableBuilder<TextEditingValue>` over `_title` and compute `_canSave`
from `value.text` plus the day set; drop the `setState` from `onChanged`.

---

### 5. MINOR (perf/robustness) — roster subscription rebuilds unconditionally; coin-value stream has no `onError`

`quest_editor_view.dart:394-412`.

`_childrenSubscription` calls `setState` on **every** `watchChildren()`
emission, even when the list is unchanged (the coin-value listener two lines
below correctly compares first — `pence == _pencePerCoin`). Any `children` table
write anywhere rebuilds the form. Neither subscription has an `onError`, so a
stream error becomes an unhandled async error and `_pencePerCoin` silently
stays at 1.

**Fix.** Guard the roster with the same value check (`listEquals(children, _children)`),
and add `onError: (_) {}` (or set a documented fallback) to both subscriptions.

---

### 6. MINOR (a11y) — the Due-by row announces no value

`quest_editor_view.dart:903-907` with `app/lib/core/design_system/components/nest_card.dart:63-70`.

`NestCard` sets `excludeSemantics: semanticLabel != null`, so passing
`semanticLabel: 'Change due time'` **drops** the row's own text from the
accessibility tree: a VoiceOver/TalkBack user hears "Change due time, button"
and never learns that the current due time is "Before tea (5pm)". Every other
value on this screen (coin count, approval title) is announced.

**Fix.** Put the value in the label and let the builder track it:
`semanticLabel: 'Due by, $_dueLabel'` (the sheet still announces each option's
own label). One line; the rebuild on change already happens via `setState`.

---

### 7. MINOR (test) — the copy audit pins the glyph the design does not print

`app/test/features/quests/quest_editor_copy_test.dart:85` — `'-', // .stepper buttons`.

`kGlyphs` is used for the "the screen invents no copy" set equality, so the test
currently **requires** the ASCII hyphen inside a shared control whose design
character is U+2212. `3_test.md` (P09-TEST-1) and `SHARED_REQUEST.md` §5 both
record it; the risk is that the pinning test makes the later fix look like a
test failure.

**Fix.** Nothing now, but keep the entry and the §5 note in the same commit that
flips `nest_stepper.dart` to `'−'` (as §5 already instructs). Do not delete the
entry without replacing it.

---

### 8. MINOR (docs) — two stage notes contradict the sources and will send the next builder after the wrong thing

* `5_ui.md:56`: *"Copy … matching the HTML source character-for-character (curly
  ’ in `Who's`)"*. The HTML prints a **straight** apostrophe — `hexdump` of
  `design/html-source/screens/P09-quest-editor.html` line 37 is
  `61 73 73 3d 22 6c 62 6c 22 3e 57 68 6f 27 73` → `Who's`, U+0027 — and the
  code (`quest_editor_view.dart:601`) is correct. Iteration 1's finding 13 fixed
  the same sentence in `2b_build_ui.md`; the UI note reintroduced it.
* `2b_build_ui.md:105-121` claims two DS glyphs were redrawn on `main` after the
  merge. Disproved by git and by the asset bytes (see finding 1).
* `5_ui.md:56` also says the icons are "the design order" while the same
  document's deviation 1 reports 4 of 6 glyph MAEs 4.5–20.5 — accurate, but the
  two sentences sit close enough to be read as "icons are done".

**Fix.** Correct the apostrophe sentence; strike the redraw claim in
`2b_build_ui.md`; keep the rest (the measured numbers are good).

---

### 9. MINOR (process, carried) — two P08 test files are edited outside RULES §1

`app/test/features/today/today_view_test.dart`, `app/test/features/today/p08_bugs_test.dart`
(+22/−5 lines in this diff: `pushedPath` / `_pushedUri` / `find.byType(QuestEditorView,
skipOffstage: false)` replacing the `find.text('P09 Quest editor')` placeholder anchor).

Deliberate and pre-authorised — `SHARED_REQUEST.md` §3 cites
`docs/screens/_shared/router_push_test_fix_REPORT.md` §4/§5 and
`shared_batch4.md` item 4. No P08 assertion was weakened or deleted, and
`flutter test test/features/today/` is green (110 pass) against the new anchor.

**Fix.** none here — the orchestrator must land these two files with the P09
merge.

---

### 10. MINOR — a parent-facing toast can carry a Dart error string

`quests_bloc.dart:55-61, 78-84, 101-107` + `quest_editor_view.dart:113-121`.

`editorError: error.toString()` reaches `showNestToast`. Unreachable from the
editor today (the view clamps before writing, `quest_editor_view.dart:478`), but
if the guard is ever bypassed the parent sees
`Invalid argument (coins): 9999: Quest coins must be 1..100` in a toast on a
parent screen.

**Fix.** Map the failure to parent-safe copy at the bloc boundary
(`'Could not save the quest. Try again.'`) and log `error` — the same treatment
a `Children's Code`-adjacent app would want for any unhandled failure.

---

## What was checked and found correct

* **Design geometry, verified independently (not from the builders' tables).**
  I measured `design/screens/light/P09-quest-editor.png` directly (÷3): the
  Save pill is `296 / 80 / 74 / 44`; the six `.ic` tiles have their border
  strokes at x = 20, 81, 142, 204, 265, 326 — i.e. `20 + i·61.2`, each **44** wide
  (pitch 61 = `space-between` over 350); gutters are exactly 20 on both sides
  (last tile ends 369.67). That confirms two things at once: the code's
  `NestDevice.tapParent` tiles and `space-between` row are right, and
  `DESIGN_SPEC.md` §5 P09's prose "6 SVG icons in **48px** tiles" is stale — the
  PNG and the CSS (`.ic{width:44px;height:44px}`) are both 44. Every figure in
  `quest_editor_view_geometry_test.dart`'s header table (grabber 175/59/40/5,
  input 20/156/350/52, segmented 20/480/350/52, approval card 20/600/350/72,
  due card 20/684/350/88, paper at y 843) matches the HTML/CSS arithmetic, and
  the suite pins them with the bundled Inter/Nunito `FontLoader`.
* **Design system, no hard-coding.** No colour literal in the diff (`Colors.transparent`
  only); every colour through `context.nest`; every gap through `NestSpacing` /
  `NestDevice` / `NestRadii`; every text style through `NestType`. The six
  screen-local numbers (`iconTileRadius` 14, `hairline` 1.5, `savePadding` 18,
  `saveMinWidth` 64, `cancelPadding` 6, `dueRowMinHeight` 56) live in
  `QuestEditorMetrics` with their CSS source quoted — the `NestPager` precedent.
  Shared components reused, none re-implemented: `NestTextField`, `NestCard`,
  `NestStepper`, `NestSegmented`, `NestDayPicker`, `NestToggle`, `NestAvatar`,
  `NestIcon`, `NestButton`, `NestModal`, `NestBottomSheet`, `NestToast`,
  `NestStatusBar`. The `.person` padding arithmetic checks out against the CSS
  (`4+1.5` left, `12+2+1.5` right = CSS `4`/`14` + the 1.5 hairline that
  `Material.shape` paints outside the child). No `letter-spacing` anywhere (P09's
  CSS sets none), no `text-wrap: balance` heading (none in the CSS, so
  `NestBalancedText` is correctly absent), no `NestChip` row (so `NestChipWrap` is
  correctly absent), no Pip on this screen.
* **Copy, character by character against the HTML.** `Cancel`, `New quest`,
  `Save`, `Quest name`, `Hoover the stairs`, `Icon`, `Who's it for?`
  (U+0027, confirmed by hexdump of both files), `Anyone`, `Reward`,
  `= 15p at payout`, `Repeats`, `Once`/`Daily`/`Weekly`, `M T W T F S S`,
  `Needs my approval`, `Coins land after your thumbs-up` (U+002D, asserted
  against `’`/`–`), `Due by`, `Before tea (5pm) ›` (U+203A, bytes `e2 80 ba`).
  Every other visible string (`Edit quest`, `Delete quest`, the confirm modal,
  `Quest not found`, `Pick at least one day`, the three due-sheet rows) is
  screen-local and enumerated in `quest_editor_copy_test.dart`'s
  `kScreenLocalCopy` with the plan section that sanctions it. UK spelling
  throughout ("colours" in comments, no US spellings in copy).
* **Icon order and labels.** `Bed, Dishes, Hoover, Book, Bins, Paw` matches the
  HTML's six `aria-label`s and their order, with Hoover (3rd) selected — the
  design's `aria-checked="true"` is also on the 3rd.
* **Architecture.** Feature-first intact: only `presentation/**`, the feature's
  own `domain/` + `data/` and its `quests_routes.dart` changed; one bloc per
  feature with three editor events added; `editorStatus` kept orthogonal to
  `status` so `emit.forEach` on `watchItems()` is untouched and no reload event
  was introduced; `/quest-editor` maps to `QuestEditorView` + `QuestsBloc` exactly
  as `ARCHITECTURE.md`'s route table says. The one cross-feature read the editor
  adds (`FamilyRepository.watchChildren()`) is read-only and plan-sanctioned, and
  `QuestsRepository.watchCoinValuePencePerCoin()` follows an existing precedent
  for a feature repo reading the `families` row
  (`today_repository_impl.dart:110 watchPayoutDay`, same
  `watchSingleOrNull().map(... ?? default)` shape) — so the coins-rate read is
  not a layering violation, just a slightly odd home for it.
* **Accessibility.** Every screen-local tappable passes `onTap:` on its own
  `Semantics` node alongside the `InkWell`, with `excludeSemantics: true` on the
  same node: `QuestCancelButton`, `QuestSavePill`, `QuestIconTile`,
  `QuestPersonPill`, `QuestDueOptionRow`, plus the due `NestCard`
  (`semanticLabel` + `onTap`). `QuestSavePill` reports `enabled: false` and drops
  the action when disabled — now also while a write is in flight. `Semantics(header: true)`
  on the screen title and the three group labels; the icon row is a `container`
  named `Quest icon`, matching the HTML's `role="radiogroup" aria-label`. The
  25-label set-equality test and the "every control node exposes tap or reports
  disabled" sweep both pass. Tap targets: Cancel 44, Save 44 (min), tiles 44,
  pills 48, day cells 44, stepper 44, toggle hit box 44, due row 56, sheet rows
  44, Delete 52.
* **Children's Code.** `/quest-editor` is in the router's `parentOnly` list
  (`app/lib/app/router.dart:88`); kid mode is redirected to `/parental-gate`
  (proven by a test). No analytics, no ads, no network, no child data leaving
  the device — the screen reads the family's own children and writes only to
  `quests`. No `subscription_status` written anywhere (not a screen that touches
  it).
* **Error handling.** Save/update/delete failures surface a toast, keep the
  editor on screen, leave the Drift row untouched and re-enable the pill via
  `clearSaveGuard()`; the route-level load failure offers `Try again` that really
  re-subscribes (the `_closeOnError` transformer, pre-existing).
* **Performance / lifecycle.** `buildWhen: previous.status != current.status`
  stops `watchItems()` re-emissions from rebuilding ~50 widgets; subscriptions
  are `late` fields created once in `initState` and cancelled in `dispose`, as is
  `_title`; `const` is used wherever it compiles; the sheet's
  `minHeight: constraints.maxHeight` keeps paper to the physical bottom edge
  while still scrolling in edit mode. Open items are findings 4 and 5.
* **Bottom edge and alignment.** The sheet is a `tokens.paper` container with
  `NestRadii.topXl` and `minHeight = viewport`, inside a `tokens.surface2`
  backdrop — no coloured strip can appear under the sheet in either theme, and
  the geometry test samples the last physical row. Gutters are `NestSpacing.padSide`
  (20) on every row; the icon row is `space-between` and the person pills
  `Wrap`, so nothing is a few px off at 390, 320 or 430.

---

## LEFT FOR THE LOOP

1. **Finding 1** — one-line revert of the Dishes tile (plus deleting the false
   "main redrew the glyphs" claim so it is not re-litigated). Nothing else is
   needed for it; §4 stays filed for the three glyphs only a `core/` agent can
   draw.
2. **Finding 2** — implement `?idea=` in `quests_routes.dart` + the editor,
   delete the stale `TODO(P10)` in `quest_library_body.dart`, add the test.
3. **Findings 3, 4, 5, 6** — cheap in-screen cleanups; 3 needs the same
   cross-file authorisation this branch already used.
4. **Findings 7, 8** — doc/test-annotation corrections; flip the hyphen entry in
   the same commit that fixes `NestStepper`.
5. **Finding 9** — must travel on the merge, not be reverted.
6. No simulator was used in this stage; stage 5 owns the ±2 px verdict and can
   lean on `quest_editor_view_geometry_test.dart` (compare bands, not
   absolutes, if the device status bar is taller than 47 px).

## Process note (not findings)

While this review ran, another stage was writing in this same worktree. Its
uncommitted files are the loop's business and are **not** reported as findings,
but three of them will matter when the loop commits:

* scratch diagnostic probe files written into `app/test/features/quests/`
  during this review (`_diag2_test.dart`, later `zz_debug_probe_test.dart`) —
  **must not be committed**; they are untracked and would run in `flutter test`.
* `app/test/features/quests/quest_editor_coin_rules_test.dart` — currently has
  two analyzer issues (`unused_local_variable` at :242, missing newline at EOF at
  :259), which would turn the `flutter analyze` gate red if committed as-is.
  HEAD itself is clean (verified above).
* `p09_bugs_test.dart`, `quest_editor_states_test.dart`, `SHARED_REQUEST.md` and
  `5_ui.md` are mid-edit — re-check finding 1 and finding 8's doc corrections
  against whatever that stage finally writes.

VERDICT: FAIL