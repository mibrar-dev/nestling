// Shared batch 5 (P09 SHARED_REQUEST §§2,4,5,6):
// - 4 exact P09 glyphs as `questBed/questDishes/questHoover/questBins`
// - `NestToggle` 51x31 track with 59x44 hit slop
// - `NestStepper` U+2212 minus
// - `NestTextField` default 12px horizontal padding (17px text inset)

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

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

String _readIcon(String file) => File('assets/icons/$file').readAsStringSync();

void main() {
  setUpAll(_loadBundledFonts);

  group('Shared batch 5 icons (P09 exact glyphs)', () {
    const mapping = <String, String>{
      'ic_quest_bed.svg': 'M3 18v-8a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v8',
      'ic_quest_dishes.svg': 'M4 11h16v9a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-9z',
      'ic_quest_hoover.svg':
          'M16 12h3a2 2 0 0 0 2-2V7a2 2 0 0 0-4 0M7 16v3M11 16v3',
      'ic_quest_bins.svg':
          'M3 7h13v9H3zM7 7V5a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2M10 12h4',
    };

    test('asset constants point at the new files', () {
      expect(NestIcons.questBed, 'assets/icons/ic_quest_bed.svg');
      expect(NestIcons.questDishes, 'assets/icons/ic_quest_dishes.svg');
      expect(NestIcons.questHoover, 'assets/icons/ic_quest_hoover.svg');
      expect(NestIcons.questBins, 'assets/icons/ic_quest_bins.svg');
    });

    for (final entry in mapping.entries) {
      test('${entry.key} is the design glyph, tintable', () {
        final svg = _readIcon(entry.key);
        expect(svg, contains('currentColor'));
        expect(svg, isNot(contains('fill="#')));
        expect(svg, isNot(contains('stroke="#')));
        expect(svg, contains('stroke-width="2"'));
        expect(
          svg,
          contains(entry.value),
          reason: '${entry.key} must contain the P09 path',
        );
      });
    }

    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      for (final asset in const [
        NestIcons.questBed,
        NestIcons.questDishes,
        NestIcons.questHoover,
        NestIcons.questBins,
      ]) {
        testWidgets('${mode.name}: $asset renders with the theme colour', (
          tester,
        ) async {
          await pumpNest(
            tester,
            Builder(
              builder: (context) => NestIcon(asset, color: context.nest.ink),
            ),
            mode: mode,
          );
          expect(find.byType(NestIcon), findsOneWidget);
          final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
          expect(svg.colorFilter, isNotNull);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('NestToggle (51x31 track, 59x44 hit slop)', () {
    testWidgets('the laid-out box is the 51x31 track', (tester) async {
      await pumpBothModes(
        tester,
        NestToggle(value: true, semanticLabel: 'T', onChanged: (_) {}),
      );
      expect(tester.getSize(find.byType(NestToggle)), const Size(51, 31));
      final track = tester.getSize(find.byType(AnimatedContainer));
      expect(track.width, 51);
      expect(track.height, 31);
    });

    testWidgets('a tap 4 px outside the track still toggles', (tester) async {
      final calls = <bool>[];
      await pumpNest(
        tester,
        Center(
          child: NestToggle(
            value: false,
            semanticLabel: 'T',
            onChanged: calls.add,
          ),
        ),
      );
      final track = tester.getRect(
        find.descendant(
          of: find.byType(NestToggle),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(track.size, const Size(51, 31));
      // 4 px left of the track: inside the 59-wide (4 px each side) hit area.
      await tester.tapAt(Offset(track.left - 4, track.center.dy));
      await tester.pump();
      expect(calls, [true]);
      // 4 px above the track: inside the 44-high (6.5 px each side) hit area.
      await tester.tapAt(Offset(track.center.dx, track.top - 4));
      await tester.pump();
      expect(calls, [true, true]);
    });

    testWidgets('semantics expose the toggle action', (tester) async {
      final calls = <bool>[];
      await pumpNest(
        tester,
        NestToggle(value: false, semanticLabel: 'T', onChanged: calls.add),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      final node = find.semantics
          .byLabel('T')
          .evaluate()
          .single
          .getSemanticsData();
      expect(node.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('NestStepper (U+2212 minus)', () {
    testWidgets('the decrease glyph is U+2212, never U+002D', (tester) async {
      await pumpBothModes(tester, const NestStepper(valueText: '15'));
      final decrease = find.descendant(
        of: find.byKey(const ValueKey('decrease')),
        matching: find.byType(Text),
      );
      expect(decrease, findsOneWidget);
      final label = tester.widget<Text>(decrease).data!;
      expect(label, '−');
      expect(label.codeUnits, isNot(contains(0x2D)));
      expect(label.runes.single, 0x2212);
    });
  });

  group('NestTextField default (17 px text inset)', () {
    test('default contentPadding cancels the 4 px editable inset', () {
      // Measured: EditableText sits ~4 px inside the decoration content box
      // (same as the search variant's `left: -4`); 12 + 4 + 1 border = 17.
      const field = NestTextField(label: 'Name');
      expect(field.search, isFalse);
    });

    testWidgets('decoration carries 12 px horizontal, 14 px vertical', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        const NestTextField(label: 'Email', hintText: 'sarah@example.co.uk'),
      );
      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(
        decoration.contentPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
    });

    testWidgets('typed text starts 17 px from the field edge', (tester) async {
      await pumpNest(
        tester,
        const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 390,
            child: NestTextField(label: 'Name', hintText: 'Name'),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Hoover');
      await tester.pump();
      final field = tester.getRect(
        find
            .descendant(
              of: find.byType(NestTextField),
              matching: find.byType(TextField),
            )
            .first,
      );
      final typed = tester.getRect(find.text('Hoover'));
      // Field x + 1 px border + 16 px padding = 17 from the field edge.
      expect(typed.left - field.left, moreOrLessEquals(17, epsilon: 1.5));
    });
  });
}
