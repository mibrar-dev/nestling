// GENERATED FROM tokens.css - do not edit by hand without updating the
// OpenDesign source (project nestling-uk-family-chores-mobile-ui-e9c1).
//
// Light values are a 1:1 transcription of tokens.css :root.
// Dark values are DERIVED - tokens.css ships no dark block. See
// NestlingColorsDark's doc comment before enabling dark mode.

import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour tokens, light. Transcribed from `--*` custom properties in tokens.css.
abstract final class NestlingColorsLight {
  const NestlingColorsLight._();

  // Neutrals
  static const Color ink = Color(0xFF1E1B3A); // primary text, plum-navy
  static const Color ink2 = Color(0xFF4A4668); // secondary text
  static const Color ink3 = Color(0xFF6E6A8A); // tertiary / captions
  static const Color paper = Color(
    0xFFFBF7F0,
  ); // parent app background, warm cream
  static const Color surface = Color(0xFFFFFFFF); // cards
  static const Color surface2 = Color(0xFFF3EEE5); // inset / chips
  static const Color line = Color(0xFFE7E0D4); // hairlines

  // Brand & semantic
  static const Color leaf = Color(0xFF17804F); // brand primary
  static const Color leafInk = Color(0xFF0B5C38); // text on leaf-tint
  static const Color leafTint = Color(0xFFE3F5EC);
  static const Color coin = Color(0xFFF4B400);
  static const Color coinInk = Color(0xFF6B4E00);
  static const Color coinTint = Color(0xFFFFF4D1);
  static const Color sky = Color(0xFF2563D6);
  static const Color skyTint = Color(0xFFE6EFFE);
  static const Color lilac = Color(0xFF7C6CF2);
  static const Color lilacStrong = Color(0xFF6A58E8);
  static const Color lilacTint = Color(0xFFEEEBFF);
  static const Color peach = Color(0xFFFF8A5B);
  static const Color peachTint = Color(0xFFFFEDE4);
  static const Color success = Color(0xFF1F9D63);
  static const Color warning = Color(0xFFC97800);
  static const Color danger = Color(
    0xFFC93A3A,
  ); // destructive only - never in kid mode

  // Kid-mode backgrounds
  static const Color kidSkyTop = Color(0xFFCFE6FF);
  static const Color kidSkyBottom = Color(0xFFF2FAFF);
  static const Color kidMeadow = Color(0xFFBFE8B0);

  /// Avatar tints for child profiles (.avatar colour modifiers in components.css).
  static const Map<String, Color> avatar = <String, Color>{
    'lilac': lilacTint,
    'peach': peachTint,
    'sky': skyTint,
    'leaf': leafTint,
    'coin': coinTint,
  };
}

/// Colour tokens, dark.
///
/// DERIVED, NOT AUTHORED. tokens.css defines a single `:root` block and no dark
/// block, so these values are an engineering inference: the warm cream / plum
/// neutrals are inverted to a dark plum-navy ramp, tints become dark surfaces, and
/// the accent hues are lifted for contrast on dark. They need design sign-off
/// before dark mode ships. Contrast of [ink] on [paper] is ~15:1 and [ink3] on
/// [paper] is ~7:1, so both clear WCAG AA for body text.
abstract final class NestlingColorsDark {
  const NestlingColorsDark._();

  // Neutrals
  static const Color ink = Color(0xFFF4F1FF);
  static const Color ink2 = Color(0xFFC3BFDD);
  static const Color ink3 = Color(0xFF9A95B8);
  static const Color paper = Color(0xFF14131C);
  static const Color surface = Color(0xFF1E1D29);
  static const Color surface2 = Color(0xFF2A2836);
  static const Color line = Color(0xFF383546);

