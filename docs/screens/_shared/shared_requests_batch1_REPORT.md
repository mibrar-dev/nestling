# Shared requests batch 1 — REPORT (branch `shared/shared_requests_batch1`)

Scope: every OPEN item in the six screen-agent filings. Items marked
RESOLVED / LANDED / WITHDRAWN / DONE-on-main in the filings were not
re-done (verified green by the full suite). All changes are
backward-compatible: new parameters/variants with defaults, new symbols,
no public API renames. Screen branches merge and compile without edits.

Note on rule 6: only `docs/screens/P08/SHARED_REQUEST.md` exists in this
worktree (merged from `screen/P08`), so the `RESOLVED on main by
shared/shared_requests_batch1` lines were appended there (§§2, 4, 5, 6, 7,
10). Copies for P02/P03/P04/P05/K03 do not exist on `main`; creating them
here would force add/add merge conflicts on five screen branches, so this
report is the canonical per-item record (each line below is the note text
the agent can paste under their item).

## P04 — `docs/screens/P04/SHARED_REQUEST.md`

- Trash icon → DONE. Drawn from `P04-privacy.html` (lid `M4 7h16`, handle
  `M9.5 7V5h5v2`, body `M6.5 7l1 13h9l1-13`; 24×24, stroke currentColor,
  2 px, round caps/joins). Files: `app/assets/icons/ic_trash.svg` (new;
  auto-bundled via the `assets/icons/` glob — no pubspec change),
  `app/lib/core/design_system/assets/nestling_assets.dart`
  (`NestlingIcons.trash`, Trust & privacy),
  `app/lib/core/design_system/components/nest_icon.dart`
  (`NestIcons.trash`). Tests: `shared_batch1_test.dart` → `P04 trash icon`
  (`asset is registered and bundled`, `renders in a peach tile without
  throwing`). Follow-up for P04: pass `leadingAsset: NestIcons.trash` on
  the 4th promise row and drop the TODO.
- Dark privacy shield → DONE. New `NestPrivacyShield` widget
  (`app/lib/core/design_system/components/nest_privacy_shield.dart`,
  exported from `design_system.dart`): geometry transcribed 1:1 from the
  HTML (132-unit viewBox, default 84 px) with token layers — disc
  `skyTint` (light `#E6EFFE`, dark navy `#1A2A4A` per
  `design/screens/dark/P04-privacy.png`), body `surface`, heart `leaf`,
  strokes `ink`. The baked `privacy_shield.svg` is untouched (backward
  compat). Tests: `shared_batch1_test.dart` → `P04 themed privacy shield`
  (`is 84 square and labels once`, `disc follows skyTint in both
  themes`). Follow-up for P04: replace
  `SvgPicture.asset(NestlingIllustrations.privacyShield)` with
  `NestPrivacyShield(semanticLabel: …)` (keeps its current label string).
- Settings row missing on first run → DONE in shared core (no feature
  edit): `AppDatabase.migration.beforeOpen` now also inserts the `fam1`
  family + settings rows with `insertOrIgnore` (defaults ⇒ crash consent
  OFF). Files: `app/lib/core/data/app_database.dart`. Tests:
  `app/test/core/data/migration_first_run_test.dart` (`fresh database has
  fam1 family + settings rows`, `crash-report consent defaults to OFF`,
  `a settings UPDATE matches the first-run row`, `re-opening never
  duplicates the rows`). `Seed.fresh` deliberately untouched (P04's red
  first-run proof asserts it writes app-state only). Follow-up: none —
  P04's local upsert and P16's `_write` are both covered by the guaranteed
  row.
- NestList real dividers add height → DONE: separators are now 1 px
  `Positioned` overlays (`left: 72`, line token) contributing zero layout
  height (4×56 rows = 224, not 227). Files:
  `app/lib/core/design_system/components/nest_list_row.dart`. Tests:
  `shared_batch1_test.dart` → `P04 NestList overlay dividers` (`dividers
  add no layout height`). Follow-up for all `NestList` screens: vertical
  rhythm tightens ~1 px/row — expected, matches the design overlays.

## P05 — `docs/screens/P05/SHARED_REQUEST.md`

- `push` no-op from top-level routes → INVESTIGATED, no router bug:
  `push` navigates (pixels + `GoRouter.state.uri` advance, `pop`
  returns). The probe asserted `routerDelegate.currentConfiguration`,
  which excludes imperative matches — a probe artifact, not a config bug,
  so `app/lib/app/router.dart` is unchanged. Proven by
  `app/test/app/router_push_test.dart` (`push P09 quest editor from
  /today`, `push P11 approvals from /today`, `push /value-tour from
  /welcome`, `push between top-level onboarding routes` — each asserts
  location via `state.uri` + rendered screen + back-pop return).
  Follow-up: none required — P05's `go` convention keeps working; future
  plans may use `push`. Note for test authors: `currentPath`
  (`test_scope.dart`) reads `currentConfiguration` and lags pushes; push
  tests must read `GoRouter.state.uri` (see `pushedPath` in the new test).
