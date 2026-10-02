// P03 Create account — adversarial bug proofs (Stage 6, iteration 1).
//
// Open bugs found this iteration. Every failing proof is SKIPPED with its bug
// id so `flutter test` stays green; the fix iteration must un-skip each one
// (change `skip: true` to `skip: false` / delete it) and make it pass. Full
// reports (severity, repro, suggested fix) live in
// `docs/screens/P03/6_bugs.md`.
//
//   flutter test test/features/auth/p03_bugs_test.dart
//
// P03-BUG-1 (MAJOR)  the legal caption lays out one 44dp hit target per row
//                    (`Wrap` children with `ConstrainedBox(minHeight: 44)`),
//                    so the caption is 80dp instead of the design's ~38dp
//                    and the bottom CTA panel is 172dp instead of 167dp
//                    (measured in the widget-test harness; on the device the
//                    panel is 214dp vs 167dp — see the report). The reclaimed
//                    height must come from overlapping hit areas (the HTML
//                    `.link { min-height:44px; margin:-12px 0 }` trick), not
//                    from layout height.
// P03-BUG-2 (MAJOR)  a validation error appears on the FIRST keystroke and
//                    when the field is cleared: `AuthBloc` sets `emailError` /
//                    `passwordError` on every change. Errors must be gated on
//                    blur/submit (or on a previously-shown error), never on
//                    first paint. NB: `create_account_view_test.dart`'s
//                    "bad input errors and disables submit" pins the current
//                    behaviour and must be updated with the fix.
// P03-BUG-3 (MINOR, shared)  FIXED mid-iteration by the shared onboarding
//                    header fix (merge 2027506): the compact `NestNavBar` is
//                    now the design's 60dp. The proof below stays green as a
//                    regression guard; SHARED_REQUEST item 3 is resolved.
// P03-BUG-4 (MINOR)  the two legal links announce their label twice
//                    ("Terms\nTerms") because the explicit `Semantics(label:)`
//                    merges with the inner `Text`.
// P03-BUG-5 (MINOR)  a repository failure that is not an `Exception` (an
//                    `Error`, e.g. `StateError`) escapes `on Exception`, so
//                    `isSubmitting` stays true: all three buttons spin and no
//                    error is ever shown.
// P03-BUG-6 (MINOR, shared)  `NestButton` merges its explicit label with the
//                    inner Text, so the main CTA announces "Create
//                    account\nCreate account". Core file — SHARED_REQUEST
//                    item 4.
// P03-BUG-7 (MINOR)  the headline fills the 350dp content width and breaks
//                    "Create your family / account" instead of the design's
//                    "Create your / family account" (ORCHESTRATOR_NOTES §2:
//                    constrain the title width from the HTML, no hard
//                    newline). Real-font widths: "Create your family" 251.2,
//                    "family account" 197.7 → cap below 252 (e.g. 240).
// P03-BUG-8 (MINOR)  the password helper "At least 8 characters" is indented
//                    20dp (left 40) instead of sitting on the 20dp gutter
//                    (ORCHESTRATOR_NOTES §4; design `.field` is a column).
//                    Rendered by the shared `NestTextField`'s InputDecoration
//                    — fix locally (own helper row) or via SHARED_REQUEST.
//
// Checked and clean this iteration (no proof needed): kid-mode deep link →
// `/parental-gate`; restart persistence (one owner row, `james`); back to
// `/value-tour` with no history; 320/390/430 × 1.0/1.3 matrix; dark-mode
// contrast (all text pairs ≥ 4.5:1); money/timezone edge cases N/A (no money
// or dates on this screen); 0/1/6 children N/A (the form is static and never
// renders the members list). The test harness' fallback font is far wider
// than Nunito/Inter, so headline line-count measurements taken with it are
// NOT product bugs — the real fonts were used to verify `maxLines: 3` fits
// at scale 1.3.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/domain/auth_provider.dart';
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
            'adding 44dp of layout height per row; today the caption is 80dp',
      );

      await disposeApp(tester);
    },
    // skip: P03-BUG-1 (MAJOR, open) — caption is 80dp: one 44dp link box
    // per row.
    skip: true,
  );

  testWidgets(
    'P03-BUG-1b the CTA panel keeps the design height (no 2× caption)',
    (tester) async {
      await _pumpCreateAccount(tester);

      // Design: 16 + 52 + 8 + 2×18 + 16 ≈ 146dp of content in the harness
      // (the design's extra home-indicator inset is not modelled here; the
      // device evidence in 6_bugs.md measures 214dp vs the design's 167dp).
      expect(
        tester.getSize(find.byType(NestBottomCta)).height,
        lessThanOrEqualTo(150),
        reason: 'the bottom bar must not eat the form above it',
      );

      await disposeApp(tester);
    },
    // skip: P03-BUG-1 (MAJOR, open) — CTA panel is 172dp vs the design's
    // 167dp (214dp on device).
    skip: true,
  );

  testWidgets(
    'P03-BUG-1c the CTA panel keeps its height at text scale 1.3',
    (tester) async {
      await _pumpCreateAccount(tester, textScale: 1.3);

      // 16 + 52 + 8 + 3×18×1.3 + 16 ≈ 162dp. Today it is 232dp.
      expect(
        tester.getSize(find.byType(NestBottomCta)).height,
        lessThanOrEqualTo(170),
        reason: 'the caption must not double at larger text scales',
      );

      await disposeApp(tester);
    },
    // skip: P03-BUG-1 (MAJOR, open) — CTA panel is 232dp at scale 1.3.
    skip: true,
  );

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
            'today it is 140dp',
      );

      await disposeApp(tester);
    },
    // skip: P03-BUG-1 (MAJOR, open) — caption is 140dp at 320dp × 1.3.
    skip: true,
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
    // skip: P03-BUG-2 (MAJOR, open) — first keystroke shows the email error.
  }, skip: true);

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
    // skip: P03-BUG-2 (MAJOR, open) — clearing the field shows the error.
  }, skip: true);

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
    // skip: P03-BUG-2 (MAJOR, open) — first keystroke shows the password
    // error.
  }, skip: true);

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
    // skip: P03-BUG-4 (MINOR, open) — Terms/Privacy links announce
    // "Terms\nTerms" (explicit Semantics label + inner Text merge).
  }, skip: true);

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
        reason: 'today isSubmitting stays true and every button spins forever',
      );
      expect(bloc.state.formError, isNotNull);

      await bloc.close();
    },
    // skip: P03-BUG-5 (MINOR, open) — on Exception misses Errors:
    // isSubmitting stays true, formError null.
    skip:
        'P03-BUG-5 (MINOR, open): a non-Exception repository failure '
        'leaves isSubmitting true and no formError',
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
      // skip: P03-BUG-7 (MINOR, open) — title fills 350dp and breaks
      // "Create your family / account" (ORCHESTRATOR_NOTES §2).
    },
    skip: true,
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
          'padding), measured 40 vs 20',
    );

    await disposeApp(tester);
    // skip: P03-BUG-8 (MINOR, open) — helper left 40 vs field left 20.
  }, skip: true);
}
