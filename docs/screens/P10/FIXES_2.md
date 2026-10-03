# Fix list after iteration 2

## From 2_build.md
# P10 · Stage 2 — INTEGRATE (iteration 2)

Job: make the two halves (`2a_build_logic.md`, `2b_build_ui.md`) compile and
pass together. Smallest change, no redesign, no shared-file edits (RULES §1).

**Result: `dart format` clean · `flutter analyze` → No issues found ·
`flutter test` → `+1921 −3`.** The 3 remaining failures are all one shared-code
defect (`NestSegmented` announces every option label twice) that I may not fix
here — detail and the exact one-line shared fix under FIXES-4. Per the brief,
PASS requires the full suite green, so this stage is **FAIL on that single
blocker**; everything in my scope is green.

## What landed (summary of the two halves)

### 2a — logic chunk (`bloc/**` + logic tests)

No contract *removal*: `QuestsState` **gained** `ideas: List<Quest>` (default
`const []`, threaded through `copyWith`/`props`), populated by
`QuestsBloc._onLoadRequested` from `_repository.ideas()` on the loading state
and every loaded emission; a failure keeps the last ideas. That closes review
finding 2 / BUG-P10-8 (the view no longer probes the service locator — the
`get_it` import and `_ideaTemplates()` are gone). The repository order test now
pins **creation order** per the orchestrator's §5 ruling (main `8ad0cdc`,
`watchActiveQuests` ordered by `createdAt, id`). Added/updated:
`quests_bloc_test.dart` (16), `quests_repository_test.dart` (10).

### 2b — UI chunk (`views/**`, `widgets/**` + view/widget tests)

`QuestLibraryView` now renders `QuestLibraryBody(items: state.items, ideas:
state.ideas)` and no longer touches GetIt. Closed BUG-P10-1 (`QuestPushOnce`
guard, new `widgets/quest_push_once.dart`), BUG-P10-2 (row text left-aligned at
card x+64), BUG-P10-3 (search + category row only on the Ideas tab), BUG-P10-4
(16 px separators *between* rows only), BUG-P10-5/6/7 (shared fixes adopted),
BUG-P10-9 (`onTap:` **and** `container: true` on every `Semantics` control,
Active-row label now `'$title. $meta'`), BUG-P10-11 (`plate`/`sofa` tints),
review 6 (`.chipscroll` fade mask via `ShaderMask`), 7 (plain `Text` for the
un-balanced title), 11 (`didUpdateWidget` re-reads `initialTab`). Verified all
7 `ORCHESTRATOR_NOTES` items; shared batch4 fixes (`NestTextField.search`,
`NestSegmented` 52/44, `NestTabBar` bottom-edge) are in the tree at `c1be080`.

Handed to me: **12 red tests**, which 2b correctly reported as owned elsewhere.

## FIXES

### FIXES-1 — DONE · 8 tests: `quest_library_states_test.dart` mock never stubbed `ideas()`

`2a`'s new `QuestsState.ideas` means the bloc calls `_repository.ideas()` on
every load. `_MockQuestsRepository` (a bare `extends Mock`) returned mocktail's
`null` for it, so the handler threw
`type 'Null' is not a subtype of type 'List<Quest>'` and the bloc never left
`loading` — the spinner, the failure block and both empty states were all
unreachable in that file.

Fix, in `app/test/features/quests/quest_library_states_test.dart` only: the mock
now stubs the method once, in its constructor, with the *real* templates —
`setUpTestScope()` registers the real `QuestsRepository`, so the body keeps
rendering the same 10 ideas the view used to read straight from GetIt:

```dart
class _MockQuestsRepository extends Mock implements QuestsRepository {
  _MockQuestsRepository() {
    when(ideas).thenReturn(GetIt.instance<QuestsRepository>().ideas());
  }
}
```

(+1 import: `get_it`.) No assertion touched; the 8 tests now exercise the real
status switch again (spinner colour/centring, error copy, `Try again` retry,
`Active (0)` empty state).

### FIXES-2 — DONE · 1 test: unsatisfiable exact-match finder on the Active row

`quest_library_a11y_test.dart` → `a row is one tappable button naming the quest
and its meta` asserted `find.bySemanticsLabel('Make your bed')` (an **exact**
match) while two lines later requiring `data.label` to `contains('coins')`.
Review finding 8 mandates the single combined label `'$title. $meta'`, so the
two assertions could never both hold.

Fix: the finder is now `find.bySemanticsLabel(RegExp('^Make your bed'))`.
`findsOneWidget`, `isButton`, `hasAction(SemanticsAction.tap)` and both
`contains(...)` assertions are unchanged — the proof is the same strength, it
just stops demanding that the quest name be the *entire* label. This matches
what 2b recommended.

### FIXES-3 — DONE · mandatory orchestrator item: delete the hidden route anchor

