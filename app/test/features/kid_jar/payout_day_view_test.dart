// K10 · Payout day — view tests over the in-memory Drift database.
//
// Scope (stage 2b, UI builder): the design's copy character-by-character, the
// navigation destinations, VoiceOver/TalkBack activation, the empty/error
// frames and the Pip render rule. Design geometry against the real bundled
// Nunito metrics lives in the sibling `payout_day_view_geometry_test.dart`.
//
// Every pumped app ends with `disposeApp` (test_scope.dart). No
// `DateTime.now`, no `google_fonts`, no simulator.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_fund_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_jar_rain.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_note.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';

import '../../test_scope.dart';

const String _route = '/payout-day';

Future<AppDatabase> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  KidJarRepository? repository,
}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await GetIt.instance<AppSession>().refresh();
  if (repository != null) {
    await GetIt.instance.unregister<KidJarRepository>();
    GetIt.instance.registerSingleton<KidJarRepository>(repository);
  }
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return db;
}

/// A repository whose `watchLatestPayout()` hands out a controllable
/// broadcast stream per call, so an error can be forced and retried.
class _ControllablePayoutRepository implements KidJarRepository {
  final List<StreamController<PayoutCelebration?>> payouts =
      <StreamController<PayoutCelebration?>>[];

  final StreamController<JarSnapshot> _jar =
      StreamController<JarSnapshot>.broadcast();

  StreamController<PayoutCelebration?>? get last =>
      payouts.isEmpty ? null : payouts.last;

  @override
  Future<List<JarEntry>> getItems() async => <JarEntry>[];

  @override
  Stream<List<JarEntry>> watchItems() => const Stream<List<JarEntry>>.empty();

  @override
  Stream<JarSnapshot> watchJar() => _jar.stream;

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      const Stream<JarSummary>.empty();

  @override
  Stream<PayoutCelebration?> watchLatestPayout() {
    final controller = StreamController<PayoutCelebration?>.broadcast();
    payouts.add(controller);
    return controller.stream;
  }

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}
}

void main() {
  group('K10 payout-day content (seeded database values, not the mock)', () {
    testWidgets('renders the payout note, the move and the goal maths', (
      tester,
    ) async {
      await _pumpRoute(tester);

      expect(find.text("It's payout day!"), findsOneWidget);
      expect(find.text('Mum marked £3.80 as paid'), findsOneWidget);
      expect(find.text('Pocket money for this week'), findsOneWidget);
      expect(
        find.text('£5.50 went into your Lego Friends set'),
        findsOneWidget,
      );
      expect(find.text('Just like you asked'), findsOneWidget);
      expect(find.text('Lego Friends set'), findsOneWidget);
      expect(find.text('£15.50'), findsOneWidget);
      expect(find.text('£9.49 to go'), findsOneWidget);
      expect(find.text('of £24.99'), findsOneWidget);
      expect(find.text('62% there!'), findsOneWidget);
      expect(find.text('Pip says well done, Maya!'), findsOneWidget);
      expect(find.byType(PayoutJarRain), findsOneWidget);
      expect(find.byType(PayoutNote), findsNWidgets(2));
      expect(find.byType(PayoutFundCard), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a recorded payout re-renders from the same rows', (
      tester,
    ) async {
      final db = await _pumpRoute(tester);
      final money = PocketMoneyRepositoryImpl(db: db);
      await money.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mum marked £4.20 as paid'), findsOneWidget);
      expect(
        find.text('£1.00 went into your Lego Friends set'),
        findsOneWidget,
      );
      expect(find.text('£16.50'), findsOneWidget);
      expect(find.text('£8.49 to go'), findsOneWidget);
      expect(find.text('66% there!'), findsOneWidget);
      expect(find.byType(PayoutNote), findsNWidgets(2));
      await disposeApp(tester);
    });

    testWidgets('Maya renders her own Pip by look and stage, never a v1 SVG', (
      tester,
    ) async {
      await _pumpRoute(tester);

      final pips = tester.widgetList<PipAvatar>(find.byType(PipAvatar));
      expect(pips, hasLength(1));
      expect(pips.single.style, PipStyle.mochi);
      expect(pips.single.skin, PipSkin.sunny);
      expect(pips.single.accessory, PipAccessory.none);
      expect(pips.single.stage, 3);
      expect(pips.single.mood, PipMood.happy);
      expect(pips.single.size, 72);
      await disposeApp(tester);
    });
  });

  group('K10 navigation', () {
    testWidgets('Thanks Mum! ends the celebration back at kid home', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('Thanks Mum!'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('back falls back to kid home with no stack', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestIconButton).first);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
  });

  group('K10 accessibility actions (VoiceOver/TalkBack)', () {
    bool hasTap(WidgetTester tester, Finder finder) => tester
        .getSemantics(finder)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap);

    testWidgets('back, lock and Thanks Mum! advertise and drive taps', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);

      for (final label in <String>['Back', 'Grown-ups', 'Thanks Mum!']) {
        final finder = find.bySemanticsLabel(label).first;
        expect(
          hasTap(tester, finder),
          isTrue,
          reason: '$label must expose SemanticsAction.tap',
        );
      }

      final thanks = tester.getSemantics(
        find.bySemanticsLabel('Thanks Mum!').first,
      );
      thanks.owner!.performAction(thanks.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K10 empty and error frames', () {
    testWidgets('a null payout stream shows the empty state, not a crash', (
      tester,
    ) async {
      final repo = _ControllablePayoutRepository();
      await _pumpRoute(tester, repository: repo);
      repo.last!.add(null);
      await tester.pump();

      expect(find.text('No payout yet'), findsOneWidget);
      expect(
        find.text(
          'When Mum marks your pocket money as paid, the celebration starts here.',
        ),
        findsOneWidget,
      );

      final semantics = tester.ensureSemantics();
      final backHome = tester.getSemantics(
        find.bySemanticsLabel('Back home').first,
      );
      backHome.owner!.performAction(backHome.id, SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a stream error shows the failure shape, and Try again '
        'reloads onto the recovered stream', (tester) async {
      final repo = _ControllablePayoutRepository();
      await _pumpRoute(tester, repository: repo);
      repo.last!.addError(StateError('could not read the jar'));
      await tester.pump();

      expect(find.text('Oh no! Something went wrong.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // Force the retry: the bloc cancels the dead stream and resubscribes;
      // this test's repo now succeeds and shows the seeded celebration.
      await tester.tap(find.text('Try again'));
      await tester.pump();
      repo.last!.add(
        const PayoutCelebration(
          childId: 'maya',
          nickname: 'Maya',
          paidPence: 380,
          movedPence: 550,
          goalTitle: 'Lego Friends set',
          goalSavedPence: 1550,
          goalTargetPence: 2499,
          pipStyle: 'mochi',
          pipSkin: 'sunny',
          pipAccessory: 'none',
          pipStage: 3,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mum marked £3.80 as paid'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      await disposeApp(tester);
    });
  });
}
