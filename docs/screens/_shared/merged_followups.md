Follow-ups on screens that are ALREADY MERGED on main (P01, P02, P08). For this task you MAY edit these feature files: app/lib/features/onboarding/**, app/lib/features/today/** and their tests.

1. ACCESSIBILITY (P08 Today): docs/screens/_shared/semantics_tap_REPORT.md lists two places in app/lib/features/today/presentation/widgets/today_loaded_body.dart:
   - ~line 429: "<parent>'s profile"
   - ~line 655: "See all quests"
   Each wraps an InkWell(onTap) around `Semantics(button, excludeSemantics: true)`, so screen readers can't activate it. Add `onTap:` (mirroring the InkWell) on the Semantics node. Tests: for each, `hasAction(SemanticsAction.tap)` and `performAction(SemanticsAction.tap)` navigates to the same route as a real tap (assert the router location with currentPath).
2. BALANCED HEADINGS (P01 Welcome, P02 Value tour): the design CSS uses `text-wrap: balance` on `.display` (P01) and on `.h1` / `pg-title` with `.balance` (P02). Render those headings with NestBalancedText (app/lib/core/design_system/components/nest_balanced_text.dart).
   - Same copy, style and maxLines; do NOT add maxLines if there is none.
   - The headline's line breaks must match the design PNGs: design/screens/light/P01-*.png and P02-*.png ÷3. Read the PNGs and write down the design's line breaks in the report.
   - Test with real fonts (FontLoader, as app/test/features/privacy_consent/privacy_consent_geometry_test.dart does) that each heading breaks exactly like the design at 390 px.
   - Do not move anything else: the existing P01/P02 geometry tests must stay green unchanged. If a heading's break already matched the design, note it and still switch to NestBalancedText (no visual change).
3. Also grep every merged screen (onboarding, auth, privacy_consent, family, paywall, today) for other `Semantics(... excludeSemantics: true)` + gesture patterns that miss onTap. Fix them the same way, with tests. The semantics report lists the paywall/family hits as static (no gesture): verify that and leave them if true.
DONE = dart format clean, flutter analyze "No issues found!", full flutter test green, docs/screens/_shared/merged_followups_REPORT.md written, committed.
