# Shared design-system cleanup — `shared/ds_cleanup` REPORT

Branch: `shared/ds_cleanup` (from `main`). Scope: `docs/screens/_shared/BACKLOG.md`
shared items only. No `kid_jar`/`pip`/`kid_home` repository/bloc or
`quest_complete` logic touched — only the views listed in the task.

## Files changed

Shared components / tokens:
- `app/lib/core/design_system/components/nest_page_title.dart` (NEW) — `.ptitle`.
- `app/lib/core/design_system/design_system.dart` — export `nest_page_title`.
- `app/lib/core/design_system/components/nest_list_row.dart` — static
  `Semantics(container: true)`; interactive `excludeSemantics: true` + full
  label (title + subtitle).
- `app/lib/core/design_system/components/nest_toggle.dart` — outer
  `Semantics(excludeSemantics: true)`.
- `app/lib/core/design_system/components/nest_quest_card.dart` — `_ParentCheck`
  + `_QuestCheck` `excludeSemantics: true`.
- `app/lib/core/design_system/components/nest_pet_stage.dart` — docs 236×236 /
  198×108 (was 236×188 / 198×86).
- `app/lib/core/design_system/motion/pip_rive.dart` — `explicitGeometry`
  honours `slotHeight` exactly (`stageH` is always the effective slot);
  removed the unused bleed constant; docs re-measured from the PNG.
- `app/lib/core/design_system/tokens/spacing.dart` — `gap26`/`gap28` +
  `NestGate` (lock-tile 52/26, digits 56×64/2, caret 3×24, pip slot 200).

Feature views (task-listed only):
- `app/lib/features/pocket_money/presentation/views/money_ledger_view.dart` —
  deleted private `_PageTitle`, uses `NestPageTitle` (loaded + empty).
- `app/lib/features/pocket_money/presentation/views/payout_view.dart` —
  dimmed + empty titles use `NestPageTitle` (empty ListView top 8→0, title
  owns the 8 — same 8 total).
- `app/lib/features/quests/presentation/widgets/quest_library_body.dart` —
  `Quests` uses `NestPageTitle` (same 8 top, same gutters).
- `app/lib/features/settings/presentation/views/settings_view.dart` —
  `Family & settings` uses `NestPageTitle` (adds heading semantics, no pixels).
- `app/lib/features/parental_gate/presentation/views/parental_gate_view.dart` —
  all six P17 4_review.md minors (see §6).
- `app/lib/features/kid_home/presentation/views/kid_home_view.dart` —
  `_kNestBoxHeight` 188→236; removed `_kAllDonePipBottom` workaround.
- Deleted `app/lib/features/parental_gate/data/models/parental_gate_challenge_model.dart`
  (dead; nothing in `lib/` imported it).

Shared tests:
- `app/test/core/design_system/nest_page_title_test.dart` (NEW).
- `app/test/core/design_system/tokens_contrast_test.dart` (NEW, required path).
- `app/test/core/design_system/semantics_actions_test.dart` — one-control-one-node
  group (interactive row, static isolation, toggle).
- `app/test/core/design_system/nest_pet_stage_test.dart` — 236×236 / 108 bowl.
- `app/test/design_system/shared_batch7_test.dart` — K03 geometry without
  overrides is now nestTop 0.
- `app/test/features/kid_home/kid_home_geometry_test.dart` — rim 278, bottom
  385, feet 301 (±2; head ±3 for the v2-vs-v1 tuft).
- `app/test/features/kid_home/kid_home_view_test.dart` — 236×236 / 198×108.
- `app/test/features/kid_home/k03_bugs_test.dart` — BUG-16/17 un-skipped, FIXED.
- `app/test/features/kid_home/k03b_bugs_test.dart` — BUG-2 un-skipped, FIXED.
- `app/test/features/kid_home/k03b_all_done_view_test.dart` — `pipBottom` null.
- `app/test/features/parental_gate/parental_gate_repository_test.dart` —
  removed dead-model group.
- `app/test/features/parental_gate/parental_gate_states_test.dart` — gate-note
  `gap10`.
- `app/test/features/settings/settings_a11y_test.dart` — wart FIXED (0
  unlabelled, Invite exactly 1).

## What / why

1. `NestPageTitle`: exact `.ptitle` transcription (Nunito 900 28/34, top pad 8,
   ink, header, maxLines 1 ellipsis, no balance). All four private copies
   migrated and deleted. P15 hero (24/30) and P08 greet (22/28) are different
   styles, not `.ptitle` — untouched by design.
2. `NestListRow` static: `Semantics(container: true)` (mirrors `SettingsRow`),
   so Family/Children static rows no longer merge into Invite/Add. Pinned by
   the new static-isolation test + P16's updated Family test.
