import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/theme/kid_meadow.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Kid-mode scope: exact `.screen.kid` background with kid metrics.
///
/// The background transcribes `components.css:25` verbatim:
/// `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%,
/// kid-horizon 62%, kid-meadow 100%)` (plus the dark-only `--kid-stars`
/// layer), with the exact two-path `.meadow` hills ([NestMeadowPainter])
/// pinned to the physical bottom of the scope (full width, 136 tall,
/// `preserveAspectRatio="none"` stretch).
///
/// All three layers sit behind content (z 0) and never intercept taps
/// (`IgnorePointer`, like the CSS `pointer-events:none`). A bottom bar in
/// the content (kid dock, bottom CTA) paints opaquely above them, so the
/// owner rule — bar surface runs to the physical edge — still holds.
class KidScope extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.meadowHeight = _defaultMeadowHeight,
    this.meadowBottom = 0,
    this.meadowColor,
  });

  final Widget child;

  /// Meadow-hill height (K03 §6). Defaults to the shared 136 px bottom hill;
  /// screens whose design shows a taller band behind content (K03 progress +
  /// cards) pass a larger height instead of painting their own hill.
  final double meadowHeight;

  /// Distance of the hill's bottom edge above the scope bottom. Defaults to
  /// 0 (pinned to the edge, per the bottom-edge owner rule).
  final double meadowBottom;

  /// `.hill-back` tone. Defaults to `kidMeadow`; the `.hill-front` overlay
  /// is always [kidHillFront] of this over the surface.
  final Color? meadowColor;

  /// The shared bottom-hill height (`meadow_hill.svg` at 136 px).
  static const double _defaultMeadowHeight = 136;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<NestTokens>()!;
    final colors = tokens.colors;
    final kid = theme.extension<NestKidTheme>() ?? const NestKidTheme();
    // `ThemeData.extensions` is a `Map<Object, ThemeExtension<dynamic>>`, but
    // the compiler types its `values` as
    // `Iterable<ThemeExtension<ThemeExtension<dynamic>>>`, which no longer
    // flows into a `ThemeExtension<dynamic>` list or a spread. Collecting into
    // a `List<Object?>` and casting once at the end sidesteps that entirely.
    final merged = <Object?>[...theme.extensions.values, kid];
    final back = meadowColor ?? colors.kidMeadow;
    final front = kidHillFront(back, colors.surface);
    return Theme(
      data: theme.copyWith(extensions: merged.cast<ThemeExtension<dynamic>>()),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // `background-color` under the gradient, as in the CSS.
                  color: colors.kidSkyBottom,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colors.kidSkyTop,
                      colors.kidSkyBottom,
                      colors.kidHorizon,
                      colors.kidMeadow,
                    ],
                    stops: const <double>[
                      0,
                      NestMeadowGeometry.horizonStop,
                      NestMeadowGeometry.horizonStop,
                      1,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (tokens.isDark)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: NestKidStarsPainter()),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: meadowBottom,
            child: NestMeadow(height: meadowHeight, back: back, front: front),
          ),
          DefaultTextStyle(
            style: NestType.kidBody(color: colors.ink),
            child: IconTheme(
              data: IconThemeData(color: colors.ink, size: 26),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
