import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_bloc.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_event.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_state.dart';

class MockParentalGateRepository extends Mock implements ParentalGateRepository;

/// The plan's canonical challenge: 7 × 6 = 42, "seven times six".
const _sevenSix = ParentalGateChallenge(
  id: '2026-1-6',
  title: 'Grown-ups only',
  detail: 'This keeps settings and purchases safe.',
  a: 7,
  b: 6,
);

ParentalGateBloc blocWithChallenge(MockParentalGateRepository repo) {
  when(
    repo.watchItems,
  ).thenAnswer((_) => Stream.value(const <ParentalGateChallenge>[_sevenSix]));
  return ParentalGateBloc(repository: repo);
}

/// Adds [event] only after the gate has loaded, so the emission sequence
/// is deterministic (no race between the stream delivery and the action).
Future<void> addAfterLoaded(
  ParentalGateBloc bloc,
  ParentalGateEvent event,
) async {
  bloc.add(const ParentalGateLoadRequested());
  await bloc.stream.firstWhere((s) => s.status == ParentalGateStatus.loaded);
  bloc.add(event);
}

void main() {
  group('ParentalGateState', () {
    test('defaults are idle and empty', () {
      const state = ParentalGateState();
      expect(state.status, ParentalGateStatus.initial);
      expect(state.items, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.entered, isEmpty);
      expect(state.attempts, 0);
      expect(state.unlocked, isFalse);
      expect(state.challenge, isNull);
      expect(state.expectedLength, 0);
      expect(state.isComplete, isFalse);
    });

    test('helpers read the live challenge', () {
      const state = ParentalGateState(
        status: ParentalGateStatus.loaded,
        items: <ParentalGateChallenge>[_sevenSix],
        entered: '4',
      );
      expect(state.challenge, _sevenSix);
      expect(state.expectedLength, 2);
      expect(state.isComplete, isFalse);
      expect(state.copyWith(entered: '42').isComplete, isTrue);
    });

    test('states with the same entry fields are equal', () {
      const a = ParentalGateState(entered: '4', attempts: 1);
      const b = ParentalGateState(entered: '4', attempts: 1);
      const different = ParentalGateState(entered: '42', unlocked: true);
      expect(a, b);
      expect(a, isNot(different));
    });
  });

  group('ParentalGateChallenge', () {
    test('question words and verify', () {
      expect(_sevenSix.question, 'seven times six');
      expect(_sevenSix.answer, 42);
      expect(_sevenSix.verify(42), isTrue);
      expect(_sevenSix.verify(24), isFalse);
    });

    test('word map covers 2–9 with a numeric fallback', () {
      String question(int n) => ParentalGateChallenge(
        id: 'x',
        title: 't',
        detail: 'd',
        a: n,
        b: 2,
      ).question;
      expect(question(2), 'two times two');
      expect(question(9), 'nine times two');
      expect(question(10), '10 times two');
    });
  });

  group('ParentalGateBloc load', () {
    blocTest<ParentalGateBloc, ParentalGateState>(
      'load emits loading then loaded with the challenge',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) => bloc.add(const ParentalGateLoadRequested()),
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'stream error emits failure with a message',
      build: () {
        final repo = MockParentalGateRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ParentalGateChallenge>>.error(Exception('boom')),
        );
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ParentalGateLoadRequested()),
      expect: () => [
        const ParentalGateState(status: ParentalGateStatus.loading),
        predicate<ParentalGateState>(
          (s) =>
              s.status == ParentalGateStatus.failure &&
              (s.errorMessage ?? '').contains('boom'),
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'disabled gate loads with an empty list',
      build: () {
        final repo = MockParentalGateRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <ParentalGateChallenge>[]));
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const ParentalGateLoadRequested()),
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(status: ParentalGateStatus.loaded),
      ],
    );
  });

  group('ParentalGateBloc entry', () {
    blocTest<ParentalGateBloc, ParentalGateState>(
      'digits append one box at a time without unlocking',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) => addAfterLoaded(bloc, const ParentalGateDigitEntered('4')),
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '4',
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'the correct full answer unlocks',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDigitEntered('2'));
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '4',
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '42',
          unlocked: true,
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'a wrong full answer clears the entry and counts an attempt',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDigitEntered('3'));
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '4',
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          attempts: 1,
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'extra digits past full length are ignored',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDigitEntered('2'))
          ..add(const ParentalGateDigitEntered('9'));
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '4',
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '42',
          unlocked: true,
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'non-digit input is ignored',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('x'))
          ..add(const ParentalGateDigitEntered(''))
          ..add(const ParentalGateDigitEntered('12'));
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'delete drops the last digit',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDeletePressed());
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '4',
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'delete on an empty entry is a no-op',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) => addAfterLoaded(bloc, const ParentalGateDeletePressed()),
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'acknowledge resets the one-shot unlock',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDigitEntered('2'));
        await bloc.stream.firstWhere((s) => s.unlocked);
        bloc.add(const ParentalGateUnlockAcknowledged());
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '4',
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '42',
          unlocked: true,
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '42',
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'digits before load and on a disabled gate do nothing',
      build: () {
        final repo = MockParentalGateRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <ParentalGateChallenge>[]));
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) async {
        // Before any load: absorbed.
        bloc.add(const ParentalGateDigitEntered('4'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        // Disabled gate (no challenge): absorbed.
        bloc.add(const ParentalGateDigitEntered('4'));
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(status: ParentalGateStatus.loaded),
      ],
    );
  });
}
