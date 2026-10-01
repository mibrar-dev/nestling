import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/auth/auth_routes.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_state.dart';

/// P01 Welcome — parent-mode brand screen at `/welcome`.
///
/// Static brand content (no data dependency): the illustration scene, the
/// headline/body and the two CTAs render identically for every
/// [OnboardingState] status. The [OnboardingBloc] is still subscribed via
/// [BlocBuilder] so the route-level `watchItems()` stream stays live for the
/// rest of the onboarding flow.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.nest.paper,
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          Expanded(
            child: BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (_, _) => const _WelcomeScroll(),
            ),
          ),
          NestBottomCta(
            caption: 'Made in the UK · No ads, ever',
            child: Column(
              spacing: NestSpacing.s2,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NestButton(
                  key: const ValueKey('p01_get_started'),
                  label: 'Get started',
                  onPressed: () => context.go(OnboardingRoutePaths.valueTour),
                ),
                NestButton(
                  key: const ValueKey('p01_have_account'),
                  label: 'I already have an account',
                  variant: NestButtonVariant.ghost,
                  onPressed: () => context.go(AuthRoutePaths.createAccount),
                ),
              ],
            ),
          ),
          const NestHomeIndicator(),
        ],
      ),
    );
  }
}

class _WelcomeScroll extends StatelessWidget {
  const _WelcomeScroll();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[_WelcomeScene(), _WelcomeText()],
      ),
    );
  }
}

/// 350x388 illustration block: leaf-tint circle, twig nest, Pip stage 2 and
/// three floating coins on the circle rim. Scales down (never up) when the
/// content width is narrower than 390dp so nothing overflows at 320dp.
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 350).clamp(0.0, 1.0);
        return SizedBox(
          width: 350 * scale,
          height: 388 * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 350,
              height: 388,
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 15,
                    top: 44,
                    width: 320,
                    height: 320,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.leafTint,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 43,
                    top: 104,
                    width: 264,
                    height: 264,
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        NestlingIllustrations.nest,
                        width: 264,
                        height: 264,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 91,
                    top: 120,
                    width: 168,
                    height: 168,
                    child: SvgPicture.asset(
                      NestlingIllustrations.pipStage2,
                      width: 168,
                      height: 168,
                      semanticsLabel:
                          'Pip the hatchling bird sitting in a twig nest',
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 104,
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: -14 * math.pi / 180,
                      child: const _SceneCoin(size: 40),
                    ),
                  ),
                  Positioned(
                    left: 308,
                    top: 132,
                    width: 34,
                    height: 34,
                    child: Transform.rotate(
                      angle: 16 * math.pi / 180,
                      child: const _SceneCoin(size: 34),
                    ),
                  ),
                  Positioned(
                    left: 7,
                    top: 241,
                    width: 36,
                    height: 36,
                    child: Transform.rotate(
                      angle: 22 * math.pi / 180,
                      child: const _SceneCoin(size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Decorative floating coin with the `--sh-1` card shadow.
class _SceneCoin extends StatelessWidget {
  const _SceneCoin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: context.nest.cardShadow,
        ),
        child: SvgPicture.asset(
          NestlingIllustrations.coin,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

class _WelcomeText extends StatelessWidget {
  const _WelcomeText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'Chores that feel like a game.',
            style: context.nestText.display,
          ),
        ),
        const SizedBox(height: NestSpacing.s3),
        Text(
          'Nestling turns family jobs into quests your children actually '
          'want to finish — and keeps pocket money fair and tidy.',
          style: NestType.body(color: context.nest.ink2),
        ),
      ],
    );
  }
}
