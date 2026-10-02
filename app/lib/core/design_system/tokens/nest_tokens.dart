import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/colors.dart';
import 'package:nestling/core/design_system/tokens/shadows.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// The resolved design tokens for the current theme.
///
/// Carried on [ThemeData.extensions]; reach it via `context.nest`.
@immutable
class NestTokens extends ThemeExtension<NestTokens> {
  const new({required this.colors, required this.brightness});

  final NestSchemeColors colors;
  final Brightness brightness;

  bool get isDark => brightness == Brightness.dark;

  Color get ink => colors.ink;
  Color get ink2 => colors.ink2;
  Color get ink3 => colors.ink3;
  Color get paper => colors.paper;
  Color get surface => colors.surface;
  Color get surface2 => colors.surface2;
  Color get line => colors.line;
  Color get leaf => colors.leaf;
  Color get leafInk => colors.leafInk;
  Color get leafTint => colors.leafTint;
  Color get coin => colors.coin;
  Color get coinInk => colors.coinInk;
  Color get coinTint => colors.coinTint;
  Color get sky => colors.sky;
  Color get skyTint => colors.skyTint;
  Color get lilac => colors.lilac;
  Color get lilacStrong => colors.lilacStrong;
  Color get lilacTint => colors.lilacTint;
  Color get peach => colors.peach;
  Color get peachTint => colors.peachTint;
  Color get success => colors.success;
  Color get warning => colors.warning;
  Color get danger => colors.danger;
  Color get onLeaf => colors.onLeaf;
  Color get onAccent => colors.onAccent;
  Color get onWarm => colors.onWarm;
  Color get heroBg => colors.heroBg;
  Color get onHero => colors.onHero;
  Color get onHero2 => colors.onHero2;
  Color get appleBg => colors.appleBg;
  Color get appleInk => colors.appleInk;
  Color get googleBg => colors.googleBg;
  Color get googleInk => colors.googleInk;
  Color get googleLine => colors.googleLine;
  Color get scrim => colors.scrim;
  Color get groundShadow => colors.groundShadow;
  Color get track => colors.track;
  Color get knob => colors.knob;
  Color get aLilac => colors.aLilac;
  Color get aPeach => colors.aPeach;
  Color get aSky => colors.aSky;
  Color get kidSkyTop => colors.kidSkyTop;
  Color get kidSkyBottom => colors.kidSkyBottom;
  Color get kidMeadow => colors.kidMeadow;
  Color get kidHorizon => colors.kidHorizon;

  List<BoxShadow> get cardShadow =>
      isDark ? NestShadows.sh1Dark : NestShadows.sh1;
  List<BoxShadow> get raisedShadow =>
      isDark ? NestShadows.sh2Dark : NestShadows.sh2;
  List<BoxShadow> get kidShadow =>
      isDark ? NestShadows.shKidDark : NestShadows.shKid;

  @override
  NestTokens copyWith({NestSchemeColors? colors, Brightness? brightness}) {
    return NestTokens(
      colors: colors ?? this.colors,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  NestTokens lerp(covariant NestTokens? other, double t) {
    if (other == null) {
      return this;
    }
    return NestTokens(
      colors: NestSchemeColors.lerp(colors, other.colors, t),
      brightness: t < 0.5 ? brightness : other.brightness,
    );
  }
}

/// Kid-mode metrics: Nunito everywhere, larger sizes, chunky targets.
///
/// Applied to a subtree via KidScope (see theme/kid_scope.dart).
@immutable
class NestKidTheme extends ThemeExtension<NestKidTheme> {
  const new({
    this.minTarget = 56,
    this.buttonHeight = 64,
    this.borderWidth = 3,
  });

  /// Minimum tap target edge in kid mode (`--tap-kid`).
  final double minTarget;

  /// `.btn-kid` height.
  final double buttonHeight;

  /// Chunky ink outline width on kid surfaces.
  final double borderWidth;

  @override
  NestKidTheme copyWith({
    double? minTarget,
    double? buttonHeight,
    double? borderWidth,
  }) {
    return NestKidTheme(
      minTarget: minTarget ?? this.minTarget,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  NestKidTheme lerp(covariant NestKidTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return NestKidTheme(
      minTarget: lerpDouble(minTarget, other.minTarget, t)!,
      buttonHeight: lerpDouble(buttonHeight, other.buttonHeight, t)!,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
    );
  }
}

/// `context.nest` — tokens; `context.nestText` — resolved type scale;
/// `context.nestKid` — kid metrics (defaults outside a KidScope).
extension NestContext on BuildContext {
  NestTokens get nest => Theme.of(this).extension<NestTokens>()!;

  NestTextStyles get nestText {
    final tokens = nest;
    return NestTextStyles(
      ink: tokens.ink,
      ink2: tokens.ink2,
      ink3: tokens.ink3,
      leafInk: tokens.leafInk,
    );
  }

  NestKidTheme get nestKid =>
      Theme.of(this).extension<NestKidTheme>() ?? const NestKidTheme();
}
