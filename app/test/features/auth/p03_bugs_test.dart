// P03 Create account — adversarial bug proofs.
//
// Iterations 2–5 closed every bug reported by iterations 1–4; those proofs
// run green as regression guards (including P03-BUG-6 and P03-BUG-21, fixed
// by the shared batch `7eaa1f7` and the iteration-5 build respectively).
// Two proofs are open and skip-marked with their ids so the suite stays
// green; un-skip each with its fix. Full reports live in
// `docs/screens/P03/6_bugs.md`.
//
//   flutter test test/features/auth/p03_bugs_test.dart
//
// P03-BUG-1..15  iterations 1–4's bugs — all fixed; regression guards.
// P03-BUG-16 (MINOR, open — Decision A)  an invalid input paints no danger
//                border. The shared `NestTextField` (`7eaa1f7`) now renders
//                the error gutter row + forced danger border via `errorText`,
//                but its row is a plain `Text` with no live region (§8), so
//                switching to it would trade BUG-16 for BUG-20. Decision
//                (review, iteration 5): keep the screen-owned live-region
//                rows and leave this skip-marked pending SHARED_REQUEST §8.
//                Do not pass `errorText` while keeping the owned rows (the
//                message would render twice).
// P03-BUG-17 (MINOR, shared §6)  the served Inter build is ~3–4% wider than
//                the design's, so the subtitle breaks after "Children"
//                instead of "Children never". No local test is possible and
//                no token-violating local fix is acceptable.
// P03-BUG-18..21  all fixed (overhang reachability, first-frame/stale
//                measurement, live regions, the empty-live-region
//                regression).
// P03-BUG-22 (MINOR, latent)  the overhang fallback in `_RenderHitTestExpand`
//                has no `!hit` gate: where a legal target's 44dp box overlaps
//                the submit button (the device's normal geometry —
//                harness-synthesised at scale 0.7 because the test font is
//                ~2× wider than Inter), a tap is delivered to the button
//                *and* to the link. Inert today, a double activation once the
//                Terms/Notice routes land. Fix: run the fallback only when
//                the normal path hit nothing.
//
// Checked and clean this iteration (no proof needed): kid-mode deep link →
// `/parental-gate`; restart persistence (one owner row); back/deep links;
// 320/390/430 × 1.0/1.3 matrix; dark-mode contrast; all nine strings
// byte-identical to the HTML (U+2019, U+2014, one U+00A0) with the
// target/paragraph equality proofs green; bottom edge/alignment per the
// owner rules; the two legal targets' lateral overlap is design-faithful;
// money/timezone/children cases N/A; CHILD ORDER N/A. The harness' fallback
// font is not Inter, so its line breaks are not product geometry.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';
import 'package:nestling/features/auth/presentation/views/create_account_view.dart';

import '../../test_scope.dart';

const String _emailError = 'Enter a valid email address';
const String _passwordError = 'Use at least 8 characters';

/// A repository that answers with no members; the empty form never reaches it.
class _SilentAuthRepository implements AuthRepository {
  @override
  Future<List<AuthAccount>> getItems() async => const <AuthAccount>[];
  @override
  Stream<List<AuthAccount>> watchItems() =>
      const Stream<List<AuthAccount>>.empty();
  @override
  Future<void> createAccount({String? email, String? name}) async {}
  @override
  Future<void> createAccountSocial({required AuthProvider provider}) async {}
}

/// Fails with an `Error`, not an `Exception` (P03-BUG-5).
class _ErrorAuthRepository implements AuthRepository {
  @override
  Future<List<AuthAccount>> getItems() async => const <AuthAccount>[];
  @override
  Stream<List<AuthAccount>> watchItems() =>
      const Stream<List<AuthAccount>>.empty();
  @override
  Future<void> createAccount({String? email, String? name}) async =>
      throw StateError('boom-error');
  @override
  Future<void> createAccountSocial({required AuthProvider provider}) async {}
}

