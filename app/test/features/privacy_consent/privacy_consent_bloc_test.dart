// P04 — PrivacyConsentBloc state machine and the Drift-backed repository
// contract.
//
// The bloc has two events (`PrivacyConsentLoadRequested`,
// `PrivacyConsentCrashToggled`) and four statuses. The static 4-row copy
// lives in the view; the bloc only carries `items` (foundation contract) +
// the live `crashConsent` flag driving the opt-in toggle.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';

import '../../test_scope.dart';

class _MockPrivacyConsentRepository extends Mock
    implements PrivacyConsentRepository;

late _MockPrivacyConsentRepository _delegatingRepo;

/// Hand-written repository for the iteration-2 optimistic-emit paths: a
/// scripted stream plus a write callback that may throw, so the bloc can be
/// driven through two in-flight writes.
class _RacyRepository implements PrivacyConsentRepository {
  _RacyRepository(this._items, this._onWrite);

  final Stream<List<ConsentOption>> _items;
  final void Function() _onWrite;
  final List<bool> writes = <bool>[];

  @override
  Future<List<ConsentOption>> getItems() => _items.first;

  @override
  Stream<List<ConsentOption>> watchItems() => _items;

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) async {
    writes.add(consent);
    _onWrite();
  }
}

const List<ConsentOption> _crashOff = <ConsentOption>[
  ConsentOption(id: 'no-ads', title: 'a', detail: 'a', enabled: true),
  ConsentOption(id: 'nickname', title: 'b', detail: 'b', enabled: true),
  ConsentOption(id: 'uk-data', title: 'c', detail: 'c', enabled: true),
  ConsentOption(id: 'delete', title: 'd', detail: 'd', enabled: true),
  ConsentOption(
    id: ConsentOptionIds.crash,
    title: 'e',
    detail: 'e',
    enabled: false,
  ),
];

const List<ConsentOption> _crashOn = <ConsentOption>[
  ConsentOption(id: 'no-ads', title: 'a', detail: 'a', enabled: true),
  ConsentOption(id: 'nickname', title: 'b', detail: 'b', enabled: true),
  ConsentOption(id: 'uk-data', title: 'c', detail: 'c', enabled: true),
  ConsentOption(id: 'delete', title: 'd', detail: 'd', enabled: true),
  ConsentOption(
    id: ConsentOptionIds.crash,
    title: 'e',
    detail: 'e',
    enabled: true,
  ),
];

