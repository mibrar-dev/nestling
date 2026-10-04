# Fix list after iteration 2

## From 3_test.md
# P09 — stage 3 · TEST (iteration 2)

Scope: `app/test/features/quests/**` only. No screen code, no shared code and
no `tools/` touched; `flutter clean` never run; no simulator booted, installed
on, screenshotted or driven; no `skip:` added, no test weakened, no
`analysis_options.yaml` change; `google_fonts` appears nowhere.

Iteration 1's 56 tests are still here and still pass against the iteration-2
tree (`5c25db1`), which is itself worth recording: the fixes landed without
breaking a single assertion from the previous round.

## 1. What iteration 2 changed, and what this stage adds

Stage 2 (`2_build.md`) fixed the iteration-1 findings. A test stage's job
after a fix round is to prove the *fix*, not the symptom the bug hunt
reported — so every test below targets the mechanism, and none of them repeats
a stage-6 proof.

| Fix | Where it lives | What this stage proves (beyond `p09_bugs_test.dart`) |
|---|---|---|
| BUG-P09-1 rate from the database | `watchCoinValuePencePerCoin()` + `_pencePerCoin` field | 5p and 2p families; a **live** rate change while the form is open; the rate never scales the coin count; the stored value stays in coins, not pence |
| BUG-P09-2 save guard | `_saving` + `QuestSavePill(onPressed: _canSave && !_saving)` + `clearSaveGuard()` | the pill goes dead **while the write is in flight**; three taps dispatch **one** write; a **failed** write releases the guard so a retry reaches the repository again |
| BUG-P09-3 icon aliases | `_questIcons.aliases` | all six legacy keys map to the right tile and light **exactly one**; the stored key survives a save that did not tap a tile; tapping a *different* tile still rewrites it; the six tiles draw the design glyphs in design order |
| BUG-P09-4 coin bounds | `_coinFloor` / `_coinCeiling` + `_save` clamp | 9999 opens as 9999 and **writes nothing**; `−` walks it back; a 0-coin row shows 0 with `−` inert (no InkWell handler *and* no tap action) and `+` climbing to 1; an in-range row is never rewritten |
| BUG-P09-5 orphan assignee | `_isKnownAssignee` fallback | the dangling id shows as **Anyone**, exactly one pill active, and **Save clears the id**; a *listed* assignee is never hijacked by the fallback |
| review 9 archived rows | `active: initialQuest?.active ?? true` | editing an archived quest changes its title but leaves `active: false`; a new quest is stored active |
| review 5 `detail` | view no longer writes a copy | after changing coins and repeat, the stored `detail` is the repository's recomputation (`Once · 21 coins`) |
| review 11 roster | one `initState` subscription | the roster is **live**: a child inserted on another screen appears, last, in creation order — a latched snapshot would fail here |

## 2. Tests added this iteration (31)

| File | Before → after | New tests |
|---|---|---|
| `quest_editor_coin_rules_test.dart` (**new**) | — → 9 | 5 rate + 4 coin-range |
| `quest_editor_data_integrity_test.dart` (**new**) | — → 18 | 9 icon-alias/glyph, 5 assignee, 4 archived/detail/days |
| `quest_editor_states_test.dart` | 17 → 20 | 3 save-guard (the `_FaultyRepository` grew a `holdWrites` mode) |
| `quest_editor_bloc_test.dart` | 6 → 7 | 1 bloc path: the repository's coin contract surfacing as `editorStatus.failure` |

Nothing else moved. The three fault-injection groups from iteration 1
(`holdGet`, `failFirstWatch`, `failWrites`) are unchanged; `holdWrites` was
added beside them.

### 2.1 `quest_editor_coin_rules_test.dart`

`Seed.demo()` sets the rate to 1, so the seeded screen looks right whether or
not the helper reads the database — the whole bug class is invisible until the
family's row says otherwise, so each test writes `families` (or a corrupt
quest row) straight into Drift. Corrupt rows have to bypass the repository:
`QuestsRepositoryImpl._checkCoins` now rejects out-of-range coins on write *by
design*, which is exactly why the row has to be planted below the data layer.

- 5p/coin → `= 75p at payout` for 15 coins (and no `= 15p` anywhere).
- A rate change **while the editor is open** (write `families`, pump) → the
  helper follows: `= 60p at payout`. This is the stream path; a value latched
  in `build` would fail here.
