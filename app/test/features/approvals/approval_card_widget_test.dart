// P11 · Approvals — card widget + time-helper tests.
//
// These are the pure presentation pieces of `presentation/widgets/**`:
//   approval_time.dart    approvalDayLabel / approvalTimeLabel
//   approval_card.dart    ApprovalCard (row geometry, busy state, semantics)
//   approvals_loaded_body.dart  helper banner + empty state
//
// P11 plan §6 item 3 wanted a dedicated `approval_time_test.dart`; that file
// name carries neither `view` nor `widget`, so the time coverage lives here to
// keep the parallel logic builder's file set untouched.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_time.dart';
import 'package:nestling/features/approvals/presentation/widgets/approvals_loaded_body.dart';

Approval _approval({
  int id = 1,
  String quest = 'Empty the dishwasher',
  String child = 'Maya',
  String colour = 'lilac',
  int coins = 15,
  DateTime? createdAt,
  String zone = 'Europe/London',
}) {
  return Approval(
    id: '$id',
    title: quest,
    detail: '',
    completionId: id,
    questId: 'q-$id',
    questTitle: quest,
    childId: 'maya',
    childName: child,
    avatarColour: colour,
    coins: coins,
    createdAt: createdAt ?? DateTime.utc(2026, 10, 3, 7, 12),
    createdAtTz: zone,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFFFBF7F0),
        body: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('approvalTime labels', () {
    // 3 Oct 2026 is a Saturday; the seed anchors its story to this date.
    test('same London day → Today', () {
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 10, 3, 7, 12),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 10, 3, 18),
        ),
        'Today',
      );
    });

    test('one London day before → Yesterday', () {
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 10, 2, 16, 40),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 10, 3, 9),
        ),
        'Yesterday',
      );
    });

    test('older → weekday + day + month', () {
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 9, 21, 16, 40),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 10, 3, 9),
        ),
        'Mon 21 Sep',
      );
    });

    test('day boundary is the stored zone midnight, not UTC', () {
      // London is on BST (UTC+1) in October, so its midnight is 23:00 UTC. A
      // completion at 22:50 UTC is 23:50 on 2 Oct in London: still "Today" at
      // 22:55 UTC (23:55 London), and "Yesterday" at 23:10 UTC (00:10 London
      // on 3 Oct). Reading the raw UTC dates would have it backwards.
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 10, 2, 22, 50),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 10, 2, 22, 55),
        ),
        'Today',
      );
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 10, 2, 22, 50),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 10, 2, 23, 10),
        ),
        'Yesterday',
      );
      // A family further east has already crossed midnight at the same instant.
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 10, 2, 22, 50),
          storedZoneId: 'Asia/Dubai',
          nowUtc: DateTime.utc(2026, 10, 2, 23, 10),
        ),
        'Today',
      );
    });

    test('a moved family names the stored zone', () {
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 9, 21, 16, 40),
          storedZoneId: 'Europe/London',
          nowUtc: DateTime.utc(2026, 10, 3, 9),
          familyZoneId: 'Asia/Dubai',
        ),
        'Mon 21 Sep (London)',
      );
    });

    test('time label: morning, noon and midnight edges', () {
      DateTime at(int hour, int minute) =>
          DateTime.utc(2026, 10, 3, hour - 1, minute);
      expect(
        approvalTimeLabel(
          createdAtUtc: DateTime.utc(2026, 10, 3, 7, 12),
          storedZoneId: 'Europe/London',
        ),
        '8:12am',
      );
      expect(
        approvalTimeLabel(
          createdAtUtc: DateTime.utc(2026, 10, 3, 6, 58),
          storedZoneId: 'Europe/London',
        ),
        '7:58am',
      );
      expect(
        approvalTimeLabel(
          createdAtUtc: at(12, 5),
          storedZoneId: 'Europe/London',
        ),
        '12:05pm',
      );
      expect(
        approvalTimeLabel(
          createdAtUtc: at(0, 0),
          storedZoneId: 'Europe/London',
        ),
        '12:00am',
      );
      expect(
        approvalTimeLabel(
          createdAtUtc: DateTime.utc(2026, 10, 2, 16, 40),
          storedZoneId: 'Europe/London',
        ),
        '5:40pm',
      );
    });

    test('an unknown stored zone falls back instead of throwing', () {
      expect(
        approvalDayLabel(
          createdAtUtc: DateTime.utc(2026, 10, 3, 7, 12),
          storedZoneId: 'Mars/Olympus',
          nowUtc: DateTime.utc(2026, 10, 3, 18),
        ),
        'Today',
      );
    });
  });

  group('approvalAvatarColor', () {
    test('maps the stored avatarColour, unknown → neutral', () {
      expect(approvalAvatarColor('lilac'), NestAvatarColor.lilac);
      expect(approvalAvatarColor('peach'), NestAvatarColor.peach);
      expect(approvalAvatarColor('sky'), NestAvatarColor.sky);
      expect(approvalAvatarColor('leaf'), NestAvatarColor.leaf);
      expect(approvalAvatarColor('coin'), NestAvatarColor.coin);
      expect(approvalAvatarColor('chartreuse'), NestAvatarColor.neutral);
    });
  });

  group('ApprovalCard', () {
    testWidgets('renders avatar, name · quest, time · coins and both buttons', (
      tester,
    ) async {
      var notYet = 0;
      var approve = 0;
      await _pump(
        tester,
        ApprovalCard(
          approval: _approval(),
          nowUtc: DateTime.utc(2026, 10, 3, 18),
          onNotYet: () => notYet++,
          onApprove: () => approve++,
        ),
      );

      expect(find.byType(NestAvatar), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('Maya · Empty the dishwasher'), findsOneWidget);
      expect(
        find.textContaining('Today 8:12am · 15 coins'),
        findsOneWidget,
        reason: 'the .tm line flattens to "<day> <time> · <coins> coins"',
      );
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);

      await tester.tap(find.text('Not yet'));
      await tester.tap(find.text('Approve'));
      expect(notYet, 1);
      expect(approve, 1);
    });

    testWidgets('row buttons are 48 high, pill-shaped and fill the card', (
      tester,
    ) async {
      await _pump(
        tester,
        ApprovalCard(
          approval: _approval(),
          nowUtc: DateTime.utc(2026, 10, 3, 18),
          onNotYet: () {},
          onApprove: () {},
        ),
      );

      final buttons = tester.widgetList<NestButton>(find.byType(NestButton));
      expect(buttons, hasLength(2));
      for (final button in buttons) {
        expect(button.minHeight, 48);
        expect(button.fontSize, 15);
        expect(button.horizontalPadding, 12);
        expect(button.fullWidth, isTrue);
      }

      final geometry = tester.getRect(find.text('Approve'));
      final pill = find.ancestor(
        of: find.text('Approve'),
        matching: find.byType(AnimatedContainer),
      );
      final pillRect = tester.getRect(pill.first);
      expect(pillRect.height, 48);
      expect(pillRect.width, greaterThan(100));
      expect(pillRect.contains(geometry.center), isTrue);

      // Two equal cells separated by a 10px gap inside the card's 16 padding.
      final secondary = tester.getRect(
        find
            .ancestor(
              of: find.text('Not yet'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(pillRect.left - secondary.right, 10);
      expect(pillRect.width, closeTo(secondary.width, 0.01));
    });

    testWidgets('busy disables both buttons and swallows taps', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        ApprovalCard(
          approval: _approval(),
          nowUtc: DateTime.utc(2026, 10, 3, 18),
          busy: true,
          onNotYet: () => taps++,
          onApprove: () => taps++,
        ),
      );

      for (final button in tester.widgetList<NestButton>(
        find.byType(NestButton),
      )) {
        expect(button.loading, isTrue);
        expect(button.onPressed, isNull);
      }
      await tester.tap(find.text('Approve'));
      expect(taps, 0);
    });

    testWidgets('each card is one semantics node with a summary label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        ApprovalCard(
          approval: _approval(),
          nowUtc: DateTime.utc(2026, 10, 3, 18),
          onNotYet: () {},
          onApprove: () {},
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Maya, Empty the dishwasher, Today 8:12am, 15 coins',
        ),
        findsOneWidget,
      );
      // The buttons stay independently reachable (their labels are NOT merged
      // into the row summary).
      expect(find.bySemanticsLabel('Not yet'), findsOneWidget);
      expect(find.bySemanticsLabel('Approve'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('no Pip renders on this screen (initials only)', (
      tester,
    ) async {
      await _pump(
        tester,
        ApprovalCard(
          approval: _approval(),
          nowUtc: DateTime.utc(2026, 10, 3, 18),
          onNotYet: () {},
          onApprove: () {},
        ),
      );
      expect(find.byType(NestAvatar), findsOneWidget);
      expect(find.text('“I stacked everything neatly!”'), findsNothing);
    });

    testWidgets('renders at 320 wide with text scale 1.3', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(
        tester,
        ApprovalCard(
          approval: _approval(quest: 'Empty the dishwasher and load the racks'),
          nowUtc: DateTime.utc(2026, 10, 3, 18),
          onNotYet: () {},
          onApprove: () {},
        ),
        width: 320,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
    });
  });

  group('ApprovalsLoadedBody', () {
    testWidgets('banner + one card per item, 16px apart', (tester) async {
      await _pump(
        tester,
        SizedBox(
          height: 700,
          child: ApprovalsLoadedBody(
            items: <Approval>[
              _approval(),
              _approval(
                id: 2,
                quest: 'Make your bed',
                child: 'Leo',
                coins: 5,
                createdAt: DateTime.utc(2026, 10, 3, 6, 58),
              ),
            ],
            nowUtc: DateTime.utc(2026, 10, 3, 18),
            onNotYet: (_) {},
            onApprove: (_) {},
          ),
        ),
      );

      expect(find.byType(ApprovalsHelperBanner), findsOneWidget);
      expect(find.byType(ApprovalCard), findsNWidgets(2));

      final banner = tester.getRect(find.byType(ApprovalsHelperBanner));
      final firstCard = tester.getRect(_cardFor('Maya · Empty the dishwasher'));
      expect(firstCard.top - banner.bottom, NestSpacing.s4);
      final secondCard = tester.getRect(_cardFor('Leo · Make your bed'));
      expect(secondCard.top - firstCard.bottom, NestSpacing.s4);
    });

    testWidgets('empty list shows the empty state, no banner', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          height: 700,
          child: ApprovalsLoadedBody(
            items: <Approval>[],
            onNotYet: _noop,
            onApprove: _noop,
          ),
        ),
      );

      expect(find.byType(ApprovalsHelperBanner), findsNothing);
      expect(find.text('All caught up'), findsOneWidget);
      expect(
        find.text(
          'When your children finish a quest, it will appear here for your '
          'thumbs-up.',
        ),
        findsOneWidget,
      );
    });
  });
}

/// The [ApprovalCard] whose `.who` line is [whoLine].
Finder _cardFor(String whoLine) =>
    find.ancestor(of: find.text(whoLine), matching: find.byType(ApprovalCard));

void _noop(int id) {}
