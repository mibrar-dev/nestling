import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';

class MockTodayRepository extends Mock implements TodayRepository;

const _items = <TodayItem>[
  TodayItem(
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    questId: 'q-dishwasher',
    childId: 'maya',
    childName: 'Maya',
    status: 'done_pending',
    coins: 15,
    repeatRule: 'weekly',
    iconKey: 'dishwasher',
  ),
  TodayItem(
    id: 'q-reading:maya',
    title: 'Reading – 20 minutes',
    questId: 'q-reading',
    childId: 'maya',
    childName: 'Maya',
    status: 'to_do',
    coins: 10,
    repeatRule: 'daily',
    iconKey: 'book',
  ),
  TodayItem(
    id: 'q-bed:leo',
    title: 'Make your bed',
    questId: 'q-bed',
    childId: 'leo',
    childName: 'Leo',
    status: 'done_pending',
    coins: 5,
    repeatRule: 'daily',
    iconKey: 'bed',
  ),
];

const _summaries = <ChildDaySummary>[
  ChildDaySummary(
    childId: 'maya',
    nickname: 'Maya',
    avatarColour: 'lilac',
    pipStage: 3,
    done: 1,
    total: 2,
    coins: 120,
    ageYears: 9,
    happyDays: 4,
  ),
  ChildDaySummary(
    childId: 'leo',
    nickname: 'Leo',
    avatarColour: 'peach',
    pipStage: 2,
    done: 0,
    total: 1,
    coins: 45,
    ageYears: 6,
    happyDays: 3,
    pipStyle: 'bolt',
    pipSkin: 'sky',
  ),
];

