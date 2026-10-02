import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Kid-mode scope: sky gradient background with an SVG meadow hill,
/// [NestKidTheme] metrics, Nunito-first text and ink icons.
///
/// Day/night follows the ambient brightness. The background is a single
/// vertical sky gradient plus the meadow hill illustration pinned to the
/// bottom (tinted with the meadow token) — no rectangular colour blocks,
/// so no visible seam.
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

  /// Hill tone. Defaults to `kidMeadow`; K03's in-flow band measured
  /// `kidHorizon` on both design PNGs.
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
    return Theme(
      data: theme.copyWith(extensions: merged.cast<ThemeExtension<dynamic>>()),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[colors.kidSkyTop, colors.kidSkyBottom],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: meadowBottom,
            child: SvgPicture.asset(
              nest_assets.NestlingIllustrations.meadowHill,
              fit: BoxFit.fill,
              height: meadowHeight,
              colorFilter: ColorFilter.mode(
                meadowColor ?? colors.kidMeadow,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (_) => const SizedBox.shrink(),
            ),
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
