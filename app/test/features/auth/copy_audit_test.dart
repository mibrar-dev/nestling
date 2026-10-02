// P03 Create account — copy audit and live-relayout proofs.
//
// COPY (orchestrator rule, iteration 3): every user-facing string must be
// byte-identical to `design/html-source/screens/P03-create-account.html`,
// with the design's typographic characters (U+2019 curly apostrophe,
// U+2014 em dash, U+00A0 where a phrase must not split). Expected values are
// transcribed from the HTML with explicit escapes so the assertions are
// readable and font-independent.
//
// Every string is checked on its own so one deviation cannot mask another.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

/// The design's non-breaking space (COPY rule: "Privacy Notice" must not
/// split). Spelled out so no invisible character hides in this file.
const String nbsp = '\u00a0';

/// Subtitle, `&rsquo;` in the HTML.
const String _designSubtitle =
    'You\u2019re the grown-up in charge. Children never need an email.';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  await setUpTestScope();
  tester.view.physicalSize = size * 3;
  addTearDown(tester.view.reset);
  await pumpAppRoute(tester, '/create-account');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Where the label [label] was actually painted, in global coordinates.
Rect _labelRect(WidgetTester tester, String label) {
  final caption = find
      .descendant(
        of: find.byType(NestBottomCta),
        matching: find.byType(RichText),
      )
      .last;
  final paragraph = tester.renderObject<RenderParagraph>(caption);
  final plain = paragraph.text.toPlainText();
  final start = plain.indexOf(label);
  Rect? box;
  for (final found in paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + label.length),
  )) {
    final rect = found.toRect().shift(paragraph.localToGlobal(Offset.zero));
    box = box == null ? rect : box.expandToInclude(rect);
  }
  return box!;
}

