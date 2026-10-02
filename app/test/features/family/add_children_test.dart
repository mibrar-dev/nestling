import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';
import 'package:nestling/features/family/presentation/views/add_children_view.dart';
import 'package:nestling/features/family/presentation/widgets/add_child_form_card.dart';
import 'package:nestling/features/family/presentation/widgets/child_display.dart';
import 'package:nestling/features/family/presentation/widgets/kid_card_grid.dart';

import '../../test_scope.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

const _maya = FamilyChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  ageYears: 9,
  avatarColour: 'lilac',
  pinSet: true,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  pipTotalCoins: 175,
  coins: 120,
  happiness: 4,
  happyDays: 4,
  weeklyBasePence: 300,
  activeQuests: 6,
  doneQuests: 4,
);

const _leo = FamilyChild(
  id: 'leo',
  nickname: 'Leo',
  ageBand: '4-6',
  ageYears: 6,
  avatarColour: 'peach',
  pinSet: false,
  pipStyle: 'bolt',
  pipSkin: 'sky',
  pipAccessory: 'none',
  pipStage: 2,
  pipTotalCoins: 60,
  coins: 45,
  happiness: 4,
  happyDays: 3,
  weeklyBasePence: 150,
  activeQuests: 4,
  doneQuests: 2,
);

const _kids = <FamilyChild>[_maya, _leo];

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

/// Pumps [AddChildrenView] directly (no router, no shell) over [bloc].
Future<void> _pumpAddChildrenView(
  WidgetTester tester,
  FamilyBloc bloc, {
  ThemeMode theme = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<FamilyBloc>.value(
        value: bloc,
        child: const AddChildrenView(),
      ),
    ),
  );
  await tester.pump();
}