  // Brand & semantic
  static const Color leaf = Color(0xFF34C77B);
  static const Color leafInk = Color(0xFF9BE7BE);
  static const Color leafTint = Color(0xFF14301F);
  static const Color coin = Color(0xFFF4B400);
  static const Color coinInk = Color(0xFFFFD97A);
  static const Color coinTint = Color(0xFF3A2E05);
  static const Color sky = Color(0xFF7FA9F5);
  static const Color skyTint = Color(0xFF1A2440);
  static const Color lilac = Color(0xFFA79BFF);
  static const Color lilacStrong = Color(0xFF8E7BFF);
  static const Color lilacTint = Color(0xFF241F45);
  static const Color peach = Color(0xFFFF9E76);
  static const Color peachTint = Color(0xFF3A2118);
  static const Color success = Color(0xFF34C77B);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFF06A6A);

  // Kid-mode backgrounds
  static const Color kidSkyTop = Color(0xFF16324F);
  static const Color kidSkyBottom = Color(0xFF0E1B29);
  static const Color kidMeadow = Color(0xFF2C5C3A);

  static const Map<String, Color> avatar = <String, Color>{
    'lilac': lilacTint,
    'peach': peachTint,
    'sky': skyTint,
    'leaf': leafTint,
    'coin': coinTint,
  };
}

/// 4pt spacing scale (--s1..--s10) plus screen side padding.
abstract final class NestlingSpace {
  const NestlingSpace._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;

  /// Screen side padding, parent and kid alike.
  static const double padSide = 20;
}

/// Corner radii (--r-s..--r-pill).
abstract final class NestlingRadius {
  const NestlingRadius._();

  static const double s = 10;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  static const BorderRadius allS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius allM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius allL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
}

/// Elevation, transcribed from --sh-1 / --sh-2 / --sh-kid.
abstract final class NestlingShadows {
  const NestlingShadows._();

  /// `--sh-1` - cards.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x0F1E1B3A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F1E1B3A), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// `--sh-2` - sheets, modals, floating buttons.
  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(color: Color(0x1A1E1B3A), offset: Offset(0, 6), blurRadius: 24),
  ];

  /// `--sh-kid` - the chunky pressable edge on `.btn-kid`.
  static const List<BoxShadow> kid = <BoxShadow>[
    BoxShadow(color: Color(0x1F1E1B3A), offset: Offset(0, 6), blurRadius: 0),
  ];
}

/// Motion (--motion-fast / --motion-spring). Respect
/// `MediaQuery.disableAnimationsOf(context)` and honour
/// `AccessibilityFeatures.disableAnimations` (i.e. iOS Reduce Motion /
/// Android Remove animations) at the call site.
abstract final class NestlingMotion {
  const NestlingMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Curve fastEase = Curves.easeOut;

  static const Duration spring = Duration(milliseconds: 320);
  static const Curve springCurve = Cubic(0.34, 1.56, 0.64, 1);
}

/// Device metrics the designs were built at (iPhone 15/16). Use for design QA
/// only - do not hard-code these into production layout.
abstract final class NestlingDevice {
  const NestlingDevice._();

  static const double width = 390;
  static const double height = 844;
  static const double statusBarHeight = 47;
  static const double homeIndicatorHeight = 34;
  static const double tabBarHeight = 84; // includes the home area

  /// Parent mode minimum tap target.
  static const double tapParent = 44;

  /// Kid mode minimum tap target.
  static const double tapKid = 56;
}

/// Type scale from tokens.css. Inter for parent-mode UI, Nunito for display and
/// kid mode, both via `google_fonts`.
abstract final class NestlingText {
  const NestlingText._();