- The rate never scales the stepper: the value stays `15`, the helper becomes
  `= 60p`.
- The rate multiplies after a stepper move: 16 coins at 2p → `= 32p at payout`.
- Saving stores **coins**, not pence (15 coins at 5p → row `coins == 15`).
- 9999 opens as `9999` / `= 9999p at payout` and the row is still 9999 after
  the open (no write).
- `−` walks 9999 → 9998 with the helper following.
- 0 opens as `0` / `= 0p at payout`, `−` is inert for the finger (no InkWell
  handler) *and* for VoiceOver (no `SemanticsAction.tap`), `+` climbs to 1.
- An in-range row (20 coins) survives open → Save unchanged.

### 2.2 `quest_editor_data_integrity_test.dart`

One test per legacy icon key (`sofa`→Bed, `plate`→Dishes, `bins`/`shirt`/`bag`
→Bins, `leaf`→Paw), each asserting the mapped tile is selected **and** that
exactly one tile is selected — a radiogroup with two highlighted tiles is
worse than none. Plus: the stored key survives a save without a tap; a tap on a
*different* tile rewrites it; the six tiles' `label` and `icon` match the
design's order and glyphs (`NestIcons.dishwasher` for Dishes today —
`questDishes` once the finding-3 icon switch lands — per 2b's
ORCHESTRATOR_NOTES 17:57 item 1 answer).

Assignee: a dangling `assigneeChildId` (no FK column, so the id really can
survive a deleted child) shows as Anyone, exactly one pill active, and Save
stores `null`; a listed assignee (`leo`) is untouched by the fallback, so the
fix cannot over-fire; a new quest still defaults to Maya (creation order, never
alphabetical); and the roster subscription is **live** — inserting
`Annabella` while the form is open appends her pill before Anyone.

Archived/detail: an archived quest (`active: false`) can be edited without
being resurrected; a new quest is stored active; `detail` is the repository's
recomputation; switching a weekly quest to Once clears the stored day CSV.

### 2.3 Save guard (in `quest_editor_states_test.dart`)

`_FaultyRepository.holdWrites` parks each write on a `Completer` the test
releases, which is the editor's in-flight state:

- **pill dead while in flight**: `onPressed == null`, one dispatch, no
  navigation; release → `/quests`.
- **three taps, one dispatch**: `written.length == 1`, and after the release
  exactly one row titled `Hoover the stairs` exists.
- **a failed write releases the guard**: `clearSaveGuard()` runs before the
  toast, so the pill is live again and a second tap reaches the repository
  (`written.length == 2`). Without that release the editor would be stuck with
  a dead Save and no way out — the failure mode this test exists for.

### 2.4 One more bloc path

`quest_editor_bloc_test.dart`: a repository that throws
`ArgumentError.value(9999, 'coins', 'Quest coins must be 1..100')` must surface
as `editorStatus.failure` + an `editorError` containing the message. The view
clamps before dispatching, so this is the last line of defence — and it is the
only new wiring the iteration-2 interface addition introduced.

## 3. Results

```
$ dart format --set-exit-if-changed .
Formatted 494 files (0 changed) in 3.94 seconds.          (exit 0)

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.7s)

$ flutter test test/features/quests/
00:52 +367 ~5: All tests passed!

$ flutter test
04:25 +2562 ~6: All tests passed!
```

The `~6` skips are stage 6's parked bug proofs (BUG-P09-6/7/8 in
`p09_bugs_test.dart`, `skip: true` until their fix lands) plus the
pre-existing repo skip in `test/features/pocket_money/p12_bugs_test.dart:320`.
Nothing this stage skips.

Process note, not a finding: at 18:52 one feature run reported
`p09_bugs_test.dart BUG-P09-1` red while stage 6 was rewriting that file
(its mtime moved under the run). Re-run afterwards: green. The loop owns merge
and file ordering.

## 4. Bugs found

### P09-TEST-2 — major — an emoji-leading nickname crashes the editor

- File: `app/lib/features/quests/presentation/views/quest_editor_view.dart:738-739`
  ```dart
  static String _initial(String nickname) {
    return nickname.isEmpty ? '?' : nickname.substring(0, 1).toUpperCase();
  }
  ```
  `substring(0, 1)` splits the surrogate pair of an astral-plane first
  character, so the pill is painted with a lone surrogate.
