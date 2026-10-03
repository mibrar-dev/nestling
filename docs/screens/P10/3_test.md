# P10 · Quest library (`/quests`) — Stage 3 TEST (iteration 2)

Route `/quests` · feature `quests` · parent mode · in-memory Drift DB with
`Seed.demo()` (12 active quests) and an empty stream for the no-quest path ·
tests pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`.
Tree tested: iteration-1 build checkpoint `de831ed` on `screen/P10`
(`flutter analyze` clean, no `lib/` change made by this stage).

**No screen code was changed.** Every finding below is a failing proof in
`app/test/features/quests/`, left in place.

---

## 1. Tests added / extended

| File | Tests | Result | What it covers |
|---|---:|---|---|
| `quests_bloc_test.dart` (extended) | 15 | 15 ✓ | `blocTest` for every event/state path — initial, loading→loaded, loaded-empty, stream error→failure, second watch emission without a new event (RULES §4), retry after failure; plus `QuestsLoadRequested` payload/equality, `QuestsState` defaults, every `QuestsStatus`, `copyWith` field-by-field (incl. "null means keep", so `errorMessage` cannot be cleared), equality/`hashCode`/`props`. |
| `quest_library_view_test.dart` (extended) | 23 | 23 ✓ | + **responsive matrix**: widths 320/390/430 × light/dark × text scale 1.0/1.3 (12 cases) asserting no overflow/exception, the 20 px gutter on every full-bleed element, `.trow` 68 high at 1.0 and growing at 1.3, the 44 px parent tap-target floor on the segmented control / search field / `+ Add`, and the `+ Add` pill pinned to the card's inner edge; + the shell clamping text scale above 1.3; + the Active tab across all three widths. |
| `quest_idea_meta_test.dart` (**new**) | 16 | 14 ✓ / 2 ✗ | Plan §f item 1: every `QuestsRepository.ideas()` id has metadata and vice versa; meta lines character-for-character (middot U+00B7, never `•` or ` - `); categories ⊆ chip row; `Kindness` is reachable-but-empty by design; min ages, icon assets and tile tints in design order; `Quest.detail` is never used for an idea row; every icon asset is a real bundled 24×24 SVG (`rootBundle`); the Active-tab icon map is total over the seed keys; **every seeded quest gets a tinted tile** (✗ BUG-P10-11); **the same quest keeps one tint across both tabs** (✗ BUG-P10-11). |
| `quest_library_filter_test.dart` (**new**) | 20 | 20 ✓ | Plan §f item 2, the pure `filterQuestIdeas`: identity defaults, unmodifiable result, source never mutated; case-insensitive substring, whitespace trim, no-match → empty (never null), empty list; per-category template sets, `Kindness` → empty, unknown category → empty, metadata-less templates dropped by a category; the two filters combine with **AND**; result order is stable. |
| `quest_library_states_test.dart` (**new**) | 19 | 19 ✓ | Plan §d: the loading spinner (leaf colour, centred, nothing from the body behind it) and loading→loaded; the failure block (whole `Exception: …` message in ink, centred, `Try again`, dark variant) and that `Try again` really re-requests and reaches `loaded`; **both empty states** (`No ideas found` for a no-match query and for the `Kindness` chip, centred, no CTA; `No active quests` / `Add one from Ideas.` with 0 actives); clearing the query / returning to `All` restores the list; tab switching never changes the route; the `Active (N)` label follows a live DB insert (DATA OVER MOCKS); `+ Add` pushes `/quest-editor?idea=<its own id>` per row, an Active row pushes with no query, back returns to `/quests` with the filters intact. |
| `quest_library_a11y_test.dart` (**new**) | 20 | 12 ✓ / 8 ✗ | The semantics contract for every P10-owned control: each segmented option is **one** labelled tappable button with the right `selected` state; every visible chip is a labelled tappable button whose selection moves; `+ Add` is its own node named after the idea; an Active row is a tappable button whose label keeps the meta line; the search field is a labelled text field with a ≥44 px height and is reachable; row icons carry no label; the route anchor stays out of the a11y tree; 44 px tap targets; taps 1 px inside the pill's top and bottom edges land; the whole contract again in dark. **8 fail → BUG-P10-9 / BUG-P10-10.** |
| `p10_bugs_test.dart` (bug stage's file) | 9 | 0 ✓ / 9 ✗ | **Un-skipped.** The bug hunt left every group behind `skip:` so the suite stayed green; the loop forbids skipping tests, so the markers are gone and each proof now runs. All nine fail → BUG-P10-1…8. |

Untouched from iteration 1: `quest_library_widget_test.dart` (16 ✓) and
`quests_repository_test.dart` (10 ✓).

Totals for `test/features/quests/`: **148 tests** (was 41), **129 pass /
19 fail**.

---

## 2. Results

```
$ dart format --set-exit-if-changed .
Formatted 415 files (0 changed) in 0.93 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 2.5s)

