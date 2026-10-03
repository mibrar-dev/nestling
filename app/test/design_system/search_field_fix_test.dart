// Shared fix (P10 SHARED_REQUEST §§9–10): `NestTextField.search` matches the
// `.search` border box — 54 high with 1 px borders inside — and centres the
// hint and the typed text in the 44 px content slot.
//
// Geometry proofs load the real bundled Inter/Nunito faces via `FontLoader`
// (the shared_batch4 pattern) and pin positions at 390 wide.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

/// Loads the bundled faces so metrics match a device run (same set as the
/// shared_batch4 geometry test).
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

/// Full-width row at the top, as in a screen scroll — a bare Container would
/// stretch to the Scaffold body height instead of sizing to the field.
Widget _searchRow() => const Align(
  alignment: Alignment.topCenter,
  child: SizedBox(
    width: 390,
    child: NestTextField.search(
      hintText: 'Search ideas',
      semanticLabel: 'Search quest ideas',
    ),
  ),
);

/// The outer `.search` container (first Container under NestTextField —
/// InputDecorator's own boxes sit deeper).
Rect _fieldRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(NestTextField),
        matching: find.byType(Container),
      )
      .first,
);

void main() {
  setUpAll(_loadBundledFonts);

  group('NestTextField.search (.search border box, centred text)', () {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${mode.name}: field is 54 high', (tester) async {
        await pumpNest(tester, _searchRow(), mode: mode);
        // `.search` border box: 4 + 44 + 4 content plus 1 px borders = 54.
        expect(_fieldRect(tester).height, moreOrLessEquals(54, epsilon: 0.5));
      });

      testWidgets('${mode.name}: hint is centred in the field', (tester) async {
        await pumpNest(tester, _searchRow(), mode: mode);
        final field = _fieldRect(tester);
        final hint = tester.getRect(find.text('Search ideas'));
        expect(hint.center.dy, moreOrLessEquals(field.center.dy, epsilon: 1));
      });

      testWidgets('${mode.name}: typed text is centred in the field', (
        tester,
      ) async {
        await pumpNest(tester, _searchRow(), mode: mode);
        await tester.enterText(find.byType(TextField), 'bins');
        await tester.pump();
        final field = _fieldRect(tester);
        final typed = tester.getRect(find.text('bins'));
        expect(typed.center.dy, moreOrLessEquals(field.center.dy, epsilon: 1));
      });

      testWidgets('${mode.name}: icon at x+16, hint at x+50', (tester) async {
        await pumpNest(tester, _searchRow(), mode: mode);
        final field = _fieldRect(tester);
        final icon = tester.getRect(find.byType(NestIcon));
        expect(icon.size, const Size(24, 24));
        expect(icon.left - field.left, moreOrLessEquals(16, epsilon: 1));
        final hint = tester.getRect(find.text('Search ideas'));
        expect(hint.left - field.left, moreOrLessEquals(50, epsilon: 1));
        // The icon stays centred too: the text fix must not move it.
        expect(icon.center.dy, moreOrLessEquals(field.center.dy, epsilon: 1));
      });
    }

    testWidgets('labelled variant is unaffected', (tester) async {
      await pumpBothModes(
        tester,
        const NestTextField(
          label: 'Email',
          hintText: 'sarah@example.co.uk',
          helperText: 'Children never need an email.',
        ),
      );
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(
        decoration.contentPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Children never need an email.'), findsOneWidget);
    });
  });
}
