import 'package:flutter/material.dart';

/// Motion (`--motion-fast / --motion-spring`).
///
/// Always route animations through [resolve] (or check
/// `MediaQuery.disableAnimationsOf`) so Reduce Motion / Remove Animations is
/// honoured at the call site.
abstract final class NestMotion {
  const new _();

  /// `--motion-fast: 180ms ease-out` — toggles, chips, fades.
  static const Duration fast = Duration(milliseconds: 180);
  static const Curve fastCurve = Curves.easeOut;

  /// `--motion-spring: 320ms cubic-bezier(.34,1.56,.64,1)` — kid presses,
  /// sheets, celebratory motion.
  static const Duration spring = Duration(milliseconds: 320);
  static const Curve springCurve = Cubic(0.34, 1.56, 0.64, 1);

  /// Returns [base] unless animations are disabled, then [Duration.zero].
  static Duration resolve(BuildContext context, Duration base) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Duration.zero;
    }
    return base;
  }

  /// Returns [base] unless animations are disabled, then [Curves.linear].
  static Curve resolveCurve(BuildContext context, Curve base) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Curves.linear;
    }
    return base;
  }
}
