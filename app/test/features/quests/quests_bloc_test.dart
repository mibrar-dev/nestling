import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';

class MockQuestsRepository extends Mock implements QuestsRepository;

const _items = <Quest>[
  Quest(
    id: 'q-bed',
    title: 'Make your bed',
    detail: 'Daily · 5 coins',
    icon: 'bed',
    coins: 5,
    repeatRule: 'daily',
    days: '',
    dueLabel: null,
    needsApproval: true,
    assigneeChildId: 'leo',
    active: true,
  ),
  Quest(
    id: 'q-reading',
    title: 'Reading – 20 minutes',
    detail: 'Daily · 10 coins',
    icon: 'book',
    coins: 10,
    repeatRule: 'daily',
    days: '',
    dueLabel: null,
    needsApproval: true,
    assigneeChildId: 'maya',
    active: true,
  ),
];

void main() {
  group('QuestsBloc', () {
    test('initial state is initial with no items', () {
      final bloc = QuestsBloc(repository: MockQuestsRepository());
      addTearDown(bloc.close);
      expect(bloc.state, const QuestsState());
      expect(bloc.state.status, QuestsStatus.initial);
      expect(bloc.state.items, isEmpty);
    });

    blocTest<QuestsBloc, QuestsState>(
      'load emits loading then loaded with the watched actives',
      build: () {
        final repo = MockQuestsRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_items));
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsLoadRequested()),
      expect: () => const <QuestsState>[
        QuestsState(status: QuestsStatus.loading),
        QuestsState(status: QuestsStatus.loaded, items: _items),
      ],
    );

    blocTest<QuestsBloc, QuestsState>(
      'stream error emits failure with a message',
      build: () {
        final repo = MockQuestsRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream<List<Quest>>.error(Exception('boom')));
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsLoadRequested()),
      expect: () => [
        const QuestsState(status: QuestsStatus.loading),
        predicate<QuestsState>(
          (s) =>
              s.status == QuestsStatus.failure &&
              (s.errorMessage ?? '').contains('boom'),
        ),
      ],
    );

    blocTest<QuestsBloc, QuestsState>(
      'empty actives load as loaded with no items (P08b path)',
      build: () {
        final repo = MockQuestsRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(const <Quest>[]));
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsLoadRequested()),
      expect: () => const <QuestsState>[
        QuestsState(status: QuestsStatus.loading),
        QuestsState(status: QuestsStatus.loaded),
      ],
    );

    late StreamController<List<Quest>> controller;

    blocTest<QuestsBloc, QuestsState>(
      'a second watch emission updates the state without a new event',
      build: () {
        final repo = MockQuestsRepository();
        controller = StreamController<List<Quest>>();
        addTearDown(controller.close);
        when(repo.watchItems).thenAnswer((_) => controller.stream);
        return QuestsBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const QuestsLoadRequested());
        await Future<void>.delayed(Duration.zero);
        controller.add(_items);
        await Future<void>.delayed(Duration.zero);
        controller.add(const <Quest>[]);
      },
      expect: () => [
        const QuestsState(status: QuestsStatus.loading),
        predicate<QuestsState>(
          (s) => s.status == QuestsStatus.loaded && s.items.length == 2,
        ),
        predicate<QuestsState>(
          (s) => s.status == QuestsStatus.loaded && s.items.isEmpty,
        ),
      ],
      // The hand-driven controller needs real async gaps; the default
      // 100 ms virtual wait is too short for three ordered emissions.
      wait: const Duration(milliseconds: 300),
    );

    blocTest<QuestsBloc, QuestsState>(
      'retry after a failure reloads and reaches loaded',
      build: () {
        final repo = MockQuestsRepository();
        var attempts = 0;
        when(repo.watchItems).thenAnswer((_) {
          attempts++;
          return attempts == 1
              ? Stream<List<Quest>>.error(Exception('offline'))
              : Stream.value(_items);
        });
        return QuestsBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const QuestsLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuestsLoadRequested());
      },
      expect: () => [
        const QuestsState(status: QuestsStatus.loading),
        predicate<QuestsState>((s) => s.status == QuestsStatus.failure),
        predicate<QuestsState>((s) => s.status == QuestsStatus.loading),
        predicate<QuestsState>(
          (s) => s.status == QuestsStatus.loaded && s.items.length == 2,
        ),
      ],
      wait: const Duration(milliseconds: 300),
    );

    blocTest<QuestsBloc, QuestsState>(
      'a load with no event is never requested twice for one emission',
      build: () {
        final repo = MockQuestsRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_items));
        return QuestsBloc(repository: repo);
      },
      // RULES §4: a stream emission must update the state on its own, with no
      // extra event — otherwise every keystroke would re-watch the table.
      act: (bloc) => bloc.add(const QuestsLoadRequested()),
      expect: () => [
        const QuestsState(status: QuestsStatus.loading),
        const QuestsState(status: QuestsStatus.loaded, items: _items),
      ],
      verify: (bloc) {
        expect(bloc.state.items, _items);
      },
    );
  });

  group('QuestsEvent', () {
    test('QuestsLoadRequested is the only event and carries no payload', () {
      expect(const QuestsLoadRequested().props, isEmpty);
      expect(const QuestsLoadRequested(), const QuestsLoadRequested());
    });

    test('QuestsEvent is sealed — an unknown event cannot be added', () {
      // Compile-time guarantee, asserted here so a future event has to be
      // given its own handler deliberately.
      expect(QuestsEvent, isNotNull);
    });
  });

  group('QuestsState', () {
    test('the default is initial with no items and no message', () {
      const state = QuestsState();
      expect(state.status, QuestsStatus.initial);
      expect(state.items, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('every QuestsStatus value is distinct', () {
      expect(QuestsStatus.values, hasLength(4));
      expect(
        QuestsStatus.values.toSet(),
        hasLength(QuestsStatus.values.length),
      );
    });

    test('copyWith replaces only what it is given', () {
      const base = QuestsState(
        status: QuestsStatus.loaded,
        items: _items,
        errorMessage: 'old',
      );

      expect(base.copyWith(status: base.status), base);
      expect(
        base.copyWith(status: QuestsStatus.failure).status,
        QuestsStatus.failure,
      );
      expect(base.copyWith(items: const <Quest>[]).items, isEmpty);
      expect(base.copyWith(errorMessage: 'new').errorMessage, 'new');

      // Untouched fields survive.
      final changed = base.copyWith(status: QuestsStatus.failure);
      expect(changed.items, _items);
      expect(changed.errorMessage, 'old');
    });

    test('copyWith cannot clear errorMessage (null means "keep")', () {
      const base = QuestsState(
        status: QuestsStatus.failure,
        errorMessage: 'boom',
      );
      expect(base.copyWith(status: QuestsStatus.loading).errorMessage, 'boom');
    });

    test('equality covers status, items and errorMessage', () {
      const a = QuestsState(
        status: QuestsStatus.loaded,
        items: _items,
        errorMessage: 'x',
      );
      expect(
        a,
        const QuestsState(
          status: QuestsStatus.loaded,
          items: _items,
          errorMessage: 'x',
        ),
      );
      expect(
        a.hashCode,
        const QuestsState(
          status: QuestsStatus.loaded,
          items: _items,
          errorMessage: 'x',
        ).hashCode,
      );

      expect(a, isNot(const QuestsState(status: QuestsStatus.failure)));
      expect(
        a,
        isNot(
          // `items` defaults to empty, so this is the "no items" state.
          const QuestsState(status: QuestsStatus.loaded, errorMessage: 'x'),
        ),
        reason: 'a different items list is a different state',
      );
      expect(
        a,
        isNot(
          const QuestsState(
            status: QuestsStatus.loaded,
            items: _items,
            errorMessage: 'y',
          ),
        ),
      );
    });

    test('props lists status, items and errorMessage', () {
      const state = QuestsState(
        status: QuestsStatus.failure,
        items: _items,
        errorMessage: 'boom',
      );
      expect(state.props, <Object?>[QuestsStatus.failure, _items, 'boom']);
    });
  });
}
