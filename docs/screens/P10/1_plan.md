# P10 · Quest library (`/quests`) — build plan

Route: `/quests` (`QuestsRoutePaths.library`). Mode: parent. Tab branch 1
(`Quests`, active). Chrome (tab bar, status/home) comes from `ParentShell`
(`app/lib/app/router.dart`); this view renders the scroll body only.
Design source: `design/html-source/screens/P10-quest-library.html` (exact CSS,
source of truth for geometry) + `design/screens/light|dark/P10-quest-library.png`
(1170×2532 @3x → divide by 3). No Pip on this screen (PIP rule N/A).

Copy (exact characters — middot `·` U+00B7, en dash `–` U+2013):
title `Quests`; segmented `Active (12)` / `Ideas` (Ideas selected);
search hint `Search ideas`, aria-label `Search quest ideas`;
chips `All, Bedroom, Kitchen, Outdoors, Pets, School, Kindness` (All selected);
rows as listed in (a); meta pattern `{coins} coins · Ages {age}+ · {Category}`;
`+ Add` buttons with aria-label `Add {title}`;
`Reading – 20 minutes` uses en dash.

## (a) Widget tree top→bottom (tokens only, never hard-code)

`QuestLibraryView` (Stateless, `Scaffold` + `SafeArea`, paper bg via theme —
no `AppBar`, no own tab bar):

1. `ListView`, padding `EdgeInsets.fromLTRB(20, 0, 20, 32)` (scroll rule),
   separators 16 (`SizedBox(16)`; `.scroll > * + *`).
   - `Text('Quests')` — `NestType.h1(color: ink)` (`.ptitle`: Nunito 28/34
     w900), `padding-top: 8` (`SizedBox(height: 8)` above or top padding).
   - `NestSegmented<String>` options `active → 'Active (12)'`,
     `ideas → 'Ideas'`; value `ideas` initially. Label for Active MUST be
     `'Active (${items.length})'` from the DB stream (seed = 12; never
     hard-code — DATA OVER MOCKS). Semantic label `Quest lists`.
   - Search: `NestTextField` (no label), `hintText: 'Search ideas'`,
     `prefixIcon: NestIcon(NestIcons.search, color: ink3)`, type search.
     CSS: surface bg, 1px line border, r-m (16), min-height 52,
     `padding: 4px 16px`, gap 10, input min-height 44, Inter 16.
     Wires `onChanged` → local query state (debounce not required).
   - Category row: horizontal `SingleChildScrollView` (NOT `NestChipWrap` —
     this row scrolls, it does not wrap), full-bleed:
     `margin: 0 -20px; padding: 0 20px 4px` → implement as a scroll view
     with `padding: EdgeInsets.fromLTRB(20, 0, 20, 4)` inside a
     `SizedBox(width: -20 margins)` equivalent: wrap the scroll in a
     container with `margin: EdgeInsets.symmetric(horizontal: -20)`.
     Fade mask on the right edge (CSS mask) — approximate with an
     8px gradient overlay? Keep simple: no mask, edge padding 20 is the
     load-bearing part. Gap 8. Chips are **44 high visually**
     (`.chipscroll .chip{min-height:44px}`, SPACING conflict §9.5), so do
     NOT use `NestChip` (32-high visual). Feature-private
     `QuestFilterChip` (widgets/): pill 44 high, padding `0 14px`,
     radius pill, Inter 14 w600; unselected surface-2/ink;
     selected leaf-tint/leaf-ink + 1.5 leaf border. `Semantics(button,
     selected, label)`, ≥44×44 tap (is 44 high; width ≥44 for `All` —
     assert in tests).
   - Ideas list: one feature-private `QuestIdeaRow` per template (widgets/):
     `Container`, surface bg, radius **r-m (16)** (`.trow`, NOT `NestCard`
     which is r-l 24), `boxShadow: cardShadow` (sh-1), `padding: 12`,
     row gap 12, `min-width: 0`:
     - icon tile 40×40, radius r-m (16), tint bg/fg per idea (below);
       `NestIcon(icon, size: 24, color: tintFg)`.
     - `Expanded` column: title Inter 16 w700 lh 22, maxLines 1, ellipsis;
       meta 13/18 ink-2, maxLines 1, ellipsis.
     - `QuestAddButton`: 44 high, min-width 44, padding `0 14px`,
       radius pill, border 1.5 leaf, leaf-tint bg, leaf-ink Inter 14 w700,
       label `+ Add`. `Semantics(button, label: 'Add {title}')`.
   - Ideas in order with (icon → `NestIcons.*`, tile tint, coins, age,
     category):
     1. `Make your bed` — bed / peach / 5 / 4+ / Bedroom
     2. `Lay the table` — table / sky / 10 / 5+ / Kitchen
     3. `Put the bins out` — bin / leaf / 15 / 8+ / Outdoors
     4. `Empty the dishwasher` — dishwasher / sky / 15 / 7+ / Kitchen
     5. `Hoover the stairs` — hoover / lilac / 20 / 9+ / Bedroom
     6. `Feed the pet` — paw / coin / 5 / 4+ / Pets
     7. `Pack school bag` — schoolBag / sky / 5 / 5+ / School
     8. `Water the plants` — sprout / leaf / 10 / 5+ / Outdoors
     9. `Help with the washing` — washingMachine / peach / 15 / 7+ / Bedroom
     10. `Read for 20 minutes` — book / lilac / 10 / 5+ / School
     (Kindness category has no templates — selecting it shows empty state.)
     Verify every `NestIcons` name exists in
     `app/lib/core/design_system/components/nest_icon.dart`; repo idea keys
     (`plate, bins, leaf, shirt, bag`) do NOT map 1:1 — the mapping above
     is normative.
   - Active tab content (design shows Ideas; Active tab still required):
     same `.trow` geometry listing DB active quests (`watchItems`, seed 12:
     6 Maya + 4 Leo + 2 Anyone), row = icon tile + title + detail meta,
     NO `+ Add`; tapping a row → `/quest-editor` (see (c)).

