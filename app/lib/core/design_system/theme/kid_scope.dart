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
  const new({required this.child, super.key});

  final Widget child;

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
            bottom: 0,
            child: SvgPicture.asset(
              nest_assets.NestlingIllustrations.meadowHill,
              fit: BoxFit.fill,
              height: 136,
              colorFilter: ColorFilter.mode(colors.kidMeadow, BlendMode.srcIn),
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
