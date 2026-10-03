# P09 — stage 4 · QA code review (iteration 4)

Scope reviewed: `git diff main...HEAD` on branch `screen/P09` against
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`, `docs/DESIGN_SPEC.md` §5 P09
(line 168), `docs/design/SPACING_SPEC.md`, the design system in
`app/lib/core/design_system/`, the HTML source
`design/html-source/screens/P09-quest-editor.html`, both design PNGs, and the
mandatory items in `docs/screens/P09/ORCHESTRATOR_NOTES.md` (17:14, 17:57,
19:19, 20:09, 23:03).

`git merge-base main HEAD` = `7afc8ad` = `main`. The branch is not behind
`main`; every shared change through batch 5 is on disk and, as checked below,
is now absorbed by the screen.

No code was edited. Only this file was written. No simulator was booted,
installed on, screenshotted or driven; `flutter clean` was never run.

Because a sibling stage is writing in this worktree, every gate was run against
an isolated `git archive HEAD` export (`/…/opencode/p09-i4`); `HEAD` was
`8022be3` for the whole review:

```
$ cd …/opencode/p09-i4/app && flutter analyze
No issues found! (ran in 4.4s)

$ dart format --set-exit-if-changed --output=none .
Formatted 495 files (0 changed) in 1.36 seconds.

$ flutter test test/features/quests/   # the screen's feature suite
+394: All tests passed!

$ flutter test                          # whole tree
+2608 ~1 -1: Some tests failed.
  test/core/family_time_test.dart … "kid_home completions are stamped with
  the family zone"
