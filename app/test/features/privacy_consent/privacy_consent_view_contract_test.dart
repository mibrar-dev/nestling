// P04 Privacy & consent — second widget-contract pass (STAGE 3).
//
// Complements `privacy_consent_view_test.dart`:
//   * every bloc state driven through the REAL app (router + DI), so the
//     route-scoped bloc, the failure caption and the "Continue always works"
//     rule are exercised as shipped;
//   * every tap destination (back with and without history, Continue, the
//     toggle, the notice dialog and both of its dismiss paths);
//   * the crash-toggle lifecycle (ON -> OFF) asserted against the Drift row
//     and against the `toggled` accessibility flag;
//   * 320x568 short-screen scrolling, 320/430 gutter alignment, dialog
//     overflow at text scale 1.3 and the back/notice control labels.
//
// Note on fonts: widget tests run without the bundled Inter/Nunito faces
// (GoogleFonts runtime fetching is off in tests), so the block test font
// renders every glyph at full em width. The opt card therefore sits lower
// than it does on a device and must be scrolled into reach before tapping.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';
import 'package:nestling/features/privacy_consent/presentation/views/privacy_consent_view.dart';

import '../../test_scope.dart';

const List<String> _titles = <String>[
  'No ads or tracking — ever',
  'Children only need a nickname',
  'Data stored in the UK (London)',
  'Delete everything anytime',
];

Finder get _toggle => find.byKey(const ValueKey('p04_crash_toggle'));
Finder get _continue => find.byKey(const ValueKey('p04_continue'));
Finder get _notice => find.byKey(const ValueKey('p04_privacy_notice'));
Finder get _toggleLabel =>
    find.bySemanticsLabel('Share anonymous crash reports');
Finder get _failureCaption => find.text(
  'Oops — your choice wasn’t saved. Continue anyway; it stays off.',
);

/// Any v1 `pip_stage_*.svg` illustration (banned from product screens).
Finder get _v1PipFinder => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName.contains('pip_stage'),
);

/// Repository with a caller-controlled items stream, for the states the Drift
/// repository cannot reach (pending load, empty list, stream error).
class _FakePrivacyConsentRepository implements PrivacyConsentRepository {
  _FakePrivacyConsentRepository(this._items);

  final Stream<List<ConsentOption>> _items;

  @override
  Future<List<ConsentOption>> getItems() => _items.first;

  @override
  Stream<List<ConsentOption>> watchItems() => _items;

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) async {}
}

/// Records every consent write the view asks the repository to perform.
class _RecordingPrivacyConsentRepository implements PrivacyConsentRepository {
  final List<bool> writes = <bool>[];

  @override
  Future<List<ConsentOption>> getItems() => watchItems().first;

  @override
  Stream<List<ConsentOption>> watchItems() =>
      Stream<List<ConsentOption>>.value(const <ConsentOption>[
        ConsentOption(
          id: ConsentOptionIds.crash,
          title: 'c',
          detail: 'd',
          enabled: false,
        ),
      ]);

  @override
  Stream<bool> watchCrashConsent() => Stream<bool>.value(false);

  @override
  Future<void> setCrashConsent({required bool consent}) async {
    writes.add(consent);
  }
}

/// Repository with a scripted items stream and a scripted write path, for the
/// optimistic-emit and write-failure contracts (P04-5, P04-6).
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

/// Swaps the DI repository so the real app drives the route-scoped bloc from
/// a caller-controlled stream.
Future<void> _useRepository(PrivacyConsentRepository repository) async {
  await GetIt.instance.unregister<PrivacyConsentRepository>();
  GetIt.instance.registerSingleton<PrivacyConsentRepository>(repository);
}

