import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Apple brand glyph (feature-private artwork, not a design-system component).
///
/// Single-path mark copied from the P03 HTML source. Tinted with the ambient
/// [IconTheme] colour so the Apple button drives the light/dark flip
/// (white-on-black, black-on-white) via tokens.
class AppleGlyph extends StatelessWidget {
  const new({super.key});

  static const String _body =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"> '
      '<path fill="currentColor" d="M16.5 12.7c0-2.2 1.8-3.3 1.9-3.4-1-1.5-2.6-1.7-3.2-1.7-1.4-.1-2.7.8-3.3.8-.7 0-1.7-.8-2.8-.8-1.5 0-2.8.8-3.6 2.1-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.6 2.2 2.7 2.2 1.1 0 1.5-.7 2.8-.7s1.7.7 2.8.7c1.2 0 1.9-1.1 2.6-2.1.8-1.2 1.2-2.4 1.2-2.4s-2.2-.9-2.2-3.3zM14.3 6.1c.6-.8 1-1.8.9-2.9-.9 0-2 .6-2.6 1.4-.6.7-1.1 1.7-.9 2.8 1 .1 2-.5 2.6-1.3z"/> '
      '</svg>';

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color;
    return SvgPicture.string(
      _body,
      width: 20,
      height: 20,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
