import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';
import 'package:nestling/features/auth/presentation/widgets/apple_glyph.dart';
import 'package:nestling/features/auth/presentation/widgets/google_glyph.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/privacy_consent/privacy_consent_routes.dart';

/// P03 Create account — parent-mode form at `/create-account`.
///
/// Static form (no data dependency): the headline, brand buttons, fields,
/// note and bottom CTA render identically whatever the [AuthBloc] status is.
/// The route-level `BlocProvider` in `auth_routes.dart` owns the bloc and its
/// `watchItems()` subscription; `items` are never displayed.
class CreateAccountView extends StatefulWidget {
  const new({super.key});

  @override
  State<CreateAccountView> createState() => _CreateAccountViewState();
}

class _CreateAccountViewState extends State<CreateAccountView> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  /// Headline width cap (P03-BUG-7, ORCHESTRATOR_NOTES §2): with the app's
  /// Nunito 900, "Create your" is 158.6dp and "Create your family" is
  /// 251.2dp, so any cap in [198, 252) breaks the design's
  /// "Create your / family account" (no hard newline) and still wraps
  /// sensibly at 320dp and text scale 1.3.
  static const double _headlineMaxWidth = 240;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(OnboardingRoutePaths.valueTour);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.submitted != current.submitted && current.submitted,
      listener: (context, _) {
        context.read<AuthBloc>().add(const AuthSubmitConsumed());
        context.go(PrivacyConsentRoutePaths.privacy);
      },
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (previous, current) =>
            previous.formError != current.formError &&
            current.formError != null,
        listener: (context, state) async {
          await SemanticsService.sendAnnouncement(
            View.of(context),
            state.formError!,
            TextDirection.ltr,
          );
        },
        child: Scaffold(
          backgroundColor: tokens.paper,
          body: Column(
            children: <Widget>[
              const NestStatusBar(),
              NestNavBar(compact: true, onBack: () => _onBack(context)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    NestSpacing.padSide,
                    0,
                    NestSpacing.padSide,
                    NestSpacing.s8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Semantics(
                        header: true,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _headlineMaxWidth,
                          ),
                          child: Text(
                            'Create your family account',
                            style: NestType.h1(color: tokens.ink),
                            maxLines: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: NestSpacing.s2),
                      Text(
                        "You're the grown-up in charge. "
                        'Children never need an email.',
                        style: NestType.body(color: tokens.ink2),
                      ),
                      const SizedBox(height: NestSpacing.s6),
                      BlocSelector<AuthBloc, AuthState, bool>(
                        selector: (state) => state.isSubmitting,
                        builder: (context, isSubmitting) {
                          return NestAppleButton(
                            key: const ValueKey('p03_apple'),
                            label: 'Continue with Apple',
                            leading: const ExcludeSemantics(
                              child: AppleGlyph(),
                            ),
                            loading: isSubmitting,
                            onPressed: isSubmitting
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    const AuthSocialSubmitted(
                                      AuthProvider.apple,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s3),
                      BlocSelector<AuthBloc, AuthState, bool>(
                        selector: (state) => state.isSubmitting,
                        builder: (context, isSubmitting) {
                          return NestGoogleButton(
                            key: const ValueKey('p03_google'),
                            label: 'Continue with Google',
                            leading: const ExcludeSemantics(
                              child: GoogleGlyph(),
                            ),
                            loading: isSubmitting,
                            onPressed: isSubmitting
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    const AuthSocialSubmitted(
                                      AuthProvider.google,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s4),
                      const _OrRow(),
                      const SizedBox(height: NestSpacing.s4),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.emailError != current.emailError,
                        builder: (context, state) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              NestTextField(
                                key: const ValueKey('p03_email'),
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onChanged: (value) => context
                                    .read<AuthBloc>()
                                    .add(AuthEmailChanged(value)),
                                // P03-BUG-11: no errorText — Material indents
                                // it 20dp inside the field; the error lives
                                // in the owned row below, on the gutter.
                              ),
                              if (state.emailError != null) ...[
                                const SizedBox(height: NestSpacing.gap6),
                                Text(
                                  state.emailError!,
                                  style: NestType.caption(color: tokens.danger)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s4),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (previous, current) =>
                            previous.passwordError != current.passwordError ||
                            previous.formError != current.formError,
                        builder: (context, state) {
                          final errorText =
                              state.passwordError ?? state.formError;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              NestTextField(
                                key: const ValueKey('p03_password'),
                                label: 'Password',
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onChanged: (value) => context
                                    .read<AuthBloc>()
                                    .add(AuthPasswordChanged(value)),
                                // P03-BUG-11: no errorText — Material indents
                                // it 20dp inside the field; the error lives
                                // in the owned row below, on the gutter like
                                // the helper it replaces.
                              ),
                              // P03-BUG-8: the helper is a feature-owned row
                              // on the field gutter (6dp below the input),
                              // not the indented InputDecoration line.
                              // Hidden while an error shows in its place.
                              if (errorText == null) ...[
                                const SizedBox(height: NestSpacing.gap6),
                                Text(
                                  'At least 8 characters',
                                  style: NestType.caption(color: tokens.ink2),
                                ),
                              ] else ...[
                                const SizedBox(height: NestSpacing.gap6),
                                Text(
                                  errorText,
                                  style: NestType.caption(color: tokens.danger)
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: NestSpacing.s3),
                      Row(
                        spacing: NestSpacing.s2,
                        children: <Widget>[
                          ExcludeSemantics(
                            child: NestIcon(
                              NestIcons.shieldCheck,
                              size: 20,
                              color: tokens.lilac,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'No child emails or photos — ever.',
                              style: NestType.bodySmallStrong(
                                color: tokens.ink2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  return NestBottomCta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        NestButton(
                          key: const ValueKey('p03_submit'),
                          label: 'Create account',
                          loading: state.isSubmitting,
                          onPressed: state.canSubmit
                              ? () => context.read<AuthBloc>().add(
                                  const AuthSubmitted(),
                                )
                              : null,
                        ),
                        const SizedBox(height: NestSpacing.s2),
                        const _LegalLine(),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divider or divider (HTML `.or-row`, `aria-hidden`).
class _OrRow extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          Expanded(child: Divider(height: 1, thickness: 1, color: tokens.line)),
          const SizedBox(width: NestSpacing.s3),
          Text(
            'or',
            style: NestType.caption(color: tokens.ink2)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(child: Divider(height: 1, thickness: 1, color: tokens.line)),
        ],
      ),
    );
  }
}

/// Legal caption (P03-BUG-1/4/9/10/12/13).
///
/// The caption lays out as plain centred text lines at the design's 20dp
/// link-line height (`.link { line-height: 20px }`), so the line breaker
/// flows the words exactly like the design. The two-word label uses U+00A0
/// so it can never split across lines (ORCHESTRATOR_NOTES §5, COPY rule).
/// Each link's 44dp target is an overlay box measured off the laid-out text
/// (post-frame) and centred over its word — the HTML
/// `.link { min-height:44px; margin:-12px 0 }` trick, where the hit box
/// overlaps its line instead of adding layout height. The links are inert in
/// v1 (`TODO(P03)`). Never use `NestBottomCta.caption` here — it cannot
/// render links.
class _LegalLine extends StatefulWidget {
  const new();

  /// Two-word link label joined by U+00A0 NO-BREAK SPACE (COPY rule) so the
  /// line breaker can never split it (P03-BUG-9).
  static const String privacyLabel = 'Privacy Notice';

  @override
  State<_LegalLine> createState() => _LegalLineState();
}

class _LegalLineState extends State<_LegalLine> {
  final GlobalKey _paragraphKey = GlobalKey();

  /// Stack-local boxes of the two link words, measured post-frame.
  Rect? _termsRect;
  Rect? _privacyRect;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The caption's metrics move with these; re-measure after the frame.
    MediaQuery.sizeOf(context);
    MediaQuery.textScalerOf(context);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final renderObject = _paragraphKey.currentContext?.findRenderObject();
    if (renderObject is! RenderParagraph) return;
    final paragraph = renderObject;
    Rect? boxFor(String label) {
      final plain = paragraph.text.toPlainText();
      final start = plain.indexOf(label);
      if (start < 0) return null;
      Rect? box;
      for (final textBox in paragraph.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + label.length),
      )) {
        final rect = textBox.toRect();
        box = box == null ? rect : box.expandToInclude(rect);
      }
      if (box == null) return null;
      // Boxes are paragraph-local; the overlay lives in the Stack, which
      // sizes exactly to the paragraph.
      final origin = paragraph.localToGlobal(Offset.zero);
      final stack = context.findRenderObject();
      final stackOrigin = stack is RenderBox
          ? stack.localToGlobal(Offset.zero)
          : origin;
      return box.shift(origin - stackOrigin);
    }

    final terms = boxFor('Terms');
    final privacy = boxFor(_LegalLine.privacyLabel);
    if (terms != _termsRect || privacy != _privacyRect) {
      setState(() {
        _termsRect = terms;
        _privacyRect = privacy;
      });
    }
  }

  /// A 44dp target centred over its word (P03-BUG-10/13).
  static Rect _targetRect(Rect label) => Rect.fromCenter(
    center: label.center,
    width: math.max(label.width, NestDevice.tapParent),
    height: NestDevice.tapParent,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // P03-BUG-12: the design's link lines are 20dp, not the 18dp caption
    // default — every caption line holds a link, so the block is 40dp.
    final base = NestType.caption(color: tokens.ink2).copyWith(height: 20 / 13);
    final link = NestType.caption(color: tokens.sky).copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: tokens.sky,
      height: 20 / 13,
    );
    return Semantics(
      label:
          'By continuing you agree to our Terms and ${_LegalLine.privacyLabel}',
      explicitChildNodes: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          ExcludeSemantics(
            child: Text.rich(
              key: _paragraphKey,
              TextSpan(
                children: <TextSpan>[
                  const TextSpan(text: 'By continuing you agree to our '),
                  TextSpan(text: 'Terms', style: link),
                  const TextSpan(text: ' and '),
                  TextSpan(text: _LegalLine.privacyLabel, style: link),
                ],
              ),
              style: base,
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
          if (_termsRect != null)
            Positioned.fromRect(
              rect: _targetRect(_termsRect!),
              child: const _LegalTarget(
                key: ValueKey('p03_terms'),
                label: 'Terms',
              ),
            ),
          if (_privacyRect != null)
            Positioned.fromRect(
              rect: _targetRect(_privacyRect!),
              child: const _LegalTarget(
                key: ValueKey('p03_privacy'),
                label: _LegalLine.privacyLabel,
              ),
            ),
        ],
      ),
    );
  }
}

/// One inert legal-link target (P03-BUG-1/4/10/13).
///
/// Carries the `p03_*` key and the exact single-node button semantics. The
/// `Positioned.fromRect` parent gives it tight ≥44×44 constraints, so it
/// fills its measured box over its word.
class _LegalTarget extends StatelessWidget {
  const new({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // TODO(P03): inert — no Terms/Notice routes exist in v1.
        onTap: () {},
        child: const SizedBox.expand(),
      ),
    );
  }
}
