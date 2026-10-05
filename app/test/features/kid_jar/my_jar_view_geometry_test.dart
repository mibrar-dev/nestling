// K09 · My jar — design geometry.
//
// Isolated from `my_jar_view_test.dart` on purpose: loading the real bundled
// Nunito moves every text metric on the screen (K03's
// `kid_home_geometry_test.dart`, K08's
// `reward_shop_widget_geometry_test.dart` do the same), so the positions below
// are only meaningful next to the real faces.
//
// Every number here was measured off `design/screens/light/K09-jar.png`
// (1170x2532 = 390x844 @3x) and cross-checked against the CSS box model of
// `design/html-source/screens/K09-jar.html`:
//
//   status bar 0…47 · back/lock row 47…107 · scroll viewport 107…810
//   title 107…141 · jar 151…371 · amount 377…421 · "coming on" 423…449
//   goal card 465…618 · "What went in" 634…660 · history card 676…862
//
// Tolerances are ±2 (UI VERDICT RULE); a uniform shift would fail.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_goal_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_history_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_illustration.dart';

import '../../test_scope.dart';

const double _tolerance = 2;

/// `.k9-ico` disc (`K09-jar.html:34`).
final Finder _discFinder = find.descendant(
  of: find.byType(JarHistoryCard),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.maxHeight == 40 &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).shape == BoxShape.circle,
  ),
);

/// Loads the bundled faces so the metrics match a device run — `flutter_test`'s
/// default font is much wider than Nunito, which would wrap the goal title and
/// move every box below it (K08 precedent).
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

Future<void> _pumpJar(WidgetTester tester, {double width = 390}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await GetIt.instance<AppSession>().refresh();
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(const NestlingApp(initialRoute: '/my-jar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void _expectRect(Rect actual, Rect expected, String what) {
  expect(
    actual.left,
    closeTo(expected.left, _tolerance),
    reason: '$what left (design ${expected.left})',
  );
  expect(
    actual.top,
    closeTo(expected.top, _tolerance),
    reason: '$what top (design ${expected.top})',
  );
  expect(
    actual.width,
    closeTo(expected.width, _tolerance),
    reason: '$what width (design ${expected.width})',
  );
  expect(
    actual.height,
    closeTo(expected.height, _tolerance),
    reason: '$what height (design ${expected.height})',
  );
}

void main() {
  setUpAll(_loadBundledFonts);

  testWidgets('the chrome, the jar and both cards sit where the design puts '
      'them', (tester) async {
    await _pumpJar(tester);

    // `.krow-top` (`K09-jar.html:16`): 56 px boxes, 20 px gutters, 4 px below.
    final back = tester.getRect(find.byType(NestIconButton));
    _expectRect(back, const Rect.fromLTWH(20, 47, 56, 56), 'back button');
    final lock = tester.getRect(find.byType(NestLockButton));
    _expectRect(lock, const Rect.fromLTWH(314, 47, 56, 56), 'lock button');

    // `.kid-title.k9-head` (`:47`), centred, 28/34.
    final title = tester.getRect(find.text('My jar'));
    _expectRect(title, const Rect.fromLTWH(20, 107, 350, 34), 'title');

    // `.jar` (`:48`), 186x220 centred under the title.
    final jar = tester.getRect(find.byType(JarIllustration));
    _expectRect(jar, const Rect.fromLTWH(102, 151, 186, 220), 'jar');

    // `.k9-amt .money` 40/44 and `.k9-when` 18/26 (`:68-69`).
    final amount = tester.getRect(find.text('£4.20'));
    expect(amount.top, closeTo(377, _tolerance));
    expect(amount.height, closeTo(44, _tolerance));
    expect(amount.center.dx, closeTo(195, _tolerance));
    final when = tester.getRect(find.text('coming on Saturday'));
    expect(when.top, closeTo(423, _tolerance));
    expect(when.height, closeTo(26, _tolerance));
    expect(when.center.dx, closeTo(195, _tolerance));

    // `.k9-goal` (`:70-81`): 3 px border + 14/16 padding, 153 tall.
    final goal = tester.getRect(find.byType(JarGoalCard));
    _expectRect(goal, const Rect.fromLTWH(20, 465, 350, 153), 'goal card');

    // `.progress.kid` (`:79`): 16 tall, inset 3 + 16 from the card.
    final progress = tester.getRect(find.byType(NestProgress));
    _expectRect(progress, const Rect.fromLTWH(39, 557, 312, 16), 'progress');

    // `h2.kid-title` (`:82`), then `.k9-list` (`:83`).
    final heading = tester.getRect(find.text('What went in'));
    _expectRect(heading, const Rect.fromLTWH(20, 634, 350, 26), 'heading');
    final list = tester.getRect(find.byType(JarHistoryCard));
    expect(list.left, closeTo(20, _tolerance));
    expect(list.top, closeTo(676, _tolerance));
    expect(list.width, closeTo(350, _tolerance));
    // The design's card holds three example rows (3 x 60 + 2 x 2 + 6 = 186);
    // the seed's nine money-in rows make it 562 — the database decides how many
    // rows there are (DATA OVER MOCKS), the design decides the row metrics.
    final rows = _discFinder.evaluate().length;
    expect(list.height, closeTo(rows * 60 + (rows - 1) * 2 + 6, 0.01));
    expect(rows, greaterThanOrEqualTo(3));

    await disposeApp(tester);
  });

  testWidgets('the history rows keep the design metrics', (tester) async {
    await _pumpJar(tester);

    // `.k9-row` min-height 60, `.k9-ico` 40 at 14 px padding inside the card's
    // 3 px border (`K09-jar.html:32,34`).
    final disc = tester.getRect(_discFinder.first);
    _expectRect(disc, const Rect.fromLTWH(37, 689, 40, 40), 'row 1 disc');

    // `.k9-row + .k9-row::before { left: 66px }` (`:33`) — a 2 px line, inset
    // 66 from the row's left edge (69 from the card's outer edge) and running
    // to the card's content edge.
    final inset = find
        .descendant(
          of: find.byType(JarHistoryCard),
          matching: find.byWidgetPredicate(
            (w) => w is Padding && w.padding == const EdgeInsets.only(left: 66),
          ),
        )
        .first;
    final divider = tester.getRect(
      find.descendant(of: inset, matching: find.byType(Container)).first,
    );
    _expectRect(divider, const Rect.fromLTWH(89, 739, 278, 2), 'divider');

    await disposeApp(tester);
  });

  testWidgets('gutters stay 20 at every supported width', (tester) async {
    for (final width in <double>[320, 390, 430]) {
      await _pumpJar(tester, width: width);
      final goal = tester.getRect(find.byType(JarGoalCard));
      expect(goal.left, closeTo(NestSpacing.padSide, _tolerance));
      expect(goal.right, closeTo(width - NestSpacing.padSide, _tolerance));
      final list = tester.getRect(find.byType(JarHistoryCard));
      expect(list.left, closeTo(goal.left, 0.01));
      expect(list.right, closeTo(goal.right, 0.01));
      final jar = tester.getRect(find.byType(JarIllustration));
      expect(jar.center.dx, closeTo(width / 2, _tolerance));
      await disposeApp(tester);
    }
  });
}