- Repro: any child whose nickname starts with an emoji (`😀 Sam`). Insert such
  a row into `children` (`nickname: '😀 Sam'`), open `/quest-editor`, and the
  screen throws while painting the assignee pill. Measured in a throwaway probe
  on the current tree: `ArgumentError: Invalid argument(s): string is not
  well-formed UTF-16`. The whole screen fails to render — no form, no error
  state, nothing recoverable but a restart.
- Reachability: P05 allows any non-empty nickname up to 24 UTF-16 units, emoji
  included, so a parent can create this row from the app itself.
- Status: stage 6 filed the same defect concurrently as **BUG-P09-8** (proof
  `p09_bugs_test.dart:336`, `skip: true`); my probe was an independent
  reproduction, not a second report. The fix is the first grapheme
  (`characters.first`, or guard the code-unit length) — I did not patch it.
- **This is why the stage verdict is FAIL.**

### P09-TEST-1 — carried over from iteration 1 (still open)

The shared `NestStepper` renders its minus as U+002D while both designs print
U+2212 (`nest_stepper.dart:32`; `SHARED_REQUEST.md` §5, advisory, unresolved
on `main`). `quest_editor_copy_test.dart` still excludes the glyph from its
set-equality audit and says so in the file header, so the audit stays green
while the request is open.

### Constrained by stage 6's open findings (deliberate, not a bug in my tests)

Stage 6 filed **BUG-P09-6** (an out-of-range reward is shown at face value —
`9999`, `= 9999p` — but silently clamped to 100 on save) against the same rows
my coin-range tests read. I removed the two assertions that pinned the clamp
so this suite does not break the moment the fix lands. What remains is what
survives either answer: *opening* the editor writes nothing, and the parent can
walk the value back into range with `−`/`+`. The save-time decision (store what
was shown, or block the save with a visible reason) belongs to
`p09_bugs_test.dart`. **BUG-P09-7** (tapping an alias-highlighted tile rewrites
the stored key) does not conflict with my tests: mine tap a *different* tile
and assert that still rewrites.

## 5. Notes for the next stages

- **Flip points when the fixes land:** `quest_editor_copy_test.dart` gains
  `−` in `kGlyphs` when `SHARED_REQUEST.md` §5 resolves;
  `p09_bugs_test.dart` un-skips BUG-P09-6/7/8; and if BUG-P09-6's fix changes
  what the editor *shows* for an out-of-range row, the display assertions in
  `quest_editor_coin_rules_test.dart` ('a 9999-coin quest opens showing 9999',
  'a 0-coin quest shows 0') move with it — they are the only two assertions
  that describe the current tree rather than an invariant.
- **Deliberately untested:** review finding 7 (`buildWhen` keeps the form from
  rebuilding on `items` emissions) is a performance property with no observable
  contract; a build-count probe would be brittle without proving anything a
  parent can see.
- **Observation, unreachable from the app's own navigation:**
  `QuestEditorView.didChangeDependencies` fetches `?id=` once
  (`if (_loadedQuest != null) return`), so navigating straight from
  `/quest-editor?id=a` to `/quest-editor?id=b` on the same `State` would keep
  showing quest `a`. Every in-app path pushes a new page instead, so this is
  not reachable today; it is noted so a future "switch to another quest from
  this screen" affordance does not inherit it silently.
- Every widget test here ends with `disposeApp(tester)`, and every semantics
  handle is disposed **inside** the test body.


## From 4_review.md
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


## From 5_ui.md
# P09 — 5_ui · UI check (iteration 2, stage 5)

Route `/quest-editor`, simulator 604697A9-11DA-462F-9837-396E9CA2493A (390×844).
Shots: `docs/screens/P09/ui/app_light_2.png`, `app_dark_2.png` (seed demo,
parent, maya, `DISABLE_ANIMATIONS=1`). Compare sheets: `cmp_light_2.png`,
`cmp_dark_2.png`. All px below are logical (design px ÷ 3). Status-bar glyphs
excluded per orchestrator STATUS BAR rule. Mandatory orchestrator items from
`ORCHESTRATOR_NOTES.md` (17:57 QA) are checked as items (a) and (b) below.
No Pip on this screen; no `NestChip` rows, no `text-wrap: balance`, no
`letter-spacing` (all correctly absent).

