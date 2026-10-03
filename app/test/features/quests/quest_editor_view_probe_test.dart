// TEMPORARY geometry probe — deleted once the numbers are folded into the
// permanent geometry assertions.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

void _dump(WidgetTester tester, String label, Finder finder) {
  final rect = tester.getRect(finder);
  // Temporary probe output goes to the test log for geometry calibration.
  // ignore: avoid_print
  print(
    'GEOM $label: x ${rect.left.toStringAsFixed(1)} '
    'y ${rect.top.toStringAsFixed(1)} w ${rect.width.toStringAsFixed(1)} '
    'h ${rect.height.toStringAsFixed(1)}',
  );
}

void main() {
  setUp(setUpTestScope);

  testWidgets('probe', (tester) async {
    await pumpAppRoute(tester, QuestsRoutePaths.editor);
    _dump(tester, 'statusbar', find.byType(NestStatusBar));
    _dump(tester, 'sheetGrabber(L)', find.byType(DecoratedBox).at(0));
    _dump(tester, 'cancel', find.text('Cancel'));
    _dump(tester, 'title', find.text('New quest'));
    _dump(tester, 'save', find.byType(QuestSavePill));
    _dump(tester, 'fieldLabel', find.text('Quest name'));
    _dump(tester, 'field', find.byType(TextField));
    _dump(tester, 'iconLabel', find.text('Icon'));
    _dump(
      tester,
      'tileBed',
      find.byKey(const ValueKey<String>('quest-icon-bed')),
    );
    _dump(
      tester,
      'tileDishes',
      find.byKey(const ValueKey<String>('quest-icon-dishwasher')),
    );
    _dump(
      tester,
      'tileHoover',
      find.byKey(const ValueKey<String>('quest-icon-hoover')),
    );
    _dump(
      tester,
      'tileBook',
      find.byKey(const ValueKey<String>('quest-icon-book')),
    );
    _dump(
      tester,
      'tileBin',
      find.byKey(const ValueKey<String>('quest-icon-bin')),
    );
    _dump(
      tester,
      'tilePaw',
      find.byKey(const ValueKey<String>('quest-icon-paw')),
    );
    _dump(tester, 'whoLabel', find.text("Who's it for?"));
    _dump(
      tester,
      'pillMaya',
      find.byKey(const ValueKey<String>('quest-assignee-maya')),
    );
    _dump(
      tester,
      'pillLeo',
      find.byKey(const ValueKey<String>('quest-assignee-leo')),
    );
    _dump(
      tester,
      'pillAnyone',
      find.byKey(const ValueKey<String>('quest-assignee-anyone')),
    );
    _dump(tester, 'card0Reward', find.byType(NestCard).at(0));
    _dump(tester, 'card1Approval', find.byType(NestCard).at(1));
    _dump(tester, 'card2Due', find.byType(NestCard).at(2));
    _dump(tester, 'rewardHelper', find.text('= 15p at payout'));
    _dump(tester, 'stepper', find.byType(NestStepper));
    _dump(tester, 'repeatsLabel', find.text('Repeats'));
    _dump(tester, 'segmented', find.byType(NestSegmented<String>));
    _dump(tester, 'dayPicker', find.byType(NestDayPicker));
    _dump(tester, 'day0', find.byKey(const ValueKey<int>(0)));
    _dump(tester, 'day5', find.byKey(const ValueKey<int>(5)));
    _dump(tester, 'day6', find.byKey(const ValueKey<int>(6)));
    _dump(tester, 'toggle', find.byType(NestToggle));
    _dump(tester, 'dueValue', find.text('Before tea (5pm) ›'));
    _dump(tester, 'approvalTitle', find.text('Needs my approval'));
    _dump(tester, 'approvalSub', find.text('Coins land after your thumbs-up'));
    _dump(tester, 'card1Approval', find.byType(NestCard).at(1));
    _dump(tester, 'scrollView', find.byType(SingleChildScrollView));
    await disposeApp(tester);
  });
}
