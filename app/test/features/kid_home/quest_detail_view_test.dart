// K04 quest-detail view tests: copy, the working checklist, every tap
// destination, the semantics contract (every control exposes
// `SemanticsAction.tap` and drives real state) and the loading / failure /
// no-child / unknown-quest states.
//
// The happy path runs on the real seeded Drift database (`Seed.demo` has
// `q-tidy`, Maya, mochi/sunny Pip); the states a healthy database cannot
// produce (silent stream, stream error, failing write, no active child,
// unknown quest id) use a feature-local fake repository registered over the
// real one, exactly like `kid_home_view_test.dart` does for K03.
//
// Every pumped app ends with `disposeApp` (see test_scope.dart) so Drift's
// deferred stream-close timer is drained.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

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

KidQuest _quest({
  String id = 'q-tidy',
  String title = 'Tidy your bedroom',
  String icon = 'bed',
  int coins = 15,
  String status = 'to_do',
}) {
  return KidQuest(
    id: '$id:maya',
    title: title,
    detail: 'To do · +$coins',
    questId: id,
    icon: icon,
    coins: coins,
    status: status,
  );
}

/// The states a healthy seeded database cannot produce. Mirrors
/// `kid_home_view_test.dart`'s fake: streams rebuilt per `watch…()` call, and
/// a successful [completeQuest] flips the quest and re-emits so the
/// celebration rides the flip exactly as it does on the real repository.
class _FakeKidHomeRepository extends KidHomeRepository {
  _FakeKidHomeRepository({
    this.items = const <KidQuest>[],
    this.child = _maya,
    this.failLoad = false,
    this.hang = false,
    this.failComplete = false,
  });

  List<KidQuest> items;
  KidChild? child;
  bool failLoad;
  bool hang;
  bool failComplete;

  final List<List<String>> completed = <List<String>>[];
  final StreamController<List<KidQuest>> _pushed =
      StreamController<List<KidQuest>>.broadcast();

  @override
  Future<List<KidQuest>> getItems() async => items;

  @override
  Stream<List<KidQuest>> watchItems() {
    if (hang) return const Stream<List<KidQuest>>.empty();
    if (failLoad) return Stream<List<KidQuest>>.error(Exception('items down'));
    return _watchItems();
  }

  Stream<List<KidQuest>> _watchItems() async* {
    yield items;
    yield* _pushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() => Stream<List<KidChild>>.value(
    child == null ? const <KidChild>[] : <KidChild>[child!],
  );

  @override
  Stream<KidChild?> watchActiveChild() {
    if (hang) return const Stream<KidChild?>.empty();
    if (failLoad) {
      return Stream<KidChild?>.error(Exception('child down'));
    }
    return Stream<KidChild?>.value(child);
  }

  @override
  List<String> stepsFor(String questId) {
    return const <String>[
      'Clothes in the basket',
      'Toys in the box',
      'Books on the shelf',
    ];
  }

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(<String>[childId, questId]);
    if (failComplete) throw Exception('save failed');
    items = <KidQuest>[
      for (final quest in items)
        if (quest.questId == questId)
          KidQuest(
            id: quest.id,
            title: quest.title,
            detail: quest.detail,
            questId: quest.questId,
            icon: quest.icon,
            coins: quest.coins,
            status: 'done_pending',
          )
        else
          quest,
    ];
    _pushed.add(items);
  }
}

Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

Future<void> _pump(
  WidgetTester tester, {
  String route = KidHomeRoutePaths.detail,
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

/// Bounded route pumps: `pumpAndSettle` is avoided because a still-loading
/// screen spins an endless progress indicator.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The `.k4-dot` ring at [index] (40 px circle, 3 px ink border).
Finder _dot(int index) => find
    .byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final box = widget.decoration;
      return box is BoxDecoration &&
          box.shape == BoxShape.circle &&
          widget.constraints?.maxHeight == 40;
    })
    .at(index);

