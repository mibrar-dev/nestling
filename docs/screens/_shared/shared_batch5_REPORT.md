# Shared batch 5 — REPORT (branch `shared/shared_batch5`)

Scope: P09 `SHARED_REQUEST.md` §§2,4,5,6 (plus `5_ui.md` iteration 2).
All changes are minimal and backward-compatible: 4 additive icons (no
existing SVG touched), 3 component fixes via existing tokens/patterns, no
public API renames, no route changes, no `app/lib/features/**/presentation`
screen code touched. Screen branches merge and compile without edits
(P09/P14 delete their compensations as follow-ups below).

Evidence read first: P09 `SHARED_REQUEST.md` §§2,4,5,6, P09 `5_ui.md`
(iteration 2, tile MAEs + field x 41.7 vs 38.3), `docs/ARCHITECTURE.md`,
`docs/screens/RULES.md`, `docs/design/SPACING_SPEC.md`
(`.toggle` 51×31 + `::before` −4/−7, `.stepper` 44 circle, `.field`
`border 1px + padding 0 16px`), `tools/screens/stages/common.md` (owner
rules), `design/html-source/screens/P09-quest-editor.html:30-32,34,38`
(exact SVGs), `P08-today.html:37,39,41`, `P10-quest-library.html:21,23-25`,
`P04-privacy.html:25`, `P06-pocket-money.html:72,81`, `P14-rewards.html:16-20`,
`app/lib/core/design_system/components/nest_{toggle,stepper,text_field,icon}.dart`,
`app/lib/core/design_system/assets/nestling_assets.dart`.

## Files changed

- `app/assets/icons/ic_quest_bed.svg` (new) — P09 Bed flat frame, no headboard.
- `app/assets/icons/ic_quest_dishes.svg` (new) — P09 Dishes handled basket.
- `app/assets/icons/ic_quest_hoover.svg` (new) — P09 Hoover angular canister +
  hose + legs (`M7 16v3M11 16v3`).
- `app/assets/icons/ic_quest_bins.svg` (new) — P09 Bins handled case + clasp
  (`M10 12h4`).
- `app/lib/core/design_system/assets/nestling_assets.dart` — 4 additive
  `questBed/questDishes/questHoover/questBins` constants with P09 docs.
- `app/lib/core/design_system/components/nest_icon.dart` — 4 forwards.
- `app/lib/core/design_system/components/nest_toggle.dart` — 51×31 track IS the
  box; 59×44 hit slop via `_ToggleHitSlop` (same pattern as `NestChip`
  `_ExpandedHitBox`); `ConstrainedBox`+`Center` removed.
- `app/lib/core/design_system/components/nest_stepper.dart` — `'-'` U+002D →
  `'−'` U+2212 with comment.
- `app/lib/core/design_system/components/nest_text_field.dart` — default
  `contentPadding` horizontal `s4` (16) → `s3` (12); 12 + 4 px editable inset
  + 1 px border = 17 from the field edge.
- Tests: new `app/test/design_system/shared_batch5_test.dart` (20 tests);
  updated `app/test/design_system/inputs_test.dart` (toggle 51×31),
  `overflow_test.dart` (toggle 51×31), `search_field_fix_test.dart`
  (labelled 12/14), `app/test/features/privacy_consent/privacy_consent_view_test.dart`
  (2× 51×31), `app/test/features/rewards/reward_card_widget_test.dart`
  (51×31 + 175 follow-up pin), `rewards_responsive_test.dart` (2× 51×31),
  `rewards_a11y_test.dart` (2× 51×31 + label-addressed semantics),
  `p14_bugs_test.dart` (label-addressed semantics, raw-string lints).
- `app/lib/features/**/presentation/**`: untouched (per task).

## Item 1 — ICONS (§4, BLOCKER) → DONE

Was: `NestIcons.bed` (headboard arc), `.dishwasher` (appliance),
`.hoover` (rounded canister + dot wheels), `.bin` (wheelie bin) vs P09 design
(flat bed, handled basket, angular canister + legs, handled case + clasp).
Whole-tile MAEs in `5_ui.md`: bed 4.5 / dishes 17.5 / hoover 20.5 / bins 17.3.

Audit of every `NestIcons.bed/basket/dishwasher/hoover/bin` use in
`app/lib/features` + design HTML:

- `bed`: `value_tour_view.dart:327`, `gallery_screens.dart:371`,
  `kid_home_view.dart` (via `questIconAsset`), `today_loaded_body.dart:30`,
  `quest_idea_meta.dart:53,150`. Design: `P08-today.html:41` HAS headboard
  (matches current `ic_bed.svg`); `P09-quest-editor.html:30` +
  `P10-quest-library.html:21` have NO headboard. → Keep `bed` for P08, add
  `questBed` for P09/P10.
