# Shared batch 2 — REPORT (branch `shared/shared_batch2`)

Scope: the four design-system/data fixes blocking P03, P05 and K03. All
changes are backward-compatible: new optional parameters with defaults, one
new required-at-most column with a column default (no new required insert
arguments), no public API renames, no screen-code edits. Screen branches
merge and compile without edits.

Evidence read first: `P05/docs/screens/P05/5_ui.md` item 1 (chip row 44 vs
design 32), `P03/docs/screens/P03/3_test.md` (P03-BUG-16) + P03
`SHARED_REQUEST.md` §§5/8, `K03/docs/screens/K03/4_review.md` finding 1 +
K03 `ORCHESTRATOR_NOTES.md`, P05 `SHARED_REQUEST.md` (child order).

## Files changed

- `app/lib/core/design_system/components/nest_chip.dart` — pill lays out at
  the design 32 px; ≥44×44 tap area via a layout-neutral hit-test expander.
- `app/lib/core/design_system/components/nest_text_field.dart` — error state:
  2 px danger border + gutter error row announced through a live region.
- `app/lib/core/design_system/components/nest_pet_stage.dart` — explicit
  size mode (`nestWidth` / `fixedPipHeight`); legacy capped sizing default.
- `app/lib/core/data/app_database.dart` (+ regenerated
  `app_database.g.dart`) — schema v2 → v3: `children.created_at` +
  `created_at_tz`; `watchChildren` orders by creation, then `rowid`.
- `app/lib/core/data/seed.dart` — Maya created before Leo (explicit).
- `app/lib/features/family/data/family_repository_impl.dart` — `addChild`
  stamps an explicit creation instant (data layer only, no presentation
  touched).
- Tests: new `app/test/design_system/shared_batch2_test.dart`,
  `app/test/core/data/children_order_test.dart`; updated
  `app/test/design_system/inputs_test.dart`,
  `app/test/design_system/shared_batch1_test.dart`,
  `app/test/design_system/overflow_test.dart` (chip gate now asserts the
  32 px layout; the 44 hit area is proven functionally),
  `app/test/core/data/time_migration_test.dart` (v1 fixture gains the
  `children` table real v1 databases had).

## Item 1 — NestChip visual size (blocks P05) → DONE

Was: the interactive branch carried the 44 minimum AS the layout box
(vertical 4.5 padding around the pill), so chip rows measured 44 tall and
pushed P05's swatch row +12 px low. Also fixed en route: the pill measured
35, not 32, because `Container` folds a `BoxDecoration` border into its
size — now `Padding` + `DecoratedBox` (border paints inside), exactly 32;
and the content uses a fixed-32 `SizedBox` instead of `Center` (which takes
the full run width and forced one chip per `Wrap` row).
Now: layout is the 32 px pill in both branches; `_ExpandedHitBox` (private,
outermost render object) shrink-wraps the pill and widens only the hit
test to ≥44×44, forwarding outside hits with the position clamped just
inside (epsilon-inset, since `Size.contains` excludes the bottom/right
edge) so the `InkWell` below accepts them. Single `onTap` path — no double
fire, ripple kept. Narrow pills keep the 44 minimum width.
Tests (`shared_batch2_test.dart` → `SHARED BATCH 2 NestChip`): `interactive
chip lays out 32 tall`, `static chip lays out 32 tall`, `tap 6 px outside
the visual chip still selects`, `tap 6 px below the visual chip still
selects`, `Wrap of chips at text scale 1.3 still has no overflow`.
Follow-up for P05: drop any chip `IntrinsicWidth`/height workaround and
re-measure the swatch row (expect Avatar label ≈516, swatches ≈529–573).

## Item 2 — NestTextField error state (blocks P03) → DONE

Was: the gutter error row (batch 1) rendered as a plain `Text` with a 1 px
danger border — no live region, so P03 had to choose between the design's
red border (shared `errorText`) and the announcement (owned rows).
Now: `errorText != null` paints a 2 px danger-token border (all four
borders) and the gutter row is `Semantics(liveRegion: true, label:
errorText)` + `ExcludeSemantics` text — announced once, exactly like
Material's own error row was. No new flags: passing `errorText` changes
nothing else (helper still error-wins), so screens passing null are
pixel-identical.
Tests (`shared_batch2_test.dart` → `SHARED BATCH 2 NestTextField error
state`): `error border is the 2 px danger token (light)`, `error border is
the 2 px danger token (dark)`, `error row announces through a live region
exactly once`.
Follow-up for P03: pass `errorText` to both fields, delete the two owned
error rows + their `buildWhen` selectors, un-skip P03-BUG-16 (closes
P03-BUG-16/20/21 together per `SHARED_REQUEST.md` §8).

## Item 3 — NestPetStage target size (blocks K03) → DONE

Was: `pipSize` was only a cap on parent-derived sizing — no API could reach
K03's 260×236 slot with its ≈152-tall Pip.
Now: `nestWidth` renders the nest exactly that wide with Pip at the design
ratio (`pipPerNestWidth = 152/260`); `fixedPipHeight` pins the Pip height
(nest derives via the scene split unless `nestWidth` is also set). Both
null (default) keeps the legacy max-width-derived sizing capped by
`pipSize` — all existing call sites (gallery, overflow probes, K03's
`pipSize:`) render byte-identical.
Tests (`shared_batch2_test.dart` → `SHARED BATCH 2 NestPetStage explicit
size`): `nestWidth 260 yields a 260 nest and a 152 Pip`, `fixedPipHeight
overrides the Pip height`, `default sizing still caps by pipSize`.
Follow-up for K03: pass `nestWidth: 260` (or `fixedPipHeight: 152`) in
`kid_home_view.dart`, drop the `TODO(K03)` local slot, re-measure the
hearts row/section title/progress/first-card/dock tops.

## Item 4 — Child creation order (app-wide rule) → DONE

Was: `watchChildren` ordered by `nickname` (Leo before Maya); the table had
no creation marker.
Now: `children.created_at` (UTC instant, `currentDateAndTime` default) +
`created_at_tz` (London default); schema v2 → v3. SQLite forbids
non-constant defaults in `ADD COLUMN`, so the migration adds `created_at`
via raw SQL (constant 0 placeholder) + `m.addColumn` for the zone, then
backfills `strftime('%s','now') + rowid - MIN(rowid)` — staggered seconds
in insertion order. `watchChildren` orders by `created_at`, `rowid`
(SHARED_REQUEST option (a) + the `rowid` tiebreak, so every roster screen
inherits the ruling at once). Seed stamps Maya before Leo; `addChild`
stamps `now` explicitly so late adds sort last even on migrated databases.
`ChildrenCompanion.insert` gains only optional params — other branches'
inserts/tests still compile (omitted ⇒ column default ⇒ `now` on fresh
DBs).
Tests (`children_order_test.dart`): `seed demo lists Maya then Leo
(creation, not alphabetical)`, `a child added later appears last, even an
alphabetical first`, `v2 → v3 migration backfills created_at in rowid
order and reorders the roster` (Zara-then-Amy fixture proves non-alpha).
Follow-up for P05/family screens: the interim `rowid` re-sort in feature
code is now redundant (harmless — same order) and can be dropped on a
touch pass; keep the `TODO(P05)` until then.

## Verification

`cd app && dart format .` clean, `flutter analyze` → No issues found!,
`flutter test` → all pass (664 green, 0 skipped by this branch).

VERDICT: PASS
