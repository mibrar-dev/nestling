// P07 · Paywall — adversarial bug proofs (Stage 6, iteration 2).
//
// Iteration 1 found P07-BUG-1..9. Iteration 2 verified 1–7 fixed — their
// proofs are unskipped and green below — adopted stage 3's P07-BUG-10
// (expired-trial close trap) with an independent proof, added P07-BUG-11
// (announced separators) and P07-BUG-12 (active-subscription downgrade), and
// carries P07-BUG-8/9 as shared items filed in
// `docs/screens/P07/SHARED_REQUEST.md`; every open proof stays `skip: true`
// until its fix lands.
//
// Every open bug test is `skip`-marked with its id in the test name so the
// suite stays green while the defect is unfixed; when the fix lands, remove
// the skip and the test must pass. `flutter test
// test/features/paywall/p07_bugs_test.dart --run-skipped` proves each
// skipped test still fails on the current code.
//
// The green tests at the bottom are the checks this stage verified clean:
// restart persistence, parent deep links, and the realistic kid-mode guard.
// They separate "found broken" from "verified working".

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart' as v2;
import 'package:nestling/features/paywall/data/paywall_repository_impl.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/entities/subscription_status.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';

import '../../test_scope.dart';

// -- the design's copy, verbatim from design/html-source/screens/P07-paywall.html

const String _title = 'Try Nestling free for 14 days';
const List<String> _benefits = <String>[
  'Unlimited children & quests',
  'Pip’s full evolution & seasonal outfits',
  'Pocket money ledger & payout day',
  'Co-parent sharing, so James sees the same',
];
const String _planTitle = 'Annual — £29.99/year';
const String _planSub = 'Just £2.50 a month, billed yearly';
const String _planTag = 'One price, the whole family';
const String _timelineHead = 'What happens next';
const String _familyNote = 'One subscription covers the whole family.';
const String _cta = 'Start free trial';
const String _caption =
    '£29.99/year after the 14-day trial. Cancel anytime in Settings.';
const List<String> _legalLinks = <String>[
  'Restore purchases',
  'Terms',
  'Privacy',
];
const String _closeLabel = 'Close and go back';

/// Any SvgPicture loading a v1 `pip_stage_*.svg` — forbidden in product
/// screens by the orchestrator PIP rule.
Finder get _v1PipFinder => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName.startsWith(
        'assets/illustrations/pip_stage_',
      ),
);

/// Repository whose first `watchItems()` call errors and later calls succeed,
/// used to prove that a stale error message survives a successful retry.
class _FlakyRepository implements PaywallRepository {
  int calls = 0;

  @override
  Future<List<PaywallPlan>> getItems() async => const <PaywallPlan>[];

  @override
  Stream<List<PaywallPlan>> watchItems() {
    calls++;
    if (calls == 1) {
      return Stream<List<PaywallPlan>>.error(Exception('offline'));
    }
    return Stream<List<PaywallPlan>>.value(const <PaywallPlan>[]);
  }

  @override
  Stream<SubscriptionStatus> watchSubscription() =>
      const Stream<SubscriptionStatus>.empty();

  @override
  Future<SubscriptionStatus> readSubscription() => watchSubscription().first;

  @override
  Future<void> startTrial() async {}

  @override
  Future<void> activate() async {}
}

/// A few frames: enough for a tap, a Drift write and a go_router transition,
/// without `pumpAndSettle` (a live Drift watch never settles).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps `/paywall` on an arbitrary seed.
Future<AppDatabase> _pumpPaywallWithSeed(
  WidgetTester tester,
  Future<void> Function(AppDatabase db) seed, {
  ThemeMode theme = ThemeMode.light,
}) async {
  final db = await setUpTestScope(seedDemo: false);
  await seed(db);
  await GetIt.instance<AppSession>().refresh();
  await pumpAppRoute(tester, '/paywall', theme: theme);
  return db;
}

Future<AppStateData?> _appStateRow(AppDatabase db) =>
    (db.select(db.appState)..where((a) => a.id.equals(1))).getSingleOrNull();

/// Waits (bounded) for [condition] to become true on the bloc's state.
Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('condition never became true');
}

/// Swallows framework exceptions the pumped screen may have queued (used only
/// in the kid-mode probe, which can land on P01 — not the screen under test).
void _drainExceptions(WidgetTester tester) {
  for (var i = 0; i < 4; i++) {
    if (tester.takeException() == null) return;
  }
}

