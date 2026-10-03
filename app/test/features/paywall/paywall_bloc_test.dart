// P07 · Paywall — BLoC state machine and the Drift-backed repository.
//
// Scope note (Stage 2, iteration 2): `1_plan.md` §b's action events
// (`PaywallTrialStarted`, `PaywallRestoreRequested`) and the `PaywallAction`
// + `PaywallRequest` state now exist, so this file pins their transitions
// alongside the `PaywallStatus` machine. The tap-to-`app_state` contract is
// asserted from the view side (`paywall_view_test.dart`).
//
// What this file pins: the `PaywallStatus` machine (initial →
// loading → loaded | failure) over live, empty and erroring streams, the
// trial/restore action transitions (working → success | failure, with the
// request discriminator), and the repository contract against an in-memory
// Drift database under every seed.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/paywall/data/paywall_repository_impl.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/entities/subscription_status.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';

import '../../test_scope.dart';

/// The single annual plan, exactly as `P07-paywall.html` writes it:
/// `&mdash;` is an em dash (U+2014), not a hyphen.
const String _planTitle = 'Annual — £29.99/year';
const String _planSub = 'Just £2.50 a month, billed yearly';

/// The design's CTA caption (`P07-paywall.html` `.caption`), which the plan
/// detail repeats: note `after the 14-day trial` — with the article.
const String _planCaption =
    '£29.99/year after the 14-day trial. Cancel anytime in Settings.';

const List<PaywallPlan> _annualPlan = <PaywallPlan>[
  PaywallPlan(
    id: 'annual',
    title: _planTitle,
    detail: '$_planSub. $_planCaption',
  ),
];

const PaywallPlan _firstPlan = PaywallPlan(
  id: 'annual',
  title: _planTitle,
  detail: _planSub,
);

const PaywallPlan _secondPlan = PaywallPlan(
  id: 'annual-alt',
  title: 'Annual — £39.99/year',
  detail: 'Just £3.33 a month, billed yearly',
);

/// In-memory repository with a caller-controlled item stream, used to reach
/// the states the static Drift repository cannot produce (pending load,
/// empty, stream error, repeated live updates).
class _FakePaywallRepository implements PaywallRepository {
  _FakePaywallRepository({Stream<List<PaywallPlan>>? items})
    : _items = items ?? const Stream<List<PaywallPlan>>.empty();

  final Stream<List<PaywallPlan>> _items;

  int startTrialCalls = 0;
  int activateCalls = 0;

  /// `startTrial()` throws — the trial action reports failure.
  bool failTrial = false;

  /// `activate()` throws — the restore action reports failure.
  bool failRestore = false;

  /// The subscription the fake reports from `readSubscription()`. `null`
  /// keeps the legacy empty watch stream (the guard fails open and the
  /// trial is attempted).
  SubscriptionStatus? subscription;

  /// `readSubscription()` throws — the guard fails open to the trial.
  bool failSubscription = false;

  @override
  Future<List<PaywallPlan>> getItems() => _items.first;

  @override
  Stream<List<PaywallPlan>> watchItems() => _items;

  @override
  Stream<SubscriptionStatus> watchSubscription() {
    final current = subscription;
    if (current == null) return const Stream<SubscriptionStatus>.empty();
    return Stream<SubscriptionStatus>.value(current);
  }

  @override
  Future<SubscriptionStatus> readSubscription() async {
    if (failSubscription) throw Exception('offline');
    return subscription ??
        const SubscriptionStatus(status: 'trial', trialStart: null);
  }

  @override
  Future<void> startTrial() async {
    startTrialCalls++;
    if (failTrial) throw Exception('offline');
  }

  @override
  Future<void> activate() async {
    activateCalls++;
    if (failRestore) throw Exception('offline');
  }

  // Shared_batch3 co-parent name (see p07_bugs_test.dart): fakes report none.
  @override
  Future<String?> readCoParentName() => Future<String?>.value();
}

