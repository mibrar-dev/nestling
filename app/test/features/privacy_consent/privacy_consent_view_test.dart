// P04 Privacy & consent — widget contract.
//
// Covers: static copy + shield, light + dark, widths 320/390/430 at
// 1.0/1.3, every PrivacyConsentBloc status, Continue/back/footnote
// navigation, the crash-toggle write-through, the no-Pip rule, the 20px
// gutter alignment and the bottom-edge owner rule.
//
// All four promise rows render the shared tinted glyph in both themes
// (`privacy_consent_artwork_test.dart`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
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

const List<String> _subs = <String>[
  'No analytics profiles, no ad SDKs, ever',
  'No photos, no email, no chat, no location',
  'Kept on UK servers, nothing leaves',
  'One tap and your family data is gone',
];

const String _shieldLabel =
    'A shield with a leaf and a heart, protecting your family';

/// Any v1 `pip_stage_*.svg` illustration (banned from product screens).
Finder get _v1PipFinder => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName.contains('pip_stage'),
);

/// Repository with a caller-controlled items stream, for the states the Drift
/// repository cannot reach (pending load, empty, stream error).
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

/// Pumps `/privacy` through the real app (router, DI, themes) at [surface]
/// and [textScale].
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

/// Pumps [PrivacyConsentView] directly (no router) under the real theme with
/// [repository] driving the bloc.
Future<PrivacyConsentBloc> _pumpPrivacyView(
  WidgetTester tester,
  PrivacyConsentRepository repository, {
  ThemeMode theme = ThemeMode.light,
}) async {
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
  await tester.pump();
  return bloc;
}

