import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_state.dart';

class MockApprovalsRepository extends Mock implements ApprovalsRepository;

// Stream order: oldest-first, exactly as the repository emits
// (createdAt ASC: bed 06:58, table 07:05, dishwasher 07:12 UTC).
final _bed = Approval(
  id: '3',
  title: 'Make your bed',
  detail: 'Leo · Today 7:58am',
  completionId: 3,
  questId: 'q-bed',
  questTitle: 'Make your bed',
  childId: 'leo',
  childName: 'Leo',
  avatarColour: 'peach',
  coins: 5,
  createdAt: DateTime.utc(2026, 10, 3, 6, 58),
  createdAtTz: 'Europe/London',
);

final _table = Approval(
  id: '2',
  title: 'Lay the table',
  detail: 'Maya · Today 8:05am',
  completionId: 2,
  questId: 'q-table',
  questTitle: 'Lay the table',
  childId: 'maya',
  childName: 'Maya',
  avatarColour: 'lilac',
  coins: 10,
  createdAt: DateTime.utc(2026, 10, 3, 7, 5),
  createdAtTz: 'Europe/London',
);

final _dishwasher = Approval(
  id: '1',
  title: 'Empty the dishwasher',
  detail: 'Maya · Today 8:12am',
  completionId: 1,
  questId: 'q-dishwasher',
  questTitle: 'Empty the dishwasher',
  childId: 'maya',
  childName: 'Maya',
  avatarColour: 'lilac',
  coins: 15,
  createdAt: DateTime.utc(2026, 10, 3, 7, 12),
  createdAtTz: 'Europe/London',
);

final _streamOrder = <Approval>[_bed, _table, _dishwasher];

final _sortedLoaded = ApprovalsState(
  status: ApprovalsStatus.loaded,
  items: <Approval>[_dishwasher, _table, _bed],
);

/// Adds [event] only after the inbox has loaded, so the emission sequence
/// is deterministic (no race between the stream delivery and the action).
Future<void> addAfterLoaded(ApprovalsBloc bloc, ApprovalsEvent event) async {
  bloc.add(const ApprovalsLoadRequested());
  await bloc.stream.firstWhere(
    (s) => s.status == ApprovalsStatus.loaded && s.actionError == null,
  );
  bloc.add(event);
}

void main() {
  late MockApprovalsRepository repo;

  setUp(() {
    repo = MockApprovalsRepository();
    when(repo.watchItems).thenAnswer((_) => Stream.value(_streamOrder));
  });

  group('ApprovalsBloc load', () {
    blocTest<ApprovalsBloc, ApprovalsState>(
      'load emits loading then loaded with 3 items sorted newest-first',
      build: () => ApprovalsBloc(repository: repo),
      act: (bloc) => bloc.add(const ApprovalsLoadRequested()),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
      ],
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'stream error emits failure with a message',
      build: () {
        when(repo.watchItems)
            .thenAnswer((_) => Stream<List<Approval>>.error(Exception('boom')));
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ApprovalsLoadRequested()),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.failure &&
              (s.errorMessage ?? '').contains('boom'),
        ),
      ],
    );

    test('initial state is initial with empty inbox', () {
      final bloc = ApprovalsBloc(repository: repo);
      addTearDown(bloc.close);
      expect(bloc.state, const ApprovalsState());
      expect(bloc.state.status, ApprovalsStatus.initial);
      expect(bloc.state.busyIds, isEmpty);
      expect(bloc.state.approveAllBusy, isFalse);
      expect(bloc.state.actionError, isNull);
    });
  });

  group('ApprovalsBloc approve', () {
    blocTest<ApprovalsBloc, ApprovalsState>(
      'approve calls the repository and toggles busyIds',
      build: () {
        when(() => repo.approve(any())).thenAnswer((_) async {});
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) => addAfterLoaded(
        bloc,
        const ApprovalsApproveRequested(completionId: 1),
      ),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
        _sortedLoaded.copyWith(busyIds: const <int>{1}),
        _sortedLoaded,
      ],
      verify: (_) {
        verify(() => repo.approve(1)).called(1);
      },
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'approve failure sets actionError and clears the busy id',
      build: () {
        when(() => repo.approve(any())).thenThrow(Exception('offline'));
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) => addAfterLoaded(
        bloc,
        const ApprovalsApproveRequested(completionId: 1),
      ),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
        _sortedLoaded.copyWith(busyIds: const <int>{1}),
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.loaded &&
              s.busyIds.contains(1) &&
              (s.actionError ?? '').contains('offline'),
        ),
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.loaded &&
              s.busyIds.isEmpty &&
              (s.actionError ?? '').contains('offline'),
        ),
      ],
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'not-yet calls markNotYet and toggles busyIds',
      build: () {
        when(() => repo.markNotYet(any())).thenAnswer((_) async {});
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) =>
          addAfterLoaded(bloc, const ApprovalsNotYetRequested(completionId: 3)),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
        _sortedLoaded.copyWith(busyIds: const <int>{3}),
        _sortedLoaded,
      ],
      verify: (_) {
        verify(() => repo.markNotYet(3)).called(1);
      },
    );
  });

  group('ApprovalsBloc approveAll + actionError', () {
    blocTest<ApprovalsBloc, ApprovalsState>(
      'approve-all toggles approveAllBusy',
      build: () {
        when(repo.approveAll).thenAnswer((_) async {});
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) => addAfterLoaded(bloc, const ApprovalsApproveAllRequested()),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
        _sortedLoaded.copyWith(approveAllBusy: true),
        _sortedLoaded,
      ],
      verify: (_) {
        verify(repo.approveAll).called(1);
      },
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'approve-all failure sets actionError and clears the flag',
      build: () {
        when(repo.approveAll).thenThrow(Exception('offline'));
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) => addAfterLoaded(bloc, const ApprovalsApproveAllRequested()),
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
        _sortedLoaded.copyWith(approveAllBusy: true),
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.loaded &&
              s.approveAllBusy &&
              (s.actionError ?? '').contains('offline'),
        ),
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.loaded &&
              !s.approveAllBusy &&
              (s.actionError ?? '').contains('offline'),
        ),
      ],
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'consuming the action error clears it',
      build: () {
        when(() => repo.approve(any())).thenThrow(Exception('offline'));
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ApprovalsLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ApprovalsStatus.loaded && s.actionError == null,
        );
        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await bloc.stream.firstWhere((s) => s.actionError != null);
        bloc.add(const ApprovalsActionErrorConsumed());
      },
      expect: () => [
        const ApprovalsState(status: ApprovalsStatus.loading),
        _sortedLoaded,
        _sortedLoaded.copyWith(busyIds: const <int>{1}),
        predicate<ApprovalsState>(
          (s) =>
              s.busyIds.contains(1) &&
              (s.actionError ?? '').contains('offline'),
        ),
        predicate<ApprovalsState>(
          (s) => s.busyIds.isEmpty && (s.actionError ?? '').contains('offline'),
        ),
        predicate<ApprovalsState>(
          (s) => s.actionError == null && s.busyIds.isEmpty,
        ),
      ],
    );
  });
}