`ORCHESTRATOR_NOTES.md` (update 10:00) says: *"After the merge, delete the
hidden anchor."* The shared batch4 "today test anchor" fix has landed —
`app/test/features/today/today_view_test.dart:286-287` now asserts
`pushedPath(tester) == '/quests'` ("Route-path assertion only: P10 owns the
library view and its copy"), and no `P10 Quest library` literal remains in
another feature's tests.

So `QuestLibraryView` is back to 2b's plain `Scaffold → SafeArea →
BlocBuilder` body: the `Stack(fit: StackFit.passthrough)` wrapper, the
`Positioned` anchor and the whole `_QuestLibraryRouteAnchor` class (with its
`TODO(P10)`) are deleted. Verified: P08's two navigation tests and
`router_push_test.dart` pass without it, which is what the shared fix was for.
P08b's "Browse ideas" assertion has the same `pushedPath` shape.

### FIXES-4 — LEFT (shared code, cannot fix here) · 3 tests: `NestSegmented` double label

All three failures are the same assertion and the same root cause:

```
Expected: exactly one matching candidate
  Actual: _ElementPredicateWidgetFinder:<Found 2 widgets with a semantics label named "Ideas">
   Which: is too many
```

* `quest_library_a11y_test.dart` → `P10 segmented control each option is one
  labelled, tappable button`
* …→ `P10 icon buttons every interactive node announces what it does`
* …→ `P10 dark mode the same semantics contract holds in dark`

`app/lib/core/design_system/components/nest_segmented.dart:53-58` wraps each
option in `Semantics(button: true, selected:, label: option.label, onTap: …)`
but has no `excludeSemantics: true`, so the option's inner `Text` (`:78`) and
the `InkWell`'s own node keep their own semantics — a screen reader walks
"Ideas" twice on every segmented control in the app (`NestSegmented` is used by
`quest_library_body.dart` and the gallery). Batch4 added the missing `onTap:`
but not `excludeSemantics`.

**Fix (shared, one line):** add `excludeSemantics: true` to that per-option
`Semantics`; the `onTap` batch4 added stays, so the node keeps its action.
`nest_chip.dart:119-121` already does exactly this ("One node per chip").

Left here on purpose: `app/lib/core/**` is forbidden to a screen agent
(RULES §1); `ExcludeSemantics` around the control would delete its tap actions
from the semantics tree (worse than the duplicate); re-implementing the control
is forbidden; and relaxing the three proofs to `findsWidgets` would mask a real
MAJOR a11y defect that `SHARED_REQUEST.md` §1 is tracking. `SHARED_REQUEST.md`
§1 now records that this is the *only* remaining blocker plus the exact proof
names.

## LEFT / notes (not blockers)

1. Chip-row right-edge fade and the real-font geometry proofs are green per 2b
   (`ShaderMask` + `p10_bugs_test.dart` 9/9); a UI pass (`shot.sh` +
   `compare.py`, both themes) still belongs to stage 5 — no simulator was
   booted, installed on, screenshotted or driven in this stage.
2. `?idea=` / `?id=` query params on `/quest-editor` (P09, same feature) remain
   documented `TODO(P10)`s.
3. `SHARED_REQUEST.md` §5 (shared `NestChip` tap action), §6 (`QuestPushOnce`
   → `core/`) and §7 (`plate` tint disagreement with P08) stay open for the
   orchestrator; no P10 test is red on any of them.

## Verification tails

```
$ dart format .
Formatted 435 files (0 changed) in 1.13s.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.5s)

$ flutter test
00:36 +1921 -3: Some tests failed.
  test/features/quests/quest_library_a11y_test.dart: P10 segmented control each option is one labelled, tappable button
  test/features/quests/quest_library_a11y_test.dart: P10 icon buttons every interactive node announces what it does
  test/features/quests/quest_library_a11y_test.dart: P10 dark mode the same semantics contract holds in dark
```

On entry: `+1912 −12`. Of the 12, **9 are fixed in scope** (FIXES-1, FIXES-2)
and 3 are FIXES-4. The `WARNING (drift): AppDatabase created multiple times`
notices in the output are the repo-wide debug-build notice from `test_scope.dart`,
not failures.


## From 3_test.md
# P10 · Quest library (`/quests`) — Stage 3 TEST (iteration 2)

Route `/quests` · feature `quests` · parent mode · in-memory Drift DB with
`Seed.demo()` (12 active quests) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`.
Tree tested: `caeefe1` "P10: checkpoint after build (iteration 2)" on
`screen/P10`.

**No screen code was changed.** Every finding below is a failing proof in
`app/test/features/quests/`, left in place.

---

## 0. What this iteration added, and why

Iteration 1 closed the coverage gaps from `4_review.md`. Iteration 2 was driven
by two new orchestrator rules that landed in the brief:

- **ACCESSIBILITY ACTIONS** — *every* interactive element must be operable by
  VoiceOver/TalkBack; where a control sits inside
  `Semantics(excludeSemantics: true)` the node itself must carry `onTap:`;
  tests must assert `hasAction(SemanticsAction.tap)` **and that
  `performAction(SemanticsAction.tap)` changes the real state or DB.**
- **UI VERDICT RULE** — every element within ±2 px of the design, with the
  measured y of the title, the first control and each card top reported
  design-versus-app.

So this stage added two suites:

| File | Tests | Result |
|---|---:|---|
| `quest_library_a11y_actions_test.dart` (**new**) | 11 | 10 ✓ / 1 ✗ |
| `quest_library_design_geometry_test.dart` (**new**) | 9 | 9 ✓ |
| `p10_bugs_test.dart` (edited) | 10 | 9 ✓ / 1 ✗ |

and un-skipped the one proof the iteration-2 bug hunt had left behind
(`BUG-P10-12`).

---

## 1. `performAction` proofs — ACCESSIBILITY ACTIONS

`quest_library_a11y_actions_test.dart` fires the real
`SemanticsAction` through `SemanticsOwner.performAction(node.id, …)` — the same
call VoiceOver's and TalkBack's double-tap make — and then checks the effect on
real state or the route. It asserts the node advertises the action first, so a
control that only *looks* tappable fails here instead of silently doing nothing.

| Control | Proof | Result |
|---|---|---|
| Chip `Kitchen` | tap → list narrows to `Lay the table` + `Empty the dishwasher`, `Kitchen` becomes `selected`, `All` unselects | ✓ |
| Chip `All` | tap → list restores | ✓ |
| Chip `Kindness` | tap → `No ideas found` | ✓ |
| Chips `All`/`Bedroom`/`Kitchen` | each advertises and handles `tap` | ✓ |
| Segmented `Active (12)` | tap → `+ Add` gone, seeded rows shown, **route unchanged** | ✓ |
| Segmented `Ideas` | tap → `+ Add` back | ✓ |
| `+ Add` on the first row | tap → pushes `/quest-editor?idea=…`; back returns to `/quests` | ✓ |
| `+ Add` on three rows | tap → each pushes its own template id | ✓ |
| `+ Add` | tap does **not** write to the DB (`Active (12)` unchanged) | ✓ |
| Active row | tap → pushes the editor | ✓ |
| Search field | `setText('pet')` → list narrows to `Feed the pet` | ✓ |
| Search field | the editable node must carry the design's `aria-label` | ✗ **BUG-P10-13** |

This is the positive counterpart to iteration 1's `hasAction(tap)` assertions:
the new `onTap:` wiring that `2b` added to `quest_filter_chip.dart`,
`quest_idea_row.dart` and the shared `NestSegmented` is proven end-to-end, not
just by flag.

---

## 2. Design geometry — UI VERDICT RULE

`quest_library_design_geometry_test.dart` pins items 1–6 of
`ORCHESTRATOR_NOTES.md` against values read off
`design/screens/light/P10-quest-library.png` by scanning for the exact token
colours. It injects `FakeViewPadding(top: 47, bottom: 34)` — the insets a real
390×844 phone reports — so widget y values line up with the design's absolute y
(the body starts at 0 otherwise, because `NestStatusBar` only reserves height).
Inter + Nunito are loaded through `FontLoader`, so text metrics are real.

**All 9 pass at the rule's ±2 px tolerance.** Measured, design → app:

| Element | Design y | App y | Δ |
|---|---|---|---|
| `.ptitle` ink band | 61.0 … 86.7 | 55.0 … 89.0 (line box; ink 61.0 … 86.7) | **0** |
| Segmented track | 105.0 … 157.0 (52) | 105.0 … 157.0 (52) | **0** |
| Segmented thumb | 109.0 … 153.0 (44) | 109.0 … 153.0 (44) | **0** |
| `.search` field box | 173.0 … 227.0 (**54**) | 173.0 … 225.0 (**52**) | top 0, **height −2** |
| Search magnifier box | x 36, 24×24 | x 37, 24×24 | **+1** |
| Search hint | field x + 50 (PNG ≈ +53.7) | field x + 51 | **+1** |
| Chip row (`.chipscroll`) | 227.0 … 271.0 | 225.0 … 269.0 | **−2** |
| Chip pill `All` | 227.0 … 271.0 (44) | 225.0 … 269.0 (44) | **−2** |
| **Card 1 top** | **291.0** | **289.0** | **−2** |
| Card 2 / 3 / 4 tops | 375 / 459 / 543 | 373 / 457 / 541 | **−2** each |
| Card height | 68 | 68 | 0 |
| Card step | 84 (68 + 16) | 84 | 0 |
| Tab-bar surface top | 726.0 | 726.0 (118 high → 844) | **0** |
| Tab icon box | 736 … 760 | 737 … 761 | **+1** |
| Tab label box | 764 … 778 | 765 … 779 | **+1** |
| Tab-bar surface bottom | 810 (design strip) | **844** | ✓ OWNER BOTTOM-EDGE RULE |

Reading of the table: the vertical cascade the orchestrator measured in
iteration 1 (items 3–4, everything 8–10 px high) is gone — items 1–5 are all
now within the rule's ±2 px, and item 5 is exact while the bar still fills to the
physical edge. The one systematic residual is a **2 px** offset: `NestTextField.search`
renders 52 high where `.search` computes to 54, which lifts the chip row and
every card by 2. That is at the rule's tolerance and is filed as
`SHARED_REQUEST.md` §9 (minor) rather than as a P10 finding, since the component
is shared.

Also pinned: the list scrolls under the tab bar (item 6) and the dark-mode y
values are identical to light.

---

## 3. Bugs found

### BUG-P10-12 — MAJOR (now un-skipped, confirmed) — the applied search filter goes invisible after a tab round-trip

`app/test/features/quests/p10_bugs_test.dart:310-357` — the iteration-2 bug
hunt added this proof and left it behind `skip:`. Removed (the loop forbids
skipping tests); it **fails**.

**Repro.** `/quests` → type `pet` in the search field → the list narrows to
`Feed the pet` → tap `Active (12)` → tap `Ideas`. The search field is now
**empty** while 9 of the 10 ideas stay hidden, so the list looks broken with no
visible cause.

**Cause.** The BUG-P10-3 fix moved the search field out of the tree on the
Active tab, which disposes the `TextField`'s own text state, while `_query` in
`_QuestLibraryBodyState` (`quest_library_body.dart`) survives.

**Fix-agnostic assertion.** Either hoist a `TextEditingController` so the field
keeps showing the applied query, or clear `_query` when the field leaves the
tree.

### BUG-P10-13 — MAJOR — the search field's accessible name is its hint, not the design's `aria-label`

**File** `app/lib/core/design_system/components/nest_text_field.dart:199-202`
(shared; `SHARED_REQUEST.md` §8).

**Cause.** `NestTextField.search` wraps its row in
`Semantics(label: semanticLabel, textField: true, child: row)`. That wrapper
becomes its **own** node advertising `isTextField` but carrying no actions,
while the real `TextField` keeps a separate node labelled only with its hint.
P10 passes `semanticLabel: 'Search quest ideas'` (the design's
`aria-label`), so it lands on the wrong node.

Measured with `debugDumpSemanticsTree()` on `/quests`:

```
SemanticsNode#26  flags: isTextField   label: "Search quest ideas"   (no actions)
SemanticsNode#28  actions: focus, tap  label: "Search ideas"        isTextField
```

**Impact.** A screen reader that focuses the labelled node finds a text field it
cannot type into; the editable node announces the placeholder instead of the
`aria-label`. This is exactly what the new ACCESSIBILITY ACTIONS rule forbids.

**Repro (test).** `ACCESSIBILITY ACTIONS — search field setting the field value
really filters the list`:

```
Expected: 'Search quest ideas'
  Actual: 'Search ideas'
```

**Fix.** Put the name on the input (merge into the editable node) rather than
beside it, and stop the wrapper advertising `textField: true` unless it carries
the actions.

### Open, already tracked (unchanged this iteration)

**BUG-P10-1 … 11** — all eleven iteration-1 findings are fixed by the build stage
except **BUG-P10-10**, the shared `NestSegmented` double-label defect
(`SHARED_REQUEST.md` §1), which is the **only** remaining blocker for P10 and is
explicitly a shared item per `ORCHESTRATOR_NOTES.md` (10:00).

**BUG-P10-10 — MAJOR** — `nest_segmented.dart:51-58`. The per-option `Semantics`
has `onTap:` (batch 4) but no `excludeSemantics: true`, so the option's inner
`Text` and the `InkWell`'s node each keep the same label. Three P10 tests are red
on it:

```
find.bySemanticsLabel('Active (12)') → Found 2 widgets   (outer + inner)
```

Measured: `SemanticsNode#21 label "Active (12)" actions: tap` and
`SemanticsNode#22 label "Active (12)" actions: focus, tap` — a screen reader
walks the same option twice on every segmented control in the app.

---

## 4. Results

```
$ dart format --set-exit-if-changed .
Formatted 437 files (0 changed) in 1.23 seconds.

$ flutter analyze
Analyzing app...
No issues found! (ran in 3.5s)

$ flutter test
+1940 -5: Some tests failed.

$ flutter test test/features/quests/
+169 -5: Some tests failed.
```

The 5 failures in `test/features/quests/` are the two bugs above plus the three
`NestSegmented` proofs. Per file:

| File | Result |
|---|---|
| `quest_library_view_test.dart` | 27/27 |
| `quest_library_states_test.dart` | 19/19 |
| `quest_library_filter_test.dart` | 20/20 |
| `quests_bloc_test.dart` | 16/16 |
| `quest_idea_meta_test.dart` | 16/16 |
| `quest_library_widget_test.dart` | 16/16 |
| `quests_repository_test.dart` | 10/10 |
| `quest_library_design_geometry_test.dart` (new) | 9/9 |
| `p10_bugs_test.dart` | 9/10 (BUG-P10-12) |
| `quest_library_a11y_actions_test.dart` (new) | 10/11 (BUG-P10-13) |
| `quest_library_a11y_test.dart` | 17/20 (NestSegmented ×3) |

Whole app: **1945 tests, 5 failed**, every failure in P10. No other feature's
tests broke. No test is skipped anywhere in `test/features/quests/`;
`p10_bugs_test.dart` has no `skip:` marker left.

Housekeeping note (not a finding): the review stage is running concurrently and
leaves `test/features/quests/zzz_review_probe*_test.dart` scratch files, each
headed "TEMPORARY review probe - deleted after the run". While they are present
they are unformatted and account for all 47 `flutter analyze` issues; the
`dart format` / `analyze` / `test` figures above come from a run with them set
aside (one was restored immediately afterwards so the review stage keeps
working). They must not be committed.

---

## 5. Owner rules checked

- **No skipped tests** — the `BUG-P10-12` marker removed; `grep 'skip:'` over
  `test/features/quests/` returns nothing but a comment.
- **ACCESSIBILITY ACTIONS** — `hasAction(SemanticsAction.tap)` **and**
  `performAction(...)` with a real state/route/DB effect for the chips, the
  segmented control, `+ Add`, the Active row and the search field. One control
  fails (BUG-P10-13).
- **UI VERDICT RULE** — measured design-vs-app y for the title, every control and
  every card top, in §2 above; all within ±2 px, one systematic −2 px filed as
  `SHARED_REQUEST.md` §9.
- **BOTTOM-EDGE** — the tab-bar surface reaches 844 in light and dark, asserted
  directly.
- **google_fonts** — 0 occurrences in `lib/features/quests` and
  `test/features/quests`.
- **CHIP ROWS / tap targets** — ≥44 px (parent) asserted for every chip, `+ Add`,
  the segmented control and the search field.
- **COPY** — meta lines character-for-character (U+00B7 middot), plus the search
  field's accessible name, which is what BUG-P10-13 is about.
- **Simulators** — none booted, installed on, screenshotted or driven.

---

## 6. Verdict

Five proofs fail. Two are defects this stage surfaced (BUG-P10-12 confirmed after
un-skipping, BUG-P10-13 new); three are the shared `NestSegmented` defect the
orchestrator has already classified as a shared item. No screen code was
patched, as instructed, so the verdict cannot be PASS.


## From 4_review.md
# P10 · Quest library (`/quests`) — Stage 4 QA code review (iteration 2)

Scope: `git diff main...HEAD` (branch `screen/P10`) = 9 `presentation/` files
+ 9 `test/features/quests/` files. No code edited during this stage (temporary
measurement probes were written, run and deleted).

Reviewed against: `docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/DESIGN_SPEC.md` §5 P10, `docs/design/SPACING_SPEC.md`,
`design/html-source/screens/P10-quest-library.html`,
`design/screens/light|dark/P10-quest-library.png` (measured pixel-by-pixel),
`app/lib/core/design_system/`, `1_plan.md`, `ORCHESTRATOR_NOTES.md`
(mandatory — all 6 items accounted for below).

## Verification I ran myself (no simulator)

- `dart format --output=none --set-exit-if-changed` → **31 files, 0 changed**.
- `flutter analyze` → **No issues found**.
- `flutter test` on the nine **committed** test files →
  **150 pass, 4 fail** (findings 1 and 2).
- Design PNG measured directly from `design/screens/light/P10-quest-library.png`
  by scanning for the exact token colours (`--line`, `--surface-2`, `--leaf`,
  `--leaf-tint`, `--surface`, `--ink`, `--ink-2`, `--ink-3`, `--paper`, the five
  tile tints), and the app measured at 390×844 with the 47/34 device insets
  injected — the table is under "Measured geometry" below.
- `git diff main...HEAD --name-only` filtered against RULES §1 → **no path
  outside `features/quests/{presentation,domain,data}`, `test/features/quests`,
  `docs/screens/P10`**.

---

## Measured geometry — design vs app (UI VERDICT RULE)

Design values read off the light PNG (÷3); app values from a 390×844 surface
with `top:47, bottom:34` insets. All x gutters measured exactly 20.0…370.0 in
both.

| Element | Design y | App y | Δ |
|---|---|---|---|
| Screen title `Quests` (box) | 55 … 89 | 55 … 89 | 0 |
| `.segmented` track | 105 … 157 (52) | 105 … 157 (52) | 0 |
| `.segmented` selected pill | 109 … 153 (44) | 109 … 153 (44) | 0 |
| **`.search` field (border box)** | **173 … 227 (54)** | **173 … 225 (52)** | **−2 (bottom edge)** |
| **chip row (`All` pill)** | **227 … 271 (44)** | **225 … 269 (44)** | **−2** |
| **card 1** | **291 … 359 (68)** | **289 … 357 (68)** | **−2** |
| **card 2** | **375 … 443** | **373 … 441** | **−2** |
| **card 3** | **459 … 527** | **457 … 525** | **−2** |
| **card 4** | **543 … 611** | **541 … 609** | **−2** |
| **card 5** | **627 … 695** | **625 … 693** | **−2** |
| **card 6** | **711 … 726 (clipped by the bar)** | **709 … 777** | **−2** |
| card step | 84 | 84 | 0 |
| `.trow` title text x | 84 (ink 85.3) | 84 | 0 |
| `+ Add` pill | x 287 … 358, y 303 … 347 | x 286.4 … 358, y 301 … 345 | −0.6 / −2 |
| `.search` magnifier | box x 37 … 61 | x 37 … 61 | 0 |
| placeholder left | field x + 50 | field x + 51 | 1 |
| tab bar surface | top 726, ends 810 (owner rule: app must reach 844) | 726 … 844 | correct |
| tab icon box | ≈ 737 … 761 | 737 … 761 | 0 |
| tab label | ink 768 … 778 (box ≈ 764 … 778) | 765 … 779 | +1 |

**Reading:** everything above the search field is pixel-exact. Everything from
the search field down is a **uniform 2 px upward shift**, caused by one box
model error in the shared search row (finding 4). No misalignment, no gutter
drift, no coloured strip under the bar (the tab-bar surface runs 726 → 844 in
both themes), so the OWNER BOTTOM-EDGE and ALIGNMENT rules hold.

---

## Findings

### 1. BLOCKER — the committed suite is red: `NestSegmented` announces every option label twice

`app/test/features/quests/quest_library_a11y_test.dart:49,121,196` (three
tests) vs `app/lib/core/design_system/components/nest_segmented.dart:53-59`.

```
P10 segmented control each option is one labelled, tappable button   [E]
P10 icon buttons every interactive node announces what it does        [E]
P10 dark mode the same semantics contract holds in dark               [E]
  Expected: exactly one matching candidate
    Actual: Found 2 widgets with a semantics label named "Active (12)" / "Ideas"
```

The semantics tree I dumped confirms it — two nodes per option:

```
#21 label="Active (12)" actions=[tap]
  └#22 label="Active (12)" actions=[tap, focus]
#23 label="Ideas"       actions=[tap]
  └#24 label="Ideas"       actions=[tap, focus]
```

`nest_segmented.dart:53` wraps each option in `Semantics(button:, selected:,
label:, onTap:)` with **no `excludeSemantics: true`**, so the option's own
`Text(option.label)` (`:80`) stays in the tree and a screen reader walks the
label twice. RULES §7.1 requires `flutter test` → all pass, so this branch
cannot land as-is.

**Fix (one line, shared — `core/`, which RULES §1 forbids P10 from editing):
add `excludeSemantics: true` to the per-option `Semantics` at
`nest_segmented.dart:53`**; the `onTap` batch4 added stays, so the node keeps
its action (the pattern to copy is `nest_chip.dart:119-137`). Already filed as
`SHARED_REQUEST.md` §1 — it needs the orchestrator to land it on `main`.

P10 must **not** work around it: wrapping the control in `ExcludeSemantics`
would delete its tap actions, re-implementing it locally is forbidden, and
softening the three proofs to `findsWidgets` would mask the defect.

### 2. MAJOR — the applied search filter goes invisible after a tab round-trip (reproduced)

`app/lib/features/quests/presentation/widgets/quest_library_body.dart:38`
(`String _query`), `:118-131` (the search field is only built while
`filtersOn`, i.e. on the Ideas tab).

Reproduced on the committed code (type `pet` → tap `Active (12)` → tap
`Ideas`):

```
rows after typing:            1
field text after round-trip:  ""
rows after round-trip:        1
"Make your bed" present:      false
```

Because the search field is lifted out of the tree on the Active tab, its
`EditableText` state is discarded, while `_query` in
`_QuestLibraryBodyState` survives. The parent comes back to an **empty search
box with 9 of 10 ideas missing** and no way to tell why — to un-filter they
must type something and delete it again. (`_category` survives the same way but
stays *visible*, because the chip row returns with its selection, so the
invisible half of the filter is the text query only.)

**Fix (in scope, `quest_library_body.dart`):** own a `TextEditingController`
in the state and pass it to `NestTextField.search(controller: …)`, syncing
`_query` in `onChanged` — the field then always shows the query that is
actually applied, which is also what the design implies (the filters persist
across a tab switch). Dispose the controller in `dispose()`. The alternative —
clearing `_query` in the segmented `onChanged` when leaving Ideas — also
removes the dead end but silently throws the parent's filter away; prefer the
controller.

The working-tree `p10_bugs_test.dart` now runs this proof un-skipped and fails,
which is the correct expectation until the fix lands.

### 3. MAJOR — `Try again` leaks a live database watcher on every tap

`app/lib/features/quests/presentation/bloc/quests_bloc.dart:23`
(`await emit.forEach<List<Quest>>(_repository.watchItems(), …)`), reached from
`app/lib/features/quests/presentation/views/quest_library_view.dart:44-51`.

`QuestsBloc` is the only bloc in the app that subscribes with a bare
`emit.forEach`. Drift `watch()` streams never close, so when the stream errors
the handler's `onError` fires but the subscription stays open; the `Try again`
button then starts a **second** concurrent `emit.forEach` while the first is
still alive. Measured with a fake repository:

```
subscriptions after 1st load: 1
status after error:          QuestsStatus.failure
subscriptions after retry:   2      ← the failed one is still subscribed
subscriptions after 2nd retry: 3
```

Every other multi-stream bloc carries the exact guard for this, with a comment
naming the leak: `today_bloc.dart:80`, `family_bloc.dart:110`,
`pocket_money_bloc.dart:174` (`_closeOnError` — "otherwise the failed load's
watchers stay subscribed and every 'Try again' leaks another full set").
P10 duplicates none of it.

**Fix (in scope, `quests_bloc.dart`):** terminate the stream on the first
error before handing it to `emit.forEach`, e.g.

```dart
final _closeOnError = StreamTransformer<List<Quest>, List<Quest>>.fromHandlers(
  handleError: (error, stackTrace, sink) => sink..addError(error, stackTrace)..close(),
);
…
await emit.forEach(_repository.watchItems().transform(_closeOnError), …);
```

so `emit.forEach` completes, cancels the watcher and lets the retry start
clean. (A `StreamSubscription` field cancelled before re-subscribing works
too.) Add a bloc test asserting the subscription count is 1 after two
retries.

### 4. MAJOR — 2 px design drift: everything below the search field sits 2 px high

`app/lib/core/design_system/components/nest_text_field.dart:151-155` (shared),
reached from `app/lib/features/quests/presentation/widgets/quest_library_body.dart:124`.

`NestTextField.search` builds `minHeight: 52` + `vertical: NestSpacing.gap3` (3)
+ `border: 1` = **52 total**, and its doc comment claims "the row measures
exactly 52". The design is `box-sizing: border-box` globally
(`tokens.css:200`), so `.search { min-height:52px; padding:4px 16px;
border:1px }` with a 44-high input computes to 4 + 44 + 4 + 2 = **54**, which
is what the PNG shows (the `--line` ring spans y 173 … 227). Result: the chip
row and all ten cards are 2 px above the design (table above) — exactly on the
UI VERDICT RULE's ±2 px boundary, and a uniform shift of every element below
the field, which the rule explicitly calls a failure mode.

**Fix (shared — file in `SHARED_REQUEST.md`, do not hack locally):** make the
search row 54 tall — either `padding: EdgeInsets.symmetric(vertical:
NestSpacing.s4)` with `minHeight: 54`, or keep the 3 px padding and raise the
constraint to 54. Both keep the content centred exactly as the design paints
it. P10 must not wrap or re-pad the shared field locally.

### 5. MINOR — the search field's accessible name lands on an inert node

`app/lib/core/design_system/components/nest_text_field.dart:201`
(`return Semantics(label: semanticLabel, textField: true, child: row);`),
supplied by P10 at `quest_library_body.dart:126`.

The wrapper has no `container`, no `excludeSemantics` and no action, so the
tree carries two text-field nodes:

```
#26 label="Search quest ideas"  isTextField=true  actions=[]      ← inert
#28 label="Search ideas"        isTextField=true  actions=[tap, focus]
```

VoiceOver therefore announces the field as **"Search ideas"** (its hint), not
the design's `aria-label="Search quest ideas"` (`P10-quest-library.html:19`),
and the node that carries the intended label cannot be focused or typed into.
The field is still operable, so this is not a blocker, but the accessible name
is wrong and there is a phantom text field in the tree.

**Fix (shared):** merge the label onto the `TextField` itself — either
`ExcludeSemantics` the hint and put `label` on a `container: true` wrapper
that owns `SemanticsAction.setText`, or move the label into
`InputDecoration.labelText`/`semanticCounterText` so one node carries it. Add
to the existing `SHARED_REQUEST.md` §3.

### 6. MINOR — the row title rebuilds `bodyStrong` by hand

`app/lib/features/quests/presentation/widgets/quest_idea_row.dart:83-84`:
`NestType.body(color: tokens.ink).copyWith(fontWeight: FontWeight.w700, height:
22 / 16)`. `NestType.bodyStrong(color)` is already Inter 16/24 w700 and is what
`NestQuestCard` (`nest_quest_card.dart:74-76`) and `NestListRow`
(`nest_list_row.dart:83-86`) use for the same 22/16 override.

**Fix:** `NestType.bodyStrong(color: tokens.ink).copyWith(height: 22 / 16)` —
same pixels, one less duplicated weight literal to drift.

### 7. MINOR — the two empty states do not share the 20 px gutter

`app/lib/features/quests/presentation/widgets/quest_library_body.dart:159-167`
returns `const <Widget>[NestEmptyState(...)]` with **no** `_gutter`, while the
Ideas empty state (`:183-192`) wraps the same widget in `_gutter(...)`.
`NestEmptyState` adds its own 16 px, so the Active empty state starts 16 px
from the screen edge and the Ideas one 36 px — the OWNER ALIGNMENT rule asks
for one consistent 20 px gutter on a screen.

**Fix:** wrap the Active `NestEmptyState` in `_gutter(...)` like its sibling.

### 8. MINOR — the icon-tile edge is a bare `40` where a token exists

`app/lib/features/quests/presentation/widgets/quest_idea_row.dart:60-61`
(`width: 40, height: 40`). `NestSpacing.s10 == 40`, and the shared
`NestListRow` carries the same literal, so this is app-wide rather than
P10-specific — but the "tokens only" rule is what the design system is for.
Either use `NestSpacing.s10` or (better) ask the orchestrator for a
`NestTile` size token next to `NestDevice`, since `.icon-tile` is a component
dimension, not a spacing step. Add to `SHARED_REQUEST.md` §6/§7.

---

## What is verified clean (no action)

- **RULES §1**: no path outside `features/quests/presentation/**`,
  `test/features/quests/**`, `docs/screens/P10/**` in `git diff main...HEAD`.
- **Architecture (iteration-1 findings 2, 5 closed)**: `QuestLibraryView` no
  longer touches `GetIt`; `ideas()` is read once in `_onLoadRequested` and
  travels in `QuestsState`; the hidden `_QuestLibraryRouteAnchor` and its
  `Stack` wrapper are gone. DI, routes, the repository and the schema are
  untouched.
- **Design-system reuse**: `NestSegmented`, `NestTextField.search`,
  `NestButton`, `NestEmptyState`, `NestIcon`, `NestRadii`, `NestSpacing`,
  `NestTileTint`, `tokens.cardShadow`. `.trow` is correctly *not* `NestCard`
  (r-m 16, per `.trow`) and `QuestFilterChip` is correctly 44-high per
  SPACING_SPEC §9.5 rather than `NestChip`'s 32 — and the chip row is a
  scrolling `SingleChildScrollView`, so `NestChipWrap` (a `Wrap`) is the wrong
  container here; the whole pill is already the 44 px target.
- **Tokens only**: no literal colour (`Colors.transparent` only, as
  `NestChip` does), no `fontSize`, no `letterSpacing` (LETTER-SPACING rule
  respected), no `google_fonts`/`GoogleFonts` anywhere in the feature or tests.
- **Copy**: character-for-character against the HTML — `Quests`,
  `Active ({n})`/`Ideas`, `Search ideas`, `Search quest ideas`, the seven chip
  labels in design order, `+ Add`, `Add {title}` aria-labels, and all ten meta
  strings with U+00B7 middot and spaces (`5 coins · Ages 4+ · Bedroom` …).
  UK spelling throughout; no US spellings in copy.
- **DATA OVER MOCKS**: the segmented count is `widget.items.length`; no literal
  `12` in the view. **CHILD ORDER**: `QuestsRepository` creation order, not
  alphabetical (the repo test asserts Maya's 6 → Leo's 4 → Anyone's 2).
- **Copy `+ Add` semantics / tap targets**: the semantics tree shows one node
  per chip (`All`…`Kindness`, all `actions=[tap]`), one node per `+ Add`
  (`label="Add Make your bed"`, `actions=[tap]`, `container: true` so it does
  not bubble into the row), and one node per Active row carrying
  `"<title>. <meta>"` with `tap` — iteration-1 findings 8 and the
  `Semantics`/`onTap` rule are satisfied.
- **Iteration-1 finding 1 closed**: row text is start-aligned at card x + 64
  (measured 84.0 absolute; pinned by
  `quest_library_view_test.dart:400`).
- **Iteration-1 finding 6 closed**: `.chipscroll`'s right-edge fade is a
  `ShaderMask(dstIn)` over the viewport, exactly as the CSS mask.
- **Iteration-1 finding 7 closed**: `.ptitle` has no `text-wrap: balance`
  (`components.css` puts balance on `.h1`/`.display`, and the HTML renders
  `class="ptitle"` only), so the plain `Text` is correct — no
  `NestBalancedText`, no stray `LayoutBuilder` per rebuild.
- **Performance / lifetime**: no `Timer`, no `AnimationController`,
  `DISABLE_ANIMATIONS` irrelevant here; 10 rows rebuilt per keystroke over a
  `const` list; `QuestPushOnce` schedules only a post-frame callback (no
  controller to dispose, and a disposed state is never `setState`d); the
  bloc's watcher is cancelled on `bloc.close()` (verified: `hasListener`
  false afterwards).
- **Children's Code**: parent screen — no analytics, ads, telemetry or child
  data beyond the family-scoped quest rows.
- **Design system is honest about its own limits**: `SHARED_REQUEST.md`
  §1/§5/§6/§7 are accurate and still open; nothing in this diff contradicts
  them.

## Advisory (process, not findings)

The working tree — not `git diff main...HEAD` — currently adds
`test/features/quests/quest_library_a11y_actions_test.dart` and
`quest_library_design_geometry_test.dart` (untracked) and modifies
`p10_bugs_test.dart`. Two things the next stage should know, since the loop
commits the worktree:

1. `quest_library_a11y_actions_test.dart`'s search case asserts
   `hasAction(SemanticsAction.setText)` on the `TextField`. I checked the
   framework baseline: a **plain** `MaterialApp` + `TextField` in this Flutter
   build exposes `tap, focus` and **no** `setText`, so that assertion can never
   pass here and will sit red for a reason unrelated to P10. Assert on the
   label + `tap`/`focus` (or drive the field with `tester.enterText`) instead.
2. The new geometry test pins `field.height` at `54 ± 2`, which **passes at 52**
   and so locks finding 4's 2 px shift into the suite as "correct". Once the
   shared box model lands, tighten it to ±1 or exact so the drift cannot come
   back.

## Verdict

The iteration-1 architecture and accessibility findings are genuinely closed,
and the screen is token-clean, copy-exact and well aligned. What remains is
one blocker (three committed tests red on a shared one-line defect) and three
majors: an invisible filter after a tab round-trip that I reproduced on the
committed code, a retry path that leaks a database watcher per tap, and a 2 px
uniform drift of the whole lower half of the screen from a shared box model.
Findings 2 and 3 are fixable inside `features/quests/**`; 1 and 4 need the
orchestrator to land `SHARED_REQUEST.md` §1 and a new search-field item.


## From 6_bugs.md
# P10 · Quest library — bug hunt (Stage 6, iteration 2)

Route `/quests` · feature `quests` · parent mode · seeds `Seed.demo()` (12
active quests) and `Seed.empty()` (0) · tests pinned to Sat 3 Oct 2026 by
`test/flutter_test_config.dart`. Tree tested: iteration-2 build checkpoint
`caeefe1` with shared batch4 on `main` (`c1be080`: `NestSegmented` 52/44,
`NestTextField.search`, `NestTabBar` content position, `watchActiveQuests`
creation order). `ORCHESTRATOR_NOTES.md` items 1–6 re-verified.

**Iteration-1 proofs:** all nine `p10_bugs_test.dart` proofs (BUG-P10-1…8)
are now un-skipped and **green** — they guard the fixes. **One new P10-local
major was found this iteration** (BUG-P10-12, proof added behind
`skip: 'BUG-P10-12'`). **One major shared bug remains open** (BUG-P10-10,
the only stable red in the feature). No screen code was changed.

| Id | Iter-1 | Iter-2 status |
|---|---|---|
| BUG-P10-1 | major | **FIXED** — `QuestPushOnce`; same-frame double tap → 1 editor; re-arm after pop verified |
| BUG-P10-2 | major | **FIXED** — `CrossAxisAlignment.start`; proofs green |
| BUG-P10-3 | minor | **FIXED** — search + chips rendered on Ideas only; proof green |
| BUG-P10-4 | minor | **FIXED** — 16 px separators between rows; end gap 32 |
| BUG-P10-5 | major | **FIXED** — shared `NestTextField.search`; icon 24 at x+16 |
| BUG-P10-6 | major | **FIXED** — shared `NestSegmented` 52/44; proof green |
| BUG-P10-7 | major | **FIXED** — shared tab bar; Today icon centre 749 (design 748) |
| BUG-P10-8 | major | **FIXED** — `ideas` in `QuestsState`; view no longer imports GetIt |
| BUG-P10-9 | major | **FIXED** — every P10 `Semantics(excludeSemantics: true)` carries `onTap` + `container`; a11y proofs green |
| **BUG-P10-10** | major | **OPEN (shared)** — `NestSegmented` announces each option twice; 3 red tests |
| BUG-P10-11 | minor | **FIXED** — `plate`/`sofa` tints |
| **BUG-P10-12** | — | **OPEN — new major** (P10-local) — applied search filter invisible after a tab round-trip |

---

## BUG-P10-12 — major — the applied search filter goes invisible after a tab trip

`quest_library_body.dart:38` keeps `_query` in `_QuestLibraryBodyState`, while
the search field exists only while `filtersOn` (`:118-131`, the BUG-P10-3
fix). Switching to Active removes the `NestTextField` from the tree and
disposes its internal text state; `_query` survives. Returning to Ideas
rebuilds an **empty** field while `filterQuestIdeas` still applies the old
query.

**Repro.** `/quests` → type `pet` (1 row: “Feed the pet”) → tap `Active (12)`
→ tap `Ideas`. The field is blank, but only “Feed the pet” is listed. With a
no-match query (`zzz`) the screen shows “No ideas found” under an empty search
field, with nothing on screen explaining why (measured: field text `""`,
empty state `true`).

**Proof (skipped with the bug id):** `returning to Ideas can show a query that
hides rows` in `p10_bugs_test.dart` — fails today with `Found 0 widgets with
text "Make your bed"` under the empty field. Fix-agnostic: it passes if the
app either keeps the query **visible** or clears it.

**Fix.** Hoist a `TextEditingController` in `_QuestLibraryBodyState` and pass
it to `NestTextField.search` (the field keeps showing the applied query across
tab switches; `_query` stays derived from it), or clear `_query` when
`filtersOn` goes false. Either way, un-skip BUG-P10-12.

## BUG-P10-10 — major — `NestSegmented` announces every option twice (shared)

`nest_segmented.dart:53-58` wraps each option in `Semantics(button, selected,
label, onTap)` without `excludeSemantics: true`, so the option's own `Text`
and the `InkWell` node merge into a second “Ideas” node. `find.bySemanticsLabel
('Active (12)')` matches **2** and a screen reader reads every label twice.
Proofs (red, owned by stage 3): `each option is one labelled, tappable
button`, `every interactive node announces what it does`, `the same semantics
contract holds in dark` in `quest_library_a11y_test.dart`.

**Fix (one line, shared):** add `excludeSemantics: true` to that per-option
`Semantics`; keep the `onTap` batch4 added. Filed in `SHARED_REQUEST.md` §1.
Not fixable under RULES §1 (core).

---

## Adversarial probes this iteration (no additional bugs)

| Area | Result |
|---|---|
| Push guard same-frame / cross-frame | Double tap before a frame → 1 `/quest-editor`; 50 ms-later tap absorbed → 1; back → `/quests`; fresh tap pushes again (re-arm) ✓ |
| Push guard via assistive tech | `performAction(tap)` on `+ Add` and on an Active row pushes the editor ✓ |
| A11y actions (new rule) | Chip `performAction(tap)` filters the list; `+ Add`/row push; segmented switches tab; search field is a labelled text field. Only the shared duplicate label (BUG-P10-10) is red |
| Absolute geometry, 390×844 with 47/34 insets (real fonts) | title top **55**; segmented top **105**, height **52**; `.search` row 173–225 (inner input 177–221, 44); chips top 225, chip centre 247; first card top **289**; Today icon centre **749** — every value within ±2 px of the design (notes items 1–5) |
| Regression suite | Iteration-1 proofs 9/9 green; responsive matrix 320/390/430 × 1.0/1.3 × light/dark green |
| Back / deep links | Editor back → `/quests`; `/quests` and `/quests/` match; kid mode → `/parental-gate` ✓ |
| Restart / Drift persistence | Re-pump and file-DB reopen keep `Active (12)`; a live insert updates to `Active (13)` ✓ |
| Dark mode | Tokens unchanged; tinted tiles stay tinted; contrast pairs ≥ 4.5:1 ✓ |
| 320 px + 1.3 scale, long UK names, 9999 coins, empty lists, async mid-push | All green (matrix + proofs) |
| Europe/London + BST, money pence, 0/1/6 children | N/A — no dates, no `£`, no child data on P10 |

Process note: the concurrent TEST stage (iteration 2) was writing
`quest_library_a11y_actions_test.dart` and editing `quest_idea_meta_test.dart`
while this stage ran; loader failures/analyze infos from those two files at
capture belong to that stage, not to this report. The 3 stable red tests are
BUG-P10-10 above.

## Gates at hand-off

- `flutter analyze test/features/quests/p10_bugs_test.dart lib/features/quests` → **No issues found**.
- `dart format --set-exit-if-changed` on the bug file → clean.
- `flutter test test/features/quests/p10_bugs_test.dart` → **9 passed, 1 skipped, 0 failed** (the skip is BUG-P10-12).
- BUG-P10-12 un-skipped → fails with the expected assertion; the other nine proofs pass on `caeefe1`.

