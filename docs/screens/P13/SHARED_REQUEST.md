# Shared request — P13 `pumpAppRoute` surface size is hard-coded

Need: `test/test_scope.dart::pumpAppRoute` (line 34) sets
`tester.view.physicalSize = const Size(390 * 3, 844 * 3)` unconditionally, so any
size a test sets *before* calling it is silently overwritten and the first frame
is always 390×844. Every screen's "320 px" / "430 px" / "short screen" case that
goes through this helper therefore passes while running at 390 — responsive
coverage that cannot fail. Give the helper an optional `size` (and optionally
`textScale`) parameter defaulting to the current behaviour:

```dart
Future<void> pumpAppRoute(
  WidgetTester tester,
  String route, {
  ThemeMode theme = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async { ... }
```

Files: `app/test/test_scope.dart` (one helper signature, no behaviour change for
existing callers).

Blocks: **no** — P13 already works around it. `payout_responsive_test.dart` and
`p13_bugs_test.dart` pump `NestlingApp` directly with their own
`tester.view.physicalSize`, so their 320/390/430 and 320×568 probes are real.
Only the two `payout_view_test.dart` cases named below still silently run at
390; each now carries a `HARNESS TRAP` comment above it saying so.

Confirmed affected P13 cases (both currently execute at 390×844, not what their
names claim):

- `payout_view_test.dart` — `320 px at text scale 1.3 overflows nothing`
- `payout_view_test.dart` — `a short screen scrolls the sheet instead of
  overflowing`

Same trap exists for P12's `money_ledger_responsive_test.dart` and other
features; a shared fix repairs all of them at once.
