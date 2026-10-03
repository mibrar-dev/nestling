# P09 — stage 4 · QA code review (iteration 3)

Scope reviewed: `git diff main...HEAD` on branch `screen/P09` against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P09
(line 168), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html`, both design PNGs, and every
mandatory item in `docs/screens/P09/ORCHESTRATOR_NOTES.md` (17:14, 17:57,
19:19, 20:09).

`git merge-base main HEAD` = `7afc8ad` = `main`. **The branch is not behind
main** — batch 5 (`shared/shared_batch5`) is merged in and its changes are on
disk at HEAD. That matters for findings 1–3: nothing here is a merge-order or
process artefact, the screen simply has not absorbed the shared change that
landed under it.

No code was edited. Only this file was written. No simulator was booted,
installed on, screenshotted or driven; `flutter clean` was never run.

Because the loop may be writing in this worktree, every gate was run against an
isolated `git archive HEAD` export
(`/…/opencode/p09-clean`, and a second scratch copy `/…/opencode/p09-r3` used to
measure candidate fixes):

```
$ cd …/opencode/p09-clean/app && flutter analyze
No issues found! (ran in 6.8s)

$ flutter test                       # full suite at HEAD
02:32 +2583 ~1 -10: Some tests failed.        # the ~1 skip is main's P12-BUG-05

