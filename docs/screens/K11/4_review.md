# K11 · Badges — stage 4 QA code review (iteration 3)

Scope: `git diff main...HEAD` for feature `badges` (route `/badges`, kid mode) against
docs/ARCHITECTURE.md, docs/screens/RULES.md, docs/DESIGN_SPEC.md §5 K11,
docs/design/SPACING_SPEC.md (§§7–8/10–11), docs/screens/K11/1_plan.md, and the
orchestrator rules (including `docs/screens/K11/ORCHESTRATOR_NOTES.md`, mandatory).
No code edited in this stage. Iteration-3 delta since the iteration-2 PASS is narrow:
`badge_grid_cell.dart` locked-medal rework + 8 new `badges_view_test.dart` pins
(`c81a3c5`); everything else is the already-reviewed iteration-2 tree.

Files reviewed: `app/lib/features/badges/data/badges_repository_impl.dart`,
`domain/badges_repository.dart`, `domain/entities/badges_data.dart`,
`presentation/bloc/badges_{bloc,event,state}.dart`,
`presentation/views/badges_view.dart`,
`presentation/widgets/{badge_grid_cell,happy_week_card}.dart`,
`badges_{di,routes}.dart`, `app/test/features/badges/*.dart`,
`docs/screens/K11/{1_plan,2b_build_ui,3_test,5_ui,6_bugs}.md`,
`SHARED_REQUEST.md`, `ORCHESTRATOR_NOTES.md`,
`design/html-source/screens/K11-badges.html`, both design PNGs (read-only PIL sample).

## Compliance (all pass)

- **RULES §1 paths:** committed diff touches only `app/lib/features/badges/**`,
  `app/test/features/badges/**`, `docs/screens/K11/**` (+ UI PNGs). No `core/`,
  `app/`, other-feature, or `tools/` edits. `git diff --check` clean.
  Working-tree uncommitted files (`badges_locked_art_test.dart`, `app_light_3.png`,
  `badges_a11y/bloc_test.dart` mods, `.brief_*`) are process items per the
  orchestrator PROCESS ITEMS rule — not findings.
- **Architecture:** one bloc per feature (`BadgesLoadRequested` + initial/loading/
  loaded/failure); internal `BadgesDataReceived`/`BadgesStreamFailed` are
  bloc-private (views never send them; routes only send `BadgesLoadRequested`).
  Domain = entities (`badge.dart`, `badges_data.dart` Equatable) + abstract repo
  only; no use-cases, no extra folders. DI lazy-singleton repo + factory bloc;
  route-level `BlocProvider(create: (_) => sl<>()..add(...))` — matches the contract.
  `badges_placeholder_card.dart` deletion is the expected foundation-placeholder
  removal. `badge.dart`/`badge_model.dart` `const new` is foundation code, untouched
  by this branch.
- **ORCHESTRATOR_NOTES (mandatory, all done):** no `seed.dart` edit; all nine design
  ids render their own medal (4 earned via shared coloured assets, 5 todo via local
  `lockedMedalSvg`); `TODO(K11)` gone and no `'maya'` literal remains (grep clean);
  K11-BUG-1 clamp and K11-BUG-2 first-child-in-creation-order resolution intact.
  06:55 items: (1) dashed ring is ink `#1E1B3A`, 3 px, `dasharray 5 4` — code
  `badge_grid_cell.dart:78` matches; sampled `(30,27,58)` at ring top on BOTH design
  PNGs, confirming the HTML duplicate-`stroke` first-wins reading. (2) ribbon keeps
  `opacity=".4"` on the whole `<path>` (fill `#6E6A8A` + 3 px ink stroke together) —
  code matches; sampled `(165,164,176)`/`(197,195,208)` light and `(31,28,51)`/
  `(63,59,83)` dark, exactly ink/grey-at-40 % over each tile. (3) fixed illustration
  colours in both themes match both PNGs (disc `(243,238,229)` = `#F3EEE5` both
  themes); the note's "(dark shows a light ring)" parenthetical is not what the PNGs
  contain — measured dark ring is `(30,27,58)` ink. Zoomed-crop proof in `5_ui.md`
  belongs to the next stage-5 run (iteration-3 pixels supplied, unit-pinned here).