- `dishwasher`: `gallery_screens.dart:274`, `kid_home_view.dart:142`,
  `today_loaded_body.dart:23`, `quest_idea_meta.dart:71,142`. Design:
  `P08-today.html:37` + `P10-quest-library.html:24` + `P09:31` are ALL the
  handled basket (`M4 11h16…`), never the appliance. Current
  `ic_dishwasher.svg` matches NO screen — kept for compat, P09 must use
  `questDishes`.
- `hoover`: `gallery_parent_b.dart:158`, `kid_home_view.dart:146`,
  `today_loaded_body.dart:32`, `quest_idea_meta.dart:77,152`. Design:
  `P09:32` WITH legs, `P10:25` WITHOUT legs, `P08` has no hoover row. Current
  `ic_hoover.svg` (rounded + dots) matches NONE — kept, P09 uses `questHoover`
  (exact WITH-legs glyph).
- `bin`: `value_tour_view.dart:313`, `gallery_screens.dart:324`,
  `gallery_parent_a.dart:115`, `kid_home_view.dart:145`,
  `today_loaded_body.dart:28`, `quest_idea_meta.dart:65,148`. Design:
  `P08:39` + `P09:34` have case + clasp (`M10 12h4`); `P10:23` omits the
  clasp. Current `ic_bin.svg` (wheelie) matches NONE — kept, P09 uses
  `questBins` (exact WITH-clasp glyph).
- `basket` (`ic_basket.svg` slatted laundry): `value_tour_view.dart`? No —
  `gallery_screens.dart:718`, P02/P04 only. Untouched; P09 must NOT use it
  (orchestrator 17:57 look-alike ban).

Mapping P09 must use (screen code, next iteration):

- Bed → `NestIcons.questBed` (`assets/icons/ic_quest_bed.svg`)
- Dishes → `NestIcons.questDishes`
- Hoover → `NestIcons.questHoover`
- Book → `NestIcons.book` (unchanged, byte-identical)
- Bins → `NestIcons.questBins`
- Paw → `NestIcons.paw` (unchanged, byte-identical)

And revert the iter-2 `NestIcons.basket` substitution on the Dishes tile
(`quest_editor_view.dart:260-270` on the P09 branch) to `questDishes`.

Tests (all in `shared_batch5_test.dart`, `pumpBothModes` light+dark):

- `asset constants point at the new files`
- `ic_quest_{bed,dishes,hoover,bins}.svg is the design glyph, tintable`
  (contains P09 path, `currentColor`, `stroke-width="2"`, no baked hex)
- `light/dark: assets/icons/ic_quest_*.svg renders with the theme colour`
  (8 tests: `NestIcon` + `SvgPicture.colorFilter != null`, no exception)

## Item 2 — NestToggle (§2) → DONE

Was: `ConstrainedBox(min 59×44)` + `Center` centred the 51×31 track, so the
painted switch landed 4 px short + 2 px low in right-aligned rows. Now the
track IS `NestToggle`'s box (51×31); `_ToggleHitSlop` (copy of `NestChip`
`_ExpandedHitBox`) accepts 59×44 centred on it and forwards clamped hits —
padding/overflow hit test, never shifts the track.

Tests:

- `the laid-out box is the 51x31 track` (`getSize(NestToggle) == 51×31`,
  `AnimatedContainer` 51×31)
- `a tap 4 px outside the track still toggles` (left −4 → `[true]`, top −4 →
  `[true,true]`)
- `semantics expose the toggle action` (`byLabel('T')` has `tap`)

Updated shared tests: `inputs_test.dart` (`51x31 track is the laid-out box`),
`overflow_test.dart` (`atLeast 51,31` with hit-slop comment).

Merged-test updates (new == design 51×31, so updated; lib untouched):

- `privacy_consent_view_test.dart`: 2× `getSize == Size(51,31)` (was
  `>= tapParent`).
- `reward_card_widget_test.dart`: `toggleBox.size == 51×31`,
  `toggleBox.top == card.top+72.5` (was 66 — 6.5 centring now in the box),
  `track.left closeTo(175,1)` (was 179 — still carries the pre-batch
  `Transform.translate(-4,0)`; see follow-up), `track.bottom` unchanged
  (103.5, still design).
- `rewards_responsive_test.dart`: 2× `size == 51×31`.
- `rewards_a11y_test.dart`: 6 toggles `size == 51×31`; sheet `Needs my OK`
  switch excluded from the 44 px loop + separate `51×31` pin (hit proven by
  the existing 5 px-above/below live test).
- `p14_bugs_test.dart`: widget-lookup → label-lookup for semantics
  (`byLabel(RegExp('^Needs approval'))`, `byLabel('Needs my OK')`) because
  the outer hit-slop render carries no semantics (the `NestChip` pattern);
  behaviour unchanged (tap flips DB).

