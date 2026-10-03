// P03 Create account — adversarial bug proofs.
//
// Iterations 2–5 closed every bug reported by iterations 1–4; those proofs
// run green as regression guards (including P03-BUG-6 and P03-BUG-21, fixed
// by the shared batch `7eaa1f7` and the iteration-5 build respectively).
// Iteration 6 closed the last two (P03-BUG-16 via the landed §8 shared
// live-region error row, P03-BUG-22 via the gesture-entry gate in
// `_RenderHitTestExpand.hitTest`); their proofs are green regression
// guards too. Full reports live in `docs/screens/P03/6_bugs.md`.
//
//   flutter test test/features/auth/p03_bugs_test.dart
//
// P03-BUG-1..15  iterations 1–4's bugs — all fixed; regression guards.
// P03-BUG-16 (MINOR, fixed iteration 6)  an invalid input showed no danger
//                border. `SHARED_REQUEST.md` §8 has now landed on main
//                (the shared field's gutter row is a labelled live
//                region), so P03 passes `errorText` to both fields and
//                shows both the border and the owner rows' announcement;
//                the screen-owned rows are deleted.
// P03-BUG-17 (MINOR, shared §6 — resolved shared-side)  the served Inter
//                build was ~3–4% wider than the design's, so the subtitle
//                broke after "Children" instead of "Children never". The
//                shared batch that bundled the designs' own Inter/Nunito
//                builds fixed it with no local change. Iteration 6 closed
//                the "no local proof is possible" gap too: the bundled
//                builds load into a widget test with a `FontLoader`, so
//                `typography_test.dart` now pins the design's actual wrap
//                ("…Children never" / "need an email.") and its 349.06 dp
//                advance with the design's own metrics, while
//                `body_text_width_test.dart` keeps pinning it shared-side.
// P03-BUG-23 (MINOR, fixed iteration 7)  the "or" row painted an 18 dp
//                `NestType.caption` line box where the design's `.or-label`
//                sets no line-height (13 px/normal ≈15.7 dp), so the email
//                label, both fields, the helper and the note row sat 2 dp
//                below the design and the CTA panel 1 dp. Fixed by styling
//                the label with the design's own line box
//                (`_orLabelLineBox = 15.7`, token-derived); both proofs
//                green.
// P03-BUG-24 (MAJOR, mandatory rule — OPEN)  the headline still renders with
//                a hand-calibrated `ConstrainedBox(maxWidth: 240)` + `Text`
//                instead of `NestBalancedText`. The design's `.h1` sets
//                `text-wrap: balance` (components.css:29) and the standing
//                BALANCED HEADINGS rule requires the component for `.h1`
//                (copy, style, maxLines kept); the cap is exactly the
//                hand-tuned pattern the rule replaces and drifts silently
//                when a type token changes. Migration must keep the design's
//                LEFT alignment (pass `textAlign: TextAlign.left`), not the
//                component's centred default, and must KEEP the 240 dp cap:
//                inside it the break is already the narrowest two-line break
//                (197.7 dp), so the component is a no-op there, while
//                dropping the cap would move the 390 dp break to "Create
//                your family" / "account". Measured at text scale 1.3 the cap
//                renders three lines ("Create your" / "family" / "account");
//                balance cannot fix that, since it only ever narrows.
// P03-BUG-18..21  all fixed (overhang reachability, first-frame/stale
//                measurement, live regions, the empty-live-region
//                regression).
// P03-BUG-22 (MINOR, latent — fixed iteration 6)  the overhang fallback
//                in `_RenderHitTestExpand` fired even when an interactive
//                control owned the tap, so a point in the button/link
//                overlap hit both. Fix: suppress the fallback whenever the
//                normal path's entries include a gesture target
//                (`RenderPointerListener`/`RenderSemanticsGestureHandler`);
//                an empty/decorated-only bar area still reaches the
//                overhanging link boxes (P03-BUG-18 stays green).
//
// Checked and clean in iteration 6 (no new proof needed): the compact nav
// 60dp band; back → `/value-tour` and pop-when-stacked; Apple → `/privacy`,
// Google → `/privacy`, social failure stays put; loading blocks every
// control and stops on completion; repository `Error` (not `Exception`)
// surfaces; a double tap creates one account; restart persistence (one owner
// row); the 320/390/430 × 1.0/1.3 matrix incl. five consecutive resizes, a
// live text-scale change and a theme switch; dark-mode contrast; all nine
// strings byte-identical to the HTML (U+2019, U+2014, one U+00A0) with the
// target/paragraph equality proofs green; the two legal targets' lateral
// overlap is design-faithful; the BOTTOM EDGE owner rule now as painted
// pixels (`create_account_view_test.dart`, both themes); P03-BUG-16 now proves
// the danger border in the raster, not only in the decoration; money /
// timezone / children-order cases N/A for this screen.
//
// The harness' fallback font is still not Inter, so line breaks measured in
// this file are not product geometry — `typography_test.dart` loads the
// bundled design builds and pins the real ones.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
import 'pixel_probe.dart';

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
  // P03-BUG-16 (MINOR, fixed iteration 6) — an invalid field painted no
  //   danger border: P03 handed the field `errorText: null` so it could
  //   own the gutter row itself. SHARED_REQUEST §8 has now landed on
  //   main — the shared field's gutter error row IS a live region — so
  //   P03 passes `errorText` to both fields and the decoded error text
  //   is announced with the border in one shared component (the owned
  //   rows and their `buildWhen` selectors are deleted).
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-16 an invalid field paints the danger border', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);
    final bloc = BlocProvider.of<AuthBloc>(
      tester.element(find.byType(CreateAccountView)),
    );
    final tokens = tester.element(find.byType(NestBottomCta)).nest;

    /// The colours of the outlines the keyed field paints. The shared
    /// field paints its border from the `InputDecoration` it hands to the
    /// `TextField` (`border`/`enabledBorder`/`focusedBorder`/`errorBorder`/
    /// `focusedErrorBorder`), so reading those four is reading what is
    /// painted on the box.
    List<Color> fieldBorders(ValueKey<String> key) {
      final field = tester.widget<TextField>(
        find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      );
      final decoration = field.decoration!;
      Color? colourOf(InputBorder? border) {
        if (border is OutlineInputBorder) return border.borderSide.color;
        return null;
      }

      return <Color>[
        ?colourOf(decoration.border),
        ?colourOf(decoration.enabledBorder),
        ?colourOf(decoration.focusedBorder),
      ];
    }

    expect(
      fieldBorders(const ValueKey('p03_email')),
      isNot(contains(tokens.danger)),
      reason: 'a clean field must not be marked invalid',
    );

    /// The painted outline across the middle of the keyed field's top edge.
    ///
    /// The decoration read above is the input to the painter; this is its
    /// output, so it also catches a border the painter declines to honour.
    /// Two rows, because the design-system error state is 2 dp wide.
    Future<List<String>> paintedTopEdge(ValueKey<String> key) {
      final input = tester.getRect(
        find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
      );
      return paintedColumn(
        tester,
        input.left + input.width / 2,
        input.top,
        input.top + 1,
      );
    }

    expect(
      (await paintedTopEdge(const ValueKey('p03_email'))).map(hexOfRow),
      <String>[hexOf(tokens.line), hexOf(tokens.surface)],
      reason:
          'a valid field wears the 1 dp line border over the surface fill '
          '(nest_text_field.dart `enabledBorder`)',
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
          'components.css:135; SPACING_SPEC §3). P03 hands the field '
          '`errorText`, and the shared field paints the danger border '
          'itself (nest_text_field.dart) alongside its gutter error row',
    );

    expect(
      (await paintedTopEdge(const ValueKey('p03_email'))).map(hexOfRow),
      <String>[hexOf(tokens.danger), hexOf(tokens.danger)],
      reason:
          'and that border has to be what the raster ends up painting, '
          'not only what the decoration says. Sampled with the raster '
          'settled: reading too early still shows the clean border, which '
          'looks exactly like a live bug and is not one',
    );

    await disposeApp(tester);
    // skip removed in iteration 6: SHARED_REQUEST §8 landed on main (the
    // shared row now announces via `Semantics(liveRegion: true, label: …)`),
    // so P03 passes `errorText` to both fields and its owned rows are
    // deleted. The danger border and the announcement now arrive together.
  });

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
  // P03-BUG-22 (MINOR, latent — fixed iteration 6) — the overhang
  // fallback fired even when an interactive control already owned the
  // tap, so a point in the submit/link overlap hit both. The normal
  // path's entries are now checked for a gesture target
  // (`RenderPointerListener`/`RenderSemanticsGestureHandler`); when the
  // bar background's DecoratedBox is the only hit, the overhanging link
  // boxes are still reachable (P03-BUG-18).
  //
  // The device geometry always has that overlap (Terms ends caption line
  // 1; its 44dp box overhangs ~12dp into the button), but the harness
  // font is ~2x wider than Inter, so its caption pushes Terms to line
  // 2 — scale 0.7 restores the device's line distribution for this
  // proof. The app clamps the scaler at >= 1.0, so this is a harness
  // synthesis of the device geometry, not a reachable UI state.
  // -------------------------------------------------------------------
  testWidgets(
    'P03-BUG-22 a tap owned by the submit button does not also hit a legal '
    'target',
    (tester) async {
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
            'the submit button owns this point, so the overhang fallback must '
            'not also collect the link box, or it double-activates with the '
            'button once the routes land. (`hit` cannot be the gate: the '
            "bar's DecoratedBox claims every in-panel point — see "
            '6_bugs.md, "The `!hit` question is settled")',
      );

      await disposeApp(tester);
      // skip removed in iteration 6: `_HitTestExpand.hitTest` now suppresses
      // the overhang fallback whenever the normal path already landed on a
      // gesture target, so a button-strip tap no longer reaches the link
      // while an empty-bar overhang tap still does (P03-BUG-18).
    },
  );

  // -------------------------------------------------------------------
  // P03-BUG-23 (MINOR, fixed iteration 7) — the form block sat 2 dp below
  // the design.
  //
  //   Repro: `docs/screens/P03/ui/filled-light.png` against
  //   `design/screens/light/P03-create-account.png` — the design PNG is the
  //   FILLED state, so that capture is the only apples-to-apples frame
  //   (docs/screens/P03/filled_shot.sh). compare.py: mean 2.08% light,
  //   2.05% dark.
  //
  //   Measured tops (design → app): "or" row 392.67 → 393.67 (+1), Email
  //   label 423.00 → 425.00 (+2), email field 443.00 → 445.00 (+2),
  //   password label 515.33 → 517.33 (+2), password field 535.00 → 537.00
  //   (+2), helper 597.33 → 599.33 (+2), note row 625.67 → 627.67 (+2),
  //   CTA panel 677.00 → 678.00 (+1). Everything above the "or" row is
  //   pixel-exact (headline 112.67/146.00, subtitle 188.67/212.67, Apple
  //   255.00..307.00, Google 319.00..371.00).
  //
  //   Cause: `_OrRow` (create_account_view.dart:280) styles its label with
  //   `NestType.caption`, whose line box is `--lh-caption` = 18 dp. The
  //   design's `.or-label` sets `font-size: 13px; font-weight: 600` and NO
  //   line-height (P03-create-account.html:27), so its row is 13 px ×
  //   Inter's normal line height ≈ 15.7 dp. The 2.3 dp lands on every
  //   element below the row, and the ALIGNMENT rule treats visible
  //   misalignment as a UI failure.
  //
  //   The proof is font-independent on purpose: `NestType.caption` sets its
  //   height explicitly, so the row is 18 dp whatever family the harness
  //   resolves, and the design's arithmetic (16 + 15.7 + 16 + 24 = 71.7) can
  //   be asserted directly. With the design's own fonts the same offset is
  //   pinned against the design PNG's absolute bands in
  //   `typography_test.dart`.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-23 the form block starts at the design band', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    final google = tester.getRect(
      find.byKey(const ValueKey('p03_google')).first,
    );
    final orLabel = tester.getRect(find.text('or'));
    final email = tester.getRect(
      find.descendant(
        of: find.byKey(const ValueKey('p03_email')),
        matching: find.byType(TextField),
      ),
    );

    // The design's `.or-row` is as tall as its label's line box: 13 px at
    // Inter's normal line height (≈15.7), not the caption token's 18.
    expect(
      orLabel.height,
      lessThan(17),
      reason:
          "the design's `.or-label` sets no line-height, so its row is 13 px "
          '× normal ≈ 15.7 dp; `NestType.caption` paints an 18 dp line box '
          'and adds 2.3 dp to everything below it',
    );

    // Google button bottom → email field top, in the design:
    // `.scroll > .or-row { margin-top: 16 }` + the or-row (15.7) +
    // `.scroll > .field { margin-top: 16 }` + label 18 + label gap 6.
    expect(
      email.top - google.bottom,
      closeTo(71.7, 1),
      reason:
          'the design measures 443.00 − 371.00 = 72 dp from the Google '
          'button to the email field; with an 18 dp or-row it is 74',
    );

    await disposeApp(tester);
  });

  // -------------------------------------------------------------------
  // P03-BUG-24 (MAJOR, mandatory BALANCED HEADINGS rule — OPEN) — the
  // design's `.h1` sets `text-wrap: balance` (components.css:29) and the
  // HTML is `<h1 class="h1">` (P03-create-account.html:36), so the
  // headline must render with `NestBalancedText` (same copy, style and
  // maxLines); the hand-calibrated `_headlineMaxWidth = 240` cap
  // (create_account_view.dart:39) is the pattern the rule replaces.
  //
  // Nothing changes on screen at 390 — the cap already reproduces the
  // design's "Create your" / "family account" — so this is a rule
  // violation, not a pixel defect. Two things the swap must respect, both
  // measured in `typography_test.dart` with the design's fonts:
  //
  //   * `textAlign: TextAlign.left`. The component centres its narrowed box
  //     by default; the design left-aligns both headline lines on the 20 dp
  //     gutter.
  //   * keep the 240 dp cap. Inside it the break is already the narrowest
  //     two-line break (197.7 dp), so `NestBalancedText` narrows to 197.68
  //     and neither the break nor the ink moves. Dropping the cap would
  //     break the design: at 350 dp the balanced break is "Create your
  //     family" / "account".
  //
  // One shared caveat, measured in `typography_test.dart` and filed as
  // SHARED_REQUEST §10: with `maxLines: 3` the component's binary search
  // runs through a clamped painter, so at text scale 1.3 (where the text
  // needs 4 lines) it converges to a 0.1 dp box and renders one glyph per
  // line. `maxLines: 3` is what this proof requires, so the shared fix has
  // to land first — or the migration drops `maxLines`.
  //
  // Left red on purpose (Stage 3 un-skipped it: a skipped proof is not
  // evidence). The fix is the screen's.
  // -------------------------------------------------------------------
  testWidgets('P03-BUG-24 the headline is rendered with NestBalancedText', (
    tester,
  ) async {
    await _pumpCreateAccount(tester);

    final balanced = find.byType(NestBalancedText);
    expect(
      balanced,
      findsOneWidget,
      reason:
          'the design h1 uses `text-wrap: balance`; the BALANCED HEADINGS '
          'rule requires NestBalancedText instead of the hand-calibrated '
          '`_headlineMaxWidth = 240` cap',
    );
    final headline = tester.widget<NestBalancedText>(balanced);
    expect(headline.text, 'Create your family account');
    expect(headline.maxLines, 3);
    expect(
      headline.textAlign,
      TextAlign.left,
      reason:
          'the design headline is left-aligned on the 20dp gutter (ink x=20 '
          'on both lines); the component default is centre, which would '
          'move the block off the gutter',
    );
    expect(
      tester.getTopLeft(find.text('Create your family account')).dx,
      moreOrLessEquals(20, epsilon: 1),
      reason: 'the painted headline must still start on the 20dp gutter',
    );

    await disposeApp(tester);
  });
}