$ flutter test test/features/quests/
00:23 +368 -10: Some tests failed.
```

All 10 failures are in P09's own test files. Nothing outside
`features/quests/**` regressed (`test/features/today/` is green).

`git diff --stat -- app/lib/core app/lib/app tools` is empty;
`analysis_options.yaml` and `pubspec.yaml` are untouched; no `skip:`, no
`// ignore:`, no `google_fonts`/`GoogleFonts`, no `print`/`debugPrint`, no
`TODO(` left anywhere in the diff.

## Verdict summary

**One blocker and two majors. The blocker is the `flutter test` done-criteria
gate (RULES §7.1) — 10 of this screen's own tests are red at HEAD. Both majors
are the same missed hand-off: the shared batch-5 change landed on `main` and
`ORCHESTRATOR_NOTES.md` (20:09) explicitly instructed this branch to absorb it,
but neither the icon switch nor the removal of the two now-stale compensations
was done. VERDICT: FAIL.**

The screen is otherwise a careful, faithful build: no hard-coded colours,
sizes or fonts; shared components reused rather than re-implemented; copy
matches the HTML character for character; every screen-local tappable carries
`onTap:` on its own `Semantics` node; streams and controllers disposed; the
per-keystroke rebuild storm is gone; and the geometry test pins the design's
absolute rects against the bundled real fonts.

---

## Findings

### 1. BLOCKER — the `flutter test` gate is red: 10 failures, all in `test/features/quests/`

**Where:** `quest_editor_copy_test.dart:85`, `quest_editor_copy_test.dart:262`,
`quest_editor_a11y_test.dart:479-491`, `quest_editor_view_test.dart:612-625`,
`quest_editor_view_test.dart:778-782`, `quest_editor_robustness_test.dart:256-281`,
`quest_editor_view_geometry_test.dart:327-358`,
`quest_editor_data_integrity_test.dart:170`.

**Why it is a blocker.** `docs/screens/RULES.md` §7.1 makes
"`flutter test` → all pass" a hard done-criteria gate, and the failures are
behavioural, not cosmetic. Four independent causes:

**(a) The copy audit still pins the glyph batch 5 removed (3 failures).**
`quest_editor_copy_test.dart:85` reads `'-', // .stepper buttons` (U+002D).
Iteration 2's finding 7 said, in writing, to *"flip the hyphen entry in the same
commit that fixes `NestStepper`"* and *"do not delete the entry without
replacing it"*. `nest_stepper.dart:30-32` is now `label: '−'` (U+2212, with a
comment saying so). Result:

```
quest_editor_copy_test.dart:189  Expected: empty   Actual: Set:['−']  unlisted copy on screen
quest_editor_copy_test.dart:302  Expected: empty   Actual: Set:['−']
quest_editor_copy_test.dart      Expected: contains '-'
```

so `the screen invents no copy beyond the design`,
`every design string is on screen, character for character` and
`the stepper announces Decrease reward / Increase reward` all fail. **Fix:**
`quest_editor_copy_test.dart:85` → `'−', // .stepper buttons (U+2212, per §5)`.

**(b) Three tests read the toggle's semantics through the wrong node
(3 failures).** `NestToggle` now puts its `Semantics` *below* the new
`_ToggleHitSlop` hit-test proxy (`nest_toggle.dart:36-44`), so
`tester.getSemantics(find.byType(NestToggle))` walks **up** from the proxy and
returns the ancestor node — label `''`, `hasAction(tap)` false:

```
quest_editor_a11y_test.dart:480   Expected: 'Needs my approval'   Actual: ''
quest_editor_view_test.dart:779   Expected: true                  Actual: <false>
quest_editor_copy_test.dart:263   Expected: 'Needs my approval'   Actual: ''
```

This is a **test** problem, not an a11y regression: the `Semantics` node is
still in the tree, still labelled and still actionable, and
`shared_batch5_REPORT.md` says exactly this ("the outer hit-slop render carries
no semantics (the `NestChip` pattern)") and fixed P14's tests the same way.
**Fix:** address the node by label, e.g.
`tester.getSemantics(find.bySemanticsLabel('Needs my approval'))`, in
`quest_editor_a11y_test.dart:479/491`, `quest_editor_view_test.dart:778/782`
and `quest_editor_copy_test.dart:262`.

**(c) Two tests assert the toggle's old 59×44 box (3 failures).**
`quest_editor_robustness_test.dart:268` (`Expected >= 44, Actual 31`) and
`quest_editor_view_test.dart:620` (`Expected 44, Actual 31`) sweep
`getRect(find.byType(NestToggle))` as if it were the hit box. The box is now
the 51×31 track by design. **Fix:** drop the toggle from the ≥44 sweep, pin
`size == Size(51, 31)` instead, and keep a live proof that a tap **4 px** left
of / **7 px** above the track still flips it (the `::before` overhang), which is
how P14's `rewards_a11y_test.dart` handles it.

**(d) `quest_editor_data_integrity_test.dart:170`** pins the tile list as
`NestIcons.bed / dishwasher / hoover / book / bin / paw` — the pre-batch-5 list.
It passes today and must be updated **in the same commit as finding 2 below**,
or it will fail the moment the picker is switched.

*(Cause (a) and cause (b)/(c) survive finding 2: in the scratch copy, applying
finding 2's fix took the suite from 10 failures to 9, of which these 6 remain.)*

---

### 2. MAJOR — the approval card and its toggle now miss the design by 4 px / 2 px, because both batch-5 compensations are still in place

**Where:** `quest_editor_view.dart:969-974` (card bottom padding
`NestSpacing.s3`) and `quest_editor_view.dart:996-997`
(`Transform.translate(offset: QuestEditorMetrics.toggleTrackOffset)`);
`quest_editor_widgets.dart:35-49` (`toggleTrackOffset = Offset(4, -2)`).

**Why it is wrong.** Both lines exist only to compensate for the *old*
`NestToggle`, which was a 59×44 box with the 51×31 track centred inside it.
Batch 5 made the track the widget's own box (`nest_toggle.dart:12-16,52-53`)
and moved the 59×44 area into a non-layouting hit slop. `ORCHESTRATOR_NOTES.md`
(20:09) is explicit: *"delete the `toggleTrackOffset` Transform.translate, as
in `docs/screens/_shared/shared_batch5_REPORT.md` lines ~87-90 and ~209"* — and
that report's own follow-up list names this branch's two compensations. The
compensations now **double-count**:

* the card's bottom padding was shaved 16→12 to absorb the toggle's 44-high
  box; with a 31-high track the row is driven by the 40-high text block, so the
  card renders **68** where the design is **72**;
* the `Transform` now pushes the track **4 px past the content edge** and
  **2 px up**.

Measured, HEAD vs design (÷3, bundled Inter, light):

| element | design (PNG) | app at HEAD | Δ |
|---|---|---|---|
| `.card` approval | 20 / 600 / 350 / **72** | 20 / 600 / 350 / **68** | **−4 h** |
| `.toggle` track | **303** / **620.5** / 51 / 31 | **307** / **618.5** / 51 / 31 | **+4 x, −2 y** |

Design figures are my own pixel probe of
`design/screens/light/P09-quest-editor.png`, not the builders' table: at
`x = 300 px` the white card runs `y 1800 → 2016` px = logical `600.0 → 672.0`;
at `y = 1900 px` the leaf-green track runs `x 909 → 1061` px = logical
`303.0 → 353.7` and the card's white ends at `x 1110` = logical `370.0`, so the
track's right edge is flush with the content edge `370 − 16 = 354`. The
green-column centre at `x = 310` is `636.5`, giving a 31-high track centred on
`636` ⇒ `620.5 → 651.5`. Both deltas are outside the owner's ±2 px rule, so
stage 5 must fail this as it stands.

**Fix (two lines, and I verified both in the scratch export).** Delete
`quest_editor_view.dart:996-997` and restore the bottom padding:

```dart
padding: const EdgeInsets.fromLTRB(
  NestSpacing.s4,   // 16 — unchanged
  NestSpacing.s4,   // 16 — was s3, the compensation for the old 44-high box
  NestSpacing.s4,
),
```

With only those two edits the probe returns
`card = Rect.fromLTRB(20, 600, 370, 672)` (height **72**) and
`toggle = Rect.fromLTRB(303, 620.5, 354, 651.5)` — the design rects exactly,
with the 44 px tap target still reaching 59×44 through the shared hit slop.
Then delete `QuestEditorMetrics.toggleTrackOffset`
(`quest_editor_widgets.dart:35-49`) and its now-false comment block at
`quest_editor_view.dart:991-995`, and update
`quest_editor_view_geometry_test.dart:327-358` / `quest_editor_view_test.dart:612-625`
to assert the track itself at `303 / 620.5 / 51 / 31` (the header table's
`.toggle track 303 / 620.5 / 51 / 31` row is already correct and needs no edit).

---

### 3. MAJOR — mandatory orchestrator item 20:09 not done: four of the six icon tiles still draw the wrong glyph

**Where:** `quest_editor_view.dart:293` (`NestIcons.bed`), `:298`
(`NestIcons.dishwasher`), `:300` (`NestIcons.hoover`), `:306`
(`NestIcons.bin`).

**Why it is wrong.** `ORCHESTRATOR_NOTES.md` 17:57 item 1 (still binding) bans
look-alike substitutions: *"If a glyph is missing from `app/assets/icons`, write
`SHARED_REQUEST.md` … rather than substituting a look-alike."* Batch 5 answered
that request — `ic_quest_{bed,dishes,hoover,bins}.svg` and
`NestIcons.questBed / questDishes / questHoover / questBins` are on `main`
(`nestling_assets.dart:119-137`, `nest_icon.dart:36-39`) and carry the design's
exact paths (`M4 11h16v9…`, `M3 18v-8a2 2 0 0 1 2-2h14…`, the canister with
`M7 16v3M11 16v3` legs, the case with the `M10 12h4` clasp). The 20:09 note
orders the switch. It has not happened, so four tiles still draw glyphs that
**no** P09 frame contains:

| tile | design | still painted | delta |
|---|---|---|---|
| Bed | flat frame, no headboard | `ic_bed.svg` has a headboard arc | wrong object |
| Dishes | handled basket | `ic_dishwasher.svg` appliance with rack line + 2 control dots | wrong object (P08 item 2 of iteration 2) |
| Hoover | angular canister + hose + 2 legs | `ic_hoover.svg` rounded canister + dot wheels | wrong object |
| Bins | handled case + clasp | `ic_bin.svg` wheelie bin | wrong object |

Iteration 2's own UI note measured whole-tile MAE at **4.5 / 17.5 / 20.5 /
17.3** for these four tiles; the fix is now one constant each, so stage 5 can
expect those to collapse to raster residue.

**Fix.**

```dart
(key: 'bed',       aliases: <String>['sofa'], label: 'Bed',    icon: NestIcons.questBed),
(key: 'dishwasher',aliases: <String>['plate'],label: 'Dishes', icon: NestIcons.questDishes),
(key: 'hoover',    aliases: <String>[],       label: 'Hoover', icon: NestIcons.questHoover),
(key: 'book',      …),                                                  // unchanged
(key: 'bin',       aliases: <String>['bins','shirt','bag'], label: 'Bins', icon: NestIcons.questBins),
(key: 'paw',       …),                                                  // unchanged
```

The stored `key` values (`bed`/`dishwasher`/`hoover`/`bin`) must **not** change —
they are what `quests.icon` holds in the database and what the alias table
resolves — so this is an artwork swap only, and
`quest_editor_data_integrity_test.dart:170` must move to the same list in the
same commit (finding 1d). The stale comment at
`quest_editor_view.dart:281-290` needs no edit beyond confirming it still
describes the aliases.

---

### 4. MINOR — a parent-facing toast can still carry a Dart error string

**Where:** `quests_bloc.dart:55-61, 78-84, 101-107` →
`quest_editor_view.dart:153-154` (`showNestToast(context, error)`).

Carried from iteration 2 (finding 10). `editorError: error.toString()` means a
bypassed guard would put `Invalid argument (coins): 9999: Quest coins must be
1..100` in front of a parent. `_save` clamps and `_canSave` blocks, so it is
unreachable today.

**Fix.** Map to parent-safe copy at the bloc boundary
(`'Could not save the quest. Try again.'`) and log `error`.

---

### 5. MINOR — `SHARED_REQUEST.md` still describes four landed shared batches as open

**Where:** `docs/screens/P09/SHARED_REQUEST.md` §2 (line 19), §4 (line 77,
"**BLOCKS P09 UI check**"), §5 (line 177), §6 (line 206).

All four were answered by `shared/shared_batch5` — the SVGs exist on `main`
(verified: `app/assets/icons/ic_quest_{bed,dishes,hoover,bins}.svg`),
`NestToggle` is 51×31, `NestStepper` is U+2212, `NestTextField`'s default
horizontal padding is 12. §4's "BLOCKS" banner is now false and is exactly what
told findings 2 and 3 to wait instead of adapting.

**Fix.** Retitle §2/§4/§5/§6 `— RESOLVED on main (shared/shared_batch5)` in the
style of §1, and note the P09-side follow-ups each still owes (this file is
inside RULES §1, so no request is needed).

---

### 6. MINOR — two stage notes still name `NestIcons.basket` as the design glyph for Dishes

`docs/screens/P09/3_test.md:74` and `docs/screens/P09/FIXES_2.md:77`: *"design's
order and glyphs (`NestIcons.basket` for Dishes, per 2b's …)"*. The basket was
the banned look-alike, reverted in iteration 2; `2b_build_ui.md` and `5_ui.md`
were corrected (finding 8 is otherwise closed — the false "main redrew the
glyphs" claim is gone and the apostrophe sentence is now right).

**Fix.** Correct both lines to `NestIcons.dishwasher` / `questDishes`.

---

### 7. MINOR — `DESIGN_SPEC.md` §5 P09 is stale on the tile size (carry, no change here)

`docs/DESIGN_SPEC.md:168` says *"Icon picker row (6 SVG icons in **48px**
tiles, one selected)"*. The CSS is `.ic{width:44px;height:44px}` and my probe of
the PNG confirms 44 (border strokes at `x = 20, 81, 142, 204, 265, 326`,
`20 + i·61.2`, last tile ending at 369.67). `app/lib/core/**` and `docs/**` are
off-limits to a screen agent, so this is for the orchestrator's doc pass; the
code's 44 is correct.

---

### 8. MINOR — the interface doc promises `[ArgumentError]`, but debug builds throw `AssertionError`

`quests_repository.dart:22-24` (*"Out-of-range values throw `[ArgumentError]`"*)
vs `quests_repository_impl.dart:98-107`, where the `assert` precedes the
`ArgumentError` — so in debug (and in every `flutter test`) the `ArgumentError`
is unreachable, and `quests_repository_test.dart:416/434` asserts
`isA<AssertionError>()`. The behaviour is intentional and documented in the
impl; only the contract comment is untrue in debug.

**Fix.** One line in `quests_repository.dart`: *"throws `AssertionError` in
debug, `ArgumentError` in release (see `QuestsRepositoryImpl._checkCoins`)"*.

---

### 9. MINOR — the view resolves its repositories through `GetIt.instance` with no graceful degradation

`quest_editor_view.dart:54`, `:75`, `:431-432`. If the locator has no
registration, `didChangeDependencies`/`initState` throw during build and the
screen becomes an error widget. The sibling P10 screen took the opposite
decision for the same class of failure (`p10_bugs_test.dart` "BUG-P10-8 — the
view silently degrades when its DI lookup fails"), and the same view already
handles a *missing row* (`Quest not found`) and a *failed stream* (`onError`),
so the asymmetry is visible.

**Fix (cheap, optional).** Wrap the two lookups in a `hasRegistration` check:
a missing repository yields the load-failure panel (`_QuestLoadFailure`) with
`Try again`, and `initState` skips the two subscriptions. Do **not** rewire the
bloc away from `QuestsBloc` — `buildWhen` and `editorStatus` are correct and
out of scope.

---

## What was checked and found correct

* **RULES §1 file scope.** `git diff --stat main...HEAD -- app/` touches only
  `lib/features/quests/{presentation,domain,data}` + `quests_routes.dart` and
  `test/features/quests/**`, plus two pre-authorised P08 test files
  (`test/features/today/{today_view_test,p08_bugs_test}.dart`, +68/−25) whose
  only change is swapping a `find.text('P09 Quest editor')` placeholder anchor for
  `pushedPath`/`_pushedUri` + `find.byType(QuestEditorView, skipOffstage: false)`
  — `SHARED_REQUEST.md` §3 cites `router_push_test_fix_REPORT.md` §4/§5 for it
  and `test/features/today/` is green (110 pass). Nothing in
  `app/lib/core/**`, `app/lib/app/**` or `tools/**` is touched.
* **Architecture.** Feature-first intact; `domain/` still only entities + the
  abstract repository; one bloc per feature with three editor events added
  (`QuestsCreateRequested` / `UpdateRequested` / `DeleteRequested`); routes and
  query contract centralised in `quests_routes.dart` (`QuestsEditorQuery` with
  `questId` / `legacyQuestId` / `ideaId` and doc comments); `/quest-editor` →
  `QuestEditorView` + `QuestsBloc` exactly as `ARCHITECTURE.md`'s route table
  says. `editorStatus`/`editorError` stay orthogonal to `status`, so
  `emit.forEach` on `watchItems()` is untouched and **no reload event was
  introduced** — the watch-stream contract in RULES §4.1 holds. The one
  cross-feature read (`FamilyRepository.watchChildren()`) is read-only, is
  unsubscribed in `dispose`, and has an in-feature precedent for a feature repo
  reading the `families` row (`today_repository_impl.dart:110`). No new folder,
  no use-case class, all imports `package:nestling/…`.
* **Design system, no hard-coding.** No colour literal in the whole diff
  (`Colors.transparent` ×3 only — always on a `Material` whose colour comes from
  tokens); every gap through `NestSpacing`/`NestDevice`/`NestRadii`; every style
  through `NestType`; no `letterSpacing` anywhere (P09's CSS sets none, so the
  `main fd92d95` rule needs no call-site override); no `NestBalancedText` (no
  `text-wrap: balance` heading in P09's CSS — correct to omit); no
  `NestChip` row, so `NestChipWrap` is correctly absent. Shared components
  reused, none re-implemented: `NestStatusBar`, `NestTextField`, `NestCard`,
  `NestStepper`, `NestSegmented`, `NestDayPicker`, `NestToggle`, `NestAvatar`,
  `NestIcon`, `NestButton`, `NestModal`, `NestBottomSheet`, `NestToast`. The six
  screen-local numbers (`iconTileRadius` 14, `hairline` 1.5, `savePadding` 18,
  `saveMinWidth` 64, `cancelPadding` 6, `dueRowMinHeight` 56) live in
  `QuestEditorMetrics` with their CSS quoted — the `NestPager` precedent. The
  `.person` padding arithmetic still reconciles with the CSS
  (`4+1.5` left, `12+2+1.5` right = CSS `4`/`14` + the hairline that
  `Material.shape` paints outside the child).
* **Copy, character by character against the HTML.** `Cancel`, `New quest`,
  `Save`, `Quest name`, `Icon`, `Who's it for?` (U+0027 — hexdump of both the
  HTML and the view), `M`, `Maya`, `L`, `Leo`, `Anyone`, `Reward`,
  `= 15p at payout`, `15`, `Repeats`, `Once`/`Daily`/`Weekly`, `M T W T F S S`,
  `Needs my approval`, `Coins land after your thumbs-up` (U+002D, asserted
  against `’`/`–`), `Due by`, `Before tea (5pm) ›` (U+203A). Every non-design
  string is enumerated in `kScreenLocalCopy` with the plan section that sanctions
  it. UK spelling throughout.
* **Iteration-2 findings that are now closed.** Finding 2 (`?idea=` is live:
  `QuestsEditorQuery.ideaId`, `_ideaTemplateOf`, a CREATE with a fresh id, the
  alias table covers all 10 template icons so every `+ Add` seeds a selected
  tile, stale `TODO(P10)` comments deleted) — closed, with the test the review
  asked for. Finding 3 (`Tooltip('Back')` deleted; the P10 sites use
  `handlePopRoute()`; a test now pins exactly one `byTooltip('Back')` absence) —
  closed. Finding 4 (the `ValueListenableBuilder<TextEditingValue>` over `_title`
  means a keystroke rebuilds only `QuestSavePill`) — closed.
  Finding 5 (`listEquals` guard on the roster, `onError` on **both**
  subscriptions) — closed. Finding 6 (`semanticLabel: 'Due by, $_dueLabel'`, so
  the value is announced and the card still exposes `onTap`) — closed.
  Finding 9 (the P08 test edits must travel on the merge) — still true.
* **Accessibility.** Every screen-local tappable passes `onTap:` on its own
  `Semantics` node next to the `InkWell`, with `excludeSemantics: true` on that
  node: `QuestCancelButton`, `QuestSavePill`, `QuestIconTile`,
  `QuestPersonPill`, `QuestDueOptionRow`, and the due `NestCard`
  (`semanticLabel` + `onTap`, verified in `nest_card.dart:61-83`).
  `QuestSavePill` reports `enabled: false` and drops the action while disabled or
  while a write is in flight. `Semantics(header: true)` on the title and the
  three group labels (the test pins exactly 4 headers); the icon row is a
  `container` named `Quest icon`, matching the HTML's `role="radiogroup"`. The
  only semantics problem in the tree is the three stale test lookups in
  finding 1b — the node itself is intact, and
  `shared_batch5_REPORT.md` prescribes the same fix for P14.
* **Children's Code.** `/quest-editor` is in the router's `parentOnly` list;
  kid mode is redirected to `/parental-gate` (proven by a test). No analytics,
  no ads, no network, no child data leaving the device — the screen reads the
  family's own children and writes only to `quests`. No `subscription_status`
  written anywhere; no period/`countsForCurrentPeriod` logic is needed on P09;
  no Pip on this screen, so the PIP ruling does not apply.
* **Error handling.** Save/update/delete failures surface a toast, keep the
  editor on screen, leave the Drift row untouched and re-enable the pill through
  `clearSaveGuard()`; the route-level load failure offers `Try again` that
  really re-subscribes. Coins are validated in the repository before Drift is
  touched, so a corrupt row can never be re-persisted.
* **Performance / lifecycle.** `buildWhen: previous.status != current.status`
  stops `watchItems()` re-emissions from rebuilding the form; both subscriptions
  are `late` fields created once in `initState` and cancelled in `dispose`, as is
  `_title`; neither subscription rebuilds on an unchanged value; `const` is used
  everywhere it compiles; the sheet's `minHeight: constraints.maxHeight` keeps
  the paper to the physical edge while still scrolling in edit mode. Iteration 2's
  two perf findings are closed and I found no new rebuild storm.
* **Bottom edge, alignment, child order.** The sheet is a `tokens.paper`
  container inside a `tokens.surface2` backdrop, so no coloured strip can appear
  under it in either theme (a test samples the last physical row). Gutters are
  `NestSpacing.padSide` (20) on every row, the icon row is `space-between` over
  350 and the assignee pills are a `Wrap`, so nothing is a few px off at 390,
  320 or 430. Children come from `watchChildren()`, which the shared repository
  already orders by creation (`createdAt`, `rowid`) — Maya then Leo, never
  alphabetical — and a new quest defaults to `_children.first`.

## LEFT FOR THE LOOP

1. **Finding 1** — 6 test-side edits (one character, three lookups, two sweep
   pins, one icon list). Nothing crosses a feature boundary; all of it is in
   `app/test/features/quests/**`.
2. **Finding 2** — delete `Transform.translate` + `QuestEditorMetrics.toggleTrackOffset`,
   restore the card's bottom padding to `NestSpacing.s4`, update the two
   geometry assertions. Verified to land the card and the track exactly on the
   design rects.
3. **Finding 3** — switch four `NestIcons` constants; the same commit updates
   `quest_editor_data_integrity_test.dart:170`.
4. **Findings 4-9** — small; 4 and 8 are one-liners.
5. **Finding 9 of the closed list** (the two `test/features/today/` files) must
   travel on the merge, not be reverted.
6. **Do not** re-open the icon question: `2b_build_ui.md` and `5_ui.md` are
   corrected, and the design PNG + CSS are the authority (44 px tiles, not the
   spec's 48).
7. No simulator was used in this stage; stage 5 owns the ±2 px verdict and can
   lean on `quest_editor_view_geometry_test.dart` (compare bands, not absolute
   y, if the device status bar is taller than 47 px). Expect the four icon tiles
   and the toggle/card block to move; re-shoot after findings 2 and 3.

## Process note (not findings)

While this review ran, another stage was writing in this same worktree. Its
files are the loop's business and are **not** reported here, but the next
iteration should not commit them blind:

* `HEAD` was `aaea888` for the whole review and every measurement above was
  taken from a `git archive HEAD` export, so none of this is affected by them.
* After the review finished, `app/test/features/quests/quest_editor_copy_test.dart`
  had an uncommitted one-line change and `app/test/features/quests/_diag3_test.dart`
  appeared — a scratch diagnostic probe. **The probe must not be committed**
  (it would run in `flutter test`). The one-line change looks like finding 1(a)
  being fixed; re-check finding 1 against whatever that stage finally writes.

VERDICT: FAIL