Screens currently compensating (DO NOT edit here — they remove after merge):

- P09 (P09 branch, not in this tree): `quest_editor_widgets.dart:49`
  `QuestEditorMetrics.toggleTrackOffset = Offset(4,-2)` applied at
  `quest_editor_view.dart:890-891`. Delete the `Transform.translate` after
  merging (track lands on 303→354 / 620.5→651.5 by layout).
- P14 (this tree): `p14_reward_card.dart:126-133`
  `Transform.translate(Offset(-s1,0))` (“tucked 4 px back”). Delete it after
  merging and restore `track.left` 179 in `reward_card_widget_test.dart`
  (currently pinned 175 with TODO).

## Item 3 — NestStepper minus (§5) → DONE

Was `label: '-'` U+002D; both `P09-quest-editor.html:38` and P06 source print
`&minus;` U+2212. Now `label: '−'` with comment. Same `NestType.bodyStrong
20 w700` style as `+`, so equal weight/family.

Test: `the decrease glyph is U+2212, never U+002D` (`data == '−'`,
`codeUnits != [0x2D]`, `runes.single == 0x2212`).

Merged impact: none fails. P06 keeps its local `P06WeeklyStepper` +
`kP06StepperMinusGlyph` (tests `p06_bugs_test.dart:870`,
`p06_weekly_stepper_widget_test.dart:34` green); its comment noting “shared
keeps U+002D” is now stale (follow-up: P06 may drop the fork).
`money_ledger_view_test.dart:352` (no ASCII hyphen) still green — one fewer
`-` in the tree.

## Item 4 — NestTextField default (§6) → DONE

Was `contentPadding: horizontal s4 (16)` + ~4 px editable inset = 20 from the
box edge vs design 17 (field x + 1 border + 16 padding). Now horizontal `s3`
(12): 12 + 4 + 1 = 17. Vertical 14 unchanged. Search variant untouched
(already `left: -4`).

Tests:

- `default contentPadding cancels the 4 px editable inset` (constructor flag)
- `decoration carries 12 px horizontal, 14 px vertical`
- `typed text starts 17 px from the field edge` (390-wide `Align`, bundled
  Inter, `enterText 'Hoover'`, `typed.left - field.left ≈ 17 ±1.5`)

Re-checked merged geometry tests (design PNGs ÷3):

- P03 email/password (`create_account_view_test.dart`, `p03_bugs_test.dart`,
  `typography_test.dart`): field outer rects only (20/156/350/52 gutters,
  eye at right 2); no test pins text-x. All green — no update.
- P05 nickname (`add_children_test.dart:2153-2154`, `p05_view_metrics_test`):
  label/input/age/chip rects only; no inset pin. Green — no update.
- P10 search (`quest_library_design_geometry_test.dart`,
  `p10_bugs_test.dart:193-201`, `shared_batch4_test.dart`,
  `search_field_fix_test.dart`): search variant (54 high, icon x+16, hint
  x+50) already fixed, untouched. Green — no update.
- Only pin of the old inset was shared `search_field_fix_test.dart`
  (`labelled variant is unaffected` expecting 16/14) → updated to 12/14 (new
  == design, per task).

## Gates

- `cd app && dart format .` → clean (0 changed on re-run).
- `flutter analyze` → `No issues found!` (no new ignores).
- `flutter test` → `All tests passed!` (2417 passed, 1 skipped, 0 failed;
  includes 20 new `shared_batch5_test.dart`).

## Follow-ups for screens

- P09 (next iteration): use `questBed/questDishes/questHoover/questBins`
  (revert `basket` on Dishes); delete `toggleTrackOffset` `Transform.translate`;
  re-take stage-5 shots (expect tile MAEs → raster residue, field text x 37).
- P14: delete `Transform.translate(-4,0)` in `p14_reward_card.dart:126-133`;
  restore `track.left` 179 in `reward_card_widget_test.dart` (currently 175
  TODO); optionally drop `visibleTrackRect` indirection (now == toggle rect).
- P06: shared `NestStepper` now draws U+2212 — may drop `P06WeeklyStepper`
  fork + update its stale “keeps U+002D” comment.
- P08/P10/K03: `questIconAsset`/`kQuestIdeaMeta` still return legacy
  `bed/dishwasher/hoover/bin` (wheelie/appliance/rounded) while their designs
  (`P08-today.html`, `P10-quest-library.html`) show the quest glyphs —
  switch those maps to `questBed/questDishes/questHoover/questBins` (P10 bins
  clasp + hoover legs deltas are ≤ raster; keep P09 exact).
- P04/P16/P13/P17 (other `NestToggle` users): no code change needed — tracks
  now sit 4 px closer to the content edge by design; remove any local
  centring hacks if spotted (none found besides P09/P14).

VERDICT: PASS
