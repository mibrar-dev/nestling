// Shared batch 6 (P16 SHARED_REQUEST §§1–5):
// - NestListRow keeps 56 px with a NestToggle trailing (hit slop overhangs
//   the row padding, like NestChip/NestToggle)
// - NestSectionLabel matches the browser natural 16 px line box
// - NestCard gains optional radius/padding (defaults unchanged)
// - IANA link ids resolve (Europe/Belfast → London, Asia/Calcutta → Kolkata)

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('NestListRow with NestToggle trailing (P16 §1)', () {
    testWidgets('row stays 56 with a toggle (44 tap overhangs, not layout)', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        const SizedBox(
          width: 350,
          child: NestList(
            children: [
              NestListRow(
                title: 'Approvals waiting',
                trailing: NestToggle(
                  value: true,
                  semanticLabel: 'Approvals waiting notifications',
                  onChanged: null,
                ),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final row = tester.getSize(find.byType(NestListRow));
      expect(row.height, closeTo(56, 0.5), reason: 'design min-height binds');
      // The track itself still lays out 51×31 (shared batch 5).
      expect(tester.getSize(find.byType(NestToggle)), const Size(51, 31));
    });

    testWidgets('a tap 5 px above/below the track toggles it', (tester) async {
      var value = false;
      final calls = <bool>[];
      await pumpNest(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 350,
              child: NestList(
                children: [
                  NestListRow(
                    title: 'Approvals waiting',
                    trailing: NestToggle(
                      value: value,
                      semanticLabel: 'Approvals waiting notifications',
                      onChanged: (next) {
                        setState(() => value = next);
                        calls.add(next);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
      expect(tester.takeException(), isNull);
      final track = tester.getRect(find.byType(NestToggle));
      expect(track.size, const Size(51, 31));
      // 5 px above the track: inside the 44-high slop (6.5 px each side)
      // and inside the row's 10 px padding, but outside the inner Row.
      await tester.tapAt(Offset(track.center.dx, track.top - 5));
      await tester.pump();
      expect(calls, [true], reason: 'tap 5 px above must toggle');
      // 5 px below the track flips back.
      await tester.tapAt(Offset(track.center.dx, track.bottom + 5));
      await tester.pump();
      expect(calls, [true, false], reason: 'tap 5 px below must toggle');
    });

    testWidgets('semantics expose the toggle action', (tester) async {
      await pumpNest(
        tester,
        SizedBox(
          width: 350,
          child: NestList(
            children: [
              NestListRow(
                title: 'Approvals waiting',
                trailing: NestToggle(
                  value: false,
                  semanticLabel: 'Approvals waiting notifications',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      // The row title Text and the toggle merge into one semantics node
      // (the row has no button wrapper when onTap is null), so match by
      // containing pattern, not an exact label.
      final candidates = find.semantics
          .byLabel(RegExp('Approvals waiting notifications'))
          .evaluate();
      expect(
        candidates,
        isNotEmpty,
        reason: 'toggle label must be in the semantics tree',
      );
      final data = candidates.single.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });
  });

  group('NestSectionLabel natural line box (P16 §2)', () {
    test('sectionLabel is 13/16 w700 ls .78 (browser natural, not 18)', () {
      final style = NestType.sectionLabel();
      expect(style.fontSize, 13);
      expect(style.height, 16 / 13);
      expect(style.letterSpacing, 0.78);
      expect(style.fontWeight, FontWeight.w700);
    });

    testWidgets('label lays out 16 high at scale 1.0', (tester) async {
      await pumpBothModes(tester, const NestSectionLabel(label: 'Family'));
      expect(tester.takeException(), isNull);
      expect(find.text('FAMILY'), findsOneWidget);
      final box = tester.getSize(find.byType(NestSectionLabel));
      expect(box.height, closeTo(16, 0.5));
    });
  });

  group('NestCard radius + padding (P16 §3)', () {
    testWidgets('defaults unchanged (24 radius, 16 padding)', (tester) async {
      await pumpBothModes(tester, const NestCard(child: Text('Body')));
      expect(tester.takeException(), isNull);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NestCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.borderRadius, NestRadii.allL);
      expect(container.padding, const EdgeInsets.all(NestSpacing.s4));
    });

    testWidgets('subcard override (16 radius, 14/16 padding)', (tester) async {
      await pumpBothModes(
        tester,
        const NestCard(
          radius: NestRadii.m,
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Text('Body'),
        ),
      );
      expect(tester.takeException(), isNull);
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(NestCard),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(NestRadii.m),
        reason: 'P16 .subcard --r-m (16)',
      );
      expect(
        container.padding,
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        reason: 'P16 .subcard padding:14px 16px',
      );
    });

    testWidgets('tap variant keeps the override on Material + Ink', (
      tester,
    ) async {
      await pumpNest(
        tester,
        NestCard(
          radius: NestRadii.m,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          onTap: () {},
          child: const Text('Body'),
        ),
      );
      expect(tester.takeException(), isNull);
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(NestCard),
          matching: find.byType(Material),
        ),
      );
      expect(material.borderRadius, BorderRadius.circular(NestRadii.m));
      final inkWell = tester.widget<InkWell>(
        find.descendant(
          of: find.byType(NestCard),
          matching: find.byType(InkWell),
        ),
      );
      expect(inkWell.borderRadius, BorderRadius.circular(NestRadii.m));
    });
  });

  group('IANA link ids (P16 §5, P16-B09)', () {
    test('Europe/Belfast resolves to Europe/London', () {
      expect(isKnownZoneId('Europe/Belfast'), isTrue);
      expect(normalizeZoneId('Europe/Belfast'), 'Europe/London');
    });

    test('Asia/Calcutta is accepted as Asia/Kolkata', () {
      expect(isKnownZoneId('Asia/Calcutta'), isTrue);
      expect(normalizeZoneId('Asia/Calcutta'), 'Asia/Kolkata');
    });

    test('GB resolves (country link to London)', () {
      expect(isKnownZoneId('GB'), isTrue);
      expect(normalizeZoneId('GB'), 'Europe/London');
    });

    test('canonical zones still resolve unchanged', () {
      expect(isKnownZoneId('Europe/London'), isTrue);
      expect(normalizeZoneId('Europe/London'), 'Europe/London');
      expect(isKnownZoneId('Asia/Dubai'), isTrue);
      expect(normalizeZoneId('Asia/Dubai'), 'Asia/Dubai');
    });

    test('unknown ids still fall back safely', () {
      expect(isKnownZoneId('Mars/Olympus'), isFalse);
      expect(normalizeZoneId('Mars/Olympus'), 'Europe/London');
    });
  });
}