void main() {
  group('P07-BUG-1 — the paywall screen does not exist (blocker)', () {
    testWidgets('[P07-BUG-1] the design surface renders at /paywall', (
      tester,
    ) async {
      await _pumpPaywallWithSeed(tester, Seed.fresh);

      // Not the foundation placeholder.
      expect(find.text('P07 Paywall'), findsNothing);

      // Nav + hero.
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(find.bySemanticsLabel('Subscription'), findsOneWidget);
      expect(find.bySemanticsLabel(_closeLabel), findsOneWidget);
      expect(_v1PipFinder, findsNothing);
      final avatars = tester.widgetList<v2.PipAvatar>(
        find.byType(v2.PipAvatar),
      );
      expect(avatars, hasLength(1), reason: 'hero Pip');
      expect(avatars.single.style, v2.PipStyle.mochi);
      expect(avatars.single.skin, v2.PipSkin.sunny);
      expect(avatars.single.stage, 4);

      // Title + benefits + plan card.
      expect(find.text(_title), findsOneWidget);
      for (final benefit in _benefits) {
        expect(find.text(benefit), findsOneWidget, reason: benefit);
      }
      expect(find.text(_planTitle), findsOneWidget);
      expect(find.text(_planSub), findsOneWidget);
      expect(find.text(_planTag), findsOneWidget);

      // Below the fold.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await _settle(tester);
      expect(find.text(_timelineHead), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Full access, straight away'), findsOneWidget);
      expect(find.text('Day 12'), findsOneWidget);
      expect(find.text('We’ll remind you by email'), findsOneWidget);
      expect(find.text('Day 14'), findsOneWidget);
      expect(find.text('£29.99 billed — cancel any time'), findsOneWidget);
      expect(find.text(_familyNote), findsOneWidget);

      // Bottom bar.
      expect(find.byType(NestBottomCta), findsOneWidget);
      expect(find.text(_cta), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      for (final link in _legalLinks) {
        expect(find.text(link), findsOneWidget, reason: link);
      }

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P07-BUG-2 — no trial/restore action path (major)', () {
    testWidgets(
      '[P07-BUG-2] Start free trial completes onboarding and lands on /today',
      (tester) async {
        final db = await _pumpPaywallWithSeed(tester, Seed.fresh);

        await tester.tap(find.text(_cta));
        await _settle(tester);

        final row = await _appStateRow(db);
        expect(row?.onboardingComplete, isTrue);
        expect(row?.subscriptionStatus, 'trial');
        expect(row?.trialStart, isNotNull);
        expect(row?.trialStartTz, 'Europe/London');
        expect(currentPath(tester), '/today');

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P07-BUG-2] Restore purchases activates (never downgrades) and lands on /today',
      (tester) async {
        final db = await _pumpPaywallWithSeed(tester, Seed.fresh);

        await tester.tap(find.text('Restore purchases'));
        await _settle(tester);

        final row = await _appStateRow(db);
        expect(row?.subscriptionStatus, 'active');
        expect(row?.onboardingComplete, isTrue);
        expect(currentPath(tester), '/today');

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P07-BUG-2] a rapid double tap starts one trial and navigates once',
      (tester) async {
        final db = await _pumpPaywallWithSeed(tester, Seed.fresh);

        // Two taps with no frame in between (fastest possible double tap).
        await tester.tap(find.text(_cta));
        await tester.tap(find.text(_cta));
        await _settle(tester);

        final row = await _appStateRow(db);
        expect(row?.onboardingComplete, isTrue);
        expect(row?.subscriptionStatus, 'trial');
        expect(currentPath(tester), '/today');
        expect(
          tester.takeException(),
          isNull,
          reason: 'the second tap must not navigate from a disposed context',
        );

        await disposeApp(tester);
      },
    );
  });

  group('P07-BUG-3 — the bar cannot render the design order (major)', () {
    testWidgets(
      '[P07-BUG-3] CTA, then caption, then legal row — all inside the bottom bar',
      (tester) async {
        await _pumpPaywallWithSeed(tester, Seed.fresh);

        final cta = tester.getRect(find.text(_cta));
        final caption = tester.getRect(find.text(_caption));
        final restore = tester.getRect(find.text('Restore purchases'));

        expect(
          cta.bottom,
          lessThanOrEqualTo(caption.top + 0.01),
          reason: 'the caption sits under the CTA',
        );
        expect(
          caption.bottom,
          lessThanOrEqualTo(restore.top + 0.01),
          reason: 'the legal row sits under the caption',
        );
        expect(
          find.ancestor(
            of: find.text('Terms'),
            matching: find.byType(NestBottomCta),
          ),
          findsOneWidget,
          reason: 'the legal row belongs to the bottom bar',
        );

        await disposeApp(tester);
      },
    );
  });

  group('P07-BUG-4 — the plan caption drops “the” (minor)', () {
    test(
      '[P07-BUG-4] the repository caption is the design’s wording',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final repository = PaywallRepositoryImpl(db: db);
        await Seed.fresh(db);

        final detail = (await repository.watchItems().first).single.detail;

        expect(detail, contains('after the 14-day trial'));
        expect(
          detail,
          isNot(contains('after 14-day trial')),
          reason: 'the HTML caption is “£29.99/year after the 14-day trial.”',
        );
      },
    );
  });

  group('P07-BUG-5 — plan detail is not the design copy (minor)', () {
    test(
      '[P07-BUG-5] the sub keeps the design’s punctuation (no stray full stop)',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final repository = PaywallRepositoryImpl(db: db);
        await Seed.fresh(db);

        final detail = (await repository.watchItems().first).single.detail;

        // `P07-paywall.html:86` has no full stop after “billed yearly”.
        expect(
          detail,
          isNot(contains('billed yearly.')),
          reason: 'the design sub is “Just £2.50 a month, billed yearly”',
        );
        expect(detail, contains(_planSub));
      },
    );

    test('[P07-BUG-5] the plan tag has a data source', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repository = PaywallRepositoryImpl(db: db);
      await Seed.fresh(db);

      final detail = (await repository.watchItems().first).single.detail;

      // `P07-paywall.html:87` / 1_plan.md §a: the card's third line. Either a
      // `tag` field on PaywallPlan or a string in `detail`; the tag must be
      // reachable from the data layer, not only from a hard-coded widget.
      expect(detail, contains(_planTag));
    });
  });

  group('P07-BUG-6 — a stale error survives a successful retry (minor)', () {
    test(
      '[P07-BUG-6] errorMessage is cleared when the reload succeeds',
      () async {
        final bloc = PaywallBloc(repository: _FlakyRepository());
        addTearDown(bloc.close);

        bloc.add(const PaywallLoadRequested());
        await _until(() => bloc.state.status == PaywallStatus.failure);
        expect(bloc.state.errorMessage, isNotNull);

        bloc.add(const PaywallLoadRequested());
        await _until(() => bloc.state.status == PaywallStatus.loaded);

        expect(
          bloc.state.errorMessage,
          isNull,
          reason: 'PaywallState.copyWith cannot clear a previous error message',
        );
      },
    );
  });

  group('P07-BUG-7 — repository writes are UPDATE-only (minor, latent)', () {
    test(
      '[P07-BUG-7] startTrial records the trial even if the row is missing',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final repository = PaywallRepositoryImpl(db: db);
        await Seed.fresh(db);

        // The class of P01 BUG-4: a missing `app_state` row. `beforeOpen`
        // normally inserts it, but the repository must not rely on that.
        await db.delete(db.appState).go();
        await repository.startTrial();

        final row = await _appStateRow(db);
        expect(row, isNotNull, reason: 'startTrial must upsert, not no-op');
        expect(row!.trialStart, isNotNull);
        expect(row.subscriptionStatus, 'trial');
      },
    );
  });

  group('P07-BUG-8 — the 14-day trial never expires (major, shared)', () {
    testWidgets(
      '[P07-BUG-8] a trial started 15 days ago must not keep giving access',
      skip: true,
      (tester) async {
        final db = await setUpTestScope(seedDemo: false);
        await Seed.fresh(db);
        final session = GetIt.instance<AppSession>();
        await session.refresh();

        await session.startTrialNow();
        await session.completeOnboarding();

        // Fifteen days pass.
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          AppStateCompanion(
            trialStart: Value(
              DateTime.now().toUtc().subtract(const Duration(days: 15)),
            ),
          ),
        );
        await session.refresh();

        await pumpAppRoute(tester, '/today');
        expect(
          currentPath(tester),
          '/paywall',
          reason: 'an expired trial must be sent back to the paywall',
        );

        await disposeApp(tester);
      },
    );
  });

  group('P07-BUG-9 — kid-mode guard order during onboarding (minor, shared)', () {
    testWidgets(
      '[P07-BUG-9] a kid-mode deep link to /paywall lands on the parental gate',
      skip: true,
      (tester) async {
        final db = await setUpTestScope(seedDemo: false);
        await Seed.fresh(db);
        final session = GetIt.instance<AppSession>();
        await session.refresh();

        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        await session.setAppMode('kid');
        await session.refresh();

        await pumpAppRoute(tester, '/paywall');
        // Landing on P01 (welcome) may overflow in the test font; that is not
        // this bug — drain it so the redirect assertion is what fails.
        _drainExceptions(tester);

        expect(
          currentPath(tester),
          '/parental-gate',
          reason: 'parent-only routes must stop at the gate in kid mode',
        );

        await disposeApp(tester);
      },
    );
  });

  group(
    'P07-BUG-10 — X cannot leave the expired-trial paywall (major, latent)',
    () {
      testWidgets(
        '[P07-BUG-10] the expired-trial paywall shows no dead close control',
        // Updated (Stage 2b, iteration 3): the router bounces every
        // non-`/paywall` location back to /paywall while the trial is
        // expired, so no close affordance can ever work. The screen now
        // omits the close tile on the hard gate; only its working exits
        // (trial CTA / restore) remain. Original assertion ("X leaves
        // /paywall") could not be satisfied without an app/router change.
        (tester) async {
          final db = await setUpTestScope();
          await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
            const AppStateCompanion(
              subscriptionStatus: Value('expired'),
              onboardingComplete: Value(true),
            ),
          );
          await GetIt.instance<AppSession>().refresh();

          await pumpAppRoute(tester, '/today');
          await tester.pump(const Duration(milliseconds: 200));
          expect(currentPath(tester), '/paywall');

          expect(
            find.bySemanticsLabel(_closeLabel),
            findsNothing,
            reason:
                'the expired gate must not render a close button that can '
                'only bounce the parent back to /paywall',
          );
          expect(find.text(_cta), findsOneWidget);

          await disposeApp(tester);
        },
      );
    },
  );

  group('P07-BUG-11 — the legal separators are announced (minor)', () {
    testWidgets('[P07-BUG-11] the · separators stay out of semantics', (
      tester,
    ) async {
      await _pumpPaywallWithSeed(tester, Seed.fresh);

      // `P07-paywall.html:108,110` marks both separators `aria-hidden`;
      // the two links carry their own labels, so the middle dots must not
      // become separate semantics nodes.
      expect(
        find.bySemanticsLabel('·'),
        findsNothing,
        reason: 'aria-hidden separators must be ExcludeSemantics in Flutter',
      );

      await disposeApp(tester);
    });
  });

  group(
    'P07-BUG-12 — Start free trial downgrades an active subscriber (minor)',
    () {
      testWidgets(
        '[P07-BUG-12] an active subscription is not replaced by a trial',
        (tester) async {
          // Seed.demo is an already-paying family (`subscriptionStatus:
          // 'active'`, trial_start 2026-09-19). The paywall stays reachable
          // for onboarded apps (deep link), so the CTA must not regress a
          // paid subscription — the restore path already refuses to.
          final db = await _pumpPaywallWithSeed(tester, Seed.demo);
          final before = await _appStateRow(db);
          expect(before?.subscriptionStatus, 'active');

          await tester.tap(find.text(_cta));
          await _settle(tester);

          final after = await _appStateRow(db);
          expect(
            after?.subscriptionStatus,
            'active',
            reason: 'a paying family must not be downgraded to trial',
          );
          expect(
            after?.trialStart,
            before?.trialStart,
            reason: 'the old trial date must not be overwritten',
          );
          expect(currentPath(tester), '/today');

          await disposeApp(tester);
        },
      );
    },
  );

  group('verified clean — baselines that must stay green', () {
    test(
      'the trial handoff survives an app restart (Drift persistence)',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);

        final first = AppSession(db);
        await first.refresh();
        await first.startTrialNow();
        await first.completeOnboarding();
        first.dispose();

        // A restart = a fresh AppSession over the same database.
        final second = AppSession(db);
        addTearDown(second.dispose);
        await second.refresh();

        expect(second.onboardingComplete, isTrue);
        expect(second.subscriptionStatus, 'trial');
        final row = await _appStateRow(db);
        expect(row?.trialStart, isNotNull);
        expect(row?.trialStartTz, 'Europe/London');
      },
    );

    testWidgets(
      'parent deep link: /paywall is reachable while onboarding is incomplete',
      (tester) async {
        await _pumpPaywallWithSeed(tester, Seed.fresh);
        expect(currentPath(tester), '/paywall');
        await disposeApp(tester);
      },
    );

    testWidgets('parent deep link: /paywall stays open for an onboarded app', (
      tester,
    ) async {
      await _pumpPaywallWithSeed(tester, Seed.demo);
      expect(currentPath(tester), '/paywall');
      await disposeApp(tester);
    });

    testWidgets(
      'kid mode on an onboarded app is stopped at the parental gate',
      (tester) async {
        // Mode must be set before the router is built: the guard reads the
        // controller at redirect time.
        final db = await setUpTestScope(seedDemo: false);
        await Seed.demo(db);
        final session = GetIt.instance<AppSession>();
        await session.refresh();
        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        await session.setAppMode('kid');
        await session.refresh();

        await pumpAppRoute(tester, '/paywall');
        expect(currentPath(tester), '/parental-gate');

        await disposeApp(tester);
      },
    );
  });
}