```

The one failure is **pre-existing on `main` itself** (verified by checking out
`git archive main` and rerunning the same file — same failure), caused by code
under `app/lib/core`/`app/test/core` that this diff does not touch. Not a P09
finding and not this screen's to fix. The skipped `~1` is main's P12-BUG-05.

`git diff main...HEAD` touches exactly: `lib/features/quests/{data,domain,
presentation}/**`, `lib/features/quests/quests_routes.dart`,
`test/features/quests/**`, the two pre-authorised `test/features/today/`
files, and `docs/screens/P09/**`. `app/lib/core/**`, `app/lib/app/**`,
`app/test/core/**`, `tools/**`, `analysis_options.yaml`, `pubspec.yaml`: all
untouched. No `skip:`, no `// ignore:`, no `GoogleFonts`/`google_fonts`, no
`print`/`debugPrint`, no `TODO(` anywhere in the diff.

## Verdict summary

**All three iteration-3 defects are fixed and verified. No blocker, no major.
Two minors. VERDICT: PASS.**

Iteration 3's BLOCKER (red 10-test gate), MAJOR (approval card/toggle 4 px/2 px
off the design) and MAJOR (four legacy icon glyphs) are each resolved at HEAD
with measurements or green tests to prove it. The rest of the screen still
holds to the architecture, design-system and copy rules.

---

## Resolution of the iteration-3 findings

### Iter-3 1 (BLOCKER) — the `flutter test` gate was red (10 failures) → **fixed**

All four causes are addressed at HEAD:

* `quest_editor_copy_test.dart:85` now reads `'−' // .stepper buttons — U+2212,
  the design's glyph (shared batch5 fixed §5)` and the header comment
  documents why; the screen-local caption list gains
  `'Coins must be 1\u{2013}100'`.
* The three `getSemantics(find.byType(NestToggle))` call sites
  (`quest_editor_a11y_test.dart:515-531`, `quest_editor_copy_test.dart:259-274`,
  `quest_editor_view_test.dart:775+`) address the switch by a predicate that
  also matches its `flagsCollection.isToggled != Tristate.none` role — the
  same fix `shared_batch5_REPORT.md` gave P14.
* The robustness sweep (`quest_editor_robustness_test.dart:291-301`) drops the
  ≥44 rule for the toggle in favour of an explicit `51×31` track pin, and a
  new edge-tap loop around the track centre (`:490-513`) proves the 44×59 hit
  area still answers 6.5 px above/below and 4 px left/right of the painted
  track.
* `quest_editor_data_integrity_test.dart:225-233` pins the new six tiles
  (`questBed / questDishes / questHoover / book / questBins / paw`).

`flutter test test/features/quests/` → **394 passed, 0 failed**; the whole tree
is green except main's own pre-existing failure above.

### Iter-3 2 (MAJOR) — approval card/toggle 4 px / 2 px off the design → **fixed**

`quest_editor_view.dart` `_approvalCard` is reworked (`:991-1065` at HEAD):
the card padding moves inside a `Padding(all: NestSpacing.s4)`, the row gets a
51-wide placeholder, and the toggle is overlaid with
`Positioned(top: QuestEditorMetrics.approvalTrackTopInCard /* 20.5 */, right:
NestSpacing.s4)`. `QuestEditorMetrics.toggleTrackOffset` is deleted, and its
long comment now correctly explains that the batch-5 widget already aligns by
layout. This also fixes the iteration-3 review's implicit BUG-P09-10 (the
44-high toggle can no longer be clipped by the row's 40-high hit area, since
it is a `Stack` child, and the edge-tap test proves it).

Independent probe on the `HEAD` export (bundled Inter, light route):

```
PROBE card=Rect.fromLTRB(20.0, 600.0, 370.0, 672.0)   # 20/600/350/72  = design
PROBE toggle=Rect.fromLTRB(303.0, 620.5, 354.0, 651.5) # 303/620.5/51/31 = design
```

Both match the design PNG probe (`x 300 px` card white `y 1800→2016`, track
green `x 909→1061` → logical `303→354`) exactly. The geometry test
(`quest_editor_view_geometry_test.dart:303-340`) pins the same numbers and the
view test asserts `toggle.right == 354`, `51×31`, `center.dy == approval.top
+ 36`.

### Iter-3 3 (MAJOR) — four legacy icon glyphs → **fixed**

`quest_editor_view.dart` `_questIcons` (`:293-311` at HEAD) now reads
`NestIcons.questBed / questDishes / questHoover / book / questBins / paw`, with
a comment explaining that the stored `key`s never change (they are what
`quests.icon` holds and what the alias table resolves). Book and Paw are
unchanged and byte-identical to the design, so the picker is now six of six on
the design's artwork.

### Iter-3 4 (MINOR) — toast carried a Dart error string → **mostly fixed**

`QuestsBloc._editorError` (`quests_bloc.dart:118-127`) maps `ArgumentError` to
the parent-safe `Could not save the quest. Try again.` and logs the detail
under `name: 'quests'`. Remaining leak is finding 1 below.

### Iter-3 5/6 (MINOR) — stale `SHARED_REQUEST.md` / `NestIcons.basket` docs → **fixed**

`SHARED_REQUEST.md` §2/§4/§5/§6 are retitled `— RESOLVED on main
(shared/shared_batch5)` and §1 keeps its history; the stale basket references
in `3_test.md` and `FIXES_2.md` are gone (the remaining `basket` hits in
`FIXES_3.md`, `2a_build_logic.md`, the corrected `SHARED_REQUEST.md` and the
review docs describe the history and are correct as history).

### Iter-3 8 (MINOR) — `[ArgumentError]` contract comment → **fixed**

`quests_repository.dart` now reads the real contract: `AssertionError` in
debug (asserts are enabled under `flutter test`), `ArgumentError` in release.

### Iter-3 7 (MINOR) — §5 P09 "48 px tiles" stale spec line → not P09's to edit

Still true and still out of a screen agent's scope (`docs/DESIGN_SPEC.md` is
shared). Carried for the orchestrator's doc pass; the code's 44 px is right and
now pinned by the geometry test.

### Iter-3 9 (MINOR) — `GetIt.instance` without degradation → accepted, unchanged

Same precedent as iteration 3; `P10`'s BUG-P10-8 remains the divergent
screen. Not a blocker.

---

## New findings (iteration 4)

### 1. MINOR — `_editorError` still forwards raw `error.toString()` for anything that is not an `ArgumentError`

`quests_bloc.dart:118-127`. A Drift `SqliteException` (disk full, constraint
violation on a column P09 does not clamp) would still reach
`showNestToast` verbatim — e.g. `SqliteException (8): attempt to write a
readonly database` on a parent screen. The editor never produces those paths
today, and the iteration-3 softening of this finding was the right first step,
so it is a minor.

**Fix.** Wrap the fallthrough too:

```dart
String _editorError(Object error) {
  log('quest save failed: $error', name: 'quests');
  return QuestsBloc.saveFailedMessage;
}
```

and keep the log. If the design ever wants distinct copy per cause, map each
cause explicitly rather than forwarding the runtime's text.

### 2. MINOR — garbled token in a comment

`quest_editor_view.dart:1036`: `` the design rect (`uta:hex`-verified) ``.
Looks like a truncated tool slug.

**Fix.** `the design rect (verified against the P09 PNG, ÷3).`

---

## What was checked and found correct

* **RULES §1 file scope.** `git diff --stat main...HEAD` edits only
  `lib/features/quests/**`, `quests_routes.dart`, `test/features/quests/**`,
  the two pre-authorised `test/features/today/` files, and
  `docs/screens/P09/**`. `app/lib/core/**`, `app/lib/app/**`, `tools/**`,
  `app/test/core/**`, `analysis_options.yaml`, `pubspec.yaml` are untouched.
* **Architecture.** Feature-first intact: `domain/` is still entities +
  abstract repository only; one bloc per feature; routes and the query
  contract (`QuestsEditorQuery.questId/legacyQuestId/ideaId`) live in
  `quests_routes.dart`; `/quest-editor` → `QuestEditorView` + `QuestsBloc`
  exactly as `ARCHITECTURE.md`'s table says. `editorStatus` stays orthogonal to
  `status`, so the `watchItems()` stream subscription is unaffected and no
  reload event was reintroduced. The one cross-feature read
  (`FamilyRepository.watchChildren()`) is read-only with an in-feature
  precedent.
* **Design system.** No colour literal in the diff (`Colors.transparent`
  only); every gap through `NestSpacing`/`NestDevice`/`NestRadii`; every style
  through `NestType`; no `letterSpacing` anywhere (P09's CSS sets none);
  `NestBalancedText` absent (no balanced heading here — correct); `NestChip`
  absent (no chip row — correct). Shared components reused, none re-implemented:
  `NestStatusBar`, `NestTextField`, `NestCard`, `NestStepper`, `NestSegmented`,
  `NestDayPicker`, `NestToggle`, `NestAvatar`, `NestIcon`, `NestButton`,
  `NestModal`, `NestBottomSheet`, `NestToast`. The screen-local geometry
  constants still live in `QuestEditorMetrics` with their CSS quoted.
* **Copy.** Every design string matches the HTML character for character
  (straight `Who's`, `Coins land after your thumbs-up` with U+002D,
  `Before tea (5pm) ›` with U+203A, `= 15p at payout`), and every non-design
  string is enumerated in `kScreenLocalCopy` with its plan section. The new
  stepper-boundary caption (`Coins must be 1–100`, U+2013) is registered.
* **Accessibility.** Every screen-local tappable carries `onTap:` on its own
  `Semantics` node; the toggle predicate test and the edge-tap loop prove both
  the announcement and the action still move real state; the due-row label now
  carries the current value and a test pins that it moves with the choice; the
  sheet announces one node per control; the four semantic headers are pinned by
  an exact-count test.
* **Children's Code.** `/quest-editor` is in the router's `parentOnly` list;
  kid mode is redirected to `/parental-gate` (proven by a test). No analytics,
  no ads, no network, no child data leaves the device — the screen reads the
  family's own children and writes only to `quests`. No `subscription_status`
  is written.
* **Error handling.** Save/update/delete failures keep the editor, leave the
  Drift row untouched, re-enable the pill via `clearSaveGuard()`, and toast
  the mapped copy; the route-level `_QuestLoadFailure` offers `Try again`
  which re-subscribes. Coins are always validated in the repository before
  Drift is touched, and BUG-P09-11's boundary-jump gives the stepper a real
  repair path from a corrupt stored value (covered by
  `quest_editor_coin_rules_test.dart` and `p09_bugs_test.dart:227`).
* **Performance / lifecycle.** `buildWhen` keeps `watchItems()` emissions from
  rebuilding the form; both stream subscriptions are `late` fields cancelled
  in `dispose`, as is `_title`; the per-keystroke rebuild is scoped to the
  save pill with `ValueListenableBuilder`; `const` is used everywhere it
  compiles; the `Stack` + `Positioned` overlay does not add a layout pass over
  the old `Row`.
* **Bottom edge, alignment, child order.** The paper sheet still runs to the
  physical edge (a test samples the last row); gutters are 20 on every row and
  the icon row is `space-between`; children arrive creation-ordered from the
  shared repository (Maya then Leo, never alphabetical), and a new quest
  defaults to the first of them.

## LEFT FOR THE LOOP

1. Finding 1 — one-line wrap in `quests_bloc.dart::_editorError`.
2. Finding 2 — one-line comment fix at `quest_editor_view.dart:1036`.
3. The two `test/features/today/` files must travel on the merge (they are the
   pre-authorised anchor swap for P10's editor fixture).
4. Iteration-3's stage-5 note: `app_light_3/app_dark_3` and the
   `cmp_*_3` sheets were taken **before** this build's fixes; the next UI
   stage should re-shoot. Expect the approval block to move back onto the
   design's 72-high card, the toggle onto `303/620.5/51/31`, and the four
   icon tiles to render the batch-5 glyphs.
5. No simulator was used in this stage.

VERDICT: PASS