void main() {
  group('PaywallState', () {
    test('copyWith replaces only the given fields', () {
      const state = PaywallState();
      final loading = state.copyWith(status: PaywallStatus.loading);
      expect(loading.status, PaywallStatus.loading);
      expect(loading.items, state.items);
      expect(loading.errorMessage, isNull);

      final failed = loading.copyWith(
        status: PaywallStatus.failure,
        errorMessage: 'offline',
      );
      expect(failed.status, PaywallStatus.failure);
      expect(failed.errorMessage, 'offline');
      expect(failed.items, isEmpty);
    });

    test('equality is driven by status, items and error message', () {
      const a = PaywallState(status: PaywallStatus.loaded, items: _annualPlan);
      const b = PaywallState(status: PaywallStatus.loaded, items: _annualPlan);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const PaywallState()));
      expect(a, isNot(a.copyWith(status: PaywallStatus.loading)));
      expect(a, isNot(a.copyWith(errorMessage: 'offline')));
    });

    test('equality includes the action and request discriminator', () {
      const base = PaywallState();
      expect(
        base.copyWith(
          action: PaywallAction.working,
          request: PaywallRequest.trial,
        ),
        const PaywallState(
          action: PaywallAction.working,
          request: PaywallRequest.trial,
        ),
      );
      expect(
        base.copyWith(action: PaywallAction.success),
        isNot(base.copyWith(action: PaywallAction.failure)),
      );
      expect(
        base.copyWith(request: PaywallRequest.trial),
        isNot(base.copyWith(request: PaywallRequest.restore)),
      );
    });

    test('clearError resets a previous error message', () {
      const failed = PaywallState(errorMessage: 'offline');
      expect(failed.copyWith(clearError: true).errorMessage, isNull);
      expect(
        failed.copyWith(errorMessage: 'still here').errorMessage,
        'still here',
      );
    });

    test(
      'copyWith replaces the co-parent name, clearing it on a fresh load',
      () {
        const loaded = PaywallState(
          status: PaywallStatus.loaded,
          coParentName: 'James',
        );
        expect(
          loaded
              .copyWith(status: PaywallStatus.loading, clearCoParent: true)
              .coParentName,
          isNull,
        );
        expect(
          const PaywallState().copyWith(coParentName: 'Aisha').coParentName,
          'Aisha',
        );
      },
    );
  });

  group('PaywallBloc', () {
    test('starts initial with no items and no error', () {
      final bloc = PaywallBloc(repository: _FakePaywallRepository());
      addTearDown(bloc.close);

      expect(bloc.state, const PaywallState());
      expect(bloc.state.status, PaywallStatus.initial);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.errorMessage, isNull);
    });

    blocTest<PaywallBloc, PaywallState>(
      'load on the Drift repository emits loading then the annual plan',
      setUp: setUpTestScope,
      build: () => PaywallBloc(repository: GetIt.instance<PaywallRepository>()),
      act: (bloc) => bloc.add(const PaywallLoadRequested()),
      expect: () => <Matcher>[
        isA<PaywallState>().having(
          (state) => state.status,
          'status',
          PaywallStatus.loading,
        ),
        isA<PaywallState>()
            .having((state) => state.status, 'status', PaywallStatus.loaded)
            .having((state) => state.items.length, 'plan count', 1)
            .having((state) => state.items.single.id, 'plan id', 'annual')
            .having(
              (state) => state.items.single.title,
              'plan title',
              _planTitle,
            ),
      ],
    );

    blocTest<PaywallBloc, PaywallState>(
      'the load carries the co-parent name from the database',
      // `setUpTestScope` seeds `Seed.demo`, whose second parent is James.
      setUp: setUpTestScope,
      build: () => PaywallBloc(repository: GetIt.instance<PaywallRepository>()),
      act: (bloc) => bloc.add(const PaywallLoadRequested()),
      verify: (bloc) => expect(bloc.state.coParentName, 'James'),
    );

    blocTest<PaywallBloc, PaywallState>(
      'live repository stream: every emission becomes a loaded state',
      build: () => PaywallBloc(
        repository: _FakePaywallRepository(
          items: Stream<List<PaywallPlan>>.fromIterable(<List<PaywallPlan>>[
            <PaywallPlan>[_firstPlan],
            <PaywallPlan>[_firstPlan, _secondPlan],
          ]),
        ),
      ),
      act: (bloc) => bloc.add(const PaywallLoadRequested()),
      expect: () => <Matcher>[
        isA<PaywallState>().having(
          (state) => state.status,
          'status',
          PaywallStatus.loading,
        ),
        isA<PaywallState>()
            .having((state) => state.status, 'status', PaywallStatus.loaded)
            .having((state) => state.items, 'items', <PaywallPlan>[_firstPlan]),
        isA<PaywallState>()
            .having((state) => state.status, 'status', PaywallStatus.loaded)
            .having((state) => state.items, 'items', <PaywallPlan>[
              _firstPlan,
              _secondPlan,
            ]),
      ],
    );

    blocTest<PaywallBloc, PaywallState>(
      'an empty repository stream is a loaded state with no items',
      build: () => PaywallBloc(
        repository: _FakePaywallRepository(
          items: Stream<List<PaywallPlan>>.value(const <PaywallPlan>[]),
        ),
      ),
      act: (bloc) => bloc.add(const PaywallLoadRequested()),
      expect: () => const <PaywallState>[
        PaywallState(status: PaywallStatus.loading),
        PaywallState(status: PaywallStatus.loaded),
      ],
    );

    blocTest<PaywallBloc, PaywallState>(
      'a repository stream error becomes a failure state with the message',
      build: () => PaywallBloc(
        repository: _FakePaywallRepository(
          items: Stream<List<PaywallPlan>>.error(Exception('offline')),
        ),
      ),
      act: (bloc) => bloc.add(const PaywallLoadRequested()),
      expect: () => <Matcher>[
        isA<PaywallState>().having(
          (state) => state.status,
          'status',
          PaywallStatus.loading,
        ),
        isA<PaywallState>()
            .having((state) => state.status, 'status', PaywallStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('offline'),
            ),
      ],
    );

    test(
      'the load stream stays open, so a retry event is still accepted',
      () async {
        // `emit.forEach` keeps the handler alive for the bloc's lifetime; a
        // screen that retries must be able to re-add the load event while the
        // first stream is still pending, without the bloc throwing.
        final bloc = PaywallBloc(
          repository: _FakePaywallRepository(
            items: const Stream<List<PaywallPlan>>.empty(),
          ),
        );
        addTearDown(bloc.close);

        bloc.add(const PaywallLoadRequested());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, PaywallStatus.loading);

        bloc.add(const PaywallLoadRequested());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, PaywallStatus.loading);
      },
    );
  });

  group('PaywallBloc trial and restore actions', () {
    blocTest<PaywallBloc, PaywallState>(
      'PaywallTrialStarted calls startTrial, then trial success',
      build: () => PaywallBloc(repository: _FakePaywallRepository()),
      act: (bloc) => bloc.add(const PaywallTrialStarted()),
      expect: () => const <PaywallState>[
        PaywallState(
          action: PaywallAction.working,
          request: PaywallRequest.trial,
        ),
        PaywallState(
          action: PaywallAction.success,
          request: PaywallRequest.trial,
        ),
      ],
    );

    blocTest<PaywallBloc, PaywallState>(
      'a failing startTrial becomes trial failure with the message',
      build: () =>
          PaywallBloc(repository: _FakePaywallRepository()..failTrial = true),
      act: (bloc) => bloc.add(const PaywallTrialStarted()),
      expect: () => <Matcher>[
        isA<PaywallState>()
            .having((state) => state.action, 'action', PaywallAction.working)
            .having((state) => state.request, 'request', PaywallRequest.trial),
        isA<PaywallState>()
            .having((state) => state.action, 'action', PaywallAction.failure)
            .having((state) => state.request, 'request', PaywallRequest.trial)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('offline'),
            ),
      ],
    );

    blocTest<PaywallBloc, PaywallState>(
      'PaywallRestoreRequested calls activate, then restore success',
      build: () => PaywallBloc(repository: _FakePaywallRepository()),
      act: (bloc) => bloc.add(const PaywallRestoreRequested()),
      expect: () => const <PaywallState>[
        PaywallState(
          action: PaywallAction.working,
          request: PaywallRequest.restore,
        ),
        PaywallState(
          action: PaywallAction.success,
          request: PaywallRequest.restore,
        ),
      ],
    );

    blocTest<PaywallBloc, PaywallState>(
      'a failing activate becomes restore failure with the message',
      build: () =>
          PaywallBloc(repository: _FakePaywallRepository()..failRestore = true),
      act: (bloc) => bloc.add(const PaywallRestoreRequested()),
      expect: () => <Matcher>[
        isA<PaywallState>()
            .having((state) => state.action, 'action', PaywallAction.working)
            .having(
              (state) => state.request,
              'request',
              PaywallRequest.restore,
            ),
        isA<PaywallState>()
            .having((state) => state.action, 'action', PaywallAction.failure)
            .having((state) => state.request, 'request', PaywallRequest.restore)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('offline'),
            ),
      ],
    );

    test(
      'the trial delegates to startTrial, the restore to activate',
      () async {
        final repository = _FakePaywallRepository();
        final bloc = PaywallBloc(repository: repository);
        addTearDown(bloc.close);

        bloc.add(const PaywallTrialStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(repository.startTrialCalls, 1);
        expect(repository.activateCalls, 0);
        expect(bloc.state.request, PaywallRequest.trial);

        bloc.add(const PaywallRestoreRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(repository.activateCalls, 1);
        expect(bloc.state.request, PaywallRequest.restore);
      },
    );

    blocTest<PaywallBloc, PaywallState>(
      'P07-BUG-12: a trial tap while already active skips startTrial '
      'and succeeds as restore',
      build: () => PaywallBloc(
        repository: _FakePaywallRepository()
          ..subscription = const SubscriptionStatus(
            status: 'active',
            trialStart: null,
          ),
      ),
      act: (bloc) => bloc.add(const PaywallTrialStarted()),
      expect: () => const <PaywallState>[
        PaywallState(
          action: PaywallAction.working,
          request: PaywallRequest.trial,
        ),
        PaywallState(
          action: PaywallAction.success,
          request: PaywallRequest.restore,
        ),
      ],
    );

    test(
      'P07-BUG-12: the active-subscription guard never writes the trial',
      () async {
        final repository = _FakePaywallRepository()
          ..subscription = const SubscriptionStatus(
            status: 'active',
            trialStart: null,
          );
        final bloc = PaywallBloc(repository: repository);
        addTearDown(bloc.close);

        bloc.add(const PaywallTrialStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(repository.startTrialCalls, 0);
        expect(bloc.state.action, PaywallAction.success);
        // The view's restore branch (`setSubscription('active')`) is a
        // no-op for a paying family, unlike its trial branch.
        expect(bloc.state.request, PaywallRequest.restore);
      },
    );

    test(
      'P07-BUG-12: an unreadable subscription fails open to the trial',
      () async {
        final repository = _FakePaywallRepository()..failSubscription = true;
        final bloc = PaywallBloc(repository: repository);
        addTearDown(bloc.close);

        bloc.add(const PaywallTrialStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(repository.startTrialCalls, 1);
        expect(bloc.state.action, PaywallAction.success);
        expect(bloc.state.request, PaywallRequest.trial);
      },
    );
  });

  group('PaywallRepository (in-memory Drift)', () {
    late AppDatabase db;
    late PaywallRepositoryImpl repository;

    setUp(() {
      db = AppDatabase.memory();
      repository = PaywallRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    Future<AppStateData?> appStateRow() =>
        (db.select(db.appState)..where((a) => a.id.equals(1))).getSingle();

    test(
      'readSubscription is a one-shot read that never waits on a stream',
      () async {
        // P07-BUG-12's guard (`_alreadySubscribed`) awaits this before every
        // `startTrial()`. The per-seed statuses are pinned by the
        // `watchSubscription` tests above; what this pins is the *mechanism*.
        // The interface default is `watchSubscription().first`, and awaiting a
        // fresh Drift watch stream from inside a running widget test leaves
        // the guard pending forever — so a regression to the default has to
        // fail here on the budget, not hang the suite. The second half proves
        // the same read is never stale: it sees a write immediately.
        const budget = Duration(seconds: 1);
        await Seed.fresh(db);

        final first = await repository.readSubscription().timeout(budget);
        expect(first.status, 'trial');

        await repository.activate();

        final afterWrite = await repository.readSubscription().timeout(budget);
        expect(
          afterWrite.status,
          'active',
          reason: 'a one-shot read must see the latest write',
        );
      },
    );

    test('watchItems and getItems return the single annual plan', () async {
      await Seed.demo(db);

      final plans = await repository.watchItems().first;
      expect(plans, hasLength(1), reason: 'P07 sells exactly one plan');
      expect(plans.single.id, 'annual');
      expect(plans.single.title, _planTitle);
      expect(
        plans.single.detail,
        contains(_planSub),
        reason: 'the plan sub line is part of the repository copy',
      );
      expect(await repository.getItems(), plans);
    });

    test('the plan detail carries the design’s caption verbatim', () async {
      // `P07-paywall.html` `.caption` reads
      // `£29.99/year after the 14-day trial. Cancel anytime in Settings.`
      // — with the article “the”. Orchestrator COPY rule: the design's
      // typographic characters and wording exactly, so a variant without
      // the article must not reach the data layer (and from there a view
      // that renders `detail` verbatim).
      await Seed.demo(db);
      final detail = (await repository.watchItems().first).single.detail;

      expect(detail, contains(_planCaption));
      expect(
        detail,
        isNot(contains('after 14-day trial')),
        reason: 'the design says “after the 14-day trial”',
      );
      expect(
        detail,
        isNot(contains('\u2013')),
        reason: 'no en dash in the copy',
      );
      expect(detail, contains('£29.99/year'));
    });

    test('the plan list is identical under every seed', () async {
      final snapshots = <String>[];
      for (final seed in const <String>['demo', 'empty', 'fresh']) {
        if (seed == 'demo') {
          await Seed.demo(db);
        } else if (seed == 'empty') {
          await Seed.empty(db);
        } else {
          await Seed.fresh(db);
        }
        snapshots.add(
          (await repository.watchItems().first)
              .map((plan) => '${plan.id}/${plan.title}')
              .join(' | '),
        );
      }

      expect(snapshots.toSet(), hasLength(1), reason: snapshots.join('\n'));
      expect(snapshots.first, 'annual/$_planTitle');
    });

    test('Seed.demo already has an active subscription', () async {
      await Seed.demo(db);

      final status = await repository.watchSubscription().first;
      expect(status.status, 'active');
      expect(status.expired, isFalse);
      expect(status.trialStart, isNotNull);
    });

    test('Seed.empty is a live trial', () async {
      await Seed.empty(db);

      final status = await repository.watchSubscription().first;
      expect(status.status, 'trial');
      expect(status.expired, isFalse);
      expect(status.trialStart, isNotNull);
    });

    test('a fresh install reads trial with no start date yet', () async {
      await Seed.fresh(db);

      final status = await repository.watchSubscription().first;
      expect(status.status, 'trial');
      expect(status.expired, isFalse);
      expect(status.trialStart, isNull);
    });

    test(
      'readSubscription matches the watched status under every seed',
      () async {
        await Seed.demo(db);
        expect((await repository.readSubscription()).status, 'active');

        await Seed.empty(db);
        final empty = await repository.readSubscription();
        expect(empty.status, 'trial');
        expect(empty.trialStart, isNotNull);

        await Seed.fresh(db);
        final fresh = await repository.readSubscription();
        expect(fresh.status, 'trial');
        expect(fresh.trialStart, isNull);
      },
    );

    test(
      'startTrial records the status, a UTC start and the family zone',
      () async {
        await Seed.fresh(db);
        final before = DateTime.now().toUtc();

        await repository.startTrial();

        final row = await appStateRow();
        expect(row?.subscriptionStatus, 'trial');
        expect(row?.trialStart, isNotNull);
        expect(
          row!.trialStart!.toUtc().isAfter(
            before.subtract(const Duration(minutes: 1)),
          ),
          isTrue,
          reason: 'the trial start must be written as “now”, not left unset',
        );
        expect(row.trialStartTz, 'Europe/London');

        // The live stream reports the new status (the router's paywall
        // redirect reads the same stream).
        final status = await repository.watchSubscription().first;
        expect(status.status, 'trial');
      },
    );

    test(
      'activate marks the subscription active and keeps the trial date',
      () async {
        await Seed.fresh(db);
        await repository.startTrial();
        final trialStart = (await appStateRow())?.trialStart;

        await repository.activate();

        final row = await appStateRow();
        expect(row?.subscriptionStatus, 'active');
        expect(
          row?.trialStart,
          trialStart,
          reason: 'restoring purchases must not move the trial start date',
        );
      },
    );

    test(
      'activate then startTrial is reachable (trial wins, by design)',
      () async {
        await Seed.fresh(db);
        await repository.activate();
        expect((await appStateRow())?.subscriptionStatus, 'active');

        await repository.startTrial();
        expect((await appStateRow())?.subscriptionStatus, 'trial');
      },
    );

    test('watchSubscription emits again when the row changes', () async {
      await Seed.fresh(db);
      final emissions = <String>[];
      final sub = repository.watchSubscription().listen(
        (status) => emissions.add(status.status),
      );
      addTearDown(sub.cancel);

      await repository.activate();
      await repository.startTrial();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emissions.first, 'trial');
      expect(
        emissions,
        containsAllInOrder(<String>['trial', 'active', 'trial']),
      );
    });
  });
}
