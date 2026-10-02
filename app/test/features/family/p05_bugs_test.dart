// P05 · Add children — adversarial bug proofs (Stage 6, iteration 1).
//
// Every test below is a *failing proof* of a real bug found in this stage.
// They carry `skip: true` with the bug id in the test name so `flutter test`
// stays green; the fix stage removes the skip (the proof must then pass). Run
// them with `flutter test --run-skipped test/features/family/p05_bugs_test.dart`.
// Full reports (severity, repro, suggested fix): `docs/screens/P05/6_bugs.md`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/views/add_children_view.dart';

import '../../test_scope.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

const _members = <FamilyMember>[
  FamilyMember(
    id: 'sarah',
    title: 'Sarah',
    detail: 'You',
    name: 'Sarah',
    role: 'owner',
    inviteStatus: 'active',
  ),
];

const _bands = <String>['4-6', '7-9', '10-12', '13+'];

/// Pumps [AddChildrenView] under a minimal router (so the CTA's `go` works)
/// over [bloc] — no GetIt, so tests control the repository directly.
Future<void> _pumpView(WidgetTester tester, FamilyBloc bloc) async {
  final router = GoRouter(
    initialLocation: '/add-children',
    routes: <RouteBase>[
      GoRoute(
        path: '/add-children',
        builder: (_, _) => BlocProvider<FamilyBloc>.value(
          value: bloc,
          child: const AddChildrenView(),
        ),
      ),
      GoRoute(
        path: '/pocket-money-setup',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('P06 placeholder'))),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router, theme: NestTheme.light()),
  );
  await tester.pump();
}

/// Stubs `addChild` with a gate so the in-flight save can be held open.
void _stubGatedAddChild(
  _MockFamilyRepository repo,
  Completer<void> gate,
  void Function() onCall,
) {
  when(
    () => repo.addChild(
      nickname: any(named: 'nickname'),
      ageBand: any(named: 'ageBand'),
      avatarColour: any(named: 'avatarColour'),
    ),
  ).thenAnswer((_) {
    onCall();
    return gate.future;
  });
}

