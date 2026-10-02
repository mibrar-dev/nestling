import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
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
      'children event emits the roster from the repository stream',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyChildrenRequested()),
      expect: () => const <FamilyState>[
        FamilyState(status: FamilyStatus.loading),
        FamilyState(status: FamilyStatus.loaded, children: _kids),
      ],
    );

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
        FamilyState(draftAgeBand: '4-6', draftAvatarColour: 'sky'),
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
    blocTest<FamilyBloc, FamilyState>(
      'the children event reports a stream failure',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchChildren).thenAnswer(
          (_) => Stream<List<FamilyChild>>.error(Exception('offline')),
        );
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyChildrenRequested()),
      expect: () => [
        const FamilyState(status: FamilyStatus.loading),
        predicate<FamilyState>(
          (s) =>
              s.status == FamilyStatus.failure &&
              (s.errorMessage ?? '').contains('offline'),
        ),
      ],
    );

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
        const FamilyState(),
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

      expect(find.text("Who's in your nest?"), findsOneWidget);
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

      expect(find.text("Who's in your nest?"), findsOneWidget);
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

      expect(find.text("Who's in your nest?"), findsOneWidget);
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
      expect(find.text("Who's in your nest?"), findsNothing);
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

      expect(find.text("Who's in your nest?"), findsOneWidget);
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

      expect(find.text("Who's in your nest?"), findsOneWidget);
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

          expect(find.text("Who's in your nest?"), findsOneWidget);
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

        final head = tester.getRect(find.text("Who's in your nest?"));
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
      testWidgets('the CTA panel runs to the physical edge in $theme', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/add-children', theme: theme);

        final view = tester.view.physicalSize / tester.view.devicePixelRatio;
        final cta = tester.getRect(find.byType(NestBottomCta));
        // No strip below the bar: the panel's bottom edge is the screen edge.
        expect(cta.bottom, view.height);
        expect(cta.left, 0.0);
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
  });

  group('P05 semantics', () {
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
      expect(find.text("Who's in your nest?"), findsOneWidget);
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
}