Future<void> _pumpPrivacy(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  required double textScale,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await pumpAppRoute(tester, '/privacy', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Brings the crash toggle on-screen. See the note about test fonts above.
Future<void> _scrollToToggle(WidgetTester tester) async {
  await tester.ensureVisible(_toggle);
  await tester.pumpAndSettle();
}

Future<void> _tapToggle(WidgetTester tester) async {
  await _scrollToToggle(tester);
  await tester.tap(_toggle);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

/// `SemanticsFlags.isToggled` is a tristate: `none` and `false` both read as
/// "not switched on" here.
bool _isToggled(WidgetTester tester) =>
    tester
        .getSemantics(_toggleLabel)
        .getSemanticsData()
        .flagsCollection
        .isToggled
        .toBoolOrNull() ??
    false;

/// Reads the stored crash consent. Drift resolves queries on a background
/// isolate, so inside a widget test the read has to go through
/// `tester.runAsync`
/// (a plain `await` would deadlock the fake-async zone).
Future<bool> _consentInDb(
  WidgetTester tester,
  PrivacyConsentRepositoryImpl repository,
) {
  return tester
      .runAsync(() => repository.watchCrashConsent().first)
      .then((value) => value ?? false);
}

void main() {
  group('P04 — states through the real app router', () {
    testWidgets('an empty items list still renders the whole static screen', (
      tester,
    ) async {
      await setUpTestScope();
      final controller = StreamController<List<ConsentOption>>();
      addTearDown(controller.close);
      await _useRepository(_FakePrivacyConsentRepository(controller.stream));
      await pumpAppRoute(tester, '/privacy');
      controller.add(const <ConsentOption>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(currentPath(tester), '/privacy');
      expect(find.text('Your family’s privacy'), findsOneWidget);
      for (final title in _titles) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Continue'), findsOneWidget);
      expect(_failureCaption, findsNothing);
      // Loaded with zero rows: still no consent, but the opt-in is live.
      expect(tester.widget<NestToggle>(_toggle).value, isFalse);
      expect(tester.widget<NestToggle>(_toggle).onChanged, isNotNull);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('failure: caption shows and Continue still reaches P05', (
      tester,
    ) async {
      await setUpTestScope();
      await _useRepository(
        _FakePrivacyConsentRepository(
          Stream<List<ConsentOption>>.error(Exception('offline')),
        ),
      );
      await pumpAppRoute(tester, '/privacy');
      await tester.pump(const Duration(milliseconds: 300));

      expect(_failureCaption, findsOneWidget);
      expect(tester.widget<NestToggle>(_toggle).onChanged, isNull);
      expect(find.text('Continue'), findsOneWidget);

      await tester.tap(_continue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/add-children');
      await disposeApp(tester);
    });

    testWidgets('first run (no seed): the screen renders with consent off', (
      tester,
    ) async {
      // Seed.fresh-equivalent scope — no family row, no settings row.
      await setUpTestScope(seedDemo: false);
      await pumpAppRoute(tester, '/privacy');
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/privacy');
      expect(find.text('Your family’s privacy'), findsOneWidget);
      for (final title in _titles) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.widget<NestToggle>(_toggle).value, isFalse);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('still loading: content renders, toggle disabled, CTA works', (
      tester,
    ) async {
      await setUpTestScope();
      await _useRepository(
        _FakePrivacyConsentRepository(
          const Stream<List<ConsentOption>>.empty(),
        ),
      );
      await pumpAppRoute(tester, '/privacy');

      expect(
        tester.widget<NestToggle>(_toggle).onChanged,
        isNull,
        reason: 'no items yet — the opt-in must not be tappable',
      );
      expect(find.text('Your family’s privacy'), findsOneWidget);
      expect(_failureCaption, findsNothing);

      await tester.tap(_continue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/add-children');
      await disposeApp(tester);
    });
  });

  group('P04 — tap destinations', () {
    testWidgets('back with no history goes to /create-account', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      expect(currentPath(tester), '/privacy');

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');
      expect(find.text('Your family’s privacy'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('the toggle stays on /privacy', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      await _tapToggle(tester);

      expect(currentPath(tester), '/privacy');
      expect(find.text('Your family’s privacy'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the notice dialog returns to /privacy after Close', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      await tester.tap(_notice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Privacy Notice'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Privacy Notice'), findsNothing);
      expect(currentPath(tester), '/privacy');
      await disposeApp(tester);
    });
  });

  group('P04 — crash toggle lifecycle', () {
    testWidgets('ON then OFF round-trips through Drift and semantics', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');
      final repository = PrivacyConsentRepositoryImpl(
        db: GetIt.instance<AppDatabase>(),
      );

      expect(await _consentInDb(tester, repository), isFalse);
      expect(_isToggled(tester), isFalse);

      await _tapToggle(tester);

      expect(tester.widget<NestToggle>(_toggle).value, isTrue);
      expect(await _consentInDb(tester, repository), isTrue);
      expect(
        _isToggled(tester),
        isTrue,
        reason: 'the switch must announce its state to assistive tech',
      );

      await _tapToggle(tester);

      expect(tester.widget<NestToggle>(_toggle).value, isFalse);
      expect(await _consentInDb(tester, repository), isFalse);
      expect(_isToggled(tester), isFalse);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the toggle is announced and enabled once loaded', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final data = tester.getSemantics(_toggleLabel).getSemanticsData();
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      expect(data.flagsCollection.isToggled.toBoolOrNull(), isFalse);
      expect(data.label, 'Share anonymous crash reports');

      await disposeApp(tester);
    });

    testWidgets('dark: the toggle writes through and no Pip appears', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy', theme: ThemeMode.dark);

      expect(find.byType(PipAvatar), findsNothing);
      expect(_v1PipFinder, findsNothing);

      await _tapToggle(tester);

      expect(tester.widget<NestToggle>(_toggle).value, isTrue);
      expect(
        await _consentInDb(
          tester,
          PrivacyConsentRepositoryImpl(db: GetIt.instance<AppDatabase>()),
        ),
        isTrue,
      );
      expect(find.text('Your family’s privacy'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P04 — notice dialog stress', () {
    testWidgets('320dp at text scale 1.3: no overflow, both dismiss paths', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      await tester.tap(_notice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Privacy Notice'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(
        tester.getSize(find.byType(NestButton).last).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
        reason: 'the dialog action keeps the parent tap target',
      );
      expect(
        tester.getSize(find.byType(NestButton).last).width,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(tester.takeException(), isNull);

      await tester.tapAt(const Offset(8, 8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Privacy Notice'), findsNothing);
      expect(currentPath(tester), '/privacy');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the dialog restates all four promises', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(_notice);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // One centred line per promise (row copy + dialog line each).
      for (final title in _titles) {
        expect(find.text(title), findsNWidgets(2));
      }

      await disposeApp(tester);
    });
  });

  group('P04 — short screen and alignment', () {
    testWidgets('320x568 scrolls the opt card into reach and taps', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 568),
        textScale: 1.3,
      );

      expect(find.text('Your family’s privacy'), findsOneWidget);
      expect(find.byType(NestBottomCta), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tapToggle(tester);

      expect(find.text('Optional: help improve Nestling'), findsOneWidget);
      expect(tester.widget<NestToggle>(_toggle).value, isTrue);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final width in const <int>[320, 430]) {
      testWidgets('$width.dp: content, cards and CTA share the 20px gutters', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPrivacy(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
          textScale: 1,
        );

        expect(
          tester.getTopLeft(find.text('Your family’s privacy')).dx,
          NestSpacing.padSide,
        );

        final list = find
            .ancestor(
              of: find.text('No ads or tracking — ever'),
              matching: find.byType(NestList),
            )
            .first;
        expect(tester.getTopLeft(list).dx, NestSpacing.padSide);
        expect(tester.getTopRight(list).dx, width - NestSpacing.padSide);

        final optCard = find
            .ancestor(
              of: find.text('Optional: help improve Nestling'),
              matching: find.byType(NestCard),
            )
            .first;
        expect(tester.getTopLeft(optCard).dx, NestSpacing.padSide);
        expect(tester.getTopRight(optCard).dx, width - NestSpacing.padSide);

        expect(tester.getTopLeft(_continue).dx, NestSpacing.padSide);
        expect(tester.getTopRight(_continue).dx, width - NestSpacing.padSide);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }
  });

  group('P04 — optimistic switch and failure caption (P04-5, P04-6)', () {
    testWidgets('the switch answers on the next frame, before Drift replies', (
      tester,
    ) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final repository = _ScriptedPrivacyConsentRepository(
        items: Stream<List<ConsentOption>>.value(const <ConsentOption>[
          ConsentOption(
            id: ConsentOptionIds.crash,
            title: 'c',
            detail: 'd',
            enabled: false,
          ),
        ]),
        // The write stays in flight for 400 fake ms, so the frame rendered
        // right after the tap lands before the database has answered.
        onWrite: ({required consent}) =>
            Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      final bloc = PrivacyConsentBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<PrivacyConsentBloc>.value(
            value: bloc,
            child: const PrivacyConsentView(),
          ),
        ),
      );
      bloc.add(const PrivacyConsentLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _scrollToToggle(tester);
      await tester.tap(_toggle);
      await tester.pump();

      expect(
        tester.widget<NestToggle>(_toggle).value,
        isTrue,
        reason: 'the switch must not wait for the database round-trip',
      );
      expect(repository.writes, <bool>[true]);
      expect(bloc.state.crashConsent, isTrue);
      expect(tester.takeException(), isNull);

      // Let the in-flight write finish so the bloc closes cleanly.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('a failed OFF write says crash reports are still on', (
      tester,
    ) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final repository = _ScriptedPrivacyConsentRepository(
        items: Stream<List<ConsentOption>>.value(const <ConsentOption>[
          ConsentOption(
            id: ConsentOptionIds.crash,
            title: 'c',
            detail: 'd',
            enabled: true,
          ),
        ]),
        onWrite: ({required consent}) =>
            Future<void>.error(Exception('read only')),
      );
      final bloc = PrivacyConsentBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<PrivacyConsentBloc>.value(
            value: bloc,
            child: const PrivacyConsentView(),
          ),
        ),
      );
      bloc.add(const PrivacyConsentLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _scrollToToggle(tester);
      await tester.tap(_toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        tester.widget<NestToggle>(_toggle).value,
        isTrue,
        reason: 'the failed write reverts to the stored opt-in',
      );
      expect(find.textContaining('it stays off'), findsNothing);
      expect(
        find.textContaining('Crash reports are still on.'),
        findsOneWidget,
      );
      expect(bloc.state.status, PrivacyConsentStatus.failure);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('a failed ON write says the choice stays off', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final repository = _ScriptedPrivacyConsentRepository(
        items: Stream<List<ConsentOption>>.value(const <ConsentOption>[
          ConsentOption(
            id: ConsentOptionIds.crash,
            title: 'c',
            detail: 'd',
            enabled: false,
          ),
        ]),
        onWrite: ({required consent}) =>
            Future<void>.error(Exception('disk full')),
      );
      final bloc = PrivacyConsentBloc(repository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<PrivacyConsentBloc>.value(
            value: bloc,
            child: const PrivacyConsentView(),
          ),
        ),
      );
      bloc.add(const PrivacyConsentLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await _scrollToToggle(tester);
      await tester.tap(_toggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.widget<NestToggle>(_toggle).value, isFalse);
      expect(
        find.textContaining(
          'Oops — your choice wasn’t saved. Continue anyway; it stays off.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('still on'), findsNothing);
      expect(bloc.state.errorMessage, contains('disk full'));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('the failure state keeps Continue and the screen usable', (
      tester,
    ) async {
      await setUpTestScope();
      await _useRepository(
        _FakePrivacyConsentRepository(
          Stream<List<ConsentOption>>.error(Exception('offline')),
        ),
      );
      await pumpAppRoute(tester, '/privacy');
      await tester.pump(const Duration(milliseconds: 300));

      expect(_failureCaption, findsOneWidget);
      expect(
        tester.getSize(_continue).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      await tester.tap(_continue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/add-children');

      await disposeApp(tester);
    });
  });

  group('P04 — promise row glyphs (orchestrator note item 1)', () {
    // The orchestrator asked for "a widget test that all four row icons find
    // their SvgPicture/Icon". Rows 1-3 are verifiable here and green; row 4 is
    // covered by the skipped `[P04-2]` proof in p04_bugs_test.dart because the
    // trash glyph needs the shared `ic_trash.svg` (SHARED_REQUEST §1), which
    // RULES §1 forbids P04 from adding. This test pins the three shipped
    // glyphs — asset AND tint — so a wrong-asset or invisible-glyph regression
    // cannot slip through, and documents row 4 as the open gap.
    testWidgets('rows 1-3 render their own tinted glyph; row 4 is the gap', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final expected = <String, ({String asset, Color ink})>{
        'No ads or tracking — ever': (
          asset: NestIcons.noAds,
          ink: NestColors.light.leafInk,
        ),
        'Children only need a nickname': (
          asset: NestIcons.person,
          ink: NestColors.light.lilac,
        ),
        'Data stored in the UK (London)': (
          asset: NestIcons.pinUk,
          ink: NestColors.light.sky,
        ),
      };

      for (final entry in expected.entries) {
        final row = find
            .ancestor(
              of: find.text(entry.key),
              matching: find.byType(Semantics),
            )
            .first;
        final icon = find.descendant(of: row, matching: find.byType(NestIcon));
        expect(icon, findsOneWidget, reason: entry.key);

        final widget = tester.widget<NestIcon>(icon);
        expect(widget.assetName, entry.value.asset, reason: entry.key);
        expect(widget.size, 24, reason: entry.key);
        expect(widget.color, entry.value.ink, reason: entry.key);

        // The glyph is really painted, not an empty tile: one SVG per row.
        final picture = find.descendant(
          of: row,
          matching: find.byType(SvgPicture),
        );
        expect(picture, findsOneWidget, reason: entry.key);
        final svg = tester.widget<SvgPicture>(picture);
        expect(
          (svg.bytesLoader as SvgAssetLoader).assetName,
          entry.value.asset,
        );
        expect(
          svg.colorFilter,
          isNotNull,
          reason: '${entry.key}: the glyph must be tinted, never default black',
        );
        expect(svg.width, 24);
        expect(svg.height, 24);
      }

      // Row 4: tile present and tinted, glyph still missing (SHARED_REQUEST §1).
      final deleteRow = find
          .ancestor(
            of: find.text('Delete everything anytime'),
            matching: find.byType(Semantics),
          )
          .first;
      expect(
        find.descendant(of: deleteRow, matching: find.byType(NestIcon)),
        findsNothing,
        reason:
            'row 4 has no trash glyph yet — ic_trash.svg is still missing; this '
            'assertion flips when the shared asset lands ([P04-2])',
      );
      final deleteTile = find
          .descendant(of: deleteRow, matching: find.byType(Container))
          .first;
      final decoration =
          tester.widget<Container>(deleteTile).decoration! as BoxDecoration;
      expect(decoration.color, NestColors.light.peachTint);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the three shipped glyphs are tinted', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/privacy', theme: theme);
        final icons = find.descendant(
          of: find.byType(NestList),
          matching: find.byType(NestIcon),
        );
        expect(icons, findsNWidgets(3));

        final palette = theme == ThemeMode.light
            ? NestColors.light
            : NestColors.dark;
        final inks = <Color>[palette.leafInk, palette.lilac, palette.sky];
        for (final icon in icons.evaluate()) {
          final widget = tester.widget<NestIcon>(
            find.byElementPredicate((e) => e == icon),
          );
          expect(
            inks,
            contains(widget.color),
            reason:
                '${widget.assetName} must use its tile ink in ${theme.name}',
          );
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('P04 — promise row geometry (SPACING_SPEC §9.3/§9.4)', () {
    testWidgets('four 40px tiles, tints in order, three 72px-indent dividers', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final list = find.byType(NestList);
      expect(
        find.descendant(of: list, matching: find.byType(Divider)),
        findsNWidgets(3),
      );
      for (final divider
          in find
              .descendant(of: list, matching: find.byType(Divider))
              .evaluate()) {
        expect(
          tester
              .widget<Divider>(find.byElementPredicate((e) => e == divider))
              .indent,
          72,
        );
      }

      final tints = <String, Color>{
        'No ads or tracking — ever': NestColors.light.leafTint,
        'Children only need a nickname': NestColors.light.lilacTint,
        'Data stored in the UK (London)': NestColors.light.skyTint,
        'Delete everything anytime': NestColors.light.peachTint,
      };

      for (final entry in tints.entries) {
        final row = find
            .ancestor(
              of: find.text(entry.key),
              matching: find.byType(Semantics),
            )
            .first;
        final tile = find
            .descendant(of: row, matching: find.byType(Container))
            .first;
        final size = tester.getSize(tile);
        expect(size.width, 40, reason: '${entry.key} tile');
        expect(size.height, 40, reason: '${entry.key} tile');

        final decoration =
            tester.widget<Container>(tile).decoration! as BoxDecoration;
        expect(decoration.color, entry.value, reason: '${entry.key} tint');
        expect(
          decoration.borderRadius,
          BorderRadius.circular(NestSpacing.s3),
          reason: '40px tiles use radius 12',
        );
        // P04 rows pad 7px vertically (design wins over NestListRow's 10px).
        expect(tester.getSize(row).height, greaterThanOrEqualTo(56));
      }

      // Rows 1-3 carry their line icon; row 4 keeps the peach tile reserved
      // with no stand-in glyph until the shared ic_trash.svg lands
      // (docs/screens/P04/SHARED_REQUEST.md item 1).
      final icons = find.descendant(of: list, matching: find.byType(NestIcon));
      expect(icons, findsNWidgets(3));
      final deleteRow = find
          .ancestor(
            of: find.text('Delete everything anytime'),
            matching: find.byType(Semantics),
          )
          .first;
      expect(
        find.descendant(of: deleteRow, matching: find.byType(NestIcon)),
        findsNothing,
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('titles and subtitles wrap instead of ellipsising', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1,
      );

      for (final title in _titles) {
        final widget = tester.widget<Text>(find.text(title));
        expect(widget.softWrap, isTrue, reason: title);
        expect(widget.maxLines, isNull, reason: '$title must not clamp lines');
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the shield illustration is 84x84 and labelled', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final picture = find.descendant(
        of: find.bySemanticsLabel(
          'A shield with a leaf and a heart, protecting your family',
        ),
        matching: find.byType(SvgPicture),
      );
      expect(picture, findsOneWidget);
      expect(tester.getSize(picture).width, 84);
      expect(tester.getSize(picture).height, 84);
      expect(
        find.bySemanticsLabel(
          'A shield with a leaf and a heart, protecting your family',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });
  });

  group('P04 — control accessibility', () {
    testWidgets('the back chevron is a labelled 44px button', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final back = find.bySemanticsLabel('Back');
      expect(back, findsOneWidget);
      expect(
        tester.getSize(back).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tester.getSize(back).width,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tester.getSemantics(back).getSemanticsData().flagsCollection.isButton,
        isTrue,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the notice link is a labelled button with a 44px target', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      final link = find.bySemanticsLabel('Read the full Privacy Notice');
      expect(link, findsWidgets);
      final data = tester.getSemantics(link.first).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.label, 'Read the full Privacy Notice');

      final target = find
          .ancestor(of: _notice, matching: find.byType(ConstrainedBox))
          .first;
      expect(
        tester.getSize(target).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tester.getSize(target).width,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await disposeApp(tester);
    });

    testWidgets('promise rows are read as text, not as buttons', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/privacy');

      for (final title in _titles) {
        final row = find.ancestor(
          of: find.text(title),
          matching: find.byType(Semantics),
        );
        final data = tester.getSemantics(row.first).getSemanticsData();
        expect(
          data.flagsCollection.isButton,
          isFalse,
          reason: '"$title" is display-only',
        );
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // Guards against a regression where the view stops wiring the toggle to the
  // bloc: the tap must reach the repository as a `PrivacyConsentCrashToggled`
  // write (the bloc's own contract is covered in the bloc test).
  testWidgets('the toggle dispatches PrivacyConsentCrashToggled', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final repository = _RecordingPrivacyConsentRepository();
    final bloc = PrivacyConsentBloc(repository: repository);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: NestTheme.light(),
        home: BlocProvider<PrivacyConsentBloc>.value(
          value: bloc,
          child: const PrivacyConsentView(),
        ),
      ),
    );
    bloc.add(const PrivacyConsentLoadRequested());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.writes, isEmpty);

    await _tapToggle(tester);
    expect(repository.writes, <bool>[true]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
