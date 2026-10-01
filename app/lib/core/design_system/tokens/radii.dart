import 'package:flutter/material.dart';

/// Corner radii (`--r-s..--r-pill`).
///
/// `--r-s:10 --r-m:16 --r-l:24 --r-xl:32 --r-pill:999`.
abstract final class NestRadii {
  const new _();

  static const double s = 10;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double pill = 999;

  static const BorderRadius allS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius allM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius allL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius topXl = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
