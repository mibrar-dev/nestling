# P10 · Stage 2b — build, UI chunk (iteration 1)

Scope: `app/lib/features/quests/presentation/views/**` +
`presentation/widgets/**` and the view/widget tests in
`app/test/features/quests/` (`quest_library_view_test.dart`,
`quest_library_widget_test.dart`). No `domain/`, `data/` or `bloc/` file was
touched — those belong to the parallel logic builder.

## CONTRACT CHANGES (re-read before finishing)

`2a_build_logic.md` says **None** — `QuestsRepository.watchItems()` /
`ideas()`, `QuestsLoadRequested`, `QuestsState(status, items, errorMessage)`
and `QuestsStatus` are exactly the names plan §b specifies. The UI layer was
coded against that contract unchanged; nothing had to be re-based. `2a`'s
"Layer boundary" list (`quest_idea_meta.dart`, the filter fn,
`QuestLibraryBody`, `QuestFilterChip` / `QuestIdeaRow` / `QuestAddButton`,
and tests 1–3 of plan §f) is exactly what this stage shipped.

## Files

New widgets/views:

| File | Lines | What |
|---|---|---|
| `presentation/views/quest_library_view.dart` | 80 | route shell: `Scaffold` + `SafeArea`, `BlocBuilder` status switch (spinner / failure + `Try again` / `QuestLibraryBody`) |
| `presentation/widgets/quest_library_body.dart` | 190 | scroll body; local `_tab` / `_query` / `_category`, `ListView`, gutters, segmented, search, chip row, rows, empty states |
| `presentation/widgets/quest_category_chips.dart` | 56 | `.chipscroll` — horizontal `SingleChildScrollView`, 20 px inner padding, 8 gap |
| `presentation/widgets/quest_filter_chip.dart` | 66 | `.chipscroll .chip` — 44-high pill |
| `presentation/widgets/quest_idea_row.dart` | 180 | `.trow` + `.addbtn` (`QuestAddButton`) |
| `presentation/widgets/quest_idea_meta.dart` | 198 | `kQuestCategories`, `QuestIdeaMeta`, `kQuestIdeaMeta` (10 templates), `filterQuestIdeas`, `questIconAsset`, `questTileTintFor` |

Tests: `quest_library_view_test.dart` (10 tests), `quest_library_widget_test.dart`
(15 tests) — 25 total.

## Implemented (plan §a–§f)

- **Layout**: title → segmented → search → category row → rows, exactly the
  HTML order. `.ptitle`'s `padding-top:8` is a leading `SizedBox`; `.scroll`'s
  20 px gutter is applied **per child** via `_gutter`, because Flutter forbids
  negative padding and the chip row must bleed to −20/+20
  (`.chipscroll { margin: 0 -20px; padding: 0 20px 4px }`). That `margin: 0`
  also cancels `.scroll > * + *`, so the chip row is correctly **flush** under
  the search field with no 16 px gap — matching both PNGs.
- **Bottom edge**: `ListView` padding is `bottom` only (`s8`); the view adds no
  bar, no container and no `extendBody`, so nothing can paint below the
  `ParentShell` tab bar and the tab-bar surface runs to the physical edge.
  Checked in both themes.
- **Alignment**: every card/title/segmented/search is 350 wide at x=20;
  `quest_library_view_test.dart` asserts `card.left == NestSpacing.padSide`
  and `card.width == 390 - 2 * padSide`; only the chip row bleeds, by design.
