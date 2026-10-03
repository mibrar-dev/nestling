# P10 · Stage 2 — INTEGRATE (iteration 3)

Job: make the two halves (`2a_build_logic.md`, `2b_build_ui.md`) compile and
pass together. Smallest change, no redesign, no shared-file edits (RULES §1).

**Result: `dart format` → 0 changed (exit 0) · `flutter analyze` → No issues
found · `flutter test` → `+1953 −1`.**

**There was no integration breakage left to fix this iteration** — the halves
did not overlap a single file and neither changed the contract, so nothing had
to be re-based, renamed or re-plumbed. The single red test is the *deliberate,
mandatory* design pin for a shared-code defect (`NestTextField.search` floats
its hint 11 px too high), which I may not fix here. Per the brief — PASS
requires the full suite green — this stage is **FAIL on that one blocker**;
everything inside my scope is green. Details and the exact one-line shared fix
under FIXES-2.

## Summary of 2a — logic chunk

Scope `bloc/**` + logic tests. **Contract changes: none.**
`QuestsState(status, items, ideas, errorMessage)` and `QuestsLoadRequested` are
exactly as iteration 2 declared, so the UI layer needed no re-plumbing.

- `quests_bloc.dart` — review finding 3 (MAJOR, `Try again` watcher leak): the
  `watchItems()` stream now goes through a typed `_closeOnError` transformer
  (forward the first error, then close) before `emit.forEach`, so a failed
  load's Drift watcher is released and the retry starts exactly one fresh
  subscription instead of stacking another live watcher behind the dead one —
  same guard as `today_bloc.dart:80` / `family_bloc.dart:110`, typed for this
  call site (`List<dynamic>` does not satisfy `List<Quest>`).
- `quests_bloc_test.dart` — new proof `a failed load releases its watcher so
  retry subscribes exactly once` (broadcast controller: error ⇒ no listener,
  retry ⇒ exactly one listener, `verify(repo.watchItems).called(2)`).
  2a mutation-checked it against the pre-fix bloc (fails without the fix).
- Files: `quests_bloc.dart`, `quests_bloc_test.dart` only. 27/27 in its two
  test files, analyze clean, no `skip:`.

## Summary of 2b — UI chunk

Scope `views/**` + `widgets/**` + UI proofs. No `domain/`, `data/` or `bloc/`
file touched, so the two file sets are disjoint (confirmed against
`git status`: 2a owns `quests_bloc.dart` + `quests_bloc_test.dart`, 2b owns
`quest_idea_row.dart`, `quest_library_body.dart`,
`quest_library_a11y_actions_test.dart`, `quest_library_design_geometry_test.dart`).

- **BUG-P10-12 / review finding 2 (MAJOR)** — the applied search filter went
  invisible after a tab round-trip: the field is only built while `filtersOn`
  (BUG-P10-3), so the `EditableText` state was disposed while `_query`
  survived. `_QuestLibraryBodyState` now owns a `TextEditingController`,
  passes it to `NestTextField.search(controller:)` and disposes it.
- **review finding 6** — the row title now uses `NestType.bodyStrong(…).copyWith(height: 22/16)`
  instead of rebuilding `bodyStrong` by hand; **finding 7** — both empty states
  share the 20 px gutter (OWNER ALIGNMENT); **finding 8** — the icon tile's
  `40` literals became `NestSpacing.s10`.
- **review advisory 1** — the search-field proof asserted `SemanticsAction.setText`
  on a node that carries neither `setText` nor `tap` in this Flutter build
  (framework baseline, not a P10 defect); rewritten to assert what P10 owns
  (is a text field, the design's `aria-label` is in the tree once, typing
  really filters) — the action half still proved end-to-end.
- **Found and filed BUG-P10-14 (MAJOR, shared)** + added the two
  `ORCHESTRATOR_NOTES` 12:17 pins (hint centre, magnifier centre) and
  ORCHESTRATOR_NOTES item 12's real-font geometry suite.
- Per-file: `p10_bugs_test` 10/10, `quest_library_a11y_actions_test` 11/11,
  `quest_library_a11y_test` 20/20, `quest_library_view_test` 27/27,
  `quest_library_widget_test` 16/16, `quest_library_states_test` 19/19,
  `quests_bloc_test` 17/17, plus filter / meta / repository / geometry files.
  **No live `skip:` marker** anywhere in `test/features/quests/` (the single
  grep hit is a comment recording their removal). No `google_fonts` /
  `GoogleFonts.*` in the feature.

## FIXES