void main() {
  group('PrivacyConsentEvent', () {
    test('CrashToggled carries its value into props/equality', () {
      const on = PrivacyConsentCrashToggled(value: true);
      const alsoOn = PrivacyConsentCrashToggled(value: true);
      const off = PrivacyConsentCrashToggled(value: false);

      expect(on, alsoOn);
      expect(on.hashCode, alsoOn.hashCode);
      expect(on, isNot(off));
      expect(on.value, isTrue);
      expect(off.value, isFalse);
      expect(
        const PrivacyConsentLoadRequested(),
        const PrivacyConsentLoadRequested(),
      );
      expect(const PrivacyConsentLoadRequested(), isNot(on));
    });
  });

  group('PrivacyConsentState', () {
    test('copyWith replaces only the given fields', () {
      const state = PrivacyConsentState();
      expect(state.crashConsent, isFalse);
      final loading = state.copyWith(status: PrivacyConsentStatus.loading);
      expect(loading.status, PrivacyConsentStatus.loading);
      expect(loading.items, state.items);
      expect(loading.crashConsent, isFalse);

      final on = loading.copyWith(crashConsent: true);
      expect(on.crashConsent, isTrue);
      expect(on.status, PrivacyConsentStatus.loading);
    });

    test('errorMessage is sticky by default but explicitly clearable', () {
      const failed = PrivacyConsentState(
        status: PrivacyConsentStatus.failure,
        errorMessage: 'offline',
      );

      // Omitted => kept.
      expect(failed.copyWith().errorMessage, 'offline');
      // Explicit null => cleared, so a later success never shows stale text.
      final cleared = failed.copyWith(
        status: PrivacyConsentStatus.loaded,
        errorMessage: null,
      );
      expect(cleared.errorMessage, isNull);
    });

    test('equality is driven by status, items, crash flag and error', () {
      const a = PrivacyConsentState(
        status: PrivacyConsentStatus.loaded,
        items: _crashOff,
      );
      const b = PrivacyConsentState(
        status: PrivacyConsentStatus.loaded,
        items: _crashOff,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const PrivacyConsentState()));
      expect(a, isNot(a.copyWith(crashConsent: true)));
    });
  });

  group('PrivacyConsentBloc', () {
    test('starts initial with no items, consent off, no error', () {
      final bloc = PrivacyConsentBloc(
        repository: _MockPrivacyConsentRepository(),
      );
      addTearDown(bloc.close);

      expect(bloc.state, const PrivacyConsentState());
      expect(bloc.state.status, PrivacyConsentStatus.initial);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.crashConsent, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'load on the Drift repository emits loading then loaded, consent off',
      setUp: setUpTestScope,
      build: () => PrivacyConsentBloc(
        repository: GetIt.instance<PrivacyConsentRepository>(),
      ),
      act: (bloc) => bloc.add(const PrivacyConsentLoadRequested()),
      expect: () => <Matcher>[
        isA<PrivacyConsentState>().having(
          (s) => s.status,
          'status',
          PrivacyConsentStatus.loading,
        ),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.crashConsent, 'crashConsent', isFalse)
            .having((s) => s.items.length, 'items', 5),
      ],
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'live stream: crash row true becomes crashConsent true',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ConsentOption>>.fromIterable(<List<ConsentOption>>[
            _crashOff,
            _crashOn,
          ]),
        );
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const PrivacyConsentLoadRequested()),
      expect: () => const <PrivacyConsentState>[
        PrivacyConsentState(status: PrivacyConsentStatus.loading),
        PrivacyConsentState(
          status: PrivacyConsentStatus.loaded,
          items: _crashOff,
        ),
        PrivacyConsentState(
          status: PrivacyConsentStatus.loaded,
          items: _crashOn,
          crashConsent: true,
        ),
      ],
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'an empty items stream is loaded with consent off',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ConsentOption>>.value(const <ConsentOption>[]),
        );
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const PrivacyConsentLoadRequested()),
      expect: () => const <PrivacyConsentState>[
        PrivacyConsentState(status: PrivacyConsentStatus.loading),
        PrivacyConsentState(status: PrivacyConsentStatus.loaded),
      ],
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'a stream error becomes failure with the message',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ConsentOption>>.error(Exception('offline')),
        );
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const PrivacyConsentLoadRequested()),
      expect: () => <Matcher>[
        isA<PrivacyConsentState>().having(
          (s) => s.status,
          'status',
          PrivacyConsentStatus.loading,
        ),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage', contains('offline')),
      ],
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'CrashToggled(true) calls setCrashConsent; the stream re-emits true',
      setUp: setUpTestScope,
      build: () => PrivacyConsentBloc(
        repository: GetIt.instance<PrivacyConsentRepository>(),
      ),
      act: (bloc) async {
        bloc.add(const PrivacyConsentLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PrivacyConsentCrashToggled(value: true));
      },
      expect: () => <Matcher>[
        isA<PrivacyConsentState>().having(
          (s) => s.status,
          'status',
          PrivacyConsentStatus.loading,
        ),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.crashConsent, 'crashConsent', isFalse),
        // Optimistic emit answers the tap instantly; the stream re-emit
        // below carries a new items list with the same values.
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.crashConsent, 'crashConsent', isTrue),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.crashConsent, 'crashConsent', isTrue)
            .having((s) => s.items.length, 'items', 5),
      ],
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'items without a crash row load with consent off',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream<List<ConsentOption>>.value(_crashOff.take(4).toList()),
        );
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const PrivacyConsentLoadRequested()),
      expect: () => const <PrivacyConsentState>[
        PrivacyConsentState(status: PrivacyConsentStatus.loading),
        PrivacyConsentState(
          status: PrivacyConsentStatus.loaded,
          items: <ConsentOption>[
            ConsentOption(id: 'no-ads', title: 'a', detail: 'a', enabled: true),
            ConsentOption(
              id: 'nickname',
              title: 'b',
              detail: 'b',
              enabled: true,
            ),
            ConsentOption(
              id: 'uk-data',
              title: 'c',
              detail: 'c',
              enabled: true,
            ),
            ConsentOption(id: 'delete', title: 'd', detail: 'd', enabled: true),
          ],
        ),
      ],
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'CrashToggled delegates to the repository',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream<List<ConsentOption>>.value(_crashOff));
        when(() => repo.setCrashConsent(consent: true))
            .thenAnswer((_) async {});
        _delegatingRepo = repo;
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const PrivacyConsentLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PrivacyConsentCrashToggled(value: true));
      },
      verify: (_) {
        verify(() => _delegatingRepo.setCrashConsent(consent: true)).called(1);
      },
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'CrashToggled(false) writes the OFF path too',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream<List<ConsentOption>>.value(_crashOn));
        when(() => repo.setCrashConsent(consent: false))
            .thenAnswer((_) async {});
        _delegatingRepo = repo;
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const PrivacyConsentLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PrivacyConsentCrashToggled(value: false));
      },
      expect: () => const <PrivacyConsentState>[
        PrivacyConsentState(status: PrivacyConsentStatus.loading),
        PrivacyConsentState(
          status: PrivacyConsentStatus.loaded,
          items: _crashOn,
          crashConsent: true,
        ),
        // Optimistic emit: the switch answers instantly; the static mock
        // stream never re-emits, so this is the final state.
        PrivacyConsentState(
          status: PrivacyConsentStatus.loaded,
          items: _crashOn,
        ),
      ],
      verify: (_) {
        verify(() => _delegatingRepo.setCrashConsent(consent: false)).called(1);
      },
    );

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'a toggle write error becomes failure but keeps prior items',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream<List<ConsentOption>>.value(_crashOff));
        when(() => repo.setCrashConsent(consent: true))
            .thenThrow(Exception('disk full'));
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const PrivacyConsentLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PrivacyConsentCrashToggled(value: true));
      },
      expect: () => <Matcher>[
        isA<PrivacyConsentState>().having(
          (s) => s.status,
          'status',
          PrivacyConsentStatus.loading,
        ),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.items, 'items', _crashOff),
        // Optimistic emit flips first; the failed write reverts to the
        // prior consent below.
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.crashConsent, 'crashConsent', isTrue),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.failure)
            .having((s) => s.items, 'items', _crashOff)
            .having((s) => s.crashConsent, 'crashConsent', isFalse)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('disk full'),
            ),
      ],
    );

    test(
      'Drift round-trip: toggle writes through watchItems (no reload event)',
      () async {
        await setUpTestScope();
        final repository = GetIt.instance<PrivacyConsentRepository>();
        final bloc = PrivacyConsentBloc(repository: repository);
        addTearDown(bloc.close);
        bloc.add(const PrivacyConsentLoadRequested());

        final loadedOff = await bloc.stream.firstWhere(
          (s) => s.status == PrivacyConsentStatus.loaded,
        );
        expect(loadedOff.crashConsent, isFalse);

        bloc.add(const PrivacyConsentCrashToggled(value: true));
        // The optimistic emit flips the flag with stale items; wait for the
        // reconciled state whose crash row is enabled too.
        final loadedOn = await bloc.stream.firstWhere(
          (s) =>
              s.status == PrivacyConsentStatus.loaded &&
              s.crashConsent &&
              s.items
                  .where((i) => i.id == ConsentOptionIds.crash)
                  .single
                  .enabled,
        );
        expect(
          loadedOn.items
              .where((i) => i.id == ConsentOptionIds.crash)
              .single
              .enabled,
          isTrue,
        );
        expect(
          await PrivacyConsentRepositoryImpl(db: GetIt.instance<AppDatabase>())
              .watchCrashConsent()
              .first,
          isTrue,
        );
      },
    );

    test('Drift round-trip: ON then back OFF through the same bloc', () async {
      await setUpTestScope();
      final repository = GetIt.instance<PrivacyConsentRepository>();
      final bloc = PrivacyConsentBloc(repository: repository);
      addTearDown(bloc.close);
      bloc.add(const PrivacyConsentLoadRequested());
      await bloc.stream.firstWhere(
        (s) => s.status == PrivacyConsentStatus.loaded,
      );

      bloc.add(const PrivacyConsentCrashToggled(value: true));
      await bloc.stream.firstWhere(
        (s) => s.status == PrivacyConsentStatus.loaded && s.crashConsent,
      );

      bloc.add(const PrivacyConsentCrashToggled(value: false));
      final backOff = await bloc.stream.firstWhere(
        (s) =>
            s.status == PrivacyConsentStatus.loaded &&
            !s.crashConsent &&
            !s.items
                .where((i) => i.id == ConsentOptionIds.crash)
                .single
                .enabled,
      );
      expect(backOff.crashConsent, isFalse);
      expect(
        await PrivacyConsentRepositoryImpl(db: GetIt.instance<AppDatabase>())
            .watchCrashConsent()
            .first,
        isFalse,
      );
    });

    blocTest<PrivacyConsentBloc, PrivacyConsentState>(
      'a failed OFF write keeps the prior ON consent in state',
      build: () {
        final repo = _MockPrivacyConsentRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream<List<ConsentOption>>.value(_crashOn));
        when(() => repo.setCrashConsent(consent: false))
            .thenThrow(Exception('read only'));
        return PrivacyConsentBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const PrivacyConsentLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PrivacyConsentCrashToggled(value: false));
      },
      expect: () => <Matcher>[
        isA<PrivacyConsentState>().having(
          (s) => s.status,
          'status',
          PrivacyConsentStatus.loading,
        ),
        isA<PrivacyConsentState>().having(
          (s) => s.crashConsent,
          'crashConsent',
          isTrue,
        ),
        // Optimistic emit flips to OFF first; the failed write reverts to
        // the prior ON consent below.
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.loaded)
            .having((s) => s.crashConsent, 'crashConsent', isFalse),
        isA<PrivacyConsentState>()
            .having((s) => s.status, 'status', PrivacyConsentStatus.failure)
            .having((s) => s.crashConsent, 'crashConsent', isTrue)
            .having((s) => s.items, 'items', _crashOn)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('read only'),
            ),
      ],
    );

    // Iteration 2 added the optimistic emit. Two quick taps mean two writes in
    // flight; if the FIRST one fails after the second already succeeded, the
    // revert must not leave the switch showing a value the database does not
    // hold. The `watchItems` re-emit after the good write is what settles it.
    test(
      'a failed first write does not strand the switch after a later success',
      () async {
        final controller = StreamController<List<ConsentOption>>();
        addTearDown(controller.close);
        var writes = 0;
        final repository = _RacyRepository(controller.stream, () {
          writes += 1;
          // First write fails, the second succeeds.
          if (writes == 1) {
            throw Exception('transient');
          }
        });

        final bloc = PrivacyConsentBloc(repository: repository);
        addTearDown(bloc.close);
        controller.add(_crashOff);
        bloc.add(const PrivacyConsentLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == PrivacyConsentStatus.loaded,
        );

        // Tap ON (fails) then immediately OFF (succeeds).
        bloc
          ..add(const PrivacyConsentCrashToggled(value: true))
          ..add(const PrivacyConsentCrashToggled(value: false));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(repository.writes, <bool>[true, false]);
        controller.add(_crashOff);
        final settled = await bloc.stream.firstWhere(
          (s) => s.status == PrivacyConsentStatus.loaded && !s.crashConsent,
        );

        // Whatever the transient failure did on the way, the state the parent
        // is left with matches the last write.
        expect(settled.crashConsent, isFalse);
        expect(settled.status, PrivacyConsentStatus.loaded);
        expect(settled.errorMessage, isNull);
      },
    );

    test('a stream emission after a failure clears the error', () async {
      final controller = StreamController<List<ConsentOption>>();
      addTearDown(controller.close);
      final bloc = PrivacyConsentBloc(
        repository: _RacyRepository(controller.stream, () {
          throw Exception('transient');
        }),
      );
      addTearDown(bloc.close);

      controller.add(_crashOff);
      bloc.add(const PrivacyConsentLoadRequested());
      await bloc.stream.firstWhere(
        (s) => s.status == PrivacyConsentStatus.loaded,
      );
      bloc.add(const PrivacyConsentCrashToggled(value: true));
      final failed = await bloc.stream.firstWhere(
        (s) => s.status == PrivacyConsentStatus.failure,
      );
      expect(failed.errorMessage, contains('transient'));

      controller.add(_crashOff);
      final recovered = await bloc.stream.firstWhere(
        (s) =>
            s.status == PrivacyConsentStatus.loaded && s.errorMessage == null,
      );
      expect(
        recovered.errorMessage,
        isNull,
        reason: 'a healthy emission must not keep showing a stale error',
      );
    });
  });
}