- **Design system / tokens:** everything chrome via `context.nest` / `nestKid` /
  `NestSpacing` / `NestDevice` / `NestRadii` / `NestType`. File-local consts (back
  chevron 26, medal 60, dot 38, 15/19 + 14/18 type, 10/4 + 14/12 padding, 4/12 gaps)
  each cite the HTML line and match SPACING_SPEC screen-local geometry. Hex appears
  ONLY inside the locked-medal SVG strings — illustration art, explicitly allowed by
  DESIGN_SPEC §0.7 and the same category as the shared `badge_*` files' hexes (all
  chrome still uses tokens). `Colors.transparent` is transparency, not palette.
  Grid uses `Expanded` slots (never fixed 108.67); dots use `LayoutBuilder
  min(38,(w-24)/7)`. `KidScope` shared sky+meadow, transparent Scaffold, explicit
  34 px home reserve painting nothing — BOTTOM EDGE holds. `NestBalancedText` on
  `.kid-title` only. No chips/Pip/avatars/£ (PIP N/A; jar-only £ holds); `Row`s are
  layout rows, not chip rows. Glyph path merging (single `<path>` with relative
  `m` moves) is pixel-equivalent to the HTML's split paths — verified against both
  the HTML coordinates and the shipped `badge_bins_out.svg` merged form.
- **Copy (char-exact vs HTML):** `My badges`; repo-owned `Got it!` / `Keep going!`
  (view never remaps); `×` U+00D7 from DB title; why-line em dash U+2014 + curly ’
  U+2019 in source; `M T W T F S S`; `Back` / `Grown-ups`; DB-driven subtitle/why
  with flagged zero-state kid voice per plan §c–d. UK spelling clean. Tiles stay
  static (no detail route in nav map — no invented onTap/toast/sheet, plan §c).
- **Accessibility:** back/lock expose tap via design-system buttons (stage-3 tests
  prove `hasAction(tap)` + `performAction(tap)` drives real navigation with the
  double-tap single-push guard). Static tiles carry one merged label with
  `excludeSemantics: true` and no tap action — correct, they are not controls
  (RULES §8 `onTap` applies to wrapped controls). Both `SvgPicture.string` and
  `SvgPicture.asset` sit under `ExcludeSemantics`. Spinner labelled `Loading
  badges`. 56 px targets, 1.0–1.3 clamp, 2-line ellipsis.
- **Performance/errors/Children's Code:** `BlocBuilder` scoped to body; const chrome;
  no timers/controllers; `_sub` cancelled on `close()` and released on error so `Try
  again` works; `_switchMap` `onCancel` cancels inner+outer; loading/failure/empty
  keep chrome mounted with generic kid-safe copy (raw `errorMessage` stored but never
  rendered). `lockedMedalSvg` builds 5 tiny strings per emission — trivial, no rebuild
  storm. No analytics/ads/location/photos; positive framing, no loss-aversion. No
  `DateTime.now` / `clock` / `newId` / `google_fonts` / `Color(0x` / `letterSpacing` /
  `PipAvatar` in lib (test files mention the rule in comments only). No `flutter
  clean`, no simulator, no global kills.

## Findings

1. (minor) `app/lib/features/badges/data/badges_repository_impl.dart:129` —
   `_switchMap` drops the previous inner subscription with
   `unawaited(innerSub?.cancel())`, so old and new inners overlap briefly and a
   racing old emission could forward once. Carried from iteration-1/2; stage-6
   probes (10 switch+write bursts) proved no stale child emission lands, and the
   logic builder deliberately kept it identical to the K08 shared pattern per the
   finding's own "if ever touched" guidance. Hardening only. Fix (if ever touched):
   await the cancel before subscribing, or gate emissions with a generation counter.

No blocker or major findings. Iteration-3 delta (ink ring + whole-element ribbon
opacity + per-id glyphs + 8 pins) is correct and fully covered.

## Verification evidence

- `flutter analyze app/lib/features/badges app/test/features/badges` → No issues found.
- Grep: no `Color(0x`, no `GoogleFonts`, no `DateTime.now`, no `'maya'` literal,
  no `TODO`, no `letterSpacing`, no `PipAvatar` in lib; `git diff --check` clean.
- PIL spot-check (read-only, no simulator): ring-top `(30,27,58)` both PNGs; disc
  `(243,238,229)` both PNGs; ribbon `(165,164,176)`/`(197,195,208)` light and
  `(31,28,51)`/`(63,59,83)` dark — all exactly what `lockedMedalSvg` draws.
- Stage-2b reports 42/42 view tests (34 + 8 new) and 71/71 neighbours green; this
  stage re-read the code rather than re-running the suite (no code edits, no simulator).

VERDICT: PASS
