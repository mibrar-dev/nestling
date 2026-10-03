# P10 · Stage 2b — build, UI chunk (iteration 3)

Scope: `app/lib/features/quests/presentation/views/**` +
`presentation/widgets/**` for P10, plus the UI-layer proofs
(`*view*`, `*widget*`, geometry, a11y-actions). No `domain/`, `data/` or
`bloc/` file was touched by me — the logic builder's parallel stage owns those.

## CONTRACT CHANGES re-read

`2a_build_logic.md` (and the iteration-3 `CONTRACT CHANGES` it carries):
`QuestsState` gains `ideas`, the view takes `QuestLibraryBody(items:,
ideas:)` and must not probe the service locator. **Already implemented on this
branch before I started** — `quest_library_view.dart:61` passes `state.ideas`
and has no `get_it` import. No widget signature changed, so nothing in the UI
layer needed re-plumbing. `git diff` on my files confirms no signature change.

## FIXES_2 triage — every item

### FIXES_2 §4_review finding 2 · BUG-P10-12 — MAJOR — **FIXED**
`quest_library_body.dart`. The applied search filter went invisible after a tab
round-trip: the search field is only built while `filtersOn` (BUG-P10-3), which
disposed the `EditableText` state while `_query` survived, so the parent came
back to an empty box with 9 of 10 ideas hidden. `_QuestLibraryBodyState` now
owns a `TextEditingController` (`_search`), passes it to
`NestTextField.search(controller:)` and disposes it; `_query` stays derived
from `onChanged`. The field now always shows the query that is actually
applied — which is also what the design implies, since the filters persist
across a tab switch.
Proof: `p10_bugs_test.dart` → `returning to Ideas can show a query that hides
rows` — **was already un-skipped and red; now green**, and it takes the
"keeps showing the query" branch (`fieldText == 'pet'`, `Feed the pet` present,
`Make your bed` gone).

### FIXES_2 §4_review finding 6 — MINOR — **FIXED**
`quest_idea_row.dart:83`. The row title rebuilt `bodyStrong` by hand
(`NestType.body(...).copyWith(fontWeight: w700)`). Now
`NestType.bodyStrong(color: tokens.ink).copyWith(height: 22 / 16)` — identical
pixels, no duplicated weight literal to drift, and the same call
`NestQuestCard` / `NestListRow` use.

### FIXES_2 §4_review finding 7 — MINOR — **FIXED**
`quest_library_body.dart`. The Active `NestEmptyState` had no `_gutter`, so it
started 16 px from the screen edge while the Ideas one started at 36 px. Both
empty states now share the screen's 20 px gutter (OWNER ALIGNMENT rule).

### FIXES_2 §4_review finding 8 — MINOR — **FIXED**
`quest_idea_row.dart:60`. The icon tile's `width: 40, height: 40` literals are
now `NestSpacing.s10` (== 40) — tokens only. The shared `NestTile` size token
(SHARED_REQUEST §6/§7) stays optional, not blocking.

### FIXES_2 §4_review advisory 1 — **FIXED**
`quest_library_a11y_actions_test.dart`, `search field setting the field value
really filters the list`. The proof asserted `SemanticsAction.setText` on the
`TextField` node. Measured in this Flutter build, that node carries **neither
`setText` nor `tap`** (only `focus`) — the framework baseline the review
described — so the assertion could never pass and would report a defect that
does not exist. Rewritten to assert what P10 owns: the node is a text field,
the design's `aria-label="Search quest ideas"` is in the tree exactly once,
and typing really filters the list (`Feed the pet` in, `Make your bed` out).
The ACTION half is therefore still proved end-to-end.

### FIXES_2 §4_review advisory 2 — **PARTLY**
`quest_library_design_geometry_test.dart` still pins `field.height` at `54 ± 2`,
which passes at 52 and so locks finding 4's 2 px shift in as "correct". The
tolerance stays until the shared box model lands; tightening it now would make
the suite red for a fix that is not mine. **LEFT** — see below.

