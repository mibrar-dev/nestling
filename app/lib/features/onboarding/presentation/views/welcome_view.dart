import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/auth/auth_routes.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';

/// P01 Welcome — parent-mode brand screen at `/welcome`.
///
/// Static brand content (no data dependency): the illustration scene, the
/// headline/body and the two CTAs render identically whatever the onboarding
/// bloc status is, so the view subscribes to nothing — the route-level
/// `BlocProvider` in `onboarding_routes.dart` owns the `OnboardingBloc` and
/// its `watchItems()` subscription.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          const Expanded(child: _WelcomeScroll()),
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

/// 350x388 illustration block (design/html-source/screens/P01-welcome.html:12-25,
/// SPACING_SPEC §8): leaf-tint circle, twig nest, Pip (Mochi, sunny, stage 2
/// per ORCHESTRATOR_NOTES) and three floating coins on the circle rim.
///
/// Scales down (never up) below 390dp: the outer box reserves the scaled
/// frame while the [OverflowBox] lays the 350x388 design frame out at full
/// size, so only the *paint* is scaled and nothing is cropped (BUG-1). The
/// [Stack] does not clip, matching the HTML `.scene` (BUG-5).
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene();

  /// Design frame width: the 390dp canvas minus both 20dp side paddings.
  static const double _frameW = 350;

  /// Design frame height (`_frameW` + 38).
  static const double _frameH = 388;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / _frameW).clamp(0.0, 1.0);
        return SizedBox(
          width: _frameW * scale,
          height: _frameH * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: OverflowBox(
              minWidth: _frameW,
              maxWidth: _frameW,
              minHeight: _frameH,
              maxHeight: _frameH,
              alignment: Alignment.topLeft,
              child: Stack(
                clipBehavior: Clip.none,
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
                    child: Semantics(
                      label: 'Pip the hatchling bird sitting in a twig nest',
                      image: true,
                      // Mochi / sunny (default) / stage 2 per ORCHESTRATOR_NOTES;
                      // idle mood and no accessory (defaults). Passed
                      // explicitly they trip avoid_redundant_argument_values,
                      // and mood is additionally an ambiguous import
                      // (pip_avatar and pip_rive both define PipMood); the
                      // resolved values are pinned by welcome_view_test's
                      // PipAvatar test.
                      child: const PipAvatar(style: PipStyle.mochi, stage: 2),
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

  /// Headline cap (ORCHESTRATOR_NOTES #3): at 390dp the display line "Chores
  /// that feel like" must not fit, so "like" falls to line 2 as in the
  /// design. A cap (not a hard break) still wraps sensibly at 320dp
  /// (content 280 < cap) and text scale 1.3.
  static const double _headlineW = 300;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _headlineW),
            child: Text(
              'Chores that feel like a game.',
              style: context.nestText.display,
            ),
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