/// Pumps [AddChildrenView] over [bloc] under a minimal router, so the CTA's
/// `go` calls resolve (no GetIt, no shared scope) while the repository stays
/// under the test's control.
Future<void> _pumpAppView(WidgetTester tester, FamilyBloc bloc) async {
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
        builder: (_, _) => const Scaffold(body: Text('P06 placeholder')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(routerConfig: router, theme: NestTheme.light()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The design tokens resolved under the currently pumped subtree.
NestTokens _tokensOf(WidgetTester tester, Finder finder) =>
    Theme.of(tester.element(finder)).extension<NestTokens>()!;

/// Resizes the test surface and applies a text scale, then settles a frame.
Future<void> _resize(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('FamilyBloc roster', () {
    blocTest<FamilyBloc, FamilyState>(
      'load event emits members and children together',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyLoadRequested()),
      expect: () => const <FamilyState>[
        FamilyState(status: FamilyStatus.loading),
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
        ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'stream error emits failure with a message',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer(
          (_) => Stream<List<FamilyChild>>.error(Exception('offline')),
        );
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyLoadRequested()),
      expect: () => [
        const FamilyState(status: FamilyStatus.loading),
        predicate<FamilyState>(
          (s) =>
              s.status == FamilyStatus.failure &&
              (s.errorMessage ?? '').contains('offline'),
        ),
      ],
    );
  });

  group('FamilyBloc draft', () {
    blocTest<FamilyBloc, FamilyState>(
      'draft changes update each field',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      act: (bloc) {
        bloc
          ..add(const FamilyDraftChanged(nickname: 'Ollie'))
          ..add(const FamilyDraftChanged(ageBand: '10-12'))
          ..add(const FamilyDraftChanged(avatarColour: 'sky'));
      },
      expect: () => const <FamilyState>[
        FamilyState(draftNickname: 'Ollie'),
        FamilyState(draftNickname: 'Ollie', draftAgeBand: '10-12'),
        FamilyState(
          draftNickname: 'Ollie',
          draftAgeBand: '10-12',
          draftAvatarColour: 'sky',
        ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'editing the nickname clears the inline error',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      seed: () => const FamilyState(nicknameError: 'Give them a nickname'),
      act: (bloc) => bloc.add(const FamilyDraftChanged(nickname: 'O')),
      expect: () => const <FamilyState>[FamilyState(draftNickname: 'O')],
    );
  });

  group('FamilyBloc add child', () {
    blocTest<FamilyBloc, FamilyState>(
      'empty nickname shows an inline error and never saves',
      build: () {
        final repo = _MockFamilyRepository();
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(FamilyAddChildRequested(onSaved: () {})),
      expect: () => const <FamilyState>[
        FamilyState(nicknameError: 'Give them a nickname'),
      ],
    );

    test('empty nickname never calls addChild', () async {
      final repo = _MockFamilyRepository();
      final bloc = FamilyBloc(repository: repo)
        ..add(FamilyAddChildRequested(onSaved: () {}));
      await bloc.stream.firstWhere(
        (s) => s.nicknameError == 'Give them a nickname',
      );
      verifyNever(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      );
      await bloc.close();
    });

    blocTest<FamilyBloc, FamilyState>(
      'valid nickname saves trimmed with the draft band and colour',
      build: () {
        final repo = _MockFamilyRepository();
        when(
          () => repo.addChild(
            nickname: any(named: 'nickname'),
            ageBand: any(named: 'ageBand'),
            avatarColour: any(named: 'avatarColour'),
          ),
        ).thenAnswer((_) async {});
        return FamilyBloc(repository: repo);
      },
      seed: () => const FamilyState(
        draftNickname: '  Ollie ',
        draftAgeBand: '4-6',
        draftAvatarColour: 'sky',
      ),
      act: (bloc) => bloc.add(FamilyAddChildRequested(onSaved: () {})),
      expect: () => const <FamilyState>[
        FamilyState(
          draftNickname: '  Ollie ',
          draftAgeBand: '4-6',
          draftAvatarColour: 'sky',
          saveInProgress: true,
        ),
        FamilyState(
          draftAgeBand: '4-6',
          draftAvatarColour: 'sky',
          lastSavedNickname: 'Ollie',
        ),
      ],
      verify: (bloc) {
        // The bloc under test owns the mock; fetch it back via closure.
        expect(bloc.state.draftNickname, isEmpty);
        expect(bloc.state.draftAgeBand, '4-6');
        expect(bloc.state.draftAvatarColour, 'sky');
      },
    );

    test('valid nickname calls addChild trimmed', () async {
      final repo = _MockFamilyRepository();
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) async {});
      var saved = false;
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyDraftChanged(nickname: '  Ollie '))
        ..add(const FamilyDraftChanged(ageBand: '4-6'))
        ..add(const FamilyDraftChanged(avatarColour: 'sky'))
        ..add(FamilyAddChildRequested(onSaved: () => saved = true));
      await bloc.stream.firstWhere(
        (s) => !s.saveInProgress && s.draftNickname.isEmpty,
      );
      verify(
        () => repo.addChild(
          nickname: 'Ollie',
          ageBand: '4-6',
          avatarColour: 'sky',
        ),
      ).called(1);
      expect(saved, isTrue);
      await bloc.close();
    });

    blocTest<FamilyBloc, FamilyState>(
      'over-long nickname shows a length error and never saves',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      seed: () => FamilyState(draftNickname: 'A' * 25),
      act: (bloc) => bloc.add(FamilyAddChildRequested(onSaved: () {})),
      expect: () => [
        FamilyState(
          draftNickname: 'A' * 25,
          nicknameError: 'Keep it under 24 characters',
        ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'save failure keeps the form and explains inline',
      build: () {
        final repo = _MockFamilyRepository();
        when(
          () => repo.addChild(
            nickname: any(named: 'nickname'),
            ageBand: any(named: 'ageBand'),
            avatarColour: any(named: 'avatarColour'),
          ),
        ).thenThrow(Exception('offline'));
        return FamilyBloc(repository: repo);
      },
      seed: () => const FamilyState(draftNickname: 'Ollie'),
      act: (bloc) => bloc.add(FamilyAddChildRequested(onSaved: () {})),
      expect: () => const <FamilyState>[
        FamilyState(draftNickname: 'Ollie', saveInProgress: true),
        FamilyState(
          draftNickname: 'Ollie',
          nicknameError: 'Something went wrong \u2014 try again',
        ),
      ],
    );
  });

  group('FamilyBloc helpers', () {
    test('avatar colours map to the design-system swatches', () {
      expect(avatarColourFor('lilac'), NestAvatarColor.lilac);
      expect(avatarColourFor('peach'), NestAvatarColor.peach);
      expect(avatarColourFor('sky'), NestAvatarColor.sky);
      expect(avatarColourFor('leaf'), NestAvatarColor.leaf);
      expect(avatarColourFor('coin'), NestAvatarColor.coin);
      expect(avatarColourFor('mystery'), NestAvatarColor.neutral);
    });

    test('age bands render with an en-dash', () {
      expect(displayAgeBand('4-6'), '4\u20136');
      expect(displayAgeBand('7-9'), '7\u20139');
      expect(displayAgeBand('10-12'), '10\u201312');
      expect(displayAgeBand('13+'), '13+');
    });
  });

  group('FamilyBloc state', () {
    test('defaults match the design draft', () {
      const state = FamilyState();
      expect(state.status, FamilyStatus.initial);
      expect(state.items, isEmpty);
      expect(state.children, isEmpty);
      expect(state.draftNickname, isEmpty);
      expect(state.draftAgeBand, '7-9');
      expect(state.draftAvatarColour, 'peach');
      expect(state.nicknameError, isNull);
      expect(state.saveInProgress, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith keeps the inline error when the field is omitted', () {
      const state = FamilyState(nicknameError: 'Give them a nickname');
      final kept = state.copyWith(draftAgeBand: '4-6');
      expect(kept.nicknameError, 'Give them a nickname');
      expect(kept.draftAgeBand, '4-6');
      final cleared = state.copyWith(nicknameError: null);
      expect(cleared.nicknameError, isNull);
    });

    test('copyWith leaves untouched fields alone', () {
      const state = FamilyState(
        children: _kids,
        items: _members,
        draftNickname: 'Ollie',
        draftAgeBand: '4-6',
        draftAvatarColour: 'sky',
        saveInProgress: true,
        errorMessage: 'offline',
      );
      expect(
        state.copyWith(status: FamilyStatus.loaded).draftNickname,
        'Ollie',
      );
      expect(
        state.copyWith(status: FamilyStatus.loaded).saveInProgress,
        isTrue,
      );
      expect(state.copyWith().status, FamilyStatus.initial);
      expect(state.copyWith(), state);
    });
  });

  group('FamilyBloc draft events', () {
    blocTest<FamilyBloc, FamilyState>(
      'a partial draft change leaves the other fields alone',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      seed: () => const FamilyState(
        draftNickname: 'Ollie',
        draftAgeBand: '4-6',
        draftAvatarColour: 'sky',
      ),
      act: (bloc) => bloc.add(const FamilyDraftChanged(ageBand: '13+')),
      expect: () => const <FamilyState>[
        FamilyState(
          draftNickname: 'Ollie',
          draftAgeBand: '13+',
          draftAvatarColour: 'sky',
        ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'an empty draft change emits nothing',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      seed: () => const FamilyState(draftNickname: 'Ollie'),
      act: (bloc) => bloc.add(const FamilyDraftChanged()),
      expect: () => const <FamilyState>[],
    );

    blocTest<FamilyBloc, FamilyState>(
      'changing the age band does not clear the inline error',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      seed: () => const FamilyState(nicknameError: 'Give them a nickname'),
      act: (bloc) => bloc.add(const FamilyDraftChanged(ageBand: '4-6')),
      expect: () => const <FamilyState>[
        FamilyState(draftAgeBand: '4-6', nicknameError: 'Give them a nickname'),
      ],
    );
  });

  group('FamilyBloc roster streams', () {
    test('a later roster emission replaces the cards', () async {
      final controller = StreamController<List<FamilyChild>>();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => controller.stream);
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      controller.add(const <FamilyChild>[]);
      await bloc.stream.firstWhere((s) => s.status == FamilyStatus.loaded);
      expect(bloc.state.children, isEmpty);

      controller.add(_kids);
      await bloc.stream.firstWhere((s) => s.children.isNotEmpty);
      expect(bloc.state.children, _kids);

      controller.add(<FamilyChild>[_leo]);
      await bloc.stream.firstWhere((s) => s.children.length == 1);
      expect(bloc.state.children, <FamilyChild>[_leo]);

      await controller.close();
      await bloc.close();
    });
  });

  group('FamilyBloc save guards', () {
    blocTest<FamilyBloc, FamilyState>(
      'a 24-character nickname is accepted (boundary)',
      build: () {
        final repo = _MockFamilyRepository();
        when(
          () => repo.addChild(
            nickname: any(named: 'nickname'),
            ageBand: any(named: 'ageBand'),
            avatarColour: any(named: 'avatarColour'),
          ),
        ).thenAnswer((_) async {});
        return FamilyBloc(repository: repo);
      },
      seed: () => FamilyState(draftNickname: 'A' * 24),
      act: (bloc) => bloc.add(FamilyAddChildRequested(onSaved: () {})),
      expect: () => [
        FamilyState(draftNickname: 'A' * 24, saveInProgress: true),
        FamilyState(lastSavedNickname: 'A' * 24),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'a whitespace-only nickname is rejected like an empty one',
      build: () => FamilyBloc(repository: _MockFamilyRepository()),
      seed: () => const FamilyState(draftNickname: '   '),
      act: (bloc) => bloc.add(FamilyAddChildRequested(onSaved: () {})),
      expect: () => const <FamilyState>[
        FamilyState(
          draftNickname: '   ',
          nicknameError: 'Give them a nickname',
        ),
      ],
    );

    test('onSaved never runs when the repository throws', () async {
      final repo = _MockFamilyRepository();
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenThrow(Exception('offline'));
      var saved = false;
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyDraftChanged(nickname: 'Ollie'))
        ..add(FamilyAddChildRequested(onSaved: () => saved = true));
      await bloc.stream.firstWhere((s) => s.nicknameError != null);
      expect(saved, isFalse);
      await bloc.close();
    });

    test('a second save reuses the band and colour of the first', () async {
      final repo = _MockFamilyRepository();
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) async {});
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyDraftChanged(nickname: 'Ollie'))
        ..add(const FamilyDraftChanged(ageBand: '13+'))
        ..add(const FamilyDraftChanged(avatarColour: 'coin'))
        ..add(FamilyAddChildRequested(onSaved: () {}));
      await bloc.stream.firstWhere((s) => s.draftNickname.isEmpty);
      bloc
        ..add(const FamilyDraftChanged(nickname: 'Ada'))
        ..add(FamilyAddChildRequested(onSaved: () {}));
      await bloc.stream.firstWhere((s) => s.draftNickname.isEmpty);

      verify(
        () => repo.addChild(
          nickname: 'Ollie',
          ageBand: '13+',
          avatarColour: 'coin',
        ),
      ).called(1);
      verify(
        () => repo.addChild(
          nickname: 'Ada',
          ageBand: '13+',
          avatarColour: 'coin',
        ),
      ).called(1);
      await bloc.close();
    });
  });

  group('P05 Add children (light, demo seed)', () {
    testWidgets('shows the roster cards, form defaults and bottom CTA', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
      expect(
        find.text('Nicknames only \u2014 no photos, no email.'),
        findsOneWidget,
      );
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Age 7\u20139'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('Age 4\u20136'), findsOneWidget);
      // The pencil label merges with the card text in one node (design-system
      // convention, as on P08 rows).
      expect(find.bySemanticsLabel(RegExp('Edit Maya')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Edit Leo')), findsOneWidget);

      expect(find.text('Add a child'), findsOneWidget);
      expect(find.text('e.g. Ollie'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is NestChip && w.label == '7\u20139' && w.selected,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Avatar colour peach' &&
              w.properties.selected == true,
        ),
        findsOneWidget,
      );
      expect(
        find.text('We only ask for an age range so quests suit them.'),
        findsOneWidget,
      );
      expect(find.text('Add another child'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(
        find.text('You can change any of this later in Family.'),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('edit opens the child profile with its childId', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.tap(find.byKey(const Key('editChild-maya')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('P15 Child profile'), findsOneWidget);
      expect(currentPath(tester), '/child-profile');
      expect(
        GoRouter.of(tester.element(find.text('P15 Child profile')))
            .state
            .uri
            .queryParameters['childId'],
        'maya',
      );

      await disposeApp(tester);
    });

    testWidgets('age chips are single-select', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      // Scroll the chip clear of the bottom CTA first — with the demo seed the
      // stacked chip rows put 10–12 under the CTA (P05-BUG-1, 6_bugs.md), and
      // a tap at its position lands on the CTA instead.
      await tester.scrollUntilVisible(
        find.text('10\u201312'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('10\u201312'));
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is NestChip && w.label == '10\u201312' && w.selected,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is NestChip && w.label == '7\u20139' && w.selected,
        ),
        findsNothing,
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('swatch tap moves the selection ring', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

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
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('add-another with a nickname saves and clears the field', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ollie'), findsOneWidget);
      expect(find.text('Age 7\u20139'), findsNWidgets(2));
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.controller?.text, isEmpty);
      expect(currentPath(tester), '/add-children');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('add-another with an empty field shows an inline error', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.tap(find.text('Add another child'));
      await tester.pump();

      expect(find.text('Give them a nickname'), findsOneWidget);
      expect(currentPath(tester), '/add-children');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('continue with an empty field goes straight to setup', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/add-children');

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/pocket-money-setup');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('continue with a nickname saves it, then goes to setup', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/add-children');

      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/pocket-money-setup');

      final rows = await db.select(db.children).get();
      expect(rows.map((r) => r.nickname), contains('Ollie'));

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('back goes to privacy', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/privacy');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 Add children empty (fresh seed)', () {
    testWidgets('form-only layout with no kid cards', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/add-children');

      expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
      expect(find.text('Add a child'), findsOneWidget);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Leo'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 Add children (dark)', () {
    testWidgets('same content renders in dark mode', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children', theme: ThemeMode.dark);

      expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Add a child'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 Add children states', () {
    testWidgets('loading shows the spinner', (tester) async {
      final repo = _MockFamilyRepository();
      when(repo.watchItems)
          .thenAnswer((_) => const Stream<List<FamilyMember>>.empty());
      when(repo.watchChildren)
          .thenAnswer((_) => const Stream<List<FamilyChild>>.empty());
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Who\u2019s in your nest?'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure shows the reason and Try again recovers', (
      tester,
    ) async {
      final repo = _MockFamilyRepository();
      var attempts = 0;
      when(repo.watchItems).thenAnswer((_) {
        attempts++;
        return attempts == 1
            ? Stream<List<FamilyMember>>.error(Exception('offline'))
            : Stream.value(_members);
      });
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      await tester.pump();

      expect(find.text('Exception: offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure renders in dark theme too', (tester) async {
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer(
        (_) => Stream<List<FamilyMember>>.error(Exception('offline')),
      );
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc, theme: ThemeMode.dark);
      await tester.pump();

      expect(find.text('Exception: offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('P05 sizes', () {
    testWidgets('no overflow at 320 wide + text scale 1.3', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');
      await _resize(tester, 320, 1.3);

      expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);

      final list = find.byType(Scrollable).first;
      for (final label in <String>[
        'Leo',
        'Add a child',
        'Age band',
        'Avatar colour',
        'We only ask for an age range so quests suit them.',
      ]) {
        await tester.scrollUntilVisible(
          find.text(label),
          300,
          scrollable: list,
        );
        await tester.pump();
      }

      // The bottom CTA is fixed outside the scroll: it must still lay out
      // (buttons grow with text scale) without overflowing.
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final scale in <double>[1, 1.3]) {
      for (final width in <double>[320, 390, 430]) {
        testWidgets('lays out at ${width.toInt()} wide, text scale $scale', (
          tester,
        ) async {
          await setUpTestScope();
          await pumpAppRoute(tester, '/add-children');
          await _resize(tester, width, scale);

          expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
          expect(find.text('Maya'), findsOneWidget);
          expect(find.text('Add a child'), findsOneWidget);

          final list = find.byType(Scrollable).first;
          for (final label in <String>[
            'Leo',
            'Age band',
            'Avatar colour',
            'We only ask for an age range so quests suit them.',
          ]) {
            await tester.scrollUntilVisible(
              find.text(label),
              300,
              scrollable: list,
            );
            await tester.pump();
          }

          // Fixed bottom CTA survives every width/scale combination.
          expect(find.text('Add another child'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(
            find.text('You can change any of this later in Family.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);

          await disposeApp(tester);
        });
      }
    }
  });

  // Owner rule: consistent 20 px gutters, cards and bars on the same edges.
  group('P05 alignment (owner rule)', () {
    for (final width in <double>[320, 390, 430]) {
      testWidgets('every band shares the ${width.toInt()}px gutters', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/add-children');
        await _resize(tester, width, 1);

        final head = tester.getRect(find.text('Who\u2019s in your nest?'));
        final grid = tester.getRect(find.byType(KidCardGrid));
        final formCard = tester.getRect(find.byType(NestCard).last);
        final addAnother = tester.getRect(
          find.byKey(const Key('addAnotherButton')),
        );
        final caption = tester.getRect(
          find.text('You can change any of this later in Family.'),
        );

        for (final rect in <Rect>[head, grid, formCard, addAnother, caption]) {
          expect(
            rect.left,
            NestSpacing.padSide,
            reason: 'left gutter at $width',
          );
          expect(
            rect.right,
            width - NestSpacing.padSide,
            reason: 'right gutter at $width',
          );
        }
        // Form card and CTA panel share the horizontal edges exactly.
        expect(formCard.left, addAnother.left);
        expect(formCard.right, addAnother.right);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the kid grid hugs two computed columns and keeps the pencil '
        'inside its card', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');
      await _resize(tester, 320, 1);

      final cards = find.descendant(
        of: find.byType(KidCardGrid),
        matching: find.byType(NestCard),
      );
      expect(cards, findsNWidgets(2));
      final first = tester.getRect(cards.first);
      final second = tester.getRect(cards.last);
      // (W - 20 - 20 - 10) / 2, never a hard-coded 170.
      expect(first.width, (320 - 40 - 10) / 2);
      expect(second.left, first.right + NestSpacing.gap10);
      expect(second.right, 320 - NestSpacing.padSide);

      final pencil = tester.getRect(find.byKey(const Key('editChild-maya')));
      expect(second.contains(pencil.topLeft), isTrue);
      expect(second.contains(pencil.bottomRight), isTrue);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // Owner rule: the area under a bottom bar keeps the bar's surface colour.
  group('P05 bottom edge (owner rule)', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in <double>[320, 390, 430]) {
        testWidgets('the CTA panel runs to the physical edge in $theme at '
            '${width.toInt()}px', (tester) async {
          await setUpTestScope();
          await pumpAppRoute(tester, '/add-children', theme: theme);
          await _resize(tester, width, 1);

          final view = tester.view.physicalSize / tester.view.devicePixelRatio;
          final cta = tester.getRect(find.byType(NestBottomCta));
          // No strip below the bar: the panel's bottom edge is the screen edge.
          expect(cta.bottom, view.height);
          expect(cta.left, 0);
          expect(cta.right, view.width);

          final panel = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: find.byType(NestBottomCta),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          final colour = (panel.decoration as BoxDecoration).color!;
          final tokens = _tokensOf(tester, find.byType(NestBottomCta));
          final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
          // The panel must carry the surface token, and it must differ from the
          // page tint so a short bar would be visibly wrong, not invisible.
          expect(colour, tokens.surface);
          expect(scaffold.backgroundColor, tokens.paper);
          expect(colour, isNot(tokens.paper));

          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        });
      }
    }
  });

  // Tap targets: >= 44 in parent mode (NestDevice.tapParent).
  group('P05 tap targets', () {
    testWidgets('every interactive control is at least 44px', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      void atLeast44(Size size, String what) {
        expect(
          size.width,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '$what width',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '$what height',
        );
      }

      atLeast44(
        tester.getSize(find.bySemanticsLabel('Back').first),
        'nav back',
      );
      atLeast44(
        tester.getSize(find.byKey(const Key('editChild-maya'))),
        'edit pencil (Maya)',
      );
      atLeast44(
        tester.getSize(find.byKey(const Key('editChild-leo'))),
        'edit pencil (Leo)',
      );
      for (final band in AddChildFormCard.ageBands) {
        atLeast44(
          tester.getSize(find.byKey(Key('ageChip-$band'))),
          'age chip $band',
        );
      }
      for (final colour in AddChildFormCard.swatchColours) {
        final size = tester.getSize(find.byKey(Key('swatch-$colour')));
        expect(size.width, NestDevice.tapParent, reason: 'swatch $colour');
        expect(size.height, NestDevice.tapParent, reason: 'swatch $colour');
      }

      expect(
        tester.getSize(find.byKey(const Key('addAnotherButton'))).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(const Key('continueButton'))).height,
        greaterThanOrEqualTo(NestDevice.tapParent * 1 + 8),
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the failure panel Try again button is a 44+ target', (
      tester,
    ) async {
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer(
        (_) => Stream<List<FamilyMember>>.error(Exception('offline')),
      );
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      await tester.pump();

      final retry = find.byType(NestButton);
      expect(retry, findsOneWidget);
      final size = tester.getSize(retry);
      expect(size.width, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(tester.takeException(), isNull);
    });
  });

  group('P05 semantics', () {
    testWidgets('the whole form is interactive in dark mode', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children', theme: ThemeMode.dark);

      // Chips select in dark too (design: one row, 7–9 selected by default).
      await tester.tap(find.text('13+'));
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is NestChip && w.label == '13+' && w.selected,
        ),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('swatch-coin')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('swatch-coin')));
      await tester.pump();
      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('swatch-coin')))
            .properties
            .selected,
        isTrue,
      );

      // The selection ring is the ink token (light in dark mode), exactly like
      // the dark design's `box-shadow: 0 0 0 3px var(--ink)`.
      final tokens = _tokensOf(tester, find.byType(NestBottomCta));
      expect(tokens.isDark, isTrue);
      final shadows = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byKey(const Key('swatch-coin')),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .expand((d) => d.boxShadow ?? const <BoxShadow>[])
          .toList();
      expect(shadows, hasLength(1));
      expect(shadows.single.color, tokens.ink);
      expect(shadows.single.spreadRadius, NestSpacing.gap3);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('icon buttons are labelled and act on an accessibility tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      // Every icon-only control carries a label. The pencil label merges with
      // the card text into one node (design-system convention, as on P08 rows),
      // so match it as a pattern.
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Edit Maya')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Edit Leo')), findsOneWidget);
      for (final colour in AddChildFormCard.swatchColours) {
        expect(find.bySemanticsLabel('Avatar colour $colour'), findsOneWidget);
      }
      // The nickname field is a labelled text field with the Done action.
      expect(find.bySemanticsLabel(RegExp('Nickname')), findsWidgets);
      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.textInputAction, TextInputAction.done);
      expect(field.controller, isNotNull);

      // Tapping through the semantics tree navigates like a pointer tap.
      final editLeo = tester.getSemantics(
        find.byKey(const Key('editChild-leo')),
      );
      expect(editLeo.label, contains('Edit Leo'));
      await tester.tap(find.byKey(const Key('editChild-leo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/child-profile');
      expect(
        GoRouter.of(tester.element(find.text('P15 Child profile')))
            .state
            .uri
            .queryParameters['childId'],
        'leo',
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('chips expose their selected state', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      NestChip chip(String band) =>
          tester.widget<NestChip>(find.byKey(Key('ageChip-$band')));
      expect(chip('7-9').selected, isTrue);
      expect(chip('4-6').selected, isFalse);

      final selected = tester.widget<Semantics>(
        find.byKey(const Key('swatch-peach')),
      );
      expect(selected.properties.selected, isTrue);
      final other = tester.widget<Semantics>(
        find.byKey(const Key('swatch-sky')),
      );
      expect(other.properties.selected, isFalse);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 save states', () {
    testWidgets('both buttons disable and Continue spins while saving', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) => gate.future);
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();

      expect(
        tester
            .widget<NestButton>(find.byKey(const Key('addAnotherButton')))
            .onPressed,
        isNull,
      );
      final continueButton = tester.widget<NestButton>(
        find.byKey(const Key('continueButton')),
      );
      expect(continueButton.loading, isTrue);
      expect(continueButton.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // A tap in the next frame cannot submit a second time: the guard is the
      // disabled button, not a bloc lock (see 3_test.md, bug P05-BUG-2 for
      // the sub-frame window that still gets through).
      await tester.tap(find.text('Add another child'), warnIfMissed: false);
      await tester.pump();
      verify(
        () => repo.addChild(
          nickname: 'Ollie',
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).called(1);

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.getSize(find.byKey(const Key('continueButton'))).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tester
            .widget<NestButton>(find.byKey(const Key('addAnotherButton')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed save keeps the field and explains inline', (
      tester,
    ) async {
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenThrow(Exception('offline'));
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Something went wrong \u2014 try again'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'Ollie',
      );
      expect(
        tester
            .widget<NestButton>(find.byKey(const Key('addAnotherButton')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    for (final (input, message) in <(String, String)>[
      ('   ', 'Give them a nickname'),
      ('A' * 25, 'Keep it under 24 characters'),
    ]) {
      testWidgets('rejects "${input.trim()}" inline', (tester) async {
        final db = await setUpTestScope(seedDemo: false);
        await Seed.fresh(db);
        await pumpAppRoute(tester, '/add-children');
        await tester.enterText(find.byKey(const Key('nicknameField')), input);
        await tester.pump();
        await tester.tap(find.text('Add another child'));
        await tester.pump();

        expect(find.text(message), findsOneWidget);
        expect(currentPath(tester), '/add-children');
        final rows = await db.select(db.children).get();
        expect(rows, isEmpty);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('P05 against the real repository', () {
    testWidgets('a saved child lands in the database with the trimmed draft', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.enterText(
        find.byKey(const Key('nicknameField')),
        '  Ollie  ',
      );
      await tester.pump();
      // Scroll the chip clear of the bottom CTA first — with the demo seed the
      // stacked chip rows put 10–12 under the CTA (P05-BUG-1, 6_bugs.md).
      await tester.scrollUntilVisible(
        find.text('10\u201312'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.text('10\u201312'));
      await tester.pump();
      // Scroll the swatches clear of the bottom CTA before tapping — with the
      // demo seed they currently sit under it (P05-BUG-1, 3_test.md), and a
      // tap at their position lands on the CTA and fires Continue instead.
      await tester.scrollUntilVisible(
        find.byKey(const Key('swatch-sky')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('swatch-sky')));
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final rows = await db.select(db.children).get();
      final ollie = rows.where((r) => r.nickname == 'Ollie').toList();
      expect(ollie, hasLength(1));
      expect(ollie.single.ageBand, '10-12');
      expect(ollie.single.avatarColour, 'sky');
      // The roster stream repaints the grid without a reload.
      expect(find.text('Ollie'), findsOneWidget);
      expect(find.text('Age 10\u201312'), findsOneWidget);
      expect(currentPath(tester), '/add-children');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a fifth child wraps onto a third row without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (final name in <String>['One', 'Two', 'Three']) {
        await tester.enterText(find.byKey(const Key('nicknameField')), name);
        await tester.pump();
        await tester.tap(find.text('Add another child'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      final cards = find.descendant(
        of: find.byType(KidCardGrid),
        matching: find.byType(NestCard),
      );
      expect(cards, findsNWidgets(5));
      final grid = tester.getRect(find.byType(KidCardGrid));
      // 3 rows x 124 + 2 x 10 spacing.
      expect(grid.height, 3 * 124 + 2 * NestSpacing.gap10);
      expect(find.text('Three'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('roster order comes from the database (nickname order)', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      // Seeded roster, ordered by `watchChildren` (ORDER BY nickname): the
      // design mock shows the seed insertion order instead.
      final maya = tester.getRect(find.text('Maya'));
      final leo = tester.getRect(find.text('Leo'));
      expect(leo.left, lessThan(maya.left));

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Seed.empty (no children) shows the form-only layout', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await pumpAppRoute(tester, '/add-children');

      expect(find.byType(KidCardGrid), findsNothing);
      expect(find.text('Who\u2019s in your nest?'), findsOneWidget);
      expect(find.text('Add a child'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Continue still advances: the funnel must never dead-end.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/pocket-money-setup');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 navigation', () {
    testWidgets('every non-navigating tap stays on the screen', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.tap(find.text('4\u20136'));
      await tester.pump();
      expect(currentPath(tester), '/add-children');

      // Scrolled clear of the bottom CTA first — see P05-BUG-1: at the top of
      // the list the swatches sit under the CTA and a tap there fires Continue.
      await tester.scrollUntilVisible(
        find.byKey(const Key('swatch-leaf')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('swatch-leaf')));
      await tester.pump();
      expect(currentPath(tester), '/add-children');
      expect(
        tester
            .widget<Semantics>(find.byKey(const Key('swatch-leaf')))
            .properties
            .selected,
        isTrue,
      );

      await tester.tap(find.text('Add another child'));
      await tester.pump();
      expect(currentPath(tester), '/add-children');
      expect(find.text('Give them a nickname'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('edit on each card carries its own childId', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (final (id, label) in <(String, String)>[
        ('maya', 'Maya'),
        ('leo', 'Leo'),
      ]) {
        await tester.tap(find.byKey(Key('editChild-$id')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(currentPath(tester), '/child-profile');
        expect(
          GoRouter.of(tester.element(find.text('P15 Child profile')))
              .state
              .uri
              .queryParameters['childId'],
          id,
          reason: 'pencil on $label',
        );
        // Back to the funnel for the second pencil. P15 is still a placeholder with
        // no chrome of its own, so drive the router directly here; the in-app
        // Back button is covered by the 'back goes to privacy' test.
        GoRouter.of(tester.element(find.byType(Navigator).first))
            .go(FamilyRoutePaths.addChildren);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(currentPath(tester), '/add-children');
      }

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  // Orchestrator notes (mandatory, iteration 2): the UI check runs this screen
  // with SEED=onboarding_kids, so the seeded pair must reach the grid from the
  // database without a redirect, and the age chips must flow in a row.
  group('P05 onboarding_kids seed (orchestrator-mandated UI state)', () {
    Future<AppDatabase> seedOnboardingKids() async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.onboardingKids(db);
      await GetIt.instance<AppSession>().refresh();
      return db;
    }

    testWidgets('renders Maya and Leo from the database, still on P05', (
      tester,
    ) async {
      await seedOnboardingKids();
      await pumpAppRoute(tester, '/add-children');

      // onboarding_complete = false must not bounce the funnel to /welcome:
      // /add-children is in the router's onboarding allow-list.
      expect(currentPath(tester), '/add-children');
      expect(find.byType(KidCardGrid), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Age 7\u20139'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('Age 4\u20136'), findsOneWidget);
      expect(find.text('Add a child'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('each card takes its avatar colour from its own row', (
      tester,
    ) async {
      await seedOnboardingKids();
      await pumpAppRoute(tester, '/add-children');

      NestAvatarColor colourOf(String nickname) => tester
          .widget<NestAvatar>(
            find.descendant(
              of: find.ancestor(
                of: find.text(nickname),
                matching: find.byType(NestCard),
              ),
              matching: find.byType(NestAvatar),
            ),
          )
          .color;

      expect(colourOf('Maya'), NestAvatarColor.lilac);
      expect(colourOf('Leo'), NestAvatarColor.peach);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('saving from this seed appends to the roster and keeps both', (
      tester,
    ) async {
      final db = await seedOnboardingKids();
      await pumpAppRoute(tester, '/add-children');

      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final rows = await db.select(db.children).get();
      expect(
        rows.map((r) => r.nickname),
        containsAll(<String>['Maya', 'Leo', 'Ollie']),
      );
      expect(find.text('Ollie'), findsOneWidget);
      expect(currentPath(tester), '/add-children');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 age chip row (mandatory orchestrator item 1)', () {
    testWidgets('chips hug their pills and flow left-aligned from the gutter', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      // The form card's content left edge (card 20 + padding 14).
      final contentLeft =
          tester.getRect(find.byType(NestCard).last).left + NestSpacing.gap14;

      final boxes = <String, Rect>{
        for (final band in AddChildFormCard.ageBands)
          band: tester.getRect(find.byKey(Key('ageChip-$band'))),
      };

      // No chip may claim the whole Wrap run (the P05-BUG-1 signature).
      for (final entry in boxes.entries) {
        expect(
          entry.value.width,
          lessThan(322),
          reason: '${entry.key} hugs its pill, not the run',
        );
        expect(
          entry.value.left,
          greaterThanOrEqualTo(contentLeft),
          reason: '${entry.key} stays inside the card gutter',
        );
      }

      // Left-aligned like `.chip-row`: the first chip starts exactly on the
      // content edge, never centred in the run.
      final lefts = boxes.values.map((r) => r.left).toList();
      expect(lefts.reduce((a, b) => a < b ? a : b), contentLeft);

      // Chips that share a row are 8 px apart (design `.chip-row { gap: 8 }`).
      final sorted = boxes.values.toList()
        ..sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < sorted.length; i++) {
        if ((sorted[i].top - sorted[i - 1].top).abs() < 1) {
          expect(
            sorted[i].left - sorted[i - 1].right,
            NestSpacing.s2,
            reason: 'same-row gap is 8 px',
          );
        }
      }

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    for (final (width, scale) in <(double, double)>[
      (320, 1),
      (320, 1.3),
      (430, 1.3),
    ]) {
      testWidgets('no chip overflows the card at $width / $scale\u00d7', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/add-children');
        await _resize(tester, width, scale);

        final cardRight =
            tester.getRect(find.byType(NestCard).last).right -
            NestSpacing.gap14;
        for (final band in AddChildFormCard.ageBands) {
          final box = tester.getRect(find.byKey(Key('ageChip-$band')));
          expect(
            box.right,
            lessThanOrEqualTo(cardRight + 0.01),
            reason: 'chip $band inside the content box',
          );
          expect(
            box.width,
            lessThanOrEqualTo(cardRight - 20),
            reason: 'chip $band is not run-wide',
          );
        }
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }
  });

  group('P05 copy is character-exact (orchestrator COPY rule)', () {
    // Every string below is compared against
    // design/html-source/screens/P05-add-children.html character by
    // character. Escapes are written out on purpose: a straight quote or an
    // ASCII hyphen must not slip back in unnoticed.
    const heading =
        'Who\u2019s in your nest?'; // <h1>Who&rsquo;s in your nest?</h1>
    const sub = 'Nicknames only \u2014 no photos, no email.'; // &mdash;
    const caption = 'You can change any of this later in Family.';
    const note = 'We only ask for an age range so quests suit them.';

    testWidgets('the h1 uses the curly apostrophe, not ASCII', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      expect(find.text(heading), findsOneWidget);
      final rendered = tester.widget<Text>(find.text(heading)).data!;
      expect(rendered, heading);
      expect(rendered.codeUnits, contains(0x2019));
      expect(
        rendered.contains(RegExp("'")),
        isFalse,
        reason: 'ASCII U+0027 apostrophe',
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the subtitle keeps the em dash and the rest of the copy', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (final line in <String>[sub, caption, note]) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      expect(sub.codeUnits, contains(0x2014), reason: 'em dash U+2014');
      expect(
        find.textContaining('-'),
        findsNothing,
        reason: 'no ASCII hyphen in the screen copy',
      );
      expect(
        find.text("Who's"),
        findsNothing,
        reason: 'no ASCII apostrophe anywhere in the heading',
      );
      // UK spelling, exactly as the HTML spells it.
      expect(find.text('Avatar colour'), findsOneWidget);
      expect(find.textContaining('color'), findsNothing);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('age bands and card ages use en dashes (U+2013)', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (final band in AddChildFormCard.ageBands) {
        expect(
          find.text(displayAgeBand(band)),
          findsOneWidget,
          reason: 'chip $band',
        );
      }
      expect(find.text('Age 7\u20139'), findsOneWidget);
      expect(find.text('Age 4\u20136'), findsOneWidget);
      expect(
        find.text('Age 7-9'),
        findsNothing,
        reason: 'the hyphen form is only what the database stores',
      );
      // `displayAgeBand` is the single place that converts for display.
      expect(displayAgeBand('7-9'), '7\u20139');
      expect(displayAgeBand('13+'), '13+', reason: 'no hyphen to convert');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    test('the seed stores hyphens while the design shows en dashes', () {
      // Guards the conversion boundary: DB tokens are hyphenated by design
      // (Seed writes `ageBand: Value('7-9')`), the UI must never echo them.
      expect(displayAgeBand('4-6'), '4\u20136');
      expect(displayAgeBand('10-12'), '10\u201312');
      expect('7-9', isNot(displayAgeBand('7-9')));
    });
  });

  // Orchestrator ruling (app-wide): children are listed in the order they were
  // added, never alphabetically. P05 renders the repository order verbatim and
  // sorts nothing locally, so the invariant below holds both today (core still
  // orders by nickname — see SHARED_REQUEST.md, creation-order fix pending) and
  // after the shared fix lands (creation order). TODO(P05): delete nothing, but
  // expect Maya before Leo once `watchChildren` orders by creation.
  group('P05 child order follows the repository (CHILD ORDER ruling)', () {
    List<String> renderedOrder(WidgetTester tester, List<String> names) {
      final rects = <String, Rect>{
        for (final name in names) name: tester.getRect(find.text(name).first),
      };
      return rects.keys.toList()..sort((a, b) {
        // Reading order: row by row, then left to right inside a row.
        final byTop = rects[a]!.top.compareTo(rects[b]!.top);
        return byTop != 0 ? byTop : rects[a]!.left.compareTo(rects[b]!.left);
      });
    }

    testWidgets('the grid renders the repository order, unsorted', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      // `watchChildren().first` does not resolve under the shared test scope
      // (2_build.md deviation 6), and FamilyBloc is a GetIt *factory*, so the
      // authoritative order is read off the bloc the screen itself uses.
      final roster = BlocProvider.of<FamilyBloc>(
        tester.element(find.byType(KidCardGrid)),
      ).state.children;
      final expected = roster.map((c) => c.nickname).toList();
      expect(expected, hasLength(2));
      expect(
        renderedOrder(tester, expected),
        expected,
        reason: 'P05 must not re-sort the repository roster',
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a newly saved child lands where the repository puts it', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final roster = BlocProvider.of<FamilyBloc>(
        tester.element(find.byType(KidCardGrid)),
      ).state.children;
      final expected = roster.map((c) => c.nickname).toList();
      expect(expected, hasLength(3));
      expect(renderedOrder(tester, expected), expected);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    test('the bloc never reorders the roster', () async {
      // Both directions, so the guarantee does not depend on which order the
      // database happens to produce.
      for (final kids in <List<FamilyChild>>[
        <FamilyChild>[_maya, _leo],
        <FamilyChild>[_leo, _maya],
      ]) {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(kids));
        final bloc = FamilyBloc(repository: repo)
          ..add(const FamilyLoadRequested());
        await bloc.stream.firstWhere((s) => s.status == FamilyStatus.loaded);
        expect(bloc.state.children, kids);
        await bloc.close();
      }
    });
  });

  group('P05 focused nickname field', () {
    testWidgets('focus paints the leaf focus ring and unfocused does not', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      // The field's own wrapper Container — the card and the selected swatch
      // carry shadows as well, so the finder must not sweep the whole card.
      BoxDecoration? fieldDecoration() =>
          tester
                  .widget<Container>(
                    find
                        .ancestor(
                          of: find.byType(TextField),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration?;

      final tokens = _tokensOf(tester, find.byType(NestBottomCta));
      expect(
        fieldDecoration()?.boxShadow,
        isNull,
        reason: 'no focus ring before focusing',
      );

      await tester.tap(find.byKey(const Key('nicknameField')));
      await tester.pump();

      expect(
        fieldDecoration()?.boxShadow,
        NestShadows.focusRing(tokens.leafTint, tokens.leaf),
      );
      final decoration = tester
          .widget<TextField>(find.byType(TextField).first)
          .decoration!;
      final focusedBorder = decoration.focusedBorder;
      expect(focusedBorder, isA<OutlineInputBorder>());
      expect(
        (focusedBorder! as OutlineInputBorder).borderSide.color,
        tokens.leaf,
      );

      // Losing focus removes the ring again.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(fieldDecoration()?.boxShadow, isNull);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 BUG-8 device insets', () {
    testWidgets('with a device safe area the form is still fully reachable', (
      tester,
    ) async {
      await setUpTestScope();
      const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      tester.view.padding = insets;
      tester.view.viewPadding = insets;
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await pumpAppRoute(tester, '/add-children');

      final cta = tester.getRect(find.byType(NestBottomCta));
      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('We only ask for an age range so quests suit them.'),
        300,
        scrollable: list,
      );
      await tester.pump();

      // The symptom of the missing `padding: EdgeInsets.zero`: the grid
      // re-applied 47 + 34 px of inset and pushed the tail of the form under
      // the CTA, where scrolling could not lift it clear.
      final note = tester.getRect(
        find.text('We only ask for an age range so quests suit them.'),
      );
      expect(
        note.bottom,
        lessThanOrEqualTo(cta.top),
        reason: 'the closing note must be reachable above the CTA',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P05 BUG-5 conditional clear', () {
    test('lastSavedNickname is recorded on save and kept by copyWith', () {
      const none = FamilyState();
      expect(none.lastSavedNickname, isNull);

      final saved = none.copyWith(lastSavedNickname: 'Ollie');
      expect(saved.lastSavedNickname, 'Ollie');
      expect(saved.copyWith(draftAgeBand: '4-6').lastSavedNickname, 'Ollie');
      expect(saved, isNot(none), reason: 'props include lastSavedNickname');
    });

    test('typing while the save is in flight keeps the newer draft', () async {
      final gate = Completer<void>();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) => gate.future);
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyDraftChanged(nickname: 'Ollie'))
        ..add(FamilyAddChildRequested(onSaved: () {}));

      await bloc.stream.firstWhere((s) => s.saveInProgress);
      // The parent starts typing the next child while the insert runs.
      bloc.add(const FamilyDraftChanged(nickname: 'Ada'));
      await bloc.stream.firstWhere((s) => s.draftNickname == 'Ada');
      gate.complete();
      await bloc.stream.firstWhere((s) => !s.saveInProgress);

      expect(
        bloc.state.draftNickname,
        'Ada',
        reason: 'the newer draft belongs to the next child',
      );
      expect(bloc.state.lastSavedNickname, 'Ollie');
      expect(bloc.state.nicknameError, isNull);

      await bloc.close();
    });

    test('an untouched draft still clears after the save', () async {
      final repo = _MockFamilyRepository();
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) async {});
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyDraftChanged(nickname: 'Ollie'))
        ..add(FamilyAddChildRequested(onSaved: () {}));
      await bloc.stream.firstWhere((s) => s.lastSavedNickname == 'Ollie');

      expect(bloc.state.draftNickname, isEmpty);
      expect(bloc.state.lastSavedNickname, 'Ollie');

      await bloc.close();
    });

    testWidgets('the field keeps mid-save typing but clears a plain save', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) => gate.future);
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ada');
      await tester.pump();
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        'Ada',
      );

      // Next child: a save with no mid-save typing clears the field again.
      final second = Completer<void>();
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) => second.future);
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      second.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller?.text,
        isEmpty,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('P05 BUG-2 guard interactions', () {
    testWidgets('Continue during an in-flight save is inert, then works', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      var calls = 0;
      when(
        () => repo.addChild(
          nickname: any(named: 'nickname'),
          ageBand: any(named: 'ageBand'),
          avatarColour: any(named: 'avatarColour'),
        ),
      ).thenAnswer((_) {
        calls++;
        return gate.future;
      });
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAppView(tester, bloc);
      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // The guard drops the second request outright: one insert, no
      // navigation, no inline error.
      expect(calls, 1);
      expect(currentPath(tester), '/add-children');
      expect(find.text('Give them a nickname'), findsNothing);

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The funnel stays usable once the save settles.
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/pocket-money-setup');
      expect(
        calls,
        1,
        reason: 'the field cleared on save, so Continue only navigates',
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the selected chip keeps it selected', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('7\u20139'));
        await tester.pump();
        expect(
          find.byWidgetPredicate(
            (w) => w is NestChip && w.label == '7\u20139' && w.selected,
          ),
          findsOneWidget,
        );
      }
      expect(currentPath(tester), '/add-children');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a successful add-another restores focus to the nickname', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.enterText(find.byKey(const Key('nicknameField')), 'Ollie');
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(
        field.focusNode?.hasFocus,
        isTrue,
        reason: 'the next child can be typed straight away',
      );
      expect(field.controller?.text, isEmpty);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P05 failure recovery', () {
    testWidgets('Try again re-subscribes once and renders the roster', (
      tester,
    ) async {
      final repo = _MockFamilyRepository();
      var subscribes = 0;
      when(repo.watchItems).thenAnswer((_) {
        subscribes++;
        return subscribes == 1
            ? Stream<List<FamilyMember>>.error(Exception('offline'))
            : Stream.value(_members);
      });
      when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      await tester.pump();
      expect(find.text('Exception: offline'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(subscribes, 2, reason: 'exactly one fresh subscription');
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);

      // A second recovery press is impossible: the panel is gone.
      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the roster and the form survive a late roster emission', (
      tester,
    ) async {
      final controller = StreamController<List<FamilyChild>>();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => controller.stream);
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await _pumpAddChildrenView(tester, bloc);
      controller.add(_kids);
      await tester.pump();
      expect(find.text('Maya'), findsOneWidget);

      controller.add(const <FamilyChild>[]);
      await tester.pump();
      expect(
        find.byType(KidCardGrid),
        findsNothing,
        reason: 'every child removed collapses the grid',
      );
      expect(find.text('Add a child'), findsOneWidget);

      await controller.close();
      expect(tester.takeException(), isNull);
    });
  });

  group('P05 field robustness', () {
    testWidgets('a 24-character nickname ellipsizes in the narrowest column', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');
      await _resize(tester, 320, 1.3);

      // 24 chars is the bloc's hard limit, so this is the widest card text the
      // screen can ever show.
      const longest = 'Bartholomew Woosencrat';
      await tester.enterText(find.byKey(const Key('nicknameField')), longest);
      await tester.pump();
      await tester.tap(find.text('Add another child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(longest), findsOneWidget);
      // Nickname order puts "Bartholomew…" first, so find its own card rather
      // than assuming an index.
      final card = find.ancestor(
        of: find.text(longest),
        matching: find.byType(NestCard),
      );
      final name = tester.getRect(find.text(longest));
      expect(
        tester.getRect(card).contains(name.topLeft),
        isTrue,
        reason: 'the ellipsised name stays inside its card',
      );
      expect(
        tester.getRect(card).contains(name.bottomRight),
        isTrue,
        reason: 'the ellipsised name never overflows its column',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final (width, scale) in <(double, double)>[(320, 1.3), (390, 1.3)]) {
      testWidgets('the inline error keeps the CTA on screen at $width / '
          '$scale\u00d7', (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/add-children');
        await _resize(tester, width, scale);

        await tester.tap(find.text('Add another child'));
        await tester.pump();

        expect(find.text('Give them a nickname'), findsOneWidget);
        final cta = tester.getRect(find.byType(NestBottomCta));
        final view = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(cta.bottom, view.height, reason: 'owner bottom-edge rule');
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('Add another child'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the field is not auto-focused on open (design ring is a mock '
        'state)', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.focusNode?.hasFocus, isFalse);
      expect(field.controller?.text, isEmpty);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the chip and swatch groups are labelled containers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.container && w.properties.label == 'Age band',
        ),
        findsOneWidget,
        reason: 'role=group for the age band (design role="group")',
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.container &&
              w.properties.label == 'Avatar colour',
        ),
        findsOneWidget,
      );
      // The individual controls stay reachable inside the groups (the label is
      // carried by both the semantics node and the rendered text).
      expect(
        find.bySemanticsLabel(RegExp('4\u20136')),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.bySemanticsLabel('Avatar colour lilac'),
        findsAtLeastNWidgets(1),
      );

      handle.dispose();
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