$ flutter test              # whole app
+1471 -19: Some tests failed.

$ flutter test test/features/quests/
+129 -19: Some tests failed.
```

All 19 failures are in P10 and are the bug proofs listed in §3. **No other
feature's tests broke** (P08's `today_view_test.dart` navigation anchors still
pass against `_QuestLibraryRouteAnchor`), and no test was skipped.

Two test-authoring traps worth recording for the next iteration:

- `disposeApp(tester)` is required after **any** test that pumps the app or a
  bloc over a real Drift repository. Without it the run hangs at
  "A Timer is still pending" rather than failing cleanly. With a mocked
  repository the same drain is still needed in the tear-down **after**
  `bloc.close()` (tear-downs run last-registered-first).
- `StreamController.close()` must not be awaited in a tear-down registered
  before `bloc.close()`: `close()` only completes once the bloc's
  `emit.forEach` subscription has been dropped, so awaiting deadlocks.

---

## 3. Bugs found

`BUG-P10-1…8` are the bug hunt's, confirmed still open by the now-un-skipped
proofs in `p10_bugs_test.dart`. The rest are new.

### BUG-P10-9 — MAJOR — every P10 chip / `+ Add` / Active row is invisible to assistive tech

**Files**

- `app/lib/features/quests/presentation/widgets/quest_filter_chip.dart:29-33`
- `app/lib/features/quests/presentation/widgets/quest_idea_row.dart:145-149` (`+ Add`)
- `app/lib/features/quests/presentation/widgets/quest_idea_row.dart:123-128` (Active row)

**Cause.** `Semantics(button: true, label: …, excludeSemantics: true, child:
Material(… InkWell(onTap: …)))`. `excludeSemantics: true` drops the subtree,
and `InkWell` is the only source of `SemanticsAction.tap` (it builds its own
`Semantics(onTap: …)` inside). The node announces `isButton` with the right
label and **no `tap` action**, so VoiceOver/TalkBack double-tap does nothing.
Worse on the real tree: the `Semantics` has `container: false`, so on an Ideas
row the `+ Add` node merges into the row's node and the control has **no node
of its own** at all.

**Repro (tests).** `flutter test test/features/quests/quest_library_a11y_test.dart`

```
"every visible chip is a tappable button with its own label"   → hasAction(tap) is false
"it is one tappable button named after the idea"               → find.bySemanticsLabel('Add Make your bed') found 0
"a row is one tappable button naming the quest and its meta"   → hasAction(tap) is false
```

**Independent measurement** (`debugDumpSemanticsTree()` on `/quests`):

```
SemanticsNode#33  flags: isButton, isImage
  label: "Make your bed\n5 coins · Ages 4+ · Bedroom\nAdd Make your bed"
  (no `actions:` line, i.e. no tap action)
```

Isolated controls, against a plain `InkWell` reference:

```
QuestFilterChip "All"              → label=All       actions=[]          isButton=true
QuestAddButton  "Add Make your bed"→ label=Add …     actions=[]          isButton=true
NestChip         "All"             → label=All       actions=[]          isButton=true
plain InkWell    "Plain"           → label=Plain     actions=[tap,focus] isButton=false
```

**Fix (P10's own files).** Move the `Semantics` *inside* the `InkWell` — the
pattern P08 already uses for its avatar button
(`app/lib/features/today/presentation/widgets/today_loaded_body.dart:424-437`).
Give the Active row's label both lines (`'$title. $meta'`), which also closes
review finding 8. Same root cause exists in the shared `NestChip`
(`app/lib/core/design_system/components/nest_chip.dart:119-137`), so
`SHARED_REQUEST.md` §5 asks for the design-system fix too.

### BUG-P10-10 — MAJOR — the segmented control announces every option twice

**File** `app/lib/core/design_system/components/nest_segmented.dart:51-55`
(shared; surfaced by P10, used by P09/P12/P16 as well).

**Cause.** The per-option `Semantics(button: true, label: option.label, …)` has
no `excludeSemantics: true`, so the option's own `Text(option.label)`
(`:73`) merges into the same node and Flutter concatenates them.

**Repro (test).** `P10 segmented control each option is one labelled, tappable
button` — `find.bySemanticsLabel('Ideas')` finds **0** widgets. The node's
label is:

```
"Active (12)\nActive (12)"   and   "Ideas\nIdeas"
```

`NestChip` documents and avoids exactly this (`nest_chip.dart:119-121`).

**Fix.** Shared — `SHARED_REQUEST.md` §1. `excludeSemantics: true` on the
option's `Semantics`.

### BUG-P10-11 — MINOR — "Lay the table" changes tile colour between the tabs

**File** `app/lib/features/quests/presentation/widgets/quest_idea_meta.dart`
(`questTileTintFor`, `default:` at `:195`).

**Cause.** The seed's `quests.icon` key `plate` (used by `q-table`,
"Lay the table") has no case in `questTileTintFor`, so it falls through to
`NestTileTint.neutral` (surface-2). The same quest on the **Ideas** tab comes
from `kQuestIdeaMeta['idea-table']`, which is `NestTileTint.sky`. `sofa`
(`q-living`, "Tidy the living room") is also unmapped.

**Repro (tests).**

```
every seeded quest gets a tinted tile, never the grey default
  → icon key `plate` renders an untinted tile
