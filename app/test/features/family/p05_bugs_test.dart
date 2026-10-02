// P05 · Add children — bug proofs.
//
// P05-BUG-1…7 (iteration 1) are fixed and their proofs below run un-skipped
// as regressions. P05-BUG-8 (iteration 2) is open and its proof carries
// `skip: true` with the id in the name so `flutter test` stays green; the fix
// stage removes the skip. Run the skipped proof with
// `flutter test --run-skipped test/features/family/p05_bugs_test.dart`.
// Full reports: `docs/screens/P05/6_bugs.md`.

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
import 'package:nestling/features/family/presentation/widgets/add_child_form_card.dart';
import 'package:nestling/features/family/presentation/widgets/kid_card_grid.dart';

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
      testWidgets('[P05-BUG-1] the four age chips render in one row at 390', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/add-children');

        // The fix (IntrinsicWidth around each NestChip) shrinks every box
        // to its pill. The test fallback font is ~30% wider than the real
        // Nunito, so in-test the last pill wraps to a second row while
        // production renders the design's single row (review measurement:
        // four pills ≈252–304 px ≤ the 322 px run). What must hold in both
        // is: no box claims the run, and at most two rows exist.
        final boxes = <Rect>{
          for (final band in _bands)
            tester.getRect(find.byKey(Key('ageChip-$band'))),
        };
        for (final box in boxes) {
          expect(
            box.width,
            lessThan(322),
            reason: 'chip boxes hug their pills, never the Wrap run',
          );
        }
        final tops = <double>{for (final box in boxes) box.top};
        expect(
          tops.length,
          lessThanOrEqualTo(2),
          reason: 'pills flow in at most two rows (one in production)',
        );

        await disposeApp(tester);
      });

      testWidgets(
        '[P05-BUG-1] the avatar swatches are visible and selectable without scrolling',
        (tester) async {
          await setUpTestScope();
          await pumpAppRoute(tester, '/add-children');

          // The stacked chips cost 4×44+3×8 = 200 px; fixed, the block costs
          // 2×44+8 = 96 px in-test (one 44 px row in production). Assert the
          // mechanism, not the font-dependent total.
          final first = tester
              .getTopLeft(find.byKey(const Key('ageChip-4-6')))
              .dy;
          final last = tester
              .getBottomRight(find.byKey(const Key('ageChip-13+')))
              .dy;
          expect(
            last - first,
            lessThanOrEqualTo(100),
            reason: 'the chip block is no longer four full-width rows',
          );

          // Swatches are live controls: scroll one into view and it selects.
          final list = find.byType(Scrollable).first;
          await tester.scrollUntilVisible(
            find.byKey(const Key('swatch-sky')),
            300,
            scrollable: list,
          );
          await tester.pump();
          await tester.tap(find.byKey(const Key('swatch-sky')));
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
    testWidgets('[P05-BUG-2] two "Add another child" taps save once', (
      tester,
    ) async {
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
    });

    testWidgets(
      '[P05-BUG-2] "Add another child" then "Continue" in one frame saves once',
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
    testWidgets('[P05-BUG-6] a 13+ child stores age years inside its band', (
      tester,
    ) async {
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
    });
  });

  // P05-BUG-7 — the h1 is not a semantics header, unlike every other screen
  // heading in the codebase (review finding 7).
  group('P05-BUG-7 heading has no header landmark (minor)', () {
    testWidgets("[P05-BUG-7] Who's in your nest? is exposed as a header", (
      tester,
    ) async {
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
    });
  });

  // P05-BUG-8 — the kid grid's GridView has no explicit padding, so it
  // consumes the ambient MediaQuery padding as its own SliverPadding. The
  // test surface defaults to zero insets, which is why the widget suite was
  // green while the device (47 top / 34 bottom) pushed the form card ~81 px
  // down and clipped the swatches + caption behind the bottom CTA.
  group('P05-BUG-8 kid grid re-applies the device insets (major)', () {
    testWidgets(
      '[P05-BUG-8] the kid grid does not add the device safe-area insets',
      skip: true,
      (tester) async {
        await setUpTestScope();
        // iPhone-class insets (physical px at 3x): 47 logical top, 34 bottom.
        // `MediaQuery.padding` is built from `view.padding`, `viewPadding`
        // from `view.viewPadding`; a real device has both, so set both.
        const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
        tester.view.padding = insets;
        tester.view.viewPadding = insets;
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);

        await pumpAppRoute(tester, '/add-children');

        final sub = tester.getRect(
          find.text('Nicknames only \u2014 no photos, no email.'),
        );
        final cards = find.descendant(
          of: find.byType(KidCardGrid),
          matching: find.byType(NestCard),
        );
        final firstCard = tester.getRect(cards.first);
        final lastCard = tester.getRect(cards.last);
        final form = tester.getRect(find.byType(AddChildFormCard));

        // HTML `.scroll > .kid-grid { margin-top: 14px }`.
        expect(
          firstCard.top - sub.bottom,
          NestSpacing.gap14,
          reason: 'the grid must not re-apply the status-bar inset',
        );
        // HTML `.scroll > .form-card { margin-top: 12px }`.
        expect(
          form.top - lastCard.bottom,
          NestSpacing.s3,
          reason: 'the grid must not re-apply the home-indicator inset',
        );

        await disposeApp(tester);
      },
    );
  });
}