void main() {
  group('P03 copy audit — byte-identical to the design HTML', () {
    testWidgets('h1', (tester) async {
      await _pump(tester);
      expect(find.text('Create your family account'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('subtitle', (tester) async {
      await _pump(tester);
      expect(
        find.text(_designSubtitle),
        findsOneWidget,
        reason:
            'the HTML writes "You&rsquo;re" (U+2019); a straight U+0027 is a '
            'different character and must be flagged (COPY rule)',
      );
      await disposeApp(tester);
    });

    testWidgets('note', (tester) async {
      await _pump(tester);
      expect(
        find.text('No child emails or photos \u2014 ever.'),
        findsOneWidget,
        reason: 'the HTML writes "&mdash;" (U+2014)',
      );
      await disposeApp(tester);
    });

    testWidgets('helper and field labels', (tester) async {
      await _pump(tester);
      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('or'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('buttons', (tester) async {
      await _pump(tester);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'legal caption: the sentence matches and the label is unbreakable',
      (tester) async {
        await _pump(tester);
        // The whole sentence, exactly as the HTML has it …
        final caption = find
            .descendant(
              of: find.byType(NestBottomCta),
              matching: find.byType(RichText),
            )
            .last;
        final plain = tester
            .renderObject<RenderParagraph>(caption)
            .text
            .toPlainText();
        expect(
          plain,
          'By continuing you agree to our Terms and Privacy${nbsp}Notice',
          reason:
              'the sentence is verbatim; the single non-breaking space is the '
              'COPY rule\'s blessed way to stop "Privacy Notice" splitting',
        );
        await disposeApp(tester);
      },
    );
  });

  group('P03 legal targets survive a live relayout', () {
    // The targets are measured post-frame (create_account_view.dart
    // `_LegalLineState`), so a viewport or text-scale change that is not
    // accompanied by a rebuild must still leave them over their words.
    for (final entry in const <MapEntry<String, Size>>[
      MapEntry('narrower 320', Size(320, 844)),
      MapEntry('wider 430', Size(430, 844)),
    ]) {
      testWidgets('${entry.key} keeps both targets on their words', (
        tester,
      ) async {
        await _pump(tester);
        await _pump(tester, size: entry.value);

        for (final pair in <List<String>>[
          <String>['Terms', 'p03_terms'],
          <String>['Privacy${nbsp}Notice', 'p03_privacy'],
        ]) {
          expect(
            _labelRect(
              tester,
              pair[0],
            ).overlaps(tester.getRect(find.byKey(ValueKey(pair[1])))),
            isTrue,
            reason:
                'the ${pair[1]} target drifted off its word at '
                '${entry.value.width}dp',
          );
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    testWidgets('a live text-scale change keeps both targets on their words', (
      tester,
    ) async {
      await _pump(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      for (final pair in <List<String>>[
        <String>['Terms', 'p03_terms'],
        <String>['Privacy${nbsp}Notice', 'p03_privacy'],
      ]) {
        expect(
          _labelRect(
            tester,
            pair[0],
          ).overlaps(tester.getRect(find.byKey(ValueKey(pair[1])))),
          isTrue,
          reason: 'the ${pair[1]} target drifted off its word at scale 1.3',
        );
      }
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a theme switch keeps both targets on their words', (
      tester,
    ) async {
      await _pump(tester);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.dark);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      for (final pair in <List<String>>[
        <String>['Terms', 'p03_terms'],
        <String>['Privacy${nbsp}Notice', 'p03_privacy'],
      ]) {
        expect(
          _labelRect(
            tester,
            pair[0],
          ).overlaps(tester.getRect(find.byKey(ValueKey(pair[1])))),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P03 legal targets land exactly on the laid-out words', () {
    // The targets are measured from a TextPainter mirror during layout
    // (`_LegalLineState._measureSync`) and re-checked post-frame
    // (`_verify`). This pins the mirror to the *real* paragraph: both sides
    // are computed from the rendered glyphs, so it holds for any font.
    for (final cfg in const <List<Object>>[
      <Object>[320, 1.0],
      <Object>[390, 1.0],
      <Object>[430, 1.0],
      <Object>[390, 1.3],
      <Object>[320, 1.3],
    ]) {
      testWidgets(
        '${cfg[0]}dp at scale ${cfg[1]}: targets equal the paragraph boxes',
        (tester) async {
          await _pump(tester, size: Size((cfg[0] as int).toDouble(), 844));
          tester.platformDispatcher.textScaleFactorTestValue = cfg[1] as double;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          final caption = find
              .descendant(
                of: find.byType(NestBottomCta),
                matching: find.byType(RichText),
              )
              .last;
          final paragraph = tester.renderObject<RenderParagraph>(caption);
          final plain = paragraph.text.toPlainText();
          final origin = paragraph.localToGlobal(Offset.zero);
          // Line metrics from a mirror painter over the real paragraph
          // (RenderParagraph has no public accessor).
          final metrics = (TextPainter(
            text: paragraph.text,
            textAlign: paragraph.textAlign,
            textDirection: paragraph.textDirection,
            textScaler: paragraph.textScaler,
            locale: paragraph.locale,
            strutStyle: paragraph.strutStyle,
          )..layout(maxWidth: paragraph.size.width)).computeLineMetrics();

          /// The target the real paragraph implies: the label's union glyph
          /// box, re-centred vertically on its own line, at least 44x44.
          /// Computed in paragraph coordinates, then moved to global.
          Rect expected(String label) {
            final start = plain.indexOf(label);
            Rect? box;
            for (final found in paragraph.getBoxesForSelection(
              TextSelection(
                baseOffset: start,
                extentOffset: start + label.length,
              ),
            )) {
              box = box == null
                  ? found.toRect()
                  : box.expandToInclude(found.toRect());
            }
            final glyph = box!;
            var y = 0.0;
            var lineCentre = y;
            for (final metric in metrics) {
              if (glyph.center.dy >= y &&
                  glyph.center.dy <= y + metric.height) {
                lineCentre = y + metric.height / 2;
                break;
              }
              y += metric.height;
            }
            return Rect.fromCenter(
              center: Offset(glyph.center.dx, lineCentre),
              width: glyph.width < NestDevice.tapParent
                  ? NestDevice.tapParent
                  : glyph.width,
              height: NestDevice.tapParent,
            ).shift(origin);
          }

          for (final pair in <List<String>>[
            <String>['Terms', 'p03_terms'],
            <String>['Privacy${nbsp}Notice', 'p03_privacy'],
          ]) {
            final key = ValueKey<String>(pair[1]);
            expect(
              tester.getRect(find.byKey(key)),
              expected(pair[0]),
              reason:
                  'the $key target drifted from the laid-out text at '
                  '${cfg[0]}dp scale ${cfg[1]}',
            );
          }
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        },
      );
    }
  });
}