### FIXES-1 — NONE NEEDED · no integration breakage

Checked, not assumed:

- **Contract**: `QuestsState` unchanged this iteration; the view still passes
  `state.items` / `state.ideas` (no `get_it` probe) and every widget signature
  is untouched, so the two halves line up as-is.
- **File overlap**: none (see above) — nothing had to be reconciled.
- **Iteration-2 carry-overs, re-verified green**: the states-test mock stub,
  the a11y prefix-match finder and the hidden-anchor deletion all still hold;
  `today_view_test.dart` asserts `pushedPath(tester)` and passes with no anchor
  in the tree.
- **The 3 red tests that blocked iteration 2 are fixed by shared code that
  landed mid-stage**: `ab1ba06` "Fix NestSegmented double announcement with
  excludeSemantics" (merged `0cdb53c`, `nest_segmented.dart:63` now has
  `excludeSemantics: true`), so `quest_library_a11y_test.dart` is 20/20. No
  local workaround was taken, per the orchestrator's instruction.

### FIXES-2 — LEFT (shared code, cannot fix here) · 1 test · the sole blocker

`quest_library_design_geometry_test.dart` →
`the hint is centred in the field, not floated to the top`

I re-ran it and confirmed the premise independently:

```
Expected: a numeric value within <1> of <200>
  Actual: <189.0>
   Which:  differs by <11.0>
```

The painted `Text('Search ideas')` rect centres at **y 189.0**; the design's
field spans 173…227, so its centre — where the design puts the hint ink, level
with the magnifier — is **y 200**. The magnifier itself is correct (centre 199,
pinned by its own passing test), so the drift is the hint alone.

Cause is inside `app/lib/core/design_system/components/nest_text_field.dart`
(`_buildSearch`, lines ~167-193): the `TextField` sits in a *tight*
`SizedBox(height: 44)` with `isDense: true` and `contentPadding:
EdgeInsets.only(left: -4)`, and `textAlignVertical: center` only centres within
the editable's intrinsic ~24 px line box, which is painted at the top of the
44 px slot.

Left here on purpose, and it is the whole of the remaining red:

- `app/lib/core/**` is forbidden to a screen agent (RULES §1);
- `NestTextField.search` exposes no `contentPadding` / `isDense` /
  `textAlignVertical` / `strutStyle` knob (checked the constructor), so there
  is no in-scope parameter to pass;
- wrapping or re-padding the shared field locally is exactly the "hack it
  locally" the orchestrator rules forbid, and re-implementing the field is
  forbidden outright;
- the pin itself is **mandatory** — `ORCHESTRATOR_NOTES.md` 12:17 item 3 says
  "Pin the hint text centre (200 ±1) in the geometry test" — so deleting,
  skipping or relaxing it is not an option.

`SHARED_REQUEST.md` §10 carries the measurements, the cause and a suggested
fix (give the editable the 44 px box instead of a line box: `strutStyle` /
`textHeightBehavior`, or vertical `contentPadding` of `(44 - 24) / 2 = 10`
alongside the existing `left: -4`). It composes with §9 (field 52 → 54): the
pin already uses the design number 200, not the app's current 199, so it goes
green the moment §10 lands either alone or with §9.

### FIXES-3 — LEFT (shared, informational, no red test)

`SHARED_REQUEST.md` §8 (the search `aria-label` lands on a wrapper node rather
than merging into the editable node — the test now asserts the label is in the
tree exactly once), §9 (search row 52 where `.search` computes 54, leaving the
chip row and all ten cards a uniform 2 px high; the geometry test still pins
`54 ± 2` and should be tightened to ±1 once §9 lands), §6 (`QuestPushOnce` →
`core/`) and §7 (P08 paints `plate` lilac where P10 paints sky) all stay with
the orchestrator.

## Gates

```
$ dart format --set-exit-if-changed .
Formatted 438 files (0 changed) in 1.18s.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.0s)

$ flutter test
00:38 +1953 -1: Some tests failed.
  test/features/quests/quest_library_design_geometry_test.dart:
    P10 design geometry — the title and the controls under it
    the hint is centred in the field, not floated to the top
```

Per-file failure sweep of `test/features/quests/` (one command per file): the
only file with a failure is `quest_library_design_geometry_test.dart` (1, the
pin above); all ten other files report 0. The
`WARNING (drift): AppDatabase created multiple times` notices in the output
are the repo-wide debug-build notice from `test_scope.dart`, not failures.

No simulator was booted, installed on, screenshotted or driven in this stage.

VERDICT: FAIL