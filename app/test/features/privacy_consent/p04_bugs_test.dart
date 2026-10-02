// P04 · Privacy & consent — adversarial bug proofs (Stage 6, iteration 3).
//
// The proofs assert the CORRECT behaviour. Iterations 1-3 fixed P04-1, P04-3,
// P04-5, P04-6 and P04-8 (P04-3 by the shared compact-nav merge), so those
// proofs are un-skipped and green. P04-2 and P04-7 assert shared-side fixes
// (asset / themed artwork) deferred to the orchestrator's in-flight shared
// batch; P04-4 is a shared-component defect with an in-scope fix (review
// iteration 3, finding 1); P04-9 is new this iteration (the first-run upsert
// is not atomic and can drop the later of two overlapping writes).
//
// Run the proofs against the current tree with:
//   flutter test --run-skipped test/features/privacy_consent/p04_bugs_test.dart
//
// Findings, severity, repro and suggested fixes: docs/screens/P04/6_bugs.md.
//
// Bug index:
//   P04-1 major   first-run crash-consent opt-in is silently dropped  [FIXED]
//   P04-2 major   promise row 4 has no trash glyph (empty peach tile)  [shared]
//   P04-3 major   compact nav bar 16 px short — header block sits high [FIXED]
//   P04-4 major   1 px real dividers inflate the promise list     [open, in scope]
//   P04-5 minor   rapid double-tap writes the same toggle value twice [FIXED]
//   P04-6 major   failed OFF write still tells the parent "it stays off" [FIXED]
//   P04-7 minor   dark mode renders the light-baked shield artwork    [shared]
//   P04-8 minor   double-failed rapid toggle reverts to unpersisted  [FIXED]
//   P04-9 minor   overlapping first-run writes keep the earlier value [open]
//
// Checked and clean (passing proofs at the bottom): kid-mode guard, deep-link
// back navigation, restart persistence (demo and first-run), first-run
// double-tap last-write-wins, async-gap emit-after-close, and the notice link
// under a double tap.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';
import 'package:nestling/features/privacy_consent/presentation/views/privacy_consent_view.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Fixtures and helpers
// ---------------------------------------------------------------------------

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

Finder get _toggle => find.byKey(const ValueKey('p04_crash_toggle'));
Finder get _notice => find.byKey(const ValueKey('p04_privacy_notice'));
Finder get _h1 => find.text('Your family’s privacy');
Finder get _back => find.bySemanticsLabel('Back');

/// Repository whose write fails after a delay — the write is still open when
/// the parent leaves the screen (async-gap class).
class _SlowFailPrivacyConsentRepository implements PrivacyConsentRepository {
  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() =>
      Stream<List<ConsentOption>>.value(_crashOff);

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    throw Exception('disk full');
  }
}

/// Repository whose two rapid writes both fail, the first before the second —
/// nothing is persisted and the items stream never re-emits (P04-8).
class _DoubleFailPrivacyConsentRepository implements PrivacyConsentRepository {
  final List<bool> calls = <bool>[];

  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() =>
      Stream<List<ConsentOption>>.value(_crashOff);

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) {
    calls.add(consent);
    final delay = consent
        ? const Duration(milliseconds: 10)
        : const Duration(milliseconds: 50);
    return Future<void>.delayed(
      delay,
      () => throw Exception('write $consent failed'),
    );
  }
}

/// Repository with a scripted items stream and a scripted write path.
class _ScriptedPrivacyConsentRepository implements PrivacyConsentRepository {
  _ScriptedPrivacyConsentRepository({required this.items, this.onWrite});

  final Stream<List<ConsentOption>> items;
  final Future<void> Function({required bool consent})? onWrite;
  final List<bool> writes = <bool>[];

  @override
  Future<List<ConsentOption>> getItems() => items.first;

  @override
  Stream<List<ConsentOption>> watchItems() => items;

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) {
    writes.add(consent);
    return onWrite?.call(consent: consent) ?? Future<void>.value();
  }
}

/// Pumps [PrivacyConsentView] directly under the real theme, with [repository]
/// driving the route-scoped bloc (no router).
Future<PrivacyConsentBloc> _pumpView(
  WidgetTester tester,
  PrivacyConsentRepository repository, {
  ThemeMode theme = ThemeMode.light,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final bloc = PrivacyConsentBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<PrivacyConsentBloc>.value(
        value: bloc,
        child: const PrivacyConsentView(),
      ),
    ),
  );
  bloc.add(const PrivacyConsentLoadRequested());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return bloc;
}

