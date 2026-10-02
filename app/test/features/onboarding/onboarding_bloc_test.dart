// P01 — OnboardingBloc state machine and the Drift-backed onboarding
// repository contract.
//
// The bloc has one event (`OnboardingLoadRequested`) and four states
// (initial/loading/loaded/failure); P01 renders static brand content for
// every one of them, while P02 reads `items`. These tests pin every path of
// the state machine plus the in-memory Drift persistence behind
// `watchComplete` / `completeOnboarding`.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_state.dart';

import '../../test_scope.dart';

const List<OnboardingStep> _tourSteps = <OnboardingStep>[
  OnboardingStep(
    id: 'quests',
    title: 'Set quests in seconds',
    detail:
        "Pick from 40+ ready-made jobs like 'Put the bins out' or make "
        'your own.',
  ),
  OnboardingStep(
    id: 'pip',
    title: 'Pip grows as they help',
    detail: 'Every finished quest feeds Pip the bird, from egg to songbird.',
  ),
  OnboardingStep(
    id: 'money',
    title: 'Pocket money, sorted',
    detail: 'No bank card needed — we keep score, you pay your way.',
  ),
];

const OnboardingStep _firstStep = OnboardingStep(
  id: 'quests',
  title: 'Set quests in seconds',
  detail: "Pick from 40+ ready-made jobs like 'Put the bins out'.",
);

const OnboardingStep _secondStep = OnboardingStep(
  id: 'pip',
  title: 'Pip grows as they help',
  detail: 'Every finished quest feeds Pip the bird.',
);

/// In-memory repository with a caller-controlled item stream, used to reach
/// states the Drift repository cannot (pending load, empty, stream error,
/// live updates).
class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository({Stream<List<OnboardingStep>>? items})
    : _items = items ?? const Stream<List<OnboardingStep>>.empty();

  final Stream<List<OnboardingStep>> _items;

  @override
  Future<List<OnboardingStep>> getItems() => _items.first;

  @override
  Stream<List<OnboardingStep>> watchItems() => _items;

  @override
  Stream<bool> watchComplete() => Stream<bool>.value(true);

  @override
  Future<void> completeOnboarding() async {}
}

void main() {
  group('OnboardingState', () {
    test('copyWith replaces only the given fields', () {
      const state = OnboardingState();
      final loading = state.copyWith(status: OnboardingStatus.loading);
      expect(loading.status, OnboardingStatus.loading);
      expect(loading.items, state.items);
      expect(loading.errorMessage, isNull);

      final failed = loading.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: 'offline',
      );
      expect(failed.status, OnboardingStatus.failure);
      expect(failed.errorMessage, 'offline');
      expect(failed.items, isEmpty);
    });

    test('equality is driven by status, items and error message', () {
      const a = OnboardingState(
        status: OnboardingStatus.loaded,
        items: _tourSteps,
      );
      const b = OnboardingState(
        status: OnboardingStatus.loaded,
        items: _tourSteps,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const OnboardingState()));
      expect(a, isNot(a.copyWith(status: OnboardingStatus.loading)));
    });
  });

  group('OnboardingBloc', () {
    test('starts initial with no items and no error', () {
      final bloc = OnboardingBloc(repository: _FakeOnboardingRepository());
      addTearDown(bloc.close);

      expect(bloc.state, const OnboardingState());
      expect(bloc.state.status, OnboardingStatus.initial);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.errorMessage, isNull);
    });

    blocTest<OnboardingBloc, OnboardingState>(
      'load on the Drift repository emits loading then the three tour cards',
      setUp: setUpTestScope,
      build: () =>
          OnboardingBloc(repository: GetIt.instance<OnboardingRepository>()),
      act: (bloc) => bloc.add(const OnboardingLoadRequested()),
      expect: () => const <OnboardingState>[
        OnboardingState(status: OnboardingStatus.loading),
        OnboardingState(status: OnboardingStatus.loaded, items: _tourSteps),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'live repository stream: every emission becomes a loaded state',
      build: () => OnboardingBloc(
        repository: _FakeOnboardingRepository(
          items: Stream<List<OnboardingStep>>.fromIterable(
            <List<OnboardingStep>>[
              <OnboardingStep>[_firstStep],
              <OnboardingStep>[_firstStep, _secondStep],
            ],
          ),
        ),
      ),
      act: (bloc) => bloc.add(const OnboardingLoadRequested()),
      expect: () => <Matcher>[
        isA<OnboardingState>().having(
          (state) => state.status,
          'status',
          OnboardingStatus.loading,
        ),
        isA<OnboardingState>()
            .having((state) => state.status, 'status', OnboardingStatus.loaded)
            .having((state) => state.items, 'items', <OnboardingStep>[
              _firstStep,
            ]),
        isA<OnboardingState>()
            .having((state) => state.status, 'status', OnboardingStatus.loaded)
            .having((state) => state.items, 'items', <OnboardingStep>[
              _firstStep,
              _secondStep,
            ]),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'an empty repository stream is a loaded state with no items',
      build: () => OnboardingBloc(
        repository: _FakeOnboardingRepository(
          items: Stream<List<OnboardingStep>>.value(const <OnboardingStep>[]),
        ),
      ),
      act: (bloc) => bloc.add(const OnboardingLoadRequested()),
      expect: () => const <OnboardingState>[
        OnboardingState(status: OnboardingStatus.loading),
        OnboardingState(status: OnboardingStatus.loaded),
      ],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'a repository stream error becomes a failure state with the message',
      build: () => OnboardingBloc(
        repository: _FakeOnboardingRepository(
          items: Stream<List<OnboardingStep>>.error(Exception('offline')),
        ),
      ),
      act: (bloc) => bloc.add(const OnboardingLoadRequested()),
      expect: () => <Matcher>[
        isA<OnboardingState>().having(
          (state) => state.status,
          'status',
          OnboardingStatus.loading,
        ),
        isA<OnboardingState>()
            .having((state) => state.status, 'status', OnboardingStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('offline'),
            ),
      ],
    );
  });

  group('OnboardingRepository (in-memory Drift)', () {
    late AppDatabase db;
    late OnboardingRepositoryImpl repository;

    setUp(() {
      db = AppDatabase.memory();
      repository = OnboardingRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    test(
      'watchItems and getItems return the three static tour cards',
      () async {
        await Seed.demo(db);

        final watched = await repository.watchItems().first;
        expect(watched, _tourSteps);
        expect(await repository.getItems(), _tourSteps);
      },
    );

    test('Seed.demo is already onboarded', () async {
      await Seed.demo(db);
      expect(await repository.watchComplete().first, isTrue);
    });

    test('Seed.empty is an onboarded parent with no children', () async {
      await Seed.empty(db);
      expect(await repository.watchComplete().first, isTrue);
      expect(await db.select(db.children).get(), isEmpty);
    });

    test(
      'Seed.fresh is not onboarded until completeOnboarding writes',
      () async {
        await Seed.fresh(db);
        expect(await repository.watchComplete().first, isFalse);

        await repository.completeOnboarding();
        expect(await repository.watchComplete().first, isTrue);
      },
    );
  });
}
