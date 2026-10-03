import 'package:flutter/material.dart';

/// The resolved colour set for one brightness.
///
/// Field names mirror `design/html-source/tokens.css` custom properties
/// (`--ink` → [ink], `--ink-2` → [ink2], …). Exact values are the contract in
/// `docs/design/SPACING_SPEC.md` — never hard-code hex in widgets, read them
/// from `context.nest` instead.
@immutable
class NestSchemeColors {
  const new({
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
    required this.onLeaf,
    required this.onAccent,
    required this.onWarm,
    required this.heroBg,
    required this.onHero,
    required this.onHero2,
    required this.appleBg,
    required this.appleInk,
    required this.googleBg,
    required this.googleInk,
    required this.googleLine,
    required this.scrim,
    required this.groundShadow,
    required this.track,
    required this.knob,
    required this.aLilac,
    required this.aPeach,
    required this.aSky,
    required this.kidSkyTop,
    required this.kidSkyBottom,
    required this.kidMeadow,
    required this.kidHorizon,
    this.petGlow,
  });

  factory lerp(NestSchemeColors a, NestSchemeColors b, double t) {
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return NestSchemeColors(
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
      onLeaf: c(a.onLeaf, b.onLeaf),
      onAccent: c(a.onAccent, b.onAccent),
      onWarm: c(a.onWarm, b.onWarm),
      heroBg: c(a.heroBg, b.heroBg),
      onHero: c(a.onHero, b.onHero),
      onHero2: c(a.onHero2, b.onHero2),
      appleBg: c(a.appleBg, b.appleBg),
      appleInk: c(a.appleInk, b.appleInk),
      googleBg: c(a.googleBg, b.googleBg),
      googleInk: c(a.googleInk, b.googleInk),
      googleLine: c(a.googleLine, b.googleLine),
      scrim: c(a.scrim, b.scrim),
      groundShadow: c(a.groundShadow, b.groundShadow),
      track: c(a.track, b.track),
      knob: c(a.knob, b.knob),
      aLilac: c(a.aLilac, b.aLilac),
      aPeach: c(a.aPeach, b.aPeach),
      aSky: c(a.aSky, b.aSky),
      kidSkyTop: c(a.kidSkyTop, b.kidSkyTop),
      kidSkyBottom: c(a.kidSkyBottom, b.kidSkyBottom),
      kidMeadow: c(a.kidMeadow, b.kidMeadow),
      kidHorizon: c(a.kidHorizon, b.kidHorizon),
      petGlow: Color.lerp(a.petGlow, b.petGlow, t),
    );
  }

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
  final Color onLeaf;
  final Color onAccent;
  final Color onWarm;
  final Color heroBg;
  final Color onHero;
  final Color onHero2;
  final Color appleBg;
  final Color appleInk;
  final Color googleBg;
  final Color googleInk;
  final Color googleLine;
  final Color scrim;
  final Color groundShadow;
  final Color track;
  final Color knob;
  final Color aLilac;
  final Color aPeach;
  final Color aSky;
  final Color kidSkyTop;
  final Color kidSkyBottom;
  final Color kidMeadow;
  final Color kidHorizon;

  /// `--pet-glow` centre colour (`tokens.css`): null in light (no glow),
  /// white @10% in dark. Widgets build the `radial-gradient(circle 110px…,
  /// transparent 70%)` fade from this; never hard-code the alpha at call
  /// sites. Nullable, so [copyWith] takes a sentinel default (below) — an
  /// explicit null clears it.
  final Color? petGlow;

  /// Sentinel distinguishing "not passed" from an explicit null [petGlow].
  static const Object _petGlowUnset = Object();

  NestSchemeColors copyWith({
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
    Color? onLeaf,
    Color? onAccent,
    Color? onWarm,
    Color? heroBg,
    Color? onHero,
    Color? onHero2,
    Color? appleBg,
    Color? appleInk,
    Color? googleBg,
    Color? googleInk,
    Color? googleLine,
    Color? scrim,
    Color? groundShadow,
    Color? track,
    Color? knob,
    Color? aLilac,
    Color? aPeach,
    Color? aSky,
    Color? kidSkyTop,
    Color? kidSkyBottom,
    Color? kidMeadow,
    Color? kidHorizon,
    Object? petGlow = _petGlowUnset,
  }) {
    return NestSchemeColors(
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
      onLeaf: onLeaf ?? this.onLeaf,
      onAccent: onAccent ?? this.onAccent,
      onWarm: onWarm ?? this.onWarm,
      heroBg: heroBg ?? this.heroBg,
      onHero: onHero ?? this.onHero,
      onHero2: onHero2 ?? this.onHero2,
      appleBg: appleBg ?? this.appleBg,
      appleInk: appleInk ?? this.appleInk,
      googleBg: googleBg ?? this.googleBg,
      googleInk: googleInk ?? this.googleInk,
      googleLine: googleLine ?? this.googleLine,
      scrim: scrim ?? this.scrim,
      groundShadow: groundShadow ?? this.groundShadow,
      track: track ?? this.track,
      knob: knob ?? this.knob,
      aLilac: aLilac ?? this.aLilac,
      aPeach: aPeach ?? this.aPeach,
      aSky: aSky ?? this.aSky,
      kidSkyTop: kidSkyTop ?? this.kidSkyTop,
      kidSkyBottom: kidSkyBottom ?? this.kidSkyBottom,
      kidMeadow: kidMeadow ?? this.kidMeadow,
      kidHorizon: kidHorizon ?? this.kidHorizon,
      petGlow: petGlow == _petGlowUnset ? this.petGlow : petGlow as Color?,
    );
  }
}