- **Tokens only**: no literal colour or size anywhere. Radius `NestRadii.allM`
  (`.trow` is r-m 16, deliberately **not** `NestCard`'s r-l 24), shadow
  `tokens.cardShadow`, icon tile 40×40 r-m, all colours from `context.nest`.
- **`.trow` internals**: padding 12, gap 12, tile 40 + `NestIcon` 24,
  title Inter 16 w700 lh 22 `maxLines:1` ellipsis, meta `NestType.caption`
  (13/18 ink-2) `maxLines:1` ellipsis, `+ Add` pill 44 tall / `0 14px` /
  r-pill / 1.5 leaf border / leaf-tint / leaf-ink Inter 14 w700.
- **Copy** is character-for-character from the HTML: `Quests`,
  `Active (12)`, `Ideas`, `Search ideas` (hint) + `Search quest ideas`
  (semantics), `All, Bedroom, Kitchen, Outdoors, Pets, School, Kindness`,
  `+ Add`, and the ten `5 coins · Ages 4+ · Bedroom` lines (middot U+00B7).
  `Read for 20 minutes` comes from the repository title verbatim.
- **`Active (12)` is data-driven**: the label is
  `'Active (${widget.items.length})'` from the bloc stream — the seeded DB is
  the only source of that number (DATA OVER MOCKS). Verified by test.
- **Filter state is local** to `QuestLibraryBody` (not bloc), so typing does
  not spam `QuestsLoadRequested`. `filterQuestIdeas` is pure: case-insensitive
  title substring AND exact category; `All` passes everything.
- **Idea metadata** lives in presentation because the `quests` table has no
  category column and the schema is shared (RULES §1). `Quest.detail` is
  **not** used for idea rows (repo format is `'5 coins · age 4+'` — lowercase
  `age`, no category); Active rows still use it, which is correct there.
- **Interactions**: `+ Add` → `context.push('${QuestsRoutePaths.editor}?idea=$id')`,
  Active row tap → `context.push(QuestsRoutePaths.editor)`; both carry a
  `TODO(P10)` noting P09 does not read `?idea=` / `?id=` yet (same feature, no
  shared change).
- **States**: loading = centred `CircularProgressIndicator(color: leaf)`;
  failure = message + `NestButton` secondary `Try again` re-adding
  `QuestsLoadRequested`; no ideas match → `NestEmptyState` `No ideas found` /
  `Try a different search or category.`; `Kindness` (0 templates) hits the
  same block; Active tab empty → `No active quests` / `Add one from Ideas.`
- **Accessibility**: labelled search field, `selected` on chips, `Add {title}`
  on `+ Add`, `Quest lists` on the segmented control, whole-row semantics on
  Active rows. Tap targets: chips 44 high and ≥44 wide, `+ Add` 44×44,
  search ≥44. Width 320 and 1.3× text scale are covered by overflow tests.

## Owner-rule compliance

| Rule | Status |
|---|---|
| PIP | N/A — no Pip on P10. |
| STATUS BAR | `SafeArea` only; no fake status bar drawn. |
| DATA OVER MOCKS | `Active (${items.length})`, never a literal. |
| PERIODS | N/A — this screen lists templates/actives, it does not judge completion status. |
| BOTTOM EDGE | View adds nothing below content; shell tab bar runs to the edge. |
| ALIGNMENT | 20 px gutters asserted in tests; only the chip row bleeds, by design. |
| CHILD ORDER | Rows come from `watchItems()` order (insertion order) — no sorting, no alphabetical pass. |
| COPY | Middot `·` U+00B7 preserved; design has no curly quotes/dashes on this screen; asserted char-for-char. |
| FONTS | No `google_fonts` / `GoogleFonts.*` in this feature's lib or tests (grep clean). Nunito + Inter come from bundled assets. |
| LETTER SPACING | No `copyWith(letterSpacing:)` added anywhere — `.ptitle` and `.trow` have no tracking in the CSS. |
| CHIP ROWS | `NestChipWrap` rule N/A: this row uses `QuestFilterChip` (44-high *visual* pill), not `NestChip`, and it scrolls horizontally instead of wrapping — the rule's premise (a 32 px chip inside a 44 px hit area) does not exist here. Documented in `quest_category_chips.dart`. |
| UI CHECK MEASURES SHAPES | Tests assert the painted **rect**: chip pill 44 high / ≥44 wide, selected fill `leafTint` + 1.5 leaf border, unselected `surface2` + transparent border, `+ Add` 44 high, tile 40×40, row 68 high with 12 padding. |
| BALANCED HEADINGS | `Quests` renders through `NestBalancedText` (it is the `.h1`-weight 28/34 display face). Not used on the row/meta text. |
| TRIAL | N/A. |
| SIMULATORS | **None used.** No boot, install, screenshot or drive — this is not stage 5. |

## Verification run

```
flutter analyze lib/features/quests test/features/quests   → No issues found!
dart format --output=none --set-exit-if-changed …          → 0 changed (22 files)
flutter test test/features/quests/quest_library_view_test.dart \
              test/features/quests/quest_library_widget_test.dart
                                                          → 00:01 +25: All tests passed!
```

One lint was found and fixed during this stage:
`directives_ordering` in `quest_library_view_test.dart` (the
`quests_routes.dart` import was sorted before the `presentation/` imports).

The `drift` "AppDatabase created multiple times" warning in the test output is
the repo-wide debug-build notice from `test_scope.dart`, not a failure.

Per the brief I did **not** run the whole-app `flutter test` and did **not**
touch a simulator — the integrator does both.

## Layer boundary

Untouched, as required: `domain/`, `data/`, `presentation/bloc/`, `quests_di.dart`,
`quests_routes.dart`, `quests.dart`, `quest_editor_view.dart`,
`quests_placeholder_card.dart`, `core/**`, `app/**`. No `SHARED_REQUEST.md`
needed (plan §g: no shared change).

## LEFT FOR NEXT ITERATION

1. **Chip-row right-edge mask.** The CSS has a
   `mask-image: linear-gradient(to right, ink calc(100% - 24px), transparent)`
   so chips fade at the right edge; the build keeps the load-bearing 20 px edge
   padding and skips the fade, exactly as plan §a allows. Cheap to add with a
   `ShaderMask` if the UI check flags the hard clip against the design PNG.
2. **Visual compare** (`shot.sh` + `compare.py`, light and dark) — stage 5
   owns the simulator, so the band-drift table has not been produced yet. My
   geometry comes from the CSS, not from a rendered screenshot.
3. **`Active (n)` label** — if the seed count ever changes, the label follows
   automatically; no action needed, noting it only because `2a` flagged it.

VERDICT: PASS