- Interactive `NestChip` in a `Wrap` → DONE. The bare `Center` took
  `constraints.biggest` (full run width per chip); the branch is now
  `Material → InkWell → ConstrainedBox(minWidth 44) → Padding(4.5) → Ink`
  — all shrink-wrap, so the `Wrap` sees intrinsic widths. The pill keeps
  its geometry (32 content + 1.5 border each side = 35; +2×4.5 = exactly
  44 high). Files:
  `app/lib/core/design_system/components/nest_chip.dart`. Tests:
  `shared_batch1_test.dart` → `P05 interactive NestChip in a Wrap`
  (`four age chips share one row`, `chip tap box keeps the 44 minimum`,
  `chips stay on one row at 320 wide and textScale 1.3`). Follow-up for
  P05: drop the `IntrinsicWidth` workaround, use bare `NestChip`s in the
  `Wrap`.

## P08 — `docs/screens/P08/SHARED_REQUEST.md` (copy in this worktree)

- §2 double-announced semantics → DONE (refined): `excludeSemantics:
  true` on the `NestCard` labelled branches (unlabelled cards still
  expose children) and the `NestQuestCard`/`NestKidQuestCard` tap
  wrappers — except cards with a working check (`done != null` /
  `onToggled != null`), whose `Mark done` node must stay reachable (the
  shared display/overflow tests pin it). Same one-node treatment for
  `NestButton`, brand buttons, `NestKidButton`, interactive `NestChip`,
  nav-bar text action (inner `Text` under `ExcludeSemantics`). Files:
  `nest_card.dart`, `nest_quest_card.dart`, `nest_button.dart`,
  `nest_brand_buttons.dart`, `nest_kid_button.dart`, `nest_chip.dart`,
  `nest_nav_bar.dart`. Tests: `shared_batch1_test.dart` → `P08 §2 + P03
  §§2/4 one semantics node per card/button` (8 exact-label assertions +
  unlabelled-card children stay exposed). Follow-up for P08: keep full
  announcements in `semanticLabel`; fix the feature-side B4a banner the
  same way.
- §4 push contract Today→P09/P11 → DONE (proved, no config change): see
  the P05 entry + `router_push_test.dart`. Follow-up stays with P09/P11:
  return with `context.pop()`.
- §5 DESIGN_SPEC floating pill → DONE: `docs/DESIGN_SPEC.md` §5 P08 now
  describes the header-row 44 px leaf `+`.
- §6 `DISABLE_ANIMATIONS=1` never parses → DONE: `kDisableAnimations`
  (`app/lib/core/data/env_flags.dart`) and
  `LaunchFlags.disableAnimations` (`app/lib/app/launch_flags.dart`) OR in
  `String.fromEnvironment('DISABLE_ANIMATIONS') == '1'`; `shot.sh`
  untouched. Tests: `launch_flags_test.dart` → `DISABLE_ANIMATIONS
  parsing` (`defaults to false when the flag is unset`); the `=1` parse is
  proved by the screenshot harness (see Visual verification).
- §7 quest-meta `runSpacing` → DONE: 4 → `NestSpacing.gap6` in
  `nest_quest_card.dart` (same batch as §2).
- §9 P11 scoping → NOT DONE (P11 feature territory): until P11 scopes its
  list with `countsForCurrentPeriod` (`rule ?? 'once'`), banner and Review
  list can disagree. No shared file change possible.
- §10 still-art coverage → DONE: `app/test/pip_avatar_test.dart` now pins
  `fallbackAsset` per style and pumps the reduced-motion case over every
  style × stage 1..4 asserting an `SvgPicture` renders.
- §11 day/week rollover → NOT DONE: needs an orchestrator-wide pattern
  (resume re-dispatch or period-tick stream), not a component patch.

## P03 — `docs/screens/P03/SHARED_REQUEST.md`

- §2 brand buttons doubled label → DONE: inner `Text` under
  `ExcludeSemantics` in `_BrandButton` (`nest_brand_buttons.dart`).
- §4 `NestButton` doubled label → DONE: inner `Text` under
  `ExcludeSemantics` in `nest_button.dart`.
- §5 `errorText` inside the field → DONE: the decoration no longer takes
  `errorText` (it laid out on the indented content box); the error
  renders as a gutter-aligned row under the input (13/18 danger w600,
  same x as the label), the danger border is forced explicitly (Material
  only applies `errorBorder` with decoration `errorText` set), and an
  error suppresses the helper (error-wins). Files: `nest_text_field.dart`.
  Tests: `shared_batch1_test.dart` → brand/NestButton single-label
  assertions + `P03 §5 NestTextField error gutter` (`error aligns with
  the label gutter`, `error border still turns danger`, `error replaces
  the helper`). Follow-up for P03: none (existing `contains` pins still
  pass; the local helper-row workaround is now redundant but harmless).

## P02 — `docs/screens/P02/SHARED_REQUEST.md`