## Mean diff

- Light: **1.79 %** (bands 0–7: 1.66 / 1.31 / 1.49 / 1.64 / 0.65 / 2.39 /
  2.13 / 2.99; iter1 was 1.71 %).
- Dark: **1.62 %** (bands: 1.65 / 1.32 / 1.37 / 1.58 / 0.70 / 2.46 / 2.13 /
  1.71; iter1 was 1.60 %).
- Band-7 light delta (+0.67) is the OS home-indicator pill rendering darker
  in this capture plus due-card shadow softness at y ≈ 772 (app paper
  251,247,240 vs design shadow greys 232,228,225 on that single row). The
  home zone itself is paper in both (sampled y = 830 at x = 20/195/370:
  identical), so the OWNER bottom-edge rule still passes in both themes.

## Measured y (design vs app, logical px, top edge)

Best-fit uniform vertical shift over y 60–800 is **dy = 0 px** — no uniform
shift. Centre-scanline edges (x = 195), design → app:

| Element | Design y | App y | Δ |
|---|---|---|---|
| Grabber (40×5) | 58.7–63.7 | 58.7–63.7 | 0 |
| Screen title `New quest` (text peaks) | 100.3 / 106.6 | 100.3 / 106.6 | 0 |
| First control: `Cancel` box / Save pill | 90 / 80–124 | 90 / 80–124 | 0 |
| `Quest name` label | 136.8 | 136.8 | 0 |
| Name input (52 high) | 156.2 | 156.2 | 0 |
| `Icon` label | 207.2 | 207.2 | 0 |
| Icon tiles (6× 44×44) | 232 | 232 | 0 |
| `Who's it for?` label | 276 | 276 | 0 |
| Person pills (48 high) | 300.8 | 301.0 | 0.2 |
| Reward card (inset, 76) | 363.7 | 363.7 | 0 |
| `Repeats` label | 461.0 | 461.0 | 0 |
| Segmented track (52) | 479.7 | 479.7 | 0 |
| Day row (44) | 540.2 | 540.7 | 0.5 |
| Approval card (72) | 599.7 | 599.7 | 0 |
| Due-by card (88) | 683.7 | 683.7 | 0 |
| Due-card bottom edge | 771.7 | 771.7 | 0 |

Shape check (background/border rects): Save pill, name field
(20/156/350/52), tiles at x 20/81/142/204/265/326, pills (anchored lefts
exact; right edges ≤ 2 wider from text shaping), segmented + Weekly thumb,
day cells (44.9 wide / 50.86 pitch, ≤ 0.9 cumulative), stepper, toggle track
(303/620.5 → 354), both cards — all Δ ≤ 2 px, nearly all 0. Gutters exactly
20 (card edges 19.7 → 369.7, both images, both themes). No overflow,
clipping, or ellipsis faults. Child order Maya → Leo → Anyone (correct).
Copy unchanged from iter1 and matching the HTML source character-for-
character (curly ’ in `Who's`, `Before tea (5pm) ›` with U+203A).

## Deviations