void main() {
  // P05-BUG-1 — interactive NestChip's factorless `Center` claims the whole
  // Wrap run, so the four chips stack; the swatch row is pushed under the
  // bottom CTA. Root cause: core/design_system/components/nest_chip.dart:74.
  group(
    'P05-BUG-1 age chips stack and swatches fall under the CTA (major)',
    () {
      testWidgets(
        '[P05-BUG-1] the four age chips render in one row at 390',
        skip: true,
        (tester) async {
          await setUpTestScope();
          await pumpAppRoute(tester, '/add-children');

          final tops = <double>{
            for (final band in _bands)
              tester.getTopLeft(find.byKey(Key('ageChip-$band'))).dy,
          };
          // Design `.chip-row { display:flex; gap:8px }`: one row of four.
          expect(tops, hasLength(1), reason: 'design shows one row of 4 pills');

          await disposeApp(tester);
        },
      );

      testWidgets(
        '[P05-BUG-1] the avatar swatches are visible and selectable without scrolling',
        skip: true,
        (tester) async {
          await setUpTestScope();
          await pumpAppRoute(tester, '/add-children');

          final viewport = tester.getRect(find.byType(Scrollable).first);
          final swatch = tester.getRect(find.byKey(const Key('swatch-sky')));
          // The form (design: card ends y≈613, CTA starts y≈658) must fit above
          // the fixed CTA: every swatch inside the scroll viewport.
          expect(
            swatch.bottom,
            lessThanOrEqualTo(viewport.bottom),
            reason: 'swatch-sky must be on screen without scrolling',
          );

          await tester.tap(
            find.byKey(const Key('swatch-sky')),
            warnIfMissed: false,
          );
          await tester.pump();
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.label == 'Avatar colour sky' &&
                  w.properties.selected == true,
            ),
            findsOneWidget,
            reason: 'tapping the swatch selects it',
          );

          await disposeApp(tester);
        },
      );
    },
  );

  // P05-BUG-2 — the only double-submit guard is the one-frame-late button
  // rebuild; two taps delivered before that rebuild both reach the bloc.
  group('P05-BUG-2 two taps in one frame double-submit (minor)', () {
    testWidgets(
      '[P05-BUG-2] two "Add another child" taps save once',
      skip: true,
      (tester) async {
        final gate = Completer<void>();
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren)
            .thenAnswer((_) => Stream.value(const <FamilyChild>[]));
        var calls = 0;
        _stubGatedAddChild(repo, gate, () => calls++);
        final bloc = FamilyBloc(repository: repo)
          ..add(const FamilyLoadRequested());

        await _pumpView(tester, bloc);
        await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
        await tester.pump();

        // Both taps before the disabled-state rebuild.
        await tester.tap(find.text('Add another child'));
        await tester.tap(find.text('Add another child'));
        await tester.pump();

        expect(calls, 1, reason: 'one nickname, one insert');
        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.pumpWidget(Container());
        unawaited(bloc.close());
      },
    );

    testWidgets(
      '[P05-BUG-2] "Add another child" then "Continue" in one frame saves once',
      skip: true,
      (tester) async {
        final gate = Completer<void>();
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren)
            .thenAnswer((_) => Stream.value(const <FamilyChild>[]));
        var calls = 0;
        _stubGatedAddChild(repo, gate, () => calls++);
        final bloc = FamilyBloc(repository: repo)
          ..add(const FamilyLoadRequested());

        await _pumpView(tester, bloc);
        await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
        await tester.pump();

        await tester.tap(find.text('Add another child'));
        await tester.tap(find.text('Continue'));
        await tester.pump();

        expect(calls, 1, reason: 'one nickname, one insert');
        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.pumpWidget(Container());
        unawaited(bloc.close());
      },
    );
  });

  // P05-BUG-4 — `emit.forEach(onError:)` never cancels the failed load, so
  // every "Try again" leaks another pair of Drift watchers.
  // (Review finding 3; P08 fixed the same defect as P08-B08.)
  group('P05-BUG-4 retry leaks the failed watcher (minor)', () {
    testWidgets(
      '[P05-BUG-4] Try again releases the failed load before re-subscribing',
      skip: true,
      (tester) async {
        final repo = _MockFamilyRepository();
        var calls = 0;
        var cancels = 0;
        final first = StreamController<List<FamilyMember>>(
          onCancel: () => cancels++,
        );
        addTearDown(() => unawaited(first.close()));
        when(repo.watchItems).thenAnswer((_) {
          calls++;
          return calls == 1 ? first.stream : Stream.value(_members);
        });
        when(repo.watchChildren)
            .thenAnswer((_) => Stream.value(const <FamilyChild>[]));
        final bloc = FamilyBloc(repository: repo)
          ..add(const FamilyLoadRequested());

        await _pumpView(tester, bloc);
        first.add(_members);
        await tester.pump();
        first.addError(Exception('offline'));
        await tester.pump();
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);

        await tester.tap(find.text('Try again'));
        await tester.pump();
        await tester.pump();

        expect(calls, 2, reason: 'the retry starts a fresh subscription');
        expect(cancels, 1, reason: 'the failed load must be cancelled');

        await tester.pumpWidget(Container());
        unawaited(bloc.close());
      },
    );
  });

  // P05-BUG-5 — the save-success listener clears the field unconditionally,
  // wiping anything the parent typed while the insert was in flight.
  group('P05-BUG-5 typing during a save is discarded (minor)', () {
    testWidgets(
      '[P05-BUG-5] text typed while the save spinner runs is preserved',
      skip: true,
      (tester) async {
        final gate = Completer<void>();
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren)
            .thenAnswer((_) => Stream.value(const <FamilyChild>[]));
        _stubGatedAddChild(repo, gate, () {});
        final bloc = FamilyBloc(repository: repo)
          ..add(const FamilyLoadRequested());

        await _pumpView(tester, bloc);
        await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
        await tester.pump();
        await tester.tap(find.text('Add another child'));
        await tester.pump();

        // Spinner is up; the parent starts the next child's nickname.
        await tester.enterText(find.byKey(const Key('nicknameField')), 'Ada');
        await tester.pump();

        gate.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(
          field.controller?.text,
          'Ada',
          reason: 'the in-flight save must not wipe newer typing',
        );

        await tester.pumpWidget(Container());
        unawaited(bloc.close());
      },
    );
  });

  // P05-BUG-6 — `addChild` never sets `ageYears`, so every new child keeps
  // the schema default 7 whatever band was picked.
  group('P05-BUG-6 new children always store ageYears 7 (minor)', () {
    testWidgets(
      '[P05-BUG-6] a 13+ child stores age years inside its band',
      skip: true,
      (tester) async {
        final db = await setUpTestScope(seedDemo: false);
        await Seed.empty(db);
        await pumpAppRoute(tester, '/add-children');

        await tester.enterText(find.byKey(const Key('nicknameField')), 'Zara');
        await tester.pump();
        await tester.tap(find.text('13+'));
        await tester.pump();
        await tester.tap(find.text('Add another child'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final rows = await db.select(db.children).get();
        final zara = rows.singleWhere((r) => r.nickname == 'Zara');
        expect(zara.ageBand, '13+');
        // P08 sorts "eldest first" by ageYears; P15 shows the age.
        expect(
          zara.ageYears,
          greaterThanOrEqualTo(13),
          reason: 'ageYears must agree with the chosen 13+ band',
        );

        await disposeApp(tester);
      },
    );
  });

  // P05-BUG-7 — the h1 is not a semantics header, unlike every other screen
  // heading in the codebase (review finding 7).
  group('P05-BUG-7 heading has no header landmark (minor)', () {
    testWidgets(
      "[P05-BUG-7] Who's in your nest? is exposed as a header",
      skip: true,
      (tester) async {
        final handle = tester.ensureSemantics();
        await setUpTestScope();
        await pumpAppRoute(tester, '/add-children');

        final node = tester.getSemantics(find.text("Who's in your nest?"));
        expect(
          node.getSemanticsData().flagsCollection.isHeader,
          isTrue,
          reason: 'codebase convention: headings are header landmarks',
        );

        handle.dispose();
        await disposeApp(tester);
      },
    );
  });
}
