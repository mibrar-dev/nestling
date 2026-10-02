import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/domain/auth_provider.dart';
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
              // NOTE(P03): NestNavBar compact with title:null crashes (nested
              // Expanded around a Spacer — see SHARED_REQUEST.md). The design
              // has no bar title, so pass '' (renders an empty centred slot).
              NestNavBar(
                compact: true,
                title: '',
                onBack: () => _onBack(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    NestSpacing.padSide,
                    0,
                    NestSpacing.padSide,
                    NestSpacing.s8,
                  ),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Semantics(
                            header: true,
                            child: Text(
                              'Create your family account',
                              style: NestType.h1(color: tokens.ink),
                              maxLines: 3,
                            ),
                          ),
                          const SizedBox(height: NestSpacing.s2),
                          Text(
                            "You're the grown-up in charge. "
                            'Children never need an email.',
                            style: NestType.body(color: tokens.ink2),
                          ),
                          const SizedBox(height: NestSpacing.s6),
                          NestAppleButton(
                            key: const ValueKey('p03_apple'),
                            label: 'Continue with Apple',
                            leading: const ExcludeSemantics(
                              child: AppleGlyph(),
                            ),
                            loading: state.isSubmitting,
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    const AuthSocialSubmitted(
                                      AuthProvider.apple,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: NestSpacing.s3),
                          NestGoogleButton(
                            key: const ValueKey('p03_google'),
                            label: 'Continue with Google',
                            leading: const ExcludeSemantics(
                              child: GoogleGlyph(),
                            ),
                            loading: state.isSubmitting,
                            onPressed: state.isSubmitting
                                ? null
                                : () => context.read<AuthBloc>().add(
                                    const AuthSocialSubmitted(
                                      AuthProvider.google,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: NestSpacing.s4),
                          const _OrRow(),
                          const SizedBox(height: NestSpacing.s4),
                          NestTextField(
                            key: const ValueKey('p03_email'),
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) => context.read<AuthBloc>().add(
                              AuthEmailChanged(value),
                            ),
                            errorText: state.emailError,
                          ),
                          const SizedBox(height: NestSpacing.s4),
                          NestTextField(
                            key: const ValueKey('p03_password'),
                            label: 'Password',
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            helperText: 'At least 8 characters',
                            onChanged: (value) => context.read<AuthBloc>().add(
                              AuthPasswordChanged(value),
                            ),
                            errorText: state.passwordError ?? state.formError,
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
                      );
                    },
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

/// Legal caption with two inert 44dp link targets (no Terms/Notice routes in
/// v1). Never use `NestBottomCta.caption` here — it cannot render links.
class _LegalLine extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final base = NestType.caption(color: tokens.ink2);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          'By continuing you agree to our ',
          style: base,
          textAlign: TextAlign.center,
          softWrap: true,
        ),
        const _LegalLink(key: ValueKey('p03_terms'), label: 'Terms'),
        Text(' and ', style: base, softWrap: true),
        const _LegalLink(key: ValueKey('p03_privacy'), label: 'Privacy Notice'),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const new({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final linkStyle = NestType.caption(color: tokens.sky).copyWith(
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: tokens.sky,
    );
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: NestDevice.tapParent,
          minHeight: NestDevice.tapParent,
        ),
        child: InkWell(
          // TODO(P03): inert — no Terms/Notice routes exist in v1.
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
            child: Text(label, style: linkStyle, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