/// Records `onError` callbacks for P03-BUG-14.
class _RecordingObserver extends BlocObserver {
  final List<(Object, StackTrace)> errors = <(Object, StackTrace)>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add((error, stackTrace));
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> _disposeView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Finder _emailInput() => find.descendant(
  of: find.byKey(const ValueKey('p03_email')),
  matching: find.byType(TextField),
);

Finder _passwordInput() => find.descendant(
  of: find.byKey(const ValueKey('p03_password')),
  matching: find.byType(TextField),
);

Future<void> _pumpCreateAccount(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  Size surface = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await setUpTestScope();
  await pumpAppRoute(tester, '/create-account', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The legal caption block's laid-out height, implementation-agnostic.
///
/// `NestBottomCta`'s column is `[button, s2 gap, caption]` with an `s4`
/// bottom padding, so the caption's height is what is left below the button.
double _captionBlockHeight(WidgetTester tester) {
  final panel = tester.getRect(find.byType(NestBottomCta));
  final button = tester.getRect(
    find.descendant(
      of: find.byType(NestBottomCta),
      matching: find.byType(NestButton),
    ),
  );
  return panel.bottom - button.bottom - NestSpacing.s2 - NestSpacing.s4;
}

/// The legal caption's `RichText`: the one whose text holds the sentence
/// (inner link `Text`s inside `WidgetSpan`s match `RichText` too, so `.last`
/// no longer finds the paragraph).
Finder _captionTextFinder() => find.byWidgetPredicate(
  (w) =>
      w is RichText && w.text.toPlainText().contains('By continuing you agree'),
);

/// The caption's `RenderParagraph`.
RenderParagraph _captionParagraph(WidgetTester tester) {
  return tester.renderObject<RenderParagraph>(_captionTextFinder());
}

/// The caption's global top-left, so paragraph-local line metrics can be
/// compared against global label boxes.
Offset _captionOrigin(WidgetTester tester) =>
    tester.getRect(_captionTextFinder()).topLeft;

/// The laid-out box of [label] inside the legal caption, read off the
/// caption's own `RenderParagraph` (font-independent: it asks the engine
/// where the glyphs actually went), shifted to global coordinates.
///
/// Rendered link labels use U+00A0 (COPY rule), so a space-form query falls
/// back to the no-break-space form.
Rect _labelBox(WidgetTester tester, String label) {
  final paragraph = _captionParagraph(tester);
  final plain = paragraph.text.toPlainText();
  var query = label;
  var start = plain.indexOf(query);
  if (start < 0) {
    query = label.replaceAll(' ', String.fromCharCode(0xa0));
    start = plain.indexOf(query);
  }
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: 'label "$label" must occur in the caption text',
  );
  Rect? box;
  for (final found in paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + query.length),
  )) {
    box = box == null ? found.toRect() : box.expandToInclude(found.toRect());
  }
  final origin = tester.getRect(_captionTextFinder()).topLeft;
  return box!.shift(origin);
}

/// The caption's line metrics, computed from its own span (so the harness
/// font's line heights, not the glyph boxes, are what is measured).
List<LineMetrics> _captionLineMetrics(WidgetTester tester) {
  final paragraph = _captionParagraph(tester);
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
  )..layout(maxWidth: paragraph.size.width);
  return painter.computeLineMetrics();
}

/// The height of the caption line that [label] sits on.
///
/// The label box is global while line metrics accumulate from the paragraph
/// top, so the paragraph's global top offsets the comparison.
double _linkLineHeight(WidgetTester tester, String label) {
  final box = _labelBox(tester, label);
  final center = (box.top + box.bottom) / 2 - _captionOrigin(tester).dy;
  var y = 0.0;
  for (final metric in _captionLineMetrics(tester)) {
    if (center >= y && center <= y + metric.height) {
      return metric.height;
    }
    y += metric.height;
  }
  return -1;
}

/// The rendered lines of the legal caption as global bands.
///
/// Derived from line metrics (not glyph boxes) so every laid-out line is
/// included exactly once. Bands — not 1px top strips — are what a label box
/// overlaps: a 13px font in a 20dp line starts several px below the line top.
List<Rect> _captionLineBands(WidgetTester tester) {
  final left = _captionOrigin(tester).dx;
  final width = tester.getRect(_captionTextFinder()).width;
  var y = _captionOrigin(tester).dy;
  final bands = <Rect>[];
  for (final metric in _captionLineMetrics(tester)) {
    bands.add(Rect.fromLTRB(left, y, left + width, y + metric.height));
    y += metric.height;
  }
  return bands;
}

