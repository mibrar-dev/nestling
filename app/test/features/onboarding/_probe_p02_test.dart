// TEMPORARY probe v3 — not committed. Remaining P02 edge cases.
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';

import '../../test_scope.dart';

Future<void> _pumpTour(WidgetTester tester, {Size surface = const Size(390, 844)}) async {
  await pumpAppRoute(tester, '/value-tour');
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('PROBE dispose mid page animation', (tester) async {
    await setUpTestScope();
    await _pumpTour(tester);
    await tester.tap(find.byKey(const ValueKey('p02_next')));
    await tester.pump(const Duration(milliseconds: 100));
    // Leave mid-animation.
    await disposeApp(tester);
    debugPrint('PROBE dispose mid-animation ok');
  });

  testWidgets('PROBE skip mid page animation', (tester) async {
    await setUpTestScope();
    await _pumpTour(tester);
    await tester.tap(find.byKey(const ValueKey('p02_next')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('p02_skip')));
    await tester.pumpAndSettle();
    debugPrint('PROBE skip mid-animation path=${currentPath(tester)} '
        'exception=${tester.takeException()}');
    await disposeApp(tester);
  });

  testWidgets('PROBE mode flip to kid while on tour', (tester) async {
    await setUpTestScope();
    await _pumpTour(tester);
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
    await tester.pumpAndSettle();
    debugPrint('PROBE kid flip path=${currentPath(tester)}');
    await disposeApp(tester);
  });

  testWidgets('PROBE deep link after onboarding complete', (tester) async {
    await setUpTestScope();
    await GetIt.instance<OnboardingRepository>().completeOnboarding();
    await GetIt.instance<AppSession>().refresh();
    await _pumpTour(tester);
    debugPrint('PROBE post-onboarding deep link path=${currentPath(tester)} '
        'continue=${find.byKey(const ValueKey('p02_next')).evaluate().isNotEmpty}');
    await tester.tap(find.byKey(const ValueKey('p02_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p02_next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('p02_continue')));
    await tester.pumpAndSettle();
    debugPrint('PROBE post-onboarding continue path=${currentPath(tester)}');
    await disposeApp(tester);
  });

  testWidgets('PROBE six children long names', (tester) async {
    final db = await setUpTestScope();
    // Add four more children with the longest plausible UK names.
    for (var i = 3; i <= 6; i++) {
      await db.into(db.children).insert(
        ChildrenCompanion.insert(
          id: 'c$i',
          familyId: Seed.familyId,
          nickname: 'Maximilian-Alexander',
          pipStyle: const Value('bolt'),
          pipSkin: const Value('sky'),
        ),
      );
    }
    await _pumpTour(tester);
    debugPrint('PROBE six children tour renders: '
        'title=${find.text('Set quests in seconds').evaluate().isNotEmpty} '
        'exception=${tester.takeException()}');
    await disposeApp(tester);
  });
}
