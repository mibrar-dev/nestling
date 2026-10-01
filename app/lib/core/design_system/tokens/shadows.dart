import 'package:flutter/material.dart';

/// Elevation (`--sh-1 / --sh-2 / --sh-kid`, plus dark variants).
///
/// Light: `sh-1: 0 1px 2px ink@6%, 0 2px 8px ink@6%`,
/// `sh-2: 0 6px 24px ink@10%`, `sh-kid: 0 6px 0 ink@12%`.
/// Dark: `sh-1: 0 1px 2px black@35%, 0 2px 8px black@40%`,
/// `sh-2: 0 6px 24px black@50%`, `sh-kid: 0 6px 0 black@45%`.
abstract final class NestShadows {
  const new _();

  /// `--sh-1` light — cards, lists, chips-selected, icon buttons.
  static const List<BoxShadow> sh1 = <BoxShadow>[
    BoxShadow(color: Color(0x0F1E1B3A), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F1E1B3A), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// `--sh-2` light — sheets, modals, FAB.
  static const List<BoxShadow> sh2 = <BoxShadow>[
    BoxShadow(color: Color(0x1A1E1B3A), offset: Offset(0, 6), blurRadius: 24),
  ];

  /// `--sh-kid` light — chunky pressable edge on kid buttons/cards/keys.
  static const List<BoxShadow> shKid = <BoxShadow>[
    BoxShadow(color: Color(0x1F1E1B3A), offset: Offset(0, 6)),
  ];

  /// `--sh-1` dark.
  static const List<BoxShadow> sh1Dark = <BoxShadow>[
    BoxShadow(color: Color(0x59000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// `--sh-2` dark.
  static const List<BoxShadow> sh2Dark = <BoxShadow>[
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 6), blurRadius: 24),
  ];

  /// `--sh-kid` dark.
  static const List<BoxShadow> shKidDark = <BoxShadow>[
    BoxShadow(color: Color(0x73000000), offset: Offset(0, 6)),
  ];

  /// Focus ring for inputs: `0 0 0 2px leaf-tint, 0 0 0 3px leaf`.
  static List<BoxShadow> focusRing(Color leafTint, Color leaf) {
    return <BoxShadow>[
      BoxShadow(color: leafTint, spreadRadius: 2),
      BoxShadow(color: leaf, spreadRadius: 1),
    ];
  }
}
