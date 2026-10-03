# Fix list after iteration 1

## From 3_test.md
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


## From 4_review.md
# P10 · Quest library (`/quests`) — Stage 4 QA code review (iteration 1)

Scope: `git diff main...HEAD` (branch `screen/P10`) = 6 `presentation/` files +
4 new `test/features/quests/` files. No code edited during this stage.

Reviewed against: `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P10, `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P10-quest-library.html`,
`design/screens/light|dark/P10-quest-library.png`,
`app/lib/core/design_system/`, `1_plan.md`,
`ORCHESTRATOR_NOTES.md` (mandatory — all 7 items accounted for below).

## What is solid (no action)

- **Rule compliance (RULES §1)**: only
  `app/lib/features/quests/presentation/**`,
  `app/test/features/quests/**` and `docs/screens/P10/**` are touched. No
  `core/`, no `app/`, no other feature, no `tools/screens/`.
- **No hard-coded design values**: the diff adds no literal colour
  (`Colors.transparent` only, matching `NestChip`'s own transparent border),
  no `fontSize`, no `letterSpacing` — the LETTER-SPACING rule is respected
  (`NestType` defaults to 0; no Material tracking re-added).
- **No `google_fonts` / `GoogleFonts`** anywhere in the feature or its tests.
- **Design system reused, not re-implemented**: `NestSegmented`,
  `NestTextField`, `NestButton`, `NestEmptyState`, `NestIcon`, `NestRadii`,
  `NestSpacing`, `NestTileTint`, `tokens.cardShadow`. `.trow` is *not*
  `NestListRow` (that is `.list-row`: `12/10/16/10`, r-12 tile, shadow on the
  list, not the row) so a feature-private row is correct; `QuestFilterChip`
  is correctly 44-high per SPACING_SPEC §9.5 rather than `NestChip`'s 32.
- **Copy** matches the HTML character-for-character (middot U+00B7 in the
  meta lines, `+ Add`, `Search ideas`, `Search quest ideas`, chip labels,
  `Active ({count})` from the stream).
- **DATA OVER MOCKS**: `Active (12)` is built from `state.items.length`
  (`quest_library_body.dart:80`), never a literal.
- **Streams**: the bloc keeps `emit.forEach` (RULES §4); nothing is disposed
  by P10; no `Timer`/`AnimationController`; no rebuild storm (10 rows, one
  `setState` per keystroke over a `const` list).
- **Children's Code**: parent screen, no analytics/ads/telemetry, no child
  data beyond quest rows from the family-scoped query.
- **Owner's ALIGNMENT/BOTTOM-EDGE rules**: 20 px gutters on title, segmented,
  search and every row; the chip row bleeds by design; the view paints
  nothing below the content (the shell's tab bar runs to the edge — 5_ui
  confirmed).
- **Verification I ran myself** (no simulator): `dart format
  --set-exit-if-changed` clean on all 10 committed Dart files; `flutter
  analyze` reports **0 issues in the committed P10 files**; `flutter test`
  on the 4 committed test files → **41 tests pass**.

---

## Findings

### 1. MAJOR — `.trow` text block is centred; design is left-aligned
`app/lib/features/quests/presentation/widgets/quest_idea_row.dart:71-93`
(the `Expanded > Column`).

`Column`'s `crossAxisAlignment` defaults to `CrossAxisAlignment.center`, so
the title and the meta line are centred inside the flexible column instead of
starting at the tile gap. `.trow .main{flex:1;min-width:0}` with block-level
`.nm`/`.mt` is start-aligned: both lines must start at card x + 12 (pad) +
40 (tile) + 12 (gap) = **+64 from the card's left edge** (20 + 64 = 84 dp
absolute on a 390 screen).

Evidence: `design/screens/light/P10-quest-library.png` has `Make your bed`
starting at x ≈ 84 dp; `docs/screens/P10/ui/app_light_1.png` has it at
x ≈ 121 dp on every row, both themes. Independently measured by stage 5
(`5_ui.md` deviation 1) and pinned by ORCHESTRATOR_NOTES item 1.

**Fix**: add `crossAxisAlignment: CrossAxisAlignment.start` to that `Column`
(keep `maxLines: 1` + ellipsis). Add a geometry assertion so it cannot
regress: in `quest_library_widget_test.dart`, assert
`tester.getTopLeft(find.text('Make your bed')).dx == rect.left + 64`
(the "UI CHECK MEASURES SHAPES" rule — the existing tests check the card, the
fill and the type, but never the text x).

### 2. MAJOR — the view resolves its data through the global service locator, with a silent-empty fallback
`app/lib/features/quests/presentation/views/quest_library_view.dart:69`
and `:85-92` (`_ideaTemplates()`).

`QuestLibraryView` is the **only** view in the app that touches
`GetIt.instance`: `grep -rn GetIt app/lib/features/*/presentation` hits
`quests` and nothing else. Every other feature keeps `get_it` in
`<feature>_di.dart` + `<feature>_routes.dart` and lets the bloc own all
repository access (ARCHITECTURE: "BLoC for state, get_it for DI"; per-feature
contract — `presentation/` = bloc + views + widgets).

Two defects in one method:
- **Silent degradation**: `isRegistered` → `const <Quest>[]` renders the
  "No ideas found" empty state. A DI-ordering mistake or a partially built
  scope produces a wrong-looking screen instead of a loud failure.
- **Per-build lookup**: `_ideaTemplates()` runs on every `BlocBuilder` build
  (every stream emission and every status transition) inside the builder.

**Fix**: make the bloc the only holder of the repository and put the
templates in `QuestsState` — `QuestsState(status, items, ideas,
errorMessage)` populated in `_onLoadRequested` from
`_repository.ideas()`, `QuestLibraryBody(items: state.items, ideas:
state.ideas)`. All of that is inside `features/quests/presentation/**`
(allowed by RULES §1) and matches how every other feature loads data. Delete
the `get_it` import from the view.

### 3. MAJOR — search field geometry: the prefix icon slot is 48 px wide, so the icon is oversized and the hint starts ~10–14 px right of the design
`app/lib/features/quests/presentation/widgets/quest_library_body.dart:98`.

`.search` is `display:flex; gap:10px; padding:4px 16px; min-height:52px` with
a 24 px icon: icon at field x = 16, hint text at field x = 16 + 24 + 10 =
**50** (absolute ≈ 70–73 on a 390 screen). `NestTextField` forwards the widget
to Material's `InputDecoration.prefixIcon`, whose default
`prefixIconConstraints` floor the slot at 48 px, so the 24 px `NestIcon` sits
centred in 48 and the hint starts at 16 + 48 = 64 (absolute ≈ 84) — the drift
stage 5 measured and ORCHESTRATOR_NOTES item 2 demands be closed.

**Fix (needs a shared change — file `docs/screens/P10/SHARED_REQUEST.md`, do
not hack `core/`)**: expose `prefixIconConstraints` on `NestTextField` (pass
it through to `InputDecoration`), then in P10 pass
`prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 44)`
together with a 24 px `NestIcon` so the icon starts at field x = 16 and the
hint at x = 50. Material centres the child inside the slot, so pin the result
with the geometry test requested by ORCHESTRATOR_NOTES (item 6: a
real-font `FontLoader` test) rather than trusting the arithmetic. If the
shared change cannot land this iteration, keep the TODO and add the pinning
test so the drift cannot regress silently.

### 4. MINOR — mandatory ORCHESTRATOR_NOTES items 3 and 5 need a SHARED_REQUEST that does not exist yet
`docs/screens/P10/SHARED_REQUEST.md` (missing).

Items 3 (`NestSegmented` track 44 vs `.segmented` 48 = 4 pad + 40 button) and
5 (`NestTabBar` content 34 px lower than the design, surface must still run
to the edge) are both **shared-component** geometry. Neither can be fixed in
`features/quests/**`. `1_plan.md` §g says "SHARED_REQUEST: None", which is now
out of date. File one request carrying the measured numbers from
ORCHESTRATOR_NOTES (design y 109–155 vs app 108–148; design tab icon centre
y ≈ 749 / label ≈ 772 vs app ≈ 783 / 806) so the orchestrator can batch it,
and update §g.

### 5. MINOR — hidden `_QuestLibraryRouteAnchor` ships test scaffolding in the product tree
`quest_library_view.dart:74-78` + `:95-122`.

A zero-opacity `Text('P10 Quest library')` exists only so P08's stale
assertions (`app/test/features/today/today_view_test.dart:286-289`, `:335`,
which are outside RULES §1 and cannot be edited here) keep passing. It is
fully documented and paints nothing, so runtime risk is nil — but it puts a
fake node in the shipped tree, and any future `find.text('P10 Quest
library')` anywhere in the app will "pass" against an invisible widget.

**Fix**: file the shared request (same file as finding 4) asking the
orchestrator to move those two assertions to the documented
`pushedPath(tester)` helper (`app/test/test_scope.dart`), then delete
`_QuestLibraryRouteAnchor` **and** the `Stack(fit: StackFit.passthrough)`
wrapper at `:30-80`, which exists only to host it. Keep the `TODO(P10)`
until then.

### 6. MINOR — `.chipscroll`'s right-edge fade mask is missing
`quest_category_chips.dart:31-40`.

The CSS is
`mask-image: linear-gradient(to right, var(--ink) calc(100% - 24px), transparent 100%)`;
the design PNG shows `Pets` fading out at the right edge. The load-bearing
`padding: 0 20px 4px` is implemented; the fade is not. **Fix**: wrap the
scroll view in a `ShaderMask` with that exact gradient (`BlendMode.dstIn`),
or record it as an accepted deviation in the stage notes.

### 7. MINOR — `NestBalancedText` used where the design sets no `text-wrap: balance`
`quest_library_body.dart:61`.

The BALANCED HEADINGS rule scopes `NestBalancedText` to `.display`, `.h1`,
`.kid-title`, `.kid-hero` and screen-local `.balance`. `.ptitle` is a
screen-local style (`font-family/weight/size/line-height/padding-top` only)
with no `text-wrap`, and it is not `.h1`. Today it is inert — one word with
`maxLines: 1` short-circuits to a plain `Text` inside
`NestBalancedText.build` (`nest_balanced_text.dart:123`) — but it adds a
`LayoutBuilder` + a `TextPainter` pass per rebuild and reads as if the CSS had
a balance rule it does not have. **Fix**: use a plain `Text('Quests', style:
NestType.h1(color: tokens.ink), maxLines: 1)` (keep the style assertions in
`quest_library_view_test.dart:53-61`, which pass either way).

### 8. MINOR — Active-row semantics drop the meta line
`quest_idea_row.dart:122-128`.

`Semantics(button: true, label: title, excludeSemantics: true)` hides the
`Daily · 5 coins` subtitle, so a screen-reader user activating a quest hears
only its name. **Fix**: `label: '$title. $meta'` (or drop
`excludeSemantics: true` and let both texts merge).

### 9. MINOR — test gaps against `1_plan.md` §d/§f
`app/test/features/quests/`

- no test for the **failure** branch and its `Try again` retry
  (`quest_library_view.dart:41-65`); the bloc-level failure/retry *is*
  covered (`quests_bloc_test.dart:67`, `:132`), the view's `Try again`
  button is not.
- no view test for the two **empty states** the plan requires:
  `Kindness` → "No ideas found" (`quest_library_body.dart:139-149`) and
  Active + `Seed.empty()` → "No active quests" (`:120-126`).
- plan §f item 2 asked for a direct unit test of the pure
  `filterQuestIdeas` (query/category AND, `Kindness` → empty, empty query +
  `All` → 10); it is only covered indirectly through the view, which cannot
  prove the AND-combination.
**Fix**: three small tests in the existing files; no production change.

### 10. MINOR — the Active tab lists quests title-sorted, interleaving children
`app/test/features/quests/quests_repository_test.dart:26-49`
(`'demo seed actives arrive title-sorted'`).

The new test codifies `AppDatabase.watchActiveQuests`'s
`orderBy([(q) => OrderingTerm(expression: q.title)])`, so Maya's, Leo's and
"Anyone" quests interleave alphabetically. The CHILD ORDER ruling wants
children in the order they were added. The order itself lives in
`core/data/app_database.dart:447` (shared, not editable here), so this is a
question for the orchestrator, not a P10 edit — but P10 should not *pin*
alphabetical order in a test before that ruling is confirmed. **Fix**:
raise it in the same SHARED_REQUEST (finding 4) and, if the ruling changes
the order, update this test at the same time.

### 11. MINOR — `initialTab` is read once and never re-read
`quest_library_body.dart:37` — `late QuestLibraryTab _tab = widget.initialTab;`
caches the value on first access, so a parent that changes `initialTab` is
ignored (no caller does today). **Fix**: either drop the parameter (the
design always opens on Ideas) or handle it in `didUpdateWidget`.

---

## Advisory (not a finding — process, per the loop's rules)

`app/test/features/quests/` currently holds untracked scratch files written by
another stage while this review ran: `_scratch_test.dart`,
`p10_bugs_test.dart`, `zz_probe_test.dart`, `zz_probe2_test.dart`,
`zz_probe3_test.dart`. They are unformatted and produce all 33 `flutter
analyze` infos in the package. Uncommitted work is the loop's business, but
`zz_probe*`/`_scratch*` must not be committed — they would break RULES §7.1
(`dart format` clean, `flutter analyze` → no issues) for the whole repo.

## Verdict

Two design-fidelity majors (1, 3), one architecture major (2). Findings 1 and
3 are the two ORCHESTRATOR_NOTES items that live in P10's own code; finding 2
breaks the one app-wide DI convention the feature contract defines. All three
are small, local fixes except the shared half of 3, which needs
`SHARED_REQUEST.md` (finding 4).


## From 5_ui.md
# P10 · Quest library (`/quests`) — Stage 5 UI check (iteration 1)

Route `/quests`, mode parent, child maya, seed demo, simulator E7D5555E-378A-49DF-AAEE-16677AF4B9DB.
Design: `design/screens/light|dark/P10-quest-library.png` (1170×2532 @3x = 390×844 logical).
App shots: `docs/screens/P10/ui/app_light_1.png`, `docs/screens/P10/ui/app_dark_1.png`.
Compare sheets: `docs/screens/P10/ui/cmp_light_1.png`, `docs/screens/P10/ui/cmp_dark_1.png`.

Note: the first dark capture landed on the wrong route (kid home). Retaken with the
same command; the file now shows `/quests` in dark theme.

Mean diff (compare.py, design vs app):
- light: 6.47% (bands: 0: 1.65, 1: 3.40, 2: 7.46, 3: 8.80, 4: 7.61, 5: 8.24, 6: 8.62, 7: 5.99)
- dark: 6.27% (bands: 0: 1.65, 1: 3.37, 2: 7.52, 3: 8.35, 4: 7.29, 5: 7.82, 6: 8.33, 7: 5.81)

Status-bar time/glyph differences ignored per orchestrator (NestStatusBar reserves height only).
Bottom edge: app runs the tab-bar surface to the physical edge in both themes — correct
per OWNER RULE (overrides the design's tinted strip). Not a deviation.
`Active (12)` matches the seeded DB (12) — correct per DATA OVER MOCKS.
Copy/order verified against `design/html-source/screens/P10-quest-library.html`:
title `Quests`, segmented `Active (12)` / `Ideas` (Ideas selected), hint `Search ideas`,
chips `All, Bedroom, Kitchen, Outdoors, …` (All selected), rows in design order with
`{coins} coins · Ages {age}+ · {Category}` meta (middot U+00B7) and `+ Add` buttons.
No Pip on this screen (PIP N/A). No overflow, clipping, or ellipsis faults on screen.
Dark-mode tiles stay tinted and `+ Add` stays leaf-tint/leaf-ink — correct.

## Deviations

1. Idea-row title + meta are horizontally centered; design is left-aligned (MAJOR, both themes).
   - Design: `.trow .main{flex:1 min-width:0}`, `.nm`/`.mt` default start-aligned —
     text block starts at card x = 12 (pad) + 40 (tile) + 12 (gap) = 64 from card
     left edge, both lines left edges equal.
   - App (`app_light_1.png`, `app_dark_1.png`, every `.trow`): `Make your bed` /
     `5 coins · Ages 4+ · Bedroom` (and all rows below) are centered in the middle
     column instead of starting at the tile gap. Visible in the diff sheets as doubled
     title/meta ghosts in bands 2–6 (≈7–9% band diff).
   - Fix: `app/lib/features/quests/presentation/widgets/quest_idea_row.dart:71-93` —
     the `Expanded > Column` defaults to `CrossAxisAlignment.center`. Add
     `crossAxisAlignment: CrossAxisAlignment.start` (texts default to start alignment;
     keep `maxLines: 1, overflow: ellipsis`).

2. Search field icon box too wide; hint text starts right of design (MAJOR, both themes).
   - Design: `.search{min-height:52px; padding:4px 16px; gap:10px}`, icon svg 24px —
     text starts at 16 (left pad) + 24 (icon) + 10 (gap) = 50 from field left edge.
   - App: `NestTextField` uses Material `InputDecoration.prefixIcon` with the default
     48px-min icon box, so the magnifier visual sits in a wider slot and `Search ideas`
     starts visibly right of the design position (red ghosting around search in both
     compare sheets; icon also renders heavier/larger than the 24px design icon).
     Exceeds the ±2px tolerance by ~10px.
   - Fix: constrain the prefix icon to the design geometry — e.g. pass
     `prefixIconConstraints: BoxConstraints(minWidth: 50, minHeight: 44)` (or wrap the
     24px `NestIcon` in left-16/right-10 padding) in `NestTextField` usage for this
     screen or in the shared field so icon = 24, gap = 10, text x = 50. Shared-file
     change must go via SHARED_REQUEST (screen agent may not edit `core/`).

No other visible deviations: title, segmented (52 high), 44-high filter chips with
20px bleed, 40×40 r-m icon tiles, 44-high `+ Add` pills (pill radius, 1.5px leaf border,
`0 14px` padding), card r-m 16 with sh-1, 20px gutters, 16px rhythm, tab bar with
Quests active — all match within tolerance in both themes.


## From 6_bugs.md
# P10 · Quest library — bug hunt (Stage 6, iteration 1)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-1 checkpoint
`de831ed` (`screen/P10`), including the UI stage's `5_ui.md` findings and
`ORCHESTRATOR_NOTES.md` (all items accounted for below).

Proofs live in `app/test/features/quests/p10_bugs_test.dart` — **9 tests in 8
skipped groups**, one group per bug id. With the skips removed all nine fail
on this tree (`flutter test … --reporter compact` → `+0 -9`); with the skips
in place the feature suite is green. The geometry proofs are the real-font
(`FontLoader`, bundled Inter/Nunito) geometry test the notes ask for, pinned
at 390×844. No screen code was changed by this stage.

| Id | Severity | Area | Source |
|---|---|---|---|
| BUG-P10-1 | **major** | same-frame double-tap stacks two `/quest-editor` routes (`+ Add` and Active row) | this stage |
| BUG-P10-2 | **major** | `.trow` title/meta centred; design starts them at card x+64 | 5_ui 1 · notes 1 · review 1 |
| BUG-P10-3 | minor | search + category chips are inert on the Active tab | this stage |
| BUG-P10-4 | minor | end-of-list gap 48 px; design 32 px | this stage |
| BUG-P10-5 | **major** | search prefix icon 48×48 at field x+0; design 24×24 at x+16 (hint at x+50) | 5_ui 2 · notes 2 · review 3 · **shared** |
| BUG-P10-6 | **major** | segmented track/thumb 44/36; design `.segmented` 52/44 | notes 3 · review 4 · **shared** |
| BUG-P10-7 | **major** | tab-bar content 34 px low (icon centre 783; design 748) | 5_ui 5 · notes 5 · **shared** |
| BUG-P10-8 | **major** | view silently degrades to “No ideas found” when the global DI lookup fails | review 2 |

---

## BUG-P10-1 — major — same-frame double-tap stacks two editor routes

Both push sites in `presentation/widgets/quest_library_body.dart` call
`context.push` unguarded: `+ Add` at `:183`, Active row at `:146`.

**Repro.** Tap `+ Add` twice before a frame renders (same-frame double tap) →
two `QuestEditorView` routes (`findsNWidgets(2)` with `skipOffstage: false`);
one `pageBack()` still lands on `/quest-editor`, so the parent must press back
twice. Same on the Active tab by double-tapping the first row. A 50 ms-later
double tap is absorbed by the route transition (matches P08-B12) — only the
same-frame case stacks. **Proofs:** `+ Add pushes two /quest-editor routes`,
`an Active row pushes two /quest-editor routes`.

**Fix.** Copy P08's per-frame guard (`_PushOnce`,
`today/presentation/widgets/today_loaded_body.dart:238-269`) into the quests
layer (no cross-feature import) or promote it to `core/` via a shared request;
route both pushes through it. Un-skip BUG-P10-1.

## BUG-P10-2 — major — `.trow` text block is centred

`quest_idea_row.dart:71-93`: the `Expanded > Column` has no
`crossAxisAlignment`, so title and meta centre instead of starting at the tile
gap. **Proof:** `title and meta left-align to the tile gap` — measured title
offset **101.4 px** (design 64; card x=20, tile 40, gaps 12+12). **Fix:** add
`crossAxisAlignment: CrossAxisAlignment.start` to that `Column`. Un-skip
BUG-P10-2.

## BUG-P10-3 — minor — the Active tab renders controls that do nothing

Search + chip row render on both tabs (`quest_library_body.dart:90-110`) but
the Active branch (`:125-152`) ignores `_query`/`_category`. **Proof:**
`typing in the search field does not narrow the list` — after typing `bins`,
`Empty the dishwasher` is still on screen. **Fix:** hide search + chips on the
Active tab (the table has no category column), or filter the Active title by
the query. Un-skip BUG-P10-3.

## BUG-P10-4 — minor — 16 px extra below the last row

`_rows()` appends `SizedBox(16)` after every row including the last
(`:150` Active, `:169` Ideas) on top of `padding-bottom: 32` (`:56`); the
design's `.scroll > * + *` adds no margin after the last child, so the design
gap is 32. **Proof:** `16 px extra below the last row` — measured 48.0.
**Fix:** emit the separator only between rows. Un-skip BUG-P10-4.

## BUG-P10-5 — major — search prefix icon is 48×48 at x+0 (shared)

`quest_library_body.dart:98` passes a 24 px `NestIcon` as `prefixIcon`;
`NestTextField` forwards it to Material's `InputDecoration.prefixIcon`, whose
default constraints floor the slot at 48 px. The `NestIcon` is stretched to
**48×48 at field x+0** (design: 24×24 at x+16) and the hint starts at x+64
(design x+50), so the chain below is shifted too. **Proof:** `the magnifier
keeps the design slot`. **Fix:** shared — expose `prefixIconConstraints` on
`NestTextField` and keep the slot/alignment such that icon = 24 at x+16, hint
at x+50; see `SHARED_REQUEST.md` §1. Un-skip BUG-P10-5.

## BUG-P10-6 — major — segmented control is 8 px short (shared)

`NestSegmented` is 44 high with 36 px buttons; the HTML `.segmented` is
`padding: 4px` around buttons whose `min-height:44px` beats `height:40px` —
PNG measurement: track 315–470 @3x = **52**, selected pill 44. **Proof:**
`track, thumb and the 16/0/16 chain below it` — measured 44/36 plus the
segmented→search (16), search→chips (0) and chips→card (16) chain. **Fix:**
shared `NestSegmented` track 52 / buttons 44; see `SHARED_REQUEST.md` §2.
Un-skip BUG-P10-6.

## BUG-P10-7 — major — tab-bar content sits 34 px low (shared)

With the device insets (47/34), the app tab bar spans 760–844 with the Today
icon centre at **783**; the design puts the bar block at 726–810 (icon centre
**748**) with the 34 px home strip below it, and the owner rule wants the
surface to run to the edge. **Proof:** `Today icon centre matches the design
bar top`. **Fix:** shared `NestTabBar`/`ParentShell` content position; see
`SHARED_REQUEST.md` §3. Un-skip BUG-P10-7.

## BUG-P10-8 — major — the view silently loses its ideas when DI fails

`quest_library_view.dart:69,85-92`: `_ideaTemplates()` probes
`GetIt.instance.isRegistered` on every build and falls back to `const []`, so
a DI-order/build failure swaps 10 templates for “No ideas found” instead of
failing loudly (review finding 2). **Proof:** `a lost repository renders the
empty Ideas state` — after unregistering the repository and forcing a stream
rebuild, all `+ Add` rows disappear. **Fix:** put `ideas` in `QuestsState`
(populated by the bloc from `_repository.ideas()`); the view stops importing
`get_it`. Un-skip BUG-P10-8.

---

## ORCHESTRATOR_NOTES coverage

| Note | Handled by |
|---|---|
| 1 — `.trow` text at card x+64 | BUG-P10-2 (proof: real-font geometry) |
| 2 — search icon 24 at x+16, hint x+50, field height | BUG-P10-5 (icon + position; outer field measures 52 vs design ≈54 — within the ±2 band once the chain is fixed) |
| 3 — segmented track/buttons | BUG-P10-6 (track 52, buttons 44) |
| 4 — chips centre / first card top follow 2–3 | BUG-P10-6 proof also pins the 16/0/16 chain; absolute y then follows |
| 5 — tab bar content at design top, surface to edge | BUG-P10-7 + `SHARED_REQUEST.md` §3 |
| 6 — cards continue under the bar like the design | derivative of 2–5: once the content moves down 10 and the bar top rises to 726, the 6th card peeks 15 px exactly as the design (no separate assertion) |
| Real-font geometry test | `setUpAll(_loadBundledFonts)` + the three geometry proofs |

## Probed, no bug found (brief's hunt list)

| Area | Result |
|---|---|
| Rapid double taps | Cross-frame (50 ms) absorbed → 1 editor; same-frame stacks (BUG-P10-1). |
| Back navigation / deep links | Editor → back → `/quests` ✓; `/quests` and `/quests/` both match ✓. |
| Restart / Drift persistence | Re-pumping against the same DB keeps `Active (12)`; a file-backed DB closed and reopened returns the same 12 actives. |
| Parent/kid guard | Kid mode + `/quests` → `/parental-gate` ✓. |
| Dark mode | All P10 text pairs ≥ 4.5:1 (ink/ink2/ink3 on surface; leafInk on leafTint; sky on skyTint; aPeach on peachTint); tiles stay tinted. |
| Text scale 1.3 + width 320 | No overflow/exception; chips scroll (Kitchen off-screen at 320×1.3 is expected). |
| Long UK names / 9999 coins | Long title ellipsizes; `Daily · 9999 coins` renders; `Active (13)` follows a DB insert (DATA OVER MOCKS). |
| Empty lists | `Seed.empty()` → `Active (0)` + `No active quests` / `Add one from Ideas.`; no-match → `No ideas found`. |
| Async gaps | Disposing mid-push leaves no exception; Drift's deferred stream-close drains. |
| Europe/London + BST | N/A — no dates/times and no completion-status logic on P10 (period rule N/A). |
| Money rounding / integer pence | N/A — coins only, no `£`. |
| 0/1/6 children, £0.00/£999.99 | N/A — no child or money data on this screen. |

Carried (not counted): missing `.chipscroll` right-edge fade (plan §a allows);
Active order is title-sorted (review finding 10 — orchestrator question, filed
in `SHARED_REQUEST.md` §5); `?idea=` opens the P09 placeholder blank
(documented `TODO(P10)`, same feature, P09 not built).

## Gates at hand-off

- `flutter analyze test/features/quests/p10_bugs_test.dart lib/features/quests`
  → **No issues found**; a whole-app analyze was also clean when re-run with
  no foreign temp files in the tree. (The concurrently-running TEST stage
  repeatedly leaves `zz_probe*_test.dart` probes in `test/features/quests/`;
  they are not P10 screen findings and were left untouched.)
- `dart format --set-exit-if-changed` on the new test file → clean.
- `flutter test test/features/quests` → **41 owned tests pass, 9 skipped
  (bug proofs), 0 failed**.
- Unskipped proof run → **`+0 -9`**: every bug above fails on this tree.

