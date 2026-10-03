import 'package:flutter/material.dart';

/// Type scale from `tokens.css`.
///
/// Parent UI uses Inter, display text and all kid text uses Nunito. Both
/// families are bundled in `assets/fonts` (Inter 4.001, Nunito 3.602 — the
/// exact builds the design HTML loads from Google Fonts, pinned so text
/// metrics match the design renders without a runtime download). Every
/// style carries `height = lineHeight / fontSize` so line boxes match
/// the CSS exactly.
abstract final class NestType {
  const new _();

  static const String _interFamily = 'Inter';
  static const String _nunitoFamily = 'Nunito';

  static TextStyle _inter(
    double size,
    double lineHeight,
    FontWeight weight, {
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _interFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      // The design CSS sets letter-spacing only on `.display` and
      // `.status-time`; every other class uses the browser default of 0.
      // Null would inherit Material 3 defaults (e.g. 0.25, 0.5), so default
      // to 0 explicitly.
      letterSpacing: letterSpacing ?? 0,
      color: color,
    );
  }

  static TextStyle _nunito(
    double size,
    double lineHeight,
    FontWeight weight, {
    double? letterSpacing,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _nunitoFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      // Same as [_inter]: design default is 0, not the Material default.
      letterSpacing: letterSpacing ?? 0,
      color: color,
    );
  }

  // Display (Nunito).
  static TextStyle display({Color? color}) =>
      _nunito(34, 40, FontWeight.w900, letterSpacing: -0.34, color: color);
  static TextStyle h1({Color? color}) =>
      _nunito(28, 34, FontWeight.w900, color: color);
  static TextStyle h2({Color? color}) =>
      _nunito(22, 28, FontWeight.w800, color: color);
  static TextStyle h3({Color? color}) =>
      _nunito(18, 24, FontWeight.w800, color: color);

  // Parent UI (Inter).
  static TextStyle body({Color? color}) =>
      _inter(16, 24, FontWeight.w400, color: color);
  static TextStyle bodyStrong({Color? color}) =>
      _inter(16, 24, FontWeight.w700, color: color);
  static TextStyle bodySmall({Color? color}) =>
      _inter(15, 22, FontWeight.w400, color: color);
  static TextStyle bodySmallStrong({Color? color}) =>
      _inter(15, 22, FontWeight.w600, color: color);
  static TextStyle caption({Color? color}) =>
      _inter(13, 18, FontWeight.w400, color: color);

  /// `.field label`: 13/18 w600.
  static TextStyle fieldLabel({Color? color}) =>
      _inter(13, 18, FontWeight.w600, color: color);

  /// Section label (P16 `.sect`): 13 w700 uppercase ls +6%.
  static TextStyle sectionLabel({Color? color}) =>
      _inter(13, 18, FontWeight.w700, letterSpacing: 0.78, color: color);

  /// `.chip` label: Inter 14/20 w600.
  static TextStyle chipLabel({Color? color}) =>
      _inter(14, 20, FontWeight.w600, color: color);

  /// Status chip / badge: Inter 12/16 w700.
  static TextStyle chipSmall({Color? color}) =>
      _inter(12, 16, FontWeight.w700, color: color);

  /// Pushed-screen bar title: Nunito 18/24 w800, centred (`.nav-bar.compact
  /// .nav-title`). Matches `h3` exactly; kept as an alias for call sites.
  static TextStyle navCompact({Color? color}) =>
      _nunito(18, 24, FontWeight.w800, color: color);

  /// `.tab` label: Inter 11 w600 lh 14.
  static TextStyle tabLabel({Color? color}) =>
      _inter(11, 14, FontWeight.w600, color: color);

  /// Parent button label: Inter 16/24 w700.
  static TextStyle buttonLabel({Color? color}) =>
      _inter(16, 24, FontWeight.w700, color: color);

  /// `.money`: tabular figures, w700, nowrap at the call site.
  static TextStyle money({Color? color}) => _inter(
    16,
    24,
    FontWeight.w700,
    color: color,
  ).copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);

  /// Status bar clock: Inter 15 w600 ls -1%.
  static TextStyle statusTime({Color? color}) =>
      _inter(15, 20, FontWeight.w600, letterSpacing: -0.15, color: color);

  // Kid (Nunito).
  static TextStyle kidBody({Color? color}) =>
      _nunito(18, 26, FontWeight.w700, color: color);
  static TextStyle kidTitle({Color? color}) =>
      _nunito(28, 34, FontWeight.w900, color: color);
  static TextStyle kidHero({Color? color}) =>
      _nunito(40, 44, FontWeight.w900, color: color);

  /// K03 kid header name: Nunito 22/26 w900.
  static TextStyle kidName({Color? color}) =>
      _nunito(22, 26, FontWeight.w900, color: color);

  /// K03 kid copy under the name: Nunito 15/20 w700. (K03 follows its HTML
  /// at 15 px with the recorded exemption from DESIGN_SPEC §0.9's 17 px
  /// kid minimum.)
  static TextStyle kidCaption({Color? color}) =>
      _nunito(15, 20, FontWeight.w700, color: color);

  /// K03 status chip label ("4 of 6 done"): Nunito 15/15 w800.
  static TextStyle kidChipLabel({Color? color}) =>
      _nunito(15, 15, FontWeight.w800, color: color);

  /// Kid button label: Nunito 20/26 w900.
  static TextStyle buttonKid({Color? color}) =>
      _nunito(20, 26, FontWeight.w900, color: color);

  /// `.coin-pill`: Nunito 16 w800 lh 1.
  static TextStyle coinPill({Color? color}) =>
      _nunito(16, 16, FontWeight.w800, color: color);
}

/// The type scale resolved against the current palette.
///
/// Reach it via `context.nestText`.
@immutable
class NestTextStyles {
  const new({
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.leafInk,
  });

  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color leafInk;

  TextStyle get display => NestType.display(color: ink);
  TextStyle get h1 => NestType.h1(color: ink);
  TextStyle get h2 => NestType.h2(color: ink);
  TextStyle get h3 => NestType.h3(color: ink);
  TextStyle get body => NestType.body(color: ink);
  TextStyle get bodyStrong => NestType.bodyStrong(color: ink);
  TextStyle get bodySmall => NestType.bodySmall(color: ink);
  TextStyle get bodySmallStrong => NestType.bodySmallStrong(color: ink);
  TextStyle get caption => NestType.caption(color: ink2);
  TextStyle get chipLabel => NestType.chipLabel(color: ink);
  TextStyle get chipSmall => NestType.chipSmall(color: ink);
  TextStyle get fieldLabel => NestType.fieldLabel(color: ink2);
  TextStyle get sectionLabel => NestType.sectionLabel(color: ink2);
  TextStyle get tabLabel => NestType.tabLabel(color: ink3);
  TextStyle get money => NestType.money(color: ink);
  TextStyle get kidBody => NestType.kidBody(color: ink);
  TextStyle get kidTitle => NestType.kidTitle(color: ink);
  TextStyle get kidHero => NestType.kidHero(color: ink);
  TextStyle get kidName => NestType.kidName(color: ink);
  TextStyle get kidCaption => NestType.kidCaption(color: ink2);
  TextStyle get kidChipLabel => NestType.kidChipLabel(color: leafInk);
}
