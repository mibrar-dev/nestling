# Shared batch 4 — REPORT (branch `shared/shared_batch4`)

Scope: P10 `SHARED_REQUEST.md` §§1–5 (BUG-P10-5/6/7 proofs in `6_bugs.md`).
All changes are minimal and backward-compatible: one new named constructor,
two component resizes via existing tokens, one inset-additive `SafeArea`,
one additive schema migration, seed-only timestamp stamps. No public API
renames, no route changes, no screen presentation code touched. Screen
branches merge and compile without edits.

Evidence read first: P10 `SHARED_REQUEST.md` §§1–5, P10 `6_bugs.md`
(BUG-P10-5/6/7 measurements), P10 `ORCHESTRATOR_NOTES.md` (design targets:
icon x+16 / hint x+50, segmented 52/44, bar top 726 / icon 748 / label 772),
`docs/ARCHITECTURE.md`, `docs/screens/RULES.md`,
`docs/design/SPACING_SPEC.md`, `tools/screens/stages/common.md` (owner
rules), `docs/research/DATETIME_STORAGE.md` (UTC instant + IANA zone),
`design/html-source/components.css` + `screens/P08-today.html` +
`P10-quest-library.html`, `design/html-source/tokens.css`
(`box-sizing: border-box`), `design/screens/light/P08-today.png`.

## Files changed

- `app/lib/core/design_system/components/nest_text_field.dart` — new
  `const NestTextField.search(...)` named constructor (item 1). Existing
  `const new(...)` constructor byte-identical in behaviour (gains only the
  `semanticLabel = null` initializer for the new field).
- `app/lib/core/design_system/components/nest_segmented.dart` — track 44 →
  52, buttons 36 → 44, via existing tokens (`tapParent + s2`, `tapParent`);
  doc comment corrected (item 2).
- `app/lib/core/design_system/components/nest_tab_bar.dart` — the 84 px
  content block is now wrapped in `SafeArea(bottom)` inside a
  surface-coloured outer `Container`, so content keeps the design position
  and the surface runs to the physical edge (item 3).
- `app/lib/core/data/app_database.dart` (+ regenerated
  `app_database.g.dart`) — `quests.created_at` (UTC, `currentDateAndTime`
  default) + `created_at_tz` (London default), `schemaVersion` 3 → 4,
  v3 → v4 migration (same rowid-order backfill trick as v2 → v3), and
  `watchActiveQuests` ordered by `created_at`, then `id` (item 5).
- `app/lib/core/data/seed.dart` — `_questsDemo` stamps each quest one
  second after the previous (`utc(9, 19, 8) + index`), so the seed renders
  in insertion order under the new sort (item 5).
- Tests: new `app/test/design_system/shared_batch4_test.dart` (9 tests),
  new `app/test/core/data/quest_order_test.dart` (4 tests); updated
  `app/test/design_system/inputs_test.dart` (segmented 52/44),
  `app/test/design_system/overflow_test.dart` (owner-QA segmented 52/44),
  `app/test/core/data/children_order_test.dart` (v2 fixture gains the
  v2-shape `quests` table — real v2 databases always have it, and the v4
  open now runs the v4 step on that fixture),
  `app/test/features/today/today_view_test.dart` (two placeholder-text
  assertions → `pushedPath`, item 4).
- `app/lib/features/quests/...` and `quest_library_view.dart`: untouched.
  This tree has no hidden `Text('P10 Quest library')` anchor or `Stack`
  wrapper (the view is still the foundation placeholder with a visible
  `AppBar` title) — P10 deletes its branch-local anchor after merging this
  (per SHARED_REQUEST §4).

## Item 1 — search prefix (§1) → DONE

Was: P10 passes a 24 px `NestIcon` as `prefixIcon`; Material's default
`prefixIconConstraints` floor the slot at 48 px (icon stretched to 48×48
at field x+0, hint pushed to x+64). Chose the `NestTextField.search`
constructor over a `prefixIconConstraints` pass-through: the request
itself notes Material centring alone lands the icon at x+13, not x+16 —
only a plain `Row` (no `InputDecoration` prefix slot) hits the design
slot deterministically. Three framework quirks, all pinned by test:

