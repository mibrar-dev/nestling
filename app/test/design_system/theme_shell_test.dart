import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('KidScope', () {
    testWidgets('applies sky gradient and kid theme', (tester) async {
      await pumpBothModes(
        tester,
        const SingleChildScrollView(
          child: KidScope(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Kid content'),
                NestKidButton(label: 'Play'),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(KidScope), findsOneWidget);
    });
  });

  group('app shell', () {
    setUpAll(() async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await configureDependencies();
    });

    testWidgets('clamps the text scaler to 1.0-1.3', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const NestlingApp());
      await tester.pumpAndSettle();
      final clamped = find.byWidgetPredicate(
        (widget) =>
            widget is MediaQuery && widget.data.textScaler.scale(1) == 1.3,
      );
      expect(clamped, findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gallery renders sections and toggles theme', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const NestlingApp());
      await tester.pumpAndSettle();
      expect(find.text('Design system'), findsOneWidget);
      expect(find.text('Colour'), findsOneWidget);
      await tester.tap(find.byTooltip('Toggle light/dark'));
      await tester.pumpAndSettle();
      expect(GetIt.instance<ThemeModeController>().mode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(AppBar))).brightness,
        Brightness.dark,
      );
      await tester.scrollUntilVisible(
        find.text('Screens'),
        500,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Screens'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
