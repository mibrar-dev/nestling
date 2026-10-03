import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';

enum NestAvatarColor { neutral, lilac, peach, sky, leaf, coin }

enum NestAvatarSize {
  s32,
  s44,
  s64,
  s96;

  double get dimension => switch (this) {
    NestAvatarSize.s32 => 32,
    NestAvatarSize.s44 => 44,
    NestAvatarSize.s64 => 64,
    NestAvatarSize.s96 => 96,
  };

  double get fontSize => switch (this) {
    NestAvatarSize.s32 => 14,
    NestAvatarSize.s44 => 18,
    NestAvatarSize.s64 => 24,
    NestAvatarSize.s96 => 38,
  };
}

class NestAvatar extends StatelessWidget {
  const new({
    required this.initial,
    super.key,
    this.size = NestAvatarSize.s44,
    this.color = NestAvatarColor.neutral,
    this.semanticLabel,
  });

  final String initial;
  final NestAvatarSize size;
  final NestAvatarColor color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final (Color bg, Color fg) = switch (color) {
      NestAvatarColor.neutral => (tokens.surface2, tokens.ink),
      NestAvatarColor.lilac => (tokens.lilacTint, tokens.aLilac),
      NestAvatarColor.peach => (tokens.peachTint, tokens.aPeach),
      NestAvatarColor.sky => (tokens.skyTint, tokens.aSky),
      NestAvatarColor.leaf => (tokens.leafTint, tokens.leafInk),
      NestAvatarColor.coin => (tokens.coinTint, tokens.coinInk),
    };
    final circle = Container(
      width: size.dimension,
      height: size.dimension,
      decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size.fontSize,
          fontWeight: FontWeight.w900,
          // `.avatar` sets no letter-spacing: browser default 0.
          letterSpacing: 0,
          color: fg,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
      ),
    );
    final label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: circle);
    }
    return Semantics(label: label, image: true, child: circle);
  }
}
