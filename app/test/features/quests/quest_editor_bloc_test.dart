import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';

class MockQuestsRepository extends Mock implements QuestsRepository;

/// P09 new-quest draft: Saturday-only weekly hoover quest for Maya.
const _newQuest = Quest(
  id: 'q-test-hoover',
  title: 'Hoover the stairs',
  detail: 'Weekly · 15 coins',
  icon: 'hoover',
  coins: 15,
  repeatRule: 'weekly',
  days: '6',
  dueLabel: 'Before tea (5pm)',
  dueTimeLocal: '17:00',
  needsApproval: true,
  assigneeChildId: 'maya',
  active: true,
);

const _editedQuest = Quest(
  id: 'q-hoover',
  title: 'Hoover the stairs properly',
  detail: 'Weekly · 20 coins',
  icon: 'hoover',
  coins: 20,
  repeatRule: 'weekly',
  days: '6',
  dueLabel: 'Before tea (5pm)',
  dueTimeLocal: '17:00',
  needsApproval: true,
  assigneeChildId: 'maya',
  active: true,
);

void main() {
  group('QuestsBloc editor', () {
    late MockQuestsRepository repo;

    blocTest<QuestsBloc, QuestsState>(
      'create calls the repo and moves editorStatus saving -> saved',
      build: () {
        repo = MockQuestsRepository();
        when(() => repo.createQuest(_newQuest)).thenAnswer((_) async {});
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsCreateRequested(_newQuest)),
      expect: () => const <QuestsState>[
        QuestsState(editorStatus: QuestEditorStatus.saving),
        QuestsState(editorStatus: QuestEditorStatus.saved),
      ],
      verify: (_) {
        verify(() => repo.createQuest(_newQuest)).called(1);
      },
    );

    blocTest<QuestsBloc, QuestsState>(
      'update calls the repo and moves editorStatus saving -> saved',
      build: () {
        final repo = MockQuestsRepository();
        when(() => repo.updateQuest(_editedQuest)).thenAnswer((_) async {});
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsUpdateRequested(_editedQuest)),
      expect: () => const <QuestsState>[
        QuestsState(editorStatus: QuestEditorStatus.saving),
        QuestsState(editorStatus: QuestEditorStatus.saved),
      ],
    );

    blocTest<QuestsBloc, QuestsState>(
      'delete calls the repo with the id and moves saving -> saved',
      build: () {
        final repo = MockQuestsRepository();
        when(() => repo.deleteQuest('q-hoover')).thenAnswer((_) async {});
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsDeleteRequested('q-hoover')),
      expect: () => const <QuestsState>[
        QuestsState(editorStatus: QuestEditorStatus.saving),
        QuestsState(editorStatus: QuestEditorStatus.saved),
      ],
    );

    blocTest<QuestsBloc, QuestsState>(
      'repo error moves editorStatus to failure with the message',
      build: () {
        final repo = MockQuestsRepository();
        when(() => repo.createQuest(_newQuest)).thenThrow(Exception('offline'));
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsCreateRequested(_newQuest)),
      expect: () => <Object?>[
        const QuestsState(editorStatus: QuestEditorStatus.saving),
        predicate<QuestsState>(
          (s) =>
              s.editorStatus == QuestEditorStatus.failure &&
              (s.editorError ?? '').contains('offline'),
        ),
      ],
    );

    blocTest<QuestsBloc, QuestsState>(
      'a new save attempt clears the previous editorError',
      build: () {
        final repo = MockQuestsRepository();
        var attempts = 0;
        when(() => repo.createQuest(_newQuest)).thenAnswer((_) async {
          attempts++;
          if (attempts == 1) throw Exception('offline');
        });
        return QuestsBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const QuestsCreateRequested(_newQuest));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const QuestsCreateRequested(_newQuest));
      },
      expect: () => <Object?>[
        const QuestsState(editorStatus: QuestEditorStatus.saving),
        predicate<QuestsState>(
          (s) =>
              s.editorStatus == QuestEditorStatus.failure &&
              (s.editorError ?? '').contains('offline'),
        ),
        predicate<QuestsState>(
          (s) =>
              s.editorStatus == QuestEditorStatus.saving &&
              s.editorError == null,
        ),
        const QuestsState(editorStatus: QuestEditorStatus.saved),
      ],
    );

    blocTest<QuestsBloc, QuestsState>(
      'editor saves leave the list load path untouched',
      build: () {
        final repo = MockQuestsRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <Quest>[_editedQuest]));
        return QuestsBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const QuestsLoadRequested()),
      expect: () => const <QuestsState>[
        QuestsState(status: QuestsStatus.loading),
        QuestsState(status: QuestsStatus.loaded, items: <Quest>[_editedQuest]),
      ],
    );
  });
}
