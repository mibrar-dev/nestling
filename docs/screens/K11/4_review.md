# K11 · Badges — stage 4 QA code review (iteration 4)

Scope: `git diff main...HEAD` for feature `badges` (route `/badges`, kid mode) against
docs/ARCHITECTURE.md, docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K11,
docs/design/SPACING_SPEC.md (§§7–8/10–11), docs/screens/K11/1_plan.md, and the
orchestrator rules (including `docs/screens/K11/ORCHESTRATOR_NOTES.md`, mandatory).
No code edited in this stage. Iteration-4 delta since the iteration-3 PASS is narrow:
`badge_grid_cell.dart` ribbon group-opacity (07:33) + `badges_view_test.dart` 42 → 44
(group-form string pin + 2 raster guards) + `k11_bugs_test.dart` K11-ART stroke guard
updated to group math; everything else is the already-reviewed iteration-2/3 tree.

Files reviewed: `app/lib/features/badges/data/badges_repository_impl.dart`,
`domain/badges_repository.dart`, `domain/entities/badges_data.dart`,
`presentation/bloc/badges_{bloc,event,state}.dart`,
`presentation/views/badges_view.dart`,
`presentation/widgets/{badge_grid_cell,happy_week_card}.dart`,
`badges_{di,routes}.dart`, `app/test/features/badges/*.dart`,
`docs/screens/K11/{1_plan,2_build,2b_build_ui,3_test,5_ui,6_bugs}.md`,
`SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`,
`design/html-source/screens/K11-badges.html`, both design PNGs (read-only sample).

## Compliance (all pass)

- **RULES §1 paths:** diff touches only `app/lib/features/badges/**`,
  `app/test/features/badges/**`, `docs/screens/K11/**` (+ UI PNGs). No `core/`,
  `app/`, other-feature, or `tools/` edits. `git diff --check` clean.
- **Architecture:** one bloc per feature (`BadgesLoadRequested` + initial/loading/
  loaded/failure); internal `BadgesDataReceived`/`BadgesStreamFailed` are
  bloc-private (routes only send `BadgesLoadRequested` via
  `BlocProvider(create: (_) => sl<>()..add(...))`). Domain = entities
  (`badge.dart`, `badges_data.dart` Equatable) + abstract repo only; no use-cases,
  no extra folders. DI lazy-singleton repo + factory bloc. Placeholder-card
  deletion is the expected foundation-placeholder removal.
