/// 4pt spacing scale (`--s1..--s10`) plus screen side padding.
///
/// Mirror of `tokens.css`: `--s1:4 --s2:8 --s3:12 --s4:16 --s5:20 --s6:24
/// --s8:32 --s10:40`, `--pad-side:20`. All values are logical px.
abstract final class NestSpacing {
  const new _();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;

  /// Screen side padding, parent and kid alike (`--pad-side`).
  static const double padSide = 20;

  /// Sub-scale gaps used verbatim by screens/components (no magic numbers).
  /// Covers every gap/padding below the 4pt grid used in the 6 reference
  /// screens: meta `margin-top:2`, pager dot half-gap `3`, P08 coin-inline
  /// paddings `5`/`9`, care-grid `gap:10`, P08 kid-card art margins `6`,
  /// hero/button paddings `14`.
  static const double gap2 = 2;
  static const double gap3 = 3;
  static const double gap5 = 5;
  static const double gap6 = 6;
  static const double gap7 = 7;
  static const double gap9 = 9;
  static const double gap10 = 10;
  static const double gap14 = 14;

  /// Kid header metrics shared by the kid backdrop headers (P17 `.kb-top`
  /// side padding, `.kb-pet` top margin) and the K01/K03/K04/K05 headers
  /// that draw the same block. Off the 4pt grid, so they live here rather
  /// than as per-screen literals (P17 4_review.md finding 8).
  static const double gap26 = 26;
  static const double gap28 = 28;
}

/// Parental-gate metrics (`design/html-source/screens/P17-parental-gate.html`).
///
/// Screen-specific sizes with no entry on the 4pt grid, kept here so the
/// gate (and any future `.lock-tile`/`.digit` user) shares one source
/// instead of documented literals (P17 4_review.md finding 8, same pattern
/// as [NestPager]).
abstract final class NestGate {
  const new _();

  /// `.lock-tile`: 52px lilac square.
  static const double lockTile = 52;

  /// Lock glyph inside the tile: 26px.
  static const double lockIcon = 26;

  /// `.digit`: 56×64 box, 2px border.
  static const double digitWidth = 56;
  static const double digitHeight = 64;
  static const double digitBorder = 2;

  /// Empty-digit caret: 3×24 leaf bar.
  static const double caretWidth = 3;
  static const double caretHeight = 24;

  /// `.kb-pet` Pip slot: 200px.
  static const double pipSlot = 200;
}

/// P02 value-tour pager geometry (`design/html-source/screens/P02-value-tour.html`).
///
/// Screen-specific metrics with no entry on the 4pt grid, kept here so pager
/// screens share one source instead of documented `static const`s.
abstract final class NestPager {
  const new _();

  /// `.pg-stage`: 52px progress-stage circle.
  static const double stage = 52;

  /// `.pg-pet`: 158px pager pet illustration.
  static const double pet = 158;

  /// `.pg-line`: 32px minimum row height.
  static const double lineMinHeight = 32;

  /// `.pv-add` dashed "add" row: 1.5px dashes, 6px dash / 4px gap, radius
  /// `r-m` (16), 44px minimum height.
  static const double addDashWidth = 1.5;
  static const double addDashLength = 6;
  static const double addDashGap = 4;
  static const double addMinHeight = 44;
}

/// Device metrics the designs were built at (iPhone 15/16, 390x844).
///
/// Use for design QA only — never hard-code layout widths from these except
/// the chrome heights, which are fixed by the spec.
abstract final class NestDevice {
  const new _();

  static const double width = 390;
  static const double height = 844;

  /// `--status-h`: status bar height.
  static const double statusH = 47;

  /// `--home-h`: home indicator reserve.
  static const double homeH = 34;

  /// `--tab-h`: tab bar height including the home reserve.
  static const double tabH = 84;

  /// Parent-mode minimum tap target edge.
  static const double tapParent = 44;

  /// Kid-mode minimum tap target edge.
  static const double tapKid = 56;

  /// Parent quest-check ring visual (28px; 44px hit area via padding).
  static const double checkRing = 28;
}