- §1 compact nav wide text action → DONE: the compact trailing slot is
  content-sized with a 44 minimum (was a fixed 44 box that ellipsised
  `Skip`); empty slot keeps the 44-wide spacer with no height of its own,
  so back-less/action-less bars still resolve to 52 and all 44-fitting
  slots render identically. Files: `nest_nav_bar.dart` (+
  `ExcludeSemantics` on the action text — one announcement). Tests:
  `shared_batch1_test.dart` → `P02 §1 compact nav wide text action`
  (`Skip fits without clipping`, `compact bar stays 60 high with a text
  action`). Follow-up for P02: replace private `_TourNav` with
  `NestNavBar(compact: true, actionLabel: 'Skip', …)` and drop the
  TODO.
- §3 pager tokens → DONE: new `NestPager` in
  `app/lib/core/design_system/tokens/spacing.dart` (`stage` 52, `pet`
  158, `lineMinHeight` 32, `addDashWidth` 1.5, `addDashLength` 6,
  `addDashGap` 4, `addMinHeight` 44 — all from `P02-value-tour.html`).
  Tests: `NestPager pins the P02 geometry`. Follow-up for P02: adopt the
  consts, drop the local documented copies.

## K03 — `docs/screens/K03/SHARED_REQUEST.md`

- §1 kid quest tile tint → DONE: `NestKidQuestCard` gains `tileBackground`
  (default `surface2`) + `tileIconColor` (default ink, applies to the
  default glyph; custom `icon`s carry their own colour).
  Files: `nest_quest_card.dart`. Tests: `K03 §1` (`tileBackground
  overrides the surface2 tile`, `default tile stays surface2`).
  Follow-up for K03: pass `skyTint`/`lilacTint`/`peachTint` per quest.
- §5 `DISABLE_ANIMATIONS=1` → DONE (same change as P08 §6).
- §6 KidScope meadow band → DONE: `KidScope` gains `meadowHeight`
  (default 136), `meadowBottom` (default 0) and `meadowColor` (default
  `kidMeadow`; K03's band measured `kidHorizon`). Files: `kid_scope.dart`.
  Tests: `K03 §6` (`defaults keep the 136 shared hill`, `taller band
  renders without throwing`). Follow-up for K03: adopt the parameters,
  delete `_MeadowPainter` + TODO.
- §7 kid type styles → DONE: `NestType.kidName` (Nunito 22/26 w900),
  `kidCaption` (15/20 w700), `kidChipLabel` (15/15 w800) + `nestText`
  getters (leafInk added to `NestTextStyles`, single construction site
  updated). Files: `typography.dart`, `nest_tokens.dart`. Tests: `K03 §7`
  (`pins the kid copy geometry`, `resolves against the palette`).
  Follow-up for K03: stop calling `GoogleFonts.nunito` directly.
- §9 kid button label wrap → DONE: `NestKidButton.wrapLabel` (default
  true; false ⇒ one line + `FittedBox(scaleDown)`). Files:
  `nest_kid_button.dart`. Tests: `K03 §9` (`wrapLabel false keeps one
  line`, `default still wraps`). Follow-up for K03: pass
  `wrapLabel: false` on the dock buttons.

## Visual verification

- `tools/screens/shot.sh … /privacy` light+dark, seed fresh, on sim
  `604697A9` (build once, both themes stable first try — no `frame never
  stabilised` warning, i.e. the `DISABLE_ANIMATIONS=1` parse fix holds):
  - `/tmp/p04_verify_light.png` — READ: trash glyph in the 4th-row peach
    tile (lid + body, matches the HTML path); shield with light
    sky-tint disc, white body, leaf heart.
  - `/tmp/p04_verify_dark.png` — READ: navy disc (`#1A2A4A`), dark
    surface body, light strokes, leaf heart — matches
    `design/screens/dark/P04-privacy.png`; trash glyph correct in the
    peach tile; toggle OFF; rows/CTA/notice link match the design.
- Method note: the P04 view on this branch is still the foundation
  placeholder, so for the screenshots the committed `screen/P04` view was
  staged UNCOMMITTED plus the two one-line adoptions P04 must make
  (`leadingAsset: NestIcons.trash`; `SvgPicture.asset(privacyShield)` →
  `NestPrivacyShield`) — then fully reverted (`git checkout --
  app/lib/features/privacy_consent/`, verified clean above). Staging also
  proved the P04 branch compiles unchanged against the new shared code.
  Follow-up stays with P04 to land those two adoptions.

## Test summary

- `cd app && dart format .` clean (0 changed); `flutter analyze` → `No
  issues found!` (no new ignores).
- `flutter test`: all 527 pass, 0 fail (final full run `EXIT:0`).
- New/changed tests: `test/design_system/shared_batch1_test.dart` (30),
  `test/app/router_push_test.dart` (4), `test/core/data/
  migration_first_run_test.dart` (4), `test/app/launch_flags_test.dart`
  (+1), `test/pip_avatar_test.dart` (Mochi-only pins extended to every
  style × stage).

VERDICT: PASS