- **ORCHESTRATOR_NOTES (mandatory, all done):** no `seed.dart` edit; all nine design
  ids render their own medal (4 earned via shared coloured assets, 5 todo via local
  `lockedMedalSvg`); `TODO(K11)` gone and no `'maya'` literal in lib (grep clean);
  K11-BUG-1 clamp and K11-BUG-2 first-child-in-creation-order resolution intact.
  06:55 items: dashed ring is ink `#1E1B3A`, 3 px, `dasharray 5 4`; ribbon fill
  `#6E6A8A` + 3 px ink stroke at 40 %. 07:33 (iteration 4): opacity sits on a
  wrapping `<g>`, NO opacity on the `<path>` (`badge_grid_cell.dart:81-82`) —
  exactly the mandated form. Group math verified by hand: ink-at-40 % over white
  = 0.4·(30,27,58)+0.6·(255,255,255) = (165,164,176) light (the note's ±3 target);
  per-paint math gives (130,128,148) — the dark band the fix removes. The
  `k11_bugs_test.dart` guard update (expectation base `fillComposite` →
  `tokens.surface`) is the correct group-compositing expectation: inside one group
  layer the opaque stroke hides the fill, so the stroke centre is ink-at-40 % over
  the tile surface.
- **Design system / tokens:** all chrome via `context.nest` / `nestKid` /
  `NestSpacing` / `NestDevice` / `NestRadii` / `NestType`. File-local consts (back
  chevron 26, medal 60, dot 38, 15/19 + 14/18 type, 10/4 + 14/12 padding, 4/12 gaps)
  each cite the HTML line and match SPACING_SPEC screen-local geometry. Hex appears
  ONLY inside the locked-medal SVG strings (illustration art, DESIGN_SPEC §0.7,
  same category as the shared `badge_*` files) and inside test-only expected-value
  constants (`_ribbonInk`, `_ink`, `_disc` — raster assertions, not chrome).
  `Colors.transparent` is transparency, not palette. Grid uses `Expanded` slots
  (never fixed 108.67); dots use `LayoutBuilder min(38,(w−24)/7)`. `KidScope`
  shared sky+meadow, transparent Scaffold, explicit 34 px home reserve painting
  nothing — BOTTOM EDGE holds. `NestBalancedText` on `.kid-title` only. No chips
  (layout `Row`s only), no Pip on this screen (PIP N/A), no £/coins (jar-only holds).
- **Copy (char-exact vs HTML, verified by byte read):** `My badges`; repo-owned
  `Got it!` / `Keep going!` (view never remaps); `×` U+00D7 from the DB title;
  why-line em dash U+2014 + curly ’ U+2019 present in source; `M T W T F S S`;
  `Back` / `Grown-ups`; DB-driven subtitle/why with flagged zero-state kid voice
  per plan §c–d. UK spelling clean. Tiles stay static (no detail route in nav map).
- **Accessibility:** back/lock expose tap via design-system buttons with real
  navigation (double-tap single-push guard on the lock). Static tiles carry one
  merged label with `excludeSemantics: true` and no tap action — correct, they are
  not controls (the `onTap`-on-wrapper rule applies to wrapped controls only).
  Both `SvgPicture.string` and `SvgPicture.asset` sit under `ExcludeSemantics`.
  Spinner labelled `Loading badges`. 56 px targets, 1.0–1.3 clamp, 2-line ellipsis,
  320 px layout via slot-derived columns and shrinking dots.
- **Performance/errors/Children's Code:** `BlocBuilder` scoped to body; const chrome;
  no timers/controllers; `_sub` cancelled on `close()` and released on error so `Try
  again` works; `_switchMap` `onCancel` cancels inner+outer; loading/failure/empty
  keep chrome mounted with generic kid-safe copy (raw `errorMessage` stored but never
  rendered). `lockedMedalSvg` builds 5 tiny strings per emission — trivial. No
  analytics/ads/location/photos; positive framing, no loss-aversion, no red. No
  `DateTime.now` / `clock` / `newId` / `google_fonts` / `Color(0x` / `letterSpacing` /
  `PipAvatar` in lib (`badge_model.dart` `DateTime.parse` is stored-value parsing,
  not a wall-clock read). No `flutter clean`, no simulator, no global kills.

## Findings

1. (minor) `app/lib/features/badges/data/badges_repository_impl.dart:129` —
   `_switchMap` drops the previous inner subscription with
   `unawaited(innerSub?.cancel())`, so old and new inners overlap briefly and a
   racing old emission could forward once. Carried from iterations 1–3; stage-6
   probes (switch+write bursts) proved no stale child emission lands, and the
   builder deliberately kept it identical to the K08 shared pattern per this
   finding's own "if ever touched" guidance. Hardening only. Fix (if ever touched):
   await the cancel before subscribing, or gate emissions with a generation counter.

2. (minor) `app/test/features/badges/badges_locked_art_test.dart:5-8` — header
   comment still says the ribbon `opacity=".4"` sits on the WHOLE `<path>`; since
   the iteration-4 group fix it sits on the wrapping `<g>` with no opacity on the
   path. Test pins (`contains('opacity=".4"')`) still pass, so behaviour is
   unaffected — comment only. Fix: reword to the `<g opacity=".4"><path …/></g>`
   group-layer form, matching `badge_grid_cell.dart:70-78` and 2b's updated pins.

No blocker or major findings. Iteration-4 delta (group ribbon + corrected guards +
pins) implements the mandatory 07:33 note exactly and stays green.

## Verification evidence

- `flutter analyze lib/features/badges test/features/badges` → No issues found.
- `dart format lib/features/badges test/features/badges` → 0 changed.
- Grep: no `GoogleFonts` (comment mentions only), no `DateTime.now`, no `'maya'`
  literal, no `TODO`, no `Color(0x`, no `letterSpacing`, no `PipAvatar` in lib;
  `git diff --check main...HEAD` clean.
- Byte-level copy check: em dash U+2014 in subtitle + why-line, curly ’ U+2019 in
  why-line, `×` asserted from the DB title in tests.
- 2_build reports feature suite 170 passed + full suite 5212 passed on the merged
  tree (post-guard-fix); this stage re-read the code rather than re-running the
  suite (no code edits, no simulator).

VERDICT: PASS