Future<void> _disposeView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('P04 privacy — copy, theming, width and scale', () {
    testWidgets('light: renders head, shield, 4 rows, opt card and CTAs', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Orchestrator rule: NestStatusBar only reserves height.
      expect(find.text('9:41'), findsNothing);
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        NestDevice.statusH,
      );

      expect(find.text('Your family’s privacy'), findsOneWidget);
      expect(
        find.text('Exactly what we store — and nothing else.'),
        findsOneWidget,
      );
      for (final title in _titles) {
        expect(find.text(title), findsOneWidget);
      }
      for (final sub in _subs) {
        expect(find.text(sub), findsOneWidget);
      }
      expect(find.bySemanticsLabel(_shieldLabel), findsOneWidget);
      expect(find.text('Optional: help improve Nestling'), findsOneWidget);
      expect(
        find.text('Share anonymous crash reports. No names, no photos.'),
        findsOneWidget,
      );

      final toggle = tester.widget<NestToggle>(
        find.byKey(const ValueKey('p04_crash_toggle')),
      );
      expect(toggle.value, isFalse);

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Read the full Privacy Notice'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark: same content without overflow', (tester) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('Your family’s privacy'), findsOneWidget);
      for (final title in _titles) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Continue'), findsOneWidget);
      expect(find.bySemanticsLabel(_shieldLabel), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('no Pip anywhere (shield screen, orchestrator PIP rule)', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.byType(PipAvatar), findsNothing);
      expect(_v1PipFinder, findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets('$themeName ${width}dp at text scale $scale', (
            tester,
          ) async {
            await setUpTestScope();
            await _pumpPrivacy(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(find.text('Your family’s privacy'), findsOneWidget);
            for (final title in _titles) {
              expect(find.text(title), findsOneWidget);
            }
            expect(find.text('Continue'), findsOneWidget);
            expect(find.text('Read the full Privacy Notice'), findsOneWidget);
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }
  });

  group('P04 privacy — BLoC states render the static screen', () {
    testWidgets('initial: content renders before the load event', (
      tester,
    ) async {
      final bloc = await _pumpPrivacyView(
        tester,
        _FakePrivacyConsentRepository(
          const Stream<List<ConsentOption>>.empty(),
        ),
      );

      expect(bloc.state.status, PrivacyConsentStatus.initial);
      expect(find.text('Your family’s privacy'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      // Disabled until loaded.
      expect(
        tester
            .widget<NestToggle>(find.byKey(const ValueKey('p04_crash_toggle')))
            .onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loading: content renders while no items have arrived', (
      tester,
    ) async {
      final bloc = await _pumpPrivacyView(
        tester,
        _FakePrivacyConsentRepository(
          const Stream<List<ConsentOption>>.empty(),
        ),
      );
      bloc.add(const PrivacyConsentLoadRequested());
      await tester.pump();

      expect(bloc.state.status, PrivacyConsentStatus.loading);
      expect(find.text('Your family’s privacy'), findsOneWidget);
      for (final title in _titles) {
        expect(find.text(title), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('failure: Continue still works + inline caption shows', (
      tester,
    ) async {
      final bloc = await _pumpPrivacyView(
        tester,
        _FakePrivacyConsentRepository(
          Stream<List<ConsentOption>>.error(Exception('offline')),
        ),
      );
      bloc.add(const PrivacyConsentLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(bloc.state.status, PrivacyConsentStatus.failure);
      expect(find.text('Your family’s privacy'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(
        find.text(
          'Oops — your choice wasn’t saved. Continue anyway; it stays off.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<NestToggle>(find.byKey(const ValueKey('p04_crash_toggle')))
            .onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P04 privacy — interactions', () {
    testWidgets('tap toggle writes crash consent on', (tester) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        tester
            .widget<NestToggle>(find.byKey(const ValueKey('p04_crash_toggle')))
            .value,
        isFalse,
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('p04_crash_toggle')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p04_crash_toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        tester
            .widget<NestToggle>(find.byKey(const ValueKey('p04_crash_toggle')))
            .value,
        isTrue,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Continue opens /add-children', (tester) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      final router = GoRouter.of(tester.element(find.text('Continue')));

      // The footnote sits inside the scrollable bottom CTA; ensure the
      // primary CTA is visible (it always is at 390x844) then tap it.
      await tester.tap(find.byKey(const ValueKey('p04_continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/add-children',
      );

      await disposeApp(tester);
    });

    testWidgets('back chevron pops to the previous screen', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/create-account');
      unawaited(
        GoRouter.of(tester.element(find.byType(Scaffold))).push('/privacy'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Your family’s privacy'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        GoRouter.of(tester.element(find.byType(Scaffold)))
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        '/create-account',
      );

      await disposeApp(tester);
    });

    testWidgets('footnote opens the Privacy Notice dialog + Close dismisses', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p04_privacy_notice')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Privacy Notice'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Privacy Notice'), findsNothing);
      expect(find.text('Your family’s privacy'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P04 privacy — accessibility', () {
    testWidgets('labels and tap targets meet the parent contract', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.bySemanticsLabel('Continue'), findsWidgets);
      expect(
        find.bySemanticsLabel('Read the full Privacy Notice'),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(_shieldLabel), findsOneWidget);
      expect(
        find.bySemanticsLabel('Share anonymous crash reports'),
        findsOneWidget,
      );

      final headlineData = tester.getSemantics(
        find.text('Your family’s privacy'),
      );
      expect(headlineData.getSemanticsData().flagsCollection.isHeader, isTrue);

      final continueSize = tester.getSize(
        find.byKey(const ValueKey('p04_continue')),
      );
      expect(continueSize.height, greaterThanOrEqualTo(52));
      expect(continueSize.height, greaterThanOrEqualTo(NestDevice.tapParent));

      final toggleBox = find.byKey(const ValueKey('p04_crash_toggle'));
      expect(
        tester.getSize(toggleBox).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      final footnote = find.byKey(const ValueKey('p04_privacy_notice'));
      final footnoteAncestor = find
          .ancestor(of: footnote, matching: find.byType(ConstrainedBox))
          .first;
      expect(
        tester.getSize(footnoteAncestor).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await disposeApp(tester);
    });

    testWidgets('tap targets hold at 320dp with text scale 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('p04_continue'))).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('p04_crash_toggle'))).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P04 privacy — alignment (owner rule)', () {
    testWidgets('content shares the 20px gutters at 390px', (tester) async {
      await setUpTestScope();
      await _pumpPrivacy(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(tester.getTopLeft(find.text('Your family’s privacy')).dx, 20);
      final list = find
          .ancestor(
            of: find.text('No ads or tracking — ever'),
            matching: find.byType(NestList),
          )
          .first;
      expect(tester.getTopLeft(list).dx, 20);
      expect(tester.getTopRight(list).dx, 370);

      final optCard = find
          .ancestor(
            of: find.text('Optional: help improve Nestling'),
            matching: find.byType(NestCard),
          )
          .first;
      expect(tester.getTopLeft(optCard).dx, 20);
      expect(tester.getTopRight(optCard).dx, 370);

      final cta = find.byKey(const ValueKey('p04_continue'));
      expect(tester.getTopLeft(cta).dx, 20);
      expect(tester.getTopRight(cta).dx, 370);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P04 privacy — bottom edge (owner rule)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the bottom CTA surface reaches the edge', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpPrivacy(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          textScale: 1,
        );

        final screenBottom =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final screenRight =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;

        final bar = find.byType(NestBottomCta);
        expect(bar, findsOneWidget);
        final rect = tester.getRect(bar);
        expect(
          rect.bottom,
          screenBottom,
          reason: 'no strip below the bar down to the physical edge',
        );
        expect(rect.left, 0);
        expect(rect.right, screenRight);

        final box = tester.widget<DecoratedBox>(
          find.descendant(of: bar, matching: find.byType(DecoratedBox)).first,
        );
        final decoration = box.decoration as BoxDecoration;
        final expected = theme == ThemeMode.light
            ? NestColors.light.surface
            : NestColors.dark.surface;
        expect(
          decoration.color,
          expected,
          reason: 'the home-indicator area keeps the CTA surface colour',
        );

        await disposeApp(tester);
      });
    }
  });
}
