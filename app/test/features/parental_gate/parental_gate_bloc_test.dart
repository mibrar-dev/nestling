import 'dart:async';

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

/// A second fixed challenge (3 × 9 = 27) for challenge-swap tests.
const _threeNine = ParentalGateChallenge(
  id: '2026-10-4',
  title: 'Grown-ups only',
  detail: 'This keeps settings and purchases safe.',
  a: 3,
  b: 9,
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

  group('ParentalGateBloc retry, re-entry and guards after unlock', () {
    // Live `settings` watch: a broadcast controller stands in for the
    // settings row so a test can flip the gate off mid-session. It is closed
    // without awaiting (a broadcast controller never blocks on close).
    late StreamController<List<ParentalGateChallenge>> settings;
    var gateOn = true;
    setUp(() {
      settings = StreamController<List<ParentalGateChallenge>>.broadcast();
      gateOn = true;
    });
    tearDown(() {
      unawaited(settings.close());
    });

    blocTest<ParentalGateBloc, ParentalGateState>(
      'a second LoadRequested recovers from failure (the Try again path)',
      build: () {
        final repo = MockParentalGateRepository();
        var subscriptions = 0;
        when(repo.watchItems).thenAnswer((_) {
          subscriptions++;
          return subscriptions == 1
              ? Stream<List<ParentalGateChallenge>>.error(Exception('boom'))
              : Stream.value(const <ParentalGateChallenge>[_sevenSix]);
        });
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.failure,
        );
        // Exactly what the view's ghost `Try again` button adds.
        bloc.add(const ParentalGateLoadRequested());
      },
      expect: () => [
        const ParentalGateState(status: ParentalGateStatus.loading),
        predicate<ParentalGateState>(
          (s) =>
              s.status == ParentalGateStatus.failure &&
              (s.errorMessage ?? '').contains('boom'),
        ),
        // The retry clears the stale failure text (clearError): the loading
        // and loaded states below carry no errorMessage. The view only reads
        // `errorMessage` while failing, so either way it never draws stale.
        predicate<ParentalGateState>(
          (s) =>
              s.status == ParentalGateStatus.loading && s.errorMessage == null,
        ),
        predicate<ParentalGateState>(
          (s) =>
              s.status == ParentalGateStatus.loaded &&
              s.challenge == _sevenSix &&
              s.errorMessage == null,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.status, ParentalGateStatus.loaded);
        expect(bloc.state.challenge, _sevenSix);
        expect(bloc.state.errorMessage, isNull);
      },
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'digits and delete are ignored once unlocked',
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
        // Both are absorbed: the gate is already open.
        bloc
          ..add(const ParentalGateDigitEntered('7'))
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
          entered: '42',
          unlocked: true,
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'acknowledging without an unlock emits nothing',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc.add(const ParentalGateUnlockAcknowledged());
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
      'two wrong answers count two attempts and clear both times',
      build: () => blocWithChallenge(MockParentalGateRepository()),
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDigitEntered('3'));
        await bloc.stream.firstWhere((s) => s.attempts == 1);
        bloc
          ..add(const ParentalGateDigitEntered('5'))
          ..add(const ParentalGateDigitEntered('5'));
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
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          entered: '5',
          attempts: 1,
        ),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
          attempts: 2,
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'a settings change mid-session re-emits loaded with the new list',
      build: () {
        final repo = MockParentalGateRepository();
        // Seeds with the current switch value, then forwards every change —
        // exactly how `watchItems()` reads the Drift settings row.
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ParentalGateChallenge>>.multi((controller) {
            controller.add(
              gateOn
                  ? const <ParentalGateChallenge>[_sevenSix]
                  : const <ParentalGateChallenge>[],
            );
            settings.stream.listen(controller.add);
          }),
        );
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        // P16 flips the switch off: the live list empties and the view
        // passes straight through.
        gateOn = false;
        settings.add(const <ParentalGateChallenge>[]);
      },
      expect: () => const <ParentalGateState>[
        ParentalGateState(status: ParentalGateStatus.loading),
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_sevenSix],
        ),
        ParentalGateState(status: ParentalGateStatus.loaded),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'a new challenge resets the typed entry and attempts (P17-BUG-3)',
      build: () {
        final repo = MockParentalGateRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ParentalGateChallenge>>.multi((controller) {
            controller.add(const <ParentalGateChallenge>[_sevenSix]);
            settings.stream.listen(controller.add);
          }),
        );
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc
          ..add(const ParentalGateDigitEntered('4'))
          ..add(const ParentalGateDigitEntered('3'));
        await bloc.stream.firstWhere((s) => s.attempts == 1);
        // A new question arrives mid-entry (any settings write re-emits the
        // watch): the stale digits belonged to the old answer.
        settings.add(const <ParentalGateChallenge>[_threeNine]);
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
        // Same boxes, new challenge: entry cleared, attempts reset.
        ParentalGateState(
          status: ParentalGateStatus.loaded,
          items: <ParentalGateChallenge>[_threeNine],
        ),
      ],
    );

    blocTest<ParentalGateBloc, ParentalGateState>(
      'a same-challenge re-emit keeps the typed entry',
      build: () {
        final repo = MockParentalGateRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ParentalGateChallenge>>.multi((controller) {
            controller.add(const <ParentalGateChallenge>[_sevenSix]);
            settings.stream.listen(controller.add);
          }),
        );
        return ParentalGateBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ParentalGateLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ParentalGateStatus.loaded,
        );
        bloc.add(const ParentalGateDigitEntered('4'));
        await bloc.stream.firstWhere((s) => s.entered == '4');
        // An unrelated settings write re-emits the identical challenge:
        // the half-typed answer must survive (and emit nothing new).
        settings.add(const <ParentalGateChallenge>[_sevenSix]);
        await Future<void>.delayed(const Duration(milliseconds: 20));
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
      ],
      verify: (bloc) => expect(bloc.state.entered, '4'),
    );
  });

  group('ParentalGateChallenge word map across the whole range', () {
    test('every product the gate can produce has a spelled-out question', () {
      for (var a = 2; a <= 9; a++) {
        for (var b = 2; b <= 9; b++) {
          final challenge = ParentalGateChallenge(
            id: '$a-$b',
            title: 'Grown-ups only',
            detail: 'This keeps settings and purchases safe.',
            a: a,
            b: b,
          );
          expect(challenge.question, isNot(contains(RegExp(r'\d'))));
          expect(challenge.answer, a * b);
          // 4..81 ⇒ the design's 56×64 boxes are always 1 or 2 wide.
          expect(challenge.answer.toString().length, inInclusiveRange(1, 2));
        }
      }
    });
  });
}
