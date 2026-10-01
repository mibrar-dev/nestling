import 'package:equatable/equatable.dart';

// A quest card in kid mode (K03, K04): big icon, coin reward and the child's
// progress state. Only coins are shown — never £.
class KidQuest extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.questId,
    required this.icon,
    required this.coins,
    required this.status,
  });

  final String id;
  final String title;
  final String detail;
  final String questId;
  final String icon;
  final int coins;

  /// `to_do | done_pending | approved | not_yet`.
  final String status;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    questId,
    icon,
    coins,
    status,
  ];
}
