Accessibility: every interactive design-system component must expose SemanticsAction.tap (VoiceOver/TalkBack can activate it).

EVIDENCE: ../nestling-screens/P06/docs/screens/P06/4_review.md findings 2 and 3 (read-only).
Probe on P06 with the semantics handle on: `Continue` (NestButton) reports button=true, tap=false, actions=0. NestChip is the same.
CAUSE: `Semantics(label: …, excludeSemantics: true, child: InkWell/GestureDetector(onTap))`. `excludeSemantics: true` drops every descendant contribution, INCLUDING the tap action, so the node says "button" but can't be pressed. This fails WCAG 2.1 AA SC 4.1.2 and 2.1.1. Nestling is a family/children's app and must meet it.
Files named so far: app/lib/core/design_system/components/nest_button.dart (~152-180) and nest_chip.dart (~119-137).

DO:
1. Audit EVERY interactive widget in app/lib/core/** and app/lib/app/**: buttons, chips, kid buttons, nav bar, bottom CTA, text-field affordances, toggles, steppers, swatches, list rows, dock, NestChipWrap children, the parental gate keypad, and anything with onTap/onPressed/onChanged.
   - Where a Semantics node has `excludeSemantics: true` or wraps an ExcludeSemantics around the gesture, pass the callback on the Semantics node: `onTap:` (plus `onLongPress` if used, and `onIncrease`/`onDecrease` for steppers if applicable).
   - Keep the single-node announcement (label, button/selected/toggled flags) that existing tests rely on.
   - When the control is disabled (callback null), it must expose no tap action and must report `enabled: false`.
2. Add a shared test, app/test/core/design_system/semantics_actions_test.dart. For each interactive component:
   - The enabled state has `SemanticsAction.tap`.
   - `performAction(SemanticsAction.tap)` calls the callback exactly once.
   - The disabled state has no tap action and reports isEnabled false.
3. Do NOT edit feature presentation code. In the report, list every feature file (grep app/lib/features) that uses the same `Semantics(... excludeSemantics: true)` + gesture pattern, file:line each, so the screens can fix their own.
4. Add one paragraph to docs/screens/RULES.md: "Every interactive element must expose SemanticsAction.tap; tests assert hasAction(SemanticsAction.tap) and performAction drives the real behaviour."
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/semantics_tap_REPORT.md written, committed.
