ROLE: Spacing & sizing auditor (sub-agent). Working dir = Nestling repo root. The product owner's hard requirement: Flutter spacing must match the approved screenshots exactly — no cramped chips, no overflowing/ellipsized labels, no "roughly right" paddings.

Contract: docs/design/SPACING_SPEC.md (logical px, from the CSS). Visual truth: design/screens/light/*.png (1170×2532 = 390×844 @3x → divide pixel distances by 3).
Code under audit: app/lib/core/design_system/** (tokens, theme, components) and app/lib/features/design_system_gallery/**.

TASKS
1. Build `docs/design/SPACING_AUDIT.md`: one row per component property in SPACING_SPEC.md → spec value | value found in Dart (file:line) | PASS/FAIL. Cover height, padding (t r b l), gap, radius, border, shadow, font size/weight/line-height/letter-spacing, icon size, min tap target, and state styles. Also verify theme-level values (ColorScheme/component themes) don't override component values.
2. Measure 6 reference screens from the PNGs (P08-today, P11-approvals, P12-money, K03-kid-home, K06-pip, K08-shop): for each, list the key vertical rhythm (status bar → header → first card, card gaps, section label spacing, bottom CTA/tab bar heights) in logical px, and check the design-system tokens can reproduce them (e.g. there is a spacing token for every gap used). Add missing tokens rather than magic numbers.
3. Fix every FAIL directly in the design-system code (smallest change; keep public APIs; tokens not literals).
4. Overflow hardening: write widget tests `test/design_system/overflow_test.dart` that pump EVERY component (and the P08/K03 preview compositions) at widths 320, 360, 390, 430 and textScaler 1.0 and 1.3, in light and dark, and assert no RenderFlex overflow (FlutterError), no ellipsized button labels (find text painters with didExceedMaxLines on buttons/chips = fail), and tap targets ≥ 44 (parent) / ≥ 56 (kid).
5. Quality gate in app/: `dart format .`, `flutter analyze` → "No issues found!", `flutter test` → all pass. Do NOT run `flutter clean`.
FINAL REPLY: counts (properties checked / failed / fixed), list of fixes (file:line), new tokens, test results.
