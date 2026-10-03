# Fix list after iteration 3

## From 2_build.md
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


## From 3_test.md
# P10 · Quest library (`/quests`) — Stage 3 TEST (iteration 3)

Route `/quests` · feature `quests` · parent mode · in-memory Drift DB ·
tests pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.
Tree tested: `325e93e` "P10: checkpoint after build (iteration 3)" on
`screen/P10` (which includes the shared merge
`0cdb53c Merge shared/segmented_semantics`).

**No screen code was changed.** The one finding below is a failing proof in
`app/test/features/quests/`, left in place.

---

## 0. Where iteration 2 left things

Iteration 2 ended at **170 pass / 5 fail**. The shared `segmented_semantics`
merge and the iteration-3 build closed four of the five:

| Iteration-2 failure | Now |
|---|---|
| BUG-P10-10 · `NestSegmented` announced every option twice (3 tests) | **fixed** by the shared merge — `quest_library_a11y_test.dart` 20/20 |
| BUG-P10-12 · the applied search filter went invisible after a tab trip | **fixed** — `p10_bugs_test.dart` 10/10 |
| BUG-P10-13 · the search field's accessible name was its hint | **fixed** — `quest_library_a11y_actions_test.dart` 11/11 |
| BUG-P10-13/§10 · `NestTextField.search` floats its hint to the top | **open** (shared) — 1 test red |

So the stage opened at **176 pass / 1 fail**. The brief carries no new
orchestrator rules this iteration, so the work went into closing the two
coverage gaps I had explicitly deferred earlier rather than into more of the
same.

---

## 1. Tests added

### 1a. `quest_library_seed_empty_test.dart` (**new**, 6 tests)

Iteration 1 proved "no active quests" with a **mocked empty stream** because
driving the real router with `Seed.empty()` hung the test, and I recorded that
as a known deferral. This brief says *"Use the in-memory Drift DB with
Seed.demo/empty"*, so the real seed is now covered:

- `/quests` stays on route with `Seed.empty()` — no trial or onboarding
  redirect (`Seed.empty` writes `subscriptionStatus: 'trial'`,
  `trialStart: now`, so the trial guard must not fire);
- the Active tab reports the database's real count, `Active (0)`, and shows
  `No active quests` / `Add one from Ideas.`;
- **the Ideas tab still lists the static templates** with an empty database —
  `QuestsRepository.ideas()` are never stored rows, so `Seed.empty()` must not
  empty the Ideas tab (DATA OVER MOCKS). This is the assertion the mock could
  not make honestly, since the mock returned the real templates itself;
- the search field and the chip row still work, including the AND combination
  (`pet` + `Kitchen` → empty state; `Kitchen` alone → its two templates);
- no overflow and no exception on the empty tree;
- and with `Seed.demo()`, deactivating `q-bed` moves `Active (12)` → `Active
  (11)`, proving the label tracks the stream rather than a literal.

The earlier hang was not the seed: it was my own chain of
`setUpTestScope` → `AppSession.refresh()` → `watchItems().first` → pump, which
left a Drift timer pending. Calling `setUpTestScope`/`Seed.empty` and then
`pumpAppRoute` (which ends with `disposeApp`) is clean.

### 1b. `quest_library_view_test.dart` (extended, 27 → 34 tests)