Color _dotFill(WidgetTester tester, int index) {
  final box =
      tester.widget<Container>(_dot(index)).decoration! as BoxDecoration;
  return box.color!;
}

/// The cheer Pip's `Semantics` node, matched on its widget label: the node
/// merges with the bubble's text (adjacent label-only siblings), so the
/// rendered label is "Pip cheering you on\nPip is doing a happy dance!" while
/// the design's `alt` is exactly this string.
Finder _cheerSemantics() => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics && widget.properties.label == 'Pip cheering you on',
  description: 'Pip cheer image semantics',
);

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K04 quest detail — the design quest', () {
    testWidgets('renders the title, reward, hint, steps, cheer and buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);

      expect(find.text('Tidy your bedroom'), findsOneWidget);
      expect(find.byType(NestCoinPill), findsOneWidget);
      expect(find.text('+15'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Plus 15 coins'),
        findsOneWidget,
        reason: 'the pill announces the reward, not "+15 coins"',
      );
      expect(
        find.text('Tick each bit off, then press the big button.'),
        findsOneWidget,
      );
      for (final step in <String>[
        'Clothes in the basket',
        'Toys in the box',
        'Books on the shelf',
      ]) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text('Pip is doing a happy dance!'), findsOneWidget);
      expect(find.byType(NestSpeechBubble), findsOneWidget);
      // PIP rule: the child's own Pip (Maya = mochi / sunny / stage 3), drawn
      // as a `PipAvatar` — never a v1 `pip_stage_*.svg` illustration.
      final pip = find.byType(PipAvatar);
      expect(pip, findsOneWidget);
      expect(
        tester.getSize(pip),
        const Size(64, 64),
        reason: 'the design slot is 64 px',
      );
      // The Pip image node and the bubble's text node are adjacent label-only
      // siblings, so the semantics compiler merges them into one node whose
      // label reads "Pip cheering you on\nPip is doing a happy dance!" — the
      // design's `alt` is still announced verbatim (hence the RegExp).
      expect(_cheerSemantics(), findsOneWidget);
      expect(find.text('I did it!'), findsOneWidget);
      expect(find.text('Back'), findsWidgets);
      expect(find.byType(NestKidButton), findsNWidgets(2));

      // A fresh checklist starts unticked (v1 stores no per-quest steps).
      final surface = Theme.of(tester.element(find.byType(NestCoinPill)))
          .extension<NestTokens>()!
          .surface;
      for (var i = 0; i < 3; i++) {
        expect(_dotFill(tester, i), surface, reason: 'dot $i starts unticked');
      }

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the Pip slot uses the child row look', (tester) async {
      await _pump(tester);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.stage, 3);
      await disposeApp(tester);
    });
  });

  group('K04 quest detail — the checklist', () {
    testWidgets('a tap ticks and unticks the ring', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      final leaf = Theme.of(tester.element(find.byType(NestCoinPill)))
          .extension<NestTokens>()!
          .leaf;
      final surface = Theme.of(tester.element(find.byType(NestCoinPill)))
          .extension<NestTokens>()!
          .surface;

      expect(
        find.bySemanticsLabel('Books on the shelf, not ticked'),
        findsOneWidget,
      );
      await tester.tap(find.text('Books on the shelf'));
      await tester.pump();
      expect(_dotFill(tester, 2), leaf);
      expect(
        find.bySemanticsLabel('Books on the shelf, ticked'),
        findsOneWidget,
      );

      await tester.tap(find.text('Books on the shelf'));
      await tester.pump();
      expect(_dotFill(tester, 2), surface);
      expect(
        find.bySemanticsLabel('Books on the shelf, not ticked'),
        findsOneWidget,
      );
      // Ticking is local: it never dispatches a completion.
      expect(
        find.text('I did it!'),
        findsOneWidget,
        reason: 'the primary button is never gated by the checklist',
      );

      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the accessibility action toggles the ring too', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      final leaf = Theme.of(tester.element(find.byType(NestCoinPill)))
          .extension<NestTokens>()!
          .leaf;

      final node = tester.getSemantics(
        find.bySemanticsLabel('Toys in the box, not ticked'),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(
        find.semantics.byLabel('Toys in the box, not ticked'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(_dotFill(tester, 1), leaf);
      expect(find.bySemanticsLabel('Toys in the box, ticked'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('every control exposes a tap action', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      for (final label in <String>[
        'Back',
        'Grown-ups',
        'I did it!',
        'Clothes in the basket, not ticked',
        'Toys in the box, not ticked',
        'Books on the shelf, not ticked',
      ]) {
        final finder = find.bySemanticsLabel(label);
        expect(finder, findsWidgets, reason: '$label must be labelled');
        // 'Back' exists twice (the top row and the bottom bar): every node
        // carrying the label must be operable.
        for (var i = 0; i < finder.evaluate().length; i++) {
          final data = tester.getSemantics(finder.at(i)).getSemanticsData();
          expect(
            data.hasAction(SemanticsAction.tap),
            isTrue,
            reason: '$label must be operable by VoiceOver/TalkBack',
          );
        }
      }
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K04 quest detail — completing', () {
    testWidgets('"I did it!" dispatches once, then celebrates', (tester) async {
      final repo = _FakeKidHomeRepository(items: <KidQuest>[_quest()]);
      await _useFakeRepository(repo);
      await _pump(tester);

      // No pump between the taps: a same-frame double tap must still
      // dispatch exactly one completion (K03-BUG-1/6 pattern).
      await tester.tap(find.text('I did it!'));
      await tester.tap(find.text('I did it!'));
      await _settleRoute(tester);

      expect(repo.completed, <List<String>>[
        <String>['maya', 'q-tidy'],
      ]);
      expect(pushedPath(tester), KidHomeRoutePaths.complete);
      await disposeApp(tester);
    });

    testWidgets('a failing write toasts and stays on the checklist', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(
        items: <KidQuest>[_quest()],
        failComplete: true,
      );
      await _useFakeRepository(repo);
      await _pump(tester);

      await tester.tap(find.text('I did it!'));
      await _settleRoute(tester);

      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      expect(pushedPath(tester), KidHomeRoutePaths.detail);
      await disposeApp(tester);
    });

    testWidgets('an already-done quest disables the primary button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repo = _FakeKidHomeRepository(
        items: <KidQuest>[_quest(status: 'done_pending')],
      );
      await _useFakeRepository(repo);
      await _pump(tester);

      final node = tester.getSemantics(find.bySemanticsLabel('I did it!'));
      final data = node.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);

      await tester.tap(find.text('I did it!'));
      await _settleRoute(tester);
      expect(repo.completed, isEmpty);
      expect(pushedPath(tester), KidHomeRoutePaths.detail);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K04 quest detail — navigation', () {
    testWidgets('the bottom Back goes home on a direct launch', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('Back').last);
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('pushed from home, Back pops back to home', (tester) async {
      await _pump(tester, route: KidHomeRoutePaths.home);
      final context = tester.element(find.byType(Navigator).first);
      unawaited(
        GoRouter.of(context).push(
          KidHomeRoutePaths.detail,
          extra: <String, Object>{'questId': 'q-tidy', 'childId': 'maya'},
        ),
      );
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.detail);

      await tester.tap(find.byType(NestIconButton));
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate', (tester) async {
      await _pump(tester);
      await tester.tap(find.byType(NestLockButton));
      await _settleRoute(tester);
      expect(pushedPath(tester), ParentalGateRoutePaths.gate);
      await disposeApp(tester);
    });

    testWidgets('the route extra selects the quest', (tester) async {
      final repo = _FakeKidHomeRepository(
        items: <KidQuest>[
          _quest(id: 'q-reading', title: 'Reading', icon: 'book', coins: 10),
          _quest(),
        ],
      );
      await _useFakeRepository(repo);
      await _pump(tester, route: KidHomeRoutePaths.home);
      final context = tester.element(find.byType(Navigator).first);
      unawaited(
        GoRouter.of(context).push(
          KidHomeRoutePaths.detail,
          extra: <String, Object>{'questId': 'q-reading', 'childId': 'maya'},
        ),
      );
      await _settleRoute(tester);

      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('Tidy your bedroom'), findsNothing);
      await disposeApp(tester);
    });
  });

  group('K04 quest detail — the other states', () {
    testWidgets('an unknown quest id shows the pick-a-quest state', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(items: <KidQuest>[_quest()]);
      await _useFakeRepository(repo);
      await _pump(tester, route: KidHomeRoutePaths.home);
      final context = tester.element(find.byType(Navigator).first);
      unawaited(
        GoRouter.of(context).push(
          KidHomeRoutePaths.detail,
          extra: <String, Object>{'questId': 'q-gone', 'childId': 'maya'},
        ),
      );
      await _settleRoute(tester);

      expect(find.text('Pick a quest'), findsOneWidget);
      expect(find.text('Choose a quest to see its steps.'), findsOneWidget);
      await tester.tap(find.text('Back home'));
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('no quests at all shows the pick-a-quest state', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository();
      await _useFakeRepository(repo);
      await _pump(tester);
      expect(find.text('Pick a quest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('no active child asks who is playing', (tester) async {
      final repo = _FakeKidHomeRepository(child: null);
      await _useFakeRepository(repo);
      await _pump(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      await tester.tap(find.text('Choose'));
      await _settleRoute(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.picker);
      await disposeApp(tester);
    });

    testWidgets('a silent stream shows the loading state', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = _FakeKidHomeRepository(hang: true);
      await _useFakeRepository(repo);
      await _pump(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading quest'), findsOneWidget);
      // The top row is already there, so nothing jumps when the quest lands.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a broken stream shows Pip lost and reloads on retry', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failLoad: true);
      await _useFakeRepository(repo);
      await _pump(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.text("Let's try again."), findsOneWidget);
      expect(find.byType(PipAvatar), findsOneWidget);

      repo
        ..failLoad = false
        ..items = <KidQuest>[_quest()];
      await tester.tap(find.text('Try again'));
      await _settleRoute(tester);
      expect(find.text('Tidy your bedroom'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('K04 quest detail — copy parity', () {
    testWidgets(
      'every string matches the HTML source character for character',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _pump(tester);
        // `design/html-source/screens/K04-quest-detail.html`: title (DB), the
        // three steps, the hint, the cheer line and the two button labels.
        const expected = <String>[
          'Tick each bit off, then press the big button.',
          'Clothes in the basket, not ticked',
          'Toys in the box, not ticked',
          'Books on the shelf, not ticked',
          'I did it!',
          'Grown-ups',
          'Back',
          'Plus 15 coins',
        ];
        for (final copy in expected) {
          expect(find.bySemanticsLabel(copy), findsWidgets, reason: copy);
        }
        // The cheer line lives in a `Text` (its node merges with the Pip
        // image label above) and the Pip `alt` is a semantics property.
        expect(find.text('Pip is doing a happy dance!'), findsOneWidget);
        expect(_cheerSemantics(), findsOneWidget);
        // No curly quotes, en/em dashes or ellipsis sneak in on this screen.
        expect(
          find.byWidgetPredicate((w) {
            if (w is! Text) return false;
            final value = w.data ?? '';
            return RegExp('[‘’“”–—…]').hasMatch(value);
          }),
          findsNothing,
        );
        semantics.dispose();
        await disposeApp(tester);
      },
    );
  });

  group('K04 quest detail — resilience', () {
    testWidgets('320 px wide at 1.3x text overflows nothing', (tester) async {
      await _pump(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('Tidy your bedroom'), findsOneWidget);
      expect(find.text('Books on the shelf'), findsOneWidget);
      expect(find.text('I did it!'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
