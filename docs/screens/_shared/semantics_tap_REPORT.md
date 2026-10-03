# Shared semantics_tap report

## Files changed

Shared components (`app/lib/core/design_system/components/`), one-line
`onTap:` mirror on the labelling `Semantics` node each (plus `enabled:`
where the callback is nullable and was missing):

- `nest_button.dart` — `Semantics` gains `onTap: disabled ? null : tap`.
- `nest_kid_button.dart` — gains `onTap: enabled ? widget.onPressed : null`.
- `nest_brand_buttons.dart` (`_BrandButton`) — gains
  `onTap: disabled ? null : onPressed`.
- `nest_chip.dart` — interactive branch gains `enabled: true` +
  `onTap: () => callback(!selected)`.
- `nest_toggle.dart` — gains `onTap: changed == null ? null :
  () => changed(!value)`.
- `nest_stepper.dart` (`_StepBtn`) — gains `onTap: tapped`.
- `nest_segmented.dart` — option `Semantics` gains `enabled:
  changed != null` + `onTap`.
- `nest_tab_bar.dart` (`_Tab`) — gains `onTap: onTap`.
- `nest_list_row.dart` — tappable branch gains `enabled: true` + `onTap`.
- `nest_quest_card.dart` — `NestQuestCard`/`NestKidQuestCard` gain
  `enabled: true` + `onTap`; `_ParentCheck`/`_QuestCheck` gain `enabled:
  toggled != null` + `onTap`.
- `nest_keypad.dart` (`_Key`) — gains `onTap: onTap`.
- `nest_day_picker.dart` (`_DayCell`) — gains `onTap: onTap`.
- `nest_card.dart` — tappable branch gains `enabled: true` + `onTap: tap`.
- `nest_icon_button.dart` — gains `onTap: onPressed`.
- `nest_fab.dart` — gains `onTap: onPressed`.
- `nest_lock_button.dart` — gains `onTap: onPressed`.
- `nest_nav_bar.dart` — `_NavBackButton` gains `onTap: onBack`;
  `_NavActionButton` gains `enabled: onTap != null` + `onTap`.
- `nest_bottom_sheet.dart` (`_CloseButton`) — gains `onTap: onClose`.
- `nest_pager_dots.dart` — dot `Semantics` gains `enabled:
  tapHandler != null` + `onTap`.

Docs:

- `docs/screens/RULES.md` — new §8 accessibility-actions paragraph.
- `app/test/core/design_system/semantics_actions_test.dart` — new (see below).

## What / why

`Semantics(label, excludeSemantics: true)` drops every descendant
contribution, including the `InkWell`/`GestureDetector` tap action, so the
node announced "button" with `hasAction(tap) == false` (P06 probe:
`Continue` button=true tap=false actions=0; same for `NestChip`). This fails
WCAG 2.1 AA SC 4.1.2 and 2.1.1. The fix passes the same callback on the
`Semantics` node (`onTap:`), keeping the single-node announcement (label,
button/selected/toggled) that existing display tests pin. Disabled (callback
null) passes `onTap: null` and reports `enabled: false`, hence no tap action.
No `onLongPress`/`onIncrease`/`onDecrease` exists in core, so `onTap`
covers every control; steppers are two separate buttons. `PipAvatar`/`PipRive`
carry a bare `GestureDetector` with no `Semantics` wrapper, so their tap was
never dropped — untouched. Display-only `excludeSemantics` nodes (coin pill,
progress, badge, money, pager-dot container, card without `onTap`) have no
gesture and are untouched.

## Test names added (`semantics_actions_test.dart`, 40 tests)

NestButton enabled/disabled; NestKidButton enabled/disabled; brand buttons
Apple/Google enabled/disabled; NestChip enabled/static/in-NestChipWrap;
NestToggle enabled/disabled; NestStepper enabled/disabled; NestSegmented
enabled/disabled; NestTabBar tabs; NestListRow tappable/static; NestQuestCard
card/parent-check-enabled/parent-check-disabled; NestKidQuestCard
card/check-enabled/check-disabled; NestKeypad digit+delete; NestDayPicker
cells; NestCard tappable/static; NestIconButton enabled/disabled; NestFab;
NestLockButton; NestNavBar back/action-enabled/action-disabled;
NestBottomSheet close; NestPagerDots with/without handler; NestTextField eye
affordance (tooltip `Show password` → `Hide password`). Each enabled test
asserts `hasAction(SemanticsAction.tap)` and that `tester.semantics
.performAction(..., SemanticsAction.tap)` fires the callback exactly once;
each disabled test asserts no tap action and `isEnabled false` (static
non-button controls assert no tap action).

Results: `dart format` clean, `flutter analyze` → No issues found!,
`flutter test` → all 1382 tests pass (40 new).

## Follow-up screens must do

Do NOT edit shared code; fix these own-branch occurrences of the same
`Semantics(... excludeSemantics: true)` + gesture pattern (main branch
`file:line`):

- `app/lib/features/today/presentation/widgets/today_loaded_body.dart:429`
  (`"$parentName's profile"` — `InkWell(onTap: go settings)` ancestor over
  `Semantics(button, excludeSemantics: true)`): add `onTap:` on the
  `Semantics` mirroring the `InkWell`.
- `app/lib/features/today/presentation/widgets/today_loaded_body.dart:655`
  (`See all quests` — same ancestor pattern): same fix.
- P06 branch only (per `../P06/docs/screens/P06/4_review.md` findings 2–3,
  not present on main):
  `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart:313-319`
  (`_PocketOptionCard`) and `:556-567` (`_DayCell`): add `onTap:` on each
  `Semantics(button, selected, excludeSemantics: true)`.

No action needed (static, no gesture) but same grep hit, listed to avoid
confusion: `paywall_view.dart:475` (`_BenefitRow`), `:525` (`_PlanCard`),
`family/.../add_child_form_card.dart:75,107` (Age-band / Avatar-colour
headings).

VERDICT: PASS
