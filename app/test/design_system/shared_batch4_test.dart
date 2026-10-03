// Shared batch 4 (P10 SHARED_REQUEST §§1–3): search-field geometry,
// segmented 52/44, tab-bar content position with the surface to the edge.
//
// Geometry proofs load the real bundled Inter/Nunito faces via `FontLoader`
// (the P04 geometry-test pattern) and pin positions at 390×844.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

/// Loads the bundled faces so metrics match a device run (same set as the
/// P04 geometry test).
Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

const List<NestTabItem> _items = <NestTabItem>[
  NestTabItem(label: 'Today', icon: NestIcons.home),
  NestTabItem(label: 'Quests', icon: NestIcons.quests),
  NestTabItem(label: 'Money', icon: NestIcons.money),
  NestTabItem(label: 'Family', icon: NestIcons.family),
];

/// Pumps a bare [Scaffold] with the tab bar as its bottom navigation bar on
/// a 390×844 surface, optionally with OS insets (physical px = logical × 3).
Future<void> _pumpTabBar(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  double topInset = 0,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (topInset > 0 || bottomInset > 0) {
    final insets = FakeViewPadding(top: topInset * 3, bottom: bottomInset * 3);
    tester.view.padding = insets;
    tester.view.viewPadding = insets;
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: mode,
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: NestTabBar(
          items: _items,
          currentIndex: 0,
          onTap: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(_loadBundledFonts);

  group('NestTextField.search (.search geometry)', () {
    // Full-width row at the top, as in a screen scroll — a bare Container
    // would stretch to the Scaffold body height instead of sizing to 52.
    Widget searchRow() => const Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 390,
        child: NestTextField.search(
          hintText: 'Search ideas',
          semanticLabel: 'Search quest ideas',
        ),
      ),
    );

    testWidgets('icon 24 at x+16, hint at x+50, field 52 high', (tester) async {
      await pumpBothModes(tester, searchRow());

      // The outer `.search` container (first Container under NestTextField —
      // InputDecorator's own boxes sit deeper).
      final field = tester.getRect(
        find
            .descendant(
              of: find.byType(NestTextField),
              matching: find.byType(Container),
            )
            .first,
      );
      // `.search { min-height:52px }`: 4 px padding around the 44 px input.
      expect(field.height, moreOrLessEquals(52, epsilon: 1));

      final icon = tester.getRect(find.byType(NestIcon));
      expect(icon.size, const Size(24, 24));
      // `.search { padding: 4px 16px }`: the glyph starts 16 px in.
      expect(icon.left - field.left, moreOrLessEquals(16, epsilon: 1));

      // Icon 24 + `gap:10px`: the hint starts at 16 + 24 + 10 = x+50.
      final hint = tester.getRect(find.text('Search ideas'));
      expect(hint.left - field.left, moreOrLessEquals(50, epsilon: 1));
    });

    testWidgets('typing reports the query', (tester) async {
      var changed = '';
      await pumpNest(
        tester,
        NestTextField.search(
          hintText: 'Search ideas',
          onChanged: (value) => changed = value,
        ),
      );
      await tester.enterText(find.byType(TextField), 'bins');
      expect(changed, 'bins');
      expect(find.text('bins'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('semantic label marks the text field', (tester) async {
      await pumpNest(
        tester,
        const NestTextField.search(
          hintText: 'Search ideas',
          semanticLabel: 'Search quest ideas',
        ),
      );
      expect(find.bySemanticsLabel('Search quest ideas'), findsOneWidget);
    });
  });

  group('NestSegmented (52 track, 44 buttons)', () {
    const options = [
      NestSegmentOption(value: 'Active', label: 'Active'),
      NestSegmentOption(value: 'Ideas', label: 'Ideas'),
    ];

    testWidgets('selected pill keeps r-pill and sh-1', (tester) async {
      await pumpNest(
        tester,
        NestSegmented<String>(
          options: options,
          value: 'Ideas',
          onChanged: (_) {},
        ),
      );
      final pill = tester
          .widgetList<Ink>(find.byType(Ink))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == NestColors.light.surface);
      expect(pill.borderRadius, NestRadii.allPill);
      expect(pill.boxShadow, isNotNull);
    });

    testWidgets('dark selected pill keeps r-pill with a line border', (
      tester,
    ) async {
      await pumpNest(
        tester,
        NestSegmented<String>(
          options: options,
          value: 'Ideas',
          onChanged: (_) {},
        ),
        mode: ThemeMode.dark,
      );
      final pill = tester
          .widgetList<Ink>(find.byType(Ink))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.color == NestColors.dark.surface);
      expect(pill.borderRadius, NestRadii.allPill);
      expect(pill.border, isNotNull);
    });
  });

  group('NestTabBar (content up, surface to the edge)', () {
    testWidgets('no inset: exactly the 84 block at the edge', (tester) async {
      await _pumpTabBar(tester);
      final bar = tester.getRect(find.byType(NestTabBar));
      expect(bar.height, 84);
      expect(bar.bottom, 844);
    });

    testWidgets('47/34: content at the design position', (tester) async {
      await _pumpTabBar(tester, topInset: 47, bottomInset: 34);
      final bar = tester.getRect(find.byType(NestTabBar));
      // 84 px content block + 34 px home inset, surface to the edge.
      expect(bar.height, 84 + 34);
      expect(bar.top, moreOrLessEquals(726, epsilon: 1));
      expect(bar.bottom, 844);

      // Design: icon centre 748, label centre ≈ 772.
      final icon = tester.getRect(find.byType(NestIcon).first);
      expect(icon.size, const Size(24, 24));
      expect(icon.center.dy, moreOrLessEquals(748, epsilon: 1));
      final label = tester.getRect(find.text('Today'));
      expect(label.center.dy, moreOrLessEquals(772, epsilon: 2));
    });

    for (final theme in const [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the surface colour fills down to y 844', (
        tester,
      ) async {
        await _pumpTabBar(tester, mode: theme, bottomInset: 34);
        final bar = tester.getRect(find.byType(NestTabBar));
        expect(bar.bottom, 844);

        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(NestTabBar),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = container.decoration! as BoxDecoration;
        final expected = theme == ThemeMode.light
            ? NestColors.light.surface
            : NestColors.dark.surface;
        expect(
          decoration.color,
          expected,
          reason: 'the home-inset area keeps the tab bar surface colour',
        );
      });
    }
  });
}