1. (BLOCKER — icon choice; orchestrator 17:57 item (a)) 4 of 6 icon-picker
   glyphs are visibly different line-art from the design, light AND dark
   (tile geometry correct; only glyph strokes differ). Whole-tile MAE vs
   design: tile 0 Bed 4.5, tile 1 Dishes 17.5, tile 2 Hoover 20.5,
   tile 3 Book 4.1 (match), tile 4 Bins 17.3, tile 5 Paw 1.9 (match).
   - Tile 0 `Bed`: design flat mattress/bed-frame side view; app
     `NestIcons.bed` = lidded chest/box.
   - Tile 1 `Dishes`: design handled basket; app now `NestIcons.basket`
     (tapered slatted basket, substituted in the iter-2 build for
     `NestIcons.dishwasher`). The substitution violates the mandatory
     orchestrator instruction ("write SHARED_REQUEST … rather than
     substituting a look-alike"): the basket is visibly a different
     drawing (plain body + arch handle vs slats + side handles, MAE 17.5)
     and must be replaced with the exact design glyph, not kept.
   - Tile 2 `Hoover` (selected): design canister vacuum + hose + wheels;
     app `NestIcons.hoover` = hook/whistle-like loop.
   - Tile 4 `Bins`: design small handled case/clasp; app `NestIcons.bin` =
     rimmed trash bin.
   - Design value: exact SVGs in `design/html-source/screens/P09-quest-
     editor.html` (copied verbatim into `SHARED_REQUEST.md` §4).
   - App value: the `NestIcons` glyphs listed above.
   - Fix (shared, `core/` off-limits here): draw the four exact design
     glyphs as DS icons/assets; screen mapping stays as-is (order Bed,
     Dishes, Hoover, Book, Bins, Paw is already the design order).
     `SHARED_REQUEST.md` §4 updated with exact names + SVG sources; blocks
     PASS until the DS glyphs land on main and are merged back.

2. (Shared-cause advisory — field text x; orchestrator 17:57 item (b),
   filed as `SHARED_REQUEST.md` §6, non-blocking) `Hoover the stairs` ink
   starts at x ≈ **41.7** in the app vs **38.3** in the design (leftmost
   dark pixel, field-text band y 168–200; same y-top 176.3). Design
   arithmetic: field x 20 + 1 px border + 16 px padding = 37 (+ `H` side
   bearing ≈ 38.3 measured). The field BOX is exact (20/156/350/52, edges
   19.7 → 369.7) and the screen passes no padding to `NestTextField`
   (plain label + controller, `quest_editor_view.dart:592-596`): the ~3.4 px
   excess is the shared default variant's uncancelled editable inset
   (`contentPadding: horizontal s4` without `isDense`,
   `nest_text_field.dart:303-306`; the search variant in the same file
   cancels it with `left: -4`). Invisible without pixel measurement — a
   designer would not reject it — so it stays advisory per §6; recorded
   here because the orchestrator asked for the numbers.

No other deviations. Explicitly not findings: status-bar time/glyphs and
home-indicator pill rendering (OS regions), pill right-edge +0.5–1.5 px
and day-cell 44.9 vs 44 (anchored edges exact, inside ±2 px), text-edge
diff heat (antialiasing; block edges ≤ 2 px), due-card shadow-softness row
at y ≈ 772 (single-row painting residue, no layout effect).


## From 6_bugs.md
# P09 — stage 6 · FIND BUGS (iteration 2)

Tree: `5c25db1` (“P09: checkpoint after build (iteration 2)”) + the new proofs
below. No screen code was changed — the brief forbids fixing here.

Adversarial area sweep (iteration 2): the five iteration-1 bugs re-verified,
then new probes over the changed code — data edge cases (0 / 1 / 6 children,
emoji-leading and long UK names, £0.00 / £999.99 / 9999 coins), rapid double
taps on every popping control, back navigation and deep links, Drift restart
persistence, the parent/kid guard (with query strings), dark-mode contrast,
320 dp × text scale 1.3, async gaps, Europe/London wall-clock storage and
integer-pence money.

All proofs live in `app/test/features/quests/p09_bugs_test.dart`. Iteration-2
bug proofs are `skip: true` (bug id in the group name) so the suite stays
green; run them with `--run-skipped` to see them fail. Every probe in the
“attacks that hold” group runs unskipped.

## Iteration-1 findings — all FIXED, proofs unskipped and green

| id | what was wrong | iteration-2 fix (where) |
|---|---|---|
| BUG-P09-1 | payout helper hard-coded 1p/coin | view streams `watchCoinValuePencePerCoin()` (`quests_repository_impl.dart:26`, view `:405`) |
| BUG-P09-2 | double-tap Save created the quest twice | local `_saving` guard + pill disabled while saving (`:362`, `:458-465`, `:663`) |
| BUG-P09-3 | non-picker icon showed no selected tile | `_questIcons.aliases` covers every seeded key (`:257-280`) |
| BUG-P09-4 | out-of-range coins unreachable after a tap | `_coinFloor`/`_coinCeiling` grow to the stored value (`:328-333`, `:787-792`) |
| BUG-P09-5 | removed child left an orphaned assignee | roster-unknown assignee falls back to `Anyone` (`:367-384`) |

All five proofs now run unskipped in the suite (5 of the 18 passing tests in
the file). No regression.

## Summary — iteration 2

| id | severity | one-liner | failing test (group › test) |
|---|---|---|---|
| BUG-P09-8 | **major** | an emoji-leading child nickname makes the editor throw `ArgumentError: string is not well-formed UTF-16` while painting the avatar (the screen fails to paint) | `BUG-P09-8 — an emoji-leading nickname breaks the avatar initial` › `the initial is the full first grapheme, not a lone surrogate` **and** `painting the lone surrogate throws a UTF-16 error` |
| BUG-P09-6 | minor | an out-of-range reward is shown at face value (9999 / `= 9999p`, or 0 / `= 0p`) but silently clamped on save (writes 100 / 1) | `BUG-P09-6 — an out-of-range reward is shown at face value, saved clamped` › `the screen says 9999 / 9999p and the write says 100` **and** `a 0-coin quest is shown as 0 / 0p and saved as 1` |
| BUG-P09-7 | minor | tapping the alias-highlighted tile (Dishes for `plate`) is visually a no-op but rewrites the stored icon key to the tile key | `BUG-P09-7 — tapping the alias-highlighted tile rewrites the stored key` › `q-table (plate) saves dishwasher after a no-op-looking tap` |

---

## BUG-P09-8 — major — an emoji-leading nickname breaks the editor paint

**Where:** `_initial` (`quest_editor_view.dart:738-740`) —
`nickname.substring(0, 1).toUpperCase()` — fed to `NestAvatar.initial`
(`:724`).

**Why it is wrong:** `String.substring` slices UTF-16 code units, not
graphemes. A nickname beginning with an astral-plane character (`😀`, flags,
most emoji) has a surrogate pair at index 0, so `substring(0, 1)` returns the
lone high surrogate. P05 accepts any non-empty nickname up to 24 UTF-16 units
(`family_bloc.dart:66-71`, no input formatter), so this is reachable from the
app’s own add-child flow. Flutter’s paragraph builder then rejects the
malformed string — the editor fails to paint:

```
ArgumentError: Invalid argument(s): string is not well-formed UTF-16
  at _NativeParagraphBuilder.addText
```

Not a font/rendering artifact: `addText` validates well-formedness, so it
throws in release too, not just debug.

**Repro:**
```dart
// child nickname '😀 Sam' inserted directly (P05's own rules allow it)
await pumpAppRoute(tester, QuestsRoutePaths.editor);
final avatars = tester.widgetList<NestAvatar>(find.byType(NestAvatar));
expect(avatars.last.initial, '😀');          // actual: lone surrogate '\uD83D'
expect(tester.takeException(), isNull);      // actual: ArgumentError above
```
Two skipped tests prove each half: the initial is `'\uD83D'` (renders `�`),
and the pump throws the UTF-16 `ArgumentError`.

**Suggested fix:** take the first grapheme, not the first code unit —
`nickname.characters.first.toUpperCase()` (`characters` is exported by
`package:flutter/foundation.dart`, already imported via Material), with the
existing `isEmpty → '?'` fallback. Add a unit test for `😀`, a flag emoji and
a combining-mark name.

## BUG-P09-6 — minor — out-of-range reward shown at face value, saved clamped

**Where:** `_save` writes `coins: _coins.clamp(_minCoins, _maxCoins)`
(`quest_editor_view.dart:478`) while the stepper and the helper render the
raw `_coins` (`:773`, `:784`).

**Why it is wrong:** the editor deliberately shows a corrupt stored value as
stored (BUG-P09-4 fix: the stepper can reach it), but the write silently
repairs it. The screen promises one number and stores another: a 9999-coin
quest shows `9999` and `= 9999p at payout`, and Save writes **100**; a
0-coin quest shows `0` / `= 0p` and writes **1**. The repository’s own
comment says a corrupt value should “fail loudly instead of being silently
rewritten” (`quests_repository_impl.dart:92-96`) — the view clamp means that
path is unreachable from the editor, and the parent is never told the reward
changed.

**Repro:** insert `coins: 9999` (or `0`), open `?id=…`, Save without touching
the reward; `getQuest` returns `100` (or `1`), while the screen showed the
original.

**Suggested fix:** make the mismatch impossible instead of silent — when
`_coins` is outside 1..100, disable Save and show a live-region caption (the
same pattern as `Pick at least one day`), e.g. `Coins must be 1–100`, so the
parent explicitly steps it into range; keep the widened stepper bounds so the
repair is always reachable. (Alternative: don’t clamp and let the repo’s
validation surface the toast — but then an untouched corrupt row cannot be
saved at all.)

## BUG-P09-7 — minor — tapping the alias-highlighted tile rewrites the key

**Where:** the tile call site (`quest_editor_view.dart:677-678`) —
`selected: selected == option.key || option.aliases.contains(selected)` with
`onTap: () => setState(() => _icon = option.key)`.

**Why it is wrong:** for a quest stored as `plate`, the Dishes tile is
highlighted through the alias, so it already looks selected; tapping it is
visually a no-op, yet it rewrites `_icon` to `dishwasher`. Save then stores
the normalised key and the library/today glyph changes — the parent cannot
see that their tap changed anything. Same for `bins`→`bin` (a seeded quest,
`q-bins`), `bag`/`shirt`→`bin`, `leaf`→`paw`, `sofa`→`bed`. A radio that is
already checked is normally inert.

**Repro:** open `?id=q-table` (icon `plate`); assert the Dishes tile is
selected; tap it; Save; `getQuest('q-table').icon` is `dishwasher`
(expected `plate`).

**Suggested fix:** ignore the tap when the tile is already the visual
selection — compute `isSelected` first and only `setState(_icon = option.key)`
when `!isSelected` — so an alias-highlighted tile keeps the stored key unless
the parent picks a *different* tile.

---

## Attacks that hold (probes, unskipped — 13 tests)

- **Rapid double taps:** double-tap `Delete quest` → one confirm modal;
  double-tap `Due by` → one option sheet; double-tap `Cancel`, a due-sheet
  row and `Keep it` never pops a second route (all swallowed by the
  route/modal transition). Double-tap **Save** is now guarded (iteration-1
  proof runs green).
- **Restart persistence:** save → dispose the app → new `NestlingApp` over
  the same Drift DB → the quest is on the library’s Active tab.
- **Parent/kid guard:** kid mode + `/quest-editor` (plain **and** with
  `?id=`) lands on `/parental-gate`; the editor never builds.
- **320 dp × text scale 1.3**, new and edit mode: no overflow/exception.
- **One-child family:** the new quest defaults to that child.
- **Six children with long names** (`Maximilian-Alexander`,
  `Annabella-Rose`, `Cassandra-Jane`, `Fitzwilliam`) at 320 × 1.3: pills wrap,
  creation order preserved, `Anyone` last.
- **Dark mode:** the Save pill’s `--surface` on `--leaf` pair keeps ≥ 4.5:1
  contrast.
- **Back navigation:** a quest pushed from Today (`?questId=`) → Cancel
  returns to `/today`.
- **Zone/BST:** with the family moved to `Asia/Dubai`, the due time is still
  stored as the wall-clock string `17:00` (`dueLabel` `Before tea (5pm)`).
- **A11y actions:** all three due-sheet rows expose `SemanticsAction.tap` and
  `performAction(tap)` moves the real due label (and the saved `HH:MM`);
  `Keep it` / `Delete` expose tap and `Keep it` keeps the Drift row.
- The 0-child / `Seed.empty`, unknown-id, blank-title and weekly-no-days edges
  stay covered by the existing feature suites (green).

## Verification

```
$ dart format --set-exit-if-changed test/features/quests/p09_bugs_test.dart
Formatted 1 file (0 changed)
$ flutter analyze test/features/quests/p09_bugs_test.dart
No issues found!
$ flutter test test/features/quests/p09_bugs_test.dart
00:29 +18 ~5: All tests passed!        # 13 probes + 5 fixed iteration-1 proofs
$ flutter test test/features/quests/p09_bugs_test.dart --run-skipped
00:12 +18 -5: Some tests failed        # the five iteration-2 proofs fail as documented
$ flutter test
01:48 +2563 ~6: All tests passed!      # whole app; ~6 = 5 new proofs + P12-BUG-05
```

No simulator was booted, installed on, screenshotted or driven; `flutter
clean` was never run; no `// ignore:` and no shared file was touched.

**Out of scope (process, not findings):** the worktree also carries other
stages’ uncommitted work (`quest_editor_coin_rules_test.dart`,
`quest_editor_data_integrity_test.dart`, `quest_editor_states_test.dart`,
`5_ui.md`, UI PNGs). It was left untouched; at the time of writing those
files’ two `flutter analyze` infos are theirs, not this stage’s.

