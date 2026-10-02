// P03 Create account — adversarial bug proofs.
//
// Iteration 2's build closed every iteration-1 bug except the shared
// `NestButton` doubling (P03-BUG-6); those proofs now run green as regression
// guards. The proofs at the end of this file capture the six bugs still open
// after that fix pass. Every open-bug proof is `skip:`-marked with its id so
// `flutter test` stays green; the fix iteration must un-skip each one and
// make it pass. Full reports (severity, repro, suggested fix) live in
// `docs/screens/P03/6_bugs.md`.
//
//   flutter test test/features/auth/p03_bugs_test.dart
//
// P03-BUG-1..8  iteration-1 bugs. BUG-1/2/3/4/5/7/8 are fixed (proofs green
//               regression guards). BUG-6 stays skipped — shared core
//               (`NestButton` announces its label twice, SHARED_REQUEST §4).
// P03-BUG-9  (MAJOR)  the caption splits the "Privacy Notice" label across
//               two lines — a lone underlined "Notice" on line 2.
//               ORCHESTRATOR_NOTES §5 requires "…Terms and" /
//               "Privacy Notice". The label must be unbreakable.
// P03-BUG-10 (MAJOR)  the 44dp link targets no longer sit over their words:
//               the overlay centres both as one adjacent 88dp block, so the
//               visible links are untappable and plain words are covered.
// P03-BUG-11 (MINOR)  the validation error is indented 20dp inside the field
//               while the label, input and the BUG-8 helper sit on the
//               gutter — the text jumps sideways when an error appears.
// P03-BUG-12 (MINOR)  the caption's link lines are 18dp tall instead of the
//               design's 20dp (`P03-create-account.html:26`
//               `.link { line-height: 20px }`), so the CTA panel is ~4dp
//               short and the hairline sits at 682.7 vs the design's 677.7
//               (UI iteration-2 deviation 2).
// P03-BUG-13 (MINOR)  on a two-line caption the 44dp legal targets render
//               44×36 — the stack is only 36 tall — below DESIGN_SPEC §0.9's
//               44×44 parent minimum. Two-line is the device's normal 390dp
//               geometry; the harness reproduces it at 430dp, where its
//               wider font wraps the caption to two lines.
// P03-BUG-14 (MINOR)  `on Object catch` without `addError(stackTrace)`: the
//               failure surfaces as formError but no observer ever receives
//               the stack trace (the one place a developer wants it).
//
// Checked and clean this iteration (no proof needed): kid-mode deep link →
// `/parental-gate`; restart persistence (one owner row); back/deep links;
// 320/390/430 × 1.0/1.3 matrix; dark-mode contrast; money/timezone edge
// cases N/A (no money or dates on this screen); 0/1/6 children N/A (the form
// is static and never renders the members list); double-taps guarded. The
// test harness' fallback font is far wider than Nunito/Inter, so headline
// line-count measurements taken with it are NOT product bugs — the real
// fonts were used to verify `maxLines: 3` fits at scale 1.3.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// The caption's `RenderParagraph`.
RenderParagraph _captionParagraph(WidgetTester tester) {
  final caption = find.descendant(
    of: find.byType(NestBottomCta),
    matching: find.byType(RichText),
  );
  return tester.renderObject<RenderParagraph>(caption.last);
}

/// The laid-out box of [label] inside the legal caption, read off the
/// caption's own `RenderParagraph` (font-independent: it asks the engine
/// where the glyphs actually went).
Rect _labelBox(WidgetTester tester, String label) {
  final paragraph = _captionParagraph(tester);
  final plain = paragraph.text.toPlainText();
  final start = plain.indexOf(label);
  Rect? box;
  for (final found in paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + label.length),
  )) {
    box = box == null ? found.toRect() : box.expandToInclude(found.toRect());
  }
  return box!;
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
double _linkLineHeight(WidgetTester tester, String label) {
  final box = _labelBox(tester, label);
  final center = (box.top + box.bottom) / 2;
  var y = 0.0;
  for (final metric in _captionLineMetrics(tester)) {
    if (center >= y && center <= y + metric.height) {
      return metric.height;
    }
    y += metric.height;
  }
  return -1;
}

/// The rendered lines of the legal caption, by their vertical position.
Set<double> _captionLineTops(WidgetTester tester) {
  final paragraph = _captionParagraph(tester);
  final plain = paragraph.text.toPlainText();
  return paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: plain.length),
      )
      .map((box) => box.top)
      .toSet();
}

