import 'package:equatable/equatable.dart';

// Recent activity in the kid's jar (K09): pocket-money history in £/p.
class JarEntry extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.type,
    required this.amountPence,
    required this.date,
    this.iconKey = '',
  });

  final String id;
  final String title;
  final String detail;
  final String type;
  final int amountPence;
  final DateTime date;

  /// Quest icon key (`quests.icon`) for `quest_bonus` rows, resolved by title
  /// in the repository (K09-BUG-3). `''` when unknown — other row types, an
  /// unmatched note or an empty note — and the view then uses its fallback
  /// glyph. Defaults to `''` so existing constructions keep compiling.
  final String iconKey;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    type,
    amountPence,
    date,
    iconKey,
  ];
}