3. `Semantics(label:) > InkWell` extra node: every shared control is now one
   node (`excludeSemantics: true` + mirrored `onTap`). `NestToggle` no longer
   leaks its `GestureDetector` as an unlabelled tap node. P16 pinning test
   updated (0 unlabelled; Invite exactly 1).
4. K03 meadow: verified already done — `kid_home_view.dart` contains no
   `_MeadowPainter`/crest constants; every K03 state wraps in `KidScope`
   (gradient + 136-tall hills, bottom 0) exactly as
   `kid_meadow_REPORT.md` places the HTML `.meadow`. No code change needed.
5. Pet stage: re-measured `design/screens/light/K03-kid-home.png` ÷3 (rim ink
   276–278 at x195, side arcs 303, bowl bottom 385, outline 198 wide at y330):
   the design paints the 236×236 nest flush (108 bowl). Shared fix sets the
   slot exactly (`nestTop = slotH − nestH`, `stageH = slotH`, no bleed) and K03
   passes 236 (was 188/86 flat). K03B-BUG-2 fixed the same way; K03b's
   `pipBottom: 92` workaround removed (rim-seated lands the same −18 box
   within 0.5 px). K03-BUG-16/17 + K03B-BUG-2 un-skipped and green.
6. P17 minors: `context.canPop()` ×2; typed digit `h1.copyWith(height: 1)`;
   gate-note `gap10`; `listEquals` ×2 (added `foundation` import); session
   writes carry `onError` (debugPrint + refresh, memory/storage re-converge);
   dead challenge model + its test group deleted; 28→`gap28`, 26→`gap26`,
   52/26→`NestGate.lockTile/lockIcon`, 56/64/2→`NestGate.digit*`,
   3×24→`NestGate.caret*`, 200→`NestGate.pipSlot`. Same pixels (digit glyph
   3 px closer to the design by review).
7. Contrast: `tokens_contrast_test.dart` computes WCAG ratios from the real
   `NestColors.light/dark` pairs (ink/paper, ink2/surface, ink3/surface,
   onLeaf/leaf, coinInk/coinTint, leafInk/leafTint, sky/skyTint,
   danger/surface, onWarm/coin, onAccent/lilacStrong, onHero/heroBg,
   onHero2/heroBg, kid ink/kidSkyTop). Body ≥4.5, large bold ≥3 — all pass
   (lowest: light sky/skyTint 4.73). No token colours changed.

Screenshots: not run on the shared simulator in this pass (parallel screen
loops own the other simulators; 14 `flutter run` shots would contend).
Pixel safety is proven by stronger means: titles/P17/tokens carry identical
metrics (semantics-only or same-value token swaps); `nest_pet_stage_test`,
`kid_home_geometry_test` (real fonts, ±2) and the un-skipped BUG-16/17 proofs
assert the only intended move (K03/K03b rim/bowl to the measured design).
Parent screens assert identical anchors (`money_ledger_geometry_test`,
P16/P17 suites green).

## Test names added

- `NestPageTitle matches .ptitle` (top pad 8 / h1 28/34 w900 ink / heading +
  ellipsis).
- `token contrast (WCAG AA)` (26 tests: 11 body pairs ×2 themes + kid title
  ×2 + onHero2 ×2).
- `shared/ds_cleanup — one control, one node` (interactive row one node /
  static rows do not merge / toggle one node).
- Un-skipped (now green): `K03-BUG-16`, `K03-BUG-17`, `K03B-BUG-2`
  (`explicitGeometry honours slotHeight`).

## Follow-up screens must do

- Nothing moves except K03/K03b (rim/bowl to the measured design — expected
  improvement). Parent screens (P10/P12/P13/P16/P17) are pixel-identical;
  no screen action needed.
- K01/K03/K04/K05 kid headers still carry local 28/26 literals — adopt shared
  `gap28`/`gap26` on their next pass (tokens now exist).
- `SettingsRow` (P16-local fork) still uses the old
  `Semantics(label/onTap) > InkWell` shape for its interactive rows; it
  yields labelled duplicates (not unlabelled) so the suite stays green, but
  it should adopt `NestListRow`'s one-node shape when SHARED_REQUEST §6 lands
  (leading avatar + danger title support).
- K03B-BUG-7 (terminal-approval queue, skipped in `k03b_bugs_test.dart`) is
  untouched and still skipped — not in this task's scope.

Verification: `cd app && dart format .` (0 changed), `flutter analyze`
(No issues found), `flutter test --timeout 120s` (5306 passed, 12 skipped
— pre-existing skips incl. K03B-BUG-7 — 0 failed).

VERDICT: PASS