/// Access point for the two resolved colour sets.
///
/// `NestColors.light` is a 1:1 transcription of `tokens.css :root`;
/// `NestColors.dark` transcribes `:root[data-theme="dark"]`.
abstract final class NestColors {
  const new _();

  static const NestSchemeColors light = NestSchemeColors(
    ink: Color(0xFF1E1B3A),
    ink2: Color(0xFF4A4668),
    ink3: Color(0xFF6E6A8A),
    paper: Color(0xFFFBF7F0),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF3EEE5),
    line: Color(0xFFE7E0D4),
    leaf: Color(0xFF17804F),
    leafInk: Color(0xFF0B5C38),
    leafTint: Color(0xFFE3F5EC),
    coin: Color(0xFFF4B400),
    coinInk: Color(0xFF6B4E00),
    coinTint: Color(0xFFFFF4D1),
    sky: Color(0xFF2563D6),
    skyTint: Color(0xFFE6EFFE),
    lilac: Color(0xFF7C6CF2),
    lilacStrong: Color(0xFF6A58E8),
    lilacTint: Color(0xFFEEEBFF),
    peach: Color(0xFFFF8A5B),
    peachTint: Color(0xFFFFEDE4),
    success: Color(0xFF1F9D63),
    warning: Color(0xFFC97800),
    danger: Color(0xFFC93A3A),
    onLeaf: Color(0xFFFFFFFF),
    onAccent: Color(0xFFFFFFFF),
    onWarm: Color(0xFF1E1B3A),
    heroBg: Color(0xFF1E1B3A),
    onHero: Color(0xFFFFFFFF),
    onHero2: Color(0xFFC9C4DC),
    appleBg: Color(0xFF000000),
    appleInk: Color(0xFFFFFFFF),
    googleBg: Color(0xFFFFFFFF),
    googleInk: Color(0xFF1E1B3A),
    googleLine: Color(0xFFE7E0D4),
    scrim: Color(0x731E1B3A),
    groundShadow: Color(0x1F1E1B3A),
    track: Color(0xFFD9D3C6),
    knob: Color(0xFFFFFFFF),
    aLilac: Color(0xFF3F35A8),
    aPeach: Color(0xFFB44A1F),
    aSky: Color(0xFF1E4FA3),
    kidSkyTop: Color(0xFFCFE6FF),
    kidSkyBottom: Color(0xFFF2FAFF),
    kidMeadow: Color(0xFFBFE8B0),
    kidHorizon: Color(0xFFEAF7E2),
  );

  static const NestSchemeColors dark = NestSchemeColors(
    ink: Color(0xFFF3F0FA),
    ink2: Color(0xFFC9C4DC),
    ink3: Color(0xFFA09AB9),
    paper: Color(0xFF15131F),
    surface: Color(0xFF1F1C2E),
    surface2: Color(0xFF2A2640),
    line: Color(0xFF363150),
    leaf: Color(0xFF3CC98A),
    leafInk: Color(0xFF8EE6BC),
    leafTint: Color(0xFF173A2B),
    coin: Color(0xFFF4B400),
    coinInk: Color(0xFFFFD86B),
    coinTint: Color(0xFF3A2F10),
    sky: Color(0xFF7FA9FF),
    skyTint: Color(0xFF1A2A4A),
    lilac: Color(0xFFA89BFF),
    lilacStrong: Color(0xFFA89BFF),
    lilacTint: Color(0xFF2B2550),
    peach: Color(0xFFFF9E78),
    peachTint: Color(0xFF3E261D),
    success: Color(0xFF3CC98A),
    warning: Color(0xFFF0A83A),
    danger: Color(0xFFFF7A7A),
    onLeaf: Color(0xFF0E1A14),
    onAccent: Color(0xFF14121F),
    onWarm: Color(0xFF1E1B3A),
    heroBg: Color(0xFF2A2640),
    onHero: Color(0xFFF3F0FA),
    onHero2: Color(0xFFC9C4DC),
    appleBg: Color(0xFFFFFFFF),
    appleInk: Color(0xFF000000),
    googleBg: Color(0xFF131314),
    googleInk: Color(0xFFE3E3E3),
    googleLine: Color(0xFF8E918F),
    scrim: Color(0x9E000000),
    groundShadow: Color(0x73000000),
    track: Color(0xFF453F63),
    knob: Color(0xFFFFFFFF),
    aLilac: Color(0xFFCDC4FF),
    aPeach: Color(0xFFFFB795),
    aSky: Color(0xFFA9C6FF),
    kidSkyTop: Color(0xFF1B2150),
    kidSkyBottom: Color(0xFF2C3572),
    kidMeadow: Color(0xFF1E4A3A),
    kidHorizon: Color(0xFF253359),
    // `--pet-glow` centre: rgba(255,255,255,.10) (0x1A = 26/255 ≈ 0.102).
    petGlow: Color(0x1AFFFFFF),
  );
}
