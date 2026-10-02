// P02 Value tour — adversarial bug proofs (Stage 6, iteration 1).
//
// Every test in this file is EXPECTED TO FAIL while its bug is open. They are
// all marked `skip:` with the bug id so `flutter test` stays green; delete the
// matching `skip:` when the fix lands. Findings, repros and suggested fixes:
// `docs/screens/P02/6_bugs.md`.
//
//   flutter test test/features/onboarding/p02_bugs_test.dart
//
// MAJOR  P02-BUG-1  pager 468dp vs the design's 400dp; below-pager copy clipped
// MAJOR  P02-BUG-2  card-1 preview rows 60dp vs the design's 38dp → titles cut
// MAJOR  P02-BUG-3  short screens (375x667 / 320x568) overflow or lose the copy
// MINOR  P02-BUG-4  card-1 assignee/repeat copy contradicts Seed.demo
// MINOR  P02-BUG-5  "Sat 4 Oct" chip is a stale date (no longer a Saturday)
// MINOR  P02-BUG-6  system back from /value-tour does not return to /welcome

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../test_scope.dart';

const String _step1Title = 'Set quests in seconds';

/// Pumps `/value-tour` through the real app at [surface] and [textScale].
Future<void> _pumpTour(
  WidgetTester tester, {
  required Size surface,
  double textScale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpAppRoute(tester, '/value-tour');
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _cardOne() => find.ancestor(
  of: find.text("Today's quests"),
  matching: find.byType(NestCard),
);

void main() {
  // ---------------------------------------------------------------------
  // P02-BUG-1 (MAJOR) — the pager is 468dp tall instead of the design's
  // 400dp, so the copy block below it is clipped and jammed against the CTA.
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-1a pager is the design 400dp at 390x844 (currently 468dp)',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400, epsilon: 0.01),
        reason:
            'design .pager is 400dp (SPACING_SPEC §7, PNG card y107→507). '
            'The 468dp pager pushes everything below it 68dp down and leaves '
            'the copy block with only 193dp of viewport (see BUG-1c).',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-1
  );

  testWidgets(
    'P02-BUG-1b pager is 400x1.3 at text scale 1.3 (currently 468x1.3)',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844), textScale: 1.3);

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400 * 1.3, epsilon: 0.01),
        reason:
            '1_plan §a text-scale rule: pagerH = design 400 x ts. At 1.3 the '
            'screen currently reserves 608.4dp, leaving a 52dp copy viewport.',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-1
  );

  testWidgets(
    'P02-BUG-1c copy viewport fits the design copy block at 390x844',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      // Design copy budget: dots top 22 + dots 18 + title gap 30 + h1 line 34
      // + gap 12 + body 2 lines 48 + bottom pad 32 = 196dp.
      expect(
        viewport.height,
        greaterThanOrEqualTo(196),
        reason:
            'at 390x844 the app leaves 193dp (844 - 47 status - 52 nav - 468 '
            'pager - 84 CTA), so the body block is clipped by the pager/CTA '
            'and the body-to-CTA gap is ~20dp against the design 54-74dp.',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-1
  );

  // ---------------------------------------------------------------------
  // P02-BUG-2 (MAJOR) — card-1 rows are 60dp instead of the design's 38dp,
  // so every preview title ellipsises on device ("Empty th…", "Put the bi…").
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-2 card-1 preview rows match the design 38dp .pv-row',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      final rows = find.descendant(
        of: _cardOne(),
        matching: find.byType(NestListRow),
      );
      expect(rows, findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        expect(
          tester.getSize(rows.at(i)).height,
          lessThanOrEqualTo(40),
          reason:
              'design .pv-row is 38dp (36 tile, 15/20 + 13/18, no vertical '
              'row padding, 8dp gaps). The 60dp row spends the extra width on '
              'a 40 tile / 12 gaps / larger pill and truncates every title '
              '(device screenshot docs/screens/P02/ui/app_light_1.png).',
        );
      }

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-2
  );

  // ---------------------------------------------------------------------
  // P02-BUG-3 (MAJOR) — on short devices the fixed stack (47 status + 52 nav
  // + 468 pager + 84 CTA = 651dp) cannot fit: RenderFlex overflows.
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-3a 320x568 at text scale 1.0 has no RenderFlex overflow',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(320, 568));

      expect(
        tester.takeException(),
        isNull,
        reason:
            'fixed regions alone are 651dp > 568dp (RenderFlex overflowed by '
            '83px). 1_plan §a / SPACING_SPEC §10.2 require small portrait '
            'devices to scale down without overflow.',
      );
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(
        viewport.height,
        greaterThan(0),
        reason: 'the step copy must keep a usable viewport on short screens',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-3
  );

  testWidgets(
    'P02-BUG-3b 375x667 at text scale 1.3 has no RenderFlex overflow',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(375, 667), textScale: 1.3);

      expect(
        tester.takeException(),
        isNull,
        reason:
            '47 + 52 + 608.4 + 84 = 791.4dp into a 667dp screen; the app '
            'overflows by 124px (iPhone SE class + large system text).',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-3
  );

  // ---------------------------------------------------------------------
  // P02-BUG-4 (MINOR) — card-1 assignee/repeat copy contradicts Seed.demo
  // (DATA OVER MOCKS; the database value is the spec).
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-4 card-1 rows use the seeded assignee and repeat rule',
    (tester) async {
      final db = await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      const titles = <String>[
        'Empty the dishwasher',
        'Put the bins out',
        'Reading – 20 minutes',
        'Tidy your bedroom',
      ];
      final quests = {
        for (final q in await db.select(db.quests).get()) q.title: q,
      };
      for (final title in titles) {
        final quest = quests[title]!;
        final child = await (db.select(
          db.children,
        )..where((c) => c.id.equals(quest.assigneeChildId!))).getSingle();
        final expected = '${child.nickname} · ${quest.repeatRule}';
        final row = tester.widget<NestListRow>(
          find.ancestor(
            of: find.text(title),
            matching: find.byType(NestListRow),
          ),
        );
        expect(
          row.subtitle,
          expected,
          reason:
              'Seed.demo: $title is ${child.nickname}/${quest.repeatRule}; '
              'the card hard-codes a different assignee/repeat for 3 of its '
              '4 rows (dishwasher weekly, bins Leo once, tidy weekly).',
        );
      }

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-4
  );

  // ---------------------------------------------------------------------
  // P02-BUG-5 (MINOR) — "Sat 4 Oct" is a stale design date: 4 Oct 2026 is a
  // Sunday, not a Saturday (the seed story day is Sat 3 Oct 2026).
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-5 date chip weekday matches its own date',
    (tester) async {
      await setUpTestScope();
      await _pumpTour(tester, surface: const Size(390, 844));

      const pattern =
          r'^(Mon|Tue|Wed|Thu|Fri|Sat|Sun) (\d{1,2}) '
          r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$';
      final regex = RegExp(pattern);
      final labels = tester
          .widgetList<NestChip>(find.byType(NestChip))
          .map((chip) => chip.label)
          .toList();
      final dateLabel = labels.firstWhere(regex.hasMatch);
      final match = regex.firstMatch(dateLabel)!;

      const months = <String, int>{
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final date = DateTime.utc(
        Seed.anchorOverride!.year,
        months[match.group(3)!]!,
        int.parse(match.group(2)!),
      );
      const weekdays = <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ];

      expect(
        match.group(1),
        weekdays[date.weekday - 1],
        reason:
            'DATA OVER MOCKS: the chip hard-codes the design date "$dateLabel"; '
            'in the seeded year ${Seed.anchorOverride!.year} that day is a '
            '${weekdays[date.weekday - 1]}. Derive the chip from the seeded '
            'payout Saturday or drop the date.',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-5
  );

  // ---------------------------------------------------------------------
  // P02-BUG-6 (MINOR) — back from the tour: 1_plan §c says "system back
  // returns to /welcome via the router stack", but P01 uses context.go, which
  // replaces the stack — back pops nothing and exits the app.
  // ---------------------------------------------------------------------
  testWidgets(
    'P02-BUG-6 system back from /value-tour returns to /welcome',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/welcome');
      await tester.tap(find.byKey(const ValueKey('p01_get_started')));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/value-tour');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        currentPath(tester),
        '/welcome',
        reason:
            '1_plan §c promises back returns to /welcome; context.go in '
            'welcome_view.dart replaces the stack, so on Android back exits '
            'the app instead. Push the tour (or handle PopScope in P02).',
      );

      await disposeApp(tester);
    },
    skip: true, // P02-BUG-6
  );
}