/// Test fonts render full-em glyphs, so the opt card sits below the fold in
/// widget tests; bring the toggle into reach before tapping it.
Future<void> _scrollToToggle(WidgetTester tester) async {
  await tester.ensureVisible(_toggle);
  await tester.pumpAndSettle();
}

/// Reads the stored crash consent through the real Drift repository.
Future<bool?> _consentInDb(WidgetTester tester) {
  return tester.runAsync(
    () =>
        PrivacyConsentRepositoryImpl(db: GetIt.instance<AppDatabase>())
            .watchCrashConsent()
            .first,
  );
}

/// Lets real-async Drift work (writes, stream re-emits) complete in a widget
/// test, where plain `pump` only runs the fake clock.
Future<void> _flushDrift(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump();
}

void main() {
  // -------------------------------------------------------------------------
  // Bug proofs (skipped: each FAILS on the iteration-1 screen)
  // -------------------------------------------------------------------------

  group('P04-1 — first-run consent write', () {
    testWidgets(
      '[P04-1] first run: the toggle tap is actually stored',
      (tester) async {
        // Seed.fresh-equivalent: an empty database (app_state only), the state
        // a real first launch reaches P04 in. Nothing creates the fam1
        // `settings` row before P04.
        await setUpTestScope(seedDemo: false);
        await pumpAppRoute(tester, '/privacy');
        await _scrollToToggle(tester);

        await tester.tap(_toggle);
        await tester.pump();
        await _flushDrift(tester);

        expect(
          await _consentInDb(tester),
          isTrue,
          reason: 'the parent opted in — the write must not be dropped',
        );
        expect(
          tester.widget<NestToggle>(_toggle).value,
          isTrue,
          reason: 'the switch must reflect the stored opt-in',
        );

        await disposeApp(tester);
      },
      // P04-1 FIXED (iteration 2): setCrashConsent upserts.
    );
  });

  group('P04-2 — missing trash glyph', () {
    testWidgets('[P04-2] every promise row renders its leading glyph', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final list = find.byType(NestList);
      expect(
        find.descendant(of: list, matching: find.byType(NestIcon)),
        findsNWidgets(4),
        reason:
            'row 4 "Delete everything anytime" must show the peach-ink '
            'trash glyph; the shared ic_trash.svg + NestIcons.trash are '
            'still missing (SHARED_REQUEST §1)',
      );
      expect(
        find.descendant(of: list, matching: find.byType(SvgPicture)),
        findsNWidgets(4),
        reason: 'all four tiles must render a drawn glyph (SVG)',
      );

      await disposeApp(tester);
      // P04-2: row 4 ships an empty peach tile (no trash asset).
    }, skip: true);
  });

  group('P04-3 — compact nav bar height', () {
    testWidgets(
      '[P04-3] header block matches the 60px design bar',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/privacy');

        // `.nav-bar.compact`: min-height 52 + padding 4/12/12 around the 44px
        // back button = 60px; scroll starts at 47 + 60 = 107.
        expect(
          tester.getCenter(_back).dy,
          73,
          reason: 'back chevron centre is 47 + 4 + 22 in the design',
        );
        expect(
          tester.getTopLeft(_h1).dy,
          107,
          reason: 'h1 line box starts at the scroll top',
        );

        await disposeApp(tester);
      },
      // P04-3 FIXED (iteration 2): the shared compact-nav merge (min 52 +
      // padding 4/12/12 = 60) moved the header back to the design position.
    );
  });

  group('P04-4 — list divider height', () {
    testWidgets('[P04-4] dividers do not add height to the promise list', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      // The design draws the separators as absolutely-positioned 1px
      // ::before overlays, so the list height equals the sum of the row
      // heights (4 × 56 = 224 with the product fonts). NestList adds real
      // 1px Dividers, making the list 3px taller and shifting every later
      // element down; measured on the simulator: tile tops 279/336/393/450
      // (57 apart) vs the design's 295/351/407/463 (56 apart), opt card top
      // 514 vs the design's 527.
      const titles = <String>[
        'No ads or tracking — ever',
        'Children only need a nickname',
        'Data stored in the UK (London)',
        'Delete everything anytime',
      ];
      var rows = 0.0;
      for (final title in titles) {
        rows += tester
            .getSize(
              find
                  .ancestor(
                    of: find.text(title),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .height;
      }
      expect(
        tester.getSize(find.byType(NestList)).height,
        rows,
        reason: 'dividers overlay the row boundary; they must not add height',
      );

      await disposeApp(tester);
      // P04-4: real dividers add 3px to the list; the opt card lands at 514.
    }, skip: true);
  });

  group('P04-5 — rapid double tap', () {
    testWidgets('[P04-5] double-tapping the switch toggles twice', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      await _scrollToToggle(tester);

      // Two taps: the widget still shows OFF for both because the state only
      // updates after the Drift round-trip, so both taps ask for the same
      // value. A switch must be reliable under a double tap (ON then OFF).
      await tester.tap(_toggle);
      await tester.pump();
      await tester.tap(_toggle);
      await tester.pump();
      await _flushDrift(tester);

      expect(
        await _consentInDb(tester),
        isFalse,
        reason: 'two taps on OFF must end ON then OFF, i.e. OFF',
      );

      await disposeApp(tester);
      // P04-5 FIXED (iteration 2): optimistic emit + serialised writes.
    });
  });

  group('P04-6 — failure caption vs stored consent', () {
    testWidgets('[P04-6] a failed OFF write never claims "it stays off"', (
      tester,
    ) async {
      final repository = _ScriptedPrivacyConsentRepository(
        items: Stream<List<ConsentOption>>.value(_crashOn),
        onWrite: ({required consent}) =>
            Future<void>.error(Exception('read only')),
      );
      await _pumpView(tester, repository);
      await _scrollToToggle(tester);

      await tester.tap(_toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The failed write leaves the stored opt-in ON; the caption says it
      // stays OFF, which is a false statement about consent state.
      expect(tester.widget<NestToggle>(_toggle).value, isTrue);
      expect(
        find.textContaining('stays off'),
        findsNothing,
        reason:
            'the parent is trying to turn crash reports OFF; the write '
            'failed, so the opt-in is still ON — say so',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      // P04-6 FIXED (iteration 2): the caption is state-aware.
    });
  });

  group('P04-7 — dark shield artwork', () {
    testWidgets('[P04-7] the dark-mode shield does not bake light colours', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy', theme: ThemeMode.dark);

      final shield = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .firstWhere(
            (w) =>
                w.bytesLoader is SvgAssetLoader &&
                (w.bytesLoader as SvgAssetLoader).assetName.contains(
                  'privacy_shield',
                ),
          );
      final asset = (shield.bytesLoader as SvgAssetLoader).assetName;
      final xml = await tester.runAsync(() => rootBundle.loadString(asset));

      // `privacy_shield.svg` bakes the light sky tint (#E6EFFE) and a white
      // shield body; the dark design uses #1A2A4A + #1F1C2E.
      expect(
        xml,
        isNot(contains('#E6EFFE')),
        reason: 'dark mode must not render the light-theme disc (#E6EFFE)',
      );
      expect(
        xml,
        isNot(contains('#FFFFFF')),
        reason: 'the shield body must use the dark surface, not white',
      );

      await disposeApp(tester);
      // P04-7: the same light-baked asset renders in both themes.
    }, skip: true);
  });

  group('P04-8 — failure revert vs stored value', () {
    testWidgets(
      '[P04-8] a double-failed rapid toggle reverts to the stored value',
      (tester) async {
        final repository = _DoubleFailPrivacyConsentRepository();
        await _pumpView(tester, repository);
        await _scrollToToggle(tester);

        // ON (write 1, fails at 10ms) then OFF (write 2, fails at 50ms).
        // Neither write persists, so the stored consent is false = the
        // items stream the state keeps re-reading.
        await tester.tap(_toggle);
        await tester.pump();
        await tester.tap(_toggle);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          tester.widget<NestToggle>(_toggle).value,
          isFalse,
          reason:
              'the revert must restore the stored value (false), not the '
              'other handler optimistic value (true)',
        );
        expect(
          find.textContaining('still on'),
          findsNothing,
          reason:
              'nothing was persisted — the caption must not claim crash '
              'reports are still on',
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        // P04-8 FIXED (iteration 3): catches revert to `_crashFrom(items)`.
      },
    );
  });

  group('P04-9 — first-run upsert atomicity', () {
    test(
      '[P04-9] overlapping first-run writes keep the last value',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        await Seed.fresh(db);
        final repository = PrivacyConsentRepositoryImpl(db: db);

        // Two rapid taps ON → OFF, overlapping: both calls issue their
        // UPDATE before either INSERT runs, so both see the empty `settings`
        // table and `insertOrIgnore` keeps whichever insert lands first.
        final on = repository.setCrashConsent(consent: true);
        final off = repository.setCrashConsent(consent: false);
        await Future.wait<void>(<Future<void>>[on, off]);

        expect(
          await repository.watchCrashConsent().first,
          isFalse,
          reason: 'the second (last) call must win',
        );
        expect(
          (await db.select(db.settings).get()).length,
          1,
          reason: 'still exactly one settings row',
        );
      },
      skip: true,
      // P04-9: setCrashConsent is an UPDATE-then-INSERT pair, not a transaction.
    );
  });

  // -------------------------------------------------------------------------
  // Verified clean this iteration (guard, deep link, persistence)
  // -------------------------------------------------------------------------

  group('verified clean — guard, deep link, restart', () {
    testWidgets('kid mode is redirected from /privacy to the parental gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/privacy');

      expect(currentPath(tester), '/parental-gate');
      expect(_h1, findsNothing);
      await disposeApp(tester);
    });

    testWidgets('deep link with no history: back lands on /create-account', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      expect(currentPath(tester), '/privacy');

      await tester.tap(_back);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');
      await disposeApp(tester);
    });

    testWidgets('the opt-in survives leaving and reopening the screen', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      await _scrollToToggle(tester);
      await tester.tap(_toggle);
      await tester.pump();
      await _flushDrift(tester);
      expect(await _consentInDb(tester), isTrue);

      // Close the route (bloc disposed) and open it again on the same DB —
      // the persistence path a real app restart uses.
      await disposeApp(tester);
      await pumpAppRoute(tester, '/privacy');
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.widget<NestToggle>(_toggle).value, isTrue);
      await disposeApp(tester);
    });

    testWidgets('first run: a double tap persists the last tap (upsert path)', (
      tester,
    ) async {
      // The upsert's insertOrIgnore fallback must not drop the later write
      // when two first-run writes overlap.
      await setUpTestScope(seedDemo: false);
      await pumpAppRoute(tester, '/privacy');
      await _scrollToToggle(tester);

      await tester.tap(_toggle);
      await tester.pump();
      await tester.tap(_toggle);
      await tester.pump();
      await _flushDrift(tester);

      expect(
        await _consentInDb(tester),
        isFalse,
        reason: 'two taps on OFF = ON then OFF; the row must hold the OFF',
      );

      await disposeApp(tester);
    });

    testWidgets('first run: the opt-in survives reopening the screen', (
      tester,
    ) async {
      await setUpTestScope(seedDemo: false);
      await pumpAppRoute(tester, '/privacy');
      await _scrollToToggle(tester);
      await tester.tap(_toggle);
      await tester.pump();
      await _flushDrift(tester);
      expect(await _consentInDb(tester), isTrue);

      await disposeApp(tester);
      await pumpAppRoute(tester, '/privacy');
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.widget<NestToggle>(_toggle).value,
        isTrue,
        reason: 'the upserted settings row must persist across a restart',
      );
      await disposeApp(tester);
    });

    test('a failing write after leaving does not escape as an error', () async {
      final repository = _SlowFailPrivacyConsentRepository();
      Object? escaped;
      await runZonedGuarded(
        () async {
          final bloc = PrivacyConsentBloc(repository: repository)
            ..add(const PrivacyConsentLoadRequested());
          await bloc.stream.firstWhere(
            (s) => s.status == PrivacyConsentStatus.loaded,
          );

          bloc.add(const PrivacyConsentCrashToggled(value: true));
          await Future<void>.delayed(const Duration(milliseconds: 10));

          // Parent leaves the screen while the write is still in flight.
          await bloc.close();
          await Future<void>.delayed(const Duration(milliseconds: 60));
        },
        (error, stack) {
          escaped = error;
        },
      );

      expect(
        escaped,
        isNull,
        reason: 'bloc 9.2 drops emits after close; the failure must be caught',
      );
    });

    testWidgets('double-tapping the notice link opens a single dialog', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      await tester.tap(_notice);
      await tester.tap(_notice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Privacy Notice'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/privacy');
      await disposeApp(tester);
    });
  });
}