### FIXES_2 §4_review finding 1 · BUG-P10-10 — **NOT MINE, now landed**
`NestSegmented` announced every option label twice. `core/`, which RULES §1
forbids me from editing — SHARED_REQUEST §1. It landed on `main` mid-stage
(`0cdb53c`, `excludeSemantics: true` at `nest_segmented.dart:63`). All three
proofs in `quest_library_a11y_test.dart` are **green**. No local workaround
taken, exactly as instructed.

### FIXES_2 §4_review finding 3 — **NOT MINE**
The `Try again` watcher leak is in `quests_bloc.dart` (logic builder's file).
The logic builder landed `_closeOnError` mid-stage and its proof
`a failed load releases its watcher so retry subscribes exactly once` is
**green**. Nothing for me to do.

### FIXES_2 §4_review findings 4 and 5 — **NOT MINE, filed, red**
Both are in `core/design_system/components/nest_text_field.dart`:
- §4 the search row renders 52 where `.search` computes to 54 (SHARED §9).
- §5 the aria-label lands on an inert wrapper node (SHARED §8).
Not hacked locally; §5 is now asserted as "the label is in the tree once",
which is the half P10 owns, and the merge half stays filed.

### FIXES_2 §3_test BUG-P10-12 / §6_bugs BUG-P10-12 — **FIXED** (same item as above)
### FIXES_2 §3_test BUG-P10-13 — **re-scoped, shared half open** (SHARED §8)
### FIXES_2 §3_test BUG-P10-10 — **landed on main** (above)

## NEW BUG found and filed — BUG-P10-14 · MAJOR (shared)

ORCHESTRATOR_NOTES 12:17 items 1 + 3 were mandatory and were not yet
addressed by any stage: the search hint is **not vertically centred**.

Measured at 390×844 with the 47/34 insets and the bundled Inter face:

```
FIELD     173.0 … 225.0   centre 199.0   (52 tall)
ICON      187.0 … 211.0   centre 199.0   ← the magnifier IS centred
TEXTFIELD 177.0 … 221.0   centre 199.0   (44 tall — the design's `input`)
HINT      177.0 … 201.0   centre 189.0   ← 10 px high
```

The design's `--line` ring spans 173…227, so its centre is y **200** and the
design's hint ink sits there, level with the icon. **Cause is in `core/`**
(`nest_text_field.dart:167-193`: the tight 44-high `SizedBox` plus
`textAlignVertical` centres within the editable's *intrinsic* 24 px line box,
which is painted at the top of the slot), so per RULES §1 and the note's own
instruction I did **not** patch it locally — filed as **SHARED_REQUEST §10**
with the measured numbers and a suggested fix.

Proof added, red on purpose, pinned at the design value rather than the app's:
`quest_library_design_geometry_test.dart` →
`the hint is centred in the field, not floated to the top`. It asserts the hint
centre at 200 ±1 and within 2 px of the field centre. It uses the design
number, so it composes with §9 (54 tall) and turns green when either lands.
`the magnifier is centred in the field` pins the icon at the field centre, so
the fix cannot be paid for by moving the icon.

## Skipped tests

None. No `skip:` marker exists anywhere in `test/features/quests/`
(grep-verified). The only red test is the one red proof above, which asserts a
real defect in shared code and is documented as such.

## Verification (this stage only — no simulator, per SIMULATORS rule)

- `dart format --set-exit-if-changed lib/features/quests test/features/quests`
  → 30 files, 0 changed.
- `flutter analyze lib/features/quests test/features/quests` → **No issues
  found** (no ignores).
- `flutter test test/features/quests` → **176 pass, 1 fail** — the single fail
  is the BUG-P10-14 pin above. Before this stage: 170 pass, 6 fail.
- Per file: `p10_bugs_test` 10/10, `quest_library_a11y_actions_test` 11/11,
  `quest_library_a11y_test` 20/20, `quest_library_view_test` 27/27,
  `quest_library_widget_test` 16/16, `quest_library_states_test` 19/19,
  `quests_bloc_test` 17/17, `quest_library_filter_test`,
  `quest_library_design_geometry_test` (all but the new pin),
  `quest_idea_meta_test`, `quests_repository_test`.
- No `google_fonts` / `GoogleFonts.*` anywhere in the feature's lib or tests.
- `git diff --name-only` on my scope: `quest_idea_row.dart`,
  `quest_library_body.dart`, `quest_library_a11y_actions_test.dart`,
  `quest_library_design_geometry_test.dart` (+ `SHARED_REQUEST.md`). The fifth
  modified file, `quests_bloc_test.dart`, is the logic builder's, not mine.
- Whole-app `flutter test` and the simulator are the integrator's; not run.

## Owner rules checked

- **PIP** N/A — no Pip on P10.
- **BOTTOM EDGE** — the view adds nothing below its content; `ParentShell`'s
  tab bar surface runs to the physical edge. Pinned by
  `content keeps the design y while the surface runs to the edge` (bar.top 726
  ±2, bar.bottom 844, in both light and dark). No coloured strip.
- **ALIGNMENT** — 20 px side gutters on every child via `_gutter`; the chip row
  bleeds to −20/+20 only because the design does. Both empty states now share
  the 20 px gutter (finding 7).
- **CHILD ORDER** — Active rows come from `QuestsRepository` in creation order
  (Maya's 6, then Leo's 4, then the 2 Anyone quests); the view does no sorting.
- **DATA OVER MOCKS** — the segmented label is `Active (${widget.items.length})`;
  no literal `12` in the view.
- **COPY** — `Quests`, `Active ({n})`/`Ideas`, `Search ideas`,
  `Search quest ideas`, the seven chips in design order, `+ Add`,
  `Add {title}`, and the `{n} coins · Ages {a}+ · {Category}` meta strings
  (U+00B7) are unchanged by this stage and still character-for-character
  against `design/html-source/screens/P10-quest-library.html`.
- **LETTER SPACING** — no tracking added anywhere; `NestType` defaults stand.
- **BALANCED HEADINGS** — `.ptitle` sets no `text-wrap: balance`, so the plain
  `Text('Quests')` is correct; no `NestBalancedText` on this screen.
- **CHIP ROWS** — `QuestCategoryChips` is a horizontal `SingleChildScrollView`,
  not `NestChipWrap`: the row scrolls rather than wraps, and each pill is
  already 44 high (`QuestFilterChip`), so there is no separate 44 px hit area
  to preserve. `NestChipWrap` would reintroduce the wrap the design does not
  have.
- **ACCESSIBILITY ACTIONS** — every interactive control keeps `Semantics
  (excludeSemantics: true, container: true, onTap:)`, so `performAction(tap)`
  still drives the real behaviour (11/11 proofs green). The search field's
  own node is a real text field; the aria-label is announced exactly once.
- **TRIAL** — N/A, no subscription field on this screen.

## LEFT FOR NEXT ITERATION

1. **BUG-P10-14 / SHARED_REQUEST §10** — the search hint 10 px above the
   field centre. Needs the orchestrator to land the `core/` fix
   (`nest_text_field.dart`); then the red pin goes green on its own.
2. **SHARED_REQUEST §9** — the search row is 52 where the design computes 54,
   which leaves the chip row and all ten cards a uniform 2 px high. Also
   `core/`. Once it lands, tighten
   `quest_library_design_geometry_test.dart` → `the search field sits on the
   design y` from `54 ± 2` to exact or ±1 (review advisory 2) so the drift
   cannot come back.
3. **SHARED_REQUEST §8** — the search field's `aria-label` still lands on the
   shared wrapper rather than merging into the editable node. The test now
   asserts the label is in the tree once; when §8 lands, assert
   `getSemanticsData().label == 'Search quest ideas'` on the `TextField` node
   itself.
4. `quest_library_design_geometry_test.dart` is not a `view`/`widget`-named
   file, so it sat outside my declared test ownership. It is UI-layer work
   (the ORCHESTRATOR_NOTES 12:17 mandatory pin) and no one else was editing
   it; flagging the boundary rather than hiding it.

VERDICT: PASS