void main() {
  // -------------------------------------------------------------------
  // P03-BUG-1 (MAJOR) — the legal caption is one 44dp link row per line,
  // inflating the CTA panel and eating the form above it.
  //
  // Bounds are calibrated against the widget-test harness font, which is
  // ~1em per glyph and therefore wider than Nunito/Inter: the caption needs
  // 3 lines at 390dp and 4 lines at 320dp × 1.3 in this harness (2 lines on
  // a real device). The design's 40dp caption is 2×20dp link lines on
  // device (P03-BUG-12); in the harness the equivalent bound is
  // 3×20dp+4 = 64dp. See 6_bugs.md.
  // -------------------------------------------------------------------
  testWidgets(
    'P03-BUG-1a the legal caption is its text lines, not 44dp link rows',
    (tester) async {
      await _pumpCreateAccount(tester);

      expect(
        _captionBlockHeight(tester),
        lessThanOrEqualTo(3 * 20 + 4),
        reason:
            'each link hit target must overlap its text line (the HTML '
            '`.link { min-height:44px; margin:-12px 0 }` trick) instead of '
            'adding 44dp of layout height per row; iteration 1 measured 80dp',
      );

      await disposeApp(tester);
    },
  );

  testWidgets(
    'P03-BUG-1b the CTA panel keeps the design height (no 2× caption)',
    (tester) async {
      await _pumpCreateAccount(tester);

      // Design: 16 + 52 + 8 + 2×20 + 16 ≈ 148dp of content in the harness
      // (the design's extra home-indicator inset is not modelled here; the
      // device measurement in iteration 1 was 214dp vs the design's 167dp).
      expect(
        tester.getSize(find.byType(NestBottomCta)).height,
        lessThanOrEqualTo(156),
        reason: 'the bottom bar must not eat the form above it',
      );

      await disposeApp(tester);
    },
  );

  testWidgets('P03-BUG-1c the CTA panel keeps its height at text scale 1.3', (
    tester,
  ) async {
    await _pumpCreateAccount(tester, textScale: 1.3);

    // 16 + 52 + 8 + 3×20×1.3 + 16 ≈ 170dp (iteration 1 measured 232dp).
    expect(
      tester.getSize(find.byType(NestBottomCta)).height,
      lessThanOrEqualTo(174),
      reason: 'the caption must not double at larger text scales',
    );

    await disposeApp(tester);
  });

  testWidgets(
    'P03-BUG-1d the caption is still text-height at 320dp / scale 1.3',
    (tester) async {
      await _pumpCreateAccount(
        tester,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      // At 320dp the harness font needs four caption lines: 4×20×1.3 ≈
      // 104dp.
      expect(
        _captionBlockHeight(tester),
        lessThanOrEqualTo(108),
        reason:
            'at 320dp the caption may wrap, but never as 44dp link rows; '
            'iteration 1 measured 140dp',
      );

      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------
  // P03-BUG-2 (MAJOR) — validation fires on the first keystroke.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-2a typing the first character of an email shows no '
      'error', (tester) async {
    await _pumpCreateAccount(tester);

    await tester.enterText(_emailInput(), 's');
    await tester.pump();

    expect(
      find.text(_emailError),
      findsNothing,
      reason:
          'a partially typed address is not yet invalid; the error belongs '
          'on blur or submit, as on every other Nestling form',
    );

    await disposeApp(tester);
  });

  testWidgets('P03-BUG-2b clearing the email field shows no error', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    await tester.enterText(_emailInput(), 'sarah@example.co.uk');
    await tester.pump();
    await tester.enterText(_emailInput(), '');
    await tester.pump();

    expect(find.text(_emailError), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('P03-BUG-2c the first character of a password shows no error', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    await tester.enterText(_passwordInput(), 'n');
    await tester.pump();

    expect(
      find.text(_passwordError),
      findsNothing,
      reason: 'the helper already says "At least 8 characters"',
    );

    await disposeApp(tester);
  });

  testWidgets(
    'P03-BUG-2d submitting an empty form still shows both field errors',
    (tester) async {
      // The submit button is disabled while the form is invalid, so this
      // pumps the view with its own bloc and submits the way the button
      // would — the errors must still appear.
      GoogleFonts.config.allowRuntimeFetching = false;
      final bloc = AuthBloc(repository: _SilentAuthRepository())
        ..add(const AuthSubmitted());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const CreateAccountView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(bloc.state.emailError, authEmailErrorText);
      expect(bloc.state.passwordError, authPasswordErrorText);
      expect(find.text(_emailError), findsOneWidget);
      expect(find.text(_passwordError), findsOneWidget);

      await _disposeView(tester);
    },
  );

  // -------------------------------------------------------------------
  // P03-BUG-3 (MINOR, shared) — FIXED in the current tree by the shared
  // "onboarding header" fix (merge 2027506: compact `NestNavBar` is now
  // 4+44+12 = 60dp). Kept as a regression guard, green.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-3 the compact nav bar is the design 60dp', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    // `.nav-bar.compact`: padding-top 4 + 44 button + padding-bottom 12.
    expect(
      tester.getSize(find.byType(NestNavBar)).height,
      moreOrLessEquals(60, epsilon: 1),
      reason:
          'design/html-source/screens/P03-create-account.html:58 sets '
          '`min-height: 52px` with 4px top and 12px bottom padding around a '
          '44px button',
    );

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-4 (MINOR) — the legal links announce their label twice.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-4 the legal links announce their label once', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    final handle = tester.ensureSemantics();

    expect(find.bySemanticsLabel('Terms\nTerms'), findsNothing);
    expect(
      find.bySemanticsLabel('Privacy Notice\nPrivacy Notice'),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Terms'), findsOneWidget);
    expect(find.bySemanticsLabel('Privacy Notice'), findsOneWidget);

    handle.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-5 (MINOR) — a non-Exception throw strands the screen in a
  // permanent spinner: `on Exception` does not catch Errors.
  // -------------------------------------------------------------------
  test(
    'P03-BUG-5 a repository Error is surfaced, not a permanent spinner',
    () async {
      Object? unhandled;
      late AuthBloc bloc;
      await runZonedGuarded(() async {
        // The bloc must be built inside the guarded zone: the event-handler
        // error is raised in the zone that created the stream subscription.
        bloc = AuthBloc(repository: _ErrorAuthRepository())
          ..add(const AuthEmailChanged('parent@example.co.uk'))
          ..add(const AuthPasswordChanged('password123'));
        await Future<void>.delayed(const Duration(milliseconds: 5));
        bloc.add(const AuthSubmitted());
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, stack) => unhandled = error);

      expect(
        unhandled,
        isNull,
        reason: 'a repository Error must not escape the event handler',
      );
      expect(
        bloc.state.isSubmitting,
        isFalse,
        reason: 'iteration 1 stranded the screen with isSubmitting true',
      );
      expect(bloc.state.formError, isNotNull);

      await bloc.close();
    },
  );

  // -------------------------------------------------------------------
  // P03-BUG-6 (MINOR, shared) — `NestButton` announces its label twice.
  // Requires the core fix in SHARED_REQUEST item 4; un-skip when it lands.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-6 the main CTA does not announce its label twice', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    final handle = tester.ensureSemantics();

    expect(
      find.bySemanticsLabel('Create account\nCreate account'),
      findsNothing,
    );

    handle.dispose();
    await disposeApp(tester);
    // P03-BUG-6 is FIXED: the shared batch (7eaa1f7) excludes the inner
    // label Text, so the CTA node is a single 'Create account'. Kept green.
  });

  // -------------------------------------------------------------------
  // P03-BUG-7 (MINOR) — the headline does not take the design's line break
  // (ORCHESTRATOR_NOTES §2: constrain the title width, no hard newline).
  // The harness font is too wide for break-pattern assertions, so the proof
  // pins the width constraint that produces the design break in Nunito.
  // -------------------------------------------------------------------
  testWidgets(
    'P03-BUG-7 the headline is width-constrained for the design break',
    (tester) async {
      await _pumpCreateAccount(tester);

      expect(
        tester.getSize(find.text('Create your family account')).width,
        lessThanOrEqualTo(260),
        reason:
            'real-font widths are "Create your family" 251.2 and '
            '"family account" 197.7, so the title column must cap below '
            '252 (e.g. maxWidth 240) instead of filling the 350dp content '
            'width; the design breaks "Create your / family account"',
      );

      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------
  // P03-BUG-8 (MINOR) — the password helper is indented instead of sitting
  // on the 20dp gutter (ORCHESTRATOR_NOTES §4).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-8 the password helper sits on the field gutter', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    final fieldLeft = tester
        .getRect(find.byKey(const ValueKey('p03_password')))
        .left;
    final helperLeft = tester.getRect(find.text('At least 8 characters')).left;
    expect(
      helperLeft,
      fieldLeft,
      reason:
          'the design .field is a flex column: the helper starts at the '
          '20dp gutter; the app indents it 20dp (Material content '
          'padding); iteration 1 measured 40 vs 20',
    );

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-9 (MAJOR) — the "Privacy Notice" label wraps across two lines.
  // ORCHESTRATOR_NOTES §5: "By continuing you agree to our Terms and" /
  // "Privacy Notice". On the device the app renders
  // "…Terms and Privacy" / "Notice" — a lone underlined word on line 2
  // (ui/light.png: line 1 x 37–354, line 2 x 175–215).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-9 the Privacy Notice label never splits across lines', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    final label = _labelBox(tester, 'Privacy Notice');
    final lines = _captionLineBands(tester);
    final onOneLine = lines.where((band) => band.overlaps(label));
    expect(
      onOneLine.length,
      1,
      reason:
          'a two-word link must not break: ORCHESTRATOR_NOTES §5 puts the '
          'whole label on one line. Today the label spans two caption lines '
          '(device: "…Terms and Privacy" / "Notice")',
    );

    await disposeApp(tester);
  });

  testWidgets('P03-BUG-9b the caption never leaves a lone link fragment on a '
      'line by itself', (tester) async {
    await _pumpCreateAccount(tester);

    // Each link label must live on exactly one caption line at every width
    // and text scale the app supports.
    for (final cfg in const <List<Object>>[
      <Object>[320, 1.0],
      <Object>[390, 1.0],
      <Object>[430, 1.0],
      <Object>[390, 1.3],
      <Object>[320, 1.3],
    ]) {
      await _pumpCreateAccount(
        tester,
        surface: Size((cfg[0] as int).toDouble(), 844),
        textScale: cfg[1] as double,
      );
      for (final label in const <String>['Terms', 'Privacy Notice']) {
        final box = _labelBox(tester, label);
        final bands = _captionLineBands(tester);
        expect(
          bands.where((band) => band.overlaps(box)).length,
          1,
          reason:
              '"$label" splits across caption lines at ${cfg[0]}dp '
              'scale ${cfg[1]}',
        );
      }
      await disposeApp(tester);
      await _pumpCreateAccount(tester);
    }

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-10 (MAJOR) — the 44dp link targets no longer sit over the words
  // they serve. The BUG-1 overlay centres both targets as one adjacent
  // 88dp block (measured x 151–239 at 390dp), while the words they claim to
  // represent sit elsewhere ("Terms" at x 89–155 in the harness, at the end
  // of line 1 on the device).
  // -------------------------------------------------------------------
  for (final width in const <int>[320, 390, 430]) {
    testWidgets('P03-BUG-10 the $width dp link targets cover their own words', (
      tester,
    ) async {
      await _pumpCreateAccount(tester, surface: Size(width.toDouble(), 844));

      for (final entry in const <MapEntry<String, ValueKey<String>>>[
        MapEntry('Terms', ValueKey('p03_terms')),
        MapEntry('Privacy Notice', ValueKey('p03_privacy')),
      ]) {
        final label = _labelBox(tester, entry.key);
        final target = tester.getRect(find.byKey(entry.value));
        expect(
          label.overlaps(target),
          isTrue,
          reason:
              'the 44dp target for "${entry.key}" must sit over the word it '
              'labels; today the two targets are one centred 88dp block that '
              'covers plain text while the word itself is untappable',
        );
      }

      await disposeApp(tester);
    });
  }

  testWidgets('P03-BUG-10b the two link targets are not one contiguous block', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    // Stacked centred lines legitimately share x-projection (the design's
    // own 44px-tall inline hit boxes overlap the same way), so contiguity
    // is decided vertically: separate caption lines mean separate targets.
    // Iteration 2 put both boxes on one centred row, sharing an edge.
    final terms = tester.getRect(find.byKey(const ValueKey('p03_terms')));
    final privacy = tester.getRect(find.byKey(const ValueKey('p03_privacy')));
    expect(
      (terms.center.dy - privacy.center.dy).abs(),
      greaterThan(10),
      reason:
          'the two links sit on different caption lines ("Terms" line 1, '
          '"Privacy Notice" line 2), so their 44dp targets must centre '
          '20dp apart, not share one centred row',
    );

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-11 (MINOR) — the error text is indented 20dp inside the field
  // while the label, the input and the BUG-8 helper are all on the gutter.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-11 the error text sits on the field gutter', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    final bloc = BlocProvider.of<AuthBloc>(
      tester.element(find.byType(CreateAccountView)),
    );

    final fieldLeft = tester
        .getRect(find.byKey(const ValueKey('p03_password')))
        .left;
    expect(
      tester.getRect(find.text('At least 8 characters')).left,
      fieldLeft,
      reason: 'the helper is on the gutter (P03-BUG-8)',
    );

    // Reject a submit so both errors appear, then compare the error lines.
    bloc.add(const AuthSubmitted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.getRect(find.text(_passwordError)).left,
      fieldLeft,
      reason:
          'ORCHESTRATOR_NOTES §4: the hint is on the 20dp gutter, so the '
          'error that replaces it must be too; today it renders at left 40',
    );
    expect(
      tester.getRect(find.text(_emailError)).left,
      tester.getRect(find.byKey(const ValueKey('p03_email'))).left,
    );

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-12 (MINOR) — the caption's link lines are 18dp tall instead of
  // the design's 20dp (`.link { line-height: 20px }`), so the whole CTA
  // panel is ~4dp short: hairline 682.7 in the app vs 677.7 in the design
  // (UI iteration-2 deviation 2).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-12 the caption link lines are the design 20dp tall', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    for (final label in const <String>['Terms', 'Privacy Notice']) {
      expect(
        _linkLineHeight(tester, label),
        moreOrLessEquals(20, epsilon: 0.5),
        reason:
            'the design HTML sets `.link { line-height: 20px }`, so every '
            'caption line containing a link is 20dp tall and the block is '
            '40dp; today the lines are 18dp (NestType.caption) and the CTA '
            'panel sits 4dp short with the hairline at 682.7 vs 677.7',
      );
    }

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-13 (MINOR) — on a two-line caption the 44dp targets are 44×36
  // because the stack is only 36 tall (the device's normal 390dp geometry;
  // reproduced here at 430dp, where the harness font wraps to two lines).
  // DESIGN_SPEC §0.9 requires 44×44 parent targets.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-13 the 44dp legal targets stay 44 tall on a 2-line '
      'caption', (tester) async {
    await _pumpCreateAccount(tester, surface: const Size(430, 844));

    for (final key in const <ValueKey<String>>[
      ValueKey('p03_terms'),
      ValueKey('p03_privacy'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(
        size.height,
        greaterThanOrEqualTo(44),
        reason:
            'DESIGN_SPEC §0.9: parent tap targets are ≥44×44; the overlay '
            'is clamped to the caption text height, measured 44×36 — the '
            'device always renders a two-line caption',
      );
      expect(size.width, greaterThanOrEqualTo(44));
    }

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-14 (MINOR) — `on Object catch` surfaces the error but never
  // reports it (no `addError`), so no observer receives the stack trace.
  // -------------------------------------------------------------------
  test(
    'P03-BUG-14 a repository failure keeps its stack trace for observers',
    () async {
      final observer = _RecordingObserver();
      final original = Bloc.observer;
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = original);

      final bloc = AuthBloc(repository: _ErrorAuthRepository())
        ..add(const AuthEmailChanged('parent@example.co.uk'))
        ..add(const AuthPasswordChanged('password123'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      bloc.add(const AuthSubmitted());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(
        bloc.state.formError,
        isNotNull,
        reason: 'the user still sees the failure (P03-BUG-5)',
      );
      expect(
        observer.errors,
        isNotEmpty,
        reason:
            'the caught Object must be re-reported with `addError(error, '
            'stackTrace)` so the bloc observer gets the stack',
      );
      expect(observer.errors.first.$2.toString(), isNotEmpty);

      await bloc.close();
    },
  );

  // P03-BUG-16, open (see its restored proof near the end of this file): the
  // shared batch `7eaa1f7` already made `NestTextField` render an
  // `errorText` row on the gutter with the danger border forced, so the old
  // "mutually exclusive with BUG-11" note is obsolete — the fix is to pass
  // `errorText` and drop the screen-owned rows, gated on SHARED_REQUEST §8
  // for the live-region half (or an explicit decision to drop BUG-20).

  // -------------------------------------------------------------------
  // P03-BUG-15 (MAJOR, mandatory) — the subtitle uses a straight U+0027
  // apostrophe where the design HTML has `You&rsquo;re` (U+2019).
  // ORCHESTRATOR_NOTES iteration-3 item 2 + the standing COPY rule.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-15 the subtitle uses the design U+2019 apostrophe', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    expect(
      find.text(
        'You\u2019re the grown-up in charge. Children never need an email.',
      ),
      findsOneWidget,
      reason:
          'the HTML writes `You&rsquo;re`; a straight U+0027 is a different '
          'character (COPY rule). The app ships U+0027 today — also proved '
          'by copy_audit_test.dart ("subtitle")',
    );

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-18 (MINOR) — the legal targets' overhang beyond the caption
  // block is not hit-testable: Flutter bounds hit tests at the parent box,
  // so the rendered 44dp targets have ~32dp of effective height (the
  // `tester.getSize` proofs cannot see this).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-18 the legal targets are reachable over their full '
      '44dp box', (tester) async {
    // 430dp is the harness' two-line caption — the device's normal geometry.
    await _pumpCreateAccount(tester, surface: const Size(430, 844));

    for (final key in const <ValueKey<String>>[
      ValueKey('p03_terms'),
      ValueKey('p03_privacy'),
    ]) {
      final target = tester.renderObject(find.byKey(key));
      final rect = tester.getRect(find.byKey(key));
      for (final point in <Offset>[
        Offset(rect.center.dx, rect.top + 1),
        Offset(rect.center.dx, rect.bottom - 1),
      ]) {
        final hit = tester
            .hitTestOnBinding(point)
            .path
            .any((entry) => entry.target == target);
        expect(
          hit,
          isTrue,
          reason:
              'DESIGN_SPEC §0.9 needs a 44dp-tall target; the box at $point '
              'is outside the caption Stack, so Flutter never hit-tests it '
              '(only the intersecting ~32dp is reachable)',
        );
      }
    }

    await disposeApp(tester);
  });

  // NOTE (review finding 4): a `tapAt` proof for the button/link overlap
  // strip was attempted and removed — the strip never exists in the widget
  // harness (its wide fallback font always pushes "Terms" off caption
  // line 1, so the target cannot reach the submit row at 320/390/430).
  // On the device geometry it does (target top ≈ button bottom − 4dp);
  // taps there fire both, the submit wins functionally, and the links are
  // inert until their routes land (see the TODO on `_LegalTarget`).

  // -------------------------------------------------------------------
  // P03-BUG-19 (MINOR) — the targets come from a one-shot post-frame
  // measurement: they are missing from the first painted frame, and any
  // reflow that is not a MediaQuery/theme change (the runtime font swap is
  // the real one) leaves them stale. Layout-derived boxes fix both.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-19 the legal targets exist in the first painted frame', (
    tester,
  ) async {
    await setUpTestScope();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
    GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);

    // Exactly one pump: the first painted frame.
    await tester.pumpWidget(const NestlingApp(initialRoute: '/create-account'));

    expect(
      find.byKey(const ValueKey('p03_terms')),
      findsOneWidget,
      reason:
          'the link targets are part of the caption and must exist in the '
          'first painted frame; today a post-frame callback adds them one '
          'frame later (and a font swap can leave them stale)',
    );
    expect(find.byKey(const ValueKey('p03_privacy')), findsOneWidget);

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-20 (MINOR) — owning the error row moved the validation message
  // out of Material's live region: client-side errors are announced by
  // nothing (the screen only announces server `formError`s).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-20 a validation error is a live region', (tester) async {
    await _pumpCreateAccount(tester);
    final handle = tester.ensureSemantics();

    BlocProvider.of<AuthBloc>(tester.element(find.byType(CreateAccountView)))
        .add(const AuthSubmitted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The node carrying each message is the live region (P03-BUG-20) and
    // carries the message itself (P03-BUG-21: an empty live region
    // announces nothing).
    for (final message in const <String>[_passwordError, _emailError]) {
      expect(find.bySemanticsLabel(message), findsOneWidget);
      final data = tester
          .getSemantics(find.bySemanticsLabel(message).first)
          .getSemanticsData();
      expect(data.label, message);
      expect(data.flagsCollection.isLiveRegion, isTrue);
    }

    handle.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-16 (MINOR, STILL OPEN — un-skipped by Stage 3 iteration 5)
  // — an invalid field paints no danger border. Iteration 4 deleted and
  // iteration 5 skip-marked this proof on the premise that the shared
  // `hasError` flag never landed; in fact `7eaa1f7` landed it, together with
  // the gutter-aligned error row, so passing `errorText` no longer re-opens
  // P03-BUG-11 — the shared field already puts the message on the 20dp
  // gutter. What is still missing is only the live-region wrapper on that
  // shared row (SHARED_REQUEST §8), not a shared release. The design marks
  // the input itself, not just the message:
  // `.field input[aria-invalid="true"] { border-color: var(--danger) }`
  // (design/html-source/components.css:135, SPACING_SPEC §3).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-16 an invalid field paints the danger border', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    final bloc = BlocProvider.of<AuthBloc>(
      tester.element(find.byType(CreateAccountView)),
    );
    final tokens = tester.element(find.byType(NestBottomCta)).nest;

    /// The colours of every outline painted inside the keyed field.
    List<Color> fieldBorders(ValueKey<String> key) {
      final painted = find
          .byWidgetPredicate(
            (w) =>
                (w is DecoratedBox && w.decoration is BoxDecoration) ||
                (w is Container && w.decoration is BoxDecoration),
            description: 'box-decorated',
          )
          .evaluate();
      final colours = <Color>[];
      for (final element in painted) {
        final decoration = element.widget is DecoratedBox
            ? (element.widget as DecoratedBox).decoration as BoxDecoration
            : (element.widget as Container).decoration! as BoxDecoration;
        final border = decoration.border;
        if (border is! Border) {
          continue;
        }
        final colour = border.top.color;
        if (colour.a > 0 &&
            (colour == tokens.line || colour == tokens.danger)) {
          colours.add(colour);
        }
      }
      return colours;
    }

    expect(
      fieldBorders(const ValueKey('p03_email')),
      isNot(contains(tokens.danger)),
      reason: 'a clean field must not be marked invalid',
    );

    bloc.add(const AuthSubmitted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(_emailError), findsOneWidget);

    expect(
      fieldBorders(const ValueKey('p03_email')),
      contains(tokens.danger),
      reason:
          'the design marks the invalid input itself '
          '(`input[aria-invalid="true"] { border-color: var(--danger) }`, '
          'components.css:135; SPACING_SPEC §3). The field is handed '
          'errorText: null so the message can own the gutter, which also '
          'leaves the resting `line` border on an invalid field',
    );

    await disposeApp(tester);
    // skip: P03-BUG-16 (MINOR, open — Decision A, review iteration 5).
    // The shared `NestTextField` now offers the gutter row + forced danger
    // border via `errorText` (`7eaa1f7`), so the layout half is unblocked;
    // but its row is a plain Text with no live region (§8), so switching
    // would trade this defect for BUG-20 (lost announcement). Keep the
    // screen-owned live-region rows; un-skip when SHARED_REQUEST §8 lands
    // and both fields can pass `errorText` with the owned rows deleted. Do
    // not pass `errorText` while keeping the owned rows (duplicate message).
  }, skip: true);

  // -------------------------------------------------------------------
  // P03-BUG-21 (MAJOR, regression) — the BUG-20 fix wrapped the owned error
  // row in `ExcludeSemantics` inside `Semantics(liveRegion: true)`, so the
  // live region announces an empty node: the validation message is neither
  // announced nor present in the semantics tree for a screen reader.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-21 the validation errors are reachable by a screen '
      'reader', (tester) async {
    await _pumpCreateAccount(tester);
    final handle = tester.ensureSemantics();
    BlocProvider.of<AuthBloc>(tester.element(find.byType(CreateAccountView)))
        .add(const AuthSubmitted());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (final message in const <String>[_emailError, _passwordError]) {
      expect(
        find.bySemanticsLabel(message),
        findsOneWidget,
        reason:
            'the error row wraps its Text in ExcludeSemantics, so the '
            'live-region node it leaves behind has an empty label and the '
            'message cannot be read or announced',
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel(message).first)
          .getSemanticsData();
      expect(
        data.flagsCollection.isLiveRegion,
        isTrue,
        reason: 'and the node that carries it must be the live region',
      );
    }

    handle.dispose();
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-22 (MINOR, latent) — the overhang fallback fires even when the
  // submit button already owns the tap, so a point in their overlap is
  // delivered to both. The device geometry always has that overlap (Terms
  // ends caption line 1; its 44dp box overhangs ~12dp into the button), but
  // the harness font is ~2x wider than Inter, so its caption pushes Terms to
  // line 2 — scale 0.7 restores the device's line distribution for this
  // proof. The app clamps the scaler at >= 1.0, so this is a harness
  // synthesis of the device geometry, not a reachable UI state.
  // -------------------------------------------------------------------
  testWidgets(
    'P03-BUG-22 a tap owned by the submit button does not also hit a legal '
    'target',
    (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.platformDispatcher.textScaleFactorTestValue = 0.7;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final bloc = AuthBloc(repository: _SilentAuthRepository());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const CreateAccountView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final button = tester.getRect(find.byKey(const ValueKey('p03_submit')));
      final terms = tester.getRect(find.byKey(const ValueKey('p03_terms')));
      final overlap = button.intersect(terms);
      expect(
        overlap.height,
        greaterThan(1),
        reason: 'geometry precondition: the target overhangs into the button',
      );

      final point = Offset(overlap.center.dx, overlap.center.dy);
      final path = tester.hitTestOnBinding(point).path;
      final targetRender = tester.renderObject(
        find.byKey(const ValueKey('p03_terms')),
      );
      expect(
        path.any((entry) => entry.target == targetRender),
        isFalse,
        reason:
            'the submit button owns this point; the overhang fallback must '
            'run only when the normal path hit nothing (`if (!hit && …)`), or '
            'the link double-activates with the button once the routes land',
      );

      await disposeApp(tester);
      // skip: P03-BUG-22 (MINOR, latent) — no `!hit` gate on the overhang
      // fallback; a button-strip tap reaches the link too.
    },
    skip: true,
  );
}
