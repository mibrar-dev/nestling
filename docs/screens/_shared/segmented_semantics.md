One-line accessibility fix: NestSegmented announces every option label twice.

app/lib/core/design_system/components/nest_segmented.dart ~53-58: each option is wrapped in `Semantics(button: true, selected:, label: option.label, onTap: …)` WITHOUT `excludeSemantics: true`. The inner Text and the InkWell keep their own semantics, so a screen reader reads "Ideas" twice.
FIX: add `excludeSemantics: true` to that per-option Semantics. Keep `onTap:` (added by shared_batch4) so the node keeps its tap action, exactly like nest_chip.dart ~119-121 ("one node per chip").
TEST (add to app/test/core/design_system/semantics_actions_test.dart or a segmented test), for a 2-option NestSegmented:
- `find.bySemanticsLabel('Ideas')` finds exactly one node;
- it has SemanticsAction.tap and isSelected matches;
- performAction(tap) selects it.
Proof cases on screen/P10 (read-only reference): ../nestling-screens/P10/app/test/features/quests/quest_library_a11y_test.dart.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/segmented_semantics_REPORT.md, committed.