  static TextStyle _inter(
    double size,
    double height,
    FontWeight weight, {
    double? letterSpacing,
    Color? color,
  }) {
    return GoogleFonts.interTextTheme().style.copyWith(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle _nunito(
    double size,
    double height,
    FontWeight weight, {
    Color? color,
  }) {
    return GoogleFonts.nunitoTextTheme().style.copyWith(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      color: color,
    );
  }

  // Parent mode / Inter
  static TextStyle body({Color? color}) =>
      _inter(16, 24, FontWeight.w400, color: color);
  static TextStyle bodyMedium({Color? color}) =>
      _inter(16, 24, FontWeight.w500, color: color);
  static TextStyle bodyStrong({Color? color}) =>
      _inter(16, 24, FontWeight.w700, color: color);
  static TextStyle bodySmall({Color? color}) =>
      _inter(15, 22, FontWeight.w400, color: color);
  static TextStyle bodySmallStrong({Color? color}) =>
      _inter(15, 22, FontWeight.w600, color: color);
  static TextStyle caption({Color? color}) =>
      _inter(13, 18, FontWeight.w500, color: color);
  static TextStyle label({Color? color}) =>
      _inter(13, 18, FontWeight.w600, color: color); // .field label
  static TextStyle tabLabel({Color? color}) =>
      _inter(11, 14, FontWeight.w600, color: color); // .tab-bar label
  static TextStyle numeric({Color? color}) =>
      _inter(16, 24, FontWeight.w600, color: color).copyWith(
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ); // .money / .num

  // Display & kid mode / Nunito
  static TextStyle display({Color? color}) =>
      _nunito(34, 40, FontWeight.w900, color: color);
  static TextStyle h1({Color? color}) =>
      _nunito(28, 34, FontWeight.w900, color: color);
  static TextStyle h2({Color? color}) =>
      _nunito(22, 28, FontWeight.w900, color: color);
  static TextStyle h3({Color? color}) =>
      _nunito(18, 24, FontWeight.w800, color: color);
  static TextStyle kidBody({Color? color}) =>
      _nunito(18, 26, FontWeight.w800, color: color);
  static TextStyle kidTitle({Color? color}) =>
      _nunito(28, 34, FontWeight.w900, color: color);
  static TextStyle kidHero({Color? color}) =>
      _nunito(40, 44, FontWeight.w900, color: color);
  static TextStyle buttonKid({Color? color}) =>
      _nunito(18, 24, FontWeight.w900, color: color);
  static TextStyle coinPill({Color? color}) =>
      _nunito(16, 20, FontWeight.w800, color: color);
}

/// The resolved colour set for one brightness, carried on [ThemeData.extensions].
@immutable
class NestlingPalette {
  const NestlingPalette({
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.paper,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.leaf,
    required this.leafInk,
    required this.leafTint,
    required this.coin,
    required this.coinInk,
    required this.coinTint,
    required this.sky,
    required this.skyTint,
    required this.lilac,
    required this.lilacStrong,
    required this.lilacTint,
    required this.peach,
    required this.peachTint,
    required this.success,
    required this.warning,
    required this.danger,
    required this.kidSkyTop,
    required this.kidSkyBottom,
    required this.kidMeadow,
  });

  /// The light palette, straight from tokens.css.
  factory NestlingPalette.light() => const NestlingPalette(
    ink: NestlingColorsLight.ink,
    ink2: NestlingColorsLight.ink2,
    ink3: NestlingColorsLight.ink3,
    paper: NestlingColorsLight.paper,
    surface: NestlingColorsLight.surface,
    surface2: NestlingColorsLight.surface2,
    line: NestlingColorsLight.line,
    leaf: NestlingColorsLight.leaf,
    leafInk: NestlingColorsLight.leafInk,
    leafTint: NestlingColorsLight.leafTint,
    coin: NestlingColorsLight.coin,
    coinInk: NestlingColorsLight.coinInk,
    coinTint: NestlingColorsLight.coinTint,
    sky: NestlingColorsLight.sky,
    skyTint: NestlingColorsLight.skyTint,
    lilac: NestlingColorsLight.lilac,
    lilacStrong: NestlingColorsLight.lilacStrong,
    lilacTint: NestlingColorsLight.lilacTint,
    peach: NestlingColorsLight.peach,
    peachTint: NestlingColorsLight.peachTint,
    success: NestlingColorsLight.success,
    warning: NestlingColorsLight.warning,
    danger: NestlingColorsLight.danger,
    kidSkyTop: NestlingColorsLight.kidSkyTop,
    kidSkyBottom: NestlingColorsLight.kidSkyBottom,
    kidMeadow: NestlingColorsLight.kidMeadow,
  );

  /// The derived dark palette.
  factory NestlingPalette.dark() => const NestlingPalette(
    ink: NestlingColorsDark.ink,
    ink2: NestlingColorsDark.ink2,
    ink3: NestlingColorsDark.ink3,
    paper: NestlingColorsDark.paper,
    surface: NestlingColorsDark.surface,
    surface2: NestlingColorsDark.surface2,
    line: NestlingColorsDark.line,
    leaf: NestlingColorsDark.leaf,
    leafInk: NestlingColorsDark.leafInk,
    leafTint: NestlingColorsDark.leafTint,
    coin: NestlingColorsDark.coin,
    coinInk: NestlingColorsDark.coinInk,
    coinTint: NestlingColorsDark.coinTint,
    sky: NestlingColorsDark.sky,
    skyTint: NestlingColorsDark.skyTint,
    lilac: NestlingColorsDark.lilac,
    lilacStrong: NestlingColorsDark.lilacStrong,
    lilacTint: NestlingColorsDark.lilacTint,
    peach: NestlingColorsDark.peach,
    peachTint: NestlingColorsDark.peachTint,
    success: NestlingColorsDark.success,
    warning: NestlingColorsDark.warning,
    danger: NestlingColorsDark.danger,
    kidSkyTop: NestlingColorsDark.kidSkyTop,
    kidSkyBottom: NestlingColorsDark.kidSkyBottom,
    kidMeadow: NestlingColorsDark.kidMeadow,
  );

  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color paper;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color leaf;
  final Color leafInk;
  final Color leafTint;
  final Color coin;
  final Color coinInk;
  final Color coinTint;
  final Color sky;
  final Color skyTint;
  final Color lilac;
  final Color lilacStrong;
  final Color lilacTint;
  final Color peach;
  final Color peachTint;
  final Color success;
  final Color warning;
  final Color danger;
  final Color kidSkyTop;
  final Color kidSkyBottom;
  final Color kidMeadow;

  NestlingPalette copyWith({
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? paper,
    Color? surface,
    Color? surface2,
    Color? line,
    Color? leaf,
    Color? leafInk,
    Color? leafTint,
    Color? coin,
    Color? coinInk,
    Color? coinTint,
    Color? sky,
    Color? skyTint,
    Color? lilac,
    Color? lilacStrong,
    Color? lilacTint,
    Color? peach,
    Color? peachTint,
    Color? success,
    Color? warning,
    Color? danger,
    Color? kidSkyTop,
    Color? kidSkyBottom,
    Color? kidMeadow,
  }) {
    return NestlingPalette(
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      line: line ?? this.line,
      leaf: leaf ?? this.leaf,
      leafInk: leafInk ?? this.leafInk,
      leafTint: leafTint ?? this.leafTint,
      coin: coin ?? this.coin,
      coinInk: coinInk ?? this.coinInk,
      coinTint: coinTint ?? this.coinTint,
      sky: sky ?? this.sky,
      skyTint: skyTint ?? this.skyTint,
      lilac: lilac ?? this.lilac,
      lilacStrong: lilacStrong ?? this.lilacStrong,
      lilacTint: lilacTint ?? this.lilacTint,
      peach: peach ?? this.peach,
      peachTint: peachTint ?? this.peachTint,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      kidSkyTop: kidSkyTop ?? this.kidSkyTop,
      kidSkyBottom: kidSkyBottom ?? this.kidSkyBottom,
      kidMeadow: kidMeadow ?? this.kidMeadow,
    );
  }

  static NestlingPalette lerp(NestlingPalette a, NestlingPalette b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return NestlingPalette(
      ink: c(a.ink, b.ink),
      ink2: c(a.ink2, b.ink2),
      ink3: c(a.ink3, b.ink3),
      paper: c(a.paper, b.paper),
      surface: c(a.surface, b.surface),
      surface2: c(a.surface2, b.surface2),
      line: c(a.line, b.line),
      leaf: c(a.leaf, b.leaf),
      leafInk: c(a.leafInk, b.leafInk),
      leafTint: c(a.leafTint, b.leafTint),
      coin: c(a.coin, b.coin),
      coinInk: c(a.coinInk, b.coinInk),
      coinTint: c(a.coinTint, b.coinTint),
      sky: c(a.sky, b.sky),
      skyTint: c(a.skyTint, b.skyTint),
      lilac: c(a.lilac, b.lilac),
      lilacStrong: c(a.lilacStrong, b.lilacStrong),
      lilacTint: c(a.lilacTint, b.lilacTint),
      peach: c(a.peach, b.peach),
      peachTint: c(a.peachTint, b.peachTint),
      success: c(a.success, b.success),
      warning: c(a.warning, b.warning),
      danger: c(a.danger, b.danger),
      kidSkyTop: c(a.kidSkyTop, b.kidSkyTop),
      kidSkyBottom: c(a.kidSkyBottom, b.kidSkyBottom),
      kidMeadow: c(a.kidMeadow, b.kidMeadow),
    );
  }
}

/// Spacing, radii, motion and device metrics, exposed as a [ThemeExtension] so
/// widgets can reach them with a single `context.tokens` lookup.
@immutable
class NestlingTokens extends ThemeExtension<NestlingTokens> {
  const NestlingTokens({required this.palette, this.radiusScale = 1});

  final NestlingPalette palette;

  /// Global radius multiplier. 1 in the shipped design; expose a setting if you
  /// want a squarer/rounder variant.
  final double radiusScale;

  factory NestlingTokens.light() =>
      NestlingTokens(palette: NestlingPalette.light());
  factory NestlingTokens.dark() =>
      NestlingTokens(palette: NestlingPalette.dark());

  // Spacing re-exported so a widget never has to import two files.
  double get s1 => NestlingSpace.s1;
  double get s2 => NestlingSpace.s2;
  double get s3 => NestlingSpace.s3;
  double get s4 => NestlingSpace.s4;
  double get s5 => NestlingSpace.s5;
  double get s6 => NestlingSpace.s6;
  double get s8 => NestlingSpace.s8;
  double get s10 => NestlingSpace.s10;
  double get padSide => NestlingSpace.padSide;

  double get rS => NestlingRadius.s * radiusScale;
  double get rM => NestlingRadius.m * radiusScale;
  double get rL => NestlingRadius.l * radiusScale;
  double get rXl => NestlingRadius.xl * radiusScale;
  BorderRadius get rPill => NestlingRadius.pill;

  List<BoxShadow> get shadowCard => NestlingShadows.card;
  List<BoxShadow> get shadowRaised => NestlingShadows.raised;
  List<BoxShadow> get shadowKid => NestlingShadows.kid;

  // Convenience aliases for the most-used tokens.
  Color get ink => palette.ink;
  Color get ink2 => palette.ink2;
  Color get ink3 => palette.ink3;
  Color get paper => palette.paper;
  Color get surface => palette.surface;
  Color get surface2 => palette.surface2;
  Color get line => palette.line;
  Color get leaf => palette.leaf;
  Color get leafInk => palette.leafInk;
  Color get leafTint => palette.leafTint;
  Color get coin => palette.coin;
  Color get coinInk => palette.coinInk;
  Color get coinTint => palette.coinTint;
  Color get sky => palette.sky;
  Color get skyTint => palette.skyTint;
  Color get lilac => palette.lilac;
  Color get lilacTint => palette.lilacTint;
  Color get peach => palette.peach;
  Color get peachTint => palette.peachTint;
  Color get success => palette.success;
  Color get warning => palette.warning;
  Color get danger => palette.danger;

  @override
  NestlingTokens copyWith({NestlingPalette? palette, double? radiusScale}) {
    return NestlingTokens(
      palette: palette ?? this.palette,
      radiusScale: radiusScale ?? this.radiusScale,
    );
  }

  @override
  NestlingTokens lerp(covariant NestlingTokens? other, double t) {
    if (other == null) return this;
    return NestlingTokens(
      palette: NestlingPalette.lerp(palette, other.palette, t),
      radiusScale: lerpDouble(radiusScale, other.radiusScale, t),
    );
  }
}

/// `context.tokens` - the [NestlingTokens] extension for the current theme.
extension NestlingTokensContext on BuildContext {
  NestlingTokens get tokens => Theme.of(this).extension<NestlingTokens>()!;
  NestlingPalette get colors => tokens.palette;
}

/// Builds a [ThemeData] wired to the Nestling tokens.
///
/// The parent-mode Material theme is calm (warm cream, generous space). Kid mode
/// is a separate theme, not a flag - see [buildNestlingKidTheme].
ThemeData buildNestlingTheme({Brightness brightness = Brightness.light}) {
  final bool isLight = brightness == Brightness.light;
  final tokens = isLight ? NestlingTokens.light() : NestlingTokens.dark();
  final p = tokens.palette;
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: p.leaf,
    onPrimary: isLight ? Colors.white : p.ink,
    primaryContainer: p.leafTint,
    onPrimaryContainer: p.leafInk,
    secondary: p.coin,
    onSecondary: p.coinInk,
    secondaryContainer: p.coinTint,
    onSecondaryContainer: p.coinInk,
    tertiary: p.lilac,
    onTertiary: Colors.white,
    tertiaryContainer: p.lilacTint,
    onTertiaryContainer: p.lilac,
    error: p.danger,
    onError: Colors.white,
    errorContainer: p.danger,
    onErrorContainer: Colors.white,
    surface: p.surface,
    onSurface: p.ink,
    surfaceContainerHighest: p.surface2,
    onSurfaceVariant: p.ink2,
    outline: p.line,
    outlineVariant: p.line,
    shadow: p.ink,
    scrim: p.ink,
    inverseSurface: p.ink,
    onInverseSurface: p.paper,
    inversePrimary: p.leaf,
  );

  final TextTheme text = TextTheme(
    bodyLarge: NestlingText.body(color: p.ink),
    bodyMedium: NestlingText.bodySmall(color: p.ink2),
    bodySmall: NestlingText.caption(color: p.ink3),
    labelLarge: NestlingText.bodySmallStrong(color: p.ink),
    labelMedium: NestlingText.label(color: p.ink2),
    labelSmall: NestlingText.tabLabel(color: p.ink3),
    titleLarge: NestlingText.h2(color: p.ink),
    titleMedium: NestlingText.h3(color: p.ink),
    titleSmall: NestlingText.bodyStrong(color: p.ink),
    displayLarge: NestlingText.display(color: p.ink),
    displayMedium: NestlingText.h1(color: p.ink),
    displaySmall: NestlingText.h2(color: p.ink),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    canvasColor: p.surface,
    textTheme: text,
    extensions: <ThemeExtension<dynamic>>[tokens],
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: NestlingText.h3(color: p.ink),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: NestlingRadius.allL),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: p.leaf,
        foregroundColor: isLight ? Colors.white : p.ink,
        shape: const RoundedRectangleBorder(borderRadius: NestlingRadius.pill),
        textStyle: NestlingText.bodyStrong(),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        shape: const RoundedRectangleBorder(borderRadius: NestlingRadius.pill),
        textStyle: NestlingText.bodyStrong(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.sky,
        textStyle: NestlingText.bodySmallStrong(),
      ),
    ),
    iconTheme: IconThemeData(color: p.ink2, size: 24),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: NestlingSpace.s3,
      iconColor: p.ink2,
      titleTextStyle: NestlingText.bodyStrong(color: p.ink),
      subtitleTextStyle: NestlingText.bodySmall(color: p.ink3),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? Colors.white : p.surface,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> s) =>
            s.contains(WidgetState.selected) ? p.leaf : p.surface2,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Kid mode: Nunito everywhere, chunky 64px `.btn-kid`-style targets, sky
