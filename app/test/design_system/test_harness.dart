import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

Future<void> pumpNest(
  WidgetTester tester,
  Widget child, {
  ThemeMode mode = ThemeMode.light,
  Size surface = const Size(390, 844),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: mode,
      home: _ScaleProbe(textScale: textScale, child: child),
    ),
  );
  // Settle entrance motion without hanging on live indicators:
  // indeterminate progress spinners never settle, so tests that include one
  // must not call pumpAndSettle while it is in the tree.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _ScaleProbe extends StatelessWidget {
  const new({required this.textScale, required this.child});

  final double textScale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: child),
    );
  }
}

Future<void> pumpBothModes(
  WidgetTester tester,
  Widget child, {
  Size surface = const Size(390, 844),
  double textScale = 1.0,
}) async {
  for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
    await pumpNest(
      tester,
      child,
      mode: mode,
      surface: surface,
      textScale: textScale,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'overflow or build error in $mode at $surface x$textScale',
    );
  }
}
