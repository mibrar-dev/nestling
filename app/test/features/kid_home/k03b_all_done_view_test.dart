// K03b all-done state tests: the shared KidHomeView renders the celebration
// branch when every quest counts as done for the current period, and the
// existing K03 UI stays exactly as-is otherwise. Uses a feature-local fake
// repository (same pattern as kid_home_view_test.dart); every pumped app
// ends with disposeApp.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

import '../../test_scope.dart';

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
);

List<KidQuest> _items(List<String> statuses) => <KidQuest>[
  for (var i = 0; i < statuses.length; i++)
    KidQuest(
      id: 'q$i:maya',
      title: 'Quest $i',
      detail: '',
      questId: 'q$i',
      icon: 'book',
      coins: 10,
      status: statuses[i],
    ),
];

class _Repo extends KidHomeRepository {
  _Repo(this._statuses);

  final List<String> _statuses;

  @override
  Future<List<KidQuest>> getItems() async => _items(_statuses);

  @override
  Stream<List<KidQuest>> watchItems() =>
      Stream<List<KidQuest>>.value(_items(_statuses));

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

Future<void> _useRepo(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-home',
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('KidHomeState.allDone', () {
    test('empty list is false', () {
      const state = KidHomeState();
      expect(state.allDone, isFalse);
    });

    test('partial done is false', () {
      final state = KidHomeState(
        items: _items(<String>[
          'approved',
          'done_pending',
          'approved',
          'done_pending',
          'to_do',
          'to_do',
        ]),
      );
      expect(state.allDone, isFalse);
    });

    test('all approved/done_pending is true', () {
      final state = KidHomeState(
        items: _items(<String>[
          'approved',
          'done_pending',
          'approved',
          'done_pending',
          'approved',
          'done_pending',
        ]),
      );
      expect(state.allDone, isTrue);
    });
  });

  testWidgets('all done renders the K03b branch', (tester) async {
    await setUpTestScope();
    await _useRepo(
      _Repo(<String>[
        'approved',
        'done_pending',
        'approved',
        'done_pending',
        'approved',
        'done_pending',
      ]),
    );
    await _pump(tester);
    expect(find.text('All done!'), findsOneWidget);
    expect(
      find.text('You did everything today! Pip is so proud.'),
      findsOneWidget,
    );
    expect(find.text('6 of 6 done'), findsOneWidget);
    expect(find.text('Visit Pip'), findsOneWidget);
    expect(find.text('Pip is happy today'), findsNothing);
    expect(find.text("Let's do some quests!"), findsNothing);
    expect(find.text('My jar'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('partial keeps the K03 branch untouched', (tester) async {
    await setUpTestScope();
    await _useRepo(
      _Repo(<String>[
        'approved',
        'done_pending',
        'approved',
        'done_pending',
        'to_do',
        'to_do',
      ]),
    );
    await _pump(tester);
    expect(find.text('4 done today'), findsOneWidget);
    expect(find.text('Pip is happy today'), findsOneWidget);
    expect(find.text('My jar'), findsOneWidget);
    expect(find.text('All done!'), findsNothing);
    expect(find.text('Visit Pip'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('Visit Pip exposes a tap action', (tester) async {
    await setUpTestScope();
    await _useRepo(_Repo(<String>['approved', 'approved']));
    await _pump(tester);
    final button = find.descendant(
      of: find.byType(NestKidButton),
      matching: find.text('Visit Pip'),
    );
    expect(button, findsOneWidget);
    final node = tester.getSemantics(button);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await disposeApp(tester);
  });

  testWidgets('320 wide + text scale 1.3 does not overflow', (tester) async {
    await setUpTestScope();
    await _useRepo(
      _Repo(<String>[
        'approved',
        'done_pending',
        'approved',
        'done_pending',
        'approved',
        'done_pending',
      ]),
    );
    await _pump(tester, width: 320, textScale: 1.3);
    expect(find.text('All done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('/kid-home-done renders KidHomeView, not the placeholder', (
    tester,
  ) async {
    await setUpTestScope();
    await _useRepo(
      _Repo(<String>[
        'approved',
        'done_pending',
        'approved',
        'done_pending',
        'approved',
        'done_pending',
      ]),
    );
    await _pump(tester, route: '/kid-home-done');
    expect(find.text('K03b Kid home done'), findsNothing);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('Visit Pip'), findsOneWidget);
    await disposeApp(tester);
  });
}