/// gradient background. No tab bar, no prices in pounds.
ThemeData buildNestlingKidTheme({Brightness brightness = Brightness.light}) {
  final ThemeData base = buildNestlingTheme(brightness: brightness);
  final NestlingPalette p = brightness == Brightness.light
      ? NestlingPalette.light()
      : NestlingPalette.dark();

  return base.copyWith(
    textTheme: TextTheme(
      bodyLarge: NestlingText.kidBody(color: p.ink),
      bodyMedium: NestlingText.kidBody(color: p.ink2),
      bodySmall: NestlingText.kidBody(color: p.ink3),
      titleLarge: NestlingText.kidTitle(color: p.ink),
      titleMedium: NestlingText.kidTitle(color: p.ink),
      displayLarge: NestlingText.kidHero(color: p.ink),
      displayMedium: NestlingText.kidTitle(color: p.ink),
      displaySmall: NestlingText.h2(color: p.ink),
      labelLarge: NestlingText.buttonKid(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        backgroundColor: p.leaf,
        foregroundColor: brightness == Brightness.light ? Colors.white : p.ink,
        shape: const RoundedRectangleBorder(borderRadius: NestlingRadius.allL),
        textStyle: NestlingText.buttonKid(),
        elevation: 0,
      ),
    ),
  );
}

/// The kid-mode background: vertical sky gradient over the meadow.
const LinearGradient nestlingKidSky = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: <Color>[
    NestlingColorsLight.kidSkyTop,
    NestlingColorsLight.kidSkyBottom,
  ],
);