void main() {
  group('TodayBloc', () {
    blocTest<TodayBloc, TodayState>(
      'load emits loading then loaded with counts + header',
      build: () {
        final repo = MockTodayRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_items));
        when(repo.watchSummaries).thenAnswer((_) => Stream.value(_summaries));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(2));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () {
        final london = toFamilyZone(DateTime.now().toUtc(), 'Europe/London');
        return [
          const TodayState(status: TodayStatus.loading),
          TodayState(
            status: TodayStatus.loaded,
            items: _items,
            summaries: _summaries,
            pendingCount: 2,
            greeting: dayPartForHour(london.hour),
            dateLine:
                '${formatDay(DateTime.now().toUtc(), 'Europe/London')} · Happy week: 4 days',
            happyDays: 4,
          ),
        ];
      },
    );

    blocTest<TodayBloc, TodayState>(
      'stream error emits failure with a message',
      build: () {
        final repo = MockTodayRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_items));
        when(repo.watchSummaries).thenAnswer(
          (_) => Stream<List<ChildDaySummary>>.error(Exception('boom')),
        );
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.failure &&
              (s.errorMessage ?? '').contains('boom'),
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'empty streams load with empty lists and no banner',
      build: () {
        final repo = MockTodayRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <TodayItem>[]));
        when(repo.watchSummaries)
            .thenAnswer((_) => Stream.value(const <ChildDaySummary>[]));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.isEmpty &&
              s.summaries.isEmpty &&
              s.pendingCount == 0 &&
              s.happyDays == 0,
        ),
      ],
    );
  });

  group('TodayBloc state paths', () {
    test('initial state is initial with no data', () {
      final bloc = TodayBloc(repository: MockTodayRepository());
      addTearDown(bloc.close);
      expect(bloc.state, const TodayState());
      expect(bloc.state.status, TodayStatus.initial);
    });

    blocTest<TodayBloc, TodayState>(
      'parent name and payout day flow into the loaded state',
      build: () {
        final repo = MockTodayRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_items));
        when(repo.watchSummaries).thenAnswer((_) => Stream.value(_summaries));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('James'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(3));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(2));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.parentName == 'James' &&
              s.payoutDay == 3 &&
              s.pendingCount == 2 &&
              s.happyDays == 4,
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'pendingCount is the family-wide count, not the visible rows',
      build: () {
        final repo = MockTodayRepository();
        // No visible rows (e.g. every pending completion belongs to an
        // "Anyone" quest) but three approvals are still waiting in P11.
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <TodayItem>[]));
        when(repo.watchSummaries).thenAnswer((_) => Stream.value(_summaries));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(3));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.isEmpty &&
              s.pendingCount == 3,
        ),
      ],
    );

    late StreamController<List<TodayItem>> items;
    late StreamController<int> pending;

    blocTest<TodayBloc, TodayState>(
      'a second items emission updates the state without a new event',
      build: () {
        final repo = MockTodayRepository();
        items = StreamController<List<TodayItem>>();
        pending = StreamController<int>();
        addTearDown(items.close);
        addTearDown(pending.close);
        when(repo.watchItems).thenAnswer((_) => items.stream);
        when(repo.watchSummaries).thenAnswer((_) => Stream.value(_summaries));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => pending.stream);
        return TodayBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const TodayLoadRequested());
        pending.add(2);
        items.add(_items);
        await Future<void>.delayed(Duration.zero);
        // Items and the family-wide pending count move independently.
        items.add(const <TodayItem>[]);
        await Future<void>.delayed(Duration.zero);
        pending.add(0);
      },
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.length == 3 &&
              s.pendingCount == 2,
        ),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.isEmpty &&
              s.pendingCount == 2,
        ),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.isEmpty &&
              s.pendingCount == 0,
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'an error after a loaded emission switches to failure',
      build: () {
        final repo = MockTodayRepository();
        items = StreamController<List<TodayItem>>();
        addTearDown(items.close);
        when(repo.watchItems).thenAnswer((_) => items.stream);
        when(repo.watchSummaries).thenAnswer((_) => Stream.value(_summaries));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) {
        bloc.add(const TodayLoadRequested());
        items
          ..add(_items)
          ..addError(Exception('bang'));
      },
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) => s.status == TodayStatus.loaded && s.items.length == 3,
        ),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.failure &&
              (s.errorMessage ?? '').contains('bang'),
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'retry after a failure reloads and reaches loaded',
      build: () {
        final repo = MockTodayRepository();
        var attempts = 0;
        when(repo.watchItems).thenAnswer((_) {
          attempts++;
          return attempts == 1
              ? Stream<List<TodayItem>>.error(Exception('offline'))
              : Stream.value(_items);
        });
        when(repo.watchSummaries).thenAnswer((_) => Stream.value(_summaries));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(2));
        return TodayBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const TodayLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TodayLoadRequested());
      },
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>((s) => s.status == TodayStatus.failure),
        predicate<TodayState>((s) => s.status == TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.length == 3 &&
              s.pendingCount == 2,
        ),
      ],
    );
    test('date line uses the singular "1 day" for a one-day happy week', () async {
      final repo = MockTodayRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_items));
      when(repo.watchSummaries).thenAnswer(
        (_) => Stream.value(const <ChildDaySummary>[
          ChildDaySummary(
            childId: 'maya',
            nickname: 'Maya',
            avatarColour: 'lilac',
            pipStage: 3,
            done: 1,
            total: 2,
            coins: 120,
            ageYears: 9,
            happyDays: 1,
          ),
        ]),
      );
      when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
      when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
      when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      final loaded = await bloc.stream.firstWhere(
        (s) => s.status == TodayStatus.loaded,
      );

      expect(loaded.happyDays, 1);
      expect(
        loaded.dateLine,
        '${formatDay(DateTime.now().toUtc(), 'Europe/London')} · Happy week: 1 day',
      );
    });
  });

  group('dayPartForHour', () {
    test('morning / afternoon / evening boundaries', () {
      expect(dayPartForHour(0), 'Good morning');
      expect(dayPartForHour(11), 'Good morning');
      expect(dayPartForHour(12), 'Good afternoon');
      expect(dayPartForHour(17), 'Good afternoon');
      expect(dayPartForHour(18), 'Good evening');
      expect(dayPartForHour(23), 'Good evening');
    });
  });

  group('happyWeekLabel', () {
    test('singular / plural', () {
      expect(happyWeekLabel(0), 'Happy week: 0 days');
      expect(happyWeekLabel(1), 'Happy week: 1 day');
      expect(happyWeekLabel(4), 'Happy week: 4 days');
    });
  });
}