the same quest title keeps one tile tint across both tabs
  → `plate` (Active) vs `idea-table` (Ideas): neutral vs sky
```

Measured tile colours: Ideas `Lay the table` = `skyTint`
`rgb(0.902, 0.937, 0.996)`; Active `q-table` = `surface2`
`rgb(0.953, 0.933, 0.898)` — same title, same `ic_table.svg`, different pill.

**Fix.** Add `case 'plate': return NestTileTint.sky;` (P08's `todayTintFor`
uses lilac there, so the two screens also disagree — worth settling in the
same pass) and a `case 'sofa':` so no seeded quest falls through to neutral.
The doc comment on `questTileTintFor` claims "Same mapping P08 uses"; it is
currently false for `plate`, `bag`, `shirt`, `sofa` and the default.

---

## 4. Mandatory ORCHESTRATOR_NOTES items — where each one now stands

`ORCHESTRATOR_NOTES.md` exists, so every item is mandatory. Status after this
stage (no screen code touched, so each is pinned by a test rather than fixed):

| Item | Status |
|---|---|
| 1 · idea-row text left-aligned at card x+64 | pinned by `p10_bugs_test.dart` BUG-P10-2 (**failing**) — review finding 1 |
| 2 · search icon slot / hint x / field height | pinned by BUG-P10-5 (**failing**) + `SHARED_REQUEST.md` §3 |
| 3 · segmented track 52/44 | pinned by BUG-P10-6 (**failing**) + `SHARED_REQUEST.md` §2 |
| 4 · chips row / first card y | follows items 2–3; asserted in BUG-P10-6's 16/0/16 chain (**failing**) |
| 5 · tab-bar content 34 px low | pinned by BUG-P10-7 (**failing**) + `SHARED_REQUEST.md` §4 |
| 6 · the 6th card peeks under the bar | already satisfied (the list scrolls under the shell's bar; `5_ui.md` confirmed) |
| 7 · real-font (FontLoader) geometry test at 390×844 | **done** — `p10_bugs_test.dart` loads Inter + Nunito through `FontLoader` in `setUpAll` and pins items 1–5 |

`SHARED_REQUEST.md` (new) carries the measured numbers for items 2, 3 and 5
plus the two semantics items, so `1_plan.md` §g "SHARED_REQUEST: None" is now
out of date.

---

## 5. Review-finding test gaps closed

From `4_review.md` finding 9 (all were missing):

- failure branch + `Try again` retry → `quest_library_states_test.dart`
- both empty states (`Kindness`/no-match, and Active with 0 quests) → same file
- direct `filterQuestIdeas` unit test (the AND combination) →
  `quest_library_filter_test.dart`
- plan §f item 1 (all 10 repo ids + copy char-for-char + categories ⊆ chips) →
  `quest_idea_meta_test.dart`

---

## 6. Owner rules checked by the new tests

- **No skipped tests** — the bug hunt's `skip:` markers are gone.
- **`google_fonts`** — 0 occurrences in `lib/features/quests` and
  `test/features/quests`; no `GoogleFonts.*` call.
- **CHIP ROWS / tap targets** — every chip, the `+ Add` pill, the segmented
  control and the search field are asserted ≥ 44 px (parent mode) in the
  responsive matrix; taps 1 px inside a pill's top and bottom edges are proven
  to land. The `.chipscroll` row scrolls and its pills are already 44 high, so
  `NestChipWrap`'s 6 px slop is not needed — P10 does not use `NestChip`.
- **UI CHECK MEASURES SHAPES** — the matrix asserts card, pill, field and
  segmented *rects* (x/y/w/h), not text positions.
- **ALIGNMENT** — the 20 px gutter is asserted for the title, segmented,
  search, chips and every card at 320/390/430, in both themes.
- **COPY** — the 10 `.trow .mt` lines are asserted character-for-character,
  including that the separator is U+00B7 and never `•` or ` - `.
- **DATA OVER MOCKS** — `Active (12)` comes from the stream and is re-checked
  after a live insert (`Active (13)`).
- **Simulators** — none booted, installed on, screenshotted or driven by this
  stage.

---

## 7. Verdict

19 proofs fail, covering 11 distinct defects (8 from the bug hunt + 3 new,
one of which needs a shared fix). No screen code was patched, as instructed.
The verdict cannot be PASS until the failing proofs are green.

VERDICT: FAIL
