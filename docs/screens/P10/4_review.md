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

VERDICT: FAIL