2. Bottom edge / alignment (OWNER RULES): view adds nothing below content;
   `ParentShell` tab bar (surface) runs to the physical edge. Side gutters
   exactly 20 everywhere; title, segmented, search, rows all 350 wide and
   edge-aligned (only the chip scroll bleeds to −20/+20 by design).

Dark mode: all colours via `context.nest` tokens (surface, surface-2, line,
leaf, leaf-tint, leaf-ink, ink/ink-2/ink-3, peach/sky/lilac/coin tints);
tile tints use the design-system tint pairs (check PNG dark: tinted tiles
stay tinted, never grey).

## (b) BLoC events/states + repository

No schema/seed change. `QuestsRepository` already exposes `watchItems()`
(active quests, Drift) and `ideas()` (10 static templates). `QuestsBloc`
keeps `QuestsLoadRequested` + `emit.forEach(watchItems())` (RULES §4).

UI state (`_tab: active|ideas`, `_query: String`, `_category: String`) is
local to a new `StatefulWidget` (`QuestLibraryBody`) — NOT bloc state
(same pattern as other filter screens; avoids event spam per keystroke).
`QuestLibraryView` stays the route shell (`BlocProvider` + status switch);
loaded state renders `QuestLibraryBody(items:…, ideas:…)`.

Category/age/tint metadata: the `Quest` entity has NO category field and the
DB `quests` table has none either — do NOT add one (shared schema). Add a
static const map in `presentation/widgets/quest_idea_meta.dart`:
`idea id → (category, minAge, tileTint, iconAsset)` for the 10 template ids
(`idea-bed`, `idea-table`, `idea-bins`, `idea-dishwasher`, `idea-hoover`,
`idea-pet`, `idea-bag`, `idea-plants`, `idea-washing`, `idea-reading`).
Row meta string is formatted in presentation from
`coins/minAge/category` — never use `Quest.detail` for ideas (repo format
`'5 coins · age 4+'` lacks category and uses lowercase `age`).

Search filter: case-insensitive substring on idea title; category filter:
`All` or exact match. Both combine (AND).

## (c) Interactions + navigation (route constants)

- Segmented `Active/Ideas` → switches local `_tab` (no route change).
- Search input → updates `_query`, filters ideas live.
- Category chip → single-select `_category` (All default).
- `+ Add` on idea `{id}` → `context.push('${QuestsRoutePaths.editor}?idea={id}')`
  (`/quest-editor?idea=…`; import `quests_routes.dart`). P09 (same feature)
  reads `idea` — if P09 does not support the query param yet, it opens the
  editor blank; add a `TODO(P10)` comment. No shared change.
- Active-tab row tap → `context.push(QuestsRoutePaths.editor)` (edit path;
  same TODO if id-param unsupported).
- Tab bar taps → handled by `ParentShell` (Today/Quests/Money/Family).

## (d) Empty / loading / error states

- Loading/initial: centered `CircularProgressIndicator(color: leaf)`.
- Failure: centered message + `NestButton.secondary` `Try again`
  re-adding `QuestsLoadRequested`.
- Ideas + query/category with 0 matches: `NestEmptyState`-style block —
  title `No ideas found`, body `Try a different search or category.`, no CTA.
- Kindness category → same empty block (0 templates by design).
- Active tab with 0 active quests: title `No active quests`,
  body `Add one from Ideas.` (Seed.empty path).

## (e) Accessibility

- Search is a labelled text field (`Search quest ideas`); chips expose
  `selected`; `+ Add` exposes `Add {title}`; segmented exposes options.
- Tap targets: search input ≥44 high; filter chips 44 high / ≥44 wide;
  `+ Add` 44×44 min; segmented buttons 44 high (via `NestSegmented`).
- Text scale: app clamps 1.0–1.3; rows use `Expanded` + maxLines 1 ellipsis
  so 1.3× never overflows; chip scroll scrolls horizontally.
- Width 320: gutters stay 20; rows shrink via `Expanded`; icon tile and
  `+ Add` fixed outside the flexible column.
- Contrast from tokens (both themes); no red anywhere (parent destructive
  colour unused here).

## (f) Test plan (`app/test/features/quests/` — new dir)

1. `quest_idea_meta_test.dart`: all 10 repo `ideas()` ids have metadata;
   categories ⊆ {Bedroom, Kitchen, Outdoors, Pets, School, Kindness};
   formatted meta strings equal design copy character-for-character
   (incl. `·`, `–`); icon assets exist.
2. `quest_library_filter_test.dart`: pure filter fn — query/category AND
   logic; `Kindness` → empty; empty query + All → 10.
3. `quest_library_view_test.dart` (pump app, end with `disposeApp(tester)`):
   title/segmented/search/chips/10 rows render; `Active (12)` label from
   seeded DB; switching tabs; search filters; chip selects; `+ Add`
   pushes `/quest-editor?idea=…`; 44px tap-target assertions on chips
   and `+ Add`; semantics labels present.
4. `quests_bloc_test.dart`: `watchItems` emits seeded actives in order.
5. `dart format .` clean; `flutter analyze` no issues; full `flutter test`
   passes. Never import `google_fonts` (removed dependency).

## (g) SHARED_REQUEST

None. No schema, seed, route-shell, or design-system change needed:
filter chips and `+ Add` are feature-private widgets built from existing
tokens (44-high pill is a P10-local CSS override, SPACING §9.5); category
metadata lives in presentation; `?idea=` is a same-feature query param.

VERDICT: PASS