- A `TextField` is a scrollable and expands to its max height, so the
  input gets a fixed 44 px box (the design's `input min-height:44px`) with
  `TextAlignVertical.center` — a min-height lets the row stretch to the
  parent (measured 844 in the harness before the fix).
- The editable's text origin sits 4 px inside the decoration content box
  (measured, stable across border/filled/borderless variants), so the
  decoration carries `contentPadding: left -4` and the rendered hint
  starts exactly at the gap edge (16 + 24 + 10 = x+50).
- The design is `border-box` (`tokens.css:200`), so 52 px is the TOTAL
  incl. the 1 px border: 3 + 44 + 3 + 2 × 1. Vertical padding is 3 px
  (`NestSpacing.gap3`), not the CSS 4 px — centred content paints
  identically and the row measures exactly 52 (a 4 px pad totals 54 and
  fails the 52 ± 1 band).

No existing `NestTextField` use passes `prefixIcon` (verified by grep —
only P10's unmerged branch does), so nothing existing changes.

## Item 2 — segmented 52/44 (§2) → DONE

`components.css`: `.segmented { padding:4px }`, buttons
`height:40px` vs `min-height:44px` (min wins → 44), so track = 4 + 44 + 4
= 52. Selected pill keeps r-pill + sh-1 (light) / 1 px line border, no
shadow (dark) — both re-pinned. Grep over `app/lib/features`: the only
uses are dev-gallery demos (`gallery_parent_a`, `pip_lab_view`,
`motion_lab_pip_panel`) with no design PNG — no merged screen uses it.
Two shared tests asserted the old 44/36 and were updated ONLY after
confirming 52/44 against the CSS + the P10 PNG band (315–470 @3x = 52):
`inputs_test.dart` (`44 thumb in a 52 container`) and `overflow_test.dart`
(owner-QA `segmented geometry and dark border`). Merged screens affected:
none.

## Item 3 — tab bar content up, surface to edge (§3) → DONE

CSS: `.tab-bar { height:84px; padding:8px 4px 24px }` above the 34 px home
strip → content block 726–810 at 390×844 (icon centre 726 + 8 + 2 + 12 =
748, label centre ≈ 726 + 8 + 2 + 24 + 4 + 7 = 771 ≈ 772), surface to 844
per the owner rule. `SafeArea(top/left/right: false, bottom: true)` pads
only the OS inset below the unchanged 84 px block, in the same surface
colour (top border stays at the content top, y 726). Zero inset ⇒ exactly
the old 84 px bar, so `chrome_test` (`84 bar`), the P08 bottom-edge test
(`height == tabH`, surface colour) and every gallery usage pass
unchanged. Verified with real insets (`tester.view.padding/viewPadding`,
physical px = logical × 3, the P05 pattern): 47/34 → bar 726–844
(118 high), icon centre 748 ± 1, `Today` label centre 772 ± 2, surface
colour to y 844 (rect + decoration assertions, light and dark); 0/0 → 84
at the edge. P08 check: full `today_view_test.dart` + `today_repository_`
+ `p08_bugs_test.dart` green, and the P08 PNG band (bar top 726, icon
748) matches the new geometry. `ParentShell` (`router.dart`) untouched —
the fix lives in `NestTabBar`, so all four branches inherit it.

## Item 4 — test hygiene (§4) → DONE

`today_view_test.dart` `See all opens the quest library` (~286) and the
P08b `Browse ideas` tap (~335) now assert `pushedPath(tester) ==
'/quests'` only — no placeholder copy. `_currentUri` helper kept (still
used by 8 other navigation assertions). `quest_library_view.dart`
untouched (no anchor exists in this tree; see Files changed).

## Item 5 — quest creation order (§5) → DONE

Orchestrator decision implemented: `watchActiveQuests` sorts by
`created_at`, then `id` (deterministic tie-break for same-second
inserts). `quests` had no `created_at`, so schema v4 adds `created_at`
UTC + `created_at_tz` (London default), mirroring `DATETIME_STORAGE.md`
and the v2 → v3 `children` migration (constant-0 `ADD COLUMN` +
`strftime('%s','now') + rowid - MIN(rowid)` backfill = seed order on
migrated databases), with a migration test. `createQuest` intentionally
untouched: absent columns take the `currentDateAndTime`/London defaults,
so a newly created quest stamps "now" and sorts last (covered by test).
Merged-screen impact checked: Today re-sorts pending-first then α in
`rows()`, KidHome sorts by title, Family uses counts — raw DB order
reaches no merged screen. P08's list order (pending-first, dishwasher
first) is pinned by `today_view_test.dart` and still passes against the
P08 design. `quests_repository_test.dart` (title-order pins,
P10-branch-only) must be updated by P10 after merging this — listed as a
follow-up below, not editable from here.

## Tests

New `shared_batch4_test.dart` (real Inter/Nunito via `FontLoader`, 390×844):

- `NestTextField.search: icon 24 at x+16, hint at x+50, field 52 high`
  (both themes)
- `NestTextField.search: typing reports the query`
- `NestTextField.search: semantic label marks the text field`
- `NestSegmented: selected pill keeps r-pill and sh-1` (light)
- `NestSegmented: dark selected pill keeps r-pill with a line border`
- `NestTabBar: no inset — exactly the 84 block at the edge`
- `NestTabBar: 47/34 — content at the design position` (726/748/772)
- `NestTabBar: light/dark surface colour fills down to y 844`

New `quest_order_test.dart`:

- `seed demo lists the Active quests in creation order` (12 ids in seed
  order, strictly increasing instants, London zones)
- `a quest added later sorts last, even an alphabetical first`
  (`a-aaa`/`AAA first quest` — would be first alphabetically)
- `deactivating a quest keeps the order of the rest`
- `v3 → v4 migration backfills created_at in rowid order and orders the
  Active list` (Zebra-then-Apple fixture)

Updated: `inputs_test` 44-thumb→52/44, `overflow_test` owner-QA 52/44,
`children_order_test` v2 fixture + `quests` table, `today_view_test` 2×
`pushedPath`.

Gates: `dart format .` clean (0 changed), `flutter analyze` → No issues
found, `flutter test` → 1395 passed, 0 failed.

## Follow-ups for screens

- P10 (after merging this): switch the search field to
  `NestTextField.search(hintText: 'Search ideas', keyboardType: text,
  textInputAction: search, semanticLabel: 'Search quest ideas',
  onChanged: ...)` and drop the `prefixIcon` + outer `Semantics` wrapper
  (the constructor provides the label); un-skip BUG-P10-5/6/7 proofs;
  delete the hidden `Text('P10 Quest library')` anchor + `Stack` wrapper;
  update `quests_repository_test.dart:26-49` title-order pins to creation
  order (seed order listed in `quest_order_test.dart` as `_seedOrder`).
- P08 / all other merged screens: nothing — suites green, no follow-up.
- Note for P10's BUG-P10-5 proof: `find.byType(TextField)` rect is the
  inner editable, not the field — measure the first `Container` under
  `NestTextField` (or the `NestTextField` rect itself) for field-relative
  x offsets.

VERDICT: PASS