- **Every tap navigates to the right route** — the brief's wording covers the
  shell too, and the four parent tab-bar items had no coverage on P10. Each is
  now proved: `Today` → `/today`, `Money` → `/money`, `Family` →
  `/child-profile`, `Quests` → `/quests`, plus a round-trip through all four
  that ends with the library intact. Taps are scoped to `NestTabBar` via a
  `_tab()` helper, because the library's own heading is also labelled
  `Quests` (the same collision P08's tests hit).
- A tab round-trip does not disturb the applied category filter.
- **`/quests` is parent-only** — with `AppModeController.selectMode(AppMode.kid)`
  the router lands on `/parental-gate`. P10 is a parent screen, so the 56 px
  kid tap floor from the brief never applies to it; this test makes that
  explicit rather than implicit.
- The Active tab now runs at **widths 320/390/430 × text scale 1.0/1.3**
  (it previously covered the widths at 1.0 only).

### Audited and already complete, so unchanged

- **bloc_test for every event/state path** — `QuestsState` gained `ideas` in
  iteration 2 and the suite was updated then: `copyWith` per field, the
  "null means keep" rule, equality, `hashCode`, `props` order
  (`[status, items, ideas, errorMessage]`), plus every status path including
  "a failure keeps the last ideas" and the empty-ideas case. 17/17.
- **Semantics labels + `performAction`** — `quest_library_a11y_test.dart` 20/20
  and `quest_library_a11y_actions_test.dart` 11/11.
- **Empty / loading / error states** — `quest_library_states_test.dart` 19/19.
- **Tap targets ≥ 44 (parent)** — chips, `+ Add`, segmented, search field, in
  the responsive matrix and the a11y suite.
- **Design geometry** — `quest_library_design_geometry_test.dart`, 10/11.

---

## 2. Results

```
$ dart format --set-exit-if-changed .
Formatted 439 files (0 changed) in 1.18 seconds.

$ flutter analyze
Analyzing app...
No issues found! (run in 3.0s)

$ flutter test
+1966 -1: Some tests failed.
```

| File | Result |
|---|---|
| `quest_library_view_test.dart` | 34/34 |
| `quest_library_states_test.dart` | 19/19 |
| `quest_library_filter_test.dart` | 20/20 |
| `quests_bloc_test.dart` | 17/17 |
| `quest_idea_meta_test.dart` | 16/16 |
| `quest_library_widget_test.dart` | 16/16 |
| `quest_library_a11y_test.dart` | 20/20 |
| `quest_library_a11y_actions_test.dart` | 11/11 |
| `p10_bugs_test.dart` | 10/10 |
| `quests_repository_test.dart` | 10/10 |
| `quest_library_seed_empty_test.dart` (**new**) | 6/6 |
| `quest_library_design_geometry_test.dart` | 10/11 ✗ |

`test/features/quests/` is now **189 tests**, 1 failing. The whole app is
**1967 tests, 1 failing**, and the single failure is P10's. No other feature's
tests broke. No test is skipped anywhere in `test/features/quests/`.

---

## 3. Bug found

### The one red test — MAJOR (shared) — the search hint floats to the top of the field

`app/test/features/quests/quest_library_design_geometry_test.dart:276-293`
→ `the hint is centred in the field, not floated to the top`.

**File** `app/lib/core/design_system/components/nest_text_field.dart:167-193`
(shared; already filed by the build stage as `SHARED_REQUEST.md` §10, which I
re-measured independently and confirm).

**Measured**, 390×844 with the 47/34 device insets and the bundled Inter face:

```
FIELD     173.0 … 225.0   centre 199.0   (52 tall)
ICON      187.0 … 211.0   centre 199.0   ← the magnifier IS centred
TEXTFIELD 177.0 … 221.0   centre 199.0   (44 tall — the design's `input`)
HINT      177.0 … 201.0   centre 189.0   ← 10 px high
```

**Independent confirmation from the design PNG** (I re-measured rather than
trusting the earlier note): the `--line` ring spans device rows 519–521 and
678–680 ⇒ the field is **y 173.0 … 227.0**, centre **200.0**; the hint's
non-white pixels run **y 194.0 … 206.3**, centre **200.2** — the same centre as
the magnifier's ink band (191.0 … 209.0). So the design really does centre the
hint on the field, and the pin's expected value (200) is the design's, not the
app's.

**Cause.** The `SizedBox(height: 44)` around the `TextField` is tight, and
`textAlignVertical: TextAlignVertical.center` only centres the text inside the
editable's own box, which measures 24 (Inter 16 × `height: 1.5`) — the
intrinsic line box, not the 44. The hint therefore paints at the top of the
slot.

**Repro.** `/quests` → look at the search field: the magnifier sits vertically
centred, the placeholder sits 10 px above centre.

**Fix.** Shared — the editable needs the 44 px box, not a line box
(`strutStyle`/`textHeightBehavior`, or `contentPadding` vertical
`(44 − 24) / 2 = 10`, or wrapping so `TextField` fills the slot and
`TextAlignVertical.center` does the work). P10 must not re-pad the shared field
locally, so it stays unfixed here — same rule as §1.

The pin is written against the design's absolute numbers, so it turns green on
its own once §9 (field 52 → 54) and this fix land together.

---

## 4. Owner rules checked

- **No skipped tests** — `grep 'skip:'` over `test/features/quests/` finds only
  a comment recording that the markers were removed.
- **No `lib/` change** — `git status` shows only `test/features/quests/` and
  `docs/screens/P10/`.
- **google_fonts** — 0 occurrences in `lib/features/quests` and
  `test/features/quests`.
- **BOTTOM-EDGE / ALIGNMENT / UI VERDICT RULE** — the geometry suite pins the
  20 px gutters, the bar surface reaching 844 and the design y for the title,
  every control and every card top, in light and dark; unchanged and still
  green apart from the shared hint pin.
- **ACCESSIBILITY ACTIONS** — unchanged, all green: `hasAction(tap)` and
  `performAction` with a real state/route/DB effect for every control.
- **Simulators** — none booted, installed on, screenshotted or driven.

---

## 5. Verdict

One proof fails. It is a genuine defect in shared `NestTextField.search`, not
in P10's screen code, and it is already filed as `SHARED_REQUEST.md` §10. The
suite cannot be green until that shared fix lands, so the verdict is FAIL — with
every P10-local issue from iterations 1 and 2 now closed and verified.


## From 5_ui.md
# P10 · Quest library (`/quests`) — Stage 5 UI check (iteration 3)

Route `/quests`, parent, maya, seed demo, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Designs `design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x = 390×844 logical).
Shots `docs/screens/P10/ui/app_light_3.png`, `app_dark_3.png`; sheets `cmp_light_3.png`, `cmp_dark_3.png`.
ORCHESTRATOR_NOTES 09:46 + 10:00 + 12:17 applied (shared items are not P10 findings;
hint-centre pin: field 173–227, centre 200 ±1).

Mean diff: light 3.33% (bands 1.58/1.63/3.98/4.87/4.18/4.13/3.78/2.50);
dark 3.16% (bands 1.58/1.55/3.82/4.57/3.84/3.80/3.49/2.61) — unchanged from iteration 2.

Status-bar glyphs ignored (OS draws real bar). Bottom edge: tab-bar surface runs to the
physical edge in both themes (owner rule) — correct. `Active (12)` from DB — correct.
No Pip on this screen. Copy/order vs HTML source all match (middot `·`, `+ Add`).
6th card peeks under the tab bar as in the design.

Measured y, design vs app, logical px (@3x ÷ 3; tolerance ±2):
- screen title top: 61.7 vs 62.0 (+0.3)
- segmented track top: 100.0 vs 100.0 (0)
- search field outer top: 174.0 vs 174.0 (0)
- row-1 title/meta text x: 85.0 vs 85.3/85.0 (+0.3/0)
- card tops 1–5: 297.0/381.0/465.0/549.0/633.3 vs 295.3/379.3/463.3/547.3/631.3 (−1.7…−2.0)
- `+ Add` pill 1 x/y/w/h: 287.0/303.0/70.7/43.7 vs 286.7/301.0/71.0/43.7 (≤2.0)
- `All` chip x: 20.0 both; tab-bar active content y 739.0–776.3 both (0)
All P10-local elements are within ±2px.

## Deviations

1. Search hint text floats ~11 px too high in the field (MAJOR, both themes — shared cause).
   - Design: field ring spans y 173–227 (centre 200); hint ink centre measured 201.2.
     Icon is centred on the field in both (orchestrator 12:17).
   - App (`app_light_3.png`): field top 174.0 matches, but hint ink spans 183.0–195.0,
     centre 190.2 — 11.0 px above the design centre. Visible in both diff sheets as a
     doubled `Search ideas` line (band 1 would otherwise be ~0).
   - Cause is inside shared `NestTextField.search` (tight 44px slot + hint painted at
     the top of the line box; see SHARED_REQUEST §10 for the widget-tree measurement).
     RULES §1 forbids a screen agent from editing `core/`, and orchestrator 10:00
     forbids hacking it locally — no P10-local fix exists.
   - Fix (shared): give the editable the 44 px box (contentPadding vertical
     (44−24)/2 = 10, strut, or fill the slot so TextAlignVertical.center works);
     already filed as SHARED_REQUEST §10 with red proof
     (`the hint is centred in the field, not floated to the top`, pins 200 ±1).
     The residual chip-row (−2.0) and card-top (−1.7…−2.0) offsets follow the short
     field (§9, 52 vs 54 tall) and compose with this fix.


## From 6_bugs.md
# P10 · Quest library — bug hunt (Stage 6, iteration 3)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-3 build checkpoint
`325e93e`, with shared `segmented_semantics` (`ab1ba06`, merged `0cdb53c`) and
batch4 on `main`. `ORCHESTRATOR_NOTES.md` items 1–6 plus the 12:17 update
re-verified.

**Result: no new P10-local bug.** Every finding from iterations 1–2 is fixed
and guarded by un-skipped green proofs; the whole feature is green except the
**one mandatory pin for a shared defect** — `NestTextField.search` floats the
hint 11 px too high (BUG-P10-14). No screen code was changed by this stage;
`p10_bugs_test.dart` needed no edit (its only skip, BUG-P10-12, is now a
green proof).

| Id | Iter-2 | Iter-3 status |
|---|---|---|
| BUG-P10-1 | fixed | green proof (push guard) |
| BUG-P10-2 | fixed | green proof (row text x+64) |
| BUG-P10-3 | fixed | green proof (filters Ideas-only) |
| BUG-P10-4 | fixed | green proof (end gap 32) |
| BUG-P10-5 | fixed | green proof (search icon 24 at x+16) |
| BUG-P10-6 | fixed | green proof (segmented 52/44) |
| BUG-P10-7 | fixed | green proof (tab content y) |
| BUG-P10-8 | fixed | green proof (ideas in state) |
| BUG-P10-9 | fixed | green proofs (semantics actions) |
| BUG-P10-10 | open (shared) | **FIXED** on main `ab1ba06` (`excludeSemantics`); a11y suite 20/20 |
| BUG-P10-11 | fixed | green proof (tile tints) |
| BUG-P10-12 | open (local) | **FIXED** — `TextEditingController` owned by the body; round-trip probe below; proof green |
| BUG-P10-13 | open (shared) | **no red** — assertion rewritten to what P10 owns; underlying node-merge defect informational, `SHARED_REQUEST.md` §8 |
| **BUG-P10-14** | — | **OPEN (shared, major)** — search hint centre 189 vs design 200; the sole red test |

---

## OPEN — BUG-P10-14 — major — `NestTextField.search` floats the hint to the top

`app/lib/core/design_system/components/nest_text_field.dart` (`_buildSearch`):
the editable gets a tight 44 px `SizedBox` with `isDense` + negative left
padding, and `TextAlignVertical.center` only centres the ~24 px line box inside
itself, so the hint paints at the **top** of the slot.

Measured on `/quests` at 390×844 with the device insets (the geometry suite,
real fonts): field box 173…225, magnifier centre **199** (correct), hint box
177…201 → hint centre **189**; the design's field is 173…227 and its hint sits
level with the magnifier at **200** (ORCHESTRATOR_NOTES 12:17 item 1, ±1
mandate). Everything below the field is consequently the uniform **−2 px**
shift: chip pill 227→225, cards 291→289, 375→373, … (12:17 item 2). A 11 px
error and a whole-lower-half shift both violate the UI VERDICT RULE.

**Proof (the only red in the feature, mandatory per note 3):**
`quest_library_design_geometry_test.dart` →
`the hint is centred in the field, not floated to the top` (`hint.center.dy`
189 vs 200±1, and vs `field.center.dy` 199).

**Fix (shared — `SHARED_REQUEST.md` §10, RULES §1 forbids editing `core/`):**
give the editable the full 44 px box rather than a line box (vertical
`contentPadding` of `(44 − 24) / 2 = 10` beside the existing `left: -4`, or a
`strutStyle`/`textHeightBehavior`), and settle `§9` at the same time (row 52 →
the design's 54). The pin already uses the design value 200, so it goes green
when either shared fix lands. Related shared minors with no red: §8 (the
`aria-label` lands on an inert wrapper node; the editable announces the hint).

## Fixed this iteration (verified)

- **BUG-P10-12** — `_QuestLibraryBodyState` now owns and disposes a
  `TextEditingController`, passed to `NestTextField.search`. Probe: type `pet`
  → Active → Ideas keeps the field text `pet` and the 1-row filter; clearing
  restores the list. Proof green (no skip left).
- **Review finding 3 / watcher leak** — `QuestsBloc` streams through
  `_closeOnError` before `emit.forEach`; proof
  `a failed load releases its watcher so retry subscribes exactly once` green
  (`quests_bloc_test.dart:202`, 17/17).
- **Review 6/7/8** — `NestType.bodyStrong` reuse, both empty states on the
  20 px gutter (probe: both rects x 20…370), `NestSpacing.s10` for the tile.

## Adversarial probes this iteration

| Area | Result |
|---|---|
| Search round-trip (the BUG-P10-12 fix) | text preserved and applied; clear → full list ✓ |
| Filter semantics sanity | `the` → 7 ideas (all titles containing “the”), `pet` → 1 ✓ |
| Empty states | Active `(0)` and Ideas no-match both x 20…370 ✓ |
| Watcher retry | 1 subscription after a failed load; retry reaches `loaded` ✓ |
| Suites | a11y 20/20, a11y-actions 11/11, view 27/27, widget 16/16, states 19/19, filter 20/20, meta 16/16, repo 10/10, bloc 17/17, geometry 8/9 (hint pin) |
| Rapid double taps / push guard / performAction | Still green (10/10 in `p10_bugs_test.dart`) |
| UI VERDICT RULE measurements (design → app) | title 55…89 → 55…89 (0); segmented 105…157 → 105…157, thumb 109…153 → 109…153 (0); field 173…227 → 173…225 (−2); chip 227…271 → 225…269 (−2); cards 291/375/459/543/627/711 → 289/373/457/541/625/709 (−2 each); tab surface top 726 → 726, bottom design 810 → app 844 (owner edge rule ✓); tab icon 736…760 → 737…761 (+1); label 764…778 → 765…779 (+1); **hint centre 200 → 189 (−11, open)** |
| Back/deep links, kid gate, restart persistence, dark mode, 320 × 1.3, long names, 9999 coins, async mid-push | Unchanged code paths, still green |
| Europe/London + BST, money pence, 0/1/6 children | N/A on P10 |

Process note: the concurrent UI stage left `zz_probe_empty_test.dart` and a
whole-app analyze run picked up its 3 infos; P10-owned files are clean. The
2026-10-03 UI screenshots (`app_*_3.png`) are that stage's.

## Gates at hand-off

- `flutter analyze` → clean for every P10-owned file (3 infos from the other
  stage's temp probe only).
- `dart format --set-exit-if-changed` on the P10 test files → 0 changed.
- `flutter test test/features/quests` → **176 passed, 1 failed** — the failed
  test is the shared BUG-P10-14 pin above.
- `flutter test test/features/quests/p10_bugs_test.dart` → **10/10, no skips**.