void main() {
  // -------------------------------------------------------------------
  // P03-BUG-1 (MAJOR) — the legal caption is one 44dp link row per line,
  // inflating the CTA panel and eating the form above it.
  //
  // Bounds are calibrated against the widget-test harness font, which is
  // ~1em per glyph and therefore wider than Nunito/Inter: the caption needs
  // 3 lines at 390dp and 4 lines at 320dp × 1.3 in this harness (2 lines on
  // a real device). The design's ~38dp caption is 2×18dp on device; in the
  // harness the equivalent bound is 3×18dp+4 = 58dp. See 6_bugs.md.
  // -------------------------------------------------------------------
  testWidgets(
    'P03-BUG-1a the legal caption is its text lines, not 44dp link rows',
    (tester) async {
      await _pumpCreateAccount(tester);

      expect(
        _captionBlockHeight(tester),
        lessThanOrEqualTo(3 * 18 + 4),
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

      // Design: 16 + 52 + 8 + 2×18 + 16 ≈ 146dp of content in the harness
      // (the design's extra home-indicator inset is not modelled here; the
      // device measurement in iteration 1 was 214dp vs the design's 167dp).
      expect(
        tester.getSize(find.byType(NestBottomCta)).height,
        lessThanOrEqualTo(150),
        reason: 'the bottom bar must not eat the form above it',
      );

      await disposeApp(tester);
    },
  );

  testWidgets('P03-BUG-1c the CTA panel keeps its height at text scale 1.3', (
    tester,
  ) async {
    await _pumpCreateAccount(tester, textScale: 1.3);

    // 16 + 52 + 8 + 3×18×1.3 + 16 ≈ 162dp (iteration 1 measured 232dp).
    expect(
      tester.getSize(find.byType(NestBottomCta)).height,
      lessThanOrEqualTo(170),
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

      // At 320dp the harness font needs four caption lines: 4×18×1.3 ≈ 94dp.
      expect(
        _captionBlockHeight(tester),
        lessThanOrEqualTo(100),
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
      find.bySemanticsLabel('Privacy Notice\nPrivacy Notice'),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Terms'), findsOneWidget);
    expect(find.bySemanticsLabel('Privacy Notice'), findsOneWidget);

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
    // skip: P03-BUG-6 (MINOR, shared) — NestButton label merges with the
    // inner Text (SHARED_REQUEST §4).
  }, skip: true);

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
    final lines = _captionLineTops(tester);
    final onOneLine = lines.where(
      (top) => label.overlaps(Rect.fromLTRB(0, top, 390, top + 1)),
    );
    expect(
      onOneLine.length,
      1,
      reason:
          'a two-word link must not break: ORCHESTRATOR_NOTES §5 puts the '
          'whole label on one line. Today the label spans two caption lines '
          '(device: "…Terms and Privacy" / "Notice")',
    );

    await disposeApp(tester);
    // skip: P03-BUG-9 (MAJOR, open) — "Privacy Notice" splits across two
    // caption lines.
  }, skip: true);

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
        final tops = _captionLineTops(tester);
        expect(
          tops
              .where((t) => box.overlaps(Rect.fromLTRB(0, t, 9999, t + 1)))
              .length,
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
    // skip: P03-BUG-9 (MAJOR, open) — same split at every width/scale.
  }, skip: true);

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
      // skip: P03-BUG-10 (MAJOR, open) — overlay targets are a centred
      // 88dp block, not over their words.
    }, skip: true);
  }

  testWidgets('P03-BUG-10b the two link targets are not one contiguous block', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    final terms = tester.getRect(find.byKey(const ValueKey('p03_terms')));
    final privacy = tester.getRect(find.byKey(const ValueKey('p03_privacy')));
    // The caption always has " and " between the two links, so the targets
    // can never touch.
    expect(
      privacy.left,
      greaterThan(terms.right),
      reason: 'the words " and " sit between the two links',
    );

    await disposeApp(tester);
    // skip: P03-BUG-10 (MAJOR, open) — the targets touch (one 88dp block).
  }, skip: true);

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
    // skip: P03-BUG-11 (MINOR, open) — the error renders at left 40.
  }, skip: true);

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
    // skip: P03-BUG-12 (MINOR, open) — caption link lines are 18dp.
  }, skip: true);

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
    // skip: P03-BUG-13 (MINOR, open) — targets are 44×36 with 2 lines.
  }, skip: true);

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
    skip: 'P03-BUG-14 (MINOR, open): on Object catch drops the stack trace',
  );
}
